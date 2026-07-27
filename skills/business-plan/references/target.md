# The target verdict — decomposed into drivers, computed, then negotiated

A target is a concrete outcome plus a date: a monthly revenue figure by a month, a paying-user
count before a raise, a salary replaced inside eighteen months. **Either axis may be stated as a
range** — a salary replaced in eighteen to twenty-four months, a company sold for a value range
inside a date range — and a range on both axes at once is how an exit target normally arrives,
not an edge case. The scalar statement is the simple form of the same thing, a range of one; a
ranged target is solved at [the corners of the rectangle its ranges
describe](#a-stated-range-on-either-axis-is-a-rectangle-solved-at-its-corners), never at a
midpoint. This file is the method for judging one — how the outcome decomposes into drivers,
where each driver's value comes from, what the verdict says, what it says when the evidence
cannot carry a verdict at all, and what happens when the answer is no.

It sits behind invariant 16, and carries the verdict half of invariant 18, exactly as
[vault.md](vault.md) sits behind invariants 7–15: the head of `SKILL.md` carries the rule, this
file carries the detail, and the phases point here rather than restating any of it. That split
is not tidiness. Compaction re-attaches only the head of a skill file, so a method written
inside Phase 3 is not in context when Phase 3 runs.

## Contents

- [The outcome decomposes into drivers before any number goes into it](#the-outcome-decomposes-into-drivers-before-any-number-goes-into-it)
  - [Each driver takes its value from a named place in the corpus](#each-driver-takes-its-value-from-a-named-place-in-the-corpus)
  - [The multiple's inputs have homes too, and not one of them is ARR](#the-multiples-inputs-have-homes-too-and-not-one-of-them-is-arr)
  - [A structural driver may be sourced from the reference class; a policy driver may only be checked by it](#a-structural-driver-may-be-sourced-from-the-reference-class-a-policy-driver-may-only-be-checked-by-it)
- [Every driver value names its driver in both directions, and a low one with none is unmodelled](#every-driver-value-names-its-driver-in-both-directions-and-a-low-one-with-none-is-unmodelled)
- [The verdict names which driver binds, and by how much](#the-verdict-names-which-driver-binds-and-by-how-much)
- [A binding driver that is policy makes the verdict conditional, not negative](#a-binding-driver-that-is-policy-makes-the-verdict-conditional-not-negative)
- [A driver that traces to nothing makes the verdict undetermined, not negative](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative)
- [A stated range on either axis is a rectangle, solved at its corners](#a-stated-range-on-either-axis-is-a-rectangle-solved-at-its-corners)
- [The multiple usually binds, and it is always the least evidenced driver](#the-multiple-usually-binds-and-it-is-always-the-least-evidenced-driver)
- [A verdict is capped twice and never asserted at high confidence](#a-verdict-is-capped-twice-and-never-asserted-at-high-confidence)
- [Two verdicts, because a late-only verdict wastes a whole research run](#two-verdicts-because-a-late-only-verdict-wastes-a-whole-research-run)
- [The nearest reachable target is a solve, not a smaller number chosen by feel](#the-nearest-reachable-target-is-a-solve-not-a-smaller-number-chosen-by-feel)
- [The levers are counterfactuals, kept apart from the counter-offer](#the-levers-are-counterfactuals-kept-apart-from-the-counter-offer)
- [The founder chooses, and the superseded target keeps its reason](#the-founder-chooses-and-the-superseded-target-keeps-its-reason)
- [Computing a verdict: the checklist](#computing-a-verdict-the-checklist)

## The outcome decomposes into drivers before any number goes into it

Every target is an arithmetic identity waiting to be written down. Write the identity first, in
full, before a single value goes into it — because the identity is what makes the verdict
checkable by someone who disagrees with it. **The shapes below are the ones this file
decomposes, not the ones that exist.** Read the list as open: a target whose shape is missing
gets forced into the nearest one on it, and the substitution is silent because the identity that
results is well-formed.

- **A revenue target.** `MRR at the target date = paying customers at that date × price`.
- **The customer count underneath it.** `new customers per month = reach per month × conversion`,
  and the count *standing* at the target date is every prior month's acquisitions net of churn at
  the evidenced retention rate. Retention is what makes a customer count a stock rather than a
  running sum; a chain that adds acquisitions and never subtracts churn reaches any target given
  enough months, which is why an unreachable target so often reads as reachable on the first pass.
- **A user-count target** is the same chain stopped one step earlier: price drops out, and
  conversion is measured to the event the target actually counts — activation, signup, first
  paid — not to whichever of those the benchmark happened to measure.
- **A salary-replacement target** adds one step below revenue: `owner draw = (revenue − costs) ×
  draw share`. The revenue the identity has to reach is the salary grossed up by the cost base and
  by the reinvestment the plan already commits to — owner pay is a named bucket in
  [strategy-sim.md](strategy-sim.md), never the residual. Solving for revenue equal to the salary
  is the standard version of this mistake, and it understates the target by the whole cost base.
- **An exit target** — an outcome stated as an acquisition or a company valuation —
  is `exit value = ARR at exit × multiple`. The left term is one of the identities above, solved
  at the sale date rather than at the target date, so those shapes are a *term* of this one and
  never a substitute for it. **The multiple enters as a band and never as a scalar.** Written as
  one number it reads as a property of the category and the verdict inherits a precision nobody
  evidenced; written as a band it carries its own uncertainty into the answer, which is the only
  thing that lets the flip test fire on the term that decides the answer. The band's ends come
  from the four inputs in [the multiple's own driver-home
  table](#the-multiples-inputs-have-homes-too-and-not-one-of-them-is-arr), and the verdict is
  solved at both of them — [the multiple usually
  binds](#the-multiple-usually-binds-and-it-is-always-the-least-evidenced-driver). This is also
  the shape most often stated as a range on both axes at once, so the corner solve and the
  multiple band compose: each corner is solved across the band, not at a point inside it.

**Forcing an exit into the revenue identity is the substitution this shape exists to stop, and it
is silent.** Reduced to revenue, an exit target's dominant term disappears: the growth slope at
the moment of sale, the strategic necessity of the asset to a *named* acquirer, how hard it is to
rebuild, and whether a second buyer exists all collapse into an assumed ARR figure at a multiple
nobody evidenced or even wrote down. The verdict then comes back confident about a quantity that
was never the constraint. The tell is a readout naming a revenue driver as binding on a target
whose stated outcome is a sale.

**The failure the identity prevents:** without it, "can we get to this number" is answered by
judgement about the number as a whole, and judgement about a whole number is unarguable. Nobody
can tell you which part of it they think is wrong, so nobody does — and a verdict nobody can
attack is one nobody can trust either.

### Each driver takes its value from a named place in the corpus

A driver value is only a driver value if you can say where it came from. Every one of them has a
home, and the home is not the same for all four:

| driver | kind | where its value comes from |
|---|---|---|
| price | policy within a structural band | the market analysis's pricing / willingness-to-pay dimension, as a `claim` with its subject from `_vocab.yml`, plus the founder's price instinct `[F#]` where the two differ |
| conversion | structural | a sourced category benchmark — a `source` note with its verbatim `quote` and its `url` — at the stage the target counts; where `research/growth-curves.md` indexes a comparable that discloses it, the reference-class value at the month since origin the target counts is preferred to the benchmark, and a divergence between the two is recorded rather than averaged |
| retention | policy within a structural band | the **band** from the same places conversion takes its value, and it is per-period, so the period is part of the value. The **position inside the band** is homed to the product — the depth of what it does, whether the valuable thing is reachable unassisted, and the friction between the two — as a `claim` carrying a sourced base with its magnitude labelled `measured`, `reference-class` or `assumed`, and an `assumed` one taking the both-directions test like any other input |
| reach | policy | what the founder's own channels support at their grilled hours and budget: the resource facts from the grill crossed with the channel's evidenced throughput; where the indexed set covers the same months, a comparable's reach at that month since origin is the reference-class check on that figure — it does not replace it, because reach is this founder's channels and hours |

**`kind` records who sets the value, and it decides two things: where that value is allowed to come
from, and what a negative verdict is later allowed to conclude.** A **structural** driver is set by
the category: conversion is what it is at the stage the target counts, and no decision the founder
takes this week moves it. A **policy** driver is a value the founder chose and could choose
differently — reach is channels × hours, which is a decision. **Two drivers are split**, and they
take the same construction: price is a point the founder picks inside a band the
willingness-to-pay evidence sets, and retention is a position the product holds inside a band the
category sets. In both, the point is policy and the band is structural. Two tests run on this column
at two moments: [a structural
driver may be sourced from the reference class; a policy driver may only be checked by
it](#a-structural-driver-may-be-sourced-from-the-reference-class-a-policy-driver-may-only-be-checked-by-it)
at fill time, and [a binding driver that is policy makes the verdict conditional, not
negative](#a-binding-driver-that-is-policy-makes-the-verdict-conditional-not-negative) at verdict
time.

**What places the product inside the retention band is the value it delivers.** A consumer utility
does not retain like an ERP, and that is the band. Inside it, three things move the position and all
three are built rather than found: how deep the thing the product does actually is, whether the
valuable part of it is reachable by the buyer unassisted, and how much friction sits between the
two. The plan states them where the price is defended, in [plan-template.md](plan-template.md)'s
`## Value delivered (MANDATORY wherever price is defended)` section, and that section names
retention as its channel into the arithmetic — which is what stops a delivered-value argument from
being a paragraph that moves no number.

**A retention claim therefore carries a base and a label, and an improvement claim carries them
harder.** The band is sourced; the position is a `claim` with a sourced base and its magnitude
labelled `measured`, `reference-class` or `assumed`, and an `assumed` one takes [the
both-directions
test](#every-driver-value-names-its-driver-in-both-directions-and-a-low-one-with-none-is-unmodelled).
**The failure that guard prevents:** churn is the divisor of the steady-state identity, so halving
it roughly doubles the equilibrium — an unguarded improvement claim moves the answer further than
any other input in the model, and it does so while flattering the thing the founder built, which is
what makes it easy to write and hard to challenge. Unguarded, the split is a licence to model churn
down to whatever the target needs.

**`conversion` is not split, and the line is drawn there deliberately.** Onboarding quality moves
activation and trial-to-paid too, so the argument above reaches for conversion next. It stops.
Conversion is a funnel property of the category measured at a stage; retention is where a product's
own value shows up over time. **The failure splitting it as well would cause:** reach is policy,
price is split, retention is split — split conversion too and the identity keeps no structural term
at all, every negative verdict becomes conditional on something the founder could change this week,
and the method loses the one output it exists to be able to produce, which is telling a founder no.

**Where the founder's instinct and the evidenced range disagree, record the divergence — never
average them.** The midpoint of a founder's hope and a benchmark is a number neither of them
asserts, and it enters the identity carrying the authority of both.

**A category benchmark is a level with no trajectory behind it, and the target has a date.** One
benchmark figure stands in for every stage at once, so a driver filled from it quietly asserts
that a company six months from its origin converts and reaches like one forty months from it —
against a target whose whole question is what is true at a stated month. The indexed set in
`research/growth-curves.md` carries the month, which is what lets a driver take its value at the
month the target counts instead of at no month in particular. Where both exist, the reference-class
value is the one with a trajectory under it; where only the benchmark exists, the driver still
takes it and the readout says which of the two it stood on.

**Reach is the driver a sizing figure will happily impersonate, and that substitution is the
single commonest way an unreachable target clears.** SAM is not reach. Reach is how many of the
right people this founder's channels put in front of the product per month, at the hours and
budget they stated in the grill. A market of millions and a founder with six hours a week and no
audience are both true at once; only one of them is in the identity.

**A driver taken from the plan's own projection is not evidence.** The financial model is
downstream of the verdict — feeding its output back in makes the verdict a check on its own
arithmetic, which it will always pass.

### The multiple's inputs have homes too, and not one of them is ARR

The multiple in an exit identity is a driver like any other, so it takes its value from named
places rather than from a feel for the category. It has four inputs, and the reason to write them
down separately is that **none of them is ARR**: the revenue term is the one an exit verdict is
least sensitive to, and the second term is what decides the answer.

| driver | kind | where its value comes from |
|---|---|---|
| growth slope at the moment of sale — **not the level reached** | policy | the slope this roadmap commits to at the month the sale lands — stated configuration in the same sense reach is, never the plan's own projection fed back in — with `research/growth-curves.md`'s indexed set read at that same month as the check on it. A company growing fast at a smaller ARR prices above a larger one that has flattened, which is why the level term cannot stand in for this one. The exit multiple and the indexed curve are the same instrument read at different moments, which is why they share an exhibit rather than each getting one |
| strategic necessity to a **named** acquirer | policy | the dossier's seam argument — what is true only because these parts sit in one system. The question is not "is this valuable" but *which acquirer has a hole this patches, and is the product visibly the patch*. An unnamed acquirer is not a driver value; it is a blank the identity accepts without complaint. Which acquirer the roadmap is aimed at is a decision, and that is what makes this policy |
| scarcity, and how buildable the asset is | structural | the moats dimension, with `power = benefit + barrier` asked of the buyer rather than of a competitor. If the acquirer ships it itself in two quarters the price collapses to an acquihire, and nothing the founder decides this week moves that |
| a bidding dynamic | structural | the same named-acquirer set, counted rather than argued: how many buyers have the same hole. One interested party is a price **floor**, not a price — a single bidder pays what it has to, and what it has to pay is whatever the founder's next-best alternative is worth |

**`kind` means the same thing here as above — where the value may come from, and what a negative
verdict is allowed to conclude.** At fill time that reads: the indexed set and the comparable-exit
set *check* slope and the named acquirer, because both are commitments this roadmap makes; the moats
dimension and the counted acquirer set *source* scarcity and the bidder count outright, because both
are properties of the category and its buyers.

At verdict time it reads as it does above. Slope and the acquirer aimed at are policy, so an exit
value the multiple will not carry at the roadmap's current slope is unreachable *in the stated
configuration*, and
[A binding driver that is policy makes the verdict conditional, not
negative](#a-binding-driver-that-is-policy-makes-the-verdict-conditional-not-negative) is the rule
that fires. Scarcity and the bidder count are structural: they are set by the category and by the
buyers in it, and a verdict binding on either is a finding about the business rather than about
the plan. Reporting a slope-bound exit as structural tells a founder their company cannot be sold
for that, when what is true is that this roadmap cannot sell it for that.

**The band's ends are those four inputs at their plausible extremes, never a range typed in from
memory.** A band whose ends trace to nothing is a scalar with error bars painted on, and it fails
in the direction that hides: it *passes* the flip test, because ends chosen close together give
the same verdict at both, and the run then reports a verdict that rests on the width of a guess.

### A structural driver may be sourced from the reference class; a policy driver may only be checked by it

The two tables above hand the same instrument two different authorities, and the reason is the
`kind` column rather than anything about the instrument. `research/growth-curves.md` *sets*
conversion, at the month since origin the target counts; the same file only *checks* reach against
what the founder said their own channels do. Stated as a principle:

**A structural driver is a property of the category, so the indexed set can source it. A policy
driver is the founder's own configuration, so a comparable's value is evidence about a different
company's choices and can only ever be a check.**

Conversion is what the category does at a stage, and a comparable measured at that stage is
measuring the same quantity — the set speaks to it directly. **Retention is split, and the rule
covers it unchanged rather than needing an exception:** the band is a property of the category, so
the set sources it; the position inside the band is this product's own, so the set may only check
it. A comparable retaining better is reporting a different product's depth and reachability, and
pasting that figure in replaces the product under test with somebody else's — which is the same
substitution the reach row makes, arriving one level down. Reach is this founder's
channels at this founder's hours; a comparable that put ten times as many people in front of its
product a month is reporting a different budget and a different audience, and pasting that figure in
replaces the configuration under test with somebody else's. The same reading runs down the exit
table: slope at the sale month and the acquirer the roadmap aims at are commitments this plan makes,
so the indexed set and the comparable-exit set check them, while scarcity and the bidder count are
properties of the category and its buyers, so the moats dimension and the counted acquirer set
source them.

**Sourcing a policy driver from a comparable is neither conservative nor aggressive — it answers a
different question, and the answer comes back well-formed.** The verdict exists to say whether *this
configuration* reaches the target. Fill reach from the reference class and it says instead whether a
company with that reference class's channels would, and the founder's stated hours never enter the
arithmetic at all. Nothing in the readout marks the swap: the figure carries a citation, the identity
balances, and the binding driver is named with the same confidence it would have had. The founder
then argues about a constraint that was never theirs.

**The reference class is not a term in any identity, and it is the input every structural driver's
value rests on.** Which companies are comparable is what sets conversion, the band retention sits in,
and the multiple at once, one level beneath the arithmetic — so it takes the discipline the drivers take: **named in
the readout, classified `structural`, homed to `research/growth-curves.md`, and put through the flip
test.** Left unwritten it is not a neutral background choice; it is the largest unexamined input in
the method.

**A class inferred from the subject's own price point or packaging is downstream of a policy input,
and it inherits that input's mutability.** The split classifies by who sets the value, and a class
read off the subject's own price point and delivery shape was set by the founder rather than by the
market — so the class still describes the category and stays `structural`, but the choice that put
the subject inside it is a configuration the founder can change tomorrow. Filing it `structural` on
the strength of where it landed hides that. A class derived that way therefore says what it was
inferred from wherever it is named, and it is re-flipped when that input settles differently: a
repricing, a repackaging or a change in how the product is delivered re-opens which companies are
comparable, and the candidate classes that come back are what the flip test then runs over.

**The failure this causes:** a founder decision selects the comparable set, the set fixes
conversion, retention's band and the multiple together one level beneath the arithmetic, and the
verdict
that follows is reported as a property of the market. Repricing then reads as a pricing question
when it is a reclassification — the one change that moves every structural driver at once — and it
is never costed as one, because nothing in the readout records that the class was ever downstream of
a decision the founder controls.

**Flip the reference class across the alternatives a reasonable person would argue for.** Re-solve
the identity with each candidate set's values at the months the target counts. Same verdict under
both and it stands, with the readout naming which class it stood on. Verdict moves and there is no
verdict: the run returns **undetermined**, names both candidate classes, and names the cheapest test
that would settle which one the subject belongs to. This is [a driver that traces to
nothing](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative) applied one
level up — to the thing that decides where every structural driver's value comes from.

**The failure an unwritten reference class causes:** a class chosen by feel cannot be attacked,
because it never appears as an input, and the growth rate it sets then inherits the authority of the
indexed set it was only ever assumed into. The founder is handed what reads as a property of their
market, and what they were handed is a categorisation. It is the highest-leverage error available in
this method precisely because every structural driver beneath it moves together: the whole verdict
shifts without a single figure in it looking wrong.

A worked example, invented end to end:

> A developer-tool product is indexed against a general developer-tooling class, and its structural
> drivers take their month-18 values from that set. A reviewer argues the subject belongs to a
> narrower class the same file indexes separately — tools adopted bottom-up by individual engineers
> inside larger accounts — which posts materially steeper conversion at the same month.
>
> Both classes are defensible from the dossier, so the class is flipped. The target clears under the
> narrower one and misses under the general one.
>
> **Readout:** *undetermined, and what is undetermined is the reference class rather than any driver.
> Conversion, the band retention sits in, and the multiple all move together between the two
> classes, which is why no
> single figure looks wrong under either. The cheapest test is the adoption path in the disclosed
> deployments: whether the product enters an account through an individual engineer or through a
> procurement decision. Kill/continue: if the disclosed deployments are predominantly
> procurement-led, the general class is the right one and the target does not clear.*

**Every company in the indexed set is a survivor, so a driver sourced from it carries the
survivorship qualifier wherever the value appears.** The set is assembled from companies that got far
enough to be written about; the ones that posted the same early numbers and then stopped are absent
by construction. That is a property of the set rather than of any member, and it makes a driver
sourced this way systematically optimistic. The qualifier travels with the value into the readout and
into any exhibit that renders it, in the same words each time — not as a footnote on the research
file, which is not where the number is read.

**Where a broad-population figure and a named-company value both exist for the same metric, record
the disagreement — never pick by feel and never average.** This is the founder-instinct rule at a
different pair of sources: a midpoint is a number neither source asserts, entering the identity
carrying the authority of both. The gap is not a rounding difference. Broad-population medians and
named-company values for the same metric routinely differ by most of an order of magnitude, because
the named companies are the ones that worked, and a run that quietly took the higher of the two has
sized the plan against a population the subject is not in yet.

**The failure an unqualified survivor value causes:** reported bare it says *this is what companies
at this stage do*, when what it says is *this is what the companies that made it did*. That is the
both-directions defect wearing the opposite sign — an unaudited bias in a value that reads as
sourced. Replacing a pessimistic default nobody challenged with an optimistic one nobody challenged
moves the error; it does not remove it, and it is harder to catch in the second position because the
number now has a citation behind it.

## Every driver value names its driver in both directions, and a low one with none is unmodelled

A value is a claim about the world in whichever direction it points. **Every value that enters an
identity — each driver, each of the multiple's four inputs, every rate and share the chain
multiplies — names the driver behind it in both directions.** A figure near the top of its plausible
range names why it is that high; a figure near the bottom names why it is that low. Neither direction
is the default one and neither is exempt. The curve rule in [plan-template.md](plan-template.md) is
this rule applied to the shape of a projection; this is the general form, and it applies one level
up, to the numbers the shape is built from.

**A low value with no driver behind it is `unmodelled`, not conservative, and the readout says so in
that word.** "Conservative" is a compliment the figure has not earned. It describes a value set below
the evidence *on purpose*, for a stated reason — a hard channel cap, a deliberate ceiling, a known
constraint. A value that is merely low, picked because low felt safe, has no reason attached at all,
and it is doing exactly as much unexamined work in the arithmetic as a hockey stick would.

**Run this test before the flip test, on every driver, and do not expect the flip test to cover
it.** [The flip test](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative)
re-solves at both ends of an assumption's plausible range and asks whether the verdict moves. A
pessimistic value with no driver behind it is a perfectly well-formed `assumption` note carrying a
`value` and a `sensitivity`, and it passes clean — because the band it was given is a band drawn
around the wrong centre. The flip test audits how wide the uncertainty is; this test audits whether
the number was ever pointed anywhere on purpose.

**The failure this prevents:** skepticism that fires in one direction is not skepticism, it is a
filter. Challenging an aggressive figure reads as rigour and challenging a conservative one reads as
advocacy, so the low class is the one nobody audits — and in a multiplicative chain it is the class
that silently compounds, because each member of it is individually defensible and the product of them
is never examined as a choice. What arrives is a verdict carrying the authority of a disciplined
process that was only ever pointed one way, reported as a property of the market rather than as a
stack of decisions nobody wrote down.

A worked example, invented end to end:

> A founder's paying-user target decomposes into seven multiplied terms: monthly reach, conversion to
> signup, activation, conversion to paid, monthly retention, referral share, and a seasonal drag.
> Each was filled at the low end to be safe — reach at the bottom of what the named channel supports,
> both conversion steps a few points under the sourced rate, referral share at zero, the drag applied
> to every month rather than to the two months it was evidenced in. Every one of the seven is
> defensible on its own, and every one sits at roughly half of what the evidence carries. Multiplied,
> they return the target as short by about two orders of magnitude, and the readout names a
> structural driver as binding.
>
> Run the both-directions test and five of the seven name no driver in either direction.
>
> **Readout:** *five inputs are unmodelled, not conservative — activation, referral share, the
> seasonal drag and both conversion steps. No verdict is computed until each one names its driver or
> takes its value from a home. The two that do name one stand: reach, at the channels and hours the
> founder stated, and retention, at the low end of the sourced category band, placed there because
> the product's valuable step still needs a call to reach.*
>
> Re-solved with the five given homes, the same target clears at the cheapest corner. Nothing about
> the market changed between the two runs. The chain had been pointed one way seven times, and the
> first readout reported the product of those seven choices as a finding about the category.

## The verdict names which driver binds, and by how much

The verdict is not a yes or a no. It is: the value each driver has to reach for the target to
land on its date, the value the evidence actually supports, and the ratio between them — with the
driver carrying the largest shortfall named as the one that binds.

A worked example, invented end to end:

> A founder wants a fixed monthly revenue figure twelve months out. The pricing dimension
> evidences a price band; the target divided by that band's midpoint needs roughly 220 paying
> customers *standing* at month 12. Run the customer chain backwards at the evidenced conversion
> and retention rates and that needs about 90 new trials a month, every month, from month 1. The
> channels the founder named, at the six hours a week they grilled to, evidence something nearer
> 15.
>
> **Readout:** *reach binds. The target needs roughly six times the monthly reach your channels
> evidence at six hours a week. Price clears at the band's midpoint and conversion clears at the
> benchmark; neither is what is stopping this.*

Two properties of that sentence are load-bearing:

- **It is actionable.** The founder now knows which of four numbers to argue with, and what
  would have to change. "Unreachable" gives them a mood.
- **It is falsifiable.** Every figure in it traces to a note, so a founder who thinks their
  channels do better than 15 has somewhere specific to push, and the push is settled by evidence
  rather than by who sounds more certain.

**Report the drivers that clear, not only the one that binds.** A readout that names the binding
driver alone reopens every number in the negotiation that follows, because the founder has no way
to tell which parts of the analysis they are still standing on.

**Re-check the binding driver after any change, because it moves.** Relieve reach and price often
binds next. A negotiation that keeps arguing about the first binding driver after it stopped
binding is arguing about a constraint that is no longer there.

**Three things can be wrong with a readout, and they are what a red team attacks:** the wrong
driver was named as binding, its evidenced range is wrong, or an assumption the flip test cleared
was given a narrower plausible range than it deserved. Each of the three is settled by re-running
the identity, which is the property that makes the verdict worth attacking at all — an objection
to a judgement can only be met with a counter-judgement.

## A binding driver that is policy makes the verdict conditional, not negative

**Classify the binding driver before the verdict is written anywhere.** Read its `kind` off the
driver-home table: **structural**, set by the category, **policy**, set by the founder and
re-settable, or **policy within a structural band**, where the band is structural and the position
inside it is not. Reach is the case that decides most runs, because reach is the driver that binds
most often and reach is policy — channels crossed with hours is a decision, and a decision is not a
ceiling.

**Where the binding driver is policy, the target is not unreachable — it is unreachable in the
stated configuration**, and the verdict says so in those words, with the policy variable named. The
run then goes directly to the counter-offer and the lever table with that variable solved: the
hours, the channel count or the price point the stated target would need. The readout names the
kind alongside the driver, so the founder reads *reach binds, and reach is policy* rather than
*reach binds* and supplies the second half themselves — usually as "so it cannot be done".

**A split driver makes the verdict conditional on where in its band the product sits, and the words
change with it.** Where retention binds, the finding is *this product as built does not retain well
enough for that target*, with the target under one changed position stated beside it — never *this
market does not retain*. The band is the market's half of the answer and it stands; the position is
the product's, and the plan's roadmap is the instrument that moves it. Price behaves the same way
one row up. **The failure this prevents:** filed as structural, a retention-bound miss reports a
category floor where a product outcome belongs, and the founder is told to leave a market when what
they were shown is the cost of shipping a shallower product than the target needs.

**This is the sibling of the rule below it, aimed at a different defect.** A driver that traces to
nothing makes the verdict *undetermined*, because the verdict would be resting on nothing; a driver
that is policy makes the verdict *conditional*, because it would be resting on a choice. Both tests
run before the verdict is stored, and for the same reason: afterwards it is a `claim` note carrying
a confidence letter, and neither defect is legible from the outside.

**The failure this prevents:** a negative verdict is the single output of this skill most likely to
make a founder stop, and a policy-bound one stops them over a decision they could revisit this week
— reported in the same frontmatter, with the same confidence letter, as an observation someone read
off a page and quoted. "Your target is unreachable" and "your target is unreachable at six hours a
week across two channels" are indistinguishable in a rendered plan, and only the second one is
true.

A worked example, invented end to end:

> A founder wants a paying-user count standing before a raise. Solved at the evidenced conversion
> and retention rates, the count needs roughly three times the monthly reach the founder's named
> channels support at their stated hours. Reach binds — and reach is **policy**, so the verdict is
> not that the count is unreachable.
>
> **Readout:** *reach binds, and reach is policy. At the channels and hours you stated, the count
> lands around a third of the way by the date. Conversion is structural and clears at the category
> benchmark. Retention clears too, and it is policy within a structural band — the band is the
> category's, and the product sits mid-band because the valuable step is reachable unassisted but
> the second one is not. Nothing about the product or the category is stopping this; the
> configuration is.*
>
> The lever table then carries the hours and the channel count that would close the gap, and what
> each of them costs.

**Relieving a policy driver is where "re-check the binding driver after any change" pays.** Solve
the hours lever in that example and reach stops binding; in this run conversion binds next, at a
value the category benchmark does not support at the stage the target counts. That second verdict
is **structural**, and it is the one worth telling the founder about. A run that stops at the first
binding driver hands the founder their own calendar back as if it were a finding about the market,
and never reaches the constraint they cannot decide their way out of.

**Retention is now among the drivers a solve may relieve, and it is the one the roadmap acts on
directly.** Reach is relieved by hours and channels, price by a chosen point in its band —
neither is something the product team builds. Retention's position is: it moves when the product
gets deeper, when the valuable part becomes reachable unassisted, or when the friction between
those two comes down, and those are roadmap items with owners and dates. So a retention-bound
verdict routes to the roadmap rather than to the calendar, and the lever it carries is a shipped
change with a stated size, guarded like any other input — a sourced base, a magnitude labelled
`measured`, `reference-class` or `assumed`, and the both-directions test on an `assumed` one. **The
failure the guard prevents here specifically:** churn is the divisor, so the retention lever is the
cheapest-looking row in any lever table, and an unguarded one lets the run solve the target by
choosing the improvement the target needs.

## A driver that traces to nothing makes the verdict undetermined, not negative

**A driver with no subject instrument tries the reference class before it degrades to an
assumption.** No `source` note, no benchmark and no grilled founder fact is not yet a dead end.
Where the driver is **structural** and `research/growth-curves.md` indexes it at the month the
target counts, the value is a `claim` resting on that indexed set — carrying the set's `stale_after`
and a `validated_by` naming the kill test that would overturn it. Only a driver the reference class
genuinely cannot speak to degrades: every policy driver, whose value the set is only ever allowed to
check, and any structural one the set does not index at the month in question.

**The failure skipping that rung causes:** invariant 11 caps a claim at its weakest input. Route the
only legitimate evidence a pre-launch company has through an `assumption` and every driver is weak by
construction — so every plan for a company that has not launched reads as unjustified, which is every
company at the moment the plan is worth writing. `market-analysis` builds the indexed reference class
precisely so a driver can take its value at a stated month; declining to let it is the skill refusing
its own instrument, and the founder is told the evidence is thin when what is thin is the routing.

**What survives that rung is a real assumption.** A driver value with no source and no
reference-class home is an `assumption` note carrying its `value` and its `sensitivity` — the fields
and the note shape are in
[vault.md](vault.md#the-assumption-note-is-what-you-would-believe-with-no-evidence). It is never
written into the identity as though it were sourced.

A worked example, invented end to end:

> A pre-launch product has no conversion data of its own, and the benchmark the research found
> measures conversion to signup while the target counts first paid. `research/growth-curves.md`
> indexes four comparables that disclose paid conversion, two of them at the month since origin the
> target counts.
>
> Conversion is **structural** and the set speaks to it at the right month, so it does not degrade.
> It enters as a `claim` resting on those two comparables, at the tighter of the two ranges they
> describe, with the set's `stale_after` and a `validated_by` reading: *a landing test at the stated
> price, run to a few hundred visitors; if paid conversion lands below the set's low end the driver
> is overstated and the verdict is re-solved.*
>
> Reach in the same run has no source either — and reach is **policy**, so no comparable is allowed
> to set it. It degrades to an `assumption` at the founder's stated channels and hours, and the flip
> test runs across its band. The two drivers were equally unsourced and are routed differently, and
> the thing that decided it was the `kind` column, not how thin the evidence felt.

**Then run the flip test, and run it before the verdict is written anywhere.** Re-solve the
identity at both ends of the assumption's plausible range:

- **The verdict is the same at both ends** — it stands. Record the assumption with its
  sensitivity and state in the verdict which figure was assumed, so a reader can see what the
  result did not depend on.
- **The verdict flips** — there is no verdict. The run returns *undetermined*, and returns with
  it the cheapest test that would settle the driver, named specifically, with its kill/continue
  threshold. That test becomes the assumption's `validated_by`.

**The failure a negative-instead-of-undetermined verdict causes:** a confident "no" resting on a
guessed conversion rate talks a founder out of something the evidence never spoke to — and the
vault's formality is what makes the guess look researched. A number in a `claim` note with a
derived confidence reads as established regardless of where it came from.

**The failure an unnamed test causes:** "undetermined" with no test attached is a shrug that cost
a full turn and closed nothing. The founder cannot act on it and cannot even schedule acting on
it. If you cannot name the cheapest test, the driver is not the problem — the framing is, and it
belongs in a `question` note with its gaps stated.

**Undetermined is a real answer and is delivered as one.** Hedging it into a soft negative
("probably a stretch") is the same failure with better manners: it lands on the founder as a no,
and it carries none of the evidence a no would have had to carry.

## A stated range on either axis is a rectangle, solved at its corners

A target stated as a value range over a date range is two ranges, and the pair describes a
rectangle rather than a point. **Solve the identity at its corners, never at its centre.** The
corners are not equally hard, and which ones clear *is* the verdict:

- **the cheapest corner** — the low value at the late date;
- **the hardest corner** — the high value at the early date;
- **the two mixed corners** — low value early, high value late. These are the ones that separate a
  value problem from a date problem, because each moves one axis at a time.

A ranged target therefore does not return one answer. It returns **which corners clear and which
do not, with the binding driver named per corner** — strictly more actionable than a single
verdict, because it tells the founder which part of their own ambition is the problem and leaves
the rest standing. *The low end at the late date clears on an evidenced multiple; the high end at
the early date needs a multiple nothing in the reference class supports* is a sentence a founder
can act on. "Undetermined" over the whole rectangle is not.

**The failure collapsing a range to its midpoint causes:** a midpoint is a number neither end of
the range asserts, entering the identity carrying the authority of both — the same defect this
file already rejects when a founder's instinct and an evidenced range get averaged. It does more
damage here, because the collapse destroys the finding as well as the number: a rectangle where
three corners clear and one does not reads at its centre as a single clean yes, and the corner
that fails is usually the one the founder was actually aiming at.

**A stated range is not an assumption, and it does not trigger the flip test.** [A driver that
traces to nothing](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative)
returns *undetermined* when re-solving at both ends of an **assumption's** plausible range moves
the verdict. A stated target range is not an unevidenced input — it is the founder's own intent,
chosen deliberately, and nobody has to source it. Conflating the two returns *undetermined* for
every ranged target by construction: a rectangle drawn across a real decision boundary is exactly
one whose corners disagree, and that disagreement is the finding rather than a gap in the
evidence.

**The two tests compose, because they run on different things.** The flip test runs on **evidence
uncertainty** — the plausible range of a driver nobody sourced. The corner solve runs on **stated
intent** — the range the founder chose. So each corner is a solve in its own right and gets its
own flip test on the drivers inside it: a corner whose verdict flips across an assumption's band
returns *undetermined for that corner*, with its own cheapest test, while its neighbours still
return clean verdicts. A run that reports one undetermined for the whole rectangle has thrown away
every corner that was settled.

**The late end of a date range is not the easy end.** It is cheaper on ARR — the reference-class
decay has more months to compound, so the revenue term clears more easily — and *more exposed on
the multiple*, because the window under the band is structural and time-varying. A date five years
out assumes the window that produced today's comparable exits is still open in five years, and
nothing evidences that. The two axes pull against each other rather than relaxing together, so a
founder who widens the date to make the target easier has bought ARR headroom by taking on window
risk nobody told them about. Surfacing that trade is what the [shelf life on the multiple's
claim](#the-multiple-usually-binds-and-it-is-always-the-least-evidenced-driver) is for: a cheapest
corner whose multiple claim outlives the plan's own horizon gets reported as the safest corner,
which is the reverse of what is true.

## The multiple usually binds, and it is always the least evidenced driver

In an exit identity the multiple is usually the binding driver and always the least evidenced one,
so the two rules above fire on it hard rather than needing new ones. Nothing here is a new test —
this is where the existing tests land once the identity has a multiple in it.

**An exit verdict solved at a single assumed multiple is [a driver that traces to
nothing](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative), applied to
the term that decides the answer.** An unsourced multiple is an `assumption` note carrying its
`value` and its `sensitivity` like any other, and the flip test runs across its plausible band.
Flip it and the verdict moves: a stated exit value that clears at the band's top and misses at its
bottom is not a verdict, it is the band being reported as an answer. The run returns
**undetermined**, with the cheapest test named.

**The cheapest test is a comparable-exit reference class, not a founder interview.** The founder
cannot know the multiple — it is set by buyers they have not met, at a moment that has not
happened — so asking returns their hope wearing the authority of an answer to a question that was
formally asked. That is worse than the assumption it replaced: an `assumption` note carries its
sensitivity and invites the flip test, while a founder's figure enters as `[F#]` and reads as
grilled fact. What settles it is the disclosed acquisitions in the category, indexed the way
`research/growth-curves.md` indexes anything else — to the acquired company's growth slope at the
moment of sale — with the multiple each one implies and a kill/continue threshold stated against
them.

A worked example, invented end to end:

> A founder wants a stated exit value inside four years. The revenue identity, solved at the sale
> date on the evidenced driver ranges, gives an ARR band the plan plausibly reaches. Dividing the
> stated exit value by that band needs a multiple near the top of what the comparable set supports
> at the slope this roadmap implies. Re-solve at the bottom of the multiple band and the same ARR
> lands nearer a third of the stated value.
>
> **Readout:** *undetermined. The verdict flips across the multiple's plausible band, and the ARR
> term is not what is in question — it clears at both ends. The cheapest test is a comparable-exit
> reference class: the disclosed acquisitions in this category, indexed to the acquired company's
> growth slope at the moment of sale, with the multiple each one implies. Kill/continue: if the
> comparable set's implied multiple at your roadmap's slope sits below the multiple this exit
> value needs, the stated value does not clear at any ARR this plan reaches by the date — and what
> binds is the slope, not the revenue.*

**The window under the band is structural and time-varying, so the multiple's claim needs a
`stale_after` that lands inside the plan's horizon.** Every claim carries one
([vault.md](vault.md#every-note-carries-these-six-fields)), and for every other driver in this
file the field is routine bookkeeping: conversion at a stage and retention per period drift
slowly. The multiple does not. A multiple assumed three years out assumes the window that produced
today's comparable exits is still open on the sale date, and that assumption expires on a schedule
of its own that nothing in the plan touches. Declare the shelf life at the point the comparable
set stops being the same buyers under the same conditions — inside the target's horizon, never on
it or past it. This is the first driver in this file whose `stale_after` is load-bearing rather
than administrative.

**The failure a horizon-length `stale_after` causes:** the claim comes up for re-checking for the
first time on the date the plan was to be executed against it, which is the one date the answer
stops being useful. Everything built on that multiple — the roadmap aimed at a named acquirer, the
milestone a raise was sized against — ran the whole way on a band nobody re-drew, and it read
exactly like a band re-drawn last week. A claim inside its shelf life and a claim whose shelf life
was set too generously are the same note.

## A verdict is capped twice and never asserted at high confidence

Invariant 11 already caps a verdict at its weakest input: `confidence = min(confidence_own, every
rests_on target)`. A verdict resting on a Low-confidence sizing figure cannot be an assured
"impossible", because the derivation will not let it.

**On top of that derivation, a verdict's `confidence_own` is never `H`.** The ceiling is a
property of the type of statement, not of how good the inputs were, so it applies even to a
verdict whose every driver is sourced and current. The two limits compose: the ceiling can only
ever lower the stored value, never raise it.

**The failure this prevents:** a verdict is a forecast about a future nobody has run, and the
vault renders it in exactly the shape of a cited observation — same frontmatter, same confidence
letter, same authority in a rendered document. Without the second ceiling, a plan shows
*reachable (H)* beside *market size (H)* and tells its reader the two were established the same
way. One was read off a page and quoted; the other is arithmetic over ranges about an unrun
future. A reader with no way to tell them apart will act on both equally, and the one that fails
them is the forecast.

## Two verdicts, because a late-only verdict wastes a whole research run

**The provisional verdict** runs after the Phase 0 dossier and the grill, before the research
fleet spends anything. It is recorded as an `assumption` note carrying its `sensitivity` — never a
`fact`, and never a `claim` — so nothing downstream can cite it as researched. It is cheap
precisely because nothing has been spent yet and changing the target is still free.

**The evidence-backed verdict** runs after research and before the plan drafts, as a `claim` note
resting on the target `fact` plus the sizing, pricing-floor and resource facts. It may overturn
the provisional verdict in either direction, and **saying so explicitly is part of its output** —
it carries `supersedes` and `supersedes_reason` pointing at the provisional assumption, and that
note flips to `status: superseded`.

**The failure a late-only verdict causes:** a founder states a target, waits through a full
research run, and is then told the number was never reachable. **The failure the late verdict
prevents in turn:** a cheap gut-check talks a founder down from a target the research would have
supported. That second failure is why the provisional verdict is an assumption rather than a
finding — the researched one has to be free to overturn it, and it can only do that if nothing
was built on the first.

## The nearest reachable target is a solve, not a smaller number chosen by feel

Once hours, capital and price are all movable, "nearest" is undefined: every one of them can be
moved far enough to make any target reachable, so a nearest-target picked without a rule is
whichever lever the writer happened to reach for first. That is not a counter-offer, it is a
preference.

**The rule: hold the founder's stated resources fixed and the evidenced driver ranges fixed, and
solve the same identity for the outcome actually achievable by the stated date.** That solved
outcome is the counter-offer, and nothing else is.

- **The date is held, not solved for — and a stated date range is held as stated.** The stated
  number arriving later is a legitimate second offer, but it answers a different question — it
  belongs in the lever table below with hours, capital and price, never folded into the
  counter-offer. Blending the two produces an offer the founder agrees to without knowing which of
  the two things they just agreed to move. Where the date was stated as a range, hold the whole
  range: solve the counter-offer at each of its ends rather than collapsing it to a point or a
  midpoint, because a midpoint is a date the founder never named. A date **outside** the stated
  range remains a lever, exactly as a later date is against a stated point.
- **Solve at both ends of every evidenced range, and present a band — one band per corner.** A
  single-point counter-offer implies a precision the evidence does not have, and a founder who
  lands inside the band but below that point reads it as a miss against a target the evidence
  never pinned to one number.
- **Keep the founder's stated range and the evidence's range visibly apart in the readout.** The
  first is intent and the second is uncertainty, and they arrive as the same shape — an interval
  with two ends. Merged into one interval, the founder reads the whole width as their own ambition
  being narrowed, when half of it is the evidence admitting what it does not know; and the corner
  structure disappears with it, so nobody can tell which end of the ambition the analysis actually
  reached.
- **The counter-offer assumes nothing the founder has not already stated.** The moment it quietly
  assumes more hours it stops being reachable on the stated resources, which is the one property
  that made it the counter-offer.

## The levers are counterfactuals, kept apart from the counter-offer

The negotiation output is three parts, in this order, visibly separated:

1. **The stated target, and why it does not clear** — the binding driver and the size of the gap,
   in the readout sentence above.
2. **The nearest reachable target** — the solve, as a band, on the founder's stated resources.
3. **The levers** — each with the value it would have to reach, and what that costs.

| Lever | Stated now | Would have to become | What that costs, and what it assumes |
|---|---|---|---|
| hours/week | the grilled figure `[F#]` | solved from the identity | the constraint the founder gave, in their words |
| capital | the grilled figure `[F#]` | solved from the identity | what it buys, and how long before it shows |
| price | the evidenced band | solved from the identity | what the willingness-to-pay evidence says at that point |
| date | the stated date | solved from the identity | what the delay costs — runway, a window, a competitor |

**For an exit target the lever set is different, because hours, capital and price all move ARR and
ARR is not what binds.** Those three still act, one term down, through the left side of the
identity — but a table offering only them answers the question the founder did not ask, using the
term the verdict was least sensitive to. The exit levers are slope, acquirer legibility and date:

| Lever | Stated now | Would have to become | What that costs, and what it assumes |
|---|---|---|---|
| growth slope at the sale date | the slope the plan's own projection implies, placed against the indexed set | solved from the identity | what has to be spent to hold that slope *through* the sale month — a slope held for a quarter and a slope standing on the date are different commitments, and only the second one is in the identity |
| acquirer legibility | the acquirers the dossier's seam argument actually names, and how many | solved from the identity — the strategic-necessity position and the buyer count the required multiple takes | the roadmap items that make the product visibly the patch for a named buyer, and what those items displace |
| date | the stated date, or the stated date range held at both ends | solved from the identity | what the delay costs — runway, a competitor, and the window, which is the one term a delay moves against the founder rather than for them |

**Every lever value is solved from the same identity with the other drivers held at their
evidenced values.** A lever line produced any other way is a wish with a number attached, and it
is the line a founder will actually try to execute.

**A lever whose required value contradicts something already established is shown with the
contradiction named, not quietly dropped.** A price above the band the willingness-to-pay
evidence supports, hours above what the founder said they have, a multiple above anything the
comparable set has paid at that slope — all of them stay in the table, labelled as what they are.
Dropping them reads as "there is nothing you can do"; including them silently reads as a plan.

**Levers stay out of the counter-offer.** Fused, the founder agrees to a number and a commitment
in a single word — and six weeks later remembers only the number, while the plan is built on the
commitment.

## The founder chooses, and the superseded target keeps its reason

A negative verdict does not stop the run and does not quietly substitute a smaller number.
Report-and-stop leaves a founder with a "no" and no path, which is the opposite of what this
skill is for. Planning against the stated number with a caveat buried somewhere makes every
downstream milestone fiction — the correction was needed before the plan was built on it, not
inside it.

The founder picks: the counter-offer, the stated target with a lever moved, or the stated target
unchanged and explicitly at risk. Whichever they pick, the plan is built against it and the
original stays visible as the thing that was tested and failed.

**In the vault, a renegotiated target is a supersession, under the standing two-edit rule**
([vault.md](vault.md#every-note-carries-these-six-fields)). The settled target is a new `fact`
note resting on the grill's `source` note, and it is the note that carries the reason. Following
that rule is what makes "wanted this, settled on that, and here is why" a single query rather
than an archaeology exercise.

**`retracted` is for a target abandoned with no replacement** — a founder who decides they do not
want a target at all. Writing `retracted` where a replacement exists severs the link between the
two numbers, and the ledger then records that the target died without recording what it became,
which is exactly the history the renegotiation existed to keep.

**The verdict `claim` on the superseded target is not deleted either.** It keeps its `used_in`,
so the plan can show what was tested and what it failed on — invariant 14, applied to the one
number a founder is most likely to want re-litigated later.

## Computing a verdict: the checklist

1. **Write the identity** for the target's shape, in full, before any value goes into it —
   including the exit shape, whose left term is one of the other identities solved at the sale
   date and whose right term is a multiple band. **Write the target's stated ranges beside it**,
   on either axis, exactly as stated.
2. **Name the reference class before any driver takes a value from it**, classify it `structural`,
   home it to `research/growth-curves.md`, and flip it across the alternatives a reasonable person
   would argue for. A verdict that moves between two defensible classes is *undetermined*, with both
   classes named and the cheapest test that settles which one the subject is in. The class records
   what it was inferred from as part of naming it, and where it was read off the subject's own price
   point, packaging or delivery, that dependency is named wherever the class is named, because it is
   what makes step 8 fire.
3. **Classify each driver from the table's `kind` column** — `structural`, `policy`, or `policy
   within a structural band` — before any verdict is written. That column decides two things: where
   the value may come from — the indexed set sources a structural driver and only checks a policy
   one, and on a split driver it sources the band and checks the position — and what a negative
   verdict may conclude, since a verdict whose binding driver turns out to be policy is negative for
   the stated configuration only and is written in those words. Price and retention are the two
   split drivers, and a split one binding is conditional on the position, never on the band. For an
   exit target it runs over the multiple's four inputs too: slope and the named acquirer are policy,
   scarcity and the bidder count are structural.
4. **Fill each driver from its named home** — price, conversion, retention, reach — recording any
   founder-instinct divergence rather than averaging it, and any disagreement between a
   broad-population figure and a named-company value the same way. A split driver is filled twice,
   band then position, and the position names what in the built product places it there. Every value
   taken from the indexed set carries the survivorship qualifier wherever it is reported.
5. **Try the reference class before degrading** — a structural driver with no subject instrument
   that the indexed set reaches at the target's month is a `claim` resting on that set, with its
   `stale_after` and a `validated_by` kill test. Only what the set cannot speak to becomes an
   `assumption` with its `value` and `sensitivity`, and none of them enters the identity as though it
   were sourced.
6. **Run the both-directions test on every value in the identity**, before the flip test and
   whichever way the value points: each names the driver behind it in the direction it sits. A low
   figure with none named is labelled **unmodelled, not conservative**, and takes a driver or a home
   before anything is solved. The flip test does not catch these — a pessimistic value with no driver
   is a well-formed `assumption` and passes it clean. **An optimistic value gets the mirror of the
   same test**, and the two it fires on hardest are a delivered-value figure and a retention
   improvement: each carries a sourced base and a magnitude labelled `measured`, `reference-class` or
   `assumed`, and an `assumed` one is solved at both ends of its range like any other. Both flatter
   the thing the founder built, which is what makes them easy to write and hard to challenge, and
   the retention one moves the answer furthest because churn is the divisor.
7. **Run the flip test** at both ends of every assumption's plausible range — evidence
   uncertainty only, never the target's own stated range. If the verdict flips, stop: return
   *undetermined* plus the cheapest test that settles it, and name the threshold.
8. **Re-flip the class where the input it was inferred from has settled differently** — a class
   read off the subject's own price point, packaging or delivery is re-flipped against whatever
   pricing, packaging and delivery decision is settled at verdict time, and again when a decision
   settled later lands on a different packaging than the class was inferred from. A changed class
   is never annotated onto the verdict: the drivers it sources are re-filled at step 4 and the
   identity is solved again from there.
9. **Solve for the required value of each driver** at the target date, and name the one that
   binds — with the size of its gap, its kind, and with the drivers that clear stated too. Where
   either axis was stated as a range, solve at the rectangle's corners and report which clear,
   with the binding driver named per corner; never solve at a midpoint.
10. **Cap the confidence twice**: derive it per invariant 11, then hold `confidence_own` at `M` or
    below.
11. **If it is negative, solve the counter-offer** on the stated resources and evidenced ranges,
    with the date held, as a band — then build the lever table separately.
12. **Record it** — an `assumption` before research, a `claim` after — and supersede the earlier
    verdict rather than editing it.
