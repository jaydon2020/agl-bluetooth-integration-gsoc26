---
title: AGL Bluetooth Integration - GSoC 2026
description: JianDe's GSoC 2026 contributor portfolio for modern Bluetooth integration in Automotive Grade Linux.
---

<section class="home-hero">
  <div class="home-hero-copy">
    <p class="hero-eyebrow">GSoC 2026 contributor</p>
    <h2>AGL Bluetooth Integration</h2>
    <p>
      A clean project portfolio for adding phone-to-IVI Bluetooth support in
      Automotive Grade Linux through BlueZ, PipeWire, WirePlumber, C++ D-Bus,
      and Flutter.
    </p>
    <p>
      The goal is to make pairing, media audio, hands-free calls, phone book
      access, and messages easier to validate and automate on the modern AGL
      Flutter IVI stack.
    </p>
  </div>
  <div class="home-hero-card">
    <p class="hero-eyebrow">Project path</p>
    <ul>
      <li>Connect a phone to the AGL IVI target</li>
      <li>Automate media/audio behavior through A2DP and AVRCP</li>
      <li>Prepare HFP, PBAP, and MAP profile integration</li>
      <li>Expose reliable Bluetooth state to Flutter apps</li>
    </ul>
  </div>
</section>

<section class="home-feature-section scope-section" aria-labelledby="scope-heading">
  <div class="section-heading-row">
    <div>
      <p class="hero-eyebrow">Scope</p>
      <h2 id="scope-heading">From phone connection to IVI features</h2>
    </div>
    <p>
      Each Bluetooth profile maps to a user-visible IVI behavior, from media
      playback to calls, contacts, and messages.
    </p>
  </div>
  <div class="scope-grid">
    <article class="scope-card">
      <span class="material-symbols" aria-hidden="true" translate="no">music_note</span>
      <h3>A2DP</h3>
      <p>Media audio from a connected phone into the IVI audio stack.</p>
    </article>
    <article class="scope-card">
      <span class="material-symbols" aria-hidden="true" translate="no">radio_button_checked</span>
      <h3>AVRCP</h3>
      <p>Playback metadata and media controls such as play, pause, and next track.</p>
    </article>
    <article class="scope-card">
      <span class="material-symbols" aria-hidden="true" translate="no">phone_iphone</span>
      <h3>HFP</h3>
      <p>Hands-free calling, call state, and call audio routing for the IVI.</p>
    </article>
    <article class="scope-card">
      <span class="material-symbols" aria-hidden="true" translate="no">contacts</span>
      <h3>PBAP</h3>
      <p>Phone book access for contact lists and caller identity.</p>
    </article>
    <article class="scope-card">
      <span class="material-symbols" aria-hidden="true" translate="no">chat</span>
      <h3>MAP</h3>
      <p>Message access for future IVI notification and messaging flows.</p>
    </article>
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
        GSoC 2026 contributor.
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
