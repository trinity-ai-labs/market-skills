# Plan artifacts & templates

## Pick the artifact by track — never default to the 40-page classic

Investors don't read classic business plans ("I have never read a business plan or a balance
sheet" — Paul Graham). The founder's ambition + audience (grill Phase 1) selects the shape:

| Track | Main artifact (`business-plan.md`) | Financials horizon |
|---|---|---|
| Venture-scale (raising) | Investment memo — 2–4 pages seed, 5–8 Series A+ | 24–36 mo, to the next fundable milestone |
| Bootstrapped / lifestyle / solo | Lean plan: canvas + 6–12 month operating plan | Months, not years; default-alive curve |
| Bank / SBA / grant | The classic full plan (only live use of the genre) | 3–5 yr + use-of-funds detail |

**The selection rule when the axes conflict**: AUDIENCE selects the document shape (a
bank/grant reader forces the lender track regardless of ambition); AMBITION selects the
financial framing and horizon inside it. Self/cofounder-only reader + venture ambition → memo
shape with no ask section. Lifestyle = the bootstrap track with a fixed income target in place
of a growth curve.

**Always produce `one-pager.md` first, on every track** — the door-opener artifact; writing it
first forces the clarity every longer document inherits. Then the main artifact. The plan is
read in ~20 minutes by a skeptic: density and traceability beat completeness.

**Writing rules (every track):**
- Section headings are action titles — the finding as a sentence, never "Market Overview".
- Banned words (each is a red flag to the people who read hundreds of these): revolutionary,
  disruptive, game-changing, cutting-edge, delve, tapestry, paramount, landscape-as-filler,
  seamless-as-filler. Replace each with the specific fact it was standing in for.
- Conviction claims (why-us, the founder's why-now belief) are marked
  `[founder voice — verify/rewrite]` — evidence is yours to write; conviction is theirs.
- Every fact: `[S#]` (sources.md) or `[F#]` (founder brief). No third kind.

## `founder-brief.md`

```markdown
# Founder Brief — <Product>
_Grilled: <date> · Cited from the plan as [F#]_

| # | Fact | Grill area | Note |
|---|---|---|---|
| F1 | <the answer, as a fact> | ambition | <e.g. "founder override: kept price despite floor evidence"> |
```

## `one-pager.md`

```markdown
# <Product> — <one sentence: what it is, for whom, why it wins>
**Problem** <2–3 sentences, the beachhead segment's words [S#]>
**Solution** <what it does + the differentiated value, not the feature list>
**Why now** <the shift that opens the window [S#]>
**Market** <venture: SOM range, bottom-up formula visible [S#] · bootstrap: the beachhead
segment + a reachable-customer count, no TAM · lender: the serviceable revenue base the loan
underwrites>
**Traction** <realest numbers available; "pre-launch, validating via X" beats padding>
**Model** <price × who pays × motion>
**Team** <why these humans [F#]>
**The ask** <venture: capital + the milestone it buys · bootstrap: the 90-day goal · lender:
amount, term, use of funds in 3–4 line items, and the cash flow that repays it>
```

## `business-plan.md` — venture track (memo shape, Sequoia-skeleton order)

```markdown
# <Product> — Investment Memo
_Date · prepared with <slug> market analysis (see sources.md)_

## Thesis
<Pyramid-first: the bet in one paragraph — whitespace recommendation × unfair advantage.
Then 3–5 supporting bullets, each tagged [S#]/[F#].>

## Problem
<beachhead segment, their words, acuteness evidence [S#]>

## Solution & product
<how it kills the pain; confirmed value hypotheses ONLY — VH verdicts from the analysis>

## Traction & metrics
<early, position 3–4, never buried. Cohorts/growth-rate over cumulative vanity. Pre-launch:
the validation evidence so far and the tests running now.>

## Why now
<from trends research — the mechanism, not the vibe [S#]>

## Market
<TAM/SAM/SOM imported with tags + formulas visible. SOM names the beachhead, the wedge, and
the next 2–3 expansion segments — a SOM without a named beachhead is a red flag.>

## Competition & moat
<positioning map ref; per-threat one line + the wedge. Moat: which power is actually
available (from moats research), what has to be true to earn it, and the honest "what stops
<biggest threat> from shipping this next quarter" paragraph.>

## Business model & pricing
<price anchor [S#], packaging hypothesis, motion (see GTM gates below)>

## Go-to-market
<motion selected via the three gates: ACV band → buyer type (single-user value capture?) →
time-to-value (<30 min unassisted aha?). CAC/ACV sanity ≤ ~30–40%. Hybrid is the normal
steady state. Solo founder: ONE primary channel matched to founder strength, 90-day commit,
6–9 months to compounding traction — never promise a 90-day breakout.>

## Financial summary
<the 5 numbers from financial-model.md: burn, runway, base-case revenue at horizon,
CAC payback + LTV:CAC (always paired), the milestone this capital buys>

## Team
<[F#], unfair advantages made concrete>

## Key risks & mitigations
<2–4 real ones, stated plainly (surviving red-team objections land HERE), each with a
concrete mitigation or an honest open question. Naming your own risks is a credibility
signal; defensive spin is not.>

## Validation plan
<every Low-tagged assumption → cheapest real-world test → kill/continue threshold → date>

## The ask
<amount, runway it buys, the specific milestone it reaches>
```

**Bootstrap track** replaces Market/Financial summary/The ask with: a lean canvas block,
a 6–12 month operating plan (monthly cash curve → default-alive date, the ONE channel and its
90-day checkpoints, time-to-first-dollar), and "what I'm NOT doing" (explicit non-goals).
Skip TAM/SAM/SOM rigor unless a loan later needs it. **Lender track** expands financials to
3–5 years and adds use-of-funds down to line items; tone shifts from bet-defense to
repayment-capacity.

## `financial-model.md`

```markdown
# Financial Model — <Product>
_Horizon by track: venture 24–36 mo · bootstrap/lifestyle 6–12 mo monthly · lender 3–5 yr
annual with monthly year 1_

## Assumptions (every input lives here — nothing buried in a formula)
| # | Assumption | Value | Source | Confidence |
|---|---|---|---|---|
<price, CAC by channel, conversion, churn, ramp times, hires… one row each.
Source = [S#] | [F#] | "guess — validate". At least one negative assumption is mandatory
(churn > 0, hiring delay, sales-cycle friction) — a model with no friction is fiction.>

## Revenue build (bottom-up ONLY)
<channel → spend → CAC → new customers/mo → conversion → price → revenue, as a visible chain.
NEVER "X% of TAM" as a model input. Every inflection point names its operational driver
(hire ramp, channel launch, seasonality) — smooth exponential curves read as reverse-
engineered from a funding target.>

## Scenarios — one engine, three assumption sets
<Base / Downside / Upside as DELTAS on the assumptions table (downside = a real stress:
CAC +30%, growth −20% — not "same shape, smaller"). Each scenario names its TRIGGER:
the metric + threshold that tells the founder "we are now in this case".>

## Sensitivity
<one table: the 2–3 highest-leverage assumptions flexed ±20–30% → effect on runway and
revenue. This is the fastest trust-builder in the whole model.>

## Unit economics
<LTV:CAC AND CAC payback, always together (a 3:1 ratio on a 3-year payback is a cash trap).
Floors (venture & bootstrap tracks): SaaS ≥3:1 & payback ≤12 mo; prosumer/consumer ≤6 mo
payback, LTV $40–120 at $5–15/mo. A product straddling both: pick by the grilled price point —
single-user pricing under ~$25/mo is judged on the prosumer floor, team pricing on the SaaS
floor; if the model carries both plans, show both floors against their own segments. Show the
cohort retention curve assumption behind LTV — the ratio is gameable, the curve is not.>

## Runway & milestone
<burn, months of runway, and the specific milestone (not "more revenue") this period buys;
the date the company is default-alive or needs capital — whichever comes first.>

## Use of funds & repayment (lender track only)
<capital by line item, the drawdown schedule, annual debt service, and DSCR (operating cash
flow ÷ debt service) in base AND downside. A downside DSCR under 1.0 is stated, never
smoothed.>
```
