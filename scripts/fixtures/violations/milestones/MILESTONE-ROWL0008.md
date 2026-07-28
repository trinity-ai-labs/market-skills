---
id: MILESTONE-ROWL0008
type: milestone
title: "Self-serve trial opens to the second segment"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
sequence: "7"
date_confidence: none
moves:
  - A5
resource: design-bandwidth
rests_on:
  - CLAIM-SWEP0013
---

Violates: malformed-edge

`moves` holds the plan's assumptions-table row label rather than the note ID.
This is the other half of defect 7 and the half that used to pass clean: a
value that IS a well-formed ID naming no note is `dangling-edge`
(MILESTONE-MOVE0004), and a value that is not an ID at all fell through the
edges loop silently, because only `rests_on` reported it.

Silently is the word that matters. `A-n` is the label the plan's assumptions
table carries and the label roadmap-sequencing.md Rule 1 uses when it names the
assumption an item moves, so it is the form an author reading the prose writes
first - which made the one unchecked shape the expected one, and left Rule 1
mechanical only against a mistake nobody makes.
