---
id: CLAIM-SV2JJ009
type: claim
title: "The buying window stays open for a year past the deadline"
status: current
confidence: M
confidence_own: M
created: "2026-07-10"
subject: "timing-window"
stale_after: "2099-12-31"
reconciled: "2026-07-10"
supersedes:
  - CLAIM-SV2HH008
supersedes_reason: "Producers that miss the deadline still have to re-label, so the demand moves rather than disappearing."
rests_on:
  - FACT-SV2BB002
---

`reconciled` is the same day as `created`, which passes: the rule is that the
read cannot predate the supersession, not that it has to happen later. Same-day
is the normal case — the reconciliation is what closes out the supersession, and
a rule demanding a later date would fail every one done in a single sitting.
