---
title: Week 4
description: Progress summary for Week 4 (June 15-21, 2026) of the AGL Bluetooth Integration project.
---

This week focused on completing the Bluetooth connection flow in
`ivi-homescreen`, including paired-device management, discovery, pairing,
connection switching, disconnection, and device removal.

## Status

- **Status**: Completed
- **Timeline**: June 15, 2026 to June 21, 2026

---

## Progress

### 1. Paired Bluetooth Devices

Updated the main Bluetooth page to show paired devices only. Each disconnected
device is displayed with a forget icon, while the currently connected device is
highlighted and includes a **Disconnect** button. The connection logic limits
the system to one active Bluetooth device at a time.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-15-00.png" alt="Bluetooth page showing paired Keychron B6 Pro and WH-CH520 devices with forget icons." />
  <figcaption>Paired devices shown on the main Bluetooth page.</figcaption>
</figure>

### 2. Bluetooth Device Discovery

Implemented the **Scan for New Device** flow. Starting a scan makes the host
pairable and discoverable, starts Bluetooth discovery, and opens a dedicated
page containing unpaired devices only. Devices with a resolved name show that
name, while unnamed devices fall back to their Bluetooth MAC address.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-15-43.png" alt="Scan for New Device page showing an unpaired Pixel 9a, a Huawei watch, and unnamed devices represented by MAC addresses." />
  <figcaption>Unpaired devices discovered during a Bluetooth scan.</figcaption>
</figure>

Selecting a result temporarily blocks further selection and highlights the row
with a **Connecting...** status while BlueZ starts the connection and pairing
process.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-15-48.png" alt="Scan page showing Pixel 9a highlighted with a Connecting status." />
  <figcaption>Selected device entering the connecting state.</figcaption>
</figure>

### 3. Pairing Agent Flow

Integrated the BlueZ pairing-agent request with the homescreen UI. When a
device requires authentication, the app opens a **Bluetooth Pairing Request**
dialog containing the device name, passkey or PIN, instructions, and
**Cancel** and **Confirm** actions.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-15-50.png" alt="Bluetooth Pairing Request dialog for Pixel 9a showing passkey 061383 and Cancel and Confirm buttons." />
  <figcaption>BlueZ pairing request presented as a passkey confirmation dialog.</figcaption>
</figure>

After confirmation, the device is paired, marked as trusted, connected, and
added to the main Bluetooth page. The connected row is highlighted and exposes
the disconnect action.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-16-03.png" alt="Bluetooth page showing Pixel 9a connected and highlighted with a Disconnect button." />
  <figcaption>Pixel 9a paired, trusted, and connected successfully.</figcaption>
</figure>

### 4. Connection Switching

Added handling for incoming pair or connection requests while another device is
already connected. The **Switch Bluetooth Device?** dialog identifies the new
device and warns which active device will be disconnected.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-50-58.png" alt="Switch Bluetooth Device dialog explaining that connecting POCO F6 Pro will disconnect Pixel 9a." />
  <figcaption>Confirmation dialog shown before switching the active Bluetooth device.</figcaption>
</figure>

Choosing **Switch** disconnects the current device, accepts the incoming
request, pairs and trusts the new device when required, and then connects it.
Choosing **Cancel** rejects the request and keeps the current device connected.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-51-27.png" alt="Bluetooth page showing POCO F6 Pro as the connected device while Pixel 9a remains paired." />
  <figcaption>POCO F6 Pro connected after switching from Pixel 9a.</figcaption>
</figure>

### 5. Disconnecting a Device

The **Disconnect** button appears only on the active device row. Disconnecting
keeps the device paired and returns its row to the normal paired state, allowing
it to be connected again later without repeating the pairing process.

<figure>
  <img src="images/journal/week-4/Screenshot%20From%202026-06-22%2020-16-12.png" alt="Bluetooth page showing Pixel 9a retained as a paired device after disconnection." />
  <figcaption>Pixel 9a remains in the paired-device list after disconnection.</figcaption>
</figure>

### 6. Forgetting a Paired Device

Added a forget action to every paired-device row. Selecting the **X** icon opens
a confirmation dialog before removing the device. Confirming the action first
disconnects the device when necessary, removes it from BlueZ's paired devices,
and removes its row from the Bluetooth page. Cancelling leaves the device and
its current connection unchanged.

---

## Next Week's Plan

- **Code Cleanup and Merge Preparation**:
  - Refactor and document the homescreen Bluetooth UI views and pairing agent classes.
  - Clean up the `bluez_media_native` plugin codebase and prepare the merge requests for the upstream repository.
- **Hardware Validation on Raspberry Pi 5**:
  - Deploy the updated `ivi-homescreen` application onto the Raspberry Pi 5 AGL target image.
  - Capture and verify D-Bus, BlueZ, and PipeWire logs during the pairing, connection, and switching sequences to ensure system stability.

---

## Links

- **Active Development Repository**: [bluez_media_native](https://github.com/jaydon2020/bluez_media_native)
- **Issue Tracker**: [AGL Bluetooth Integration - BlueZ_Media Issues](https://github.com/jaydon2020/bluez_media_native/issues)
