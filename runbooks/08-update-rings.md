# Runbook 08 — Windows Update for Business Rings

## Objective

Design and configure Windows Update for Business deployment rings so updates roll out to a small pilot group first, then a broader population, instead of hitting every device on patch day.

## Prerequisites

- Completed [04-windows-autopilot.md](04-windows-autopilot.md) — at least one enrolled Windows test device
- Read [notes/update-rings-design.md](../notes/update-rings-design.md) first — it has the ring strategy and vocabulary (rings, pilot, validation, phased rollout) this runbook assumes

## Steps

1. **Create the Pilot ring**
   1. Go to **Devices > Windows > Windows update for business > Windows 10/11 update rings > Create**.
   2. Name it `Lab-Ring-Pilot-IT`.
   3. Feature updates: deferral **0 days**. Quality updates: deferral **0 days**. Servicing channel: General Availability.
   4. Deadline for feature updates: **2 days**, deadline for quality updates: **2 days**. Grace period: **1 day**.
   5. Enable "Change deadline and grace period" for user experience, but keep auto-restart notifications on.
      - `[screenshot: pilot ring configuration]`
   6. Assign to a small group (e.g., `Lab-Test-Devices`, representing "IT devices" in this lab).
      - `[screenshot: assignment]`
2. **Create the Broad ring**
   1. Create a second ring, `Lab-Ring-Broad`.
   2. Feature updates: deferral **14 days**. Quality updates: deferral **7 days**.
   3. Deadline: **5 days**, grace period: **2 days** (more generous than pilot, since these are everyday users, not IT).
      - `[screenshot: broad ring configuration]`
   4. Assign to a separate group representing the wider fleet (in a real tenant, this would exclude the pilot group so a device isn't in two rings at once).
      - `[screenshot: assignment, showing pilot group excluded]`
3. **Confirm ring assignment doesn't overlap**
   1. Check **Devices > Monitor > Windows updates report** (or the ring's assignment status) and confirm my one test device only picked up the Pilot ring, not both.
      - `[screenshot: update ring report showing correct single-ring assignment]`
4. **(Optional, if time allows) Simulate a bad update scenario**
   1. Temporarily pause updates on the pilot ring (**Update rings > Lab-Ring-Pilot-IT > Pause feature updates**), and note in "What I Broke On Purpose" what pausing actually does versus what unassigning devices does.
      - `[screenshot: paused ring status]`

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if I accidentally put the same device in both rings — which policy wins? What happens if I set deferral higher than deadline (an invalid/contradictory config) — does Intune block it or silently accept it?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Real ring strategies usually have 3-4 rings, not 2: e.g., **Pilot** (IT/early adopters, 0-day deferral) → **Validation/Early adopters** (small % of general users, short deferral) → **Broad/Production** (majority, longer deferral) → sometimes a **Deferred/Executive** ring for VIP or change-sensitive devices with the longest deferral.
- Rings should be built on dynamic groups (e.g., device group tag, department) so device population grows without manual re-assignment.
- Deadlines force installs even if a user keeps snoozing — set them thoughtfully; too aggressive causes complaints, too lax means slow patch compliance and audit findings.
- Monitor the pilot ring's update compliance and any support tickets before letting an update reach the broad ring — that's the whole point of a phased rollout, so build in a real "go/no-go" check, not just a timer.
