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
