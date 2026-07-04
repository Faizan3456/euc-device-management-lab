# Runbook 04 — Windows Autopilot

## Objective

Enrol a Windows device into Intune with zero-touch provisioning using Windows Autopilot — the Windows equivalent of Apple's ADE.

## Prerequisites

- Completed [01-tenant-setup.md](01-tenant-setup.md)
- A Windows 10/11 device or VM I can reset to Out-of-Box Experience (OOBE)
- Ability to capture the device's hardware hash (via PowerShell script or OEM registration — for a lab VM I generate it myself)
- Understanding that real production Autopilot devices are usually registered automatically by the OEM/reseller at purchase time (drop-ship model) — in the lab I do this step manually

## Steps

1. **Capture the hardware hash**
   1. On the test Windows device (before or after a fresh Windows install), open an elevated PowerShell window.
   2. Install the hash-capture helper and export the hash:
      ```powershell
      Install-Script -Name Get-WindowsAutoPilotInfo -Force
      Get-WindowsAutoPilotInfo.ps1 -OutputFile "$env:USERPROFILE\Desktop\AutopilotHWID.csv"
      ```
      - `[screenshot: PowerShell output showing hash captured]`
3. **Import the hardware hash into Intune**
   1. In Intune admin center, go to **Devices > Windows > Windows enrolment > Devices > Import**.
   2. Upload `AutopilotHWID.csv`.
      - `[screenshot: Intune - Autopilot device imported, sync status]`
   3. Wait for the sync (can take several minutes), then confirm the device appears in the Autopilot devices list, and assign it to `Lab-Test-Devices` group (see [01-tenant-setup.md](01-tenant-setup.md)).
      - `[screenshot: device visible in Autopilot devices list with group membership]`
4. **Create a Deployment Profile**
   1. Go to **Devices > Windows > Windows enrolment > Deployment Profiles > Create profile > Windows PC**.
   2. Name it `Lab-Autopilot-UserDriven`, deployment mode **User-Driven**, join type **Microsoft Entra joined**.
   3. Configure Out-of-Box Experience (OOBE): hide privacy settings, hide EULA, hide change account options, set user account type to **Standard** (realistic least-privilege default).
      - `[screenshot: deployment profile settings]`
   4. Assign the profile to `Lab-Test-Devices`.
      - `[screenshot: profile assignment]`
5. **Configure an Enrolment Status Page (ESP)**
   1. Go to **Devices > Windows > Windows enrolment > Enrolment Status Page**, create one that blocks device use until required apps/profiles install, with a reasonable timeout (e.g., 60 minutes) and "Continue anyway" after timeout enabled — realistic middle ground between forcing completion and not blanket-blocking Support desk.
      - `[screenshot: ESP configuration]`
6. **Reset and boot the device through OOBE**
   1. Reset the Windows device (Settings > Recovery > Reset this PC, or reinstall Windows).
   2. Boot through OOBE, connect to Wi-Fi, and confirm it recognizes itself as an Autopilot device (shows my configured branding instead of generic OOBE).
      - `[screenshot: OOBE showing Autopilot branded screen]`
   3. Sign in with the Entra ID test user, watch the ESP screen track app/profile installation progress.
      - `[screenshot: ESP progress screen]`
7. **Verify in Intune**
   1. Confirm the device shows up under **Devices > All devices** with enrolment type `Windows Autopilot` and is Entra-joined.
      - `[screenshot: device details confirming Autopilot enrolment]`

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if the ESP times out because a required app fails to install — does the user get stuck or does "continue anyway" kick in? What happens if I forget to assign the deployment profile before the device boots to OOBE?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- In production, hardware hashes come from the OEM/reseller (drop-ship), not manual PowerShell capture — manual capture is really only practical for a small pilot or lab.
- Autopilot deployment profiles should be scoped to specific dynamic groups (by device group tag or purchase order) so different business units/regions get different OOBE branding or app sets, not a single global profile.
- ESP "block device use" is a trade-off: too strict frustrates users on slow networks, too loose lets users bypass required software installs. Pilot-test timeout values before broad rollout.
- Autopilot Self-Deploying or Pre-provisioning (White Glove) modes exist for kiosk/shared devices and IT-staged builds — worth knowing the distinction even if this lab only covers User-Driven.
