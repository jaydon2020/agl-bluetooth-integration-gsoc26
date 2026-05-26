---
title: Phone Book Access Profile
navTitle: Profile PBAP
description: Commands and D-Bus checks for validating Bluetooth PBAP contact access on an AGL target.
---

PBAP validates contact and call-history access from a paired phone. BlueZ exposes PBAP through the OBEX service `org.bluez.obex`, so these checks use `obexctl` and the OBEX D-Bus APIs rather than the normal `org.bluez` adapter and device APIs.

Before running this test, complete the [Profile GAP](guide/verify-bluez/profile-gap) flow so the adapter is powered on and the remote phone is paired and trusted. If `obexctl` is missing from the target image, see [Install OBEX on Yocto](guide/install-obex-yocto).

For D-Bus examples, replace `F8:7D:76:9D:9B:6B` and `/org/bluez/obex/client/session0` with the values from your target.

## Check OBEX support

PBAP requires the BlueZ OBEX daemon. On many Linux images, OBEX runs as a user D-Bus service.

Check that `obexctl` is available:

```
obexctl --version
```

Sample output:

```
obexctl: 5.84
```

Check that the OBEX service can be activated:

```
busctl --user tree org.bluez.obex
```

Sample output:

```
`-/org
  `-/org/bluez
    `-/org/bluez/obex
```

## Verify remote PBAP UUID

Use `bluetoothctl` to confirm that the phone advertises PBAP server support.

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
	UUID: Phonebook Access Server (0000112f-0000-1000-8000-00805f9b34fb)
```

## Connect a PBAP session

Start an interactive `obexctl` session:

```
obexctl
```

Connect to the phone with the PBAP target:

```
connect <bt_address> pbap
```

Example:

```
connect F8:7D:76:9D:9B:6B pbap
```

Sample output:

```
Attempting to connect to F8:7D:76:9D:9B:6B
[NEW] Session /org/bluez/obex/client/session0
Connection successful
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex org.bluez.obex.Client1 CreateSession sa{sv} F8:7D:76:9D:9B:6B 1 Target s pbap
```

The returned object path is the session path used by later PBAP calls.

## Select a phonebook

PBAP operations should select the object store before listing or pulling contacts.

In `obexctl`, list the current folder or change folders if the phone exposes the PBAP hierarchy as folders:

```
ls
cd telecom
ls
cd pb
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 Select ss int pb
```

Common phonebook values:

- `pb` is the saved phonebook.
- `ich` is incoming call history.
- `och` is outgoing call history.
- `mch` is missed call history.
- `cch` is combined call history.

## List contacts

List contact handles from the selected phonebook.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 List a{sv} 1 MaxCount q 20
```

Sample output:

```
a(ss) 2 "1.vcf" "Alice Example" "2.vcf" "Bob Example"
```

Get the number of entries:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 GetSize
```

Sample output:

```
q 42
```

## Pull the full phonebook

Pull all contacts from the selected phonebook into a local vCard file.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 PullAll sa{sv} /tmp/pb.vcf 1 Format s vcard30
```

Sample output:

```
o "/org/bluez/obex/client/session0/transfer0"
a{sv} 3 "Status" s "queued" "Name" s "pb.vcf" "Filename" s "/tmp/pb.vcf"
```

Monitor the transfer:

```
busctl --user get-property org.bluez.obex /org/bluez/obex/client/session0/transfer0 org.bluez.obex.Transfer1 Status
busctl --user get-property org.bluez.obex /org/bluez/obex/client/session0/transfer0 org.bluez.obex.Transfer1 Filename
```

## Pull one contact

After listing contacts, pull a single vCard handle.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 Pull ssa{sv} 1.vcf /tmp/contact.vcf 1 Format s vcard30
```

Sample output:

```
o "/org/bluez/obex/client/session0/transfer1"
a{sv} 3 "Status" s "queued" "Name" s "contact.vcf" "Filename" s "/tmp/contact.vcf"
```

## Search contacts

Search by contact name or number.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.PhonebookAccess1 Search ssa{sv} name Alice 1 MaxCount q 10
```

Sample output:

```
a(ss) 1 "1.vcf" "Alice Example"
```

## Disconnect the PBAP session

In `obexctl`:

```
disconnect
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex org.bluez.obex.Client1 RemoveSession o /org/bluez/obex/client/session0
```

## BlueZ OBEX Proxy XML

Use this proxy XML as a compact reference for the BlueZ OBEX D-Bus interfaces used by the PBAP commands above.

```
<node>
  <interface name="org.bluez.obex.Client1">
    <method name="CreateSession">
      <arg name="destination" type="s" direction="in"/>
      <arg name="args" type="a{sv}" direction="in"/>
      <arg name="session" type="o" direction="out"/>
    </method>
    <method name="RemoveSession">
      <arg name="session" type="o" direction="in"/>
    </method>
  </interface>

  <interface name="org.bluez.obex.Session1">
    <method name="GetCapabilities">
      <arg name="capabilities" type="s" direction="out"/>
    </method>
    <property name="Source" type="s" access="read"/>
    <property name="Destination" type="s" access="read"/>
    <property name="Channel" type="y" access="read"/>
    <property name="Target" type="s" access="read"/>
    <property name="Root" type="s" access="read"/>
  </interface>

  <interface name="org.bluez.obex.PhonebookAccess1">
    <method name="Select">
      <arg name="location" type="s" direction="in"/>
      <arg name="phonebook" type="s" direction="in"/>
    </method>
    <method name="PullAll">
      <arg name="targetfile" type="s" direction="in"/>
      <arg name="filters" type="a{sv}" direction="in"/>
      <arg name="transfer" type="o" direction="out"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
    <method name="List">
      <arg name="filters" type="a{sv}" direction="in"/>
      <arg name="vcards" type="a(ss)" direction="out"/>
    </method>
    <method name="Pull">
      <arg name="vcard" type="s" direction="in"/>
      <arg name="targetfile" type="s" direction="in"/>
      <arg name="filters" type="a{sv}" direction="in"/>
      <arg name="transfer" type="o" direction="out"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
    <method name="Search">
      <arg name="field" type="s" direction="in"/>
      <arg name="value" type="s" direction="in"/>
      <arg name="filters" type="a{sv}" direction="in"/>
      <arg name="vcards" type="a(ss)" direction="out"/>
    </method>
    <method name="GetSize">
      <arg name="size" type="q" direction="out"/>
    </method>
    <method name="UpdateVersion"/>
    <method name="ListFilterFields">
      <arg name="fields" type="as" direction="out"/>
    </method>
    <property name="Folder" type="s" access="read"/>
    <property name="DatabaseIdentifier" type="s" access="read"/>
    <property name="PrimaryCounter" type="s" access="read"/>
    <property name="SecondaryCounter" type="s" access="read"/>
    <property name="FixedImageSize" type="b" access="read"/>
  </interface>

  <interface name="org.bluez.obex.Transfer1">
    <method name="Cancel"/>
    <method name="Suspend"/>
    <method name="Resume"/>
    <property name="Status" type="s" access="read"/>
    <property name="Session" type="o" access="read"/>
    <property name="Name" type="s" access="read"/>
    <property name="Type" type="s" access="read"/>
    <property name="Time" type="t" access="read"/>
    <property name="Size" type="t" access="read"/>
    <property name="Transferred" type="t" access="read"/>
    <property name="Filename" type="s" access="read"/>
  </interface>
</node>
```

## References

- BlueZ OBEX API: [OBEX API](https://bluez.readthedocs.io/en/latest/obex-api/)
- Install OBEX tools on AGL/Yocto: [Install OBEX on Yocto](guide/install-obex-yocto)
