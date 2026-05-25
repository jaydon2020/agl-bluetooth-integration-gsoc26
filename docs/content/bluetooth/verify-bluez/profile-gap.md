---
title: General Access Profile
navTitle: Profile GAP
description: Commands and smoke-test goals for validating Bluetooth GAP behavior on an AGL target.
---

You can perform Bluetooth GAP functions with `bluetoothctl`, or directly through BlueZ D-Bus APIs. Use these commands to verify adapter power, discovery, pairing, bonding, and discoverable mode on the device under test.

Start an interactive `bluetoothctl` session:

```
bluetoothctl
```

The prompt changes to `[bluetooth]#` after the shell starts. Run the `bluetoothctl` commands below from that prompt.

For D-Bus examples, the default adapter path is assumed to be `/org/bluez/hci0`. If the target uses another adapter, replace `hci0` with the correct adapter name.

To confirm the adapter path, run:

```
busctl tree org.bluez
```

## Enable Bluetooth

To enable Bluetooth on the device, run:

```
power on
```

Sample output:

```
Changing power on succeeded
```

Using D-Bus:

```
busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered b true
```

## Run Bluetooth inquiry scan

To initiate an inquiry for nearby devices, run:

```
scan on
```

Sample output:

```
Discovery started
[CHG] Controller B8:27:EB:12:34:56 Discovering: yes
[NEW] Device F8:7D:76:9D:9B:6B Phone
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0 org.bluez.Adapter1 StartDiscovery
```

## Stop Bluetooth inquiry scan

To stop an inquiry that is in progress, run:

```
scan off
```

Sample output:

```
Discovery stopped
[CHG] Controller B8:27:EB:12:34:56 Discovering: no
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0 org.bluez.Adapter1 StopDiscovery
```

## Pair with a remote Bluetooth device

Before pairing a remote device, run a Bluetooth inquiry scan to ensure that the remote device is available.

To pair with a remote Bluetooth device, run:

```
pair <bt_address>
```

To accept the outgoing or incoming pairing request, enter `yes`. To reject it, enter `no`.

Parameters:

- `<bt_address>` is the Bluetooth address of the remote device.

Example:

To pair with a remote device with `<bt_address>` `F8:7D:76:9D:9B:6B`, run:

```
pair F8:7D:76:9D:9B:6B
```

Sample output:

```
Attempting to pair with F8:7D:76:9D:9B:6B
[agent] Confirm passkey 123456 (yes/no): yes
Pairing successful
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 Pair
```

For D-Bus pairing, make sure a BlueZ agent is registered before calling `Pair`. The simplest interactive setup is:

```
agent on
default-agent
```

## Trust a paired device

After pairing, mark the remote device as trusted so BlueZ can reconnect without prompting.

```
trust <bt_address>
```

Example:

```
trust F8:7D:76:9D:9B:6B
```

Sample output:

```
Changing F8:7D:76:9D:9B:6B trust succeeded
```

Using D-Bus:

```
busctl set-property org.bluez /org/bluez/hci0/dev_F8_7D_76_9D_9B_6B org.bluez.Device1 Trusted b true
```

## Get the bonded or paired device list

To get a verified list of paired devices, run:

```
devices Paired
```

Sample output:

```
Device F8:7D:76:9D:9B:6B Phone
Device 20:19:D8:36:90:40 Headset
```

Using D-Bus:

```
busctl call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects
```

In the D-Bus output, paired devices appear under paths such as `/org/bluez/hci0/dev_F8_7D_76_9D_9B_6B` with the `org.bluez.Device1` property `Paired` set to `true`.

## Unpair a device

To unpair a device, run:

```
remove <bt_address>
```

Example:

To unpair a device with the address `20:19:D8:36:90:40`, run:

```
remove 20:19:D8:36:90:40
```

Sample output:

```
[DEL] Device 20:19:D8:36:90:40 Headset
Device has been removed
```

Using D-Bus:

```
busctl call org.bluez /org/bluez/hci0 org.bluez.Adapter1 RemoveDevice o /org/bluez/hci0/dev_20_19_D8_36_90_40
```

## Enable device discovery

To enable discovery mode on the device under test, run:

```
discoverable on
```

Sample output:

```
Changing discoverable on succeeded
[CHG] Controller B8:27:EB:12:34:56 Discoverable: yes
```

Using D-Bus:

```
busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Discoverable b true
```

## Disable Bluetooth

To disable Bluetooth on the device, run:

```
power off
```

Sample output:

```
Changing power off succeeded
```

Using D-Bus:

```
busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered b false
```

## BlueZ Proxy XML

Use this proxy XML as a compact reference for the BlueZ D-Bus interfaces used by the GAP commands above.

```
<node>
  <interface name="org.bluez.Adapter1">
    <method name="StartDiscovery"/>
    <method name="StopDiscovery"/>
    <method name="RemoveDevice">
      <arg name="device" type="o" direction="in"/>
    </method>
    <method name="SetDiscoveryFilter">
      <arg name="properties" type="a{sv}" direction="in"/>
    </method>
    <method name="GetDiscoveryFilters">
      <arg name="filters" type="as" direction="out"/>
    </method>
    <property name="Address" type="s" access="read"/>
    <property name="AddressType" type="s" access="read"/>
    <property name="Name" type="s" access="read"/>
    <property name="Alias" type="s" access="readwrite"/>
    <property name="Class" type="u" access="read"/>
    <property name="Powered" type="b" access="readwrite"/>
    <property name="Discoverable" type="b" access="readwrite"/>
    <property name="DiscoverableTimeout" type="u" access="readwrite"/>
    <property name="Pairable" type="b" access="readwrite"/>
    <property name="PairableTimeout" type="u" access="readwrite"/>
    <property name="Discovering" type="b" access="read"/>
    <property name="UUIDs" type="as" access="read"/>
    <property name="Modalias" type="s" access="read"/>
  </interface>

  <interface name="org.bluez.Device1">
    <method name="Connect"/>
    <method name="Disconnect"/>
    <method name="ConnectProfile">
      <arg name="uuid" type="s" direction="in"/>
    </method>
    <method name="DisconnectProfile">
      <arg name="uuid" type="s" direction="in"/>
    </method>
    <method name="Pair"/>
    <method name="CancelPairing"/>
    <property name="Address" type="s" access="read"/>
    <property name="AddressType" type="s" access="read"/>
    <property name="Name" type="s" access="read"/>
    <property name="Alias" type="s" access="readwrite"/>
    <property name="Class" type="u" access="read"/>
    <property name="Appearance" type="q" access="read"/>
    <property name="Icon" type="s" access="read"/>
    <property name="Paired" type="b" access="read"/>
    <property name="Trusted" type="b" access="readwrite"/>
    <property name="Blocked" type="b" access="readwrite"/>
    <property name="LegacyPairing" type="b" access="read"/>
    <property name="RSSI" type="n" access="read"/>
    <property name="Connected" type="b" access="read"/>
    <property name="UUIDs" type="as" access="read"/>
    <property name="Modalias" type="s" access="read"/>
    <property name="Adapter" type="o" access="read"/>
    <property name="ServicesResolved" type="b" access="read"/>
  </interface>

  <interface name="org.bluez.AgentManager1">
    <method name="RegisterAgent">
      <arg name="agent" type="o" direction="in"/>
      <arg name="capability" type="s" direction="in"/>
    </method>
    <method name="UnregisterAgent">
      <arg name="agent" type="o" direction="in"/>
    </method>
    <method name="RequestDefaultAgent">
      <arg name="agent" type="o" direction="in"/>
    </method>
  </interface>

  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg name="device" type="o" direction="in"/>
      <arg name="pincode" type="s" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg name="device" type="o" direction="in"/>
      <arg name="pincode" type="s" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg name="device" type="o" direction="in"/>
      <arg name="passkey" type="u" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg name="device" type="o" direction="in"/>
      <arg name="passkey" type="u" direction="in"/>
      <arg name="entered" type="q" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg name="device" type="o" direction="in"/>
      <arg name="passkey" type="u" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg name="device" type="o" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg name="device" type="o" direction="in"/>
      <arg name="uuid" type="s" direction="in"/>
    </method>
    <method name="Cancel"/>
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
