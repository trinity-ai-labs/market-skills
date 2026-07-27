# The target verdict — decomposed into drivers, computed, then negotiated

A target is a concrete outcome plus a date: a monthly revenue figure by a month, a paying-user
count before a raise, a salary replaced inside eighteen months. This file is the method for
judging one — how the outcome decomposes into drivers, where each driver's value comes from,
what the verdict says, what it says when the evidence cannot carry a verdict at all, and what
happens when the answer is no.

It sits behind invariant 16 exactly as [vault.md](vault.md) sits behind invariants 7–15: the head
of `SKILL.md` carries the rule, this file carries the detail, and the phases point here rather
than restating any of it. That split is not tidiness. Compaction re-attaches only the head of a
skill file, so a method written inside Phase 3 is not in context when Phase 3 runs.

## Contents

- [The outcome decomposes into drivers before any number goes into it](#the-outcome-decomposes-into-drivers-before-any-number-goes-into-it)
  - [Each driver takes its value from a named place in the corpus](#each-driver-takes-its-value-from-a-named-place-in-the-corpus)
- [The verdict names which driver binds, and by how much](#the-verdict-names-which-driver-binds-and-by-how-much)
- [A binding driver that is policy makes the verdict conditional, not negative](#a-binding-driver-that-is-policy-makes-the-verdict-conditional-not-negative)
- [A driver that traces to nothing makes the verdict undetermined, not negative](#a-driver-that-traces-to-nothing-makes-the-verdict-undetermined-not-negative)
- [A verdict is capped twice and never asserted at high confidence](#a-verdict-is-capped-twice-and-never-asserted-at-high-confidence)
- [Two verdicts, because a late-only verdict wastes a whole research run](#two-verdicts-because-a-late-only-verdict-wastes-a-whole-research-run)
- [The nearest reachable target is a solve, not a smaller number chosen by feel](#the-nearest-reachable-target-is-a-solve-not-a-smaller-number-chosen-by-feel)
- [The levers are counterfactuals, kept apart from the counter-offer](#the-levers-are-counterfactuals-kept-apart-from-the-counter-offer)
- [The founder chooses, and the superseded target keeps its reason](#the-founder-chooses-and-the-superseded-target-keeps-its-reason)
- [Computing a verdict: the checklist](#computing-a-verdict-the-checklist)

## The outcome decomposes into drivers before any number goes into it

Every target is an arithmetic identity waiting to be written down. Write the identity first, in
full, before a single value goes into it — because the identity is what makes the verdict
checkable by someone who disagrees with it.

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

**The failure the identity prevents:** without it, "can we get to this number" is answered by
judgement about the number as a whole, and judgement about a whole number is unarguable. Nobody
can tell you which part of it they think is wrong, so nobody does — and a verdict nobody can
attack is one nobody can trust either.

### Each driver takes its value from a named place in the corpus

A driver value is only a driver value if you can say where it came from. Every one of them has a
home, and the home is not the same for all four:

| driver | where its value comes from |
|---|---|
| price | the market analysis's pricing / willingness-to-pay dimension, as a `claim` with its subject from `_vocab.yml`, plus the founder's price instinct `[F#]` where the two differ |
| conversion | a sourced category benchmark — a `source` note with its verbatim `quote` and its `url` — at the stage the target counts |
| retention | the same, and it is per-period, so the period is part of the value |
| reach | what the founder's own channels support at their grilled hours and budget: the resource facts from the grill crossed with the channel's evidenced throughput |

**Where the founder's instinct and the evidenced range disagree, record the divergence — never
average them.** The midpoint of a founder's hope and a benchmark is a number neither of them
asserts, and it enters the identity carrying the authority of both.

**Reach is the driver a sizing figure will happily impersonate, and that substitution is the
single commonest way an unreachable target clears.** SAM is not reach. Reach is how many of the
right people this founder's channels put in front of the product per month, at the hours and
budget they stated in the grill. A market of millions and a founder with six hours a week and no
audience are both true at once; only one of them is in the identity.

**A driver taken from the plan's own projection is not evidence.** The financial model is
downstream of the verdict — feeding its output back in makes the verdict a check on its own
arithmetic, which it will always pass.

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
driver-home table: **structural**, set by the category and the product, or **policy**, set by the
founder and re-settable. Reach is the case that decides most runs, because reach is the driver that
binds most often and reach is policy — channels crossed with hours is a decision, and a decision is
not a ceiling.

**Where the binding driver is policy, the target is not unreachable — it is unreachable in the
stated configuration**, and the verdict says so in those words, with the policy variable named. The
run then goes directly to the counter-offer and the lever table with that variable solved: the
hours, the channel count or the price point the stated target would need. The readout names the
kind alongside the driver, so the founder reads *reach binds, and reach is policy* rather than
*reach binds* and supplies the second half themselves — usually as "so it cannot be done".

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
> lands around a third of the way by the date. Conversion and retention are structural and both
> clear at the category benchmark — nothing about the product or the category is stopping this; the
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

## A driver that traces to nothing makes the verdict undetermined, not negative

Any driver value that cannot be traced to a source is an `assumption` note carrying its `value`
and its `sensitivity` — the fields and the note shape are in
[vault.md](vault.md#the-assumption-note-is-what-you-would-believe-with-no-evidence). It is never
written into the identity as though it were sourced.

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

- **The date is held, not solved for.** The stated number arriving later is a legitimate second
  offer, but it answers a different question — it belongs in the lever table below with hours,
  capital and price, never folded into the counter-offer. Blending the two produces an offer the
  founder agrees to without knowing which of the two things they just agreed to move.
- **Solve at both ends of every evidenced range, and present a band.** A single-point
  counter-offer implies a precision the evidence does not have — and a founder who lands inside
  the band but below that point reads it as a miss against a target the evidence never pinned to
  one number.
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

**Every lever value is solved from the same identity with the other drivers held at their
evidenced values.** A lever line produced any other way is a wish with a number attached, and it
is the line a founder will actually try to execute.

**A lever whose required value contradicts something already established is shown with the
contradiction named, not quietly dropped.** A price above the band the willingness-to-pay
evidence supports, hours above what the founder said they have — both stay in the table, labelled
as what they are. Dropping them reads as "there is nothing you can do"; including them silently
reads as a plan.

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

1. **Write the identity** for the target's shape, in full, before any value goes into it.
2. **Fill each driver from its named home** — price, conversion, retention, reach — and record
   any founder-instinct divergence rather than averaging it.
3. **Write every unsourced driver as an `assumption`** with its `value` and `sensitivity`. None of
   them enters the identity as though it were sourced.
4. **Run the flip test** at both ends of every assumption's plausible range. If the verdict flips,
   stop: return *undetermined* plus the cheapest test that settles it, and name the threshold.
5. **Solve for the required value of each driver** at the target date, and name the one that
   binds — with the size of its gap, and with the drivers that clear stated too.
6. **Cap the confidence twice**: derive it per invariant 11, then hold `confidence_own` at `M` or
   below.
7. **If it is negative, solve the counter-offer** on the stated resources and evidenced ranges,
   with the date held, as a band — then build the lever table separately.
8. **Record it** — an `assumption` before research, a `claim` after — and supersede the earlier
   verdict rather than editing it.
