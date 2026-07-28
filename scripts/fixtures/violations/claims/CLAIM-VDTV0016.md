---
id: CLAIM-VDTV0016
type: claim
title: "The stated account count does not clear by the stated date"
status: current
confidence: M
confidence_own: M
created: "2026-07-20"
subject: "target-verdict"
stale_after: "2099-12-31"
rests_on:
  - FACT-DANG0002
---

Violates: verdict-fields-incomplete, verdict-thin-evidence

The strict half of the asymmetric trigger, and the note the release exists for.
`target-verdict` is a term this release introduces, so no corpus written before it
carries the subject — which means a note under it can be held to the fields
outright, and carrying NONE of them fails exactly as carrying a partial set does.

Anything looser would make omission the cheapest way past every rule that reads
one of these fields, and a dodge available by omission is not an exemption. The
ceiling notes beside this one are the lenient half, where field presence is what
triggers the set, because every existing vault holds one of those.

Four fields are owed here and `conditional_on` is not: with no `driver_kind`,
nothing says the driver is policy, and a rule demanding a condition of every
verdict would be met by inventing one.
