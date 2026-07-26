---
id: DECISION-HALF0003
type: decision
title: "Sell direct to producers before building the distributor channel"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
options:
  - "Direct to producers"
  - "Through the two national distributors"
  - "Keep taking whichever orders arrive"
do_nothing: "Keep taking whichever orders arrive"
chosen: "Direct to producers"
criteria:
  - "first money arrives within nine months"
  - "keeps me able to stop without owing anyone"
  - "does not need me to hire a salesperson"
criteria_ranked_by: founder
option_evidence:
  - "Direct to producers :: CLAIM-NEAR0002"
  - "Through the two national distributors :: CLAIM-NEAR0003"
  - "Keep taking whichever orders arrive :: none - the corpus holds nothing on the status quo"
likelihood: likely
likelihood_range: "55-80%"
evidence_grade: moderate
reasoning: |
  Distributor onboarding takes two quarters, so the channel would arrive after
  the window it exists to serve.
reopen_if: |
  The deadline is extended.
rests_on:
  - CLAIM-NEAR0002
---

Violates: decision-brief-incomplete

A brief-backed decision with the grid, the ranked criteria and the
recommendation all recorded, and `founder_reasoning` missing. Nothing else in
the corpus can tell: the note reads as complete, and six months later it shows
a choice made on analysis with no trace of the constraint that actually drove
it. `assumptions_low` is absent and must not be demanded - decisions.md marks it
required only when Low-confidence load-bearing assumptions exist.
