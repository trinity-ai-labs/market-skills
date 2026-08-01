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
   metric is cited as evidence for a mechanism, state what else produces that number.** A count says
   a thing exists; it never says why. Where the alternative explanation is not excluded the metric
   is a description and not evidence — and a metric chosen *after* the conclusion is a conclusion
   wearing an instrument. That second clause is the one worth writing down: a careful reader
   supplies the alternative explanation anyway, while an instrument selected to fit a thesis already
   reached leaves every step downstream of it locally sound. The tell is a second metric introduced
   to confirm the first; chosen after the thesis, it tests the thesis's fit to the instrument rather
   than the mechanism.
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
    turn, and again in Phase 5 before anything renders. (A session with only the PowerShell
    tool runs `vault-lint.ps1` instead — same modes, same output; see
    [vault.md](references/vault.md#a-session-invokes-whichever-script-its-shell-tool-can-run)
    for which one a given session picks.) A plan citing a retracted source does
    not render. **Phase 5's run is one call — `vault-lint.sh --release-gate`** — which runs the
    bare check, `--used-in`, `--supersession-sweep`, `--red-team`, `--roadmap-table`,
    `--binding-driver`, `--monitoring`, `--deliverable`, `--assumption-rows` and
    `--claim-drift`, and exits
    non-zero unless
    every part passes. It is one call because it was several, and calls made from memory are a set
    nobody can be held to: which of them actually ran was a matter of recall, and the bare run's
    success line said `clean` over a corpus with dozens of dead anchors. That line now names what
    it checked and what it did not, and the gate carries one exit status for all of them.
    `--used-in` stays a separate mode *inside* the gate rather than folding into `check`, because
    it reads documents outside the note directories: the default run never opens a citation
    target, so a plan clears the bare gate while carrying a citation to a document that was
    renamed or a section that was cut, and the next thing that happens is a rendered PDF
    asserting it to the one reader with no way to check. The sweep prints a worklist and **fails
    when nothing records that it was read** — a `reconciled:` date absent from the superseding
    note, or earlier than that note's own `created`; it is in the gate because Phase 4's
    dispositions mint supersessions *after* invariant 19's sweep has already run, which makes the
    render the only point they are read at all — the worklist the gate prints is read to its end
    before the first render, or the deliverable ships the version the panel corrected while
    `red-team.md` records that row as fixed. `--red-team` is in the gate for the mirror-image
    reason: it fails when a lens named in `red-team.md`'s `## Lenses dispatched` roster wrote no
    objection row, and the last thing a plan does before rendering is cite objection codes into
    that table. `--roadmap-table` is in the gate because the roadmap section is edited by hand
    for as long as the plan is being written, while the notes it renders were minted once and
    left alone: it matches each row's item cell against a milestone `title` verbatim, both ways,
    so a row added late with no note behind it and a note the table quietly dropped both surface
    before the render rather than in a reader's question nobody can answer.
    `--binding-driver` is in the gate for that same reason one section over — the verdict section
    is hand-edited to the last minute and its note was minted once — and invariant 16 states what
    it holds.
    `--monitoring` is in the gate because a snapshot cannot see a direction: every profile carries
    the date it was researched and every claim a `stale_after`, and both answer *is this still
    true* rather than *which way is this moving* — which is the only thing separating a closing
    window from an open one. It fails an axis with no instrument, no cadence, or no decision it
    would change. `--deliverable` is in the gate because what an outside reader receives is held
    to the same terms the ledger is: it reads the rendered `deliverables/*.html` and fails on a
    strikethrough span, a note ID or an objection code — vault addresses that resolve for anyone
    holding the corpus and resolve to nothing for the audience the document is for. **Invariant 14
    does not change**: retraction stays visible in the plan, and the deliverable reaches its reader
    through Phase 5's restate-forward step rather than through a strip filter.
    `--assumption-rows` is in the gate because it is the only inverse the assumptions table has:
    the rule that every number in a projection is a named row is checked by reading the model, and
    whether a named assumption is MISSING from the table can only be checked against the notes. It
    fails a declared model input with no row and no stated exclusion, a row matching no note
    `title`, a row whose every `title` match is a note the ledger has retired, and a revenue
    line the roadmap ships that the model does not carry and the identity
    does not declare. **A live `claim` backs a row exactly as a live `assumption` does** — both
    assert a value, and what disqualifies either is `superseded` or `retracted` — so promoting a
    sourced figure out of the assumptions set is a repair rather than a defect. Those two are the
    whole set: a `source` or `fact` is provenance a claim rests *on*, not a value the projection
    carries. **What that last one cost, undetected, is the largest miss on record
    here:**
    a revenue line existed as correctly authored notes, never became rows, was filed as revenue
    outside the model, and three separate verdict re-solves each corrected a different term and
    inherited the same denominator — so the answer never moved.
    `--claim-drift` is in the gate because it is the only check that can see invariant 20 being
    undone after it was satisfied: it re-opens a claim whose cited section has been rewritten
    since the note recorded reading it. `--used-in` cannot — the heading is untouched, so the
    citation still resolves — and the render is the last moment before the section reaches a
    reader with no way to check it. Both are `schemaVersion` 3 rules, so a vault at 1 or 2 is told
    the rule was not applied rather than that its documents agree.
    **Phase 2's checkpoint stays the bare run**: no note carries `used_in` until drafting
    cites it, so the gate's second part would check an empty set there, and running the whole
    gate anyway teaches it as cadence-wide when it belongs to one phase.
    **That same gate reads the dimension's own file, never the summary its author
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
    decision of theirs can move. **The second clause is checked rather than stated:
    `vault-lint.sh --binding-driver`**, a part of `--release-gate`, fails a policy-bound verdict
    whose `conditional_on` string is absent from the plan section its `used_in` names, and fails a
    `Kind` cell hand-edited away from its note's `driver_kind` in either direction — the cell being
    otherwise the cheapest way past the first check. The fields it reads are
    [references/vault.md](references/vault.md#a-target-verdict-is-a-claim-carrying-five-more-fields-not-an-eighth-note-type)'s.
    The `Kind` half needs a corner table to read, and the verdict section it looks in runs to the
    next heading of the same depth or shallower — so a `###` subsection under the anchor is part
    of that section and its table is read, and a plan carrying no such table anywhere under the
    anchor is told the `Kind` check did not run rather than that it agreed.
    **A third clause sits on the identity's own terms: the ARR term declares its composition.** A
    model may legitimately exclude a revenue line — a metered layer must not be allowed to flatter
    subscription churn — but an exclusion the identity does not state is a denominator nobody can
    see, and `vault-lint.sh --assumption-rows` fails a line the roadmap ships a change to that the
    model has no row for and no verdict note names in `arr_excludes`. **The failure:** the excluded
    layer was a roadmap item carrying an order of magnitude more revenue per account than the line
    that stayed in, the plan said so in its own one-pager, and three verdict re-solves each
    corrected a different term — a rate, a convention, a sample size — while inheriting the same
    denominator, so the answer never moved. Nothing was wrong with any solve; a term of the
    identity had no check pointed at it. The method is strong at preventing false statements and
    weak at noticing missing ones, and this is the term that costs most.
    [references/target.md](references/target.md#the-arr-term-declares-its-composition-or-the-exclusion-is-invisible)
    carries it.

17. **The vault is a git repo (Phase 0): commit at every meaningful write, regenerate the vault's
    `README.md` and `research/timeline.md` in the commit that changes a fact either one states,
    and where a remote exists — the
    Phase 5 consent gate — push every commit.** Phase boundaries are too coarse a unit of loss for
    a phase that writes dozens of files: a crash mid-phase should cost one file, not a day of
    research. They are the same wrong unit for both generated files, and for the same reason. The
    README states the current target and its verdict status while both move *inside* Phase 3; the
    timeline states what is true at a given month while the milestone set and its order move
    inside that same phase — so pinned to the boundary either one
    spends most of a phase asserting what the ledger beneath it has already superseded, and it
    reads as current because its last line says it is generated rather than hand-edited. The
    fields whose change triggers a regeneration are named per file in the output contract below —
    four for the README, four for the timeline — so the
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
    **The verdict half now has an enforcement surface and the ceiling half's is partial** — say
    which, because the two are checked to different depths and treating them as equal is how the
    weaker one stops being written. Under `subject: target-verdict` four of the five labelling
    fields are owed unconditionally — `binding_driver`, `driver_kind`, `evidence_n`,
    `evidence_counterparties` — and `conditional_on` is owed on top of them only where
    `driver_kind` is `policy` or `policy-within-band`, because a rule demanding a condition from
    every verdict would be met by inventing one. A note missing any field it owes fails, and
    `verdict-unfiled` fails a rendered `{#target-verdict}` section with no note behind it at all.
    Under
    `steady-state-ceiling` the same fields are owed only once the note carries one of them: that
    subject predates them, every existing vault holds a ceiling claim, and a rule firing over all
    of them would fail every vault authored before this release. So an unlabelled ceiling claim
    still passes the note-level check, and there the rule stays a discipline until the note is
    re-filed. **`verdict-unfiled` deliberately has no `{#steady-state}` equivalent**, and the
    asymmetry is exact rather than an omission: `steady-state-ceiling` is `required: true`, so
    `coverage-gap` already fails a vault with no ceiling note and there is no unfiled-section hole
    left to close; `target-verdict` is `required: false`, so nothing else asks for the note and the
    hole is real. The fields, both triggers and the argument for the split are
    [references/vault.md](references/vault.md#a-target-verdict-is-a-claim-carrying-five-more-fields-not-an-eighth-note-type)'s.

19. **Nothing is dispatched to the red team until the plan and the vault have been reconciled.**
    Lint runs at Phase 2's per-dimension checkpoint and again in Phase 5 before rendering;
    between drafting and the panel there is nothing, and a panel briefed on a plan the ledger has
    already moved past returns objections about a version nobody is shipping, at full panel cost.
    **Three named calls and then the read** — the calls bound the read rather than replace it.
    `vault-lint.sh --used-in` **fails**: a citation resolving to a file or a section that is not
    there is not a judgment call. `vault-lint.sh --supersession-sweep` **emits the worklist** —
    every section a supersession put in doubt — and **fails** when a superseding note carries no
    `reconciled:` date, or one predating its own `created`. `vault-lint.sh --red-team` **fails**
    when a lens named in a closed round's roster wrote no objection row; on the first dispatch
    there is no closed round and it passes, and on a re-dispatch it is the cheapest moment a
    silent lens is still fixable. Then **the read**: every `current` claim whose
    `used_in` names a plan document is reconciled against that document, and every superseded
    claim's `used_in` targets are re-read, and the date that read happened is stamped as
    `reconciled:` on each superseding note. It is a read and not a grep, because plan prose cites
    `[S#]` and `[F#]` codes while a claim carries no code at all, so nothing mechanical can tell
    whether a section still says what the note says. The lint calls are what keep the read
    bounded and therefore done: a reconciliation stated as "check the plan against the vault" is
    a task nobody can size, and a task nobody can size is a task nobody starts. The gate sits on
    the dispatch rather than the phase boundary, because a panelist already briefed cannot be
    un-briefed.

    **This stays three named calls rather than becoming `--release-gate`, and the reason is
    worth holding.** The gate composite also runs `check`, which this gate deliberately does
    not: Phase 2's checkpoint owns note well-formedness while the authoring context is live, and
    a malformed note written during drafting should not block a panel dispatch on a fix that has
    nothing to do with whether the plan and the ledger agree. The stronger reason is that
    invariant 15 gives `--release-gate` one home, at the render, and a call with two homes makes
    "did the gate run" a question of recall again — which is the defect the composite was built
    to remove. **And the failing halves have not made the read optional.** `reconciled:` records
    that the read was claimed, not that it was done: a date can be stamped without opening a
    document. What the verdicts remove is skipping it silently.

20. **A claim is not finished when the note is written; it is finished when the prose it names
    carries it — and it does not stay finished on its own.** Writing the note and writing
    `used_in` are one act, and the claim stays open until the section `used_in` names actually
    says what the note says — invariant 19 is where that gets read. **Where the note is a
    supersession, the closing edit is the `reconciled:` date on it**, which is the one form of
    this obligation the corpus can see: the sweep fails a supersession carrying none, so the open
    claim is visible from outside instead of being a thing the conductor is trusted to remember.
    **And the read expires when the section is rewritten**, which is the half that was invisible:
    the claim records the content hash of each section it was read against, in
    `reconciled_sections` beside that same date, and `vault-lint.sh --claim-drift` **re-opens** the
    claim when a hash no longer matches. The failure it closes happened *after* this invariant had
    been satisfied once — a claim was written into a plan section, a later re-solve rewrote that
    block, the heading was untouched so `used_in` still resolved, the gate stayed green, and the
    drift was found by hand days later. A hash cannot say the section still agrees with the note;
    that is invariant 19's read. What it says is that the text somebody read is the text standing
    there now, so a rewrite is visible from outside instead of being something the conductor has
    to notice. Gated on `schemaVersion` 3, because every claim in every finished corpus is already
    cited into a plan and a rule demanding a recorded hash from each of them would fail every
    existing vault the day the plugin updates;
    [references/vault-migration.md](references/vault-migration.md) carries the back-fill. This is an invariant rather than a Phase 3 step because the obligation
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

22. **At every phase boundary, and after any substantive founder exchange, ask what was
    established in conversation that no note carries.** Invariant 20 governs claims that are
    already written and holds them open until the prose they name carries them; this one governs
    what was never written at all — a constraint, a reframing or a disqualification both parties
    now treat as settled, reasoned from downstream, and existing only in the transcript. The two
    cannot substitute for each other: 20's worklist is the set of notes, and something that never
    became a note is not on it. Whatever the sweep surfaces is recorded exactly as invariant 21
    records a late fact — the next `[F#]`, a `fact` note resting on the interview `source`, an
    appended row in the brief — and is then subject to 20 like anything else. It is an invariant
    rather than a step in any one phase because value discovered in dialogue is the default state
    of a good engagement rather than an exception to it: the sharpest material arrives mid-answer
    while the conductor is working on something else, in every phase, and compaction re-attaches
    only the head of this file, so a rule written into one phase body is out of context in the
    next — which is where the conversation it needed to sweep just happened. **The failure this
    prevents:** the engagement knows things the corpus does not, and nothing can tell. Every note
    is correct, the lint is clean, the reconciliation passes, and the missing material has no ID
    to be missing by. It surfaces at the walk sign-off, when the founder asks why the thing you
    both agreed three phases ago is not in the plan.

23. **Steelman a founder statement before checking it — verify the claim they are making, not
    the cheapest adjacent number.** This is invariant 3 pointed at a founder's remark instead of
    at the model: a metric chosen after the conclusion is a conclusion wearing an instrument, and
    checking whichever number is easiest to check instead of the number the founder actually meant
    is the same move wearing a different subject. A founder says a competing tool costs more than
    their seat. The competitor's list price is lower, so the claim is filed as false — but the
    competitor's product is a control plane that bills separately for the compute underneath it,
    so the delivered cost is roughly double the seat, and the founder was right about the thing
    that matters. The cheap number is the one that gets checked, and checking it produces a
    confident wrong answer. **And a correction that moves no number in the plan is a conversation,
    not a note:** the vault is a ledger of what the plan stands on, and filing a detail error as a
    finding spends the founder's attention on a scoreboard rather than on the plan. **The failure
    this prevents:** a founder's claim about their own market gets refuted on a technicality
    neither party meant, the refutation reads as rigor because a number backs it, and the plan
    quietly loses the one piece of the founder's testimony most worth having — the delivered
    reality a list price hides.

## Output contract — deterministic home

Same folder the market-analysis skill uses (same slug rule — repo directory name or settled
product name, kebab-case; re-runs update in place, never a new folder):

**The engagement folder IS the vault.** There is no `vault/` subdirectory — the slug directory
carries `.vault/config.json`, and everything else lives inside it:

```
~/Documents/go-to-market/<product-slug>/  # ← this directory is the vault
  .vault/config.json        # schemaVersion — a directory without it is not a vault
  _vocab.yml                # controlled subjects, seeded from references/vocabulary.yml
  sources/ facts/ claims/ assumptions/ questions/ decisions/ milestones/  # one note, <ID>.md
  research/                 # ALL prose, untouched by the vault — market-analysis dimensions,
    product-dossier.md      #   profiles/, plus these two written here in Phase 0 / Phase 1
    founder-brief.md        #   the grill's numbered [F#] facts — the plan cites these
    timeline.md             # GENERATED from milestones/, never hand-edited — see below
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
category (AI tooling, consumer apps) or ~12 months otherwise; between those, work
`competitor-analysis.md`'s `## Monitoring plan` axis by axis as a partial refresh — each axis's
instrument read, and the decision that axis says would flip stated as flipped or not — and note
it in Coverage; past them, or if the product's stage/boundary moved, plan a full refresh.

**A partial refresh re-reads the axes, never the pages.** A pass over pricing pages and
changelogs answers *is this still true*, which is the question the `_Analyzed:` date beside it has
already answered and which every claim note's `stale_after` asks again — so it returns *still
accurate* over a vendor whose direction reversed a month ago, and a direction is the only thing
separating a closing window from an open one. Only an axis carries one, which is why this branch
reads the axes and their decisions rather than re-checking the pages those axes are read from.

**Scaffold the vault before anything writes.** The vault path IS the slug directory — never a
`vault/` subdirectory under it. Create the tree above, write `.vault/config.json` with
`"schemaVersion": 3` — the current version, so every check the schema carries applies to this
vault from its first note — and copy [references/vocabulary.yml](references/vocabulary.yml) to
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
understand stops the run rather than being half-read. **An existing vault at an older
`schemaVersion` is left at it** — the lint reads every version it supports and holds each vault
to the rules it was written under, so a reuse is not the moment to bump one. The upgrade is its
own procedure, in
[references/vault-migration.md](references/vault-migration.md#stamp-schemaversion-2-last-after-the-vault-can-already-pass-at-2).

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

Three files are **generated**, never hand-edited, and their cadences differ because they track
different things: **`.gitignore` is regenerated at every phase boundary and committed there;
`README.md` is regenerated in the same commit as any write that changes a fact it states; and
`research/timeline.md` is regenerated in the same commit as any write that changes the milestone
set or its order** (both field lists are named below). The first two exist from scaffold; the
timeline appears with the first milestone note, in Phase 3.

- **`.gitignore`** — editor and OS state only: `.DS_Store`, and an editor's per-window workspace
  file (Obsidian rewrites `.obsidian/workspace.json` on every open, so unignored it makes each
  commit noise and buries the ledger changes the history exists to show). Never ignore a dotfile
  wholesale: `.vault/config.json` is what makes the directory a vault, and a clone without it is
  not one. **Rendered `deliverables/*.pdf` are committed, not ignored** — they are the artifact a
  shared vault exists to share, and a repo whose deliverables are ignored hands a recipient the
  working notes and none of the output.
- **`README.md`** at the vault root — what the product is; what this corpus is and which skill
  produced it; the note-type map (the seven types and what each asserts); where to start reading
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
- **`research/timeline.md`** — the artifact that holds what is true at a given month, generated
  from `milestones/` and carrying three sections: **state at M0** (each item shipped or absent,
  and what each absence costs), **the sequence** with what each item unlocks and the resource it
  consumes, and **chains** — walking a proposal to the month it would land, with its prerequisites
  counted. It is a *view* over the notes, not an eighth hand-maintained document: a file that
  mirrors the plan's roadmap table drifts from it, and nothing in the corpus can tell.

  **The failure it closes:** nothing else in this contract holds state over time, so a proposal
  gets judged against the corpus's snapshot of today rather than against the state at the month it
  would land. That is wrong in both directions — it kills a proposal over a gap that is a dated
  roadmap item, and it credits a capability whose prerequisite has not shipped. Both read as
  rigour, which is why neither gets caught.

  **Four writes regenerate it, named for the same reason the README's four are:** a milestone
  written or retired, a `sequence` change, a `depends_on` or `resource` change, and an M0 state
  change (an item shipping, or a shipped one being pulled). Anything else — a `title` reworded, a
  `date_stated` corrected — leaves it alone. The trigger has to be decidable from the write
  itself, because a rule that required re-reading the generated file before every commit is one
  that gets skipped, and a timeline that lags the ledger is worse than none: it reads as the
  answer to *what is true in month N*, which is exactly the question nobody re-derives.

Then build the dossier: run the **market-analysis skill's Phase 0 only** — a cheap
dossier-building pass (explore agents on a repo; drafting from a doc/idea), no research fleet —
writing it to `research/product-dossier.md` (vault-relative — the slug directory is the vault). The grill needs the dossier's value
hypotheses to exist; nothing else of market-analysis runs yet.

**Inventory the founder's own artifacts before the grill, and measure them rather than asking
about them.** Not a question — a worklist: every repo the founder has written (not only the
subject), every repo they have worked in for someone else, every document produced for a client
(proposals, audits, strategic reports, statements of work), every product in this category they
have personally used, and anything they have published. Establish what exists, then open it —
what an artifact is measured on lands as a primary observation resting on that artifact as its
`source`, exactly as the sweep below records what it finds. **A founder's own artifacts are the
only evidence in an engagement that is simultaneously free, primary, checkable and unavailable
to a competitor**, and market research is none of the four. Measuring rather than asking is the
whole of it: asking returns the founder's recollection of an artifact, which is commentary and
tags `L` like everything else they say, while opening it returns an observation anyone can
re-check against the same file. The two arrive in the same words and only one is evidence. **The
failure this prevents:** the grill asks what the founder's unfair advantages are and gets an
adjective the plan then carries unsupported, while the repo that would have proved it, the dated
report that predates the plan's own thesis, and the category tool they used for two years and
abandoned all sit unopened. The sweep below is one entry on this list, and nothing has ever asked
for the rest.

**Sweep for founder-authored writing before the grill — it is the cheapest context you will
ever get.** Blog, changelog, README, docs, talks, launch threads, issue bodies — and the class
that outweighs all of those, what the founder wrote for a paying client: proposals, audits,
strategic reports, statements of work, post-mortems. Founders routinely explain their own
reasoning in public and then never mention it, because to them it isn't news; they leave the
commercial half out because it does not occur to them that it counts as theirs to offer. It
counts most. A thesis stated in a dated report to a paying client — addressed to a third party,
with money attached to being right, and usually predating the product by years — is categorically
stronger evidence than the same thesis on a blog. Skipping this sweep means grilling for things
already written down and, worse, missing the founder's own framing of why the product is shaped
as it is. Anything public lands as `[F#]` with its URL, and as a `source` note carrying that URL.
**A client document lands as what it establishes and never as the file:** these are confidential
by default, so what enters the corpus is the claim and its date, resting on a
[source with no public URL](references/vault.md#the-source-note-keeps-the-quote-that-outlives-the-url)
whose provenance names the document's kind and its year — never the text, never the client, never
a copy in the vault. That rule is stated in the paragraph that creates the exposure, because the
vault is a git repo from this phase and is offered a remote in Phase 5: omit it and the sweep's
own success is what puts a client's confidential document into a corpus built to be shared.

**The product's own records are the third inventory, and the one this method kept walking past.**
The two sweeps above cover what the founder **wrote**; this one covers what the product
**measures** — its users, its own operation, and the job it claims to do. It is the artifact
sweep's argument one step closer to the subject, with one property none of the founder's own
artifacts has: it is a dated series about the very people the plan is about. The dossier pass
above built the inventory; **this phase is where the readable entries get read**, because that
pass can only see shapes — the query itself needs the founder, and the founder is here. An
inventory of unopened stores is the original defect wearing the shape of a fix.

**Each figure read becomes a note, on the same terms the artifact sweep uses.** The instrument is
a [source with no public URL](references/vault.md#the-source-note-keeps-the-quote-that-outlives-the-url)
whose provenance names the store and the query, and each figure read off it is a `fact` resting on
that source. Notes rather than prose, for the reason every rule in this release exists: the
dossier's inventory is prose a later phase may never re-open, while a dated note is on disk at the
moment a dimension files the binding driver at `L` for *"no instrument exists"* — which puts the
contradiction in the corpus instead of in somebody's memory of Phase 0, and is the only reason the
conductor's read at Phase 2's checkpoint can catch it at all. Invariant 3 then governs what the
figure means before it is cited as evidence for a mechanism.

**An entry closes with a figure and its date, or with its blocker named — never with the store
named and nothing else.** A blocker is a real one: the instrument is not built, the access is the
founder's to grant, the export is theirs to run. *Nobody ran the query* is not a blocker, and on
the run this comes from it was the only thing standing between the corpus and every instrument it
needed. Invented, and the shape rather than the products is the point: a completion log for the
product's core action settles how often the job actually gets done per active account — the
denominator the plan's retention assumptions are otherwise guessing — and a per-account progress
table settles what fraction of accounts reach the step the whole thesis turns on, **as a
percentage**, which ends an argument between founder and analyst that no quantity of category
research could.

**What enters the vault is the figure, never the rows** — the count, the fraction, the date and
the query that produced it, and never a row, never a free-text answer verbatim, never an export
copied into `research/`. Same rule as the client document above, and worse here in one way: this
data is the subject's own users', which makes copying it into the corpus the easier thing to talk
yourself into.

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
- **Category usage** — which products in this category the founder has personally used, and what
  specifically broke. A named failure they hit themselves is a primary observation and outranks
  any feature matrix; their verdict on a competitor is commentary. Both arrive in one sentence,
  so file them apart.
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
the file is written once and only ever grows. Crossing out of this phase runs invariant 22's
sweep, over the grill that just happened.

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
- `competitor-analysis.md` carries its `## Adoption candidates` section, rolled up from the
  profiles, **and every profile that carried no adopt section is named there as missing it.** Each
  candidate arrives as the fields a `milestone` note is authored from, which is what lets Phase 3's
  roadmap step adopt and date it or refuse it with the reason on the record
  ([references/roadmap-sequencing.md](references/roadmap-sequencing.md#rule-8--an-adoption-candidate-is-the-other-legitimate-source-of-an-item-admitted-or-refused)).
  Without the roll-up the profiles found what to copy and the plan never sees it: the run passes
  every other check on this list while the cheapest move available to a founder — copy the part
  that already works, from a company that has already paid to learn it — never reaches the roadmap.
  The named-as-missing half is what stops the roll-up from clearing this line while being short for
  the wrong reason, since a category with little worth copying and a set of profiles nobody asked
  read identically here and only the second is worth re-running. The first line's "all contract
  files exist" cannot do the work — it is satisfied by `competitor-analysis.md` existing, and a
  document existing says nothing about whether anything in it points at what this product is
  behind on.
- `competitor-analysis.md` carries its `## Monitoring plan`, and **every axis names an instrument,
  a cadence and the decision it would change.** Those three columns are what the render gate's
  `--monitoring` fails an axis for leaving empty, and this checkpoint is the last one at which
  filling one in costs a sentence: the researcher who knows which direction a profile was pointed
  is here now and gone by Phase 5, and an axis invented at the render is a watchlist entry rather
  than a trigger. Every profile in that document is a snapshot dated on the day it was taken, and
  a snapshot cannot see a direction — one researched the day before it was used missed a strategic
  reversal by that vendor six weeks earlier, the single fact that most changed what the competitor
  meant. The first line's "all contract files exist" cannot do this work: it is satisfied by the
  document existing, and a document existing says nothing about whether anything in it watches a
  direction rather than a page.
- `research/growth-curves.md` exists, and `market-analysis.md` carries its `## Comparable growth
  curves` section: the series indexed to months since origin, each company's origin event named,
  and the companies held out of the indexed overlay listed rather than dropped. The band says how
  fast comparables grew; only the indexed set says *when*, which is what a dated target asks.
  Without the file Phase 3's shape check has nothing to place a trajectory against and degrades
  back to the level check it exists to extend — silently, since the level check still runs and
  still passes. An origin left unnamed makes two series incomparable while they sit on one axis
  looking comparable, and an exclusion left off the list reads as a comparable nobody found rather
  than one whose origin could not be dated.
- That same `## Comparable growth curves` section carries the **mechanism record** beside the
  indexed series — per comparable, how it got from zero to its first $1M: the launch motion, the
  first channel that produced PAYING customers, what the founder did personally that did not scale,
  what compounded, and what was tried and abandoned. A `"rates only, no origin account found"`
  line against a comparable is a **pass** on this check: it is the record doing its job, and
  silence is the failure. Without the record Phase 3's `## Growth engine` section has only
  category-general rules to write from, and the plan's acquisition assumptions read as evidenced
  when they were designed
  ([references/growth-engine.md](references/growth-engine.md#the-first-channel-is-cited-from-the-mechanism-record-never-chosen-out-of-the-rules-above)
  carries that rule and the failure behind it). This checkpoint is also the last one whose context
  is live: the bucket this product sits in is the one the indexed set is emptiest in, so a mechanism
  nobody hunted here is one nobody can hunt by Phase 5.
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
- `research/product-dossier.md` carries its `## Instrumentation inventory`, and **every row is
  reconciled by name against what the fleet came back with, both directions.** *Forward:* a
  `question` note's `gaps` entry or an `L`-tagged driver naming a quantity some row says an
  instrument could settle means that instrument was never opened — the binding driver gets filed
  at `L` for *"no instrument exists"* while a dated `fact` note carrying the figure sits in the
  same vault, and nothing compares the two. *Reverse:* a row marked read, with its `fact` note
  minted, and the dimension owning that quantity resolved through a comparable anyway — the
  measurement is on disk and the plan is about to run on somebody else's proxy for it. Both
  directions carry weight for `--red-team`'s reason: with only the forward one, the cheapest way
  past an instrument nobody wanted to query is to delete its row from the inventory. This phase
  is the last one whose context is still live when the fix costs a single query, and the first
  line's "all contract files exist" cannot do the work — it is satisfied by the dossier existing,
  and a dossier existing says nothing about whether anything in it was opened.
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

**Where the verdict comes back reachable, or undetermined with its upper corners clearing, the
furthest defensible target is solved in the same pass and reported beside it** — the same identity,
the same date, the same stated resources, with the evidenced driver ranges at their defensible top
instead of their bottom, capped by a named driver and its kind
([references/target.md](references/target.md#the-furthest-defensible-target-is-a-solve-too-and-a-target-that-clears-with-room-was-set-too-low)).
A target that clears with room is evidence about the target. Every other guard in this skill catches
a founder claiming too much; this is the one that catches a plan sequenced to a number smaller than
its own evidence supports, where the roadmap order, the capital path and the reference class were
all settled against the smaller one for the same work.

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
  one minted while it was being written. **Name the heading's `{#anchor}` attribute, which
  `plan-template.md` puts on every heading, rather than the slug of its text** — the headings
  are action titles you will reword as the finding sharpens, and a citation written against the
  text dies on the first rewording with nothing reporting it until the render gate runs.
- **The thesis traces.** The plan's core bet restates the analysis's whitespace recommendation,
  sharpened by the founder's unfair advantages — traceably, not vibes-first.
- **Cite by code, and there is no third kind.** `[S#]` resolves through `sources.md`, `[F#]`
  through the founder brief; invariant 1 is what bars a fact with neither.
- **The financial model is assumption-first.** Every input is a named row in the assumptions
  table (source: analysis, founder, or explicit guess), the revenue build is bottom-up, and
  base/downside/upside scenarios move the assumptions — not the conclusions. Fake precision is
  the failure mode; visible formulas are the fix. Every explicit-guess row is an `assumption`
  note with a `sensitivity`, which is what orders the validation queue. **Every one of those
  notes declares `model_input` — `revenue` or `cost` — or declares `excluded_from_model` with
  the reason.** `--assumption-rows` reads the table both ways, and the direction that catches a
  missing row fires only on notes that declared themselves, so a corpus where nothing carries
  the field has that half checking nothing — and its success line now names that half as un-run
  rather than reporting the rows it did match, which is what let the gate read green over the
  exact gap it exists to find. Declaring the field is still the whole point: a line the notes
  never claim is one the check can only report as unclaimed, which is how a whole
  revenue line stayed out of a projection with every note behind it lint-clean, the failure
  invariant 16's third clause and [references/vault.md](references/vault.md) both name. **Every input to the
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
  **Write the `milestone` notes before the roadmap table, not after.** One note per item, each
  carrying its `sequence`, the `resource` it consumes, and the `moves` edge naming the note it
  changes ([references/vault.md](references/vault.md#the-milestone-note-carries-a-position-a-cost-and-the-assumption-it-moves)).
  The table and `research/timeline.md` are both renderings of that set. Written the other way
  round they are two hand-maintained lists, and the lint has nothing to read: "every item names
  the assumption it moves" and "two items on one resource are not concurrent" are exactly the two
  rules that were prose nobody verified until the notes existed to carry them.
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

**The target list is generated, not read.** Invariant 19's reconciliation runs before any of this
and gates the dispatch — its three lint calls, `vault-lint.sh --used-in`, `vault-lint.sh
--supersession-sweep` and `vault-lint.sh --red-team`, belong beside the query below rather than in
a block of their own, and no brief is written until the read behind them is done. On a first
dispatch `--red-team` has no closed round to check and passes; on a re-dispatch it is what stops
a second panel being briefed over a first one whose objections were never written down. Two further queries then run before the panel
is briefed: `vault-lint.sh --unverified`, and every claim that reached the plan carrying
`confidence: L`. Those, addressed by note ID with the sections their `used_in` names, are the attack
surface each panelist's brief carries in its lens. "Read the plan and object" produces objections
about whatever a panelist happened to notice; this produces them about what the corpus already knows
is weak. Every brief also carries the founder's named fear `[F#]`: attack this hardest, then name
the two risks the founder did NOT name. The operator and target-customer briefs additionally carry
the structural half of `research/growth-curves.md`'s strategy record — what comparables had that
this founder does not — because that is an objection the corpus can already evidence rather than
one a panelist has to invent.

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

Each panelist's objections land in `red-team.md`, one row per objection, with an ID namespaced
by round:
`| R<round>-O<n> | Lens | Objection | Severity | Disposition (fixed / moved to Risks / rejected + why) |` —
round 4's third objection is `R4-O3`. Round is the count of times Phase 4 has been dispatched for
this engagement, starting at 1 and incrementing on each re-dispatch (a plan revision, a follow-on
session); objection numbering restarts at `O1` inside each round, so the round prefix is what
keeps round 2's `O1` and round 4's `O1` from colliding on whichever a reader finds first. **Once
cited, a code is never renumbered** — invariant 21 states the same rule for `[F#]` and for the
same reason: renumbering silently repoints every citation already written.

**`red-team.md` also carries the roster of what was dispatched, under `## Lenses dispatched`, and
a lens on it owes at least one row.** It is a two-column table — `| Round | Lens |`, one row per
lens per round, the round written as `R1` so it reads as the same namespace the objection IDs
carry:

```
## Lenses dispatched

| Round | Lens |
|---|---|
| R1 | Capital skeptic |
| R1 | Operator |
| R1 | Target customer |
```

**The failure its absence costs:** a lens returns, its findings get folded into two documents,
and its objection rows are never written here at all — and from outside, that is indistinguishable
from a lens that had no objections. Silence and thoroughness read the same, so the plan cites
objection codes into a table that never carried them and nothing says so. Nothing else in the
corpus records which lenses were sent, which is why the roster has to be created before it can
be enforced. `vault-lint.sh --red-team` checks it both ways: a rostered lens with no rows, and a
row whose lens is not on the roster — the second direction because otherwise the check clears by
deleting a line rather than by dispatching a lens. **Write a round's roster rows in the same edit
that folds that round's objections**, not at dispatch: a roster written ahead of the rows fails
the check for the whole time the round is in flight, and a gate that fails on the normal case is
one people learn to skip.

Fold: fix what's
fixable; every row disposed "moved to Risks" appears in the plan's Key risks section by its
round-qualified ID — a plan that pre-states its best objections beats one that hides them.
**A surviving objection also lands in the vault**, as a `claim` that `supersedes` what it
corrects or an `assumption` with a `validated_by` step. An objection disposed only in the table
is one nothing downstream can find. That note is subject to invariant 20 like any other: it is
finished when the section its `used_in` names carries it, not when the row is disposed — and a
note minted this late is the likeliest of all to be left sitting in a ledger nobody reads back
into the prose. If an objection guts the thesis, say so to the founder plainly and revise the
bet — that IS the job. That is a substantive founder exchange like any other, and it is the last
one before anything renders: invariant 22's sweep runs over it before this phase closes.

## Phase 5 — Deliverables

**Lint is the release gate, and it runs before the first render.** One call —
`vault-lint.sh --release-gate --vault "$VAULT_PATH"` — which invariant 15 breaks into its parts
and says what each is for. It exits non-zero unless every part passes, so the gate is a
verdict rather than a set of calls somebody has to remember making, and the sweep worklist it
prints is read to its end before anything renders — every supersession Phase 4 minted stamped
with the `reconciled:` date of that read, which is what the sweep fails on when it is missing. The
vault comes back clean or nothing renders: a plan citing a retracted or superseded source does
not ship, and neither does one whose citation names a document that was renamed or a section
that was cut. The failure this stops is the worst one available — a polished PDF asserting
flatly what the corpus already withdrew, handed to the one reader with no way to check it.

**Restate forward before you render — the artifact states what is true now, and the ledger keeps
the archaeology.** Invariant 14 is right and does not change: a retracted note keeps its status
and its reason, and a withdrawn line in the *markdown* stays struck through with the reason,
because silent deletion lets a dead claim return two drafts later with its cause of death erased.
The deliverable is the other side of that rule. Its reader was never in the room, and a note ID or
a red-team objection code is a **vault address** — it resolves for anyone holding the corpus and
resolves to nothing for the audience the document is for. A reader who gets both sees a document
arguing with its own previous draft. Left unchecked, a finished plan and its model carry well over
a hundred pieces of that narrative between them — into the two documents an investor reads.

So this is a step with an output, not a cleanup pass. For every correction the markdown carries —
a strikethrough, a superseded figure, an objection that changed the answer — **write the sentence
the corrected claim now supports** and let the artifact carry that. Then drop the address:
`[S#]` and `[F#]` citation codes are the reader's trace and stay; note IDs and `R<n>-O<n>` codes
do not.

**It is a restatement, never a strip filter, and that distinction is the whole design.** Removing
`~~…~~` mechanically leaves *"That multiple was actually…"* with no antecedent — the sentence
still renders, still reads like prose, and now asserts nothing. No script can judge an antecedent,
so the dangling-antecedent half is a named item in `rendering.md`'s render → Read the PDF back →
check every page loop, and the mechanical half is a check:

- **`vault-lint.sh --deliverable --vault "$VAULT_PATH"`** reads the *rendered*
  `deliverables/*.html` and fails on a strikethrough span, a note ID or an objection code. It
  gates the **rendered HTML rather than the markdown** on purpose: the markdown is the working
  document and keeps everything invariant 14 owes it, the HTML is what the outside reader holds,
  and the HTML is the only one a check can hold to this at all — the restatement itself is a
  judgement.
- It is one of `--release-gate`'s parts, so the call before the first render is still one call.
  But at that point nothing has been rendered yet and the mode says so, which means **the run that
  gates what ships is the one inside the render loop**, after the HTML exists and before the PDF
  is called done. A deliverable that failed it goes back through the restatement above, not
  through a find-and-replace.

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
- `competitor-analysis.md`'s `## Monitoring plan` watches axes rather than pages: every axis names
  the direction being watched, the instrument read to answer it, a cadence, and the decision that
  flips if the answer changes — and `vault-lint.sh --monitoring` fails a row leaving any of the
  three empty. Every profile carries the date it was researched and every claim its `stale_after`,
  so the corpus asks *is this still true* twice over and nothing in it asks *which way is this
  moving* — and a direction is the only thing separating a closing window from an open one. A
  profile researched the day before it was used missed a strategic reversal by that vendor six
  weeks earlier: the single fact that most changed what the competitor meant, and a re-check of
  pricing pages could not have seen it, because a snapshot cannot see a direction.
- Wherever the plan or the red team reasons from a count to a cause, the metric states what else
  produces that number, and a metric introduced after the conclusion it supports is named as one.
  Unexcluded, the alternative explanation ships as the evidenced part of the argument — and a
  second metric picked to confirm the first tests the thesis's fit to the instrument, which reads
  as corroboration and is the shape nobody stops to check.
- Lint is clean over the whole vault at the per-dimension gate, and the render gate ran
  `vault-lint.sh --release-gate` to a zero exit — every part, one verdict — with the
  `--supersession-sweep` worklist it printed read to its end, every superseded pair carrying
  the `reconciled:` date of that read, and every note naming its replacement in `superseded_by`
  named back by that replacement in `supersedes` — a supersession the successor does not record
  is one the sweep reads as replaced by nothing, so its cited sections are never named. The bare run is a strict subset of
  the checks that exist and its success line now says so, so a plan clears it while citing a
  document nobody can open — and the last thing standing between that citation and a rendered
  PDF is this gate.
- Every lens dispatched to the panel wrote at least one row in `red-team.md`, and every row's lens
  is named in its `## Lenses dispatched` roster. A lens whose findings were folded into two
  documents and never written down reads exactly like a lens that had no objections, and the
  plan then cites an objection code into a table that does not carry it.
- The plan states the strongest claim its evidence supports, and a claim weaker than its evidence
  is an error of the same class as one stronger. Understatement is not caution: an overclaim gets
  challenged, an understatement gets believed. Every other bar on this list fires on optimism, so
  a claim falling short of its own evidence clears all of them and reads as rigour — to the
  founder, to the panel, and to the reader who acts on it — and the only person who can catch it
  is the one who re-opens the source. The both-directions test below governs the *values* in the
  model; this governs what the prose asserts, whatever the evidence behind it was.
- Every claim about the subject's own product was re-verified against source at the current
  commit before the first section was drafted, and each drift landed as a supersession rather
  than an edit in place. This is the bar above at the one point it can be enforced by
  construction: the product moves while the research fleet spends a week running — a capability
  shipped, a limit was raised, a seam was closed — so *which* claims fell behind their own
  evidence is a knowable population here, and a matter of noticing everywhere else.
- Every claim cited in a rendered document carries `used_in`, and every `used_in` target carries
  the claim — a claim whose named section does not say what the note says is still open,
  whenever it was minted. Every `required: true` subject has a claim under it or a stated gap.
- Every cited section's content hash is recorded in the claim's `reconciled_sections` as it was
  read, and `vault-lint.sh --claim-drift` re-opens the claim when the section no longer matches.
  The bar above is satisfied once, at drafting; this is the only thing that keeps it satisfied
  afterwards. A later re-solve rewrites the block and leaves the heading alone, so `--used-in`
  still resolves and the gate stays green over a section that has stopped saying what the note
  says — found by hand days later, or not at all, by which point the one reader with no way to
  check it has acted on it. A `schemaVersion` 3 rule, so a vault at 1 or 2 is told the rule was
  not applied rather than that its documents agree.
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
- Every roadmap item names the assumption it moves, and it names it in a `milestone` note rather
  than in the table alone — so the naming is a `moves` edge the lint resolves, not a sentence.
- The roadmap table and the milestone set are the same set, and the item cell is the note `title`
  verbatim. `vault-lint.sh --roadmap-table` reads it both ways: a row with no note behind it moves
  no assumption anybody can name, and a note the table never lists is a dated change to an
  assumption row the plan does not show — so the curve has a step its reader cannot see.
- The roadmap's order survives its own two checks: no item sequences before a prerequisite it
  declares, and no two items sharing a constrained `resource` are asserted concurrent. Both are
  read off the notes by `vault-lint.sh`, and a plan that has a roadmap and no `milestones/`
  directory has neither check run over it — which prints the same green as one that passed them.
- The financial model's assumptions table is complete in **both** directions — no number appears
  in a projection that isn't a named assumption row, **and** no assumption note that declares
  itself a model input is missing from the table, **and** every live row is backed by a note the
  ledger still stands behind, `assumption` or `claim`, rather than only by one retired to
  `superseded` or `retracted`. `vault-lint.sh
  --assumption-rows` reads all three against each other; the second half is the one that was prose and never fired, and what it cost
  was a whole revenue line that existed as correctly authored notes, never became rows, and was
  therefore filed as *revenue outside this model* — which reads as a modelling decision and was a
  consequence of the omission. Every verdict downstream inherited a denominator missing it.
- A revenue line the roadmap ships a change to is reachable from the model that solves the
  target, or the exclusion is stated at the identity. Excluding one is legitimate — a metered
  layer must not be allowed to flatter subscription churn — so the note carries
  `excluded_from_model` with the reason and the verdict note names it in `arr_excludes`. Undeclared,
  the ARR term every corner is solved against is a subset figure and nothing says which subset, so
  three re-solves can each correct a different term, inherit the same denominator, and never move
  the answer.
- A ranged target's readout is the set of corner verdicts, with the binding driver and its `kind`
  named per corner, and the founder's stated range labelled apart from the evidenced range.
  Collapsed to one verdict or one interval, the finding is destroyed exactly where it matters — a
  rectangle where three corners clear and one fails reads at its centre as a clean yes, and the
  failing corner is usually the one the founder was aiming at. **Every corner that names a kind has
  a filed verdict note behind it carrying that kind** — the table renders off the notes, so a
  corner rendered with no note is a verdict the ledger never saw and `--binding-driver` fails it.
- Where the verdict is reachable, or undetermined with its upper corners clearing, the plan reports
  the furthest defensible target beside it, in the founder's currency and with the driver that caps
  it named. The nearest-reachable solve has governed the downward case since the first release and
  nothing governed the upward one, so a conservative target was computed, verdicted and never
  questioned — and an understatement is inherited by every document downstream while reading as
  discipline. A bar that fires only on optimism is a filter, not a check.
- The plan matches the founder's stated ambition, not a template's default ambition.
- Nothing was dispatched to the red team until the plan and the vault were reconciled: the
  `--used-in` pass clean, the `--supersession-sweep` worklist read to its end and stamped
  `reconciled:`, `--red-team` clean over every closed round, and every
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
- Every rendered deliverable reaches its reader carrying no vault address, and
  `vault-lint.sh --deliverable` reads `deliverables/*.html` and fails on a strikethrough span, a
  note ID or an objection code. Invariant 14 keeps retraction visible in the plan, which is right
  for the working document and wrong for this one: a note ID and an objection code are addresses
  into a corpus that reader does not hold, and a struck-through line with its reason beside it is
  a document arguing with its own previous draft. The route out is Phase 5's restate-forward step
  and never a strip filter — deleting a `~~…~~` span leaves the sentence after it correcting an
  antecedent the reader can no longer see.
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
| Product claim gone stale in the pessimistic direction | Re-verify against source at the current commit; a drift is a supersession |
| Policy variable reported as a ceiling | Label every input structural or policy and record the label on the note; a chosen input caps the configuration, not the business |
| Venture template forced on a bootstrapper | Ambition question first; shape follows it |
| Red team skipped ("plan looks solid") | It runs every time — that's when it's most needed |
| Grilling the founder on what research answers | Grill intent/resources/appetite; research the market |
