---
id: ASSUMPTION-HE1EE005
type: assumption
title: "Referral traffic converts at the paid-channel rate"
status: superseded
confidence: L
created: "2026-07-01"
value: "3% of referred visits"
sensitivity: low
superseded_by: CLAIM-HE1ZZ999
---

Violates: superseded-by-dangling

`superseded_by` names an ID no note in this vault carries. The separate row is
the point: there is no successor to add the back-edge to, so the repair is to
write the note or fix the typo, not to amend a note that exists. Nothing else in
the tool reports it — the dangling-edge check walks the block-list edge fields
and never this scalar.

It also carries no `used_in`, so it lands under `reached_no_document` while
still failing, which is what says the two questions are independent.
