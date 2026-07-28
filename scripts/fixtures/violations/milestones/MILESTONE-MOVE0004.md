---
id: MILESTONE-MOVE0004
type: milestone
title: "Partner integration surface ships"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
sequence: "4"
date_confidence: none
moves:
  - ASSUMPTION-NOTHERE99
resource: a-hire-that-has-not-happened
rests_on:
  - CLAIM-SWEP0013
---

Violates: dangling-edge

`moves` names an assumption no note in this vault carries. This is the whole of
defect 7 - "every roadmap item names the assumption it moves" was prose nobody
verified - and it needed no rule of its own: `moves` is in `EDGE_FIELDS`, so the
existing dangling-edge rule reads it exactly as it reads `rests_on`.
