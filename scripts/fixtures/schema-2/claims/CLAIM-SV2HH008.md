---
id: CLAIM-SV2HH008
type: claim
title: "The buying window closes at the deadline"
status: superseded
confidence: M
confidence_own: M
created: "2026-07-01"
subject: "timing-window"
stale_after: "2099-12-31"
rests_on:
  - FACT-SV2BB002
used_in:
  - "business-plan.md#why-now"
---

The superseded half of a pair that was closed out properly. It is here so this
vault asserts the other side of the sweep verdict: a schemaVersion 2 corpus with
a live supersession in it still prints a worklist, still prints its count, and
still exits 0. A verdict that only ever fires is one nothing distinguishes from
a mode that always fails.
