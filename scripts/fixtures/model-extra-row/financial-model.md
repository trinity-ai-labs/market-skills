# Financial Model — example product

The reverse direction of `--assumption-rows`: a row in the assumptions table
matching no `assumption` note title, character for character. The number in it
has no `value`, no `sensitivity` and no `validated_by`, so nothing orders it in
the validation queue and nothing will ever revisit it.

Both other rows match their notes verbatim, which is what makes the failure count
the assertion with teeth: a check that reported every row would fire three times
here and still clear a census that only looks for the check name.

## Assumptions (every input lives here — nothing buried in a formula) {#assumptions}

| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
| A-1 | Seat price holds at the published list rate | 40 per seat per month | [S1] | M |
| A-2 | Support load per account stays flat after onboarding | 20 minutes per month | [S2] | L |
| A-3 | Referral traffic converts at the paid-channel rate | 3% | guess — validate | L |

The third row is the planted one. Nothing in `assumptions/` carries that title.

## Sensitivity {#sensitivity}

The second table in this document, and it is outside the assumptions section, so
nothing here is read: only the FIRST table under the assumptions heading is.

| Input | Flex | Effect on runway |
|---|---|---|
| Seat price | ±30% | ±2 months |
