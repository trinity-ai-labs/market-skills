---
id: CLAIM-TR58WQ03
type: claim
title: "The compliance segment grows with the re-labelling deadline and flattens after it"
status: superseded
confidence: M
confidence_own: M
created: "2026-03-15"
subject: "market-growth"
stale_after: "2099-12-31"
rests_on:
  - FACT-QP81ZZ07
used_in:
  - "business-plan.md#why-now"
---

The superseded half of a complete, well-formed supersession: `status` is
`superseded`, `CLAIM-HV21ND76` names this note in `supersedes` and carries the
reason, and `used_in` names a section of `business-plan.md` that exists. Both
edits were made, so `check` reports nothing about the pair - and that is the
whole point of the note. `--supersession-sweep` still emits one row for
`business-plan.md#why-now`, because a supersession the checker is happy with is
exactly the one nothing else in the corpus tells the document about.
