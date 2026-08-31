---
title: Week 14
description: Tested the BlueZ MediaItem patch series, hardened cover-art support, and validated initial HFP integration through PipeWire from August 24 to August 30, 2026.
---

This week, I tested George Kiagiadakis's BlueZ patch series for the
`MediaItem1.Play()` crash reported in Week 13 and hardened cover-art retrieval
across the native, Dart, and Flutter layers of `bluez_media_native`.

## BlueZ Patch Testing

I tested the five-patch
[BlueZ player series](https://patchwork.kernel.org/project/bluetooth/list/?series=1149990)
against the media-player failure tracked in
[GitHub issue #5](https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26/issues/5).
The series addresses the original `MediaItem1.Play()` crash and related pending
request defects:

- Avoids the crash when `MediaItem1.Play()` is called without a browsing scope.
- Answers a pending request when its player is destroyed.
- Updates `NumberOfItems` after `SetBrowsedPlayer`.
- Reports `EBUSY` when `Search()` is already busy.
- Adds BlueZ media-player unit tests for these paths.

The AGL build workspace used the
[`test-bluez-media-player-patch`](https://github.com/jaydon2020/agl-yocto-bluez/tree/test-bluez-media-player-patch)
branch of the
[`agl-yocto-bluez`](https://github.com/jaydon2020/agl-yocto-bluez)
repository.

## Cover-Art and MediaItem Hardening

I updated
[`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
to make cover-art retrieval more reliable and expose artwork for browsed media
items as well as the current player track. I then integrated the updated media
and cover-art APIs into `flutter-ics-homescreen` so the AGL Bluetooth media
screen could display the active track, browsed media items, and their artwork
directly on the Raspberry Pi 5 target.

The work completed during the week includes:

- Improved cover-art retrieval for the current track and browsed media items.
- Added reliable OBEX handling, artwork fallbacks, and `MediaItem` support to
  `bluez_media_native`.
- Integrated metadata, playback controls, media browsing, and cover art into
  the `flutter-ics-homescreen` Bluetooth media screen.


<figure>
  <img src="images/journal/week-14/PXL_20260831_091858604.jpg" alt="Full AGL media screen on Raspberry Pi 5 showing the Bluetooth source selected with no Bluetooth media connection." />
  <figcaption>
    Bluetooth selected before a media session was available.
  </figcaption>
</figure>

<figure>
  <img src="images/journal/week-14/PXL_20260831_095432170-cropped.png" alt="Full AGL Bluetooth media screen playing I Ain't Worried by OneRepublic with cover art, metadata, progress, playback controls, and a media item row." />
  <figcaption>
    Active playback with AVRCP metadata and controls plus cover art retrieved
    through OBEX BIP.
  </figcaption>
</figure>

<figure>
  <img src="images/journal/week-14/PXL_20260831_095525431.jpg" alt="Full AGL Bluetooth media screen playing I Ain't Worried by OneRepublic with cover art, metadata, progress, playback controls, and a media item row." />
  <figcaption>
    Active playback with AVRCP metadata and controls plus cover art retrieved
    through OBEX BIP.
  </figcaption>
</figure>

<figure>
  <img src="images/journal/week-14/annotate.jpeg" alt="Annotated AGL Bluetooth media screen mapping cover art to OBEX BIP, metadata and playback controls to AVRCP MediaPlayer1, the browsed list to MediaFolder1 and MediaItem1, and Bluetooth audio streaming to A2DP through PipeWire." />
  <figcaption>
    The current track's cover art, metadata, playback controls, and browsed
    media items annotated with their Bluetooth profiles and BlueZ D-Bus
    interfaces. The host volume control is intentionally not included.
  </figcaption>
</figure>


## HFP Through PipeWire and WirePlumber

The current AGL image uses oFono as its default Hands-Free Profile backend.
While `ofono.service` is running, it claims the HFP role, so PipeWire's
telephony implementation cannot take over the profile. To test HFP through
PipeWire on the Raspberry Pi 5, I first disabled oFono and the monolithic
WirePlumber service. I then restarted PipeWire and the split WirePlumber
services, including the Bluetooth instance. This service switch was required
before the PipeWire HFP path would work:

```
systemctl disable --now wireplumber.service
systemctl mask wireplumber.service
systemctl disable --now ofono.service
systemctl restart pipewire.service
systemctl restart wireplumber@audio.service \
  wireplumber@bluetooth.service \
  wireplumber@policy.service \
  wireplumber@video-capture.service
```

`wireplumber@bluetooth.service` started successfully with the Bluetooth
profile, and `org.pipewire.Telephony` appeared on the system D-Bus. Querying
its object manager exposed the connected Pixel 9a as an audio gateway:

```
/org/pipewire/Telephony/ag1
org.pipewire.Telephony.AudioGateway1
Address = 04:C8:B0:EC:DE:0F
SpeakerVolume = 15
MicrophoneVolume = 15
Codec = 0
State = idle
RejectSCO = false
```

This confirms that HFP through PipeWire and the modular WirePlumber Bluetooth
service is working: the service claimed the profile and registered the phone
through PipeWire's telephony D-Bus API. The `idle` state only indicates that no
call was active when the output was captured. The remaining work is to update
the Yocto recipe so this PipeWire/WirePlumber configuration becomes the default
instead of requiring the services to be switched manually from oFono.


## Next Steps

- Clean up the codebase and prepare merge requests for the Bluetooth audio
  player changes.
- Update the Yocto recipe so the AGL image configures HFP through PipeWire and
  the modular WirePlumber Bluetooth service instead of oFono.
- Investigate and plan the HFP telephony integration in
  `flutter-ics-homescreen`.

## Links

- **AGL build repository**: [`agl-yocto-bluez`](https://github.com/jaydon2020/agl-yocto-bluez)
- **Media integration repository**: [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
- **BlueZ patch series**: [player crash and pending-request fixes](https://patchwork.kernel.org/project/bluetooth/list/?series=1149990)
- **Crash report**: [GitHub issue #5](https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26/issues/5)
