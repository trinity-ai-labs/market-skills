---
id: ASSUMPTION-MR22BB02
type: assumption
title: "Metered overage is billed on the same invoice as the seats"
status: unverified
confidence: L
created: "2026-07-20"
value: "one invoice per account per month, both lines on it"
sensitivity: high
model_input: revenue
validated_by:
  - QUESTION-MR11QQ01
---

The failing side. It carries `model_input` and no row in the assumptions table
carries its title, and it states no `excluded_from_model` reason — so the input
sits in the ledger, cannot enter the projection, and nothing records a decision
about it. Adding either the row or the reason clears it, which is what the two
scratch copies in run-fixtures.sh assert.
