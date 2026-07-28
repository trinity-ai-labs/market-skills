---
id: CLAIM-RR55TT19
type: claim
title: "Producers treat the deadline as a \"nice to have\" until a peer is fined"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
subject: "primary-risk"
stale_after: "2099-12-31"
rests_on:
  - FACT-GF45SD01
used_in:
  - "business-plan.md#risks"
  - "business-plan.md#competition"
  - "business-plan.md#business-model"
  - "business-plan.md#business-model--pricing"
---

The embedded quotes in the title are escaped inside a double-quoted scalar, and
the parser returns the passage with them intact. Carried at Low confidence and
cited in a rendered document, which is exactly the pair `--unverified` reports.

The last three entries are the explicit-anchor contract, carried on one note so
the corpus stays small. `#competition` and `#business-model` are explicit
`{#anchor}` attributes; `#business-model--pricing` is the slug of that same
heading's text with the attribute stripped, which is what a vault written before
the template carried attributes cites. All three resolve, because a heading
registers both addresses.
