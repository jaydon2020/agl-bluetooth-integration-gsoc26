---
title: Hands-Free Profile
navTitle: Profile HFP
description: Commands and D-Bus checks for validating Bluetooth HFP telephony on an AGL target.
---

HFP validates voice-call control between the AGL device and a paired mobile phone. In the current PipeWire telephony model, Bluetooth call control is exposed through the `org.pipewire.Telephony` D-Bus service when PipeWire 1.3.82 or later is running with the BlueZ plugin enabled in WirePlumber.

Before running this test, complete the [Profile GAP](guide/verify-bluez/profile-gap) flow so the adapter is powered on and the remote phone is paired and trusted. For call audio, also make sure the [Profile A2DP](guide/verify-bluez/profile-a2dp) flow is working first.

For D-Bus examples, replace `F8:7D:76:9D:9B:6B` and the sample phone number with the values from your target.

## Check telephony support

Confirm that PipeWire telephony is available on the system.

```
busctl --user introspect org.pipewire.Telephony /org/pipewire/Telephony
```

Sample output:

```
NAME                                TYPE      SIGNATURE  RESULT/VALUE  FLAGS
org.freedesktop.DBus.ObjectManager  interface -          -             -
org.ofono.Manager                   interface -          -             -
org.pipewire.Telephony.AudioGateway1 interface -         -             -
org.pipewire.Telephony.AudioGatewayTransport1 interface - -           -
```

If the service is not available, confirm that PipeWire and WirePlumber are running with the Bluetooth telephony plugin enabled.

## Verify the paired phone

Use `bluetoothctl` to confirm that the phone is paired and trusted.

```
bluetoothctl info <bt_address>
```

Example:

```
bluetoothctl info F8:7D:76:9D:9B:6B
```

Sample output:

```
Device F8:7D:76:9D:9B:6B (public)
	Name: Phone
	Paired: yes
	Trusted: yes
	UUID: Handsfree (0000111e-0000-1000-8000-00805f9b34fb)
	UUID: Headset (00001108-0000-1000-8000-00805f9b34fb)
```

## List connected phones

Start by inspecting the telephony root object:

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony org.freedesktop.DBus.ObjectManager GetManagedObjects
```

Sample output:

```
a{oa{sa{sv}}} 1 "/org/pipewire/Telephony/ag1" 2 "org.pipewire.Telephony.AudioGateway1" 1 "Address" s "F8:7D:76:9D:9B:6B" "org.pipewire.Telephony.AudioGatewayTransport1" 3 "Codec" y 0 "State" s "idle" "RejectSCO" b false
```

Then introspect the connected phone object:

```
busctl --user introspect org.pipewire.Telephony /org/pipewire/Telephony/ag1
```

Useful properties and methods include:

```
busctl --user get-property org.pipewire.Telephony /org/pipewire/Telephony/ag1 org.pipewire.Telephony.AudioGateway1 Address
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1 org.pipewire.Telephony.AudioGateway1 GetCalls
```

## Dial a call

Use the telephony gateway object to start an outgoing call.

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1 org.pipewire.Telephony.AudioGateway1 Dial s <phone_number>
```

Example:

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1 org.pipewire.Telephony.AudioGateway1 Dial s +60123456789
```

Sample output:

```
o "/org/pipewire/Telephony/ag1/call1"
```

The returned call object represents the active call.

## Inspect the call

Introspect the call object to verify call state and caller identification.

```
busctl --user introspect org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1
```

Useful properties:

```
busctl --user get-property org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.pipewire.Telephony.Call1 State
busctl --user get-property org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.pipewire.Telephony.Call1 LineIdentification
busctl --user get-property org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.pipewire.Telephony.Call1 Multiparty
```

Sample output:

```
s "alerting"
s "+60123456789"
b false
```

## Answer an incoming call

If a phone call arrives, answer it through the call object.

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.pipewire.Telephony.Call1 Answer
```

You can also use the oFono-compatible interface:

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.ofono.VoiceCall Answer
```

## Hang up a call

End the active call using the call object.

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.pipewire.Telephony.Call1 Hangup
```

You can also use the oFono-compatible interface:

```
busctl --user call org.pipewire.Telephony /org/pipewire/Telephony/ag1/call1 org.ofono.VoiceCall Hangup
```

## Use telephony audio transport

The call object exposes the audio gateway transport. Inspect it when you need to confirm SCO codec state.

```
busctl --user introspect org.pipewire.Telephony /org/pipewire/Telephony/ag1
```

Look for the `org.pipewire.Telephony.AudioGatewayTransport1` interface and inspect its codec property:

```
busctl --user get-property org.pipewire.Telephony /org/pipewire/Telephony/ag1 org.pipewire.Telephony.AudioGatewayTransport1 Codec
```

Sample output:

```
y 0
```

## PipeWire Telephony Proxy XML

Use this proxy XML as a compact reference for the PipeWire telephony D-Bus interfaces used by the HFP commands above.

```
<node>
  <interface name="org.freedesktop.DBus.ObjectManager">
    <method name="GetManagedObjects">
      <arg name="objects" type="a{oa{sa{sv}}}" direction="out"/>
    </method>
    <signal name="InterfacesAdded">
      <arg name="object" type="o"/>
      <arg name="interfaces" type="a{sa{sv}}"/>
    </signal>
    <signal name="InterfacesRemoved">
      <arg name="object" type="o"/>
      <arg name="interfaces" type="as"/>
    </signal>
  </interface>

  <interface name="org.ofono.Manager">
    <method name="GetModems">
      <arg name="modems" type="a{oa{sv}}" direction="out"/>
    </method>
  </interface>

  <interface name="org.pipewire.Telephony.AudioGateway1">
    <method name="CreateMultiparty"/>
    <method name="Dial">
      <arg name="number" type="s" direction="in"/>
      <arg name="call" type="o" direction="out"/>
    </method>
    <method name="HangupAll"/>
    <method name="HoldAndAnswer"/>
    <method name="ReleaseAndAnswer"/>
    <method name="ReleaseAndSwap"/>
    <method name="SendTones">
      <arg name="tones" type="s" direction="in"/>
    </method>
    <method name="SwapCalls"/>
    <property name="Address" type="s" access="read"/>
  </interface>

  <interface name="org.pipewire.Telephony.AudioGatewayTransport1">
    <method name="Activate"/>
    <property name="Codec" type="y" access="read"/>
  </interface>

  <interface name="org.pipewire.Telephony.Call1">
    <method name="Answer"/>
    <method name="Hangup"/>
    <property name="IncomingLine" type="s" access="read"/>
    <property name="LineIdentification" type="s" access="read"/>
    <property name="Multiparty" type="b" access="read"/>
    <property name="Name" type="s" access="read"/>
    <property name="State" type="s" access="read"/>
  </interface>
</node>
```

## References

- PipeWire telephony design and D-Bus workflow: [PipeWire Telephony](https://gkiagia.gr/2025-02-20-pipewire-telephony/)
- `busctl` command reference: [busctl(1)](https://man7.org/linux/man-pages/man1/busctl.1.html)
