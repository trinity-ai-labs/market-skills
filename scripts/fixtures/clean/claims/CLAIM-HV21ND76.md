---
id: CLAIM-HV21ND76
type: claim
title: "The compliance segment keeps growing for a year after the deadline before it flattens"
status: current
confidence: M
confidence_own: M
created: "2026-03-18"
subject: "market-growth"
stale_after: "2099-12-31"
supersedes:
  - CLAIM-TR58WQ03
supersedes_reason: "The readiness survey put the bulk of re-labelling after the deadline rather than before it, so the flattening point moves out by a year."
rests_on:
  - FACT-QP81ZZ07
---

The replacing half of the pair. It carries `supersedes` and `supersedes_reason`
together - the reason is required with the edge, because the only question
anyone ever asks about a superseded note is why, and by the time it is asked the
person who knew has gone. Its confidence is `min(confidence_own, FACT-QP81ZZ07)`
like every other note in this vault, so nothing about the pair trips a check.
