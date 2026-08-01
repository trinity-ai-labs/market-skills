---
id: CLAIM-CB11AA01
type: claim
title: "Trial-to-paid conversion holds inside the observed band"
status: current
confidence: M
confidence_own: M
subject: "conversion-rate"
created: "2026-07-20"
stale_after: "2027-07-20"
rests_on:
  - SOURCE-CB55EE05
used_in:
  - "financial-model.md#assumptions"
reconciled_sections:
  - "financial-model.md#assumptions 6cd27ac1"
---

A ROW BACKED BY A CLAIM AND BY NOTHING ELSE — no `assumption` in this vault
carries the title. Before the fix the row→note direction indexed `assumption`
titles only, so this row matched nothing at all and was reported as
`model-row-no-assumption`: a row written by hand with nothing in the ledger
behind it, said of a sourced figure whose `used_in` names the assumptions
section directly. A-3 next door is the other half of the same defect.
