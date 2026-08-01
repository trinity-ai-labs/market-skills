# Financial Model — example product

A live assumptions table whose rows match assumption note titles character for
character, exactly as a rendered table does — and two of the three notes behind
them have been retired from the ledger. Before `model-row-dead-assumption` the
title match alone cleared every row, so this document read as `matched verbatim`
while the projection stood on values nothing was obliged to maintain.

The first row is the silent side: its note is `current`, so the row matches and
nothing is reported. Two of three failing is what says the status is read rather
than the whole table being flagged.

## Assumptions (every input lives here — nothing buried in a formula) {#assumptions}

| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
| A-1 | Seat price holds at the published list rate | 40 per seat per month | [S1] | M |
| A-2 | Support load per account stays flat after onboarding | 20 minutes per month | [S2] | L |
| A-3 | Referral traffic converts at the paid-channel rate | 3% | [S3] | L |

Rows A-2 and A-3 are the planted ones. Both titles exist in `assumptions/`, and
both notes carry a status that retired them.
