# Roadmap sequencing — sequencing IS projection

Companion to `strategy-sim.md`. Load it whenever the plan contains a roadmap and a financial
model, which is every track.

**The failure this prevents:** a roadmap written as a feature list, ordered by enthusiasm or by
what's nearly done, sitting next to a financial model whose assumptions it never touches. The
two documents look consistent because neither references the other. They aren't — the roadmap
is a set of claims about when the model's inputs change, and if it never says which ones, the
model's curve is decoration.

## Rule 1 — every roadmap item names the assumption it moves

An item that moves no assumption is not a roadmap item. It's maintenance, and it belongs in a
maintenance line, not in a plan a reader is asked to believe.

| Item | Assumption moved | Direction & size | Confidence |
|---|---|---|---|
| New-platform GA | trial volume (A-n) | +X% trials from M6 | M — bound, not a date |
| Team-invite flow | seats per account (A-n) | 1.0 → 1.4 | L — mechanism shipped, untested |
| Internal refactor | — | none | **not a roadmap item** |

Write the table. If a majority of items have an empty middle column, the roadmap is a backlog
wearing a plan's clothes, and the honest move is to say so to the founder rather than pad the
model.

**Corollary:** an item whose assumption is already at its ceiling moves nothing. Check the
assumption's range before crediting the item.

## Rule 2 — items unlock each other; levers multiply, they don't add

Two items that each move a different term in the same formula compound. Two items that move the
same term compete, and crediting both is double-counting.

Given `seats = trials × conversion × seats-per-account ÷ churn`:

- Windows GA (trials) **×** second-seat flow (seats-per-account) → multiplicative. Shipping both
  is worth more than the sum of shipping either.
- Two separate onboarding improvements both aimed at conversion → **not** additive. Model the
  better one and treat the second as insurance.

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

## What lands in the plan

- The **assumption-moved table** (Rule 1) in or beside the roadmap section.
- The **chosen sequence with its permutation comparison** (Rule 3), compressed to the winning
  order and the runner-up.
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
