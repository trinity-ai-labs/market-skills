---
id: CLAIM-BD2DD004
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
  - FACT-BD2BB002
used_in:
  - "business-plan.md#target-verdict"
---

The silent side, and what gives the failure count teeth: its corner row carries
`policy` and so does this note, so a check that reported every row would fire
twice here and still pass a census that only looks for the check name.
