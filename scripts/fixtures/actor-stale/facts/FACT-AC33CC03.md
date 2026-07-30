---
id: FACT-AC33CC03
type: fact
title: "Example Ledger prices per seat rather than per ledger"
status: current
confidence: H
confidence_own: H
created: "2026-01-20"
actor: "ledger-example-com"
field_class: pricing
pulled: "2026-01-20"
rests_on:
  - SOURCE-AC11AA01
---

Violates: actor-fields-incomplete

THE PARTIAL SET. Two of the three fields a `fact` owes on top of the base schema
are here and `stale_after` is not, which is the shape the rule exists for: this
note reads as a corpus fact to every consumer while carrying nothing that could
ever flag it for re-checking. A partial set reads COMPLETE to every tool, and the
missing field is precisely the one that would have dated it.

The omission also has to fail rather than be treated leniently, because an
OMITTED `stale_after` reads as no re-check owed rather than as none scheduled —
and a dodge available by omission is not an exemption. `"permanent"` is the
positive record that no clock governs a value; nothing is the absence of a record.

Paired with SOURCE-AC11AA01, which carries `actor` and only `pulled` and must fire
nothing: together the two notes are the type-scoping assertion in both directions.
