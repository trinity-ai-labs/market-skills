# Business plan — example product

The reverse direction of `--roadmap-table`: a roadmap table that renders one of
the two `milestone` notes and never lists the other. The missing item is still a
dated change to an assumption row, so the model has a step the reader of this
document cannot see and has nowhere to go and ask about.

## Milestones & roadmap {#roadmap}

| # | Item | Assumption moved | Resource |
|---|---|---|---|
| 1 | Unassisted setup for the core job ships | setup effort per account (A-1) | founder-hours |

The item column is deliberately NOT the first one here, which is the shape the
generated `research/timeline.md` uses and the shape a plan reaches for the moment
its rows are numbered. A rule that always read the first cell would report `1` as
an item that escaped the ledger — one failure, on a table whose every row
resolves, in a mode whose whole reason to exist is that it does not cry wolf.

The header row and the `|---|` rule above it are both dropped by the same test,
so `Item` is never read as a roadmap item — which would report a milestone with
no note under it on every correctly written table in existence.

## Financial summary

Deliberately empty — nothing cites it.
