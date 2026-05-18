---
title: Verify BlueZ Stack
description: Minimal smoke tests for validating BlueZ on an AGL/Raspberry Pi 5 target.
---

Use this page to run a focused BlueZ smoke test on an AGL image. The goal is not to cover every Bluetooth profile. The goal is to prove that the platform can bring up the adapter, discover a phone or headset, pair and trust it, connect it, and observe the first audio and media-control signals needed by the AGL Bluetooth integration project.

## Prerequisites

Before starting, prepare the target and a nearby Bluetooth device.

- Raspberry Pi 5 running an AGL development image.
- SSH access to the target.
- BlueZ installed and enabled.
- PipeWire and WirePlumber running for audio graph and routing checks.
- A phone, headset, speaker, or other Bluetooth device that can be made discoverable.
- Optional second terminal for `btmon` while running the pairing and connection flow.

Set a shell variable for the remote Bluetooth address once the device appears during scanning:

```
BT_ADDR="XX:XX:XX:XX:XX:XX"
```

## Check Services

Confirm that the Bluetooth daemon is running:

```
systemctl status bluetooth
```

Confirm that the audio session stack is present:

```
wpctl status
```

Success criteria:

- `bluetooth.service` is active.
- `wpctl status` prints PipeWire devices, sinks, sources, or streams.
- No obvious startup failure appears in the service output.

## Inspect The Adapter

Open the BlueZ command-line tool:

```
bluetoothctl
```

Inside `bluetoothctl`, inspect and enable the adapter:

```
show
power on
agent on
default-agent
show
```

Success criteria:

- `show` displays a local controller such as `hci0`.
- `Powered: yes` appears after `power on`.
- The default pairing agent registers successfully.
- The adapter is available before any Flutter plugin code is involved.

## Scan For Devices

Make the phone, headset, or speaker discoverable, then start discovery:

```
scan on
```

Wait until the target device appears, then stop scanning:

```
scan off
```

Success criteria:

- The target device appears with a Bluetooth address and name.
- Discovery can start and stop without restarting `bluetoothd`.
- If the device does not appear, verify that it is discoverable and close enough to the target.

## Pair, Trust, And Connect

Pair with the discovered device:

```
pair <bt_address>
```

Accept the confirmation prompt on both sides if the passkey matches. Then trust and connect the device:

```
trust <bt_address>
connect <bt_address>
devices
info <bt_address>
```

Success criteria:

- Pairing completes without an authentication error.
- `devices` lists the remote device.
- `info <bt_address>` reports `Paired: yes`.
- `info <bt_address>` reports `Trusted: yes`.
- `info <bt_address>` reports `Connected: yes` after the connect command.
- The device exposes UUIDs that match its role, such as audio sink/source, AVRCP, hands-free, phone book, or message access.

## Verify Pairing Persistence

Disconnect and reconnect the device:

```
disconnect <bt_address>
connect <bt_address>
info <bt_address>
```

If the image is stable enough for reboot testing, reboot the target and reconnect:

```
reboot
```

After the target returns:

```
bluetoothctl
connect <bt_address>
info <bt_address>
```

Success criteria:

- The trusted device remains known after disconnect.
- After reboot, the device remains paired and trusted.
- Reconnect works without repeating the full pairing flow.

## Verify A2DP And PipeWire

Connect an A2DP-capable device, then inspect PipeWire from a normal shell:

```
wpctl status
pw-cli ls Node
```

Look for Bluetooth-related nodes or routes. Depending on the image and device role, names may include `bluez`, the remote device address, or an A2DP profile name.

If the AGL image includes a playable test audio file, play it through the selected sink using the tools available on the image. For example:

```
wpctl status
```

Use the listed sink ID to make the Bluetooth device the default sink:

```
wpctl set-default <sink_id>
```

Then play audio using the image's available media or audio test tool.

Success criteria:

- A Bluetooth audio node appears in PipeWire after connection.
- WirePlumber exposes a usable sink or source for the Bluetooth device.
- Audio routes to or from the Bluetooth device.
- Disconnecting the device removes or disables the corresponding PipeWire node cleanly.

## Verify AVRCP Metadata And Controls

AVRCP support depends on the remote device and active media session. Start media playback on the phone or media device, then inspect the connected device:

```
info <bt_address>
```

From `bluetoothctl`, inspect media-related menus if available:

```
menu player
list
show
```

Try simple playback controls when a player is listed:

```
play
pause
next
previous
```

Success criteria:

- A media player or media control object is visible when the remote device supports AVRCP.
- Track or playback state can be observed where the device exposes it.
- Playback commands are accepted or fail with a clear unsupported-operation message.
- The result can guide the Flutter media player integration without requiring a custom app yet.

## HFP Readiness Check

HFP is a stretch goal for this project. Treat this section as a readiness check unless the AGL image already includes the telephony and audio policy needed for hands-free calling.

Check whether the connected device exposes hands-free UUIDs:

```
info <bt_address>
```

Check whether the image includes telephony services or future integration points:

```
systemctl --type=service | grep -Ei 'ofono|pipewire|wireplumber|bluetooth'
wpctl status
```

Success criteria:

- The remote phone advertises HFP or hands-free UUIDs.
- The AGL image clearly shows which service will own call control and SCO or wideband speech routing.
- Missing telephony support is recorded as expected future work, not a core smoke-test failure.

## Debug Commands

Use these commands when discovery, pairing, connection, or audio routing does not behave as expected.

Inspect BlueZ logs from the current boot:

```
journalctl -u bluetooth -b
```

Watch HCI traffic while reproducing the issue:

```
btmon
```

Inspect the BlueZ D-Bus object tree:

```
busctl tree org.bluez
```

Inspect properties for the adapter or a device object:

```
busctl introspect org.bluez /org/bluez/hci0
busctl introspect org.bluez /org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX
```

Inspect PipeWire and WirePlumber state:

```
wpctl status
pw-cli ls Node
```

Useful notes to capture in a bug report:

- AGL image version and board revision.
- Bluetooth adapter name from `bluetoothctl show`.
- Remote device model and OS version.
- Exact `bluetoothctl info <bt_address>` output.
- Relevant `journalctl -u bluetooth -b` lines.
- Whether PipeWire nodes appeared after connection.

## Cleanup

To remove the test device from BlueZ:

```
remove <bt_address>
```

Success criteria:

- The device disappears from `devices`.
- A future pairing run starts from a clean state.
