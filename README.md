# market-skills

Two agent skills that take a product to market, packaged as one plugin. Both are **model-invoked** — Claude reaches for them on its own from the frontmatter `description`, so you rarely type them.

- **`market-analysis`** — heavy, evidence-first market research for a product (a code repo, a
  spec/doc, or an idea): value-hypothesis extraction, multi-agent competitor discovery and
  profiling, bottom-up market sizing, customers/JTBD, pricing & willingness-to-pay, timing,
  channels, moats — plus two archaeology passes over repo sources: infra-cost (derive COGS from
  the actual stack, project cost vs revenue at scale) and instrumentation (what the product
  already records, and which number in the analysis it could settle) — with adversarial
  verification of every load-bearing number. Each competitor comes back twice: where they leave
  the market open, and what they already do better than you, priced as something you could adopt.
  Comparable companies come back the same way — how fast they grew, and how they actually got
  their first paying customers. The analysis closes with a monitoring plan that says which way each
  axis is moving rather than which pages to re-check: the instrument that reads each axis, the
  cadence, and the decision it would change.
- **`business-plan`** — the conductor that grills the founder, runs `market-analysis` as its
  research engine, and produces the plan artifact the founder's track actually needs
  (investor memo / bootstrap operating plan / lender classic) plus a one-pager, a bottom-up
  financial model with strategy simulations (bootstrap vs raise as parallel paths, beachhead
  sequencing, profit-reinvestment loops, pre-committed switch triggers), an adversarial
  red-team pass, and a growth-engine section that turns GTM into automated per-product agent
  skills (content, screenshots/video, docs-sync). It consumes both halves of the research the
  bullet above promises: an adoption candidate is either sequenced onto the roadmap as a dated
  item or refused with the reason on the record, and the first channel is cited from what
  comparable companies actually did rather than picked out of the growth-engine's own rules.

Both write deterministically to `~/Documents/go-to-market/<product-slug>/` (same product → same
folder, re-runs update in place) and render polished, self-contained HTML + page-verified PDF
deliverables.

The pair is designed to run **workflow-heavy**: research fans out to fleets of sub-agents
(multi-modal competitor discovery, per-competitor profiling, refutation panels, a completeness
critic) with explicit model/effort tiering per stage — cheap models for the fleet, strong
models only for reconciliation and synthesis. See
`skills/market-analysis/references/orchestration.md` for the canonical workflow script.

`business-plan` dispatches `market-analysis` itself and shares its rendering reference — they
ship as a pair, always, which is why one plugin holds both.

---

## Install

```
/plugin marketplace add trinity-ai-labs/claude-plugins
/plugin install market@trinity-ai-labs
```

Then enable auto-update: `/plugin` → **Marketplaces** → `trinity-ai-labs` → **Enable auto-update**. It is off by default for third-party marketplaces.

⚠️ Updates land on a **version bump**, not on a push. `plugin.json` declares `version`, so an install is pinned to that string — CI fails the build if shipped content changes without bumping it, so this can't happen silently. See [CHANGELOG.md](CHANGELOG.md).

**To develop these skills**, clone and link each one into your skills directory instead — edits then apply live, no release step:

```bash
git clone https://github.com/trinity-ai-labs/market-skills
ln -s "$PWD/market-skills/skills/market-analysis" ~/.claude/skills/market-analysis
ln -s "$PWD/market-skills/skills/business-plan"   ~/.claude/skills/business-plan
```

Link the two skill directories, not the repo: Claude Code loads `~/.claude/skills/<name>/SKILL.md`,
so cloning the whole repo into that directory buries both `SKILL.md`s a level too deep and
registers nothing. The other thing a clone does not give you is `vault-lint` on the agent's
`PATH` — that happens only for an installed plugin, so invoke it by path while developing:
`bin/vault-lint.sh` or `bin/vault-lint.ps1`, whichever matches your session's shell tool (see
[`vault-lint`](#vault-lint) below).

---

## Use

- "Run a market analysis on this repo" / "analyze the market for <idea>" → **market-analysis**
- "Build me a business plan for this" / "how do I take this to market" / "can I get this to $20k
  MRR by next June?" → **business-plan** (which dispatches market-analysis itself)

Point either at a repo (most common), a spec/PRD/doc, or just describe the idea. Interactive
runs open on your target, then grill you on the genuine gaps — the questions research can't
answer — before spending research tokens. Everything lands in `~/Documents/go-to-market/<product-slug>/`,
including `deliverables/*.html` and page-verified `deliverables/*.pdf`.

To force one, name it: `/market:market-analysis` or `/market:business-plan`.

When dispatching sub-agents, name the skill as an explicit first step — a sub-agent won't reach
for it on its own as reliably as the main thread does:

> Step 0: invoke the `market:business-plan` skill.

---

## You state a target; the skill tells you whether it is reachable

The entry to `business-plan` is a product and a **target** — a concrete outcome and a date
(`$20k MRR by June 2027`, `replace a $90k salary in 18 months`, `sell for $30–50M in 3–5 years`)
— and the plan is engineered backwards from it. Plain language is fine: a direction with no number
gets converted into one ("make this my job" → "what does the job have to pay?"), and "no specific
number" is a legitimate answer that changes the plan's framing rather than stalling the run.

An **exit** is a supported shape, not a revenue target in disguise: it decomposes as ARR at the
sale date times a *multiple band*, and the multiple — set by your growth slope at the moment of
sale, by which named acquirer has a hole this patches, by how buildable the asset is, and by how
many buyers have that same hole — is usually what binds. Either axis can be stated as a **range**,
and a range on both is a rectangle solved at its corners rather than averaged to a midpoint: you
get back which corners clear and which do not, so you can see whether it is the value or the date
that is the problem.

The verdict on that target is **computed from evidenced drivers, not asserted**, and it names which
driver binds and by how much — "reach binds: the target needs about six times the monthly reach your
channels evidence at the hours you gave" — because that is the sentence you can act on. Where the
driver that binds is one **you chose** — your hours, your channel count, the price point you picked,
or how well what you built holds onto the people it reaches — the answer comes back as unreachable
*in that configuration*, with the value that variable would have to reach, rather than as a verdict
on the target: a constraint you could revisit this week reads very differently from one the market
sets, and you are told which of the two you are looking at. Where the evidence can't carry a verdict
at all, it says so and names the cheapest test instead of guessing: a confident "no" resting on a
guessed conversion rate talks you out of something the evidence never spoke to.

**That is a checked rule now, not a promise the skill keeps by discipline.** The verdict is stored
with the driver that binds, that driver's kind and the count of what stands under it, and
`vault-lint.sh --binding-driver` holds the rendered plan to them: a section that says *unreachable*
where the note says *unreachable at six hours a week across two channels* fails, and so does a
finding whose evidence is two deals with the same counterparty and does not say so. For nine
releases both were prose that read correctly and nothing verified — and a verdict is the one output
here most likely to make you stop, so it was the one held to the loosest standard.

That scrutiny runs in **both directions**. A cautious number is a claim about your business
exactly as an ambitious one is, so every value in the model names what drives it whichever way it
points, and a low one with nothing behind it comes back *unmodelled, not conservative* rather than
passing as prudence — half a dozen individually defensible low guesses multiplied together move a
verdict by orders of magnitude and arrive looking like a finding about your market. It points the
other way too, at the numbers that flatter what you built, and that is the harder half: a claim
that your product holds onto people better than the rest of the category, or that it is worth more
to a buyer than what they would otherwise assemble, comes with the real figure it was worked out
from and says whether the size of the effect was measured on actual users, taken from comparable
companies, or simply assumed — and an assumed one gets checked at both ends of its range like any
other number in the model. Those are the easiest figures in a plan to write and the hardest to push
back on, because pushing back on them sounds like pushing back on the product. The set of
companies you are measured against is an input too, named and tested like any other: where two
defensible comparison sets disagree about whether the target clears, you get *undetermined* and
the cheapest test that settles which one you are in. And not having launched yet is not held
against you — a driver the market sets, with no data of your own behind it, takes its value from
that indexed set with the shelf life and kill test that come with it, instead of being filed as a
guess that drags the whole plan's confidence down for a reason that is routing rather than
evidence.

A price is held to the same standard, and it is argued from **both sides** rather than one: what
the buyer would otherwise have to assemble — the tools, the integrations and the fraction of a
person who keeps the whole thing working — and what the buyer can produce with your product that
they could not before. Argued from the substitute's cost alone, the price ends up anchored to
whichever side somebody happened to add up, and that is almost always the cheaper one, because a
substitute is easy to total and an outcome is not.

An unreachable target opens a **negotiation, not a rejection**: the stated target and why it
doesn't clear, the nearest target reachable on the resources you stated, and the levers — hours,
capital, price, or for an exit the slope, the named acquirer and the date — with what each would
have to become. You choose, and the original stays visible in the plan as the thing that was
tested.

The vault is a **git repo** from its first commit, so a claim ledger's retractions, amendments and
confidence changes become a diffable history. It is local-only by default; once there are
deliverables worth sharing it asks where a remote should live and whether it is public or private,
private preselected, and creates nothing without an explicit answer to both.

The run also inventories and measures your own artifacts — repos you've written or worked in,
documents you produced for clients, products in the category you've used — rather than only
asking about them. Where those documents are confidential, the corpus records what they
establish with a provenance note, never the file itself.

It inventories what your **product** already records on the same reasoning, and before any
research is commissioned: the tables, event logs, forms and admin reports it carries, what each
one measures, and which number in the plan it could settle. A form field asking arriving users
what they came to do is first-party evidence about demand that no competitor can obtain and no
survey improves on, and its usual state is unread with the row count unknown — so whatever is
readable gets read in that phase rather than estimated for the rest of the run. What enters the
corpus is the figure, the date and the query behind it: never the rows, never a free-text answer
verbatim, and never a copy of your users' data.

---

## On disk

`~/Documents/go-to-market/<product-slug>/` **is** the vault — there is no `vault/` subdirectory.
The slug directory itself carries `.vault/config.json`, and everything else the skills produce
lives inside it:

```
~/Documents/go-to-market/<product-slug>/
├── .vault/config.json       # schemaVersion — currently 3; a directory without it is not a vault
├── _vocab.yml               # controlled subject vocabulary
├── sources/ facts/ claims/ assumptions/ questions/ decisions/ milestones/ # one file per note
├── research/                # all prose — market-analysis dimensions, product-dossier.md,
│                            #   founder-brief.md — untouched by the vault machinery.
│                            #   timeline.md is the exception: generated from milestones/
├── sources.md               # the [S#] index
├── one-pager.md  business-plan.md  financial-model.md  red-team.md # plan documents
├── deliverables/            # rendered business-plan.html/.pdf, one-pager.html/.pdf
├── market-analysis.md       # market-analysis's output —
└── competitor-analysis.md   #   owned by that skill, not business-plan
```

Why the boundary sits at the slug directory and not one level down: a source with no public
URL carries a *vault-relative* path, so anything a `source` note rests on must be inside the
vault or the path resolves to nothing — silently, since a missing file is not a malformed
field. Research prose is exactly such a source — a competitor ledger or a dimension file is
frequently the evidence itself. One level down, `research/competitors.md` would read as
vault-relative, resolve nowhere, and lint clean anyway.

It's also what makes a corpus **portable**: copy the slug directory and every citation, every
`rests_on` edge, and every research file travels with it.

**A vault created under an earlier version keeps working, and that is a promise rather than an
accident.** `.vault/config.json` carries a `schemaVersion`; a new vault is created at **3**, and a
vault at 1 or 2 is held to exactly the rules it was written under — where a check reads a field
that version does not have, it reports that the rule was not applied rather than that your
documents agree. Moving a vault up is opt-in, one version at a time, and forward-only; what each
step asks for is in
[`vault-migration.md`](skills/business-plan/references/vault-migration.md), and until you take it
nothing you already have changes.

This is a summary, not the authority — see
[`skills/business-plan/references/vault.md`](skills/business-plan/references/vault.md#layout-one-directory-per-type-one-file-per-note)
("Layout: one directory per type, one file per note") and
[`skills/business-plan/SKILL.md`](skills/business-plan/SKILL.md) for the full rules.

---

## `vault-lint`

The plugin ships two executables, `vault-lint.sh` and `vault-lint.ps1` — the same lint in
POSIX shell and in PowerShell 5.1, held byte-identical by a JSON parity gate. `business-plan`
builds a claim vault at `~/Documents/go-to-market/<product-slug>/` — every load-bearing
number traced to a dated source — and `vault-lint` is the read-only whole-corpus check that
gates it.

**Inside the note directories** it finds dangling edges, confidence that stopped propagating,
near-miss subject terms, duplicate sources, retracted notes still cited, and — on a vault at
`schemaVersion: 2` — a roadmap whose order contradicts itself, either a prerequisite scheduled
after the item that needs it or two items competing for one constrained resource while the plan
asserts they run side by side.

**Nine further modes leave the note directories and read the documents**, because the disagreement
worth catching before a render is between the ledger and the document somebody is about to hand
over: citations that no longer resolve, sections a supersession put in doubt, panel lenses that
wrote no objection row, the roadmap table against the milestone notes it was rendered from, the
verdict on your target against the drivers stored under it, whether the monitoring plan names an
axis with an instrument, a cadence and the decision it would change, the financial model's
assumptions table against the notes that declare themselves inputs to it, every cited section
against the content hash the claim recorded when it read it, and — the only mode that reads a
rendered file rather than the vault — whether a deliverable carries a vault address out to a reader
who has no vault. **`--release-gate` is all ten as one call**, which is what you run before a
render.

Claude Code puts an enabled plugin's `bin/` on whichever shell tool the session has — a
session with the Bash tool gets `vault-lint.sh` on that tool's `PATH`; a session with only
the PowerShell tool (native Windows with no Git for Windows installed, so no `sh` to run
the first one with) gets `vault-lint.ps1` instead, same flags, same output. Either way the
skills invoke it bare, from whatever directory the user happens to be working in — the
examples below show the `.sh` form; substitute `.ps1` under a PowerShell-only session:

```sh
vault-lint.sh --vault ~/Documents/go-to-market/<product-slug>
vault-lint.sh --release-gate --vault "$VAULT_PATH"
vault-lint.sh --unverified --vault "$VAULT_PATH"
vault-lint.sh --used-in --vault "$VAULT_PATH"
vault-lint.sh --supersession-sweep --vault "$VAULT_PATH"
vault-lint.sh --red-team --vault "$VAULT_PATH"
vault-lint.sh --roadmap-table --vault "$VAULT_PATH"
vault-lint.sh --binding-driver --vault "$VAULT_PATH"
vault-lint.sh --monitoring --vault "$VAULT_PATH"
vault-lint.sh --deliverable --vault "$VAULT_PATH"
vault-lint.sh --assumption-rows --vault "$VAULT_PATH"
vault-lint.sh --claim-drift --vault "$VAULT_PATH"
vault-lint.sh graph CLAIM-AS23SD44 --vault "$VAULT_PATH"
```

`--used-in` is the one that leaves the vault: a claim records the document and section it was
cited into, and this opens each one to check the file is there and the `#anchor` names a real
heading, exiting 1 when it does not. It stops at whether the citation **resolves** — whether the
section still *carries* the claim is a read, and `--help` says why a tool cannot do it.

A heading offers two addresses and either resolves. The plan templates put an explicit
`{#anchor}` attribute on every heading — `## Competition & moat {#competition}` — and that is
the one to cite, because those same templates require a heading to state the current finding, so
its text gets reworded and an anchor tracking the text would take every citation into that
section down with it. The GitHub slug of the heading text, with the attribute stripped off,
resolves too, so a vault written before its documents carried attributes keeps passing with
nothing back-filled.

`--supersession-sweep` is what makes that read a short one. Replacing a note is recorded on the
note, and nothing tells the documents that were built on the old one — so this walks every
superseded note and prints the document sections its citations reached, grouped one row per
section however many notes point at it, each row naming the note, its replacement and the reason
it was replaced. It prints the row count first, because a list you can size before you start is
one that gets read.

**Finding rows is not a failure — but nothing recording that they were read is.** A healthy
vault still exits 0 with a worklist in it, because a supersession with a blast radius is the
corpus doing its job and a mode that went red on that would teach you to ignore the exit code
the real checks depend on. What fails is the superseding note carrying no `reconciled:` date, or
one earlier than its own `created`: the sections were never read, or were read before the
supersession that put them in doubt existed. The verdict applies to a vault at `schemaVersion`
2 — a vault at 1 predates the field and exits 0 either way. It says the read happened, not that
it was done well; what it removes is skipping the read by default.

**And a supersession has two ends.** `supersedes` is written on the replacement; `superseded_by`
is the same edge written on the note being replaced, and the whole worklist is built from the
first one, because that is where the reason and the `reconciled:` date live. So a note naming its
successor in `superseded_by` where that successor never named it back used to read as *replaced
by nothing at all* — which says the record names no replacement, when in fact it names one and
only the other end is missing. That cost a real corpus a live financial-model row backed by a
dead note, with three current claims still resting on it, because nothing could see that the edge
existed and was half written. Two failures now, kept separate because the repairs are: a
`superseded_by` naming a note that does not list it back needs one line added to that note, and a
`superseded_by` naming an ID the vault does not hold needs somebody to write the successor or fix
a typo. Neither is gated on a version — both fire on the presence of the field, so a vault that
never wrote it owes nothing.

`--red-team` asks the same question of the panel. `red-team.md` carries a `## Lenses dispatched`
roster, and this fails when a lens named there wrote no objection row, or when a row names a
lens the roster does not — a lens that returned findings, saw them folded into two documents and
never wrote a row is otherwise indistinguishable from a lens that had no objections, and the
plan then cites objection codes into a file carrying none of them. The reverse direction is
checked because otherwise the gate clears by deleting a line from the roster. A vault with no
`red-team.md` dispatched no panel and passes.

`--roadmap-table` holds the plan's roadmap to the milestone notes it is supposed to be rendered
from. The plan template already says the two cannot drift — every item in that section is a
`milestone` note written before the table, and the table renders `sequence`, `moves` and
`resource` off the notes — which makes the item cell the milestone `title`, and the key a
**verbatim** match rather than a fuzzy one. A correct table matches character for character by
construction, so this needs no ID column in a document a founder hands an investor; a mismatch
means somebody edited the table by hand. It fails both ways: a row matching no milestone is an
item that escaped the ledger, so it moves no assumption anybody can name; a milestone the table
never lists is a dated change to an assumption row the plan doesn't show, so the curve has a
step the reader can't see. A vault with no milestone notes owes no roadmap and passes; one with
milestone notes and no `business-plan.md` fails. Gated on `schemaVersion` 2, where the milestone
type was added.

Only the **first** table under the roadmap heading is read, and the column headed `Item` is the
one compared — the section legitimately carries a second table (the permutation comparison of
`roadmap-sequencing.md` Rule 3, whose first column is an *order*), and a numbered roadmap puts an
ordinal ahead of the item. Reading either wrong would report every row of a correct table as an
item with no note behind it, which is the crying wolf this check was scoped out for once already.

`--binding-driver` does the same job for the verdict on your target. That verdict is stored as a
note carrying the driver that binds, that driver's kind — one of `structural`, `policy` and
`policy-within-band`, in those words and no fourth — the configuration a policy-bound one is
conditional on, and how many distinct sources and distinct counterparties stand under the driver.
This mode holds all of that against the section of the plan that renders it, and fails on four
things: a policy-bound verdict whose section states the finding and drops the configuration, a
corner table whose `Kind` cell disagrees with its note (both ways, because otherwise editing a cell
is the cheapest way out), a tail that reaches fewer than three sources or all of them from one
counterparty where the tail is not surfaced, and a rendered verdict section with no note behind it at
all. **A single counterparty is reportable however many sources there are:** three deals from one
counterparty is one relationship's terms reported as a market's, and a source count of three reads
as the opposite.

**Surfacing a thin tail takes both halves.** The note has to carry counts that match what the ledger
actually reaches, *and* the section has to carry the one line those two numbers generate —
`Evidence: 2 sources, 1 counterparty`. Counts that are right in the vault and absent from the plan
leave the problem exactly where it was: the section still reads the same as one whose verdict rests
on twenty deals across twelve parties, and the confidence letter cannot tell you which, because it
is about the weakest link and says nothing about how many links there are. The line is owed only
where the tail is genuinely thin, so a well-evidenced verdict carries nothing and this never becomes
boilerplate you learn to skip.

Both strings the plan renders off the note — the configuration phrase and the `Kind` cell — are
matched **verbatim**, so a mismatch means somebody wrote the sentence by hand — and so is the
evidence line, which is built from the note's two counts rather than searched for as a pair of
numbers, because a stray pair of digits in the same paragraph would otherwise silence the rule.
Nothing here reads your prose for sentiment or shape: the section-with-no-note check fires on the
section being there and non-empty, never on what it says. A vault with no verdict passes, and so does an existing
corpus's ceiling claim that carries none of the new fields — the fields are owed outright only under
the `target-verdict` subject, which no corpus written before that term can hold.

**The verdict section runs to the next heading of the same depth or shallower**, so a `###`
subsection under the anchor is part of it and a corner table inside that subsection is read.
Nothing asks you to keep the section flat, and nothing should: read to the next heading of any
depth, a plan that opens a subsection one line in has its table fall outside the section, the mode
compares zero rows, and the whole `Kind` half goes quiet while the run still passes. **A plan with
no corner table under the anchor is told exactly that**, and the line names the `Kind` check as not
run rather than reporting a count and *matched verbatim* — zero rows compared and zero rows
disagreeing end in the same words, and only one of them means the check happened.

`--monitoring` asks the competitor analysis which way things are moving, which is the one question
nothing else in the corpus asks. Every profile carries the date it was researched and every claim
note carries a `stale_after`, and both of those answer *is this still true* — a snapshot, and a
snapshot cannot see a direction. So `competitor-analysis.md`'s `## Monitoring plan` is a table
rather than a paragraph: one row per axis, each naming the **instrument** that reads it, the
**cadence**, and the **decision it would change**. This fails an absent section, a section with no
axis in it, and any row that leaves one of those three columns empty. Each column earns its place
by what goes wrong without it — an axis with no instrument is a thing somebody intends to notice,
one with no cadence is a re-check with no date, and one with no decision behind it is a signal
nobody acts on, which costs the same to collect as one that matters. A cell carrying no letter or
digit — an em dash, a run of hyphens — reads as empty, because that is the cheapest way past the
rule. A vault with no `competitor-analysis.md` **at its root** passes, and the line it prints names
the document it could not open and says the axes went unread — it does not tell you nobody was
profiled, because it cannot know that: that wording once printed over a vault holding 31 competitor
profiles and a fully written monitoring plan whose document simply lived somewhere else. Gated on
`schemaVersion` 2.

`--deliverable` is the only mode that reads a rendered file rather than the vault, and it exists
because the vault's rules and the artifact's are opposites. In the vault a retraction stays
visible — a struck-through line keeps its reason, because silently deleting a dead claim lets it
come back two drafts later with its cause of death erased. The reader of the PDF was never in the
room, and a note ID or a red-team `R<n>-O<n>` code is a **vault address**: it resolves for anyone
holding the corpus and resolves to nothing for the audience the document is for. Get both and you
are reading a document arguing with its own previous draft. So this reads `deliverables/*.html`
and fails on a strikethrough span, a note ID, or an objection code.

**It gates the rendered HTML, not the markdown, and that is the design.** The markdown is the
working document and keeps everything the retraction rule owes it. The HTML is what the outside
reader holds — and it is the only one a check can hold to this at all, because the fix is a
judgement: a correction reaches the artifact **restated forward**, as what is true now. Deleting
the `~~` leaves *"That multiple was actually…"* with no antecedent, which still renders, still
reads like prose, and now asserts nothing. No script can judge an antecedent, so that half is a
step in the render loop's page-by-page read-back and this is the half that is mechanical. A note
ID is matched as its type prefix plus the eight characters a generated ID carries, which is what
keeps it off `FACT-CHECKED` in ordinary prose. A vault that has rendered nothing passes.

`--assumption-rows` does the same job for the financial model that `--roadmap-table` does for the
roadmap, and it exists because the rule it inverts had no other half. The plan template requires
that no number in a projection is anything but a named assumption row — correct, and load-bearing
against fake precision — and nothing asked whether a named assumption was *missing* from the table.
On a real engagement two assumptions governing a whole revenue line existed as properly authored
notes, never became rows, and the rule meant to enforce rigour made that revenue line unable to
enter the projection at all; it was then filed as "revenue outside this model", which reads as a
modelling decision and was a consequence of the omission. Every verdict downstream inherited a
denominator missing a line the roadmap ships.

So a **live** `assumption` note that declares itself a model input — `model_input: revenue` or
`cost` — owes either a row in the assumptions table, matched on its `title` **verbatim**, or an
`excluded_from_model` reason saying why the model does not carry it. Either clears the rule; neither
is the failure. **A retired note owes neither**, and that is the same live predicate read from the
note side: demanding a row of a `superseded` or `retracted` note cannot be satisfied, because the
only escapes are to render the dead title as a row — undoing the repair the other direction asks
for — or to write `excluded_from_model` onto a corpse, recording a decision about a live revenue
line on a note nobody will open. It reads the reverse direction too, because otherwise the cheapest way past the
first check is a row nothing in the ledger stands behind. **The reverse direction reads `status`
as well as the title:** a live row whose every matching note is `superseded` or `retracted` is its
own failure, naming the note it found and the status it carries. The title match says the row was
rendered off *some* note; only the status says the ledger still stands behind it, and a projection
resting on a retired assumption has nothing ordering it in the validation queue while every check
reads green — which is what happened, a live row backed only by a superseded note, reported as
*matched verbatim* for days. **A live `claim` backs a row exactly as a live `assumption` does**,
because both are notes that assert a value and what disqualifies either is `superseded` or
`retracted`. That matters because a promotion is a repair this method prescribes: a structural
driver with no subject instrument belongs in the indexed set, so a sourced figure filed as an
unevidenced assumption gets retired and replaced by a `claim` carrying the same title. Reading only
`assumption` titles, the check called that correction a defect — every word of the failure true,
the conclusion wrong. **Those two are the whole set**, and it stays closed: a `source` or `fact` is
the provenance a claim rests *on* rather than a value the projection carries, and a `milestone`,
`question` or `decision` asserts no value at all. **And there is
one rule that is about the
target rather than the table:** where the roadmap ships a dated change to a line the model excludes,
the verdict note has to name that line in `arr_excludes` — the exit identity is ARR × multiple and
none of the multiple's inputs is ARR, so an undeclared exclusion is a denominator nobody can see.
Excluding a revenue line is legitimate; a metered layer must not be allowed to flatter subscription
churn. Excluding it silently is what fails.

**A vault where no note declares itself a model input is told that**, rather than handed a row
count and *matched verbatim*: the direction this mode was written for walks the declared inputs, so
with none of them the half that catches a missing row iterates over nothing, and the count printed
beside it belongs entirely to the other half. **And where both halves do run, the line states each
of them rather than setting one count against the other** — the two are not two sides of one
number, because a row backed by a `claim` is not a declared model input and a declared input
cleared by `excluded_from_model` is not a row, so a line reading as a comparison sends its reader
hunting for a row that was never owed.

`--claim-drift` answers the one question `--used-in` says outright it cannot: whether a section still
carries what it carried yesterday. `--used-in` checks that a citation resolves, and a heading that
nobody renamed keeps resolving through any rewrite of the prose beneath it — so a claim written into
a plan section, a later re-solve that rewrote the block, and a green gate are all consistent with
each other, and the drift gets found by hand days later or not at all.

The claim therefore records the content hash of each section it was read against, in
`reconciled_sections` beside the `reconciled:` date, and a changed hash **re-opens** the claim rather
than passing. The failure message carries the current hash, so re-reconciling is re-reading the
section and pasting one token — the tool has no write mode, and pasting the token is the assertion
that the read happened, exactly as stamping a date is. The hash ignores what a renderer ignores
(trailing whitespace, blank-line runs) so a trimmed file does not re-open the whole corpus, and it
is deliberately not a cryptographic digest: it is detecting an edit, and it has to be identical in
POSIX `sh` and PowerShell with no dependencies on either side. What it cannot tell you is whether the
section still *agrees* with the note — that is a read, not a grep. What it removes is the read
silently expiring.

Both are `schemaVersion: 3` rules, and a vault at 1 or 2 is told the rule was not applied rather
than that its documents agree. That is the whole reason the version field exists: every claim in a
finished corpus is already cited into a plan, so a hash rule that fired unconditionally would turn
every existing vault red the day the plugin updated.

`--subject-orphan` asks what the bare check asks only of `required: true` subjects, and asks it of
the rest. The note-level `coverage-gap` fires when a required subject has no claim under it and
stops there — so a subject that is optional *in general* and load-bearing *in this plan* is
invisible: the documents reason from it, the vocabulary declares it, and no note is ever written.
A subject with no note cannot collide with a contradiction, cannot go stale, cannot be superseded
and cannot be challenged, because there is nothing filed to return. Silent in every direction is
what makes it a different failure from an ordinary coverage gap, and why the two are separate
checks rather than one widened: they send their reader to different repairs.

**The mention is the whole trigger.** The mode fires on an unfiled subject only where the term or
one of its `aliases` appears in a markdown document under the vault, on a line that is not a
`subject:` line — so a vault that legitimately has nothing to say about a subject never writes the
word and stays clean, and one arguing from a subject it never filed is the state the check exists
to surface. Mentions are matched on token boundaries rather than as substrings, so `price` matches
`Price` and `price anchor` and never `priceless`. The failure names the subject, the document, the
line number and the line itself, and then says which note to write — this is the one check that
turns an existing corpus red on upgrade wherever it carries the gap, and a red gate whose message
is a diagnosis is a five-minute fix while one that is only a verdict is a support request. It is
gated on no `schemaVersion`, because it reads no field a corpus written before it lacks.

`--release-gate` is the call before a render, and the only one that asks every question. It is
**ten parts** — the bare check plus `--used-in`, `--supersession-sweep`, `--red-team`,
`--roadmap-table`, `--binding-driver`, `--monitoring`, `--deliverable`, `--assumption-rows` and
`--claim-drift` — and it prints each under its own heading and exits with the worst status any part
returned, so the gate is clean only when every part is. The alternative was several calls made from
memory, and which of them actually ran was a matter of recall.

**The bare run's success line says what it checked and what it did not**, because it used to say
`clean` and a corpus with dozens of dead anchors printed exactly that. It reads *note-level
checks passed … not opened: citation targets, supersession blast radius, panel objection rows,
roadmap table against the milestone set, verdict drivers and the evidence under them, monitoring
axes and the decision each would change, what the rendered deliverable carries out of the vault,
assumption rows against the model table, cited sections against their recorded hash* —
and the list of what it skipped is read off the same mode table `--release-gate` composes itself
from, so a mode added to the gate cannot leave the line quietly overstating what it covered. A
success line is what somebody renders on, so it has to be narrower than the verdict its reader
wants it to be.

Both implementations are zero-dependency — `vault-lint.sh` is POSIX `/bin/sh`, `vault-lint.ps1`
is Windows PowerShell 5.1, and neither reaches for Node, Python or jq. A tool that reads an
entire private business corpus should not carry a transitive dependency tree, and a runtime
prerequisite discovered at the moment of use is a broken product — which is also why each
implementation is the shell that ships in-box on its platform rather than one a user must
go install.

---

## Repo layout

```
.
├── .claude-plugin/plugin.json
├── .github/workflows/ci.yml   # each step's comment names the failure it prevents
├── bin/
│   ├── vault-lint.sh          # SHIPPED — on the agent's PATH, POSIX sh
│   └── vault-lint.ps1         # SHIPPED — on the agent's PATH, PowerShell 5.1
├── scripts/                   # contributor-only, never loaded
│   ├── check.mjs              # the repo gate
│   ├── fixtures/              # vault-lint's own suite: run-fixtures.sh + its corpora
│   └── parity/                # parity.mjs — diffs the two bin/ scripts' output
└── skills/
    ├── market-analysis/
    │   ├── SKILL.md           # the conductor: phases, run modes, quality bars
    │   └── references/        # dimensions · templates · orchestration · rendering
    └── business-plan/
        ├── SKILL.md           # grill → dispatch → draft → red team → render
        └── references/        # grill · plan-template · strategy-sim · growth-engine · vault
```

Contributing: see [AGENTS.md](AGENTS.md).

---

## License

MIT — see [LICENSE](LICENSE).
