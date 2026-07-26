---
id: DECISION-MG18QW42
type: decision
title: "Stay on the single warehouse until the second region has orders"
status: current
confidence: M
confidence_own: M
created: "2026-03-17"
options:
  - "One warehouse until the second region has orders"
  - "Open the second warehouse now"
chosen: "One warehouse until the second region has orders"
reasoning: |
  No order has arrived from the second region, so a warehouse there would be
  capacity bought against a demand nothing has shown.
founder_reasoning: |
  I have run out of cash once already and I am not doing it again for a room
  full of stock nobody has asked for.
reopen_if: |
  Two consecutive months where orders from the second region exceed a tenth of
  the total.
rests_on:
  - CLAIM-AS23SD44
---

A decision note carrying `founder_reasoning` and no other decision-brief field.
This is the shape a migration produces: existing prose held the founder's own
words, so the words were kept verbatim rather than paraphrased into `reasoning`,
and no brief was reconstructed around them. `founder_reasoning` is owed by a
brief-backed record and never demands one - triggering on it would fail this
note, and the cheapest way to green would be deleting the founder's words.
