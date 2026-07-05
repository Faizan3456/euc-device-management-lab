# Runbook 05 — Compliance Policies & Conditional Access

## Objective

Define what "healthy" means for a device (compliance policy), and enforce that only healthy devices can reach company resources (Conditional Access) — the core Zero Trust device pattern.

## Prerequisites

- Completed [03-macos-ade-enrolment.md](03-macos-ade-enrolment.md) and/or [04-windows-autopilot.md](04-windows-autopilot.md) — at least one enrolled test device
- Entra ID P1 (included in most trial SKUs, but may need manually activating as a trial — see "What I Broke" below) for Conditional Access
- A test user account that is **not** a Global Admin (Conditional Access can't be applied to Global Admins' accounts safely without break-glass exclusions) — created `Lab Test User` for this, licensed with Intune from the M365 admin center (license assignment isn't available directly in the Intune admin center)

## Steps

1. **Create a compliance policy — Windows**
   1. Go to **Devices > Compliance > Policies > Create policy > Windows 10 and later**.
   2. Require: BitLocker enabled, Windows Defender antivirus active, minimum OS version, password/PIN required.
      - `[screenshot: Windows compliance policy settings]`
   3. Set the action for noncompliance: mark noncompliant immediately, send email to end user after 0 days, and (optional) schedule remote actions after grace period.
   4. Assign to `Lab-Test-Devices`.
      - `[screenshot: assignment]`
2. **Create a compliance policy — macOS**
   1. Go to **Devices > Compliance > Policies > Create policy > macOS**.
   2. Require: FileVault enabled, minimum OS version, password required, jailbreak/managed check.
      - `[screenshot: macOS compliance policy settings]`
   3. Assign to `Lab-Test-Devices`.
3. **Confirm compliance status**
   1. On both test devices, check-in with Intune (sync manually from Company Portal or `Settings > Accounts > Access Work or School > Info > Sync`) and confirm compliance status appears in Intune within a few minutes.
      - `[screenshot: Intune - device shows Compliant]`
4. **Create a Conditional Access policy**
   1. In Entra ID > **Protection > Conditional Access > Create new policy**.
   2. Name it `Lab-CA-RequireCompliantDevice`.
   3. Assign to `Lab-Test-Users` group, target cloud app **Office 365** (or a specific app like SharePoint), condition: exclude break-glass account.
   4. Grant control: **Require device to be marked as compliant**.
   5. Set state to **Report-only** first (safe default — never go straight to Enforced in a real tenant).
      - `[screenshot: CA policy in report-only mode]`
5. **Test in report-only, then enforce**
   1. Sign in as the test user from the enrolled test device, check the CA sign-in log shows the policy would have applied and the result (report-only doesn't block, just logs).
      - `[screenshot: Entra ID sign-in logs, Conditional Access report-only result]`
   2. Once confident, flip the policy to **On** (enforced).
   3. Test from the compliant enrolled device (should succeed) and from an unmanaged device/browser (should be blocked), confirming the block screen references compliance.
      - `[screenshot: block screen on unmanaged device]`

## What I Broke On Purpose

Before I could even get to compliance policies, I needed an actually-enrolled test device — and discovered the tenant had no dedicated non-admin test user at all (runbook 01 planned one but it was never created), and the Windows VM had never completed real enrollment (Autopilot never applied — see [04-windows-autopilot.md](04-windows-autopilot.md)). Manually enrolling a device via **Settings > Access work or school > Join this device to Microsoft Entra ID** turned into its own multi-layer troubleshooting chain:

- Joined the device to Entra ID successfully (`dsregcmd /status` showed `AzureAdJoined: YES`), but it never showed up in Intune's **Devices > All devices**. Checked `dsregcmd /status` and found `MdmUrl:` blank under Tenant Details — the device had no MDM configuration at all, despite being Entra-joined.
- Traced this to **Entra ID > Mobility (MDM and WIP) > Microsoft Intune > MDM user scope** being set to **None** — the tenant had never been configured to auto-enrol any user's devices into Intune, regardless of Entra join status. Changing it to "All" didn't retroactively fix the already-joined device, because `MdmUrl` and related tenant config are only fetched fresh **at join time**, not on every logon/restart. Had to fully disconnect and rejoin the work account to pick up the corrected config — confirmed by `MdmUrl` becoming populated on the next `dsregcmd /status`.
- Even with `MdmUrl` populated, the device still didn't enrol — checked **Task Scheduler > Microsoft > Windows > EnterpriseMgmt** and found it completely empty (no GUID subfolder at all), meaning the client-side auto-enrollment task had never been created. This needed a separate local policy: **Computer Configuration > Administrative Templates > Windows Components > MDM > "Enable automatic MDM enrollment using default Azure AD credentials"**, set via `gpedit.msc`.
- Trying to save that policy failed repeatedly with **"Access is denied"**, even running `gpedit.msc` explicitly as Administrator. Ran `net localgroup administrators` and discovered the work account (`AzureAD\LabTestUser`) was **not actually a member of the local Administrators group**, despite Windows Settings visually labeling it "Administrator" in the accounts list — that label reflects Entra role assumptions, not actual local group membership. `net localgroup administrators "AzureAD\LabTestUser" /add` itself also failed with Access Denied (same underlying issue, chicken-and-egg). Fixed by signing into the separate local admin account and using **Settings > Accounts > Other Users > [account] > Change account type > Administrator** instead — a GUI action that doesn't require the same elevated token the command-line approach needed.
- After that, the Group Policy setting saved successfully, `gpupdate /force` still printed a warning ("Windows failed to apply the MDM Policy settings") but the enrollment task infrastructure was created regardless (a new GUID folder appeared under EnterpriseMgmt with several tasks). Manually running the **"Login Schedule created by enrollment client..."** task triggered real enrollment — the device appeared in Intune within a minute, already showing **Compliant** by default (no compliance policy exists yet, so it has nothing to fail).

## What I Learned

- "Entra-joined" and "Intune-managed" are two separate states — a device can successfully join Entra ID and still never enrol in Intune if the tenant's **MDM user scope** is set to None. This is a real, easy-to-miss tenant configuration step that has nothing to do with licensing (the license can be active and assigned, and enrollment will still silently not happen).
- Tenant-level MDM configuration is fetched by the client **at join time**, not continuously — changing the MDM user scope after a device has already joined doesn't retroactively apply to it. The device needs a fresh join (disconnect + rejoin) to pick up the new config, confirmed via `dsregcmd /status`'s `MdmUrl` field going from blank to populated.
- Being Entra-joined doesn't automatically create the local scheduled task that actually triggers MDM enrollment — that depends on the **"Enable automatic MDM enrollment using default Azure AD credentials"** Group Policy (or equivalent MDM/Policy CSP), which isn't guaranteed to be pre-configured just because a tenant has Intune licensing.
- Windows Settings' account list can **mislabel** an Entra work account as "Administrator" when it is not actually a member of the local Administrators security group — `net localgroup administrators` is the actual source of truth, not the Settings UI. This caused every attempt to save a Group Policy change to fail with a generic "Access is denied," which is a confusing error if you trust the Settings label at face value.
- When an account lacks true local admin rights, you can't always fix that from the command line as that same account (`net localgroup ... /add` needs the elevation it's missing) — switching to a genuinely separate local admin account and using the Settings GUI's "Change account type" control sidesteps the chicken-and-egg problem entirely.
- `dsregcmd /status` is the single most useful diagnostic command for this entire chain — `AzureAdJoined`, `MdmUrl`, and `AzureAdPrt` fields told us more, faster, than clicking through the Intune/Entra admin UIs guessing at what might be wrong.

## Production Considerations

- Always deploy new Conditional Access policies in **Report-only** mode first, review sign-in logs for a representative period (days, not minutes), then enforce.
- Always exclude at least one break-glass admin account from every Conditional Access policy, and monitor sign-ins to that account for anomalies.
- Compliance grace periods matter: too short and users get locked out over transient checks (VPN not connected yet); too long and noncompliant devices linger with access.
- Conditional Access + compliance is session-based re-evaluation, not instant revocation — token lifetime and Continuous Access Evaluation (CAE) affect how fast a noncompliant device actually loses access.
