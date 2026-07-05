# Runbook 01 — Tenant Setup

## Objective

Stand up a Microsoft 365 tenant with Intune licensing, so I have a real environment to practice device management in — not just theory.

## Prerequisites

- A personal or work email not already tied to a Microsoft 365 tenant
- Access to sign up for a Microsoft 365 E5 (or Business Premium) trial, which includes Intune
- A phone number for MFA setup
- Understanding of the difference between **Entra ID (Azure AD)**, **Microsoft 365**, and **Intune** — Entra ID is the identity layer, Intune is the MDM/MAM layer, Microsoft 365 is the license bundle that includes both

## Steps

1. Go to the Microsoft 365 admin center and sign up for an E5 or Business Premium trial tenant.
2. Set the initial Global Admin account password and enable MFA on it.
   - `[screenshot: initial tenant creation screen]`
3. Create a second admin account (break-glass / test account) so I don't lock myself out.
4. Assign an Intune-included license (E5 or Business Premium) to my test admin account and to at least one "test user" account I'll use for enrolment testing.
   - `[screenshot: license assignment in M365 admin center]`
5. In the Intune admin center (intune.microsoft.com), confirm the tenant shows up and licensing is recognized under **Tenant administration > Licenses**.
   - `[screenshot: Intune tenant admin - licenses page]`
6. Create an Entra ID security group called `Lab-Test-Devices` and a group called `Lab-Test-Users` — I'll use these throughout the lab to scope policies instead of "All devices"/"All users", which is closer to how a real production tenant is run.
   - `[screenshot: Entra ID groups created]`
7. Assign an **Intune Administrator** role (not Global Admin) to my day-to-day working account, to practice least-privilege the way a real EUC engineer would work.
   - `[screenshot: role assignment]`

## What I Broke On Purpose

The tenant was stood up and is fully functional, but several setup-time decisions were left at their defaults and only revealed themselves as problems much later, in other runbooks — which is itself the lesson: a tenant can look "done" and still be quietly misconfigured in ways that block work downstream.

- **No dedicated non-admin test user existed** — only the Global Admin account. This wasn't noticed until [05-compliance-and-conditional-access.md](05-compliance-and-conditional-access.md), where a test user was needed (you can't safely test Conditional Access against a Global Admin). Had to create `Lab Test User` then.
- **Security Defaults was left enabled.** This silently blocks custom Conditional Access policies — Entra refuses to enable a CA policy while Security Defaults is on. Only surfaced when the first CA policy was created in runbook 05, where Security Defaults had to be turned off.
- **The MDM user scope was left at "None"** (Entra ID > Mobility > Microsoft Intune). This meant Entra-joined devices never auto-enrolled into Intune, which cost significant troubleshooting time in runbook 05 before it was traced back to this tenant-setup default.

## What I Learned

- Assigning **Intune-included licenses to users cannot be done from the Intune admin center's own Users blade** — it must be done in the Microsoft 365 admin center (Users > Active users > Licenses and apps). The Intune Users blade shows licenses read-only and links out to M365 for changes.
- Several tenant **defaults will silently block later work** rather than erroring at setup time: Security Defaults being on blocks Conditional Access, and MDM user scope being None blocks auto-enrolment. Worth deliberately setting these during initial tenant setup instead of discovering them mid-troubleshooting weeks later.
- Least-privilege is worth practising from the start: a scoped **Intune Administrator** role for day-to-day work rather than Global Admin, at least one break-glass Global Admin held aside, and security groups (`Lab-Test-Devices`, `Lab-Test-Users`) to scope policies to instead of "All users/All devices" — all mirror how a real production tenant is run.
- Licensing must exist **before** enrolment: an unlicensed user can Entra-join a device but it won't successfully enrol/manage, and the failure isn't an obvious licensing message.

## Production Considerations

- Real tenants should never use only one Global Admin account — always have at least 2 break-glass accounts stored securely (per Microsoft's recommendation), excluded from Conditional Access.
- Role-based access control (RBAC) matters: production EUC teams use scoped Intune roles (Helpdesk, App Manager, Policy and Profile Manager), not blanket admin rights.
- Licensing should be automated with dynamic group assignment in production, not manually assigned one by one.
- Trial tenants expire — plan for tenant renewal or migration if this lab needs to run longer than 30/90 days.
