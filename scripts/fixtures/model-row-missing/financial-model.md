# Financial Model — example product

The forward direction of `--assumption-rows`: an `assumption` note declaring
itself an input to the projection, with no row in the table and no stated reason
the model leaves it out. The rule this inverts — no number in a projection that
is not a named assumption row — is correct and untouched; what it never asked is
whether a named assumption is missing from the table.

## Assumptions (every input lives here — nothing buried in a formula) {#assumptions}

| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
| A-1 | Seat price holds at the published list rate | 40 per seat per month | [S1] | M |

The second declared input has no row here. That is the whole fixture: the note
lints clean, this table lints clean, and until this mode nothing compared them.

## Revenue build (bottom-up ONLY) {#revenue-build}

Deliberately empty — nothing cites it.
