---
id: ASSUMPTION-BADV0001
type: assumption
title: Retention: the base case after the deadline passes
status: unverified
confidence: L
created: "2026-03-16"
value: "70% of accounts renew in the year after the deadline passes"
sensitivity: no
validated_by:
  - QUESTION-GAPS0001
---

Violates: ambiguous-value

Twice: the unquoted title splits on its colon-space, and `sensitivity: no` reads
as boolean false in YAML 1.1 and as the text no in YAML 1.2. The schema answer
is `sensitivity: low`.
