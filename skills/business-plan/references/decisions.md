# Decisions — presenting a fork, recording the choice, re-surfacing it when the basis moves

The grill asks the founder what they know. This file covers what happens when the answer is
"I don't know what that means" — which is the honest answer to half the questions that decide
a plan's shape, and the one the grill has no move for.

A founder who cannot say whether they want a venture-scale outcome is not withholding an
answer. They are being asked to pick between futures they have never seen priced. The move is
not to press harder and it is not to guess on their behalf: it is to lay out the fork with the
evidence, the costs, and a recommendation whose strength is stated in the sentence, then record
what they chose and what would make the choice wrong.

This document is the format for that. It composes with the vault: the record it produces **is**
the `decision` note defined in [vault.md](vault.md), with additional fields — not a second
schema.

## Contents

- [A fork the founder cannot answer becomes a brief, and most forks do not](#a-fork-the-founder-cannot-answer-becomes-a-brief-and-most-forks-do-not)
- [The forcing function is the intervention, and it is the part users like least](#the-forcing-function-is-the-intervention-and-it-is-the-part-users-like-least)
- [The ten sections of a decision brief, in this order](#the-ten-sections-of-a-decision-brief-in-this-order)
- [The option grid: mandatory columns, mandatory rows, one page](#the-option-grid-mandatory-columns-mandatory-rows-one-page)
  - ["Do nothing" is a column, not a footnote](#do-nothing-is-a-column-not-a-footnote)
  - [Seven rows are mandatory; the founder's own questions are the rest](#seven-rows-are-mandatory-the-founders-own-questions-are-the-rest)
  - [Equal detail, both frames, every cell filled](#equal-detail-both-frames-every-cell-filled)
- [Rank the criteria; never score them](#rank-the-criteria-never-score-them)
  - [Why AHP is rejected](#why-ahp-is-rejected)
  - [Why Analysis of Competing Hypotheses is rejected](#why-analysis-of-competing-hypotheses-is-rejected)
- [Likelihood and confidence are two fields that never fuse](#likelihood-and-confidence-are-two-fields-that-never-fuse)
- [The verb carries the evidence grade](#the-verb-carries-the-evidence-grade)
- [Three Low assumptions bar strong-recommendation language](#three-low-assumptions-bar-strong-recommendation-language)
- [The record extends the vault's decision note; it does not replace it](#the-record-extends-the-vaults-decision-note-it-does-not-replace-it)
  - [The fields this document adds](#the-fields-this-document-adds)
  - [The one block-scalar field this document asks for](#the-one-block-scalar-field-this-document-asks-for)
  - [The founder's reasoning is kept verbatim and separate](#the-founders-reasoning-is-kept-verbatim-and-separate)
  - [What happened and whether the reasoning was right are different questions](#what-happened-and-whether-the-reasoning-was-right-are-different-questions)
- [Four triggers re-surface a decision, and the output is a diff](#four-triggers-re-surface-a-decision-and-the-output-is-a-diff)
- [A worked fork, end to end](#a-worked-fork-end-to-end)
- [Writing a decision brief: the checklist](#writing-a-decision-brief-the-checklist)

## A fork the founder cannot answer becomes a brief, and most forks do not

A decision brief is ten sections and a turn of the founder's attention. Spending that on every
open question turns the grill into a form, which is the shape [grill.md](grill.md) exists to
avoid.

**Raise a fork to a brief when both hold:**

1. The founder could not answer it after one grill turn that carried a recommended default and
   its reasoning — not "they hesitated", but "the default did not give them anything to push
   against, because they cannot evaluate it."
2. The answer changes more than one downstream section of the plan.

Everything else stays a grill question with a default to flip.

**The failure this prevents:** a skill that briefs every question spends the founder's attention
on decisions that do not move the plan, and by the time it reaches the one that does, the
founder is skimming. Attention is the budget, and the brief is the expensive instrument.

**The failure the opposite direction prevents:** pressing a founder for an answer they cannot
form produces one anyway. People answer questions. The answer is then recorded as a founder
fact, cited through the plan, and defended by a document that has no idea it rests on a guess
made under social pressure.

## The forcing function is the intervention, and it is the part users like least

Read this section before changing anything else in this file.

**A pros-and-cons layout is an explanation.** That is not a metaphor about it — a grid of
options with reasons under each is structurally an explanation of a recommendation, and
explanations raise a reader's reliance on the recommendation they accompany. They raise it when
the recommendation is right and they raise it by a similar amount when it is wrong, because
what the reader is responding to is the legibility of the layout, not the quality of the
reasoning. A clean grid feels like something that has been checked.

So the format that makes a fork readable to a non-expert also makes a wrong call harder for
that non-expert to reject. Every guardrail in this file exists because of that one property.

**The intervention with evidence behind it is a cognitive forcing function**: make the reader
engage with the problem before the recommendation is revealed. In this format that is concrete
and structural, not a tone of voice:

- Section 4 asks the founder to **rank the criteria** — and the ranking is captured before the
  recommendation is shown.
- Sections 5 through 8 lay out options, costs, what must be true, and failure modes.
- Section 9 is the **first place a recommendation appears**.

**This is the part users like least, and that is not a bug report.** It costs a turn. It feels
like being made to do homework by something that already knows the answer. The founder who
asked "just tell me what to do" will ask again, and every usability instinct — including a
future maintainer's, including yours — says to move the recommendation to the top and let the
grid be optional supporting detail.

**Do not.** Here is what breaks, stated so a later reader cannot mistake this rule for
ceremony:

- Move the recommendation above the criteria ranking and the founder evaluates the
  *recommendation* instead of the *fork*. The grid stops being a comparison and becomes
  justification for a conclusion already read.
- The criteria then get elicited — if at all — after the answer is known, so they arrive
  already bent toward it. The one signal that catches a wrong recommendation is a founder whose
  ranked criteria do not match it, and that signal cannot fire if the criteria were formed
  downstream of the answer.
- The friction is the only thing in the format that is *load-bearing against the format's own
  persuasiveness*. Removing it does not make the brief faster to read. It makes it faster to
  agree with, which is a different thing that looks identical in a usability test.

**The test that separates a decision aid from a steering system**: a good aid moves choices
toward **values-congruence**, not in a fixed direction. Judge a brief by whether the founder's
choice matches the constraints they stated — never by whether they took the recommendation. A
brief format that produces near-total recommendation-acceptance is failing this test, not
passing it, and a run of briefs where the founder never once diverged is evidence the forcing
function has stopped working.

**If you must cut something for length, cut the recommendation, not the friction.** An option
grid with no recommendation is still a decision aid. A recommendation with no forcing function
in front of it is a sales page with citations.

## The ten sections of a decision brief, in this order

The order is the format. Sections 1–8 come before any recommendation exists on the page.

Headings below are literal — write them as shown, in the founder's second person, and do not
renumber, merge, or reorder them.

**1. `## The fork`** — one sentence naming what is being decided, and one naming what is *not*
being decided here. The second sentence is not padding: a fork stated without its boundary
collects every adjacent worry, and the founder answers a bigger question than the one that was
asked.

**2. `## Why it is live now`** — what forces the decision on this clock, and what specifically
degrades if it is deferred one more quarter. If nothing degrades, say so plainly and offer to
defer; a brief that manufactures urgency is steering.

**3. `## What you have already told me`** — the founder's own constraints, quoted as `[F#]`
facts from the founder brief, before any option appears. Their words, not a paraphrase. This is
what section 4's ranking gets checked against, and what section 9's recommendation is judged
against later.

**4. `## Rank these before you read on`** — 3 to 7 criteria in the founder's own words, offered
unordered, with an explicit ask to put them in order. **Stop here and wait for the ranking.**
The ranking is recorded in `criteria` before the rest of the brief is shown.

> Below three criteria there is no comparison to make; above seven the ranking is arbitrary at
> the tail and the extra entries contribute noise that looks like precision.

**5. `## The options, side by side`** — the option grid. Rules in
[the next section](#the-option-grid-mandatory-columns-mandatory-rows-one-page).

**6. `## What it costs to be wrong`** — per option: what it costs to undo, how long you are
locked in, and what is unrecoverable. Plus one row for the do-nothing column: what another
quarter of not choosing costs. Reversibility is the single input a non-expert most reliably
under-weights, and it is not comparable inside a grid cell, which is why it gets its own
section.

**7. `## What has to be true`** — the load-bearing assumptions, one line each, each with its
confidence tag. Load-bearing means: if this is false, a different option wins. An assumption
whose falsity does not change the choice is not load-bearing and does not belong here. This
list is what the [hard gate](#three-low-assumptions-bar-strong-recommendation-language) counts.

**8. `## What goes wrong, and how you would know early`** — per option, the most likely failure
and the leading indicator that would show it in weeks rather than quarters. An option with no
early indicator is an option you cannot course-correct out of, and saying so is more useful
than the failure mode itself.

**9. `## What we recommend, and how strongly`** — the first appearance of a recommendation.
Carries, in this order: the recommended option; the [register](#the-verb-carries-the-evidence-grade)
matched to its evidence grade; the [likelihood and the confidence as two separate
statements](#likelihood-and-confidence-are-two-fields-that-never-fuse); the reasoning tied to
the founder's **top-ranked** criterion by name; and, when the recommendation does not serve
that top criterion best, an explicit sentence saying so.

**10. `## What would change this answer`** — the reopen trigger, written as if-then with a
named metric and a threshold, not as a mood. "If direct acquisition cost per account exceeds
first-year contract value for two consecutive quarters" fires. "If the economics stop working"
does not, because nobody ever agrees that today is the day.

> Vague triggers are the reason decision records get filed and never re-read. A specific
> trigger with a number attached is many times more likely to actually fire, because firing
> becomes an observation rather than a judgement call. The switch-trigger table in
> [strategy-sim.md](strategy-sim.md) is the same instrument applied to a modelled path — pick
> the threshold in the calm moment, so the tense moment is execution rather than argument.

## The option grid: mandatory columns, mandatory rows, one page

Options are columns. The founder's questions are rows. One page.

If it does not fit on one page, there are too many options or too many rows. **Cut options,
never detail** — a grid with five thin columns steers harder than a grid with three full ones,
because thinness is invisible to a reader who has nothing to compare it against.

### "Do nothing" is a column, not a footnote

**Every grid carries a do-nothing column, with the same detail as every other column.** It is
mandatory, and it is written as *what the founder is actually doing today*, in their words —
"keep taking whichever orders arrive", "keep building on evenings and decide when someone
forces it" — never as the phrase "do nothing", which reads as a non-option and is therefore not
one.

The record mirrors this: `do_nothing` names the option verbatim, and the same string appears in
`options`.

**The failure this prevents:** a grid of three active options presents a decision as already
made — the founder is choosing *how* to act, and the choice to keep going as-is was removed
before they saw the page. That removal is usually not a decision anyone took. It is an artifact
of listing what could be done, and it is the single easiest way to steer a brief while
believing you laid out the fork honestly. For a founder with short runway, the status quo is
frequently the correct answer for another quarter, and it is the only option whose costs they
already understand.

### Seven rows are mandatory; the founder's own questions are the rest

| row | what belongs in the cell |
|---|---|
| What would I actually do first, this week? | The first concrete action, not the strategy |
| What does it cost — money, and hours a week? | Both units; hours is the one founders under-count |
| How long until I know if it is working? | Time to the first real signal, not to the outcome |
| What do I give up? | What this option forecloses, including the other options |
| What has to be true for this to work? | The load-bearing assumptions for this column only |
| What does the evidence say, and how strong is it? | The finding and its confidence tag together |
| What is the worst realistic outcome? | Realistic, not worst-conceivable |

**Then add every question the founder asked during the grill, verbatim as a row.** Not
paraphrased into the analyst's vocabulary.

**The failure this prevents:** a grid built only from the standard rows answers the analyst's
questions well and the founder's not at all. The question a founder actually decides on is
frequently one nobody thought to standardise — "would I have to move?", "does this mean I stop
writing code?" — and it goes unanswered in a document that otherwise looks complete. A grid
that answers everything except the deciding question sends the founder away to decide on vibes,
with a well-made artifact in hand that had no influence at all.

### Equal detail, both frames, every cell filled

Three formatting rules, each of which is a steering vector when broken:

**Equal font, equal ordering, equal detail across every column.** An option described in two
words next to one described in two sentences has already been rejected by the layout, before
the reader read either. That is steering by formatting, and it is invisible to the reader and
usually to the author, who experiences it as having more to say about the option they prefer.

**Both frames of a tradeoff go in the same cell.** "70% of accounts renew" and "30% of accounts
churn" are the same fact, and readers act differently on them. Write both: *"about 70% renew —
so about 30% do not."* Splitting the two frames across different cells, or writing only the
flattering one, is a framing choice made silently, and it is the cheapest way to move a
non-expert without saying anything untrue.

**Every cell is filled. "Unknown" is a filled cell; blank is not.** A blank cell reads as
"nothing to say here", which readers score as neutral. "We have nothing on this" reads as a
gap, which is what it is — and it is often the most decision-relevant thing on the page,
because a gap in the do-nothing column and a gap in the expensive column mean very different
things.

## Rank the criteria; never score them

The skill builds no weighing apparatus. No scores, no weights, no totals, **no arithmetic
anywhere in a decision brief.**

The evidence for the restraint is not a preference. Unit-weighted checklists — every criterion
counted once, no fitted coefficients — match or beat both statistically fitted models and
expert judgement when tested out of sample. Rank-order weights capture nearly everything full
weight elicitation gets. So the sophisticated apparatus buys accuracy that rounds to zero, and
it costs something real: a number the founder cannot audit.

**What the skill does instead:**

1. Criteria come from the founder's stated constraints (`[F#]` facts), phrased in their words.
2. The founder ranks them. Position is the weight. Nothing is multiplied.
3. The brief states which option best serves each criterion, in rank order.
4. The top-ranked criterion carries the decision, unless a lower one is a hard constraint —
   a compliance line, a refusal to do sales calls — in which case it eliminates columns before
   ranking is consulted at all.
5. If two options tie on the top criterion, go to the second. If they tie on every ranked
   criterion, the brief says the evidence does not separate them
   (`evidence_grade: insufficient`) and names what would.

**The skill may propose the criteria list; only the founder ranks it.** `criteria_ranked_by`
records which happened. A skill-ranked list presented as the founder's own is the exact failure
the values-congruence test is meant to catch, and it defeats the test silently, because the
recommendation then agrees with "the founder's criteria" by construction.

**The failure step 5 prevents:** manufacturing a tiebreak. When two options genuinely tie, any
mechanism that separates them is producing the appearance of a decision from noise, and it will
produce one every time — that is what a tiebreak mechanism does.

### Why AHP is rejected

The Analytic Hierarchy Process elicits pairwise comparisons, reports a consistency ratio, and
returns priority weights to three decimal places.

Two properties make it unusable here:

- **Rank reversal.** Adding or removing an option that nobody would choose can flip the order
  of the options that remain. A method whose answer depends on the presence of an irrelevant
  alternative is not reporting a property of the options.
- **Unstable elicitation.** The same person gives materially different pairwise judgements on
  different days, and the aggregate moves with them. The consistency ratio checks internal
  coherence, which is not the same as stability, and a coherent-but-unstable elicitation passes
  it.

**The failure this prevents:** the output is `0.412` versus `0.388`, and a founder who cannot
evaluate the method reads that as a finding rather than as noise — and reads it as carrying
more authority than the evidence underneath it, because it is more precise than the evidence
underneath it. The whole reason this document exists is that a non-expert cannot audit the
apparatus in front of them. Handing that non-expert a fragile number with three decimal places
is the failure, executed deliberately.

### Why Analysis of Competing Hypotheses is rejected

ACH scores evidence against hypotheses in a matrix and eliminates on disconfirmation. It is
rejected as a judgement method for two independent reasons:

- The controlled evidence shows **no benefit over unaided judgement, and possible harm**. A
  procedure that does not help is a cost; a procedure that may hurt while feeling rigorous is
  worse than one that feels arbitrary, because nobody double-checks it.
- It imports the wrong frame. A fork is a **choice under constraints**, not a set of competing
  hypotheses about what is true. The options in a decision brief are not rival explanations of
  evidence — they are things the founder could do, most of which could work.

**The failure this prevents:** an evidence-by-hypothesis matrix produces the same false
precision as AHP with an extra step and a more scientific-looking presentation. Because it
carries an intelligence-analysis pedigree, it is unusually hard to argue against once it is in
a document — which is precisely why it needs to be refused at the format level rather than
case by case.

## Likelihood and confidence are two fields that never fuse

Two different quantities:

- **Likelihood** — how probable the outcome is.
- **Confidence** — how much basis there is for saying so.

`Likely (55–80%) · Low confidence` is a complete, common, and useful state: the corpus points
one way, thinly. A single hedged verb cannot express it at all.

**The failure fusion causes:** words like *possibly*, *might*, and *could* collapse both
quantities into one. A weak basis disappears behind the hedge and so does a strong one, so the
reader cannot tell "we have good evidence that this is a coin flip" from "we have almost
nothing, and it leans this way". Those call for opposite next actions — the first says decide,
the second says go find out — and the fused sentence supports neither.

**Likelihood bands. A band term is never written without its range.**

| term | range |
|---|---|
| almost certain | 90–99% |
| very likely | 80–90% |
| likely | 55–80% |
| roughly even | 45–55% |
| unlikely | 20–45% |
| very unlikely | 5–20% |
| almost no chance | 1–5% |

At a boundary, take the higher band. **There is no 0% and no 100% band** — a brief that assigns
certainty to a business outcome is not describing a decision.

**The failure the ranges prevent:** verbal probability terms drift badly between readers. Two
people reading "likely" in the same sentence will act on numbers far enough apart to justify
different choices, and neither will know they disagreed. The range removes the drift without
inventing precision, because the band is wide on purpose.

**Confidence reuses the vault's `H`/`M`/`L` scale and its derivation rule** — see
[confidence is derived wherever a note rests on something](vault.md#confidence-is-derived-wherever-a-note-rests-on-something).
A decision's stored `confidence` is `min(confidence_own, every rests_on target)`; this document
does not restate the rule and does not define a second scale. A second confidence vocabulary
would need mapping to the first, and the mapping is where a Low quietly becomes a Medium.

**Rendering:** two adjacent statements, never merged into one adjective.

```
Likely (55–80%) · Low confidence
```

Never *probably*, never *fairly likely*, never *reasonably confident that it is likely*. Each
of those is a fusion wearing a different coat.

## The verb carries the evidence grade

The strength of a recommendation lives in its verb, so that strength survives a skim — which is
how a brief is actually read.

| `evidence_grade` | when it applies | the sentence the brief may write |
|---|---|---|
| `strong` | derived `confidence` is `H` or `M`, **and** fewer than three entries in `assumptions_low`, **and** the options are separated on the top-ranked criterion | "**We recommend** X." |
| `moderate` | the options are separated, but on `L` evidence, or only on a lower-ranked criterion | "**We suggest** X." |
| `insufficient` | the evidence does not separate the options on any ranked criterion, **or** the hard gate below fires | "**The evidence does not separate these.** Here is what would." |

**The grade is computed from those conditions, not chosen by how the author feels about the
call.** All three conditions for `strong` are mechanical, which is the point: an author's
confidence in their own analysis is exactly the quantity that should not be setting the register.

**Never write "we recommend" and hedge in the next sentence.** A hedged recommendation is read
and remembered as a recommendation; the qualifier is discarded within a paragraph. If the
hedge is real, it belongs in the verb, which means the grade is `moderate`.

**The `insufficient` register is not a failure to do the work — it is a finding**, and it is
the most common honest state early in an engagement. It must be a real, usable option in the
format, because the alternative is that every weak case gets phrased as "we suggest", which
reads as a preference, and the founder acts on a preference the evidence never supported.
`insufficient` always names what would separate the options, so it produces a research task
rather than a shrug.

**The failure the register prevents:** without it, a well-evidenced call and a coin flip are
phrased identically, and the founder has no way to tell them apart. Confidence tags in a
sidebar do not fix this — the sidebar is not what gets read.

## Three Low assumptions bar strong-recommendation language

**Three or more `L`-confidence load-bearing assumptions make the `strong` grade unavailable.**

This is a bar, not a caution. There is no warning banner, no "proceed with care" note, and no
author override. The `strong` grade cannot be set; the brief renders in the `moderate` or
`insufficient` register, and section 9 states in one sentence why the register was capped.

**What counts.** Load-bearing means listed in the brief's section 7: if the assumption is
false, a different option wins. An assumption whose falsity does not change the choice is not
load-bearing and is not counted. The `L`-confidence ones are listed by ID in `assumptions_low`,
which makes the gate a count of one field rather than a graph walk — a gate that requires
traversing the corpus to evaluate is a gate nobody runs.

**The failure this prevents:** three independent unevidenced beliefs, each individually
reasonable and each hedged separately, produce a recommendation that reads as evidence-backed.
Readers track one hedge, not three, and nobody multiplies them. Three things that each have to
be true is a materially weaker position than one thing that has to be true, and no amount of
careful per-assumption phrasing conveys that — the compounding has to be done by the format,
because it will not be done by the reader.

**This is a different instrument from the vault's `min` rule, and both apply.** Derived
confidence describes the weakest link in the chain the decision rests on; a single `L`
assumption in `rests_on` already drags the decision's stored `confidence` to `L`. The gate
describes something the chain cannot express: how many *simultaneous, independent* unevidenced
beliefs the choice needs. One `L` assumption is a validation task. Three at once means the
option comparison is largely fiction, and the register has to say so.

**Do not merge assumptions to duck the count.** If two entries are genuinely the same belief
stated twice, merging them is a correction and the brief should say so in one line. If they are
not, merging is gaming a guardrail, and it is the specific thing a reviewer looks for when the
count sits at exactly two.

## The record extends the vault's decision note; it does not replace it

The decision record is **the same artifact** as the `decision` note in
[vault.md](vault.md#the-decision-note-keeps-the-rejected-options-and-the-reopen-trigger), with
additional fields. There is no second schema, no separate file, and no parallel directory: the
record is one file in the vault's `decisions/` directory, named `DECISION-xxxxxxxx.md`, carrying
the vault's required fields plus the ones below.

**Everything the vault already settles stays settled here.** In particular:

- `chosen` must match an entry in `options` **verbatim** — the vault's rule, its reasoning, and
  its failure mode. This document adds `do_nothing`, which is held to the same verbatim rule
  against `options`.
- `confidence` is **derived**, `min(confidence_own, every rests_on target)`. This document does
  not recompute it and does not introduce a competing notion of strength — `likelihood` and
  `evidence_grade` are additional axes, not replacements.
- `reasoning` and `reopen_if` are the vault's fields, used as the vault defines them.
- The vault's two format invariants bind every field below: **block lists, never inline flow
  lists**, and **coerce nothing** — every value is a string, dates are quoted, anything
  containing `: ` is quoted, and bare `yes`/`no`/`on`/`off`/`null`/`~` never appear. That is why
  `was_the_reasoning_right` takes `sound`/`unsound`/`not_yet_knowable` rather than a yes-or-no.

### The fields this document adds

| field | shape | required | the failure it prevents |
|---|---|---|---|
| `criteria` | block list, most important first | yes | Without the ranking recorded, the values-congruence check cannot be run later — there is nothing to compare the choice against |
| `criteria_ranked_by` | `founder` \| `skill` | yes | A skill-ranked list read later as the founder's makes every recommendation look values-congruent by construction |
| `option_evidence` | block list of `"<option> :: <NOTE-ID>"` | yes | Evidence attached to the decision as a whole cannot show that one column was well-sourced and another had nothing behind it |
| `do_nothing` | string, verbatim `options` entry | yes | Makes the mandatory column mechanically checkable instead of aspirational |
| `founder_reasoning` | block scalar (`\|`) | yes | The skill's reasoning paraphrasing the founder's is how a founder's real constraint disappears from the record |
| `likelihood` | band term from the table above | yes | A probability with no term is unread; a term with no range drifts |
| `likelihood_range` | string, e.g. `"55-80%"` | yes | Pairing term and range in two fields lets a lint check they match; one fused field cannot be checked |
| `evidence_grade` | `strong` \| `moderate` \| `insufficient` | yes | Without it the register is set by the author's mood rather than by the evidence |
| `assumptions_low` | block list of `ASSUMPTION-*` IDs | when any exist | Makes the three-Low gate a count of one field rather than a corpus traversal |
| `reaffirmed` | block list of quoted dates | when it happens | A decision re-surfaced three times and left standing is stronger than one never tested; without the field they look identical |
| `reviewed` | quoted date | on outcome review | Distinguishes a decision nobody has looked back at from one reviewed and found sound |
| `what_happened` | string, one line | on outcome review | Without the outcome recorded next to the reasoning, the only thing anyone remembers later is whether it felt like a good call |
| `was_the_reasoning_right` | `sound` \| `unsound` \| `not_yet_knowable` | on outcome review | Keeps the verdict on the reasoning separate from the outcome (below) |
| `review_note` | string, one line | with `was_the_reasoning_right` | A verdict with no reason cannot be learned from |

**`option_evidence` is a flat block list of strings, not a nested mapping**, and the delimiter
is ` :: ` rather than `: `. Two reasons, both practical: a flat list of strings stays checkable
by the line-oriented POSIX-shell lint that ships with this skill, and a `: ` delimiter turns the
value into a nested mapping the instant somebody drops the quotes — a delimiter that only works
while quoted is one edit away from silently changing shape. The text before ` :: ` must match an
`options` entry verbatim, same rule as `chosen`.

**An option with no evidence gets an explicit entry**, not an omitted one:

```yaml
option_evidence:
  - "Keep taking whichever orders arrive :: none — the corpus holds nothing on the status quo"
```

The do-nothing column is usually the one with nothing behind it, and that absence is a finding.
Omitting the entry hides it exactly where it matters most.

**What the lint enforces is all-or-nothing, not presence.** Only a guided fork produces a brief
([grill.md](grill.md#posture--read-it-off-the-first-substantive-answer-never-ask-for-it)). A
founder in the direct posture who simply decided writes a `decision` note carrying none of the
fields above, and that note is complete as it stands — it is the worked example in
[vault.md](vault.md#the-decision-note-keeps-the-rejected-options-and-the-reopen-trigger). So
`vault-lint.sh` never requires these fields of a decision note. It fires
`decision-brief-incomplete` when a note carries any **option-grid** field — `criteria`,
`criteria_ranked_by`, `option_evidence`, `do_nothing`, `likelihood`, `likelihood_range`,
`evidence_grade` — and not the rest of them, `founder_reasoning` included. Those seven are what
say a brief stands behind the record, because each is meaningless alone: ranked criteria with no
evidence per option, or a likelihood with no evidence grade, is half a brief.

**`founder_reasoning` is owed by a brief and never demands one.** It is the exception, on
purpose. A verbatim record of what the founder said is worth having on any decision note, so a
note carrying it and nothing else — a decision migrated out of older prose that held the
founder's own words — is a legitimate write and stays green. Triggering on it would fail that
note, and the cheapest way back to green would be deleting the verbatim words. The conditional
rows are never demanded and never trigger either, for the same reason: `assumptions_low` names
load-bearing beliefs worth recording on any decision, and the review rows record what happened
to a decision afterwards, which a decision with no brief behind it goes through just the same.

**The failure this prevents:** requiring the fields on every decision note would fail vault.md's
own worked example, and a lint that fails the schema document's own example is one people switch
off. Requiring them nowhere leaves the half-filled note — a grid, a ranked criteria list, a
recommendation, and no `founder_reasoning` — reading as complete to every consumer and to every
later reader, with nothing in the corpus able to say otherwise. Carrying none of the option-grid
fields is a different and legitimate shape of record. Carrying some of them is the state that is
silently wrong.

### The one block-scalar field this document asks for

Multi-line prose in vault frontmatter is restricted to a closed set of fields using the literal
block scalar (`|`), with the folded form (`>`) banned outright. This document adds exactly one
field to that set: **`founder_reasoning`**.

The closed set becomes `quote`, `reasoning`, `reopen_if`, `founder_reasoning`.

Every other field this document introduces is a single-line quoted string or a block list, on
purpose — `what_happened` and `review_note` are held to one line each, which is a useful
constraint on top of a parser-compatibility one. `founder_reasoning` is the one field that
cannot be, because it is a verbatim record of what a person said and a person's reasoning does
not arrive in one line. Compressing it to fit is the paraphrase the field exists to prevent.

### The founder's reasoning is kept verbatim and separate

Two fields, never merged:

- `reasoning` — the skill's reasoning for the recommendation.
- `founder_reasoning` — the founder's own words for why they chose what they chose, verbatim,
  including the parts that do not follow from the brief.

**The failure this prevents:** a merged reasoning field ends up in the skill's voice, because
the skill writes the note. The founder's actual reason — "I don't want to owe anyone money", "I
promised my co-founder we'd stay small", "I've done the distributor thing before and hated it" —
is exactly the kind of constraint that does not survive paraphrase into analytical language, and
it is frequently the reason the decision was correct. Six months later, the record then shows a
decision that appears to rest on analysis and cannot be re-checked against the constraint that
actually drove it.

**Record deferral verbatim too.** When the founder says "go with your recommendation, I don't
have a view", that sentence *is* the founder reasoning and gets written as such. A decision the
founder deferred entirely is weaker than one they reasoned about, and the record has to show the
difference — otherwise a deferral and a considered agreement are indistinguishable at re-surface
time, when knowing which is what tells you whether to re-open the fork or just confirm it.

### What happened and whether the reasoning was right are different questions

`what_happened` and `was_the_reasoning_right` are separate fields and neither implies the other.

**A decision can be right and unlucky, or wrong and lucky.** Collapsing outcome into verdict
teaches the wrong lesson in both directions: a sound process that met a bad break gets recorded
as a mistake and abandoned, and a careless call that happened to land gets recorded as good
judgement and repeated. Repeating the second one is expensive and takes a long time to
discover.

Worked, in the format:

```yaml
reviewed: "2027-02-01"
what_happened: "Direct reached 40 accounts in nine months; the distributor channel was never opened."
was_the_reasoning_right: sound
review_note: "The timing read held. The per-account cost estimate was 30% low, which changed the pace but not the choice."
```

And the other direction, which is the one worth recording carefully:

```yaml
reviewed: "2027-02-01"
what_happened: "Direct reached 40 accounts in nine months, comfortably ahead of plan."
was_the_reasoning_right: unsound
review_note: "The window claim it rested on was wrong — the deadline moved and nobody noticed. The result came from a channel effect the brief never considered."
```

## Four triggers re-surface a decision, and the output is a diff

A decision is re-surfaced when, and only when, one of four things happens:

1. **`reopen_if` fired.** The named condition became true. This is the trigger the founder wrote
   themselves, which is why it carries the most weight when it fires.
2. **Something in `rests_on` changed status.** A claim, fact, or source underneath the decision
   went `needs_review`, `superseded`, or `retracted` — including a claim whose `stale_after`
   passed. This is the blast-radius trigger, and it is the one the founder cannot see coming.
3. **A load-bearing assumption resolved.** Something in `assumptions_low` was validated or
   refuted. **Both directions count.** A validated assumption is not a non-event: it frequently
   comes back true *with a different value*, and the value is what the option comparison used.
4. **The criteria ranking moved.** The founder's constraints changed — runway shortened, the
   ambition answer changed, a hard constraint appeared or lifted — so the criterion that carried
   the decision is no longer the top one. This is the values-congruence trigger: the choice was
   congruent when it was made, and the values moved underneath it.

**Re-surfacing sets `status: needs_review` on the decision note.** That is the vault's existing
mechanism, used as the vault defines it; this document introduces no parallel state.

**The output is a diff for the one decision whose basis moved. Never a regenerated plan.**

```
DECISION-QK71PP04 — Bootstrap to profitable before considering a round

  Trigger 2 — something this rests on changed status

    CLAIM-AS23SD44    current → needs_review
      then:  the deadline opens a 12-month buying window
      now:   the deadline moved to 2028; the window is roughly 24 months

  What this moves
    Your top-ranked criterion was "first money arrives within nine months".
    With a 24-month window, options A and B both clear it, so the criterion
    no longer separates them and the decision now turns on your second:
    "keeps me able to stop without owing anyone".

  Your reasoning at the time, verbatim
    "I don't want to owe anyone money before I know this works. If it takes
    longer that's fine, as long as I can stop."

  Three moves
    · re-decide the fork  · record that the choice stands  · defer with a date
```

The diff shows the changed input, the criterion it moves, the founder's own words at the time,
and nothing else.

**The failure a regenerated plan causes:** a rewritten document hides which input changed. The
founder is handed a new artifact that differs from the old one in ways they cannot enumerate,
and the only question they actually need answered — *what moved, and does it change my
choice?* — is the one thing a full regeneration deletes. It also destroys the audit trail: a
plan that quietly rewrites itself cannot be checked against what it said before, so a wrong
change and a right one look identical.

**The three closing moves are all real, and all get recorded.** Re-deciding writes a new
decision note that `supersedes` the old one, per the vault's two-edit rule. Leaving the choice
standing appends today's date to `reaffirmed` and flips `status` back to `current`. Deferring
sets a date and leaves `status: needs_review` — visible, and not the same thing as agreement.

## A worked fork, end to end

The fork the decision layer exists for: the founder cannot answer "venture-scale,
bootstrapped-profitable, or lifestyle?" because they have never seen what each implies.
Everything below is generic — the product, the numbers, and the founder are invented.

**Section 4, as the founder sees it.** Four criteria, offered unordered, with the ask to rank
them. The brief stops here.

```
Before I show you the options, put these in the order that matters to you.
There is no right answer — the order is what picks the option.

  · keeps me able to stop without owing anyone
  · first money arrives within nine months
  · does not need me to do sales calls
  · leaves the option of a larger outcome open
```

**Section 5, after the ranking comes back.** Four columns, one of them the status quo:

| | A: bootstrap to profitable | B: small round for runway | C: build for venture scale | D: keep going as is |
|---|---|---|---|---|
| What would I actually do first, this week? | Price the tool and email the 12 people who already asked | Write a one-pager and list 20 angels | Rewrite the positioning around the largest segment | Nothing changes |
| What does it cost — money, and hours a week? | ~0 up front, ~20 hrs/wk | ~0 up front, ~30 hrs/wk for a quarter, then ~20 | ~0 up front, 40+ hrs/wk, effectively full time | ~8 hrs/wk, the current pace |
| How long until I know if it is working? | 6–10 weeks to first paid | 3–5 months to a closed round, and no product signal in that time | 9–12 months to a fundable metric | No signal — this is the option with no clock |
| What do I give up? | Speed; the largest segment stays unserved for a year | ~15–25% of the company, and the option to stop cleanly | The option to stay small; the round sets the expectation | Everything the other three could start; the window narrows |
| What has to be true for this to work? | 12 interested people convert at ~30% | Angels fund pre-revenue in this category | The largest segment is reachable without a sales team | Nobody else serves these buyers meanwhile |
| What does the evidence say, and how strong is it? | Comparable tools price in this band — Medium | Two comparable rounds closed in 18 months — Low | Category has one winner-take-most comparable — Low | Nothing. The corpus holds no evidence on the status quo |
| What is the worst realistic outcome? | 9 months of evenings, ~4 customers, no clear signal — and it is recoverable | Round does not close, 4 months gone, product unchanged | Runway ends before the metric arrives, with investors owed a story | The window closes and the choice is made for you |

**Section 9, in the register the evidence permits.** Two `L`-confidence load-bearing
assumptions, so the gate has not fired, and the options separate on the top criterion:

```
We suggest A — bootstrap to profitable.

  Likely (55–80%) · Low confidence

Your top-ranked criterion was "keeps me able to stop without owing anyone", and A
is the only option that clears it outright — B trades it away and C trades it away
permanently. The recommendation is "suggest" rather than "recommend" because the
separation rests on Low-confidence evidence about conversion from your existing 12
interested people, and that number is the whole case.

If a third Low-confidence assumption enters this brief, this sentence becomes
"the evidence does not separate these" — the strong register is unavailable at
three, whatever the analysis feels like.
```

**The record.** Vault fields and this document's fields in one note, at
`<vault>/decisions/DECISION-QK71PP04.md`:

```yaml
---
id: DECISION-QK71PP04
type: decision
title: "Bootstrap to profitable before considering a round"
status: current
confidence: L
confidence_own: M
created: "2026-03-16"
options:
  - "Bootstrap to profitable"
  - "Small round for runway"
  - "Build for venture scale"
  - "Keep going as is"
do_nothing: "Keep going as is"
chosen: "Bootstrap to profitable"
criteria:
  - "keeps me able to stop without owing anyone"
  - "first money arrives within nine months"
  - "does not need me to do sales calls"
  - "leaves the option of a larger outcome open"
criteria_ranked_by: founder
option_evidence:
  - "Bootstrap to profitable :: CLAIM-AS23SD44"
  - "Bootstrap to profitable :: FACT-GF45SD01"
  - "Small round for runway :: CLAIM-BB77KK12"
  - "Build for venture scale :: CLAIM-QQ19PL30"
  - "Keep going as is :: none — the corpus holds nothing on the status quo"
likelihood: likely
likelihood_range: "55-80%"
evidence_grade: moderate
assumptions_low:
  - ASSUMPTION-MN66TT21
  - ASSUMPTION-RT08WW63
reasoning: |
  The top-ranked criterion eliminates B and C outright: both trade away the
  ability to stop cleanly, and C trades it permanently. A and D both clear it,
  and A is the only one of those two with a clock on it. The separation rests on
  a Low-confidence conversion estimate from the 12 existing interested people,
  which is why the register is "suggest".
founder_reasoning: |
  I don't want to owe anyone money before I know this works. If it takes longer
  that's fine, as long as I can stop. The venture thing sounds like a job I'd be
  bad at and I'd resent it in a year.
reopen_if: |
  Two consecutive months where fewer than 2 of the 12 interested people convert
  at the listed price, or a competitor ships the same capability free at the
  correctness layer.
rests_on:
  - CLAIM-AS23SD44
---

Chosen on reversibility, not on ceiling. The round is not rejected — it is deferred
until there is revenue to price it on.
```

Two things to read off that record. `confidence` is `L` because `CLAIM-AS23SD44` is `M` and an
`L` assumption sits under the chain — derived, not authored, per the vault's rule. And
`evidence_grade` is `moderate` while `assumptions_low` holds two entries; a third entry makes
`strong` unavailable regardless, and here the grade was already capped by the Low evidence.

## Writing a decision brief: the checklist

1. **Check the fork earns a brief** — the founder could not answer it after one grill turn with
   a default, and the answer moves more than one plan section. Otherwise it stays a grill
   question.
2. **Draft sections 1–3**, with the founder's constraints quoted as `[F#]`, not paraphrased.
3. **Send section 4 and stop.** Capture the ranking into `criteria` before writing anything
   downstream of it. This is the forcing function; skipping it removes the only guardrail the
   format has against its own persuasiveness.
4. **Build the grid** — every option a column including the do-nothing column written in the
   founder's words, seven mandatory rows plus the founder's own questions verbatim, equal detail
   in every column, both frames in every tradeoff cell, no blanks.
5. **Write sections 6–8.** Section 7's list is the input to the gate — count the `L`-confidence
   entries there, not anywhere else.
6. **Set `evidence_grade` from its three conditions**, then write section 9 in the register that
   grade permits. Three or more `L` load-bearing assumptions and `strong` is off the table.
7. **State likelihood and confidence as two adjacent statements**, band term with its range, no
   fused adverbs.
8. **Write section 10 as if-then** with a named metric and a threshold that can be observed
   rather than argued about.
9. **Write the record** as a `decision` note per [vault.md](vault.md) plus this document's
   fields — block lists, quoted values, `chosen` and `do_nothing` verbatim against `options`,
   `founder_reasoning` in the founder's own words including a deferral.
10. **Run the lint** before the note is done, and check the one thing the lint cannot: that the
    founder's choice matches their own top-ranked criteria. If it does not, the brief has a
    problem the record will not show — go and ask.
