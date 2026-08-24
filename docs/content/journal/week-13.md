---
title: Week 13
description: Progress summary for Week 13 (August 17-23, 2026) of the AGL Bluetooth Integration project.
---

This week, I uploaded patch set 6 of the Bluetooth pairing and connection
change for `flutter-ics-homescreen`. The update strengthens the single-device
connection policy, improves pairing and switching behavior, and makes the
Bluetooth UI usable when the native backend is unavailable.

## Status

- **Status**: Completed
- **Timeline**: August 17, 2026 to August 23, 2026
- **Gerrit change**: [AGL Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
- **Review status**: Patch set 6 uploaded; the change remains open for review.

## Progress

### 1. Uploaded Patch Set 6 to [Gerrit Change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)

The main highlight of patch set 6 is a more predictable single-connected-device
workflow. Before pairing or connecting a selected phone, the homescreen
unblocks and trusts it. After the connection succeeds, all other paired devices
are blocked through BlueZ's `Device1.Blocked` property so they cannot reconnect
and interfere with the active session.

Other patch set 6 improvements include:

- Implemented the block-device flow, which unblocks the selected device before
  connecting and blocks the other paired devices after a successful connection.
- Filtered scan results by A2DP, AVRCP, and HFP profiles, following the
  [Qt Bluetooth design](https://git.automotivelinux.org/src/libqtappfw/tree/bluetooth/bluetooth.cpp#n51),
  while retaining phones detected by Bluetooth device class.
- Improved the Bluetooth UI with a **Saved Devices** header, a
  **No saved devices** empty state, signal-strength sorting, and a scan refresh
  action.
- Added a demo interface when `bluez_native` or BlueZ cannot initialize.
- Replaced broad `ref.watch(bluetoothProvider)` usage with selective watches to
  reduce unnecessary widget rebuilds.

### 2. Bluetooth Runtime Sequences

The following sequences describe how the homescreen, `bluez_native`, and BlueZ
D-Bus objects interact after the patch set 6 changes.

#### Bluetooth On and Off

<pre class="mermaid">
sequenceDiagram
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as BlueZ Adapter1
    participant R as rfkill

    activate BN
    alt Turn Bluetooth off
        UI->>BN: setPowered(false)
        BN->>A: Set Powered = false
        activate A
        A-->>BN: adapterChanged
        deactivate A
        BN-->>UI: Bluetooth off
    else Turn Bluetooth on
        UI->>BN: setPowered(true)
        opt Adapter is blocked
            BN->>R: unblock
            activate R
            R-->>BN: Success
            deactivate R
        end
        BN->>A: Set Powered = true
        activate A
        A-->>BN: adapterChanged
        deactivate A
        BN-->>UI: Bluetooth on
    end
    deactivate BN
</pre>

#### Pairing a New Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as BlueZ Adapter1
    participant D as BlueZ Device1
    participant AM as BlueZ AgentManager1
    participant O as Other paired devices

    UI->>BN: enterScanMode()
    activate BN
    BN->>A: Set BR/EDR discovery filter
    activate A
    A-->>BN: Success
    deactivate A
    BN->>A: StartDiscovery()
    activate A
    A-->>BN: Success
    deactivate A
    BN-->>UI: Scan started
    deactivate BN

    A-->>BN: deviceAdded
    activate BN
    BN-->>UI: Show supported devices
    deactivate BN

    UI->>BN: pairAndConnect(Mobile)
    activate BN
    BN->>D: Set Blocked = false
    activate D
    D-->>BN: Success
    deactivate D
    opt Device is not trusted
        BN->>D: Set Trusted = true
        activate D
        D-->>BN: Success
        deactivate D
    end
    BN->>D: Pair()
    activate D
    D->>M: Bluetooth pairing protocol
    activate M
    M-->>D: Protocol response
    deactivate M
    D->>AM: RequestConfirmation / AuthorizeService
    activate AM
    AM->>BN: agentRequest
    activate BN
    BN-->>UI: Show pairing dialog
    activate UI
    UI->>BN: Accept pairing
    deactivate UI
    BN->>AM: agentRespond(accepted: true)
    deactivate BN
    AM-->>D: Success
    deactivate AM
    D-->>BN: Paired = true
    deactivate D
    BN-->>UI: Update UI (Paired)

    BN->>D: Disconnect temporary pairing connection
    activate D
    D-->>BN: Success
    deactivate D
    BN->>D: Connect A2DP and AVRCP profiles
    activate D
    D->>M: Connect profiles
    activate M
    M-->>D: Profiles connected
    deactivate M
    D-->>BN: Connected = true
    deactivate D
    loop Every other paired device
        BN->>O: Set Blocked = true
        activate O
        O-->>BN: Success
        deactivate O
    end
    BN-->>UI: Connected
    deactivate BN
</pre>

#### Connecting a Saved Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as BlueZ Device1
    participant O as Other paired devices

    UI->>BN: connect(Device)
    activate BN
    BN->>D: Set Blocked = false
    activate D
    D-->>BN: Success
    deactivate D
    BN->>D: Connect()
    activate D
    alt Connection succeeds
        D->>M: Connect A2DP / AVRCP / HFP profiles
        activate M
        M-->>D: Profiles connected
        deactivate M
        D-->>BN: Connected = true
        loop Every other paired device
            BN->>O: Set Blocked = true
            activate O
            O-->>BN: Success
            deactivate O
        end
        BN-->>UI: Connected
    else Connection fails or times out
        D-->>BN: org.bluez.Error.Failed
        BN-->>UI: Revert connection state
    end
    deactivate D
    deactivate BN
</pre>

#### Disconnecting a Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as BlueZ Device1
    participant O as Paired devices

    UI->>BN: disconnect(Device)
    activate BN
    BN->>D: Disconnect()
    activate D
    D->>M: Disconnect profiles
    activate M
    M-->>D: Profiles disconnected
    deactivate M
    D-->>BN: Connected = false
    deactivate D
    loop Every paired device
        BN->>O: Set Blocked = false
        activate O
        O-->>BN: Success
        deactivate O
    end
    BN-->>UI: Disconnected
    deactivate BN
</pre>

#### Removing a Device

<pre class="mermaid">
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as BlueZ Adapter1
    participant D as BlueZ Device1
    participant O as Paired devices

    UI->>BN: removeDevice(Device)
    activate BN
    opt Device is connected
        BN->>D: Disconnect()
        activate D
        D->>M: Disconnect
        activate M
        M-->>D: Disconnected
        deactivate M
        D-->>BN: Connected = false
        deactivate D
        loop Every paired device
            BN->>O: Set Blocked = false
            activate O
            O-->>BN: Success
            deactivate O
        end
    end
    BN->>A: RemoveDevice(Device object path)
    activate A
    A->>M: Remove bonding
    activate M
    M-->>A: Bonding removed
    deactivate M
    A-->>BN: deviceRemoved
    deactivate A
    BN-->>UI: Remove device from saved list
    deactivate BN
</pre>

#### Switching Devices

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
    activate D2
    D2-->>BN: Success
    deactivate D2
    BN->>D2: SetProperty("Trusted", true)
    activate D2
    D2-->>BN: Success
    deactivate D2

    BN-->>UI: New Connecting / old Disconnecting
    BN->>D1: Disconnect()
    activate D1
    D1->>M1: Disconnect
    activate M1
    M1-->>D1: Disconnected
    deactivate M1
    D1-->>BN: Connected = false
    deactivate D1

    BN->>D2: Connect()
    activate D2
    alt Switching succeeds
        D2->>M2: Connect profiles
        activate M2
        M2-->>D2: Profiles connected
        deactivate M2
        D2-->>BN: Connected = true
        loop Every other paired device, including Device 1
            BN->>O: Set Blocked = true
            activate O
            O-->>BN: Success
            deactivate O
        end
        BN-->>UI: Update UI (Switched)
    else Switching fails
        D2-->>BN: org.bluez.Error.Failed
        BN->>D1: SetProperty("Blocked", false)
        activate D1
        D1-->>BN: Success
        deactivate D1
        BN->>D1: Connect() for best-effort rollback
        activate D1
        D1->>M1: Connect
        activate M1
        M1-->>D1: Connected
        deactivate M1
        D1-->>BN: Connected = true
        deactivate D1
        loop Every other paired device, including Device 2
            BN->>O: SetProperty("Blocked", true)
            activate O
            O-->>BN: Success
            deactivate O
        end
        BN-->>UI: Restore previous device
    end
    deactivate D2
    deactivate BN
</pre>

Detailed versions with activations and D-Bus object interactions are available
in the [AGL Bluetooth Settings Module](guide/bluetooth-settings).

### 3. Prepared BlueZ Media-Player Verification

The verification follows a crash observed when the homescreen called
`MediaItem1.Play()`, causing `bluetoothd` to terminate. The problem and test
context are tracked in
[GitHub issue #5](https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26/issues/5).
George Kiagiadakis submitted the
[Patchwork series](https://patchwork.kernel.org/project/bluetooth/list/?series=1149990),
but I have not tested the series yet.

## Next Week Plan

- Build or apply George's BlueZ player series in the
  [bluez_media_native test environment](https://github.com/jaydon2020/bluez_media_native).
- Re-run AVRCP browsing, media playback, search, and player-disconnect
  scenarios.
- Compare the observed D-Bus callbacks with the documented runtime sequences.
- Continue resolving review feedback on Gerrit change 31887.

## Links

- **Gerrit review**: [flutter-ics-homescreen change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
- **Bluetooth settings module**: [AGL Bluetooth Settings Module](guide/bluetooth-settings)
- **BlueZ crash verification**: [GitHub issue #5](https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26/issues/5) and [George's Patchwork series 1149990](https://patchwork.kernel.org/project/bluetooth/list/?series=1149990)
