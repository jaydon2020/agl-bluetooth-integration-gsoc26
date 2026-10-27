# BlueZ Native Architecture

Status: architecture snapshot for `bluez_native` release `v0.3.2`, release
commit `bad7c236c142dc37428dd0e638fa2c9453463399`, verified from upstream on
2026-10-27.

## 1. Goal and scope

`bluez_native` is a Linux Dart/Flutter FFI client for the BlueZ system-bus API.
It follows the public object model of `canonical/bluez.dart` while moving D-Bus
work into a C++ sdbus-c++ library and delivering GATT notifications through
Dart API DL.

It owns:

- adapter enumeration, power and discovery;
- discovery filters and device removal;
- device properties, pairing, connection and service resolution;
- GATT service, characteristic and descriptor discovery;
- characteristic/descriptor read and write;
- characteristic notification subscription and delivery;
- native handle, D-Bus and Dart object lifetimes.

It does not implement AVRCP/media, OBEX PBAP/MAP, HFP call control, SCO/audio
routing, or non-Linux Bluetooth stacks. Those belong to the sibling packages
and platform services.

## 2. Release baseline

| Item | Value |
| --- | --- |
| Repository | <https://github.com/jwinarske/bluez_native> |
| Release | `v0.3.2` |
| Release commit | `bad7c236c142dc37428dd0e638fa2c9453463399` |
| Package version | `0.3.2` |
| Dart baseline | `^3.10.0` |
| BlueZ baseline | BlueZ 5.50 or later |
| Native baseline | CMake 3.22, C++23, sdbus-c++, Dart API DL |
| Platform | Linux |

Release `0.3.2` changes examples and tests only; the library behavior described
here includes the handle-lifetime and notification-state fixes delivered in
`0.3.1` and `0.3.0`.

## 3. Runtime architecture

```text
Dart or Flutter application
  |
  | BlueZClient and cached typed objects
  v
Dart FFI facade and binary codec
  |
  | versioned C ABI       ^ Dart_PostCObject_DL events/results
  v                       |
libbluez_nc.so
  +-- registry-backed client context
  +-- ObjectManager cache
  +-- adapter/device/GATT bridges
  +-- pairing agent
  |
  v
system D-Bus --> org.bluez --> adapter/device/GATT objects
```

The native sdbus-c++ connection owns D-Bus event processing. Async D-Bus
method calls deliver results through one-shot Dart ports. Object and property
signals update the native snapshot and are forwarded to the long-lived client
event port.

Characteristic value notifications use `Dart_PostCObject_DL` external typed
data so the payload is not copied into an intermediate Dart buffer before it is
delivered to the receiving isolate.

## 4. BlueZ contract

| Interface | Package responsibility |
| --- | --- |
| `org.freedesktop.DBus.ObjectManager` | Initial adapter/device/GATT snapshot and live lifecycle |
| `org.freedesktop.DBus.Properties` | Partial property updates and explicit property reads |
| `org.bluez.Adapter1` | Power, discovery, discovery filter and device removal |
| `org.bluez.Device1` | Connect, disconnect, pair, cancel pairing and device state |
| `org.bluez.GattService1` | Service identity, device association and primary state |
| `org.bluez.GattCharacteristic1` | Read, write, notify and characteristic state |
| `org.bluez.GattDescriptor1` | Read, write and descriptor state |
| `org.bluez.Agent1` / `AgentManager1` | Pairing interaction and agent registration where required |

The package connects to BlueZ on the system bus. Object paths and interface
presence come from ObjectManager and must not be inferred from Bluetooth
addresses or UUIDs.

## 5. Dart object model

The consumer constructs `BlueZClient`, calls `connect()`, uses cached adapters
and devices, then calls `close()`. `connect()` does not complete until the
initial ObjectManager snapshot sentinel has been received and applied.

The client exposes adapter/device collections and lifecycle/property streams.
Adapters own their discovered devices; devices expose GATT services; services
contain characteristics; characteristics contain descriptors. Parent paths are
derived only where the BlueZ hierarchy makes that relationship authoritative.

Property signals are partial. Native DTOs carry changed masks, and Dart merges
only the fields present in an update. Missing values must not reset cached
state. Collections are mutated before their corresponding stream event is
published.

Retained wrappers may outlive `BlueZClient.close()`. Every operation therefore
validates its native token and local disposed state rather than dereferencing a
captured pointer.

## 6. Adapter and device operations

Adapter discovery filters cover transport, RSSI and UUID constraints. Starting
or stopping discovery is a shared BlueZ operation and may interact with other
processes. Power-on may attempt to clear a Linux rfkill soft block; permission
and platform policy errors remain explicit.

Device Connect, Disconnect and Pair use asynchronous D-Bus calls so Flutter's
isolate remains responsive. `waitForServicesResolved()` observes BlueZ state;
it does not synthesize GATT readiness from connection alone. Pairing behavior
depends on the registered agent and platform authorization.

## 7. GATT operations and notifications

Characteristic and descriptor reads return byte lists. Writes preserve the
selected response mode. Notification startup has a two-part contract:

1. subscribe to relevant property signals before calling `StartNotify`;
2. confirm that `Notifying` becomes true after the method reply.

The stop path similarly confirms `Notifying` becomes false before removing the
listener. A successful D-Bus method reply alone is insufficient because BlueZ
scopes notification sessions to the requesting bus client.

Characteristic updates merge `Value`, `Notifying`, MTU and other changed
fields. The public value stream emits only when an update actually contains a
new value. Unexpected variant types are contained and reported without taking
down the shared event loop.

## 8. FFI wire contract and lifetime

The C ABI uses opaque non-reused tokens resolved through a synchronized
registry. Lookup retains a shared native context for the duration of a call.
Destroy removes the token immediately, while already admitted work may finish
against the retained context. Unknown, retired and double-destroyed tokens are
safe failures/no-ops as defined by the entry point.

Native/Dart DTOs use the package's Glaze-compatible binary encoding. Length and
count prefixes are 32-bit in this implementation. Changed masks version the
meaning of partial property payloads; a native library and Dart package from
incompatible wire revisions must not be mixed.

Every exported C entry point must:

- validate the token and pointer/length inputs;
- copy caller-owned command bytes before returning when work is asynchronous;
- catch C++ exceptions;
- return or post a defined status/error payload;
- avoid holding registry locks across D-Bus waits or teardown joins.

## 9. Build and packaging

`hook/build.dart` builds `libbluez_nc.so` with CMake and publishes it as a
bundled Native Asset. When a Git dependency omitted submodules, the hook may
initialize the pinned sdbus-c++ submodule if a Git checkout is available.
Published archives must already contain the required source.

The build hook tracks C/C++ headers, sources and CMake files. Explicit
`BLUEZ_NC_LIB` loading remains a development/manual-build path; normal
consumers use the declared Native Asset.

## 10. Verification model

The release contains:

- Dart codec, type and handle-lifetime tests;
- native DTO and ObjectManager extraction/round-trip tests;
- adapter filter and operation-result tests;
- high-frequency and large-payload GATT notification tests;
- notify state regression examples;
- formatting, clang-tidy, ASan and coverage scripts;
- CI across Linux distributions and architectures.

Hardware validation must still cover the BlueZ daemon, kernel/adapter, remote
device and authorization policy actually shipped by a target image.

## 11. Known boundaries

- Linux/BlueZ only; macOS and Windows are unsupported.
- The library cannot override rfkill hard blocks or D-Bus policy.
- Service resolution, pairing features and GATT behavior depend on the remote
  device and BlueZ version.
- Media, OBEX and telephony interfaces are intentionally outside this package.
- Release `v0.3.2` documents a package dependency example using an older
  version constraint; consumers should use the intended current release.
