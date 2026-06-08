---
title: Week 2
description: Progress summary for Week 2 (June 1-7, 2026) of the AGL Bluetooth Integration project.
---

I am happy to share my progress for the second week of the coding period for the AGL Bluetooth and audio integration project. This week was focused on building out the core FFI bridge infrastructure and implementing the primary player control interfaces.

## Status

- **Status**: Completed
- **Timeline**: June 1, 2026 to June 7, 2026

---

## Progress

### 1. C++/Dart FFI Bridge Foundation
Established the core native infrastructure for `bluez_media_native` to achieve non-blocking, asynchronous communication with Dart:
- **D-Bus Lifecycle & Event Loop**: Implemented the D-Bus system bus connection lifecycle and spawned a dedicated background thread to run the `sdbus-cpp` event loop.
- **Serialization Layer**: Integrated a lightweight, compile-time reflection and binary serialization layer using `glaze_meta.h`.
- **Asynchronous Callback Loop**: Integrated Dart Native Ports to post deserialized event notifications and property-changed signals back to Dart isolates asynchronously.

### 2. Player Control Target & Playback State (`org.bluez.MediaPlayer1`)
Exposed full playback state controls and metadata stream capabilities to Dart:
- **Playback State Exposure**: Successfully exposed playback state properties (`Status`, `Position`, and `Track` metadata) from BlueZ to Dart.
- **Standard Controls**: Implemented standard control methods including `Play`, `Pause`, `Stop`, `Next`, and `Previous`.
- **Player Options**: Implemented and tested player-specific controls for `Repeat` and `Shuffle` properties.

### 3. Remote Controller Inputs (`org.bluez.MediaControl1`)
- Implemented handling for volume adjustments and connectivity state hooks driven by remote controller inputs.

### 4. AVRCP Media Browsing (`org.bluez.MediaFolder1` & `org.bluez.MediaItem1`)
- Implemented D-Bus interfaces for AVRCP Media Browsing (`org.bluez.MediaFolder1` and `org.bluez.MediaItem1`).
- *Note*: Since most modern Android music players do not natively support AVRCP Media Browsing over D-Bus, I will figure out an alternate solution.

---

## Next Week's Plan

- **Setup Bluetooth Connect and Pairing UI in `ivi-homescreen`**:
  - Integrate `bluez_native` as a local dependency in `flutter-ics-homescreen`.
  - Replace mock UI logic in `bluetooth_content.dart` with real adapter scanning, dynamic device list retrieval, and connect/disconnect events.
  - Wire up pairing and trust callbacks to leverage Joel's upstream pairing agent implementation.
- **Audio Control and Media Player Integration in `ivi-homescreen`**:
  - Integrate `bluez_media_native` into the homescreen application.
  - Bridge A2DP playback status, track position, and metadata properties from the `org.bluez.MediaPlayer1` FFI interface to the homescreen's media page UI.
  - Wire media control buttons (Play, Pause, Skip, Previous) to invoke native player/control D-Bus calls instead of mock calls.
  - Co-ordinate volume controls with the D-Bus `org.bluez.MediaTransport1` volume property alongside default Kuksa VSS paths.

---

## Links

- **Active Development Repository**: [bluez_media_native](https://github.com/jaydon2020/bluez_media_native)
- **Issue Tracker**: [AGL Bluetooth Integration – BlueZ_Media Issues](https://github.com/jaydon2020/bluez_media_native/issues)
