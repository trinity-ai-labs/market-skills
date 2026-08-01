---
id: CLAIM-CB33CC03
type: claim
title: "Gross margin holds at the observed blended rate"
status: current
confidence: M
confidence_own: M
subject: "gross-margin"
created: "2026-07-20"
stale_after: "2027-07-20"
reconciled: "2026-07-21"
rests_on:
  - SOURCE-CB55EE05
supersedes:
  - ASSUMPTION-CB44DD04
supersedes_reason: "a measured figure filed as an unevidenced assumption capped every claim resting on it, so the promotion is the repair rather than the defect"
used_in:
  - "financial-model.md#assumptions"
reconciled_sections:
  - "financial-model.md#assumptions 6cd27ac1"
---

THE PROMOTION SHAPE, VERBATIM. Row A-3's title is carried by this `current`
claim AND by the `superseded` assumption it replaced, and that pair is what
`model-row-dead-assumption` fired on: the title matched a retired note, no
`assumption` carried it live, and both halves of the message were true. The
conclusion did not follow — the row was backed the whole time. The row loop
reads the live-title index before the retired one, so this note clears A-3.
