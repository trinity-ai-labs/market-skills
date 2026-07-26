---
id: DECISION-DR07KK21
type: decision
title: "Keep the pilot on one product line until the second re-labels"
status: current
confidence: M
confidence_own: H
created: "2026-03-17"
options:
  - "One line until the second re-labels"
  - "Both lines from the start"
chosen: "One line until the second re-labels"
reasoning: |
  The second line has no re-label date yet, so tooling built for it now would
  be built against a spec that has not been written.
reopen_if: |
  The second line publishes a re-label date, or the first line finishes ahead
  of the deadline with capacity left over.
rests_on:
  - CLAIM-BB77KK12
---

The minimal decision note: vault.md's shape, with none of the decision-brief
fields decisions.md adds. A founder in the direct posture answered the fork
themselves, so no brief was ever written and there is nothing for `criteria`,
`option_evidence` or `founder_reasoning` to hold. This note is correct as
written, and `decision-brief-incomplete` must stay silent on it - a check that
demanded brief fields here would fail the schema document's own example.
