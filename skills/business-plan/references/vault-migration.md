# Migrating an existing prose corpus into a vault

A corpus that predates the vault is the normal case, not the exception: dozens of research
files, a `sources.md` table, a founder brief, and a plan citing `[S#]` and `[F#]` codes inside
sentences. Telling that corpus's owner to "start using the vault" means either starting over or
never adopting it, and both are how a structure that would have worked gets abandoned.

This document is the procedure that avoids both. It adds a ledger over the prose. **It never
rewrites the prose** — the research files come out of a migration byte-identical, which is what
makes the migration safe to abandon halfway through a stage and resume the next morning.

The schema this produces is [vault.md](vault.md); the subject vocabulary is
[vocabulary.yml](vocabulary.yml). This file assumes both and does not restate them — it says
which of their rules bite differently when you are writing three hundred notes instead of one.

## Contents

- [The extraction manifest is already written — it is the plan's citations](#the-extraction-manifest-is-already-written--it-is-the-plans-citations)
- [Six stages, in this order, because each one makes the next cheaper](#six-stages-in-this-order-because-each-one-makes-the-next-cheaper)
  - [Stage 1 — Sources, because collapsing duplicates is free only while nothing points at them](#stage-1--sources-because-collapsing-duplicates-is-free-only-while-nothing-points-at-them)
  - [Stage 2 — Facts, because the table rows are already notes](#stage-2--facts-because-the-table-rows-are-already-notes)
  - [Stage 3 — Claims, the smallest defensible set and most of the value](#stage-3--claims-the-smallest-defensible-set-and-most-of-the-value)
  - [Stage 4 — Assumptions and decisions, from the model's guess rows and the settled forks](#stage-4--assumptions-and-decisions-from-the-models-guess-rows-and-the-settled-forks)
  - [Stage 5 — Milestones, last, because every one of them points at a stage-4 note](#stage-5--milestones-last-because-every-one-of-them-points-at-a-stage-4-note)
  - [Stage 6 — Stop](#stage-6--stop)
- [Atomise the assertions and leave the reasoning](#atomise-the-assertions-and-leave-the-reasoning)
- [Retrofit `killed_because` while the person who remembers is still here](#retrofit-killed_because-while-the-person-who-remembers-is-still-here)
- [Seven schema rules that bite differently in bulk](#seven-schema-rules-that-bite-differently-in-bulk)
- [Budget a day per hundred notes, and finish a stage or revert it](#budget-a-day-per-hundred-notes-and-finish-a-stage-or-revert-it)
- [An upgraded vault enters here, not at Stage 1 — reconcile the claims an amended definition left behind](#an-upgraded-vault-enters-here-not-at-stage-1--reconcile-the-claims-an-amended-definition-left-behind)
- [Finish with vault-lint, and know which failures legitimately survive](#finish-with-vault-lint-and-know-which-failures-legitimately-survive)
- [Stamp schemaVersion 2 last, after the vault can already pass at 2](#stamp-schemaversion-2-last-after-the-vault-can-already-pass-at-2)
- [Then 3, and what 3 asks for is a hash per cited section](#then-3-and-what-3-asks-for-is-a-hash-per-cited-section)

## The extraction manifest is already written — it is the plan's citations

**Do this before anything else, and do not skip to the reading.**

The instinct on opening a migration is to read the research corpus and decide what is
claim-worthy. That instinct is slow, subjective, and wrong. It is slow because it is a full read
of every file. It is subjective because two people doing it produce two different sets and
neither can defend theirs. And it is wrong because the answer already exists in the corpus: the
plan documents say which assertions are load-bearing, and they say it in machine-readable form.
They cite them.

One grep gives the manifest:

```sh
cd ~/Documents/go-to-market/<product-slug>

# The distinct codes the plan leans on. This is the manifest.
grep -ohE '\[[SF][0-9]+\]' one-pager.md business-plan.md financial-model.md | sort -u

# Every citation site, sorted by code. This is where `used_in` comes from.
grep -oHnE '\[[SF][0-9]+\]' one-pager.md business-plan.md financial-model.md | sort -t: -k3
```

```
business-plan.md:3:[F3]
one-pager.md:2:[F3]
business-plan.md:2:[S12]
one-pager.md:2:[S12]
business-plan.md:2:[S4]
```

**Anything cited becomes a note. Anything uncited stays prose until something needs it.** That
is the whole rule, and it is a rule rather than a heuristic because both halves are checkable: a
cited code with no note is an incomplete migration, and an uncited assertion with a note is
scope the manifest did not ask for.

Three things the manifest buys beyond the list itself:

- **A stopping condition.** A migration whose scope is "the load-bearing assertions" has no end
  and stalls at whatever point the migrator gets tired. A migration whose scope is 140 codes is
  done at 140.
- **`used_in` for free.** The second grep already knows which document and section cites each
  code, so the claims written in stage 3 carry `used_in` at authoring time rather than as a
  retrofit nobody schedules. Without it, a stale claim tells you it needs re-checking but not
  which paragraph is standing on it, so the re-check is deferred because nobody can size it.
  A migrated plan document usually predates the `{#anchor}` attributes
  [plan-template.md](plan-template.md) ships, so its slugs are what the entries name — and they
  resolve, which is why nothing has to be back-filled. Add the attributes to the document in
  this same pass anyway, and cite those: the migration is followed by an editing pass, and every
  heading reworded in it silently kills the citations the migration just wrote.
- **A budget.** `| wc -l` on the first grep is the note count, and the note count is the day
  count — see [the cost section](#budget-a-day-per-hundred-notes-and-finish-a-stage-or-revert-it).

**The manifest is a checklist file, not a mental note.** Write it to
`research/migration-manifest.md` and tick codes off as you go. "Where did I stop" is the
question a resumed migration has to answer, and a half-migrated corpus with no answer to it is
the state this whole document exists to prevent.

## Six stages, in this order, because each one makes the next cheaper

Scaffold the vault first — the tree, `.vault/config.json` with `"schemaVersion": 2`, and
`_vocab.yml` copied from [vocabulary.yml](vocabulary.yml)
([layout](vault.md#layout-one-directory-per-type-one-file-per-note)). The lint refuses a
directory without a config, and it says so plainly:

```
vault-lint.sh: not a vault - no .vault/config.json under /some/path. Refusing rather than
walking an arbitrary directory of Markdown as if it were a corpus.
```

The order below is bottom-up through the `rests_on` graph, and two mechanical consequences make
it the only workable order rather than a stylistic preference.

**Out of order, the lint stops being readable.** Every `rests_on` written before its target
exists is a `dangling-edge` failure. Migrate claims first and the failure list is hundreds of
edges that will resolve later — at which point you stop reading the list, and the one real
dangling edge, a mistyped ID in a hand-copied `rests_on`, hides inside it. Bottom-up, the target
always exists already, so a dangling edge during a migration means exactly one thing: a typo,
right now, while you still have the note open.

**Out of order, confidence has to be computed twice.** `confidence` is derived —
`min(confidence_own, every rests_on target)`
([the rule](vault.md#confidence-is-derived-wherever-a-note-rests-on-something)) — and the lint
checks it. That value is computable at the moment you write the note only if everything under it
is already written and already carries its final confidence. Bottom-up, you compute each note's
`confidence` once, as you write it. Any other order means authoring a placeholder and revisiting
every note in the corpus after the last stage lands, which is a second full pass over work you
already did.

### Stage 1 — Sources, because collapsing duplicates is free only while nothing points at them

The input is `sources.md`, whose table is column-for-column close to a source note:

| `sources.md` column | becomes | on |
|---|---|---|
| `#` — the `[S#]` code | nothing in frontmatter; it stays the prose citation | — |
| `Source URL` | `url`, and `url_canonical` after normalising | the source note |
| `Pulled` | `pulled`, quoted | the source note |
| `Note` | the note body | the source note |
| `Claim / figure` | `title` | a **fact** note, in stage 2 |
| `Tag` — H/M/L | `confidence_own` | that fact note |
| `Used in` | `used_in` | the **claim** that cites it, in stage 3 |

**One row is not one source.** The table conflates the source with the figure it supports, so
three rows citing three figures from one regulator document are one source note and three facts.
Normalising `url_canonical` — drop the scheme, drop `www.`, lowercase the host, drop the
fragment, drop `utm_*`/`fbclid`/`gclid`/`ref`, drop a trailing slash, keep everything else — is
what turns that into a mechanical collapse instead of a judgement call.

**This is why sources go first.** Collapse the duplicates now and the facts written in stage 2
each rest on the one surviving ID. Do it in the other order and collapsing means rewriting
`rests_on` on every fact that pointed at a retired note — and the ones you miss look doubly
sourced forever, which is the exact failure `url_canonical` exists to prevent. The lint names
it:

```
sources/SOURCE-DUPA0001.md
  [duplicate-url] url_canonical standards.example.gov/labelling/2025-revision is carried by 2
  source notes: sources/SOURCE-DUPA0001.md, sources/SOURCE-DUPB0002.md. A claim resting on two
  of them looks doubly sourced when it rests on one document
```

**`quote` is the expensive field, and recovering it is the real work of stage 1.** The table has
no verbatim passage, and `quote` is required
([why](vault.md#the-source-note-keeps-the-quote-that-outlives-the-url)). Recover it in this
order: the passage the research file quoted; failing that, re-open the URL and take the passage
the citing figure leaned on. Budget most of stage 1's time here.

**When the page is gone, that is the finding, and the schema already has the right response.**
A migration is a corpus's first link-rot audit. A source whose page no longer resolves and whose
passage nothing preserved is a claim with nothing behind it that has been reading as sourced,
possibly for months. Write the source note with the closest preserved text as `quote`, set
`confidence: M` or `L` to match how much of the passage survived, set
`status: needs_review`, and say in the body that the text was recovered from the research file
rather than re-read. The derived confidence then carries that downgrade to every fact and claim
above it automatically, which is the correct outcome: a chain standing on an unverifiable page
should not read as confident.

**A source with no public URL sets both `url` and `url_canonical` to the vault-relative research
path — and since the engagement folder IS the vault, that covers the market-analysis dimension
files and `sources.md` too, not only the brief and the dossier. A path that genuinely points
*outside* the vault needs an explicit `prefix:` marker, and a bare `host/path` needs its scheme;
the `unresolved-local-source` check reports both. Vault-relative research paths** — `"research/founder-brief.md"` for the founder interview, `"research/product-dossier.md"`
for the dossier. Write these in stage 1 even though they are not rows in `sources.md`; the
sources table is not the whole source set, and stage 2's `[F#]` facts have nothing to rest on
without them. One source note per file that records a conversation.

### Stage 2 — Facts, because the table rows are already notes

Two inputs, both already atomic: the `Claim / figure` column of `sources.md`, and the numbered
`[F#]` table in `research/founder-brief.md`. A row states one value with one provenance,
which is the definition of a fact note, so this is the cheapest stage per note in the migration.

- `title` is the row's figure or statement, unchanged. Do not improve the wording — the plan
  cites this assertion and the note has to be recognisably the same one.
- `rests_on` is the stage-1 source note for that row's URL. It is required
  ([why](vault.md#the-fact-note-is-one-observed-value-with-its-provenance)), and after stage 1
  the target always exists.
- `confidence_own` is the row's H/M/L tag. `confidence` is the derived minimum, which for a fact
  is `min(that tag, the source note's confidence)` — frequently lower than the tag, and that
  gap is the point.

**A fact whose provenance is a conversation rests on the interview source note.** `[F3]` — "the
founder ran regulatory affairs at a producer for six years" — has no URL and never will. It
rests on the `source` note for `research/founder-brief.md` written in stage 1, and the founder's
own words go in that source note's `quote`. This is the same construction the grill uses when it
runs live, so a migrated founder brief and a grilled one produce identical structure.

**Convert the supersession the prose already recorded.** Corpora written without a vault record
it in text — "superseded by F38", "the vendor republished this in March; see F41". Those
sentences are edges, and losing them costs the only record that the earlier figure was ever
wrong. Two edits, always:

```yaml
# on the replacement
supersedes:
  - FACT-QQ19PL30
supersedes_reason: "The vendor republished the list; the earlier figure was a promotion."
```

...and `status: superseded` on the target. Doing only the first leaves two `current` notes
asserting different values, which is indistinguishable from an unresolved contradiction to both
a reader and the checker. The lint catches exactly that half-migration:

```
decisions/DECISION-SUPS0002.md
  [supersedes-status] supersedes DECISION-BLOK0001, but that note is still `status: current`
  rather than `superseded`. Supersession is two edits and only one was made
```

**When the prose gives no reason, write what the prose supports and no more.** `supersedes`
without `supersedes_reason` is rejected, and the temptation under a bulk migration is to
back-fill something plausible. "The later pull returned a different figure; the corpus does not
record why" is a true reason and a useful one. An invented one is a fabricated audit trail.

### Stage 3 — Claims, the smallest defensible set and most of the value

**Only the claims the plan cites.** The manifest is the list; nothing else in the research
corpus becomes a claim in this migration.

The claim's text comes from the **plan**, not the research file. The research file argues; the
plan asserts, and the assertion is what a later document leans on. So the plan sentence carrying
`[S12]` is the claim's `title`, trimmed to a single assertion — a sentence asserting two things
is two notes, because `status` and `confidence` are per-note and half a note cannot be retracted.

`rests_on` is the stage-2 facts behind it. `used_in` is the citation site the manifest grep
already recorded. `confidence_own` is your assessment of the inference the plan made on top of
the facts; `confidence` is the derived minimum.

**The subject vocabulary meets the corpus's free-text subjects here, once, in bulk.** This is not
an edge case to handle per note — it is a step. Before writing a single claim, list the corpus's
own topic words (section headings, the research file names, whatever the `Used in` column says)
and resolve each to a canonical key by
[vocabulary.yml](vocabulary.yml)'s five-step order: exact key, exact alias, normalised match,
prefix or containment, then unknown. Keep the mapping as a two-column table and use it for the
whole stage.

**Store the canonical key, never the alias.** The lint reports an alias as a fixable near-miss
rather than an error, and the message says why the distinction matters:

```
claims/CLAIM-NEAR0002.md
  [near-miss-subject] subject `pricing` is an alias of `price-anchor`, not a vocabulary key.
  Store the canonical key: `pricing` and `price-anchor` never collide, so two claims that
  disagree stay in agreement as far as any query can tell
claims/CLAIM-NEAR0003.md
  [near-miss-subject] subject `Timing_Window` differs from the key `timing-window` only in case
  or separators. Drift like this never collides
```

A term with no alias and no near-miss is reported as `unknown-subject` with no suggestion —
`positioning` is deliberately unaliased because it could mean `category-boundary` or
`competitive-gap`, and the error sends you to the definitions rather than guessing on your
behalf. **Resolve it by finding the term it belongs under.** Adding a term to `_vocab.yml` to
silence the error skips the question the error existed to ask, and a vocabulary extended that way
becomes a transcript of whatever people happened to type, at which point the collision query has
nothing left to collide.

**`stale_after` is authored per claim, and a migration is where the shortcut is most tempting.**
You have two hundred claims and a `Pulled` column, and deriving `stale_after` from pull-date plus
a fixed window takes one command. Do not: it flags every durable claim as stale and lets the
fast-rotting ones sit unflagged for the same period, which trains everyone to ignore the flag.
Bulk-assign by rot rate instead — vendor pricing about a quarter, market structure about a year,
a fixed regulatory date until that date — which is a bulk judgement about the claim, not about
when someone happened to read a page.

**A cited assertion with no fact under it is an assumption, and finding those is one of the
migration's real payoffs.** Plans acquire sentences that cite a code the source does not actually
support, or that cite nothing at all. `rests_on` is required on a claim, so the note cannot be
written — and per [vault.md](vault.md#the-assumption-note-is-what-you-would-believe-with-no-evidence),
a thing resting on nothing is an assumption, which is what makes it one. Write it as one, with a
`value`, a `sensitivity`, and a `validated_by`. The plan sentence has not changed; it is now
visibly a bet.

### Stage 4 — Assumptions and decisions, from the model's guess rows and the settled forks

**Assumptions come from the financial model's assumption table** — specifically the rows whose
source column reads `guess — validate` ([plan-template.md](plan-template.md)). Each becomes one
assumption note: `value` is the row's number, `sensitivity` is how far the model moves if it is
wrong, and `validated_by` names the step that would settle it.

**Do not double-write the sourced rows.** A row citing `[S#]` or `[F#]` is already a fact from
stage 2, and re-emitting it as an assumption puts two notes on one assertion with two statuses
that will drift apart. Only the guess rows atomise here.

`validated_by` needs a target, so this stage also writes the `question` notes the assumptions
point at, each carrying the `gaps` that make it researchable. When the validation step is
shipping something rather than researching it, the target is a plan reference —
`"business-plan.md#milestone-2"` — and no question note is needed.

**Decisions come from the forks the prose already settled** — "we went direct rather than through
distributors because…". Reconstructing one is the most authored work in the migration, and two
fields carry it:

- `options` must include the **rejected** ones, and `chosen` must match one entry verbatim.
  Reading the rejected set is the entire reason to record it: "we already considered that, here
  is why not" is the answer to the question that returns in three months. A `chosen` that
  paraphrases an option makes the rejected set unreadable.
- `reopen_if` is almost never in the prose, and writing it is the point of migrating the
  decision at all. Derive it from the reasoning: reasoning that turns on a twelve-month window
  gives "the window is extended or closes early". A decision with no trigger is indistinguishable
  from one nobody may revisit, so it gets ignored rather than re-checked.

**Do not paraphrase the founder into `founder_reasoning`.** If the prose preserves the founder's
own words, they go in verbatim; if it does not, leave the field off and the note is a `decision`
note per [vault.md](vault.md#the-decision-note-keeps-the-rejected-options-and-the-reopen-trigger)
rather than a full decision record per
[decisions.md](decisions.md#the-record-extends-the-vaults-decision-note-it-does-not-replace-it).
That difference is honest and visible. A skill-voiced paraphrase in that field is the failure the
field was split out to prevent — six months later the record shows a decision resting on analysis
that actually rested on a constraint nobody wrote down.

### Stage 5 — Milestones, last, because every one of them points at a stage-4 note

**Only for a corpus you are also moving to `schemaVersion: 2`.** The `milestone` type does not
exist at 1, so a vault staying at 1 stops after stage 4 and its roadmap stays prose. The stamp is
the last edit of all, after everything below — see
[Stamp schemaVersion 2 last](#stamp-schemaversion-2-last-after-the-vault-can-already-pass-at-2).

**The input is the plan's roadmap table**, one note per row. It is last for the same reason
sources are first: `moves` names the assumption or claim the item changes, and every one of those
was written in stage 3 or 4. Migrate the roadmap earlier and every `moves` edge is a
`dangling-edge` failure waiting on a note that does not exist yet — the same unreadable failure
list the stage order exists to avoid.

Three fields are authored rather than copied, and each is where the migration earns its keep:

- **`sequence` is a whole number, and it is not the month.** A table whose rows read `M4`, `M6`,
  `M9` gives 1, 2, 3. The month the founder said goes in `date_stated` verbatim, `≤6mo` and all;
  copying `M4` into `sequence` produces a value nothing can order, which is a
  `sequence-not-orderable` failure precisely because it would otherwise silence the two order
  checks in a way that reads as passing.
- **`resource` is almost never in the table** and is the most valuable thing this stage adds.
  Label each item with what it actually consumes — founder hours, capital, a hire that has not
  happened, someone else's clock. That is what turns Rule 4 from prose into a check, and a bulk
  migration is where the false independence claims are: a roadmap written without the column
  routinely has three items in one slot that one person cannot do.
- **`moves` is a note ID, never the table's `A-n` label.** The prose keeps its labels. Build the
  label→ID map once, the way stage 3 builds the subject map, or every item in the corpus stores a
  row label that resolves to nothing.

Expect rows that have no assumption to move. Those are maintenance and are not roadmap items
(Rule 1) — leave them out and say so to the corpus's owner rather than inventing an assumption to
justify a row, which is the failure that files a backlog as a plan.

### Stage 6 — Stop

The migration is over when the manifest is ticked off. Four things look like the obvious next
step and are not:

- A note per research paragraph.
- A note per competitor row, per profile, per section heading.
- Notes for the uncited facts, "while we are in here".
- `used_in` back-filled onto notes nothing cites. Omit the key instead.

Each produces a second corpus nobody maintains. The vault's value comes from being the entire
assertable surface readable in one pass; past that size it is another pile of files, with the
added cost that every one of them now needs a status kept current.

**Re-entry is cheap and expected.** When a later document needs an assertion that stayed prose,
that is the moment it becomes a note — one note, written by the six-step checklist
([vault.md](vault.md#writing-a-note-the-six-step-checklist)), resting on a source that stage 1
already wrote. The migration is not a gate the corpus passes through once.

## Atomise the assertions and leave the reasoning

The argument inside a research file is worth reading as an essay. A dimension file comparing four
sources, weighing them against each other, and landing on a position is doing work that no
individual note holds: the comparison **is** the content, and it lives in the transitions between
the paragraphs.

Shred it into atoms and you sever exactly that. Four notes and a claim resting on them record
what was concluded; nothing records that source three was discounted because its sample was
self-selected, which is the sentence a reader needs when source three is later updated.

**So: atomise the assertions, leave the reasoning.** Worked, on one generic paragraph:

> Three of the four trade surveys put re-labelling readiness under 20%, and the fourth reports
> 61% — but the fourth surveyed only association members, who are the producers most likely to
> have acted early. Taking the three comparable surveys, fewer than one in five producers had
> re-labelled any line by March 2026.

What becomes a note: the assertion in the last sentence, as a fact resting on the three source
notes. What stays prose: the reason the outlier was discounted. What does **not** happen: four
notes, one per survey, plus a note recording that they disagree. The disagreement is an argument,
and arguments live in files.

The same line applies to the whole corpus. Research prose stays exactly as it is — untouched,
uncited-from, unedited. A migration that starts rewriting research files has stopped being a
migration.

## Retrofit `killed_because` while the person who remembers is still here

A killed hypothesis is the least re-tested thing in any corpus, because it feels finished. And a
kill made under a mistaken premise stays dead: nobody re-opens a question that was already
answered, and nothing in a prose corpus makes the premise findable.

Every corpus has these, recorded as a sentence and nothing more — "we looked at the marketplace
model and dropped it, the take rate does not clear support costs at this volume". Migrate each as
a `question` note with `killed_because` set and `status: retracted`, in one edit
([the field](vault.md#the-question-note-records-the-gap-not-the-answer)):

```yaml
id: QUESTION-KM40TR18
type: question
title: "Can a marketplace take rate cover support cost at the volumes this segment produces?"
status: retracted
confidence: M
created: "2026-07-26"
gaps:
  - "No support-cost-per-transaction figure for a comparable low-volume marketplace"
killed_because: "Take rate at the modelled volume does not clear support cost."
```

**Do this during the migration, not after it.** The reason a kill happened is in someone's head
now and in nobody's in six months, and a `killed_because` reconstructed later is a guess wearing
the authority of a record.

**The payoff is a grep replacing a hand-search.** When a premise moves — a vendor ships the thing
you assumed they would not, a price floor changes, a volume assumption turns out low — the
question is "which of our kills rested on that?". Today that is opening every research file and
hoping to recognise the sentence. Afterwards:

```sh
grep -rl 'killed_because' "$VAULT_PATH/questions"
grep -rh 'killed_because' "$VAULT_PATH/questions" | sort
```

And never delete the note instead. A deleted kill is how the same hypothesis is re-proposed two
months later with nothing recording that it was already tested and failed.

## Seven schema rules that bite differently in bulk

Authoring one note, these are checklist items. Authoring three hundred, each is a way to produce
a corpus that fails lint uniformly and takes a second pass to fix.

**1. Generate IDs with the recipe; never derive them from the old codes.** The first instinct in
a bulk migration is `[S4]` → `SOURCE-S4`, because it preserves the mapping. It reintroduces
sequential IDs and everything they cost: two people migrating different parts of one corpus both
allocate `SOURCE-S17`, both are locally correct, and the merged vault has one address pointing at
two documents. Use the recipe
([why](vault.md#an-id-is-an-address-not-a-label)), which needs no registry and no coordination:

```sh
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8; echo
```

The `[S#]` and `[F#]` codes are not lost — they stay in the prose as the human-readable
citation, exactly as they do in a corpus the skill builds from scratch. The note ID is what a
query reaches; the code is what a person reads.

**2. Never author `confidence`; derive it.** A migration that copies the corpus's H/M/L tag into
`confidence` fails the propagation check on every note whose sources are weaker than its tag —
which is most of them, since propagation exists precisely because that gap is invisible in prose.
The tag is `confidence_own`. `confidence` is `min(confidence_own, every rests_on target)`,
computed as you write, which the stage order makes possible. If you migrate with a script, the
script computes it; it does not copy it. The failure reads:

```
claims/CLAIM-CONF0005.md
  [confidence-propagation] stored confidence is H but min(confidence_own, every rests_on
  target) is M, set by FACT-DANG0002, which is M. Without min, a hedged source becomes a
  fairly confident fact becomes a flat claim
```

**3. `subject` is a canonical vocabulary key, never an alias.** Covered in stage 3, repeated here
because it is the one rule a bulk migration violates uniformly: the mapping table gets built
once, and if it stores aliases then every claim in the corpus stores an alias.

**4. Block lists, never inline flow lists.** `rests_on: [FACT-GF45SD01, SOURCE-K92MZ1QA]` is the
natural shape to emit from a script and the one shape that breaks silently — Obsidian rewrites it
into block form on save, so every edge written that way disappears the first time somebody opens
the vault in an editor, and the blast-radius query then returns a clean result over a corpus it
can no longer see. An empty list is an **omitted key**, never `[]` and never a bare `rests_on:`
([why](vault.md#block-lists-survive-an-obsidian-save-inline-flow-lists-do-not)).

**5. Coerce nothing — and a migration is dense in exactly the values that coerce.** Every note
has a quoted `created`; every source has a quoted `pulled`; every claim has a quoted
`stale_after`. Plan headlines routinely contain `: `, which splits an unquoted `title` into a
nested mapping. Reference codes with leading zeros read as octal in some parsers and truncate in
others. Quote all of it
([the table of banned values](vault.md#coerce-nothing-ban-the-ambiguous-value-instead-of-parsing-it)):

```
sources/SOURCE-CODE0005.md
  [ambiguous-value] line 10: field `pulled` has the unquoted value 2026-03-16 - unquoted it is
  a date object in most parsers and text in the rest, and the plain string comparison every
  staleness query relies on stops working. Quote it
```

**6. `created` is the migration date, not the research date.** Backdating a migrated note to when
the research ran is the intuitive move and it breaks the field's only job: distinguishing a note
written before a source was amended from one written after
([why](vault.md#status-moves-in-one-direction-and-never-silently)). A note written today,
backdated to March, reads as having survived an amendment it never saw. The research date is not
lost — it is `pulled` on the source note, which is where a read date belongs.

**7. On a milestone, `moves` is a note ID and `sequence` is a position, never the row label and
never the month.** Covered in stage 5, repeated here for the reason rule 3 is: both are mapping
tables built once, so a map that stores the wrong side stores it uniformly. A roadmap table reads
`| M4 | New-platform GA | trial volume (A-7) |`, and the natural script copies `M4` into
`sequence` and `A-7` into `moves` — after which every item in the corpus carries a value that
orders nothing and an edge that resolves to nothing. `M4` goes in `date_stated`, verbatim; `A-7`
resolves through the label→ID map to the assumption note stage 4 already wrote. Only the second
of the two is caught by the lint, as `dangling-edge`; the first is caught as
`sequence-not-orderable`, which exists because the two order checks would otherwise skip it in
silence.

## Budget a day per hundred notes, and finish a stage or revert it

**Roughly a day per hundred notes**, for someone who knows the corpus. That is the honest number
and it belongs in the conversation before the first note is written, because an unstated cost is
why migrations stall halfway.

Where it goes, per stage, per note:

| stage | pace | what makes it that pace |
|---|---|---|
| Sources | slowest | `quote` recovery and the link-rot audit; the table has no verbatim passage |
| Facts | fastest | a table row is already a note; the mapping is columns |
| Claims | middling | the subject mapping, then a `stale_after` judgement per claim |
| Assumptions, decisions | slow | `sensitivity`, `reopen_if` and `validated_by` are authored, not extracted |

The manifest gives the count, so multiply and say the answer out loud:
`grep -ohE '\[[SF][0-9]+\]' *.md | sort -u | wc -l` returning 140 means about a day and a half
for the cited set, plus stage 4, plus the sources those citations resolve to.

**The expensive outcome is not a slow migration; it is a stopped one.** A corpus half-migrated
has two sources of truth and lint coverage over neither: some assertions are queryable and some
are not, the blast-radius query returns a clean short answer over the half it can see, and a
clean result is what somebody acts on. Nobody investigates a green.

**So the unit of completion is a stage, not the corpus.** Finish a stage or revert it. Stages 1
and 2 with no claims yet is a coherent state — everything in it is consistent, lintable, and its
remaining failures are a known, enumerable set. A stage 3 abandoned at claim 60 of 140 is not,
because the claim set no longer matches the manifest and nothing except the manifest checklist
records where the boundary is. Keep that checklist current as you go; it is what makes stopping
for the day safe.

## An upgraded vault enters here, not at Stage 1 — reconcile the claims an amended definition left behind

Everything above turns prose into a ledger. This section is the other entry point and it starts
from the opposite place: the vault exists, the notes are written, and what moved is the
definition underneath them. There is no manifest, no bottom-up order, and no new notes beyond the
replacements this produces — so read it as its own short procedure rather than as a sixth stage.
You are here because Phase 0 reused an existing vault and reported vocabulary drift.

**The trigger is Phase 0's advisory, and the amendment log is the scope.** The shipped
[vocabulary.yml](vocabulary.yml) carries a `vocabulary_version` and an `amendments` log; the
vault's `_vocab.yml` carries the stamp it was seeded with, or none at all if it predates the
stamp. Phase 0 reports the entries between the two, each naming the term, the framing it carried
(`was`), the framing it carries now (`now`), and the test to apply (`must_assert`). That report
is an advisory rather than a lint failure, which means nothing forces this work — so do it while
the advisory is in front of you, because a vault carrying claims under two readings of one
subject looks identical to a healthy one from every query.

**One grep per amended term is the entire scope.** Only claims carry a `subject`, so nothing
else in the corpus is affected:

```sh
grep -rl 'subject: "steady-state-ceiling"' "$VAULT_PATH/claims"
```

Bounding it this way is the difference between an afternoon and a corpus-wide re-read nobody
starts. A re-read that never starts leaves the drift in place *and* costs the advisory its
credibility for the next amendment.

**Re-read each hit against `must_assert`, and the answer is binary.** Either the claim still
asserts what the subject now asserts — in which case leave it completely untouched, because a
cosmetic edit puts a note in the history as having changed when what changed was the vocabulary
around it — or it does not, and it is superseded: two edits, per
[vault.md](vault.md#every-note-carries-these-six-fields), with `supersedes_reason` naming the
amendment. Editing the claim in place is the failure this whole procedure exists to prevent. The
sentence then reads as though its author wrote it under wording they never saw, and the record
that the ground moved — the only thing that explains why a plan said one thing in March and
another in July — is gone.

Worked on the one amendment that has actually shipped, `steady-state-ceiling`, amended at
`vocabulary_version` 2 from *the equilibrium the business converges on* to a ceiling belonging to
the modelled **configuration**, with every input labelled `structural` or `policy`. A claim filed
under the old framing:

```yaml
id: CLAIM-PM71QD05
type: claim
title: "The business levels off at about 900 paying customers"
status: current
confidence: M
confidence_own: M
created: "2026-02-11"
subject: "steady-state-ceiling"
stale_after: "2026-12-31"
rests_on:
  - FACT-KD03WQ55
  - FACT-ZB77NN12
used_in:
  - "business-plan.md#the-ceiling"
```

Under `was` that sentence is exactly what the subject asked for. Under `now` it asserts something
the subject no longer carries: 900 is the answer for one churn rate and one acquisition rate, and
the founder chose both. The claim names no configuration and labels no input, so it fails
`must_assert` and gets a replacement:

```yaml
id: CLAIM-VT38HK92
type: claim
title: "At 5% monthly churn and 45 new customers a month the modelled configuration levels off at about 900 paying customers"
status: current
confidence: M
confidence_own: M
created: "2026-07-27"
subject: "steady-state-ceiling"
stale_after: "2026-12-31"
rests_on:
  - FACT-KD03WQ55
  - FACT-ZB77NN12
used_in:
  - "business-plan.md#the-ceiling"
supersedes:
  - CLAIM-PM71QD05
supersedes_reason: "vocabulary_version 2 amended steady-state-ceiling from a property of the business to a property of the modelled configuration. The earlier claim named no configuration and labelled no input."
```

...and `status: superseded` on `CLAIM-PM71QD05`, whose title stays in the words it was written
in. The body of the replacement carries the labels the amended definition asks for — churn is
`policy` here, and the ceiling under one changed value of it belongs beside the number. Between
the two notes the corpus now records what was asserted, what it became, and why, which is what
the two-edit rule buys and what re-filing in place would have spent.

**`used_in` is the second half of the reconciliation, and skipping it moves the defect rather
than fixing it.** The superseded claim names the paragraph standing on it, and that paragraph
still says the business tops out at 900 — a founder's own decision reported as a law of nature,
which is invariant 18's failure exactly. Rewrite the sentence to the replacement's
assertion. A ledger reconciled under a document that was not is a ledger nobody's reader ever
sees.

**Get that paragraph list from the lint rather than by hand:**

```sh
vault-lint.sh --supersession-sweep --vault "$VAULT_PATH"
```

One row per document section, however many superseded claims reached it, each naming the claim,
its replacement and the `supersedes_reason` — which is the whole rewrite list for the amendment
you just reconciled, sized by the count it prints first. Deriving it by hand means one `grep` per
superseded claim and then merging the results, which is the step that gets shortened to "the ones
I remember". A migrated vault is at schemaVersion 1, where the mode exits 0 whether or not it
finds anything — so here it is a target list rather than another census entry to clear. At 2 it
additionally fails a supersession carrying no `reconciled:` date, which means the rewrite you
just did has a date to stamp: put it on each superseding note in the same edit.

**Adopt the amended definition last, and stamp the copy.** Once every claim under the term is
reconciled, replace that one term's `definition` in the vault's `_vocab.yml` with the shipped
wording and set `vocabulary_version` to the shipped value. Three ways this goes wrong, each with
a distinct cost:

- **Adopting first** is the silent redefinition [vocabulary.yml](vocabulary.yml)'s extension rule
  bans — the vault then reads every existing claim against wording none of them was written to,
  and nothing marks which ones predate it. Reconciling first is what makes the adoption honest.
- **Overwriting the whole file** with the shipped `vocabulary.yml` drops the engagement's own
  terms, and every claim under them becomes an `unknown-subject` error at the next lint. Edit the
  one term.
- **Skipping the stamp** leaves the advisory firing on every subsequent run with the work already
  done, which is how a real signal turns into one people dismiss by reflex.

**Then run the lint, and expect the reconciliation to show up in it.** `supersedes-status` is the
check that catches a half-done reconciliation — a replacement written while its target is still
`current` — and it is the reason this is a lint-verifiable procedure rather than a careful one.
The census below is the acceptance test, unchanged.

## Finish with vault-lint, and know which failures legitimately survive

Run the shipped lint over the migrated vault. It is read-only, takes the vault path by
`--vault` or `VAULT_PATH`, and never searches upward for one:

```sh
vault-lint.sh --vault ~/Documents/go-to-market/<product-slug>
```

Clean looks like this, and exits 0:

```
vault-lint: note-level checks passed - /Users/example/Documents/go-to-market/example-product.
Not opened: citation targets, supersession blast radius, panel objection rows, roadmap table against the milestone set, verdict drivers and the evidence under them - --release-gate asks all of them.
```

The line is deliberately narrower than "clean". This run reads note fields and opens no
document, so a corpus whose citations all point at renamed files prints it too — and a success
line that reads as a whole-corpus verdict is the one somebody renders on.

Failures are grouped by file, each naming the check and the failure it prevents, and exit 1:

```
vault-lint: 5 failures under /Users/example/Documents/go-to-market/example-product

_vocab.yml
  [coverage-gap] no claim carries the required subject `price-anchor`. The note schema cannot
  catch a thin spine, because you cannot type a fact nobody wrote - a required subject with no
  claim under it is an omission every document downstream inherits in silence

sources/SOURCE-K92MZ1QA.md
  [orphan-source] nothing in the vault rests on this source. Either the research was read and
  never used, or something that should have cited it cited nothing - both are worth one look,
  and neither is visible from inside the note
```

**Two checks legitimately still fire on a correctly migrated corpus, so "exit 0" is the wrong
acceptance test.** Both are findings about the corpus rather than defects in the migration:

- **`coverage-gap`** — a `required: true` subject with no claim under it. A `_vocab.yml` seeded
  from the shipped vocabulary carries 25 required terms, and a real plan rarely takes a position
  on all 25. The gap list is the research backlog, and it is deliberately not silenceable:
  extension is additive and a base term is never redefined, so flipping `required` locally is not
  the fix. Research the subject, or state the gap in the plan.
- **`orphan-source`** — nothing rests on a source. Mid-migration this fires on every source you
  have written, because stage 2 has not happened yet. At the end it means what the message says:
  either that research was read and never used, or something that should have cited it cited
  nothing. Worth one look each; not necessarily worth an edit.

Everything else must be zero. That makes the acceptance test a **census of check names**, not an
exit code:

```sh
vault-lint.sh --vault "$VAULT_PATH" --json |
  grep -o '"check": "[a-z-]*"' | sort | uniq -c
```

```
   3 "check": "coverage-gap"
   2 "check": "orphan-source"
```

Two check names and nothing else is a finished migration. A `dangling-edge`,
`confidence-propagation`, `near-miss-subject`, `inline-flow-list`, `ambiguous-value`,
`duplicate-url`, `supersedes-status` or `required-field` in that census is migration work that is
not done.

**Expect the census to shrink stage by stage, and read it between stages rather than only at the
end.** After stage 1 it is every source orphaned plus every required subject gapped. After stage
2, orphan-source clears for every source a fact now rests on. After stage 3, coverage-gap drops
to the subjects the plan genuinely has no position on. Running the lint only once, at the end,
means every mistake you made in stage 1 is discovered three hundred notes later.

Three closing checks the census does not cover:

```sh
# Every used_in entry stage 3 wrote, opened. A migration takes its citation sites from a
# grep over documents that already exist, so a heading renamed since - or a document the
# manifest named under its old filename - lands in the vault as a citation to nothing.
# A verdict, not a target list: it exits 1 on a missing file or a dead #anchor.
vault-lint.sh --used-in --vault "$VAULT_PATH"

# The validation queue the migration just created: every assumption written in stage 4,
# plus everything carried at Low confidence. A target list, not a verdict - it exits 0.
vault-lint.sh --unverified --vault "$VAULT_PATH"

# The sections a supersession put in doubt. A migration that imported prose saying
# "superseded by F38" wrote those edges in stage 3, and the documents the old notes were
# cited into still carry the old assertion. One row per section, with the reason, and a
# count so the re-read can be sized. A migrated vault is at schemaVersion 1, where this
# is a target list and exits 0; at 2 it also fails a supersession carrying no
# `reconciled:` date, which is the last stage of the upgrade below.
vault-lint.sh --supersession-sweep --vault "$VAULT_PATH"

# One chain, end to end. Pick a sentence in the plan, take the claim it cites, and confirm
# the graph reaches a source note with a real quote in it.
vault-lint.sh graph CLAIM-AS23SD44 --vault "$VAULT_PATH"
```

**Before the first render — not here — the first and third of those are part of one call.**
`vault-lint.sh --release-gate` runs the bare check, `--used-in`, the sweep, `--red-team`,
`--roadmap-table`, `--binding-driver`, `--assumption-rows` and `--claim-drift`
together and exits
non-zero unless every part passes, which is what the render gate is held to. It is deliberately
not the migration's acceptance test: `coverage-gap` and `orphan-source` legitimately survive a
finished migration, so the gate exits 1 over a corpus that is done, and the census above is the
thing that tells you it is. Reaching for the gate here would make a finished migration look
unfinished, and a red that is expected is a red nobody reads.

The census proves the corpus is well-formed. The `graph` spot-check on two or three of the
plan's load-bearing sentences is what proves it is *true* — that the chain from an assertion a
stranger will act on down to a verbatim passage actually connects, which is the only thing the
migration was ever for.

## Stamp schemaVersion 2 last, after the vault can already pass at 2

`vault-lint.sh` reads `schemaVersion` 1, 2 and 3. A vault at 1 is held to exactly the rules it
was written under, so **nothing about upgrading the skill obliges you to upgrade a vault** — an
existing corpus keeps working untouched, which is the property the version set exists to buy.
Move to 2 when you want the checks version 2 added; the list of what those are is in
[vault.md](vault.md#schemaversion-refuses-what-it-does-not-understand). Move to 3 after that and
never in the same pass — [the section below](#then-3-and-what-3-asks-for-is-a-hash-per-cited-section)
says what 3 asks for and why its worklist is one row per citation rather than one per supersession.

**What 2 asks of an existing corpus is stage 5, plus a back-fill on anything it already
superseded or already red-teamed.** The milestone half fires only on notes in `milestones/` — a
directory a vault at 1 does not have — so for that half the upgrade is: write the roadmap notes,
then stamp. A corpus whose plan has no roadmap at all owes nothing there, and one whose roadmap
stays prose should stay at 1 rather than stamp 2 over an empty `milestones/` directory, which
claims a check it is not subject to. The one failure that half surfaces on its own is
`type-agreement` on a vault that grew a `milestones/` directory while still stamped 1 — that is
the directory and the version disagreeing, and the fix is finishing the upgrade rather than
deleting the notes.

**Writing those notes is also what puts the plan's existing roadmap table under `--roadmap-table`,
so mint each note from the row it renders and copy the item cell into `title` unchanged.** The
match is verbatim, so a note whose title is a tidied-up version of its row fails twice over — once
as a row with no note behind it, once as a note the table never lists. A back-fill is the one
moment those two lists exist side by side and can be made to agree for free.

The other half **does** reach back into what is already there: version 2 also asks for a
`reconciled:` date on every note carrying `supersedes`, and for a `## Lenses dispatched` roster in
a `red-team.md` that has one. Both are step 2 below, and both are back-fill rather than repair —
but a corpus with supersessions in it does not move to 2 for free, which is the one thing to know
before starting.

The number is a claim about the corpus, not a label on it: it tells the tool which rules to
apply. So the order mirrors the vocabulary reconciliation above — **do the work, then stamp** —
and the mechanism that makes that workable is the vault's own git history, which invariant 17
already requires.

1. **Edit `schemaVersion` to 2 in the working tree and do not commit it.** The version-2 checks
   only fire at 2, so this is how you find out what the upgrade owes. An uncommitted number is a
   question, not an assertion.
2. **Run the gate and read the failures as the worklist.**

   ```sh
   vault-lint.sh --release-gate --vault "$VAULT_PATH"
   ```

   Everything it reports beyond the two that legitimately survive any finished migration
   (`coverage-gap`, `orphan-source`) is upgrade work. The milestone rules fire only on notes you
   wrote in stage 5. Two more reach back into a corpus that already exists, and both are back-fill
   rather than repair:

   - **`reconciled:` on every note carrying `supersedes`.** The sweep names the sections each
     supersession put in doubt; **read them, then stamp the date you read them on the superseding
     note.** Stamping first inverts the whole point — the field asserts the read happened, so a
     date written to clear a red is a false assertion in the ledger, and it is exactly the
     assertion the render gate downstream is trusting. If the corpus has more supersessions than
     the session has room for, that is the signal to revert the `2` and come back, not to stamp
     the rest.
   - **A `## Lenses dispatched` roster in `red-team.md`**, if the engagement has one. Write the
     round and lens for each round already folded into the table, reading the lens names off the
     rows themselves; a round whose rows are all present needs no more than transcribing. A lens
     you know was dispatched and that wrote nothing is the finding, not an obstacle — record it
     and go get the rows.

3. **Fix the corpus, never the number.** If the worklist is bigger than the session, revert the
   `2` and leave the vault at 1 — it is correct at 1 and it keeps rendering. A vault left
   committed at 2 mid-upgrade puts the render gate permanently red for reasons that have nothing
   to do with the render, and the next person cannot tell an upgrade in progress from a corpus
   that broke.
4. **Commit the stamp together with the fixes, as the last edit.** One commit in which the vault
   both claims 2 and passes at 2 means no commit in the history ever records a version the corpus
   could not back up — which is the same failure mode as adopting an amended definition before
   reconciling the claims under it, one level up.

## Then 3, and what 3 asks for is a hash per cited section

`schemaVersion` 3 is where two rules with no version behind them would have failed every corpus that
exists. Both are optional in the sense that matters: **a vault at 2 keeps working untouched**, and
moving to 3 is a decision to buy what 3 checks. The rules are in
[vault.md](vault.md#schemaversion-refuses-what-it-does-not-understand)'s version-3 table.

**The two halves cost very different amounts, so read them apart before starting.**

**`--assumption-rows` costs almost nothing on an existing corpus**, because its forward trigger is a
field no note carries yet. Nothing owes a row until an `assumption` note declares `model_input`, so
the upgrade here is opt-in per note: go through the assumptions table in `financial-model.md`, and
for each row mint or find the `assumption` note behind it and copy the row's `Assumption` cell into
`title` **unchanged**. The match is verbatim, so a note whose title is a tidied-up version of its row
fails twice over — once as a row with no note behind it, once as a declared input the table never
lists. This is stage 4 read from the other end, and a back-fill is the one moment the two lists sit
side by side and can be made to agree for free.

**`--claim-drift` is the expensive half, and the cost is a real read rather than a transcription.**
Every `current` `claim` and `assumption` whose `used_in` names a resolving `#anchor` owes a
`reconciled_sections` entry, so on a migrated corpus that is one entry per citation stage 3 wrote.
Do it the only way the field means anything:

```sh
# The worklist, and it names the hash to paste for every entry it is missing.
vault-lint.sh --claim-drift --vault "$VAULT_PATH"
```

1. **Open the section the failure names and read it against the note.** This is the whole point. The
   hash records that the read happened, exactly as `reconciled:` does — a hash pasted without opening
   the document is a false assertion in the ledger, and it is precisely the assertion the render gate
   downstream trusts.
2. **If the claim still holds, paste the entry the message printed** and set `reconciled:` to the
   date you read it. If it does not hold, the claim is what changes — supersede it, and the sweep
   picks up the blast radius from there.
3. **If the corpus has more citations than the session has room for, revert the `3` and come back.**
   A vault left committed at 3 mid-upgrade puts the render gate permanently red for reasons that have
   nothing to do with the render, and the next person cannot tell an upgrade in progress from a corpus
   that broke. That is the same rule the 2 upgrade states and it bites harder here, because the
   worklist is one row per citation rather than one per supersession.

**Commit the stamp together with the entries, as the last edit**, for the reason the 2 upgrade gives:
one commit in which the vault both claims 3 and passes at 3 means no commit in the history records a
version the corpus could not back up.

**What moving to 3 buys is that a reconciliation cannot silently expire.** At 2, a claim reconciled
against a section stays green after somebody rewrites that section — the heading is untouched, so
`--used-in` still resolves, and the drift is found by hand or not at all. At 3 the rewrite re-opens
the claim. That is invariant 20 holding past the first time it was satisfied, which is the only place
it was ever failing.

**Migrations stay forward-only.** There is no 2→1 path and no 3→2 path, for the reason
[vault.md](vault.md#schemaversion-refuses-what-it-does-not-understand) gives: writing one means
holding every field the newer schema added in a shape the older one can carry, which is a second
schema maintained forever.
