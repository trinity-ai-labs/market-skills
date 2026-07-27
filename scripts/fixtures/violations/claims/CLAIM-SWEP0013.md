---
id: CLAIM-SWEP0013
type: claim
title: "The buying window runs to the quarter after the deadline"
status: current
confidence: M
confidence_own: M
created: "2026-03-18"
subject: "timing-window"
stale_after: "2099-12-31"
supersedes:
  - CLAIM-STAL0006
  - CLAIM-UNKN0001
supersedes_reason: "The window was measured from the wrong end; both notes were filed against the superseded reading."
rests_on:
  - FACT-DANG0002
---

Violates: supersedes-status

Neither superseded note had its `status` flipped, so `supersedes-status` fires
once per target. Everything else here is correct on purpose, including
`supersedes_reason`, so the two halves of the two-edit rule are tested apart:
`DECISION-SUPS0002` is the missing-reason half and this is the missing-status
half.

It is also what gives `--supersession-sweep` its deduplication case.
`CLAIM-STAL0006` names `business-plan.md#why-now` in `used_in` and so does
`DECISION-BLOK0001`, so two superseded notes reach one section - and the sweep
owes exactly one row naming both. A row per note would make one re-read look
like two, and a worklist that overstates its own size is one that gets skipped.
`CLAIM-UNKN0001` has no `used_in` at all, which is the other case: it reached no
document, and the sweep lists it as such rather than dropping it, because a
dropped note and a note the sweep failed to read look identical from outside.
