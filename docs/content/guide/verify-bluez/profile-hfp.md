---
title: PipeWire Bluetooth Phone Calls over D-Bus
navTitle: Profile HFP
description: Complete system-D-Bus reference for Bluetooth HFP phone calls through PipeWire and WirePlumber on AGL.
---

This guide shows how to control Bluetooth Hands-Free Profile (HFP) phone calls on Automotive Grade Linux using PipeWire's native HFP backend and its D-Bus telephony service.

The commands were prepared for the following AGL stack:

- AGL Vimba development branch
- BlueZ 5.86
- PipeWire 1.6.6
- WirePlumber 0.5.14 using AGL's split system services
- AGL acting as the Hands-Free unit (HF)
- The paired mobile phone acting as the Audio Gateway (AG)

## Architecture

There are three separate responsibilities:

1. BlueZ pairs and connects the phone and owns the Bluetooth profiles.
2. PipeWire's native HFP backend exchanges HFP commands and carries bidirectional SCO call audio.
3. `org.pipewire.Telephony` exposes phone-call state and controls over D-Bus.

Call control is therefore not performed through `org.bluez`. BlueZ D-Bus is still used for pairing and connection, but dialing, answering, hanging up, and DTMF use `org.pipewire.Telephony`.

The D-Bus API controls the call and SCO transport. PipeWire graph routing is inspected or adjusted separately with `wpctl`, `pw-link`, or Helvum.

## 1. Configure the Native HFP Backend

AGL's WirePlumber Bluetooth configuration is:

```
/etc/wireplumber/wireplumber.conf.d/30-AGL-bluetooth.conf
```

The configuration should select the native backend:

```
monitor.bluez.properties = {
  bluez5.hfphsp-backend = "native"
  bluez5.telephony.use-system-bus = true
}
```

AGL's split system service has no user session bus. The system-bus setting is therefore required; without it, WirePlumber logs `spa.bluez5.telephony: failed to get session dbus connection` and never registers `org.pipewire.Telephony`.

The device policy should include the Hands-Free role:

```
monitor.bluez.rules = [
  {
    matches = [
      {
        device.name = "~bluez_card.*"
      }
    ]
    actions = {
      update-props = {
        bluez5.auto-connect = [ hfp_hf hsp_hs a2dp_sink ]
      }
    }
  }
]
```

### Keep oFono for SIM Support Without Bluetooth HFP

oFono is still useful for cellular modem and SIM functionality, including SIM state, network registration, SMS, cellular calls, and mobile-data control. It does not need to be removed or disabled.

However, oFono must not register Bluetooth HFP profiles when PipeWire uses the native HFP backend. Add this Yocto append:

```
meta-agl/meta-agl-core/recipes-connectivity/ofono/ofono_%.bbappend
```

```
# Keep oFono for cellular modems, but let PipeWire own Bluetooth HFP.
PACKAGECONFIG:remove = "bluez"
```

This keeps oFono installed and allows `ofono.service` to run for SIM and cellular modem management, while PipeWire remains the only owner of Bluetooth HFP. No `SYSTEMD_AUTO_ENABLE` override and no `systemctl disable ofono.service` are required.

Before rebuilding, confirm that BitBake finds the append and removes the feature:

```
bitbake-layers show-appends | grep -A2 ofono
bitbake -e ofono | grep '^PACKAGECONFIG='
```

The final `PACKAGECONFIG` must not contain `bluez`.

The corresponding WirePlumber Yocto change is:

```
meta-agl/meta-pipewire/recipes-multimedia/wireplumber/wireplumber-config-agl/30-AGL-bluetooth.conf
```

```
monitor.bluez.properties = {
  bluez5.hfphsp-backend = "native"
  bluez5.telephony.use-system-bus = true
}
```

On a current AGL image, the monolithic WirePlumber service should be masked because AGL uses split instances:

```
systemctl is-enabled wireplumber.service
systemctl status wireplumber@bluetooth.service
```

If the old monolithic service is still enabled:

```
systemctl disable --now wireplumber.service
systemctl mask wireplumber.service
```

Restart the audio stack after changing the configuration:

```
systemctl restart pipewire.service
systemctl restart \
  wireplumber@audio.service \
  wireplumber@bluetooth.service \
  wireplumber@policy.service \
  wireplumber@video-capture.service
```

Confirm that the Bluetooth instance is running:

```
systemctl --no-pager --full status wireplumber@bluetooth.service
journalctl -u wireplumber@bluetooth.service -b --no-pager
```

## 2. Pair and Connect the Phone

Replace `04:C8:B0:EC:DE:0F` with the phone's Bluetooth address:

```
bluetoothctl
```

Then run:

```
power on
agent on
default-agent
scan on
pair 04:C8:B0:EC:DE:0F
trust 04:C8:B0:EC:DE:0F
connect 04:C8:B0:EC:DE:0F
scan off
quit
```

Confirm the BlueZ device state:

```
DEVICE=/org/bluez/hci0/dev_04_C8_B0_EC_DE_0F

busctl --system get-property \
  org.bluez "$DEVICE" org.bluez.Device1 Connected

busctl --system get-property \
  org.bluez "$DEVICE" org.bluez.Device1 UUIDs
```

For a phone acting as an HFP Audio Gateway, the UUID list should include:

```
0000111f-0000-1000-8000-00805f9b34fb
```

## 3. Verify the PipeWire Telephony Service

For AGL's system-bus configuration:

```
busctl --system status org.pipewire.Telephony
```

The owning process should be the Bluetooth WirePlumber instance, similar to:

```
CommandLine=/usr/bin/wireplumber -p bluetooth
Unit=wireplumber@bluetooth.service
```

If the name is absent from the system bus, check whether it is using the default user bus instead:

```
busctl --user status org.pipewire.Telephony
```

Use either `--system` or `--user` consistently in all following commands.

Define the dynamic interface and object values used below:

```
AG_IFACE=org.pipewire.Telephony.AudioGateway1
TRANSPORT_IFACE=org.pipewire.Telephony.AudioGatewayTransport1
CALL_IFACE=org.pipewire.Telephony.Call1
```

Discover all current objects:

```
busctl --system call \
  org.pipewire.Telephony /org/pipewire/Telephony \
  org.freedesktop.DBus.ObjectManager GetManagedObjects
```

`GetManagedObjects` is the preferred discovery operation because the service manager is registered at `/org/pipewire/Telephony`, not at `/`:

```
busctl --system introspect \
  org.pipewire.Telephony /org/pipewire/Telephony
```

`busctl --system tree org.pipewire.Telephony` starts by introspecting `/` and may report `Access denied` or discover no objects even while the manager works.

After connecting a phone, an Audio Gateway object should appear:

```
/org/pipewire/Telephony/ag1
```

Do not hard-code `ag1`; discover the path because its numeric suffix can change after reconnecting.

For the remaining examples:

```
AG=/org/pipewire/Telephony/ag1
```

Inspect the available methods and properties:

```
busctl --system introspect org.pipewire.Telephony "$AG"
```

Read all Audio Gateway properties:

```
busctl --system call \
  org.pipewire.Telephony "$AG" \
  org.freedesktop.DBus.Properties GetAll \
  s "$AG_IFACE"
```

Typical properties include the phone address, speaker volume, and microphone volume.

## 4. Monitor Call Events

Keep this running in a second terminal:

```
busctl --system monitor org.pipewire.Telephony
```

An alternative with filtering is:

```
dbus-monitor --system "sender='org.pipewire.Telephony'"
```

The manager emits standard ObjectManager events:

- `InterfacesAdded` when an Audio Gateway or call object appears
- `InterfacesRemoved` when the object disappears
- `PropertiesChanged` when call or transport state changes

When a call exists, a dynamic object appears below the gateway:

```
/org/pipewire/Telephony/ag1/call1
```

Discover it instead of assuming the suffix is always `call1`:

```
busctl --system call \
  org.pipewire.Telephony /org/pipewire/Telephony \
  org.freedesktop.DBus.ObjectManager GetManagedObjects
```

For the examples below:

```
CALL=/org/pipewire/Telephony/ag1/call1
```

Read the call properties:

```
busctl --system call \
  org.pipewire.Telephony "$CALL" \
  org.freedesktop.DBus.Properties GetAll \
  s "$CALL_IFACE"
```

Important properties are:

- `LineIdentification`: incoming caller ID or the outgoing number
- `IncomingLine`: local subscriber line called by the remote party, when available
- `Name`: caller name supplied by the phone or network
- `Multiparty`: whether the call belongs to a conference
- `State`: current call state

Possible call states are:

- `active`
- `held`
- `dialing`
- `alerting`
- `incoming`
- `waiting`
- `disconnected`

## 5. Make an Outgoing Call

Call `Dial` on the Audio Gateway object. Unlike oFono's `Dial` method, PipeWire's native interface takes only one string argument:

```
NUMBER=1234567890

busctl --system call \
  org.pipewire.Telephony "$AG" "$AG_IFACE" \
  Dial s "$NUMBER"
```

Valid dial-string characters are digits, `+`, `*`, `#`, comma, and `A` through `D`, with a maximum of 80 characters.

After dialing, discover the new call object:

```
busctl --system call \
  org.pipewire.Telephony /org/pipewire/Telephony \
  org.freedesktop.DBus.ObjectManager GetManagedObjects
```

Its state should normally progress from `dialing` to `alerting`, then `active` when answered.

## 6. Answer an Incoming Call

Call the connected phone from another phone. While it is ringing, discover the call object and confirm that its state is `incoming`:

```
busctl --system get-property \
  org.pipewire.Telephony "$CALL" "$CALL_IFACE" State
```

Answer it:

```
busctl --system call \
  org.pipewire.Telephony "$CALL" "$CALL_IFACE" \
  Answer
```

`Answer` is valid only while the call state is `incoming`.

## 7. Hang Up or Reject a Call

Hang up one specific call:

```
busctl --system call \
  org.pipewire.Telephony "$CALL" "$CALL_IFACE" \
  Hangup
```

Calling `Hangup` while the phone is ringing rejects the incoming call.

Release all calls except waiting calls:

```
busctl --system call \
  org.pipewire.Telephony "$AG" "$AG_IFACE" \
  HangupAll
```

## 8. Send DTMF Tones

Send tones during an active call:

```
busctl --system call \
  org.pipewire.Telephony "$AG" "$AG_IFACE" \
  SendTones s "123#"
```

Allowed tones are `0-9`, `*`, `#`, and `A-D`.

## 9. Manage Multiple Calls

The Audio Gateway interface also exposes:

```
# Swap active and held calls
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" SwapCalls

# Release active calls and answer the waiting call
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" ReleaseAndAnswer

# Release active calls and activate held calls
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" ReleaseAndSwap

# Hold the active call and answer the waiting call
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" HoldAndAnswer

# Join active and held calls into a conference
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" CreateMultiparty
```

The phone and mobile network determine which multi-call operations are supported.

## 10. Speaker and Microphone Volume

Read the current HFP volumes:

```
busctl --system get-property \
  org.pipewire.Telephony "$AG" "$AG_IFACE" SpeakerVolume

busctl --system get-property \
  org.pipewire.Telephony "$AG" "$AG_IFACE" MicrophoneVolume
```

Set values in the HFP range `0-15`:

```
busctl --system set-property \
  org.pipewire.Telephony "$AG" "$AG_IFACE" \
  SpeakerVolume y 12

busctl --system set-property \
  org.pipewire.Telephony "$AG" "$AG_IFACE" \
  MicrophoneVolume y 12
```

## 11. Inspect and Activate the SCO Transport

Read the SCO transport properties:

```
busctl --system call \
  org.pipewire.Telephony "$AG" \
  org.freedesktop.DBus.Properties GetAll \
  s "$TRANSPORT_IFACE"
```

The transport state is one of:

- `error`
- `idle`
- `pending`
- `active`

During an active phone call, the transport should normally become `active` automatically.

Check whether SCO is being rejected:

```
busctl --system get-property \
  org.pipewire.Telephony "$AG" "$TRANSPORT_IFACE" RejectSCO
```

Allow SCO:

```
busctl --system set-property \
  org.pipewire.Telephony "$AG" "$TRANSPORT_IFACE" \
  RejectSCO b false
```

If a phone does not initiate SCO automatically, request activation manually:

```
busctl --system call \
  org.pipewire.Telephony "$AG" "$TRANSPORT_IFACE" \
  Activate
```

Use manual activation as a diagnostic step. Normal call setup should activate SCO without it.

## 12. Verify PipeWire Call Audio

AGL's system-wide PipeWire socket is normally under `/run/pipewire`:

```
export PIPEWIRE_RUNTIME_DIR=/run/pipewire
```

Inspect the graph before and during a call:

```
wpctl status
pw-link -l
```

When SCO is active, the Bluetooth card should switch from the high-quality, playback-only A2DP profile to an HFP profile with both playback and capture nodes.

The two audio directions are:

- Phone downlink: Bluetooth HFP source to the vehicle speaker sink
- Vehicle uplink: vehicle microphone source to the Bluetooth HFP sink

If the call is active but silent, first verify that the SCO transport is `active`, then inspect the PipeWire links. D-Bus can establish and control the call, but WirePlumber policy creates the audio links.

## 13. D-Bus Permissions for a Non-root Application

Testing as `root` may work while an application running as `agl-driver` receives `org.freedesktop.DBus.Error.AccessDenied`.

For this Yocto configuration, update:

```
meta-agl/meta-pipewire/recipes-multimedia/wireplumber/wireplumber-config-agl/wireplumber-bluetooth.conf
```

The installed policy is `/etc/dbus-1/system.d/wireplumber-bluetooth.conf` and should contain:

```
<!DOCTYPE busconfig PUBLIC
  "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="pipewire">
    <allow send_destination="org.bluez"/>
    <allow own="org.pipewire.Telephony"/>
  </policy>

  <!-- Useful for busctl diagnostics; optional in a production image. -->
  <policy user="root">
    <allow send_destination="org.pipewire.Telephony"/>
  </policy>

  <policy user="agl-driver">
    <allow send_destination="org.pipewire.Telephony"/>
  </policy>
</busconfig>
```

Use `agl-driver`, not `policy context="default"`, because AGL Flutter applications and `agl-app-flutter@.service` run as `User=agl-driver`. A default policy would allow every local user to dial, answer, and terminate calls. Keep the `root` rule during development if `busctl introspect` is needed; it can be removed from a hardened production image.

Deploy the policy through the Yocto image and reboot. For temporary target testing, reload the policy without restarting the bus:

```
busctl --system call \
  org.freedesktop.DBus /org/freedesktop/DBus \
  org.freedesktop.DBus ReloadConfig
```

Do not use a broad rule such as `<allow send_destination="*"/>` for the application.

## 14. Troubleshooting

### `org.pipewire.Telephony` has no owner

Check both buses:

```
busctl --system status org.pipewire.Telephony
busctl --user status org.pipewire.Telephony
```

Then check the Bluetooth WirePlumber instance:

```
systemctl status wireplumber@bluetooth.service
journalctl -u wireplumber@bluetooth.service -b --no-pager
```

Confirm that the native backend is configured:

```
grep -R "hfphsp-backend" /etc/wireplumber
```

oFono may be active for SIM and modem management. In the Yocto build, confirm its BlueZ integration is disabled:

```
bitbake -e ofono | grep '^PACKAGECONFIG='
```

The result must not contain `bluez`. The oFono configure command should consequently contain:

```
--disable-bluetooth
```

After flashing, check that the compiled-in BlueZ HFP plugin is absent. Checking `/usr/lib/ofono` is insufficient because oFono plugins can be linked into `/usr/sbin/ofonod`:

```
strings /usr/sbin/ofonod | \
  grep -F "External Hands-Free Profile Plugin"
```

The command must produce no output. If oFono logs `Service level connection established` when a Bluetooth phone connects, its HFP plugin is still compiled in.

These WirePlumber errors confirm that another process, commonly an old Bluetooth-enabled oFono build, already owns the HFP listener or BlueZ profile:

```
spa.bluez5.native: listen(): Address already in use
spa.bluez5.native: RegisterProfile() failed: org.bluez.Error.NotPermitted
```

Stop oFono temporarily on the affected image so PipeWire can be tested:

```
systemctl stop ofono.service
systemctl restart wireplumber@bluetooth.service
```

Then clean and rebuild oFono and the image before reflashing:

```
bitbake -c cleansstate ofono
bitbake ofono
bitbake agl-ivi-demo-flutter
```

### The manager exists but there is no `agN` object

The phone has not connected its HFP Audio Gateway profile. Check:

```
bluetoothctl info 04:C8:B0:EC:DE:0F
busctl --system tree org.bluez
journalctl -u bluetooth.service -b --no-pager
```

Disconnect and reconnect the phone after confirming it advertises UUID `0000111f-0000-1000-8000-00805f9b34fb`.

An empty manager response is valid and means no HFP Audio Gateway has completed its Service Level Connection:

```
a{oa{sa{sv}}} 0
```

The first observed gateway is not guaranteed to be `ag0`; reconnects and failed earlier registrations can result in `ag1` or another suffix. A successful response resembles:

```
a{oa{sa{sv}}} 1 "/org/pipewire/Telephony/ag1" ...
```

### `busctl introspect` reports `Access denied`

`GetManagedObjects` may work while introspection fails because BlueZ's system-bus policy already permits the standard ObjectManager interface globally. That does not grant access to `org.freedesktop.DBus.Introspectable` on `org.pipewire.Telephony`.

Add the destination rule for the calling Unix user, reload D-Bus configuration, and introspect the explicit manager path:

```
busctl --system introspect \
  org.pipewire.Telephony /org/pipewire/Telephony
```

### There is an `agN` object but no `callN` object

This is normal while the gateway is idle. A call object is created dynamically when an incoming, outgoing, held, or waiting call exists and is removed after disconnection.

Monitor D-Bus while placing or receiving a call:

```
busctl --system monitor org.pipewire.Telephony
```

### `InvalidState`

The method does not apply to the current call state. Examples include calling `Answer` on an already active call or sending DTMF without an active call. Read the call's `State` property before issuing the command.

### The call works but audio is silent

Check the transport first:

```
busctl --system get-property \
  org.pipewire.Telephony "$AG" "$TRANSPORT_IFACE" State
```

Then inspect the graph:

```
PIPEWIRE_RUNTIME_DIR=/run/pipewire wpctl status
PIPEWIRE_RUNTIME_DIR=/run/pipewire pw-link -l
```

Also inspect kernel and Bluetooth logs for SCO errors:

```
dmesg | grep -i -E 'bluetooth|sco'
journalctl -u bluetooth.service -u wireplumber@bluetooth.service -b --no-pager
```

### Wideband speech does not work

The negotiated codec is available through the transport's `Codec` byte. CVSD commonly uses codec ID `1`, while mSBC commonly uses `2`. Codec selection also depends on the phone, Bluetooth controller, kernel support, and PipeWire build options.

## Quick Command Reference

```
AG=/org/pipewire/Telephony/ag1
CALL=/org/pipewire/Telephony/ag1/call1
AG_IFACE=org.pipewire.Telephony.AudioGateway1
CALL_IFACE=org.pipewire.Telephony.Call1
TRANSPORT_IFACE=org.pipewire.Telephony.AudioGatewayTransport1

# Discover gateways and calls
busctl --system call org.pipewire.Telephony /org/pipewire/Telephony \
  org.freedesktop.DBus.ObjectManager GetManagedObjects

# Dial
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" Dial s "1234567890"

# Answer
busctl --system call org.pipewire.Telephony "$CALL" "$CALL_IFACE" Answer

# Hang up one call
busctl --system call org.pipewire.Telephony "$CALL" "$CALL_IFACE" Hangup

# Hang up all calls
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" HangupAll

# DTMF
busctl --system call org.pipewire.Telephony "$AG" "$AG_IFACE" SendTones s "123#"

# Monitor changes
busctl --system monitor org.pipewire.Telephony
```

## References

- PipeWire source documentation: `spa/plugins/bluez5/README-Telephony.md` in PipeWire 1.6.6
- [PipeWire documentation](https://docs.pipewire.org/)
- [BlueZ D-Bus API documentation](https://github.com/bluez/bluez/tree/master/doc)
- [AGL native HFP configuration: agl-yocto-bluez commit 08a246a](https://github.com/jaydon2020/agl-yocto-bluez/commit/08a246ac62002ee4c640789ed10c5aa6c611db57)
- Existing test record: [Week 14](../../journal/week-14)
- Earlier oFono test record: [Bonding period](../../journal/bonding-period)
