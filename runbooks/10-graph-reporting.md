# Runbook 10 — Microsoft Graph API Compliance Reporting

## Objective

Pull device compliance data directly out of Intune using the Microsoft Graph API and PowerShell SDK, rather than relying on the Intune admin center UI — the skill that's actually tested in most EUC engineer interviews and used for real reporting/automation.

## Prerequisites

- At least one enrolled test device with a compliance policy assigned (see [05-compliance-and-conditional-access.md](05-compliance-and-conditional-access.md))
- PowerShell 7+ and the `Microsoft.Graph` module (`Install-Module Microsoft.Graph -Scope CurrentUser`)
- [scripts/graph/README.md](../scripts/graph/README.md) for setup details
- An account with at least the Graph scopes `DeviceManagementManagedDevices.Read.All` and `DeviceManagementConfiguration.Read.All` (Intune Administrator role covers this)

## Steps

1. **Connect to Graph**
   1. Run [scripts/graph/Connect-Lab.ps1](../scripts/graph/Connect-Lab.ps1) and complete the interactive sign-in / consent prompt.
      - `[screenshot: browser consent screen listing the requested scopes]`
   2. Confirm the script prints the connected account and granted scopes.
      - `[terminal output: Connect-MgGraph context]`
2. **Pull the full compliance report**
   1. Run [scripts/graph/Get-DeviceComplianceReport.ps1](../scripts/graph/Get-DeviceComplianceReport.ps1).
   2. Confirm it prints a summary table to the console (device name, OS, compliance state, last sync) and writes a CSV to `scripts/graph/output/`.
      - `[screenshot: console summary table]`
3. **Pull the noncompliant-only report**
   1. Run [scripts/graph/Get-NonCompliantDevices.ps1](../scripts/graph/Get-NonCompliantDevices.ps1).
   2. Confirm it shows the specific failing policy per device (not just "noncompliant").
      - `[screenshot: noncompliant report showing failing policy name]`
4. **Cross-check against the Intune admin center UI**
   1. Compare the script's output against **Devices > Monitor > Device compliance** in the Intune admin center — confirm the numbers match.
      - `[screenshot: Intune UI compliance blade side-by-side with script output]`

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if I request a scope I don't have consent for — does the script fail at connect time or at the API call? What happens if I run the report against zero enrolled devices — does it handle the empty result gracefully?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Real reporting pipelines shouldn't use interactive/delegated auth — they should use an app registration with certificate-based auth and application permissions, scheduled via a runbook/Azure Automation/cron, not a human clicking through a consent prompt each time.
- Least privilege matters: grant only the Graph scopes actually needed for the report (`Read.All`, not `ReadWrite.All`) since these scripts only read data.
- Graph API responses are paginated — production scripts must follow `@odata.nextLink` to get complete results, not just the first page (the scripts in this lab use the SDK's built-in `-All` handling, which does this for you).
- Consider exporting to a proper reporting store (Log Analytics, a database, Power BI) instead of a local CSV once this moves beyond a personal lab.
