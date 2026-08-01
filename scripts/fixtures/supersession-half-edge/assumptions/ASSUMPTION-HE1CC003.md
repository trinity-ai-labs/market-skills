---
id: ASSUMPTION-HE1CC003
type: assumption
title: "Support load per account stays flat after onboarding"
status: superseded
confidence: L
created: "2026-07-01"
value: "20 minutes per account per month"
sensitivity: medium
superseded_by: CLAIM-HE1DD004
used_in:
  - "business-plan.md#pricing"
---

Violates: superseded-by-unreciprocated

The bug this fixture exists for. This note records its own replacement and
`CLAIM-HE1DD004` never wrote the matching `supersedes`, so the sweep — which
walks the superseding side, where the reason and the `reconciled:` date live —
reached nothing and printed this as replaced by NOTHING AT ALL. The record names
a successor; only the other end of the edge is missing, and that is one line on
a named note rather than a decision about what replaced this.
