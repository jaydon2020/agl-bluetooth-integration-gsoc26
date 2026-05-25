---
title: Inspect Raspberry Pi D-Bus System Bus from PC
navTitle: Remote D-Bus Inspection
description: Forward the Raspberry Pi system D-Bus socket over SSH and inspect it from a PC with busctl or D-Spy.
---

This guide shows how to inspect the remote Raspberry Pi system D-Bus from a PC without running every debugging tool directly on the target. The workflow forwards the Raspberry Pi system bus Unix socket over SSH, then points local tools such as `busctl` or D-Spy at the forwarded socket.

The Raspberry Pi system bus socket is normally:

```
/run/dbus/system_bus_socket
```

This guide forwards it to a local Unix socket on the PC:

```
/root/dbus_on_local
```

Local tools then connect to:

```
unix:path=/root/dbus_on_local
```

`busctl` supports custom D-Bus addresses through `--address=ADDRESS`, and can then run commands such as `list`, `status`, `tree`, `introspect`, `get-property`, `call`, and `monitor`.

## Check Raspberry Pi system bus

From the PC, SSH into the Raspberry Pi:

```
ssh root@raspberrypi5.lan
```

On the Raspberry Pi, check that the system bus socket exists:

```
ls -l /run/dbus/system_bus_socket
```

Sample output:

```
srw-rw-rw- 1 root root 0 May 25 09:00 /run/dbus/system_bus_socket
```

Also test that the Pi can inspect its own system bus:

```
busctl --system list
```

Or simply:

```
busctl list
```

By default, `busctl` talks to the system bus unless `--user` is specified.

Exit back to the PC:

```
exit
```

## Create SSH Unix socket forwarding

On the PC, remove any old forwarded socket first:

```
sudo rm -f /root/dbus_on_local
```

Create the SSH tunnel:

```
sudo ssh -nNT \
  -o ExitOnForwardFailure=yes \
  -L /root/dbus_on_local:/run/dbus/system_bus_socket \
  root@raspberrypi5.lan
```

The forwarding rule means:

```
local PC socket        -> remote Raspberry Pi socket
/root/dbus_on_local    -> /run/dbus/system_bus_socket
```

The SSH process stays running while the tunnel is active. Keep this terminal open while inspecting D-Bus.

If the socket already exists, SSH may fail to bind it. OpenSSH has a `StreamLocalBindUnlink` option for removing existing Unix-domain socket files before forwarding, but manually running `rm -f` first is usually the simplest workflow.

## Inspect with busctl

Open a second terminal on the PC and check that the forwarded socket exists:

```
sudo ls -l /root/dbus_on_local
```

List the remote Raspberry Pi D-Bus names:

```
sudo busctl --address=unix:path=/root/dbus_on_local list
```

Show a service status:

```
sudo busctl --address=unix:path=/root/dbus_on_local status org.bluez
```

Show an object tree:

```
sudo busctl --address=unix:path=/root/dbus_on_local tree org.bluez
```

Introspect an object:

```
sudo busctl --address=unix:path=/root/dbus_on_local introspect org.bluez /org/bluez
```

Monitor all bus traffic:

```
sudo busctl --address=unix:path=/root/dbus_on_local monitor
```

Monitor only one service:

```
sudo busctl --address=unix:path=/root/dbus_on_local monitor org.bluez
```

`busctl monitor` dumps messages being exchanged on the bus, while `tree` shows object paths and `introspect` shows interfaces, methods, properties, and signals.

## Inspect BlueZ on Raspberry Pi

List the BlueZ service:

```
sudo busctl --address=unix:path=/root/dbus_on_local list | grep bluez
```

Show the BlueZ object tree:

```
sudo busctl --address=unix:path=/root/dbus_on_local tree org.bluez
```

Introspect the root BlueZ object:

```
sudo busctl --address=unix:path=/root/dbus_on_local introspect org.bluez /org/bluez
```

An adapter path usually looks like:

```
/org/bluez/hci0
```

Introspect the adapter:

```
sudo busctl --address=unix:path=/root/dbus_on_local introspect org.bluez /org/bluez/hci0
```

Get adapter power state:

```
sudo busctl --address=unix:path=/root/dbus_on_local get-property \
  org.bluez \
  /org/bluez/hci0 \
  org.bluez.Adapter1 \
  Powered
```

Start discovery:

```
sudo busctl --address=unix:path=/root/dbus_on_local call \
  org.bluez \
  /org/bluez/hci0 \
  org.bluez.Adapter1 \
  StartDiscovery
```

Stop discovery:

```
sudo busctl --address=unix:path=/root/dbus_on_local call \
  org.bluez \
  /org/bluez/hci0 \
  org.bluez.Adapter1 \
  StopDiscovery
```

## Inspect with D-Spy

D-Spy is a GNOME tool for exploring D-Bus connections.

On Ubuntu or Debian-style systems, install it on the PC:

```
sudo apt install d-spy
```

Run it as root when the forwarded socket is under `/root`:

```
sudo d-spy
```

In D-Spy, open:

```
Bus Names -> Connect to Other Bus
```

Enter:

```
unix:path=/root/dbus_on_local
```

After connecting, D-Spy should show Raspberry Pi system bus services such as:

```
org.freedesktop.DBus
org.bluez
org.freedesktop.NetworkManager
```

## Use a user-writable socket

Using `/root/dbus_on_local` works, but it requires `sudo` for local tools. A user-writable socket avoids `sudo d-spy`.

Create a local directory:

```
mkdir -p ~/.cache/dbus-forward
rm -f ~/.cache/dbus-forward/rpi-system-bus
```

Forward the remote system bus:

```
ssh -nNT \
  -o ExitOnForwardFailure=yes \
  -L ~/.cache/dbus-forward/rpi-system-bus:/run/dbus/system_bus_socket \
  root@raspberrypi5.lan
```

Use `busctl` without `sudo`:

```
busctl --address=unix:path=$HOME/.cache/dbus-forward/rpi-system-bus list
```

In D-Spy, connect to:

```
unix:path=/home/YOUR_USERNAME/.cache/dbus-forward/rpi-system-bus
```

## Cleanup

Stop the SSH tunnel with:

```
Ctrl + C
```

Remove the root-owned local socket:

```
sudo rm -f /root/dbus_on_local
```

Or remove the user-writable socket:

```
rm -f ~/.cache/dbus-forward/rpi-system-bus
```

## Troubleshooting

If `busctl` reports connection refused or no such file, check that the SSH tunnel is still running:

```
ps aux | grep "dbus_on_local"
```

Check that the socket exists:

```
sudo ls -l /root/dbus_on_local
```

If SSH reports that the address is already in use, remove the old socket and recreate the tunnel:

```
sudo rm -f /root/dbus_on_local
```

If `busctl` reports permission denied, use `sudo` when the local socket is under `/root`:

```
sudo busctl --address=unix:path=/root/dbus_on_local list
```

If D-Spy cannot open `/root/dbus_on_local`, run D-Spy with `sudo` or forward to a user-writable socket path.

## Recommended workflow

For quick debugging, create the tunnel:

```
sudo rm -f /root/dbus_on_local

sudo ssh -nNT \
  -o ExitOnForwardFailure=yes \
  -L /root/dbus_on_local:/run/dbus/system_bus_socket \
  root@raspberrypi5.lan
```

Then in another terminal:

```
sudo busctl --address=unix:path=/root/dbus_on_local list
sudo busctl --address=unix:path=/root/dbus_on_local tree org.bluez
sudo busctl --address=unix:path=/root/dbus_on_local introspect org.bluez /org/bluez/hci0
```

For GUI inspection:

```
sudo d-spy
```

Connect to:

```
unix:path=/root/dbus_on_local
```

## References

- `busctl` manual: [busctl(1)](https://man7.org/linux/man-pages/man1/busctl.1.html)
- OpenSSH socket-forwarding behavior: [sshd_config(5)](https://manpages.ubuntu.com/manpages/bionic/man5/sshd_config.5.html)
- D-Spy application page: [D-Spy](https://apps.gnome.org/Dspy/)
