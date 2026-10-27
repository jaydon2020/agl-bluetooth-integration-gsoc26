# Native project architecture and task bundle

This directory collects the architecture contract and implementation checklist
for the four native Dart/Flutter Bluetooth packages used by the project.

## Contents

| Project | Architecture | Tasks | Source baseline | Document origin |
| --- | --- | --- | --- | --- |
| `bluez_obex_native` | [ARCHITECTURE.md](bluez_obex_native/ARCHITECTURE.md) | [task.md](bluez_obex_native/task.md) | Local checkout `3be5f8a4638958c22dfc5a9e148ac6e68665fab9` | Copied byte-for-byte from the local project |
| `pipewire_telephony_native` | [ARCHITECTURE.md](pipewire_telephony_native/ARCHITECTURE.md) | [task.md](pipewire_telephony_native/task.md) | Local checkout `db241b1e00f1915ab1db79ec2b21a2bd9b6d71c1` | Copied byte-for-byte from the local project |
| `bluez_media_native` | [ARCHITECTURE.md](bluez_media_native/ARCHITECTURE.md) | [task.md](bluez_media_native/task.md) | Upstream release [`v0.3.1`](https://github.com/jaydon2020/bluez_media_native/tree/v0.3.1), commit `2c25cbb5f13b076c2b701c1f6a4081cb085e0551` | Created from the tagged source, README, changelog, public API, native ABI, tests and build hook |
| `bluez_native` | [ARCHITECTURE.md](bluez_native/ARCHITECTURE.md) | [task.md](bluez_native/task.md) | Upstream release [`v0.3.2`](https://github.com/jwinarske/bluez_native/tree/v0.3.2), commit `bad7c236c142dc37428dd0e638fa2c9453463399` | Created from the tagged source, README, changelog, public API, native ABI, tests and build hook |

The baselines were checked on 2026-10-27. `bluez_media_native` release
`v0.3.1` is also the current upstream `main` revision. `bluez_native` has newer
commits on `main`; this bundle deliberately uses the latest stable release so
the architecture describes a reproducible published version.

## Responsibility boundaries

| Package | Primary responsibility |
| --- | --- |
| `bluez_native` | BlueZ adapters, devices, pairing, connection and GATT |
| `bluez_media_native` | AVRCP media control and browsing, A2DP transports, local player registration and cover art |
| `bluez_obex_native` | OBEX sessions, PBAP phonebooks, MAP messages and transfers |
| `pipewire_telephony_native` | HFP call control, gateway/call state and SCO transport observation/control |

These are documentation snapshots, not shared runtime code. Update a copied
file from its owning repository; update a generated file by reviewing the next
tag's public API, native ABI, tests and release notes before changing its
baseline.
