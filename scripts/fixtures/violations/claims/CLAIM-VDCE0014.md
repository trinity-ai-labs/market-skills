---
id: CLAIM-VDCE0014
type: claim
title: "The configuration tops out near two hundred accounts"
status: current
confidence: M
confidence_own: M
created: "2026-07-20"
subject: "steady-state-ceiling"
stale_after: "2099-12-31"
binding_driver: "trial flow"
rests_on:
  - FACT-DANG0002
---

Violates: verdict-fields-incomplete, verdict-thin-evidence

The ceiling half of the trigger: `steady-state-ceiling` predates the verdict
fields, so a claim carrying none of them owes none — and this one carries
`binding_driver`, which makes `driver_kind`, `evidence_n` and
`evidence_counterparties` owed. `conditional_on` is not owed here, because
`driver_kind` is absent and nothing says the driver is policy; a rule demanding a
condition of every ceiling would be met by inventing one.

It names the driver its counts were taken under and then states no counts, which
is the second failure: the closure under it reaches one source note from one
counterparty, and nothing in the note or in a rendered section says so.
