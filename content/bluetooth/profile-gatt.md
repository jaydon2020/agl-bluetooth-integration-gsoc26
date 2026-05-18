---
title: Profile GATT
description: Notes and smoke-test goals for validating Bluetooth GATT behavior on an AGL target.
---

This guide tracks the Bluetooth GATT work needed for the AGL Bluetooth integration. It is intentionally lightweight until the project has a concrete GATT profile target, but it gives the docs a stable place for profile notes, validation steps, and implementation findings.

## Scope

GATT validation is useful when the AGL target needs to interact with Bluetooth Low Energy peripherals. For this project, the first priority remains classic Bluetooth bring-up through BlueZ, A2DP, and AVRCP. GATT should be treated as an additional profile area unless a specific BLE device becomes part of the project deliverable.

## What To Capture

- Target peripheral model and firmware version.
- Expected services, characteristics, and descriptors.
- Whether the target acts as a GATT client, a GATT server, or both.
- BlueZ D-Bus objects created for the device.
- Any pairing, bonding, or permission requirement before reading characteristics.

## Smoke Test Goals

- The BLE device appears during discovery.
- The device can be paired or connected when required by the peripheral.
- BlueZ exposes expected GATT service and characteristic objects.
- A read-only characteristic can be read successfully.
- A writable characteristic can be written only when the profile allows it.
- Notifications can be enabled and observed when the characteristic supports them.

## Success Criteria

A GATT profile is considered ready for project integration when the expected service map is visible through BlueZ, the required reads and writes work repeatedly after reconnect, and any notification flow survives disconnect and reconnect testing.

## Open Questions

- Which BLE peripheral should be the reference device?
- Does the AGL image need additional BlueZ experimental features for the selected profile?
- Should the Flutter API expose raw GATT primitives or project-specific profile methods?
