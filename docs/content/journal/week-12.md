---
title: Week 12
description: Progress summary for Week 12 (August 10-16, 2026) of the AGL Bluetooth Integration project.
---

- Integrated Bluetooth media metadata, playback controls, phone volume, and
  direct AVRCP cover-art retrieval into `ivi-homescreen` on AGL.

## Status

- **Status**: Completed
- **Timeline**: August 10, 2026 to August 16, 2026

---

## Progress

### 1. Reviewed Gerrit Feedback for the Bluetooth Settings UI

Review feedback on
[`flutter-ics-homescreen` change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
identified broad `ref.watch(bluetoothProvider)` calls that rebuild widgets when
unrelated Bluetooth state changes, and I will start work on it.

I also revisited the earlier native crash during pairing and disconnection
errors. It was caused by a compiler toolchain and ABI mismatch, so
`bluez_native` needs to be built with Clang to match the Flutter application.

The phone still disconnects automatically immediately after its first pairing.
I reproduced the same behavior with `bluetoothctl`, without the Flutter UI or
native library, which indicates that it is not caused by the application. I
will compare a direct connection with a manual pair, trust, and connect sequence
to isolate the BlueZ behavior.

I also observed that the first pair-and-connect attempt does not establish
AVRCP. After disconnecting and reconnecting the phone, AVRCP and the media
features work correctly. I will test the connection sequence to determine
whether trust, timing, or profile initialization causes the first connection to
miss AVRCP.

### 2. Integrated the Bluetooth Media Player into AGL

- Displayed the current track's cover art, title, artist, album, elapsed time,
  and duration in the AGL media screen.
- Connected the previous, pause/play, and next buttons to the remote Bluetooth
  player.
- Displayed the current shuffle and repeat states.
- Added the phone's media volume to the bottom horizontal volume control. This
  value represents the volume reported by and controlled from the connected
  phone; it is separate from the vertical vehicle audio controls on the left.

<figure>
  <img src="images/journal/week-12/Screenshot%20From%202026-08-17%2021-13-24.png" alt="AGL ivi-homescreen Bluetooth media view paused on Nancy Mulligan by Ed Sheeran from the album Divide (Deluxe), showing the Divide cover art, elapsed time 01:20 of 03:00, previous, pause and next controls, shuffle and repeat states, and the phone volume slider at the bottom." />
  <figcaption>
    Bluetooth playback paused on “Nancy Mulligan” by Ed Sheeran. The screen
    shows the “÷ (Deluxe)” album name, Divide cover art, 01:20 of 03:00
    playback progress, transport controls, shuffle and repeat states, and the
    phone volume along the bottom.
  </figcaption>
</figure>

### 3. Documented the Runtime Requirements

Direct cover-art retrieval without `mpris-proxy.service` still requires:

- `bluetoothd` for pairing, connection, AVRCP, and `MediaPlayer1`.
- `obexd` with BlueZ's experimental Image/BIP API enabled.
- BlueZ experimental features enabled with `-E` or `--experimental`.
- A remote phone that publishes both `MediaPlayer1.ObexPort` and
  `Track.ImgHandle`.

Without `mpris-proxy`, the system does not expose an
`org.mpris.MediaPlayer2` desktop proxy or `mpris:artUrl`. The Flutter
application does not require either one because `CoverArtService` downloads the
image directly.

## Next Week Plan

- Continue working on
  [`flutter-ics-homescreen` change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887).
- Compare BlueZ's direct `Connect` operation with manually handling the
  `Pair` → `Trust` → `Connect` sequence, then determine which approach handles
  the initial connection and AVRCP setup more reliably.

## Links

- **Gerrit review**: [`flutter-ics-homescreen` change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
- **Source code**: [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
