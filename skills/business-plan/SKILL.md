---
name: business-plan
description: Use when a product — a code repo, a spec/doc, or an idea — needs a business plan or a path to market: monetization, go-to-market, pricing, financial projections, milestones, risks. Grills the founder first; consumes the market-analysis skill as its research engine.
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
  one-pager.md                # the door-opener — always produced first, every track
  business-plan.md            # the main artifact — SHAPE DEPENDS ON TRACK (see below)
  financial-model.md          # assumptions table + scenarios, referenced by the plan
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

## Phase 0 — Ground

Resolve the slug, look inside `~/Documents/business/<slug>/`. A market analysis already there
is prior work: if the product dossier still matches reality and the analysis is recent, plan to
reuse it and say so; if the product moved or the analysis is stale (months old in a fast
category), plan a refresh run. If the source is a repo, skim enough (README, docs) to talk
about the product credibly in the grill — the deep product read belongs to the market-analysis
skill's Phase 0, not to you.

## Phase 1 — Grill the founder

The market analysis can research everything except what's in the founder's head. Before any
dispatch, grill — like a partner who's about to co-sign the plan, not a form. **One question at
a time, each with your recommended answer and why.** Pre-answer what the repo/doc/context
already answers. Full question bank with per-question defaults: `references/grill.md` — load it
now. The areas that gate everything downstream:

- **Ambition** — lifestyle business, bootstrapped-profitable, or venture-scale? Changes every
  downstream recommendation; never assume.
- **Monetization intent** and price instinct.
- **Resources** — team, runway (months, not dollars, if they prefer), hours/week, capital
  available or sought.
- **Unfair advantages** — distribution, audience, domain expertise, tech head start.
- **Constraints & appetite** — geography, compliance lines, will they do sales calls, content,
  paid ads?
- **Timeline** — when does the first dollar need to arrive?

Call out bad answers when you see them — a venture-scale ambition with 4 hours/week, a price
instinct 10× under the category's floor, "no competitors". Push with reasoning; a wrong premise
you let through makes the whole plan fiction. Answers become `founder-brief` facts the plan
cites the same way it cites sources.

## Phase 2 — Run the market analysis

The research engine is the **market-analysis skill**, run brief+skill style: load
`~/.claude/skills/market-analysis/SKILL.md` (fallback: `~/.agents/skills/market-analysis/SKILL.md`)
and execute it in **dispatched mode** — the founder's Phase 1 answers are its brief, so it never
re-asks the user; its research fan-out runs as its own workflow fleet per its
`references/orchestration.md`, so your conductor context stays lean. If the harness supports
agents that can spawn agents, you may instead hand the whole execution to ONE executor agent
(model: `opus`, effort high) with the same brief; either way you verify the return.

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
- **Ambition shapes shape.** Venture-scale gets the investor-facing memo framing; bootstrap
  gets a cash-curve and time-to-default-alive framing. Same evidence, different document.
- **Every Low-tagged assumption gets a validation step** in the plan's validation section —
  the cheapest real-world test (interviews, landing page, waitlist, pre-sales) with a kill/
  continue threshold.

## Phase 4 — Red team

Before the plan is done, it gets attacked. Dispatch a panel — one agent per lens, parallel
(model: `opus`, effort high; these need to be smart):

- **Skeptical investor** — kill the thesis: market too small, moat copyable, why-now weak?
- **Operator** — kill the execution: does the milestone plan survive contact with the team
  size, runway, and the founder's hours?
- **Target customer** — kill the demand: would the beachhead segment actually switch, at this
  price, from what they use today?

Each returns its top 3–5 objections with severity. Fold: fix what's fixable, and put what
isn't in the plan's Risks section with a straight face — a plan that pre-states its best
objections beats one that hides them. If an objection guts the thesis, say so to the founder
plainly and revise the bet — that IS the job.

## Phase 5 — Deliverables

Render `business-plan.md` (+ the financial model) into ONE polished, self-contained
`deliverables/business-plan.html` and a print-quality `deliverables/business-plan.pdf`, and
`one-pager.md` into its own single-page pair, per
`~/.claude/skills/market-analysis/references/rendering.md` (the shared rendering system —
design, paged-media CSS, toolchain ladder, and the mandatory render → Read the PDF back →
check every page → fix loop). A deliverable you didn't read back is not done.

## Walk sign-off

Close with specific callouts, not a summary dump: the thesis in one sentence, the number most
likely to be wrong and its validation step, the red-team objection that survived, the first
three milestones, and where everything landed. Invite pushback on the specific bet.

## Quality bars — non-negotiable

- Every market fact traces to `sources.md` or the founder brief; confidence tags survive import.
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
