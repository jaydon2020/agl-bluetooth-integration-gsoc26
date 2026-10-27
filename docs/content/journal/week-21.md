---
title: Week 21
description: Progress summary for Week 21 (October 12-18, 2026) of the AGL Bluetooth Integration project.
---

This week, I integrated the HFP telephony and phone-contact flows into the
Flutter AGL homescreen and fully tested the UI and Bluetooth call flows on AGL
running on the Raspberry Pi 5.

## Status

- **Status**: Completed
- **Timeline**: October 12, 2026 to October 18, 2026
- **Target**: AGL Raspberry Pi 5

The implementation supports phone connection status, recent calls, contacts,
dialling, active-call controls, and phone messages through the native HFP and
OBEX libraries.

## AGL UI Validation

All full and partial telephone numbers shown in the screenshots are masked for
privacy.

The AGL launcher exposes the Phone and Messages applications alongside the
other homescreen applications. The shared left-side controls provide volume,
playback, and mute access, while the bottom navigation keeps Home, HVAC, Media,
Settings, and Apps available throughout the flow.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133356347.jpg" alt="AGL homescreen Applications view showing Phone, Messages, Bluetooth Telephony, and other application tiles with shared vehicle controls and bottom navigation." />
  <figcaption>Homescreen application launcher with the Phone, Messages, and Bluetooth Telephony entry points.</figcaption>
</figure>

The Phone screen shows the connected Pixel 9a, a Ready Bluetooth status, and
three modes: Recents, Contacts, and Dial. The Dial view provides the full
keypad for entering a number and starting a call.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133404733.jpg" alt="AGL Phone screen in Dial mode showing a connected Pixel 9a, Ready status, full numeric keypad, clear and delete controls, and call button." />
  <figcaption>Dial mode with number entry, clear/delete actions, and the call button.</figcaption>
</figure>

The Recents view presents incoming and outgoing call history in separate cards.
Each entry shows the contact or number, direction, timestamp, and a call-back
button.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133411890.jpg" alt="AGL Phone Recents view showing recent incoming and outgoing calls with contact names, privacy-masked numbers, timestamps, and call-back buttons." />
  <figcaption>Recent-call history with privacy-masked numbers, direction indicators, and one-touch call-back actions.</figcaption>
</figure>

The Contacts view loads the phone book alphabetically and includes contact
search, refresh, messaging, and calling actions for each contact row.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133418388.jpg" alt="AGL Phone Contacts view showing a searchable alphabetical contact list with message and call actions." />
  <figcaption>Phone-book contacts loaded from the connected device.</figcaption>
</figure>

The active-call screen displays the number and call state in the center. Mute,
keypad, hold, and end-call controls are presented as large touch targets for
in-vehicle use.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133436879.jpg" alt="AGL active-call screen showing a privacy-masked calling number and large Mute, Keypad, Hold, and End call controls." />
  <figcaption>Active HFP call screen with the calling number masked for privacy and the primary call-control actions.</figcaption>
</figure>

The in-call keypad can be opened without leaving the call. The center action
changes to Hide keypad while Mute, Hold, and End call remain available.

<figure>
  <img src="images/journal/week-21/PXL_20261019_133450572.jpg" alt="AGL in-call keypad showing DTMF keys, Mute, Hide keypad, Hold, and End call controls." />
  <figcaption>DTMF keypad available during an active call.</figcaption>
</figure>

## Testing

The HFP calling, SCO audio controls, phone-book loading, recent calls, DTMF
keypad, and message screens were fully tested on AGL Raspberry Pi 5 hardware.

## Next Week

Next week, I will document the completed HFP and phone-contact integration and
push the corresponding code changes for review.
