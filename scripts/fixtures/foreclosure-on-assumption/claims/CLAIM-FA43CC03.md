---
id: CLAIM-FA43CC03
type: claim
title: "The behavioural cut is the population the channel work was sized against"
status: current
confidence: M
confidence_own: M
created: "2026-08-01"
subject: "market-size"
stale_after: "2099-12-31"
rests_on:
  - SOURCE-PN01AA11
---

The note the assumption beside it points at. It exists so the failure under
test is the FIELD ON THE WRONG TYPE and not a dangling `foreclosed_on` - two
different rules, and a fixture that tripped both would not say which one fired.
