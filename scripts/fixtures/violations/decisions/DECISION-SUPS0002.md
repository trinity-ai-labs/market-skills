---
id: DECISION-SUPS0002
type: decision
title: "Re-take the channel decision after the guidance note"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
options:
  - "Direct to producers"
  - "Through the two national distributors"
chosen: "Through the two national distributors"
# Stamped for the reason given on CLAIM-SWEP0013: at schemaVersion 2 the sweep
# fails a supersession with no `reconciled:`, and this vault has to keep
# exiting 0 from it. What this note is built to violate is
# `supersedes-reason` - which is a different half of the same pair, and stays
# missing below.
reconciled: "2026-03-16"
supersedes:
  - DECISION-BLOK0001
reasoning: |
  The guidance note removed the timing argument the earlier decision rested on.
reopen_if: |
  Direct acquisition cost per account falls below the first-year contract value.
rests_on:
  - CLAIM-NEAR0002
---

Violates: supersedes-reason, supersedes-status

DECISION-BLOK0001 is still `current`. Supersession is two edits: without the
second, both notes read as live and the pair is indistinguishable from an
unresolved contradiction.
