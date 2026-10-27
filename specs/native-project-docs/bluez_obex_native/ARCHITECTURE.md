# BlueZ OBEX Native Architecture

Status: design contract for aligning `bluez_obex_native` with the established
`bluez_native` public object model and the `bluez_media_native` package/build
layout. The implementation predates this document, so implemented behavior and
remaining alignment work are distinguished explicitly.

## Implementation issue record

| Finding | Architecture decision | Status |
| --- | --- | --- |
| The package already follows the media repository sequence: Flutter FFI scaffold, `native/`, pinned sdbus-c++, reviewed XML, generated proxies, Dart API DL, codec, C ABI, lifecycle, PBAP and MAP. | Preserve this repository shape and evolve it in place. Do not restart or introduce a shared cross-package runtime. | Implemented |
| Blocking OBEX calls were executed on the caller isolate. | Keep one dedicated Dart worker isolate per client. The native sdbus-c++ event loop remains separate and owns signal delivery. | Implemented |
| Native pointers could become stale after disposal. | Keep non-reused registry tokens at the C ABI and make close/dispose idempotent. | Implemented |
| Service-owner replacement and bus failure could leave apparently usable proxies. | Treat service or bus loss as terminal for one client generation. Clear state, fail work, close streams, and require a fresh client. | Partly implemented; cached identity is still required |
| The public API exposes one broad event stream and creates wrappers on demand. | Match `bluez_native`: constructor plus `connect()`, cached objects, add/remove/change streams, per-object property streams, and explicit `close()`. | Open |
| Filter maps cross FFI as strings and are reconstructed by key-name heuristics. | Replace public untyped maps with profile-specific typed filter/argument DTOs and encode exact D-Bus variants. Keep raw maps internal only where needed for forward compatibility. | Open |
| Generated proxy regeneration removed the checked-in license preambles. | Insert the project license deterministically after generation and verify a byte-for-byte clean tree. | Implemented |
| CI runs native tests but does not run the Dart test suite, and release checks do not prove archive/offline or target packaging. | Add Dart tests, generated binding checks, ABI/export checks, archive rebuild, and target lanes before release. | Open |

## 1. Goal and scope

Provide a Linux Dart library, usable by Flutter applications on desktop Linux
and Automotive Grade Linux, for the BlueZ OBEX client service. The supported
profiles are:

- PBAP phonebook access through `org.bluez.obex.PhonebookAccess1`.
- MAP message access through `org.bluez.obex.MessageAccess1` and
  `org.bluez.obex.Message1`.
- Session and transfer lifecycle through `Client1`, `Session1`, `Transfer1`,
  ObjectManager, and Properties.
- Read-only discovery of paired BlueZ devices on the system bus so callers can
  choose a destination address.

The bundled interface contract contains 21 profile methods and 41 declared
properties across six BlueZ OBEX interfaces. It also includes the two writable
message properties, ObjectManager discovery, Properties changes, exact remote
errors, service-owner tracking, and transfer progress.

This package does not pair devices, manage trust, connect Bluetooth profiles,
parse vCard or bMessage files, render contacts/messages, or configure AGL D-Bus
policy. Those responsibilities remain with `bluez_native`, application code,
and image integration respectively.

| Responsibility | Owner |
| --- | --- |
| Pairing, trust, adapter and device connection | `bluez_native` |
| Media playback and AVRCP | `bluez_media_native` |
| OBEX sessions, PBAP, MAP and transfer state | This package |
| Call control and SCO policy | `pipewire_telephony_native` / WirePlumber |
| vCard, bMessage and attachment parsing | Application or dedicated parser |
| File destination selection, retention and user consent | Application |

## 2. Sibling conventions

This design reuses conventions, not runtime objects or native handles, from the
sibling repositories:

| Reference | Convention adopted here |
| --- | --- |
| `bluez_native/lib/src/bluez_client.dart` | Construct then `connect()`, explicit `close()`, cached children, focused lifecycle streams |
| `bluez_native/lib/src/bluez_device.dart` | Stable object wrappers with cached getters and `propertiesChanged` streams |
| `bluez_native/native/src/bluez_bridge.cpp` | Non-reused handle tokens and explicit native lifetime |
| `bluez_media_native` history and layout | Independent Flutter FFI package, native core/shared targets, XML/codegen, tooling, Native Assets and interface-focused commits |
| `bluez_media_native/lib/src/bluez_media_client.dart` | Initial readiness, service availability, cache-before-notification ordering |
| Existing OBEX implementation | Dedicated worker isolate for blocking calls, session-bus OBEX connection, system-bus device query, simulated backend |

Each package keeps an independent D-Bus connection, event loop, wire contract,
and handle registry. Do not extract a generic D-Bus/FFI framework as part of
this work.

## 3. Runtime architecture

```text
Flutter or Dart application
  | typed Futures and cached PBAP/MAP objects
BlueZObexClient and object wrappers
  | commands                         ^ ordered object/property events
dedicated Dart worker isolate         | ReceivePort
  | versioned C ABI                  | Dart_PostCObject_DL
native client context and token registry
  | blocking profile calls + native sdbus-c++ event loop
  +----------------------+-----------------------+
  | session bus                                  | system bus
org.bluez.obex                                   org.bluez
  |                                              |
OBEX sessions/transfers                          paired device discovery
  |
remote phone PBAP/MAP server
```

The worker isolate serializes blocking OBEX calls so Flutter's UI isolate never
waits on D-Bus or thread teardown. The native connection owns its sdbus-c++
event loop and ObjectManager/Properties subscriptions. One client generation
must never reuse objects or replies from an earlier service owner.

The OBEX service is session-bus scoped. Device discovery is a separate,
short-lived system-bus query. Never use the system-bus BlueZ object path as an
OBEX session path, and never assume both buses have the same owner lifetime.

## 4. Complete D-Bus contract

Destination `org.bluez.obex` is discovered through its current unique owner.
Object paths are returned by BlueZ and must never be synthesized.

### Client and session

| Interface | Methods | Properties |
| --- | --- | --- |
| `Client1` | `CreateSession`, `RemoveSession` | none |
| `Session1` | `GetCapabilities` | `Source`, `Destination`, `Channel`, `PSM`, `Target`, `Root` |

`CreateSession` receives a Bluetooth destination address and an `a{sv}` options
dictionary. Initial supported targets are `pbap` and `map`; unknown targets may
be passed only through an explicitly documented advanced API. Session ownership
is enforced by BlueZ and is tied to the caller's bus connection.

### Transfers

| Methods | Properties |
| --- | --- |
| `Cancel`, `Suspend`, `Resume` | `Status`, `Session`, `Name`, `Type`, `Time`, `Size`, `Transferred`, `Filename` |

A method that starts a transfer returns the transfer object and initial
properties. That reply does not mean the file operation is complete. Completion
is observed through transfer status and progress events. Terminal transfer
states remain observable until BlueZ removes the object.

### Phonebook Access Profile

| Methods | Properties |
| --- | --- |
| `Select`, `PullAll`, `List`, `Pull`, `Search`, `GetSize`, `UpdateVersion`, `ListFilterFields` | `Folder`, `DatabaseIdentifier`, `PrimaryCounter`, `SecondaryCounter`, `FixedImageSize` |

`Select` changes mutable remote session state. Operations on one session are
serialized. The implementation must use BlueZ-supported location and phonebook
values and preserve exact remote errors for unsupported repositories or search
fields.

### Message Access Profile

| Interface | Methods | Properties |
| --- | --- | --- |
| `MessageAccess1` | `SetFolder`, `ListFolders`, `ListFilterFields`, `ListMessages`, `UpdateInbox`, `PushMessage` | `SupportedTypes` |
| `Message1` | `Get` | `Folder`, `Subject`, `Timestamp`, `Sender`, `SenderAddress`, `ReplyTo`, `Recipient`, `RecipientAddress`, `Type`, `Size`, `Status`, `Priority`, `Read`, `Deleted`, `Sent`, `Protected`, `DeliveryStatus`, `ConversationId`, `ConversationName`, `Direction`, `AttachmentMimeTypes` |

`Read` is read/write and `Deleted` is write-only in the bundled XML. Setters use
`org.freedesktop.DBus.Properties.Set` with exact boolean variants. MAP listing
dictionaries may contain additional fields such as `Text` and `AttachmentSize`;
they belong to the listing DTO unless a reviewed BlueZ interface revision proves
they are object properties.

### Standard interfaces

Use ObjectManager at `/` for initial and live object discovery. Subscribe before
publishing readiness, apply `InterfacesAdded`, `InterfacesRemoved`, and
`PropertiesChanged` to the native registry, then notify Dart. Use `GetAll` for
refresh. Preserve invalidated properties as absent rather than replacing them
with empty strings, zero, or false.

## 5. Dart consumer model

The target API follows `bluez_native`:

```dart
final client = BlueZObexClient();
await client.connect();

final session = await client.createSession(
  device.address,
  target: BlueZObexTarget.pbap,
);
await session.phonebook.select(
  location: BlueZPhonebookLocation.internal,
  phonebook: BlueZPhonebook.contacts,
);

final entries = await session.phonebook.list(
  const BlueZPhonebookListFilter(maxCount: 100),
);

await client.close();
```

`connect()` is asynchronous and may be called once. `close()` is asynchronous,
idempotent, and required. A convenience static opener may exist under a distinct
name, but it must use the same lifecycle.

The connected client exposes read-only cached collections and focused streams:

- `sessions`, `sessionAdded`, `sessionRemoved`, `sessionChanged`.
- `transfers`, `transferAdded`, `transferRemoved`, `transferChanged`.
- `messages`, `messageAdded`, `messageRemoved`, `messageChanged`.
- `serviceAvailabilityChanged` and a terminal client state.

Session, transfer, phonebook, message-access, and message wrappers have stable
identity for one object incarnation, cached nullable properties, `refresh()`,
and `propertiesChanged`. Collections are updated before events are emitted.
Removal closes the object's stream and makes later commands fail locally.

Object identity is `(clientGeneration, interface, path, incarnation)`, not path
alone. Reuse of the same path after removal creates a new wrapper. A session's
phonebook and message-access interfaces may share its path but remain separate
interface identities.

Public filters are typed:

- PBAP list/pull filters validate `Offset`/`MaxCount` as unsigned 16-bit values
  and fields as string arrays.
- MAP folder/message filters preserve exact byte, unsigned 16-bit, boolean,
  string, and string-array variants.
- Push arguments validate `Transparent`, `Retry`, and supported charset/type
  values before crossing FFI.

Unknown future dictionary keys may be supported through a clearly named raw
escape hatch; the ordinary API must not infer D-Bus types from key strings.

## 6. Discovery, ordering, and recovery

Startup order is:

1. Allocate a new non-reused client generation and event port.
2. Connect to the session bus and resolve the current `org.bluez.obex` owner.
3. Install owner, ObjectManager, and Properties subscriptions.
4. Fetch the initial managed-object snapshot.
5. Merge signals received during enumeration.
6. Publish complete Dart caches and complete `ready`/`connect()`.

All events from one native client carry a monotonically increasing sequence.
Dart applies them in sequence and updates caches before stream delivery.
Duplicate removals are harmless. Late refreshes or operation replies cannot
revive removed objects.

On service-owner replacement or bus failure, the client becomes terminal:

- reject new commands;
- fail pending commands exactly once;
- clear cached objects, children before parents;
- emit removals and service-unavailable state in order;
- stop and join native resources off the UI isolate;
- close streams without waiting for paused subscribers.

Recovery uses a fresh client and generation. Commands are never replayed
automatically because session mutations, downloads, deletes, and pushes can have
remote side effects.

## 7. C ABI, wire format, and lifetime

Keep ffigen-generated declarations behind a small hand-written Dart bridge. The
C ABI exports only versioned `bluez_obex_*` symbols. Every entry point catches
C++ exceptions and returns a defined result. Validate handles, paths, lengths,
enum ranges, embedded NUL, filter types, and output pointers before dispatch.

The current Glaze-compatible binary DTO format may remain for version 1, but the
protocol must be documented and versioned before adding cache identity and
asynchronous result envelopes. Unknown optional fields are ignored; unknown
message kinds or incompatible versions fail explicitly. Message and allocation
sizes are bounded before allocation.

| Resource | Owner |
| --- | --- |
| FFI input strings and arrays | Dart until the synchronous ABI call returns; native copies anything retained |
| Returned byte buffer | Native allocates; Dart copies and releases with `bluez_obex_free` in `finally` |
| Posted event bytes | `Dart_PostCObject_DL` copies typed data before native storage is released |
| Client token | Dart client; native registry maps it to a shared context until close |
| D-Bus connection, event loop, proxies and registry | Native client context |
| Worker isolate, receive ports, completers and streams | Dart client |

Do not use a process-global pointer as a public handle. Tokens are monotonic and
never reused. Thread-local last-error storage is acceptable only for immediate
synchronous failures on the same worker thread; asynchronous work uses
request-scoped structured errors.

## 8. Errors, files, and privacy

Preserve exact D-Bus error name and message in a typed exception together with
operation and object path. Distinguish invalid input, stale object, closed
client, service unavailable, access denied, timeout/unknown outcome, protocol
decode failure, and remote BlueZ errors.

Download and upload paths are trust boundaries. Require absolute paths in the
public API, reject embedded NUL, do not silently overwrite unless BlueZ's method
contract and caller intent allow it, and report the final filename returned by
the transfer. The package does not parse or retain downloaded contact/message
content.

Default diagnostics redact Bluetooth addresses, contact names, phone numbers,
message subjects and file contents. Log operation, duration, request identity,
object type, and error category without payload values.

## 9. Packaging and AGL deployment

Retain the `bluez_media_native` package shape: one shared library, a static core
only when testing, checked-in reviewed XML/generated proxies, ffigen output, and
a Linux Native Assets hook. Builds must not fetch dependencies from the network.
sdbus-c++ remains pinned as a submodule with license/provenance retained.

Host and target build caches are separate. Cross-builds must use the target
compiler, sysroot, pkg-config and target `libsystemd`; target binaries are never
executed on the host. Any prebuilt path validates ELF machine, SONAME, exact C
ABI exports, runtime dependencies, and absence of unsafe RPATH/RUNPATH.

Native Assets hooks run semi-hermetically and do not inherit ordinary Yocto
`CC`, `CXX`, sysroot, or pkg-config variables. Cross-architecture hook builds
therefore receive an explicit `cmake_toolchain_file` package user-define. The
hook passes it to CMake and enables a guard requiring `CMAKE_CROSSCOMPILING` and
`CMAKE_SYSROOT`. A Yocto recipe that performs the independent native CMake build
instead sets the package `skip_native_build` user-define and injects the verified
target library itself; an ambient environment variable is not the build contract.

AGL policy must permit the application user to reach both the BlueZ system bus
service for device discovery and the user's/system image's OBEX session service.
The image owns service startup and policy. The library does not elevate
privileges or modify D-Bus configuration.

## 10. Repository layout

```text
ARCHITECTURE.md
task.md
interfaces/                 # reviewed BlueZ OBEX XML
native/
  CMakeLists.txt
  include/                  # public ABI and private types/proxies
  src/                      # ABI, client, ObjectManager and profile bridges
  generated/                # checked-in sdbus-c++ proxy headers
  third_party/sdbus-cpp/    # pinned dependency
  test/
lib/
  bluez_obex_native.dart
  src/
    bluez_obex_client.dart
    bluez_obex_session.dart
    bluez_obex_transfer.dart
    bluez_obex_phonebook.dart
    bluez_obex_message_access.dart
    bluez_obex_message.dart
    exceptions.dart
    filters.dart
    internal/               # worker and library loader
    ffi/                    # DTOs, codec and bindings facade
hook/build.dart
scripts/
test/
example/
  phonebook_sync.dart
  message_inbox.dart
  obex_watch.dart
  flutter_phone_message/
docs/                       # API coverage and target verification records
```

Interface classes may remain in fewer files while small; split them when doing
the cached-object alignment, not as a formatting-only change.

## 11. Delivery and verification

The executable work breakdown is [task.md](task.md). Host completion requires:

- `dart format --set-exit-if-changed`, `dart analyze`, and `dart test`.
- CMake build/CTest, clang-format, clang-tidy, ASan/UBSan, and coverage.
- Byte-for-byte proxy and ffigen regeneration.
- Private-bus tests for every method group, property changes, owner replacement,
  bus loss, stale identity, close under load, and malformed messages.
- Native Assets build, exact export inspection, sibling-library coexistence,
  and a metadata-free offline archive rebuild.

Hardware completion additionally requires a versioned record of the AGL image,
BlueZ/obexd versions, controller, phone/OS, PBAP/MAP capabilities, policy user,
session-bus startup, downloads/uploads, transfer cancellation, service restart,
and reconnect. Mock success is never hardware evidence.

## 12. Decisions and open inputs

| Topic | Decision or required input |
| --- | --- |
| Public lifecycle | Align to `bluez_native`: constructor, `connect()`, idempotent `close()` |
| Package/build layout | Align to `bluez_media_native` and retain Native Assets |
| OBEX bus | Session bus; system bus is used only for BlueZ device discovery |
| Blocking calls | Dedicated Dart worker isolate; never block the UI isolate |
| Object identity | Generation + interface + path + incarnation |
| Recovery | Terminal on owner/bus loss; reconnect with a fresh client |
| Filters | Typed profile DTOs with exact D-Bus variants |
| Simulation | Useful for UI/tests, but private-bus native tests are authoritative |
| Target baseline | Record the exact BlueZ/obexd revision supplied by the AGL image before release |
| Hardware | Phone and AGL target access are still required for final acceptance |

This document defines architecture only. It does not claim that open alignment
or hardware tasks have passed.
