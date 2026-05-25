---
title: Verify Functionality of BlueZ Stack
navTitle: Verify BlueZ Stack
description: Profile-oriented smoke tests for validating BlueZ on an AGL/Raspberry Pi 5 target.
---

Use this page to run focused BlueZ smoke tests on an AGL image. The Qualcomm Linux Bluetooth Guide, updated October 14, 2024 as `80-70015-13 Rev AB`, verifies BlueZ functionality with sample applications on a Qualcomm RB3 Gen 2 Development Kit. This project uses that profile coverage as a technical reference, but adapts the validation target to AGL on Raspberry Pi 5.

The immediate goal is to prove that the platform can bring up the adapter, discover a phone or headset, pair and trust it, connect it, and observe the first audio and media-control signals needed by the AGL Bluetooth integration project.

For adapter and device lifecycle commands, see the [Profile GAP](bluetooth/verify-bluez/profile-gap) subpage. For Bluetooth media audio validation, see the [Profile A2DP](bluetooth/verify-bluez/profile-a2dp) subpage. For telephony call control, see the [Profile HFP](bluetooth/verify-bluez/profile-hfp) subpage. For OBEX-based profile checks, see the [Profile PBAP](bluetooth/verify-bluez/profile-pbap) and [Profile MAP](bluetooth/verify-bluez/profile-map) subpages.

## Reference Profile Matrix

The Qualcomm guide demonstrates Bluetooth profile procedures through Linux sample applications. For AGL, use the same application names as a profile map, then adjust each test to the services available in the target image.

<ProfileMatrix/>

AGL bring-up priority:

- Core smoke tests: GAP, GATT discovery notes, A2DP, and AVRCP observation through BlueZ.
- Audio integration: A2DP nodes and routing through PipeWire and WirePlumber.
- Future or stretch validation: HFP, PBAP, MAP, OPP, FTP, and HOGP unless the AGL image already includes the required telephony, OBEX, or input-device integration.

## Profile Coverage

### General Access Profile

GAP covers basic Bluetooth visibility, discovery, device identity, pairing, bonding, trust, and connection state. Bluetooth Low Energy GAP extends the existing BR/EDR GAP model for BLE devices.

For this project, GAP is the first required smoke test because every higher-level profile depends on a working adapter and a stable device lifecycle.

### General Attribute Profile

GATT is the BLE service framework built on ATT. It is used to discover services and read or write characteristic values on a peer device.

GATT is useful for future profile work, but the first AGL validation milestone remains classic Bluetooth pairing, audio, and media-control behavior.

### Human Interface Device Over GATT Profile

HOGP defines how a BLE device exposes HID services, such as keyboard, mouse, or controller input, over the GATT protocol stack.

Treat HOGP as optional unless the AGL image needs to validate a Bluetooth input device as part of the IVI scenario.

### Advanced Audio Distribution Profile

A2DP defines multimedia audio streaming over Bluetooth. In this project, A2DP must be verified together with PipeWire and WirePlumber so the Bluetooth audio device appears as a usable audio node and can be routed predictably.

Use the [Profile A2DP](bluetooth/verify-bluez/profile-a2dp) subpage for Bluetooth audio connection, media transport, and PipeWire routing checks.

### Hands-Free Profile

HFP defines how an audio gateway, such as a phone, connects to a hands-free device for call control and audio connection.

HFP is future or stretch work for this project unless the target AGL image already includes PipeWire telephony support, SCO routing, and the required call-control policy. Use the [Profile HFP](bluetooth/verify-bluez/profile-hfp) subpage for the PipeWire telephony D-Bus workflow.

### Object Push Profile

OPP defines object exchange between Bluetooth devices, such as contact cards, images, wallpapers, ringtones, or videos.

OPP is not part of the first AGL smoke-test milestone, but it can be validated later with OBEX tooling if object exchange becomes a project requirement.

### File Transfer Protocol

FTP defines file exchange requirements between Bluetooth devices.

FTP should be treated as an OBEX follow-up area, not a blocker for the initial BlueZ, audio, and media-control bring-up.

### Phone Book Access Profile

PBAP enables exchange of phone book objects between a remote device and the local system.

PBAP is useful for an IVI contacts experience, but should be validated after pairing, reconnection, A2DP, AVRCP, and the native Flutter plugin shape are stable. Use the [Profile PBAP](bluetooth/verify-bluez/profile-pbap) subpage for `obexctl` and OBEX D-Bus validation.

### Message Access Profile

MAP defines procedures for exchanging message objects between devices.

MAP is future profile work for messaging UX and should be tested only after the base BlueZ and OBEX paths are available in the AGL image. Use the [Profile MAP](bluetooth/verify-bluez/profile-map) subpage for message-folder, message-listing, and message-download checks.
