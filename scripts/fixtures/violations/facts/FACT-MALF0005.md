---
id: FACT-MALF0005
type: fact
title: "The compliance date was confirmed in a phone call"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
rests_on:
  - "a phone call with the agency press office"
---

Violates: malformed-edge

Nothing is missing from the vault - `rests_on` never named a note in the first
place, so the fix is to write the source note, not to hunt for a deleted one.
