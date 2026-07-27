# Strategy simulation — competing paths, one product

When the capital path (bootstrap vs raise) or the entry sequencing (niche-first vs broad) is
genuinely open, the plan doesn't pick by vibes — it SIMULATES the paths and shows the founder
the comparison. Skip this only when the grill closed the question ("bootstrapped, final");
even then, the reinvestment engine below still shapes the bootstrap model.

The simulations live in `financial-model.md` (a `## Strategy comparison` section) and the
winning path's story becomes the plan's operating narrative. Everything here obeys the model's
existing rules: every input is a named assumption row, sourced or labeled a guess.

## 1. Paths as parallel copies of ONE model

Build 2–3 copies of the same model that SHARE unit economics and product assumptions and
differ only in: capital-injection schedule, spend pace, and the resulting cap table. Never a
separate hand-built model per path — shared assumptions are what make the comparison honest.

- **Compare founder dollars, not company valuation.** Bootstrapped medians run ~65% founder
  equity vs ~15% post-Series-B; VC concentrates the upside on a rare huge outcome. Which path
  "wins" depends entirely on the exit-size distribution the founder actually believes — so
  show founder take-home at low/base/high exit scenarios per path, and let the grilled
  ambition pick the distribution.
- **Dilution is a deterministic ladder, never eyeballed**: per round — pre-money, raise,
  post-money, new-investor %, option-pool refresh (its own line, ~1–3%/yr), founder % after,
  cumulative founder %. Chain it; the pre-seed→A step alone typically costs founders 40–60%
  of their stake. SAFE: `SAFE % = investment ÷ cap`, then `new % = old % × (1 − SAFE %)`.
- **Efficiency metrics per path**: CAC payback and burn multiple (net burn ÷ net new ARR) —
  not raw CAC. Payback >12 months is a trigger to NARROW the ICP, not to spend more broadly.
- **Milestone gates, not ARR vanity**: each funding stage buys ONE falsifiable proof —
  pre-seed proves the wedge is real, seed proves it repeats (retention), A proves it scales
  efficiently. Path models advance through gates, and a missed gate's pre-committed action is
  written down (see the trigger table).

## 2. Entry sequencing — beachhead vs broad, scored not asserted

- **Beachhead scoring table**: candidate segments × homogeneity (one buyer profile),
  reference-ability (tight community that refers), reachability (identifiable channels),
  size, and 10×-advantage — 1–5 each. The market analysis's beachhead recommendation seeds
  it; the founder's unfair advantages re-weight it.
- **Bowling-pin expansion is pre-committed**: pins 2, 3, 4 named BEFORE pin 1 is won, each
  with its own unlock condition ("≥40% of beachhead accounts referred a peer"), kept separate
  from the capital gates — GTM sequencing and capital sequencing are two decision tracks,
  cross-tabbed, never merged.
- **A broad launch is an irreversible bet** — treat it as a real option being exercised:
  what uncertainty must be RESOLVED before it's rational, and what's the value of waiting?

## 3. The reinvestment engine (bootstrap paths especially)

Model growth as a LOOP, not a funnel: this period's output funds next period's input.
Marketing spend is never a flat exogenous line in a bootstrapped model — it's a function of
trailing profit.

- Core shape: `growth(t) = reinvest_rate(t) × marginal_ROI(t)`, with ROI decaying as a
  channel saturates (content decays slower than paid). Growth curves are S-curves with a
  saturation term — a constant-%-forever growth line is the tell of a reverse-engineered
  model.
- **Default-alive gates the rate**: while not default-alive (P. Graham: flat expenses +
  current growth reach profitability before cash out), reinvestment is effectively total;
  once default-alive, step toward a stage target — ~65% of profit early, ratcheting toward
  ~20% as the business matures. Move any bucket ≤2pp per quarter — never snap on a noisy
  monthly metric.
- **Four named buckets** so reinvestment can't silently eat the founder: owner pay (HARD
  FLOOR — a living-cost draw, never $0-by-default; the "I'll pay myself later" pattern has no
  natural end), tax, opex, profit → split reinvest/distribute.
- **Payback sets loop speed**: `cycles/yr = 12 ÷ CAC-payback-months` — a 6-month-payback
  business compounds twice as fast as a 12-month one on the same profit. This is why the
  model treats payback as a first-class input.
- **Channel unlocks are milestones with capped test budgets**: content/organic first
  (near-zero CAC); a revenue milestone (the "$ that makes a paid test affordable without
  risking runway") unlocks a paid-ads test at ≤~10% of that month's profit until it proves
  payback. Sanity caps: marketing 15–25% of revenue early-stage, stepping down; flag spends
  above the stage ceiling.
- **Validator, not driver — Rule of 40**: growth% + margin% ≥ 40 per projected year. Failing
  it means reinvestment is too timid (growth starved) or too aggressive (margin destroyed);
  the model flags it, never silently tunes to it.

## 4. Method matched to evidence — don't fake statistics

Deterministic base/downside/upside is the DEFAULT at pre-seed — assumptions are guesses, not
distributions. Escalate to a per-driver scenario table when ≥3 material unknowns interact.
Monte Carlo only when ≥6–12 months of real usage/cohort data can parameterize distributions —
never fabricate probability distributions from vibes; its one pre-data use is finding which
1–2 inputs the outcome is most sensitive to.

## 5. Solve backwards — the required trajectory, not just a projected one

Everything above still only answers "what might happen if these assumptions hold." Once a
target is settled (per [target.md](target.md)), the model runs the other direction too: given
the target and its date, what does each driver have to become, and by when.

- **Same identity, opposite direction.** [target.md](target.md#the-outcome-decomposes-into-drivers-before-any-number-goes-into-it)
  already wrote the driver identity a verdict rests on — `MRR = paying customers × price`, the
  customer count as a stock net of churn, or the user-count / salary-replacement variants — and
  the rules for where each driver's value comes from and what makes it traceable
  ([target.md](target.md#each-driver-takes-its-value-from-a-named-place-in-the-corpus)). This
  pass takes that same identity and those same evidenced driver ranges and solves for the
  values at every month between now and the target date, not only at the date itself; it does
  not re-derive either rule.
- **The output is a trajectory, one row per driver per month** — reach, conversion, price, and
  the standing customer count, each with the value it must hit that month for the target to
  land on time. A monthly milestone is checked against this row; the forward projection above
  never produces a monthly required value to check anything against, because it was never
  solving for one.
- **Solved at both ends of the evidenced ranges, same as the counter-offer in target.md.** A
  single-point monthly figure claims a precision the evidence doesn't have. Carry the band
  through, and a milestone check compares the actual month's number against the band, not a
  point.
- **Re-solved whenever a driver's evidenced value moves** — a renegotiated target, an amended
  pricing claim, a channel underperforming its evidenced throughput. The trajectory is a live
  output of the current evidence, not a schedule computed once and archived.

**The failure this prevents:** a forward projection alone answers "what might happen," never
"what has to be true by March" — so nothing in the plan is falsifiable at a date. A milestone
checked against a projection surfaces a shortfall only once the horizon is reached and the
cumulative gap is already unrecoverable; a milestone checked against the required trajectory
reads as slippage the month it happens, while there is still time to act on it.

**Method matched to evidence: §4's rule applies unchanged** — no separate threshold for the
backward solve.

## 6. The deliverable — a Path Comparison + Trigger table

```markdown
## Strategy comparison  (in financial-model.md)
| | Path A: <e.g. bootstrap, niche-first> | Path B: <e.g. seed round, niche-first> | Path C? |
|---|---|---|---|
| Key differing assumptions | | | |
| Capital in / dilution ladder result | | | |
| Runway & burn multiple | | | |
| Time to default-alive / next gate | | | |
| Founder $ at low / base / high exit | | | |
| Dominant risk | | | |
**Recommendation**: <one path, and WHY the founder's ambition + exit beliefs pick it [F#]>
**Switch triggers (pre-committed, decided calm)**:
| Trigger metric | Threshold | Pre-committed action |
| e.g. CAC payback | > 12 mo for 2 consecutive months | pause channel X, narrow ICP to pin 1 only |
| e.g. cash | < 6 mo runway | cut Y, revert to path A spend pace |
```

Triggers are decided NOW, in a calm moment, so a downturn is playbook-execution, not
improvisation. The red team's capital-skeptic lens attacks the recommended path's weakest
trigger.
