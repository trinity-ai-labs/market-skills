---
name: business-plan
description: Use when a product — a code repo, a spec/doc, or an idea — needs a business plan or a path to market: monetization, go-to-market, pricing, financial projections, milestones, risks. For market research alone, use the market-analysis skill instead.
---

# Business Plan — Conductor

Turn a product into a plan a founder can execute and an investor can't wave away. You are the
conductor: your context is for grilling the founder, judging sub-agent returns, and writing the
plan. Heavy research never runs in your own turn — the market-analysis skill is your research
engine, and its fleet does the digging.

The core principle: **a plan is a decision document, not a brochure.** Every load-bearing
assertion is registered as an atomic note in a **vault** — a claim ledger in the user's own
directory — so the corpus can tell you what it no longer knows.

## The invariants — stated first because compaction re-attaches only the head of this file

An invariant written inside Phase 4 is not in context when Phase 4 runs. So everything that
must hold in a later phase is stated here, once, and the phases below only say where it
applies. Each line names the failure it prevents; the reference behind it carries the detail
and is never restated here.

**Evidence discipline**

1. **Every market fact is imported by reference, never re-derived.** It resolves through
   `sources.md`, the founder brief, or a vault note, with its confidence tag intact. A number
   that traces to nothing is narrative wearing evidence; flag it, don't let it stand.
2. **A claim that the subject "has no X" is unactionable until checked against source.**
   Milestone fields, issue titles and backlog labels are not evidence of absence.
3. **Names describe conditions, not costs — and a reading describes one too, never its cause.**
   Enum values, type lists and field names say what raised a thing — never how often, how badly,
   or at what cost to the user. An instrument's reading is the same kind of evidence: **before a
   metric is cited as evidence for a mechanism, state what else produces that number.** A count says a thing exists; it never
   says why. Where the alternative explanation is not excluded the metric is a description and
   not evidence — and a metric chosen *after* the conclusion is a conclusion wearing an
   instrument. That second clause is the one worth writing down: a careful reader supplies the
   alternative explanation anyway, while an instrument selected to fit a thesis already reached
   leaves every step downstream of it locally sound. The tell is a second metric introduced to
   confirm the first; chosen after the thesis, it tests the thesis's fit to the instrument
   rather than the mechanism.
4. **Evaluate the bundle, not the columns.** A product whose thesis is integration always
   scores as commodity on a per-capability grid, so the matrix gets supplemented, never trusted
   alone.
5. **Set the lens before reading the facts:** entity → product truth → interpretation. A corpus
   can be sound in its research layer and wrong in its plan layer purely because the scope was
   set by the wrong entity.
6. **M&A and corporate events are a standing sweep, not a per-session option** — mandatory
   whenever the plan reasons about an exit, a category leader, or a competitor's trajectory. A
   category's ownership can change between two sessions; a plan that missed it argues against a
   company that no longer exists in that form.

**The vault** — schema, edges and the six-step authoring checklist are in
[references/vault.md](references/vault.md). Point at it; never restate it.

7. **The vault is a ledger over the prose, not a replacement for it.** Research files stay
   exactly as they are; each phase additionally emits a note per load-bearing output. Prose
   citing `[S4]` inside a sentence resolves forward and nowhere else, so an amended source lands
   in one file while four documents downstream stay confidently wrong.
8. **IDs are `TYPE-` plus eight random alphanumerics, with no registry and no counter.** Two
   parallel researchers never coordinate. A sequential scheme makes collision procedurally
   avoided, and the procedure is exactly what parallel researchers skip.
9. **Block lists, never inline flow lists.** Obsidian rewrites `[A, B]` into block form when it
   saves, so a vault authored inline loses every edge the moment somebody opens a note — and
   the blast-radius query then returns a clean result over a corpus it can no longer see.
10. **Coerce nothing.** Every frontmatter value is a string: quote every date and anything
    containing `: `, and omit a key rather than writing an empty list. A reader that coerces has
    to reproduce YAML's rules exactly, and no two implementations agree on them.
11. **Confidence is derived — `min(confidence_own, every rests_on target)`.** Without it a
    hedged source becomes a fairly confident fact becomes a flat headline claim: every hop
    locally reasonable, the hedge gone by the third, asserted to a stranger who will act on it.
12. **`rests_on` is required on a `fact`.** A fact with no source is an unverified claim wearing
    the word "fact", which is the note people cite without hesitating. Phase 1's grilled facts
    therefore need a `source` note for the interview itself before any of them can exist.
13. **A claim's `subject` is a term from the vault's `_vocab.yml`**, seeded from
    [references/vocabulary.yml](references/vocabulary.yml). Free-text subjects are the same as
    no subjects: two researchers write `wtp` and `willingness-to-pay`, and the collision that
    would have surfaced their disagreement never fires.
14. **Retraction is visible.** A retracted note stays with `status: retracted` and its reason;
    a withdrawn line in the prose is struck through with the reason. Silent deletion lets a dead
    claim return two drafts later with its cause of death erased.
15. **Lint is a gate, not a report.** The shipped `vault-lint.sh` runs at Phase 2's
    per-dimension checkpoint, while the authoring context is still live and a fix costs one
    turn, and again in Phase 5 before anything renders. A plan citing a retracted source does
    not render. **That same gate reads the dimension's own file, never the summary its author
    wrote about it** — the researcher who wrote the prose also minted the notes the plan resolves
    citations through, so accepting a dimension on its summary is what puts an unreviewed number
    in the ledger.

**The target** — the driver identity, the binding-driver readout, the confidence ceiling, the
nearest-reachable solve and the negotiation script are in
[references/target.md](references/target.md). Point at it; never restate it.

16. **A target verdict is computed from evidenced drivers, never asserted, and never at high
    confidence — and a verdict whose binding driver is `policy` rather than `structural` is
    negative for the stated configuration only, never for the target.** Asserted instead of
    computed, a verdict is an opinion in the shape of a finding: unarguable, untestable, and
    carrying the vault's authority into a forecast about a future nobody has run. Reported
    without its driver's kind, a policy-bound "unreachable" stops a founder over a decision they
    could revisit this week, in the same words and at the same confidence as a constraint no
    decision of theirs can move.

17. **The vault is a git repo (Phase 0): commit at every meaningful write, regenerate the vault's
    `README.md` in the commit that changes a fact it states, and where a remote exists — the
    Phase 5 consent gate — push every commit.** Phase boundaries are too coarse a unit of loss for
    a phase that writes dozens of files: a crash mid-phase should cost one file, not a day of
    research. They are the same wrong unit for the generated README, which states the current
    target and its verdict status while both move *inside* Phase 3 — so pinned to the boundary it
    spends most of a phase asserting what the ledger beneath it has already superseded, and it
    reads as current because its last line says it is generated rather than hand-edited. The
    fields whose change triggers a regeneration are named in the output contract below, so the
    rule is decidable at commit time without re-reading the file. A remote is created only on the
    founder's explicit answer to both destination and visibility, and past that an unpushed commit
    is worse than no remote — it reads as a backup, so the founder believes the corpus is in two
    places while it is on one laptop.

18. **Every input to a steady-state ceiling and every target driver is labelled `structural` or
    `policy` — those two words — and any ceiling or verdict whose binding input is policy is
    stated as the result of that configuration, with one changed policy value shown beside it.**
    Unlabelled, the skill lets a founder's decision become a law of nature and reports the
    consequence as physics, and a number reported as physics is one nobody argues with. The
    ceiling's half of this is in [references/plan-template.md](references/plan-template.md), the
    verdict's in [references/target.md](references/target.md).

19. **Nothing is dispatched to the red team until the plan and the vault have been reconciled.**
    Lint runs at Phase 2's per-dimension checkpoint and again in Phase 5 before rendering;
    between drafting and the panel there is nothing, and a panel briefed on a plan the ledger has
    already moved past returns objections about a version nobody is shipping, at full panel cost.
    Three steps, and the third is the gate — the first two bound it rather than replace it.
    `vault-lint.sh --used-in` **fails**: a citation resolving to a file or a section that is not
    there is not a judgment call. `vault-lint.sh --supersession-sweep` **emits the worklist** —
    every section a supersession put in doubt. Then **the read**: every `current` claim whose
    `used_in` names a plan document is reconciled against that document, and every superseded
    claim's `used_in` targets are re-read. It is a read and not a grep, because plan prose cites
    `[S#]` and `[F#]` codes while a claim carries no code at all, so nothing mechanical can tell
    whether a section still says what the note says. The two lint calls are what keep the read
    bounded and therefore done: a reconciliation stated as "check the plan against the vault" is
    a task nobody can size, and a task nobody can size is a task nobody starts. The gate sits on
    the dispatch rather than the phase boundary, because a panelist already briefed cannot be
    un-briefed.

20. **A claim is not finished when the note is written; it is finished when the prose it names
    carries it.** Writing the note and writing `used_in` are one act, and the claim stays open
    until the section `used_in` names actually says what the note says — invariant 19 is where
    that gets read. This is an invariant rather than a Phase 3 step because the obligation
    outlives Phase 3: the vault keeps growing through drafting and into the red team, and a
    claim minted while the panel is running is subject to it exactly as one minted while the
    plan was being written. Written into the drafting phase, the rule would stop applying at
    the moment the vault is most likely to move. Without the loop, carrying a new claim into the
    prose becomes something the conductor has to remember rather than something the phase
    requires, and what gets remembered is whatever was minted most recently — leaving a corpus
    that knows something its own documents do not say, where every note is individually correct
    and the plan is quietly out of date.

21. **The grill closes as a phase, not as a channel.** Founder input arriving after Phase 1 is
    normal rather than exceptional, and it gets the treatment anything said during the grill
    gets: the same `fact` note resting on the interview `source`, the next `[F#]` in the
    existing sequence, an appended row in `research/founder-brief.md`, and invariant 20's
    propagation obligation like any other claim. The numbering continues and the brief is
    appended rather than rewritten — `[F#]` codes are cited from the plan by number, so a
    renumber silently repoints every citation already written. How a late fact is recorded is in
    [references/grill.md](references/grill.md#a-fact-arriving-after-the-grill-is-recorded-exactly-as-one-said-during-it).
    The failure this prevents: the evidence a founder volunteers late is the evidence nobody
    thought to ask for, which makes it the least redundant material in the corpus and exactly
    what a model with no channel for it drops. It arrives conversationally during Phases 3 and 4
    and lands nowhere — no `[F#]`, no note, no propagation obligation, because the phase that
    owned founder input is over — so it reaches the plan as something the conductor happened to
    remember, or not at all.

## Output contract — deterministic home

Same folder the market-analysis skill uses (same slug rule — repo directory name or settled
product name, kebab-case; re-runs update in place, never a new folder):

**The engagement folder IS the vault.** There is no `vault/` subdirectory — the slug directory
carries `.vault/config.json`, and everything else lives inside it:

```
~/Documents/go-to-market/<product-slug>/  # ← this directory is the vault
  .vault/config.json        # schemaVersion — a directory without it is not a vault
  _vocab.yml                # controlled subjects, seeded from references/vocabulary.yml
  sources/ facts/ claims/ assumptions/ questions/ decisions/   # one file per note, <ID>.md
  research/                 # ALL prose, untouched by the vault — market-analysis dimensions,
    product-dossier.md      #   profiles/, plus these two written here in Phase 0 / Phase 1
    founder-brief.md        #   the grill's numbered [F#] facts — the plan cites these
  sources.md                # the [S#] index (market-analysis)
  one-pager.md              # the door-opener — always produced first, every track
  business-plan.md          # the main artifact — SHAPE DEPENDS ON TRACK (see below)
  financial-model.md        # assumptions table + scenarios, referenced by the plan
  red-team.md               # the panel's objections + dispositions (Phase 4)
  deliverables/
    business-plan.html      # rendered deliverables (Phase 5)
    business-plan.pdf
    one-pager.html
    one-pager.pdf
  ...market-analysis files (market-analysis.md, competitor-analysis.md — owned by that skill)
```

**Why the boundary sits here and not one level down.** A source with no public URL carries a
*vault-relative* path, so anything a `source` note can rest on must be inside the vault or the
path resolves to nothing — silently, since a missing file is not a malformed field. Research
prose is exactly such a source: a competitor ledger or a dimension file frequently *is* the
evidence. With the vault one level down, `research/competitors.md` reads as vault-relative,
resolves to a path that does not exist, and lints clean.

It also makes the corpus **portable**: copy the slug directory and every citation, every
`rests_on` edge and every research file comes with it. A ledger whose evidence lives outside it
is an index, not a ledger. The lint ignores non-note files at the vault root, so the plan
documents and `sources.md` sit inside without interfering.

Layout rules:
[references/vault.md](references/vault.md#layout-one-directory-per-type-one-file-per-note).

Templates AND the track branch (venture memo vs. bootstrap operating plan vs. lender classic —
investors don't read 40-page plans; the classic genre survives only for banks/grants):
[references/plan-template.md](references/plan-template.md). Load it before drafting.

The market-analysis skill's root is `~/.claude/skills/market-analysis` (fallback:
`~/.agents/skills/market-analysis`) — every cross-skill reference below resolves against it.
`~` is shorthand in this document only: expand to the absolute home path in every path you
pass to a tool or an agent brief.

## Phase 0 — Ground

Resolve the slug per market-analysis's slug rule (repo → analyzed directory name, settled
name wins; for an idea with no name, do NOT write any file — settling the name is the first
grill turn). Look inside `~/Documents/go-to-market/<slug>/` (and `ls` the parent for an existing
folder naming the same product). A market analysis already there is prior work: **reuse** if
the dossier still matches reality and `_Analyzed:` is under ~90 days old in a fast-moving
category (AI tooling, consumer apps) or ~12 months otherwise; between those, run the
competitor-analysis Monitoring plan re-check (pricing pages, changelogs) as a partial refresh
and note it in Coverage; past them, or if the product's stage/boundary moved, plan a full
refresh.

**Scaffold the vault before anything writes.** The vault path IS the slug directory — never a
`vault/` subdirectory under it. Create the tree above, write `.vault/config.json` with its
`schemaVersion`, and copy [references/vocabulary.yml](references/vocabulary.yml) to
`<slug-dir>/_vocab.yml` — a copy, not a pointer, so a vault stays checkable against the
vocabulary it was written under after the skill ships new terms. The copy carries the shipped
file's `vocabulary_version`, which is what makes a vault scaffolded today report no drift on its
next run. Extend it by that file's governance rule; never delete or redefine a base term on the
vault's own authority — an amended base definition is adopted only through the reconciliation
below, after the claims under it have been re-read.

Pass the absolute vault path to every agent and tool: resolution is `--vault` or `VAULT_PATH`
and nothing else, because an upward search from a repo either walks to the filesystem root or
finds a *different* engagement's vault and reads the wrong corpus with no error at all. An
existing vault is reused, not re-scaffolded, and a `schemaVersion` this skill does not
understand stops the run rather than being half-read.

**A reused vault's `_vocab.yml` is compared against the shipped
[references/vocabulary.yml](references/vocabulary.yml), and an amended base definition is
reported to the founder as a version delta plus the log entries inside it.** The copy is what
keeps a vault checkable, and it is also what freezes it: the lint reads the vault's copy and
never the shipped file, so a vault scaffolded before an amendment keeps the superseded wording
indefinitely and nothing says so. This phase is the one point where both files are open, which is
what makes the comparison free. Compare the vault's `vocabulary_version` against the shipped one
— a copy carrying **no** stamp predates it and is older than every entry, never equal to the
current version — and report each `amendments` entry between them: the term, both framings
(`was` and `now`), and the `must_assert` test. Reporting only that definitions differ is what
makes this advisory get skipped: it hands the founder a corpus-wide re-read with no way to size
it, and a task nobody can size is a task nobody starts, so the drift stays unreconciled and the
report becomes noise. It is **not** an error and does not stop the run — a vault written under an
older definition is valid, it is only unreviewed, and erroring would break every existing vault on
upgrade, which is the failure that makes people stop upgrading. What the report asks for is a
re-read of the claims filed under each amended subject, bounded by one grep per term: where a
claim no longer asserts what the amended definition says the subject asserts, it is superseded
under the standing two-edit rule rather than silently re-filed under a definition it was not
written to. The procedure, the worked `steady-state-ceiling` example, and the order that makes
adopting the new wording safe are in
[references/vault-migration.md](references/vault-migration.md#an-upgraded-vault-enters-here-not-at-stage-1--reconcile-the-claims-an-amended-definition-left-behind).

If the founder already has a corpus from earlier work — research files, a plan citing `[S#]`/
`[F#]` codes — adopt it instead of scaffolding an empty vault:
[references/vault-migration.md](references/vault-migration.md).

**The vault is a git repo from its first commit** (invariant 17). Run `git init` at the slug
directory — the vault root, never a subdirectory of it. There is no remote and therefore no
exposure, and a claim ledger is what this pays off on immediately: `vault-lint.sh` says what the
corpus asserts now, `git diff` says what it stopped asserting, and nothing else in the skill
answers the second question. An existing repo is left alone: running `git init` over one is a
no-op, but a re-scaffold that rewrites its files is not.

**What counts as a meaningful write**: a dimension's prose and notes, a batch of grill facts, a
drafted section. The phase-boundary commit keeps its own job on top of those — it is where
`.gitignore` is regenerated, and it is one of the points where `README.md` is.

Two files are **generated** at scaffold, and their cadences part after that, because only one of
them tracks what the corpus asserts: **`.gitignore` is regenerated at every phase boundary and
committed there; `README.md` is regenerated in the same commit as any write that changes a fact it
states** (the fields are named below). Neither is hand-edited.

- **`.gitignore`** — editor and OS state only: `.DS_Store`, and an editor's per-window workspace
  file (Obsidian rewrites `.obsidian/workspace.json` on every open, so unignored it makes each
  commit noise and buries the ledger changes the history exists to show). Never ignore a dotfile
  wholesale: `.vault/config.json` is what makes the directory a vault, and a clone without it is
  not one. **Rendered `deliverables/*.pdf` are committed, not ignored** — they are the artifact a
  shared vault exists to share, and a repo whose deliverables are ignored hands a recipient the
  working notes and none of the output.
- **`README.md`** at the vault root — what the product is; what this corpus is and which skill
  produced it; the note-type map (the six types and what each asserts); where to start reading
  (`one-pager.md`, then `business-plan.md`); the current target and its verdict status; which
  phase the corpus is in; and the `vault-lint.sh` invocation for checking the corpus. Its last
  line states that it is generated and regenerated rather than hand-edited. Without it a shared
  vault is a directory of `CLAIM-AS23SD44.md`-style filenames — deliberately bare IDs, legible to
  this skill and opaque to a human opening the repo cold.

  **Four of the things it states move while a phase is running, and a write that changes one of
  them regenerates the README in its own commit:** the current target, its verdict status, which
  phase the corpus is in, and the note-type map when the corpus starts asserting a type it did not
  carry before. They are named rather than left as "anything the README says" so the rule is
  decidable at commit time: an agent about to commit checks its own write against those four, and
  a rule that instead required re-reading the generated file before every commit is one that gets
  skipped. Nothing else the file carries — the product description, the reading order, the
  `vault-lint.sh` invocation — moves after scaffold, so most commits touch none of the four and
  leave the README alone. That floor is the point: a README rewritten on every commit buries the
  ledger changes the history exists to show, which is the failure `.gitignore` above exists to
  prevent. The phase boundary stays a regeneration point — crossing one changes which phase the
  corpus is in — but it is no longer the only one. Between boundaries is where the damage was: a
  target renegotiated mid-Phase 3 and a verdict re-solved by the reference-class re-flip each move
  one of the first two fields, so under the old cadence the file spent most of a phase stating a
  settled-looking target the ledger underneath it had already superseded, with nothing marking the
  disagreement. A stale README on a shared repo is worse than none, because it reads as current.

Then build the dossier: run the **market-analysis skill's Phase 0 only** — a cheap
dossier-building pass (explore agents on a repo; drafting from a doc/idea), no research fleet —
writing it to `research/product-dossier.md` (vault-relative — the slug directory is the vault). The grill needs the dossier's value
hypotheses to exist; nothing else of market-analysis runs yet.

**Sweep for founder-authored writing before the grill — it is the cheapest context you will
ever get.** Blog, changelog, README, docs, talks, launch threads, issue bodies. Founders
routinely explain their own reasoning in public and then never mention it, because to them it
isn't news. Skipping this sweep means grilling for things already written down and, worse,
missing the founder's own framing of why the product is shaped as it is. Anything found lands
as `[F#]` with its URL, and as a `source` note carrying that URL.

**The dossier is the plan's product-truth spine — thinness here propagates everywhere.** A
dossier that is *true but small* is more dangerous than one that is wrong, because nothing in
it trips a check and every downstream document inherits its omissions. Two habits prevent it:
size the dossier against the product's own documentation (if the product's user guide for one
surface is longer than your whole dossier, the dossier is not done), and **organise it around
seams — what is true only because these parts are in one system — with the capability
inventory demoted to an appendix.** A per-capability list is the wrong instrument for any
product whose claim is integration, and it will make an integrated product read as a pile of
commodities.

## Phase 1 — Grill the founder

The market analysis can research everything except what's in the founder's head. Before any
dispatch, grill — like a partner who's about to co-sign the plan, not a form. **One question at
a time, each with your recommended answer and why — the message ends on the ask, never on a
preview of the questions still coming.** Pre-answer what the repo/doc/context
already answers. Full question bank with per-question defaults:
[references/grill.md](references/grill.md) — load it now. The areas that gate everything
downstream:

- **Target** — opens the grill: the concrete outcome and the date the plan is engineered
  backwards from, asked first because every other answer is read against it. A direction with no
  number is converted, not accepted ("make this my job" → "what does the job have to pay?"), and
  "no specific number" is a legitimate answer that gets recorded as one. What is computed from
  it: [references/target.md](references/target.md).
- **Pointers & background** — anything to point the research at (docs, prior research,
  competitor lists, community threads) and any background the source can't show.
- **Ambition** — lifestyle business, bootstrapped-profitable, or venture-scale? Changes every
  downstream recommendation; never assume.
- **Value-hypothesis defense** — the per-VH test questions from the Phase 0 dossier (the
  sharpest part of the grill).
- **Feature conviction** — which features the founder finds most valuable, ranked; their
  ranking versus where the product's effort went is either confirmation or the grill's
  sharpest divergence.
- **Monetization intent** and price instinct.
- **Resources** — team, runway (months, not dollars, if they prefer), hours/week, capital
  available or sought.
- **Unfair advantages** — distribution, audience, domain expertise, tech head start.
- **Constraints & appetite** — geography, compliance lines, will they do sales calls, content,
  paid ads?
- **Automation appetite** — how much of the growth engine gets automated, and the founder's
  no-automation line (feeds the plan's Growth engine section).
- **Timeline** — when does the first dollar need to arrive?

**Posture is inferred, never asked.** Read it off the first substantive answer: a founder who
cannot evaluate the options gets six forks — ambition, audience, capital path, pricing model,
beachhead, motion — as decision briefs per
[references/decisions.md](references/decisions.md), and everyone else gets the bank above in
the same number of turns. The tell, the six forks, and the `fact` note that records the posture:
[references/grill.md](references/grill.md#record-the-posture-as-a-fact-because-it-changes-how-every-later-answer-is-read).

Call out bad answers when you see them — a venture-scale ambition with 4 hours/week, a price
instinct 10× under the category's floor, "no competitors". Push with reasoning; a wrong premise
you let through makes the whole plan fiction.

**If the founder declines the grill** ("no time — just build it, assume whatever you need"):
don't insist, and don't default silently. Send ONE non-blocking message carrying only the two
decisions that select the document itself — ambition and audience — each as a recommended
default they can flip in a word, then proceed without waiting. Every other question's default
becomes an `assumption` note carrying its `sensitivity` and a `validated_by` step, listed in
`founder-brief.md` tagged `assumed — no grill` (default · why · what changes if wrong). The
declination is itself an `[F#]` fact, and the plan opens with the assumption list so reading the
plan becomes the grill. The red team still runs — with no grill it's the only adversary the plan
ever met.

**The grill's output is notes, not only a table — and the order matters.** Write ONE `source`
note for the interview FIRST, with `url` and `url_canonical` both set to the vault-relative
path `research/founder-brief.md`
([the source note](references/vault.md#the-source-note-keeps-the-quote-that-outlives-the-url)
covers a source with no public URL that way). Only then does each grilled answer become a
`fact` note resting on it — invariant 12 is what makes the order load-bearing: emit the facts
first and every one is either invalid or points at an ID that does not exist yet. Quote the
founder's own words in the body; a paraphrase is a judgement nobody can re-check. Fields and
the six-step checklist:
[references/vault.md](references/vault.md#writing-a-note-the-six-step-checklist).

A fork raised to a decision brief closes as a `decision` note in `decisions/` — the same
artifact, with the extra fields
[references/decisions.md](references/decisions.md#the-record-extends-the-vaults-decision-note-it-does-not-replace-it)
defines. There is no second record and no parallel directory.

Close the grill by writing `research/founder-brief.md` — the numbered fact table
(template in [references/plan-template.md](references/plan-template.md)) every `[F#]` citation
in the plan resolves through, exactly as `[S#]` resolves through `sources.md`. `[F#]` stays the
human-readable citation; the `fact` note ID is what a query reaches. It's written BEFORE any
dispatch, and Phase 2's brief carries it verbatim so F-numbers stay stable everywhere.

**Closing the grill closes the phase, not the channel** (invariant 21). What the founder says in
Phases 3 and 4 is recorded exactly as what they said here was, and the brief is **appended** to
rather than rewritten — every `[F#]` already cited keeps its number, which is the whole reason
the file is written once and only ever grows.

**Then compute the provisional verdict, before the research fleet spends anything** — the dossier
and the grill already carry every driver the identity needs, at assumption strength. Put it to the
founder as the "want to talk about this now, or should I go find out properly?" turn, which is
only cheap while nothing has been spent. Method and note type:
[references/target.md](references/target.md).

## Phase 2 — Run the market analysis

The research engine is the **market-analysis skill**, run brief+skill style: load its SKILL.md
from the skill root and execute **Phases 1–4 only** (Phase 0 already ran; skip its Phase 5
deliverables and its user-facing close — you render in your own Phase 5, and its analysis PDF
is rendered only if the founder asked for a standalone one in the grill). Its research
fan-out runs as its own workflow fleet per its `references/orchestration.md`, so your
conductor context stays lean. Default to running it yourself in-session; hand it to ONE
executor agent (model: `opus`, effort high) only when you've confirmed this harness lets
dispatched agents spawn agents. Either way, the brief is this verbatim contract (the fields
market-analysis's own "Dispatched brief contract" requires):

```
MODE: dispatched
Do NOT ask the user anything — Phase 1 is satisfied by the founder brief below; every
remaining gap becomes an entry in the report's Assumptions section.
Run: market-analysis Phases 1–4 only. No deliverables, no user-facing close.
slug: <slug> · outDir: <absolute path> · date: <today> · source: <repo path | doc | idea text>
vault: <absolute path to the vault scaffolded in Phase 0>  — emit notes per its vault note
  contract; the research prose is unchanged.
ambition: <venture | bootstrap | lifestyle | lender>  — bootstrap/lifestyle: skip the top-down
  sizing agent, bottom-up only (the venture-scale sniff test still gets stated); else full rigor.
target: <the outcome the plan is engineered backwards from, and its date | "no specific
  number">  — size at the resolution this needs: a target denominated in customers or MRR makes
  the bottom-up segment count the load-bearing output, not the top-down category figure. A range
  stated on either axis is passed as the range, both ends, never as a midpoint: the verdict is
  computed at the rectangle's corners, and a fleet handed a point researches one date at one value.
provisionalVerdict: <reachable | unreachable | undetermined, and the SET of drivers the identity
  named as binding, each with its own kind — structural | policy. Where either axis was stated as a
  range that is one entry per corner solved, each naming that corner's binding driver and kind;
  where the target is an exit it is a set by construction, because the multiple's four inputs carry
  their own kinds — growth slope at the sale date and the named acquirer are policy, scarcity and
  the bidder count are structural. | "none — no target stated">  — pre-research, so it is an
  assumption and never citable; the drivers it names are the ones to research hardest, and each
  kind says what "hardest" means for that one. A structural driver wants better evidence for the
  value it already has; a policy one wants evidence for what it could be set to — channel
  throughput, and which comparable strategies at this stage were adoptable at all — which is a
  different hunt pointed at different sources. **Emitting one kind for a verdict computed over four
  drivers picks one hunt and silently drops three**: the fleet comes back thorough on the driver
  that was named and empty on the one that binds, and the gap is invisible because the dimension it
  belonged to still returned a file.
categoryBoundary: <the boundary from the Phase 0 dossier, or "undecided — you call it">
mustProfile: <competitors the founder named — always profiled, whatever their kind>
founder brief (verbatim):
<founder-brief.md content>
```

Reuse from Phase 0 applies: a fresh, matching analysis skips this phase entirely — verify it
against the checklist below and move on.

**Only the load-bearing outputs atomise.** Each dimension emits a `source` note per citable
source and ONE `question` note carrying its `gaps` — what the dimension could not answer — plus
`covers` once something answers part of it. The prose keeps every argument; the notes hold what
a later document leans on. A note per paragraph produces a second corpus nobody maintains.

**Read the dimension and lint the vault at the per-dimension gate, not at the end.** As each
dimension returns, two things happen before you accept it. Read its `research/<dimension>.md` on
the terms market-analysis's Phase 2 sets out — the file, not the summary its own author wrote
about it; accepting a dimension on that summary is what lets an unreviewed writer put a citable
number into this ledger, since the same researcher minted the `source` notes the plan resolves
its citations through. Then run `vault-lint.sh` over the vault. A missing `rests_on`, an unknown
subject term, a duplicate `url_canonical` and a confidence-propagation violation are all silent
in the file itself and all cheap to fix while the researcher's context is live. Deferred to
Phase 5, an unknown subject term is unfixable — the only person who knew which existing term it
belonged under is gone. Resolve it by finding that term; adding a new one to silence the error
skips the question the error existed to ask.

**Verify the return — architect-style, against the contract, before you build on it:**

- All contract files exist in the folder (dossier, market-analysis, competitor-analysis,
  sources, research/) and follow the templates' headings.
- Every headline number is a range with an H/M/L tag and resolves through `sources.md`.
- The whitespace recommendation is specific and falsifiable — not a restatement of the product.
- The competitor set includes the rivals the founder named in Phase 1 (or says why not).
- `competitor-analysis.md` carries an `## Observed growth band`, both endpoints labelled with
  their competitor, its two dated traction points and its stage. Without it a run passes every
  other check on this list and Phase 3's implied-growth test then points at a section that was
  never produced — a check that silently does nothing is worse than one that was never written.
- `research/growth-curves.md` exists, and `market-analysis.md` carries its `## Comparable growth
  curves` section: the series indexed to months since origin, each company's origin event named,
  and the companies held out of the indexed overlay listed rather than dropped. The band says how
  fast comparables grew; only the indexed set says *when*, which is what a dated target asks.
  Without the file Phase 3's shape check has nothing to place a trajectory against and degrades
  back to the level check it exists to extend — silently, since the level check still runs and
  still passes. An origin left unnamed makes two series incomparable while they sit on one axis
  looking comparable, and an exclusion left off the list reads as a comparable nobody found rather
  than one whose origin could not be dated.
- **Where the settled target is an exit**, `market-analysis.md` additionally carries its `## Exit
  comparables & implied multiple` section: the disclosed acquisitions in the category, each indexed
  to the acquired company's growth slope at the moment of sale, the multiple each one implies, and
  the band's two ends traced to the four inputs
  ([references/target.md](references/target.md#the-multiples-inputs-have-homes-too-and-not-one-of-them-is-arr)
  homes them). Check that the set is indexed *to slope* rather than merely listed — multiples with
  no slope beside them cannot be read at this roadmap's slope, so a list of them is a category
  average wearing a reference class's name, which is the shape a run returns when it looked the
  question up instead of building the set. Without the section an exit run comes back with the
  indexed curves, passes every other check on this list, and Phase 3 then solves the exit identity
  at a multiple nobody sourced — the term the verdict is most sensitive to, and the one the flip
  test exists to fire on. Naming the artifact is what does this work: the first line's "all
  contract files exist" is satisfied by a folder listing, and a folder listing cannot tell an exit
  run from a revenue one.
- `Coverage` names what was skipped and why; `Risks to this analysis` is non-empty (a market
  analysis with nothing soft in it wasn't done honestly).
- `Assumptions` is present and non-empty for a dispatched run — each entry states the default,
  why, and what changes if wrong. An empty Assumptions section from a headless run means gaps
  were guessed silently.
- `Value hypothesis verdicts` covers every VH in the dossier (confirmed / weakened / refuted /
  untested) — Phase 3's Solution section may only build on confirmed ones.
- Lint is clean, and every dimension left a `question` note. A dimension with no gaps is a
  dimension that did not look.

A failed check goes BACK with a sharper brief ("the sizing is single-sourced top-down — re-run
bottom-up per the playbook"), not patched by you. Judge and direct; don't do the fleet's job.

## Phase 3 — Draft the plan

**Query the vault instead of re-reading the corpus. This is what the vault is for.** The
drafting input is the index — every `current` claim with its derived confidence, read in one
pass — not hundreds of KB of research prose read imperfectly. Re-reading the prose is exactly
how a Low-tagged figure gets promoted by paraphrase: the note carries its confidence, the
paragraph does not. The one-liners are in
[references/vault.md](references/vault.md#the-queries-this-schema-exists-to-make-trivial); the
coverage query is in [references/vocabulary.yml](references/vocabulary.yml).

Five things are resolved BEFORE a section is written, never after — the four vault queries, and
one re-verification none of them structurally reaches:

- **Subject collisions** — two `current` claims on one subject. Each is a contradiction, a
  duplicate, or a missing `scopes` edge, and the fix is one of those three edits. Picking a side
  silently is how the disagreement returns in the red team as an objection you already had the
  evidence to settle.
- **Coverage gaps** — a `required: true` subject with no claim under it: a plan section resting
  on nothing. Research it or state the gap. This is the check that catches a thin spine, which
  the note schema structurally cannot — you cannot type a fact nobody wrote.
- **Stale claims** — `stale_after` already passed. Re-check or downgrade before citing.
- **`status: unverified`** — asserted with nothing behind it. Each needs a validation step in
  the plan, or it does not get asserted.
- **Product claims re-verified against source at the current commit.** Every claim about the
  subject's own product is re-read against the product's own repo, docs and changelog *as they
  are today* — not as the Phase 0 dossier found them. The dossier is the product truth the whole
  plan inherits, and it was written before the research fleet spent a week running; the product
  moved underneath it. **A plan that only re-checks numbers that look too good drifts
  pessimistic, and every drift reads as rigour.** A capability that shipped, a limit that was
  raised, a seam that was closed: each one now reads as the plan being careful. The skill's
  existing skepticism fires in one direction only — strong rules against unmodelled optimism, a
  both-directions test on input values — so this step is worth nothing unless it is run in the
  direction those do not cover. A drift is a **supersession, not an edit in place**, under the
  standing two-edit rule, with `supersedes_reason` naming the commit or release that moved it;
  edited in place, the plan reads as though it were written against a product state its author
  never saw. The population is the one Phase 4's code-verify rule already governs — this is that
  rule moved to the entry of the phase that drafts rather than the phase that attacks, because
  the objection Phase 4 catches is one Phase 3 already wrote into the plan, and a *pessimistic*
  claim rarely draws an objection at all. The four queries above cannot reach it: a claim stale
  because the world moved is what `stale_after` catches, and a claim stale because the product
  moved has no shelf life on it at all. **The failure this prevents:** an understated product
  claim survives every check in the skill, reads as conservative to every reader, and reaches an
  acquirer or an investor as a fabricated weakness — one the founder then has to argue their own
  plan out of.

**The evidence-backed verdict is computed after those queries and before the first section is
drafted**, as the `claim` note [references/target.md](references/target.md) specifies — and where
it is negative, the negotiation turn happens HERE, before drafting, per that same file. A plan
drafted against a target still being argued about is re-cut section by section when the target
settles, and the milestones written under the old number are the ones that quietly survive. The
solved verdict and a target the negotiation settles differently both land mid-phase, so each is
one of the writes whose commit regenerates the vault's `README.md` (invariant 17).

**A reference class inferred from the subject's own price point or packaging is re-flipped in this
phase, and the trigger fires in both directions.** The class is named back in Phase 2 from the
dossier, while the pricing and capital forks that settle the subject's packaging are simulated and
settled here — so it is fixed before the decision it was read off is final. The trigger therefore
has two halves: re-flip it against whatever pricing, packaging and delivery decision is settled at
the moment the verdict is computed, **and** re-flip it again when a fork settled later in this
phase — the strategic-fork simulation below runs after this point, not before it — lands on a
different packaging than the class was inferred from. Either way a changed class re-solves the
identity rather than annotating the verdict, because every structural driver beneath the class
moves together; the rule and its failure are in
[references/target.md](references/target.md#a-structural-driver-may-be-sourced-from-the-reference-class-a-policy-driver-may-only-be-checked-by-it).
A comparison nothing forces is a comparison that gets skipped, which is why this one is attached to
the single phase where both halves are open.

Write `one-pager.md` FIRST (it forces the clarity everything else inherits), then
`business-plan.md` in the track's shape, then `financial-model.md` — all per
[references/plan-template.md](references/plan-template.md). Drafting is YOUR work — it needs the
founder's answers, the vault, and judgment in one head. The load-bearing rules:

- **Write `used_in` at the moment of citation** — `"business-plan.md#why-now"` on every claim
  the draft leans on. Without it a stale claim tells you it needs re-checking but not which
  paragraph is standing on it, so the re-check gets deferred because nobody can size it. The
  same field is what closes the claim: per invariant 20 it stays open until the named section
  carries it, and a claim minted after that section was drafted is subject to that exactly as
  one minted while it was being written.
- **The thesis traces.** The plan's core bet restates the analysis's whitespace recommendation,
  sharpened by the founder's unfair advantages — traceably, not vibes-first.
- **Cite by code, and there is no third kind.** `[S#]` resolves through `sources.md`, `[F#]`
  through the founder brief; invariant 1 is what bars a fact with neither.
- **The financial model is assumption-first.** Every input is a named row in the assumptions
  table (source: analysis, founder, or explicit guess), the revenue build is bottom-up, and
  base/downside/upside scenarios move the assumptions — not the conclusions. Fake precision is
  the failure mode; visible formulas are the fix. Every explicit-guess row is an `assumption`
  note with a `sensitivity`, which is what orders the validation queue. **Every input to the
  revenue build then takes the both-directions test, whichever way the value points**: each
  names the driver behind it in the direction it sits, and a low one with none is unmodelled,
  not conservative — it takes a driver or a home before anything is solved with it. The two
  checks below run on the curve, its rate and then its shape, and neither of them reaches this:
  a chain filled at the low end at every term produces a rate inside the band and a shape the
  set contains, at a scale nobody chose. The test, and why the flip test does not cover it, is
  in
  [references/target.md](references/target.md#every-driver-value-names-its-driver-in-both-directions-and-a-low-one-with-none-is-unmodelled).
  **The projection's own implied monthly growth rate is then placed against
  `competitor-analysis.md`'s `## Observed growth band`** — outside it in either direction,
  faster than the fastest comparable or slower than the slowest, the projection is defended by a
  named difference or re-cut. The slow end is where this bites: an over-projection draws a red
  team, an under-projection reads as conservative and reaches the founder's decisions
  unexamined. **That is the level check, and it
  is followed by the shape check: the projection's implied trajectory is placed against
  `research/growth-curves.md`'s indexed set at matching months since origin**, month 6 against
  month 6 and month 18 against month 18, not its average rate against the band's endpoints. The
  level check alone passes a projection that sits comfortably inside the band on its average and
  still asserts a shape no comparable in the set has ever had — flat where every comparable
  decayed, or holding one rate across the horizon where every comparable's rate fell after its
  first year. Averaging is what hides it: one rate stated for the whole horizon understates the
  early months and overstates the late ones at the same time, and lands inside the band on both
  counts. A shape the set does not contain is defended by a named difference exactly as a level
  excursion is, or the curve is re-cut against the fitted decay. Where the set was too thin to
  fit a shape, the curves file says so and the shape check reports that it could not run —
  it never falls back to the level check while reading as though both ran.
- **Open strategic forks get simulated, not asserted.** When the capital path (bootstrap vs
  raise) or entry sequencing (beachhead vs broad) is genuinely open after the grill, build
  the paths as parallel copies of one model and compare founder dollars across exit scenarios,
  with pre-committed switch triggers — load [references/strategy-sim.md](references/strategy-sim.md)
  and follow it. The reinvestment engine there also shapes every bootstrap-track model
  (default-alive gate, owner-pay floor, loop-not-funnel growth), fork or no fork.
- **Sequencing IS projection — the roadmap and the model are one artifact.** Every roadmap item
  names the assumption it moves, items unlock each other (levers multiply, they don't add),
  sequence value ≠ sum of item values, and **resource-independence gets checked before ranking
  by value** — items gated on different constrained resources don't compete and can run
  concurrently, which a naive value-ranking will serialise and lose. Load
  [references/roadmap-sequencing.md](references/roadmap-sequencing.md) and follow it whenever
  the plan has a roadmap.
- **The plan ships a growth engine, not a marketing wishlist.** The GTM section's execution
  half is the mostly-automated weekly machine from
  [references/growth-engine.md](references/growth-engine.md) — the three per-product skills
  (content, visual assets, docs-sync), the automation rules that survive Google and slop
  backlash, and the weekly loop sized to the founder's grilled hours, with engine build-out as
  named roadmap items.
- **Track shapes shape — three ways.** Venture gets the investor-facing memo framing;
  bootstrap/lifestyle gets a cash-curve and time-to-default-alive framing; lender gets
  repayment-capacity framing (3–5yr financials, use-of-funds line items, tone shifted from
  bet-defense to ability-to-service-the-loan). Same evidence, different document.
- **Every Low-tagged assumption gets a validation step** in the plan's validation section —
  the cheapest real-world test (interviews, landing page, waitlist, pre-sales) with a kill/
  continue threshold, recorded as the assumption note's `validated_by`.
- **Reconcile the one-pager last.** After financial-model.md is written, re-open one-pager.md
  and reconcile every number against it — the ask, the SOM range, the price. A one-pager
  number that disagrees with the model it fronts is the commonest credibility kill.

**The phase closes on invariant 19's reconciliation, not on the last section being written.**
The documents are the phase's output; whether the ledger underneath them still agrees is the
phase's exit condition, and it is checked here because Phase 4 spends its most expensive
attention on whatever this hands it.

## Phase 4 — Red team

Before the plan is done, it gets attacked. Dispatch a panel — one agent per lens, parallel
(model: `opus`, effort high; these need to be smart). Lens 1 matches the track:

- **Capital skeptic** — venture: *skeptical investor* (market too small, moat copyable,
  why-now weak?) · bootstrap/lifestyle: *default-alive skeptic* (does this reach cash-positive
  before the runway ends?) · lender: *credit officer* (does cash flow service the debt through
  the downside case?).

  **Where the settled target is an exit, this lens asks the acquirer's question instead of the
  funder's** — not *would an investor put money into this*, but *which named acquirer has a hole
  this patches, and is the product visibly the patch*. The brief carries the dossier's seam
  argument and the acquirer set the exit identity was solved against, counted, and the lens attacks
  the name and the count rather than the ARR. **An unnamed acquirer is not an answer, and neither
  is a named one whose hole the plan never states.** "Someone in this category would want this"
  grants the driver the verdict was most sensitive to —
  [references/target.md](references/target.md) homes strategic necessity to a *named* acquirer and
  files it as `policy`, so a lens that accepts the unnamed form hands back a clean bill on the term
  the whole exit rests on. Two follow-ons the lens owes: a single interested buyer is a price
  **floor** and not a price, so a count of one is reported as one rather than as evidence of
  demand; and *what stops this acquirer building it itself inside two quarters* is the scarcity
  input asked from the buyer's side, where the honest answer prices an acquihire instead of an
  acquisition. **The failure this prevents:** an exit plan collects a full investor-shaped
  objection table — market size, moat, why-now — and reads as thoroughly attacked while nobody
  asked who buys it. Fundable and acquirable have different answers often enough that a pass on one
  says nothing about the other.
- **Operator** — kill the execution: does the milestone plan survive contact with the team
  size, runway, and the founder's hours?
- **Target customer** — kill the demand: would the beachhead segment actually switch, at this
  price, from what they use today?

**The target list is generated, not read.** Invariant 19's reconciliation runs before any of
this and gates the dispatch — its two lint calls, `vault-lint.sh --used-in` and
`vault-lint.sh --supersession-sweep`, belong beside the query below rather than in a block of
their own, and no brief is written until the read behind them is done. Two further queries then
run before the panel is briefed: `vault-lint.sh --unverified`, and every claim that reached the
plan carrying `confidence: L`. Those, addressed by note ID with the sections their `used_in` names, are the
attack surface each panelist's brief carries in its lens. "Read the plan and object" produces
objections about whatever a panelist happened to notice; this produces them about what the
corpus already knows is weak. Every brief also carries the founder's named fear `[F#]`: attack
this hardest, then name the two risks the founder did NOT name. The operator and target-customer
briefs additionally carry the structural half of `research/growth-curves.md`'s strategy record —
what comparables had that this founder does not — because that is an objection the corpus can
already evidence rather than one a panelist has to invent.

**A metric that enters a brief as evidence for a mechanism enters with what else produces it**,
per invariant 3. This is where that rule bites hardest: a panelist handed a number reads it as
the evidenced part of the brief and spends the turn elsewhere, so an unexcluded alternative
explanation reaches the panel as settled ground and comes back unattacked.

**The verdict is on the attack surface, not only the plan built on it.** Every brief carries the
settled target, the verdict, the driver the verdict named as binding, and that driver's `kind`;
a panel that attacks only the plan grants the number the plan is engineered backwards from, and
one told a driver binds without being told it is `policy` grants the configuration the verdict
was computed under — the assumption most worth attacking, and the one no lens is otherwise
tasked with. Re-run the identity against any objection that survives:
[references/target.md](references/target.md).

**Read the model's identity before the panel reads its numbers — a pre-pass, not a fourth lens.**
All three lenses reason from the plan document, so all three inherit its frame: a revenue model
that assumes a flat curve, or that treats a founder's choice as a fixed property of the business,
hands every panelist that frame as the ground they attack *from*. A fourth voice briefed alongside
the others would inherit it too and would arrive at the same moment as three lenses' worth of
detail objections, too late to change what the panel is pointed at — which is why this runs BEFORE
any brief is written and its output goes INTO the briefs, exactly as the settled target and the
binding driver's kind do above. Five steps, in this order:

1. **Write out the revenue model's identity — the chain of terms, ahead of any value in it.**
   `MRR = paying customers × price`, the acquisition-and-retention chain standing under the
   customer count, and for an exit target the multiple band on top of it. Terms first, values
   second: a chain nobody wrote down is one nobody can disagree with a term of, which is the same
   property that makes the target verdict attackable.
2. **Label every input `structural` or `policy`** — those two words, per invariant 18, using
   [references/target.md](references/target.md)'s vocabulary and never a coined variant. A third
   word ("semi-structural", "market-driven") is a way of not answering that reads as a finer
   distinction, and it survives review for exactly that reason.
3. **Name which of the policy inputs the founder could revisit this quarter, and state the model's
   shape — flat, decaying or compounding — as a claim with a driver behind it** rather than as the
   backdrop the curve was drawn on. Zero growth is an assertion that next month's reach, conversion
   and mix are identical to this month's, and it needs a named driver exactly as an inflection
   does.
4. **Report every input that is unmodelled in the pessimistic direction, naming each one.** The
   steps above ask what kind an input is and what drives the curve's shape; none of them asks
   whether a *low* value earned its place, and that is the direction this pass structurally cannot
   see — a low number reads as the cautious choice rather than as the claim it is, so it passes
   through the block unremarked and the panel inherits a floor nobody sourced. Run the
   both-directions test from
   [references/target.md](references/target.md#every-driver-value-names-its-driver-in-both-directions-and-a-low-one-with-none-is-unmodelled)
   over every value in the identity and name each one that is unmodelled, not conservative, so a
   panelist can attack a floor instead of reading it as the plan's margin of safety.
5. **Test the terms against what the founder said the business is, and report a term the business
   has that the identity lacks.** Read the identity from step 1 back against the dossier and the
   grill's `[F#]` facts — every revenue layer, every distinct paying motion the founder stated.
   Writing the identity out is the right instrument and it is not a test of itself: a business with
   three revenue layers solved as a single-layer funnel is not a wrong number, it is the wrong
   identity, and no rule about input *values* can reach it. Name the missing term; adding one sends
   steps 2–4 back over it, which is the cheap version of the same discovery.

The pass returns a short block every brief carries verbatim: the identity, the label per input, the
shape with its driver, the inputs unmodelled in the pessimistic direction, and any term the
founder's stated business has that the identity lacks. A panelist told the flat stretch is an
assertion resting on a named channel cap can attack the cap; one who is not told reads the flat line
as the conservative part of the plan and spends the turn somewhere else.

**The failure this prevents:** a structurally wrong model is the one a panel is unable to attack,
because every lens is pointed at the plan's contents rather than its shape. The panel returns a
full objection table, all of it about details, and the plan reads as thoroughly red-teamed — but a
model nobody could attack is not a model nobody could fault. The tell is a red team whose severest
row argues about a value inside the identity while the identity itself carries a term nobody
labelled.

**The failure the terms check prevents:** an identity missing a whole revenue layer is internally
consistent and solves cleanly, so nothing downstream can see the omission — the arithmetic is
correct about the wrong business, and every value inside it is defensible. The run reports a
confident verdict on a model of a business the founder is not building, and every input in it
survives every check, because each one is individually right.

**Code-verify every objection about the subject's own product BEFORE disposing of it. This is
the single highest-value rule in the skill.** Panelists reason from the plan document, and the
plan document under-describes the product — so a panel will reliably assert the product lacks
things it ships, and those false objections then get "fixed" into the plan as concessions or
roadmap items. Any objection of the form *"it has no X"*, *"it can't do Y"*, or *"users would
have to Z"* gets checked against source (the repo, the product's own docs) before it is
accepted, moved to Risks, or rejected — invariants 2 and 3 are the reading discipline, and both
produce confident and wrong objections when skipped.

**Expansion-hypothesis test** — apply to every "we could also sell to ___" the panel or the
plan proposes. Three questions, all three must pass or the population is a *qualifier inside
the existing beachhead*, not a segment: (a) is it **additive**, or already counted inside the
SAM? (b) is the driver an **obligation** or a preference? (c) does it pay for anything at all
today? Record the kill reason — later audits need to distinguish "already counted" (a durable
kill) from "too complex for that segment" (a kill that may have been made under a pessimistic
read of the product and is worth re-testing once the dossier is accurate).

**Weigh negative evidence by whether the thing exists yet.** Absence of articulated demand is
*weak* evidence when the product category doesn't exist (nobody complains about the absence of
a thing they've never seen; they ask for a faster version of what they have) and *strong*
evidence when the thing shipped and people declined to buy it. Treat a dead comparable as
strong evidence only after checking it was actually the same product — a failed thin version
of an idea prices the thin version, not the idea.

**"A competitor ships that free" prices the version that shipped, not the capability.** Same
discipline as the dead comparable: check what the free thing actually does *at the layer the
subject's claim is made*. A checkbox and a guarantee are different products even when the
feature list calls them the same word — the free version often does the easy 80% and leaves the
correctness layer, which is exactly where the subject's engineering went, undone. The tell is
what users of the free version have had to build for themselves on top of it: **hand-built
substitutes around a free feature are the clearest available signal that the free feature
didn't finish the job**, and counting them is a stronger demand instrument than counting
forum complaints.

**Name the layer a cost trend actually reaches.** Falling input costs let an incumbent give
away *compute*; they do not let it give away *correctness*, which is engineering. A
commoditisation argument that doesn't name its layer overclaims in one direction, and a moat
argument that ignores the layer it does reach overclaims in the other.

Each panelist's objections land in `red-team.md`:
`| # | Lens | Objection | Severity | Disposition (fixed / moved to Risks / rejected + why) |`.
Fold: fix what's fixable; every row disposed "moved to Risks" appears in the plan's Key risks
section by its number — a plan that pre-states its best objections beats one that hides them.
**A surviving objection also lands in the vault**, as a `claim` that `supersedes` what it
corrects or an `assumption` with a `validated_by` step. An objection disposed only in the table
is one nothing downstream can find. That note is subject to invariant 20 like any other: it is
finished when the section its `used_in` names carries it, not when the row is disposed — and a
note minted this late is the likeliest of all to be left sitting in a ledger nobody reads back
into the prose. If an objection guts the thesis, say so to the founder
plainly and revise the bet — that IS the job.

## Phase 5 — Deliverables

**Lint is the release gate, and it runs before the first render.** `vault-lint.sh` must
be clean over the whole vault: a plan citing a retracted or superseded source does not ship. The
failure this stops is the worst one available — a polished PDF asserting flatly what the corpus
already withdrew, handed to the one reader with no way to check it.

Render `business-plan.md` (+ the financial model) into ONE polished, self-contained
`deliverables/business-plan.html` and a print-quality `deliverables/business-plan.pdf`, and
`one-pager.md` into its own single-page pair (no cover page — rendering.md's single-page
exemption; it fails verification if it spills to page 2), per
`~/.claude/skills/market-analysis/references/rendering.md` (the shared rendering system —
design, paged-media CSS, toolchain ladder, and the mandatory render → Read the PDF back →
check every page → fix loop). A deliverable you didn't read back is not done.

**The indexed growth-curve exhibit renders with the plan, and is checked on the read-back like
every other page.** It is authored into `market-analysis.md`, and nothing on this path renders
that file — Phase 2 runs the research engine's Phases 1–4 only and skips its deliverables — so an
exhibit left where it was written reaches the founder as markdown in a file nobody opens, which
makes it a table of numbers and means the shape comparison the whole dimension exists to make
never happens. Carry it into `business-plan.md`'s Target & verdict section per
[references/plan-template.md](references/plan-template.md), author it as the inline SVG
`rendering.md` specifies, and check it page-by-page with the rest: the projection overlay
distinguishable from the comparables at print size and in grayscale, every line labelled at its
own end, and the excluded-from-overlay companies present in the caption. For a plan whose central
question is whether a target lands on its date, this is the most load-bearing exhibit the
engagement produces, and it is the one the render path was structurally dropping.

**Once the deliverables exist — and not before — ask about a remote.** The vault has been a local
repo since Phase 0; this is the separate question of whether it goes anywhere. Asked at scaffold,
it asks the founder to consent to the visibility of contents neither of you has seen yet, which
is why it waits for something worth sharing. Collect both halves:

- **Destination** — which account or organization.
- **Visibility** — private preselected. Public is a real choice some founders make deliberately
  and is offered as one; what it is not is a default, over a corpus carrying their pricing, their
  runway and their named fear.

**No remote is created without an explicit answer to both.** The gate is on creating and
configuring the remote, not on using one the founder asked for — past that point invariant 17's
push applies to every commit. Local-only is the Phase 0 default and the state a vault stays in
unless the founder asked otherwise. A remote inferred from one answer — a destination taken as
consent to a visibility, or a visibility assumed from a destination — publishes a private
business corpus on a step the founder never took.

## Walk sign-off

Close with specific callouts, not a summary dump: the thesis in one sentence, the number most
likely to be wrong and its validation step, the red-team objection that survived, the first
three milestones, and where everything landed. Invite pushback on the specific bet.

## Quality bars — non-negotiable

- Every market fact traces to `sources.md` or the founder brief; confidence tags survive import.
- Wherever the plan or the red team reasons from a count to a cause, the metric states what else
  produces that number, and a metric introduced after the conclusion it supports is named as one.
  Unexcluded, the alternative explanation ships as the evidenced part of the argument — and a
  second metric picked to confirm the first tests the thesis's fit to the instrument, which reads
  as corroboration and is the shape nobody stops to check.
- Lint is clean over the whole vault, at the per-dimension gate and again before rendering.
- Every claim about the subject's own product was re-verified against source at the current
  commit before the first section was drafted, and each drift landed as a supersession rather
  than an edit in place. The rest of the skill's skepticism fires on optimism, so a claim that
  went stale in the *pessimistic* direction — a capability that shipped, a limit that was raised
  — clears every other bar on this list and reads as conservatism the whole way to the reader
  who acts on it.
- Every claim cited in a rendered document carries `used_in`, and every `used_in` target carries
  the claim — a claim whose named section does not say what the note says is still open,
  whenever it was minted. Every `required: true` subject has a claim under it or a stated gap.
- The steady-state ceiling is computed and stated, not implied by a 12-month curve, with every
  input in the identity labelled `structural` or `policy` — and a policy-bound ceiling stated as
  the ceiling of that configuration, with one changed policy value beside it.
- Every stretch of the projection's curve names its operational driver — inflections and flat
  stretches alike. Zero growth is an assumption, not the absence of one, and unnamed it is
  unmodelled, not conservative.
- Every model input names its driver in both directions, and a low one with none is unmodelled,
  not conservative. Skepticism that fires in one direction only is a filter: each pessimistic
  input is defensible alone, the chain multiplies them, and their product reaches the founder as
  a property of the market rather than as a stack of choices nobody wrote down.
- A structural driver with no subject instrument is sourced from the indexed set — a `claim`
  resting on `research/growth-curves.md`, carrying that set's `stale_after`, a `validated_by`
  kill test and the survivorship qualifier — and is never filed as an `assumption`. Filed that
  way, invariant 11 caps it at its weakest input, and every plan for a company that has not
  launched reads as unjustified for a reason that is routing rather than evidence.
- A verdict standing on a reference class inferred from the subject's own price point or packaging
  names that dependency where the class is named, and a pricing, packaging or delivery decision
  settled after the class was named re-solves the verdict rather than annotating it. The class is
  downstream of a policy input and inherits its mutability, so one left fixed across that decision
  hands the founder a reclassification — every structural driver beneath it moving at once —
  reported as a property of the market.
- The projection's implied monthly growth rate is placed against the observed growth band, and
  its implied trajectory against the indexed comparable curves at matching months since origin.
  Any excursion — in level, in either direction, or in shape — names the difference defending it.
- Wherever the price is defended, BOTH lenses are priced: the cost of the alternative the buyer
  avoids, and the value the product delivers them. A price defended on cost alone is unmodelled,
  not conservative — the substitute's cost is a floor under the buyer's alternative, and a plan
  that prices only that side caps itself at the DIY figure while reading as rigour, since the
  substitute number is well-sourced and the output figure nobody computed is simply absent.
- A retention value carries its band, its position inside that band, and what in the built product
  places it there — and a ceiling that binds on it is the ceiling of THIS PRODUCT AS BUILT, never
  of the market. An improvement claim on either half of the loop, delivered value or retention,
  carries a sourced base and labels its magnitude `measured`, `reference-class` or `assumed`, with
  an `assumed` one taking the both-directions test. Both flatter the thing the founder built, which
  is what makes them easy to write and hard to challenge, and churn is the divisor of the
  steady-state identity, so an unguarded retention claim moves the answer further than any other
  input in the model.
- A plan whose roadmap improves the product states what that does to retention, or states that it
  does nothing to it and why. Silence is read as no effect, which is a claim nobody made — and it
  is exactly the claim a category-floor churn row asserts by construction.
- Every roadmap item names the assumption it moves.
- The financial model's assumptions table is complete — no number appears in a projection that
  isn't a named assumption row.
- A ranged target's readout is the set of corner verdicts, with the binding driver and its `kind`
  named per corner, and the founder's stated range labelled apart from the evidenced range.
  Collapsed to one verdict or one interval, the finding is destroyed exactly where it matters — a
  rectangle where three corners clear and one fails reads at its centre as a clean yes, and the
  failing corner is usually the one the founder was aiming at.
- The plan matches the founder's stated ambition, not a template's default ambition.
- Nothing was dispatched to the red team until the plan and the vault were reconciled: the
  `--used-in` pass clean, the `--supersession-sweep` worklist read to its end, and every
  superseded claim's citation sites re-read. The panel is the most expensive read the plan gets,
  and a panelist already briefed cannot be un-briefed — the objections come back about a version
  nobody is shipping and are paid for in full.
- Red team ran, and its surviving objections are IN the plan and in the vault.
- Every red-team brief carried the model's identity, its per-input `structural`/`policy` labels,
  the curve's shape with its named driver, the inputs unmodelled in the pessimistic direction, and
  any term the founder's stated business has that the identity lacks — before the panel was
  briefed. The panel reasons *from* the plan, so a brief that arrives without these inherits the
  plan's frame and can only object to details.
- Where the target is an exit, the red team met the acquirer's question: a *named* buyer, the hole
  it patches, and the bidder count. An unnamed acquirer is not a driver value, and a lens that
  accepts "someone would want this" grants the driver the verdict was most sensitive to.
- Rendered deliverables verified page-by-page.

## Common failure modes

| Failure | Fix |
|---|---|
| Plan re-researches the market inline | Dispatch the market-analysis skill; conduct, don't dig |
| Synthesis re-reads the research corpus | Query the vault — reading prose is how a Low tag gets lost |
| Notes written up at the end, in one pass | Emit per dimension; lint at the gate while context is live |
| Thesis is the product description reworded | Trace it to the whitespace recommendation + unfair advantage |
| Low-confidence number promoted to headline | Confidence is derived; tags survive import; validation step instead |
| Hockey-stick from penetration hand-waving | Bottom-up build; scenarios move assumptions |
| Flat acquisition line read as conservative | Zero growth is an assumption: name its driver, and place the implied rate against the band |
| Product claim gone stale in the pessimistic direction | Re-verify every product claim against source at the current commit before drafting; a drift is a supersession, not an edit |
| Policy variable reported as a ceiling | Label every input structural or policy; a chosen input caps the configuration, not the business |
| Venture template forced on a bootstrapper | Ambition question first; shape follows it |
| Red team skipped ("plan looks solid") | It runs every time — that's when it's most needed |
| Grilling the founder on what research answers | Grill intent/resources/appetite; research the market |
