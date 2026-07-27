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
- **Retraction is visible, never silent.** When a claim is withdrawn or corrected, strike it
  through and give the reason inline. Silent deletion is how a retracted claim comes back two
  drafts later, having lost the record of why it died.
- **Jargon check before the founder reads it.** Idiom that is invisible to a native speaker of
  one business dialect is opaque to everyone else — "in anger", "logo count", "land and
  expand", "above the fold". Founder-facing and international-audience docs get every one
  translated to the plain fact it stood for.
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

**The file is appended to, never rewritten**, and it keeps growing after Phase 1 closes —
founder input arriving during drafting or the red team lands here as the next `[F#]`, with the
date and the phase it arrived in in its `Note` column. The plan cites `[F#]` by number, so a
renumber silently repoints every citation already written; and the header's single `_Grilled:_`
date speaks for the interview, which is why a late row carries its own. The recording procedure
is [grill.md](grill.md#a-fact-arriving-after-the-grill-is-recorded-exactly-as-one-said-during-it).

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

## Target & verdict
<The settled target and its date [F#], and the verdict computed against it — the driver that
binds, and by how much — per
[target.md](target.md#the-verdict-names-which-driver-binds-and-by-how-much). Where the target
was renegotiated: the original target, why it did not clear, and what changed to reach the
settled one — as a `supersedes` / `status: superseded` pair, never `retracted`, per
[target.md](target.md#the-founder-chooses-and-the-superseded-target-keeps-its-reason) (the
two-edit mechanics are [vault.md](vault.md#every-note-carries-these-six-fields)'s).

EVERY DRIVER VALUE SAYS WHERE IT CAME FROM, AND A REFERENCE-CLASS VALUE IS LABELLED AS ONE —
measured on the subject's own instrument, read off a sourced category benchmark, or taken from the
indexed reference class in research/growth-curves.md at the month the target counts. A value the
indexed set SOURCED carries the survivorship qualifier with it, in the same words each time; a
policy driver never carries that label, because the set is only ever allowed to CHECK it, per
[target.md](target.md#a-structural-driver-may-be-sourced-from-the-reference-class-a-policy-driver-may-only-be-checked-by-it).
Rendered identically, a value extrapolated from comparables and a value measured on this product
are indistinguishable, and the founder acts on both equally — while only one of them is about
their company.

WHERE EITHER AXIS WAS STATED AS A RANGE, THIS SECTION CARRIES THE CORNER VERDICTS — plural, as a
table — not one verdict: which corners clear and which do not, with the binding driver and that
driver's kind named per corner, per
[target.md](target.md#a-stated-range-on-either-axis-is-a-rectangle-solved-at-its-corners).
Rendering "the verdict" as a single value destroys the finding exactly where it is worth most: a
rectangle where three corners clear and one does not reads at its centre as a clean yes, and the
corner that fails is usually the one the founder was aiming at. Invented shape:

| Corner | Verdict | Binding driver | Kind |
|---|---|---|---|
| low value · late date | clears | — (price and conversion both clear) | — |
| low value · early date | clears at the band's lower end | reach | policy |
| high value · late date | undetermined — flips across the multiple's band | multiple | — |
| high value · early date | does not clear | growth slope at the sale date | policy |

KEEP THE FOUNDER'S STATED RANGE AND THE EVIDENCE'S RANGE VISIBLY APART — two labelled rows, never
one interval. Both arrive as the same shape, an interval with two ends, and merged the founder
reads the whole width as their own ambition being narrowed when half of it is the evidence
admitting what it does not know. The corner structure goes with it, so nobody can then tell which
end of the ambition the analysis actually reached. Label them in those words — "stated (intent)"
and "evidenced (uncertainty)" — because the two are settled differently: one is the founder's to
change and the other is research's to narrow.

FOR AN EXIT TARGET the section additionally carries the MULTIPLE BAND, both ends with the four
inputs each end traces to, and the band's WINDOW SENSITIVITY: the `stale_after` on the multiple's
claim, written here as a date rather than left inside the note. That date lands inside the plan's
own horizon by construction, and a plan that does not surface it reports the cheapest corner — low
value at the late date — as the safest one, which is the reverse of what is true. The late corner
is cheaper on ARR, because the reference-class decay has more months to compound, and MORE exposed
on the multiple, because the window under the band closes on a schedule nothing in the plan
touches. A founder who widened the date to make the target easier bought ARR headroom with window
risk, and this is the only place the trade is visible.

Placed directly after the Thesis, on every track, so no number below is read before the reader
knows what it was tested against. Omit the section entirely — no placeholder, no "N/A" — when
the grill returned no target ([grill.md](grill.md#0-target-opens-the-grill) has the rule).

THE INDEXED GROWTH-CURVE EXHIBIT LANDS HERE, directly under the verdict: the comparable series
from research/growth-curves.md plotted on months since each company's stated origin, with this
plan's own projection overlaid as a dashed path, authored as inline SVG per rendering.md. It
belongs in this section and not in Market or Financial summary for two reasons. It answers this
section's own question — the verdict names the driver that binds, and the exhibit shows whether
the trajectory that verdict rests on is a shape any comparable has ever had, which is the level
check and the shape check standing side by side where the reader is already asking "can this
reach X by Y". And Target & verdict is the section that survives every track: Market, Financial
summary and The ask are SWAPPED OUT on the bootstrap, lifestyle and lender tracks, so an exhibit
parked in one of those disappears from exactly the tracks whose target is a fixed income figure
read against a cash curve. Caption it with the companies excluded from the overlay and the months
the fit is supported over — an exhibit whose supported range is unstated invites reading the
curve past where the evidence ends, which is the same error the fitted decay exists to prevent.>

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
6–9 months to compounding traction — never promise a 90-day breakout.

Then corroborate the selected motion against research/growth-curves.md's strategy record, AFTER
the three gates and never instead of them. A channel a comparable demonstrably ran across the
months this plan is at is better evidence than a category-level claim that the channel works,
because it is dated to a stage rather than asserted about a market — and the record is keyed to
the stretch of curve it ran during, so a comparable's month-6 play is not read as its month-40
one. Only strategies that record filed as POLICY for this founder are eligible: adoptable at
their grilled hours, channels and capital. A STRUCTURAL one goes to Key risks below, not here.

The record proves what those companies DID, never what CAUSED their curve. It is a claim, not a
fact, and nobody publishes the channel that did nothing — so the accounts that exist are the ones
that worked, and reading them as causes buys a survivorship artifact at the price of the plan's
primary motion. Cite it as corroboration for a choice the gates already made, with its confidence
tag intact; a motion selected BECAUSE a comparable ran it has confused evidence of action with
proof of mechanism.>

## Growth engine
<the automated execution machine, per growth-engine.md: the three per-product skills to build
(content w/ voice.md + contracts, visual-asset capture, docs-sync), the weekly loop sized to
the founder's hours [F#], the no-full-automation zones, and the engine build-out as dated
roadmap items. Entry sequencing when beachhead-first: the scored beachhead + pre-committed
expansion pins with unlock conditions (strategy-sim.md §2).>

## Milestones & roadmap
<Dated checkpoints against the solve-backwards trajectory, not milestones sequenced by feel —
a checkpoint falls in month N because the trajectory says a named driver has to reach a named
value by then (the failure this prevents is strategy-sim.md §5's). Alongside: validation gates
from the plan's validation section, the growth-engine build-out items (which automation skill
lands in which month), and the funding/path gate each milestone feeds. This is the section the
operator red-team lens attacks.>

## Financial summary
<the 5 numbers from financial-model.md: burn, runway, base-case revenue at horizon,
CAC payback + LTV:CAC (always paired), the milestone this capital buys>

## Team
<[F#], unfair advantages made concrete>

## Key risks & mitigations
<2–4 real ones, stated plainly (surviving red-team objections land HERE), each with a
concrete mitigation or an honest open question. Naming your own risks is a credibility
signal; defensive spin is not.

The STRUCTURAL half of research/growth-curves.md's strategy record is routed here: every
comparable growth strategy that record filed as gated on headcount, capital, an existing
audience or an advantage this founder does not have. What the comparables had and this founder
does not is a risk the plan pre-states rather than one a reader discovers by asking how those
curves were actually grown — and it is the honest counterweight to the exhibit in Target &
verdict, which shows the shapes without saying what they cost. Same discipline as the policy half
above: the record is evidence of what those companies HAD, never proof it is what produced their
curves, so state the gap and its mitigation without conceding the causal claim.>

## Validation plan
<every Low-tagged assumption → cheapest real-world test → kill/continue threshold → date>

## The ask
<amount, runway it buys, the specific milestone it reaches>
```

**Where the settled target is an exit, the venture memo keeps its sections and changes their
question.** The bet it defends returns at the sale rather than at the next round, and three
sections change subject:

- **The ask** names the milestone the capital buys in the exit identity's terms — the growth slope
  it holds *through* the sale month, or the roadmap items that make the product visibly the patch
  for a named acquirer — not a revenue level. ARR is the term an exit verdict is least sensitive
  to, so an ask sized against it answers a question the target did not pose, and it reads as
  complete because the number in it is real.
- **Competition & moat** asks its "what stops <biggest threat> from shipping this next quarter"
  paragraph of the BUYER instead of the rival. Same sentence, different subject, different stake:
  a rival shipping it costs share, an acquirer shipping it collapses the price to an acquihire —
  and that is the scarcity input of the multiple, read from the buyer's side.
- **Financial summary** extends its horizon to the sale date. A 24–36 month memo horizon against a
  four-year exit stops before the target does, and the plan then defends a trajectory nobody
  carried to the month that prices it.

The part that gets softened is the name. "Strategic acquirers in this category" states no driver
value at all — [target.md](target.md) files an unnamed acquirer as a blank the identity accepts
without complaint, so the memo reads as having answered the question that decides the verdict
while leaving it open.

**Bootstrap track** replaces Market/Financial summary/The ask with: a lean canvas block,
a 6–12 month operating plan (monthly cash curve → default-alive date, the ONE channel and its
90-day checkpoints, time-to-first-dollar — the channel's checkpoints dated against the same
solve-backwards trajectory as Milestones & roadmap above), and "what I'm NOT doing" (explicit
non-goals). Skip TAM/SAM/SOM rigor unless a loan later needs it. **Target & verdict is not one
of the swapped sections — it
stays, in the same place, on every track.** For bootstrap/lifestyle the target is usually the
fixed income figure itself, so the verdict reads directly against the cash curve just below it.
**Lender track** expands financials to 3–5 years and adds use-of-funds down to line items; tone
shifts from bet-defense to repayment-capacity — Target & verdict stays too, read against the
debt service the financials must cover.

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
NEVER "X% of TAM" as a model input.

The shape of the curve is an assumption in BOTH directions, and both directions name a driver.
Every inflection point names its operational driver (hire ramp, channel launch, seasonality) —
smooth exponential curves read as reverse-engineered from a funding target. Every flat or
near-flat stretch names one too: zero growth is not the absence of an assumption, it is the
assertion that next month's reach, conversion and mix are identical to this month's. That
needs a driver exactly as an inflection does — a hard channel cap, a fixed-capacity delivery
model, a deliberate no-growth policy — and with none named the line is UNMODELLED, not
conservative.

The two directions are not equally dangerous, and the flat one is worse: an over-projection
gets challenged, an under-projection gets believed. A hockey stick draws a red team; a flat
line reads as conservative, therefore credible, therefore unexamined — so it is the flat line
that reaches the founder's decisions with nothing behind it.

Then compute the projection's OWN implied monthly growth rate and place it against the
`## Observed growth band` section of competitor-analysis.md. Outside the band in EITHER
direction — faster than the fastest comparable, or slower than the slowest — is stated and
defended by a named difference (a channel none of them run, a delivery model that caps
throughput, a segment that buys on a different cycle), or the projection is re-cut. The bottom
edge is where this bites: take a mature comparable's rate, decay it across the horizon, and it
still lands far above zero, which is what makes a no-growth model indefensible rather than
careful. Worked example: a plan projects 40 customers in month 1 and 44 in month 24 — 0.4%/mo
— against a band running 2–9%/mo whose slow end is an eight-year-old company. That projection
is not the cautious floor of the band, it is a fifth of it. Asked why, the founder says "there
are only so many hours in my week" — which is a real driver, a fixed-capacity delivery model,
and belongs in the model as a stated cap rather than as a curve that quietly flatlines.

That is the LEVEL check. Run the SHAPE check after it: place the projection's implied
trajectory against the indexed series in research/growth-curves.md at MATCHING MONTHS SINCE
ORIGIN — month 6 against month 6, month 18 against month 18 — not one averaged rate against
the band's two endpoints. The level check alone clears a projection that sits mid-band on its
average and still asserts a shape NO COMPARABLE IN THE SET HAS EVER HAD: flat where every
comparable decayed, or one rate held across the whole horizon where every comparable's rate
fell after its first year. The averaging is what hides it — a single rate stated for the whole
horizon understates the early months and overstates the late ones AT THE SAME TIME, and lands
inside the band on both. A shape the indexed set does not contain is defended by a named
difference exactly as a level excursion is, or the curve is re-cut against the fitted decay.
Where growth-curves.md reports too few points to fit a shape, say the shape check could not
run — never let it quietly collapse back into the level check while the model reads as though
both were made.>

## Scenarios — one engine, three assumption sets
<Base / Downside / Upside as DELTAS on the assumptions table (downside = a real stress:
CAC +30%, growth −20% — not "same shape, smaller"). Each scenario names its TRIGGER:
the metric + threshold that tells the founder "we are now in this case".>

## Sensitivity
<one table: the 2–3 highest-leverage assumptions flexed ±20–30% → effect on runway and
revenue. This is the fastest trust-builder in the whole model.>

## Steady state — model to the ceiling, not to the horizon (MANDATORY, every track)
<Twelve monthly rows can hide a structural ceiling completely. One line of algebra exposes it.
Write the steady-state identity for the business and solve it:

  seats = trials × conversion × seats-per-account ÷ churn          (subscription shape)

At equilibrium, new customers = churned customers, so the ceiling is set by the RATIO, not by
the growth rate — and no amount of time in the projection changes it. State the number, state
which assumption it is most sensitive to, and say plainly whether the ceiling is above or
below the founder's stated goal. A plan whose 12-month curve is rising toward a ceiling it
never names is the commonest way a model misleads its own author.

Then check whether any assumption is COHORT-DEPENDENT rather than flat. Churn is the divisor
— if it varies by cohort (multi-seat accounts churning less than solo, annual less than
monthly), the ceiling changes SHAPE, not just height, and a flat churn row silently averages
that away. Name any assumption you suspect is cohort-dependent and mark it for post-launch
measurement.

Then label every input in the identity structural or policy — those two words, no third:

  structural — set by the market, not by the founder: the category's conversion benchmark, the
  price band willingness-to-pay supports, the churn BAND the category supports.
  policy — set by a founder decision: how many channels run, hours a week into the business,
  the price point chosen inside that band, the product's POSITION inside the churn band,
  headcount, how much of the growth engine gets built.

CHURN IS THE INPUT MOST OFTEN MISLABELLED, and it is the one that costs the most. A consumer
utility does not retain like an ERP — that band is structural and it stands. Where the product
sits inside it is not: the depth of what the product does, whether the valuable part is
reachable unassisted, and the friction between the two are what place it, and all three are
built. Label the whole rate structural and the divisor of this identity becomes a category
floor, which sets the ceiling. State the band, state the position, and state what in the built
product puts it there. A claim that the position improves carries a sourced base and labels its
size measured, reference-class or assumed — an assumed one is solved at both ends of its range
before it enters. Unguarded, churn is the one input a plan can move until the answer comes out
right, because halving it roughly doubles the equilibrium.

A ceiling whose BINDING input is policy is the ceiling of THIS CONFIGURATION, not of the
business, and is stated that way — with the ceiling under at least one changed policy value
shown beside it, so a choice reads as a choice. Worked example: the identity solves to 180
seats, the binding input is trial flow, and trial flow is one channel worked six hours a week.
The line reads "180 seats at one channel and six hours a week; 360 at two channels and the
same hours" — the same arithmetic, relabelled, and it moves the founder from "the business
tops out below my goal" to "this configuration does".

The failure this prevents: the model lets a decision become a law of nature and then reports
the consequence as physics, and a number reported as physics is one nobody argues with. The
cohort check above asks whether an input is uniform; this one asks whether it is chosen. Both
run, and neither answers the other's question.>

## Cost of the alternative (MANDATORY wherever price is defended)
<Affordability is not a pricing argument. "X% of what they already spend" says nothing about
whether they'd rather spend zero. Price the SUBSTITUTE the buyer would actually assemble:
tools + integrations + the fraction of a person who owns and maintains the glue.

The maintainer's time is usually the dominant term and is the one plans omit. Use a real
wage source, state the fully-loaded multiplier, and show the per-seat figure at 1 / 5 / 20
seats — the shape almost always changes across that range, and a substitute that is FREE at
n=1 is a genuine finding that constrains where the argument may be used, not something to
bury.

Then check the inversion: is the buyer most able to self-build also the most expensive to
have doing it? If so, say it — it is usually the strongest sentence available. If the evidence
is arithmetic rather than observed behaviour, tag it as such and do not call it revealed
preference.

This section and Value delivered below it are one argument with two halves and BOTH fire
wherever a price is defended. This one prices what the buyer avoids; that one prices what the
buyer produces. Written alone, this one caps the price at the substitute's cost — and it does
so invisibly, because a well-sourced substitute figure reads as rigour while the output figure
nobody computed is simply absent from the page.>

## Value delivered (MANDATORY wherever price is defended)
<The substitute's cost is a floor under the buyer's alternative, not a ceiling on your price.
Price what the buyer can PRODUCE with the product that they could not before, in the buyer's
own currency: output added, hours returned at a real loaded wage, error or rework avoided,
revenue unlocked. A price defended on cost alone is unmodelled, not conservative.

Every figure here carries a SOURCED BASE and a LABELLED MAGNITUDE — the two are separate and
both are required:
  - the base is the wage, output or volume figure the delta is computed against, tagged [S#]
    or [F#] like any other fact;
  - the magnitude is how much the product moves it, labelled `measured` (instrumented on real
    users), `reference-class` (a comparable disclosed it), or `assumed`.
An `assumed` magnitude is solved at both ends of its plausible range before anything downstream
of it is stated, exactly as a pessimistic input is. The reason this rule needs writing down is
that it fires on an OPTIMISTIC input, which nothing else in the method does: challenging a
generous figure about the founder's own product reads as advocacy, so a base-free value claim
is the easiest number in the plan to write and the hardest to argue with.

STATE THE CHANNEL INTO THE MODEL, or this section is a paragraph that moves no number. Delivered
value reaches the arithmetic through RETENTION: a buyer who gets more out of the product leaves
less often, churn is the divisor of the steady-state identity above, and a lower divisor raises
the equilibrium and with it the price the ceiling will carry. So this section names, in one
line, which churn row it moves and by how much — and that claim takes the same base-and-label
guard as everything else here, because churn moves the answer further than any other input.
Where the delta genuinely is not expressible in the buyer's currency, say that in one line and
say what the argument rests on instead; a fabricated figure written to fill this section is the
exact failure the guard exists to prevent.

Worked example, invented end to end: a product that shortens a weekly reconciliation from four
hours to one. Base — the loaded hourly cost of the person who does it today [S#]. Magnitude —
three hours a week, `measured` on a pilot cohort. Channel — the accounts using it weekly retain
at the top of the category band rather than the middle, because the saved hours recur; the
model's churn row carries that as a cohort split, not as a flat improvement.>

## Strategy comparison (when a capital-path or sequencing fork was open)
<the Path Comparison + Trigger table from strategy-sim.md §6: parallel paths off shared unit
economics, dilution ladder per raising path, founder $ at low/base/high exits, and the
pre-committed switch triggers. Bootstrap paths embed the reinvestment engine (default-alive
gate, four buckets with the owner-pay floor, channel-unlock milestones, Rule-of-40
validator).>

## COGS & margin at scale
<imported from the analysis's unit-economics dimension when it ran (repo sources): the
cost-vs-revenue table at usage tiers, gross margin trajectory, free-tier cliffs, break-even
tier, and the "does the margin survive success?" verdict [S#]. The pricing row of the
assumptions table must be consistent with this — a price that only works at today's COGS
gets a named trigger for revisiting.>

## Unit economics
<LTV:CAC AND CAC payback, always together (a 3:1 ratio on a 3-year payback is a cash trap).
Floors (venture & bootstrap tracks): SaaS ≥3:1 & payback ≤12 mo; prosumer/consumer ≤6 mo
payback, LTV $40–120 at $5–15/mo. A product straddling both: pick by the grilled price point —
single-user pricing under ~$25/mo is judged on the prosumer floor, team pricing on the SaaS
floor; if the model carries both plans, show both floors against their own segments. Show the
cohort retention curve assumption behind LTV, and what places it where it sits — the category
band it lies in, the product's position inside that band, and the delivered value that puts it
there. The ratio is gameable, the curve is not, and a curve stated with no position under it is
a category floor doing a product's job.>

## Runway & milestone
<burn, months of runway, and the specific milestone (not "more revenue") this period buys;
the date the company is default-alive or needs capital — whichever comes first.>

## Use of funds & repayment (lender track only)
<capital by line item, the drawdown schedule, annual debt service, and DSCR (operating cash
flow ÷ debt service) in base AND downside. A downside DSCR under 1.0 is stated, never
smoothed.>
```
