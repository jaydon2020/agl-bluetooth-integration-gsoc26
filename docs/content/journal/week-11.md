---
title: Week 11
description: Progress summary for Week 11 (August 3-9, 2026) of the AGL Bluetooth Integration project.
---

- Implemented and tested native BlueZ media support for Dart and Flutter through
  the [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
  package.

## Status

- **Status**: In progress
- **Timeline**: August 3, 2026 to August 9, 2026

---

## Progress

### 1. Implemented Native BlueZ Media Support

- Added native Dart and Flutter bindings for the main BlueZ media APIs on Linux.
- Used Dart FFI and `sdbus-c++` for the native integration.
- Exposed remote player controls, controller commands, transport information,
  media browsing, and local player registration.

### 2. Tested the Flutter Desktop Example

- Successfully discovered the connected Bluetooth media player in the Flutter
  Linux example.
- Displayed playback state, position, track metadata, media items, and cover art.
- Tested playback controls and media browsing on the Linux desktop environment.

<figure>
  <img src="images/journal/week-11/Screenshot%20From%202026-08-10%2020-31-21.png" alt="Flutter Linux BlueZ media example showing a connected MediaPlayer1 session, playback controls, track metadata, media items, and cover art." />
  <figcaption>BlueZ media session and controls in the Flutter Linux example.</figcaption>
</figure>

- Confirmed that the player view updates when the active track changes.
- Verified updates to the title, artist, position, duration, metadata, and
  artwork.

<figure>
  <img src="images/journal/week-11/Screenshot%20From%202026-08-10%2020-33-45.png" alt="Flutter Linux BlueZ media example showing updated track metadata and cover art for Me Again by Sasha Alex Sloan." />
  <figcaption>Track metadata and cover art updating in the desktop test.</figcaption>
</figure>

### 3. Identified the AGL Media Session Gap

- On the desktop, `mpris-proxy` provides the media session that BlueZ exposes to
  the Flutter example.
- The desktop session makes the remote player, metadata, and cover art available
  for testing.
- The AGL target still needs the equivalent media session to be created and
  registered by the native Flutter application.
- Cover art remains pending on AGL until the native session integration is
  complete, although it works in the desktop test.

## Support and Test Status

| Area | Package support | Test status | Notes |
| --- | --- | --- | --- |
| `MediaPlayer1` discovery and snapshots | Supported | Tested successfully on AGL | |
| Playback controls | Supported | Tested successfully on AGL | |
| Repeat and shuffle | Supported | Tested successfully on AGL | |
| `MediaControl1` | Supported | Tested successfully on AGL | |
| `MediaTransport1` | Supported | Tested successfully on AGL | |
| Media browsing | Supported | Tested successfully on AGL | |
| Track metadata | Supported | Tested successfully on AGL | |
| Cover art | Supported | Pending on AGL | Requires native media-session integration. |

## Next Week Plan

- Create the GSoC midterm report.
- Continue implementing the native MPRIS session in the Flutter application so
  AGL can create and register its media session without relying on
  `mpris-proxy`.
- Validate metadata updates and complete cover-art testing on the AGL target.

## Links

- **Source code**: [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
