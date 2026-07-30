# Red team — example product

The roster heading below carries a ZERO-WIDTH SPACE between its two words. That
one character is the whole fixture: `bin/vault-lint.sh` compares bytes in `awk`
and does not recognise the heading, so at `schemaVersion` 2 this document reports
`red-team-no-roster`. A culture-aware comparison treats a zero-width space as
ignorable and reports the folded heading EQUAL to `lenses dispatched`, reads the
roster, and answers a different document — which is a live parity divergence on
any founder prose carrying one, and parity was green only because no fixture had
one. `bin/vault-lint.ps1` states the rule where it applies it: no comparison that
reads a document is culture-aware.

## Lenses​ dispatched

| Round | Lens |
|---|---|
| R1 | Capital skeptic |
| R1 | Operator |

Both lenses wrote rows below, so a run that DID recognise this heading would
report nothing at all — which is what makes the divergence visible in the exit
code as well as in the JSON.

## Objections

| # | Lens | Objection | Severity | Disposition |
|---|---|---|---|---|
| R1-O1 | Capital skeptic | The addressable set is the producers who re-label, not every producer. | High | fixed |
| R1-O2 | Operator | The roadmap assumes two engineers and the plan funds one. | Medium | moved to Risks |
