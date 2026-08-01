---
id: CLAIM-NC1CC003
type: claim
title: "The stated outlet count does not clear by the stated date"
status: current
confidence: M
confidence_own: M
created: "2026-07-20"
subject: "target-verdict"
stale_after: "2099-12-31"
binding_driver: "reach"
driver_kind: structural
evidence_n: "1"
evidence_counterparties: "1"
rests_on:
  - FACT-NC1BB002
used_in:
  - "business-plan.md#target-verdict"
---

`driver_kind` is `structural`, so this verdict owes no stated condition and the
condition check has nothing to look for. Every other rule in the mode clears too,
which leaves the success line as the only thing this vault says — and the line has
to distinguish a `Kind` column that agreed from one that was never read.
