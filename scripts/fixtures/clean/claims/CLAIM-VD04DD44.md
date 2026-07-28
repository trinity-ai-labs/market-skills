---
id: CLAIM-VD04DD44
type: claim
title: "The stated outlet target does not clear by the stated date at the reach the named channels support"
status: current
confidence: M
confidence_own: H
created: "2026-03-18"
subject: "target-verdict"
stale_after: "2099-12-31"
binding_driver: "reach"
driver_kind: policy
conditional_on: "six hours a week across two channels"
evidence_n: "3"
evidence_counterparties: "3"
rests_on:
  - FACT-VD03CC33
  - FACT-GF45SD01
used_in:
  - "business-plan.md#target-verdict"
---

The verdict note in its complete shape, and the one the clean vault is required
to report nothing about. All four fields a verdict owes outright are here, and
`conditional_on` is here because `driver_kind` is `policy` — a `structural`
verdict would owe none, which is the negative case the fixture beside this one
carries.

`conditional_on` is matched verbatim against the section `used_in` names, so the
string here and the string in `business-plan.md#target-verdict` are the same
bytes. The corner table in that section carries `reach` in its `Binding driver`
column and `policy` in its `Kind` column, which is the other verbatim match.

The closure under this note reaches three source notes through two facts, and
three counterparties among them: two write their `counterparty` outright and the
third falls back to `publisher`. Three and three is what the two counts state,
so nothing about the tail is thin and nothing has to be surfaced.
