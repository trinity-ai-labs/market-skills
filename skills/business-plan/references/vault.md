# The vault schema — notes, IDs, edges, and the invariants that keep them greppable

The vault is the claim ledger the skill maintains alongside a plan: every load-bearing
assertion as an atomic note, addressed by ID, with the dependency edges that let you ask
what a corpus no longer knows. It lives in the user's own directory, never in this repo.

This file is the schema. It is the one document every other part of the vault work
references, so it is written to be sufficient on its own: a reader who has only this file
can write a valid note of any of the seven types, place it correctly, and know which fields
they may not omit.

## Contents

- [The vault is a claim ledger over the prose](#the-vault-is-a-claim-ledger-over-the-prose)
- [Seven note types, and the seventh is a record rather than a grade](#seven-note-types-and-the-seventh-is-a-record-rather-than-a-grade)
- [An ID is an address, not a label](#an-id-is-an-address-not-a-label)
- [Seven edges, each stored once on the asserting note](#seven-edges-each-stored-once-on-the-asserting-note)
- [Four format invariants that break silently](#four-format-invariants-that-break-silently)
  - [Block lists survive an Obsidian save; inline flow lists do not](#block-lists-survive-an-obsidian-save-inline-flow-lists-do-not)
  - [Coerce nothing: ban the ambiguous value instead of parsing it](#coerce-nothing-ban-the-ambiguous-value-instead-of-parsing-it)
  - [A block scalar is allowed on four fields, and nowhere else](#a-block-scalar-is-allowed-on-four-fields-and-nowhere-else)
  - [One assertion per note, because status and confidence are per-note](#one-assertion-per-note-because-status-and-confidence-are-per-note)
- [Frontmatter schemas, with required fields marked](#frontmatter-schemas-with-required-fields-marked)
  - [Every note carries these six fields](#every-note-carries-these-six-fields)
  - [The source note keeps the quote that outlives the URL](#the-source-note-keeps-the-quote-that-outlives-the-url)
  - [The fact note is one observed value with its provenance](#the-fact-note-is-one-observed-value-with-its-provenance)
  - [The claim note is the only type that carries a subject](#the-claim-note-is-the-only-type-that-carries-a-subject)
  - [The assumption note is what you would believe with no evidence](#the-assumption-note-is-what-you-would-believe-with-no-evidence)
  - [A target verdict is a claim carrying five more fields, not an eighth note type](#a-target-verdict-is-a-claim-carrying-five-more-fields-not-an-eighth-note-type)
  - [The question note records the gap, not the answer](#the-question-note-records-the-gap-not-the-answer)
  - [The decision note keeps the rejected options and the reopen trigger](#the-decision-note-keeps-the-rejected-options-and-the-reopen-trigger)
  - [The milestone note carries a position, a cost, and the assumption it moves](#the-milestone-note-carries-a-position-a-cost-and-the-assumption-it-moves)
- [Confidence is derived wherever a note rests on something](#confidence-is-derived-wherever-a-note-rests-on-something)
- [Contradiction is a subject collision, not an edge](#contradiction-is-a-subject-collision-not-an-edge)
- [Status moves in one direction and never silently](#status-moves-in-one-direction-and-never-silently)
- [Layout: one directory per type, one file per note](#layout-one-directory-per-type-one-file-per-note)
- [Locate the vault explicitly and never search upward](#locate-the-vault-explicitly-and-never-search-upward)
- [schemaVersion refuses what it does not understand](#schemaversion-refuses-what-it-does-not-understand)
- [The queries this schema exists to make trivial](#the-queries-this-schema-exists-to-make-trivial)
- [A worked chain from source to decision](#a-worked-chain-from-source-to-decision)
- [Writing a note: the six-step checklist](#writing-a-note-the-six-step-checklist)

## The vault is a claim ledger over the prose

Research files stay exactly as they are. The vault does not replace them and does not try to
hold the reasoning — it holds the **assertable surface**: the outputs a later document leans
on, one note each, addressed.

That division is the whole design. Prose is where an argument is made; a note is where an
assertion is registered so something else can point at it. Emitting a note for every
paragraph produces a second corpus nobody maintains; emitting one for every load-bearing
output produces roughly a few hundred notes for a large engagement, which is the entire
assertable surface readable in one pass.

**The failure this prevents:** prose that cites `[S4]` inside a sentence resolves forward and
nowhere else. When the source is amended, nothing can enumerate what inherited it — so the
amendment lands in one file and the four documents downstream of it stay confidently wrong.

## Seven note types, and the seventh is a record rather than a grade

| type | asserts | lives in |
|---|---|---|
| `source` | this material exists and says this, verbatim | `sources/` |
| `fact` | this value is stated directly by a source | `facts/` |
| `claim` | the analysis asserts this, beyond what any one source says | `claims/` |
| `assumption` | this is believed with no evidence behind it | `assumptions/` |
| `question` | this is not known, and here is the gap | `questions/` |
| `decision` | this option was chosen over these, for this reason | `decisions/` |
| `milestone` | this work sits at this position, moves that note, and costs this resource | `milestones/` |

**The ceiling is real, and it is why the set stops here.** Comparable prior-art projects define
ten or twelve page types, and past about six the taxonomy becomes ceremony: authors stall
choosing between two types that differ only in emphasis, pick inconsistently, and the query that
depends on the type being right returns a partial answer. Structure that does not fit a type
belongs on an **edge**, not in a new type.

**`milestone` was added against that rule, and the argument sits here beside the rule it breaks —
a rule overruled without one stops being a rule.** Three things had to hold, and they are the
test an eighth type has to pass rather than a licence for one:

- **The stated harm cannot occur.** What the ceiling prevents is an author stalling between two
  types that differ only in emphasis. Nothing in the other six carries a position, a dependency
  or a resource cost, so there is no pair to stall between — a note that says *when this happens*
  is not a near-miss for a note that says *whether this is true*.
- **The edge escape hatch does not reach it.** "Structure that does not fit a type belongs on an
  edge" presumes two notes to hang the edge between. There was no note anywhere in the vault for
  a roadmap item, so the position, the resource cost and the assumption moved had nothing to hang
  off.
- **The set was never six grades.** Five of the six are epistemic — they say what the
  truth-status of an assertion is. `decision` is not; it is a record of a choice with a reopen
  trigger. So the set is five grades plus one record, and a second record type for scheduled work
  follows that precedent instead of breaking it.

**What it buys, stated as the failure it removes:** nothing in the output contract held what is
true at a given month, so a proposal was judged against the corpus's snapshot of today rather
than against the state at the month it would land. That is wrong in both directions — it kills a
proposal over a gap that is a dated roadmap item, and it credits a capability whose prerequisite
has not shipped. Both read as rigour. `research/timeline.md` is the artifact that answers it, and
it is a **view over these notes** rather than an eighth hand-maintained document: a document that
mirrors the plan's roadmap table drifts from it, and nothing in the corpus can tell.

The sharp lines between the types that get confused:

- **`fact` vs `claim`** — a fact is quotable from one source with no inference. The moment
  you combine two sources, extrapolate, or add a judgement, it is a claim. If you cannot
  point at a passage that states it, it is not a fact.
- **`claim` vs `assumption`** — an assumption rests on nothing. That is what makes it one. If
  it has evidence behind it, however thin, it is a claim with Low confidence, and the
  difference matters because assumptions are what a validation step is scheduled against.
- **`question` vs `assumption`** — an assumption is a value you are proceeding on; a question
  is a gap you are proceeding without. A question that has an answer you are betting on is
  really two notes.
- **`milestone` vs everything else** — the other six answer *is this true, and how do we know*.
  A milestone answers *when does this happen, what does it cost, and what does it change*. A note
  with no `sequence` and no `resource` is not a milestone, and a milestone that moves nothing is
  maintenance rather than a roadmap item
  ([roadmap-sequencing.md](roadmap-sequencing.md#rule-1--every-roadmap-item-names-the-assumption-it-moves-and-the-note-is-what-names-it)
  Rule 1).

## An ID is an address, not a label

Every note has an ID of the form `TYPE-xxxxxxxx`: the uppercased type, a hyphen, and eight
random characters from `A-Za-z0-9`.

```
SOURCE-K92MZ1QA    FACT-GF45SD01    CLAIM-AS23SD44
ASSUMPTION-MN66TT21    QUESTION-DD31RR09    DECISION-VV02HH55
MILESTONE-PJ40XR63
```

Generate one with no dependencies:

```sh
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8; echo
```

**There is no registry, no counter, and no sequential allocation.** Two researchers working
in parallel never coordinate, because with 62^8 possible suffixes a corpus of a few hundred
notes has a collision probability around 2 in 10 billion — collision is structurally
impossible rather than procedurally avoided. A sequential scheme makes it procedurally
avoided instead, and the procedure is exactly what two parallel researchers skip: both
allocate `S-17`, both are locally correct, and the merged corpus has one ID pointing at two
different sources with no signal that anything is wrong.

Sequential IDs rot for a second reason: they encode an order that stops being true. Delete
note 12 and either the numbering has a hole or every later ID moves, and every reference to
them is now wrong in a way no tool can detect.

**Alphanumeric only, no `_` or `-` inside the suffix.** The hyphen is the type separator, so
an ID splits unambiguously on its only hyphen, and a filename made from an ID never needs
quoting in a shell.

**The ID is an address; the `title` is what a human reads.** Rendered documents show the
title and use the ID as the link target. That is the entire reason a random string is
acceptable in a document a person reads: nobody ever sees `CLAIM-AS23SD44` in a sentence.

**Length is a generation rule, not a validation rule.** Generate eight characters; validate
only the shape `TYPE-[A-Za-z0-9]+`. A shorter hand-written ID from an early note is not a
lint failure, because failing an otherwise-valid corpus over a cosmetic length is how a
useful check gets switched off.

## Seven edges, each stored once on the asserting note

| edge | meaning | written on |
|---|---|---|
| `rests_on` | this note depends on these; the blast-radius edge | the dependent note |
| `supersedes` | this note replaces that one, with `supersedes_reason` | the replacement |
| `scopes` | this narrows that one — not a contradiction, not a supersession | the narrower note |
| `validated_by` | this assumption is tested by that validation step | the assumption |
| `depends_on` | this milestone cannot land until that one has | the later milestone |
| `moves` | this milestone changes the value that note asserts | the milestone |
| `arr_excludes` | the ARR term of this verdict's identity does not carry that note's revenue | the verdict |

All seven are block lists of IDs.

**`arr_excludes` is an edge rather than a prose note on the verdict for one reason: its items are
note IDs, so a mistyped one has to be a `dangling-edge` failure and not a silent exclusion.** A
declaration that the identity leaves out a note the vault does not hold is the one form of that
declaration nobody can catch by reading it, and being an edge is also what makes the excluded line
reachable from the verdict through `vault-lint.sh graph`. The rule it exists for is
[target.md](target.md#the-arr-term-declares-its-composition-or-the-exclusion-is-invisible)'s.

**Stored once, on the asserting note, and never mirrored.** There are no backlink fields,
because a backlink is a second copy of a fact that can drift from the first: edit one side,
forget the other, and the reverse query silently misses. The reverse direction is a grep:

```sh
grep -rl -- 'FACT-GF45SD01' "$VAULT_PATH"
```

That is exact because IDs are globally unique random strings. It is one more reason not to
use sequential IDs: `grep 'F-12'` also matches `F-120` and `F-123`, so the reverse query over
sequential IDs needs a real parser to be correct, while over random IDs a plain grep is
already correct.

**There is deliberately no `unlocks` edge, and that is the no-mirroring rule doing its job.**
"B `depends_on` A" and "A unlocks B" are one fact written twice, so a vault storing both can
carry either without the other — and the two queries then disagree with nothing able to say
which side is right, which is precisely the drift a backlink field causes. What an item unlocks
is read off the reverse of `depends_on`, exactly as what rests on a note is read off the reverse
of `rests_on`: `vault-lint.sh graph MILESTONE-…` prints it under *rested on by*, and
`research/timeline.md` is generated from that same traversal.

**`scopes` is the edge people reach for when they want `contradicts`.** Two notes that
disagree because one is narrower than the other are not in conflict: "willingness to pay is
around a certain figure" and "for the largest segment it is roughly triple that" are both
true, and the second `scopes` the first. Writing that edge is what stops the next reader
treating the pair as a contradiction and picking one at random.

**There is deliberately no `contradicts` edge.** It could only ever be written by someone who
had already noticed the conflict — and that is the moment they resolve it, supersede one
side, or scope it. An edge that is only writable at the instant it becomes unnecessary gets
written approximately never, and its absence in the corpus then reads as "no contradictions
found". Contradiction detection is mechanical instead; see
[Contradiction is a subject collision](#contradiction-is-a-subject-collision-not-an-edge).

## Four format invariants that break silently

These four are grouped because they share a failure mode: violating any of them produces a
vault that still parses, still renders, and still returns clean results from every query —
over a corpus the query can no longer fully see. A loud failure would be preferable.

### Block lists survive an Obsidian save; inline flow lists do not

Every list value is a block list. Never an inline flow list.

```yaml
# Correct — block form
rests_on:
  - FACT-GF45SD01
  - SOURCE-K92MZ1QA
```

```yaml
# Wrong — inline flow form
rests_on: [FACT-GF45SD01, SOURCE-K92MZ1QA]
```

**The failure:** Obsidian rewrites inline flow lists into block form when it saves a note.
A vault authored inline and queried with an inline-shaped pattern therefore loses every edge
the moment somebody opens a note in Obsidian and it writes the file back. The blast-radius
query then returns a clean bill of health over a corpus it can no longer see, which is worse
than an error — nobody investigates a green result.

Block form is a fixed point: nothing rewrites it, so a query written against it stays correct
regardless of which editor last touched the file.

**An empty list is an omitted key.** Never write `rests_on: []` (an inline flow list) and
never write `rests_on:` with nothing after it (that is `null`, not an empty list, and a
consumer that expects a list gets a type it did not plan for). If there is nothing to list,
the key is absent.

### Coerce nothing: ban the ambiguous value instead of parsing it

**Every frontmatter value is a string.** Nothing in the vault is a number, a boolean, a date
object, or null. Readers do no type coercion at all.

That rule only holds if the file never contains a value a YAML parser *would* coerce, so the
schema bans the ambiguous values:

| never write | write instead | why |
|---|---|---|
| `sensitivity: no` | `sensitivity: low` | YAML 1.1 reads `no` as boolean false; YAML 1.2 reads it as the string `"no"` |
| `chosen: yes` / `on` / `off` | quote it: `chosen: "yes"` | same divergence, same two answers |
| `value: null` / `value: ~` | omit the key | a present key holding nothing is not the same as an absent key |
| `pulled: 2026-03-14` | `pulled: "2026-03-14"` | unquoted it is a date object in most parsers, a string in the rest |
| `code: 0074` | `code: "0074"` | unquoted leading zeros are read as octal by some parsers and truncated by others |
| `title: Pricing: the floor` | `title: "Pricing: the floor"` | an unquoted `: ` splits the value into a nested mapping |

**The failure this prevents:** a reader that coerces has to reproduce YAML's coercion rules
exactly, and it cannot — YAML 1.1 and 1.2 disagree with each other, and implementations
disagree within each. The same note then means one thing to the editor and a different thing
to the checker, and the divergence surfaces as a check that passes while the rendered
document shows something else. Coercing nothing removes the whole class: a reader that treats
every value as text cannot diverge from a real YAML parser, because there is nothing left to
be wrong about.

Quoting is always safe. When in doubt, quote.

### A block scalar is allowed on four fields, and nowhere else

Four fields carry prose that must survive exactly as written: `quote` on
[the source note](#the-source-note-keeps-the-quote-that-outlives-the-url); `reasoning` and
`reopen_if` on
[the decision note](#the-decision-note-keeps-the-rejected-options-and-the-reopen-trigger); and
`founder_reasoning`, which
[decisions.md](decisions.md#the-founders-reasoning-is-kept-verbatim-and-separate) adds to the
decision note to hold the founder's own words separately from the skill's `reasoning`. Those
four, and only those four, may use the YAML literal block scalar (`|`). Every other field in
this schema is a flat scalar or a block list.

**The folded form (`>`) is banned everywhere, including on these four fields.** Folded style
reflows a block onto single lines at read time, joining line breaks into spaces. That is
tolerable for prose nobody needs verbatim, and it is exactly wrong for `quote`, whose only job
is to preserve the passage as printed. Write `|`. Never write `>`.

**A block scalar on any field outside this set is an error, not a style choice.** `title`,
`chosen`, `killed_because`, and every other prose field in this schema is a flat, possibly
quoted scalar on one line. Writing `title: |` is not a richer way to write a title — it is the
wrong syntax for that field, and a reader that tolerates it has to special-case a fifth, sixth,
and seventh field, which is what keeping the set closed is for.

**Where the block ends:** everything indented further than the key (`quote:`, `reasoning:`,
`reopen_if:`, `founder_reasoning:`) belongs to the value, line by line, until the first line
that dedents back to the key's own indentation or less — that line, and everything after it, is
the next key or the end of the frontmatter. A parser reading `quote: |` does not stop at the
first blank line or the first piece of punctuation; it keeps consuming indented lines until the
indentation drops.

**The failure this prevents:** a naive frontmatter reader that does not special-case `|` reads
`quote: |` as the literal two-character value `"|"` and moves on, silently treating every
indented line that follows as if it belonged to the next key. It returns a `source` note that
parsed without error and has no quote in it — on the single field this schema exists to keep
verbatim. Rejecting block scalars outright fails the opposite way: every `source` note and
every `decision` note in this document uses one, so a parser that refuses them on sight rejects
every note the schema tells you to write. A closed set of four lets a reader do neither:
handle the literal block for four known keys, and reject anything else loudly instead of
guessing.

**The set grew by one, and that is the exception, not the start of a pattern.**
`founder_reasoning` was added because a real field needed a verbatim multi-line value and no
existing field could hold it without paraphrasing the founder's words — not because a fourth
option was convenient. A set that grows every time a new document wants a prose field stops
being closed in anything but name, and the closure is what lets a reader special-case a fixed,
small, enumerable list instead of writing a general-purpose YAML block-scalar handler. Expect
this to happen rarely.

### One assertion per note, because status and confidence are per-note

A note asserts exactly one thing. The reasoning stays in the research prose; the note holds
what is assertable.

**The failure:** `status` and `confidence` are per-note fields. A note asserting two things
can carry only one of each, so when half of it is disproved there is no correct move —
retract it and a true assertion disappears from the corpus, or leave it `current` and a
false assertion keeps its clean bill of health and stays cited. Splitting is not possible
after the fact either, because the documents already point at the one ID.

## Frontmatter schemas, with required fields marked

Every note is a Markdown file: YAML frontmatter, then a body. The frontmatter is the ledger.
The body is one short paragraph stating the assertion in plain language, and whatever context
a human reading the note alone would need. The body is never parsed.

In the schemas below, `# required` and `# optional` are annotations for this document — real
notes do not carry them. Every example is illustrative and generic; the product, the
regulator, and every figure are invented.

### Every note carries these six fields

```yaml
id: CLAIM-AS23SD44          # required — TYPE-xxxxxxxx, identical to the filename minus .md
type: claim                 # required — one of: source fact claim assumption question decision
title: "..."                # required — what a rendered document shows; the ID is the link target
status: current             # required — current | needs_review | superseded | retracted | unverified
confidence: M               # required — H | M | L
created: "2026-03-15"       # required — quoted date the note was written
```

**The type is stated three times** — the directory, the ID prefix, and the `type` field — and
all three must agree. The redundancy is deliberate: the filesystem sees only the directory, a
grep over IDs sees only the prefix, and a YAML reader sees only the field, so each consumer
gets the answer without needing the other two. A checker verifies they match; a mismatch means
one consumer is already answering differently from the others.

**`created` is required even though the filesystem has an mtime**, because the vault lives in
the user's documents and is frequently not under version control. Without an authored date
there is no way to tell a `current` note written before a source was amended from one written
after — and that distinction is exactly what you need when deciding which notes to re-check.

Four more fields are available on **any** type, used together:

```yaml
supersedes:                          # optional — block list, on the REPLACEMENT
  - CLAIM-QQ19PL30
supersedes_reason: "The vendor republished the list; the earlier figure was a promotion."   # required with supersedes
reconciled: "2026-07-10"             # required with supersedes at schemaVersion 2 — quoted ISO date
superseded_by: CLAIM-AS23SD44        # optional — on the REPLACED note, naming its replacement
```

**`supersedes` without `supersedes_reason` is rejected.** A replacement with no reason cannot
be evaluated later — the only question anyone asks about a superseded note is why, and the
person who knew is gone. And writing `supersedes` **without flipping the target's `status` to
`superseded`** leaves two `current` notes asserting different values on the same subject,
which is indistinguishable from an unresolved contradiction to both the checker and a reader.
Supersession is always two edits, and `reconciled:` below is what closes it out.

**`superseded_by` is the same edge written from the replaced note's own side, and it is only
usable if the other side names it back.** Every query in this vault walks `supersedes`, because
that is where the reason and the `reconciled:` date live — so a note carrying `superseded_by`
whose named successor never wrote `supersedes` is a supersession only one file knows about, and
the sweep reads it as replaced by *nothing at all*. On a live corpus that cost exactly what it
sounds like: an assumption backing a live row in the financial model named its replacement,
nothing named it back, the sweep reported it as replaced by nothing, and three current claims
went on resting on the dead note. So `vault-lint.sh --supersession-sweep` **fails** two shapes —
`superseded_by` naming a note that does not list it in `supersedes` (`superseded-by-unreciprocated`),
and `superseded_by` naming an ID no note in the vault carries (`superseded-by-dangling`). Neither
is gated on `schemaVersion`: both fire on the presence of the field, so a vault that never wrote
it owes nothing. Write `superseded_by` when it helps a reader of the replaced note find the
replacement, and write the `supersedes` half in the same edit.

**Both those edits land in the vault, and the documents the old note reached hear nothing.** That
is the third cost of a supersession: a superseded claim that was cited into three plan sections
leaves those three sections asserting the old value, with `status: superseded` sitting in a file
nobody rereads. `vault-lint.sh --supersession-sweep` is what says so out loud — it walks every
superseded note, unions the `used_in` targets behind them, and prints one row per document
section with the notes that reached it, their replacements and each `supersedes_reason`. A note
counts as superseded under any of the three addresses of the same fact — named by a `supersedes`
edge, carrying `status: superseded`, or carrying `superseded_by` — because the worklist matters
most on the pair that was only half made, and one that only read well-formed supersessions would
go quiet exactly there. One row
per *section* rather than per note, because the work is re-reading the section once however many
superseded notes point at it — and one section named two ways is still one row, since a heading
is addressable both by an explicit `{#anchor}` and by the slug of its text and two notes can
reach it under different strings. The row count it prints first is what makes the follow-up read
something you can size before starting instead of a corpus-wide re-read nobody begins, so a
worklist that counted that section twice would be one you learn to skip.

**`reconciled:` is what closes the supersession out, and what turns that worklist into something
somebody is obliged to finish.** It is a quoted ISO date on the superseding note, and it asserts
exactly one thing: the sections this supersession put in doubt have been read. `--supersession-sweep`
**fails** when a note carrying `supersedes` has no `reconciled:`, and when its `reconciled:` is
earlier than that note's own `created` — a date carried over from an earlier pass reads exactly
like one stamped after the read, and which of the two it is happens to be the only half a check
can see. Both values are quoted, so the comparison is a plain string comparison and there is no
date library anywhere near it; that is the payoff the coerce-nothing rule is claimed for, and
this is where it is collected. Same-day passes: the rule is that the read cannot predate the
supersession, not that it has to happen later, and most reconciliations are done in one sitting.

**Finding rows is still not a failure.** A vault where every supersession is reconciled prints
its worklist, prints its count, and exits 0 — a supersession with a blast radius is the corpus
working, and a mode that failed a healthy vault would train you to ignore the exit code the
actual checks depend on. What is not healthy is a supersession nothing says was read, and that
is the only thing the exit status now answers. **The field records that the read was claimed,
not that it was done well** — a date can be stamped without opening anything. What it removes is
skipping the read *by default*, which is what a worklist with no obligation attached had been
shipping.

**The verdict applies at `schemaVersion` 2.** A vault at 1 predates the field, cannot owe it, and
exits 0 either way; [vault-migration.md](vault-migration.md#stamp-schemaversion-2-last-after-the-vault-can-already-pass-at-2)
carries the back-fill, which is read the sections, stamp the dates, then stamp the version.

### The source note keeps the quote that outlives the URL

```yaml
---
id: SOURCE-K92MZ1QA         # required
type: source                # required
title: "Example Standards Agency — packaged-goods labelling rules, 2025 revision"   # required
status: current             # required
confidence: M               # required — authored directly; a source rests on nothing
created: "2026-03-14"       # required
url: "https://standards.example.gov/labelling/2025-revision"        # required
url_canonical: "standards.example.gov/labelling/2025-revision"      # required
pulled: "2026-03-14"        # required — the date the material was actually read
quote: |                    # required — the load-bearing passage, verbatim
  Pre-packaged goods sold direct to consumers must carry the revised
  nutrition panel from 1 January 2027.
publisher: "Example Standards Agency"   # optional
published: "2025-11-02"                 # optional — the source's own date, not yours
counterparty: "Example Retail Group"    # optional — the party a deal or datum came from
---

The revision sets a hard compliance date and gives no transitional exemption for
producers under a size threshold.
```

**`quote` is required, not a courtesy.** URLs rot, paywalls close, and pages are silently
edited. A source note whose evidence is a dead link is a claim with nothing behind it that
still reads as sourced — the verbatim passage is what keeps the chain checkable after the
page is gone.

**`url_canonical` is the normalised form, and it is what makes duplicate detection work.**
Normalise by: dropping the scheme, dropping `www.`, lowercasing the host, dropping the
fragment, dropping tracking parameters (`utm_*`, `fbclid`, `gclid`, `ref`), dropping a
trailing slash, and keeping everything else — including any query parameter that selects
which content is shown.

**The failure:** two researchers citing the same page, one from a newsletter link carrying
`?utm_source=...` and one from a search result, produce two source notes with two IDs. A
claim then rests on both and looks doubly sourced when it rests on one document. Normalising
turns that into a mechanical duplicate a checker can flag.

**A source with no public URL** — a founder interview, an internal document — sets both `url`
and `url_canonical` to the vault-relative path of the research file that records it, for
example `"research/founder-brief.md"`. The fields stay required and uniform, and duplicate
detection still works across the two researchers who both wrote up the same conversation.

**`counterparty` is optional and records the party a deal or datum came from** — the platform whose
take rate this is, the distributor whose terms these are, the one customer both quotes came from. A
published document like the example above has none, and omits the key. A consumer that needs the
value applies a fallback chain and stops at the first hit: `counterparty`, then `publisher`, then
the host of `url_canonical`.

**The failure it prevents is one `url_canonical` structurally cannot reach.** Two deals with the
same counterparty, written up from two separate research passes, are two source notes with two
`url_canonical` values. A count of sources says 2, while the concentration — one relationship's
terms standing in for a market's — is invisible. Deduplication cannot catch it, because the two
write-ups genuinely *are* two documents: distinct pages, distinct pulls, neither a duplicate of the
other. The only thing they share is the party on the other side of the table, and nothing but this
field records it.

**The fallback chain is a proxy, and it is worth knowing which way it errs.** `publisher` is the
first fallback because a deal write-up is usually published *by* the counterparty — a platform's own
announcement, a distributor's own terms page — so the chain is right in the common case. Where a
third party reported the deal it is wrong in the direction that cries wolf: two unrelated deals
covered by one trade publication collapse onto one party, and a concentration gets reported that is
not there. That is exactly why the field is authored rather than inferred. Dropping the chain
instead is worse in the direction that hides: an unwritten field would read as *no counterparty*
rather than *not recorded*, so every note would count as its own distinct party and a corpus written
before the field existed would report perfect diversity.

### The fact note is one observed value with its provenance

```yaml
---
id: FACT-GF45SD01           # required
type: fact                  # required
title: "The revised nutrition panel is mandatory from 1 January 2027"   # required
status: current             # required
confidence: M               # required — derived: min(confidence_own, every rests_on target)
confidence_own: H           # required — the assessment on this note's own merits
created: "2026-03-14"       # required
rests_on:                   # required — block list, the source(s) that state it
  - SOURCE-K92MZ1QA
---

Stated directly in the revision text. No transitional exemption by producer size.
```

**`rests_on` is required on a fact.** A fact with no source is an unverified claim wearing the
word "fact", and it is precisely the note that gets cited without hesitation. Requiring the
edge means the provenance question is answered at authoring time, when the answer is still
in someone's head.

### The claim note is the only type that carries a subject

```yaml
---
id: CLAIM-AS23SD44          # required
type: claim                 # required
title: "The labelling deadline opens a 12-month buying window for compliance tooling"   # required
status: current             # required
confidence: M               # required — derived, never authored on a claim
confidence_own: H           # required — the assessment on the claim's own merits
created: "2026-03-15"       # required
subject: "timing-window"           # required — a term from the controlled vocabulary
stale_after: "2027-01-01"          # required — quoted date; past it, the claim needs re-checking
rests_on:                          # required — block list
  - FACT-GF45SD01
  - FACT-QP81ZZ07
used_in:                           # required once the claim is cited in a rendered document
  - "business-plan.md#why-now"     # the heading's own {#anchor}, not the slug of its text
  - "one-pager.md"
reconciled: "2026-03-20"           # schemaVersion 3 — the date the sections below were read
reconciled_sections:               # schemaVersion 3 — what was read, and what it looked like
  - "business-plan.md#why-now 3a243b97"
scopes:                            # optional — block list
  - CLAIM-BB77KK12
---

Producers must re-label before the deadline, and the ones without an in-house
regulatory function buy tooling rather than build it.
```

**`subject` draws from the controlled vocabulary** — a fixed term list stored in the vault as
`_vocab.yml`, seeded from the `vocabulary.yml` reference that ships with this skill and
extended per engagement. The vocabulary reference is authoritative for the terms and for how
near-miss terms are detected; this schema only requires that the value be one of them.
A claim whose `subject` is absent from `_vocab.yml` is a lint failure, not a silent pass:
free-text subjects are the same as no subjects, because two researchers write
`wtp` and `willingness-to-pay` for the same thing and the collision that would have
surfaced their disagreement never happens.

**What the copy costs is drift, and the reconciliation is a Phase 0 report rather than a lint
check.** The lint reads the vault's `_vocab.yml` and never the shipped `vocabulary.yml` — a
vault has to stay checkable against the vocabulary it was written under, or an amendment to a
base term retroactively invalidates claims that were correct when they were filed. The price is
that an *amended* base definition never reaches an existing vault the way a *new* base term does:
the vault keeps the superseded wording indefinitely, every claim under that subject was written
against it, and nothing reports the divergence. So Phase 0 reports it, at the one moment both
files are open, and it reports a **version delta** rather than a diff of two wordings: the
shipped `vocabulary.yml` carries a `vocabulary_version` and an `amendments` log, so the founder
is handed the entries between the vault's stamp and the shipped one — per amended term, the
framing it carried (`was`), the framing it carries now (`now`), and the test each claim already
filed under it has to pass (`must_assert`). A report that only says the definitions differ names
no term and so asks for a corpus-wide re-read nobody can size. It is an advisory and does not
stop the run, because a vault written under an older definition is valid and only unreviewed, and
erroring on it would break every existing vault on upgrade. Reconciling is per claim and needs
judgement, and it ends in a **supersession** — two edits, per the rule above, with
`supersedes_reason` naming the amendment — never an edit in place, because a re-filed claim reads
as though it were written under wording its author never saw. The procedure, the worked example,
and the point at which the vault adopts the amended definition are in
[vault-migration.md](vault-migration.md#an-upgraded-vault-enters-here-not-at-stage-1--reconcile-the-claims-an-amended-definition-left-behind).

**`stale_after` is declared per claim and never derived from a pull date.** A vendor price
rots in a quarter; a founder's motivation does not; a regulatory deadline is fixed until it
moves. Deriving staleness from `pulled` plus a fixed window flags hundreds of durable claims
as stale and lets the fast-rotting ones sit unflagged for the same period — which trains
everyone to ignore the flag, and then it stops working for the claims that actually needed it.

**`used_in` is what gives a stale claim a blast radius that reaches a document.** Without it,
`stale_after` passing tells you a claim needs re-checking but not which paragraph of which
artifact is now standing on it — so the re-check gets deferred, because nobody can size it.
Write it when the claim is first cited; omit the key until then.

**`vault-lint.sh --used-in` is what keeps those entries honest.** It opens every target and
exits 1 when the document is missing (`used-in-missing-file`) or the `#anchor` names no heading
in it (`used-in-dead-anchor`) — the two ways a citation rots without anything else noticing, a
renamed document and a renamed section. The entry is written as the reader's own link,
`"business-plan.md#competition"`, resolved against the vault root and not against the note's own
directory. An entry with no `#` is checked for the file alone, which is the shape to use when a
claim reaches a document whose sections it does not name.

**`reconciled_sections` is what stops a claim being reconciled once and then quietly undone**, and
it is the half `--used-in` deliberately cannot reach. That mode asserts a citation *resolves*;
nothing asserted that a section still carries what it carried yesterday. Observed: a claim was
written into a plan section, satisfying invariant 20; a later re-solve rewrote that block; the
heading was untouched, so the citation still resolved and the gate stayed green while the section no
longer said what the note says. It was found by hand, days later — the exact failure invariant 20
exists to prevent, occurring **after** the invariant had been satisfied once, which is the case a
one-time check structurally cannot see.

**It is `reconciled:` itemised, not a second field beside it.** The date says a read happened; the
entries say what was read and what it looked like. One entry per `used_in` target whose `#anchor`
resolves, written as the entry followed by a space and the eight-hex content hash of that section.
`vault-lint.sh --claim-drift` recomputes each one and fails three ways: a hash the section no longer
matches (`section-hash-drifted`, which **re-opens** the claim), a resolving citation with no entry
(`section-hash-missing`, because a rule cleared by omission is not an exemption), and an entry naming
a target `used_in` does not (`section-hash-unused`, which reads as coverage to anybody counting
entries against citations).

**Nobody computes the hash by hand — the failure message carries it.** The lint has no write mode
by design, so re-reconciling is re-reading the section and pasting the token the failure printed;
pasting it is the assertion that the read happened, exactly as stamping a date is. The hash is over
bytes with trailing whitespace and blank-line runs normalised away, because all three are invisible
in a rendered document and a hash sensitive to them would re-open every claim in the corpus the
first time an editor trimmed a file.

**What a hash cannot say is that the section AGREES with the note.** That is the read invariant 19
owns, and no grep can do it — plan prose cites `[S#]` and `[F#]` codes while a claim carries no code
at all. What this adds is that the read cannot silently expire: a rewrite after the read is visible
from outside, instead of being a thing the conductor is trusted to notice.

**Both fields are `schemaVersion` 3 rules**, and that is the version's whole purpose here: every
claim in every finished corpus is already cited into a plan, so a rule demanding a recorded hash
from each of them would fail every existing vault on the day the plugin updates.
[vault-migration.md](vault-migration.md) carries the back-fill.

**Write the heading's explicit `{#anchor}`, because that is the half of the heading that does not
move.** A heading offers two addresses and the mode accepts either: the `{#anchor}` attribute at
the end of the heading line, and the GitHub slug of the heading text with that attribute stripped
off. Prefer the attribute. The plan's headings are action titles that assert the current finding,
so they are reworded every time the finding sharpens — and a citation written against the slug
dies on each of those edits, silently, leaving a rewrite of the notes as the only repair, which
re-breaks on the next one. The slug is still accepted so that a vault written before its plan
documents carried attributes keeps passing; nothing has to be back-filled. The templates that
ship the attributes are `plan-template.md`, and the contract itself — including why the slug of
a heading like `## Competition & moat` is not the anchor a human writes — is `rendering.md`. **The mode stops at whether the target resolves and never asks whether
the section carries the claim** — the prose cites `[S#]` and `[F#]` codes rather than note IDs,
so matching IDs against prose would report every correctly cited claim as broken. Whether the
section still agrees with the note is a read, not a grep, and `--supersession-sweep` is the mode
that bounds it: it names the sections a supersession put in doubt, so the read is over that list
rather than over every citation in the corpus.

**Before a render, all of them are one call: `vault-lint.sh --release-gate`.** It runs the bare
check, `--used-in`, the sweep, `--red-team`, `--roadmap-table` and `--binding-driver`, and exits
non-zero unless every part passes. The separate modes are still there and are what you reach for
mid-engagement — a citation question, a supersession question, a panel question, a roadmap question
and a question about the verdict drivers and the evidence under them are different questions — but
the gate before anything ships is one invocation with one verdict, because a set of invocations made
from memory is a set nobody can be held to. The bare run's own success line says as much: it reports
that the note-level checks passed and that the citation targets, the supersession blast radius, the
panel objection rows, the roadmap table and the verdict drivers and the evidence under them were
**not** opened.

### The assumption note is what you would believe with no evidence

```yaml
---
id: ASSUMPTION-MN66TT21     # required
type: assumption            # required
title: "Producers keep the tooling after the deadline they bought it for"   # required
status: unverified          # required
confidence: L               # required — authored; an assumption rests on nothing, which is what makes it one
created: "2026-03-15"       # required
value: "70% of accounts renew in the year after the deadline passes"   # required
sensitivity: high           # required — high | medium | low
validated_by:               # required — block list
  - QUESTION-DD31RR09
---

Nothing in the corpus speaks to post-deadline retention for a deadline-driven
purchase. The revenue model assumes it.
```

**`value` is the specific thing being assumed, not the topic.** "Retention is fine" cannot be
validated, so a validation step written against it will report success no matter what it
finds. A number or a falsifiable statement can be checked against a result.

**`sensitivity` records how far the plan moves if the assumption is wrong.** It is the field
that orders the validation queue: a Low-confidence assumption with `sensitivity: low` can wait
indefinitely, and one with `sensitivity: high` is the single most valuable thing to test next.
Without it every unverified assumption looks equally urgent, so they all get deferred equally.

**`validated_by` names the step that would settle it** — a `QUESTION-*` note when the test is
research, or a plan reference such as `"business-plan.md#milestone-2"` when the test is
shipping something and watching. An assumption with no validation step is a permanent
unverified belief that nothing will ever revisit, which is the state the field exists to
prevent.

**Two more fields hang off `model_input`, and they are what connect this note to the
projection.** An assumption that is an input to the financial model says so, in one of two words,
and either the model carries a row for it or the note says why not:

```yaml
model_input: revenue        # revenue | cost — those two words, and a third is not a value
excluded_from_model: "billed on a separate cycle, so it is modelled in the metered sheet"
```

**`model_input` declares that the projection has to carry a row for this note**, and
`vault-lint.sh --assumption-rows` reads that both ways against the assumptions table in
`financial-model.md`: a declared input with no row fails, and a row matching no note `title`
verbatim fails too. The match is the `title`, character for character, the same rule a
roadmap row is held to against a milestone `title` — [plan-template.md](plan-template.md) states
it as the contract the table is written under.

**A retired note is not a match, and that is a third failure rather than a looser rule.** The
title says the row was rendered off *some* note; only `status` says the ledger still stands
behind it. A live row in the assumptions table whose *every* matching note is `superseded` or
`retracted` fails as `model-row-dead-assumption`, naming the note it found and the status it
carries — the projection is resting on a value nobody is obliged to maintain, nothing orders it
in the validation queue, and because the title matched, every check stayed green. Observed as
exactly that: a live assumption row backed only by a superseded note, reported as *matched
verbatim* for days. The two repairs are point the row at the successor, or re-file the
assumption as `current` if it was retired in error.

**A live `claim` backs a row exactly as a live `assumption` does** — both assert a value, and what
disqualifies either is `superseded` or `retracted`. That is not a leniency; it is the promotion
rule stated from the model's side. A structural driver with no subject instrument belongs in the indexed set rather
than degraded to an assumption, so a sourced figure filed as unevidenced is the defect, and
correcting it retires the assumption and mints a `claim` carrying the same title. Read as a
question about the note's type, the check called that correction a defect: it reported the row's
only match as `superseded` with no `current` assumption behind it, which was true in both halves
while the row was backed the whole time by a `current` claim whose `used_in` named the
assumptions section directly. **The other direction did not widen**, and the asymmetry is
deliberate: `model_input` is a field an `assumption` carries, so a claim never becomes a declared
input and never owes a row on its own account.

**Those two types are the whole set, and a `fact` is deliberately not a third.** The other five are
out by argument rather than by omission: a `source` and a `fact` are the provenance a claim *rests
on* rather than a value the projection carries — [target.md](target.md)'s ladder puts a driver
value on a `claim` or an `assumption` and nowhere else — and a `milestone`, `question` or
`decision` asserts no value at all. So a figure quotable from one source with no inference belongs
in `facts/` **and** the claim that reads it into the model is what the row stands on. Filing the
model's input as a `fact` and pointing the row at it is the same defect one type over, and it
fails.

**The failure it prevents:** two assumptions
governing a whole revenue line existed as notes, correctly authored with subjects and confidence,
and were never added as rows — so the rule meant to keep every number traceable made that revenue
line structurally unable to enter the projection, the model filed it as revenue outside its scope,
and every verdict downstream inherited a denominator missing a line the roadmap ships. The notes
lint clean, the table lints clean, and nothing compared them.

**The enumeration is closed at `revenue` and `cost`, unquoted, the same rule `sensitivity` and
`driver_kind` are held to.** An unrecognised value is a note that declares nothing while reading
as declared, so the row it owes is never asked for — which is the same failure the field exists to
fix, reintroduced by a typo. `check` reports it as `model-input-unknown`.

**`excluded_from_model` is the other escape, and it is a reason rather than a flag.** A model may
legitimately leave a revenue line out — a metered layer must not be allowed to flatter subscription
churn — and stating why is what turns that from an omission into a decision. It clears the missing
row on its own. **What it does not clear is the identity**: where a `milestone`'s `moves` names this
note, the roadmap ships a dated change to a line the model has no row for, and the verdict note has
to name it in `arr_excludes` as well or the ARR term every corner is solved against is a subset
figure with nothing saying which subset. That rule and its cost are
[target.md](target.md#the-arr-term-declares-its-composition-or-the-exclusion-is-invisible)'s.

**Neither field is required, and the trigger is presence rather than `schemaVersion`** — both are
terms this release introduces, so no note in any existing corpus carries either and there is no
population an exemption would protect. The mode that reads the *table* is gated on `schemaVersion`
3, because it asks the document for something too and a corpus written before 3 was under no
contract that its rows are note titles.

**A value the indexed reference class can speak to is not believed with no evidence, so it is
not an `assumption`.** Where a **structural** driver has no subject instrument but
`research/growth-curves.md` indexes it at the month in question, its value is a `claim` resting
on that set — carrying the set's `stale_after` and a `validated_by` naming the kill test that
would overturn it. `assumption` is the **last** rung, for a value the reference class genuinely
cannot speak to. The ladder and the order it runs in are
[target.md](target.md#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative)'s;
a second copy here is a second source of truth nothing keeps in sync.

**The failure that misfiling causes:** invariant 11 caps a claim at its weakest input, so routing
the only legitimate evidence a pre-launch company has through an `assumption` makes every driver
weak by construction — and every plan for a company that has not launched then reads as
unjustified, which is every company at the moment the plan is worth writing.

### A target verdict is a claim carrying five more fields, not an eighth note type

A verdict on the founder's stated target, and a ceiling stated against that target, are one of the
two types above carrying a `subject` of `target-verdict` or `steady-state-ceiling`: an `assumption`
before the research that settles it, a `claim` after
([target.md](target.md#computing-a-verdict-the-checklist) step 12). Five further fields hang off
that **subject** rather than off the type, because one verdict is filed under both types inside a
single engagement — a rule keyed to `type: claim` would exempt every verdict written before the
research came back, which is every verdict at the point where a wrong one is cheapest to fix.

```yaml
subject: "target-verdict"     # or "steady-state-ceiling" — the subject is what these five belong to
binding_driver: "reach"       # the driver the identity solved for, in the words the plan uses
driver_kind: policy           # structural | policy | policy-within-band — those three words
conditional_on: "six hours a week across two channels"   # required when driver_kind is policy or policy-within-band
evidence_n: "2"               # distinct source notes reached under the binding driver
evidence_counterparties: "1"  # distinct counterparties among those sources
arr_excludes:                 # optional block list — the revenue lines the ARR term does not carry
  - ASSUMPTION-MN66TT21
```

**`arr_excludes` is optional and is deliberately NOT one of the five above** — the set-trigger
below is unchanged, so a note carrying it owes nothing extra and a note without it is complete. It
is here because it belongs to the verdict rather than to the model, and what it does is make the
identity's ARR term say what it does not include. An exit identity is `ARR at exit × multiple`, and [the
multiple's own driver table](target.md#the-multiples-inputs-have-homes-too-and-not-one-of-them-is-arr)
establishes that none of the multiple's inputs is ARR — so the ARR term is the one place the revenue
composition enters the identity, and it enters as a single number. The **included** side is already
enumerated as the rows of the assumptions table, so restating it here would be a second source of
truth nothing keeps in sync; the excluded side has no other home, and this is it.
`vault-lint.sh --assumption-rows` fails a line the roadmap ships a change to that the model has no
row for and no verdict note declares — the exclusion is allowed, the silence is not. **What it
cannot say** is that the exclusion is *right*: like `reconciled:`, it records that the decision was
stated, not that it was correct, and stating it is what makes it arguable by somebody who disagrees.

**`binding_driver` names the driver the identity solved for, and it is what gives the two counts a
scope.** *Distinct sources under the verdict* is most of the corpus; *distinct sources under the
binding driver* is a number worth printing. Left in prose the driver is a phrase inside a sentence,
so the counts beside it are over nothing in particular — and the binding driver **moves**, because
relieving reach usually makes price bind next
([target.md](target.md#a-binding-driver-that-is-policy-makes-the-verdict-conditional-not-negative)).
The field is therefore also the record of which driver the stored counts were taken under, which is
the half a re-run silently invalidates.

**`driver_kind` takes exactly three words — `structural`, `policy`, `policy-within-band` — and the
enumeration is closed.** Closing it is the point. Everything downstream branches on *policy or
not*: a policy-bound verdict owes a stated condition and a structural one does not. So an
unrecognised value takes the structural path by default and buys exactly the exemption invariant 18
exists to refuse, with a typo indistinguishable from a deliberate classification, and the plan
reports a founder's own decision as a category floor. The value is unquoted, the same as
`sensitivity` and `date_confidence` above: a closed word list gives a parser nothing to be wrong
about, which is the only question the coerce-nothing rule asks.

**`conditional_on` is required when `driver_kind` is `policy` or `policy-within-band`, and holds the
policy variable in the words the rendered plan uses.** Verbatim, because a later check matches this
string against the plan section the note's `used_in` names — the same rule `chosen` is held to
against `options`, and a milestone `title` against its roadmap row, for the same reason: where one
side renders off the other an exact match is a check, and anything looser is a similarity test that
cries wolf until somebody switches it off. **The failure:** *your target is unreachable* and *your
target is unreachable at six hours a week across two channels* are indistinguishable in a rendered
plan, at the same confidence letter, and only the second one is true. A `structural` verdict owes no
condition, because there is no choice to name — and that negative case carries as much weight as the
positive one, since a rule demanding a condition from every verdict would be met by inventing one.

**`evidence_n` and `evidence_counterparties` are what the verdict states about the evidence under
its binding driver** — distinct source notes reached through `rests_on`, and distinct
`counterparty` values among them under the fallback chain above. Both are quoted whole numbers, the
same rule `sequence` is held to, because a count that becomes a YAML integer stops being comparable
as the string every other query over this corpus compares. **Where the tail is thin, storing them is
half of what is owed and the rendered section carries the other half** — one line generated off these
two fields, `Evidence: 2 sources, 1 counterparty`, matched verbatim the way `conditional_on` is;
[plan-template.md](plan-template.md) carries the form. Counts that are right in the ledger and absent
from the plan leave the defect exactly where it was. **The failure:** the corpus knows the
tail is thin and the rendered figure does not say so. A verdict resting on two deals renders
identically to one resting on twenty, because `confidence` is a letter about the weakest link and
says nothing about how many links there are. The counterparty count is the half that cannot be
recovered from anything else the corpus records: three deals from one counterparty is one
relationship's terms reported as a market's, and a source count of three reads as the opposite.

**Any one of the five present makes the others owed.** `binding_driver`, `driver_kind`, `evidence_n`
and `evidence_counterparties` are owed unconditionally; `conditional_on` is owed on top of them
exactly when `driver_kind` is `policy` or `policy-within-band`. This is the rule the decision note's
brief fields are held to, one type over, and it is here for the same reason: a note carrying some of
them reads complete to every consumer, while the missing field is precisely the one that would have
qualified the number. A verdict naming its driver and labelling it `policy` with no counts is a
fully qualified finding to every reader and to every tool, and what it is not saying is that the two
deals underneath it came from one counterparty.

**The trigger is the `subject` and `schemaVersion` is not — and the two subjects are triggered
differently.** `target-verdict` is a term this release introduces, so no note in any existing corpus
carries it at any version: under that subject `binding_driver`, `driver_kind`, `evidence_n` and
`evidence_counterparties` are owed **whatever else the note carries** — a note carrying none of them
fails, and so does one carrying a partial set — with `conditional_on` owed on top of those four
exactly when `driver_kind` is `policy` or `policy-within-band`, per the rule above. `steady-state-ceiling` predates its 1.3.0 amendment and is `required: true`,
so every vault already holds one: there the trigger is **field presence** — a ceiling claim carrying
none of the five owes none of them, and carrying any one owes the set.

**The asymmetry is the point, not an inconsistency to be tidied away later.** What field presence
buys is an exemption for notes written before the fields existed, and only the ceiling half has such
notes to exempt. Extending the same leniency to the verdict half would pay an exemption's whole cost
over an empty population, and that cost is exact: omitting `binding_driver` would become the
cheapest way past every rule below that reads the note. **A dodge available by omission is not an
exemption.** `--red-team` checks its roster in both directions for this reason — with only the
forward check, the cheapest way past a lens that returned nothing is to delete it from the roster.

**This is still the exemption the version field exists to provide, obtained without spending a
version on it**, and the split makes that argument stronger rather than weaker: a check firing
unconditionally over a subject no older vault can carry fails nothing, while one firing
unconditionally over every subject fails every vault authored before it on the day the skill
updates, which is how a gate stops being run.

**A verdict that reaches the plan without ever reaching the ledger is the last hole, and
`verdict-unfiled` closes it.** Everything above presumes a note exists. Nothing yet stops the verdict
sentence being written straight into `business-plan.md` under the `{#target-verdict}` anchor with no
note behind it at all — and `target-verdict` is `required: false`, so the coverage query does not ask
for one either. What that costs is every property the ledger exists to give a number: no `rests_on`,
so no confidence derivation and no cap; no `stale_after`, so nothing ever comes up for re-checking;
no supersession when the target is renegotiated, so the superseded finding is simply overwritten; and
`--supersession-sweep` cannot name the section when something under it moves, because nothing records
that the section was ever standing on anything. It is the one output of this skill most likely to
make a founder stop, held to less than a sourced market-size figure. The check is `--roadmap-table`
inverted — that mode fails milestone notes with no `business-plan.md` to render them, and this fails
a rendered section with no note behind it. **What triggers it is a non-empty section at the anchor
and never a reading of the prose inside it**, for the same reason `conditional_on` is matched
verbatim: a check that infers a verdict from sentence shape cries wolf, and a check that cries wolf
gets switched off.

**Seven rules stand on these fields, and every one of them fails rather than printing a worklist.**
Unlike `--supersession-sweep`, a thin tail nobody surfaced is not the corpus working.

| rule | mode | what fires |
|---|---|---|
| the five fields are a set | `check` | `verdict-fields-incomplete` on a note carrying some of them |
| `driver_kind` is one of three words | `check` | `driver-kind-unknown` on a fourth |
| a policy-bound verdict states its condition | `--binding-driver` | `verdict-unconditional` where `conditional_on` does not appear in the plan section `used_in` names |
| the plan's `Kind` column renders off the note | `--binding-driver` | `verdict-kind-mismatch`, both directions — a cell hand-edited to `structural` is otherwise the cheapest way past the row above |
| the evidence under the binding driver is surfaced | `--binding-driver` | `verdict-thin-evidence` where the closure reaches under three distinct sources, or one counterparty, and either the note's counts are not what the closure holds or the rendered section does not carry the line they generate |
| the plan's verdict is filed as a note | `--binding-driver` | `verdict-unfiled` — a `business-plan.md` carrying a non-empty section at the `{#target-verdict}` anchor with no `claim` or `assumption` under `subject: target-verdict` behind it |
| the ARR term declares what it leaves out | `--assumption-rows` | `excluded-line-on-roadmap` — an assumption carrying `excluded_from_model` that a `milestone`'s `moves` names, and that no verdict note lists in `arr_excludes`. Gated on `schemaVersion` 3 |

### The question note records the gap, not the answer

```yaml
---
id: QUESTION-DD31RR09       # required
type: question              # required
title: "Do buyers keep compliance tooling after the deadline that triggered the purchase?"   # required
status: current             # required
confidence: M               # required — confidence that this is the right question, not that it is answered
created: "2026-03-15"       # required
gaps:                       # required — block list; what is missing, and therefore why this is open
  - "No renewal data for any comparable deadline-driven tool"
  - "No pricing signal for the post-deadline year"
covers:                     # required once anything answers part of it; omit while empty
  - CLAIM-AS23SD44
killed_because: "..."       # optional — set when the hypothesis is ruled out
---

Open. Directly determines whether the revenue model is a one-year spike or a base.
```

**`gaps` is required and is the substance of the note.** A question recorded as a question
alone is a topic; the list of what is specifically missing is what makes it researchable and
what tells you when it is closed. It is also what an outline check reads to find a section
resting on nothing.

**`confidence` on a question means confidence in the framing.** A Low here says the question
needs reframing before anyone spends research budget against it — which is cheaper to notice
now than after a week of work answering the wrong question well.

**`killed_because` retires a ruled-out hypothesis without deleting it.** Set it and flip
`status` to `retracted` in the same edit. Deleting the note instead is how the same
hypothesis gets re-proposed two months later with nothing recording that it was already
tested and failed.

### The decision note keeps the rejected options and the reopen trigger

```yaml
---
id: DECISION-VV02HH55       # required
type: decision              # required
title: "Sell direct to producers before building the distributor channel"   # required
status: current             # required
confidence: M               # required — derived, same rule as a claim
confidence_own: H           # required
created: "2026-03-16"       # required
options:                    # required — block list, every option considered, rejected ones included
  - "Direct to producers"
  - "Through the two national distributors"
  - "Both, distributor-first"
chosen: "Direct to producers"   # required — verbatim match of one entry in options
reasoning: |                    # required
  The deadline window is 12 months and distributor onboarding has historically
  taken two quarters, so the channel would arrive after the window it exists to
  serve. Direct is slower per account and available now.
reopen_if: |                    # required
  The deadline is extended, or direct acquisition cost per account exceeds the
  first-year contract value for two consecutive quarters.
rests_on:                       # required — block list, the claims the decision stands on
  - CLAIM-AS23SD44
---

Chosen on timing, not on economics. The channel is not rejected, only deferred.
```

**`chosen` must match an entry in `options` verbatim.** A `chosen` value that paraphrases one
of the options makes the rejected set unreadable later, and reading the rejected set is the
entire reason to record it: "we already considered that and here is why not" is the answer to
the question that comes back in three months.

**`reopen_if` is required because a decision without a trigger is indistinguishable from a
decision nobody may revisit.** The record then gets ignored rather than re-checked, and the
plan carries a choice made under conditions that stopped holding.

**`rests_on` on a decision is what makes the chain end somewhere useful.** It is the edge that
turns "this source was amended" into "this decision should be re-taken", which is the only
version of blast radius anyone acts on.

### The milestone note carries a position, a cost, and the assumption it moves

```yaml
---
id: MILESTONE-PJ40XR63      # required
type: milestone             # required
title: "Unassisted setup for the core job ships"   # required
status: current             # required
confidence: M               # required — derived, same rule as a claim
confidence_own: M           # required
created: "2026-03-16"       # required
sequence: "4"               # required — quoted whole number; the orderable position
date_stated: "≤6mo"         # optional — verbatim, exactly as the founder said it
date_confidence: stated     # required — stated | derived | none
depends_on:                 # optional — block list of MILESTONE- IDs
  - MILESTONE-RB18KC02
moves:                      # required — block list; the notes this item changes
  - ASSUMPTION-MN66TT21
resource: founder-hours     # required — the constrained resource it consumes
rests_on:                   # required — block list, what the item stands on
  - CLAIM-AS23SD44
used_in:                    # required once the item appears in a rendered roadmap
  - "business-plan.md#roadmap"
  - "research/timeline.md"
---

Ships the unassisted path for the core job. Until it lands, every account is set
up by hand, which is what caps how many the founder can take.
```

**`sequence` is the orderable field; `date_stated` is verbatim and nothing compares it.** A
founder says "≤6mo" and the ledger records that, not a date nobody stated. So `sequence` is a
quoted whole number and every order check runs on it, while `date_stated` holds whatever phrase
was actually said — including one that is not a date at all. Writing a month into `date_stated`
that the founder never gave is the failure this split prevents: it reads back six months later
as a commitment, at the same confidence as one they made.

**`date_confidence` is required even when there is no date**, and `none` is the value that says
so. An absent field is indistinguishable from a forgotten one, so without a positive record a
skill-derived month and a founder-stated month become the same string on the page — and the
derived one gets quoted back in a meeting.

**`moves` names note IDs, never the roadmap table's `A-n` row labels.** The plan's assumptions
table keeps its prose labels for a reader; the note-level edge names the note. That is what makes
"every roadmap item names the assumption it moves" mechanical rather than a rule nobody verified,
and it is checked in both directions because an item can name a wrong assumption two ways: a
well-formed ID that no note carries is the ordinary `dangling-edge` failure, and a value that is
not an ID at all — the `A-n` row label, copied across from the table — is `malformed-edge`. The
second is the one authors actually write, since the table is where they look before writing the
note, and it is why the row label is worth naming here rather than leaving to the lint. Where an
item aims at a multiple input rather than a model assumption
([roadmap-sequencing.md](roadmap-sequencing.md#rule-7--for-an-exit-target-an-item-may-move-a-multiple-input-rather-than-a-model-assumption)
Rule 7), it names the `claim` carrying that input.

**`resource` is the field that makes resource-independence checkable.** Two items compete only if
they consume the same constrained resource — founder hours, capital, a hire that has not
happened, someone else's clock. Asserted in prose, that rule is skipped; recorded per item, two
milestones declaring the same `resource` at the same `sequence` are a *false independence* claim
the lint fails. The cost of not catching it is the whole roadmap: a false independence claim
licenses a naive value ranking, orders everything downstream of it, and nothing ever revisits it.

**`title` is the key the plan's roadmap table is matched on, verbatim.** The table renders
`sequence`, `moves` and `resource` off these notes, so its item cell is this `title` character for
character — which is what lets `vault-lint.sh --roadmap-table` read the two against each other
both ways with no ID column in the plan and no fuzzy comparison anywhere. It is the same rule
`chosen` is held to against `options` above, for the same reason: a row that paraphrases its note
has stopped being a rendering of it, and nothing else in the corpus can tell. **Reword the title
and the row together, or neither** — a note whose title moved alone is reported as a milestone the
plan never lists, and its old row as an item that escaped the ledger.

**Five things the lint reads off this type**, each the mechanical form of a rule that was prose:
`required-field` on a missing `moves` or `resource`, `dangling-edge` on a `moves` or `depends_on`
target that no note carries, `malformed-edge` on a `moves` value that is not a note ID at all,
`dependency-after-dependent` where a prerequisite sequences at or after the item needing it, and
`false-independence` on the shared `resource` and `sequence` pair.
`sequence-not-orderable` guards the two order checks themselves: both skip a value they cannot
compare, so a `sequence` of `M4` would take them down silently. `--roadmap-table` is the seventh
and the only one that leaves the note directories, since the other half of what it compares is a
document. All of them fire only at
`schemaVersion: 2` — a vault at 1 has no `milestones/` directory by construction and owes none of
them.

## Confidence is derived wherever a note rests on something

Confidence is `H`, `M`, or `L`, ordered `L < M < H`.

```
confidence = min(confidence_own, confidence of every note in rests_on)
```

**Write `confidence_own` if and only if the note has `rests_on`.** On a note with no
`rests_on` — a source, an assumption — `confidence` *is* the authored assessment and no
second field exists. On a note with `rests_on` — a fact, a claim, a decision — `confidence` is
the derived value and `confidence_own` is the assessment the derivation consumes.

Worked, using the notes above:

| note | `confidence_own` | rests on | their confidence | stored `confidence` |
|---|---|---|---|---|
| `SOURCE-K92MZ1QA` | — | — | — | `M` (authored) |
| `FACT-GF45SD01` | `H` | `SOURCE-K92MZ1QA` | `M` | `M` = min(H, M) |
| `CLAIM-AS23SD44` | `H` | `FACT-GF45SD01`, `FACT-QP81ZZ07` | `M`, `H` | `M` = min(H, M, H) |
| `DECISION-VV02HH55` | `H` | `CLAIM-AS23SD44` | `M` | `M` = min(H, M) |

**The failure this prevents:** without propagation, a Low-confidence finding becomes an
unqualified headline. Someone reads a hedged source, writes a fairly confident fact from it,
writes a confident claim from the fact, and by the third hop the hedge is gone — every step
locally reasonable, the result asserted flatly in a document a stranger will act on. `min`
means the weakest link in the chain is what the chain reports, so the hedge cannot be lost by
paraphrase.

**The derived value is stored in the file, not computed at read time**, and a checker verifies
it matches. Storing it means one grep answers "what is this claim's confidence" with no graph
walk — which matters because the consumers are shell tools and a human reading one file. It
also survives a corpus you cannot fully walk: if a `rests_on` target has been deleted, the
stored value still says what the claim was worth when it was written, and the checker reports
the dangling edge rather than silently recomputing over the notes that happen to remain.

**Raising `confidence_own` does not raise `confidence`** while a weaker note is underneath.
The only way to raise a derived confidence is to strengthen or replace what it rests on.

## Contradiction is a subject collision, not an edge

Two `current` claims sharing a `subject` are a **collision**, and a collision is where a
contradiction, a duplicate, or a missing `scopes` edge is hiding. Finding them is mechanical:

```sh
grep -rh '^subject:' "$VAULT_PATH/claims" | sort | uniq -d
```

Every duplicated subject is a pair to read. The resolution is always one of three edits:
supersede one side, add a `scopes` edge because one is narrower, or discover the two
genuinely disagree and go settle it.

**The failure this prevents:** two research files disagreeing about the same number, with
nothing surfacing the conflict. Noticing it depends on one person happening to have read both
files closely enough to remember the figure — which does not scale past a corpus one person
can hold. A controlled subject vocabulary turns "did anyone notice" into a sort and a
`uniq -d`, and makes disagreement mechanical rather than lucky.

This is also why free-text subjects fail: the collision only fires when two researchers spell
the subject identically, and left to themselves they will not.

## Status moves in one direction and never silently

| status | means | set when |
|---|---|---|
| `unverified` | asserted, nothing behind it yet | an assumption is written, or a claim is drafted ahead of its evidence |
| `current` | live, and everything under it is live | evidence is in place and the chain is clean |
| `needs_review` | a trigger fired; the assertion may be stale | `stale_after` passed, or something in `rests_on` changed status |
| `superseded` | replaced by a specific newer note | a replacement note names it in `supersedes` |
| `retracted` | withdrawn, and nothing replaces it | shown to be wrong, or a hypothesis is killed |

**`needs_review` propagates along `rests_on`, the same direction as confidence.** When a note
becomes `needs_review`, `superseded`, or `retracted`, every note resting on it is a review
candidate. The propagation is a review queue, not an automatic rewrite: the checker lists the
dependents and a human decides. Automatically flipping the whole subtree would put documents
into review over a change that did not touch what they actually used, and a review queue that
is mostly noise gets ignored.

**Retraction is visible, never silent.** A retracted note stays in the vault with
`status: retracted` and its reason. Deleting it instead breaks every `rests_on` that pointed
at it into a dangling edge with no explanation, and the assertion reappears two drafts later
with nothing recording that it died.

## Layout: one directory per type, one file per note

```
<user-vault>/                     # e.g. ~/Documents/go-to-market/<product-slug>/
  .vault/                         # THE ENGAGEMENT FOLDER IS THE VAULT — no `vault/` subdir
    config.json                   # schemaVersion — the migration gate
  sources/
    SOURCE-K92MZ1QA.md
  facts/
    FACT-GF45SD01.md
  claims/
    CLAIM-AS23SD44.md
  assumptions/
    ASSUMPTION-MN66TT21.md
  questions/
    QUESTION-DD31RR09.md
  decisions/
    DECISION-VV02HH55.md
  milestones/
    MILESTONE-PJ40XR63.md
  _vocab.yml                      # the controlled subject vocabulary
  research/                       # ALL prose, untouched by the vault — dimensions, profiles,
    timeline.md                   #   the founder brief and the product dossier. timeline.md is
                                  #   the exception: GENERATED from milestones/, never hand-edited
  sources.md                      # the [S#] index
  one-pager.md  business-plan.md  # plan documents — the lint ignores non-note files at the root
```

**The boundary is the engagement folder, and that is load-bearing rather than cosmetic.** A
source with no public URL carries a *vault-relative* path, so anything a `source` note rests on
must be inside the vault or the path resolves to nothing — with no error, because a missing file
is not a malformed field. Research prose is exactly such a source: a competitor ledger or a
dimension file frequently *is* the evidence. Put the vault one level down and
`research/competitors.md` reads as vault-relative, resolves nowhere, and lints clean.

It is also what makes the corpus **portable**. Copy the folder and every citation, every
`rests_on` edge and every research file travels with it. A ledger whose evidence lives outside
it is an index, not a ledger.

**The filename is exactly the ID plus `.md`. No slug, no title, no date.**

The failure a slug would cause: it is a second title, and it goes stale the moment the note's
`title` is edited — after which the filename asserts something the note no longer says.
Worse, two notes about the same topic acquire near-identical filenames and read as duplicates
of each other in a file listing. With a bare ID, "find the file for this ID" and "grep for
this ID" are the same operation, and there is exactly one authoritative title, in the
frontmatter, where both Obsidian and grep can see it.

**The vault lives in the user's own directory and never in this repo.** The skills are
public; a corpus of claims about someone's business is not. Nothing in this repository
scaffolds, contains, or ships a vault — the tools take a path and operate on it.

## Locate the vault explicitly and never search upward

Resolution order, and it is short:

1. An explicit `--vault <path>` argument.
2. The `VAULT_PATH` environment variable.
3. Nothing. Refuse, and name both options in the error.

**No upward search from the working directory.** Unlike `git` or a Zettelkasten tool, you are
never *inside* the vault when you use it — you are in a code repository, or in a conversation
with no working directory that means anything. An upward search from a repo therefore walks
to the filesystem root and finds nothing, producing a confusing error far from its cause, or
finds something worse: a `.vault` in a shared parent directory belonging to a different
engagement, at which point claims are read from and written into the wrong corpus with no
error at all. Refusing without an explicit path costs one flag and removes the entire class.

## schemaVersion refuses what it does not understand

```json
{
  "schemaVersion": 3,
  "created": "2026-03-14"
}
```

`schemaVersion` is a required integer, incremented only on a change that would make an older
tool misread an existing vault. `created` is optional. The file is JSON, not YAML, so the
coerce-nothing rule does not apply to it — JSON has unambiguous types. **The current version is
3**; a new vault is scaffolded at it.

**The tool reads a SET of versions, not one.** `vault-lint.sh` reads `1`, `2` and `3`. A vault at
1 gets exactly the behaviour it has always had, a vault at 2 additionally gets the checks version 2
added, and a vault at 3 gets those plus the checks version 3 added — each enumerated in its own
table below. A vault at 1
has no `milestones/` directory by construction, so it cannot owe any of the milestone rules; one
that has grown the directory without moving its version is told so by `type-agreement` rather
than having its notes read in silence. That set is what makes the version a real extension point rather than a number
nobody may move: a new check that an existing corpus could not possibly satisfy goes in behind a
version, so upgrading the tool never turns a finished corpus red. A check written to fire
unconditionally has the opposite property — every vault authored before it fails on the day the
skill updates, which is how a gate stops being run.

**What version 2 adds**, each behind the version for the same reason — the field it asks for did
not exist when a version-1 corpus was written:

| rule | mode | what fires |
|---|---|---|
| the `milestone` type | `check` | `required-field` on its own fields, and `dangling-edge` through `moves` and `depends_on` |
| roadmap order | `check` | `dependency-after-dependent`, `false-independence`, and `sequence-not-orderable` |
| `reconciled:` on a supersession | `--supersession-sweep` | a note carrying `supersedes` with no `reconciled:` date, or one earlier than that note's own `created` |
| the lens roster | `--red-team` | a `red-team.md` carrying no `## Lenses dispatched` roster |
| the roadmap table renders this set | `--roadmap-table` | a roadmap row whose item cell matches no milestone `title` verbatim, a milestone the table never lists, and milestones with no `business-plan.md` to render them |
| the monitoring plan names axes | `--monitoring` | a `## Monitoring plan` section carrying prose and no axis table, and a row leaving the instrument, the cadence or the decision it would change empty |

**What version 3 adds**, on the same terms, and both rules read a field no corpus written before
this release can carry:

| rule | mode | what fires |
|---|---|---|
| the assumptions table renders the declared inputs | `--assumption-rows` | a declared `model_input` with no row and no `excluded_from_model`, a row matching no `assumption` `title` verbatim, declared inputs with no table to render them, and a line excluded from the model that the roadmap ships a change to and no verdict note lists in `arr_excludes` |
| a cited section still carries what it carried | `--claim-drift` | a `reconciled_sections` hash the section no longer matches, a resolving citation with no entry recording it, and an entry naming a target `used_in` does not |

**What no version gates**, because each fires on the presence of a field rather than on a rule
every corpus would suddenly owe — which is the exemption `schemaVersion` exists to provide,
obtained without spending a version:

| rule | mode | what fires |
|---|---|---|
| a supersession is written from both ends | `--supersession-sweep` | `superseded-by-unreciprocated` — `superseded_by` naming a note that does not list it in `supersedes`; and `superseded-by-dangling` — `superseded_by` naming an ID no note carries |
| a model row stands on a live note | `--assumption-rows` | `model-row-dead-assumption` — a row whose every `title` match, `assumption` or `claim`, is at `status: superseded` or `retracted` |

**`model-row-dead-assumption` and `model-row-no-assumption` are named narrower than the rule they
now read, and the names stay.** Both cover a `claim` carrying the row's title as well as an
`assumption`, because what backs a row is `status` rather than which asserting set holds the note.
The codes are the string a `--json` consumer keys on, so renaming them to match would break every
caller pinned to them to buy nothing but a tidier word — and the repair the names point at is still
the right one, since a row with nothing behind it is missing the `assumption` note the table
renders inputs off.

**Version 3's cost to an existing corpus is a back-fill and nothing else**, and it is bigger than
2's: every claim in a finished corpus is already cited into a plan, so moving to 3 means re-reading
each cited section and recording its hash. That is the read invariants 19 and 20 already require,
made visible — which is the point, and also the reason the version exists rather than the rule
firing unconditionally. [vault-migration.md](vault-migration.md) carries the procedure.

**Each of these tables is the only enumeration of its version's set** — the paragraph above points
at them rather than restating them, because a version that adds a rule in one release and a second
in the next ends up with two lists, one of which is quietly short. A short list of what a version
costs is worse than no list: it reads as complete.

**Neither `--binding-driver` nor `--deliverable` is a row in it**, and in both cases the omission is
the design rather than a gap in the list. `--deliverable` reads `deliverables/*.html`, so its
trigger is a rendered file rather than a version: a vault that has rendered nothing owes it nothing
at any version, and a vault that has rendered something owes it at every version, because a note ID
resolves to nothing for that reader whenever the corpus was written. Its four rules are triggered by a note's `subject`, or by the plan section a verdict
renders into, never by a version — so a corpus written before those fields existed owes nothing at
either `1` or `2` and needs no exemption bought with a version — the fields and the argument are
[above](#a-target-verdict-is-a-claim-carrying-five-more-fields-not-an-eighth-note-type). A row here
would assert the opposite, and the lint would then disagree with the schema about which vaults the
mode applies to, in the direction where the schema reads stricter than the tool.

`--claim-drift` and the last two version-2 rows are checks on a *record of a read* rather than on the
read itself, which is the only shape a mechanical check over a judgment step can take. The two directions `--red-team` checks
against an existing roster — a rostered lens with no rows, a row from an unrostered lens — are not
gated on the version: a roster is a version-2 artifact, so a vault carrying one meant to.

**A tool that finds a `schemaVersion` it does not understand refuses and exits non-zero**,
printing the version it found and the version it supports. It does not guess, and it does not
process the parts it recognises. This is the same gate as `core.repositoryformatversion` in
git, and for the same reason: a newer vault half-read by an older tool returns a clean bill of
health while silently ignoring every field the newer schema added — and a green result is
exactly what somebody acts on. Refusing is the only safe response to a version from the
future.

**A directory with no `.vault/config.json` is not a vault.** Refuse rather than treating an
arbitrary directory of Markdown as one, which is how a tool ends up walking someone's notes
app.

**Migrations are forward-only.** There is no downgrade path, because writing one means
supporting every field the newer schema added in a shape the older one can hold, which is a
second schema maintained forever. The migration procedure lives in the
[vault-migration.md](vault-migration.md) reference alongside this file.

## The queries this schema exists to make trivial

Every one of these is a shell one-liner over the corpus, which is the test the schema was
designed against — a structure that needs a program to answer its own core questions is a
structure people stop maintaining.

```sh
# Blast radius: everything that references this note, in any edge, in any direction.
grep -rl -- 'FACT-GF45SD01' "$VAULT_PATH"

# Every claim a given rendered section stands on.
grep -rl -- 'business-plan.md#why-now' "$VAULT_PATH/claims"

# Subject collisions: candidate contradictions and duplicates.
grep -rh '^subject:' "$VAULT_PATH/claims" | sort | uniq -d

# Duplicate sources two researchers cited independently.
grep -rh '^url_canonical:' "$VAULT_PATH/sources" | sort | uniq -d

# Everything asserted with no evidence behind it.
grep -rl '^status: unverified' "$VAULT_PATH"

# Every claim whose stale_after has already passed. Quoted ISO dates sort as
# strings, so this needs no date parsing — one of the things coercing nothing buys.
grep -rH '^stale_after:' "$VAULT_PATH/claims" | awk -F'"' -v today="$(date +%F)" '$2 < today'

# Inline flow lists, which should never exist.
grep -rnE '^[a-z_]+: \[' "$VAULT_PATH"
```

Whole-corpus aggregation — required-field checks, confidence-propagation violations, dangling
`rests_on` targets, near-miss vocabulary terms, and the `used_in` targets `--used-in` opens —
belongs to the lint, not to the agent. Code is reliable at counting; an agent is reliable at
authoring one good note. Splitting them that way is what keeps both honest.

## A session invokes whichever script its shell tool can run

The lint ships from this repository's `bin/` directory as two implementations held to
identical output by a JSON parity gate: `vault-lint.sh` for a session with the Bash tool,
`vault-lint.ps1` for a session that has only the PowerShell tool — native Windows with no
Git for Windows installed, where there is no `sh` to run the first one with, so it is not a
script that fails there but a command that does not exist. Claude Code puts `bin/` on
whichever shell tool the session actually has, so pick the extension that tool runs — never
`.sh` from habit — and invoke it bare either way, never by path. Every mention of
`vault-lint.sh` elsewhere in this skill names a mode, not a platform, and carries over to
`vault-lint.ps1` unchanged; this is the one place the choice itself gets made.

## A worked chain from source to decision

The notes above form one chain. Read end to end, it is the argument the vault is making:

```
SOURCE-K92MZ1QA   the revision text, quoted verbatim              confidence M
      ↑ rests_on
FACT-GF45SD01     the deadline is 1 January 2027                  own H → M
      ↑ rests_on
CLAIM-AS23SD44    the deadline opens a 12-month buying window     own H → M
      ↑ rests_on                                                  subject: timing-window
DECISION-VV02HH55 sell direct before building the channel         own H → M
                                                                  reopen_if: the deadline moves
```

Alongside it, unattached to the chain by `rests_on` and deliberately so:

```
ASSUMPTION-MN66TT21  70% renew after the deadline    sensitivity high, unverified
      ↓ validated_by
QUESTION-DD31RR09    do deadline-driven buyers keep the tool?     gaps: no renewal data
```

Now suppose the regulator extends the deadline. One edit to `SOURCE-K92MZ1QA` — a replacement
source note that supersedes it — and:

- `grep -rl -- 'SOURCE-K92MZ1QA' "$VAULT_PATH"` returns the fact that rests on it.
- The fact's status goes to `needs_review`, which puts the claim in the review queue.
- The claim's `used_in` names the two documents carrying it, so the edit has a known scope
  before anyone opens a file.
- The decision's `reopen_if` says in the founder's own earlier words that this is the trigger
  to re-take it.

None of those steps required anyone to remember anything. That is the whole point: the
corpus can tell you what it no longer knows.

## Writing a note: the six-step checklist

1. **Pick the type** using the sharp lines above. If it fits two, it is two notes.
2. **Generate the ID**: `LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8; echo`, prefixed
   with the uppercased type. Do not look anything up; there is no registry.
3. **Write the file** at `<type-plural>/<ID>.md`, with the six common fields plus that type's
   required fields. Block lists only. Quote every date, and quote anything containing `: `.
4. **Set the edges**: `rests_on` for a fact, claim, decision or milestone; `validated_by` for an
   assumption; `moves` and, where there is a prerequisite, `depends_on` for a milestone. Omit a
   key rather than writing an empty list.
5. **Derive `confidence`** where the note rests on something: `min(confidence_own, every
   rests_on target)`. Write both fields.
6. **Run the lint** before considering the note done. It catches the missing required field,
   the unknown subject term, the dangling edge, the duplicate source, and the propagation
   violation — all of which are silent in the file itself.
