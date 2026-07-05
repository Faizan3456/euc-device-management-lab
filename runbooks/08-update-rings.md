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

- Built two rings — `Lab-Ring-Pilot-IT` (feature/quality deferral **0 days**, deadline 2, grace 1) and `Lab-Ring-Broad` (feature deferral **14 days**, quality **7 days**, deadline 5, grace 2) — and **deliberately assigned both to "All devices"**, so the single test device (`WIN-KH38OBH7`) is targeted by both rings at once. In a real tenant that's a misconfiguration (a device should be in exactly one update ring).
- **Intune accepted the overlapping assignment without any error at creation time** — both rings show "Running" for quality and feature updates in the update-rings list. There's no guard rail stopping you from double-assigning; the safety is entirely on the admin's group design. When two update rings genuinely overlap on a device, the documented result is a **policy conflict** on the conflicting settings (surfaced in the per-device Windows update / settings status), not a clean "last one wins." Observing an actual patch rollout through the rings would need a real pending Windows update and days of elapsed time, which is out of scope for a single session — so the deferral/deadline behaviour here is validated by configuration, and the overlap by Intune's acceptance of it, rather than by watching a live update deploy.

## What I Learned

- **Deferral vs deadline vs grace period** are three different levers and getting them straight is the whole skill here: *deferral* = how many days after Microsoft releases an update before this ring even offers it (pilot = 0, so it gets updates first; broad = 7/14, so it waits until pilot has had a chance to surface problems); *deadline* = how long after an update is offered before it's force-installed regardless of the user snoozing; *grace period* = the minimum time a user is guaranteed even if the deadline had already passed when the device came online.
- The entire reason rings exist is a **phased rollout with a go/no-go gate**: pilot (IT) validates an update, and only if it's clean does it reach the broad population. That only works if a device is in exactly **one** ring — which is why production builds rings on non-overlapping dynamic groups and excludes the pilot group from the broad ring. This lab deliberately violated that (both rings on "All devices") to see that Intune won't stop you.
- Intune does **not** validate ring assignments for overlap or for contradictory deferral/deadline combos at creation time — it silently accepts them. The correctness burden is on group design, and problems show up later as per-device conflicts, not as an upfront error.
- **Pausing a ring ≠ unassigning it:** pausing (Update rings > ring > Pause) temporarily stops offering updates to that ring's devices while keeping the policy and assignment intact, and is reversible with Resume — useful when a bad update is discovered mid-rollout. Unassigning removes the policy relationship entirely. Pause is the "stop the bleeding" button; unassign is a structural change.

## Production Considerations

- Real ring strategies usually have 3-4 rings, not 2: e.g., **Pilot** (IT/early adopters, 0-day deferral) → **Validation/Early adopters** (small % of general users, short deferral) → **Broad/Production** (majority, longer deferral) → sometimes a **Deferred/Executive** ring for VIP or change-sensitive devices with the longest deferral.
- Rings should be built on dynamic groups (e.g., device group tag, department) so device population grows without manual re-assignment.
- Deadlines force installs even if a user keeps snoozing — set them thoughtfully; too aggressive causes complaints, too lax means slow patch compliance and audit findings.
- Monitor the pilot ring's update compliance and any support tickets before letting an update reach the broad ring — that's the whole point of a phased rollout, so build in a real "go/no-go" check, not just a timer.
