---
id: CLAIM-UR1CC003
type: claim
title: "The category compounds through the deadline year"
status: superseded
confidence: M
confidence_own: M
created: "2026-07-01"
subject: "market-growth"
stale_after: "2099-12-31"
rests_on:
  - FACT-UR1BB002
used_in:
  - "business-plan.md#why-now"
---

The superseded half of a complete, well-formed pair: `status` is `superseded`,
`CLAIM-UR1DD004` names it in `supersedes` and carries the reason, and `used_in`
names a section that exists. `check` is silent on it and `--used-in` resolves
it, which is exactly why the sweep is the only thing that can catch what is
wrong here.
