---
id: CLAIM-SS1DD004
type: claim
title: "The stated outlet count does not clear at the price point named"
status: current
confidence: M
confidence_own: M
created: "2026-07-20"
subject: "target-verdict"
stale_after: "2099-12-31"
binding_driver: "price"
driver_kind: policy
conditional_on: "the price point you named"
evidence_n: "1"
evidence_counterparties: "1"
rests_on:
  - FACT-SS1BB002
used_in:
  - "business-plan.md#target-verdict"
---

The one failure this vault is built for, and it can only fire if the corner table
inside the subsection was read: the row naming `price` carries `structural` in its
`Kind` cell while this note carries `policy`. A mode that reads zero rows reports
nothing here and passes, which is exactly what the old boundary did.
