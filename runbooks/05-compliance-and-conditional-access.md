# Runbook 05 — Compliance Policies & Conditional Access

## Objective

Define what "healthy" means for a device (compliance policy), and enforce that only healthy devices can reach company resources (Conditional Access) — the core Zero Trust device pattern.

## Prerequisites

- Completed [03-macos-ade-enrolment.md](03-macos-ade-enrolment.md) and/or [04-windows-autopilot.md](04-windows-autopilot.md) — at least one enrolled test device
- Entra ID P1 (included in most trial SKUs) for Conditional Access
- A test user account that is **not** a Global Admin (Conditional Access can't be applied to Global Admins' accounts safely without break-glass exclusions)

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

_Fill in after doing the work. Example prompts: What happens if I enforce CA before excluding the break-glass account — did I lock myself out of anything? What happens if a device falls out of compliance (e.g., disable BitLocker) while signed in — does an active session get cut immediately or only on next token refresh?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Always deploy new Conditional Access policies in **Report-only** mode first, review sign-in logs for a representative period (days, not minutes), then enforce.
- Always exclude at least one break-glass admin account from every Conditional Access policy, and monitor sign-ins to that account for anomalies.
- Compliance grace periods matter: too short and users get locked out over transient checks (VPN not connected yet); too long and noncompliant devices linger with access.
- Conditional Access + compliance is session-based re-evaluation, not instant revocation — token lifetime and Continuous Access Evaluation (CAE) affect how fast a noncompliant device actually loses access.
