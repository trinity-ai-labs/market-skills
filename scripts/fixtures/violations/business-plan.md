# Business plan — example product

Violates: roadmap-table-missing

The vault carries eight `milestone` notes and this document has no heading that
answers to `roadmap`, so the whole roadmap is in the ledger and nowhere a reader
can see it. That is reported once against this document rather than once per
milestone: the fix is one thing — write the section — and eight rows for one job
is a report people stop reading.

The rendered document the violating vault's `used_in` entries resolve against.
It carries `## Why now` and deliberately no `## Risks`, so `CLAIM-STAL0006`
stays a pure `stale-claim` fixture while `CLAIM-ANCH0012` has a real document
with a missing section in it.

## Why now

`CLAIM-STAL0006` is cited here. Its target resolves; what is wrong with that note
is its shelf life, not its citation.

## Target — verdict

The em dash is dropped and the two spaces that flanked it each become a hyphen,
so this heading anchors as `target--verdict`. Collapsing the run would produce
`target-verdict`, which is not what the rendered document carries — and a note
citing the real anchor would then be reported dead.

## Précis of the ask

A heading whose letters are not all ASCII. awk reads UTF-8 as bytes, so a slug
rule keeping only `[a-z0-9_ -]` would strike the accented letter and turn a link
that works into a reported failure.
