# Runbook 06 — Win32 App Packaging

## Objective

Package a real Windows application as a Win32 app (`.intunewin`), deploy it through Intune, and prove detection logic actually works — not just "it installed," but "Intune correctly knows whether it's installed."

## Prerequisites

- Completed [04-windows-autopilot.md](04-windows-autopilot.md) — at least one enrolled Windows test device
- An installer to package — this lab uses 7-Zip as the example (small, free, silent-install switches are well documented)
- [scripts/packaging/win32/package-app.ps1](../scripts/packaging/win32/package-app.ps1) and the 7-Zip example files in the same folder

## Steps

1. **Download the source installer**
   1. Download the 7-Zip MSI/EXE installer into a source folder, e.g. `C:\intune-lab\7zip-source\7z2301-x64.exe`.
      - `[screenshot: source folder contents]`
2. **Wrap it into a .intunewin file**
   1. Run [scripts/packaging/win32/package-app.ps1](../scripts/packaging/win32/package-app.ps1), pointing `-SourceFolder` at the source folder and `-SetupFile` at the installer.
   2. Confirm the script downloads `IntuneWinAppUtil.exe` (if not already present) and produces a `.intunewin` file.
      - `[screenshot: PowerShell output showing .intunewin created]`
3. **Create the Win32 app in Intune**
   1. Go to **Apps > Windows > Add > Win32 app**, upload the `.intunewin` file.
   2. Fill in app info (name, description, publisher, logo).
      - `[screenshot: app info tab]`
   3. Program tab: install command `7z2301-x64.exe /S`, uninstall command from [scripts/packaging/win32/7zip-example/uninstall-7zip.ps1](../scripts/packaging/win32/7zip-example/uninstall-7zip.ps1).
      - `[screenshot: program tab]`
   4. Requirements tab: architecture (x64), minimum OS.
   5. Detection rules: use the custom script [scripts/packaging/win32/7zip-example/detect-7zip.ps1](../scripts/packaging/win32/7zip-example/detect-7zip.ps1) (see `scripts/packaging/win32/README.md` for why a script-based detection was chosen over the built-in MSI rule for this example).
      - `[screenshot: detection rules tab]`
   6. Assignment: assign as **Required** to `Lab-Test-Devices`.
      - `[screenshot: assignment tab]`
4. **Deploy and verify**
   1. Sync the test device (Company Portal > Sync, or wait for the normal check-in cycle).
   2. Confirm install succeeds: **Apps > Monitor > App install status** shows the device as `Installed`.
      - `[screenshot: install status - Installed]`
   3. On the device, verify 7-Zip is actually present (Programs and Features, or `Get-ItemProperty` on the uninstall registry key).
      - `[screenshot: registry/Programs and Features confirming install]`
5. **Break the detection rule on purpose** (see below) and observe what Intune reports.

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if I intentionally point the detection script at the wrong registry key — does Intune report "failed" even though the app installed fine? What happens if I uninstall the app manually on the device — how long until Intune notices and reinstalls it (if required) or flags it (if available)?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Detection rules are the single most common cause of "the app shows as failed but it's actually installed" tickets — always test detection logic against the exact installed version string, not an assumption.
- Version-specific detection rules (checking for a minimum `DisplayVersion`) let you use the same app to service both "not installed" and "needs upgrade" scenarios via app supersedence.
- Silent install/uninstall switches vary per vendor — always verify with the vendor's documentation or `installer.exe /?` rather than guessing.
- Consider app dependencies and supersedence chains for larger app catalogs, rather than one flat list of unrelated Win32 apps.
