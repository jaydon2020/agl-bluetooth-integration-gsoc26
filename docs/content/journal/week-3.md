---
title: Week 3
description: Progress summary for Week 3 (June 8-14, 2026) of the AGL Bluetooth Integration project.
---

This week focused on moving the Bluetooth connection work from mock UI behavior
toward a real `ivi-homescreen` flow backed by BlueZ device discovery and
connection state.

## Status

- **Status**: Completed
- **Timeline**: June 8, 2026 to June 14, 2026

---

## Progress

### 1. Bluetooth Settings Entry Point

Integrated the Bluetooth entry point into the AGL settings screen and wired the
Bluetooth switch so the UI can reflect adapter power state changes.

<figure>
  <img src="images/journal/week-3/settings-bluetooth-on.png" alt="AGL settings screen with Bluetooth enabled." />
  <figcaption>Bluetooth enabled from the settings screen.</figcaption>
</figure>

### 2. Bluetooth Device Discovery UI

Implemented the Bluetooth page flow for an empty device list, active scanning,
and discovered device rendering. The UI now shows a clear empty state before
scanning and updates the list as nearby devices are discovered.

<figure>
  <img src="images/journal/week-3/bluetooth-empty-state.png" alt="Bluetooth page showing no devices found and a scan button." />
  <figcaption>Bluetooth page before scanning starts.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-3/bluetooth-scanning-results.png" alt="Bluetooth page showing discovered devices and a stop scanning button." />
  <figcaption>Discovered Bluetooth devices while scanning.</figcaption>
</figure>

### 3. Device Connection State

Added UI states for connecting and connected devices. Selecting a discovered
device now moves through a connecting state before showing the connected device
with a disconnect action.

<figure>
  <img src="images/journal/week-3/bluetooth-connecting.png" alt="Bluetooth page showing POCO F6 Pro in connecting state." />
  <figcaption>Connecting to a discovered Bluetooth device.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-3/bluetooth-connected.png" alt="Bluetooth page showing POCO F6 Pro connected with a disconnect button." />
  <figcaption>Connected device shown at the top of the Bluetooth device list.</figcaption>
</figure>

### 4. Device Details and Saved Devices

Added a device details view that exposes connection status, pairing status,
device address, and signal strength. The Bluetooth page also groups previously
paired devices under the saved devices section so the user can revisit known
devices after scanning.

<figure>
  <img src="images/journal/week-3/bluetooth-device-details.png" alt="Bluetooth device details dialog showing connection, paired status, address, signal, and forget device action." />
  <figcaption>Device detail view for the connected phone.</figcaption>
</figure>

---

## Validation Evidence

- Confirmed that the settings page can enable Bluetooth and navigate into the
  Bluetooth device page.
- Confirmed that the device page shows an empty state before scanning.
- Confirmed that scanning populates nearby device rows, including phones,
  watches, and saved paired devices.
- Confirmed that selecting `POCO F6 Pro` displays a connecting state and then a
  connected state with a disconnect action.
- Confirmed that the details dialog exposes paired state, address, RSSI signal,
  connection toggle, and forget-device action.

---

## Next Week's Plan

- Validate the Bluetooth flow on the AGL image running on Raspberry Pi 5.
- Work on pairing support for device pairing and trust handling.
- Add a new pairing UI for passkey confirmation and entry.
- Continue audio control integration work.

---

## Links

- **Active Development Repository**: [bluez_media_native](https://github.com/jaydon2020/bluez_media_native)
- **Issue Tracker**: [AGL Bluetooth Integration - BlueZ_Media Issues](https://github.com/jaydon2020/bluez_media_native/issues)
