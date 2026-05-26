---
title: Verify Functionality of BlueZ Stack
navTitle: Verify BlueZ Stack
description: Profile index for validating implemented BlueZ profile workflows on an AGL target.
---

Use this page as the table of contents for the BlueZ profile validation guides. Each profile page contains the `bluetoothctl`, `obexctl`, and D-Bus commands needed to check one implemented or prepared Bluetooth workflow on an AGL target.

Start with GAP because every profile depends on a working adapter, discovery, pairing, and trust flow. Then run the profile guides that match the feature being implemented or tested.

## Implemented profile guides

- [Profile GAP](guide/verify-bluez/profile-gap): adapter power, discovery, pairing, trust, bonded-device listing, removal, and discoverable mode.
- [Profile A2DP](guide/verify-bluez/profile-a2dp): Bluetooth media audio connection, BlueZ media transport state, and PipeWire routing checks.
- [Profile HFP](guide/verify-bluez/profile-hfp): hands-free call control through PipeWire telephony when the target image supports it.
- [Profile PBAP](guide/verify-bluez/profile-pbap): phone book access through BlueZ OBEX and `obexctl`.
- [Profile MAP](guide/verify-bluez/profile-map): message access through BlueZ OBEX and `obexctl`.

## Related setup guides

- [Install OBEX on Yocto](guide/install-obex-yocto): add `obexctl` and the BlueZ OBEX daemon to an AGL/Yocto image for PBAP and MAP testing.
- [Remote D-Bus Inspection](guide/remote-dbus): forward a target system bus socket to a PC for inspection with `busctl` or D-Spy.

## References

- BlueZ Adapter API: [Adapter API](https://bluez.readthedocs.io/en/latest/adapter-api/)
- BlueZ Device API: [Device API](https://bluez.readthedocs.io/en/latest/device-api/)
- BlueZ Media API: [Media API](https://bluez.readthedocs.io/en/latest/media-api/)
- BlueZ OBEX API: [OBEX API](https://bluez.readthedocs.io/en/latest/obex-api/)
