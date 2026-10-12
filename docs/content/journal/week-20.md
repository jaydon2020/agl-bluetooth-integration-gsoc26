---
title: Week 20
description: Progress summary for Week 20 (October 5-11, 2026) of the AGL Bluetooth Integration project.
---

This week, I completed development of
[`bluez_obex_native`](https://github.com/jaydon2020/bluez_obex_native) and
finished testing it on the AGL Raspberry Pi 5 target.

## Status

- **Status**: Completed
- **Timeline**: October 5, 2026 to October 11, 2026
- **Origin**: [`bluez_obex_native`](https://github.com/jaydon2020/bluez_obex_native)

Development and AGL Raspberry Pi 5 testing are complete for the native BlueZ
OBEX support used by the phone-contact integration.

## Native Library Features

`bluez_obex_native` provides Flutter/Dart FFI bindings for BlueZ OBEX sessions,
transfers, phone-book access, and message access. It supports:

- PBAP session creation for phone-book access and MAP sessions for messages.
- Phone-book selection, filtered contact listing, single-contact pulls, and
  complete phone-book transfers.
- Transfer inspection and suspend/resume controls.
- BlueZ `Client1`, `Session1`, `Transfer1`, `PhonebookAccess1`,
  `MessageAccess1`, and `Message1` interfaces through one object-oriented API.
- ObjectManager additions, removals, and property-change events for keeping
  Flutter state synchronized with BlueZ.
- Native-asset packaging, simulated endpoints for hardware-free testing, and
  clean reconnect handling after OBEX service or bus disconnects.
