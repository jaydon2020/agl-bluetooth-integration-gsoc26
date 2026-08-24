---
title: AGL Bluetooth Settings Module
navTitle: Bluetooth Settings Module
description: Technical design, runtime sequences, and verification guidance for the AGL Bluetooth settings screen.
---

# AGL Bluetooth Settings Module

This guide describes how the Flutter ICS homescreen controls BlueZ through
`bluez_native`. It focuses on adapter power, pairing, saved-device connections,
disconnection, removal, and switching while enforcing one active Bluetooth
device.

## Revision History

| Version | Date | Description |
| :--- | :--- | :--- |
| 0.1 | 2026-06-25 | Initial Bluetooth pairing and settings guide. |
| 1.0 | 2026-06-28 | Added D-Bus contracts, lifecycle details, and security notes. |
| 1.2 | 2026-08-24 | Aligned runtime flows with Gerrit patch set 6 and the current Bluetooth sequence specification. |

## 1. Architecture

The homescreen UI delegates Bluetooth operations to `BluetoothNotifier`. The
notifier uses `bluez_native` to call BlueZ objects over the Linux system D-Bus.

<pre class="mermaid">
graph TD
    UI[Flutter ICS Homescreen] --> N[Riverpod BluetoothNotifier]
    N --> BN[bluez_native]
    BN --> DBus[Linux System D-Bus]
    DBus --> B[BlueZ bluetoothd]
    B --> HW[Bluetooth Controller]
</pre>

The main responsibilities are:

- **Homescreen UI**: Displays adapter state, saved devices, scan results,
  pairing prompts, and operation progress.
- **BluetoothNotifier**: Serializes operations, mirrors BlueZ state, and
  enforces the single-connected-device policy.
- **bluez_native**: Exposes adapter, device, and pairing-agent operations to
  Dart.
- **BlueZ**: Owns discovery, pairing records, profile connections, and D-Bus
  state.

## 2. Runtime Policy

The implementation follows these rules:

1. At most one paired device remains connected.
2. A selected device is unblocked before pairing or connecting.
3. A selected device is trusted before the connection sequence continues.
4. After a successful connection, every other paired device is blocked.
5. A manual disconnect unblocks all paired devices so another saved device can
   connect.
6. Removing a connected device disconnects it before removing its BlueZ object.
7. A failed switch makes a best-effort attempt to reconnect the previous
   device.
8. Pairing prompts represent real BlueZ agent requests; device switching does
   not use synthetic pairing requests.

Device blocking uses the BlueZ `org.bluez.Device1.Blocked` property. This
prevents inactive paired devices from reconnecting while another phone is the
active homescreen device.

## 3. Bluetooth Runtime Sequences

These diagrams are aligned with
[Bluetooth Runtime Sequences](../../specs/bluetooth_sequences_separated.md).

### Bluetooth On and Off

<pre class="mermaid">
sequenceDiagram
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (BlueZ)
    participant R as rfkill

    activate BN
    alt User turns Bluetooth off
        UI->>BN: setPowered(false)
        BN->>A: SetProperty("Powered", false)
        activate A
        A-->>BN: Success / adapterChanged
        deactivate A
        BN-->>UI: Update UI (Bluetooth Off)
    else User turns Bluetooth on
        UI->>BN: setPowered(true)
        opt Adapter is blocked by rfkill
            BN->>R: unblock
            activate R
            R-->>BN: Success
            deactivate R
        end
        BN->>A: SetProperty("Powered", true)
        activate A
        A-->>BN: Success / adapterChanged
        deactivate A
        BN-->>UI: Update UI (Bluetooth On)
    end
    deactivate BN
</pre>

### Pairing a New Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (BlueZ)
    participant D as Device1 (BlueZ)
    participant O as Other Paired Devices
    participant AM as AgentManager1 (BlueZ)

    UI->>BN: enterScanMode()
    activate BN
    BN->>A: SetDiscoveryFilter(A2DP, AVRCP, HFP)
    BN->>A: StartDiscovery()
    A-->>BN: deviceAdded
    BN-->>UI: Update discovered devices
    deactivate BN

    UI->>BN: pairAndConnect(Mobile)
    activate BN
    BN->>D: SetProperty("Blocked", false)
    opt Device is not trusted
        BN->>D: SetProperty("Trusted", true)
    end
    BN->>D: Pair()
    activate D
    D->>M: Bluetooth pairing protocol
    D->>AM: RequestConfirmation / AuthorizeService
    AM->>BN: agentRequest
    BN-->>UI: Show pairing dialog
    UI-->>BN: Accept
    BN->>AM: agentRespond(accepted: true)
    AM-->>D: Success
    D-->>BN: Paired = true
    deactivate D

    BN->>D: Disconnect temporary pairing connection
    BN->>D: Connect()
    activate D
    D->>M: Connect A2DP / AVRCP profiles
    M-->>D: Profiles connected
    D-->>BN: Connected = true
    deactivate D

    loop Every other paired device
        BN->>O: SetProperty("Blocked", true)
    end
    BN-->>UI: Update UI (Connected)
    deactivate BN
</pre>

The explicit disconnect and reconnect after pairing resets the temporary
connection created by `Pair()` and establishes the expected media profiles.

### Connecting a Saved Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as Device1 (BlueZ)
    participant O as Other Paired Devices

    UI->>BN: connect()
    activate BN
    BN->>D: SetProperty("Blocked", false)
    BN->>D: Connect()
    activate D

    alt Connection succeeds
        D->>M: Connect A2DP / AVRCP / HFP profiles
        M-->>D: Profiles connected
        D-->>BN: Connected = true
        loop Every other paired device
            BN->>O: SetProperty("Blocked", true)
        end
        BN-->>UI: Update UI (Connected)
    else Connection fails or times out
        D-->>BN: org.bluez.Error.Failed
        BN-->>UI: Revert operation state
    end
    deactivate D
    deactivate BN
</pre>

### Disconnecting a Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as Device1 (BlueZ)
    participant O as Paired Devices

    UI->>BN: disconnect()
    activate BN
    BN->>D: Disconnect()
    activate D
    D->>M: Disconnect profiles
    M-->>D: Profiles disconnected
    D-->>BN: Connected = false
    deactivate D

    loop Every paired device
        BN->>O: SetProperty("Blocked", false)
    end
    BN-->>UI: Update UI (Disconnected)
    deactivate BN
</pre>

Disconnecting keeps the BlueZ pairing record. Unblocking the paired-device set
allows the user to choose another saved phone.

### Removing a Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (BlueZ)
    participant D as Device1 (BlueZ)
    participant O as Paired Devices

    UI->>BN: removeDevice()
    activate BN
    opt Device is connected
        BN->>D: Disconnect()
        activate D
        D->>M: Disconnect
        M-->>D: Disconnected
        D-->>BN: Success
        deactivate D
        loop Every paired device
            BN->>O: SetProperty("Blocked", false)
        end
    end

    BN->>A: RemoveDevice(Device1 object path)
    activate A
    A->>M: Remove bonding
    M-->>A: Bonding removed
    A-->>BN: deviceRemoved
    deactivate A
    BN-->>UI: Update UI (Device Removed)
    deactivate BN
</pre>

Removing deletes the BlueZ device and pairing record. The phone must be
discovered and paired again before it can reconnect.

### Switching Devices

<pre class="mermaid">
sequenceDiagram
    participant M1 as Mobile 1 (Old)
    participant M2 as Mobile 2 (New)
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D1 as Device1 (Old)
    participant D2 as Device1 (New)
    participant O as Other Paired Devices

    UI->>BN: pairAndConnect(Mobile 2)
    activate BN
    BN->>D2: SetProperty("Blocked", false)
    BN->>D2: SetProperty("Trusted", true)
    BN-->>UI: New Connecting / old Disconnecting
    BN->>D1: Disconnect()
    activate D1
    D1->>M1: Disconnect
    M1-->>D1: Disconnected
    D1-->>BN: Connected = false
    deactivate D1

    BN->>D2: Connect()
    activate D2
    alt Switch succeeds
        D2->>M2: Connect profiles
        M2-->>D2: Profiles connected
        D2-->>BN: Connected = true
        loop Every other paired device, including Device 1
            BN->>O: SetProperty("Blocked", true)
        end
        BN-->>UI: Update UI (Switched)
    else Switch fails
        D2-->>BN: org.bluez.Error.Failed
        BN->>D1: SetProperty("Blocked", false)
        BN->>D1: Connect() for best-effort rollback
        D1->>M1: Connect
        M1-->>D1: Connected
        D1-->>BN: Connected = true
        loop Every other paired device, including Device 2
            BN->>O: SetProperty("Blocked", true)
        end
        BN-->>UI: Restore previous device
    end
    deactivate D2
    deactivate BN
</pre>

The homescreen displays the target as **Connecting...** and the current device
as **Disconnecting...** during the handover. There is no synthetic
`BlueZAgentRequest` or separate switch-confirmation state.

## 4. Pairing Agent Contract

The BlueZ client registers an `org.bluez.Agent1` implementation. Pairing
prompts are used only for real BlueZ requests.

| Method | Behavior |
| :--- | :--- |
| `RequestPinCode` | Prompts for a textual PIN and returns it to BlueZ. |
| `RequestPasskey` | Prompts for a numeric passkey and returns it to BlueZ. |
| `DisplayPinCode` | Displays the PIN supplied by BlueZ. |
| `DisplayPasskey` | Displays the passkey and entered-digit count. |
| `RequestConfirmation` | Displays the passkey and asks the user to accept or reject it. |
| `RequestAuthorization` | Requests user authorization for the device. |
| `AuthorizeService` | Authorizes a requested Bluetooth profile service. |
| `Cancel` | Clears the active pairing request. |
| `Release` | Releases the agent when BlueZ terminates it. |

The agent uses the `KeyboardDisplay` capability to support PIN entry,
passkey entry, passkey display, and confirmation flows.

## 5. UI and Operation State

Only one device operation runs at a time. The UI tracks the selected target and
the device being replaced so both rows can show stable progress during a switch.

| State | Purpose |
| :--- | :--- |
| `devices` | Current BlueZ device snapshot. |
| `powered` | Current adapter power state. |
| `changingPower` | Disables repeated power changes. |
| `scanning` | Indicates active discovery. |
| `scanTimedOut` | Selects the scan timeout and refresh state. |
| `busyAddress` | Identifies the target device for the active operation. |
| `disconnectingAddress` | Identifies the previous device during switching. |
| `pairingRequest` | Holds the current real BlueZ agent request. |
| `nativeAvailable` | Indicates whether the native BlueZ backend initialized. |

Device presentation follows these rules:

- Connected saved devices appear first; the rest are sorted alphabetically.
- Scan results are sorted by signal strength.
- Paired devices always remain visible.
- Unpaired results must advertise a supported profile or identify as a
  smartphone through Bluetooth Class-of-Device.
- A maximum of ten devices may be paired. The user must remove a saved device
  before scanning or pairing another one.

When the native backend is unavailable, the settings and scan routes display
the demo Bluetooth content instead of attempting D-Bus operations.

## 6. Operation Summary

| User action | BlueZ operations | Result |
| :--- | :--- | :--- |
| Power on | rfkill unblock when required, then `Adapter1.Powered = true` | Adapter becomes available. |
| Power off | `Adapter1.Powered = false` | Adapter stops Bluetooth activity. |
| Pair | Unblock, trust, pair, answer agent request, disconnect temporary link, connect | Selected device becomes active; other paired devices are blocked. |
| Connect saved device | Unblock, connect | Selected device becomes active; other paired devices are blocked. |
| Disconnect | Disconnect, then unblock all paired devices | Pairing record remains available. |
| Remove | Disconnect when needed, unblock paired devices, remove BlueZ object | Pairing record is deleted. |
| Switch | Unblock/trust target, disconnect current device, connect target | Target becomes active; failure attempts rollback. |

Errors are logged with `debugPrint()`, and operation state is cleared so the UI
can recover. The patch set 6 flow does not store Bluetooth errors for
configuration-controlled Snackbars.

## 7. Verification Checklist

1. Power the adapter off and on; when rfkill blocks it, verify the unblock occurs
   before `Adapter1.Powered = true`.
2. Start scanning and verify only supported unpaired devices and smartphones
   appear, sorted by signal strength.
3. Pair a new phone and confirm the D-Bus order: unblock, trust, pair, agent
   response, temporary disconnect, reconnect.
4. Verify A2DP and AVRCP are connected after the explicit reconnect.
5. Confirm every other paired device is blocked after pairing or connecting a
   saved device.
6. Disconnect the active device and verify every paired device is unblocked.
7. Remove a connected device and verify it is disconnected before
   `Adapter1.RemoveDevice`.
8. Switch from one phone to another and verify both progress states are visible.
9. Force the new connection to fail and verify the previous phone is unblocked
   and reconnected on a best-effort basis.
10. Start with multiple devices connected and verify the homescreen keeps one,
    disconnects the others, and reapplies the block policy.
11. Reach ten paired devices and verify scanning or pairing shows the device
    limit dialog.
12. Leave the scan page and verify discovery and pending pairing prompts are
    cleared.

## 8. Scope and Limitations

- The module targets classic Bluetooth profiles over BR/EDR.
- A2DP, AVRCP, HFP, PBAP, and MAP are the supported phone-oriented profiles
  used for scan filtering.
- PipeWire and WirePlumber own audio routing after BlueZ establishes the
  profiles.
- The module uses the first available BlueZ adapter; multi-adapter selection is
  not covered.
- Switching rollback is best-effort. A failed rollback leaves the UI
  disconnected and records the failure in debug output.

## Source

- [Bluetooth Runtime Sequences](../../specs/bluetooth_sequences_separated.md)
- [Gerrit change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
