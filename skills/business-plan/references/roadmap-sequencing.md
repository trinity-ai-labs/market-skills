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

## What lands in the plan

- The **assumption-moved table** (Rule 1) in or beside the roadmap section.
- The **chosen sequence with its permutation comparison** (Rule 3), compressed to the winning
  order and the runner-up.
- The **resource label** per item and the concurrency call that falls out of Rule 4.
- The **cheap levers**, called out as such.
- The **binding constraint**, once (Rule 6).

## What lands in the financial model

Every roadmap item that moves an assumption appears as a **dated change to that assumption's
row** — not as a separate revenue line. The model's curve is then a consequence of the roadmap
rather than a parallel story that happens to sit next to it.
