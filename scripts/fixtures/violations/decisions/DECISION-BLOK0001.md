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
used_in:
  - "business-plan.md#why-now"
  - "business-plan.md#target--verdict"
---

Violates: block-scalar-field

`title` is a flat one-line scalar - the block form is allowed on quote,
reasoning, reopen_if and founder_reasoning and nowhere else. The parser still
reads the block correctly, so `status` on the next line is not swallowed.

Both `used_in` entries resolve, so `--used-in` stays silent on this note. They
are here for `--supersession-sweep`: `DECISION-SUPS0002` names this note in
`supersedes` while leaving its `status` at `current`, so the sweep has to report
across a half-made supersession - the report cannot depend on the pair being
well-formed, because a half-made pair is exactly the vault whose documents are
still saying the old thing. `DECISION-SUPS0002` carries no `supersedes_reason`
either, which is what the row's `reason` field has to say out loud rather than
leave blank.
