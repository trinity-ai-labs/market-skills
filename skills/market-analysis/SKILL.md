---
name: market-analysis
description: Use when a product needs a rigorous market analysis — market sizing, competitive landscape, customer segments, pricing, timing — whether the product is a code repo, a spec/PRD/doc, or just an idea described in chat. Also the sub-skill the business-plan skill dispatches headless.
---

# Market Analysis — Evidence Engine

Produce a market analysis a founder can bet money on. The core principle: **evidence over
narrative**. Every number is traceable to a dated source, sized bottom-up before top-down,
reported as a range with a confidence tag — never a fake-precise point estimate that collapses
under an investor's first question.

You are the analysis conductor. Your context is for framing, judging, and synthesis — the
research itself is fanned out to sub-agents. Scale the fleet to the product: a niche CLI tool
runs ~40 dispatches; a multi-sided platform in a regulated space runs 100+. Be deliberate
about every dispatch, not fixed-size.

## Run modes

| Mode | When | Questions to the user |
|---|---|---|
| **Interactive** | Invoked directly in a conversation | Yes — grill on genuine gaps (see Phase 1) |
| **Dispatched** | Run as a sub-agent (e.g. by the business-plan skill) | **Never.** The brief carries the founder's answers; any remaining gap becomes a logged assumption, not a question |

You are in dispatched mode when — and only when — your brief carries the line
`MODE: dispatched`. Never infer it; default to interactive. In dispatched mode every gap you
would have asked about goes into the report's `Assumptions` section as: the assumption, why
you chose that default, and what would change if it's wrong.

**Dispatched brief contract** — a dispatching skill (e.g. business-plan) must pass, and you
must refuse to start without: `MODE: dispatched` · `slug` · `outDir` (absolute — never
`~`-prefixed) · `date` · `source` (repo path | doc path | idea text) · the founder/user
answers as numbered facts · any category-boundary decision already made · `mustProfile`
(competitors the founder named — always profiled) · `ambition` (venture | bootstrap |
lifestyle | lender — bootstrap/lifestyle skips the top-down sizing agent and runs bottom-up
only, while still stating the venture-scale sniff test) · `target` (the outcome the dispatching
plan is engineered backwards from and its date, or `no specific number`) ·
`provisionalVerdict` (that skill's pre-research verdict — reachable | unreachable |
undetermined — and the driver it named as binding, or `none — no target stated`) · which of
your phases to run (a conductor that ran your Phase 0 itself and renders its own deliverables
will say "Phases 1–4 only, no deliverables, no user-facing close"). One optional field: `vault`
(absolute path). When it is present the fleet also emits notes per the **vault note contract**
below; when it is absent nothing about the research changes and no notes are written. What a
`vault:` path adds is a review obligation, not just an extra output: the `source` notes the fleet
mints are what the dispatching plan resolves its later citations through, so your read of the
dimension file (Phase 2) is the only thing standing between an unreviewed agent and a citable
number in a document that never re-derives it.

**The target sets the resolution of the sizing, not the research method.** Size at the
resolution the target is denominated in: a target in paying customers or in MRR makes the
bottom-up segment count — reachable buyers, and what they already pay — the load-bearing
output, with the top-down category figure kept as the sanity check on it. A category figure in
billions cannot be divided down into a specific customer count, so a report that leads with one
forces the dispatching skill to re-run the dimension for a number it can actually put in an
identity. `no specific number` restores the ordinary balance — size the category and the
segment as you normally would.

**The provisional verdict names the driver to research hardest.** Whichever driver it calls
binding — price, conversion, retention, or reach — is the dimension to pin down first and to
return with the narrowest range you can actually evidence, because that is the number the
verdict is re-computed against once you are done. A binding driver returned as a wide unsourced
band leaves the verdict undetermined and wastes the research run that existed to settle it. The
verdict itself is an assumption made before any evidence: never cite it, and report what you
found even when it contradicts the verdict outright — that contradiction is the most valuable
thing the run can return.

## Output contract — deterministic home

All output lands in one stable folder per product:

```
~/Documents/go-to-market/<product-slug>/
  product-dossier.md        # what the product IS (Phase 0)
  market-analysis.md        # the main report (Phase 4)
  competitor-analysis.md    # deep competitive landscape (Phase 4)
  sources.md                # master source log — every number's URL, pull date, quote, confidence
  research/<dimension>.md   # raw per-dimension findings from research agents
  research/profiles/<competitor>.md  # one file per profiled competitor (Workflow A)
  deliverables/             # rendered HTML + PDF of the reports (Phase 5)
    market-analysis.html
    market-analysis.pdf
```

**Slug rule (deterministic).** The settled product name wins; the repo directory name (for a
monorepo: the analyzed package's directory, not the repo root) is the fallback only when no
product name is established. Normalize exactly: lowercase → replace every run of non-`[a-z0-9]`
with a single `-` → trim leading/trailing `-`. An idea with no name yet gets NO files written
until the name settles — settling it is the first grill turn (interactive) or comes from the
brief (dispatched). Before minting a folder, `ls ~/Documents/go-to-market/` and reuse any existing
folder whose dossier names the same product. Record the slug as a `slug:` line in the
dossier's front matter. Same product → same folder, on every run, forever. A re-run **updates
files in place** — never a `-v2` folder, never a timestamped copy; prior research is context
to refresh, not to ignore.

`~` is shorthand in this document only: expand it to the absolute home path in every path you
pass to a tool or embed in an agent brief — agents never receive a `~`-prefixed path.

Templates for every file: `references/templates.md`. Load it before writing any output file.

## Phase 0 — Understand the product

The input is a product pointed at one of three ways. Build `product-dossier.md` before any
market research — research agents get briefed FROM the dossier, so a mushy dossier poisons
everything downstream.

- **Repo** (most common): fan out 2–4 explore agents in parallel over the codebase (model:
  `sonnet`, effort low) — README, docs/, landing/marketing pages, package manifests,
  pricing/billing code, auth/team features, CLI surface. One of them does **infra-cost
  archaeology**: inventory every paid service the code actually runs on — cloud/hosting from
  IaC and deploy configs, databases and queues from docker-compose/connection code, LLM and
  third-party APIs from SDK imports and call sites, storage/CDN/email/auth providers — plus
  the usage SHAPE (per-user, per-request, per-token, per-GB) each is billed on. Env
  *templates* only (`*.example`, `*.sample`) — never read real env/secret files. **Another does
  instrumentation archaeology** — the inventory below. They return facts; you write the dossier.
- **Doc** (spec, PRD, pitch memo): read it fully. Note what it asserts vs. what it assumes.
- **Idea** (described in chat): draft the dossier from the description; the gaps you can't fill
  become Phase 1 questions.

The dossier must state: what the product is (one paragraph, precise), who it's for, the core
jobs it does, its stage (idea / building / shipped / revenue), stack and distribution surface
(desktop/web/CLI/API), anything priced or monetized today, what the product already **records**
(below), and — critically — the **category boundary**: what adjacent categories this is NOT (the
single biggest cause of a mushy analysis is an unbounded category; "market size" for a fuzzy
category is an unfalsifiable number).

**Inventory what the product already measures, not only what it is — it goes first because it is
the cheapest primary evidence the engagement will ever have.** The passes above establish what
the product IS; this one establishes what it has already *measured* about its users, its own
operation, and the job it claims to do. A row this product's own users wrote is free, dated,
checkable and the one class of evidence a competitor cannot obtain, which is more than anything
the research fleet below will return. Every schema and migration, event-logging call site,
analytics or telemetry SDK, admin view, report query and export endpoint is an instrument — **one
entry per store or event type, never per call site**, since one call site establishes the shape
and a codebase has hundreds. **Read shapes, never data:** a schema and a call site answer *what
is recorded*, and the reading itself is a query the founder runs or authorises — the same
boundary the env-template rule above draws, for the same reason.

Four fields make an entry rather than a filename:

- **what it records**, at what grain — per account, per action, per day
- **the quantity it could settle**, named, and which claim in this analysis rests on a guess
  about that quantity today
- **read?** — the figure and the date pulled, or `unread` with what is blocking it
- **what reading it costs** — one query, an export the founder has to run, or a migration
  because the field is not there yet

An entry that names a store and stops is the same silence as no entry: it reads as diligence and
settles nothing. The inventory lands in the dossier's own `## Instrumentation inventory` section,
beside the infra-cost pass's — one section per archaeology pass, because an enumeration that
names one of two siblings drops the other. A figure already read is additionally evidence on
whichever of the `## Value hypotheses` it bears on, and **every entry still `unread` lands in
`## Open questions` naming the quantity it would settle**. That last hop is the firing mechanism,
and both ends of it are steps rather than inferences: Phase 1 asks for access to each `unread` row
by name, and the dispatching plan's own verification checklist reconciles every row against what
the fleet came back with. An inventory whose consumers were left implicit is the shape this whole
release is repairing. **The failure this prevents:** an
analysis spends its entire budget on competitor documentation, survey statistics and category
M&A, files the conversion assumption the whole thesis turns on at low confidence because no
instrument exists, and ships — while the subject's own database held a free-text field asking
arriving users what they came to do, unread, its row count unknown.

A doc or an idea gets the same four fields and a different answer, and the empty inventory is
itself a result. A spec describes instruments that may or may not exist, so each is an entry
marked unbuilt until the founder says otherwise; an idea records nothing yet, which makes the
first instrument a build item with a date rather than a blank — and the quantity it would have
settled is the one the plan is otherwise going to assume permanently.

**Extract value, not just facts.** The dossier's load-bearing section is **Value hypotheses**:
3–6 falsifiable claims about why anyone would pay — each naming the pain it kills, who feels it
most acutely, why this product's answer is meaningfully better than what those people do today,
and the evidence in the source. A repo tells you more than its README: where the engineering
effort went is what the maker believes matters; the onboarding flow is the intended aha moment;
the roadmap/issues are the value bets not yet placed. Brief the explore agents to hunt exactly
that, and to separate **differentiated value** (absent in alternatives) from **table stakes**
(needed to play, worthless to lead with). These hypotheses drive everything after: the grill
tests them on the founder, and every research dispatch tests them on the market.

## Phase 1 — Frame and grill (interactive mode)

Before spending research tokens, close the genuine gaps. Grill like a partner, not a form:
**one question at a time, each with your recommended answer and why** — a wrong guess is cheap
to correct and moves faster than a blank question. Pre-answer everything the dossier already
answers. Never batch a questionnaire.

An idea with no settled name gets the naming question FIRST — the slug, folder, and every
file wait on it ("I'd plan this under the working name X — keep it, or name it now?").

**The value hypotheses set the agenda.** For each hypothesis, decide: settled by the source,
testable by research, or only answerable by this human — and ask ONLY the third kind. The
sharpest questions are hypothesis tests, not intake fields: "the effort in this repo says
real-time collab is the bet — but the docs sell speed. Which is the value you'd defend?" A
grill that could have been a web search is a wasted turn; a hypothesis you never surfaced is a
blind spot the whole analysis inherits.

Ask only what changes the analysis:

- **Pointers & background** — open the grill (after the naming question, when one is live) with
  one open invitation: anything they want the research pointed at — docs, prior research,
  competitor lists, community threads, a spec — and any background the source can't show
  (history, pivots, why now, who this is for). Read every pointer before dispatching the
  dimension it touches; named competitors join `mustProfile`. One open ask, cheap to make,
  and it catches whole directions the dossier alone would miss.
- **Access to the instruments Phase 0 could not open** — every `unread` row of the dossier's
  `## Instrumentation inventory` is also an `## Open questions` entry naming the quantity it would
  settle. Ask for each by name, and ask for **access** rather than for what it says: the founder's
  recollection of their own store is commentary and tags `L` like everything else they say, while
  one query returns a figure anyone can re-check against the same rows. Founder-only by
  construction — the credentials are theirs — so it is the one class this phase asks about and
  never a turn research could have replaced. **Ask it early**, ahead of the conviction questions:
  an export has lead time, and a figure that lands after the fleet has dispatched changes nothing
  it already wrote. **The failure this prevents:** the inventory names the instrument, the grill
  never asks for the key, and the run reports the quantity as unevidenced with the evidence one
  query away — which is the whole defect the inventory was added to close, surviving into the one
  phase that could have finished the job.
- **Feature conviction** — which features they find the most valuable, ranked. This is
  founder-only, never inferable from the source, and always
  asked: where their ranking diverges from where the repo's effort or the docs' pitch went is
  the sharpest finding the grill can produce, and their top-ranked feature gets research
  priority — the willingness-to-pay and competitor-gap work centers on it.
- **Category call** — when the product straddles categories, propose the boundary and let them
  push back ("I'd analyze this as an AI app-builder, not an IDE — Cursor is adjacent, Lovable is
  direct. Agree?").
- **Target customer** — who pays, if it's not obvious. Segment guesses with a recommendation.
- **Geography / language** — default global-English unless the product says otherwise.
- **Pricing intent** — subscription? usage? one-time? Even a rough instinct disciplines the
  willingness-to-pay research.
- **What they already believe** — competitors they fear, numbers they've heard. You'll verify,
  not trust — but it seeds the search.

Call out bad framing when you see it — a category chosen to make the TAM look big, a "no real
competitors" claim, a customer defined as "everyone". A wrong frame you let through is your
failure. When the user pushes back with reasons, update; when they push back with vibes, say so
and hold.

In dispatched mode this phase reads the brief's answers instead, and unresolved items become
logged assumptions.

## Phase 2 — Research fan-out

**Precondition: prove web access.** Run one trivial WebSearch before dispatching anything. If
the web is unreachable, STOP and say so plainly — a market analysis without web access is not
producible, and agents without web tools don't fail loudly, they fabricate confidently.

**Competitive landscape runs first, alone — a hard gate.** It's the fastest way to falsify the
category boundary — if the "direct competitors" turn out to live in a different category, you
fix the frame BEFORE sizing a market that doesn't exist. Concretely: the engine is TWO
workflow invocations (Workflow A = competitive landscape = the table's first row; Workflow B =
every other row), with a conductor checkpoint between them where you read A's category verdict
and update the dossier's boundary before B runs. Never fold them into one uninterrupted run.

The standard dimensions (playbooks per dimension, including what each agent's return must look
like: `references/dimensions.md` — load it before dispatching):

| Dimension | Output file | Runs |
|---|---|---|
| Competitive landscape | `research/competitors.md` | First, alone |
| Growth curves & reference class | `research/growth-curves.md` | Parallel, after competitors |
| Market sizing (TAM/SAM/SOM) | `research/sizing.md` | Parallel, after competitors |
| Customers, segments & JTBD | `research/customers.md` | Parallel |
| Pricing & willingness to pay | `research/pricing.md` | Parallel |
| Trends, timing & why-now | `research/trends.md` | Parallel |
| Channels & GTM landscape | `research/channels.md` | Parallel |
| Unit economics & COGS at scale | `research/unit-economics.md` | Parallel — whenever the dossier has Cost structure signals (any repo with detectable infra; always for LLM-heavy products) |
| Moats, risks & regulation | `research/moats-risks.md` | Parallel |

Skip a dimension only when the product genuinely lacks it (a free OSS tool may not need
willingness-to-pay depth); add dimensions when the product demands them (marketplace → supply
side; regulated space → compliance deep-dive; hardware → BOM-flavored unit economics). Say in
the report which were skipped and why — silent truncation reads as coverage.

**Orchestration — this runs as a workflow, not a hand of solo agents.** Load
`references/orchestration.md` and adapt its canonical `Workflow` script; fall back to parallel
`Agent` dispatches only when the harness has no Workflow tool, keeping the same structure. One
agent per dimension is the floor, never the shape. What "heavy" actually means:

- **Multi-modal competitor discovery**: 3–5 finder agents, each searching a DIFFERENT way
  (category keywords, "alternative to X" queries, community/forum threads, marketplaces & app
  stores, funding databases). Dedup, then **loop until dry** — keep sweeping until a round
  surfaces nothing new. Then one profiling agent PER competitor that matters.
- **Split load-bearing dimensions**: sizing runs separate bottom-up and top-down agents,
  reconciled afterward; customers split per segment when segments diverge.
- **Verify panels, not spot checks** (Phase 3).
- **Completeness critic** before synthesis: one strong agent asks "what's missing — dimension
  not run, claim unverified, competitor unprofiled, number single-sourced?" Its findings are
  the next round of dispatches — up to 3 rounds; anything still open is recorded verbatim in
  `Coverage` and `Risks to this analysis`, never shipped silently.

Don't cap the fleet — 60, 100 dispatches is fine when the product warrants it. The discipline
is in the TIERING, not the count. **Set model and effort on every dispatch — never inherit:**

| Stage | Model | Effort |
|---|---|---|
| Phase 0 explore agents | `sonnet` | low |
| Finders, profilers, dimension researchers | `sonnet` | low–medium |
| Verifiers, gap-closers | `sonnet` | medium |
| Per-dimension reconcilers / competitors.md writer | `opus` | high |
| Completeness critic | `opus` | high |

Final synthesis (Phase 4) is not a dispatch at all — it runs in the conductor's own turn, on
the strongest model in the session, never delegated.

Every brief carries: the dossier (inline, it's short), the category boundary, the dimension
playbook from `references/dimensions.md`, the citation contract (below), the vault note contract
(below) whenever the run carries a `vault:` path, the `target` and the `provisionalVerdict`'s
binding driver whenever the dispatching brief carried them, and the exact output file path. A
researcher never reads this file, so a target that stops at the conductor changes nothing about
what comes back: the sizing agent returns a category figure because nobody told it the target
was denominated in customers. Research agents WRITE their own `research/<dimension>.md` and
return a compact summary.

**The summary is triage, not the review.** It tells you which file to open first and whether the
dimension is worth folding in at all; it is never the basis on which that dimension's output
enters the plan. The dimension's file is read — the file, not its summary — before that
dimension's numbers are cited or the notes it minted are trusted. Five agents writing straight
into `research/` are five unreviewed writers, and a conductor that judges each one by the summary
that same writer wrote about its own work has reproduced its worst failure mode five times in
parallel. The economy the fan-out exists for survives intact, because the reading is targeted
rather than exhaustive: one dimension file at the moment that dimension is about to be relied on,
never a raw dump of every agent's transcript.

**Citation contract (goes in every brief, verbatim):** every external claim carries its source
URL, the date pulled, and the exact figure or quote used. Numbers need **two independent
sources**; if they disagree >30%, report the range and why they diverge (usually: different
category boundaries). Tag every figure High (directly disclosed / primary survey), Medium
(derived via stated formula from disclosed inputs), or Low (flagged assumption). A number that
can't be sourced is reported as unavailable — **never fabricate a specific-looking figure**.
If you cannot reach the web, return an empty findings set with `reason: no-web-access` — never
answer a factual question from memory, and never cite a URL you could not fetch this session.

**Vault note contract (goes in every research brief verbatim — only when the brief carries a
`vault:` path).** The research prose does not change: the dimension file is still written per
`references/templates.md`, with its Sources table in-file. On top of it, each researcher emits
atomic notes for the outputs a later document leans on — a `source` note per citable source, and
ONE `question` note recording what the dimension could NOT answer. Notes for every paragraph
produce a second corpus nobody maintains; these are the assertable surface.

Generate every ID as the uppercased type, a hyphen, and eight random alphanumerics. There is no
registry, no counter, and no allocation table, so parallel researchers never coordinate and a
collision is structurally impossible rather than procedurally avoided:

```sh
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8; echo
```

Write each note to `<vault>/sources/<ID>.md` or `<vault>/questions/<ID>.md` — filename exactly
the ID plus `.md`, no slug and no date. A short body paragraph follows the frontmatter and is
never parsed.

```yaml
---
id: SOURCE-K92MZ1QA
type: source
title: "Publisher — what this material is"
status: current
confidence: M
created: "2026-07-26"
url: "https://example.com/reports/2026/pricing"
url_canonical: "example.com/reports/2026/pricing"
pulled: "2026-07-26"
quote: |
  The load-bearing passage, verbatim, exactly as printed.
counterparty: "Example Platform Ltd"   # optional — omit unless a party is on the other side
---
```

```yaml
---
id: QUESTION-DD31RR09
type: question
title: "The question this dimension could not answer"
status: current
confidence: M
created: "2026-07-26"
gaps:
  - "What is specifically missing, one entry each"
  - "Not the topic — the absence that makes this open"
---
```

Six rules bind both, and every one of them fails silently rather than loudly:

- **Block lists, never `[a, b]`.** Obsidian rewrites an inline flow list into block form when it
  saves, so a vault authored inline loses those values the first time somebody opens a note, and
  the query that depended on them returns a clean result over a corpus it can no longer see. An
  empty list is an omitted key — never `gaps: []` and never a bare `gaps:`.
- **Coerce nothing.** Every value is a string: quote every date, quote anything containing `: `,
  and never write a bare `yes` / `no` / `on` / `off` / `null` / `~`. YAML 1.1 and 1.2 disagree
  about those, so an unquoted value means one thing to the editor and another to the checker.
- **`quote` is required, and `|` is the only block form allowed.** Never `>`, which reflows line
  breaks into spaces at read time. URLs rot and pages are silently edited; the verbatim passage
  is what keeps the chain checkable after the page is gone.
- **`url_canonical` is the normalised `url`** — drop the scheme, `www.`, the fragment and every
  tracking parameter (`utm_*`, `fbclid`, `gclid`, `ref`), lowercase the host, drop a trailing
  slash, keep every query parameter that selects content. Two researchers citing one page from
  a newsletter link and a search result otherwise produce two notes, and a claim resting on both
  looks doubly sourced when it rests on one document.
- **`counterparty` names the party on the other side of a deal or a datum, and is omitted where
  there is none.** The platform whose take rate this is, the distributor whose terms these are, the
  one customer both quotes came from — a published report has no counterparty and omits the key
  rather than guessing one. This is the one field `url_canonical` structurally cannot reach: two
  deals with the same counterparty, written up on two separate passes, are two source notes with
  two canonical URLs, and deduplication cannot touch them because they genuinely are two documents
  — distinct pages, distinct pulls, neither a duplicate. The only thing they share is the party, and
  nothing but this field records it. Unwritten, the count of sources under a finding says two and
  the concentration says nothing: one relationship's terms stand in for a market's, at the same
  confidence letter as two independent ones, and a count of two reads as the opposite of what is
  there. A consumer that needs the value falls back to `publisher` and then to the `url_canonical`
  host, which is why an unwritten field degrades quietly instead of erroring — the chain, and which
  way it errs, are in
  [the vault schema](../business-plan/references/vault.md#the-source-note-keeps-the-quote-that-outlives-the-url).
- **One assertion per note.** `status` and `confidence` are per-note fields, so a note asserting
  two things has no correct move when half of it is disproved.

A researcher never writes a `claim`, an `assumption`, a `decision` or a `milestone` — those are
the conductor's synthesis, and a `fact` needs a `rests_on` edge into a source the conductor owns.
The other five note types, the edges, and confidence derivation are in
[the vault schema](../business-plan/references/vault.md), which is authoritative; nothing above
overrides it.

**Source-class precedence, in this order — it decides which number wins when they conflict:**

1. **Independent measurement and primary disclosure.** Third-party harnesses, benchmarks run by
   someone with no stake, filings, and the vendor's own published price list (a price list is
   primary about *price*, whatever else it is).
2. **Vendor self-reports — comparable ONLY against other vendor self-reports.** Never rank a
   vendor's self-measured claim against an independent measurement; the methodologies aren't
   the same instrument and the comparison manufactures a result. A vendor roadmap claim
   ("10× lower cost per token, shipping 2H") is credible about *intent and direction* and is
   not evidence of a *realised market price*. Say which of the two you are asserting.
3. **Aggregators — discarded, not averaged, when internally inconsistent.** An aggregator whose
   own figures disagree with each other, or that reports a rate with no stated formula, is not
   a weak source to be blended in. It is an unusable one. Averaging it with a good source
   launders the error into the headline.

**Distinguish the metric from the thing.** Two true measurements can point opposite ways
because they measure different quantities — a *list price for a named product* and a
*cost-per-unit-of-capability index* both legitimately called "price". Where a trend claim is
load-bearing, state which quantity moved, over what window, and by what mechanism (a step
change, a new cheaper entrant, a genuine cut). A plan that conflates them will be split open by
the first careful reader.

**A predictive claim is not refuted by a flat historical baseline.** When the founder's belief
is about what *will* happen, the historical series establishes the baseline the claim predicts
a break from — report it that way rather than filing it as a contradiction.

## Phase 3 — Adversarial verification

The load-bearing numbers — headline market size, top-3 competitor traction claims, the
willingness-to-pay anchor — get a hostile second pass. Dispatch verify panels (model: `sonnet`,
effort medium; three orthogonal lenses per claim: source integrity, category-boundary match,
recency) prompted to **refute**, defaulting to refuted when uncertain. **Any single lens's
refutation is a dispute** — the lenses are orthogonal, so a boundary-smuggled figure trips
exactly one; majority voting would wave it through. A disputed claim gets corrected or
downgraded to Low with the dispute (and its lens) noted. Cap the pass at the top ~12 non-L
claims — L-tagged figures are already flagged assumptions, nothing to refute.

## Phase 4 — Synthesize

Write `market-analysis.md`, `competitor-analysis.md`, and `sources.md` per
`references/templates.md`. Synthesis is YOUR job — never delegated, because it needs everything
in one head. The parts that are judgment, not aggregation:

- **Reconciled sizing**: bottom-up is the anchor (population × ARPU × stated penetration guess);
  top-down is the sanity check. Show the formula, not just the result.
- **Whitespace & positioning recommendation**: the specific gap this product can credibly own,
  and whether its differentiator is a real moat or a feature competitors copy in two quarters.
  This section is the load-bearing link to any downstream business plan — make it a specific,
  falsifiable bet, not a restatement of the product idea.
- **Risks to this analysis**: what's soft, what would change the conclusion, what to validate
  with real customers before committing capital. Carry every Low-tagged figure here.

## Phase 5 — Deliverables (HTML + PDF)

The markdown is the working truth; the deliverable is a document worth putting in front of an
investor. Render `market-analysis.md` + `competitor-analysis.md` into ONE polished, self-contained
`deliverables/market-analysis.html` and a print-quality `deliverables/market-analysis.pdf`.
Follow `references/rendering.md` exactly — it carries the design system, the paged-media CSS
that stops tables and figures from being cut across pages, the PDF toolchain fallback ladder,
and the mandatory verify loop: **render the PDF, Read it back, check every page for cut
content, fix, re-render.** A deliverable you didn't read back is not done.

Close by telling the user where everything landed (the deterministic folder) and the 2–3
findings that should change what they do next.

## Quality bars — non-negotiable

- Bottom-up sizing anchors; top-down only corroborates. Ranges, never fake-precise points.
- Every figure confidence-tagged; every source in `sources.md` with URL + pull date.
- Category boundary stated explicitly, with what's excluded and why.
- Competitor analysis names each rival's likely next move, not just their feature list.
- The whitespace recommendation is falsifiable ("own X for segment Y because incumbents
  structurally can't Z"), not generic.
- Unsourceable numbers are declared unavailable, never invented.

## Common failure modes

| Failure | Fix |
|---|---|
| Sizing a fuzzy category | Phase 0 boundary first; competitors falsify it before sizing runs |
| Single-sourced headline number | Two independent sources or downgrade to Low |
| $4.3B-by-2027 fake precision | Range + visible formula + confidence tag |
| Feature matrix with no wedge | Every competitor profile ends with "what they don't cover and why" |
| Research dumps as the report | Agents write `research/`; you synthesize judgment on top |
| Asking the user what research can answer | Pre-answer from evidence; grill only genuine forks |
| New folder per run | Deterministic slug; update in place |
