---
id: CLAIM-CR1EE005
type: claim
title: "Fulfilment runs on a weekly despatch cycle"
status: current
confidence: M
confidence_own: M
created: "2026-07-28"
subject: "despatch-cycle"
stale_after: "2099-12-31"
rests_on:
  - FACT-CR1BB002
---

Violates: unknown-subject

`despatch-cycle` overlaps no term and no alias in this vault's vocabulary, in
either direction and on either the substring or the common-prefix test, so it
reaches the last of the five resolution steps. That step is the one that needs
term records specifically: with an empty vocabulary the whole subject block is
skipped, so this claim also reports as clean.
