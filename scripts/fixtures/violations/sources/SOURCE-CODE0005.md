---
id: SOURCE-CODE0005
type: source
title: "Agency guidance note accompanying the revision"
status: current
confidence: M
created: "2026-03-16"
url: "https://standards.example.gov/guidance/0074"
url_canonical: "standards.example.gov/guidance/0074"
pulled: 2026-03-16
code: 0074
quote: |
  The guidance does not extend the compliance date.
---

Violates: ambiguous-value

Twice: `pulled` is an unquoted date and `code` has unquoted leading zeros, the
two footguns the coerce-nothing table in vault.md names.
