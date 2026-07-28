---
id: MILESTONE-CONC0002
type: milestone
title: "Second-seat invite flow ships"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
sequence: "3"
date_confidence: none
moves:
  - ASSUMPTION-BADV0001
resource: founder-hours
rests_on:
  - CLAIM-SWEP0013
---

Violates: false-independence

The other half. Everything else here is correct on purpose, so the only thing
this note and MILESTONE-CONC0001 share is what the check keys on - the pair of
`resource` and `sequence`, not either one alone. The passing side of that
distinction is in `schema-2/`, where two milestones share a `sequence` and
differ on `resource` and the check stays silent.
