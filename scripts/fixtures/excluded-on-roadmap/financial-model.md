# Financial Model — example product

The ARR term declares its composition, and this vault is the case where it does
not. One revenue line is excluded from the model — legitimately, because a
metered layer must not be allowed to flatter subscription churn — and the
roadmap ships a dated change to it, and no verdict note names it in
`arr_excludes`. So the ARR term every corner of the target is solved against is a
subset figure and nothing says which subset.

## Assumptions (every input lives here — nothing buried in a formula) {#assumptions}

| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
| A-1 | Seat price holds at the published list rate | 40 per seat per month | [S1] | M |

The metered line has no row here on purpose. It carries a stated
`excluded_from_model` reason, so `assumption-not-in-model` is cleared — which is
what makes `excluded-line-on-roadmap` the only failure this vault reports and the
count the assertion with teeth.
