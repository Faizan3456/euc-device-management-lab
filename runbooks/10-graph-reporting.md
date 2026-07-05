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

- `Connect-Lab.ps1` worked first try — interactive browser sign-in as the Intune admin, and the consent granted exactly the two read-only scopes requested (`DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`) plus the base `openid`/`profile`/`email`. Confirmed via `Get-MgContext` that no write scopes were granted — least-privilege consent working as intended.
- `Get-DeviceComplianceReport.ps1` failed with a real Graph error: **`400 (BadRequest): Could not find a property named 'ownerType' on type 'microsoft.graph.managedDevice'`**. The script's `-Property` (OData `$select`) list requested `ownerType`, but the actual property on the `managedDevice` entity is **`managedDeviceOwnerType`**. Because a bad property name 400s the *entire* request, no devices came back — and the script's `if (-not $devices)` guard then misreported it as **"No managed devices found in this tenant"**, which is dangerously misleading: it looked like an empty tenant when it was really a malformed query. Fixed the property name (and the value mapping to `$_.ManagedDeviceOwnerType`), re-ran, and got the real device back.
- `Get-NonCompliantDevices.ps1` returned **"No noncompliant devices found. Fleet is clean."** — and that is the *correct* answer, because the one enrolled device (`WIN-KH38OBH7`) is Compliant. This is a genuine zero result from a valid query, which sits in useful contrast to the error-masquerading-as-zero above.

## What I Learned

- Graph's OData `$select` uses the **exact entity property names**, which don't always match intuition or the friendlier SDK output names — it's `managedDeviceOwnerType`, not `ownerType`. A wrong property name is a hard 400 that fails the whole request, not a silently-ignored field.
- A failed query can **masquerade as an empty result** when a script swallows the error and only checks "did I get any rows." Always distinguish *"the query errored"* from *"the query legitimately returned zero"* — here the noncompliant script's true zero (device is compliant) vs the compliance script's error-that-looked-like-zero was a perfect side-by-side of the two.
- Least-privilege consent is real and verifiable: requesting only `Read.All` scopes granted exactly those, no write access, confirmed in `Get-MgContext.Scopes`. This is the interview-safe answer to "how would you pull Intune data without over-permissioning."
- Pulling compliance data via Graph gives the **same ground truth** as *Devices > Monitor > Device compliance* in the portal (cross-checked: 1 compliant device both ways), but scriptable, filterable, and exportable to CSV — which is the entire reason real reporting/automation uses Graph instead of the UI.
- The SDK's `-All` switch follows `@odata.nextLink` automatically, so the query returns the complete device list rather than just the first page — the pagination bug that bites hand-rolled REST calls is handled for you.
- Interactive/delegated auth (a human clicking a browser consent) is fine for a lab or ad-hoc report, but a real scheduled pipeline should use an app registration with certificate-based auth + application permissions — no human in the loop.

An example of the exported report (sanitized) is committed at [scripts/graph/sample-output.csv](../scripts/graph/sample-output.csv).

## Production Considerations

- Real reporting pipelines shouldn't use interactive/delegated auth — they should use an app registration with certificate-based auth and application permissions, scheduled via a runbook/Azure Automation/cron, not a human clicking through a consent prompt each time.
- Least privilege matters: grant only the Graph scopes actually needed for the report (`Read.All`, not `ReadWrite.All`) since these scripts only read data.
- Graph API responses are paginated — production scripts must follow `@odata.nextLink` to get complete results, not just the first page (the scripts in this lab use the SDK's built-in `-All` handling, which does this for you).
- Consider exporting to a proper reporting store (Log Analytics, a database, Power BI) instead of a local CSV once this moves beyond a personal lab.
