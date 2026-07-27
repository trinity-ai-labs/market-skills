# Changelog

Versions are the `version` field in `.claude-plugin/plugin.json`. Because that field is set, an installed plugin only picks up changes when it **changes** — pushing to `main` alone ships nothing. CI enforces the bump.

## 1.8.0

- **A citation is now opened, not just recorded.** `vault-lint.sh --used-in` reads the document
  every note's `used_in` names and checks that the file is there and the `#anchor` names a real
  heading. Nothing did that before: the default run reads the six note directories and stops at
  the vault's edge, so a document renamed after the claim was cited into it, or a heading cut
  while the note went on naming it, left the note reading as cited into a section nobody can
  find. The moment that costs the most is the one where it helps least — when a `stale_after`
  fires, the re-check it demands has nowhere to go. Two failures, named apart because they want
  different fixes: `used-in-missing-file` when nothing exists at the named path, and
  `used-in-dead-anchor` when the document is there and no heading slugs to the fragment. It is a
  verdict rather than a report and exits 1 on either. **What it deliberately does not check is
  the part worth writing down**: it asserts that a citation *resolves*, never that the named
  section *carries* the claim. The corpus resolves prose to a note for two of the three types a
  plan cites — `[S#]` through the source index, `[F#]` through the founder brief — and for the
  third it does not, because a claim is stated in the author's own words with no code to grep
  for. A scan matching note IDs against prose would fire on every correctly cited claim in the
  vault, and a check that cries wolf gets switched off, which takes the working half with it.
- **`--supersession-sweep` prints the re-read worklist a supersession owes, because replacing a
  note tells the note and nothing else.** When B supersedes A, every document section A's
  `used_in` named is now in doubt, and the supersession is visible on the note and invisible
  everywhere the note was cited. The sweep walks every superseded note and emits the union of
  those targets, **grouped one row per section** however many notes point at it — the unit of
  work is *re-read this section*, and a list repeating the section once per note makes a two-item
  job look like six — with the **row count printed first**, because the gate that consumes it is
  a read and a read is bounded only if its size is visible before it starts. It is a report and
  not a verdict: it exits 0 whether or not it finds anything, the contract `--unverified` already
  carries. A supersession with a blast radius is the corpus doing its job, and a mode that went
  red on a healthy vault would teach a reader to ignore the exit code the real checks depend on.
- **Invariant 19 — nothing is dispatched to the red team until the plan and the vault have been
  reconciled, and invariant 20 is what it reads for.** Lint ran at the per-dimension checkpoint
  and again before rendering; between drafting and the panel there was nothing. A panel briefed
  on a plan the ledger has already moved past returns objections about a version nobody is
  shipping, at full panel cost, and it cannot be walked back — a panelist already briefed cannot
  be un-briefed, which is why the gate sits on the dispatch rather than on the phase boundary.
  Three steps, and **the third is the gate**: `--used-in` fails, `--supersession-sweep` emits the
  worklist, and then a conductor *reads* every named section against the note behind it. The two
  lint calls bound that read rather than replace it, and bounding is what makes it happen at all
  — "check the plan against the vault" is a task nobody can size, and a task nobody can size is a
  task nobody starts. Invariant 20 states what the read is looking for: **a claim is finished
  when the prose it names carries it, not when the note is written.** Writing the note and
  writing `used_in` are one act, and the claim stays open until the section says what the note
  says. That is an invariant rather than a Phase 3 step because the obligation outlives Phase 3 —
  the vault keeps growing through drafting and into the panel, and a claim minted while the panel
  is running is subject to it exactly as one minted while the plan was being written. Written
  into the drafting phase, the rule would stop applying at the moment the vault is most likely to
  move, and a note minted from a disposed objection is the likeliest of all to sit in the ledger
  unread. The failure both close: a corpus where every note is individually correct and the
  documents built on them have quietly stopped agreeing.
- **Invariant 15 — the Phase 5 release gate is three calls, not one.** The default run never opens
  a citation target, so a plan clears the bare gate while carrying a citation to a document that
  was renamed or a section that was cut, and the next thing that happens is a rendered PDF
  asserting it to the one reader with no way to check. The render gate now runs the default
  check, then `--used-in`, then `--supersession-sweep`, and the sweep is in that set for a
  specific reason: Phase 4's dispositions mint supersessions *after* invariant 19's sweep has
  already run, which makes the render the only point they would be read at all. **Phase 2's
  checkpoint stays the bare run** — no note carries `used_in` until drafting cites it, so
  `--used-in` there checks an empty set, and running it anyway teaches the mode as cadence-wide
  when it belongs to one gate.
- **Invariant 21 — the grill closes as a phase, not as a channel.** Founder input arriving after
  Phase 1 is normal rather than exceptional, and it gets exactly what anything said during the
  grill gets: the same `fact` note resting on the interview source, the next `[F#]` in the
  existing sequence, an appended row in the founder brief, and invariant 20's propagation
  obligation like any other claim. The brief is appended to rather than rewritten, because `[F#]`
  codes are cited from the plan by number and a renumber silently repoints every citation already
  written. The failure this prevents: what a founder volunteers late is the evidence nobody
  thought to ask for, which makes it the least redundant material in the corpus and exactly what
  a model with no channel for it drops. It arrives conversationally mid-drafting and lands
  nowhere — no code, no note, no propagation obligation, because the phase that owned founder
  input is over — so it reaches the plan as something the conductor happened to remember, or not
  at all.
- **Invariant 3 — before a metric is cited as evidence for a mechanism, state what else produces
  that number.** A count says a thing exists; it never says why. Where the alternative explanation
  is not excluded the metric is a description and not evidence — and **a metric chosen after the
  conclusion is a conclusion wearing an instrument.** That second clause is the one worth writing
  down: a careful reader supplies the alternative explanation anyway, while an instrument selected
  to fit a thesis already reached leaves every step downstream of it locally sound, so there is
  nothing further along to catch it. The tell is a second metric introduced to confirm the first;
  chosen after the thesis, it tests the thesis's fit to the instrument rather than the mechanism,
  and it reads as corroboration. The rule bites hardest at the red team, where a matching quality
  bar now applies: a panelist handed a number reads it as the evidenced part of the brief and
  spends the turn elsewhere, so an unexcluded alternative explanation reaches the panel as settled
  ground and comes back unattacked.
- **Phase 3 opens by re-verifying product claims against source at the current commit, and the
  direction is the whole point.** The dossier is the product truth the plan inherits, and it was
  written before the research fleet spent a week running — the product moved underneath it. **A
  plan that only re-checks numbers that look too good drifts pessimistic, and every drift reads as
  rigour.** A capability that shipped, a limit that was raised, a seam that was closed: each one
  now reads as the plan being careful. The skill's existing skepticism fires in one direction only
  — strong rules against unmodelled optimism, a both-directions test on input values — so an
  understated product claim clears every other bar on the list and reaches an acquirer or an
  investor as a fabricated weakness, one the founder then has to argue their own plan out of. The
  four queries that already run before a section is drafted cannot reach it: a claim stale because
  the world moved is what `stale_after` catches, and a claim stale because the product moved has
  no shelf life on it at all. A drift lands as a supersession, not an edit in place, naming the
  release that moved it — edited in place, the plan reads as though it were written against a
  product state its author never saw.
- **The decision that a `claim` note does not get a citation code yet is written down, with the
  trigger that would reopen it** — `docs/specs/2026-07-27-claim-citation-codes.md`. Giving claims
  a code and an index would make the agreement check above mechanical, and would also change what
  every plan document looks like and what every migration into the vault has to produce: a design
  surface that earns its own pass rather than arriving as the implementation detail that made one
  check convenient to write. So the read is bounded instead, and what that costs is stated rather
  than discovered mid-release by whoever writes the gate — a lint either runs or it does not,
  while a read is a judgment step a person can skip under pressure. That is why the agreement rule
  lands as a numbered invariant in the head block rather than as a line inside the phase's own
  step: compaction re-attaches only the head of a long skill file, so a rule stated in a phase
  body is out of context by the time that phase runs, and a gate that is out of context when its
  phase runs is a gate that does not run. The sweep's own reported count is the instrument for the
  reopen — when the worklist routinely runs past what a conductor will read in one pass, the
  bounded read is spent and the mechanical resolution is worth the design pass it was deferred
  pending.

## 1.7.0

- **A price is now defended on two lenses, and `value-delivered` is the one that was missing.**
  All three pricing lenses were cost-side — affordability banned as an argument,
  `alternative-cost` mandatory wherever a price is defended, `switching-cost` pricing the move
  away — so nothing in the vocabulary named what the buyer *produces* with the product.
  Substitute pricing has a ceiling at the cost of the substitute, so a method mandating only that
  side anchors the price under the DIY figure, and it does so invisibly: the substitute number is
  well-sourced and reads as rigour, while the output figure nobody computed is simply absent from
  the page rather than visibly missing. The new term prices what the buyer can produce that they
  could not before, in the buyer's own currency, and excludes the three adjacent terms from both
  sides — `alternative-cost` was amended to declare the same boundary from its side, because a
  boundary stated once is the near-miss the vocabulary exists to kill and existing corpora already
  carry output-value claims filed there for want of anywhere else to put them. It is
  `required: false` on purpose: the output delta is not expressible in the buyer's currency for
  every product, and a required row there produces a fabricated figure to close a coverage gap.
  The obligation is conditional and lives where its condition is visible — the plan template's new
  `## Value delivered` section, fired wherever a price is defended, sibling to
  `## Cost of the alternative` and bound to it in both directions so an agent reading either knows
  both fire.
- **Retention is `policy within a structural band`, the construction `price` already used.** The
  driver-home table filed it `structural`, and the sentence beneath it said what that meant:
  conversion and retention are what they are at the stage the target counts, and no decision the
  founder takes this week moves them. Half of that is right. A consumer utility does not retain
  like an ERP — that band is the category's and it stands — but the position inside the band is
  the product's: the depth of what it does, whether the valuable part is reachable unassisted, and
  the friction between the two. Because the construction already existed for `price`, the change
  needs no new vocabulary and the existing rule
  `## A structural driver may be sourced from the reference class; a policy driver may only be checked by it`
  covers it unedited — the class sources the band and may only *check* the position. What moves is
  what a verdict may conclude: a retention-bound miss now reads *this product as built does not
  retain* with the target under one changed position beside it, never *this market does not
  retain*, and it routes to the roadmap rather than to the founder's calendar. Filed `structural`,
  a research pass could identify the coupling exactly — where value compounds per additional
  teammate the multi-seat cohort churns lower, so one improvement moves seats-per-account and
  churn together and moves the ceiling multiplicatively — write it down, and have the label keep it
  out of the arithmetic anyway. That is a labelling bug, which is why the fix is a `kind` column
  and not a new section.
- **The two ends are one change, because the cross-link is what makes either work.** Delivered
  value is the input and retention is where it becomes observable in the arithmetic: churn is the
  divisor of the steady-state identity, so halving it roughly doubles the equilibrium and with it
  the price the ceiling will carry. Price on delivered value with no retention channel and the
  value claim never touches a number — it sits in a pricing paragraph and the model is unmoved.
  Model retention as product-movable with no value rule behind it and you have a lever with no
  driver. So the template's `## Value delivered` names retention as its channel into the model,
  the retention work names delivered value as what places the product inside its band, and
  `roadmap-sequencing.md` carries the consequence: churn is a term of the identity like any other,
  an item moving it compounds with items moving the numerator, and two items both aimed at
  retention compete rather than add.
- **One guard, applied at both ends, and it is what makes the change shippable.** A claim about
  delivered value or about a retention improvement carries a sourced base and labels its magnitude
  `measured`, `reference-class` or `assumed`, with an `assumed` one taking the both-directions test
  like any other input. Both are the optimistic mirror of the 1.5.0 rule, which only ever fired on
  pessimistic inputs, and both flatter the thing the founder built — which is exactly what makes
  them easy to write and hard to challenge. The guard binds harder at the retention end because
  churn is the divisor: an unguarded improvement claim moves the answer faster than any other input
  in the model, and unguarded the reclassification is a licence to model churn down to whatever the
  target needs. Three quality bars make it checkable rather than merely stated, including one on
  silence — a plan whose roadmap improves the product states what that does to retention or states
  that it does not and why, because silence read as "no effect" is a claim nobody made.
- **`conversion` stays `structural`, and the reason is recorded next to the `kind` column.**
  Onboarding quality moves activation and trial-to-paid too, so the argument above reaches for
  conversion next. It stops there deliberately: conversion is a funnel property of the category
  measured at a stage, while retention is where a product's own value shows up over time. If reach
  is policy, price is split, retention is split and conversion is split as well, the identity keeps
  no structural term at all, every negative verdict becomes conditional on something the founder
  could change this week, and the skill loses the one output it exists to be able to produce, which
  is telling a founder no.
- `vocabulary_version` 2 → **3**, with two entries in the amendment log — `alternative-cost` and
  `churn` — both at `amended_at: 3` and `shipped_in: "1.7.0"`. `churn`'s `must_assert` supersedes a
  bare rate carrying no band and no determinant; `alternative-cost`'s keeps a claim pricing the
  substitute's total cost and re-files one asserting what the buyer produces. One version step, one
  advisory for a founder to act on, one reconciliation pass per vault.

## 1.6.1

- **The vault's generated `README.md` is regenerated by what changed, not by which phase ended.**
  It was written at scaffold and again at each phase boundary, while the vault commits at every
  meaningful write — so between boundaries it stated a target and a verdict status the corpus had
  stopped asserting, and it read as current because its last line says it is generated rather than
  hand-edited. The window is not a rounding error: a renegotiated target settles mid-Phase 3, and
  1.6.0's reference-class re-flip makes a verdict that changes between boundaries a designed-for
  event. Regeneration now rides the commit that invalidates it. The skill already made this exact
  argument one level up — invariant 17 commits at every meaningful write because *phase boundaries
  are too coarse a unit of loss for a phase that writes dozens of files* — while the block below it
  pinned the README to the coarse unit that invariant rejects; the two now state the same cadence,
  and `.gitignore`, whose content does not track the corpus, keeps its phase-boundary cadence in a
  clause of its own.
- **The volatile fields are named, so the rule is decidable at commit time.** Four of them: the
  current target, its verdict status, which phase the corpus is in, and the note-type map when the
  corpus starts asserting a type it did not carry before. An agent about to commit checks its write
  against those four rather than re-reading the generated file — a rule that expensive is one that
  gets skipped — and because nothing else the README carries moves after scaffold, most commits
  touch none of them and leave the file alone. That floor is deliberate: a README rewritten on
  every commit buries the ledger changes the history exists to show, which is the same failure
  `.gitignore` exists to prevent. Phase 3's verdict step names the regeneration where it fires; the
  README stays generated rather than hand-edited, and an existing vault picks the cadence up on its
  next write with no migration.

## 1.6.0

- **A reference class inferred from the subject's own price point or packaging is downstream of a
  policy input, and it inherits that input's mutability.** 1.5.0 made the class a first-class
  input — named, classified `structural`, homed to `research/growth-curves.md` and flip-tested —
  but left unsaid what the class may be *derived from*. `kind` classifies by who sets the value,
  and a class read off the subject's own price point and delivery shape was selected by a founder
  decision rather than by the market; filing it `structural` on the strength of where it landed
  hides that. It stays `structural` — there is no third kind — but it now says what it was
  inferred from wherever it is named, and it is re-flipped when that input settles differently.
  Without it a founder decision selects the comparable set, the set fixes conversion, retention
  and the multiple together one level beneath the arithmetic, and the verdict that follows is
  reported as a property of the market: repricing reads as a pricing question when it is a
  reclassification, and the one change that moves every structural driver at once is never costed.
- **The re-flip now has a moment to fire in, and the trigger fires in both directions.** The class
  is named in Phase 2 from the dossier, while the pricing and capital forks that settle the
  subject's packaging are simulated and settled inside Phase 3 — so the class was fixed before the
  decision it was inferred from was final, and the re-flip was missed by construction on every run
  rather than occasionally. It is attached to Phase 3, the one phase where both halves are open,
  and it covers both gaps: re-flip against whatever pricing, packaging and delivery decision is
  settled at the moment the verdict is computed, **and** re-flip again when a fork settled later in
  that phase — the strategic-fork simulation runs after the verdict, not before it — lands on a
  different packaging than the class was read off. A changed class re-solves the identity rather
  than annotating the verdict, because every structural driver beneath it moves together. The
  verdict checklist carries the re-flip as its own step immediately before the solve step, which is
  where it fires in time, and a quality bar makes it checkable rather than merely stated.

## 1.5.0

- **Every driver value names its driver in both directions, and a low one with none is
  `unmodelled, not conservative`.** Skepticism fired on optimistic inputs and not on pessimistic
  ones: a low number entered the model with nothing behind it and read as rigour, because
  challenging a conservative figure looks like advocacy while challenging an aggressive one looks
  like discipline. In a multiplicative chain that is not a rounding error: seven multiplied terms,
  each filled at roughly half of what the evidence carries and every one of them defensible on its
  own, return the target short by about two orders of magnitude — and the readout names a
  structural driver as binding rather than the stack of unexamined choices that produced it. The
  rule that would have caught it existed, but only for the projection *curve*: a flat stretch had
  to name its operational driver while the numbers the curve was built from did not. It now
  generalises to every model input and every driver value — each of the multiple's four inputs,
  every rate and share the chain multiplies — a conservative figure needs a source exactly as much
  as an aggressive one, and a low value with none takes the same label the flat-curve rule already
  used. The flip test does not cover this and is not asked to: it re-solves at both ends of an
  assumption's plausible range and asks whether the *verdict* moves, so a pessimistic value with
  no driver is a well-formed `assumption` carrying a `value` and a `sensitivity` and passes clean,
  because the band it was given is drawn around a centre nobody chose. The flip test audits how
  wide the uncertainty is; the new one, which runs first and on every value, audits whether the
  number was ever pointed anywhere on purpose.
- **A structural driver may be sourced from the reference class; a policy driver may only be
  checked by it.** The driver-home table already handed the same instrument two different
  authorities — `research/growth-curves.md` *sets* conversion and only *checks* reach — and stated
  the reason for neither, which left the split reading as a per-row accident rather than a
  principle. The principle: a structural driver is a property of the category, so the indexed set
  can source it; a policy driver is the founder's own configuration, so a comparable's value is
  evidence about a different company's choices and can only ever be a check. Sourcing a policy
  driver from a comparable is neither conservative nor aggressive — it answers a different
  question, and the answer comes back well-formed: the figure carries a citation, the identity
  balances, the binding driver is named with the confidence it would have had, and the founder's
  stated hours never entered the arithmetic at all. So `kind` now decides two things at two
  moments — at fill time where a value may come from, at verdict time what a negative verdict may
  conclude — and the target checklist classifies every driver *before* it fills any of them. The
  exit table moves with it: the growth slope at the sale month is a commitment this roadmap makes,
  so it is stated configuration with the indexed set as the check on it, never the plan's own
  projection fed back in.
- **A structural driver with no instrument of its own tries the reference class before it degrades
  to an assumption.** The ladder has three rungs — subject instrument, then the reference class
  where the driver is structural and the indexed set reaches it at the month the target counts,
  then `assumption`. The middle rung produces a `claim` resting on `research/growth-curves.md`,
  carrying that set's `stale_after` and a `validated_by` naming the kill test that would overturn
  it. The failure skipping it causes: invariant 11 caps a claim at its weakest input, so routing
  the only legitimate evidence a pre-launch company has through an `assumption` makes every driver
  weak by construction — and every plan for a company that has not launched then reads as
  unjustified, which is every company at the moment the plan is worth writing. `market-analysis`
  builds the indexed class precisely so a driver can take its value at a stated month; declining
  to let it is the skill refusing its own instrument, and the founder is told the evidence is thin
  when what is thin is the routing. Only what the set genuinely cannot speak to degrades: every
  policy driver, and any structural one the set does not index at the month in question.
- **The reference class is itself an input — named, classified and flip-tested like a driver.**
  Making it load-bearing changed the failure mode rather than removing it: a wrong class used to
  produce a visibly-hedged `assumption` and would now produce a confident `claim`. So which
  companies the subject is compared against is named in the readout, classified `structural`,
  homed to `research/growth-curves.md`, and put through the flip test — re-solved against each
  candidate set a reasonable person would argue for. A verdict that moves between two defensible
  classes is *undetermined*, with both classes named and the cheapest test that settles which one
  the subject belongs to. Left unwritten it is the largest unexamined input in the method, because
  it sets conversion, retention and the multiple at once, one level beneath the arithmetic: the
  whole verdict shifts without a single figure in it looking wrong, and the founder is handed a
  categorisation wearing the authority of the indexed set it was only ever assumed into.
- **A value the indexed set sourced carries the survivorship qualifier wherever it is reported.**
  Every company in that set got far enough to be written about, so the ones that posted the same
  early numbers and then stopped are absent by construction — a property of the set rather than of
  any member, and one that makes a structural driver sourced from it systematically optimistic.
  That is the defect above wearing the opposite sign, and it is harder to catch in this position
  because the number now has a citation behind it; replacing a pessimistic default nobody
  challenged with an optimistic one nobody challenged moves the error rather than removing it. The
  qualifier travels with the value into the readout and into any exhibit that renders it, in the
  same words each time, rather than sitting as a footnote on the research file, which is not where
  the number is read. And where a broad-population figure and a named-company value both exist for
  the same metric, the disagreement is recorded rather than averaged or picked by feel: the two
  routinely differ by most of an order of magnitude, because the named companies are the ones that
  worked, and a run that quietly took the higher of them has sized the plan against a population
  the subject is not in yet. The plan document now says which of the three a driver value came
  from — measured on the subject's own instrument, read off a sourced benchmark, or taken from the
  indexed class at a stated month — because rendered identically, a value extrapolated from
  comparables and one measured on this product are indistinguishable, and the founder acts on both
  equally.
- **Phase 3's both-directions check reaches the model's inputs, not only its curve.** The two
  checks that already ran on the projection read the curve rather than what it was built from: the
  level check places the implied monthly growth *rate* against the observed band, and the shape
  check places the implied *trajectory* against the indexed curves at matching months since
  origin. A chain filled at the low end at every term clears both — in band and in shape, at a
  scale nobody chose. Every input to the revenue build now takes the both-directions test before
  either of those two runs.
- **Phase 4's pre-pass tests the identity it writes.** It grew from three steps to five. It now
  names every input that is unmodelled in the *pessimistic* direction — the direction it
  structurally could not see, since a low number reads as the cautious choice rather than as the
  claim it is, so it passed through the block unremarked and the panel inherited a floor nobody
  sourced. And it reads the terms it wrote back against what the founder stated the business is,
  reporting a term the business has that the identity lacks. Writing the identity out is the right
  instrument and it is not a test of itself: a business with three revenue layers solved as a
  single-layer funnel is internally consistent and solves cleanly, so the arithmetic is correct
  about the wrong business while every value inside it is individually defensible, and no rule
  about input *values* can reach it. Both additions travel in the block every red-team brief
  carries verbatim, and the verification checklist names them there rather than leaving them to
  the paragraph that describes them.
- **Two of the rules above earn a quality bar, because prose in a reference file is not a
  producer.** A rule reaches an agent only when it is interpolated into a brief or performed by
  the conductor in a phase, so a rule stated once in a reference file reads correct on the page
  while nothing runs it. The both-directions test on every model input, and the reference-class
  rung that keeps a pre-launch structural driver out of the `assumption` pile, are each on the
  list that says what may not ship.

## 1.4.0

- **An exit target has its own identity, and its dominant term is a band.** An outcome stated as
  an acquisition or a company valuation was the one shape `business-plan` could not decompose:
  forced into the revenue identity it came back confident about ARR, which is the term an exit
  verdict is least sensitive to, while the term that decides the answer disappeared into an
  assumed figure nobody wrote down. It is now `exit value = ARR at exit × multiple`. The left
  term is one of the existing identities solved at the *sale* date rather than the target date,
  so those shapes are a term of this one and never a substitute for it, and the multiple enters
  as a band and never as a scalar — written as one number it reads as a property of the category
  and the verdict inherits a precision nobody evidenced. The band's ends trace to four inputs,
  each with a named home in the corpus and a `kind` per invariant 18, and not one of them is ARR:
  the growth slope at the moment of sale and the strategic necessity of the asset to a *named*
  acquirer are policy, while scarcity — whether the buyer ships it itself in two quarters — and
  the count of buyers with the same hole are structural. One interested party is a price **floor**
  and not a price, because a single bidder pays whatever the founder's next-best alternative is
  worth. Reporting a slope-bound exit as structural tells a founder their company cannot be sold
  for that, when what is true is that this roadmap cannot sell it for that. The multiple is
  usually the binding driver and always the least evidenced, so an exit solved at a single
  assumed multiple is the existing traces-to-nothing case applied to the term that decides the
  answer: the run returns **undetermined** and names the cheapest test, which is a comparable-exit
  reference class rather than a founder interview — the founder cannot know a price set by buyers
  they have not met, so asking returns their hope wearing the authority of an answer. And the
  window under the band is structural and time-varying, which makes this the first driver whose
  `stale_after` is load-bearing rather than administrative: a multiple assumed three years out
  assumes today's comparables' window is still open then, and a shelf life set to the plan's own
  horizon comes up for re-checking on the one date the answer stops being useful. The exit also
  gets its own lever table — slope, acquirer legibility, date — because hours, capital and price
  all act one term down, through the side of the identity the verdict was least sensitive to. The
  same term reaches the roadmap and the memo: a roadmap item may now earn its place by moving one
  of the multiple's inputs rather than a row in the assumptions table, which models ARR and has no
  row for the multiple at all — so the items aimed at the term that decides the answer were being
  filed as maintenance, and the permutation table that ranks orderings is measured at the sale
  month, since the order maximising twelve-month cumulative can be the one that arrives at the
  sale decelerating. In the venture memo the ask is sized against the slope it holds *through* the
  sale month rather than a revenue level, the moat section asks what stops the *buyer* shipping it
  next quarter, and the financial summary runs to the sale date instead of stopping at 36 months.
- **A target stated as a range is solved at its corners, and a midpoint is a number neither end
  asserts.** Either axis may be stated as a range — a salary replaced in eighteen to twenty-four
  months, a sale at a value range inside a date range — and both at once is how an exit target
  normally arrives rather than an edge case. A value range over a date range is a rectangle, not
  a point: the corners are not equally hard, and which of them clear *is* the verdict. So a ranged
  target returns the set of corner verdicts, with the binding driver and its kind named per
  corner, which tells the founder which part of their own ambition is the problem and leaves the
  rest standing. Collapsed to its centre, a rectangle where three corners clear and one fails
  reads as a clean yes, and the corner that fails is usually the one the founder was aiming at.
  Two distinctions carry the subtle half of it. A stated range is **not** an assumption and does
  not trigger the flip test — that test runs on evidence uncertainty, the plausible range of a
  driver nobody sourced, while the corner solve runs on stated intent, which is the founder's own
  and needs no source; conflating them returns *undetermined* for every ranged target by
  construction, because a rectangle drawn across a real decision boundary is exactly one whose
  corners disagree, and that disagreement is the finding rather than a gap in the evidence. And
  the late end of a date range is not the easy end: it is cheaper on ARR, because the
  reference-class decay has more months to compound, and more exposed on the multiple, because
  the window closes. A founder who widens the date to make the target easier has bought ARR
  headroom with window risk nobody told them about. The plan carries the corners as a table with
  the founder's stated range and the evidence's range on separate labelled rows — both arrive as
  an interval with two ends, and merged the founder reads the whole width as their ambition being
  narrowed when half of it is the evidence admitting what it does not know.
- **A growth rate carries the ARR bucket it was measured in, and rates are compared only within a
  bucket.** Re-basing a comparable's series to months since a named origin controls for calendar
  time and market conditions; it does not control for **scale**, and nothing else recorded the ARR
  level a rate was posted at. So two companies sitting at month 18 — one posting around 20%/mo
  from a few hundred thousand in ARR, one around 4%/mo at tens of millions — were compared as
  commensurable and pooled into a month-18 range neither company's scale supports. It fires in
  both directions, which is why tagging one end of it is not enough: percentage growth off a small
  base is arithmetically easy and reads as a category norm, so a subject at low ARR is told its
  plan is unambitious against companies that were tiny when they posted those rates, while the
  same undifferentiated band makes the high-ARR rate look reachable at a scale nobody in the set
  achieved it at. Buckets are now declared as a property of the reference class, every rate is
  tagged with the one it was measured in, a comparable that crosses a bucket mid-series is tagged
  per stretch rather than per company, the decay is fitted per bucket where the set spans more
  than one, and the projection is checked against the bucket it will actually be in at that month.
  The exhibit carries the bucket too rather than leaving it to the caption — a chart that hides it
  re-creates the cross-bucket comparison in the one artifact a reader trusts without reading the
  prose.
- **A headline acquisition figure is not what the seller received, and the whole reference class
  skews high because of it.** Where the target is an exit, the disclosed acquisitions in the
  category are a second series on the same indexed axis — each sale placed at the month since the
  acquired company's own named origin and at its growth slope running into the sale, because slope
  is what the multiple is set by and a multiple with no slope beside it cannot be read at the
  month a roadmap puts its own sale. Built naively that set lies: earnout contingent on post-close
  targets, escrow released later or not at all, acquirer stock carried at the acquirer's own
  valuation, and retention packages that are compensation for the team rather than price for the
  company all sit inside an announced number. That is not one bad data point to drop — headlines
  are what gets published, and the components that reduce them are disclosed later, elsewhere, in
  less-read documents, so the bias belongs to the class, and naming survivorship does not catch it
  because these deals did close. The set therefore records the headline and what portion was
  actually received at close with the source for the split, and the band is drawn on consideration
  received, cash-only figure beside it. A comparable whose split cannot be found is labelled
  `headline-only, uncorroborated` everywhere it appears and never pooled with decomposed ones:
  pooled, it lifts the band by exactly the amount nobody could verify, and the label is the only
  thing telling a reader which end of the band rests on a figure and which on an announcement.
  Endpoints stay labelled with their company, ARR at exit, stage and slope rather than averaged
  into a mean multiple that describes no deal that happened; too few comparables to bound a band
  is written in those words — "two comparables, no band" — instead of a line run through a pair;
  and survivorship is stated outright beside the band, because nobody publishes the multiple they
  were offered and refused, so the set is what this category paid the sellers who said yes.
- **The red team reads the model's frame before it reads the model's numbers.** All three lenses
  reason *from* the plan document, so all three inherit its frame: a revenue model that assumes a
  flat curve, or that treats a founder's choice as a fixed property of the business, hands every
  panelist that frame as the ground they attack from. A structurally wrong model therefore drew
  three lenses' worth of detail objections and none about its shape, and the plan read as
  thoroughly attacked — the tell being a panel whose severest row argues about a value inside the
  identity while the identity itself carries a term nobody labelled. A pre-pass now runs before
  any brief is written and its output goes into every brief: the identity written out as a chain
  of terms ahead of any value in it, every input labelled `structural` or `policy` in those two
  words and never a coined third (a "semi-structural" is a way of not answering that reads as a
  finer distinction and survives review for exactly that reason), and the curve's shape — flat,
  decaying or compounding — stated as a claim with a named driver behind it rather than as the
  backdrop it was drawn on. A fourth lens would have inherited the same frame and arrived
  alongside the other three, too late to change what the panel was pointed at; that is why it is a
  pre-pass and not another voice. Where the target is an exit, the capital lens also swaps the
  funder's question for the acquirer's — which named buyer has a hole this patches, and is the
  product visibly the patch — because an exit plan otherwise collects a full investor-shaped
  objection table while nobody asks who buys it, and fundable and acquirable have different
  answers often enough that a pass on one says nothing about the other.
- **The vocabulary carries a version, and drift has a reconciliation path instead of an
  advisory.** Phase 0 already reported that a base definition had changed when an existing vault
  was reused, but a report that only says the definitions differ names no term: it hands the
  founder a corpus-wide re-read with no way to size it, and a task nobody can size is a task
  nobody starts, so the drift stays in place and the advisory becomes the noise people learn to
  skip. `vocabulary.yml` now carries a `vocabulary_version` and an `amendments` log, and Phase 0
  reports the delta plus every entry between the vault's stamp and the shipped one — per amended
  term the framing it carried (`was`), the framing it carries now (`now`), and the test each claim
  already filed under it has to pass (`must_assert`). A copy carrying no stamp predates the stamp
  and is older than every entry rather than equal to the current version, since reading an absent
  stamp as current would exempt exactly the vaults most likely to need reconciling. The version is
  owned by that file rather than by the plugin, and adding a term does not move it: bumping on
  additions would fire the advisory on every release that touched the file and train the founder
  to dismiss it before the one release where a definition actually moved. `vault-migration.md`
  carries the procedure as its own entry point — one grep per amended term bounds the entire
  scope, because only claims carry a subject; a claim that no longer asserts what the subject now
  asserts is superseded under the standing two-edit rule with `supersedes_reason` naming the
  amendment, never re-filed in place under wording its author never saw; the paragraph in the plan
  standing on that claim is rewritten with it, or the reconciliation moves the defect rather than
  fixing it; and the vault adopts the amended wording and stamps its copy **last**, because
  adopting first is the silent redefinition the extension rule bans.
- **The vault root is `~/Documents/go-to-market/<product-slug>/`.** `business` named the
  business-plan half of a pair that also produces the whole market analysis, so the folder a user
  goes looking for their competitor research in was named after the other skill. Same layout, same
  slug rule, same boundary — the slug directory itself is still the vault, with no `vault/`
  subdirectory — only the parent changed. A corpus created under the old root is not found by the
  reuse check, which `ls`es the parent for a folder naming the same product: move the slug
  directory and nothing breaks, because every citation, `rests_on` edge and research file inside
  it is vault-relative by design.
- **The gate resolves every `#anchor` in the shipped reference files.** A skill's method lives in
  reference files navigated by their own `## Contents` blocks, and the gate resolved a link by its
  path with the fragment stripped — `other.md#gone` passed on the strength of `other.md` existing,
  and a pure in-file `(#gone)` had no path to resolve at all. So an edit deleted a `## Heading`
  while the file's own Contents block went on linking to it and everything stayed green, caught by
  hand rather than by the check. Check 9 validates every anchor, in-file and cross-file, against
  the headings the target file actually renders, and a file carrying a `## Contents` heading that
  offers no list-item anchor link is itself a failure — an index rewritten out of link form would
  otherwise drop out of the check while body links elsewhere in the same file kept it green. The
  slug rule lives in exactly one place: two checkers with two sluggers drift apart silently and
  both get trusted.
- **Three of the rules above earn a quality bar, because prose in a reference file is not a
  producer.** A rule reaches an agent only when it is interpolated into a brief or performed by
  the conductor in a phase, so a rule stated once in a reference file reads correct on the page
  while nothing runs it. The ranged target's corner readout, the model-identity block every
  red-team brief now carries, and the exit red team's named-acquirer question are each on the list
  that says what may not ship, rather than resting on the paragraph that describes them.

## 1.3.0

- **The projection guard is symmetric — a flat line names its driver exactly as a hockey stick
  does.** The revenue build rejected a curve that was too optimistic and accepted, without a
  word, one that assumed nothing happens: every inflection point had to name an operational
  driver, while a stretch of zero growth had to name nothing at all. But zero growth is not the
  absence of an assumption — it is the assertion that next month's reach, conversion and mix are
  identical to this month's, which needs a driver (a hard channel cap, a fixed-capacity delivery
  model, a deliberate no-growth policy) or it is unmodelled rather than cautious. The two
  directions are not equally dangerous, and the flat one is worse: an over-projection gets
  challenged and an under-projection gets believed, so a flat line reads as conservative,
  therefore credible, therefore unexamined, and reaches the founder's decisions with nothing
  behind it.
- **Every steady-state input is labelled `structural` or `policy`, and a policy-bound ceiling is
  the ceiling of that configuration.** *Structural* is set by the market or the product — churn
  at the evidenced rate, the category conversion benchmark, the price band willingness-to-pay
  supports. *Policy* is set by a founder decision — channel count, hours a week, the price point
  chosen inside that band, headcount, how much of the growth engine gets built. Without the
  label the identity solved to a number and the number was reported as a property of the
  business, so a decision became a law of nature and its consequence was reported as physics —
  and a number reported as physics is one nobody argues with. A ceiling whose binding input is
  policy is now stated in those terms, with the ceiling under at least one changed policy value
  shown beside it: the same arithmetic, relabelled, moving the founder from "the business tops
  out below my goal" to "this configuration does". It rides on a new invariant, 18, because the
  discipline has to hold in a phase the head of the file is all that survives into.
- **A negative verdict may not rest on a driver the founder chooses.** The target decomposed
  into drivers and named the one that binds without ever asking what kind of thing that driver
  was — and reach, the driver that binds most often, is channels crossed with hours, which is a
  decision and not a ceiling. A negative verdict is the single output most likely to make a
  founder stop, and a policy-bound one stopped them over something they could revisit this week,
  reported in the same frontmatter and at the same confidence letter as an observation somebody
  read off a page and quoted. The driver-home table now carries a `kind` column, the
  classification runs before the verdict is written anywhere, and where the binding driver is
  policy the run returns "unreachable in the stated configuration" with that variable named and
  goes straight to the counter-offer and the lever table with it solved. Relieving it is also
  what surfaces the next binding driver — often a structural one, and the one actually worth
  telling the founder about.
- **Comparable growth rates become a band, and the projection is checked against it.**
  `market-analysis` already collected disclosed traction per competitor but never dated those
  points, so no rate was derivable and nothing downstream could tell a plausible curve from an
  invented one. Profiles now carry at least two dated traction points per competitor where
  available, absence is recorded as absence rather than omitted — an omitted competitor and one
  that disclosed nothing were indistinguishable, which let the band narrow to whoever happened
  to publish — and `competitor-analysis.md` emits an `## Observed growth band` as a named output
  alongside the category verdict, both endpoints labelled with their competitor and stage rather
  than averaged into a single number describing no company in the set. `business-plan` then
  places the projection's own implied monthly growth rate against that band and defends any
  excursion in either direction with a named difference, or re-cuts. Category growth and company
  growth are held apart where both appear, since a slow-category finding was otherwise free to
  justify a flat company projection.
- **Comparable growth curves are a research dimension with an indexed exhibit, and the plan
  checks shape as well as level.** The band above is a scalar: it reports a slowest-to-fastest
  %/mo range and carries no trajectory, so it cannot answer what comparables were doing at
  *month 18* — which is the only question a target with a date actually asks. Worse, an averaged
  rate hides growth decay in both directions at once, understating the early months and
  overstating the late ones and reporting one number for both, so a projection could sit
  comfortably mid-band on its average while asserting a shape no comparable in the set had ever
  had: flat where every one of them decayed, or one rate held across the whole horizon. A new
  Tier-1 dimension emits `research/growth-curves.md` and a `## Comparable growth curves` section,
  with each company's series re-based to months since a *named* origin event rather than to
  calendar time — companies founded years apart compared by date compare market conditions, not
  trajectories — and a decay fitted across the set rather than assumed. Where the points are too
  few to fit, the dimension says so as a finding; a two-point average presented as a trajectory
  is the thing it exists to prevent. A company whose origin cannot be dated stays in the corpus
  with its calendar series and is listed as held out of the indexed overlay, because an unlisted
  exclusion reads as a comparable nobody found. `business-plan` now runs both checks: the level
  check against the band, then the shape check placing the projection's implied trajectory
  against the indexed set at matching months since origin. The driver-home table's `conversion`
  and `reach` rows can take a reference-class value from that set too — a category benchmark is
  one figure standing in for every stage at once, which quietly asserts that a company six months
  from its origin converts like one forty months from it.
- **The curve exhibit reaches the plan's own deliverable, and the strategy record behind it has
  two consumers.** Both were authored and neither was connected, which is the defect this release
  kept producing: a rule that reads correct while nothing produces or consumes it. The indexed
  exhibit was written into `market-analysis.md`, and a `business-plan` engagement runs the
  research engine's Phases 1–4 and skips its deliverables — so on the only path that matters the
  chart existed as markdown in a file nothing rendered, and the standalone-research path was the
  one place it became an artifact. It now lands in `business-plan.md`'s Target & verdict section,
  under the verdict it argues about, and Phase 5's render loop checks it page-by-page with
  everything else. That section rather than Market or Financial summary because those are swapped
  out on the bootstrap, lifestyle and lender tracks and Target & verdict is not — parked in one of
  them, the exhibit vanishes from exactly the tracks whose target is a fixed income figure. The
  strategy record — what each comparable was doing to grow across each stretch of its curve,
  sorted into `policy` or `structural` for *this* founder — had no reader at all. Its policy half
  now corroborates the go-to-market motion after the three gates rather than instead of them, and
  its structural half routes to Key risks, where what comparables had and this founder does not is
  pre-stated rather than left for a reader to find. Both halves keep the record as a `claim`: it
  is evidence of what those companies did, never proof of what caused their curves, and since
  nobody publishes the channel that did nothing, adopting a comparable's channel because it worked
  for them buys a survivorship artifact at the price of the plan's primary motion.
- **The red team is told the binding driver's kind, and the flat-line rule finally has a bar.**
  Every panelist brief carried the target, the verdict and the driver named as binding, but not
  that driver's `kind` — so a panel handed "unreachable, reach binds" attacked whether the target
  was reachable, when the question worth attacking was whether the configuration was the one to
  run. The brief now carries the kind, on the same reasoning the paragraph already gave for
  carrying the verdict at all: a panel that is not told the verdict is policy-bound grants the
  configuration it was computed under, and no lens is otherwise tasked with that. The dispatched
  market-analysis brief's `provisionalVerdict` carries it too, because the kind changes what
  researching the binding driver hardest even means — a structural driver wants better evidence
  for the value it has, a policy one wants evidence for what it could be set to. And the symmetric
  flat-line guard, the first gap this release set out to close, was stated in the revenue build
  and diagnosed in the failure-modes table while the quality bars — the list that says what may
  not ship — gated only the checks derived from it. It has its own bar now, above the band and
  trajectory bars that test the same claim: that the curve's shape is asserted, not assumed.
- **An amended base definition is reported when an existing vault is reused.** This release is
  the first time a base definition in `vocabulary.yml` has ever been amended
  (`steady-state-ceiling`), and it exposed a gap: upgrading a vault picks up *new* base terms but
  never an amended definition of a term it already has. `vault-lint.sh` reads the vault's own
  `_vocab.yml` and never the shipped file, which is deliberate and stays — a vault must remain
  checkable against the vocabulary it was written under, or an amendment retroactively invalidates
  claims that were correct when filed. The consequence was that every vault created before this
  release keeps the superseded wording indefinitely, with every claim under that subject written
  against it and nothing saying so. Phase 0 already holds both files — it copies `vocabulary.yml`
  for a new vault and explicitly reuses an existing one — so the comparison is free there and now
  runs there: a base term whose definition changed is reported to the founder as an advisory that
  does not stop the run. It is not an error, because a vault written under an older definition is
  valid and only unreviewed, and erroring would break every existing vault on upgrade — the
  failure that makes people stop upgrading. The claims already filed under an amended subject are
  re-read against the new wording and superseded under the standing two-edit rule, rather than
  silently re-filed under a definition their author never saw.
- **Every dispatched brief now interpolates its playbook, and the exemption table no longer
  documents the defect it exists to catch.** The per-competitor profiling call hand-wrote a prompt
  restating the competitors playbook in its own words, which is how the dated-traction rule above
  reached the playbook and never the agent — and it was then patched by restating the rule a second
  time, leaving two sources of truth that read correct. The sizing reconciler was told to follow a
  playbook skeleton it was never handed. Both take the block itself now, and their hand-written
  halves shrink to what a playbook cannot know: which competitor, which output path, the return
  contract. `close-gap` keeps its exemption on an argued constraint rather than an open bug — the
  critic's gaps name no dimension and several classes have none to name, so a key guessed off the
  free text would hand a gap the wrong playbook, worse than none.

## 1.2.0

- **The target is the input the plan is engineered backwards from.** `business-plan` had no
  destination in it: `ambition` is a category and `timeline` asks only when the first dollar needs
  to arrive, so nothing in a plan could be measured against where the founder was actually trying
  to get, and the skill could not answer the question they came with — *will this get me there?*
  The grill now opens on a concrete outcome and a date, before every other question, because
  every other answer is read against it. A direction stated without a number is converted rather
  than accepted, since an unquantified target cannot be tested and an untestable target turns the
  verdict below into an opinion; "no specific number" is recorded as the answer it is.
- **The verdict on that target is computed from evidenced drivers, and names the driver that
  binds.** The target is decomposed into the identity that produces it — customers × price, and
  what each of those in turn rests on — with every driver taking its value from the research
  rather than from judgement. The output is which driver fails and by how much, not a bare yes or
  no: "unreachable" on its own is neither actionable nor falsifiable. It runs twice —
  provisionally after the grill, before the research fleet spends anything and while changing the
  target is still free, then again on the evidence before the plan drafts, free to overturn the
  first in either direction.
- **A driver with no evidence makes the verdict undetermined, not negative.** Where flipping an
  unevidenced driver within a plausible range flips the answer, the run returns "undetermined —
  and this is the cheapest thing to test", with the test named. A confident "no" resting on a
  guessed conversion rate talks a founder out of something the evidence never spoke to, and the
  vault's formality makes that guess look researched.
- **An unreachable target opens a negotiation, and is never silently swapped.** The run returns
  the nearest target reachable on the founder's stated resources, then hours, capital and price as
  separate counterfactuals of what the outcome becomes if each one moves. The founder chooses, and
  the original stays in the plan as the thing that was tested and failed, carrying its
  `supersedes_reason` — a renegotiated target is a supersession, not a retraction, or "wanted
  $50k, settled on $12k, and here is why" becomes an archaeology exercise instead of one query.
- **The vault is a git repo from its first commit, and gets a remote only when asked.** `git init`
  runs at scaffold and every meaningful write is committed, not only every phase boundary: a
  single research phase writes dozens of files, so the phase is the wrong unit of loss for a crash
  or a bad edit. It also gives a claim ledger the history it was missing — `vault-lint.sh` says
  what the corpus asserts now, `git diff` says what it stopped asserting, and nothing else
  answered the second question. Once there are deliverables worth sharing, the skill asks for a
  destination and a visibility with private preselected, and
  creates a remote only on an explicit answer to both; asked at scaffold it would be asking a
  founder to consent to the visibility of contents neither party has seen. Past that point every
  commit is pushed, because a remote that was opted into and never receives one reads as a backup
  and is not one.
- **A dimension is accepted on its file, never on the summary its own author wrote.**
  `market-analysis` told the conductor it reads summaries rather than raw dumps, which made a
  ten-line self-report the entire basis on which a dimension's numbers entered the plan. Five
  parallel researchers writing straight into `research/` are five unreviewed writers, and where a
  `vault:` path is present they also mint the `source` notes the plan later resolves its citations
  through — so the door the "read summaries" rule left open led directly to a citable number
  nothing had ever reviewed. The summary is now triage: it says which file to open first and
  whether the dimension is worth folding in at all, and the file itself is read before that
  dimension is cited or its notes are trusted. The context economy the old rule existed for is
  untouched, because the reading is targeted — one dimension file at the moment it is about to be
  relied on, not every agent's transcript — and `business-plan`'s per-dimension checkpoint, which
  already linted the vault while the researcher's context was still live, now gates on the read as
  well.

## 1.1.1

- **`README.md` catches up to the portable-vault layout.** `1.1.0` removed the `vault/`
  subdirectory — the engagement folder became the vault — but the README still pointed
  `vault-lint.sh` at a `vault` path that no longer exists, which would find no
  `.vault/config.json` and lint nothing. Fixed both stale paths, added an "On disk" section
  documenting the actual on-disk layout, and renamed the source-tree `## Layout` section to
  `## Repo layout` so the two don't read as the same thing.

## 1.1.0

- **The engagement folder IS the vault — the `vault/` subdirectory is gone.** A source with no public URL carries a *vault-relative* path, so anything a `source` note rests on has to be inside the vault or the path resolves to nothing. Research prose is exactly such a source: a competitor ledger or a dimension file frequently *is* the evidence. With the vault one level down, `research/competitors.md` read as vault-relative, resolved nowhere, and linted clean. Moving the boundary up also makes a corpus **portable** — copy the slug directory and every citation, every `rests_on` edge and every research file travels with it. A ledger whose evidence lives outside it is an index, not a ledger.
- **New lint check: `unresolved-local-source`.** A `url` with no scheme and no `prefix:` marker is read as vault-relative and verified to exist. This is the class of failure the layout change was found through: a missing file is not a malformed field, so every other check passed while the evidence was absent. A path that deliberately points outside the vault now needs an explicit marker (`slug:research/file.md`), and a bare `host/path` needs its scheme.

## 1.0.1

- **Install now points at `trinity-ai-labs/claude-plugins`.** The marketplace catalogue used to live inside `orchestration-skills`, so installing these skills meant adding an unrelated plugin's repo as a marketplace first. The catalogue moved to a repo that ships no plugin of its own. The marketplace *name* is unchanged, so `market@trinity-ai-labs` still resolves — only the `marketplace add` line moves.

## 1.0.0

First release. The `market-analysis` and `business-plan` skills, previously installed by a symlinking shell script, packaged as one plugin.

- `install.sh` is gone. The marketplace installs and updates both skills, so the symlink-into-two-skill-homes script has nothing left to do.
- `vault-lint.sh` moved from `scripts/` to `bin/`, and the skills now invoke it bare as `vault-lint.sh`. Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`; the old relative `scripts/vault-lint.sh` resolved against the user's own project directory, where nothing of the sort exists.
