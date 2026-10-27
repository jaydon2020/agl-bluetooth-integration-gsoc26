# BlueZ Media Native Tasks

Design contract: [ARCHITECTURE.md](ARCHITECTURE.md).

Baseline: upstream release `v0.3.1`, commit
`2c25cbb5f13b076c2b701c1f6a4081cb085e0551`, reviewed on 2026-10-27.
Checked items are evidenced by the tagged source, tests or release notes;
unchecked items are release follow-ups, not claims that the current package is
unusable.

## Foundation

### T00 - Establish the release contract

- [x] Record the immutable release tag and commit.
- [x] Define package ownership and boundaries against `bluez_native`, OBEX and
  platform audio policy.
- [x] Document Linux, Dart, CMake and native dependency baselines.

### T01 - Package and native build

- [x] Build an independent Dart/Flutter FFI package with a CMake native tree.
- [x] Bundle `libbluez_media_native.so` through Dart Native Assets.
- [x] Track native sources and CMake inputs in the build hook.
- [x] Let the consumer select architecture and toolchain for cross-compilation
  (`v0.3.1`).
- [ ] Re-run the release archive through the current AGL SDK and record the
  target ELF architecture, dependencies and runtime loader result.

## Client and discovery

### T02 - Implement client lifecycle

- [x] Create the native client asynchronously and wait for initial readiness.
- [x] Expose explicit cover-art mode selection.
- [x] Make `close()` asynchronous and idempotent.
- [x] Reclaim resources on isolate shutdown as a fallback.
- [x] Preserve D-Bus error details when startup fails.

### T03 - Discover and synchronize media objects

- [x] Cache players, controls, folders, items and transports.
- [x] Publish add/remove and per-object property streams after cache mutation.
- [x] Subscribe before ObjectManager discovery to avoid lost startup signals.
- [x] Merge partial updates without erasing unchanged values.
- [x] Reject calls on disposed proxies and discard stale delayed refreshes.
- [x] Resynchronize after BlueZ service-owner replacement.

## Media features

### T04 - Remote playback and control

- [x] Implement player Play, Pause, Stop, Next, Previous, FastForward and
  Rewind operations.
- [x] Implement repeat and shuffle property changes.
- [x] Implement media-control playback, seek and volume commands.
- [x] Expose player/control snapshots, refresh and property-change streams.

### T05 - AVRCP browsing

- [x] Implement folder search, item listing and folder navigation.
- [x] Implement item playback and add-to-now-playing.
- [x] Preserve open-ended item and track metadata.
- [x] Cover proxy disposal and navigation/refresh corner cases in Dart tests.

### T06 - Media transports

- [x] Implement Acquire, TryAcquire and Release.
- [x] Return duplicated descriptors with negotiated MTUs.
- [x] Provide explicit local descriptor cleanup.
- [x] Implement transport volume and property refresh.
- [ ] Add a documented on-target audio-pipeline example that consumes an
  acquired descriptor without implying the package owns routing policy.

### T07 - Local player registration

- [x] Implement Media1 RegisterPlayer and UnregisterPlayer.
- [x] Serialize registration work and supply required MPRIS properties.
- [x] Avoid advertising unimplemented playback capabilities.
- [ ] Add a Dart command/event bridge before describing the local player as
  functional rather than experimental and inert.

## Cover art

### T08 - Native BIP cover art

- [x] Select native mode explicitly.
- [x] Reuse a matching BIP session or create one owned session per device.
- [x] Request thumbnails first and retain image retrieval fallback.
- [x] Track transfers to completion and preserve terminal errors.
- [x] Clean timeout artifacts and remove only sessions owned by the client.
- [x] Recover after `obexd` restart and reject stale/incomplete transfers.

### T09 - MPRIS cover art

- [x] Select MPRIS mode explicitly without runtime probing.
- [x] Read completed `mpris:artUrl` files without changing image bytes.
- [x] Treat empty proxy files as not ready.
- [x] Keep native and MPRIS modes independent with no implicit fallback.

## Safety and release gates

### T10 - Protect ABI and resource lifetime

- [x] Validate native handles and contain exceptions at the C ABI.
- [x] Prevent delayed updates from reviving disposed proxies.
- [x] Retain acquired transport descriptors until explicit Dart cleanup.
- [x] Test handle lifetime, proxy disposal and isolate shutdown.
- [x] Test codec success, malformed inputs and corner cases in both languages.

### T11 - Verify release quality

- [x] Run Dart analysis and tests in CI.
- [x] Run native unit tests, formatting, clang-tidy and sanitizers.
- [x] Exercise isolated D-Bus startup, updates and owner resynchronization.
- [x] Verify Native Assets resolution from a compiled consumer.
- [ ] Record a repeatable hardware matrix for playback control, browsing,
  transport acquisition and both cover-art modes across supported BlueZ and
  phone versions.
- [ ] Review this checklist and architecture against the next release tag
  before updating the baseline.
