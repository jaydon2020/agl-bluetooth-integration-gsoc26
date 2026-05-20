---
title: AGL Bluetooth Integration
description: Modern Bluetooth integration for AGL using BlueZ, PipeWire, WirePlumber, and Flutter.
---

The AGL Bluetooth integration project brings phone pairing, media audio, and eventually telephony into the modern Flutter-based AGL IVI stack. The goal is to prove that a fully open Linux stack can support the Bluetooth workflows expected from an automotive head unit without depending on legacy AGL application framework services.

## Mentors

| Role | Mentor |
| --- | --- |
| Primary Mentor | George Kiagiadakis, Collabora |
| Secondary Mentor | Joel Winarske, TCNA |
| Backup Mentors | Justin Noel, ICS; Walt Miner, Linux Foundation |

## Motivation

Automotive Grade Linux has moved toward a newer Flutter UI runtime for the IVI homescreen. That makes the platform faster and easier to build on, but the current Flutter stack still needs a native Bluetooth path for everyday in-vehicle use cases:

- Discovering and pairing a phone or headset.
- Trusting and reconnecting known devices.
- Routing A2DP media audio through the vehicle audio stack.
- Exposing AVRCP metadata and playback controls to the media UI.
- Preparing the architecture for HFP calls, PBAP contacts, and MAP messaging.

This project focuses on the core path first: BlueZ for Bluetooth control, PipeWire and WirePlumber for audio routing, and a typed Flutter plugin surface for the AGL homescreen and apps.

## Why Not The Legacy Service?

Older AGL Bluetooth services, including `agl-service-bluetooth`, were built around `afb-daemon` and JSON-over-WebSocket bindings. The modern Flutter IVI runtime does not use that process model, so updating the legacy service would still leave a mismatch between the UI stack and the Bluetooth service interface.

The proposed replacement is a native Flutter plugin that talks to BlueZ over D-Bus from C++. Flutter apps call the plugin through typed Pigeon APIs and consume state through Riverpod providers. This keeps the Bluetooth control path close to the modern homescreen architecture while still using standard Linux services underneath.

## Architecture

The project is organized as three layers.

### Linux Bluetooth And Audio Stack

The system layer provides the services that do the real Bluetooth and audio work:

- BlueZ exposes adapters, devices, pairing agents, media transports, and OBEX profiles over D-Bus.
- PipeWire provides the audio graph used for media and future telephony routing.
- WirePlumber applies session policy so Bluetooth audio nodes can be routed predictably in an IVI environment.
- A dedicated Yocto layer, `meta-agl-bluetooth`, will collect the system dependencies and integration policy needed by the AGL image.

### Native C++ Plugin

The native plugin bridges Flutter to Linux services. The core implementation uses `sdbus-c++` to call BlueZ interfaces and observe D-Bus signals without relying on `afb-daemon`.

Key native modules are expected to include:

- `bluez_manager.cc` for adapter state, device discovery, and connection lifecycle.
- `pairing_agent.cc` for BlueZ agent registration and passkey confirmation flows.
- `avrcp_controller.cc` for media metadata, playback controls, and transport state.
- Future `hfp_session.cc`, `pbap_client.cc`, and `map_client.cc` modules for telephony, contacts, and messaging.

### Flutter And Dart Interface

The Flutter layer exposes a typed API and reactive state:

- Pigeon defines the method contract between Dart and C++.
- Riverpod providers expose adapter state, discovered devices, pairing requests, connection state, and media metadata.
- The settings UI can subscribe to Bluetooth state changes instead of polling the native stack.
- The media player can consume A2DP and AVRCP state through the same provider model used by other AGL Flutter plugins.

## Core Goals

- Create the `meta-agl-bluetooth` Yocto integration layer.
- Implement a native Flutter-to-BlueZ bridge with type-safe APIs.
- Build a Bluetooth settings UI for scanning, pairing, trusting, connecting, and forgetting devices.
- Integrate A2DP and AVRCP support into the media player path.
- Document repeatable validation steps for BlueZ and PipeWire behavior on AGL hardware.

## Stretch Goals

- Add HFP call control and audio routing for the Flutter dialer.
- Add PBAP contact browsing and MAP messaging flows.
- Persist selected Bluetooth state securely where the UX requires it.
- Demonstrate audio ducking and session recovery when media playback and calls overlap.

## Validation Targets

The primary target is Raspberry Pi 5 running an AGL development image. Raspberry Pi 4 can be used as a secondary target when the same BlueZ and audio services are available.

The first validation milestone is intentionally small:

- BlueZ starts and exposes an adapter.
- A phone or headset is discovered.
- The device can be paired, trusted, connected, disconnected, and reconnected.
- A2DP creates PipeWire nodes and audio routes through the expected Bluetooth device.
- AVRCP metadata and control events can be observed where the remote device supports them.

For the first smoke-test flow, see [Verify BlueZ Stack](bluetooth/verify-bluez).
