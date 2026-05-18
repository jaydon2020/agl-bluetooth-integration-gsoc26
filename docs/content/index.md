---
title: AGL Bluetooth Integration — GSoC 2026
description: JianDe's GSoC26 project portfolio for modern Bluetooth integration in Automotive Grade Linux.
---

<section class="home-hero">
  <div class="home-hero-copy">
    <p class="hero-eyebrow">JianDe's GSoC26</p>
    <h2>Modern Bluetooth for the AGL Flutter IVI stack</h2>
    <p>
      This project documents a modern Bluetooth integration path for Automotive Grade Linux,
      replacing legacy afb-daemon mappings with a native C++ D-Bus bridge to BlueZ and a
      Flutter-facing API for the IVI experience.
    </p>
    <p>
      The validation path focuses on BlueZ, PipeWire, WirePlumber, and profile-oriented
      smoke tests on Raspberry Pi 5 hardware.
    </p>
  </div>
  <div class="home-hero-card">
    <p class="hero-eyebrow">Stack focus</p>
    <ul>
      <li>BlueZ over D-Bus for adapter and device lifecycle</li>
      <li>PipeWire and WirePlumber for Bluetooth audio routing</li>
      <li>Flutter plugin architecture for the AGL homescreen</li>
      <li>Repeatable GSoC validation and reporting workflow</li>
    </ul>
  </div>
</section>

<div class="quick-card-grid">
  <a class="quick-card" href="/bluetooth/overview">
    <span class="material-symbols" aria-hidden="true" translate="no">architecture</span>
    <strong>Architecture Overview</strong>
    <span>Read the project motivation, mentor context, and proposed system architecture.</span>
  </a>
  <a class="quick-card" href="/bluetooth/verify-bluez">
    <span class="material-symbols" aria-hidden="true" translate="no">fact_check</span>
    <strong>BlueZ Verification</strong>
    <span>Run profile-oriented smoke tests for the Linux Bluetooth stack.</span>
  </a>
  <a class="quick-card" href="/journal">
    <span class="material-symbols" aria-hidden="true" translate="no">timeline</span>
    <strong>Weekly Progress Journal</strong>
    <span>Follow week-by-week implementation notes and next steps.</span>
  </a>
  <a class="quick-card" href="/report/midterm">
    <span class="material-symbols" aria-hidden="true" translate="no">assignment</span>
    <strong>Milestones</strong>
    <span>Track midterm and final report readiness.</span>
  </a>
</div>

<ProjectDashboard/>
