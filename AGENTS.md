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

**3. Repo tooling assumes Node; shipped tooling assumes only POSIX shell.**
`scripts/check.mjs` is a repo gate — it runs for contributors who have already cloned
this repo to open a PR, and Node is a fair assumption there. Anything the skill invokes
on a *user's* machine is shipped tooling (`scripts/vault-lint.sh`, landing in a later
slice) and must assume nothing beyond POSIX shell: a user installs a skill to use it,
and a runtime prerequisite discovered at the moment of use is a broken product. Node is
not present on a machine running Claude Code by default — the native installer,
Homebrew, WinGet, apt, dnf and apk never install it.

Both tiers still have ZERO dependencies, but on supply-chain grounds rather than
convenience: a tool that reads a user's entire private business corpus should not carry
a transitive dependency tree. No `package.json`, no lockfile, no install step, on either
side of the split.

The repo gate stays on Node rather than moving to Python for a narrower reason:
`node --version` either works or reports not-found, while `python3` passes
`command -v` on both macOS and Windows and then fails anyway — an Xcode trampoline stub
on macOS, a Store alias stub on Windows. A runtime that fails honestly is preferable to
one that lies.

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
scripts/check.mjs         the repo gate — Node, contributors only
scripts/vault-lint.sh     shipped tooling — POSIX shell only, ships to users
install.sh                symlinks both skills into every agent skills home
```

`scripts/check.mjs` and `scripts/vault-lint.sh` sit under different constraints: the
gate runs here, for contributors, so Node is a fair assumption; `vault-lint.sh` runs on
a user's machine as part of the skill, so it can assume nothing beyond POSIX shell (see
rule 3 above). `vault-lint.sh` does not exist yet — it lands with the vault work.

`install.sh` symlinks by default, so a `git pull` here updates the live skills on every
machine that installed that way — which means **a broken commit on `main` breaks
everyone's skills immediately.** That is the reason the gate exists and the reason
nothing lands unreviewed.
