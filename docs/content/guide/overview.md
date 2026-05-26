---
title: AGL Bluetooth Architecture
navTitle: Architecture Overview
description: Modern Bluetooth integration for AGL using BlueZ, PipeWire, WirePlumber, and Flutter.
---

<div class="report-upcoming-card">
  <p class="report-upcoming-eyebrow">In progress</p>
  <h2>Architecture draft is still being refined</h2>
  <p>
    This page is a pending working draft for the AGL Bluetooth Integration
    architecture. It will be updated as the BlueZ, PipeWire, GStreamer, and
    Flutter integration design becomes clearer.
  </p>
  <p>
    The main technical theme follows George Kiagiadakis' FOSDEM 2025 talk,
    <a href="https://archive.fosdem.org/2025/schedule/event/fosdem-2025-6203-adopting-bluez-in-production-challenges-and-caveats/">Adopting BlueZ in production: challenges and caveats</a>,
    which discusses bringing BlueZ into a production automotive IVI stack and
    the related BlueZ and PipeWire work.
  </p>
</div>

## References

- BlueZ Adapter API: [Adapter API](https://bluez.readthedocs.io/en/latest/adapter-api/)
- BlueZ Device API: [Device API](https://bluez.readthedocs.io/en/latest/device-api/)
- BlueZ Media API: [Media API](https://bluez.readthedocs.io/en/latest/media-api/)
- BlueZ OBEX API: [OBEX API](https://bluez.readthedocs.io/en/latest/obex-api/)
- FOSDEM 2025: [Adopting BlueZ in production: challenges and caveats](https://archive.fosdem.org/2025/schedule/event/fosdem-2025-6203-adopting-bluez-in-production-challenges-and-caveats/)
- PipeWire telephony background: [PipeWire Telephony](https://gkiagia.gr/2025-02-20-pipewire-telephony/)
