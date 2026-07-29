---
id: CLAIM-CR1DD004
type: claim
title: "The cadence the plan bills on is monthly"
status: current
confidence: M
confidence_own: M
created: "2026-07-28"
subject: "pricing"
stale_after: "2099-12-31"
rests_on:
  - FACT-CR1BB002
---

Violates: near-miss-subject

`pricing` is declared as an alias of `price-anchor` in the vocabulary, so
resolving it needs the alias records the vocabulary pass emits. Drop the
vocabulary on a carriage return and there are no alias records, this claim
resolves against nothing, and it reports as clean rather than as unreadable.
