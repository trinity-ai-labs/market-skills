---
id: FACT-AC77GG07
type: fact
title: "Example Ledger's canonical host is ledger.example.com"
status: current
confidence: H
confidence_own: H
created: "2026-01-20"
actor: "ledger-example-com"
field_class: identity
pulled: "2026-01-20"
stale_after: "permanent"
rests_on:
  - SOURCE-AC11AA01
---

THE SILENT SIDE OF ALL SIX RULES IN ONE NOTE, and it must fire nothing. It carries
`actor`, a class from the nine, both dates, and the `permanent` sentinel on a class
that legitimately holds it.

That makes it the assertion each rule needs beside its own: `permanent` on
`identity` is not `stale-after-not-permanent`, `permanent` is never before `pulled`
and never before today, and a complete set is not `actor-fields-incomplete`. The
`permanent` half of that matters more than it looks — quoted, the sentinel splits
out of a field exactly as an ISO date does and sorts AFTER every one of them, so
both comparisons read it as not-stale with no special case anywhere in either
implementation. A rule that special-cased it in one and not the other would be a
parity failure on every dated fixture at once.

`stale_after: "permanent"` because no clock tells you a company renamed or moved
its domain. What retires this note is a `corporate-event` note recording the move,
which supersedes it.
