# Red team — example product

A rendered document at the vault root, like `business-plan.md`. `--red-team`
reads two things in it and nothing else: the roster below, and every table row
whose first cell is a round-qualified objection ID.

## Lenses dispatched

| Round | Lens |
|---|---|
| R1 | Capital skeptic |
| R1 | Operator |
| R1 | Target customer |

Three lenses, one round, and every one of them wrote a row. That is the case the
mode has to stay silent on — a panel that ran and recorded what it found.

## Objections

| # | Lens | Objection | Severity | Disposition |
|---|---|---|---|---|
| R1-O1 | Capital skeptic | The addressable set is the producers who re-label, not every producer in the category. | High | fixed — the market section now sizes the affected subset |
| R1-O2 | Operator | The roadmap assumes two engineers from month one and the plan funds one. | Medium | moved to Risks as R1-O2 |
| R1-O3 | target customer | Buyers who already run an in-house regulatory function will not switch. | Medium | rejected — that segment is out of the beachhead by construction |

`R1-O3` writes its lens in lower case on purpose. The roster wrote it as
`Target customer`, and matching the raw cell would report two lenses here, one of
them with no rows — a check that fires on capitalisation is one somebody
switches off.

## The row template, in a fence

```
| R<round>-O<n> | Lens | Objection | Severity | Disposition |
| R4-O1 | Regulatory | An example row in a fence. | High | — |
```

The fence is what keeps `Regulatory` from registering as a lens that wrote a row
without being dispatched. A document that carries its own row template would
otherwise fail for documenting its own format.
