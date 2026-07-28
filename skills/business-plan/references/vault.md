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
- [Six edges, each stored once on the asserting note](#six-edges-each-stored-once-on-the-asserting-note)
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

## Six edges, each stored once on the asserting note

| edge | meaning | written on |
|---|---|---|
| `rests_on` | this note depends on these; the blast-radius edge | the dependent note |
| `supersedes` | this note replaces that one, with `supersedes_reason` | the replacement |
| `scopes` | this narrows that one — not a contradiction, not a supersession | the narrower note |
| `validated_by` | this assumption is tested by that validation step | the assumption |
| `depends_on` | this milestone cannot land until that one has | the later milestone |
| `moves` | this milestone changes the value that note asserts | the milestone |

All six are block lists of IDs.

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

Three more fields are available on **any** type, used together:

```yaml
supersedes:                          # optional — block list
  - CLAIM-QQ19PL30
supersedes_reason: "The vendor republished the list; the earlier figure was a promotion."   # required with supersedes
reconciled: "2026-07-10"             # required with supersedes at schemaVersion 2 — quoted ISO date
```

**`supersedes` without `supersedes_reason` is rejected.** A replacement with no reason cannot
be evaluated later — the only question anyone asks about a superseded note is why, and the
person who knew is gone. And writing `supersedes` **without flipping the target's `status` to
`superseded`** leaves two `current` notes asserting different values on the same subject,
which is indistinguishable from an unresolved contradiction to both the checker and a reader.
Supersession is always two edits, and `reconciled:` below is what closes it out.

**Both those edits land in the vault, and the documents the old note reached hear nothing.** That
is the third cost of a supersession: a superseded claim that was cited into three plan sections
leaves those three sections asserting the old value, with `status: superseded` sitting in a file
nobody rereads. `vault-lint.sh --supersession-sweep` is what says so out loud — it walks every
superseded note, unions the `used_in` targets behind them, and prints one row per document
section with the notes that reached it, their replacements and each `supersedes_reason`. One row
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
check, `--used-in`, the sweep, `--red-team` and `--roadmap-table`, and exits non-zero unless every
part passes. The
separate modes are still there and are what you reach for mid-engagement — a citation question,
a supersession question, a panel question and a roadmap question are different questions — but the
gate before
anything ships is one invocation with one verdict, because a set of invocations made from memory
is a set nobody can be held to. The bare run's own success line says as much: it reports that the
note-level checks passed and that the citation targets, the supersession blast radius, the
panel objection rows and the roadmap table were **not** opened.

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
  "schemaVersion": 2,
  "created": "2026-03-14"
}
```

`schemaVersion` is a required integer, incremented only on a change that would make an older
tool misread an existing vault. `created` is optional. The file is JSON, not YAML, so the
coerce-nothing rule does not apply to it — JSON has unambiguous types. **The current version is
2**; a new vault is scaffolded at it.

**The tool reads a SET of versions, not one.** `vault-lint.sh` reads both `1` and `2`. A vault at
1 gets exactly the behaviour it has always had, and a vault at 2 additionally gets the checks
version 2 added, enumerated in the table below. A vault at 1
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

**This table is the only enumeration of the set** — the paragraph above points at it rather than
restating it, because a version that adds a rule in one release and a second in the next ends up
with two lists, one of which is quietly short. A short list of what a version costs is worse than
no list: it reads as complete.

The last two are checks on a *record of a read* rather than on the read itself, which is the only
shape a mechanical check over a judgment step can take. The two directions `--red-team` checks
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
belongs to `vault-lint.sh`, not to the agent. It ships from this repository's `bin/` directory,
which Claude Code puts on the Bash tool's `PATH`, so it is invoked bare from wherever you are.
Code is reliable at counting; an agent is reliable at authoring one good note. Splitting them
that way is what keeps both honest.

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
