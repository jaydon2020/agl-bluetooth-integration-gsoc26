---
title: Install OBEX Tools on AGL Yocto
navTitle: Install OBEX on Yocto
description: Add BlueZ OBEX support and the obexctl client to an AGL Yocto image.
---

`obexctl` is not installed on an AGL or Yocto Raspberry Pi image with `apt`. It must be included in the image at build time.

In OE-Core, `bluez5-obex` packages the OBEX daemon, systemd units, and D-Bus service files. The `obexctl` client is normally built as a BlueZ no-install tool, so include it explicitly in `bluez5-noinst-tools` when the target image needs PBAP, MAP, OPP, or other OBEX validation.

This guide is a build-time fix. Use it when the target image boots successfully but PBAP or MAP validation fails because `obexctl` or `org.bluez.obex` is missing.

## Add a BlueZ bbappend

Create a bbappend in your own layer:

```
mkdir -p meta-your-layer/recipes-connectivity/bluez5
nano meta-your-layer/recipes-connectivity/bluez5/bluez5_%.bbappend
```

Add the OBEX profile support, readline client support, and the `obexctl` no-install tool:

```
# Make sure OBEX support and readline client support are enabled.
PACKAGECONFIG:append = " obex-profiles readline"

# Install obexctl, which BlueZ normally builds as a no-install tool.
NOINST_TOOLS_READLINE:append = " tools/obexctl"
```

## Add packages to the image

For quick testing, add the packages in `build/conf/local.conf`. Keep the leading space inside the string; the `:append` operator does not add it automatically.

```
IMAGE_INSTALL:append = " bluez5 bluez5-obex bluez5-noinst-tools"
```

For a cleaner project setup, put the same package list in your custom image recipe or in a packagegroup instead of `local.conf`.

## Rebuild

From the AGL build environment, rebuild BlueZ and the target image:

```
bitbake bluez5 -c cleansstate
bitbake <your-agl-image>
```

Example image names:

```
bitbake agl-image-minimal
bitbake agl-image-weston
```

Use your custom image name if the project has one.

## Verify before flashing

After the build finishes, check which package owns `obexctl`:

```
oe-pkgdata-util find-path /usr/bin/obexctl
```

Expected result:

```
bluez5-noinst-tools: /usr/bin/obexctl
```

You can also inspect the package contents:

```
oe-pkgdata-util list-pkg-files bluez5-noinst-tools | grep obexctl
```

## Verify on Raspberry Pi 5

After flashing and booting the new AGL image, check that `obexctl` exists:

```
which obexctl
obexctl
```

Expected result:

```
/usr/bin/obexctl
[NEW] Client /org/bluez/obex
[obex]#
```

Check that Bluetooth and OBEX services are available:

```
systemctl status bluetooth
systemctl status obex
```

If `obexctl` exists but OBEX sessions do not work, the missing part is usually `bluez5-obex`, `obexd`, or phone-side permission, not the CLI itself.

## Older AGL or Yocto syntax

If the AGL branch is older and does not support `:append`, use the legacy override syntax:

```
PACKAGECONFIG_append = " obex-profiles readline"
NOINST_TOOLS_READLINE_append = " tools/obexctl"
IMAGE_INSTALL_append = " bluez5 bluez5-obex bluez5-noinst-tools"
```

## Recommended final setup

Keep the BlueZ recipe change in your layer:

```
# meta-your-layer/recipes-connectivity/bluez5/bluez5_%.bbappend

PACKAGECONFIG:append = " obex-profiles readline"
NOINST_TOOLS_READLINE:append = " tools/obexctl"
```

Then include the runtime packages from the image recipe or packagegroup:

```
IMAGE_INSTALL:append = " bluez5 bluez5-obex bluez5-noinst-tools"
```

## References

- OE-Core BlueZ recipe: [bluez5.inc](https://github.com/openembedded/openembedded-core/blob/master/meta/recipes-connectivity/bluez5/bluez5.inc)
- Yocto image customization: [Customizing Images](https://docs.yoctoproject.org/dev-manual/customizing-images.html)
