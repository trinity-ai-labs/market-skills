---
id: MILESTONE-SEQU0006
type: milestone
title: "Pricing page rebuild ships"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
sequence: "M4"
date_confidence: none
moves:
  - ASSUMPTION-BADV0001
resource: capital
rests_on:
  - CLAIM-SWEP0013
---

Violates: sequence-not-orderable

`M4` is the month label, not a position. Both order checks skip a value they
cannot compare, so without this rule the note would take `dependency-after-
dependent` and `false-independence` down with it and print the same green as a
roadmap that passed them.
