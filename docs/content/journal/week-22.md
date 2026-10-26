---
title: Week 22
description: Progress summary for Week 22 (October 19-25, 2026) of the AGL Bluetooth Integration project.
---

This week, I completed and documented the calling features supported by
`flutter-ics-homescreen`. These include phone and call detection, dialing,
incoming and active-call controls, call volume, and SCO Bluetooth call audio.

## Status

- **Status**: Completed
- **Timeline**: October 19, 2026 to October 25, 2026
- **Target**: AGL Raspberry Pi 5

## Telephony features in `flutter-ics-homescreen`

| ID | Feature | Support | Homescreen behavior |
| --- | --- | --- | --- |
| TEL-01 | Outgoing calls | Supported | Dial from the keypad, Recents, Contacts, or a message conversation. Rapid taps start only one call. |
| TEL-02 | Incoming-call overlay | Supported | Shows the caller over the current app with Answer and Decline actions. |
| TEL-03 | Answer, decline, and end | Supported | Sends one operation from the homescreen. If the call is accepted, declined, or ended on the phone, the overlay and call screen update automatically to match the native call state. |
| TEL-04 | In-call keypad | Not supported | DTMF touch tones cannot currently be sent during an active call. |
| TEL-05 | Microphone mute | Supported | Mute sets microphone gain to zero; unmute restores the previous nonzero gain. |
| TEL-06 | Waiting-call actions | Conditional | Offers Hold & answer and End & answer when a second call is waiting. Accepting, holding, or ending a call on the phone automatically updates the homescreen UI. |
| TEL-07 | Multi-call actions | Conditional | Shows Swap, End & swap, and Merge only when the current call combination supports them. Phone-side hold, swap, merge, or hangup changes automatically update the displayed calls and controls. A single call does not show Hold/Resume. |
| TEL-09 | Primary-call transition | Supported | When the phone swaps or activates another call, the homescreen automatically updates the participant and resets the duration for the new primary call. |
| TEL-10 | Phone switching | Supported | Clears the previous phone's call and gateway data before showing data from the newly connected phone. |
| TEL-12 | SCO call audio | Supported | Activates bidirectional Bluetooth voice audio when a call becomes active. |

## Screenshot-to-flow map

The screenshots below demonstrate the main visible flows. Some conditional and
recovery behaviors in the table do not have a separate screenshot.
All full and partial telephone numbers are masked for privacy.

| Flow | Screens | Capability coverage |
| --- | --- | --- |
| 1. Discover telephony data | Ready dial view (`06-55-14`), recent calls (`06-55-23`), contacts (`06-55-38`) | Phone availability, call list, and caller details |
| 2. Enter and dial a number | Partial number (`06-55-51`), complete number (`06-56-00`), alternate entry (`07-09-44`) | Number entry and outgoing calls |
| 3. Monitor and control a call | End call (`06-56-16`), SCO call (`06-59-27`), microphone mute (`07-52-06`) | Call status, caller details, hangup, microphone control, and SCO call audio |
| 4. Receive a call while viewing another app | Incoming (`12-45-09`), answered (`12-45-16`), muted (`12-45-20`) | Incoming-call overlay, Answer/Decline, active-call overlay, microphone mute, and hangup |

### Flow 1: Discover telephony data

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-55-14.png" alt="Phone Dial tab showing the connected device in Ready state and an empty keypad." />
  <figcaption><strong>TEL-01:</strong> The Ready dial screen confirms that the connected phone is available before placing a call.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-55-23.png" alt="Phone Recents tab showing calls discovered for the connected phone." />
  <figcaption><strong>TEL-01:</strong> The Recents view provides one route for starting an outgoing call.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-55-38.png" alt="Phone Contacts tab showing synchronized contacts and call actions." />
  <figcaption><strong>TEL-01:</strong> The Contacts view provides another route for starting an outgoing call.</figcaption>
</figure>

### Flow 2: Enter and dial a number

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-55-51.png" alt="Phone keypad with a privacy-masked partial telephone number." />
  <figcaption><strong>TEL-01:</strong> Number entry begins on the dial keypad; the entered digits are masked for privacy.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-56-00.png" alt="Phone keypad with the complete telephone number masked for privacy." />
  <figcaption><strong>TEL-01:</strong> The completed, privacy-masked number is ready to place an outgoing call.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_07-09-44.png" alt="Phone keypad showing another privacy-masked partial telephone-number entry." />
  <figcaption><strong>TEL-01:</strong> An alternate privacy-masked number entry uses the same outgoing-call flow.</figcaption>
</figure>

### Flow 3: Monitor and control a call

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-56-16.png" alt="Call screen showing Hean Wei Ying with microphone, keypad, and hangup controls." />
  <figcaption><strong>TEL-03:</strong> The call view shows the participant and the control used to end the call.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_06-59-27.png" alt="Active call screen for Jian De Saek while monitoring the call." />
  <figcaption><strong>TEL-12:</strong> The continued active call uses the SCO voice-audio path.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_07-52-06.png" alt="Call screen with privacy-masked caller numbers and the microphone control highlighted." />
  <figcaption><strong>TEL-05:</strong> The highlighted microphone action shows the muted state.</figcaption>
</figure>

### Flow 4: Receive a call while viewing another app

TEL-02 shows that an incoming call does not force the driver away from the
current app. The global call overlay identifies the caller and keeps the
relevant controls available throughout the call.

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_12-45-09.png" alt="HVAC screen with an incoming-call banner for Jian De Seak showing Decline and Answer controls." />
  <figcaption><strong>TEL-02:</strong> The incoming-call banner appears over HVAC with the caller name, privacy-masked telephone number, Decline, and Answer actions.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_12-45-16.png" alt="HVAC screen with a compact active-call overlay for Jian De Seak showing duration, microphone, and hangup controls." />
  <figcaption><strong>TEL-03:</strong> After answering, the compact overlay shows the active participant, call duration, microphone control, and hangup action.</figcaption>
</figure>

<figure>
  <img src="images/journal/week-22/agl-screenshot-HDMI-A-1-2026-10-26_12-45-20.png" alt="HVAC screen with an active-call overlay showing the microphone muted." />
  <figcaption><strong>TEL-05:</strong> The highlighted microphone icon confirms the muted state while the call remains active over HVAC.</figcaption>
</figure>

## Scope boundaries

The PipeWire client controls and observes the telephony service and SCO
transport. Bluetooth pairing and profile connection remain BlueZ/platform
policy responsibilities, while PCM routing and audio focus remain with
WirePlumber or AGL audio policy. Screenshots of Bluetooth pairing, HVAC, and
media playback were therefore removed from this report.

## Next Week

Next week, I will submit the completed PipeWire telephony documentation and
implementation for review and address any final integration feedback.
