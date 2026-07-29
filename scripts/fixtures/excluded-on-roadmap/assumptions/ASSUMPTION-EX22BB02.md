---
id: ASSUMPTION-EX22BB02
type: assumption
title: "Metered overage bills at a per-unit rate above the seat price"
status: unverified
confidence: L
created: "2026-07-20"
value: "one unit rate per account per month, above the seat line"
sensitivity: high
model_input: revenue
excluded_from_model: "a metered layer and a subscription layer have different churn, and mixing them lets usage revenue flatter seat retention"
validated_by:
  - QUESTION-EX11QQ01
---

The failing side. The exclusion is a real modelling decision and correctly
authored — what is missing is the other half of it: no verdict note names this
note in `arr_excludes`, so the identity the verdict solves never says the ARR term
leaves this line out. The scratch copy in run-fixtures.sh adds that declaration
and clears the failure.
