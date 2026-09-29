---
title: Week 18
description: Progress summary for Week 18 (September 21-27, 2026) of the AGL Bluetooth Integration project.
---

I published the updated [`bluez_media_native`](https://pub.dev/packages/bluez_media_native)
package to pub.dev; its API is unchanged. I also raised [SPEC-5718](https://lf-automotivelinux.atlassian.net/browse/SPEC-5718) to request an AGL BlueZ media repository.


## Verification

Built and verified against [Yocto Wrynose 6.0.2 / SPEC-5670](https://lf-automotivelinux.atlassian.net/browse/SPEC-5670)
at [AGL commit `cde5ce6`](https://gerrit.automotivelinux.org/gerrit/c/AGL/AGL-repo/+/31893).
`mpris-proxy` and OBEX are available by default on master.

## Cover Art

Cover art requires BlueZ experimental mode (`-E`):

```
mkdir -p /etc/systemd/system/bluetooth.service.d && \
echo -e '[Service]\nExecStart=\nExecStart=/usr/libexec/bluetooth/bluetoothd -E' > /etc/systemd/system/bluetooth.service.d/experimental.conf && \
systemctl daemon-reload && \
systemctl restart bluetooth
```

## Media Browsing

Do not play album-list items until the [BlueZ MediaPlayer patch series](https://lore.kernel.org/linux-bluetooth/20260821193449.1336263-1-george.kiagiadakis@collabora.com/)
is applied; otherwise BlueZ may crash. 
