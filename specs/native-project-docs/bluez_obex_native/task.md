# BlueZ OBEX Native Implementation Tasks

Design contract: [ARCHITECTURE.md](ARCHITECTURE.md).

Status: the repository already implements the broad OBEX/PBAP/MAP surface. This
checklist records that evidence and the remaining work needed to align behavior
and release gates with `bluez_native` and `bluez_media_native`.

## Working rules

Each task is a reviewable deliverable with its own verification. Check a task
only when its acceptance criteria and evidence pass. Use the listed Conventional
Commit subject for implementation work. Keep `task.md` and `ARCHITECTURE.md` out
of implementation commits so planning corrections do not obscure code changes.

Follow the sibling sequence and conventions:

1. Independent Flutter FFI scaffold.
2. `native/` CMake and pinned sdbus-c++.
3. Reviewed XML and reproducible generated proxies.
4. Development scripts and Dart API DL.
5. Versioned wire types/codec and safe C ABI.
6. Client lifecycle and discovery.
7. Session/transfer, PBAP, then MAP interface groups.
8. Native Assets, examples, private-bus integration, AGL and release gates.

Use `bluez_native`'s constructor plus `connect()`, cached objects, focused
property streams, non-reused handle tokens and asynchronous error behavior.
Use `bluez_media_native`'s package structure, native core/shared targets,
code-generation checks, loader, Native Assets packaging and focused examples.

No generic RPC framework, Bluetooth pairing implementation, vCard/bMessage
parser, UI data store, or system policy mutation belongs in this package.

## Issue and resolution ledger

| ID | Issue | Resolution/status |
| --- | --- | --- |
| I01 | The initial implementation was built before a written architecture contract. | This document and `ARCHITECTURE.md` establish the contract without rewriting working foundations. |
| I02 | Blocking native operations could stall the caller isolate. | `ae3b570` introduced the dedicated Dart worker isolate. |
| I03 | Native buffers were borrowed/re-read and fixed-size. | `c144ac3` and `d172e75` introduced owned dynamic result buffers. |
| I04 | D-Bus errors lost their exact remote identity. | `e447125` preserves error names and messages. |
| I05 | Bus failure and service-owner replacement left unsafe client state. | `94d92f8`, `08cf0c5`, and `2e95d5e` contain event-loop failure, invalidate the client and make shutdown idempotent. |
| I06 | Session defaults and folder navigation did not match BlueZ behavior. | `81ab082`, `1525005`, `1a52b3b`, and `dfa0a07` corrected PBAP defaults, ownership and MAP/PBAP navigation. |
| I07 | MAP listing values were decoded with the wrong container shape. | `960a4ee` decodes object-to-dictionary message listings. |
| I08 | Native packaging required manual library setup. | `9a3fc41`, `ad7c145`, and `a6d99a4` added and hardened the Linux Native Assets build. |
| I09 | Public objects are not cached and expose no focused lifecycle/property streams. | Open: T10-T12 align the consumer model with the BlueZ siblings. |
| I10 | Public filter maps become strings and native code guesses D-Bus types from key names. | Open: T13 replaces heuristic conversion with typed profile DTOs. |
| I11 | Proxy regeneration removed checked-in license preambles, so generated output was not byte-for-byte clean. | The generation script now inserts the project preamble deterministically; T03 verifies the result. |
| I12 | CI omits `dart test` and lacks complete binding/archive/ABI checks. | Open: T17-T18 close host release gates. |
| I13 | The Native Assets hook accepted a foreign target architecture without proving that CMake used a cross toolchain, while hook execution strips normal Yocto compiler environment variables. | The hook now requires an explicit CMake toolchain user-define for cross-architecture builds and CMake requires both cross-compiling mode and a sysroot. |

## Open issues

| ID | Open issue | Required closure |
| --- | --- | --- |
| O01 | Exact BlueZ/obexd target revision is not recorded. | Pin the AGL image/package revision and compare its introspection with the six reviewed XML files. |
| O02 | No connected AGL target and consented PBAP/MAP phone matrix is recorded. | Complete T20 with real phone/device evidence; do not substitute simulation. |
| O03 | Target-prebuilt validation and normal offline Yocto fetch are not proven. | Complete T18/T19 with the real target toolchain and packaged dependency sources. |
| O04 | Cached object identity and stale-wrapper rejection are absent from the public model. | Complete T10-T12 before stable API release. |
| O05 | README links `docs/api.md` and `docs/verification.md`, but those files do not exist. | Create them in T21 from the finalized contract and evidence. |

## Foundation

### T00 - Align architecture and task checklist

- [x] Deliverable: project-specific architecture and dependency-ordered task
  checklist grounded in the current repository and both sibling designs.
- Depends on: none.
- Acceptance: all 21 methods and 41 declared properties are accounted for;
  lifecycle, identity, filters, packaging, CI and hardware gates are explicit.
- Commit: none; planning files remain local by project rule.
- Evidence: repository, history, six XML files, public Dart API, C ABI, tests,
  CI, `bluez_native`, `bluez_media_native`, and telephony planning template were
  reviewed on 2026-10-18.

### T01 - Initialize the Flutter FFI package

- [x] Deliverable: independent package scaffold and Linux plugin metadata.
- Depends on: none.
- Acceptance: package resolves and analysis passes.
- Commit subject: `chore: initialize Flutter FFI package`.
- Evidence: `61e8a51`; current `dart analyze` passes.

### T02 - Add native structure and pin sdbus-c++

- [x] Deliverable: CMake shared library, test core and pinned sdbus-c++ submodule.
- Depends on: T01.
- Acceptance: clean host configure/build succeeds with tests enabled; production
  builds do not compile the test core.
- Commit subject: `feat: add native structure and sdbus-c++ submodule`.
- Evidence: `164c031`, `45fdb15`; host CMake and two CTests pass.

### T03 - Review XML and make proxy generation reproducible

- [x] Deliverable: reviewed `Client1`, `Session1`, `Transfer1`,
  `PhonebookAccess1`, `MessageAccess1`, and `Message1` XML plus deterministic
  generated proxy headers, including license preambles.
- Depends on: T02.
- Acceptance: interface count script confirms 21 methods and 41 declared
  properties; regeneration produces no diff in a relocated checkout; no absolute
  paths appear in headers.
- Commit subject: `fix: make obex proxy generation reproducible`.
- Evidence: `423f68e` added XML/proxies and root-relative generation. The
  generation script now inserts deterministic project license preambles and
  regenerates all six headers without a diff on 2026-10-18.

### T04 - Add development tooling and Dart API DL

- [x] Deliverable: format, tidy, sanitizer, coverage and codegen scripts plus
  vendored Dart API DL declarations/implementation.
- Depends on: T02; may proceed with T03.
- Acceptance: all scripts execute with versioned tool discovery and exclude
  generated/vendor sources appropriately.
- Commit subject: `chore: add native development tooling`.
- Evidence: `3d7b4bf`; format, clang-tidy, ASan/UBSan and coverage scripts pass
  on the current host.

### T05 - Define and test the wire codec

- [x] Deliverable: C++ OBEX DTO serialization and Dart decoding for session,
  transfer, phonebook, message access, messages, object lifecycle, errors and
  system-bus device discovery.
- Depends on: T04.
- Acceptance: valid fixtures round-trip; malformed lengths, invalid UTF-8,
  unknown types and allocation bounds fail safely.
- Commit subject: `feat: add obex wire types and codec`.
- Evidence: `b888ecc`, `be5eef6`; codec tests include overrun, impossible list
  count and invalid UTF-8 coverage.

### T06 - Implement a safe C ABI and handle registry

- [x] Deliverable: exported C ABI, non-reused client tokens, owned output
  buffers, thread-local immediate error detail and idempotent destruction.
- Depends on: T05.
- Acceptance: stale/unknown handles never dereference memory; every allocated
  result is released once; C++ exceptions never cross ABI.
- Commit subject: `feat: add obex native bridge`.
- Evidence: `0819f38`, `c144ac3`, `d172e75`, `e447125`, `2e95d5e`; native handle
  lifetime and Dart bridge tests pass.

## Lifecycle and object model

### T07 - Connect, discover and track service ownership

- [x] Deliverable: session-bus OBEX connection, ObjectManager snapshot/signals,
  Properties changes, unique-owner tracking and terminal bus/service failure.
- Depends on: T06.
- Acceptance: initial objects, additions, removals, property changes, owner
  replacement and bus death are observable; native event loop exits safely.
- Commit subject: `feat: add obex client lifecycle`.
- Evidence: `285bb03`, `94d92f8`, `6280c8d`, `08cf0c5`; private-bus scenarios
  cover disconnect, ownership, responsiveness and restart.

### T08 - Keep blocking work off the caller isolate

- [x] Deliverable: one dedicated Dart worker isolate per native client and
  request/reply forwarding for every operation.
- Depends on: T07.
- Acceptance: UI/caller isolate remains responsive; worker exit fails pending
  requests; disposal is idempotent and joins native resources.
- Commit subject: `fix: isolate blocking obex operations`.
- Evidence: `ae3b570`; private-bus `responsive`, `disconnect`, `completion`, and
  restart scenarios pass.

### T09 - Provide system-bus BlueZ device discovery

- [x] Deliverable: paired/connected device metadata and profile UUID filtering
  without coupling to a long-lived `bluez_native` client.
- Depends on: T06.
- Acceptance: result includes address, name, paired, connected and UUIDs; bus
  errors remain typed; no pairing or trust mutation is added.
- Commit subject: `feat: add obex device discovery`.
- Evidence: `3c4548d`, `3a4a4d6`, `dc324e0`.

### T10 - Align client lifecycle with bluez_native

- [ ] Deliverable: public `BlueZObexClient()` constructor, asynchronous
  `connect()`, readiness/service state, and idempotent `close()`.
- Depends on: T08.
- Acceptance: connect once, failed startup, repeated close, close during work,
  paused listeners and worker exit all terminate without leaks or stranded
  Futures. Keep a migration path from static `connect()`/`dispose()` until the
  next breaking release.
- Commit subject: `refactor: align obex client lifecycle with bluez native`.

### T11 - Add cached sessions and transfers

- [ ] Deliverable: client-owned session/transfer caches, add/remove/change
  streams, per-object cached nullable properties, `propertiesChanged`, and
  `refresh()`.
- Depends on: T10.
- Acceptance: subscribe before initial enumeration; update cache before events;
  preserve missing versus empty/zero/false; parent session removal invalidates
  related transfers; terminal statuses and progress remain observable.
- Commit subject: `feat: cache obex sessions and transfers`.

### T12 - Add cached PBAP/MAP objects and identity validation

- [ ] Deliverable: cached phonebook, message-access and message wrappers with
  `(generation, interface, path, incarnation)` identity.
- Depends on: T11.
- Acceptance: same-path interface coexistence and reuse work; removed wrappers
  fail locally and natively; late replies cannot update a new incarnation;
  message/property streams close on removal.
- Commit subject: `feat: cache obex profile objects`.

### T13 - Replace heuristic filters with typed contracts

- [ ] Deliverable: typed PBAP list/pull/search filters, MAP folder/message
  filters and push arguments encoded as exact D-Bus variants.
- Depends on: T06; may proceed alongside T10-T12.
- Acceptance: byte/uint16/bool/string/string-array values preserve type; ranges,
  unsupported fields and embedded NUL fail before dispatch; an advanced raw API
  is explicit and tested if retained.
- Commit subject: `refactor: add typed obex filters`.

## Profile operations

### T14 - Verify complete PBAP behavior

- [x] Deliverable: `Select`, `PullAll`, `List`, `Pull`, `Search`, `GetSize`,
  `UpdateVersion`, `ListFilterFields`, phonebook properties and transfer results.
- Depends on: T07.
- Acceptance: exact signatures and errors pass on a private service; operations
  use the session root and supported search fields; transfer reply is not treated
  as completion.
- Commit subject: `feat: complete pbap support`.
- Evidence: `6e7c076`, `a76933e`, `81ab082`, `1a52b3b`, `dfa0a07`; simulated and
  private-bus tests pass. Typed filter hardening remains T13.

### T15 - Verify complete MAP behavior

- [x] Deliverable: folder navigation/listing, filter fields, message listing,
  inbox update, push/get, message properties and read/deleted setters.
- Depends on: T07.
- Acceptance: exact object/dictionary result shape, transfer lifecycle, folder
  failures and exact remote setter errors pass on a private service.
- Commit subject: `feat: complete map support`.
- Evidence: `6e7c076`, `a76933e`, `b7fc7ae`, `960a4ee`; simulated and private-bus
  tests pass. Typed filter hardening remains T13.

### T16 - Expand lifecycle and malformed-signal integration coverage

- [ ] Deliverable: independent private-bus emitter coverage for malformed,
  wrong-type, foreign-sender, duplicate, reordered and same-path-reuse events,
  plus close under mixed PBAP/MAP/transfer load.
- Depends on: T11-T15.
- Acceptance: no malformed frame escapes a native callback; caches remain
  consistent; pending Futures complete exactly once; fresh client reconnects
  after owner replacement and bus loss.
- Commit subject: `test: cover obex lifecycle races`.

## Packaging and release

### T17 - Make CI enforce the complete host pipeline

- [ ] Deliverable: CI lanes for Dart tests, analysis, Dart/native formatting,
  CTest, proxy and ffigen drift, clang-tidy, ASan/UBSan, coverage and publish dry
  run.
- Depends on: T03, T16.
- Acceptance: every push/PR runs `dart test`; generated sources are clean;
  coverage captures production targets only and fails on real lcov errors.
- Commit subject: `ci: enforce complete obex verification`.
- Existing evidence: current CI covers analysis and most native lanes, but omits
  Dart tests and ffigen consistency.

### T18 - Verify host Native Assets and archive packaging

- [ ] Deliverable: bundled Linux library, exact export check, sibling-library
  coexistence, relocated bundle loading and metadata-free offline archive build.
- Depends on: T17.
- Acceptance: no Git/network access is needed during archive build; dependency
  sources and licenses are present; only intended C ABI symbols are exported;
  two simultaneous clients close cleanly.
- Commit subject: `build: verify obex native assets packaging`.
- Existing evidence: `9a3fc41`, `ad7c145`, `a6d99a4` implement the hook and
  Linux cross-build allowance; the complete acceptance matrix is not recorded.

### T19 - Implement validated AGL build paths

- [ ] Deliverable: documented Yocto/SDK source cross-build and explicit prebuilt
  input with isolated caches and target artifact validation.
- Depends on: T18.
- Acceptance: target compiler/sysroot/pkg-config are used; wrong ELF machine,
  SONAME, ABI, dependencies or RPATH fails; no target binary executes on host;
  normal offline fetch supplies sdbus-c++.
- Commit subject: `build: support agl obex artifacts`.
- Partial evidence: the Native Assets hook now requires an explicit CMake
  toolchain user-define for a foreign architecture, and native CMake rejects a
  host compiler or missing sysroot when that guard is active. Real AGL source
  and prebuilt artifact validation remain open.

### T20 - Verify on AGL with real phones

- [ ] Deliverable: versioned target record for BlueZ/obexd introspection,
  D-Bus policy, PBAP/MAP capabilities, file paths and transfer lifecycle.
- Depends on: T19 and target/phone access.
- Acceptance: as the application user, discover a paired phone; create/remove
  PBAP and MAP sessions; list/pull/search contacts; navigate/list/get/update/push
  messages where supported; set read/deleted; suspend/resume/cancel transfers;
  survive phone disconnect, obexd restart and reconnect. Record unsupported phone
  features separately from library failures.
- Commit subject: `docs: record agl obex verification`.

### T21 - Finalize examples and release documentation

- [ ] Deliverable: focused device/list/watch/PBAP/MAP examples, Flutter phone
  message exerciser, `docs/api.md`, `docs/verification.md`, limitations and
  changelog.
- Depends on: T20.
- Acceptance: examples use only the final public typed API; release bundle
  contains the native library; documentation explains service/session bus,
  consent/privacy, transfer completion, file ownership, errors and recovery.
- Commit subject: `docs: finalize obex release readiness`.

## Coverage and verification gates

| Surface | Required count/task |
| --- | --- |
| Client/session lifecycle | 3 methods, 6 session properties; T07, T10-T12 |
| Transfer control/state | 3 methods, 8 properties; T11, T16 |
| PBAP | 8 methods, 5 properties; T13-T14 |
| MAP access | 6 methods, 1 property; T13, T15 |
| MAP message | 1 method, 21 declared properties, 2 writes; T12, T15 |
| Standard interfaces | ObjectManager snapshot/add/remove, Properties GetAll/change/invalidate, owner changes; T07, T11-T12, T16 |
| Device discovery | system-bus read-only device/UUID query; T09 |
| Packaging | Native Assets, exact exports, archive/offline, sibling coexistence, AGL source/prebuilt; T17-T19 |

Full host gates are `dart format`, `dart analyze`, `dart test`, CMake build and
CTest, clang-format, clang-tidy, ASan/UBSan, coverage, proxy/ffigen regeneration,
Native Assets packaging, ABI/export inspection and archive rebuild. Hardware
gates require actual target and phone evidence. Never mark a hardware task
complete because simulation or a private D-Bus service passed.
