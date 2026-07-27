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

Both write deterministically to `~/Documents/business/<product-slug>/` (same product → same
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
- "Build me a business plan for this" / "how do I take this to market" → **business-plan**
  (which dispatches market-analysis itself)

Point either at a repo (most common), a spec/PRD/doc, or just describe the idea. Interactive
runs will grill you on the genuine gaps — the questions research can't answer — before
spending research tokens. Everything lands in `~/Documents/business/<product-slug>/`,
including `deliverables/*.html` and page-verified `deliverables/*.pdf`.

To force one, name it: `/market:market-analysis` or `/market:business-plan`.

When dispatching sub-agents, name the skill as an explicit first step — a sub-agent won't reach
for it on its own as reliably as the main thread does:

> Step 0: invoke the `market:business-plan` skill.

---

## On disk

`~/Documents/business/<product-slug>/` **is** the vault — there is no `vault/` subdirectory.
The slug directory itself carries `.vault/config.json`, and everything else the skills produce
lives inside it:

```
~/Documents/business/<product-slug>/
├── .vault/config.json       # schemaVersion — a directory without it is not a vault
├── _vocab.yml               # controlled subject vocabulary
├── sources/ facts/ claims/ assumptions/ questions/ decisions/ # one file per note
├── research/                # all prose — market-analysis dimensions, product-dossier.md,
│                            #   founder-brief.md — untouched by the vault machinery
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
`~/Documents/business/<product-slug>/` — every load-bearing number traced to a dated
source — and `vault-lint.sh` is the read-only whole-corpus check that gates it: dangling edges,
confidence that stopped propagating, near-miss subject terms, duplicate sources, retracted notes
still cited.

Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`, so the skills invoke it
bare, from whatever directory the user happens to be working in:

```sh
vault-lint.sh --vault ~/Documents/business/<product-slug>
vault-lint.sh --unverified --vault "$VAULT_PATH"
vault-lint.sh graph CLAIM-AS23SD44 --vault "$VAULT_PATH"
```

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
