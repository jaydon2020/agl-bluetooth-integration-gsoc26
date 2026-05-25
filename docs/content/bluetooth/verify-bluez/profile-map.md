---
title: Message Access Profile
navTitle: Profile MAP
description: Commands and D-Bus checks for validating Bluetooth MAP message access on an AGL target.
---

MAP validates message browsing and message transfer from a paired phone. BlueZ exposes MAP through the OBEX service `org.bluez.obex`, so these checks use `obexctl` and OBEX D-Bus APIs.

Before running this test, complete the [Profile GAP](bluetooth/verify-bluez/profile-gap) flow so the adapter is powered on and the remote phone is paired and trusted. On most phones, message access also requires an explicit permission prompt on the phone.

For D-Bus examples, replace `F8:7D:76:9D:9B:6B` and `/org/bluez/obex/client/session0` with the values from your target.

## Check OBEX support

MAP requires the BlueZ OBEX daemon. On many Linux images, OBEX runs as a user D-Bus service.

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

## Verify remote MAP UUID

Use `bluetoothctl` to confirm that the phone advertises MAP server support.

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
	UUID: Message Access Server (00001132-0000-1000-8000-00805f9b34fb)
```

## Connect a MAP session

Start an interactive `obexctl` session:

```
obexctl
```

Connect to the phone with the MAP target:

```
connect <bt_address> map
```

Example:

```
connect F8:7D:76:9D:9B:6B map
```

Sample output:

```
Attempting to connect to F8:7D:76:9D:9B:6B
[NEW] Session /org/bluez/obex/client/session0
Connection successful
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex org.bluez.obex.Client1 CreateSession sa{sv} F8:7D:76:9D:9B:6B 1 Target s map
```

The returned object path is the session path used by later MAP calls.

## Browse message folders

In `obexctl`, use the generic folder commands to inspect the MAP folder tree:

```
ls
cd telecom
ls
cd msg
ls
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 ListFolders a{sv} 1 MaxCount q 20
```

Sample output:

```
aa{sv} 4 1 "Name" s "inbox" 1 "Name" s "sent" 1 "Name" s "outbox" 1 "Name" s "deleted"
```

Change the working folder:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 SetFolder s telecom/msg
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 SetFolder s inbox
```

## List messages

List messages in the current folder or a named subfolder.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 ListMessages sa{sv} "" 3 MaxCount q 20 SubjectLength y 80 Fields as 5 Subject Timestamp Sender SenderAddress Read
```

Sample output:

```
a(oa{sv}) 1 "/org/bluez/obex/client/session0/message0" 5 "Subject" s "Meeting update" "Timestamp" s "20260525T093000" "Sender" s "Alice Example" "SenderAddress" s "+60123456789" "Read" b false
```

List available message filter fields:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 ListFilterFields
```

## Download a message

After listing messages, use the returned message object path to download a message in bMessage format.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0/message0 org.bluez.obex.Message1 Get sb /tmp/message.bmsg false
```

Sample output:

```
o "/org/bluez/obex/client/session0/transfer0"
a{sv} 3 "Status" s "queued" "Name" s "message.bmsg" "Filename" s "/tmp/message.bmsg"
```

Monitor the transfer:

```
busctl --user get-property org.bluez.obex /org/bluez/obex/client/session0/transfer0 org.bluez.obex.Transfer1 Status
busctl --user get-property org.bluez.obex /org/bluez/obex/client/session0/transfer0 org.bluez.obex.Transfer1 Filename
```

## Update the inbox

Ask the remote phone to refresh its inbox before listing messages again.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 UpdateInbox
```

## Mark a message as read

If the phone allows it, mark a message as read through the message object.

Using D-Bus:

```
busctl --user set-property org.bluez.obex /org/bluez/obex/client/session0/message0 org.bluez.obex.Message1 Read b true
```

## Push a message

MAP can push a local message file in bMessage format to the remote phone. Treat this as optional unless sending messages is part of the AGL validation scope.

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex/client/session0 org.bluez.obex.MessageAccess1 PushMessage ssa{sv} /tmp/outgoing.bmsg outbox 3 Transparent b false Retry b true Charset s UTF-8
```

Sample output:

```
o "/org/bluez/obex/client/session0/transfer1"
a{sv} 3 "Status" s "queued" "Name" s "outgoing.bmsg" "Filename" s "/tmp/outgoing.bmsg"
```

## Disconnect the MAP session

In `obexctl`:

```
disconnect
```

Using D-Bus:

```
busctl --user call org.bluez.obex /org/bluez/obex org.bluez.obex.Client1 RemoveSession o /org/bluez/obex/client/session0
```

## BlueZ OBEX Proxy XML

Use this proxy XML as a compact reference for the BlueZ OBEX D-Bus interfaces used by the MAP commands above.

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

  <interface name="org.bluez.obex.MessageAccess1">
    <method name="SetFolder">
      <arg name="name" type="s" direction="in"/>
    </method>
    <method name="ListFolders">
      <arg name="filter" type="a{sv}" direction="in"/>
      <arg name="folders" type="aa{sv}" direction="out"/>
    </method>
    <method name="ListFilterFields">
      <arg name="fields" type="as" direction="out"/>
    </method>
    <method name="ListMessages">
      <arg name="folder" type="s" direction="in"/>
      <arg name="filter" type="a{sv}" direction="in"/>
      <arg name="messages" type="a(oa{sv})" direction="out"/>
    </method>
    <method name="UpdateInbox"/>
    <method name="PushMessage">
      <arg name="sourcefile" type="s" direction="in"/>
      <arg name="folder" type="s" direction="in"/>
      <arg name="args" type="a{sv}" direction="in"/>
      <arg name="transfer" type="o" direction="out"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
  </interface>

  <interface name="org.bluez.obex.Message1">
    <method name="Get">
      <arg name="targetfile" type="s" direction="in"/>
      <arg name="attachment" type="b" direction="in"/>
      <arg name="transfer" type="o" direction="out"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
    <property name="Folder" type="s" access="read"/>
    <property name="Subject" type="s" access="read"/>
    <property name="Timestamp" type="s" access="read"/>
    <property name="Sender" type="s" access="read"/>
    <property name="SenderAddress" type="s" access="read"/>
    <property name="ReplyTo" type="s" access="read"/>
    <property name="Recipient" type="s" access="read"/>
    <property name="RecipientAddress" type="s" access="read"/>
    <property name="Type" type="s" access="read"/>
    <property name="Size" type="t" access="read"/>
    <property name="Status" type="s" access="read"/>
    <property name="Priority" type="b" access="read"/>
    <property name="Read" type="b" access="readwrite"/>
    <property name="Deleted" type="b" access="write"/>
    <property name="Sent" type="b" access="read"/>
    <property name="Protected" type="b" access="read"/>
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
