---
id: CLAIM-NULL0008
type: claim
title: "Enforcement lands first on the largest producers"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
subject: "primary-risk"
stale_after: "2099-12-31"
rests_on:
  - FACT-DANG0002
scopes:
---

Violates: null-value

`scopes:` is present holding nothing, which is not the same as an absent key - a
consumer expecting a list gets a type it did not plan for.
