---
id: CLAIM-NEAR0002
type: claim
title: "A producer will pay a monthly figure per product line"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
subject: "pricing"
stale_after: "2099-12-31"
rests_on:
  - FACT-DANG0002
---

Violates: near-miss-subject

Step 2 of the resolution order: `pricing` is an alias of `price-anchor`, so it
is resolvable and reported with the canonical key rather than as an error.
