---
id: MILESTONE-SV2FF006
type: milestone
title: "Self-serve renewal lands for the accounts the deadline brought in"
status: current
confidence: M
confidence_own: M
created: "2026-07-01"
sequence: "2"
date_confidence: none
depends_on:
  - MILESTONE-SV2EE005
moves:
  - ASSUMPTION-SV2DD004
resource: founder-hours
rests_on:
  - CLAIM-SV2CC003
used_in:
  - "business-plan.md#roadmap"
  - "research/timeline.md"
---

Its prerequisite sequences before it, which is the passing side of
`dependency-after-dependent`. It shares `resource` with MILESTONE-SV2EE005 and
does NOT share a `sequence`, so it is also the passing side of
`false-independence` - two items on one resource, run one after the other.

`date_confidence: none` is the positive record that no date was stated for it.
An absent field would be indistinguishable from a forgotten one.
