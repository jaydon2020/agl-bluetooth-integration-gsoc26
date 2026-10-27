# PipeWire Telephony Implementation Tasks

Design contract: [ARCHITECTURE.md](ARCHITECTURE.md).
Status on 2026-10-25: baseline release preparation is committed on `main`;
targeted native-loader/build safety fixes are verified locally under T25 and
await their implementation commit. The independent `rewrite/bluez-media-port` history
below records the original port. AGL deployment acceptance remains separate.

## Working Rules

Each task is a reviewable deliverable with its own verification. Check it off
only when its acceptance criteria pass and record the evidence. The suggested
Conventional Commit subject is the required commit for that task. Per the user's
latest clarification on 2026-10-25, never commit this file or `ARCHITECTURE.md`.
Keep both updated locally and untracked. `.pubignore` also excludes them from
the pub.dev archive. The baseline release commit is `20e2ffe`; T25 describes the
additional local safety fixes.

Follow the actual `bluez_media_native` port sequence: independent Flutter FFI
scaffold, `native/` CMake and sdbus-c++ submodule, reviewed XML plus generated
proxies, development scripts and Dart API DL, wire types/codec, lifecycle, then
interface groups. Reuse `bluez_native`'s constructor plus `connect()`, cached
objects, property streams, token registry and asynchronous error behavior inside
that package structure.

Keep upstream Glaze JSON and ffigen-generated C declarations behind a small
hand-written bindings facade. Keep the native owner-thread queue. Use reviewed
XML and generated sdbus-c++ proxy declarations behind thin bridge classes. No
implementation of a generic RPC framework, PCM processing, BlueZ pairing or
WirePlumber routing belongs here.

All native methods and setters return Futures completed by D-Bus replies. Calls
arrive independently of the empty Dial reply. Preserve generation, interface,
path and incarnation in requests; a result port does not replace target identity.

## Issue and Resolution Ledger

This ledger records implementation problems discovered during the port, not
just planned features. Commit IDs identify the change that resolved or contained
the issue. Older entries describe the policy in effect at that time; the current
local-only rule above applies to both planning files.

| ID | Issue found | Root cause | Resolution and evidence |
| --- | --- | --- | --- |
| I01 | The original `main` implementation/history did not match the requested `bluez_media_native` port sequence. | Work had started from the wrong foundation and repository shape. | Restarted on the independent `rewrite/bluez-media-port` history with a clean Flutter FFI scaffold, then introduced native structure in sibling-project order (`9684b00`, `e6394f1`). |
| I02 | The sibling `bluez_native` serializer could be mistaken for upstream Glaze, and vendoring the complete Glaze repository was unnecessary. | The sibling has a custom `namespace glz` wire codec rather than the upstream library selected for this project. | Pinned upstream Glaze v8.3.0 and retained only `include/glaze`, its license and provenance; JSON is the FFI payload (`dc1ab88`). |
| I03 | Generated proxy include guards embedded the developer's absolute checkout path, so regeneration differed after relocation or archive extraction. | `sdbus-c++-xml2cpp` received absolute output paths. | Run generation from the repository root with relative XML/output paths and regenerate stable headers (`86f4822`). |
| I04 | A flat/root-only discovery model would miss existing and live calls; transport and Dial assumptions in the supplied guide also differed from PipeWire 1.6.6. | PipeWire telephony uses a root ObjectManager for gateways, a nested ObjectManager per gateway for calls, a same-path transport interface, and an empty Dial reply. | Reviewed the 1.6.6 source/XML, implemented hierarchical registries and same-path transport identity, and used ObjectManager events for Dial-created calls (`a59d4d8`, `6fc4144`, `14c4d8d`, `d7c3766`). |
| I05 | `Call1.Get` in the 1.6.6 source appears to reject its own interface, and signal-only writes can leave caches stale. | The baseline has an apparent interface-check defect and peers need not emit a confirming property signal. | Normal reads and post-write confirmation use ObjectManager snapshots and revision-guarded `GetAll`; exact remote failures remain visible (`543cab4`, `29f06d6`, `d7c3766`). Target patch status remains part of T22. |
| I06 | Shutdown and service-loss edges could strand work or trigger reentrant close behavior: mixed pending replies, paused listeners, closed Dart ports, owner replacement and bus death all needed proof. | Native and Dart lifetimes cross an owner thread, asynchronous D-Bus slots and synchronous broadcast streams. | Added a non-reused token registry, bounded queue, terminal cleanup, an async yield before the closing transition, explicit private-daemon ownership and lifecycle race coverage (`1027a65`, `0fd2af4`, `9e4a762`). |
| I07 | Loading by SONAME alone was not reliable after relocating a Flutter bundle, and coexistence with sibling native libraries was unverified. | Runtime loader search paths differ between development, installed bundles and test archives. | Added explicit override, loaded-library sibling and executable-relative lookup; packaging verifies exact exports, sibling loading and a metadata-free archive rebuild (`786af81`). |
| I08 | A host library could accidentally be supplied to an AGL build, or a prebuilt could have the wrong architecture, SONAME, exports, dependencies or runtime search path. | Flutter's Linux CMake path did not distinguish validated target artifacts from host builds. | Added source cross-build gates and strict prebuilt ELF/ABI validation, with negative host tests (`b45a7cc`). The AGL source build now passes; target-prebuilt equivalence remains O01. |
| I09 | The first desktop Flutter example connected to the system bus and displayed `NameHasNoOwner` while the live WirePlumber service owned `org.pipewire.Telephony` on the user bus. | Desktop `wireplumber@bluetooth.service` is session/user scoped on the inspected host. | Switched the desktop example to the session bus and corrected its guidance after live `busctl --user` verification (`ea4f2a3`). |
| I10 | A session-only example fixed desktop use but did not cover system-scoped AGL services or processes whose session bus is empty/unreachable. | The service scope is deployment-dependent; administrator privileges do not expose another user's private session bus. | Added `PipeWireBus.automatic` with session-first owner detection and system fallback, retained explicit scopes, and added two-daemon integration coverage for preference and fallback (`ce2a06c`). |
| I11 | The example layout no longer matched `bluez_media_native`: first the Flutter app and standalone commands were combined, then all standalone commands lived in one file. | The initial example grouped unrelated gateway, call, discovery and watch workflows together. | Moved the full UI into `example/flutter_telephony/`, then split standalone use into focused list, watch, gateway and call executables backed by one shared helper (`49e7834`, `78d51eb`). |
| I12 | Removing `DBUS_SESSION_BUS_ADDRESS` did not reliably simulate an administrator without the desktop session; the test still found the live gateway. | libsystemd can rediscover `/run/user/<uid>/bus` for the same Unix identity. | Test an explicitly unreachable session address before system fallback, and describe access in terms of bus address, UID and D-Bus policy rather than one environment variable (`ce2a06c`). |
| I13 | Host package verification stopped after adding `PWT_BUS_AUTO` because regenerated ffigen output differed from committed `HEAD`. | The verifier deliberately treats generated-source drift as a failure and builds its clean archive from `HEAD`. | Regenerate and review bindings in the feature, commit them with the ABI change, then run package/archive verification against that commit. The final `ce2a06c` package check passed; no weakening of the guard was needed. |
| I14 | Planning text became stale after the bus and test changes, including "system by default" and an eight-test count. | `ARCHITECTURE.md` and `task.md` are intentionally excluded from implementation commits. | Reconciled both local planning files with automatic bus discovery, nine CTests and this issue ledger on 2026-09-19; they remain intentionally uncommitted. |
| I15 | The AGL Flutter 3.38.3 toolchain provides Dart 3.10.1, but both package manifests required Dart 3.13.2. | The development-host SDK constraint had been copied into package metadata even though the implementation uses no 3.13-only language feature. | Lowered both SDK floors to 3.10.1, regenerated the nested lock metadata and passed root/nested analysis plus locked dependency resolution (`3132037`). |
| I16 | Yocto package QA found the native build directory embedded in `libpipewire_telephony_native.so`. | The standalone native CMake build used a second `${WORKDIR}` build tree that was not covered by the recipe's debug prefix mapping. | Added both native source and native build trees to `DEBUG_PREFIX_MAP`; the package and full image QA then passed (`d65becb5`). |
| I17 | The Flutter app recipe must cross-build the independent native CMake project before the AGL Flutter bundle is installed. | `flutter-app-plugins` builds the nested Flutter app but does not know the repository's separate `native/` target. | Added ordered native configure/compile tasks, copied the resulting library into Flutter native assets, installed the app unit, and added `flutter-telephony` to `agl-ivi-demo-flutter` (`d65becb5`). |
| I18 | The local source checkout has no Git remote, while the AGL recipe names a GitHub source and pinned revision. | Validation can use a clean local source snapshot, but a normal BitBake fetch requires the repository, branch, commit and sdbus-c++ submodule to be published. | Built with a clean `externalsrc` snapshot to validate compilation and image integration. Publishing the pinned source remains O04 and must precede a reproducible normal-fetch build. |
| I19 | Raw `PropertiesChanged` coverage used only the C++ mock, and a service-owner signal with a truncated body could throw from the native match callback. | The direct sdbus-c++ signal decoder assumed all matched messages contained `sa{sv}as`; no independent emitter exercised malformed frames, foreign senders or variant mismatches through Dart. | Added a minimal dbus-python simulator and Dart FFI integration test for initial snapshots, malformed/wrong-type/unknown/foreign signals, invalidation precedence, duplicate removals and same-path call/transport reuse. Malformed bodies are now ignored at the native boundary; all ten CTests pass (`dacace8`). |
| I20 | The scaffold license was unresolved and the FFI/loader provenance was not explicit. | The port reused Apache-2.0 implementation patterns while its original telephony implementation had no selected project license. | Acknowledged `bluez_native`, `appstream_dart`, and sdbus-c++; marked the adapted FFI codec/type organization and loader; adopted BSD-3-Clause for the project and retained Apache-2.0 for derived code (`7b41ab3`, `a3a645c`). |
| I21 | The package retained only Flutter's legacy Linux CMake bundling and did not provide the Native Assets hook used by the BlueZ siblings. | Plain `dart run` and `dart test` needed a manually built library or `PWT_NATIVE_LIB`, and the loader had no asset-ID path. | Added a Linux Native Assets CMake hook, package dependencies, OS validation, generated resolver binding and `pwt_library_path` C ABI. The public client loads the hook artifact without an override, while Flutter CMake and AGL paths remain available (`56cee38`). |
| I22 | The first GCC 15 coverage workaround ignored all inconsistent and negative lcov records, while coverage and AGL packaging validation were absent from GitHub Actions. | Capturing every test, third-party and system object exposed lcov parser defects; the CI native job also lacked the Flutter SDK required by its default integration-test configuration. | Capture only production target objects and exclude system/third-party headers without ignored errors; install Flutter and lcov in the native job, resolve both package trees, and run coverage plus packaging validation on every push and pull request (`0793e3d`). |
| I23 | The 0.0.1 manifest and changelog still contained scaffold text and no source URL. | Publication metadata had not been finalized. | Add the repository/issue URLs, an accurate description, and initial release notes; move `docs/agl_build.md` to `doc/agl_build.md`. |
| I24 | Pub's working-tree archive included untracked internal planning files. | There was no explicit publication exclusion policy. | Add `.pubignore` for planning, Git, editor, cache, coverage and binary artifacts while retaining required native sources and licenses. Planning files remain local and untracked per the user's latest clarification and are excluded from pub.dev. |
| I25 | Internal constructors and cache mutation methods were public, and raw generated bindings appeared as a public library. | Dart named constructors/helpers lacked private prefixes and ffigen wrote directly under `lib/`. | Make internal object construction/mutation private, generate `lib/src/ffi/bindings_generated.dart`, update callers/tests/verifier, and document all 88 public API elements. |
| I26 | The Dart timeout accepted values above the fixed native 30-second deadline. | A configurable reply wait was confused with cancellation or extending native execution. | Reject nonpositive timeouts and operation waits above 30 seconds; document unknown remote outcomes, late replies and temporary busy gateways. Constructor-boundary regressions and the existing late-reply test cover the contract. |
| I27 | Release cleanup unnecessarily raised the SDK floor above the known AGL Flutter 3.38.3/Dart 3.10.1 baseline. | Host SDK versions were mistaken for minimum requirements. | Restore Dart 3.10.1, declare Flutter 3.38.3, and allow compatible 1.x/2.x `code_assets`/`hooks` versions. Keep current stable dependency support, remove unused `plugin_platform_interface`, and add minimum/stable Flutter CI analysis. |
| I28 | Downstream binary publishers lacked native dependency notices and static-link rebuilding guidance. | The original BSD license and scattered nested license files did not explain redistribution of the combined shared library. | Add `THIRD_PARTY_NOTICES.md` identifying bundled/derived licenses, retained source locations, and the LGPL accompanying-source/rebuild/replacement route. Target image recipe licensing remains O05. |
| I29 | CI formatting referenced the removed `example/lib` directory, clean analysis lacked the nested example's dependencies, and build-hook/codec regressions were not run. | CI had not followed the example split and release checks; cached nested dependencies hid the clean-checkout analysis failure. | Resolve both package trees in the analysis matrix, format the real Dart directories, run focused tests in the native lane, and compare generator output with its pre-generation snapshot so relocation changes remain reviewable before commit. |

| I30 | A relocated CLI could execute a replacement library beside an unrelated loaded DLL; a missing asset could load code from the working directory. | SONAME, mapped-directory sibling and CWD searches widened the trust boundary. | Prefer the declared asset, retain only explicit overrides and fixed executable-relative legacy locations, and remove ambient discovery. Regression tests now reject both previously reproduced failures while preserving intentional overrides and legacy loading. |
| I31 | An arm64 CLI could contain an x86-64 library; a fake AArch64 CMake toolchain could emit host machine code. | The hook checked OS only and the cross guard trusted labels/sysroot. | Reject cross-architecture hook requests, validate the completed native target's ELF machine/class and ABI, and track validator/export-map dependencies. Foreign-target and wrong-class regressions pass. |
| I32 | CI left publication checks manual and the archive smoke test used Git's file set rather than pub's. | Excluded native sources/private notes were not covered by runtime package checks; Python fixture dependencies were implicit. | CI now installs explicit prerequisites, selects system Python, runs packaging regressions and the full generation/bundle/pub-file-set smoke test. Copy pub's selected paths without recursion, reject private local paths, and build/run the selected package. Scratch probes reject an omitted native source and an included task.md. |

### Open Issues

| ID | Open issue | Impact and required closure |
| --- | --- | --- |
| O01 | The real AGL Yocto build now proves the source cross-build, but target-prebuilt equivalence has not been run through the same AArch64 toolchain. | T20 remains open until the produced AArch64 artifact is accepted through the explicit prebuilt path and shown to provide the same filename, SONAME, ABI, dependencies and bundle location. |
| O02 | No connected AGL target and consented phone/network test setup is available. | T22 must verify target introspection, policy as the application user, incoming/outgoing calls, DTMF, volume, SCO audio in both directions, supported multi-call cases and reconnect behavior. |
| O03 | The target distro may patch the apparent PipeWire 1.6.6 `Call1.Get` defect. | Record target behavior during T22. The library already avoids dependence on that method by using snapshots and `GetAll`; no compatibility workaround should hide unrelated errors. |
| O04 | Normal recipe fetch and offline reuse have not been revalidated for the release revision. | `origin` is now configured for `https://github.com/jaydon2020/pipewire_telephony_native.git` on `main`. Publish the intended recipe source revision and pinned submodule, update the recipe revision if necessary, and run BitBake without `externalsrc`; do not assume the earlier branch/revision is the current release. |
| O05 | The source licenses are now explicit, but the AGL recipe still uses `LICENSE = "CLOSED"`. | Before T23, replace it with a checksum-backed expression covering BSD-3-Clause project code and the Apache-2.0, MIT, LGPL-2.1/exception, and BSD components incorporated into the packaged native library. |

## Foundation

### T00 - Align the architecture and task checklist

- [x] Deliverable: this checklist and updated architecture incorporating the review.
- Depends on: none.
- Acceptance: design covers 11 methods, 11 properties and three setters; owner
  tracking, identity validation, shutdown and AGL packaging have explicit tasks.
- Commit: none; planning files remain local and untracked per the user's latest
  2026-10-25 clarification. `.pubignore` excludes them from the package archive.
- Evidence: architecture updated for the media-style port and complete PipeWire
  1.6.6 telephony surface on 2026-09-16.

### T01 - Initialize the Flutter FFI plugin

- [x] Deliverable: clean Linux `plugin_ffi` scaffold in an independent Git
  history, matching the first step of `bluez_media_native`.
- Depends on: T00.
- Acceptance: root and example analysis pass; only generated scaffold files are
  committed; no implementation from `main` is inherited.
- Commit subject: `chore: initialize Flutter FFI package`.
- Evidence: root and example `flutter analyze` pass on 2026-09-16; root commit
  `9684b00` contains only the generated scaffold.

### T02 - Add the native structure and sdbus-c++

- [x] Deliverable: media-style `native/` tree, static test core, shared plugin
  library and sdbus-c++ submodule pinned initially to v2.2.1 at
  `28b78822cfc5fbec4bd9906168493e9985f586ed`. Point Linux CMake and ffigen at
  `native/`; remove the generated `src/` implementation in this task.
- Depends on: T01.
- Acceptance: host compilation succeeds with the CMake 3.22/C++23 baseline;
  Flutter builds the shared library, dependency source/license is reproducible,
  and no duplicate generated C target remains. Record unavailable AGL SDK checks
  as pending without blocking host work.
- Commit subject: `feat: add native structure and sdbus-cpp submodule`.
- Evidence: sdbus-c++ is pinned at `28b7882`; direct CMake configure/build
  produces both native targets against GCC 15.2.0 and libsystemd 259; ffigen,
  root analysis and the Flutter Linux debug build pass on 2026-09-16. No AGL SDK
  was available, so target compilation remains pending for T20/T22.

### T03 - Add PipeWire telephony XML and generated proxies

- [x] Deliverable: reviewed PipeWire 1.6.6 XML for ObjectManager,
  AudioGateway1, AudioGatewayTransport1 and Call1; generated sdbus-c++ proxy
  headers and a reproducible generation script, matching the media port pattern.
- Depends on: T02.
- Acceptance: XML covers all 11 methods, all 11 properties and three writable
  properties with exact signatures; regeneration produces no diff; compatibility
  `org.ofono.*` aliases are excluded.
- Commit subject: `chore: add PipeWire telephony D-Bus interfaces and generated proxies`.
- Evidence: the pinned v2.2.1 `sdbus-c++-xml2cpp` parses all four XML files;
  root-relative generated headers compile together and regenerate byte-for-byte
  without embedding the checkout path. Automated
  counts confirm 11 telephony methods, 11 properties, three writable properties
  and no `org.ofono` aliases on 2026-09-16.

### T04 - Add development tooling and Dart API DL

- [x] Deliverable: media-style CI/development scripts for proxy regeneration,
  formatting, static analysis, sanitizers and coverage; vendor the Dart API DL C
  source/header from the installed SDK and exclude upstream files from lint tools.
- Depends on: T02; can proceed with T03.
- Acceptance: scripts are documented, noninteractive and pass from a clean tree;
  the Dart DL shim compiles as C while the bridge compiles as C++.
- Commit subject: `chore: add native tooling and Dart API DL`.
- Evidence: Dart SDK 3.13.2 revision `60a57cd` is recorded with its BSD license;
  both native targets compile the shim as C. Direct build, clang-format,
  clang-tidy, ASan/UBSan, coverage, Flutter analysis and Linux debug bundling
  pass on 2026-09-16; generated and vendored files are excluded from linting.

### T05 - Define and test the JSON contract

- [x] Deliverable: vendor only upstream Glaze v8.3.0's `include/glaze` headers,
  license and provenance; add C++ DTOs and Dart codec/types for gateway, call,
  transport, startup, lifecycle, request, reply and error messages. Use
  architecture section 7 for identity, request and sequence fields.
- Depends on: T03, T04.
- Acceptance: real Glaze/Dart cross-language fixtures round-trip UTF-8, nullable
  values, unknown states, booleans and bytes. Reject malformed, wrong-type,
  unsupported-version and oversized messages; preserve empty versus missing.
  Enforce the 1 MiB limit and closed operation set. The complete Glaze project
  must not be vendored.
- Commit subject: `feat: define telephony ffi protocol`.
- Evidence: upstream Glaze is pinned at `dce5e0f` with only `include`, license
  and provenance vendored. Native CTest and Dart tests pass against shared JSON
  fixtures for all envelopes and edge cases; formatting, clang-tidy, ASan/UBSan,
  Flutter analysis and Linux debug bundling pass on 2026-09-16.

### T06 - Implement the C ABI and safe client context

- [x] Deliverable: version query, synchronized Dart DL initialization, client
  allocation/start, submission, stop, destruction and buffer release. Add the
  non-reused token registry, bounded queue and reserved stop wakeup. Generate C
  declarations with ffigen and wrap allocation/release in the Dart facade.
- Depends on: T05.
- Acceptance: null, bogus, retired and double-destroyed tokens are safe; input
  bytes are copied before return; exceptions never cross C; queue admission is
  bounded to 64 queued commands. Registry locking never covers a blocking
  join. Unit-test queue/stop behavior before wiring the real bus in T08.
- Commit subject: `feat: add telephony ffi lifecycle`.
- Evidence: native lifecycle tests pass for null, bogus, retired and repeated
  destruction, copied input, malformed input, the 64-request bound and reserved
  stop wakeup. Dart FFI tests, analysis, clang-tidy and clean ASan/UBSan pass;
  the original shared object exported only eight `pwt_*` symbols on 2026-09-16;
  the Native Assets resolver later added the ninth `pwt_library_path` symbol.

### T07 - Build a private D-Bus test service

- [x] Deliverable: test-owned daemon and mock telephony service with nested
  ObjectManagers, reviewed XML, configurable properties/replies and owner changes.
  Use an internal test-only bus-address override.
- Depends on: T03; can run alongside T05/T06.
- Acceptance: fixtures exercise root and gateway paths and exact variants;
  failed tests still terminate their mock/daemon. No hardware or production bus
  access is needed. Native tests use GTest/CTest and Dart tests use package:test.
- Commit subject: `test: add mock pipewire telephony service`.
- Evidence: CTest passes under `dbus-run-session` with nested managers, empty and
  dynamic trees, all 11 method signatures, all three writable property variants,
  injected exact errors and unique-owner replacement. The full suite also passes
  ASan/UBSan, Dart tests and analysis on 2026-09-16.

### T08 - Connect, track the owner and shut down

- [x] Deliverable: one native owner thread for connection, proxies, asynchronous
  replies and queue dispatch using sdbus-c++ poll integration. Implement unique
  owner tracking before discovery and the Dart client lifecycle from section 5.
  Bus choice belongs to the constructor; expose state/stateChanged/lastError.
- Depends on: T06, T07.
- Acceptance: empty service connects; missing service, access denial, concurrent
  connect, owner replacement during startup and the 30-second default deadline
  return defined results. Closing during startup or while the queue is full
  terminates cleanly. Offload startup/join work from the UI isolate. Unavailable
  and closed clients require a new instance to reconnect.
- Commit subject: `feat: connect telephony client to dbus`.
- Evidence: private-bus native and Dart integration tests pass for empty-service
  startup, missing owner, exact AccessDenied propagation, concurrent connect and
  close, close during startup, owner replacement/loss and queued-load shutdown.
  Manual sdbus poll integration covers both bus descriptors and command eventfd;
  ASan/UBSan, clang-tidy, analysis and Flutter Linux bundling pass on 2026-09-16.
  Automatic discovery now checks the current process's session bus before its
  system bus while retaining explicit scopes. A two-daemon Dart integration
  test proves session preference, fallback from an empty session bus, and
  fallback when the configured session bus is unreachable. Documentation
  records the Unix user/session boundary and recommends explicit system scope
  for deterministic AGL deployments.

## Discovery and Commands

### T09 - Discover and invalidate gateways

- [x] Deliverable: root enumeration, AudioGateway1 properties, Dart gateway cache
  and gatewayAdded/gatewayRemoved/gatewayChanged streams. Allocate incarnations.
- Depends on: T08.
- Acceptance: empty/multiple gateways, live additions/removals and owner loss
  update collections before notifications. Re-added paths have new identities;
  stale objects fail locally and natively. Never construct numeric path suffixes.
- Commit subject: `feat: discover pipewire audio gateways`.
- Evidence: root ObjectManager snapshots and live signals cover empty and multiple
  gateways without synthesizing paths. Native and Dart integration tests verify
  typed properties, cache-before-notification ordering, owner-loss clearing and
  renewed incarnations after same-path reuse. Seven CTests, five ASan/UBSan
  tests, Dart tests, analysis, clang-tidy, formatting and the Flutter Linux
  example build pass on 2026-09-16.

### T10 - Discover and invalidate calls

- [x] Deliverable: enumerate each gateway's ObjectManager; add call properties,
  parent association, aggregate client.calls and callAdded/Removed/Changed streams.
- Depends on: T09.
- Acceptance: calls predating connect and calls created during root/gateway
  enumeration are present when ready. Parent loss invalidates all children even
  without child signals. Late replies and reused paths cannot revive old calls.
- Commit subject: `feat: discover pipewire phone calls`.
- Evidence: each discovered gateway owns a nested ObjectManager registry sharing
  the client's monotonic incarnation allocator. Startup drains queued signals
  before publishing one gateway/call snapshot. Native and Dart integration tests
  cover pre-existing and live calls, direct and parent-driven removal, same-path
  reuse, aggregate/per-gateway cache ordering, stale wrappers and owner loss.
  Seven CTests, five ASan/UBSan tests, Dart tests, analysis, clang-tidy,
  formatting and Flutter Linux bundling pass on 2026-09-16.

### T11 - Synchronize properties and refresh

- [x] Deliverable: partial updates, invalidation-aware nullable getters, internal
  revision handling and scope-specific GetAll refresh. Gateway and call objects
  expose propertiesChanged; transport uses the same machinery in T16.
- Depends on: T10.
- Acceptance: missing differs from empty, false and zero; unknown state strings
  survive decoding. Subscribe-before-enumeration, concurrent refresh, removed
  interfaces and stale replies pass ordering tests. Confirm properties with
  GetAll rather than depending on the apparent baseline Call1.Get defect.
- Commit subject: `feat: synchronize telephony properties`.
- Evidence: a service-wide PropertiesChanged match is installed before discovery;
  gateway and call registries merge typed partial values, publish invalidations
  as null, and use weak-lifetime, revision-guarded GetAll calls to coalesce
  concurrent refresh work without reviving removed objects. Native and Dart
  integration tests preserve empty strings, zero, false and unknown states,
  observe null-to-refreshed transitions, and treat disconnected calls as
  terminal. Seven CTests, five ASan/UBSan tests, Dart tests, analysis,
  clang-tidy, formatting and Flutter Linux bundling pass on 2026-09-16.

### T12 - Complete the asynchronous operation contract

- [x] Deliverable: per-operation result ports, pending IDs, identity checks at
  native dispatch, one mutation per gateway, deadlines and structured exceptions.
  Native owner exclusively manages reply slots and cancellation.
- Depends on: T11.
- Acceptance: every request completes once and releases its port on success,
  immediate rejection, remote error, timeout, close or owner loss. Reject stale
  incarnations before D-Bus dispatch. Test InvalidState/NotSupported/InProgress/
  CME and local busy errors. Timed-out operations have unknown remote outcome,
  trigger reconciliation and are never replayed. Results cannot imply event-port
  ordering. A closed result port retires its request without killing the client.
- Commit subject: `feat: add asynchronous telephony commands`.
- Evidence: each Dart operation owns a request ID and receive port while the
  native owner thread validates client generation, path, interface and object
  incarnation before asynchronous dispatch. Native pending state enforces one
  mutation per gateway, retires requests before posting exactly one result, and
  fails them on close or owner change. Native and Dart integration tests cover
  concurrent reads, stale/busy rejection, close with an in-flight reply, exact
  InvalidState/NotSupported/InProgress/CME errors, and a closed timed-out result
  port followed by a successful request. Native timeouts report unknown remote
  outcome and schedule revision-guarded gateway/call reconciliation without
  replay. Seven CTests, five ASan/UBSan tests, Dart tests, analysis, clang-tidy,
  formatting and Flutter Linux bundling pass on 2026-09-16.

### T13 - Dial and send DTMF

- [x] Deliverable: Dial and SendTones through the complete Dart/FFI/D-Bus path.
- Depends on: T12.
- Acceptance: validate the exact character rules in architecture section 4 at
  both input boundaries, reject embedded NUL, test dial length boundaries and
  empty DTMF compatibility. Dial completes with no call path; events identify calls.
- Commit subject: `feat: add telephony dialing and dtmf`.
- Evidence: `PipeWireAudioGateway.dial` and `sendTones` return `Future<void>`
  from the per-request reply port and dispatch the exact `s` arguments to the
  reviewed D-Bus methods. Dart and native codec boundaries independently enforce
  `[0-9+*#,ABCD]{1,80}` for Dial and `[0-9*#A-D]*` for DTMF, including embedded
  NUL rejection and empty DTMF compatibility. Focused integration tests cover
  valid full alphabets and 80-character Dial input; native codec tests cover
  malformed, empty and overlong inputs. Seven CTests, five ASan/UBSan tests,
  Dart tests, analysis, clang-tidy, formatting and Flutter Linux bundling pass
  on 2026-09-16.

### T14 - Answer, reject and hang up

- [x] Deliverable: Call1.Answer, Call1.Hangup and AudioGateway1.HangupAll.
- Depends on: T12; can run alongside T13.
- Acceptance: exact discovered target and empty signatures verified; incoming
  answer/reject and remote state errors covered. HangupAll does not promise to
  release waiting calls. No optimistic state transitions or automatic retries.
- Commit subject: `feat: add phone call answer and hangup`.
- Evidence: typed `PipeWireCall.answer`, `PipeWireCall.hangup` and
  `PipeWireAudioGateway.hangupAll` dispatch the reviewed empty D-Bus signatures
  against their discovered objects. Integration tests cover all three success
  paths, preserve an exact remote InvalidState name/message, and confirm that
  successful replies do not optimistically remove or transition cached calls.
  Seven CTests, five ASan/UBSan tests, Dart tests, analysis, clang-tidy,
  formatting and Flutter Linux bundling pass on 2026-09-16.

### T15 - Set HFP volumes

- [x] Deliverable: SpeakerVolume and MicrophoneVolume setters.
- Depends on: T12; can run alongside T13/T14.
- Acceptance: accept integers 0..15 and reject other inputs before byte conversion;
  send exact `y` variants. Confirm cache through signals or GetAll, including a
  successful write where the peer emits no signal. Preserve Set errors.
- Commit subject: `feat: control hfp call volume`.
- Evidence: gateway speaker and microphone setters validate `0..15` in Dart and
  the native codec before byte conversion, issue exact Properties.Set byte
  variants, and keep the per-gateway mutation busy until a confirming GetAll
  refresh completes. The mock deliberately emits no property signal; integration
  tests still observe confirmed cache updates for boundary values 0 and 15 and
  preserve an exact remote Set error without changing cached state. Seven CTests,
  five ASan/UBSan tests, Dart tests, analysis, clang-tidy, formatting and Flutter
  Linux bundling pass on 2026-09-17.

### T16 - Expose SCO transport

- [x] Deliverable: optional same-path transport object, State/Codec/RejectSCO,
  transport propertiesChanged/refresh, Activate and setRejectSco.
- Depends on: T12.
- Acceptance: exact string/byte/boolean variants; interface removal/re-addition
  changes transport incarnation and gateway notification. Unknown codec/state
  preserved. Client startup never activates SCO or changes RejectSCO implicitly.
- Commit subject: `feat: add sco transport control`.
- Evidence: root discovery now creates an optional same-path typed transport
  with an independent incarnation and revision stream. Startup and live events
  preserve raw unknown states and byte codec IDs; partial changes, refresh,
  interface removal/re-addition and parent invalidation use the existing guarded
  cache machinery. Activate and boolean RejectSCO Set use the shared asynchronous
  command path, with GetAll confirmation when no Set signal is emitted. Native
  tests prove startup performs no Activate or RejectSCO write and that interface
  reuse renews identity while notifying the gateway. Seven CTests, five
  ASan/UBSan tests, Dart tests, analysis, clang-tidy, formatting and Flutter
  Linux bundling pass on 2026-09-17.

### T17 - Support multi-call operations

- [x] Deliverable: SwapCalls, ReleaseAndAnswer, ReleaseAndSwap, HoldAndAnswer and
  CreateMultiparty.
- Depends on: T12.
- Acceptance: all five names/signatures and success/remote-error paths tested;
  operations stay scoped to one gateway; phone/network support is not inferred
  merely from method presence. No invented Hold/Resume/Transfer methods.
- Commit subject: `feat: add multi-call controls`.
- Evidence: the gateway exposes exactly SwapCalls, ReleaseAndAnswer,
  ReleaseAndSwap, HoldAndAnswer and CreateMultiparty as asynchronous empty-
  signature operations. Integration tests execute every success path and inject
  an exact NotSupported response for every method, preserving phone/network
  capability errors without optimistic state or inferred support. The existing
  per-gateway mutation gate scopes all five operations to the discovered gateway.
  Seven CTests, five ASan/UBSan tests, Dart tests, analysis, clang-tidy,
  formatting and Flutter Linux bundling pass on 2026-09-17.

## Integration and Release

### T18 - Exercise lifecycle behavior across the complete API

- [x] Deliverable: integrated regressions for lifecycle handling already introduced
  in T08-T12, including every method/property operation.
- Depends on: T13, T14, T15, T16, T17.
- Acceptance: owner replacement, bus failure, parent removal, identical path
  reuse, close under load, late result and event-port failure cannot target a new
  object or strand a Future. Service loss is observable through stateChanged;
  a fresh client can reconnect. Paused listeners do not prevent resource cleanup.
- Commit subject: `test: cover telephony lifecycle races`.
- Evidence: the private integration bus now exposes its daemon PID so the final
  lifecycle test exercises real bus loss. Integrated Dart regressions cover
  mixed gateway/call/transport operations under close, late replies, a closed
  native event port, paused state/object listeners, owner replacement followed
  by a fresh client, and bus failure without stranded close. These complement
  existing parent removal, same-path gateway/call/transport reuse and owner-loss
  cache-ordering tests. The run also found and fixed synchronous state-stream
  reentrancy when `close()` is called from an unavailable notification. Seven
  CTests, five ASan/UBSan tests, Dart tests, analysis, clang-tidy, formatting and
  Flutter Linux bundling pass on 2026-09-17.

### T19 - Package and verify the Linux plugin on the host

- [x] Deliverable: media-style Linux plugin bundling using the T02 core/shared
  targets, loader, binding/proxy-regeneration checks, private symbols, sanitizer
  and archive checks.
- Depends on: T18. Until this task, tests load the explicit CMake-built artifact.
- Acceptance: fresh archive without `.git` builds offline with supplied sources;
  Dart loads the bundled asset; public symbols are restricted to the C ABI.
  Run ASAN/UBSAN and separate thread-sanitizer checks, preserving actionable
  diagnostics. Verify multiple clients and loading alongside sibling libraries.
- Commit subject: `build: package and verify telephony native assets`.
- Evidence: the Flutter debug bundle contains and loads the native library after
  relocation while all three available sibling native libraries are loaded. Its
  dynamic symbol table originally exposed exactly eight `pwt_*` C ABI functions.
  Native Assets support adds only the ninth resolver, `pwt_library_path`. A
  generated Git tree archive, with the pinned sdbus-c++ submodule source
  supplied, configures and builds without repository metadata. Binding/proxy
  regeneration is clean; two concurrent Dart clients pass on the private bus;
  seven host CTests, Dart tests, Flutter analysis/build, clang-tidy, five
  ASan/UBSan tests and five separate TSAN tests pass on 2026-09-17.

### T20 - Implement AGL cross-build and prebuilt packaging

- [ ] Deliverable: documented CMake SDK toolchain/sysroot path and explicit prebuilt
  library input to plugin CMake. Isolate build caches by target and validate
  artifact ELF architecture, exported ABI and runtime dependencies.
- Depends on: T19 and the SDK information/check from T02.
- Acceptance: build with target compiler/pkg-config/sysroot without executing
  target binaries on the host. Prebuilt and cross-built artifacts produce the
  same bundled plugin library identity; wrong architecture/ABI fails. Yocto fetch supplies
  dependencies before the offline build. No host library is labeled as target.
- Commit subject: `build: support agl telephony artifacts`.
- Evidence: the implementation isolates its target build directory,
  forbids host compilation and target test execution,
  and validates prebuilt machine, filename/SONAME, exact C ABI, runtime
  dependencies and search paths. Host checks prove valid prebuilt configuration
  and rejection of wrong machine, incomplete ABI and host-as-target builds; all
  seven host CTests and host/archive Flutter packaging still pass on 2026-09-17.
  A real AGL 21.93.0 Yocto build for `raspberrypi5` cross-compiled the source with
  the AArch64 compiler, target sysroot and target `libsystemd`; package QA passed,
  and the result has the expected SONAME, exact C ABI exports, target runtime
  dependencies and no RPATH/RUNPATH. The Flutter app package and complete
  `agl-ivi-demo-flutter` WIC image passed all 12,557 tasks on 2026-09-19. T20
  remains unchecked until the same target artifact passes the explicit prebuilt
  path and normal BitBake source fetch is reproducible (O01/O04).

### T21 - Deliver the Flutter exerciser and usage guide

- [x] Deliverable: gateway/call list, explicit phone selection, supported commands,
  property displays, error state and explicit reconnect; document desktop/AGL use.
- Depends on: T19; can proceed alongside T20.
- Acceptance: Linux release bundles the library; test empty, incoming/outgoing,
  multi-call, unsupported operation and service-loss views using the private mock.
  Keep Bluetooth pairing and audio routing owned by their existing integrations.
- Commit subject: `feat: add flutter telephony example`.
- Evidence: the responsive Flutter exerciser exposes every gateway, call and SCO
  property plus all 11 methods and three setters, with explicit phone selection,
  operation errors and fresh-client reconnect. The private-bus Flutter test
  drives empty, incoming, dialing, multiparty, unsupported multi-call, service
  loss and reconnect states at 1280x850 and 390x780 without layout errors. Eight
  CTests, root/example analysis, root Dart tests, clang-tidy and the Linux release
  build pass; the release bundle contains `libpipewire_telephony_native.so` on
  2026-09-17. The usage guide preserves BlueZ pairing and WirePlumber/AGL audio
  routing ownership. Live desktop verification found WirePlumber owning
  `org.pipewire.Telephony` on the user bus and returning `/org/pipewire/Telephony/ag1`
  with both expected gateway and transport interfaces. Both examples now use
  session-first automatic discovery while the AGL guidance retains explicit
  system-bus behavior.
  The examples now mirror `bluez_media_native`: focused standalone Dart files
  cover discovery, watch, gateway and call workflows while
  `example/flutter_telephony/` is the dedicated full UI Flutter package. Shared
  CLI parsing and printing stay in `telephony_example_utils.dart`; there is no
  monolithic dispatcher. Read-only examples were verified against the live
  desktop gateway; nested debug/release bundling, archive packaging and all nine
  CTests pass.

### T22 - Verify on the AGL target

- [ ] Deliverable: versioned hardware record with target introspection, existing
  call discovery, board/SDK/image, phone/network, codec, policy and routing details.
- Depends on: T20, T21 and test hardware.
- Acceptance: run as agl-driver with destination-specific permissions; verify
  method access and live signals, incoming/outgoing/reject/hangup/DTMF, volume,
  SCO, supported multi-call scenarios, service/phone reconnect and both audio
  directions. Inspect Call1.Get behavior for distro patches. Record unsupported
  phone features separately from untested or failing library functionality.
- Commit subject: `docs: record agl telephony verification`.
- Staging evidence: AGL recipe commit `d65becb5` installs the full Flutter UI and
  `libpipewire_telephony_native.so` into `agl-ivi-demo-flutter`. The generated
  Raspberry Pi 5 manifest contains `flutter-telephony aarch64 1.0+git`, and its
  rootfs contains the AGL app systemd unit and Flutter 3.38.3 release bundle.
  This is build/image evidence only: no board boot, D-Bus policy, phone-call or
  two-way audio acceptance item is marked passed.

### T23 - Audit coverage and prepare release documentation

- [ ] Deliverable: API coverage ledger, limitations, deployment guide and changelog.
- Depends on: T22.
- Acceptance: all gates below pass and target-specific open checks are resolved;
  no baseline API member is unimplemented. Record artifacts and test evidence.
  Publishing is a separate user-directed action.
- Commit subject: `docs: finalize telephony release readiness`.

### T24 - Prepare the host-reviewed pub.dev 0.0.1 package

- [x] Deliverable: release metadata, a deliberate archive file list, private
  implementation boundaries, complete public API docs, dependency compatibility,
  timeout validation, and third-party redistribution guidance.
- Depends on: T19, T21 and the implemented API; this task does not mark T20,
  T22 or the full AGL acceptance in T23 complete.
- Acceptance: root/example analysis and formatting pass, focused Dart tests and
  all ten private-bus CTests pass, generation/bundle/archive checks pass, and a
  clean committed-tree `dart pub publish --dry-run` has zero warnings. Preserve
  the minimum AGL SDK constraint and test its dependency resolution/API checks.
- Commit subject: `fix: prepare telephony package for pub.dev release`.
- Review scope: one client per Dart isolate with asynchronous calls, property
  signals, multiple gateways, service loss and explicit awaited shutdown.
- Preliminary evidence: Flutter 3.47.2/Dart 3.13.2 analysis and formatting,
  13 focused Dart tests, all ten CTests, relocated-bundle loading and native
  archive rebuilding passed on 2026-10-25. A metadata-free source snapshot had
  zero publication warnings. `pana` reported 100% API documentation and 150/160;
  the remaining deduction was remote GitHub manifest verification before push.
- Second-review evidence: an isolated Flutter 3.38.3/Dart 3.10.1 checkout resolves
  `code_assets` 1.2.1 / `hooks` 2.0.2, analyzes both package trees and passes all
  13 focused Dart tests plus all ten CTests, including the Flutter example.
  Current stable resolves `code_assets` 2.1.0 / `hooks` 2.2.0 and passes the
  same focused/integration checks. ASan/UBSan and separate TSAN CTests each
  pass 5/5; host prebuilt positive/negative validation passes. Native production
  sources and pinned dependency revisions are unchanged by this release cleanup.
- The minimum/stable analysis matrix resolves the nested package explicitly.
  Stable Dart owns the formatting gate because formatter versions differ on two
  existing test files; minimum Dart still analyzes and runs the actual code.
- Final committed-tree evidence for `573f0fa` on 2026-10-25:
  `dart pub publish --dry-run` exits successfully with **0 warnings**, a 1 MB
  compressed archive, required sdbus-c++ sources/license texts and nested raw
  bindings, and no `task.md` or `ARCHITECTURE.md` in the archive.
  `scripts/verify_host_package.sh` passes regenerated binding/proxy equality,
  exact nine-symbol C ABI, Flutter Linux debug bundling, relocated loading beside
  available sibling libraries and a metadata-free native archive rebuild.
  `git diff --check` and the scoped credential/private-key pattern scan find no
  issues. No production D-Bus call commands were used during this review.
- Review verdict: no remaining publication blocker found for the host-tested
  initial 0.0.1 package at the stated load. Push the release commit before
  publication so repository verification can see the updated remote manifest;
  rerun the dry run from the intended clean checkout. Commit/push and actual
  publication are distinct actions: only the local commit was requested here.
- Limits: hardware call/audio tests, real AGL target-prebuilt equivalence,
  normal BitBake fetch and recipe license updates remain O01-O05. The package
  is a host-reviewed initial 0.0.1 release, not completed AGL certification.

### T25 - Close the loader, architecture and publication-check gaps

- [ ] Deliverable: I30-I32 implementation and verified regressions. Code is
  implemented and tested locally; commit acceptance is still pending. Neither
  planning file is to be included in that commit.
- Commit subject: `fix: secure native loading and validate target artifacts`.
- This supersedes the initial T24 publication verdict: targeted probes found
  loader and architecture failures that passing host tests did not cover.
- Before the fix, all three new ambient-DLL, CWD-fallback and fake cross-compiler
  regression tests failed on the old code.
- After the fix, current Flutter 3.47.2/Dart 3.13.2 passes all 22 focused/build/
  packaging tests, analysis and formatting. Minimum Flutter 3.38.3/Dart 3.10.1
  passes analysis and 21 tests; the foreign-CLI flag probe is explicitly
  inapplicable because that CLI has no --target-arch option. Direct hook and
  CMake architecture checks still run on the minimum SDK.
- All ten private-bus CTests pass. Rebuilt ASan/UBSan and TSAN lanes each pass
  5/5 with post-link validation enabled. Host prebuilt positive/negative checks
  and C++ formatting pass. Production native telephony behavior is unchanged.
- An isolated source snapshot passes the full ffigen/proxy equality, native
  export, relocated Flutter and pub-selected CLI rebuild/load checks with zero
  publication warnings. Excluding the bridge source fails archive compilation;
  including task.md fails the private-file gate. These probes modify scratch
  copies only.
- The hook intentionally supports native compilation only. AGL cross-builds
  use the explicit target toolchain/prebuilt path with SKIP_NATIVE_BUILD=1.
- Real AGL/phone/audio tests and a remote CI run remain unverified. Keep O01-O05
  open. Commit the verified code and rerun publication checks from the intended
  clean release checkout before publishing; keep both planning files local.

## Coverage and Verification Gates

| Surface | Implemented in | Required count |
| --- | --- | --- |
| Dial, SendTones | T13 | 2 methods |
| Answer, Hangup, HangupAll | T14 | 3 methods |
| SwapCalls, ReleaseAndAnswer, ReleaseAndSwap, HoldAndAnswer, CreateMultiparty | T17 | 5 methods |
| Activate | T16 | 1 method |
| Address, SpeakerVolume, MicrophoneVolume | T09/T11 | 3 readable properties |
| LineIdentification, IncomingLine, Name, Multiparty, State | T10/T11 | 5 readable properties |
| Transport State, Codec, RejectSCO | T16 | 3 readable properties |
| SpeakerVolume, MicrophoneVolume, RejectSCO writes | T15/T16 | 3 setters |

Run relevant tests with each task. Full gates use `dart analyze`, `dart test`,
CMake build and CTest, native sanitizers, binding regeneration consistency,
Flutter Linux release packaging, and AGL hardware verification. Generate native
fixtures with actual Glaze; do not test two independently hand-written encoders
and assume their output matches the real library.

Dependencies permit T03/T04 in parallel, T13-T17 after T12, and T20/T21
after T19. An unmet SDK/hardware gate blocks target acceptance, not independent
host work. Never mark a hardware test passed because a mock passed.

Never include these planning files in implementation commits. Keep local notes
updated separately and retain their `.pubignore` exclusions. Tasks are checked
only after the relevant verification and implementation commit pass.
