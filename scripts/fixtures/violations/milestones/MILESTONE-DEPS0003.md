---
id: MILESTONE-DEPS0003
type: milestone
title: "Regulated tier goes on sale"
status: current
confidence: L
confidence_own: L
created: "2026-03-16"
sequence: "2"
date_stated: "≤6mo"
date_confidence: stated
depends_on:
  - MILESTONE-CONC0001
moves:
  - ASSUMPTION-BADV0001
resource: external-certification-clock
rests_on:
  - CLAIM-SWEP0013
---

Violates: dependency-after-dependent

Its prerequisite sits at `sequence: 3` and this item at `sequence: 2`, so the
roadmap has the tier on sale a slot before the thing it needs. The comparison
runs on `sequence` rather than on `date_stated` deliberately: `date_stated` is
the founder phrase, verbatim, and `≤6mo` is not something to compare against a
month.
