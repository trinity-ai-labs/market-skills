# Output document templates

The exact structure of every file in `~/Documents/go-to-market/<product-slug>/`. Keep the headings —
downstream consumers (the business-plan skill, the renderer) navigate by them. Prose inside each
section is yours.

## `product-dossier.md`

```markdown
# Product Dossier — <Product Name>
_slug: <the settled slug — the deterministic folder key> · Source: <repo path | doc | idea> · Updated: <date>_

## What it is
<one precise paragraph — no marketing voice>

## Who it's for
<the buyer/user, concretely>

## Jobs it does
<the end-to-end jobs, as the customer would state them>

## Stage & surface
<idea / building / shipped / revenue · desktop / web / CLI / API · stack facts that matter>

## Monetization today
<what's priced or billed now, if anything>

## Value hypotheses
<3–6 falsifiable claims about why anyone pays. Each:>
**VH1 — <claim>**: pain: <what it kills> · who: <segment feeling it most> · vs today: <why
meaningfully better than the current way> · evidence: <what in the source says so> ·
origin: source-evidence | analyst-proposed <be honest — a one-sentence idea grounds nothing> ·
class: differentiated | table-stakes · status: settled | research-testable | founder-only

## Cost structure signals (repo sources — from the infra-cost archaeology pass)
<every paid service the code runs on: service · what it does here · billing shape
(per-user / per-request / per-token / per-GB / flat) · where detected (manifest, IaC,
SDK import). Plus the scaling shape in one line: which cost grows with users, which with
usage, which is flat. Feeds the unit-economics dimension.>

## Instrumentation inventory (repo sources — from the instrumentation archaeology pass)
<one row per store or event type, never per call site: instrument · what it records and at
what grain (per account / per action / per day) · the quantity it could settle, named, and
which claim rests on a guess about it today · read? — the figure and the date pulled, or
`unread` with what is blocking it · what reading it costs (one query / an export the founder
runs / a migration, because the field is not there yet). Every `unread` row is ALSO an Open
questions entry naming the quantity it would settle — that hop is what gets access asked for
in the grill instead of the quantity being estimated for the rest of the run. A row that
names a store and stops settles nothing while reading as diligence.>

## Category boundary
**In:** <the category this competes in>
**Out:** <adjacent categories explicitly excluded, and why>

## Open questions
<gaps the source couldn't answer — feeds the grill or the assumptions log>
```

## `market-analysis.md`

```markdown
# Market Analysis — <Product Name>
_Analyzed: <date> · Confidence key: H = disclosed/primary, M = derived, L = flagged assumption_

## Executive summary
<category definition in one paragraph; headline TAM/SAM/SOM range with tags; top 3 findings;
the recommended positioning bet in one sentence>

## Category definition & scope
<in/out boundary, how it differs from adjacent categories, and the competitive-landscape
verdict that confirmed or moved it>

## Market sizing
### Bottom-up (anchor)
<population proxy × ARPU × penetration — as a visible formula, each factor sourced/tagged>
### Top-down (corroboration)
<enclosing-category figures, each with the boundary it assumes>
### Reconciled range
<TAM / SAM / SOM as ranges + tags · growth trajectory and its driver>

## Comparable growth curves
<the indexed series: one line per comparable — its origin event and that event's date, the metric
being tracked, and its dated points re-based to months since that origin. The origin is named per
company because the choice moves every comparison; an unstated origin makes a stacked set read as
an aligned one.>
<the fitted decay across the set: the shape, what it says comparables were doing at named months
(not what they averaged over their history), the months the fit is supported over, and how well it
fits. Any company with too few dated points to fit is listed here in those words — "two points, no
shape" — never folded in as a two-point average.>
<the ARR buckets the set is read in, declared for this reference class, and every rate tagged with
the bucket it was measured in — a company crossing a bucket mid-series tagged per stretch, not per
company. Rates are compared only within a bucket, and this product's own projected rate is checked
against the bucket it will be in at that month, never against the set as a whole: months since
origin controls for calendar time, nothing else here controls for scale, and a band pooled across
buckets is two phenomena on one axis.>
<companies excluded from the indexed overlay, each with the reason (origin undatable) and its
calendar series retained — listed, never silently dropped, or the reference class reads tighter
than the evidence supports.>
<the strategy record, per company and keyed to the stretch of curve it ran during: months <a>–<b>
· what they were doing to grow · the founder's own words, quoted, with source and pull date ·
policy or structural FOR THIS FOUNDER at their grilled hours, channels and capital. Every bend in
that company's indexed series is accounted for here or written down as a stated gap — "inflection
at month <n>, no driver found in the public record" — never left silent. A company's account of
its own growth is a claim, never a fact: it is evidence of what they did, not proof of what caused
the curve, and it is tagged accordingly.>
<the reconciliation against category growth from Market sizing above: trajectories implying the
profiled set outgrows its own category are named and defended with a mechanism, or flagged as too
hot. Reconciled, never averaged.>
<rendered as the indexed multi-series exhibit — months since origin on x, the metric on y, one
line per comparable, this product's own projection overlaid — per rendering.md.>

## Exit comparables & implied multiple (when the target is an exit)
<the comparable set, one entry per disclosed acquisition in the category: the acquired company,
its origin event and that event's date, the month since that origin the sale landed at, its stage
and its growth slope across the months running into the sale, ARR at exit, the ARR bucket that
figure sits in, and the multiple that ARR and the deal imply. Indexed to slope at the moment of
sale, the same basis every other series
here uses, because slope is what the multiple is set by — a sale recorded against a level with no
slope beside it cannot be read at the month a roadmap puts its own sale.>
<the consideration split, per comparable: the headline figure and the multiple it implies, then
what portion was actually received at close and the multiple THAT implies — earnout against
post-close targets, escrow/holdback, acquirer stock carried at the acquirer's own valuation, and
retention packages that are compensation for the team rather than price for the company — with the
source for the split, which is the acquirer's filings and later disclosures, never the
announcement. The band is drawn on consideration received at close, with the cash-only figure
recorded beside it. A comparable whose split cannot be found is recorded as "headline-only,
uncorroborated" and carries that label everywhere it appears, never pooled with decomposed ones:
announcements publish the headline and disclose the components that reduce it later and elsewhere,
so a set read off announcements skews high as a class rather than in one bad entry, and naming
survivorship does not catch that because these deals closed.>
<the acquirer per comparable, named, with its stated strategic rationale in its own words, quoted
with source and pull date. A rationale paraphrased into a motive is the analyst's claim wearing
the acquirer's authority.>
<the implied-multiple endpoints, each labelled with its comparable, that comparable's ARR at exit
and bucket, its stage and its slope at sale — never averaged into a single multiple, which
describes no deal
that happened. Fewer comparables than a band needs is stated in those words — "two comparables, no
band" — never a band run through two points.>
<survivorship, stated outright: the announced acquisitions are the ones that closed, nobody
publishes the multiple they were offered and refused, and a sale that collapsed in diligence
leaves no figure to index. The set is what this category paid the sellers who said yes.>
<rendered onto the indexed exhibit above — each sale marked on its own comparable's line at the
month it happened, labelled with the multiple received at close and marked as decomposed or
headline-only — per rendering.md, never as a chart of its own.>

## Customers & segments
<segments with sizes; JTBD chain and where current tools break it; beachhead recommendation>

## Pricing & willingness to pay
<competitor price table; WTP evidence; recommended anchor + packaging hypothesis (L)>

## Trends, timing & why-now
<the shifts with evidence; platform risk; what must stay true for 18 months>

## Channels & GTM landscape
<how this category is bought; channels open to a new entrant, ranked>

## Unit economics & COGS at scale (when the dimension ran)
<cost-per-user / cost-per-action formulas from the detected stack; the cost-vs-revenue table
at usage tiers; gross-margin trajectory; free-tier cliffs; break-even tier; the "does the
margin survive success?" verdict — every rate cited [S#] with its pull date>

## Value hypothesis verdicts
<one row per VH from the dossier: confirmed / weakened / refuted / untested — with the
dimension evidence that decided it. The whitespace bet below builds ONLY on confirmed ones.>

## Whitespace & positioning recommendation
<the specific, falsifiable bet: own X for segment Y because incumbents structurally can't Z.
Label the opportunity honestly: a **wedge** (one buyer's sharp pain inside a served market —
proof a model works, but incumbents nearby) or true **whitespace** (a need nobody serves —
no entrenched pricing to fight, but no proof either). Why the differentiator survives the
"copy it in 18 months" test. THE load-bearing section.>

## Risks to this analysis
<everything soft: Low-tagged figures, disputed claims from verification, assumptions that
would change the conclusion, and the cheapest real-world validation for each>

## Assumptions
<ALWAYS present. Dispatched mode: every gap you would have asked about. Interactive mode: the
defaults you took without grilling (geography, etc.) — or "None — all gaps closed in the
grill." Each entry: assumption · default chosen · why · what changes if wrong>

## Coverage
<dimensions run, dimensions skipped and why, verification passes performed>
```

## `competitor-analysis.md`

```markdown
# Competitor Analysis — <Product Name>
_Analyzed: <date>_

## Positioning map
<2 axes that actually split this market; where everyone sits, including this product>

## Capability matrix
<rows = jobs from the dossier, columns = competitors, cells = ✓ / partial / —>

## Profiles
### <Competitor> (direct | indirect | adjacent)
<what it does · pricing · disclosed traction points — dated, every citable point found (two is
the bare minimum below which no rate can be derived, never the target quantity), each with its
source (or "no disclosed traction, checked <date>" if none — absence recorded, never omitted) ·
funding · their positioning claim · most likely next move · **wedge line: what they don't cover
and why** · **what they do better, and what adopting it would cost**: the thing itself as an
observable, judged against the dossier's jobs (a step their onboarding removes that this product
still requires, a default that prevents a class of ticket), with its source and pull date · what
adopting it would move · the moves it takes · the resource it spends · policy or structural for THIS
founder — or "nothing to adopt found, checked <date>", absence recorded, never omitted>
<...one block per competitor...>

## Observed growth band
<the %/mo range derived from each competitor's earliest-to-latest dated point, slowest to
fastest across the profiled set. Each endpoint labelled with its competitor, the span it was
measured over (first and last date used — spans aren't comparable across different intervals),
and its stage (launch-year / growth / mature) — never averaged into a single number, which would
describe no company in the set. Then the per-competitor rate that produced each endpoint, each
carrying its own span, one line per competitor, including any recorded as having no disclosed
traction (excluded from the band, not silently dropped). A scalar reference range, not a growth
curve — a level check for a projection, never a substitute for modelling its trajectory.>

## Adoption candidates
<what the profiled set already does better than this product, rolled up from the profiles above and
ranked by what each would cost to adopt, policy ones first: the change · what adopting it would move
· the moves it takes · the resource · the competitor and the evidence it came from. Any profile that
carried no adopt section is named here as missing it — a short list and a category with little worth
copying read identically, and the second is the one a founder acts on. The inverse of the wedge lines
above: same jobs, read for where THIS product is the one that is behind.>

## Threat ranking
<who hurts this product most: Impact × Probability × Confidence per threat, with the scenario.
Thin-evidence threats are "watch", not "act".>

## Monitoring plan
<a table, one row per axis, and `vault-lint.sh --monitoring` fails an axis that leaves any
column empty:

| Axis | Instrument | Cadence | Decision it would change |
|---|---|---|---|
| <the direction being watched, as a question with a direction in it> | <what is read to answer it, specifically enough that somebody else could read it> | <how often> | <the decision that flips if the answer changes> |

**Axes, not pages.** The wording this replaces asked which pricing pages, changelogs and job
boards to re-check and on what cadence — which is *freshness*, and freshness is the question
every profile's research date and every claim note's `stale_after` already ask: is this still
true. Neither asks *which way is this moving*, and a direction is the only thing that separates
a closing window from an open one. A competitor profile researched one day before it was used
missed a strategic reversal by that vendor six weeks earlier — the single fact that most changed
what the competitor meant — because a snapshot cannot see a direction and nothing asked for one.

Each column earns its place by what goes wrong without it. An axis with no **instrument** is a
thing somebody intends to notice, which is not a mechanism. One with no **cadence** is a re-check
with no date, which is the same as no re-check. One with no **decision** behind it is a signal
nobody acts on, and collecting it costs the same as collecting one that matters — so the last
column is what keeps this from growing a watchlist instead of a trigger.

A cell carrying no letter or digit — an em dash, a run of hyphens — reads as empty to the lint,
because that is the cheapest way past this rule.>
```

## `sources.md`

```markdown
# Source Log — <Product Name>
_Every externally-sourced figure or claim in the reports. Re-verify before reuse; sources rot._

| # | Claim / figure | Used in | Source URL | Pulled | Tag | Note |
|---|---|---|---|---|---|---|
```

**Written exclusively by the conductor at synthesis** — `[S#]` numbers are assigned at that
merge, from the Sources tables inside each `research/*.md`. Research agents NEVER write
sources.md (thirty parallel appenders can't number anything); every brief says so. The reports
cite `[S12]` so every figure traces in one hop.

Per-dimension `research/<dimension>.md` files follow the skeleton in `dimensions.md`, not this
file.

## `business-plan.md`

Owned by the business-plan skill — template in that skill's `references/plan-template.md`.
