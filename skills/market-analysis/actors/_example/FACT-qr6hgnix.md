---
id: FACT-qr6hgnix
type: fact
title: "Example Ledger's Team tier lists at $24 per seat per month, billed annually"
status: current
confidence: H
confidence_own: H
created: "2026-07-20"
actor: "_example"
field_class: pricing
pulled: "2026-07-20"
stale_after: "2026-10-20"
rests_on:
  - SOURCE-5ObFcX8P
---

One price point, one note. The tier name and the model are separate `pricing` facts,
because status and confidence are per-note and a tier can be renamed without the
price moving.

`stale_after` is three months past `pulled`, the `pricing` class window. A rotting
class stamped `"permanent"` is the cheapest way past the whole staleness rule, so the
lint reports that as `stale-after-not-permanent`.
