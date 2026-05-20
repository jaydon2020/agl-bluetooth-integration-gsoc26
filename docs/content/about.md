---
title: About JianDe's GSoC 2026
description: Project context, student information, mentors, and organizations for the AGL Bluetooth Integration GSoC 2026 project.
---

JianDe's GSoC 2026 is a project portfolio and technical documentation site for **AGL Bluetooth Integration**, a Google Summer of Code 2026 project focused on modern Bluetooth support in Automotive Grade Linux.

## Student

| Field | Details |
| --- | --- |
| Name | JianDe |
| Preferred name | Jaydon |
| Project | AGL Bluetooth Integration |
| Program | Google Summer of Code 2026 |

## Project Context

Automotive Grade Linux has moved toward a Flutter-based IVI user experience. This project explores how Bluetooth workflows can fit that modern stack without relying on the legacy `afb-daemon` service model.

The technical direction is:

- Use BlueZ over D-Bus for adapter state, discovery, pairing, trust, connection, and profile data.
- Use PipeWire and WirePlumber for Bluetooth audio routing.
- Bridge Linux Bluetooth services into Flutter through a native C++ plugin.
- Document repeatable validation steps for mentors, reviewers, and future AGL contributors.

## Mentors

| Role | Mentor | Organization |
| --- | --- | --- |
| Primary Mentor | George Kiagiadakis | Collabora |
| Secondary Mentor | Joel Winarske | TCNA |
| Backup Mentor | Justin Noel | ICS |
| Backup Mentor | Walt Miner | Linux Foundation |

## Organizations And Links

- [Google Summer of Code project](https://summerofcode.withgoogle.com/programs/2026/projects/jkzcDIbh)
- [GitHub repository](https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26)
- [Automotive Grade Linux](https://www.automotivelinux.org/)
- [Collabora](https://www.collabora.com/)
- [Toyota Connected North America](https://www.toyotaconnected.com/)
- [Linux Foundation](https://www.linuxfoundation.org/)
- [Integrated Computer Solutions](https://www.ics.com/)

## Site Purpose

This site is both a project log and a technical handoff artifact. It should make progress easy to review during GSoC while leaving enough implementation and validation detail for future contributors to continue the work.

## Brand Note

The Google Summer of Code name and sun logo are used here to identify the program context for this project portfolio. This site remains JianDe's own project documentation and does not imply Google endorsement.
