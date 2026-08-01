# Financial Model — example product

The success line `--assumption-rows` prints when the model renders rows and no
note in the vault declares itself an input to it. Nothing here fails, and that is
the point: `model-row-no-assumption` ran over both rows and agreed, while
`assumption-not-in-model` — the direction this whole mode was written for —
iterated over an empty set.

The old line reported the row count and `matched verbatim` and said nothing about
the half that checked nothing, so a vault whose notes never carried `model_input`
read exactly like one whose declared inputs all reached the table.

## Assumptions (every input lives here — nothing buried in a formula) {#assumptions}

| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
| A-1 | Seat price holds at the published list rate | 40 per seat per month | [S1] | M |
| A-2 | Support load per account stays flat after onboarding | 20 minutes per month | [S2] | L |

Both rows match an `assumption` note title character for character, so the row
half of the mode has something to agree with and does. Neither note carries
`model_input`, so the other half has nothing at all.
