---
title: Week 17
description: Progress summary for Week 17 (September 14-20, 2026) of the AGL Bluetooth Integration project.
---

This week, I submitted the Bluetooth media playback integration for
`flutter-ics-homescreen` and prepared the AGL Yocto layer for OBEX cover-art
support and the BlueZ MediaItem fixes. I also prepared the native telephony
and OBEX support needed for the next homescreen integration phase.

## Status

- **Status**: Completed
- **Timeline**: September 14, 2026 to September 20, 2026
- **Gerrit change**: [Add Bluetooth media playback support](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/32060/1)
- **Yocto branch**: [`media-obex-master`](https://github.com/jaydon2020/agl-yocto-bluez/commits/media-obex-master)

## Progress

### 1. Bluetooth Media Playback in the AGL Homescreen

The homescreen change integrates
[`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native) as a
Bluetooth media source alongside the existing MPD source.

The complete implementation is available in the [AGL Gerrit change 32060](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/32060/1),
**Add Bluetooth media playback support**.

It adds:

- Bluetooth player, transport, metadata, position, repeat, shuffle, and
  connection-state tracking.
- Source selection and coordinated play/pause behavior for Bluetooth, USB, SD,
  and radio playback.
- AVRCP media browsing with selectable `MediaItem1` entries.
- AVRCP cover-art retrieval through OBEX, including retry handling and keeping
  the current artwork visible while a new image loads.
- Serialized playback commands with state refresh after each command and
  recovery from transient BlueZ, folder, media-item, and cover-art failures.

### 2. Yocto OBEX and Experimental BlueZ Support

The [`agl-yocto-bluez`](https://github.com/jaydon2020/agl-yocto-bluez) branch
enables the runtime pieces required by the media integration:

```
PACKAGECONFIG:append = " obex-profiles"
RDEPENDS:${PN}:append = " ${PN}-obex"
```

The BlueZ systemd service is also installed with the experimental feature flag:

```
bluetoothd -E
```

This enables the OBEX profile support needed to retrieve Bluetooth AVRCP
cover art through the BlueZ OBEX service.

### 3. BlueZ MediaItem Fix Patch Series

The Yocto layer includes the five-patch BlueZ media-player series:

1. [`0001-player-fix-mediaitem1-play-without-scope.patch`](https://github.com/jaydon2020/agl-yocto-bluez/blob/media-obex-master/meta-agl-demo/recipes-connectivity/bluez5/files/0001-player-fix-mediaitem1-play-without-scope.patch)
   fixes the
   `MediaItem1.Play()` crash when a player exposes playable Now Playing items
   without a browsing scope. It moves the pending D-Bus request to the media
   player and selects the correct AVRCP scope from the item path.
2. `0002-player-answer-pending-request-on-destroy.patch` answers pending
   requests when the media player is destroyed.
3. `0003-player-update-number-of-items-on-scope-change.patch` updates the item
   count when the browsing scope changes.
4. `0004-player-report-ebusy-from-busy-search.patch` reports `EBUSY` when a
   search is already in progress.
5. `0005-unit-test-media-player-add-media-player-tests.patch` adds regression
   tests for the media-player request and scope behavior.

Together, these patches prevent the MediaItem crash and avoid stalled D-Bus
requests while preserving browsing and playback behavior.

### 4. Native Telephony and OBEX Preparation

I prepared the native support repositories that will be ported into the AGL
homescreen:

- [`pipewire_telephony_native`](https://github.com/jaydon2020/pipewire_telephony_native)
  for PipeWire-based HFP call control and SCO audio routing.
- [`bluez_obex_native`](https://github.com/jaydon2020/bluez_obex_native)
  for native BlueZ OBEX access used by phone-book and related Bluetooth data
  flows.

## Next Steps

- Continue porting telephony and phone-book support into
  `flutter-ics-homescreen`.
- Support flutter library publish review of Gerrit change 32060.
