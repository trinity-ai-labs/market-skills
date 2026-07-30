---
id: FACT-AC22BB02
type: fact
title: "Example Ledger's Team tier lists at $24 per seat per month, billed annually"
status: current
confidence: H
confidence_own: H
created: "2026-01-20"
actor: "ledger-example-com"
field_class: pricing
pulled: "2026-01-20"
stale_after: "2026-04-20"
rests_on:
  - SOURCE-AC11AA01
---

Violates: stale-actor-fact

THE LOAD-BEARING ONE. A complete, well-formed record fact whose `stale_after` has
passed, with `status` still `current` — so nothing about it is malformed and every
other check in this vault passes over it. What is wrong is only that the date
went by, which is why this is the one rule here that fires on nothing having
changed.

`pricing` is a three-month window and this note is a quarter past it. The fix is
one fetch against the URL `rests_on` already names, landing as a new fact note
that `supersedes` this one — and the re-fetch assertion in run-fixtures.sh proves
that a fresher `pulled`/`stale_after` pair clears it, because a red nobody can
clear is a red nobody reads.

Left as is, this figure ships out of the corpus PRE-CITED and reads as more
authoritative than one the run fetched itself. That is the failure the whole
citation discipline exists to prevent, and it is the reason a corpus is safe to
ship at all: a stale corpus costs a fetch and never a wrong number.
