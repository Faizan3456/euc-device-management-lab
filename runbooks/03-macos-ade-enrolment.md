# Runbook 03 — macOS Zero-Touch Enrolment via ADE

## Objective

Enrol a Mac into Intune automatically at first boot (zero-touch), using Automated Device Enrolment (ADE) — no manual profile install, no user needing admin credentials.

## Prerequisites

- Completed [02-abm-intune-link.md](02-abm-intune-link.md) — ABM linked to Intune, test Mac serial assigned to the MDM server
- A Mac that can be wiped/reset to Setup Assistant (erase all content and settings), ideally one purchased through Apple/a reseller and added to ABM. If I don't have an ADE-eligible Mac available, use the fallback in step 6.
- Company Portal for macOS understanding (used for user-driven enrolment, contrasted here with ADE)

## Steps

1. **Create an enrolment profile in Intune**
   1. Go to **Devices > Apple > Enrolment Program Tokens > (my token) > Profiles > Create profile > macOS**.
   2. Name it `Lab-macOS-ADE-Profile`.
   3. Configure: Authentication method (Setup Assistant with modern authentication is more realistic than "Setup Assistant with Company Portal"), skip unnecessary Setup Assistant screens (Siri, Apple Pay, etc. — realistic for a corporate build), require Company Portal install if using modern auth.
      - `[screenshot: Intune - ADE profile configuration]`
2. **Assign the profile to my test Mac**
   1. Under **Devices > Enrolment Program Devices**, select my test Mac's serial and assign `Lab-macOS-ADE-Profile`.
      - `[screenshot: Intune - profile assigned to device]`
3. **Create/confirm a macOS enrolment status page or compliance grace period expectations** (optional but realistic) so I understand what the end user sees during setup.
4. **Erase and boot the Mac**
   1. Erase all content and settings on the test Mac (or use a fresh out-of-box Mac).
   2. Boot it and connect to Wi-Fi/Ethernet in Setup Assistant.
   3. Confirm it automatically detects it's ADE-enrolled and shows the "Remote Management" screen without me touching any profile file.
      - `[screenshot: Mac Setup Assistant - Remote Management screen]`
5. **Complete enrolment and verify in Intune**
   1. Sign in with the modern auth prompt (Entra ID test user credentials).
   2. Let Setup Assistant finish, Company Portal (if configured) installs, MDM profile installs automatically.
   3. In Intune, go to **Devices > All devices** and confirm the Mac shows up with the correct compliance/ownership (`Corporate`) and enrolment type (`Automated Device Enrollment`).
      - `[screenshot: Intune - device details showing ADE enrolment type]`
   4. On the Mac itself, run `scripts/mac-utils/check-mdm-enrolment.sh` to independently confirm enrolment state from the terminal.
      - `[screenshot or terminal output: check-mdm-enrolment.sh result]`
6. **Fallback if I don't have an ADE-eligible Mac**: do a manual/BYOD-style enrolment instead (Company Portal app, "Sign in" > device enrolment), and note in "What I Learned" the practical differences vs. true ADE (user sees more prompts, device is marked `Personal` unless corporate identifiers are set, and there's no "Remote Management" auto-detect screen).

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if I try to enrol a Mac whose serial isn't in the ADE token's device list? What happens if I turn off Wi-Fi mid-Setup-Assistant? What happens if the enrolment profile requires an account not licensed for Intune?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Real deployments almost always disable "Allow user to skip" or set specific Setup Assistant panes to skip, so end users get a consistent, fast first-boot experience without irrelevant screens (Siri, Apple Pay, TV app, etc.).
- Enrolment Status Page equivalents on macOS are less mature than Windows Autopilot's ESP — consider using a macOS onboarding script (postinstall / Notify) to show setup progress to the end user.
- If a device is removed from the ABM MDM server assignment or is unassigned, Intune loses zero-touch control on next wipe — device-to-MDM-server assignment should be tracked as part of asset management, not left to chance.
- Consider a device naming convention profile so devices auto-name themselves consistently (e.g., `MAC-{serial}` or `{department}-{serial}`) at enrolment time rather than relying on end users.
