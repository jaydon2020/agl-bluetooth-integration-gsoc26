---
title: Week 6
description: Progress summary for Week 6 (June 29-July 5, 2026) of the AGL Bluetooth Integration project.
---

This week focused on moving the Bluetooth pairing and connection work into
review, and on turning the remaining native crash report into a clearer
follow-up plan for `bluez_native`.

## Status

- **Status**: Completed
- **Timeline**: June 29, 2026 to July 5, 2026
- **Gerrit change**: [Add pairing UI and bluez_native support](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887?usp=search)
- **Native crash report**: [bluez_native issue #4](https://github.com/jwinarske/bluez_native/issues/4)
- **Follow-up pull request**: [bluez_native pull request #5](https://github.com/jwinarske/bluez_native/pull/5)

---

## Progress

### 1. Submitted Bluetooth Pairing and Connection for Review

Submitted the `flutter-ics-homescreen` Gerrit change for Bluetooth pairing and
connection. The change adds the pairing UI and vendors the `bluez_native`
package so the homescreen can discover, pair, connect, and interact with nearby
Bluetooth devices from the Settings application.

The review includes the homescreen-side integration points needed for the
feature:

- Bluetooth state management in `bluetooth_notifier.dart`.
- Scan routing and the new scan screen/content.
- Pairing request and Bluetooth confirmation dialogs.
- Updates to the Bluetooth settings screen/content widgets.
- App config, provider, route, export, and dependency wiring for the vendored
  `bluez_native` package.

The commit message records that the change was checked with the Flutter
analyzer and manually reviewed through the updated Bluetooth screens and package
integration.

### 2. Addressed Gerrit Review Feedback

The Gerrit review is open and has one blocking comment on the commit metadata:
the temporary `Bug-AGL: AGL-Pairing-UI` tag needs to be replaced with a real
AGL Jira issue name. I will update that before the change can move further
through review.

### 3. Investigated the bluez_native Pairing Cancellation Crash

Tracked the pairing cancellation crash as an engineering issue in
`bluez_native`.

- **Issue**: `flutter-auto` aborts with `SIGABRT` when Bluetooth pairing is
  canceled locally or rejected by the remote device.
- **Environment**: Raspberry Pi 5 running AGL, using `flutter_ics_homescreen`
  and the native `libbluez_nc.so` library.
- **Observed failure**: The application log reports a Wayland connection reset,
  while the core dump points to heap corruption in `libbluez_nc.so` during the
  sdbus-cpp asynchronous reply path.
- **Initial fix attempt**: Opened a `bluez_native` pull request that moved
  device method calls onto worker threads with separate system bus connections,
  caught native exceptions, returned failures through the Dart result port, and
  added `BlueZDevice.setTrusted(bool)`.
- **Review finding**: The likely root cause is not empty error-payload parsing.
  The suspected issue is proxy lifetime management around
  `uponReplyInvoke`, where a `shared_ptr<IProxy>` can be released while the
  async reply handler is still dispatching.
- **Scope impact**: The same callback lifetime pattern appears in
  `gatt_bridge.cpp`, so the fix should cover both device operations and GATT
  operations.
- **Rejected approach**: Detached worker threads introduce teardown, exception,
  ordering, and timeout risks.
- **Follow-up**: Collect exact reproduction steps and sanitizer or allocator
  diagnostics, rework the async proxy lifetime handling in a shared helper, and
  split `setTrusted` into a separate PR with proper Dart-visible error
  reporting.

---

## Next

Next week, I will continue on two tracks.

First, I will follow up on the native pairing crash by collecting better
diagnostics, including exact reproduction steps and sanitizer or allocator-check
output where possible. If the proxy lifetime theory is confirmed, I will rework
the native fix so the async callback slot and proxy lifetime are managed safely
for both device operations and GATT operations. I will also split the
`setTrusted` Dart/native API into a separate change.

Second, I will continue Bluetooth media player control. The UI already exists,
so the Dart library work will focus on media metadata and the BlueZ media
interfaces:

- `org.bluez.MediaPlayer1`, which is the primary focus.
- `org.bluez.MediaControl1`.

---

## Links

- **Gerrit change**: [AGL Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887?usp=search)
- **Crash report**: [jwinarske/bluez_native issue #4](https://github.com/jwinarske/bluez_native/issues/4)
- **Maintainer feedback**: [jwinarske/bluez_native pull request #5 comment](https://github.com/jwinarske/bluez_native/pull/5#issuecomment-4883230294)
