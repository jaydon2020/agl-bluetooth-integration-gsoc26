---
title: Week 1
description: Progress summary for Week 1 (May 25-31, 2026) of the AGL Bluetooth Integration project.
---

I am happy to share my progress for the first week of the coding period for the AGL Bluetooth and audio integration project.

## Status

- **Status**: Completed
- **Timeline**: May 25, 2026 to May 31, 2026

---

## Progress

### 1. Mentor Coordination
- **Pairing Agent Coordination (`org.bluez.Agent1`)**: Synced with mentor Joel regarding the pairing agent implementation. Since he is currently halfway through implementing the pairing agent logic, I have paused my work on the agent to avoid duplication of effort and am waiting for his changes to be checked in.

### 2. Repository Initialization (`bluez_media_native`)
I created and initialized a dedicated Flutter package repository, **`bluez_media_native`**, as the active development repo for native A2DP/AVRCP D-Bus integration.

**Initialization Details:**
- **Project Type**: Flutter FFI plugin targeting Linux (`ffiPlugin: true`).
- **Build & Test Configurations**:
  - Configured `CMakeLists.txt` for native C++ compilation using `sdbus-cpp` as the IPC client.
  - Configured `ffigen` (`ffigen.yaml`) for automatic generation of Dart bindings from C++ header files.
  - Set up build folders for address sanitization (`build-asan`) and test coverage (`build-cov`).
  - Added support for asynchronous callbacks from native C++ worker threads back to Dart isolates using `dart_api_dl` ports.

---

## Development Phases & D-Bus Interfaces

With the pairing agent paused, development is entirely focused on implementing the A2DP/AVRCP D-Bus interfaces within Flutter via the new library. Below is the current implementation status and roadmap:

### Phase 1: `org.bluez.Media1` Registration (v0.2)
- **Priority**: High (Core)
- **Status**: `(In-Progress)`
- **Goal**: Implement the `RegisterPlayer` and `UnregisterPlayer` APIs. This manages object path registrations and FFI structures, allowing BlueZ to recognize our application as a player or audio endpoint.
- **D-Bus interface file**: `interfaces/org.bluez.Media1.xml` `(In-Progress)`

### Phase 2: `org.bluez.MediaPlayer1` (v0.3)
- **Priority**: High (Core)
- **Status**: `(In-Progress)`
- **Goal**: Implement the player control target. Exposes playback state (`Status`, `Position`, track metadata) to Dart and implements standard control methods (`Play`, `Pause`, `Stop`, `Next`, `Previous`).
- **D-Bus interface file**: `interfaces/org.bluez.MediaPlayer1.xml` `(In-Progress)`

### Phase 3: `org.bluez.MediaControl1` (v0.4)
- **Priority**: High (Core)
- **Status**: `(In-Progress)`
- **Goal**: Handle volume adjustments and connectivity state hooks from remote controller inputs.
- **D-Bus interface file**: `interfaces/org.bluez.MediaControl1.xml` `(In-Progress)`

### Extended Goals & Future Roadmap
The following D-Bus interfaces are added to the repository for full coverage of the BlueZ stack but are currently not part of the active development phase:
- **`org.bluez.MediaTransport1`**: Managing the underlying audio transport state and volume properties. `(Extended Goal)`
- **`org.bluez.MediaEndpoint1`**: Defining media endpoints for audio streaming. `(Extended Goal)`
- **`org.bluez.MediaItem1`**: Representing media items in the player folder hierarchy. `(Extended Goal)`
- **`org.bluez.MediaFolder1`**: Managing player folder browse menus. `(Extended Goal)`

---

## Links

- **Active Development Repository**: [bluez_media_native](https://github.com/jaydon2020/bluez_media_native)
- **Issue Tracker**: [AGL Bluetooth Integration – BlueZ_Media Issues](https://github.com/jaydon2020/bluez_media_native/issues)
