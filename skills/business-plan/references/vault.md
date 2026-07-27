# The vault schema — notes, IDs, edges, and the invariants that keep them greppable

The vault is the claim ledger the skill maintains alongside a plan: every load-bearing
assertion as an atomic note, addressed by ID, with the dependency edges that let you ask
what a corpus no longer knows. It lives in the user's own directory, never in this repo.

This file is the schema. It is the one document every other part of the vault work
references, so it is written to be sufficient on its own: a reader who has only this file
can write a valid note of any of the six types, place it correctly, and know which fields
they may not omit.

## Contents

- [The vault is a claim ledger over the prose](#the-vault-is-a-claim-ledger-over-the-prose)
- [Six note types, and the taxonomy stops there](#six-note-types-and-the-taxonomy-stops-there)
- [An ID is an address, not a label](#an-id-is-an-address-not-a-label)
- [Four edges, each stored once on the asserting note](#four-edges-each-stored-once-on-the-asserting-note)
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

## Six note types, and the taxonomy stops there

| type | asserts | lives in |
|---|---|---|
| `source` | this material exists and says this, verbatim | `sources/` |
| `fact` | this value is stated directly by a source | `facts/` |
| `claim` | the analysis asserts this, beyond what any one source says | `claims/` |
| `assumption` | this is believed with no evidence behind it | `assumptions/` |
| `question` | this is not known, and here is the gap | `questions/` |
| `decision` | this option was chosen over these, for this reason | `decisions/` |

**Resist adding a seventh.** Comparable prior-art projects define ten or twelve page types,
and past about six the taxonomy becomes ceremony: authors stall choosing between two types
that differ only in emphasis, pick inconsistently, and the query that depends on the type
being right returns a partial answer. Structure that does not fit a type belongs on an
**edge**, not in a new type.

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

## An ID is an address, not a label

Every note has an ID of the form `TYPE-xxxxxxxx`: the uppercased type, a hyphen, and eight
random characters from `A-Za-z0-9`.

```
SOURCE-K92MZ1QA    FACT-GF45SD01    CLAIM-AS23SD44
ASSUMPTION-MN66TT21    QUESTION-DD31RR09    DECISION-VV02HH55
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

## Four edges, each stored once on the asserting note

| edge | meaning | written on |
|---|---|---|
| `rests_on` | this note depends on these; the blast-radius edge | the dependent note |
| `supersedes` | this note replaces that one, with `supersedes_reason` | the replacement |
| `scopes` | this narrows that one — not a contradiction, not a supersession | the narrower note |
| `validated_by` | this assumption is tested by that validation step | the assumption |

All four are block lists of IDs.

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

Two more fields are available on **any** type, used together:

```yaml
supersedes:                          # optional — block list
  - CLAIM-QQ19PL30
supersedes_reason: "The vendor republished the list; the earlier figure was a promotion."   # required with supersedes
```

**`supersedes` without `supersedes_reason` is rejected.** A replacement with no reason cannot
be evaluated later — the only question anyone asks about a superseded note is why, and the
person who knew is gone. And writing `supersedes` **without flipping the target's `status` to
`superseded`** leaves two `current` notes asserting different values on the same subject,
which is indistinguishable from an unresolved contradiction to both the checker and a reader.
Supersession is always two edits.

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
  - "business-plan.md#why-now"
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
renamed document and a renamed section. The anchor is matched against the heading's GitHub slug,
so the entry is written as the reader's own link: `"business-plan.md#why-now"` for `## Why now`,
resolved against the vault root and not against the note's own directory. An entry with no `#`
is checked for the file alone, which is the shape to use when a claim reaches a document whose
sections it does not name. **The mode stops at whether the target resolves and never asks whether
the section carries the claim** — the prose cites `[S#]` and `[F#]` codes rather than note IDs,
so matching IDs against prose would report every correctly cited claim as broken. Whether the
section still agrees with the note is a read over the worklist this mode produces, not a grep.

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
  _vocab.yml                      # the controlled subject vocabulary
  research/                       # ALL prose, untouched by the vault — dimensions, profiles,
                                  #   the founder brief and the product dossier
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
  "schemaVersion": 1,
  "created": "2026-03-14"
}
```

`schemaVersion` is a required integer, incremented only on a change that would make an older
tool misread an existing vault. `created` is optional. The file is JSON, not YAML, so the
coerce-nothing rule does not apply to it — JSON has unambiguous types.

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
4. **Set the edges**: `rests_on` for a fact, claim, or decision; `validated_by` for an
   assumption. Omit a key rather than writing an empty list.
5. **Derive `confidence`** where the note rests on something: `min(confidence_own, every
   rests_on target)`. Write both fields.
6. **Run the lint** before considering the note done. It catches the missing required field,
   the unknown subject term, the dangling edge, the duplicate source, and the propagation
   violation — all of which are silent in the file itself.
