# BlueZ Native Tasks

Design contract: [ARCHITECTURE.md](ARCHITECTURE.md).

Baseline: upstream release `v0.3.2`, release commit
`bad7c236c142dc37428dd0e638fa2c9453463399`, reviewed on 2026-10-27.
Checked items are evidenced by the tagged source, tests or changelog. Unchecked
items are documentation or validation follow-ups for a future release.

## Foundation

### T00 - Establish the release contract

- [x] Record the stable release tag and commit.
- [x] Define ownership boundaries for core BlueZ, media, OBEX and telephony.
- [x] Record the Linux, BlueZ, Dart, CMake and native build baselines.

### T01 - Build and package the native library

- [x] Maintain independent static test and shared FFI CMake targets.
- [x] Compile Dart API DL as C and the bridges as C++23.
- [x] Bundle `libbluez_nc.so` through Dart Native Assets.
- [x] Track native sources, headers and CMake inputs in the build hook.
- [x] Restore a missing sdbus-c++ submodule for Git checkouts with a clear
  failure when no Git metadata is available.
- [ ] Verify the release archive and explicit-library fallback on the current
  AGL AArch64 SDK and target image.

## Discovery and lifecycle

### T02 - Connect and build the initial object tree

- [x] Connect to `org.bluez` on the system bus.
- [x] Subscribe to ObjectManager and Properties events.
- [x] Delay `connect()` completion until the initial snapshot is applied.
- [x] Cache adapters, devices, services, characteristics and descriptors.
- [x] Update caches before publishing lifecycle/property events.

### T03 - Protect native lifetime

- [x] Replace raw reusable pointer handles with non-reused registry tokens.
- [x] Retain a shared client context while an admitted C ABI call is running.
- [x] Reject unknown and retired tokens safely.
- [x] Make repeated destruction safe.
- [x] Add Dart regression tests for bogus and retired handles.
- [ ] Add an isolated D-Bus owner-loss/restart suite that proves all cached
  objects become unusable and a fresh client can reconnect cleanly.

## Adapter and device features

### T04 - Implement adapter control

- [x] Read adapter identity and power/discovery state.
- [x] Power adapters and handle Linux rfkill soft blocks.
- [x] Start and stop discovery.
- [x] Apply transport, RSSI and UUID discovery filters.
- [x] Remove devices through Adapter1.

### T05 - Implement device control and pairing

- [x] Cache device identity, RSSI, pairing, connection and service state.
- [x] Connect and disconnect asynchronously.
- [x] Pair and cancel pairing through BlueZ.
- [x] Wait for `ServicesResolved` rather than equating connection with GATT
  readiness.
- [x] Register native pairing-agent support.
- [ ] Document and test every pairing prompt/capability exposed to Dart,
  including cancellation and authorization denial on a private bus.

## GATT

### T06 - Discover the GATT hierarchy

- [x] Link services to devices, characteristics to services and descriptors to
  characteristics.
- [x] Preserve UUIDs, flags, MTU, primary state and cached values.
- [x] Merge partial updates through changed masks.
- [x] Round-trip representative ObjectManager DTOs in native tests.

### T07 - Read and write values

- [x] Read characteristic and descriptor values asynchronously.
- [x] Write characteristic values with response-mode options.
- [x] Write descriptor values.
- [x] Preserve structured BlueZ error names and messages.
- [x] Test empty, large and malformed result payloads.

### T08 - Deliver notifications safely

- [x] Install the property listener before `StartNotify`.
- [x] Confirm `Notifying=true` after the method reply.
- [x] Confirm `Notifying=false` before completing stop cleanup.
- [x] Merge Notifying, MTU and Value changes without dropping fields.
- [x] Emit the value stream only when a value was present in the update.
- [x] Contain unexpected variants without terminating the D-Bus event loop.
- [x] Cover high-frequency notification delivery in native tests.

## ABI and release quality

### T09 - Maintain the wire contract

- [x] Keep matching native and Dart codecs for adapter, device and GATT DTOs.
- [x] Document 32-bit length/count prefixes used by this implementation.
- [x] Version breaking payload changes through the package release.
- [x] Reject unknown message types during Dart decoding.
- [ ] Add an explicit ABI version query and fail-fast compatibility check so a
  manually supplied `BLUEZ_NC_LIB` cannot silently use an older wire layout.

### T10 - Verify and publish

- [x] Run Dart analysis and unit tests.
- [x] Run native tests, clang-format, clang-tidy, ASan and coverage tooling.
- [x] Exercise x86-64 and arm64 Linux CI lanes.
- [x] Provide scan, connect, pair, read, write and notify examples.
- [x] Add and test the Sensirion gadget example without changing library code
  in `v0.3.2`.
- [ ] Update the README dependency example from the historical `^0.1.0`
  constraint to the intended current release.
- [ ] Record a hardware matrix for supported BlueZ versions, adapters, pairing
  modes and notification workloads.
- [ ] Review this checklist and architecture against the next stable tag before
  changing the baseline.
