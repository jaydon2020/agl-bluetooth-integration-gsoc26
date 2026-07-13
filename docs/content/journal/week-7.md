---
title: Week 7
description: Progress summary for Week 7 (July 6-12, 2026) of the AGL Bluetooth Integration project.
---

This week focused on moving the Bluetooth pairing work through review. I created
the missing AGL Jira issue, removed package-related changes from the Gerrit
patch, investigated the pairing/disconnection crash, and split the BlueZ
property support into a smaller upstream pull request.

## Status

- **Status**: Completed
- **Timeline**: July 6, 2026 to July 12, 2026
- **Gerrit change**: [AGL Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
- **Jira issue**: [SPEC-5669](https://lf-automotivelinux.atlassian.net/browse/SPEC-5669)
- **Crash report**: [jwinarske/bluez_native issue #4](https://github.com/jwinarske/bluez_native/issues/4)
- **Pull request**: [jwinarske/bluez_native#6](https://github.com/jwinarske/bluez_native/pull/6)

---

## Progress

### 1. Created the AGL Jira Issue

Created the Jira issue `SPEC-5669` for the Bluetooth setup, connection, and
pairing UI work. This replaced the temporary bug tag in the Gerrit change and
gave the homescreen patch a proper AGL tracking issue.

### 2. Removed Package Changes from Gerrit

Updated the Flutter ICS homescreen Gerrit change and removed package-related
changes from the review. This keeps the patch focused on the Bluetooth
connection and pairing UI instead of mixing UI work with native package
maintenance.

### 3. Investigated the Bluetooth Disconnection Crash

Continued investigating the application crash seen during Bluetooth pairing
cancellation, rejection, and disconnection flows. The root cause was identified
as a cross-library compiler toolchain and ABI mismatch, not a logic defect in
the `bluez_native` source code.

### 4. Opened a Focused BlueZ Property PR

Opened `bluez_native` pull request #6 for the BlueZ properties needed by the
pairing flow:

- `setTrusted`, used after pairing so a device can reconnect without repeated
  prompts.
- `Pairable`, used to check whether the adapter can accept pairing requests.
- `Discoverable`, used to check whether the adapter is visible to nearby
  devices.

Keeping this as a focused pull request makes the native API work easier to
review than combining it with the pairing crash investigation.

---

## Links

- **Gerrit change**: [AGL Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887) — Tracks the Bluetooth connection and pairing UI contribution for the Flutter ICS homescreen.
- **Jira issue**: [SPEC-5669](https://lf-automotivelinux.atlassian.net/browse/SPEC-5669) — Tracks the AGL Bluetooth setup, connection, and pairing UI work.
- **Crash report**: [jwinarske/bluez_native issue #4](https://github.com/jwinarske/bluez_native/issues/4) — Tracks the Bluetooth crash investigation that was traced to a compiler toolchain and ABI mismatch.
- **Pull request**: [jwinarske/bluez_native#6](https://github.com/jwinarske/bluez_native/pull/6) — Adds `setTrusted` plus access to the BlueZ `Pairable` and `Discoverable` properties.
