# Business plan — example product

A rendered document at the vault root, which is where `used_in` resolves against.
Nothing reads its prose: `--used-in` opens it for its headings and for nothing
else, because a scan matching note IDs against this text would report a false
positive on every correctly cited claim.

## Why now

`CLAIM-AS23SD44` is cited here, as `business-plan.md#why-now`. The citation code
in the prose is `[F1]` rather than the note ID, which is exactly why the mode
stops at whether the anchor resolves.

Producers must re-label before the deadline, and the ones without an in-house
regulatory function buy tooling rather than build it. [F1]

## Risks

`CLAIM-RR55TT19` is cited here, as `business-plan.md#risks`.

Producers treat the deadline as optional until a peer is fined. [F1]

## Competition & moat {#competition}

`CLAIM-RR55TT19` cites this section as `business-plan.md#competition` — the
explicit attribute, not the slug. The slug of this heading's text is
`competition--moat`: the `&` is dropped and both spaces that flanked it each
become their own hyphen, so the short anchor an author actually writes resolves
only through the attribute. This is the heading `run-fixtures.sh` rewords, to
assert the attribute is what carries the citation rather than the text.

## Business model & pricing {#business-model}

Cited both ways on purpose. `business-plan.md#business-model` resolves through
the attribute, and `business-plan.md#business-model--pricing` through the slug
of the heading text with the attribute stripped off — the entry a vault authored
before the template carried attributes already holds. Slugging the raw heading
line instead would yield `business-model--pricing-business-model`, which is
neither, so this pair is what asserts the strip happens before the slug rule
runs.

## Target & verdict {#target-verdict}

`CLAIM-VD04DD44` is cited here, as `business-plan.md#target-verdict`. The verdict
is conditional and the section says so in the words the note stores: the target
does not clear at six hours a week across two channels, and the counter-offer
below carries what each of those would have to become. `--binding-driver` matches
that string verbatim, so a section rewritten to say only *does not clear* fails
rather than rendering at the same confidence letter as the sentence that qualified
it.

The `Kind` column renders off `driver_kind` and is matched the same way. The
corner where nothing binds carries an em dash in both cells and owes no kind,
which is why the check skips it rather than reporting a corner with no note
behind it.

| Corner | Verdict | Binding driver | Kind |
|---|---|---|---|
| low value · early date | does not clear at six hours a week across two channels | reach | policy |
| low value · late date | clears | — | — |

Three distinct source notes stand under that driver, from three counterparties,
and the note states both counts — so nothing here is thin and nothing has to be
surfaced.

## Steady state {#steady-state}

`CLAIM-VD05EE55` is cited here, as `business-plan.md#steady-state`. That note
carries none of the five verdict fields, which is the ceiling half of the
asymmetry: the subject predates the fields and every existing vault holds a claim
shaped like it. There is deliberately no `{#steady-state}` equivalent of
`verdict-unfiled`, so this rendered section with a field-less note behind it is
the legitimate case rather than a failure.

## Not a heading

```sh
# This is a comment inside a fenced code block, not a section anyone can jump
# to. A note citing business-plan.md#this-is-a-comment-inside-a-fenced-code
# should fail, which is what skipping fences buys.
grep -rH '^stale_after:' claims/
```
