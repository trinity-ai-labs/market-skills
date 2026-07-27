# Target mode, and the vault as a repo

Design for two additions to `business-plan`: a founder-stated **target** the plan is engineered
backwards from and judged against, and optional **git management** of the vault.

Status: approved in design, not yet implemented.

## The entry this skill should have

The skill's intended use is closer to "here's my product, here's where I want to get to — tell me
if I'm wrong, and let's work out what's actually reachable, how, and by when" than to anything
the current entry supports. Two gaps stand between here and there.

**There is no target.** `ambition` is a category (lifestyle / bootstrapped-profitable /
venture-scale) and `timeline` asks only when the first dollar needs to arrive. Neither is a
destination, so nothing in the plan can be measured against one, and the skill cannot answer the
question a founder actually has: *will this get me there?* The only `target` in the skill today
means "target customer".

**The vocabulary is a barrier.** The grill's opening turns assume the founder can already
choose between ambition categories and motions. A founder who knows their number but not the
jargon has to learn the skill's model before the skill will help them.

The fix for both is the same: make the target the opening input, in plain language, and let the
skill translate it into the model it already has.

## The target is captured first, because every other answer is read against it

A target is a **concrete outcome plus a date** — `$20k MRR by June 2027`, `replace a $90k salary
in 18 months`, `1,000 paying users before raising`. It becomes the opening grill turn, ahead of
the existing bank.

A direction stated without a number is converted rather than accepted: "make this my job" is
answered with "what does the job have to pay?" An unquantified target cannot be tested, and a
target that cannot be tested silently turns the verdict below into an opinion.

The founder who has no target still gets asked; the question just returns "no specific number",
which is itself recorded and changes the plan's framing rather than being treated as an error.

## The vault needs no schema change to hold it

The target is a `fact` note resting on the grill's `source` note. The reachability verdict is a
`claim` note resting on that target fact plus the sizing, pricing-floor and resource facts.

Two properties fall out of the existing invariants rather than needing new machinery:

- **Confidence derives correctly** (invariant 11, `min(confidence_own, every rests_on target)`).
  A verdict resting on a low-confidence sizing figure cannot be asserted as a confident
  "impossible". The rule that already prevents a hedge from being laundered into a headline
  claim prevents it here too.
- **Renegotiation stays auditable** (invariant 14, retraction is visible). When a target is
  renegotiated, the superseded target fact stays with `status: retracted` and its reason, and a
  new target fact is minted. "Wanted $50k, settled on $12k, and here is why" remains in the
  ledger instead of being overwritten by the number that won.

No new note type, no `schemaVersion` bump, and no change to `vault-lint.sh`.

## A verdict is computed from a driver identity, never asserted

**The verdict is computed from a driver identity, never asserted.** The target outcome is
decomposed into the drivers that produce it — for a revenue target, `MRR = paying customers ×
price`, with paying customers in turn a function of reach, conversion and retention; for a
user-count target, the equivalent chain. Each driver takes its value from evidence: price from
the pricing/willingness-to-pay dimension, conversion and retention from category benchmarks
carrying their source, reach from what the founder's actual channels support at their stated
hours and budget (the resource facts from the grill).

**The verdict names the binding driver, not just a yes or no.** The useful output is which
driver fails and by how much — "the target needs roughly 220 paying customers by month 12; the
channel you would actually run supports about 40 at 6 hours a week on the evidenced conversion
rate" — because that is the sentence a founder can act on. A bare "unreachable" is not
actionable and is also unfalsifiable.

**A driver with no evidence makes the verdict undetermined, not negative.** Any driver value
not traceable to a source is an `assumption` note carrying its sensitivity. If flipping that
assumption within a plausible range flips the verdict, the run returns "undetermined — and this
is the cheapest thing to test" with the test named, rather than a verdict. A confident "no"
resting on a guessed conversion rate talks a founder out of something the evidence never
actually spoke to, and the vault's formality makes that guess look researched.

**A verdict also carries a confidence ceiling, on top of invariant 11's derivation.** A verdict
is a forecast about an unrun future, not a citation of an observed quantity, so it carries two
limits: invariant 11 caps it at its weakest input, and on top of that a verdict is never
asserted at high confidence at all. Without that second ceiling the vault renders a forecast
and a cited market size in the same shape, and a projection silently inherits the authority of
an observation.

## Two verdicts, because a late-only verdict wastes a whole research run

**The provisional verdict** runs right after the dossier and the grill, before the research fleet
spends anything. It is recorded as an `assumption` carrying its sensitivity — never a `fact` — so
nothing downstream can cite it as though it were researched. This is where the cheap
"want to talk about this now, or should I go find out properly?" turn happens, and it is cheap
precisely because nothing has been spent yet and changing the target is still free.

**The evidence-backed verdict** runs after research, before the plan drafts, as a `claim` note.
It may overturn the provisional verdict in either direction, and saying so explicitly is part of
its output. The red team then attacks the verdict itself, not only the plan built on it.

The failure this two-stage shape prevents: a founder states a target, waits through a full
research run, and is then told the number was never reachable. The failure the *late* verdict
prevents in turn: a cheap gut-check talks a founder down from a target the research would have
supported, which is why the provisional one is an assumption that the researched one is free to
overturn.

## An unreachable target opens a negotiation, and is never silently swapped

When the verdict is negative the run does not stop, and it does not quietly substitute a smaller
number. It makes a counter-offer that opens a conversation:

1. The stated target, and why it does not clear on the evidence.
2. The nearest reachable target on the same evidence.
3. The levers that would change the answer — hours, capital, price — each with what it would
   have to become.

The founder chooses. The plan is then built against the settled target, and the original stays
visible in the plan as the thing that was tested and failed, with its retraction reason.

Report-and-stop was considered and rejected: it leaves a founder with a "no" and no path, which
is the opposite of what the skill is for. Planning against the stated number with a caveat
somewhere was rejected for the reason the skill already gives for bad grill answers — a wrong
premise let through makes every downstream milestone fiction.

## The plan answers "how" and "by when", not just "whether"

The financial model gains a **solve-backwards** pass. Today it projects forward from assumptions;
it additionally solves for what has to be true to reach the settled target by its date — the
customer count, the price, the conversion rate, the month each has to arrive.

Milestones become dated checkpoints against that solve, so a missed checkpoint reads as slippage
against a known trajectory at the moment it happens, rather than surfacing as a shortfall at the
end.

## The vault is a git repo from the start, and gets a remote only when asked

**Local, automatic, at scaffold.** Phase 0 runs `git init` at the slug directory and commits at
each phase boundary. This has no exposure — there is no remote — and it is worth doing by default
for a claim ledger specifically: retractions, amendments and confidence changes become a diffable
history, which is what a ledger is for. `vault-lint.sh` and `git diff` answer different questions
about the same corpus.

This works cleanly *because* the engagement folder is itself the vault (v1.1.0). A repo rooted at
the slug directory captures the research prose that citations rest on; under the old nested
layout, a repo rooted at the vault would have left that evidence outside its own history.

**The remote is a separate decision, asked later.** Not at scaffold — asking whether a folder
should be public before anything is in it asks the founder to consent to contents neither party
has seen. It is asked once there are deliverables worth sharing, or whenever the founder asks,
and it collects:

- **Destination** — which account or organization.
- **Visibility** — private preselected.

Private covers the ordinary case. Public is a legitimate choice that some founders make
deliberately, and it is offered as such; what it is not is a default.

## A shared vault needs its own README, regenerated at each phase boundary

A vault that becomes a shareable repo needs a generated `README.md` of its own, at the slug
directory root. Without one, a shared vault is a directory of `CLAIM-AS23SD44.md`-style files
whose names are deliberately bare IDs — legible to the skill and opaque to a human opening the
repo cold. The recipient cannot tell what the corpus is, which skill produced it, what the note
types mean, or which file to read first.

It is generated, and regenerated at each phase boundary, so it does not drift from the corpus it
describes. A stale README on a shared repo is worse than none, because it reads as current.

It carries: what the product is, what this corpus is and which skill produced it, the note-type
map, where to start reading (`one-pager.md`, then `business-plan.md`), the current target and its
verdict status, and the `vault-lint.sh` invocation for checking the corpus. It is a generated
artifact, so it is regenerated rather than hand-edited — the README says so in its own text.

The same phase-boundary step also generates a `.gitignore`. Rendered `deliverables/*.pdf` are
deliberately committed rather than ignored, since they are the artifact a shared vault exists to
share.

## Where the changes land

| File | Change |
| --- | --- |
| `skills/business-plan/SKILL.md` | Target capture in Phase 1; both verdicts; the negotiation turn; `git init` in Phase 0's scaffold; the remote question after Phase 5 |
| `skills/business-plan/SKILL.md` | The vault's own `README.md` and `.gitignore`, generated in Phase 0 and regenerated at each phase boundary |
| `skills/business-plan/references/grill.md` | The target as the opening question, with its conversion rule for unquantified answers |
| `skills/business-plan/references/strategy-sim.md` | The solve-backwards pass |
| `skills/business-plan/references/plan-template.md` | The verdict section, and dated checkpoints |
| `skills/market-analysis/SKILL.md` | Receives the target as context only, so sizing is done at the resolution the target needs |
| `README.md` | A section covering target mode and the vault-repo question — see below |
| `.claude-plugin/plugin.json`, `CHANGELOG.md` | Minor bump; this is shipped behavior |

## The docs ship in the same PR as the behavior

v1.1.1 exists only because v1.1.0 changed the on-disk layout and left the README describing the
old one — including a `vault-lint.sh` invocation pointing at a directory that had stopped
existing. The change was correct and the docs were stale in the same release, so the first thing
a new user read was wrong.

So the README section for target mode is part of the implementation PR, not a follow-up. The
standing form of this rule belongs in `AGENTS.md`, where the failure it prevents is now a matter
of record.

## Out of scope

- No new vault note type and no `schemaVersion` change. The target and the verdict fit the
  existing `fact` / `claim` / `assumption` types, and anything that forced a schema change would
  also force a `vault-lint.sh` change and a migration.
- No change to how `market-analysis` researches. It gains the target as context and nothing else;
  it stays usable on its own, where no target exists.
- No automatic pushing, and no remote created without an explicit answer to both questions.
