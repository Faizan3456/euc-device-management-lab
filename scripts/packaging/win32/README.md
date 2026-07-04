# Win32 Packaging

Scripts for packaging a Windows installer as an Intune Win32 app (`.intunewin`), using 7-Zip as the worked example.

## Files

| File | Purpose |
|---|---|
| `package-app.ps1` | Downloads `IntuneWinAppUtil.exe` if missing, wraps a source folder + installer into `.intunewin` |
| `7zip-example/install-7zip.ps1` | Reference notes: the silent install command to paste into Intune |
| `7zip-example/uninstall-7zip.ps1` | Reference notes: the silent uninstall command to paste into Intune |
| `7zip-example/detect-7zip.ps1` | Custom detection script Intune runs on-device to decide if the app is installed |

## How to package 7-Zip

1. Download a 7-Zip installer (e.g. `7z2301-x64.exe`) into a source folder, e.g. `C:\intune-lab\7zip-source\`.
2. Run:
   ```powershell
   ./package-app.ps1 -SourceFolder "C:\intune-lab\7zip-source" -SetupFile "7z2301-x64.exe"
   ```
3. Upload the resulting `.intunewin` from `./output/` into **Intune > Apps > Windows > Add > Win32 app**.
4. Use the install/uninstall commands documented in the `7zip-example/` scripts, and set the detection rule type to **"Use a custom detection script"**, uploading `7zip-example/detect-7zip.ps1`.

## Detection rule logic — and why it matters

A Win32 app's detection rule is the only thing that tells Intune whether the app is actually installed on a device. It runs **after** the install command completes, independent of whether the installer itself reported success. This distinction trips people up constantly:

- **Install command exit code** tells Intune the *installer process* finished (ideally with exit code 0).
- **Detection rule** tells Intune whether the *software is actually present* afterward.

If these two disagree, you get confusing states:

- Installer exits 0, but detection fails → Intune reports the app as **Failed**, even though it's sitting right there on the machine. This happens when the detection rule checks the wrong registry key, wrong version string, or wrong file path.
- Installer exits non-zero, but something (e.g. a leftover partial install) still matches a loose detection rule → Intune reports **Installed** even though the app is broken.

**Why script-based detection was used here instead of the built-in "MSI product code" rule:** 7-Zip's installer isn't consistently MSI-based across versions/architectures, so a registry-based custom script is more portable and lets us explicitly check `DisplayVersion` — which also sets up future **supersedence** (deploying v23 to replace v19 and using version comparison to detect "needs upgrade" vs "not installed").

**Detection script contract Intune enforces:**
- Must write something to **STDOUT** (`Write-Output`, not `Write-Host`) and **exit 0** to count as "detected."
- No output, or a non-zero exit code, counts as "not detected."
- Runs in a 32-bit PowerShell host by default (relevant if you ever check `Program Files` vs `Program Files (x86)` paths, or the WOW6432Node registry hive) — see the comments in `detect-7zip.ps1`.

Getting detection logic right is one of the most common real-world Intune troubleshooting scenarios — expect it to come up in an interview.
