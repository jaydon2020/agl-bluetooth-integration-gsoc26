---
title: Week 1
description: First weekly journal entry for the AGL Bluetooth Integration project.
---

This journal page records the first week of the AGL Bluetooth Integration project. Keep entries short, concrete, and tied to evidence from the target image or codebase.

## Focus

- Confirm the hardware target and baseline AGL image.
- Verify BlueZ, PipeWire, and WirePlumber are present on the target.
- Review the existing AGL Bluetooth service history and identify what should not be carried into the Flutter plugin architecture.
- Prepare the first repeatable BlueZ smoke-test flow.

## Progress

- Created the Bluetooth docs section.
- Added the project overview and BlueZ verification guide.
- Defined initial success criteria for adapter bring-up, pairing, trust persistence, A2DP, and AVRCP readiness.

## Notes

The first week should stay focused on proving the base stack before adding UI or plugin abstractions. Once BlueZ behavior is predictable on Raspberry Pi 5, the Flutter plugin API can be shaped around real device state instead of assumptions.

## Next Steps

- Run the BlueZ smoke test on the target board.
- Capture logs for successful and failed pairing flows.
- Decide which profile area should be documented after A2DP and AVRCP.
