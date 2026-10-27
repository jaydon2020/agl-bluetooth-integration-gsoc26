# PipeWire Telephony Native: Architecture and Delivery Plan

Status: baseline implementation on `main`; targeted safety fixes verified locally.
Date: 2026-10-25.
Confirmed technology choice: sdbus-c++ and upstream Glaze, with JSON across FFI.
Implementation checklist: [task.md](task.md). This document owns the design
contract; the checklist defines dependencies and acceptance for each deliverable.

## Current release contract (2026-10-25)

The T25 safety follow-up supersedes the earlier positive T24 publication verdict.
The native loader now prefers its declared code asset and only falls back to
fixed executable-relative application locations. PWT_NATIVE_LIB remains an
explicit development/deployment override. SONAME-only, arbitrary mapped-library
sibling and working-directory discovery have been removed. Regression probes
prove both ambient substitution failures on the old code and safe loading after
the fix; intentional overrides and legacy executable-relative libraries work.

The Native Assets hook checks that target architecture equals the running host.
It rejects foreign-target requests before CMake; explicit AGL toolchain/prebuilt
integration remains available with SKIP_NATIVE_BUILD=1. Every completed native
CMake shared library is checked with readelf/nm against the intended machine,
ELF class, SONAME, export and dependency contract, without executing target code.
Validator and export-map changes invalidate the relevant build dependencies.

CI now runs seven native-packaging regressions, resolves Python D-Bus/PyGObject
dependencies explicitly and runs the full package verifier. That verifier reads
pub's selected file list, copies entries without directory recursion, rejects
private planning/cache paths and rebuilds/runs a CLI from those exact selected
source files. An accidentally excluded bridge source or included task.md is a
verification failure. Generated bindings/proxies and relocated Flutter loading
remain checked in the same lane; no automatic publisher is introduced.

Current SDK verification passes 22 focused tests and all ten private-bus CTests;
the minimum SDK passes 21 focused tests with only the unavailable foreign-CLI
flag case skipped. Direct architecture checks still run on both SDKs. Rebuilt
ASan/UBSan and TSAN lanes each pass 5/5. The selected-file package rebuild/load
passes with zero publication warnings. These fixes remain local implementation
changes pending commit; neither planning file may be committed.

The public package contains one documented Dart library. Constructors and cache
mutation helpers used only inside the object model are private; raw ffigen
declarations live at `lib/src/ffi/bindings_generated.dart`. Connection and
incarnation identifiers remain documented read-only diagnostics. The API has
88 documented public elements; moving bindings must update `ffigen.yaml`, the
hand-written facade and the generation consistency check together.

The minimum application SDK remains Flutter 3.38.3 / Dart 3.10.1 for AGL
compatibility. Supported `code_assets` versions are `>=1.0.0 <3.0.0` and `hooks`
versions are `>=1.0.2 <3.0.0`; dependency resolution selects a compatible pair
for the consumer's Flutter SDK pins. Host verification also exercises current
2.x versions on Flutter 3.47.2 / Dart 3.13.2. The unused platform-interface
dependency is removed. The minimum/stable CI matrix guards static compatibility;
hardware and Yocto acceptance still require the separate target gates.

The isolated minimum-SDK check resolves `code_assets` 1.2.1 / `hooks` 2.0.2 and
passes analysis, all 13 focused Dart tests and all ten private-bus CTests,
including the Flutter example. Current stable passes the same suites using
`code_assets` 2.1.0 / `hooks` 2.2.0. Both package trees must run `pub get` before
whole-repository analysis. Stable Dart owns formatting in CI; minimum-SDK
analysis is not coupled to byte-identical output from a different formatter.

Both constructor timeouts must be positive. `operationTimeout` is capped at
30 seconds, the native request deadline. A shorter Dart wait only closes that
request's result port; it does not cancel or replay the D-Bus operation. A
gateway mutation can remain busy until the native request completes or expires.
The caller must treat a timeout as an unknown outcome and inspect state before
deciding whether retrying is safe, especially for Dial. Startup timeout does not
promise to interrupt an in-progress synchronous native discovery call.

`.pubignore` excludes planning files, Git metadata, editor/cache/build output
and compiled binaries. The required native source, pinned dependency source,
license texts, public README, changelog, notices and `doc/agl_build.md` remain in
the archive. `task.md` and this document remain local and untracked per the user's
latest 2026-10-25 clarification and are not pub.dev package content. The release
commit is `20e2ffe`, preserving all other reviewed file contents. Retain complete upstream
sources and tests rather than pruning the 1 MB compressed archive for its score.

`THIRD_PARTY_NOTICES.md` distinguishes original BSD-3-Clause code from derived
Apache-2.0 code and bundled MIT/BSD/LGPL components. sdbus-c++ is linked statically;
its header exception retains LGPL section 6. Application publishers must use an
appropriate redistribution route, preserve notices and allow rebuilding and
replacement of the native library. The accompanying-source route and rebuild
commands are documented without claiming to certify every downstream image.

Publication readiness here means a host-reviewed initial 0.0.1 package. It does
not close T20 target-prebuilt/fetch checks, T22 real-phone/two-way-audio testing,
or T23 full AGL release acceptance. Historical image build results below apply
to their recorded revisions; they are not fresh tests of this release candidate.
The current checklist records final review commands and remaining limitations.

Final host package verification of `573f0fa` passes the clean committed-tree
publish dry run with zero warnings and a 1 MB compressed archive. Required
native dependency source/license files are present and planning files are
excluded. Binding/proxy regeneration, the nine-symbol export contract, relocated
Flutter bundle loading and metadata-free archive compilation also pass. `pana`
reports 150/160 with all 88 public elements documented; its remaining deduction
is the older remote GitHub manifest, pending a separate push. These results
support publishing an initial 0.0.1 package with the stated target limitations;
they do not replace downstream native-license obligations or hardware tests.

Historical implementation status on 2026-09-19: T00-T19 and T21 are complete. T20 now has
a successful real AGL Yocto source cross-build, but remains open for target
prebuilt-path equivalence and normal remote fetch. The package now has
the media-style Flutter FFI build, pinned header-only Glaze and sdbus-c++, the
versioned JSON/C ABI, deterministic owner-thread lifecycle, and root
ObjectManager gateway discovery. Dart publishes an unmodifiable typed gateway
cache and ordered add/remove/change streams. Each gateway has a nested call
ObjectManager whose typed calls also appear in the aggregate client cache.
Startup reconciles queued discovery signals before ready; removal, parent or
owner loss, and same-path reuse invalidate old wrappers before observers are
notified. Gateway and call properties now merge partial signals, expose
invalidation as nullable state, and reconcile with revision-guarded GetAll
requests; unknown call states remain observable. The asynchronous command
contract now uses per-request Dart ports, native identity validation, one
mutation per gateway, finite deadlines, exact remote errors, and terminal
pending-request cleanup. Uncertain native timeouts trigger revision-guarded
gateway and call reconciliation without replay. Dial and DTMF use the shared
asynchronous operation path with the documented ASCII validation at both Dart
and native boundaries; Dial still returns no call object, leaving call identity
to ObjectManager discovery.
Call-scoped Answer/Hangup and gateway-scoped HangupAll also use the shared
operation path and never update cached call state optimistically.
Speaker and microphone setters validate HFP's `0..15` range at both boundaries
and confirm successful no-signal writes through GetAll before retiring the
gateway mutation.
The optional same-path SCO transport has its own incarnation, typed state/codec/
RejectSCO cache, property stream, refresh, Activate and confirmed RejectSCO Set.
Transport interface churn invalidates only the old transport while notifying
the stable parent gateway; startup remains passive.
The five baseline multi-call commands complete the planned 11-method D-Bus
surface. They remain gateway-scoped asynchronous requests and preserve remote
capability failures rather than advertising inferred phone/network support.
Cross-surface lifecycle regressions now cover owner and bus loss, fresh-client
recovery, parent and interface churn, identical-path reuse, mixed pending work,
late replies, closed native ports and paused Dart listeners. Close yields before
emitting its synchronous state transition so listener-triggered cleanup is safe.
An independent dbus-python signal fixture also verifies Dart interpretation of
wrong variant types, changed-plus-invalidated precedence, unknown interfaces and
properties, foreign senders, truncated signal bodies, duplicate removals and
same-path call/transport replacement. Malformed matched signal bodies are
ignored at the native decoding boundary so the next valid signal still applies.
The Linux package builds through a Native Assets CMake hook while retaining the
Flutter plugin CMake path for AGL and legacy integration. The loader resolves
the asset ID or a relocated Flutter bundle and preserves the absolute library
path for isolate-safe teardown. Host packaging checks regenerate bindings and
proxies, restrict exports to the nine-function C ABI, load alongside the three
available sibling libraries, exercise concurrent clients, and rebuild from a
repository-metadata-free archive. ASan/UBSan and TSAN run as separate native
test lanes.
T20 cross-build and prebuilt support is implemented. AGL 21.93.0 successfully
cross-builds the native source for Raspberry Pi 5/AArch64 with target
`libsystemd`, packages the Flutter 3.38.3 application, and includes it in the
complete `agl-ivi-demo-flutter` WIC image. The prebuilt path validates
ELF machine against CMake's target processor, filename/SONAME, exact exports,
direct runtime dependencies and search paths. The source path requires a real
cross toolchain and sysroot and disables executable tests. Host negative checks
pass. Target prebuilt equivalence and normal remote BitBake fetch remain open.
The Flutter exerciser provides explicit phone selection, complete call and SCO
controls, all property displays, remote-error presentation and fresh-client
reconnect. Its private-bus widget integration covers empty, incoming, outgoing,
multiparty, unsupported-operation and service-loss views at desktop and compact
sizes. Linux release packaging includes the native shared library. User guidance
keeps pairing with BlueZ and audio routing/focus with WirePlumber and AGL policy.
Live desktop inspection confirms `wireplumber@bluetooth.service` owns
`org.pipewire.Telephony` on the user bus and publishes the expected gateway and
transport interfaces. The reusable client and examples default to automatic
discovery: test the current process's session bus first, then its system bus.
Explicit scopes remain available, and AGL integrations should select the system
bus when that is the image contract.
Following the sibling media package, standalone examples are split into focused
list, watch, gateway and call executables with shared CLI helpers. The dedicated
full UI remains at `example/flutter_telephony/`. All examples use the same public
typed API; none adds a second backend or bypasses the native lifecycle.

## Implementation Issue Record

The task checklist contains the detailed operational ledger. This table records
the architecture-affecting findings and the changes that established the current
design.

| Finding | Architecture correction | Evidence |
| --- | --- | --- |
| The original branch did not follow the sibling media port's independent history and layering. | Restart from a clean Flutter FFI scaffold and add native structure, XML/codegen, tooling, protocol, lifecycle and interface groups in that order. | `9684b00`, `e6394f1` |
| The sibling BlueZ serializer is custom code, not the selected upstream Glaze library. | Use upstream Glaze JSON as a header-only dependency; vendor only headers, license and provenance. | `dc1ab88` |
| Proxy generation captured the local absolute checkout path. | Invoke `sdbus-c++-xml2cpp` with repository-relative paths so generated headers survive relocation and archive builds. | `86f4822` |
| PipeWire 1.6.6 discovery is hierarchical; the transport shares the gateway path; Dial returns no object; `Call1.Get` appears defective. | Use root and nested ObjectManagers, interface-qualified same-path identities, event-driven call discovery and revision-guarded `GetAll`. | `a59d4d8`, `6fc4144`, `14c4d8d`, `543cab4`, `d7c3766` |
| Cross-isolate/owner-thread shutdown has races around late replies, closed ports, paused listeners and bus/service loss. | Keep one native owner thread, non-reused handles, bounded commands, exactly-once pending retirement and terminal fresh-client recovery; yield before Dart's synchronous closing notification. | `1027a65`, `0fd2af4`, `9e4a762` |
| SONAME lookup alone does not cover relocated Flutter bundles. | Resolve an explicit override, normal loader path, loaded-library siblings and executable-relative bundle locations; verify exact exports and archive rebuilds. | `786af81` |
| Host and target native artifacts can be confused during AGL integration. | Require a real cross toolchain/sysroot for source builds and validate prebuilt ELF machine, SONAME, ABI, dependencies and absence of RPATH/RUNPATH. | `b45a7cc` |
| The desktop example used the system bus although live WirePlumber owned telephony on the user bus. | Select the session bus for desktop operation, based on live `busctl --user` evidence. | `ea4f2a3` |
| A fixed session choice still cannot serve both desktop and system-scoped AGL deployments. | Default to automatic session-first owner detection with system fallback; keep explicit scopes. Selection is fixed for one client lifetime and never crosses Unix user credentials. | `ce2a06c` |
| Removing `DBUS_SESSION_BUS_ADDRESS` alone did not make the same user's session bus unavailable during testing. | Define reachability by actual bus connection, Unix identity and D-Bus policy. Verify fallback with an explicitly unreachable session endpoint; never describe administrator access as an environment-variable bypass. | `ce2a06c` |
| The examples did not mirror the sibling package's focused standalone-Dart executables plus full-Flutter split. | Keep separate list, watch, gateway and call executables with shared helpers, and retain the full Linux UI at `example/flutter_telephony/`. | `49e7834`, `78d51eb` |
| AGL Flutter ships Dart 3.10.1 while the package metadata required Dart 3.13.2. | Set the package and nested example SDK floor to the oldest validated AGL Dart release. | `3132037` |
| The AGL image needs both the nested Flutter app and the independent native CMake target. | Add an AGL app recipe with ordered native cross-build tasks, native-asset injection, debug path remapping and image installation. | `d65becb5` |
| The in-process C++ mock did not independently validate raw signal interpretation, and truncated `PropertiesChanged` bodies could escape the callback decoder. | Exercise the real FFI path with a dbus-python service; ignore malformed bodies while preserving strict sender, interface, path, type, invalidation and identity rules. | `dacace8` |
| The generated scaffold had no project license and did not identify the Apache-2.0 provenance of adapted FFI/loader patterns. | License original project code under BSD-3-Clause, retain Apache-2.0 for derived code, and record `bluez_native`, `appstream_dart`, and sdbus-c++ acknowledgements. | `7b41ab3`, `a3a645c` |
| Plain Dart use still required a manually built library despite the BlueZ siblings providing Native Assets hooks. | Build and register the native library through a Linux CMake hook, resolve it by asset ID, and retain the Flutter CMake/Yocto paths for existing integrations. | `56cee38` |
| Coverage collection parsed test, third-party and system objects and required broad lcov error suppression; coverage and packaging checks were not enforced by CI. | Capture only the two production object targets with source exclusions, keep lcov errors fatal, and run coverage plus host/AGL packaging validation in the Flutter-enabled native CI job. | `0793e3d` |
| Release metadata, archive exclusions, public API boundaries and generated-library location were unfinished. | Finalize the pubspec/changelog, use `doc/`, exclude internal files with `.pubignore`, hide construction/cache mutation and generate bindings below `lib/src/ffi/`. | T24 / I23-I25 |
| Dart accepted reply waits beyond the native 30-second limit. | Validate positive startup/operation timeouts, cap the operation wait, and document late remote completion and unknown outcomes. | T24 / I26 |
| Raising the SDK minimum during cleanup would exclude the documented AGL baseline. | Preserve Flutter 3.38.3/Dart 3.10.1 and accept compatible hook majors; test minimum and stable SDK compatibility. | T24 / I27 |
| Native static-link redistribution and CI release checks lacked explicit guidance. | Add third-party notices/rebuilding guidance, correct CI formatting paths and run focused hook/codec tests. | T24 / I28-I29 |

Unresolved validation is explicit rather than hidden implementation work. The
AGL source cross-build and image integration pass, but the target prebuilt path
and normal remote fetch still need reproducible checks. No connected target and
consented phone/network setup is available, so T22 hardware verification remains
open. The target must also establish whether its PipeWire build patches the
apparent 1.6.6 `Call1.Get` defect. Image-build checks must not be presented as
board, D-Bus policy, call-flow or audio results.

## 1. Goal and Scope

Provide a Linux Dart library, usable by Flutter applications on Automotive Grade
Linux (AGL), covering every native PipeWire telephony method and property in the
PipeWire 1.6.6 baseline. The vehicle is the Bluetooth HFP Hands-Free unit (HF);
the connected phone is the Audio Gateway (AG).

Completion means all 11 native methods, all 11 properties including the three
writable properties, object discovery, live changes, error propagation, and
service lifecycle handling are implemented and verified. It does not mean every
phone or mobile network supports every multi-call operation. Later PipeWire
versions require an explicit API comparison and compatibility test.

The target stack described in the supplied notes is AGL Vimba development,
BlueZ 5.86, PipeWire 1.6.6, and WirePlumber 0.5.14 with split system services.
These are the documented target versions, not versions verified on a connected
device during this design exercise.

| Responsibility | Owner |
| --- | --- |
| Pairing, trust, Bluetooth profile connection | BlueZ, accessed through `bluez_native` |
| HFP commands and SCO audio transport | PipeWire native HFP backend |
| Call control, gateway/call state, transport control | This package via `org.pipewire.Telephony` |
| Vehicle microphone/speaker links and audio focus policy | WirePlumber and AGL integration |
| Music playback/control | `bluez_media_native` |
| Phonebook, contacts and message retrieval | `bluez_obex_native` |
| Phone selection, contact matching, dialer UI and user consent | Flutter application |
| SIM/modem telephony | Separate oFono integration |

This library does not open SCO file descriptors, process PCM, register HFP
profiles, own the telephony service name, or change system configuration.
Bluetooth call audio stays outside Dart and outside the JSON channel.

The `org.ofono.*` compatibility aliases are outside the initial native API scope.
Their `GetModems`, `GetCalls`, and `GetProperties` discovery functions are covered
functionally by standard ObjectManager and Properties calls. Do not silently
switch to `org.ofono`: it may be a real cellular service on the same AGL image.

## 2. Evidence and Existing Conventions

The design was grounded in the supplied [AGL call guide](</home/jaydon/Documents/ObsidianNote/personal/02_Areas/Automotive Grade Linux/PipeWire Bluetooth Phone Calls over D-Bus.md>)
and the sibling repositories. Relevant local examples:

| Reference | Reuse in this design |
| --- | --- |
| [BlueZ client](../bluez_native/lib/src/bluez_client.dart) | Typed Dart objects, streams, explicit client lifetime |
| [BlueZ native build](../bluez_native/native/CMakeLists.txt) | CMake, testable native core and exported C ABI |
| [BlueZ bridge](../bluez_native/native/src/bluez_bridge.cpp) | One connection/client, event thread, non-reused handle tokens |
| [BlueZ device bridge](../bluez_native/native/src/device_bridge.cpp) | Async operations with result ports and preserved D-Bus errors |
| [BlueZ device model](../bluez_native/lib/src/bluez_device.dart) | Cached getters and property-name broadcast streams |
| [Media repository history](../bluez_media_native/.git) | Independent Flutter FFI scaffold followed by native structure, XML/codegen, tooling, wire types, Dart codec and interface commits |
| [Media native build](../bluez_media_native/native/CMakeLists.txt) | Linux plugin bundling, static testable core, shared library and vendored sdbus-c++ |
| [Media proxy generation](../bluez_media_native/scripts/generate_proxies.sh) | Versioned XML inputs and reproducible `sdbus-c++-xml2cpp` output |
| [OBEX object manager](../bluez_obex_native/native/src/obex_object_manager.cpp) | Owner tracking, discovery and signal handling |
| [BlueZ serializer](../bluez_native/native/include/glaze_meta.h) | Evidence of a custom wire format, not upstream Glaze |

Reuse conventions, not a shared runtime dependency on the sibling packages.
Their native handles, private wire formats and D-Bus connections must remain
independent. In particular, do not copy the custom `namespace glz` serializer
and describe it as upstream Glaze. The confirmed choice here is the actual
[Glaze library](https://github.com/stephenberry/glaze), using JSON serialization
with Dart's standard `dart:convert` decoder.

The repository and delivery sequence follow `bluez_media_native`, which was an
independent Flutter FFI project rather than a Git branch of `bluez_native`.
Start from the generated Linux plugin, introduce `native/`, pin sdbus-c++, add
reviewed D-Bus XML and generated proxy headers, add development tooling and Dart
API DL, then deliver serialization, lifecycle and interface groups in separate
commits. The generated `src/` stub remains only until the real `native/` target
replaces it, as in the media port.

Use generated sdbus-c++ proxy declarations for the four reviewed PipeWire
interfaces and thin hand-written bridge/registry classes for ownership,
hierarchical ObjectManager discovery and Dart delivery. Retain ffigen for the C
ABI, wrapped by a small hand-written Dart facade. Keep the owner-thread queue,
identity validation and explicit shutdown defined below. The public object model
still follows `bluez_native` where it is stronger: constructor plus `connect()`,
cached child objects, focused property streams and non-reused tokens.

### Source findings that affect correctness

The versioned [PipeWire telephony source](https://github.com/PipeWire/pipewire/blob/1.6.6/spa/plugins/bluez5/telephony.c)
provides details beyond the [telephony README](https://github.com/PipeWire/pipewire/blob/1.6.6/spa/plugins/bluez5/README-Telephony.md):

1. Discovery is hierarchical. `manager_get_managed_objects` returns gateways;
   `ag_get_managed_objects` returns that gateway's calls. Calling the root alone
   does not discover existing calls in this baseline.
2. Gateway additions/removals originate at the root manager. Call additions and
   removals originate at the gateway manager. A root-path-only signal match
   misses live calls.
3. `AudioGatewayTransport1` shares the gateway object path. It is not a separate
   `/transport` object or a BlueZ `MediaTransport1` interface.
4. `Dial` returns an empty method reply, not a call path. Calls arrive separately.
5. The `call_properties_get` interface condition appears inverted in 1.6.6: it
   rejects `Call1` with `InvalidArgs`. `GetAll` has the expected check. Use
   ObjectManager snapshots and `GetAll` for normal reads; verify this apparent
   upstream defect against the patched target build before claiming it occurs
   there. Do not hide unrelated failures behind a compatibility fallback.
6. Native error names include `NotSupported`, `InvalidFormat`, `InProgress` and
   `CME`, beyond the shorter error lists in the README.

These findings correct assumptions in the guide for library design; the guide
itself has not been edited.

## 3. Architecture

```text
Flutter application
  | typed Futures, cached objects, focused broadcast streams
Dart: PipeWireTelephonyClient / AudioGateway / Call / Transport
  | dart:ffi commands                     ^ ReceivePort JSON messages
Versioned C ABI                          | Dart_PostCObject_DL
  | validated, copied command queue       |
Native client: one owner thread, sdbus-c++ event processing, Glaze DTOs
  | typed D-Bus messages
Selected bus: system (AGL default) or session (explicit desktop option)
  |
org.pipewire.Telephony, owned by the Bluetooth WirePlumber instance
  |
PipeWire native HFP backend <--> phone Audio Gateway

Separate audio path:
phone SCO <--> PipeWire graph <--> vehicle microphone and speaker
```

The native owner thread handles connection lifecycle, proxies, asynchronous
D-Bus requests and incoming signals. It owns the authoritative local object
registry. Dart maintains a read-only presentation mirror from ordered native
messages. PipeWire remains the authority for actual call state.

Use [sdbus-c++ asynchronous calls and event-loop integration](https://github.com/Kistler-Group/sdbus-cpp/blob/master/docs/using-sdbus-c%2B%2B.md)
for bus processing. Integrate the command wakeup descriptor with its documented
poll API, including the bus descriptor, internal event descriptor and timeout.
Do not invent a second D-Bus dispatcher. Version-specific integration must be
checked against the dependency revision selected in phase 0.

One native thread per client is sufficient. Do not create a thread per call or
run synchronous D-Bus requests on the Flutter isolate. Unlike the OBEX sibling's
blocking-call worker model, queued FFI submissions here make a permanent Dart
worker isolate unnecessary. Thread startup and the final thread join must run
off the UI isolate; they must not use `isLeaf: true` bindings.

## 4. Complete Native API Contract

Destination: `org.pipewire.Telephony`.
Root manager: `/org/pipewire/Telephony`.
Discover gateway and call paths; never construct numeric suffixes.

Every command below returns `Future<void>` in Dart. Completion means the D-Bus
reply succeeded, not that the desired state or audio transition has completed.

### AudioGateway1: eight methods

| D-Bus method | Input / output signature | Proposed Dart method | Semantics |
| --- | --- | --- | --- |
| `Dial` | `s` / empty | `gateway.dial(number)` | Start an outgoing call; new call arrives through discovery/events |
| `SwapCalls` | empty / empty | `gateway.swapCalls()` | Exchange active and held groups |
| `ReleaseAndAnswer` | empty / empty | `gateway.releaseAndAnswer()` | Release active group and answer waiting call |
| `ReleaseAndSwap` | empty / empty | `gateway.releaseAndSwap()` | Release active group and activate held group |
| `HoldAndAnswer` | empty / empty | `gateway.holdAndAnswer()` | Hold active group and answer waiting call |
| `HangupAll` | empty / empty | `gateway.hangupAll()` | Release calls except waiting calls |
| `CreateMultiparty` | empty / empty | `gateway.createMultiparty()` | Merge active and held calls |
| `SendTones` | `s` / empty | `gateway.sendTones(tones)` | Send DTMF through the gateway |

### Call1 and AudioGatewayTransport1: three methods

| Interface / method | Input / output signature | Proposed Dart method | Semantics |
| --- | --- | --- | --- |
| `Call1.Answer` | empty / empty | `call.answer()` | Valid for incoming calls; waiting-call handling uses gateway methods |
| `Call1.Hangup` | empty / empty | `call.hangup()` | Terminate/reject the selected call; phone multi-call restrictions apply |
| `AudioGatewayTransport1.Activate` | empty / empty | `gateway.transport.activate()` | Explicit SCO activation request; normal setup should activate automatically |

### All properties

| Interface | Property | D-Bus type | Access | Dart representation |
| --- | --- | --- | --- | --- |
| `AudioGateway1` | `Address` | `s` | Read | `String? address` |
| `AudioGateway1` | `SpeakerVolume` | `y` | Read/write | `int? speakerVolume`; `setSpeakerVolume(int)` |
| `AudioGateway1` | `MicrophoneVolume` | `y` | Read/write | `int? microphoneVolume`; `setMicrophoneVolume(int)` |
| `AudioGatewayTransport1` | `State` | `s` | Read | Known enum plus preserved raw state |
| `AudioGatewayTransport1` | `Codec` | `y` | Read | `int? codec`; preserve unknown numeric IDs |
| `AudioGatewayTransport1` | `RejectSCO` | `b` | Read/write | `bool? rejectSco`; `setRejectSco(bool)` |
| `Call1` | `LineIdentification` | `s` | Read | `String? lineIdentification` |
| `Call1` | `IncomingLine` | `s` | Read | `String? incomingLine` |
| `Call1` | `Name` | `s` | Read | `String? name` |
| `Call1` | `Multiparty` | `b` | Read | `bool? multiparty` |
| `Call1` | `State` | `s` | Read | Known enum plus preserved raw state |

Nullable values represent absent or invalidated properties, never invented
defaults. Preserve empty strings as reported. Preserve `withheld` caller ID as
data; do not treat it as a number. Writable properties use standard
`org.freedesktop.DBus.Properties.Set` (`ssv`), with exact byte or boolean variants.
All three setters return `Future<void>` and update the cache from confirmed
properties, not optimistic assignment.

Known call states: `active`, `held`, `dialing`, `alerting`, `incoming`, `waiting`,
`disconnected`. Known transport states: `error`, `idle`, `pending`, `active`.
Unknown future states remain observable and must not crash decoding. Codec IDs
are metadata, not a codec-selection command.

### Standard interfaces and validation

Use `ObjectManager.GetManagedObjects` (empty input, `a{oa{sa{sv}}}` output)
at the root and each gateway, and `Properties.GetAll` (`s` to `a{sv}`) for refresh.
Handle `InterfacesAdded` (`oa{sa{sv}}`), `InterfacesRemoved` (`oas`) and
`PropertiesChanged` (`sa{sv}as`). Introspection is a diagnostic/contract check,
not a required round trip before every action.

Validate dial strings against `[0-9+*#,ABCD]{1,80}` in Dart and again at the
native boundary. Do not rewrite numbers or accept embedded NULs. DTMF accepts
only `0-9`, `*`, `#`, `A-D`; the source validator permits empty strings, so do not
invent a stricter protocol rule without recording it. The application should
avoid sending empty DTMF. Validate volume as an integer from 0 through 15 before
converting to a D-Bus byte. No implicit clamp or integer wraparound.

Do not expose speculative `Hold`, `Resume`, `Transfer`, `Deactivate`, `Acquire`,
`Mute` or codec-selection methods: they are absent from this native baseline.
In particular, `RejectSCO` is not a general audio-routing or microphone-mute API.

## 5. Dart Consumer Model

| Type | Contract |
| --- | --- |
| `PipeWireTelephonyClient` | Constructor, `connect`, `gateways`, aggregated `calls`, `state`, `lastError`, `refresh`, `close` |
| `PipeWireAudioGateway` | Discovered identity, properties, calls, optional transport and all gateway commands |
| `PipeWireCall` | Parent gateway identity, properties, `answer`, `hangup`, `refresh` |
| `PipeWireTelephonyTransport` | Same path as gateway, transport properties, `activate`, `setRejectSco`, `refresh` |
| Internal snapshot DTOs | Immutable values and revision, copied collections, property presence |
| Client streams | `gatewayAdded`, `gatewayRemoved`, `gatewayChanged`, `callAdded`, `callRemoved`, `callChanged`, `stateChanged` |
| Object streams | Gateway, call and transport each expose `Stream<List<String>> propertiesChanged` |
| `PipeWireTelephonyException` | Local category, exact remote name/message where present, operation, path and request ID |

Construct `PipeWireTelephonyClient()` and then await its instance `connect()`
method, matching `BlueZClient()` usage. `PipeWireBus.automatic` is the default:
it selects the current process's session bus when that bus owns the service and
otherwise tries the system bus. `PipeWireBus.session` and `PipeWireBus.system`
force a deterministic scope. Selection is fixed for the client lifetime; owner
loss does not migrate an active client to another bus. Automatic mode cannot
cross Unix login boundaries or discover another user's session bus when its
address and D-Bus credentials are unavailable, including typical `sudo` use.
Connection creation finishes only after initial gateway and call enumeration is
reconciled. A service with zero
gateways is a successful empty connection. Missing service and access denial
are distinct connection failures with bounded startup deadlines.

Client states are `idle`, `connecting`, `ready`, `unavailable`, `closing`, and
`closed`. Concurrent `connect()` calls share the same startup Future; connecting
an already ready client succeeds immediately. Failed startup transitions to
unavailable and cleans up resources; retry requires a new client. `connect()` on
an unavailable, closing or closed instance fails locally. `close()` before
connect is valid; concurrent closes share one Future. Closing during startup
fails the pending connect and waits for native cleanup, never for readiness.

Expose unmodifiable cached collections. Consumers subscribe first and then read
the current getters. Streams describe changes; getters are authoritative at the
time of reading. Apply the entire update before emitting notifications. Keep
wire sequence/revision handling internal; there is no generic public snapshot
or event protocol. Snapshot DTOs inside native messages remain necessary for
startup reconciliation. `stateChanged` reports unavailable with the reason in
`lastError`; invalidate collections before notifying consumers of service loss.
Gateway changes include call membership and transport interface presence;
property-name streams report D-Bus property names, including invalidations.
Known state enums include `unknown`, with a separate nullable `rawState` getter
preserving future strings and distinguishing missing properties.

Identity is `(client generation, object path, object incarnation)`. Incarnation
changes on removal/re-addition even if the same service reuses a path. Old
wrappers become unusable; commands on them fail locally. A disconnected call is
terminal even if its removal signal has not yet arrived. Never transfer an old
pending command to a newly created object with the same path.
Include generation, path, interface and incarnation in each targeted command.
The native owner validates them immediately before dispatch, even if Dart has
already validated its wrapper. The client token registry uses monotonically
allocated, non-reused tokens, as in `bluez_native`; tokens are never dereferenced
as context pointers. Retire a token at final destruction and reject submissions
as soon as closing begins. Interface removal/re-addition also renews identity.

Multiple phones are first-class: calls are grouped by discovered gateway, and
every command targets an explicit object. The application may correlate gateway
`Address` with BlueZ device addresses and OBEX contacts, but must handle missing
or ambiguous matches. The library does not pick the first phone automatically.

State-based UI hints are advisory. Method presence is not evidence that the
phone supports the operation in the current network/call state. Preserve
`NotSupported` and `InvalidState`; do not infer a permanent capability from a
single failed invocation or run commands to probe support.

## 6. Discovery, Ordering and Recovery

### Initial synchronization

1. Open the selected bus on the native owner thread. Install service owner and
   namespace signal matches before enumeration; confirm match installation.
2. Resolve the unique owner of `org.pipewire.Telephony`. Bind requests and signal
   validation to that owner. Owner replacement during startup aborts the attempt.
3. Subscribe to ObjectManager signals over `/org/pipewire/Telephony` and its
   descendants, plus PropertiesChanged on discovered interfaces. A namespace
   subscription must validate both sender and object/interface identities.
4. Request root `GetManagedObjects`, then request `GetManagedObjects` on every
   discovered gateway. The root snapshot owns gateway membership; each gateway
   snapshot owns only its call membership. Include gateways arriving meanwhile.
5. Process signals and asynchronous snapshot replies in one owner-thread order.
   A snapshot replaces only its scope at its reply boundary. Earlier updates in
   that scope are subsumed; later signals apply afterward. Do not replay an older
   buffered property value over a newer snapshot. Track per-scope query tokens
   and object incarnations so late replies cannot resurrect removed objects.
6. Publish ready after all surviving gateway scopes have completed initial
   enumeration. The result is a reconciled view, not a globally atomic database
   transaction across the phone. Continuous churn eventually hits the startup
   deadline and returns an explicit failure instead of hanging indefinitely.

Serialize refresh requests per scope; merge concurrent refresh callers onto the
same operation. Newly added gateways require their own call enumeration even
after startup. If a gateway disappears, invalidate its calls and transport as a
single logical update without relying on individual child removal signals.
Ignore duplicate removals. Preserve interface-level removal semantics.

For invalidated properties, mark the fields unknown and schedule `GetAll` on
that interface. Report refresh errors; a vanished object is removed, not retained
as apparently usable state. Ignore unknown extra properties/interfaces unless
needed for a later version's explicitly supported API.

### Commands and timeouts

Use asynchronous D-Bus calls. Allow one mutating operation in flight per gateway,
including its calls and transport. Reject another mutation with a local busy
error instead of storing stale dial/hangup actions in a long queue. Reads can
proceed independently. Different gateways can operate concurrently.

Each submitted request has an ID and one completion. A configurable finite
deadline bounds startup and method waiting; start with a documented 30-second
default and calibrate it on the target. A timeout after dispatch means the remote
outcome is unknown. Discard late completions, reconcile state, and do not retry
dial, DTMF, hangup, conference, or property writes automatically. Canceling local
waiting does not undo a command already received by the phone.

The gateway becomes available for another mutation only after the underlying
request completes or its native timeout/cancellation bookkeeping is resolved.
Following an uncertain result, refresh before enabling application follow-up;
the remote service can still respond `InProgress`.

### Service loss

On owner loss/replacement, bus disconnection or unrecoverable event processing
failure: mark the client unavailable, invalidate all wrappers, fail pending
requests, emit one terminal notification, and release resources. Do not synthesize
a remote `disconnected` call state when the actual phone state is unknown.

Recovery is explicit: the application awaits `close()` and creates a fresh
client, optionally using bounded backoff. This follows the OBEX sibling's clear
terminal-client model. It prevents old paths and commands from surviving a
WirePlumber restart. Ordinary phone disconnect/reconnect under the same owner
is handled dynamically without restarting the entire client.

## 7. C ABI, Serialization and Lifetime

Use `dart:ffi` with generated bindings from one public C header. C++ classes,
STL objects, exceptions and sdbus types never cross the ABI. Prefix public symbols
with `pwt_` and hide all other symbols, including statically bundled dependencies,
to coexist with the sibling libraries in one Flutter process.

The C surface consists of ABI version query, Dart DL initialization, client
creation/start, command submission, stop request, final destruction and buffer
release. It uses an opaque client token, fixed-width status values, explicit
byte lengths, and Dart port IDs. The command selector is a closed internal set
covering the documented API, not arbitrary user-supplied D-Bus invocation.

| Symbol | Contract |
| --- | --- |
| `pwt_abi_version` | Return the native ABI major, currently 1 |
| `pwt_initialize_dart_api_dl` | Synchronized, idempotent initialization using `NativeApi.initializeApiDLData` |
| `pwt_client_create` | Allocate a context and register a monotonically increasing, non-reused opaque token |
| `pwt_client_start` | Start the owner thread exactly once |
| `pwt_client_submit` | Validate and copy UTF-8 bytes before return, then admit at most 64 queued commands |
| `pwt_client_stop` | Idempotently reject new work and signal the reserved stop path without depending on queue capacity |
| `pwt_client_destroy` | Retire the token before stopping/joining outside the registry lock; null, stale, bogus, and repeated calls are safe |
| `pwt_free` | Release native-owned result/error buffers; accepting null is safe |

All status returns are fixed-width `int32_t`: success, invalid argument, invalid
handle, invalid state, queue full, protocol error, or internal error. The Dart
facade checks ABI compatibility before startup, maps statuses without exposing
generated declarations, and releases temporary allocations in `finally`.

FFI threads only validate/copy input, resolve a registry token and enqueue a
command. They never operate on D-Bus proxies or the object registry. The native
owner handles dispatch, reply slots, cancellation and teardown. Stop has a
reserved wakeup/control path so a full request queue cannot prevent shutdown.

Glaze writes/reads versioned UTF-8 JSON DTOs. Dart uses `jsonDecode`/`jsonEncode`
and explicit typed conversion. Commands contain protocol version, request ID,
target identity, operation and arguments. Replies/events contain protocol
version, client generation, monotonic delivery sequence, kind and typed payload;
replies also carry request ID and either a result or structured error. Do not
serialize D-Bus variants by stringifying them. Known properties map directly to
their string, integer or boolean DTO fields. A temporary result port accompanies
each submission through the C ABI, following `bluez_native`'s async operations.
Keep request IDs for pending-slot cleanup and diagnostics despite port-based
correlation. The client tracks all result ports and completes/closes each once
on success, error, timeout or shutdown. An immediate rejected submission must
also close its port. Result-port post failure retires that request; only loss of
the client event port terminates the client. Result and event ports have no
cross-port ordering guarantee; a method result never implies a cache update.

Schema rules: reject unsupported major versions, missing required fields,
wrong types and invalid bounds; tolerate additive optional fields. Preserve
missing versus empty values. Check the native ABI before opening a connection,
especially when loading an externally built library. Start with 1 MiB message
and 64 queued-command limits, with explicit resource-limit errors. These
are library resource policies, not PipeWire protocol limits, and must be tested.

### JSON protocol version 1

Every message is one UTF-8 JSON object no larger than 1 MiB. Integer identity,
request and sequence values are positive. Property byte values are integers in
the range 0 through 255. Nullable property fields distinguish an unavailable
property from an available empty string. Unknown enum/state strings remain
intact for forward compatibility; unknown top-level optional fields are ignored.

| Envelope | Required fields |
| --- | --- |
| Request | `version`, `requestId`, closed `operation`, and `target` containing `clientGeneration`, `objectIncarnation`, `path`, `interface`; typed `arguments` contains nullable `text`, `volume`, and `value` |
| Reply | `version`, `clientGeneration`, monotonic `sequence`, `kind: reply`, `requestId`, `ok`, and nullable structured `error` |
| Event | `version`, `clientGeneration`, monotonic `sequence`, event `kind`, and typed `payload` |
| Error | `category`, exact `name`, original `message`, `operation`, and target `path` |

The event payload has nullable `startup`, `lifecycle`, `gateway`, `call`,
`transport`, and `error` members. Startup contains complete gateway, call, and
transport arrays. Lifecycle contains the client state. Property DTOs include
their object path, incarnation, typed known properties, and changed D-Bus
property names. Delivery sequence is shared by replies and events from one
client generation; Dart must not infer ordering across separate native ports.

Protocol version 1 accepts only `refreshGateway`, `refreshCall`,
`refreshTransport`, `dial`, `sendTones`, `answer`, `hangup`, `hangupAll`,
`setSpeakerVolume`, `setMicrophoneVolume`, `activate`, `setRejectSco`,
`swapCalls`, `releaseAndAnswer`, `releaseAndSwap`, `holdAndAnswer`, and
`createMultiparty`. No wire value maps directly to an arbitrary D-Bus method.

### Ownership rules

| Resource | Owner and release rule |
| --- | --- |
| FFI input bytes | Dart owns allocation; native validates/copies before submission returns |
| Immediate native result/error buffer | Native allocates; Dart copies and releases through `pwt_free` in `finally` |
| Posted event bytes | Post copied `Dart_CObject` typed data; native may release its source after posting returns |
| Client handle | Exactly one Dart client owns it; valid until explicit final destruction completes |
| D-Bus connection, proxies, pending slots, registry | Native owner thread creates, uses and releases them |
| ReceivePort and Dart pending completers | Dart client owns them until native shutdown is acknowledged |

Initialize `Dart_InitializeApiDL` once with synchronized native initialization and
check its return status. Never invoke a Dart callback directly from the native
thread. Use `Dart_PostCObject_DL`, check failure according to the port rules above,
and initiate native cleanup when the client event receiver is gone. Use copied typed data for these small control
messages; an external-data zero-copy finalizer protocol is unnecessary.

All ABI entry points catch C++ exceptions and return defined failures. Do not
use a process-global last-error string. Keep errors tied to the request, and
ensure malformed input cannot produce partial command execution.

`close()` is asynchronous and idempotent: reject submissions, enqueue stop,
cancel pending requests locally, detach subscriptions, release proxies and bus,
acknowledge stopped, join/destroy off the UI isolate, then close Dart ports and
streams. No callback may reference freed memory. A best-effort finalizer may
request stop but cannot substitute for awaited close or block on a thread join.
Handle cleanup after startup failure and unexpected isolate exit explicitly.
Initiate stream closure after cleanup, but do not let an indefinitely paused
broadcast listener delay the client close Future. Gateway removal invalidates
its children before lifecycle notifications; removed object streams then close.

Deliver lifecycle changes in sequence without silent loss. Native command
queues are bounded. Dart broadcast streams can buffer when subscribers pause;
this first version does not promise bounded memory for indefinitely paused
listeners. Document that limit, measure it under signal stress, and have the
application cancel/re-subscribe using the current snapshot during long pauses.
If bounded delivery is required by target measurements, add acknowledged batches
before release rather than silently dropping removals or method results.

## 8. Errors and Diagnostics

| Failure class | Required behavior |
| --- | --- |
| Invalid input / stale object / closed client | Fail locally before sending |
| Missing owner | Service-unavailable error, distinct from empty gateway list |
| Access denied | Preserve `org.freedesktop.DBus.Error.AccessDenied`; identify bus and destination |
| PipeWire errors | Preserve full names: `Failed`, `NotSupported`, `InvalidFormat`, `InvalidState`, `InProgress`, `CME` |
| D-Bus errors | Preserve remote names, including unknown object/interface/method and invalid arguments |
| Timeout after send | Explicit unknown-outcome error; no automatic replay |
| Decode/version failure | Protocol error; invalidate state when consistency cannot be established |
| Native worker failure | Fail pending Futures and terminate the client cleanly |

Keep the original remote message, including CME descriptions; do not manufacture
a numeric CME code from human-readable text. Public exception formatting and
default logs should redact phone numbers, names, DTMF and Bluetooth addresses.
Raw remote detail can remain available to the caller for controlled diagnostics.
Log operation, duration, request ID and error category without command arguments.
No call history or contact database is stored by this package.

## 9. Packaging and AGL Deployment

Retain the generated Linux Flutter FFI plugin package model used by
`bluez_media_native`. Keep the public Dart API free of Flutter imports so tests
and CLI consumers can still use it. The plugin's `linux/CMakeLists.txt` builds
and bundles the real `native/` shared library. Remove the generated sum/demo C
implementation and bindings when that boundary lands; do not keep two native
implementations active.

Use a static core for native tests and one shared target producing
`libpipewire_telephony_native.so`. Generate Dart bindings with ffigen and proxy
headers with `sdbus-c++-xml2cpp`. Keep reviewed XML, generated proxy headers and
the regeneration script in the repository; code generation runs on the host,
not on the target device. Pin sdbus-c++ and
Glaze revisions and preserve licenses. Start with the siblings' CMake 3.22/C++23
baseline, subject to an AGL SDK compilation check before freezing requirements.
The dependency pins are sdbus-c++ v2.2.1
(`28b78822cfc5fbec4bd9906168493e9985f586ed`, matching `bluez_native`) and Glaze
v8.3.0 (`dce5e0f7ec572725ec369a0bc59a00eeb2270a9a`). Keep sdbus-c++ as a submodule;
vendor only Glaze's `include/glaze` header tree, license, and provenance rather
than its complete upstream project. Verify host and SDK
compilation in T02 before declaring target compatibility. Record any required
pin adjustment in both documents; do not silently change dependencies.

Provide dependency sources reproducibly in package archives or via the Yocto
fetch stage. Do not require a build hook to run Git or access the network inside
an offline Yocto build. Link against target `libsystemd`; do not require
libpipewire headers or link to libpipewire merely to call its D-Bus service.

The `meta-agl-demo` integration supplies a `flutter-telephony` AGL app recipe.
It cross-builds `native/` with the active Yocto toolchain, injects the resulting
shared object into the nested Flutter application's native assets, installs the
standard `agl-app-flutter` systemd unit, and adds the package to
`agl-ivi-demo-flutter`. A clean local source snapshot passed the complete
Raspberry Pi 5 image build. Normal `gitsm` fetch remains a release gate until the
pinned source branch, revision and submodule are published; `externalsrc` is
validation plumbing, not the shipping source policy.

AGL deployment is a release requirement, not a later portability exercise:

| Build mode | Planned behavior |
| --- | --- |
| Linux host build | Flutter's Linux plugin CMake build bundles the matching shared library |
| AGL SDK cross-build | CMake toolchain/sysroot and target pkg-config configuration; never reuse host cache |
| Yocto-provided shared library | Explicit CMake prebuilt input, validate ELF architecture and ABI, bundle through the same plugin library list |
| Unsupported OS/architecture | Fail clearly before producing a mislabeled binary |

Test at least desktop Linux x86_64 and the selected AGL target architecture.
The validated image target is `raspberrypi5`/AArch64 with AGL 21.93.0, Flutter
3.38.3 and Dart 3.10.1. This establishes build compatibility, not possession or
runtime acceptance of a specific physical board. Native Assets builds require
a Linux host and target; AGL continues to supply its explicit Yocto toolchain
and independent native build tasks rather than relying on host defaults.

### Target prerequisites from the supplied guide

The image must select PipeWire's native HFP backend and system-bus telephony,
enable the HF role, and run AGL's split Bluetooth WirePlumber service. Keep oFono
available for SIM support while removing its BlueZ HFP ownership as described in
the guide. Confirm that `org.pipewire.Telephony` has the expected owner.

Deploy destination-specific D-Bus permissions for `agl-driver` through Yocto.
Include method access and verify actual signal reception for that user; do not
solve application permission failures by requiring root or a broad default
policy. System changes belong to image integration, not library initialization.

Verify both SCO state and audio links. An active call does not prove usable
audio; active SCO does not prove correct routing. Validate downlink to speakers,
uplink from microphone, and music interruption/restoration through AGL policy.
No automatic `Activate` or `RejectSCO` change occurs merely by opening the client.

## 10. Repository Layout

The release implementation uses the following layout. Planning files remain
local and untracked and are excluded from the pub.dev archive.

```text
ARCHITECTURE.md
task.md
README.md
CHANGELOG.md
THIRD_PARTY_NOTICES.md
LICENSES/                   # retained license for Apache-derived code
hook/build.dart             # Linux Native Assets build
interfaces/                 # reviewed D-Bus XML
lib/
  pipewire_telephony_native.dart
  src/
    pipewire_telephony_client.dart
    pipewire_audio_gateway.dart
    pipewire_call.dart
    pipewire_telephony_transport.dart
    enums.dart
    exceptions.dart
    internal/               # library loader
    ffi/                    # generated declarations, bindings facade, DTOs, codec
native/
  CMakeLists.txt
  include/                  # public C header and private DTO/client headers
  src/                      # ABI, native client, object manager, interface bridges
  generated/                # checked-in sdbus-c++ proxy headers
  third_party/              # pinned dependency sources and license notices
  test/                     # ABI, lifecycle, serialization tests
scripts/                    # proxy generation, formatting, analysis and tests
ffigen.yaml
test/                       # Dart contracts and private-bus integration tests
example/
  telephony_example_utils.dart # shared standalone helpers
  telephony_list.dart       # gateway/call discovery
  telephony_watch.dart      # live lifecycle and property events
  telephony_gateway.dart    # gateway, volume and SCO commands
  telephony_call.dart       # call properties and commands
  flutter_telephony/        # full Flutter Linux telephony UI
doc/                        # AGL build guidance
```

Prefer a small client and interface-focused operations over a reusable RPC
framework. Share the serializer, error DTO and lifecycle machinery within this
package. Do not extract a cross-repository framework as part of telephony work.

## 11. Delivery Plan and Acceptance Gates

The executable work breakdown is [task.md](task.md), T00 through T24. Owner
tracking starts in T08, object invalidation in T09/T10, and pending-operation
failure in T12. T18 verifies those guarantees together; it does not introduce
them. T20 implements cross-build and prebuilt packaging before target validation.

Phases are dependency-ordered. No duration estimate is reliable until the AGL
SDK and device access are known. Each implementation phase should be reviewable
and use Conventional Commit subjects such as `feat:`, `fix:`, `test:` or `docs:`.

| Phase | Owner role | Deliverable | Exit gate |
| --- | --- | --- | --- |
| 0. Scaffold and freeze contracts | Lead + AGL integrator | Independent Flutter FFI scaffold, source revision record, reviewed XML/generated proxies, DTO/ABI specification, SDK/dependency pins | Reconcile root/gateway discovery and Call1.Get behavior; confirm target toolchain and service configuration |
| 1. Native boundary | Native + Dart maintainers | C ABI, Glaze JSON, native owner thread, port bridge, deterministic close, build hook | Round-trip fixtures, invalid input, ABI mismatch, startup failure and close-under-load pass; Flutter UI never waits on D-Bus |
| 2. Discovery and state | Native + Dart maintainers | Nested ObjectManager enumeration, typed snapshots, property updates and owner tracking | Existing and newly created calls are visible; startup races, invalidations, removal/re-addition and service loss pass |
| 3. Basic calls | Native + Dart maintainers | Dial, Answer, Hangup, HangupAll, SendTones | Exact signatures and errors verified; real phone outgoing/incoming/reject/DTMF flows pass |
| 4. Complete surface | Native + Dart maintainers | Five multi-call operations, volume setters, SCO activation and RejectSCO | All 11 methods and 11 properties covered against mock contract; hardware-supported multi-call and audio flows recorded |
| 5. AGL release | AGL integrator + QA | T20 cross-build/prebuilt implementation, T21 example, T22 hardware verification, T23 release audit | Packaged library runs on selected target; both audio directions, restart recovery and coexistence with siblings verified |

The lead owns API scope and lifecycle invariants. Native and Dart maintainers
review the wire contract together. The AGL integrator owns image configuration,
SDK and routing. QA owns a reproducible matrix distinguishing library defects,
unsupported phone features and target configuration failures. One person can
fill several roles; separate approval teams are not required.

## 12. Verification Strategy

Use a mock telephony service on a private D-Bus daemon, accessed through an
internal test-only bus-address override. It must reproduce nested managers,
exact variant types, native error names and signals at the correct paths. A
fake Dart backend alone cannot validate the FFI/D-Bus contract. Mock tests must
never send real call commands to a production bus.

The reviewed XML is the native-interface subset of PipeWire 1.6.6 commit
`a1c1d9f9f128ec987f23a0140a1704b8f8781787`; generated proxy headers are checked
against these files. Do not include the compatibility
`org.ofono.*` aliases. Native integration tests run with GoogleTest under
CTest's `dbus-run-session`, so each test process receives an explicit private
session-bus address and the wrapper owns daemon cleanup even after a test
failure. The reusable sdbus-c++ mock supports empty and populated nested object
trees, live gateway/call add/remove signals, typed property changes, all native
methods, injected exact D-Bus errors, and replacement with a new unique owner.
Only GoogleTest's pinned include/source/license test payload is vendored, and it
is never linked into the package shared library.

| Area | Required checks |
| --- | --- |
| API completeness | All 11 methods, 11 property reads and three setters; empty Dial reply; exact `y`/`b` writes |
| Wire contract | Glaze-to-Dart and Dart-to-Glaze fixtures; malformed/truncated/oversized JSON; unknown fields/states; null/empty distinction |
| Initial state | Zero gateways, multiple gateways, calls predating connect, calls added while root/gateway snapshots are in flight |
| Ordering | Property changes around replies, duplicate signals, invalidation refresh, stale refresh reply, removal and same-path reuse |
| Commands | Invalid number/tones/volume, per-gateway busy gate, remote unsupported/state/CME errors, timeout with late remote success |
| Lifetime | Repeated connect/close, concurrent close and command, service owner replacement, bus failure, port closure, failed startup |
| Resources | Sanitizers for native ownership/races, bounded submissions, signal stress and paused-stream memory measurements |
| Packaging | Fresh archive without `.git`, offline dependencies, host and target ELF/ABI checks, bundled Flutter release build |
| AGL hardware | Non-root `agl-driver`, two-way audio, incoming/outgoing/reject, DTMF, hold/wait/conference where supported, phone and service reconnect |

Capture phone model/OS, network support, Bluetooth controller, image revisions,
codec and supported/unsupported result for each hardware scenario. Exercise
multiple-phone routing if the target permits simultaneous gateways. Use consented
test calls and redact numbers in published logs.

Definition of done: the coverage matrix has no unimplemented baseline member;
automated tests pass; target build and basic real-call audio tests pass; optional
phone/network limitations are recorded accurately; teardown leaves no native
thread or dangling handle; public docs explain bus choice, async semantics,
service loss and deployment prerequisites.

## 13. Decisions and Remaining Inputs

| Topic | Status / decision |
| --- | --- |
| Meaning of dbus-c++ | User confirmed sdbus-c++ |
| Meaning of Glaze | User confirmed upstream Glaze with JSON across FFI |
| Platform and role | Linux/AGL, vehicle HF and phone AG |
| Bus | Automatic session-first discovery with system fallback; explicit session/system options |
| Scope | Native PipeWire 1.6.6 surface; no oFono aliases in initial release |
| Concurrency | One native owner thread/client, asynchronous bus requests, one mutation/gateway |
| Recovery | Terminal client on service/bus loss; explicit fresh connection |
| Hardware/SDK | AGL 21.93.0 Raspberry Pi 5/AArch64 source cross-build and image integration pass; T20 target-prebuilt/fetch checks and T22 board/phone verification remain open |
| Target API differences | Read-only target introspection and existing-call snapshot needed to confirm distro patches |
| Audio policy | Integrator to identify microphone/speaker endpoints and existing focus/routing policy |
| Test access | Identify test phones/network multi-call support before hardware acceptance |

The remaining target inputs do not block the host-reviewed 0.0.1 package. They
are required before claiming full AGL runtime acceptance. T24 records pub.dev
release preparation independently of those target checks. Verification uses
private mock buses and does not issue production phone-call commands.

## References

- [Supplied AGL Bluetooth call guide](</home/jaydon/Documents/ObsidianNote/personal/02_Areas/Automotive Grade Linux/PipeWire Bluetooth Phone Calls over D-Bus.md>)
- [PipeWire 1.6.6 telephony implementation and introspection](https://github.com/PipeWire/pipewire/blob/1.6.6/spa/plugins/bluez5/telephony.c)
- [PipeWire 1.6.6 telephony API guide](https://github.com/PipeWire/pipewire/blob/1.6.6/spa/plugins/bluez5/README-Telephony.md)
- [sdbus-c++ official usage guide](https://github.com/Kistler-Group/sdbus-cpp/blob/master/docs/using-sdbus-c%2B%2B.md)
- [Upstream Glaze](https://github.com/stephenberry/glaze)
- [Dart C interop](https://dart.dev/interop/c-interop)
