---
id: MILESTONE-GATE0001
type: milestone
title: "Unassisted setup for the core job ships"
status: current
confidence: L
created: "2026-03-16"
sequence: "3"
resource: founder-hours
---

No `Violates:` line, deliberately: that contract is read only over `violations/`,
and a promise in a file nothing reads is worse than none. This vault is asserted
by name, in run-fixtures.sh section 8.

A vault stamped `schemaVersion: 1` predates the milestone type, so `milestone`
is not one of the types it may carry and the message says which version added
it. Everything a version-2 vault would owe - `moves`, `resource`,
`date_confidence`, `confidence_own` - is deliberately absent here: at 1 the type
carries no required fields of its own, so `required-field` must stay silent too.
