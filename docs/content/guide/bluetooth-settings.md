---
title: AGL Bluetooth Settings Module
navTitle: Bluetooth Settings Module
description: Technical design, state machines, and API contracts for the AGL Bluetooth settings screen.
---

# AGL Bluetooth Settings Module: Technical Documentation

This document describes the design, system architecture, state machines, and API contracts of the Bluetooth settings screen in the Automotive Grade Linux (AGL) Infotainment Homescreen application.

---

## Document Control & Revision History

| Version | Date | Author | Description of Changes |
| :--- | :--- | :--- | :--- |
| 0.1 | 2026-06-25 | Jian De | Initial draft detailing basic pairing flows and screens. |
| 1.0 | 2026-06-28 | Jian De | Upgraded to production-grade: added D-Bus contracts, error state machines, concurrency models, security models, and lifecycle details. |
| 1.1 | 2026-06-28 | Jian De | Addressed review gaps: detailed initialization, reconciled authorization paths, added Just Works security caveat, expanded sequence error paths, and reordered concurrency section. |

---

## 1. System Architecture & Components

The Bluetooth module follows a decoupled architecture separating UI views from a reactive state controller. This controller manages system-level BlueZ events via D-Bus native bindings.

<pre class="mermaid">
graph TD
    UI[Flutter AGL Homescreen UI] --> Riverpod[Riverpod State Notifier: BluetoothNotifier]
    Riverpod --> BlueZClient[bluez_native Client]
    BlueZClient --> DBus[Linux System D-Bus]
    DBus --> BlueZ[BlueZ Daemon: bluetoothd]
    BlueZ --> HW[Physical Bluetooth Controller]
    
    style UI fill:#2277FF,stroke:#333,stroke-width:2px,color:#fff
    style Riverpod fill:#44AA55,stroke:#333,stroke-width:2px,color:#fff
    style BlueZClient fill:#FFAA00,stroke:#333,stroke-width:2px,color:#fff
    style DBus fill:#8844AA,stroke:#333,stroke-width:2px,color:#fff
</pre>

### Components

*   **UI Views**:
    *   `bluetooth_screen.dart`: Displays the list of paired devices and powers the system on/off.
    *   `bluetooth_scan_screen.dart`: Lifecycle-aware wrapper for scanning.
    *   `bluetooth_scan_content.dart`: Displays discovered unpaired devices and handles discovery lifecycle.
    *   `bluetooth_pairing_request.dart`: Dynamic modal dialog overlay handling authentication inputs/outputs.
*   **State Management Layer**:
    *   `bluetooth_notifier.dart`: Keeps the list of devices, manages BlueZ adapter states, controls the discovery timer, registers/unregisters the agent, and coordinates connection/switching policies.
*   **Native Wrapper**:
    *   `bluez_native`: Vendored Dart FFI package linking to `sdbus-cpp` over Linux D-Bus system buses.

---

## 2. State Machine Design

The application divides Bluetooth interactions into two modes: **Idle Mode** (viewing paired devices) and **Scan Mode** (searching/pairing). The state machine incorporates recovery transitions, time limits, and error rollbacks.

<pre class="mermaid">
stateDiagram-v2
    [*] --> Idle: ensureInitialized()
    
    state Idle {
        [*] --> PairedDevicesOnly
        PairedDevicesOnly --> PowerOff: setPowered(false)
        PowerOff --> PairedDevicesOnly: setPowered(true)
        
        state PowerOff {
            [*] --> RFKillBlocked
            RFKillBlocked --> RFKillUnblocked: rfkill unblock bluetooth
        }
        
        PairedDevicesOnly --> ErrorState: D-Bus connection fails
    }
    
    Idle --> Scanning: enterScanMode()
    
    state Scanning {
        [*] --> ActiveScan
        ActiveScan --> ActiveScan: deviceAdded / deviceChanged
        ActiveScan --> Timeout: 2 min Scan Timer
        Timeout --> ActiveScan: enterScanMode() [Refresh]
        ActiveScan --> PairingPrompt: pair() / Incoming request
        
        state PairingPrompt {
            [*] --> UserPrompt
            UserPrompt --> AcceptResponse: Confirm / Input code
            UserPrompt --> CancelResponse: Cancel / Timeout / Reject
            AcceptResponse --> TrustAndConnect: respondToPairing(true)
            CancelResponse --> ResetScanState: respondToPairing(false)
        }
        
        TrustAndConnect --> ActiveScan: setTrusted(true) & connect() success
        TrustAndConnect --> ActiveScanError: connect() fails (sets error state)
        ResetScanState --> ActiveScan: Done
        
        ActiveScan --> SwitchPrompt: Attempt second connection (Device B)
        
        state SwitchPrompt {
            [*] --> SwitchConfirmation
            SwitchConfirmation --> DisconnectingOld: Confirm Switch
            SwitchConfirmation --> RejectSwitch: Cancel Switch
        }
        
        DisconnectingOld --> ConnectingNew: Disconnect success
        DisconnectingOld --> ActiveScanError: Disconnect fails (rollback to current)
        ConnectingNew --> ActiveScan: Connect success
        ConnectingNew --> RollbackOld: Connect fails
        RollbackOld --> ActiveScanError: Reconnect current device (best-effort)
        RejectSwitch --> ActiveScan: respondToPairing(false)
    }
    
    Scanning --> Idle: exitScanMode() [Back button / Dispose]
</pre>

### Transition and Error Actions

1.  **D-Bus Disconnection / Startup Timeout**: If the `BlueZClient` cannot connect to D-Bus during initialization (`ensureInitialized`), the notifier transitions to an error state (`state.copyWith(error: ...)`), keeping the UI responsive while indicating failure.
2.  **Pairing Failures**: If `device.pair()` throws an exception (e.g., `org.bluez.Error.AuthenticationFailed`, `AuthenticationCanceled`), the notifier catches the error, sets `state.error`, clears `busyAddress`, and reverts the UI to the scanning list view.
3.  **Connection Failures**: If `device.connect()` fails (e.g., `org.bluez.Error.Failed`, `NotReady`), the notifier captures the exception, raises a snackbar notification via `ScaffoldMessenger`, and releases the UI locks.
4.  **Single-Connection Switch Failures**: During a device swap, if disconnecting the active device fails, the operation halts immediately. If disconnecting succeeds but connecting the target device fails, the notifier initiates a best-effort reconnect back to the original device (`RollbackOld`).

---

## 3. Initialization & Lifecycle Sequence

### Initialization Flow
1.  **Auto-Initialization on Constructor Call**: When Riverpod instantiates the `BluetoothNotifier` at application boot, the constructor calls `unawaited(ensureInitialized())` to trigger Bluetooth adapter configuration in the background without blocking the main rendering pipeline.
2.  **D-Bus Connection Attempt**: The `_initializeBluetooth()` method requests a system D-Bus connection via `_client.connect()`.
    *   *Retry Strategy / Embedded Startup Races*: If the connection fails (e.g., during cold-boot when the BlueZ daemon is still starting), the error is caught, and the error status is set on the state. Subsequent calls to public notifier methods (like `setPowered` or `enterScanMode`) will re-invoke `ensureInitialized()`. Because the initialization future is cached on `_initialization`, a failure stores the finished error future. Future revisions will implement a dynamic polling reconnect loop or listen to D-Bus activation signals.
3.  **Dynamic Device Mirroring**: Once connected, the notifier queries and stores existing paired/connected devices, then sets up streams to mirror dynamic device lists (`deviceAdded`, `deviceRemoved`, `deviceChanged`).

### Disposal Lifecycle
When the notifier is disposed (e.g., if the host module is detached or the application terminates):
1.  **Active Scan Cancellation**: The 2-minute timeout timer is cancelled. If active discovery is running, `_adapter?.stopDiscovery()` is invoked.
2.  **Release D-Bus Agent**: If the agent is registered (`_agentRegistered` is true), the notifier unregisters the agent via `_client.unregisterAgent()`.
3.  **Subscription Release**: All stream listeners (`_deviceAddedSub`, `_deviceRemovedSub`, `_deviceChangedSub`, `_adapterChangedSub`, `_agentRequestSub`) are closed to prevent memory leaks.
4.  **Client Disconnection**: The D-Bus system client connection is explicitly closed via `_client.close()`.

---

## 4. Core Sequences & Flows

### A. Device Scanning & Agent Lifecycle

The BlueZ pairing agent's lifecycle is scoped to the scanning screen. Opening the scan page registers the agent; navigating away immediately unregisters it.

<pre class="mermaid">
sequenceDiagram
    autonumber
    actor User
    participant Page as BluetoothScanContent
    participant N as BluetoothNotifier
    participant BC as BlueZClient
    participant D as BlueZ Device

    User->>Page: Enters "Scan for New Device" Screen
    Page->>N: enterScanMode()
    Note over N: Check: Is Agent already registered? (Idempotent guard)
    N->>BC: registerAgent()
    N->>N: Start 2-minute Timer
    N->>BC: startDiscovery()
    BC->>D: Scan airwaves for packets
    D-->>BC: Report RSSI & Properties
    BC-->>N: Stream _deviceAddedSub fires
    N-->>Page: Rebuild UI with sorted list of unpaired devices
</pre>

### B. Security Association / Pairing Flow

When a user initiates pairing, BlueZ queries the registered agent for authentication.

<pre class="mermaid">
sequenceDiagram
    autonumber
    actor User
    participant Page as BluetoothScanContent
    participant PR as BluetoothPairingRequest (Overlay)
    participant N as BluetoothNotifier
    participant BC as BlueZClient
    participant D as BlueZ Device
    
    User->>Page: Tap Unpaired Device B
    Page->>N: pairAndConnect(Device B)
    N->>BC: stopDiscovery()
    N->>D: pair()
    Note over D: BlueZ performs security challenge
    
    alt Happy Path
        D-->>BC: Request PIN / confirmation code (D-Bus callback)
        BC->>N: Stream _agentRequestSub fires
        N-->>Page: State updated: pairingRequest != null
        Page-->>PR: Render glassmorphic dialog with code/input
        User->>PR: Accept pairing / Enter PIN
        PR->>N: respondToPairing(accepted: true)
        N->>BC: agentRespond(requestId, accepted: true)
        BC-->>D: Send D-Bus reply
        D-->>BC: Pairing succeeded
        N->>D: setTrusted(true)
        N->>D: connect()
        N-->>Page: Navigate back to main Bluetooth settings page
    else Error / Cancel Path
        D-->>BC: AuthenticationFailed / Rejected by user
        BC->>N: Stream throws exception
        N->>N: Revert state.error & busyAddress
        N-->>Page: Display SnackBar with error message
    end
</pre>

---

## 5. Concurrency, Thread Safety & Event Loop Model

Dart executes code inside a single-threaded **Isolate** backed by an **Event Loop**. Concurrency issues are managed at the event loop level:

```
[System D-Bus Signal] ──> [Ffi/C++ Bridge] ──> [Isolate Event Loop Queue] ──> [Notifier Stream Handler]
```

1.  **Serialized D-Bus Events**: D-Bus callbacks (`_deviceAddedSub`, `_agentRequestSub`) are serialized onto the isolate's event loop queue. Memory corruption or data race issues are impossible because Dart code runs sequentially.
2.  **State Locks (`busyAddress`)**: To prevent race conditions from concurrent user actions (e.g., clicking two devices in rapid succession):
    *   When an operation starts, `state.busyAddress` is set to the target device's address.
    *   While `state.busyAddress != null`, other manual connections, disconnections, or deletions are ignored.
3.  **Conflict Resolution on Dialog Overlays**: If a new agent request fires while a pairing dialog is already active:
    *   The newer request overrides the state variable `pairingRequest`.
    *   This forces the UI overlay to rebuild and display the latest authentication prompt, preventing orphaned modal blocks.

---

## 6. Agent D-Bus Interface Contract

The `BlueZClient` registers a profile agent under the `org.bluez.Agent1` interface. Below is the mapping of how the notifier handles each D-Bus method:

| Method name | D-Bus Arguments | Action / Handled Behavior | Implementation Status |
| :--- | :--- | :--- | :--- |
| `RequestPinCode` | `(object device)` | Prompts UI for textual input PIN. Returns string. | **Implemented** |
| `RequestPasskey` | `(object device)` | Prompts UI for numeric input Passkey. Returns uint32. | **Implemented** |
| `DisplayPinCode` | `(object device, string pincode)` | Displays PIN on screen for confirmation. | **Implemented** |
| `DisplayPasskey` | `(object device, uint32 passkey, uint16 entered)` | Displays Passkey on screen for confirmation. | **Implemented** |
| `RequestConfirmation` | `(object device, uint32 passkey)` | Shows passkey on screen. User selects Accept/Reject. | **Implemented** |
| `RequestAuthorization` | `(object device)` | Auto-accepts connections or triggers swap dialog if already connected (collates with connection Changed event). | **Implemented** |
| `AuthorizeService` | `(object device, string uuid)` | Auto-accepts if device is trusted/paired and single-connection is satisfied. | **Implemented** |
| `Cancel` | — | Closes the current UI pairing dialog overlay. | **Implemented** |
| `Release` | — | Releases the agent on BlueZ termination. | **Implemented** |

---

## 7. Security, Trust & Connection Model

*   **Agent Capability Mode**: Registered using `KeyboardDisplay`, allowing both inputting codes (Keyboard) and displaying randomly generated passkeys (Display) for maximum capability support (compatibility with smartphones, audio headsets, and simple keyboards).
*   **Just Works Pairing**: Supported. If a remote device does not require a PIN/Passkey, the agent auto-replies with success under confirmation protocols.
    > [!WARNING]
    > **Security Risk Note**: Just Works pairing offers no Man-in-the-Middle (MITM) protection. For an automotive IVI unit that accesses contact data (PBAP) or messages (MAP), this represents a potential vector. To mitigate this risk, the AGL agent enforces explicit service-level authorization callbacks (`AuthorizeService`) to block unauthorized profile read requests.
*   **Trust Policy (`setTrusted(true)`)**: Automatically invoked post-pairing. This updates the device's DBus property `/org/bluez/dev_XX_XX_XX_XX_XX_XX/Trusted = true`. Once trusted, the device can reconnect to the system (e.g., auto-reconnecting upon entering the vehicle) without prompting the user.
*   **Auto-Reconnect Policy**: Handled natively by the BlueZ daemon. Upon system power-on, the adapter automatically accepts connection requests from pre-authorized/trusted devices.

---

## 8. Single-Connection Constraint & Device Switching

To ensure that only one device is connected at a time, the state controller acts as a gatekeeper. If a second device attempts a connection, a dialog prompts the user to switch devices.

<pre class="mermaid">
sequenceDiagram
    autonumber
    actor User / Remote Device
    participant Page as BluetoothScanContent
    participant PR as BluetoothPairingRequest (Overlay)
    participant N as BluetoothNotifier
    participant BC as BlueZClient
    participant D as BlueZ Device

    Note over User, D: Scenario: Device A is connected. Device B attempts connection.
    
    User->>D: Connect Device B
    D->>BC: D-Bus Connection Event
    BC->>N: Connection changed event (Device B connected)
    Note over N: Detects two connected devices!
    N->>N: Stage Switch: Create pseudo AgentRequest (ID -2)
    N-->>Page: State updated: pairingRequest != null
    Page-->>PR: Render "Switch Bluetooth Device?" Dialog
    User->>PR: Tap "Switch"
    PR->>N: switchToPairingDevice()
    N->>D: Device A (old) -> disconnect()
    D-->>N: Disconnection success
    N->>D: Device B (new) -> connect() (if connection was suspended)
    D-->>N: Connection success
    N->>N: Navigate back to main Bluetooth settings page
</pre>

### Reconciling D-Bus Paths
There are two pathways BlueZ takes during an incoming connection attempt:
1.  **D-Bus Service Authorization (`AuthorizeService`)**: Triggered first on the agent. If another device is already connected, the notifier intercepts this and blocks auto-approval, showing the dialog.
2.  **Connection Property Stream (`Connected = true`)**: Stream subscription `_deviceChangedSub` fires immediately after connection completes at the link layer. If a second device completes link-layer connection (bypass or race), `_trackConnectionChange` detects the dual-connection state, disconnects the incoming device to enforce the constraint, and stages a switch request dialog (using pseudo ID `-2`).

---

## 9. Data Models & Interface Types

### Key Data Structures

#### 1. `BlueZDevice` (Core Wrapper Model)
An abstraction representing a remote Bluetooth device. The state notifier tracks:
*   `address` (`String`): The MAC address of the device.
*   `objectPath` (`String`): The internal D-Bus path (`/org/bluez/hci0/dev_XX...`).
*   `name` / `alias` (`String`): User-friendly naming fields.
*   `paired` / `connected` / `trusted` (`bool`): Native system statuses.
*   `rssi` (`int`): Received Signal Strength Indicator (used for sorting scan lists).

#### 2. `BlueZAgentRequest` (Pairing Event Model)
Encapsulates D-Bus agent requests. Properties:
*   `requestId` (`int`): Unique D-Bus callback identifier.
    *   *Note*: Negative IDs represent simulated state triggers: `-1` for outgoing connection switches, and `-2` for incoming connection switches.
*   `requestType` (`AgentRequestType`): Enum representing Pin, Passkey, Confirmation, or Service Authorization.
*   `devicePath` (`String`): D-Bus path of the requesting device.
*   `passkey` (`int?`): Numerical passcode to display.
*   `pinCode` (`String?`): String passcode to display.

### Device List Sorting Order

1.  **Paired Devices View**: Sorted first by connection state (`connected` devices at the top), then alphabetically by user-friendly `alias` (or fallback `name` / `address`).
2.  **Unpaired Devices View**: Sorted by `rssi` (signal strength) in descending order. This ensures nearby discoverable devices bubble to the top.

---

## 10. System Configurations & Tunables

*   **Scanning Timeout (2 Minutes)**: Hardcoded `Duration(minutes: 2)`. Radio scanning consumes power and creates electromagnetic noise that can interfere with Wi-Fi modules (co-existence interference). Limiting discovery to 2 minutes matches automotive UI guidelines.
*   **Max Visible Devices**: Unlimited. Handled by a lazy-loaded `ListView.separated` to optimize memory usage under heavy environments.
*   **Discovery Guard (500ms Delay)**: Placed during power transitions to allow the Bluetooth controller chip to stabilize its voltage states before listening to command pipes.

---

## 11. Notifier API Public Interface

The public methods exposed by `BluetoothNotifier` (bound to `bluetoothProvider`):

| Method | Parameters | Side Effects | Returns |
| :--- | :--- | :--- | :--- |
| `enterScanMode()` | — | Registers agent, sets discoverable/pairable, starts discovery. | `Future<void>` |
| `exitScanMode({bool timedOut})` | `bool` | Cancels timers, unregisters agent, stops discovery. | `Future<void>` |
| `pairAndConnect(device)` | `BlueZDevice` | Stops discovery, pairs (if needed), trusts, and connects. | `Future<bool>` |
| `disconnect(device)` | `BlueZDevice` | Requests BlueZ to terminate connection. | `Future<void>` |
| `removeDevice(device)` | `BlueZDevice` | Disconnects and unpairs (untrusts/forgets) the device. | `Future<void>` |
| `respondToPairing({required accepted, response})` | `bool`, `String?` | Sends response to D-Bus agent callback. | `Future<void>` |
| `switchToPairingDevice()` | — | Single connection enforcement handler: swaps connections. | `Future<void>` |
| `clearError()` | — | Resets `state.error` to null. | `void` |

---

## 12. Known Limitations & Scope

1.  **Audio Profile Handover**: Hands-Free Profile (HFP) and Advanced Audio Distribution Profile (A2DP) routing is handled by PipeWire/WirePlumber in AGL. This module handles connection at the BlueZ ACL layer, relying on system audio policies to configure routing profiles.
2.  **Bluetooth Low Energy (BLE)**: This module focuses on classic Bluetooth profiles (BR/EDR). BLE advertising or GATT server configurations are out of scope.
3.  **Single Adapter Dependency**: Binds to the first detected controller (`hci0` via `_client.adapters.first`). Multi-adapter configurations are not supported.

---

## 13. Verification & Testing Strategy

### A. Unit Testing
Mock implementations of `BlueZClient` can be used to simulate D-Bus events. The following test verifies that entering scan mode registers the agent and triggers dynamic scanning states:

```dart
test('Initiating scan mode registers agent and starts discovery', () async {
  final mockClient = MockBlueZClient();
  final notifier = BluetoothNotifier.withMockClient(mockClient);

  // Trigger scan mode
  await notifier.enterScanMode();

  // Assertions
  expect(notifier.state.scanning, isTrue);
  expect(notifier.state.scanTimedOut, isFalse);
  verify(mockClient.registerAgent()).called(1);
  verify(mockClient.adapters.first.startDiscovery()).called(1);
});
```

### B. Integration Testing
Simulate pairing scenarios in headless CI using `dbus-broker` and python mock scripts emitting signals to the `org.bluez` path.

### C. Manual Test Matrix

| Scenarios | Step Actions | Expected UI Response |
| :--- | :--- | :--- |
| **Out-of-Scan Request** | Initiate pairing from phone while settings is on main Paired list. | BlueZ auto-rejects; no pairing modal displays. |
| **Active Scan Timeout** | Enter scan screen, wait 2 minutes. | Screen shows "Scan timed out" view with a "Refresh" button. |
| **Swap Connection** | Connect Device B while Device A is connected. | "Switch Bluetooth Device?" dialog displays. Swapping disconnects A, then connects B. |
| **Authentication Cancel** | Click cancel on Passkey verification popup. | Modal dismisses, error gets caught, and list remains intact. |

---

## 14. Implementation Flow Reference

This section merges the detailed Bluetooth technical-flow notes into the main
Bluetooth settings guide so the settings module has one source of truth.

The implementation reference is for maintainers, reviewers, and testers. It
documents the behavior implemented by the Flutter ICS homescreen; it is not a
generic BlueZ tutorial.

Relevant implementation files:

- `lib/data/data_providers/bluetooth_notifier.dart` — state, lifecycle, policy,
  pairing, connection switching, and cleanup.
- `lib/presentation/screens/settings/settings_screens/bluetooth/bluetooth_screen.dart`
  — paired-device page shell.
- `lib/presentation/screens/settings/settings_screens/bluetooth/widgets/bluetooth_content.dart`
  — paired-device list and actions.
- `lib/presentation/screens/settings/settings_screens/bluetooth/bluetooth_scan_screen.dart`
  — scan-page shell.
- `lib/presentation/screens/settings/settings_screens/bluetooth/widgets/bluetooth_scan_content.dart`
  — scan lifecycle and discovered-device actions.
- `lib/presentation/screens/settings/settings_screens/bluetooth/widgets/bluetooth_pairing_request.dart`
  — pairing and device-switch overlay.
- `packages/bluez_native/lib/src/` and `packages/bluez_native/native/src/` —
  Dart/FFI/native bridge to BlueZ.

### Terms

- **Bluetooth page**: either `AppState.bluetooth` (paired-device list) or
  `AppState.bluetoothScan` (scan page), unless a section specifically names one
  of them.
- **External/remote action**: pairing or connection initiated outside the AGL
  UI, typically from a phone's Bluetooth settings.
- **Busy device**: the device whose address equals `state.busyAddress`; it is
  the only device for which an app-initiated operation is currently in progress.
- **Synthetic request**: an app-created `BlueZAgentRequest` with a negative
  request ID. It drives the device-switch dialog and must not be sent back to
  BlueZ.

### Executive Behavior Summary

1. The notifier connects to BlueZ once and registers a `KeyboardDisplay` pairing
   agent for its entire lifetime.
2. The Settings switch controls adapter power. Turning on first attempts
   `rfkill unblock bluetooth`; turning off stops discovery and clears active UI
   operations.
3. The paired-device page lists only paired devices. Connected devices appear
   first, then the remainder alphabetically.
4. The scan page lists only unpaired devices, strongest RSSI first. Discovery
   stops after two minutes and can be restarted with **Refresh**.
5. Selecting a device performs **pair → trust → connect**. The app does not
   render GATT services and does not call `waitForServicesResolved()`.
6. Only one Bluetooth device is intended to remain connected. Connecting another
   device requires an explicit switch confirmation.
7. Remote pairing and connection are constrained by the active page.

### Page and Remote-Action Policy Matrix

| Current app state | Local action from AGL UI | Pairing initiated remotely | Connection initiated remotely |
| :--- | :--- | :--- | :--- |
| Any page other than `bluetooth` or `bluetoothScan` | No Bluetooth device controls are visible. | Rejected. Non-service agent requests are rejected because the app is neither scanning nor operating on that device. | Blocked. `authorizeService` is rejected, and a newly observed external connection is immediately disconnected. |
| Paired-device page (`AppState.bluetooth`) | Paired devices may be connected, disconnected, or removed. | Rejected unless the request belongs to the device currently being operated by the app. Merely opening this page does **not** permit unsolicited new pairing. | An already-paired device may be authorized when no other device is connected. If another device is connected, the app asks whether to switch. |
| Scan page (`AppState.bluetoothScan`) while discovery is active | An unpaired device may be selected; the app pairs, trusts, and connects it. | Allowed to reach the pairing overlay because `state.scanning == true`. The user must confirm or enter the requested PIN/passkey when required. | A paired device may connect. If another device is connected, the app holds the incoming connection and asks whether to switch. |
| Scan page after the two-minute timeout | **Refresh** restarts discovery. | Rejected because `state.scanning == false`, unless it belongs to the current busy device. | The general Bluetooth-page connection rules still apply because the route remains `bluetoothScan`. |

Important distinctions:

- Outside the Bluetooth pages, remote pairing and remote connecting are blocked.
  Service authorization is rejected and a connection that nevertheless appears
  is disconnected.
- The pairing agent remains registered outside the Bluetooth pages specifically
  so the application can enforce this policy.
- The paired-device page permits reconnection of an already-paired device; it
  does not permit unsolicited pairing of a new device.
- A request for the app's current busy device is treated as part of the
  app-initiated operation, not as unsolicited remote activity.

### Bluetooth State Fields

| Field | Meaning |
| :--- | :--- |
| `devices` | Immutable snapshot of all BlueZ devices known to the notifier. |
| `powered` | Current adapter power state. |
| `changingPower` | Prevents concurrent/repeated power changes and disables the Settings switch. |
| `scanning` | True while the adapter is powered and discovery is active. |
| `pairable` / `discoverable` | Observed BlueZ adapter properties. The current app does not set them. |
| `scanTimedOut` | Selects the scan-timeout UI and **Refresh** action. |
| `busyAddress` | Serializes device operations globally and identifies the row showing progress. |
| `operation` | `connecting`, `disconnecting`, `removing`, or `switching`; controls progress text. |
| `pairingRequest` | Current BlueZ agent request or synthetic device-switch request. |
| `error` | One-shot user-facing error; UI shows a snackbar only when `showBluetoothErrors` is enabled, then clears it. |

Derived lists:

- `pairedDevices`: paired only; connected first, then sorted by display name.
- `unpairedDevices`: unpaired only; sorted by RSSI descending.
- Display name fallback: non-empty alias → non-empty name → Bluetooth address.

### Adapter Power Flow

The Settings Bluetooth tile watches `BluetoothState.powered`. The tile cannot
open the Bluetooth page while power is off, and its switch is disabled while
`changingPower` is true.

Turning on:

1. Ignore the request if there is no adapter, power is already on, or a power
   change is active.
2. Set `changingPower = true` and clear the previous error.
3. Best-effort run `rfkill unblock bluetooth`.
4. Call `BlueZAdapter.setPowered(true)`; the package also performs a
   best-effort rfkill unblock.
5. Wait 500 ms and read the adapter state.
6. Publish the result and clear `changingPower`.

Turning off:

1. Stop discovery and cancel the scan timer.
2. Call `setPowered(false)`.
3. Clear any busy operation and pairing overlay.
4. Adapter events also update `powered`, `scanning`, `pairable`, and
   `discoverable`.

Turning the adapter off does not explicitly remove paired devices. BlueZ remains
the source of truth for device objects and pairing records.

### Pairing-Agent Request Handling Details

For normal BlueZ requests (`requestId >= 0`), confirm/reject is returned through
`agentRespond`. For synthetic switch requests (`requestId == -1` or `-2`), no
response is sent to BlueZ.

For agent request types other than `authorizeService`, `cancel`, and `release`,
the request is rejected when both conditions are true:

- discovery is not active; and
- the request is not for `state.busyAddress`.

This blocks a phone from initiating a new pairing while the user is elsewhere in
the app or merely viewing the paired-device page.

`authorizeService` is evaluated in this order:

1. Unknown device path → reject.
2. Request belongs to the busy device → accept as part of the app-initiated
   operation.
3. Current route is not `bluetooth` or `bluetoothScan` → reject.
4. Another device is connected → retain the request and show the switch dialog.
5. Otherwise → accept only if the requesting device is already paired.

### Remote and External Connection Tracking

Every `deviceAdded` and `deviceChanged` event updates `_connectedAddresses`. A
transition from disconnected to connected is considered a new connection.

The disconnect outside the Bluetooth pages is best-effort and asynchronous. The
connection signal is republished immediately after the app removes the address
from its tracking set.

At initialization, if BlueZ already reports multiple connected devices and no
pairing dialog is active, the app stages a switch for the last device in the
collected list. Device ordering comes from BlueZ's snapshot and should not be
treated as a user preference.

### Device-Switch Variants

- **ID `-1` — local pair/connect found an existing connection**: the target is
  already paired and trusted. The dialog says pairing succeeded and asks whether
  to disconnect the current device and connect the target.
- **ID `-2` — external connection detected while another device is active**: the
  incoming target is disconnected first, then the dialog asks whether to replace
  the current connection.
- A real `authorizeService` request with another device connected also uses the
  same switch UI, but retains its non-negative BlueZ request ID.

On **Switch**:

1. Mark the target busy with operation `switching` and disable dialog actions.
2. Disconnect the current device.
3. If this is a real BlueZ request, accept it.
4. Wait up to 3 seconds for a paired-state update when applicable; call `pair()`
   if still unpaired.
5. Set the target trusted if necessary.
6. Wait up to 500 ms for an automatic connection; call `connect()` if still
   disconnected.
7. Publish state and navigate to the paired-device page.

If switching fails, the app rejects the still-pending real request when possible,
cleans up the target, and makes a best-effort attempt to reconnect the previous
device. Rollback failure is logged but does not replace the main switch error.

On **Cancel**:

- A real BlueZ request is rejected and the target is cleaned up.
- Synthetic ID `-1` clears the dialog and restarts scan mode.
- Synthetic ID `-2` clears the dialog; the incoming device was already
  disconnected when the dialog was staged.

### Disconnect and Remove Actions

Disconnect:

- Available only on a connected paired-device row.
- Sets the row operation to `disconnecting`.
- Calls `BlueZDevice.disconnect()` and publishes device/signal state.
- Keeps the BlueZ pairing record and trust state.

Remove:

- Available from the paired-device row's delete control.
- Sets the row operation to `removing`.
- Disconnects first if connected.
- Calls `BlueZAdapter.removeDevice(objectPath)` and removes the device from the
  notifier map.
- Removes the BlueZ device/pairing record; future use requires discovery and
  pairing again.

Only one device operation can run at a time because all actions return early
while `busyAddress` is non-null.

### Failure and Cleanup Behavior

`_cleanupFailedPairing` performs best-effort cleanup:

1. Unless BlueZ already issued `cancel`/`release`, call `cancelPairing()` by
   default.
2. Disconnect the target if it is connected.
3. Log cleanup errors without hiding the original operation error.

Explicit user rejection generally rejects the agent request, cleans up the
target, clears the overlay, and restarts discovery. BlueZ agent cancellation
clears the overlay, avoids redundantly calling `cancelPairing()`, disconnects if
needed, and also attempts to restart discovery.

Errors are stored in `BluetoothState.error`. The Bluetooth page, scan page, and
Settings Bluetooth tile listen for them. Depending on `showBluetoothErrors`, the
message is either shown once in a snackbar or silently cleared.

### Connection Indicator

Whenever devices are published, the notifier calls
`signalsProvider.toggleBluetooth(any known device is connected)`.

This signal represents connection presence, not adapter power. Therefore
Bluetooth may be powered on while the connection indicator is false.

### Important Implementation Limits and Invariants

- The app uses only the first BlueZ adapter.
- The agent is application-lifetime, not scan-page-lifetime.
- Scan mode changes discovery only. It does not make the adapter
  pairable/discoverable or modify `DiscoverableTimeout`.
- The two-minute timer stops discovery; it is unrelated to BlueZ's discoverable
  timeout.
- The intended invariant is at most one connected device.
- All local device operations are globally serialized by `busyAddress`.
- External connections are allowed only while one of the two Bluetooth routes is
  active; outside them they are disconnected.
- Unsolicited new pairing is allowed only during active discovery; opening the
  paired-device page alone is insufficient.
- Already-paired remote devices may reconnect on a Bluetooth page, subject to
  service authorization and device switching.
- Trust is set automatically after successful local pairing and before
  connection.
- GATT service resolution is not part of the homescreen flow.
- Pairable/discoverable state depends on external BlueZ configuration because
  the current app only observes those properties.
- Native connect/disconnect helpers wait for property changes for up to 10/5
  seconds respectively, but return silently if those waits time out after the
  underlying D-Bus call succeeds.

### Verification Checklist

1. With Bluetooth off, the Settings row cannot open and the switch can power the
   adapter on.
2. Opening **Scan for New Device** starts discovery and lists only unpaired
   devices by descending RSSI.
3. After two minutes, discovery stops and **Refresh** starts a new two-minute
   scan.
4. Leaving the scan page stops discovery and clears any pending pairing overlay.
5. Selecting an unpaired device completes pair → trust → connect.
6. Cancelling or failing pairing disconnects/cleans the target and resumes
   discovery when possible.
7. Connecting a second device shows **Switch Device?** and never intentionally
   leaves both devices connected.
8. Cancelling a switch preserves the original connection and leaves the target
   disconnected.
9. A failed switch attempts to restore the original connection.
10. From a non-Bluetooth page, initiate pairing on a phone: the request is
    rejected and no pairing dialog appears.
11. From a non-Bluetooth page, connect from an already-paired phone: service
    authorization is rejected and any observed connection is disconnected.
12. On the paired-device page, attempt new remote pairing without scanning: it
    is rejected.
13. On the paired-device page with no current connection, connect an
    already-paired phone: it may connect.
14. On either Bluetooth page with another device connected, remote connection
    triggers a switch prompt.
15. Disconnect preserves pairing; Remove deletes the BlueZ device record.
16. Adapter power and the connection indicator behave independently.

### Source-of-Truth Note

When this document and code disagree, `BluetoothNotifier` and its current call
sites are the behavioral source of truth. Update this document in the same
change whenever page policy, agent lifetime, timeout behavior, or the
single-connection rule changes.

<style>
  .mermaid {
    background: #ffffff !important;
    border: 1px solid #d8dee9;
    border-radius: 12px;
    color: #111827 !important;
    overflow-x: auto;
    padding: 1rem;
  }

  .mermaid svg {
    display: block;
    height: auto;
    max-width: 100%;
  }
</style>

<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

  mermaid.initialize({
    startOnLoad: true,
    securityLevel: 'loose',
    theme: 'base',
    themeVariables: {
      background: '#ffffff',
      mainBkg: '#eef2ff',
      primaryColor: '#eef2ff',
      primaryBorderColor: '#7c3aed',
      primaryTextColor: '#111827',
      secondaryColor: '#fef3c7',
      tertiaryColor: '#f8fafc',
      lineColor: '#6d28d9',
      textColor: '#111827',
      actorBkg: '#eef2ff',
      actorBorder: '#7c3aed',
      actorTextColor: '#111827',
      actorLineColor: '#7c3aed',
      signalColor: '#374151',
      signalTextColor: '#111827',
      noteBkgColor: '#fef3c7',
      noteBorderColor: '#d97706',
      noteTextColor: '#111827',
      labelTextColor: '#111827',
      loopTextColor: '#111827',
      sequenceNumberColor: '#ffffff',
    },
  });
</script>
