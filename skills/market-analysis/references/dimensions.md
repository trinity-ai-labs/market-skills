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
  traction (ARR, users, downloads — only if stated somewhere citable), funding/investors,
  positioning claim in their own words, **most likely next move**, and **what they structurally
  don't cover and why** — the wedge line. Every profile ends with it.
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

Sources: competitor pricing pages + changelogs + docs (primary), funding databases and press,
founder interviews/podcasts, G2/Capterra reviews (for weaknesses users actually complain about
AND invoice-level real-price signals), HN/Reddit launch threads, job boards, Wayback Machine
pricing-page diffs (restructuring direction).

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
- **Unit economics**: hardware or high-COGS products — BOM, margins, logistics.
- **Ecosystem/API**: platform products — who would build on it, precedent take-rates.

Add-ons have no canned playbook block. The conductor AUTHORS one in the same format as the six
standard dimensions above (output file name + Hunt list + sources + the shared skeleton) and
passes it in `playbooks` — never dispatch a dimension whose playbook is empty (the canonical
workflow script throws on it).
