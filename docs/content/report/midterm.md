---
title: Midterm Report
description: Midterm progress report for the AGL Bluetooth Integration GSoC 2026 project.
---

This report covers the community-bonding period and the first twelve project
weeks, from 25 May through 16 August 2026. The work established the native
Bluetooth foundation, delivered the first version of the phone-pairing flow,
and brought A2DP/AVRCP media information and controls into the AGL Flutter
homescreen.

## Project details

| Field | Details |
| --- | --- |
| Contributor | JianDe (Jaydon) |
| Organization | Automotive Grade Linux (AGL) |
| Primary mentor | George Kiagiadakis, Collabora |
| Secondary mentor | Joel Winarske, Toyota Connected North America |
| Project | AGL Bluetooth Integration |
| Midterm period | 25 May–16 August 2026 |

## Goals at the midpoint

| Goal | Midterm state |
| --- | --- |
| Add a Bluetooth settings and pairing flow | Implemented and submitted to AGL Gerrit |
| Add native A2DP and AVRCP access | Core Dart FFI library implemented with BlueZ D-Bus support |
| Integrate Bluetooth media into the homescreen | Metadata, cover art, phone volume, and playback controls integrated |
| Establish reusable native-library boundaries | `bluez_native` and `bluez_media_native` separated from Riverpod application policy |
| Prepare stretch phone features | HFP, PBAP, and MAP retained for the second half of the project |

## Work completed

### Native BlueZ media library

I created
[`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native), a
native Dart and Flutter library backed by `dart:ffi`, C++, `sdbus-c++`, and
BlueZ D-Bus APIs. By the midpoint, it exposed:

- remote `MediaPlayer1` state and playback commands;
- `MediaControl1` and `MediaTransport1` state;
- AVRCP folders, media items, and browsing operations;
- track metadata, position, repeat, shuffle, and phone volume; and
- direct cover-art retrieval through BlueZ OBEX.

This separated native D-Bus ownership from Flutter UI state and established a
reusable package boundary for the rest of the project.

### Bluetooth settings and pairing

The Flutter settings application gained a complete Bluetooth entry point with
adapter state, saved devices, discovery, device details, pairing-agent prompts,
trust, connection switching, disconnection, and device removal. The flow also
introduced a single-active-phone policy so another paired device could not
silently replace the selected phone.

The contribution was submitted as
[Gerrit change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
and tracked in [SPEC-5669](https://lf-automotivelinux.atlassian.net/browse/SPEC-5669).

### Upstream native API work

The homescreen needed BlueZ trust, pairable, and discoverable properties that
were not available through the original package API. I separated those changes
from the application review and opened the focused
[`bluez_native` pull request #6](https://github.com/jwinarske/bluez_native/pull/6).

I also reported the pairing-cancellation crash in
[`bluez_native` issue #4](https://github.com/jwinarske/bluez_native/issues/4).
The investigation traced the failure to a compiler toolchain and ABI mismatch,
which established the requirement to build the native library with a toolchain
compatible with the Flutter application.

### AGL media integration

The AGL media screen could display the connected phone's track title, artist,
album, artwork, elapsed time, duration, shuffle and repeat state, and phone
volume. Previous, play/pause, and next actions were connected to the remote
AVRCP player.

Direct artwork retrieval removed the application's dependency on a desktop
MPRIS proxy. The AGL path instead used `bluetoothd`, `obexd`, BlueZ's
experimental Image/BIP API, and the `MediaPlayer1.ObexPort` and
`Track.ImgHandle` properties exposed by the phone.

## Midterm architecture

<pre class="mermaid">
flowchart TB
  UI[Flutter settings and media UI]

  subgraph Riverpod[Riverpod application state and policy]
    BN[BluetoothNotifier]
    BMN[BluetoothMediaNotifier]
  end

  subgraph Native[Native Dart packages]
    BZ[bluez_native]
    MEDIA[bluez_media_native]
  end

  BLUEZ[BlueZ bluetoothd]
  OBEXD[BlueZ obexd]
  PW[PipeWire and WirePlumber]
  PHONE[Remote Bluetooth phone]

  UI --> BN
  UI --> BMN
  BN --> BZ
  BMN --> MEDIA
  BZ --> BLUEZ
  MEDIA --> BLUEZ
  MEDIA --> OBEXD
  BLUEZ ---|Pairing, A2DP, AVRCP| PHONE
  OBEXD ---|Cover art over OBEX BIP| PHONE
  BLUEZ --> PW
</pre>

## Contribution record at midterm

| Work item | Public reference | Midterm state |
| --- | --- | --- |
| Bluetooth pairing and settings | [Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887) | Open review |
| Pairing and connection task | [SPEC-5669](https://lf-automotivelinux.atlassian.net/browse/SPEC-5669) | Active |
| BlueZ trust and adapter properties | [`bluez_native` PR #6](https://github.com/jwinarske/bluez_native/pull/6) | Upstream contribution |
| Pairing-cancellation crash | [`bluez_native` issue #4](https://github.com/jwinarske/bluez_native/issues/4) | Root cause identified |
| Native media library | [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native) | Active development |

## Challenges and lessons learned

The largest technical challenge was coordinating Flutter, Riverpod, Dart FFI,
native C++, BlueZ D-Bus objects, PipeWire, and phone-side profile behavior.
Clear ownership boundaries became essential: Riverpod owned application policy,
while the native packages owned D-Bus clients and object lifetimes.

The pairing crash also showed that native integration problems are not always
application-logic problems. Toolchain and ABI compatibility must be treated as
part of the architecture when Flutter loads C++ libraries on an AGL target.

Finally, phone capabilities cannot be assumed. Profile publication, AVRCP
availability, browsing support, and artwork metadata vary by device and may
appear only after pairing or reconnection. The application therefore needed
capability-driven behavior and safe fallbacks.

## State at midterm

The project had a working Bluetooth settings flow, an active upstream review,
a reusable BlueZ media library, and AGL media integration. The second half of
the project would focus on completing and upstreaming the media work, improving
service integration, and extending the native architecture toward PBAP
contacts, HFP telephony, SCO audio, and MAP support.
