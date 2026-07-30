---
id: FACT-AC66FF06
type: fact
title: "Example Ledger describes itself as approval-chain accounting for services firms"
status: current
confidence: H
confidence_own: H
created: "2026-01-20"
actor: "ledger-example-com"
field_class: description
pulled: "2099-12-31"
stale_after: "2099-12-31"
rests_on:
  - SOURCE-AC11AA01
---

Violates: stale-after-before-pulled

THE BOUNDARY THE RULE READS, which is `stale_after` not STRICTLY later than
`pulled` rather than merely earlier: the two dates here are equal, so a rule
written with `<` instead of `<=` passes this note and a fact arrives with a shelf
life that expired the moment it was read.

A transposed pair of dates makes a fact that was fresh when it was written arrive
already expired, and the fix is a re-read of the note rather than a re-fetch of the
page — which is why this is a separate code from `stale-actor-fact` and not a
harsher reading of it.

Both dates are far out on purpose, so this note is reported for the transposition
alone. Dated at today's quarter it would be past its `stale_after` as well, and two
codes on one note would keep the failure count right with either rule deleted.
