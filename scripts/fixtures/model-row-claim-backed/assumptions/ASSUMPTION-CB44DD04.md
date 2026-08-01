---
id: ASSUMPTION-CB44DD04
type: assumption
title: "Gross margin holds at the observed blended rate"
status: superseded
superseded_by: CLAIM-CB33CC03
confidence: M
created: "2026-07-15"
value: "78% blended across the cohort"
sensitivity: medium
validated_by: "the cohort export the claim that replaced this note rests on"
model_input: revenue
---

THE RETIRED HALF OF THE PROMOTION. It still declares `model_input`, which pins
the other direction: row A-3 is rendered, so the row loop marks the title hit
through the live claim and `assumption-not-in-model` stays silent on this note.
A fix that cleared the row without marking it hit would report the same pair
again as an input the table has no row for, which is the second, wrong repair.
