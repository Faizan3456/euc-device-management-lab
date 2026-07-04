# Notes: What to Check in Apple Business Manager

There isn't a command-line equivalent for inspecting Apple Business Manager (ABM) the
way `profiles status` works on a Mac — ABM is entirely a web console
(business.apple.com). This file is a checklist of exactly what to look at there,
so ABM verification is a deliberate step, not an afterthought.

## When linking ABM to Intune (see [runbooks/02-abm-intune-link.md](../../runbooks/02-abm-intune-link.md))

- **Settings > MDM Server Assignment**
  - Confirm the MDM server entry (e.g. `Intune-Lab-MDM`) exists and shows a recent
    "Renewal Date" — this is the ABM server token, and it expires yearly.
  - Confirm the public key uploaded matches the one downloaded from Intune's
    Automated Device Enrolment page (mismatched keys is a common first-time mistake).

- **Devices**
  - Search for the test device by serial number.
  - Confirm the device's "Assigned Server" column shows the correct MDM server
    (`Intune-Lab-MDM`), not blank and not a different/old server from a previous lab.
  - If a device shows "Assigned Server: None," it will NOT get zero-touch enrolment —
    it has to be assigned before it can be wiped/enrolled via ADE.

## Ongoing health checks worth doing periodically

- **Settings > MDM Server Assignment > Renewal Date** — set a reminder well before
  this expires; an expired token silently breaks new-device sync into Intune.
- **Accounts > (the Apple ID used for the MDM push certificate, tracked separately
  in Intune, not ABM)** — ABM itself doesn't hold the push cert, but it's worth
  cross-referencing here that the same admin who manages ABM also has access to
  whichever Apple ID owns the push certificate, so one person leaving doesn't
  strand both systems.
- **Devices > filter by "Assigned Server"** — periodically confirm no devices have
  drifted to "Unassigned" (can happen if a device is removed from one MDM server
  assignment during a migration and never re-assigned).

## What to screenshot for the runbook

- MDM server list showing renewal date
- A device's detail page showing assigned server + serial number
- The token upload confirmation screen in Intune, so the ABM-side and Intune-side
  screenshots can be compared side by side
