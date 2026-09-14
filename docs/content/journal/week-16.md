---
title: Week 16
description: Progress summary for Week 16 (September 7-13, 2026) of the AGL Bluetooth Integration project.
---

This week, `bluez_media_native` reached release readiness for publication to
pub.dev, and the homescreen call UI was exercised against the Bluetooth
telephony flow.

## Status

- **Status**: Completed
- **Timeline**: September 7, 2026 to September 13, 2026

## Release Readiness

[`bluez_media_native`](https://github.com/jaydon2020/bluez_media_native) is
ready for release to pub.dev.

## Call UI

The call screens expose the Bluetooth phone connection and the controls needed
for hands-free calling in the IVI:

<figure>
  <img src="images/journal/week-16/Screenshot%20From%202026-09-14%2019-38-59.png" alt="AGL Calls screen showing a connected phone, suggested contacts, a populated dial pad, and a green call button." />
  <figcaption>
    The Calls screen shows the connected phone and suggested contacts at the
    top, followed by a DTMF dial pad. The entered number is displayed above the
    keypad, with Clear, delete, and call actions below it. The left rail keeps
    the media volume, playback, fan, and mute controls available while calling.
  </figcaption>
</figure>

<figure>
  <img src="images/journal/week-16/Screenshot%20From%202026-09-14%2019-39-24.png" alt="AGL active call screen showing Daniel Tan connected, mute, keypad, hold, and end-call controls." />
  <figcaption>
    During an active call, the screen identifies the contact and elapsed call
    time, and provides Mute, Keypad, Hold, and End call controls. The speaker
    volume slider remains on the left so call audio can be adjusted without
    leaving the call screen.
  </figcaption>
</figure>

<figure>
  <img src="images/journal/week-16/Screenshot%20From%202026-09-14%2019-39-06.png" alt="AGL home screen showing an incoming call banner for Jane Doe with decline and answer buttons." />
  <figcaption>
    An incoming call is presented as a banner over the home screen. It includes
    the caller identity and number, with red decline and green answer actions,
    allowing the driver to respond without navigating away from the current
    vehicle view.
  </figcaption>
</figure>

## Next Steps

- Confirm whether AGL will own and publish `bluez_media_native`.
- Publish the package to pub.dev once the ownership decision is made.
