# Update Rings — Design Notes

## The core idea

Never push a Windows update to 100% of devices on day one. Roll it out in
**rings** — small, low-risk groups first, then progressively wider groups — so a
bad update is caught by a handful of IT devices instead of the whole company.
This is the same "phased rollout" pattern used in software release engineering,
just applied to OS patching.

## Vocabulary

- **Ring** — a group of devices assigned the same Windows Update for Business
  deployment settings (deferral, deadline, grace period). Devices should belong
  to exactly one ring at a time.
- **Pilot** — the first, smallest ring. Usually IT staff and volunteer early
  adopters. Gets updates with little or no deferral, so problems surface here first.
- **Validation** — an optional middle ring: a slightly larger, still-low-risk
  group (e.g. one department, or a "friendly users" group) that gets the update
  after pilot has looked clean for a few days, before going broad.
- **Broad / Production rollout** — the majority of the fleet. Gets updates last,
  with a longer deferral, so pilot + validation had time to catch problems first.
- **Deferral** — how many days after Microsoft releases an update before a ring
  is even offered it. A 0-day deferral ring gets it immediately; a 14-day
  deferral ring won't see it until two weeks later.
- **Deadline** — how many days a device has, after an update is offered, before
  Windows forces the install/restart regardless of what the user wants.
- **Grace period** — extra time added on top of the deadline the first time a
  device notices it's overdue, so someone doesn't get force-restarted the instant
  they open their laptop after being on holiday.

## This lab's ring strategy

| Ring | Deferral (feature) | Deferral (quality) | Deadline | Grace period | Who's in it |
|---|---|---|---|---|---|
| Pilot | 0 days | 0 days | 2 days | 1 day | IT devices / early adopters |
| Broad | 14 days | 7 days | 5 days | 2 days | Everyone else |

Real-world designs often add a third **Validation** ring between these two once
the fleet is large enough to justify it — see the "Production Considerations"
note below.

## Why these specific numbers

- **Pilot gets 0-day deferral** because the whole point of a pilot ring is to be
  the canary — if there's a bad update, IT should find out from its own machines
  before end users do.
- **Pilot's deadline (2 days) is short** because IT devices are expected to
  install fast and report problems fast; a long deadline here defeats the purpose
  of having a pilot ring at all.
- **Broad's deferral (14 days feature / 7 days quality) gives the pilot ring time
  to surface issues** — feature updates are riskier (bigger changes) so they get
  a longer deferral than routine quality/security updates, which still need to
  land reasonably fast for security reasons.
- **Broad's deadline (5 days) and grace period (2 days) are more generous** than
  pilot's, because these are everyday users who shouldn't be force-restarted
  mid-task without some warning and flexibility.

## Production considerations

- Larger organizations typically run 3-4 rings, not 2: **Pilot → Validation →
  Broad → (sometimes) a slow/VIP ring** for change-sensitive devices (executives,
  point-of-sale, kiosks) that need the longest deferral and the most cautious deadlines.
- Ring membership should be driven by dynamic groups (device group tag,
  department, "opted into pilot" attribute) so the population grows automatically
  rather than needing manual re-assignment every time a new device is provisioned.
- A ring strategy is only useful if someone actually **checks** the pilot ring's
  health (update compliance %, support ticket volume, crash reports) before the
  update reaches Broad — a ring with no monitoring is just a delay, not a safety net.
- Deadlines that are too aggressive generate complaints and lost work (forced
  restarts mid-task); deadlines that are too lax mean slow patch compliance and
  potential audit/security findings. Both need periodic review, not "set and forget."
- Communicate deadlines to end users (via Company Portal notifications or a
  companion comms email) — a forced restart that arrives with zero warning is one
  of the most common sources of helpdesk complaints in real environments.
