---
id: ASSUMPTION-FA51AA01
type: assumption
title: "The reseller route cannot carry the regulated tier"
status: current
confidence: L
created: "2026-08-02"
value: "0 regulated-tier accounts through resellers"
sensitivity: high
validated_by: "the first regulated-tier deal a reseller is asked to quote"
forecloses: "the reseller route into the regulated tier"
used_in:
  - "business-plan.md#go-to-market"
---

The combination the sibling fixture cannot hold: `type: assumption`, carrying
`forecloses`, and carrying NO `reverses_if`. Every other note in this suite that
forecloses is either a `claim` or an `assumption` that declares its reversal
condition, and neither shape can tell the two readings of --foreclosed apart.

That is the whole job of this note. --foreclosed reads `claim` only, so it is
silent here. Widen it to read both asserting types - the closed pair
--subject-orphan uses, which does not transfer, because these three fields are a
claim's BY ARGUMENT rather than by filing convention - and this note becomes a
live foreclosure with no reversal condition: the mode fires, and the assertion
that it stays silent goes red. Without this note the widening is invisible,
because a note that declares `reverses_if` keeps a widened mode quiet too.

It carries `forecloses` alone, with no `foreclosed_on` beside it, which is the
honest shape of the error rather than a stripped-down copy of the sibling: an
assumption is what you would believe with no evidence, so there is no input for
`foreclosed_on` to name. It also pins that `check` fires on ANY of the three
fields and not only on all of them - the sibling carries all three, and a rule
narrowed to the full set would still pass it while going silent here.

The repair is not `reverses_if`. It is the `question` the plan stopped asking.
