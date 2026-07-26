# AGENTS.md — working in this repo

Two agent skills that take a product to market. Read this before changing anything;
`README.md` covers what the skills do, this covers how to work on them.

## The three rules that are not negotiable

**1. This repo is PUBLIC.** Never commit engagement specifics — no client or subject
names, no real figures from a live plan, no roadmap items, no identifying detail.
Worked examples in the skills are generic by construction. A rule illustrated with
"item A gated on an external certification clock" teaches exactly as well as one
naming a real product, and doesn't leak a strategy.

**2. State lives OUTSIDE the skill.** The skills read and write
`~/Documents/business/<product-slug>/` — vaults, research, outputs. **This repo holds
method and tools only, never user data.** Scripts are stateless: they take a path and
operate on it. That separation is what lets the skills be public while the work stays
private, and lets a user upgrade the skills without touching their corpus.

**3. Scripts have ZERO dependencies.** Node, importing only from `node:*`. No
`package.json`, no lockfile, no install step. People clone this repo to *get* the
skills — requiring a package manager to use or check them is a barrier, and a
transitive dependency in a tool that reads someone's private business corpus is a
supply-chain risk nobody asked for.

## The gate

```
node scripts/check.mjs          # human output, exit 1 on failure
node scripts/check.mjs --json   # machine-readable
```

Sub-second, no install. Run it green before opening a PR. It enforces skill structure,
frontmatter (`name` must match the directory — `install.sh` maps by directory, so a
mismatch installs the skill under the wrong trigger), and that every relative markdown
link resolves. There is no build and no test suite: correctness here means the skills
are well-formed and every reference a skill tells the model to load actually exists.

## Writing skills

**Every rule must name the failure it prevents.** A rule with no failure mode behind it
is ceremony, and ceremony is what makes a skill get skipped. If you cannot say what goes
wrong without it, cut it.

**Prefer a worked example to an abstraction.** The rules that survive contact with a
real engagement are the ones with a concrete failure attached — "page count reads
correct while whole sections are dropped" beats "verify rendering carefully".

**Prose style.** Section headings are action titles stating the finding, not labels.
Banned words, each a red flag to the people who read hundreds of these: *revolutionary,
disruptive, game-changing, cutting-edge, delve, tapestry, paramount*, and *seamless* or
*landscape* used as filler. Replace each with the specific fact it stood in for.

**Cross-skill references are load-bearing.** `business-plan` dispatches `market-analysis`
and shares its rendering reference. The two install as a pair; a reference that escapes
`skills/` breaks for anyone who installed only one, and the gate rejects it.

## Workflow

Worktree → PR → merge. Never commit to `main` directly; the helper is
`~/.worktrees/setup-worktree.sh <branch> main` run from anywhere inside the repo, and it
reads `~/.worktrees/config/market-skills.sh` for the gate command and house conventions.

**Merge commits, not squash. Never rebase. Never self-merge without review.**

Branch prefixes: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`.

## Layout

```
skills/market-analysis/   SKILL.md + references/   the research engine
skills/business-plan/     SKILL.md + references/   the plan conductor
scripts/check.mjs         the gate
install.sh                symlinks both skills into every agent skills home
```

`install.sh` symlinks by default, so a `git pull` here updates the live skills on every
machine that installed that way — which means **a broken commit on `main` breaks
everyone's skills immediately.** That is the reason the gate exists and the reason
nothing lands unreviewed.
