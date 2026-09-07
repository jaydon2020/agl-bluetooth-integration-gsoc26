---
title: Week 15
description: Progress summary for Week 15 (August 31-September 6, 2026) of the AGL Bluetooth Integration project.
---

This week, the Bluetooth pairing feature merged into
`flutter-ics-homescreen`, and I documented the PipeWire native-HFP call path
over D-Bus.

## Status

- **Status**: Completed
- **Timeline**: August 31, 2026 to September 6, 2026
- **Merged change**: [AGL Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)

## Progress

### 1. Bluetooth Pairing Merged into `flutter-ics-homescreen`

[Gerrit change 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887),
which adds the pairing UI and `bluez_native` support, has merged. The
homescreen now has the reviewed Bluetooth pairing and device-management
foundation needed by the media and telephony work.

The Yocto layer also requires AGL's `flutter-app-plugins.bbclass` updates to
compile the `bluez_native` library: the initial addition in
[Gerrit 31977](https://gerrit.automotivelinux.org/gerrit/c/AGL/meta-agl/+/31977)
and its follow-up fixes in
[Gerrit 31989](https://gerrit.automotivelinux.org/gerrit/c/AGL/meta-agl/+/31989).

### 2. Studied PipeWire Bluetooth Phone Calls over D-Bus

The study established the following implementation and validation points:

- Configure WirePlumber's native HFP backend with
  `bluez5.telephony.use-system-bus = true`; AGL's split system services do not
  have a user session bus.

  ```
  # 30-AGL-bluetooth.conf
  monitor.bluez.properties = {
    bluez5.hfphsp-backend = "native"
    bluez5.telephony.use-system-bus = true
  }
  ```

- Retain oFono for SIM and modem support, but remove its `bluez` PACKAGECONFIG
  so PipeWire is the sole Bluetooth HFP owner.

  ```
  # ofono_%.bbappend
  PACKAGECONFIG:remove = "bluez"
  ```

- Discover the dynamic Audio Gateway (`agN`) and call (`callN`) objects through
  `org.freedesktop.DBus.ObjectManager.GetManagedObjects`; object suffixes must
  not be hard-coded.

  ```
  busctl --system call \
    org.pipewire.Telephony /org/pipewire/Telephony \
    org.freedesktop.DBus.ObjectManager GetManagedObjects
  ```

  Raspberry Pi 5 validation confirmed that the system-bus name is owned by the
  Bluetooth WirePlumber instance and exposed the connected phone as `ag1`:

  ```
  root@raspberrypi5:~# busctl --system status org.pipewire.Telephony
  PID=457
  PIDFD=yes
  PPID=1
  TTY=n/a
  UID=1008
  EUID=1008
  SUID=1008
  FSUID=1008
  GID=1008
  EGID=1008
  SGID=1008
  FSGID=1008
  SupplementaryGIDs=29 44 1008
  Comm=wireplumber
  Exe=/usr/bin/wireplumber
  CommandLine=/usr/bin/wireplumber -p bluetooth
  CGroup=/system.slice/system-wireplumber.slice/wireplumber@bluetooth.service
  Unit=wireplumber@bluetooth.service
  Slice=system-wireplumber.slice
  UserUnit=n/a
  UserSlice=n/a
  Session=n/a
  AuditLoginUID=n/a
  AuditSessionID=n/a
  UniqueName=:1.12
  EffectiveCapabilities=cap_sys_nice
  PermittedCapabilities=cap_sys_nice
  InheritableCapabilities=cap_setpcap cap_sys_admin cap_sys_nice
  BoundingCapabilities=cap_chown cap_dac_override cap_dac_read_search
         cap_fowner cap_fsetid cap_kill cap_setgid
         cap_setuid cap_setpcap cap_linux_immutable cap_net_bind_service
         cap_net_broadcast cap_net_admin cap_net_raw cap_ipc_lock
         cap_ipc_owner cap_sys_module cap_sys_rawio cap_sys_chroot
         cap_sys_ptrace cap_sys_pacct cap_sys_admin cap_sys_boot
         cap_sys_nice cap_sys_resource cap_sys_time cap_sys_tty_config
         cap_mknod cap_lease cap_audit_write cap_audit_control
         cap_setfcap cap_mac_override cap_mac_admin cap_syslog
         cap_wake_alarm cap_block_suspend cap_audit_read cap_perfmon
         cap_bpf cap_checkpoint_restore

  root@raspberrypi5:~# busctl --system call org.pipewire.Telephony /org/pipewire/Telephony \
    org.freedesktop.DBus.ObjectManager GetManagedObjects
  a{oa{sa{sv}}} 1 "/org/pipewire/Telephony/ag1" 2 "org.pipewire.Telephony.AudioGateway1" 3 "Address" s "04:C8:B0:EC:DE:0F" "SpeakerVolume" y 15 "MicrophoneVolume" y 15 "org.pipewire.Telephony.AudioGatewayTransport1" 3 "Codec" y 0 "State" s "idle" "RejectSCO" b false
  root@raspberrypi5:~#
  ```

- Monitor `InterfacesAdded`, `InterfacesRemoved`, and `PropertiesChanged` to
  keep the UI synchronized with call state.

  ```
  busctl --system monitor org.pipewire.Telephony
  ```

- Verify both D-Bus state and the PipeWire graph: an active call must activate
  the SCO transport and provide the HFP downlink to vehicle speakers and uplink
  from the vehicle microphone.

  ```
  busctl --system get-property \
    org.pipewire.Telephony "$AG" \
    org.pipewire.Telephony.AudioGatewayTransport1 State
  PIPEWIRE_RUNTIME_DIR=/run/pipewire wpctl status
  PIPEWIRE_RUNTIME_DIR=/run/pipewire pw-link -l
  ```

- Grant the `agl-driver` application user narrow system-D-Bus permission to
  send messages to `org.pipewire.Telephony`; a broad default-user rule would
  allow arbitrary local users to control calls.

  ```
  <!-- wireplumber-bluetooth.conf -->
  <policy user="agl-driver">
    <allow send_destination="org.pipewire.Telephony"/>
  </policy>
  ```

The detailed command workflow is captured in the
[Hands-Free Profile guide](guide/verify-bluez/profile-hfp), including gateway
and call discovery, outgoing and incoming calls, call state inspection, and
SCO transport checks.

## Next Steps

- Start the homescreen integration for PipeWire telephony call state and
  controls.
- Validate the native Flutter plugin build path with the merged homescreen
  Bluetooth feature.
- Exercise D-Bus call control and SCO audio routing on the Raspberry Pi 5.

## Links

- **Merged homescreen feature**: [Gerrit 31887](https://gerrit.automotivelinux.org/gerrit/c/apps/flutter-ics-homescreen/+/31887)
- **Bluetooth media integration**: [`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native)
- **AGL Flutter plugin build class**: [Gerrit 31977](https://gerrit.automotivelinux.org/gerrit/c/AGL/meta-agl/+/31977), [follow-up fixes in Gerrit 31989](https://gerrit.automotivelinux.org/gerrit/c/AGL/meta-agl/+/31989)
- **AGL native HFP configuration**: [agl-yocto-bluez commit 08a246a](https://github.com/jaydon2020/agl-yocto-bluez/commit/08a246ac62002ee4c640789ed10c5aa6c611db57)
- **Telephony validation guide**: [Hands-Free Profile](guide/verify-bluez/profile-hfp)
