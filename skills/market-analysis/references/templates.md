# Output document templates

The exact structure of every file in `~/Documents/business/<product-slug>/`. Keep the headings —
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

## Customers & segments
<segments with sizes; JTBD chain and where current tools break it; beachhead recommendation>

## Pricing & willingness to pay
<competitor price table; WTP evidence; recommended anchor + packaging hypothesis (L)>

## Trends, timing & why-now
<the shifts with evidence; platform risk; what must stay true for 18 months>

## Channels & GTM landscape
<how this category is bought; channels open to a new entrant, ranked>

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
<what it does · pricing · disclosed traction (cited) · funding · their positioning claim ·
most likely next move · **wedge line: what they don't cover and why**>
<...one block per competitor...>

## Threat ranking
<who hurts this product most: Impact × Probability × Confidence per threat, with the scenario.
Thin-evidence threats are "watch", not "act".>

## Monitoring plan
<the analysis rots — a standing refresh beats a stale report: which competitor pricing pages,
changelogs, and job boards to re-check, on what cadence (monthly is typical), and the signal
each would give. Every profile above carries its research date as signal freshness.>
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
