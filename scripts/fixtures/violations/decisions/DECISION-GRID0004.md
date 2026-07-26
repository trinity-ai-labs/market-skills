---
id: DECISION-GRID0004
type: decision
title: "Price the tool at the floor a producer will accept"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
options:
  - "Price at the accepted floor"
  - "Price above the floor and discount on volume"
chosen: "Price at the accepted floor"
criteria:
  - "revenue arrives before the deadline passes"
  - "no producer feels they overpaid once they compare notes"
criteria_ranked_by: founder
likelihood: likely
likelihood_range: "55-80%"
reasoning: |
  The floor is the only figure the corpus supports, and pricing above it rests
  on a volume assumption nothing has tested.
reopen_if: |
  A producer accepts a quote above the floor without a volume commitment.
rests_on:
  - CLAIM-NEAR0002
---

Violates: decision-brief-incomplete

Half an option grid. The ranked criteria and the likelihood are recorded and
`option_evidence`, `do_nothing`, `evidence_grade` and `founder_reasoning` are
not, so the note reads as a brief-backed record while the columns it claims to
compare have nothing attached to them. Four failures, one per missing field.
