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

<section class="home-feature-section sponsor-section" aria-labelledby="sponsors-heading">
  <div class="section-heading-row">
    <div>
      <p class="hero-eyebrow">Sponsors and organizations</p>
      <h2 id="sponsors-heading">Built in the open with GSoC, Linux Foundation, and AGL</h2>
    </div>
    <p>
      This portfolio tracks JianDe's GSoC 2026 work in the Automotive Grade Linux
      ecosystem, with the Linux Foundation and AGL community providing the project context.
    </p>
  </div>
  <div class="sponsor-logo-grid">
    <a class="sponsor-logo-card sponsor-logo-card-gsoc" href="https://summerofcode.withgoogle.com/programs/2026/projects/jkzcDIbh" aria-label="Google Summer of Code project page">
      <span class="sponsor-logo sponsor-logo-gsoc" aria-hidden="true"></span>
    </a>
    <a class="sponsor-logo-card" href="https://www.linuxfoundation.org/" aria-label="The Linux Foundation">
      <span class="sponsor-logo sponsor-logo-linux-foundation" aria-hidden="true"></span>
    </a>
    <a class="sponsor-logo-card sponsor-logo-card-agl" href="https://www.automotivelinux.org/" aria-label="Automotive Grade Linux">
      <span class="sponsor-logo sponsor-logo-agl" aria-hidden="true"></span>
    </a>
  </div>
</section>

<section class="home-feature-section people-section" aria-labelledby="people-heading">
  <div class="section-heading-row">
    <div>
      <p class="hero-eyebrow">People</p>
      <h2 id="people-heading">Contributor and mentors</h2>
    </div>
    <p>
      A compact view of who is building, reviewing, and guiding the Bluetooth
      integration work during GSoC 2026.
    </p>
  </div>
  <div class="people-grid">
    <article class="person-card person-card-featured">
      <p class="person-role">Contributor</p>
      <h3>JianDe (Jaydon)</h3>
      <p>
        GSoC 2026 contributor documenting and implementing the AGL Bluetooth
        integration path across BlueZ, PipeWire, WirePlumber, C++ D-Bus, and Flutter.
      </p>
    </article>
    <article class="person-card">
      <p class="person-role">Primary Mentor</p>
      <h3>George Kiagiadakis</h3>
      <p>Collabora</p>
    </article>
    <article class="person-card">
      <p class="person-role">Secondary Mentor</p>
      <h3>Joel Winarske</h3>
      <p>TCNA</p>
    </article>
    <article class="person-card">
      <p class="person-role">Backup Mentors</p>
      <h3>Justin Noel and Walt Miner</h3>
      <p>ICS and Linux Foundation</p>
    </article>
  </div>
</section>

<ProjectDashboard/>
