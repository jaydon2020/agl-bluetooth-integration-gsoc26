# BlueZ Media Native Architecture

Status: architecture snapshot for `bluez_media_native` release `v0.3.1`, commit
`2c25cbb5f13b076c2b701c1f6a4081cb085e0551`, verified from upstream on
2026-10-27.

## 1. Goal and scope

`bluez_media_native` is a Linux-only Dart and Flutter FFI package for BlueZ
media APIs. It supplies typed asynchronous objects for remote media playback,
AVRCP browsing, A2DP transports, local player registration and Bluetooth cover
art.

It owns:

- discovery and caching of BlueZ media objects;
- remote player and media-control commands;
- folder search/navigation and media-item operations;
- transport acquisition, release and volume;
- local `Media1` player registration;
- explicit native or MPRIS cover-art retrieval;
- native/Dart lifecycle, event delivery and resource cleanup.

It does not pair devices, choose the platform audio route, decode an acquired
audio stream, implement a Dart-backed local player, or switch cover-art modes
automatically. Pairing belongs to `bluez_native`; audio routing belongs to
PipeWire/WirePlumber or platform policy.

## 2. Release baseline

| Item | Value |
| --- | --- |
| Repository | <https://github.com/jaydon2020/bluez_media_native> |
| Release | `v0.3.1` |
| Commit | `2c25cbb5f13b076c2b701c1f6a4081cb085e0551` |
| Package version | `0.3.1` |
| Dart baseline | `^3.10.1` |
| Native baseline | CMake 3.22, C++23, sdbus-c++, Dart API DL |
| Platform | Linux |

Release `0.3.1` changes the build hook so the consuming environment controls
the architecture and toolchain during cross-compilation. The architecture must
not reintroduce host architecture selection in the package.

## 3. Runtime architecture

```text
Dart or Flutter application
  |
  | typed Futures, cached objects and Streams
  v
BluezMediaClient
  +-- BluezMediaPlayer / BluezMediaControl
  +-- BluezMediaFolder / BluezMediaItem
  +-- BluezMediaTransport
  |
  | versioned C ABI + binary DTOs + Dart ports
  v
libbluez_media_native.so
  +-- native object manager and media proxies
  +-- local player registration
  +-- optional cover-art session manager
  |
  +-- system bus --> org.bluez
  +-- session bus --> org.bluez.obex (native cover-art mode)
  +-- local file --> mpris:artUrl (MPRIS cover-art mode)
```

The native sdbus-c++ connection owns D-Bus event processing. Dart receives
object and property events through Dart API DL ports. Method results are posted
as asynchronous result messages so remote D-Bus work does not block Flutter's
UI isolate.

## 4. D-Bus contract

| Interface | Package responsibility |
| --- | --- |
| `org.bluez.MediaPlayer1` | Playback, seek commands, playback options, status, position, metadata and cover-art identifiers |
| `org.bluez.MediaControl1` | Playback, seek and volume commands plus connected/current-player state |
| `org.bluez.MediaTransport1` | Acquire, try-acquire, release, volume and transport properties |
| `org.bluez.MediaFolder1` | Search, list items, folder changes and folder state |
| `org.bluez.MediaItem1` | Item playback, add-to-now-playing, metadata and item cover art |
| `org.bluez.Media1` | Register and unregister a local player |
| `org.freedesktop.DBus.ObjectManager` | Initial snapshot and live object lifecycle |
| `org.freedesktop.DBus.Properties` | Partial property updates and refreshes |
| `org.bluez.obex.Client1` | Create/remove a native BIP cover-art session |
| `org.bluez.obex.Image1` | Request thumbnail or image content |
| `org.bluez.obex.Transfer1` | Observe completion and cancel cover-art transfers |

BlueZ object paths are authoritative and must not be synthesized. Interfaces
may be absent when the adapter, phone or active profile does not expose them.

## 5. Dart object model

`BluezMediaClient.create()` selects a cover-art mode, initializes Dart API DL,
starts the native client and returns after the initial ObjectManager snapshot is
available. The client exposes read-only snapshots for players, controls,
folders, items and transports plus add/remove streams for each type.

Each wrapper has stable identity for its cached object incarnation, property
getters, a `propertiesChanged` stream and a `refresh()` operation. A removed or
disposed wrapper rejects later work rather than silently targeting a new object
at the same path.

Required ordering:

1. subscribe to lifecycle/property signals;
2. obtain the initial managed-object snapshot;
3. merge any overlapping events;
4. update the Dart cache;
5. publish the corresponding stream event.

Property changes are partial. A refresh or delayed method result must not
overwrite a newer signal update. Owner replacement invalidates stale proxies,
resynchronizes caches and updates `serviceAvailabilityChanged`.

## 6. Media commands and browsing

Player and control methods preserve the remote D-Bus error name and message.
Playback operations do not imply that audio routing or remote player state has
already changed; callers observe the subsequent property update.

Folder searches and listings return cached or newly materialized folder/item
objects. Navigation mutates remote player state, so concurrent navigation must
be serialized by application policy. Metadata is open-ended and unknown keys
must remain representable.

## 7. Transport ownership

`Acquire` and `TryAcquire` return a duplicated file descriptor plus negotiated
read/write MTUs. Dart wraps the descriptor in `BluezMediaAcquiredTransport`.
The caller owns that wrapper and must close it. `close()` releases the local
duplicate; `transport.release()` asks BlueZ to release the transport itself.
Those operations have different ownership effects and must not be conflated.

Volume is a BlueZ transport property. Selecting a speaker, microphone, audio
focus or PipeWire route remains external policy.

## 8. Cover art modes

The mode is explicit and immutable for one client:

| Mode | Contract |
| --- | --- |
| `disabled` | No cover-art session management or retrieval |
| `native` | Reuse or create one matching OBEX BIP session per device; request a thumbnail first and fall back to the preferred image |
| `mpris` | Read the completed local file referenced by `mpris:artUrl` |

Modes never probe for each other and never fall back across modes. Native mode
requires BlueZ experimental media properties and an experimental BIP-capable
`obexd`. MPRIS mode requires `mpris-proxy` and `obexd` on the same user session.

A destination must be absolute and not already exist. Timeouts and incomplete
transfers are cleaned up. The client removes only sessions it owns; an existing
session used through the explicit reuse API remains externally owned.

## 9. Local player registration

`registerPlayer()` and `unregisterPlayer()` manage the BlueZ `Media1`
registration lifecycle. In `v0.3.1` the exported local MPRIS player is
experimental and inert: it is not connected to a Dart audio engine and does not
deliver incoming remote commands to Dart. The registration must not advertise
capabilities the implementation cannot service.

## 10. FFI and lifetime contract

The native library exports a C ABI consumed through generated bindings. All C
entry points must validate handles and inputs, catch C++ exceptions and return
defined status/error results. Native handles are registry-backed and stale
handles cannot name a later allocation.

Wire payloads are bounded binary DTOs. Decode failures, unsupported message
kinds and remote errors must be explicit. Cached native and Dart objects are
retired before their resources are released. `close()` is asynchronous and
idempotent; it stops event delivery, disposes proxies, closes retained file
descriptors and removes only native-owned OBEX sessions.

An isolate finalizer is a safety net, not a substitute for calling `close()`.

## 11. Build, packaging and verification

Dart Native Assets invokes `hook/build.dart`, which builds
`libbluez_media_native.so` with CMake and declares the bundled code asset. The
hook must accept the consumer's target/toolchain and track native source/CMake
inputs so changes invalidate the build.

Release verification consists of:

- Dart analysis and unit tests;
- native CTest, formatting, clang-tidy, ASan/UBSan and coverage;
- codec and corner-case fixtures across C++ and Dart;
- private D-Bus integration tests, owner restart and cache resynchronization;
- handle/proxy disposal and isolate-shutdown tests;
- Native Assets consumer and cross-build tests;
- hardware checks for the BlueZ/phone capabilities claimed by a release.

## 12. Known boundaries

- Linux and BlueZ only.
- Media browsing and cover art depend on remote-device capabilities.
- BlueZ experimental configuration is required for AVRCP cover art.
- Local player registration does not provide a functional Dart audio player.
- The package exposes transport descriptors but does not process PCM/encoded
  audio or choose a system audio route.
