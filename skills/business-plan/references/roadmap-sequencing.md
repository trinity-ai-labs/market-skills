# Roadmap sequencing — sequencing IS projection

Companion to `strategy-sim.md`. Load it whenever the plan contains a roadmap and a financial
model, which is every track.

**The failure this prevents:** a roadmap written as a feature list, ordered by enthusiasm or by
what's nearly done, sitting next to a financial model whose assumptions it never touches. The
two documents look consistent because neither references the other. They aren't — the roadmap
is a set of claims about when the model's inputs change, and if it never says which ones, the
model's curve is decoration.

## Rule 1 — every roadmap item names the assumption it moves, and the note is what names it

An item that moves no assumption is not a roadmap item. It's maintenance, and it belongs in a
maintenance line, not in a plan a reader is asked to believe.

**Every item in this table is a `milestone` note, and `moves` is where the middle column is
recorded.** The table is what a reader sees; the note is what anything can check. That split is
the whole of the mechanism: `moves` is a block list of note IDs, so an item naming an assumption
the vault does not carry is an ordinary `dangling-edge` failure, and an item with no `moves` at
all is a `required-field` failure whose message says what the absence costs. The schema is
[vault.md](vault.md#the-milestone-note-carries-a-position-a-cost-and-the-assumption-it-moves).
**The failure this closes:** this rule was prose for as long as it existed and nothing read it,
so an item could name an assumption that was never written, or name none, and the plan shipped
looking exactly like one whose every row resolved.

**The item cell is the milestone `title`, character for character, and
`vault-lint.sh --roadmap-table` reads the two against each other both ways.** The table renders
off the notes, so a correct one matches verbatim by construction — the same rule `chosen` is held
to against `options`, and for the same reason: a paraphrase makes the record unreadable later.
A row matching no note is an item that escaped the ledger; a note the table never lists is a
dated change to an assumption row the plan does not show, so the curve gets a step the reader
cannot see. **The failure that closes:** the split above made the note checkable and left the
TABLE hand-maintained, so a row could be reworded, added or dropped after the notes were written
and nothing in the corpus could tell.

**`moves` holds the assumption's note ID. The `(A-n)` in the middle column below is the label the
plan's assumptions table carries for a reader, and it never goes in the frontmatter** — a note ID
resolves to a note, an `A-n` label resolves to a row in a document the vault cannot read. Writing
the label into `moves` is a `malformed-edge` failure, named separately from `dangling-edge`
because nothing is missing from the vault: the field never named a note. It is called out here
rather than left to the lint because the table one paragraph down is where an author looks before
writing the note, so the row label is the value that comes to hand first.

| Item | Assumption moved | Direction & size | Confidence |
|---|---|---|---|
| New-platform GA | trial volume (A-n) | +X% trials from M6 | M — bound, not a date |
| Team-invite flow | seats per account (A-n) | 1.0 → 1.4 | L — mechanism shipped, untested |
| Unassisted setup for the core job | monthly churn (A-n) | 4.0% → 3.2%, mid-band to upper | L — `assumed`, base is the assisted cohort's rate |
| Internal refactor | — | none | **not a roadmap item** |

Write the table. If a majority of items have an empty middle column, the roadmap is a backlog
wearing a plan's clothes, and the honest move is to say so to the founder rather than pad the
model.

**Churn is a legitimate value in the middle column, and it is the one that needs its base stated
in the row.** A roadmap item that makes the product deeper or its valuable part reachable
unassisted moves where the product sits inside the category's retention band, which is a position
the product owns rather than a floor the category sets. So the row carries three things a trial-
volume row does not need: the band, the position it moves from and to, and the label on the size —
`measured`, `reference-class` or `assumed`, with an `assumed` one solved at both ends of its range.
**The failure that prevents:** churn is the divisor in Rule 2's identity, so a retention row is
worth more per unit of effort than any other row in the table, and a row with no base under it lets
the roadmap credit whatever improvement the target happens to need.

**Corollary:** an item whose assumption is already at its ceiling moves nothing. Check the
assumption's range before crediting the item. For a retention item the ceiling is the top of the
category band, not zero churn — an item claiming past it is claiming the roadmap changes the
category.

## Rule 2 — items unlock each other; levers multiply, they don't add

Two items that each move a different term in the same formula compound. Two items that move the
same term compete, and crediting both is double-counting.

Given `seats = trials × conversion × seats-per-account ÷ churn`:

- Windows GA (trials) **×** second-seat flow (seats-per-account) → multiplicative. Shipping both
  is worth more than the sum of shipping either.
- Two separate onboarding improvements both aimed at conversion → **not** additive. Model the
  better one and treat the second as insurance.

**Churn is a term of that identity like any of the others, and the same two readings apply to it.**
An item that lowers churn compounds with every item moving a numerator term — a deeper product that
retains better multiplies against the trial flow the platform launch bought, rather than adding to
it — and because churn is the DIVISOR, a proportional move there is worth more than the same
proportional move anywhere else in the formula. Two items both aimed at retention compete: an
unassisted-setup item and a deeper-core-job item both work on the product's position inside one
band, so model the better one and treat the second as insurance, exactly as with the two onboarding
items above. **The failure this prevents:** retention items are the ones a roadmap is most tempted
to sum, because each has its own mechanism and they read as independent — summed, they walk the
divisor down past the band the category supports, and the ceiling that falls out is a property of
the arithmetic rather than of the plan.

**Never sum item values.** Compute the sequence.

## Rule 3 — sequence value ≠ sum of item values. Permute the top 3–4 and compute.

Order changes the total, because an item that raises a multiplier early raises everything
downstream of it. With three candidate items there are six orders; with four, twenty-four.
Compute the top handful rather than asserting one.

The output is a table, not a paragraph:

| Order | 12-mo cumulative | Δ vs chosen |
|---|---|---|
| A → B → C | … | — |
| B → A → C | … | … |

If two orders land within noise of each other, say so and pick on risk instead of value — that
is a legitimate and honest tiebreak.

## Rule 4 — check resource-independence BEFORE ranking by value

**This is the rule that most often changes the answer, and it is the one people skip.**

Two items only compete if they consume the same constrained resource. Before you rank by value,
label each item with what it actually consumes:

- founder hours
- an external dependency on someone else's clock (certification, KYC, a partner, an app-store
  review, a legal opinion)
- capital
- a hire that hasn't happened

**Items gated on different resources do not compete and can run concurrently.** A naive
value-ranking will serialise them and lose the difference.

> **Worked example.** A plan ranked item A above item B on raw value and sequenced B second.
> A was gated on an **external certification clock** the founder could not compress; B was gated
> on **founder time**. They consume different resources, so B could run *during* A's wait at no
> cost to A. The naive ranking was wrong not about the values but about the structure — and
> shipping both in the same window was strictly better than either ordering it had considered.

Practical form: start the long-lead external dependency **on its original calendar date,
regardless of its rank**, and fill the wait with whatever is gated on a resource you control.

**The label is the `resource` field on the milestone note, and it is what makes this rule the
only one here a tool can settle** — two items declaring the same `resource` at the same
`sequence` are a `false-independence` failure, and two declaring different resources at the same
`sequence` pass, which is the worked example above exactly. The field and what its absence costs
are in
[vault.md](vault.md#the-milestone-note-carries-a-position-a-cost-and-the-assumption-it-moves).
**The failure this closes:** a *false* independence claim is the one this rule already warned
about and nothing could see, because the plan it produces reads as though both items land.

## Rule 5 — a cheap item that moves an assumption beats an expensive one that doesn't

Rank by *value per unit of the constrained resource*, not by value. A one-line constant change
that raises a ceiling can outrank a subsystem, and a plan that can't see that is optimising the
wrong quantity.

Flag these explicitly as **cheap levers** in the roadmap section. They are the highest-return
rows in the table and they are the ones a feature-shaped roadmap systematically hides.

## Rule 6 — state what the roadmap is gated on, once, in the plan

One sentence naming the binding constraint across the whole roadmap — founder hours, capital,
a hire, an external clock. Every downstream milestone claim inherits it. A roadmap that doesn't
name its constraint reads as though everything can happen at once, which no reader believes and
which destroys the credibility of the items that *are* real.

**Write the sentence from the notes rather than from memory: the binding constraint is whichever
`resource` value the most items declare, and it is a count, not a judgement.** A roadmap whose
`resource` labels say `founder-hours` on six of eight items is gated on founder hours whatever
the plan's prose says, and the two disagreeing is worth noticing before a reader does it for you.
`research/timeline.md` carries the same set per item, so the sentence and the artifact under it
can be read against each other in one pass.

## Rule 7 — for an exit target, an item may move a multiple input rather than a model assumption

Rules 1–6 assume an item earns its place by moving a row in the financial model's assumptions
table. An exit target breaks that in one direction: `exit value = ARR at exit × multiple`, and the
assumptions table covers the left term only. An item aimed at the right term — making the product
legible as the patch for a named acquirer, holding the growth slope through the sale month — moves
nothing on that table, so Rule 1 files it as maintenance. For a plan whose target is a sale that is
exactly backwards: it demotes the items aimed at the term the verdict is most sensitive to, and it
does so quietly, because the table it fails is the right table for every other kind of target.

**So the "assumption moved" column takes a multiple input as a legitimate value**, named from
[target.md](target.md#the-multiples-inputs-have-homes-too-and-not-one-of-them-is-arr)'s four:
growth slope at the moment of sale, strategic necessity to a named acquirer, scarcity, and the
bidder count. Carry each input's `kind` into the column, because it bounds what an item can
honestly claim — slope and the named acquirer are **policy**, which is what makes them movable by a
roadmap at all, while scarcity and the bidder count are **structural**, set by the category and the
buyers in it. An item claiming to move a structural input is claiming the roadmap changes who else
could build this; that is either a real moat item with the argument written out, or a wish.

| Item | Assumption moved | Direction & size | Confidence |
|---|---|---|---|
| Audit-trail export | strategic necessity to named buyer A (**policy**) | closes the compliance hole that buyer files against | M — the hole is named, the buyer's intent is not |
| Second integration surface | bidder count (**structural**) | 1 → 2 buyers with the same hole | L — the second buyer's hole is inferred, not evidenced |
| Onboarding rebuild | trial→paid conversion (A-n) | 4% → 6% from M4 | M |

**The slope term is dated to one month, not averaged over the horizon.** An item that lifts the
level across the plan and leaves the curve flattening by the sale month *lowers* the exit value,
because the multiple is read at the slope standing on the sale date rather than at the total
reached by it. This is the one place sequencing-is-projection has a wrong answer that looks right:
the order maximising 12-month cumulative can be the order that arrives at the sale month
decelerating, and Rule 3's permutation table will rank it first unless its column is measured at
the sale month rather than at a fixed twelve.

## Rule 8 — an adoption candidate is the other legitimate source of an item, admitted or refused

Rules 1–7 assume an item comes from the founder's own intent. `competitor-analysis.md`'s
`## Adoption candidates` section is the other source — what the profiled set already does better
than this product — and each candidate there is written as the fields a `milestone` note is
authored from: the change as a title, what it moves, the resource it spends, and the evidence it
rests on. So a candidate reaches Rule 1 with its middle column already filled, and nothing above is
relaxed to admit it. What differs is **provenance, and it belongs in the note's `rests_on`**: an
ordinary item rests on what the founder intends to make true, and this one on evidence a competitor
already paid to learn. A reader who cannot tell the two apart reads a demonstrated item at the same
strength as an intended one.

**Every candidate is adopted and dated, or refused with the reason on the record.** A candidate
that is neither is the failure this route exists to close: it leaves the roll-up that produced it
reading as a list nobody disagreed with, while the cheapest move available to a founder — copy the
part that already works, from a company that has already paid to learn it — never reaches the plan.
Refusing one costs a sentence. Dropping one costs nothing and is invisible, which is why this rule
is stated as a disjunction with no third branch.

**A candidate that moves no assumption is maintenance, and saying so IS the refusal.** Rule 1's bar
applies to it unchanged, and the producer is required to name what a candidate moves even where the
answer is nothing — precisely so this refusal can be written rather than inferred. So
*"maintenance, moves nothing"* on the record is a complete answer while an omission is not: the two
are indistinguishable one document later, and the second is what lets a candidate be refused on a
technicality nobody recorded.

## What lands in the vault

One `milestone` note per roadmap item, before the table is written. The table is a rendering of
that set — the item, its `moves` target, its `resource` and its `sequence` — so writing the notes
first is what stops the two from being two hand-maintained lists that drift, and
`vault-lint.sh --roadmap-table` is what makes that a check rather than an instruction. The generated
`research/timeline.md` is the other rendering: state at M0, the sequence with what each item
unlocks, and the chains a proposal has to walk to reach the month it would land in.

An item adopted from the research names the competitor evidence it came from in `rests_on`
(Rule 8), which is the only place the distinction survives: the table renders `moves`, `resource`
and `sequence` and has no column for where the item came from.

## What lands in the plan

- The **assumption-moved table** (Rule 1) in or beside the roadmap section, and **first** in it.
  Only the first table under the roadmap heading is read against the ledger, and the item column
  is the one headed `Item` — so the permutation table below it, whose first column is an order,
  is not mistaken for a set of items with no notes behind them.
- The **chosen sequence with its permutation comparison** (Rule 3), compressed to the winning
  order and the runner-up, **below** the item table.
- The **resource label** per item and the concurrency call that falls out of Rule 4.
- The **cheap levers**, called out as such.
- The **binding constraint**, once (Rule 6).
- For an exit target, the **multiple input** each such item moves and that input's kind (Rule 7),
  and the permutation table measured at the sale month.

## What lands in the financial model

Every roadmap item that moves an assumption appears as a **dated change to that assumption's
row** — not as a separate revenue line. The model's curve is then a consequence of the roadmap
rather than a parallel story that happens to sit next to it.

An item that moves a **multiple input** has no row here to change — the assumptions table models
ARR, and the multiple is not in it. It lands instead against the band it moves, in the plan's
Target & verdict section beside the corner verdicts. Forcing it into the model as a revenue row is
how an acquirer-legibility item gets credited twice: once as the ARR it does not produce, and again
as the multiple it does.
