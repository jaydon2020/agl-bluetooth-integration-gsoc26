# Bluetooth Patch Set 5 vs Patch Set 6

This document compares patch sets 5 and 6 of
[Gerrit change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887).
The exact comparison is available in the
[PS5 to PS6 interdiff](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887/5..6).

## Revision information

- Patch set 5: `58c66634b506bdade0ea597b629586d6e1687270`
- Patch set 6: `2ce5a77cec61aed021f54100eeb21d98a2c30e84`
- Both patch sets have the same parent commit, subject, Change-Id, author, and
  commit message.
- Interdiff: **15 files changed, 1,060 insertions, and 686 deletions**.
- New file in patch set 6: `bluetooth_demo_content.dart`.

Patch set 6 is a substantial functional and architectural update, not only a
commit-message or Signed-off-by correction.

## 1. Pairing and device-switch sequence

Patch set 5 used a separate switching state and displayed a confirmation
dialog before moving from the connected device to another device.

Patch set 6 removes the switch confirmation and uses this sequence:

1. Unblock the selected device.
2. Mark it trusted.
3. Pair it.
4. Handle the BlueZ passkey or PIN request.
5. Stop scanning and return to the saved-devices page.
6. Disconnect any temporary connection created during pairing.
7. Show the new device as **Connecting...**.
8. Show the old device as **Disconnecting...**.
9. Disconnect the old device.
10. Connect the new device.
11. Block all other paired devices.
12. Update the connection status after the new connection succeeds.

The old and new devices now display their transition states simultaneously
using `busyAddress` and `disconnectingAddress`.

If the new connection fails, patch set 6 performs a best-effort rollback by
reconnecting the previous device.

## 2. Single-connected-device policy

Patch set 5 could stage incoming connections and show a device-switch prompt.

Patch set 6 enforces one active Bluetooth device:

- When a device connects, all other paired devices are blocked.
- When the connected device is manually disconnected, all paired devices are
  unblocked.
- When switching, the target device is unblocked before connecting.
- After switching succeeds, the old device and all other devices are blocked.
- Unexpected external connections are disconnected silently.
- At startup, if multiple devices are already connected, patch set 6 keeps the
  first device, disconnects the rest, and applies the block policy.

Device blocking is applied through the BlueZ `Device1.Blocked` property using
`busctl`.

The `BluetoothOperation.switching` enum value and its switch-specific code were
removed.

## 3. Manual disconnect behaviour

Patch set 5 had a disconnect action but did not require confirmation.

Patch set 6:

- Keeps tapping a connected device row disabled.
- Provides a dedicated **Disconnect** button.
- Displays a confirmation dialog with the title **Disconnect Device?** and the
  message **Disconnect {device name}?**.
- Shows **Disconnecting...** with a circular loader while the request runs.
- Unblocks all paired devices after disconnection.

This prevents an accidental row tap from disconnecting the active device.

## 4. Ten-device pairing limit

Patch set 6 adds:

```dart
const maxPairedBluetoothDevices = 10;
```

The limit is checked:

- Before opening the scan page.
- Before pairing an unpaired device.

When the limit is reached, the scan button opens a **Device Limit Reached**
dialog telling the user to forget a saved device first. The dialog references
`maxPairedBluetoothDevices` instead of hardcoding `10`.

## 5. Device filtering

Patch set 5 exposed all unpaired devices discovered by BlueZ. Unrelated
Bluetooth device IDs could therefore appear and be selected.

Patch set 6 filters unpaired devices using supported profiles or the smartphone
device class.

A device is shown when it advertises **any one** of these profiles:

- A2DP Source
- AVRCP
- HFP Audio Gateway
- PBAP Phonebook Server
- MAP Message Access Server

It is also shown when its Bluetooth Class-of-Device identifies it as a
smartphone. This allows phones that do not advertise audio, contact, or
messaging UUIDs before pairing to remain visible.

Additional behaviour:

- Already-paired devices always remain visible.
- Discovery is limited to BR/EDR transport.
- UUID filtering is performed in Dart instead of passing UUIDs directly to
  BlueZ, preserving the smartphone-class fallback.
- Unsupported unpaired devices cannot enter `pairAndConnect()` even if passed
  to it directly.

## 6. Scanning behaviour

The two-minute scan timeout remains, but patch set 6 improves its lifecycle:

- Discovery only starts while the scan page is active.
- Repeated scan-start calls are idempotent.
- The timer is cancelled and cleared consistently.
- Leaving the scan page stops discovery and clears pairing prompts.
- Reaching the ten-device limit prevents discovery.
- A timed-out scan displays a large **Refresh** button matching the size and
  position of **Scan for New Device**.

The scan page now includes:

- An **Available Devices** header.
- A circular scanning animation.
- Devices sorted by signal strength.
- A **No devices available** empty state.
- Guidance to make the device discoverable.
- A **Connecting...** loader for the selected device.
- Disabled device rows while one connection operation is running.

## 7. Saved-device page UI

Patch set 5 displayed the paired-device list under the generic **Bluetooth**
title without a list section header or explicit empty state.

Patch set 6 adds:

- A **Saved Devices** section header.
- Connected devices sorted first.
- Remaining devices sorted alphabetically.
- An empty-state Bluetooth icon.
- **No saved devices**.
- **Scan for a new device to get started.**
- Separate connecting and disconnecting status handling.
- Dedicated disconnect and forget actions.

The forget confirmation was shortened to:

> You will no longer be paired with {device name}.

## 8. Pairing request UI

Patch set 5 reused the pairing overlay for passkey handling and device-switch
confirmation. It also used synthetic negative request IDs for internal switch
requests.

Patch set 6:

- Removes the switch variant completely.
- Removes synthetic pairing requests and `switchToPairingDevice()`.
- Uses the overlay only for actual BlueZ pairing requests.
- Watches only `pairingRequest` using Riverpod `select`.
- Registers `ref.listenManual` once in `initState`, rather than recreating the
  listener during every build.
- Clears the text controller when a new PIN or passkey input request arrives.
- Responds to BlueZ only when the request requires a response.

The shared dialog now supports a single-action layout, which is used by the
device-limit dialog.

## 9. Native library fallback and demo mode

Patch set 5 did not provide a fallback when `bluez_native` could not
initialize.

Patch set 6 introduces `nativeAvailable`:

- `null` while initializing.
- `true` when BlueZ connects successfully.
- `false` when native initialization fails, including native library or BlueZ
  availability failures.

When the native backend is unavailable:

- The Bluetooth page displays `BluetoothDemoContent`.
- The scan route also displays the demo content.
- The Bluetooth switch uses the in-memory signal state and remains toggleable.
- The demo provides simulated connect, disconnect confirmation, and forget
  behaviour.

The demo **Scan for New Device** button remains a no-op because the demo has no
discovery backend.

## 10. Configuration and error reporting

Patch set 5 added the following configuration:

```toml
show-bluetooth-errors = true
```

It stored errors in `BluetoothState`, and the Bluetooth pages listened for them
to display SnackBars.

Patch set 6 removes:

- `showBluetoothErrorsDefault`.
- `AppConfig.showBluetoothErrors`.
- TOML parsing for `show-bluetooth-errors`.
- Bluetooth error state.
- `clearError()`.
- Bluetooth error SnackBar listeners.

Bluetooth errors are now reported through `debugPrint()` instead of
configuration-controlled SnackBars.

Patch set 6 does not add an `enableBluetooth` or `disableBluetooth`
configuration setting.

## 11. Riverpod architecture

Patch set 5 used:

```dart
StateNotifierProvider<BluetoothNotifier, BluetoothState>
```

Patch set 6 uses:

```dart
NotifierProvider<BluetoothNotifier, BluetoothState>
```

Initialization changes include:

- `ensureInitialized()` was renamed to `connect()`.
- `connect()` caches its initialization `Future`, so repeated calls do not
  initialize BlueZ more than once.
- Startup explicitly calls `bluetoothProvider.notifier.connect()` from
  `main.dart`.
- BlueZ client creation is exposed through `blueZClientFactoryProvider` for
  injection and testing.
- Cleanup is registered with `ref.onDispose`.

State updates go through `_updateState`, which avoids changing state after the
provider has been disposed.

## 12. Background work and rebuild performance

Patch set 6 does not continuously poll Bluetooth state. It uses these BlueZ
event streams:

- `deviceAdded`
- `deviceRemoved`
- `deviceChanged`
- `adapterChanged`
- `agentRequest`

Patch set 6 also reduces rebuilds:

- Bluetooth pages use `select` with only the state members they display.
- Pairing UI watches only `pairingRequest`.
- The Settings Bluetooth tile watches only `powered` and `changingPower`.
- The Wi-Fi tile watches only `isWifiConnected`.
- Device-list state is only republished while a Bluetooth page is active.
- Stream subscriptions, the scan timer, agent registration, discovery, and the
  native client are cleaned up when the provider is disposed.

## 13. Generic SettingsTile refactor

Patch set 5 made the generic `SettingsTile` inspect its title and directly
watch Bluetooth and Wi-Fi providers. This caused the shared widget to contain
Bluetooth-specific behaviour and rebuild for unrelated signal changes.

Patch set 6 makes `SettingsTile` a provider-independent `StatelessWidget` with
these inputs:

- `onTap`
- `switchValue`
- `switchBusy`
- `onSwitchChanged`

Bluetooth and Wi-Fi provider logic is moved into `_BluetoothSettingsTile` and
`_WifiSettingsTile`. Other settings tiles are no longer affected by Bluetooth
state changes.

## File-level summary

| File | Patch set 6 difference |
|---|---|
| `constants.dart` | Removes the Bluetooth error-display default |
| `app_config_provider.dart` | Removes `show-bluetooth-errors` configuration |
| `app_provider.dart` | Renames `updateNested()` to `replace()` |
| `bluetooth_notifier.dart` | Reworks the state machine, filtering, blocking, fallback, and Riverpod integration |
| `signal_notifier.dart` | Adds an idempotent Bluetooth signal setter and removes an unused listener method |
| `main.dart` | Starts Bluetooth initialization once |
| `bluetooth_screen.dart` | Adds native-backend fallback and removes the error listener |
| `bluetooth_scan_screen.dart` | Adds native-backend fallback and removes the error listener |
| `bluetooth_content.dart` | Adds Saved Devices UI, limit dialog, operation statuses, and disconnect confirmation |
| `bluetooth_demo_content.dart` | Adds a standalone in-memory fallback UI |
| `bluetooth_dialog.dart` | Adds a shared confirmation helper and optional cancel action |
| `bluetooth_pairing_request.dart` | Removes the switch prompt and narrows Riverpod listening |
| `bluetooth_scan_content.dart` | Adds available and empty states, loader, and redesigned refresh action |
| `settings_content.dart` | Moves Bluetooth and Wi-Fi provider logic into dedicated wrappers |
| `settings_list_tile.dart` | Makes the shared tile provider-independent and removes dead code |

## Verification

The Bluetooth-specific analyzer check passes:

```text
Analyzing 4 items...
No issues found!
```

A complete repository analysis still reports pre-existing errors in
`storageAPI_UnitsForUsers_test.dart` because `initialize_settings.dart` and
`initializeSettings()` are missing. Those errors are outside the patch set 5
to patch set 6 Bluetooth interdiff.
