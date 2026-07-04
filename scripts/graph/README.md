# Graph Scripts

PowerShell scripts using the Microsoft Graph PowerShell SDK to report on Intune device compliance.

## Setup

1. **Install the Microsoft Graph PowerShell SDK** (once, per machine):
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```
   This is a large module family; you can install just the pieces used here if you prefer:
   ```powershell
   Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
   ```

2. **App permissions / consent.** These scripts use **delegated, interactive auth** — you sign in as yourself, and Entra ID asks you (or an admin) to consent to the scopes below the first time. No app registration is required for lab use.

   | Scope | Why it's needed |
   |---|---|
   | `DeviceManagementManagedDevices.Read.All` | Read managed device list, compliance state, last sync, OS info |
   | `DeviceManagementConfiguration.Read.All` | Read compliance policy details so we can show *which* policy a device is failing |

   Both are **read-only**. Nothing in this folder writes or changes anything in Intune — least privilege for a reporting tool.

   Your signed-in account needs the **Intune Administrator** role (or another role with device-read rights) for consent to succeed and for the calls to return data.

3. **Run in order:**
   ```powershell
   ./Connect-Lab.ps1                    # sign in once per session
   ./Get-DeviceComplianceReport.ps1     # full fleet report -> console + CSV
   ./Get-NonCompliantDevices.ps1        # noncompliant devices + failing policy -> console + CSV
   ```

## Files

| File | Purpose |
|---|---|
| `Connect-Lab.ps1` | Interactive sign-in to Microsoft Graph with the two scopes above; prints granted scopes so you can confirm consent worked |
| `Get-DeviceComplianceReport.ps1` | All managed devices: name, OS, compliance state, last sync. Prints a summary table + compliance breakdown, exports CSV |
| `Get-NonCompliantDevices.ps1` | Filters to noncompliant devices only, and looks up the specific failing policy per device (not just a red flag) |

Output CSVs are written to `scripts/graph/output/`, which is gitignored — reports contain real device/user data and shouldn't be committed.

## Why delegated auth here, not an app registration

For a personal lab, interactive/delegated auth (sign in as yourself) is simplest and avoids creating an app registration with stored secrets. See [runbooks/10-graph-reporting.md](../../runbooks/10-graph-reporting.md) "Production Considerations" for why a real production reporting pipeline should instead use an app registration with certificate-based auth and application permissions, run on a schedule, not a human clicking through a login prompt.
