---
name: business-plan
description: Use when a product — a code repo, a spec/doc, or an idea — needs a business plan or a path to market: monetization, go-to-market, pricing, financial projections, milestones, risks. For market research alone, use the market-analysis skill instead.
---

# Business Plan — Conductor

Turn a product into a plan a founder can execute and an investor can't wave away. You are the
conductor: your context is for grilling the founder, judging sub-agent returns, and writing the
plan. Heavy research never runs in your own turn — the market-analysis skill is your research
engine, and its fleet does the digging.

The core principle: **a plan is a decision document, not a brochure.** Every market fact in it
is imported from the market analysis by source reference — if a number in the plan can't be
traced to a line in `market-analysis.md` or to a founder answer, the plan is drifting from
evidence into narrative. Flag it, don't let it stand.

## Output contract — deterministic home

Same folder the market-analysis skill uses (same slug rule — repo directory name or settled
product name, kebab-case; re-runs update in place, never a new folder):

```
~/Documents/business/<product-slug>/
  founder-brief.md            # the grill's numbered [F#] facts (Phase 1) — the plan cites these
  one-pager.md                # the door-opener — always produced first, every track
  business-plan.md            # the main artifact — SHAPE DEPENDS ON TRACK (see below)
  financial-model.md          # assumptions table + scenarios, referenced by the plan
  red-team.md                 # the panel's objections + dispositions (Phase 4)
  deliverables/
    business-plan.html        # rendered deliverables (Phase 5)
    business-plan.pdf
    one-pager.html
    one-pager.pdf
  ...market-analysis files (owned by that skill)
```

Templates AND the track branch (venture memo vs. bootstrap operating plan vs. lender classic —
investors don't read 40-page plans; the classic genre survives only for banks/grants):
`references/plan-template.md`. Load it before drafting.

The market-analysis skill's root is `~/.claude/skills/market-analysis` (fallback:
`~/.agents/skills/market-analysis`) — every cross-skill reference below resolves against it.
`~` is shorthand in this document only: expand to the absolute home path in every path you
pass to a tool or an agent brief.

## Phase 0 — Ground

Resolve the slug per market-analysis's slug rule (repo → analyzed directory name, settled
name wins; for an idea with no name, do NOT write any file — settling the name is the first
grill turn). Look inside `~/Documents/business/<slug>/` (and `ls` the parent for an existing
folder naming the same product). A market analysis already there is prior work: **reuse** if
the dossier still matches reality and `_Analyzed:` is under ~90 days old in a fast-moving
category (AI tooling, consumer apps) or ~12 months otherwise; between those, run the
competitor-analysis Monitoring plan re-check (pricing pages, changelogs) as a partial refresh
and note it in Coverage; past them, or if the product's stage/boundary moved, plan a full
refresh.

Then build the dossier: run the **market-analysis skill's Phase 0 only** — a cheap
dossier-building pass (explore agents on a repo; drafting from a doc/idea), no research fleet.
The grill needs the dossier's value hypotheses to exist; nothing else of market-analysis runs
yet.

**Sweep for founder-authored writing before the grill — it is the cheapest context you will
ever get.** Blog, changelog, README, docs, talks, launch threads, issue bodies. Founders
routinely explain their own reasoning in public and then never mention it, because to them it
isn't news. Skipping this sweep means grilling for things already written down and, worse,
missing the founder's own framing of why the product is shaped as it is. Anything found lands
as `[F#]` with its URL.

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
already answers. Full question bank with per-question defaults: `references/grill.md` — load it
now. The areas that gate everything downstream:

- **Pointers & background** — opens the grill: anything to point the research at (docs, prior
  research, competitor lists, community threads) and any background the source can't show.
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
beachhead, motion — as decision briefs per `references/decisions.md`, and everyone else gets the
bank above in the same number of turns. The tell and the six forks: `references/grill.md`.

Call out bad answers when you see them — a venture-scale ambition with 4 hours/week, a price
instinct 10× under the category's floor, "no competitors". Push with reasoning; a wrong premise
you let through makes the whole plan fiction.

**If the founder declines the grill** ("no time — just build it, assume whatever you need"):
don't insist, and don't default silently. Send ONE non-blocking message carrying only the two
decisions that select the document itself — ambition and audience — each as a recommended
default they can flip in a word, then proceed without waiting. Every other question's default
goes into `founder-brief.md` tagged `assumed — no grill` (default · why · what changes if
wrong), the declination itself is recorded as an `[F#]` fact, and the plan opens with the
assumption list so reading the plan becomes the grill. The red team still runs — with no
grill it's the only adversary the plan ever met.

Close the grill by writing `founder-brief.md` — the numbered fact table (template in
`references/plan-template.md`) every `[F#]` citation in the plan resolves through, exactly as
`[S#]` resolves through sources.md. It's written BEFORE any dispatch, and Phase 2's brief
carries it verbatim so F-numbers stay stable everywhere.

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
ambition: <venture | bootstrap | lifestyle | lender>  — bootstrap/lifestyle: skip the top-down
  sizing agent, bottom-up only (the venture-scale sniff test still gets stated); else full rigor.
categoryBoundary: <the boundary from the Phase 0 dossier, or "undecided — you call it">
mustProfile: <competitors the founder named — always profiled, whatever their kind>
founder brief (verbatim):
<founder-brief.md content>
```

Reuse from Phase 0 applies: a fresh, matching analysis skips this phase entirely — verify it
against the checklist below and move on.

**Verify the return — architect-style, against the contract, before you build on it:**

- All contract files exist in the folder (dossier, market-analysis, competitor-analysis,
  sources, research/) and follow the templates' headings.
- Every headline number is a range with an H/M/L tag and resolves through `sources.md`.
- The whitespace recommendation is specific and falsifiable — not a restatement of the product.
- The competitor set includes the rivals the founder named in Phase 1 (or says why not).
- `Coverage` names what was skipped and why; `Risks to this analysis` is non-empty (a market
  analysis with nothing soft in it wasn't done honestly).
- `Assumptions` is present and non-empty for a dispatched run — each entry states the default,
  why, and what changes if wrong. An empty Assumptions section from a headless run means gaps
  were guessed silently.
- `Value hypothesis verdicts` covers every VH in the dossier (confirmed / weakened / refuted /
  untested) — Phase 3's Solution section may only build on confirmed ones.

A failed check goes BACK with a sharper brief ("the sizing is single-sourced top-down — re-run
bottom-up per the playbook"), not patched by you. Judge and direct; don't do the fleet's job.

## Phase 3 — Draft the plan

Write `one-pager.md` FIRST (it forces the clarity everything else inherits), then
`business-plan.md` in the track's shape, then `financial-model.md` — all per
`references/plan-template.md`. Drafting is YOUR work — it needs the founder's answers, the analysis, and judgment in one head. The
load-bearing rules:

- **The thesis traces.** The plan's core bet restates the analysis's whitespace recommendation,
  sharpened by the founder's unfair advantages — traceably, not vibes-first.
- **Import, never re-derive.** Market facts arrive with their confidence tags intact — a Low
  bottom-up estimate does not become a headline claim. Cite `[S#]` from `sources.md` and
  `[F#]` from the founder brief.
- **The financial model is assumption-first.** Every input is a named row in the assumptions
  table (source: analysis, founder, or explicit guess), the revenue build is bottom-up, and
  base/downside/upside scenarios move the assumptions — not the conclusions. Fake precision is
  the failure mode; visible formulas are the fix.
- **Open strategic forks get simulated, not asserted.** When the capital path (bootstrap vs
  raise) or entry sequencing (beachhead vs broad) is genuinely open after the grill, build
  the paths as parallel copies of one model and compare founder dollars across exit scenarios,
  with pre-committed switch triggers — load `references/strategy-sim.md` and follow it. The
  reinvestment engine there also shapes every bootstrap-track model (default-alive gate,
  owner-pay floor, loop-not-funnel growth), fork or no fork.
- **Sequencing IS projection — the roadmap and the model are one artifact.** Every roadmap item
  names the assumption it moves, items unlock each other (levers multiply, they don't add),
  sequence value ≠ sum of item values, and **resource-independence gets checked before ranking
  by value** — items gated on different constrained resources don't compete and can run
  concurrently, which a naive value-ranking will serialise and lose. Load
  `references/roadmap-sequencing.md` and follow it whenever the plan has a roadmap.
- **The plan ships a growth engine, not a marketing wishlist.** The GTM section's execution
  half is the mostly-automated weekly machine from `references/growth-engine.md` — the three
  per-product skills (content, visual assets, docs-sync), the automation rules that survive
  Google and slop backlash, and the weekly loop sized to the founder's grilled hours, with
  engine build-out as named roadmap items.
- **Track shapes shape — three ways.** Venture gets the investor-facing memo framing;
  bootstrap/lifestyle gets a cash-curve and time-to-default-alive framing; lender gets
  repayment-capacity framing (3–5yr financials, use-of-funds line items, tone shifted from
  bet-defense to ability-to-service-the-loan). Same evidence, different document.
- **Every Low-tagged assumption gets a validation step** in the plan's validation section —
  the cheapest real-world test (interviews, landing page, waitlist, pre-sales) with a kill/
  continue threshold.
- **Reconcile the one-pager last.** After financial-model.md is written, re-open one-pager.md
  and reconcile every number against it — the ask, the SOM range, the price. A one-pager
  number that disagrees with the model it fronts is the commonest credibility kill.

## Phase 4 — Red team

Before the plan is done, it gets attacked. Dispatch a panel — one agent per lens, parallel
(model: `opus`, effort high; these need to be smart). Lens 1 matches the track:

- **Capital skeptic** — venture: *skeptical investor* (market too small, moat copyable,
  why-now weak?) · bootstrap/lifestyle: *default-alive skeptic* (does this reach cash-positive
  before the runway ends?) · lender: *credit officer* (does cash flow service the debt through
  the downside case?).
- **Operator** — kill the execution: does the milestone plan survive contact with the team
  size, runway, and the founder's hours?
- **Target customer** — kill the demand: would the beachhead segment actually switch, at this
  price, from what they use today?

Every panelist brief carries the founder's named fear `[F#]` with the instruction: attack this
hardest, then name the two risks the founder did NOT name.

**Code-verify every objection about the subject's own product BEFORE disposing of it. This is
the single highest-value rule in the skill.** Panelists reason from the plan document, and the
plan document under-describes the product — so a panel will reliably assert the product lacks
things it ships, and those false objections then get "fixed" into the plan as concessions or
roadmap items. Any objection of the form *"it has no X"*, *"it can't do Y"*, or *"users would
have to Z"* gets checked against source (the repo, the product's own docs) before it is
accepted, moved to Risks, or rejected. Milestone fields, issue titles and backlog labels are
**not** evidence of absence.

Two reading errors to watch for specifically, because both produce confident and wrong
objections:

- **Names are not behaviour.** Enum values, type lists, error codes and field names describe
  the *condition that raised a thing* — never its frequency, its severity, or its cost to the
  user. A list of twenty failure states reads like a product that fails constantly; check the
  defaults and the opt-outs before characterising any of it as friction.
- **Constants are not product limits.** A number in the source may be an internal batch size,
  an I/O bound, or a machine-protection default with a user-facing setting elsewhere. Find the
  user-facing knob and its range before quoting a ceiling.

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
If an objection guts the thesis, say so to the founder plainly and revise the bet — that IS
the job.

## Phase 5 — Deliverables

Render `business-plan.md` (+ the financial model) into ONE polished, self-contained
`deliverables/business-plan.html` and a print-quality `deliverables/business-plan.pdf`, and
`one-pager.md` into its own single-page pair (no cover page — rendering.md's single-page
exemption; it fails verification if it spills to page 2), per
`~/.claude/skills/market-analysis/references/rendering.md` (the shared rendering system —
design, paged-media CSS, toolchain ladder, and the mandatory render → Read the PDF back →
check every page → fix loop). A deliverable you didn't read back is not done.

## Walk sign-off

Close with specific callouts, not a summary dump: the thesis in one sentence, the number most
likely to be wrong and its validation step, the red-team objection that survived, the first
three milestones, and where everything landed. Invite pushback on the specific bet.

## Standing rules — they outrank convenience

1. **A claim that the subject "has no X" is unactionable until checked against source.**
   Milestone fields are not evidence.
2. **Names describe conditions, not costs.** Enum values, type lists and field names say what
   raised a thing — never how often, how badly, or at what cost to the user.
3. **Evaluate the bundle, not the columns.** A product whose thesis is integration will always
   score as commodity on a per-capability grid. When the claim is coupling, the capability
   matrix must be supplemented, never trusted alone.
4. **Set the lens before reading the facts:** entity → product truth → interpretation. A corpus
   can be sound in its research layer and wrong in its plan layer purely because the scope was
   set by the wrong entity.
5. **M&A and corporate events are a standing sweep, not a per-session option** — mandatory
   whenever the plan reasons about an exit, a category leader, or a competitor's trajectory. A
   category's ownership can change between two sessions of the same engagement; a plan that
   missed it argues against a company that no longer exists in that form.
6. **Retraction is visible.** Strike through with the reason. Silent deletion lets a dead claim
   return two drafts later with its cause of death erased.

## Quality bars — non-negotiable

- Every market fact traces to `sources.md` or the founder brief; confidence tags survive import.
- The steady-state ceiling is computed and stated, not implied by a 12-month curve.
- The cost of the alternative is priced wherever the price is defended.
- Every roadmap item names the assumption it moves.
- The financial model's assumptions table is complete — no number appears in a projection that
  isn't a named assumption row.
- The plan matches the founder's stated ambition, not a template's default ambition.
- Red team ran, and its surviving objections are IN the plan.
- Rendered deliverables verified page-by-page.

## Common failure modes

| Failure | Fix |
|---|---|
| Plan re-researches the market inline | Dispatch the market-analysis skill; conduct, don't dig |
| Thesis is the product description reworded | Trace it to the whitespace recommendation + unfair advantage |
| Low-confidence number promoted to headline | Tags survive import; validation step instead |
| Hockey-stick from penetration hand-waving | Bottom-up build; scenarios move assumptions |
| Venture template forced on a bootstrapper | Ambition question first; shape follows it |
| Red team skipped ("plan looks solid") | It runs every time — that's when it's most needed |
| Grilling the founder on what research answers | Grill intent/resources/appetite; research the market |
