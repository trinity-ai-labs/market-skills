---
id: ASSUMPTION-MS22BB02
type: assumption
title: "Support load per account stays flat after onboarding"
status: superseded
confidence: L
created: "2026-07-20"
value: "20 minutes per account per month"
sensitivity: medium
model_input: cost
---

Violates: model-row-dead-assumption

Row A-2 is live in the model and the only note carrying its title has been
superseded. The title matched, so `--assumption-rows` printed `matched verbatim`
over it — which is exactly the failure: an input the projection rests on that
nothing orders in the validation queue, with every check green.

It also carries `model_input`, and must not ALSO be reported as an input the
table has no row for: one situation gets one failure, and a second row pointing
at a different repair is what sends a reader to the wrong fix. Two things hold
that now - the row loop marks the title hit, and the note side skips a retired
note outright.
