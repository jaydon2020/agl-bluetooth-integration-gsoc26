---
title: Bonding Period
description: Progress summary for the May 1-24, 2026 bonding period of the AGL Bluetooth Integration project.
---

I am happy to share my progress for the three-week bonding period for the AGL Bluetooth and audio integration project.

## Status

Status: Completed

Timeline: May 1, 2026 to May 24, 2026

## Progress

- Environment setup:
  - Successfully deployed and configured AGL 21.90.0, `vimba`, on Raspberry Pi 5.
  - Configured remote debugging over SSH for D-Bus and Helvum.
  - Set up Visual Studio remote debugging for the Flutter app.
  - `obexctl` was not installed by default, so I manually installed and verified `obexctl` v5.72 within the AGL image.
- Bluetooth profile validation: validated A2DP, AVRCP, HFP, MAP, and PBAP through D-Bus inspection with D-Spy and `busctl`, plus `bluetoothctl` and `obexctl`.
- Master branch status: `org.pipewire.Telephony` is unavailable because the current PipeWire version is v1.0.9.
- Blog Setup: finalized the project blog structure and integration guides for the Bluetooth validation workflow.

## Next Step

- Next step: begin implementation of `org.bluez.Agent1` to enable robust pairing workflows within `bluez_native_comms`.

## Bluetooth guides

- [Verify BlueZ Stack](guide/verify-bluez): profile index for implemented and prepared BlueZ validation workflows.
- [Profile GAP](guide/verify-bluez/profile-gap): adapter power, discovery, pairing, trust, removal, and discoverable mode.
- [Profile A2DP](guide/verify-bluez/profile-a2dp): media audio connection, BlueZ media transport state, and PipeWire routing checks.
- [Profile HFP](guide/verify-bluez/profile-hfp): hands-free call control through the available telephony stack.
- [Profile PBAP](guide/verify-bluez/profile-pbap): phone book access through BlueZ OBEX and `obexctl`.
- [Profile MAP](guide/verify-bluez/profile-map): message access through BlueZ OBEX and `obexctl`.
- [Install OBEX on Yocto](guide/install-obex-yocto): add `obexctl` and the BlueZ OBEX daemon to an AGL/Yocto image.
- [Remote D-Bus Inspection](guide/remote-dbus): inspect a target system D-Bus from a host PC.
- [Remote PipeWire Inspection](guide/remote-pipewire): inspect the target PipeWire graph from a host PC with Helvum.

## References

- BlueZ native library: [jwinarske/bluez_native](https://github.com/jwinarske/bluez_native)
- FOSDEM 2025 talk: [Adopting BlueZ in production: challenges and caveats](https://archive.fosdem.org/2025/schedule/event/fosdem-2025-6203-adopting-bluez-in-production-challenges-and-caveats/)
