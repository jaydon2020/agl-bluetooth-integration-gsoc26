---
title: Advanced Audio Distribution Profile
navTitle: Profile A2DP
description: Commands and D-Bus checks for validating Bluetooth A2DP audio streaming on an AGL target.
---

A2DP validates Bluetooth media audio between the AGL device and a remote phone or headset. On AGL, BlueZ owns the Bluetooth profile lifecycle, while PipeWire and WirePlumber normally register the local media endpoints and route the audio stream after the Bluetooth device connects.

Before running this test, complete the [Profile GAP](bluetooth/verify-bluez/profile-gap) flow so the adapter is powered on and the remote device is paired and trusted.

For D-Bus examples, the default adapter path is assumed to be `/org/bluez/hci0`. Replace `hci0` and the sample device address with the values from your target.

## Check audio endpoint registration

A2DP needs local media endpoints before BlueZ can create an audio transport. On an AGL image, these endpoints should be registered by PipeWire and WirePlumber.

Check BlueZ logs:

```
journalctl -u bluetooth --no-pager | grep -i endpoint
```

Sample output:

```
bluetoothd[621]: Endpoint registered: sender=:1.42 path=/MediaEndpoint/A2DPSink/sbc
bluetoothd[621]: Endpoint registered: sender=:1.42 path=/MediaEndpoint/A2DPSource/sbc
```

Using D-Bus:

```
busctl tree org.bluez
```

Look for media endpoint paths such as `/MediaEndpoint/A2DPSink/sbc`, `/MediaEndpoint/A2DPSource/sbc`, or endpoints below `/org/bluez/hci0`.

## Connect an A2DP device

Start an interactive `bluetoothctl` session:

```
bluetoothctl
```

Connect to the paired remote device:

```
connect <bt_address>
```

Example:

```
connect F8:7D:76:9D:9B:6B
```

Sample output:

```
Attempting to connect to F8:7D:76:9D:9B:6B
Connection successful
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 Connect
```

## Connect the A2DP profile

If the device is already connected but the audio profile is not active, connect the A2DP profile explicitly.

A2DP UUIDs:

- `0000110a-0000-1000-8000-00805f9b34fb` is Audio Source.
- `0000110b-0000-1000-8000-00805f9b34fb` is Audio Sink.

For an IVI target receiving music from a phone, the phone is normally the A2DP source and the AGL target is the A2DP sink.

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 ConnectProfile s 0000110a-0000-1000-8000-00805f9b34fb
```

For a headset or speaker receiving audio from AGL, use the Audio Sink UUID:

```
busctl call org.bluez /org/bluez/hci0/dev_20_19_D8_36_90_40 org.bluez.Device1 ConnectProfile s 0000110b-0000-1000-8000-00805f9b34fb
```

## Verify device information

Use `bluetoothctl` to confirm that the remote device is connected and exposes the expected audio UUIDs.

```
info <bt_address>
```

Example:

```
info F8:7D:76:9D:9B:6B
```

Sample output:

```
Device F8:7D:76:9D:9B:6B (public)
	Name: Phone
	Paired: yes
	Trusted: yes
	Connected: yes
	UUID: Audio Source              (0000110a-0000-1000-8000-00805f9b34fb)
	UUID: A/V Remote Control Target (0000110c-0000-1000-8000-00805f9b34fb)
```

Using D-Bus:

```
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 Connected
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 UUIDs
```

## Verify media transport

After the remote device starts media playback, BlueZ should expose a media transport object.

Using D-Bus:

```
busctl call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects
```

Look for an object path similar to:

```
/org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0
```

Then inspect the transport:

```
busctl introspect org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0 org.bluez.MediaTransport1
```

Common transport properties:

```
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0 org.bluez.MediaTransport1 State
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0 org.bluez.MediaTransport1 UUID
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0 org.bluez.MediaTransport1 Codec
busctl get-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B/sep1/fd0 org.bluez.MediaTransport1 Volume
```

Sample output:

```
s "active"
s "0000110a-0000-1000-8000-00805f9b34fb"
y 0
q 96
```

## Observe PipeWire routing

BlueZ confirms the Bluetooth profile state, but AGL audio success also depends on PipeWire receiving and routing the stream.

Check nodes:

```
wpctl status
```

Sample output:

```
Audio
 ├─ Devices:
 │      45. Phone A2DP Sink
 ├─ Sinks:
 │  *   52. Phone A2DP Sink
```

Check active PipeWire metadata:

```
pw-cli ls Node | grep -i bluez
```

## Disconnect the A2DP device

To disconnect the remote Bluetooth device, run:

```
disconnect <bt_address>
```

Example:

```
disconnect F8:7D:76:9D:9B:6B
```

Sample output:

```
Attempting to disconnect from F8:7D:76:9D:9B:6B
Successful disconnected
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 Disconnect
```

To disconnect only the A2DP source profile:

```
busctl call org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 DisconnectProfile s 0000110a-0000-1000-8000-00805f9b34fb
```

## BlueZ Proxy XML

Use this proxy XML as a compact reference for the BlueZ D-Bus interfaces used by the A2DP commands above.

```
<node>
  <interface name="org.bluez.Device1">
    <method name="Connect"/>
    <method name="Disconnect"/>
    <method name="ConnectProfile">
      <arg name="uuid" type="s" direction="in"/>
    </method>
    <method name="DisconnectProfile">
      <arg name="uuid" type="s" direction="in"/>
    </method>
    <property name="Address" type="s" access="read"/>
    <property name="Name" type="s" access="read"/>
    <property name="Alias" type="s" access="readwrite"/>
    <property name="Paired" type="b" access="read"/>
    <property name="Trusted" type="b" access="readwrite"/>
    <property name="Connected" type="b" access="read"/>
    <property name="UUIDs" type="as" access="read"/>
    <property name="Adapter" type="o" access="read"/>
    <property name="ServicesResolved" type="b" access="read"/>
  </interface>

  <interface name="org.bluez.Media1">
    <method name="RegisterEndpoint">
      <arg name="endpoint" type="o" direction="in"/>
      <arg name="properties" type="a{sv}" direction="in"/>
    </method>
    <method name="UnregisterEndpoint">
      <arg name="endpoint" type="o" direction="in"/>
    </method>
    <method name="RegisterPlayer">
      <arg name="player" type="o" direction="in"/>
      <arg name="properties" type="a{sv}" direction="in"/>
    </method>
    <method name="UnregisterPlayer">
      <arg name="player" type="o" direction="in"/>
    </method>
    <property name="SupportedUUIDs" type="as" access="read"/>
    <property name="SupportedFeatures" type="as" access="read"/>
  </interface>

  <interface name="org.bluez.MediaEndpoint1">
    <method name="SetConfiguration">
      <arg name="transport" type="o" direction="in"/>
      <arg name="properties" type="a{sv}" direction="in"/>
    </method>
    <method name="SelectConfiguration">
      <arg name="capabilities" type="ay" direction="in"/>
      <arg name="configuration" type="ay" direction="out"/>
    </method>
    <method name="ClearConfiguration">
      <arg name="transport" type="o" direction="in"/>
    </method>
    <method name="Release"/>
  </interface>

  <interface name="org.bluez.MediaTransport1">
    <method name="Acquire">
      <arg name="fd" type="h" direction="out"/>
      <arg name="read_mtu" type="q" direction="out"/>
      <arg name="write_mtu" type="q" direction="out"/>
    </method>
    <method name="TryAcquire">
      <arg name="fd" type="h" direction="out"/>
      <arg name="read_mtu" type="q" direction="out"/>
      <arg name="write_mtu" type="q" direction="out"/>
    </method>
    <method name="Release"/>
    <property name="Device" type="o" access="read"/>
    <property name="UUID" type="s" access="read"/>
    <property name="Codec" type="y" access="read"/>
    <property name="Configuration" type="ay" access="read"/>
    <property name="State" type="s" access="read"/>
    <property name="Delay" type="q" access="read"/>
    <property name="Volume" type="q" access="readwrite"/>
  </interface>

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

  <interface name="org.freedesktop.DBus.Properties">
    <method name="Get">
      <arg name="interface" type="s" direction="in"/>
      <arg name="name" type="s" direction="in"/>
      <arg name="value" type="v" direction="out"/>
    </method>
    <method name="Set">
      <arg name="interface" type="s" direction="in"/>
      <arg name="name" type="s" direction="in"/>
      <arg name="value" type="v" direction="in"/>
    </method>
    <method name="GetAll">
      <arg name="interface" type="s" direction="in"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
    <signal name="PropertiesChanged">
      <arg name="interface" type="s"/>
      <arg name="changed" type="a{sv}"/>
      <arg name="invalidated" type="as"/>
    </signal>
  </interface>
</node>
```
