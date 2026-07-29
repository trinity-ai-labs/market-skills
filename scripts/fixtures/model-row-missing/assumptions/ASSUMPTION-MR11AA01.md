---
id: ASSUMPTION-MR11AA01
type: assumption
title: "Seat price holds at the published list rate"
status: unverified
confidence: L
created: "2026-07-20"
value: "40 per seat per month, unchanged across the horizon"
sensitivity: high
model_input: revenue
validated_by:
  - QUESTION-MR11QQ01
---

The SILENT side of the check. This note declares itself a model input and the
table renders it verbatim, so a rule that reported every declared input would
fail here as loudly as it does on its sibling and the fixture would assert
nothing about which one is wrong.
