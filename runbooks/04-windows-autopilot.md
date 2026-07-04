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

- Ran `winrm quickconfig -quiet` while the VM's network connection profile was still **Public**. It half-configured (started the WinRM service) but failed the firewall exception step with: *"WinRM firewall exception will not work since one of the network connection types on this machine is set to Public."* Had to run `Set-NetConnectionProfile -NetworkCategory Private` first, then re-run `winrm quickconfig -quiet` — order matters here.
- Assigned a deployment profile to a dynamic Entra ID group using the standard rule `(device.devicePhysicalIds -any (_ -eq "[ZTDId]"))`, then watched the profile's "Assigned devices" count sit at 0 for 20+ minutes. Went down the wrong path assuming it was just replication lag. Checked **Devices > All devices** in Entra and found the device had no object there at all — a hardware hash imported into the Autopilot device inventory via CSV does **not** automatically create a corresponding Entra device object, and the dynamic group rule can only match devices that already exist as Entra objects. Confirmed this conclusively by checking the group's own Overview: **"Dynamic rules processing status: Succeeded"** but **"Device(s): 0"** — the rule itself is valid and evaluated correctly, it just has nothing to match, since no Entra device object exists yet for a hash that's only ever been CSV-imported and never actually booted/enrolled.
- After finally getting a clean VM back to OOBE (see below), booted all the way through region/keyboard/EULA to the "How would you like to set up this device?" screen — the generic personal-vs-work-account choice. With a working User-Driven Autopilot profile this screen should be skipped entirely, so this confirmed live that the profile genuinely never applied, matching the "Device(s): 0" finding above rather than it being just a console display issue.
- Tried **Settings > Recovery > Reset this PC** to get a test VM back to OOBE. Failed immediately with *"There was a problem resetting your PC. No changes were made."* — caused by a missing/broken WinRE recovery partition, common on a manually-provisioned VM that wasn't imaged with proper recovery tooling.
- Switched to `sysprep /oobe /generalize /shutdown` instead (from a fresh clone of a master VM image). Failed with *"Sysprep was not able to validate your Windows installation."* The setupact.log showed the real cause: **BitLocker was on for the OS volume**, and sysprep refuses to generalize an encrypted volume. Had to run `manage-bde -off C:` and wait for full decryption before sysprep would proceed.
- The BitLocker decryption itself was extremely slow and ran in throttled background bursts (visible in Task Manager's Disk graph as periodic spikes, not continuous activity) rather than a steady linear progress — and had a nasty side effect: decrypting every sector of the volume caused the VM's thin-provisioned virtual disk file to balloon from ~19GB to ~31GB on the host Mac, which was enough to push the host's actual free disk space to zero and crash out of several tools mid-session.

## What I Learned

- Autopilot's "assign profile before first boot" pattern (via dynamic Entra group matching on ZTDId) is the documented approach, but in this lab setup the Entra device object needed for the dynamic rule to match never got created from a CSV import alone — it appears to require an actual successful enrolment/check-in first, which is a chicken-and-egg problem for pre-assigning a profile to a device that's never booted. This is a real limitation of testing Autopilot with a manually-imported hash in a lab, not a fixable misconfiguration — worth stating plainly in an interview rather than pretending the demo worked end-to-end. In production this is a non-issue because OEM/reseller drop-ship registration works through a different pipeline than a manual CSV import.
- Learned to distinguish a genuine sync/propagation delay from a structural failure by checking the *group's own* diagnostics (Overview page shows "Dynamic rules processing status" and a live "Device(s)" count) rather than only watching the deployment profile's "Assigned devices" counter — the group-level view confirms whether the rule engine ran successfully and simply found no match, versus something being stuck.
- `winrm quickconfig` has a hard dependency on the network connection profile already being Private or Domain — running it before fixing a Public profile leaves WinRM half-configured and needs a second pass.
- Sysprep and BitLocker are incompatible — any "golden image" VM meant to be sysprepped repeatedly for lab testing should have BitLocker/device encryption disabled (via Group Policy or registry) from the very first boot, before Windows has a chance to auto-enable it, rather than trying to decrypt after the fact.
- A manually-built VM often lacks a working WinRE partition, so "Reset this PC" can't be relied on as a way to get back to OOBE for repeat testing — cloning a clean, pre-configured "master" VM image is a more reliable and much faster way to get a repeatable test bed than either in-place reset or sysprep-in-place.
- Full-volume BitLocker decryption is genuinely disk-I/O-heavy and can dramatically inflate a thin-provisioned virtual disk's real footprint on the host — worth checking host disk headroom before kicking one off, especially in a resource-constrained lab environment.

## Production Considerations

- In production, hardware hashes come from the OEM/reseller (drop-ship), not manual PowerShell capture — manual capture is really only practical for a small pilot or lab.
- Autopilot deployment profiles should be scoped to specific dynamic groups (by device group tag or purchase order) so different business units/regions get different OOBE branding or app sets, not a single global profile.
- ESP "block device use" is a trade-off: too strict frustrates users on slow networks, too loose lets users bypass required software installs. Pilot-test timeout values before broad rollout.
- Autopilot Self-Deploying or Pre-provisioning (White Glove) modes exist for kiosk/shared devices and IT-staged builds — worth knowing the distinction even if this lab only covers User-Driven.
