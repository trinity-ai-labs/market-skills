# market-skills

Two agent skills that take a product to market, packaged as a standalone, installable repo:

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

This repo is the single source of truth for the skills. Edit here; every machine that
installed via symlink picks changes up automatically.

| Piece | Lives at (after install) | What it is |
|---|---|---|
| `skills/market-analysis/` | `~/.claude/skills/market-analysis/` | The research engine skill |
| `skills/business-plan/` | `~/.claude/skills/business-plan/` | The plan conductor skill |
| both | `~/.agents/skills/…` | Same skills under the generic `~/.agents` convention |

The pair is designed to run **workflow-heavy**: research fans out to fleets of sub-agents
(multi-modal competitor discovery, per-competitor profiling, refutation panels, a completeness
critic) with explicit model/effort tiering per stage — cheap models for the fleet, strong
models only for reconciliation and synthesis. See
`skills/market-analysis/references/orchestration.md` for the canonical workflow script.

---

## Install

```bash
git clone git@github.com:trinity-ai-labs/market-skills.git
cd market-skills
./install.sh
```

`install.sh` **symlinks** both skills into both skill homes (`~/.claude/skills/`,
`~/.agents/skills/`), so a later `git pull` updates the live skills everywhere with no re-run.
Use `./install.sh --copy` for independent copies (re-run after each edit to sync).

The script is idempotent and self-healing: it wipes whatever is at each destination first,
then re-links.

Verify:

```bash
ls -la ~/.claude/skills/market-analysis   # -> .../market-skills/skills/market-analysis
ls -la ~/.claude/skills/business-plan     # -> .../market-skills/skills/business-plan
```

---

## Use

In Claude Code (or any `~/.agents`-aware agent):

- "Run a market analysis on this repo" / "analyze the market for <idea>" → **market-analysis**
- "Build me a business plan for this" / "how do I take this to market" → **business-plan**
  (which dispatches market-analysis itself)

Point either at a repo (most common), a spec/PRD/doc, or just describe the idea. Interactive
runs will grill you on the genuine gaps — the questions research can't answer — before
spending research tokens. Everything lands in `~/Documents/business/<product-slug>/`,
including `deliverables/*.html` and page-verified `deliverables/*.pdf`.

## Layout

```
skills/
  market-analysis/
    SKILL.md                      # the conductor: phases, run modes, quality bars
    references/
      dimensions.md               # per-dimension research playbooks (what to hunt, sources, return shape)
      templates.md                # exact output document templates
      orchestration.md            # canonical Workflow script for the research fleet
      rendering.md                # HTML+PDF design system, paged-media CSS, toolchain, verify loop
  business-plan/
    SKILL.md                      # the conductor: grill → dispatch → draft → red team → render
    references/
      grill.md                    # the founder question bank, with defaults and stance
      plan-template.md            # artifact-by-track templates + financial model rules
      strategy-sim.md             # competing capital/GTM paths as parallel models; reinvestment engine
      growth-engine.md            # the automated GTM machine: content/visual/docs skills + weekly loop
```

`business-plan` references `market-analysis`'s rendering.md and dispatches the skill itself —
they install as a pair, always.
