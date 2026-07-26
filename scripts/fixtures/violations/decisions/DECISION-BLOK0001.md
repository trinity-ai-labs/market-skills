---
id: DECISION-BLOK0001
type: decision
title: |
  Sell direct to producers before building the distributor channel
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
options:
  - "Direct to producers"
  - "Through the two national distributors"
chosen: "Direct to producers"
reasoning: |
  Distributor onboarding takes two quarters, so the channel would arrive after
  the window it exists to serve.
reopen_if: |
  The deadline is extended.
rests_on:
  - CLAIM-NEAR0002
---

Violates: block-scalar-field

`title` is a flat one-line scalar - the block form is allowed on quote,
reasoning, reopen_if and founder_reasoning and nowhere else. The parser still
reads the block correctly, so `status` on the next line is not swallowed.
