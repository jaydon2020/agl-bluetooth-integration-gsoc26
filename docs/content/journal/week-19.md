---
title: Week 19
description: Progress summary for Week 19 (September 28-October 4, 2026) of the AGL Bluetooth Integration project.
---

This week, I completed development of
[`pipewire_telephony_native`](https://github.com/jaydon2020/pipewire_telephony_native)
and finished testing it on the AGL Raspberry Pi 5 target.

## Status

- **Status**: Completed
- **Timeline**: September 28, 2026 to October 4, 2026
- **Origin**: [`pipewire_telephony_native`](https://github.com/jaydon2020/pipewire_telephony_native)

Development and AGL Raspberry Pi 5 testing are complete for the native
PipeWire telephony support used by the HFP integration.

## Native Library Features

`pipewire_telephony_native` provides Flutter/Dart FFI access to PipeWire's
Bluetooth HFP telephony D-Bus API through typed native objects. It supports:

- Automatic session/system-bus discovery, with explicit system-bus selection
  for AGL deployments.
- Discovery and monitoring of audio gateways, calls, and SCO transports.
- Dial, answer, hang up, DTMF tone, and multi-call operations.
- Gateway microphone and speaker volume control plus SCO state reporting.
- D-Bus event streams for gateway, call, transport, and property changes,
  including remote error propagation and reconnect handling.
- Native-asset packaging of the shared library for Dart and Flutter builds.
