# market-skills

Two agent skills that take a product to market, packaged as one plugin. Both are **model-invoked** — Claude reaches for them on its own from the frontmatter `description`, so you rarely type them.

- **`market-analysis`** — heavy, evidence-first market research for a product (a code repo, a
  spec/doc, or an idea): value-hypothesis extraction, multi-agent competitor discovery and
  profiling, bottom-up market sizing, customers/JTBD, pricing & willingness-to-pay, timing,
  channels, moats — plus infra-cost archaeology on repo sources (derive COGS from the actual
  stack, project cost vs revenue at scale) — with adversarial verification of every
  load-bearing number.
- **`business-plan`** — the conductor that grills the founder, runs `market-analysis` as its
  research engine, and produces the plan artifact the founder's track actually needs
  (investor memo / bootstrap operating plan / lender classic) plus a one-pager, a bottom-up
  financial model with strategy simulations (bootstrap vs raise as parallel paths, beachhead
  sequencing, profit-reinvestment loops, pre-committed switch triggers), an adversarial
  red-team pass, and a growth-engine section that turns GTM into automated per-product agent
  skills (content, screenshots/video, docs-sync).

Both write deterministically to `~/Documents/go-to-market/<product-slug>/` (same product → same
folder, re-runs update in place) and render polished, self-contained HTML + page-verified PDF
deliverables.

The pair is designed to run **workflow-heavy**: research fans out to fleets of sub-agents
(multi-modal competitor discovery, per-competitor profiling, refutation panels, a completeness
critic) with explicit model/effort tiering per stage — cheap models for the fleet, strong
models only for reconciliation and synthesis. See
`skills/market-analysis/references/orchestration.md` for the canonical workflow script.

`business-plan` dispatches `market-analysis` itself and shares its rendering reference — they
ship as a pair, always, which is why one plugin holds both.

---

## Install

```
/plugin marketplace add trinity-ai-labs/claude-plugins
/plugin install market@trinity-ai-labs
```

Then enable auto-update: `/plugin` → **Marketplaces** → `trinity-ai-labs` → **Enable auto-update**. It is off by default for third-party marketplaces.

⚠️ Updates land on a **version bump**, not on a push. `plugin.json` declares `version`, so an install is pinned to that string — CI fails the build if shipped content changes without bumping it, so this can't happen silently. See [CHANGELOG.md](CHANGELOG.md).

**To develop these skills**, clone and link each one into your skills directory instead — edits then apply live, no release step:

```bash
git clone https://github.com/trinity-ai-labs/market-skills
ln -s "$PWD/market-skills/skills/market-analysis" ~/.claude/skills/market-analysis
ln -s "$PWD/market-skills/skills/business-plan"   ~/.claude/skills/business-plan
```

Link the two skill directories, not the repo: Claude Code loads `~/.claude/skills/<name>/SKILL.md`,
so cloning the whole repo into that directory buries both `SKILL.md`s a level too deep and
registers nothing. The other thing a clone does not give you is `vault-lint.sh` on the agent's
`PATH` — that happens only for an installed plugin, so invoke it by path while developing.

---

## Use

- "Run a market analysis on this repo" / "analyze the market for <idea>" → **market-analysis**
- "Build me a business plan for this" / "how do I take this to market" / "can I get this to $20k
  MRR by next June?" → **business-plan** (which dispatches market-analysis itself)

Point either at a repo (most common), a spec/PRD/doc, or just describe the idea. Interactive
runs open on your target, then grill you on the genuine gaps — the questions research can't
answer — before spending research tokens. Everything lands in `~/Documents/go-to-market/<product-slug>/`,
including `deliverables/*.html` and page-verified `deliverables/*.pdf`.

To force one, name it: `/market:market-analysis` or `/market:business-plan`.

When dispatching sub-agents, name the skill as an explicit first step — a sub-agent won't reach
for it on its own as reliably as the main thread does:

> Step 0: invoke the `market:business-plan` skill.

---

## You state a target; the skill tells you whether it is reachable

The entry to `business-plan` is a product and a **target** — a concrete outcome and a date
(`$20k MRR by June 2027`, `replace a $90k salary in 18 months`, `sell for $30–50M in 3–5 years`)
— and the plan is engineered backwards from it. Plain language is fine: a direction with no number
gets converted into one ("make this my job" → "what does the job have to pay?"), and "no specific
number" is a legitimate answer that changes the plan's framing rather than stalling the run.

An **exit** is a supported shape, not a revenue target in disguise: it decomposes as ARR at the
sale date times a *multiple band*, and the multiple — set by your growth slope at the moment of
sale, by which named acquirer has a hole this patches, by how buildable the asset is, and by how
many buyers have that same hole — is usually what binds. Either axis can be stated as a **range**,
and a range on both is a rectangle solved at its corners rather than averaged to a midpoint: you
get back which corners clear and which do not, so you can see whether it is the value or the date
that is the problem.

The verdict on that target is **computed from evidenced drivers, not asserted**, and it names which
driver binds and by how much — "reach binds: the target needs about six times the monthly reach your
channels evidence at the hours you gave" — because that is the sentence you can act on. Where the
driver that binds is one **you chose** — your hours, your channel count, the price point you picked,
or how well what you built holds onto the people it reaches — the answer comes back as unreachable
*in that configuration*, with the value that variable would have to reach, rather than as a verdict
on the target: a constraint you could revisit this week reads very differently from one the market
sets, and you are told which of the two you are looking at. Where the evidence can't carry a verdict
at all, it says so and names the cheapest test instead of guessing: a confident "no" resting on a
guessed conversion rate talks you out of something the evidence never spoke to.

That scrutiny runs in **both directions**. A cautious number is a claim about your business
exactly as an ambitious one is, so every value in the model names what drives it whichever way it
points, and a low one with nothing behind it comes back *unmodelled, not conservative* rather than
passing as prudence — half a dozen individually defensible low guesses multiplied together move a
verdict by orders of magnitude and arrive looking like a finding about your market. It points the
other way too, at the numbers that flatter what you built, and that is the harder half: a claim
that your product holds onto people better than the rest of the category, or that it is worth more
to a buyer than what they would otherwise assemble, comes with the real figure it was worked out
from and says whether the size of the effect was measured on actual users, taken from comparable
companies, or simply assumed — and an assumed one gets checked at both ends of its range like any
other number in the model. Those are the easiest figures in a plan to write and the hardest to push
back on, because pushing back on them sounds like pushing back on the product. The set of
companies you are measured against is an input too, named and tested like any other: where two
defensible comparison sets disagree about whether the target clears, you get *undetermined* and
the cheapest test that settles which one you are in. And not having launched yet is not held
against you — a driver the market sets, with no data of your own behind it, takes its value from
that indexed set with the shelf life and kill test that come with it, instead of being filed as a
guess that drags the whole plan's confidence down for a reason that is routing rather than
evidence.

A price is held to the same standard, and it is argued from **both sides** rather than one: what
the buyer would otherwise have to assemble — the tools, the integrations and the fraction of a
person who keeps the whole thing working — and what the buyer can produce with your product that
they could not before. Argued from the substitute's cost alone, the price ends up anchored to
whichever side somebody happened to add up, and that is almost always the cheaper one, because a
substitute is easy to total and an outcome is not.

An unreachable target opens a **negotiation, not a rejection**: the stated target and why it
doesn't clear, the nearest target reachable on the resources you stated, and the levers — hours,
capital, price, or for an exit the slope, the named acquirer and the date — with what each would
have to become. You choose, and the original stays visible in the plan as the thing that was
tested.

The vault is a **git repo** from its first commit, so a claim ledger's retractions, amendments and
confidence changes become a diffable history. It is local-only by default; once there are
deliverables worth sharing it asks where a remote should live and whether it is public or private,
private preselected, and creates nothing without an explicit answer to both.

The run also inventories and measures your own artifacts — repos you've written or worked in,
documents you produced for clients, products in the category you've used — rather than only
asking about them. Where those documents are confidential, the corpus records what they
establish with a provenance note, never the file itself.

---

## On disk

`~/Documents/go-to-market/<product-slug>/` **is** the vault — there is no `vault/` subdirectory.
The slug directory itself carries `.vault/config.json`, and everything else the skills produce
lives inside it:

```
~/Documents/go-to-market/<product-slug>/
├── .vault/config.json       # schemaVersion — a directory without it is not a vault
├── _vocab.yml               # controlled subject vocabulary
├── sources/ facts/ claims/ assumptions/ questions/ decisions/ milestones/ # one file per note
├── research/                # all prose — market-analysis dimensions, product-dossier.md,
│                            #   founder-brief.md — untouched by the vault machinery.
│                            #   timeline.md is the exception: generated from milestones/
├── sources.md               # the [S#] index
├── one-pager.md  business-plan.md  financial-model.md  red-team.md # plan documents
├── deliverables/            # rendered business-plan.html/.pdf, one-pager.html/.pdf
├── market-analysis.md       # market-analysis's output —
└── competitor-analysis.md   #   owned by that skill, not business-plan
```

Why the boundary sits at the slug directory and not one level down: a source with no public
URL carries a *vault-relative* path, so anything a `source` note rests on must be inside the
vault or the path resolves to nothing — silently, since a missing file is not a malformed
field. Research prose is exactly such a source — a competitor ledger or a dimension file is
frequently the evidence itself. One level down, `research/competitors.md` would read as
vault-relative, resolve nowhere, and lint clean anyway.

It's also what makes a corpus **portable**: copy the slug directory and every citation, every
`rests_on` edge, and every research file travels with it.

This is a summary, not the authority — see
[`skills/business-plan/references/vault.md`](skills/business-plan/references/vault.md#layout-one-directory-per-type-one-file-per-note)
("Layout: one directory per type, one file per note") and
[`skills/business-plan/SKILL.md`](skills/business-plan/SKILL.md) for the full rules.

---

## `vault-lint.sh`

The plugin ships one executable. `business-plan` builds a claim vault at
`~/Documents/go-to-market/<product-slug>/` — every load-bearing number traced to a dated
source — and `vault-lint.sh` is the read-only whole-corpus check that gates it: dangling edges,
confidence that stopped propagating, near-miss subject terms, duplicate sources, retracted notes
still cited, and — on a vault at `schemaVersion: 2` — a roadmap whose order contradicts itself,
either a prerequisite scheduled after the item that needs it or two items competing for one
constrained resource while the plan asserts they run side by side.

Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`, so the skills invoke it
bare, from whatever directory the user happens to be working in:

```sh
vault-lint.sh --vault ~/Documents/go-to-market/<product-slug>
vault-lint.sh --release-gate --vault "$VAULT_PATH"
vault-lint.sh --unverified --vault "$VAULT_PATH"
vault-lint.sh --used-in --vault "$VAULT_PATH"
vault-lint.sh --supersession-sweep --vault "$VAULT_PATH"
vault-lint.sh graph CLAIM-AS23SD44 --vault "$VAULT_PATH"
```

`--used-in` is the one that leaves the vault: a claim records the document and section it was
cited into, and this opens each one to check the file is there and the `#anchor` names a real
heading, exiting 1 when it does not. It stops at whether the citation **resolves** — whether the
section still *carries* the claim is a read, and `--help` says why a tool cannot do it.

A heading offers two addresses and either resolves. The plan templates put an explicit
`{#anchor}` attribute on every heading — `## Competition & moat {#competition}` — and that is
the one to cite, because those same templates require a heading to state the current finding, so
its text gets reworded and an anchor tracking the text would take every citation into that
section down with it. The GitHub slug of the heading text, with the attribute stripped off,
resolves too, so a vault written before its documents carried attributes keeps passing with
nothing back-filled.

`--supersession-sweep` is what makes that read a short one. Replacing a note is recorded on the
note, and nothing tells the documents that were built on the old one — so this walks every
superseded note and prints the document sections its citations reached, grouped one row per
section however many notes point at it, each row naming the note, its replacement and the reason
it was replaced. It prints the row count first, because a list you can size before you start is
one that gets read. It is a **report and not a verdict: it exits 0 whether or not it finds
anything**, since a supersession with a blast radius is the corpus doing its job — a mode that
went red on a healthy vault would teach you to ignore the exit code the real checks depend on.

`--release-gate` is the call before a render, and the only one that asks all three questions. It
runs the bare check, then `--used-in`, then `--supersession-sweep`, prints each part under its
own heading, and exits with the worst status any part returned — so the gate is clean only when
every part is. The alternative was three calls made from memory, and which of them actually ran
was a matter of recall.

**The bare run's success line says what it checked and what it did not**, because it used to say
`clean` and a corpus with dozens of dead anchors printed exactly that. It reads *note-level
checks passed … not opened: citation targets, supersession blast radius* — and the list of what
it skipped is read off the same mode table `--release-gate` composes itself from, so a mode
added to the gate cannot leave the line quietly overstating what it covered. A success line is
what somebody renders on, so it has to be narrower than the verdict its reader wants it to be.

It is POSIX `/bin/sh` with zero dependencies — no Node, no Python, no jq. A tool that reads an
entire private business corpus should not carry a transitive dependency tree, and a runtime
prerequisite discovered at the moment of use is a broken product.

---

## Repo layout

```
.
├── .claude-plugin/plugin.json
├── .github/workflows/ci.yml   # each step's comment names the failure it prevents
├── bin/
│   └── vault-lint.sh          # SHIPPED — on the agent's PATH, POSIX sh only
├── scripts/                   # contributor-only, never loaded
│   ├── check.mjs              # the repo gate
│   └── fixtures/              # vault-lint's own suite: run-fixtures.sh + its corpora
└── skills/
    ├── market-analysis/
    │   ├── SKILL.md           # the conductor: phases, run modes, quality bars
    │   └── references/        # dimensions · templates · orchestration · rendering
    └── business-plan/
        ├── SKILL.md           # grill → dispatch → draft → red team → render
        └── references/        # grill · plan-template · strategy-sim · growth-engine · vault
```

Contributing: see [AGENTS.md](AGENTS.md).

---

## License

MIT — see [LICENSE](LICENSE).
