---
title: Inspect Remote PipeWire with Helvum
navTitle: Remote PipeWire Inspection
description: Forward a target PipeWire socket over SSH and inspect the remote audio graph from a PC with Helvum.
---

Locked-down embedded environments can make audio debugging awkward. On customized Yocto builds or Automotive Grade Linux targets, you may be working with a headless system, a read-only filesystem, and no package manager available on the device.

If you need to debug PipeWire routing, installing a graphical patchbay such as `helvum` directly on the target is usually not practical. Instead, forward the target PipeWire Unix socket over SSH and run `helvum` on the host PC.

This guide uses a Raspberry Pi 5 as the example target, but the same workflow applies to any AGL target that exposes a reachable PipeWire socket.

## Prerequisites

- A Linux host PC with `helvum` installed.
- An AGL or Yocto target running PipeWire.
- SSH access from the host PC to the target.
- Permission to access the target PipeWire socket.

## Locate the target PipeWire socket

SSH into the target:

```
ssh root@<target-hostname-or-ip>
```

Search the runtime directory for the default PipeWire socket:

```
find /run -name "pipewire-0"
```

Common results:

```
/run/pipewire/pipewire-0
/run/user/1000/pipewire-0
```

System-style embedded images often expose PipeWire at `/run/pipewire/pipewire-0`. Desktop-style user sessions usually place it under `/run/user/<uid>/pipewire-0`.

This guide uses the system-style path:

```
/run/pipewire/pipewire-0
```

Exit back to the host PC:

```
exit
```

## Forward the socket to the host PC

On the host PC, create a temporary directory for the local forwarded socket:

```
mkdir -p /tmp/pw-remote
rm -f /tmp/pw-remote/pipewire-0
```

Forward the local Unix socket to the target PipeWire socket:

```
ssh -nNT \
  -o ExitOnForwardFailure=yes \
  -L /tmp/pw-remote/pipewire-0:/run/pipewire/pipewire-0 \
  root@<target-hostname-or-ip>
```

The forwarding rule means:

```
local host socket        -> remote target socket
/tmp/pw-remote/pipewire-0 -> /run/pipewire/pipewire-0
```

The SSH process stays open while the tunnel is active. Keep this terminal open during inspection.

## Launch Helvum locally

Open a second terminal on the host PC.

Point PipeWire clients at the forwarded socket directory and remote name:

```
PIPEWIRE_RUNTIME_DIR=/tmp/pw-remote PIPEWIRE_REMOTE=pipewire-0 helvum
```

Helvum should open on the host desktop and show the PipeWire nodes, ports, and links from the remote target. Connections changed in the GUI are applied to the remote PipeWire graph.

## Optional command-line checks

You can test the same forwarded socket with PipeWire command-line tools:

```
PIPEWIRE_RUNTIME_DIR=/tmp/pw-remote PIPEWIRE_REMOTE=pipewire-0 pw-cli info 0
```

List remote nodes:

```
PIPEWIRE_RUNTIME_DIR=/tmp/pw-remote PIPEWIRE_REMOTE=pipewire-0 pw-cli ls Node
```

Check WirePlumber's view if `wpctl` is installed on the host:

```
PIPEWIRE_RUNTIME_DIR=/tmp/pw-remote PIPEWIRE_REMOTE=pipewire-0 wpctl status
```

## Troubleshooting

If SSH reports that the address is already in use, remove the stale local socket and recreate the tunnel:

```
rm -f /tmp/pw-remote/pipewire-0
```

If Helvum opens but shows the host audio graph, check that both variables are set in the same command:

```
PIPEWIRE_RUNTIME_DIR=/tmp/pw-remote PIPEWIRE_REMOTE=pipewire-0 helvum
```

If Helvum cannot connect, confirm that the tunnel is still running and that the local socket exists:

```
ls -l /tmp/pw-remote/pipewire-0
```

If the target socket is under `/run/user/<uid>`, update the SSH forwarding command to use that exact remote path:

```
ssh -nNT \
  -o ExitOnForwardFailure=yes \
  -L /tmp/pw-remote/pipewire-0:/run/user/1000/pipewire-0 \
  root@<target-hostname-or-ip>
```

## Cleanup

Stop the SSH tunnel with:

```
Ctrl + C
```

Remove the forwarded socket:

```
rm -f /tmp/pw-remote/pipewire-0
```

## References

- PipeWire environment variables: [pipewire(1)](https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire_1.html)
- PipeWire native protocol: [Protocol Native](https://docs.pipewire.org/page_module_protocol_native.html)
- OpenSSH client socket forwarding: [ssh(1)](https://man7.org/linux/man-pages/man1/ssh.1.html)
