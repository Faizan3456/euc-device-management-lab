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

_Fill in after doing the work. Example prompts to answer: Did I assign a license to the wrong account and see what happens to enrolment? Did I try enrolling a device before any license was assigned, to see the error?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Real tenants should never use only one Global Admin account — always have at least 2 break-glass accounts stored securely (per Microsoft's recommendation), excluded from Conditional Access.
- Role-based access control (RBAC) matters: production EUC teams use scoped Intune roles (Helpdesk, App Manager, Policy and Profile Manager), not blanket admin rights.
- Licensing should be automated with dynamic group assignment in production, not manually assigned one by one.
- Trial tenants expire — plan for tenant renewal or migration if this lab needs to run longer than 30/90 days.
