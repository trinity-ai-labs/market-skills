---
id: MILESTONE-CONC0001
type: milestone
title: "Unassisted setup for the core job ships"
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

Half of the pair. It declares the same `resource` as MILESTONE-CONC0002 at the
same `sequence`, which asserts that one founder does both in one slot.
roadmap-sequencing.md Rule 4 is the rule this reads: two items compete only when
they consume the same constrained resource, and asserting them concurrent there
is the false-independence claim that orders a whole roadmap and never gets
revisited.

Reported against BOTH members on purpose. Neither is the wrong one, and a reader
who opens the other file has to find the failure there too.
