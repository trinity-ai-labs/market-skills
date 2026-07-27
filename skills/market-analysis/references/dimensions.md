# Research dimension playbooks

One block per dimension: what the research agent hunts, which sources to prefer, and the exact
return shape. Paste the relevant block into each research agent's brief along with the dossier,
the category boundary, the citation contract, and the output file path.

**Every dimension tests the value hypotheses.** The dossier's VH list rides in every brief, and
each agent reports what its dimension says about them: customers — is the pain real and acute
for the named segment (voice-of-customer evidence)? competitors — is the differentiated value
actually absent elsewhere, or already shipped? pricing — do people demonstrably pay for this
job? trends — is this value getting more or less valuable? A hypothesis no dimension could
confirm is a finding, not a footnote — it flows into `Risks to this analysis`.

Every agent's output file follows the same skeleton:

```markdown
# <Dimension> — <product name>
_Researched: <date> · Confidence key: H = disclosed/primary, M = derived via stated formula, L = flagged assumption_

## Findings
<the substance — structured per the dimension below>

## Sources
| # | Claim/figure used | Source URL | Pulled | Tag |
|---|---|---|---|---|

## Gaps & assumptions
<what couldn't be sourced, what was assumed instead, what would change if wrong>
```

The agent also RETURNS (as its final text) a ≤200-word summary: the 3–5 findings that should
change the analysis, each with its confidence tag. The conductor reads summaries, not files.

---

## Competitive landscape (`research/competitors.md`) — runs FIRST, alone

The wedge-finder, and the category-boundary falsifier. For each competitor the deliverable is
not a feature list — it's an account of where they leave the market open.

Hunt:
- **True alternatives first, competitors second** (Dunford): the list opens with at least one
  non-product alternative — status quo / spreadsheet / manual process / build-internally —
  because that's often what's really being displaced, and it re-frames which attributes matter.
  Then **direct** (same job, same buyer), **indirect** (same job, different mechanism),
  **adjacent** (incumbents one feature-launch away). Name the bucket and why. Classify by the
  BUYER'S decision, not the feature list: a platform offering the identical capability but
  requiring the buyer to migrate their stack onto it is **adjacent for buyers who won't
  migrate and direct for buyers who would** — pick per the dossier's target segment and say
  which rule you applied (this call moves the sizing, so it's never left implicit).
- Per competitor: what it does (one paragraph), pricing model + actual price points, disclosed
  traction points (dated — see below), funding/investors, positioning claim in their own words,
  **most likely next move**, and **what they structurally don't cover and why** — the wedge
  line. Every profile ends with it.
- **Traction points are dated, not a single snapshot, and the ask is every point, not a count**:
  capture every citable dated point found (ARR, users, downloads — only if stated somewhere
  citable), each tagged with its own date and source. Two is the bare minimum below which no
  rate can be derived at all — it is not the target. A floor phrased as a quantity gets read as
  the quantity: a fleet agent that finds six dated points and reports two has followed the rule
  as written, and the discarded points can't be recovered later without re-running the research.
  **Record absence as absence**, e.g. "no disclosed traction, checked <date>" — never a silent
  omission. An omitted competitor and a competitor that disclosed nothing look identical in the
  growth band below, so skipping the line instead of stating the absence lets the band quietly
  narrow to whoever happened to publish.
- **Next-move prediction is signal-counting, not vibes**: job postings lead announcements by
  6–18 months (2+ same-role posts in ~60 days or a leadership hire = signal; one post = noise);
  call a move a prediction only on ≥2 independent signal types (hiring, changelog, pricing
  change, homepage messaging drift, new integrations) — else label it a rumor.
- **Their pricing-page CTA is motion ground truth**: "Get started" + transparent tiers = PLG;
  "Talk to sales" only = sales-led. Record it per competitor — it feeds channels and pricing.
- A capability matrix across the jobs from the dossier — rows = jobs, columns = competitors,
  cells = covered / partial / absent, so whitespace is visible at a glance.
- **Category verdict**: does the competitive set confirm the dossier's category boundary, or
  does it pull the product into a different category? Say so explicitly — the conductor adjusts
  the frame on this verdict before the other dimensions run.
- **Observed growth band**: a named output alongside the category verdict, not folded into it.
  For each competitor, derive a %/mo rate from its earliest and latest dated point (whatever the
  full count collected above) and report the slowest-to-fastest range across the profiled set.
  **Every rate carries the span it was measured over** — the first and last date used, not just
  the number — because rates measured over different intervals aren't comparable: a band whose
  endpoints span different intervals ranks companies by how long ago someone published, not by
  how fast they grow. Label both endpoints — competitor, its dated points and span, and its stage
  (launch-year, growth, mature) — rather than averaging: a mature company's rate and a
  launch-year company's rate are both real and mean different things, and collapsing them into
  one averaged range produces a single number that describes no company in the set. A competitor
  recorded as having disclosed no traction sits out of the band rather than being folded in as a
  zero. **The band is a scalar reference range, not a growth curve**: two dated points (or an
  earliest-to-latest span) discard the shape and decay of a company's growth, so the band is a
  sanity check on a projection's level, never a substitute for modelling its trajectory — reading
  it as a curve invites extrapolating one averaged rate flat across a horizon, the same
  unmodelled-line error the business-plan skill's projection guard exists to catch.

Sources: competitor pricing pages + changelogs + docs (primary), funding databases and press,
founder interviews/podcasts, G2/Capterra reviews (for weaknesses users actually complain about
AND invoice-level real-price signals), HN/Reddit launch threads, job boards, Wayback Machine
pricing-page diffs (restructuring direction).

## Growth curves & reference class (`research/growth-curves.md`) — runs after competitors, in the parallel wave

The reference class for a target with a date on it. It reads the dated traction points the
competitive dimension already collected and keeps their SHAPE instead of reducing them to a
level: **the observed growth band is the level check — is a rate plausible at all — and this
dimension is the shape check — what a comparable was actually doing at month 18**, which is the
question a dated target asks and a scalar range structurally cannot answer.

Hunt:
- **Index every series to a common origin, never to calendar time.** Re-base each comparable's
  dated points onto months-since-origin, where the origin is a stated event — launch, general
  availability, or the first crossing of a named revenue or user threshold. Plotting by calendar
  date compares companies founded years apart on the market conditions each was living through,
  not on their trajectories: two companies that each grew fast in their own funding climate read
  as one trend line when they are two different markets sampled at two different times.
- **Name the origin per company, in the file, because the choice moves every comparison.** Write
  the origin event and its date beside each series. The same company sits at a different month
  under a launch origin than under a first-crossed-a-revenue-threshold origin, so a set whose
  origins are unstated looks aligned when it is actually stacked — and nobody downstream can tell
  which, because the axis label is identical either way.
- **A company whose origin cannot be dated stays in the corpus and out of the indexed overlay,
  labelled as such.** Keep its calendar series and its dated points in the file, list it under the
  exhibit as excluded-from-overlay with the reason. Silently excluding it makes the reference
  class look tighter than the evidence supports: what the survivors share is a habit of publishing
  launch dates, which is a disclosure pattern, not a growth pattern.
- **Every rate carries the ARR bucket it was measured in, and rates are only ever compared within
  a bucket.** Re-basing to months since origin controls for calendar time and market conditions;
  it does not control for **scale**, and nothing else in this file records the ARR level a rate
  was posted at. So declare the buckets in the file as a property of the reference class —
  order-of-magnitude bands are the usual cut — tag every rate with the bucket it was measured in,
  fit per bucket where the set spans more than one (a single curve fitted across buckets is this
  same error one level up), and check the subject's own projected rate against the bucket **it
  will actually be in at that month**, not against the set as a whole. A
  band assembled across buckets is not a band; it is two different phenomena plotted on one axis.
  A comparable that crosses a bucket mid-series is tagged per stretch rather than per company: the
  company that posted the early rates is not the one that posted the late ones in the only respect
  this comparison turns on.
- **The bucket failure fires in both directions, which is why tagging one end of it is not
  enough.** Two comparables both sit at month 18 — one posting around 20%/mo from a few hundred
  thousand in ARR, one around 4%/mo at tens of millions. Pooled, they produce a month-18 range
  neither company's scale supports: a subject at low ARR is told its plan is unambitious against
  companies that were tiny when they posted those rates, because percentage growth off a small
  base is arithmetically easy and reads as a category norm; and the same undifferentiated band
  makes the high-ARR rate look reachable at a scale nobody in the set achieved it at. Both come
  back as a confident number with a reference class behind it, which is exactly what carries them
  through review.
- **Fit the decay across the set — never assume a constant rate.** The output is two things: a
  per-company trajectory over months-since-origin, and a fitted decay across the indexed set with
  a stated goodness of fit and the months the fit is supported over. That is what lets the
  deliverable say what comparables were doing at month N instead of what they averaged over their
  whole history — and an averaged rate is wrong in both directions at once, understating the early
  months and overstating the current ones while reporting one number for both.
- **Too few points to fit is a finding, written in those words.** Where a company has fewer dated
  points than a shape needs, record it against that company as "two points, no shape" (or one, or
  none) and leave it out of the fit rather than out of the file. A two-point average presented as
  a trajectory is the exact error this dimension exists to end: on the page it is indistinguishable
  from a fitted curve, and it carries none of the evidence a curve implies.
- **Ask how each stretch was grown, and treat the inflections as the target.** A curve gives shape
  and no mechanism, and a reference class with no mechanism cannot be acted on: the founder learns
  comparables were at some rate around month 18 and still cannot tell whether that came from a
  channel they could run this week or from twenty engineers and an audience that already existed.
  So for every comparable, record what it was doing to grow across each stretch of its own indexed
  curve — and above all **at the bends**. An inflection in the series with no named driver in the
  public strategy record is written down as a stated gap, not left silent. This is the identical
  test `business-plan`'s `plan-template.md` already applies to the subject's own projection, where
  every inflection and every flat stretch names its operational driver; applying it to the
  reference class too is what makes the comparison legitimate in both directions, and skipping it
  here holds the founder's own line to a standard the comparables were never held to.
- **Date every strategy to the stretch of curve it ran during.** "They did X" is near-useless
  without when: a company's month-6 strategy and its month-40 strategy belong to two different
  companies, and the later one is the one that gets written up. An undated strategy record
  therefore describes the mature company by default and gets read as the origin story — the
  founder copies a playbook that only works with the distribution the company had by then.
- **A company's account of its own growth is a `claim`, never a `fact`.** It is retrospective,
  self-serving, and survivorship-filtered: the accounts that exist are the ones that worked, and
  nobody publishes the channel that did nothing. Quote the founder's own words rather than
  paraphrasing them into causation, and tag confidence under the citation contract in `SKILL.md`
  like any other figure — no parallel scheme. A stated cause is evidence of what they **did**,
  never proof of what **caused** the curve; recorded as a fact it becomes an unchallengeable
  mechanism two documents downstream, with the hedge stripped at the first hop.
- **Filter each strategy to what is actually available to THIS founder, in the two words the plan
  already uses.** A comparable's strategy the founder could adopt at their grilled hours, channels
  and capital is **policy** for them and belongs with the levers; one gated on resources,
  headcount or advantages they do not have is **structural** for them and belongs in risks. The
  vocabulary is defined in `business-plan`'s `references/plan-template.md` and `references/target.md`
  — apply it, never coin a variant. Unfiltered, the dimension hands a founder a list of things
  that worked for companies that were not them, and the structural ones read as choices they are
  failing to make.
- **Sector extrapolation is the top-down corroborant — reconcile it, never average it.** Put the
  fitted set against the category growth from the market-sizing dimension below. Company
  trajectories that would have the profiled set outgrowing its own category are not automatically
  wrong, but they need a named and defended mechanism — share taken from a specific incumbent, a
  category boundary that is itself expanding, a new buyer entering — or the fits are too hot and
  say so. Same discipline sizing applies to bottom-up vs top-down: a large gap is a mismatch to
  explain, and averaging the two produces a number that is neither the category's growth nor any
  company's.
- **Where the target is an exit, the disclosed acquisitions in the category are a second series on
  the same axis.** Index them the way this dimension indexes anything else — to the acquired
  company's growth slope at the moment of sale, at its month since its own stated origin — so a
  sale lands at a month and a slope rather than at a date. Per comparable, hunt **ARR at exit, the
  multiple that implies, the acquirer, the acquirer's stated strategic rationale in its own quoted
  words, and the company's stage and slope at sale**. The multiple is the term an exit verdict is
  most sensitive to and the one nobody sources: the founder cannot supply it — it is set by buyers
  they have not met, at a moment that has not happened — so a run without this set solves the exit
  at an assumed multiple and returns *undetermined* on the driver that decided the answer.
  `business-plan`'s `references/target.md` names this set as the cheapest test that settles it,
  which is why the indexing basis has to be the same one: an exit indexed to anything but slope
  cannot be read at the month the roadmap puts the sale.
- **The set IS the reference class — label the endpoints, never average them into a multiple.**
  The same discipline the observed growth band already runs under: each endpoint carries its
  company, its ARR at exit, its stage, its slope at sale and the deal's date. A mean multiple
  across the set describes no deal that happened, and it is the figure that ends up in the
  identity precisely because it is the only one shaped like an answer.
- **Too few comparables to bound a band is a stated finding, written in those words.** Where the
  category has one or two disclosed exits, record "two comparables, no band" against the set and
  leave the band undrawn rather than running a line through the pair. A band drawn through two
  points is indistinguishable on the page from one bounded across twelve and carries none of the
  evidence a band implies — the two-point-average error again, one term further down the identity
  where it moves the verdict far more.
- **Name survivorship outright, in the file, beside the band.** Announced acquisitions are the
  ones that closed: nobody publishes the multiple they were offered and refused, and a sale that
  collapsed in diligence leaves no figure to index. The set is therefore what this category paid
  the sellers who said yes, which is a narrower statement than what this category pays — and left
  unstated the reader makes the wider one, because a labelled band reads as a property of the
  category rather than of the handful of deals that reached an announcement.
- **The file states the exhibit it will produce**: an indexed multi-series chart — months since
  origin on x, the metric on y, one line per comparable, the subject's own projection overlaid —
  plus the excluded-from-overlay list beneath it, and the ARR bucket each line sits in made
  legible in the chart itself rather than only in the caption — a chart that hides the bucket
  re-creates the cross-bucket comparison the bucket rule exists to remove, and does it in the one
  artifact a reader trusts without reading the prose. Where the exit set ran, each sale is marked
  on its own company's line at the month it happened, carrying its implied multiple: slope is what
  sets the multiple, so the multiple rides the curve rather than sitting in an exhibit of its own,
  where a reader has to carry a month across two charts and stops doing it after the second
  comparable. Built per `rendering.md`; an unrendered curve file gets read as a table of numbers
  and the shape comparison never happens.

Sources: the dated traction points already in `research/profiles/` and `research/competitors.md`
(primary — never re-derive points that dimension sourced; a second series for the same company
disagrees with the band and nothing says which is right), founder retrospectives and
"our first N years" posts, S-1/F-1 and annual filings for pre-IPO series, investor letters and
conference decks, Wayback Machine snapshots of a customer-count or logo page (the cheapest way to
date a threshold crossing), category growth from `research/sizing.md` for the top-down bound.

For the strategy record the sources are the ones the fleet is already on for other reasons, asked
a question they were never asked: founder interviews, podcasts and conference talks (dated by the
episode, which is what keys them to a stretch of curve), engineering and growth blogs, changelogs
and launch threads, job boards (a hiring wave dates a channel or a team the founder may not have),
Wayback pricing-page diffs, and for public companies the filings and investor letters. Reading the
same page twice costs nothing; discovering at synthesis that nobody asked how the curve was grown
costs the whole dimension a re-run.

For the exit set the sources are the acquirer's own disclosures rather than the coverage of them:
the acquisition announcement and the acquirer's investor communications around it (the stated
rationale, quoted rather than paraphrased into a motive), the acquired company's last disclosed
traction points already in `research/profiles/` (ARR at exit and the slope running into the sale,
never re-derived), and category M&A trackers to find the deals at all.

## Market sizing (`research/sizing.md`)

Bottom-up is the anchor; top-down corroborates. A brand-new category has no honest analyst
number — say so and build the bottom-up.

Hunt:
- **Bottom-up**: addressable population (from proxies: platform user counts, survey populations,
  registration/incorporation data, GitHub/app-store counts — name the proxy and its bias),
  **filtered by ability-to-pay** (users ≠ paying customers — a TAM built on raw user counts
  without a payer filter is flagged), × observed ARPU (from the pricing dimension's anchors or
  competitor price points) × an explicit, stated-as-a-guess penetration rate. Show the formula
  as a formula.
- **Top-down**: analyst figures for the enclosing categories (often quotable from VC blog posts
  and press summaries when the reports are paywalled). State which category boundary each figure
  assumes — mismatched boundaries are why figures diverge. Expect the reconciled bottom-up and
  top-down to land within ~20–30% of each other; a bigger gap means a boundary mismatch to
  explain, not an average to take.
- Growth trajectory: compounding, flat, or shrinking, with the driver. Venture-scale sniff
  test: markets under ~1M potential customers or ~10%/yr growth get flagged as sub-venture
  scale (fine for bootstrap tracks — but say it).
- **This is category growth, not company growth — never let the two merge.** This bullet
  measures the market expanding; the competitive-landscape dimension's observed growth band
  measures how fast a company inside that market acquires customers. A category compounding
  slowly says nothing about how fast a company inside it can acquire — conflating the two lets a
  slow-category finding justify a flat company projection downstream.
- TAM / SAM / SOM as ranges, each with the formula and tag. **"TAM × 1%" is a hard-reject
  pattern.** A defensible SOM names (a) the specific beachhead segment, (b) the concrete wedge
  there, (c) the next 2–3 expansion segments. TAM is a ceiling for sanity-checking ambition,
  never a claimed outcome. A claim that the product EXPANDS the market (Uber vs. taxis) needs a
  named mechanism — new use case, new buyer, price unlock — or it's TAM inflation.

## Customers, segments & JTBD (`research/customers.md`)

Hunt:
- 2–4 concrete segments (not "everyone who..."): who they are, rough size with proxy, how
  acutely they feel the problem, what they use today.
- **Jobs-to-be-done**: the end-to-end task sequence the customer wants done, and where current
  tools break the chain — this is where the product's wedge gets its demand-side evidence.
- Voice of customer: forum threads, reviews, survey data — quote real complaints (cited).
- A recommended **beachhead segment** with the reasoning.

Sources: subreddits and forums where the segment lives, review sites, public surveys
(Stack Overflow, State-of-X reports), competitor case studies (who they showcase = who buys).

## Pricing & willingness to pay (`research/pricing.md`)

Hunt (no-survey WTP pass, in this order — never a single source):
- **Competitor tier teardown**: per competitor a tier/price/cadence/feature-gate/upsell-trigger
  matrix; note the "Most Popular" tier (reveals their target buyer + ACV); Wayback-diff their
  pricing page for restructuring direction; public comps → revenue ÷ subscribers for implied
  ACV; G2/Capterra for invoice-level real prices.
- **WTP evidence**: what the segment pays for adjacent tools, price complaints and upgrade
  triggers in reviews, "what did your previous vendor charge" signals in forum threads.
- **Packaging norms** in the category and the shift direction. Current default for AI-feature
  products: seat/platform base + metered add-on for the AI action (hybrid displaced pure-seat
  as the norm) — with a predictability guardrail (caps/alerts), because an unpredictable meter
  erodes trust even when it's value-aligned.
- **Free-tier fit** (not a default): freemium only when time-to-value < ~5 min, bottoms-up,
  low ACV; trial (or reverse trial) when ACV > ~$50/mo or sales-assisted.
- A recommended price anchor + packaging hypothesis for THIS product, tagged L (it's a
  hypothesis) with the cheapest validation to run (a 3-tier page test with an anchor top tier
  beats a survey; Van Westendorp only as a floor/ceiling sanity check).

## Trends, timing & why-now (`research/trends.md`)

Hunt:
- The 3–5 shifts that make this product possible/necessary NOW (tech capability, cost curves,
  behavior change, regulation) — each with evidence it's real, not narrative.
- **Platform risk**: what happens if the platform/model vendors ship this natively; who is one
  quarter away.
- Distribution shifts relevant to the surface (desktop vs web vs extension...).
- What has to stay true for the next 18 months for this to matter.

## Channels & GTM landscape (`research/channels.md`)

Hunt:
- How products in this category actually get discovered and bought (PLG self-serve, sales-led,
  hybrid, marketplaces, communities, content/SEO, launch platforms) — with examples of who wins
  via what. Read each competitor's pricing-page CTA as their true motion.
- **The three motion gates for THIS product**: ACV band (<$10K → PLG default, $10–50K hybrid,
  >$50K sales-led) → buyer type (single-user value capture + self-serve payment authority, or
  a committee?) → time-to-value (unassisted aha in <30 min, or implementation-gated?). A
  motion that fails a gate fails regardless of execution — motion-product mismatch is the top
  GTM killer, so report the gate results explicitly.
- CAC reality: citable benchmarks or disclosed numbers for the motion (payback medians: PLG
  ~9–15 mo, sales-led 12–29 mo, PQL-assist 3–6 mo); CAC/ACV over ~30–40% is structurally
  broken without high NRR.
- The channels open to a NEW entrant at the product's stage — ranked, with reasoning.
  Community-led is a compounding layer, never the primary motion for a pre-revenue team.
- **Automation leverage in this category**: which growth levers are demonstrably
  automatable here (programmatic/comparison SEO that survives quality gates, changelog-as-SEO,
  screenshot/demo pipelines, AI-UGC creative testing, standing directory queues) and which
  burn trust in THIS audience (developer communities are adversarial to bot-shaped output).
  Evidence: what visibly works for the profiled competitors.

## Unit economics & COGS at scale (`research/unit-economics.md`) — runs whenever the dossier has Cost structure signals

The repo already named the cost structure; this dimension prices it and projects it. Hunt:
- **Current metered rates** for every service in the dossier's Cost structure signals —
  from the providers' own pricing pages (these change; pull dates matter more than usual).
  Include the free-tier boundaries (many products live inside them at first — say where the
  cliff is).
- **Cost per unit of value**: build the formula — cost per active user/month and per core
  action (per analysis run, per generation, per 1k requests) — from the billing shapes.
  LLM-heavy products: tokens per action × current per-token rates, with the model named; note
  the historical direction of those rates (falling) as a trend input, not a promise.
- **Scale projections**: a cost-vs-revenue table at usage tiers (e.g. 100 / 1k / 10k / 100k
  users, or the product's natural usage unit), revenue side anchored on the pricing
  dimension's recommended anchor. Gross margin at each tier; the tier where free-tier cliffs
  hit; break-even. Flag the "does the margin survive success?" verdict explicitly — a product
  whose COGS scales linearly with its value delivery (LLM calls, rendering, storage) can be
  healthy at 100 users and dead at 100k.
- **Optimization levers** incumbents use in this category (caching, model tiering, batch,
  self-hosting thresholds) — as evidence of where margin structurally lands, not as advice.

Sources: provider pricing pages (primary), engineering blogs on cost at scale in this
category, disclosed gross margins of public comparables.

## Moats, risks & regulation (`research/moats-risks.md`)

Hunt:
- Which of the 7 Powers are actually available here, applying the hard test: **power = benefit
  + barrier** — "why can't a well-funded competitor copy this in 18 months?" answered
  specifically, or the claim dies. The realistic early-software sequence is
  counter-positioning → scale → switching costs → network effects; brand / process power /
  cornered resource claimed pre-scale is almost always overstated — downgrade it.
- **Counter-positioning is validated by naming the incumbent's cannibalized revenue line** and
  showing that copying is NPV-negative for them — not "they're slow".
- **Network effects need the real test**: a metric where per-user value rises with N. Without
  it, reclassify as scale economies or nothing. In AI-adjacent categories, note that classic
  switching costs and surface network effects are weakening (agents migrate data and arbitrage
  platforms); proprietary data access and compounding first-party loops are what's
  strengthening.
- Ban the phrases "no competition" and unqualified "data moat" from findings — name the
  mechanism or drop the claim. Every defensibility claim carries a **"how we'd know"** line:
  the metric or interview finding that would confirm or falsify it.
- Regulatory/compliance exposure (often thin — 15 minutes to confirm there's nothing, then say
  "nothing material found" rather than padding).
- The top 5 ways this product dies, each ranked **Impact × Probability × Confidence** (thin
  evidence caps a threat at "watch", never "act") with the leading indicator to watch.

---

## Add-on dimensions — dispatch when the product demands

- **Marketplace/supply side**: liquidity, chicken-and-egg strategies that worked in the category.
- **Compliance deep-dive**: regulated verticals (health, fintech, kids) — certification costs and
  timelines become plan-level facts. Also triggered by MECHANISM, not just vertical: a
  horizontal product that touches other people's regulated data (clones prod databases,
  processes PII, records calls) earns this dimension too.
- **Hardware BOM & logistics** (`research/bom.md`): hardware or physical-goods products —
  BOM, margins, logistics. Extends (never replaces) the standard unit-economics block.
- **Ecosystem/API**: platform products — who would build on it, precedent take-rates.

Add-ons have no canned playbook block. The conductor AUTHORS one in the same format as the
standard dimensions above (output file name + Hunt list + sources + the shared skeleton) and
passes it in `playbooks` — never dispatch a dimension whose playbook is empty (the canonical
workflow script throws on it).
