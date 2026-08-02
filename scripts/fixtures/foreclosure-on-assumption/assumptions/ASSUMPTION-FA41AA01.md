---
id: ASSUMPTION-FA41AA01
type: assumption
title: "The self-serve channel cannot carry the mid-market segment"
status: current
confidence: L
confidence_own: L
created: "2026-08-02"
value: "0 mid-market accounts through self-serve"
sensitivity: high
validated_by: "the first quarter of self-serve signups, segmented"
forecloses: "the self-serve route into mid-market"
foreclosed_on: CLAIM-FA43CC03
reverses_if: "self-serve closes one mid-market account in the first quarter"
used_in:
  - "business-plan.md#go-to-market"
---

An option taken off the table by a note that rests on nothing. Every field the
foreclosure schema asks for is here, INCLUDING `reverses_if` - which is what
makes this the sharp case: --foreclosed reads claims only, so it is silent, and
a rule that merely demanded the missing field would have nothing to say either.

What is wrong is not a missing field. An assumption is what you would believe
with no evidence, so there is no input for `foreclosed_on` to name and no
conclusion drawn from one - this is an assumption in the shape of a finding, and
the repair is the `question` the plan stopped asking rather than three more
fields on a note that cannot carry them.
