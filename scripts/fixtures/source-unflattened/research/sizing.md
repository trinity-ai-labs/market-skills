# Sizing — example product

This file keeps its own local source table, which is how a research document
stays traceable while the numbering it uses is its own. The root `sources.md`
is what turns a local row into a citable `[S#]`.

| S | Source | URL |
|---|---|---|
| S1 | Regulator, deadline notice | https://example.org/deadline |
| S2 | Category association, unit shipments | https://example.org/shipments |

`S2` is the defect. Its URL appears nowhere in the global log, so the source
can be cited from this file's prose and cannot be cited from a plan document at
all. Every existing check passes over it: this table is well-formed, the log is
well-formed, and nothing compared them.

## What the numbering costs when a row never lands

A plan that cites the second row's number anyway resolves it against whatever
the log happens to assign that number to, which is a different source. The
citation resolves, the check that only asks whether a code resolves passes, and
the reader gets the wrong provenance.
