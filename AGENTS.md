# AGENTS.md — working in this repo

Two agent skills that take a product to market. Read this before changing anything;
`README.md` covers what the skills do, this covers how to work on them.

## The four rules that are not negotiable

**1. This repo is PUBLIC.** Never commit engagement specifics — no client or subject
names, no real figures from a live plan, no roadmap items, no identifying detail.
Worked examples in the skills are generic by construction. A rule illustrated with
"item A gated on an external certification clock" teaches exactly as well as one
naming a real product, and doesn't leak a strategy.

**2. State lives OUTSIDE the skill.** The skills read and write
`~/Documents/go-to-market/<product-slug>/` — the engagement folder IS the vault, and the
research and outputs it produces live inside that same folder. **This repo holds
method and tools only, never user data.** Scripts are stateless: they take a path and
operate on it. That separation is what lets the skills be public while the work stays
private, and lets a user upgrade the skills without touching their corpus.

**3. `bin/` is shipped and assumes only POSIX shell; `scripts/` is the repo gate and may
assume Node.** The split is a directory, not a convention to remember. Everything under
`bin/` runs on a *user's* machine — Claude Code puts an enabled plugin's `bin/` on the
Bash tool's `PATH`, so `vault-lint.sh` is invoked bare, from whatever directory that user
is working in — and must assume nothing beyond POSIX shell: a user installs a skill to
use it, and a runtime prerequisite discovered at the moment of use is a broken product.
Node is not present on a machine running Claude Code by default — the native installer,
Homebrew, WinGet, apt, dnf and apk never install it. Everything under `scripts/`
(`check.mjs`, `fixtures/`) runs only for contributors who have already cloned this repo
to open a PR — it is never loaded and never reaches a user's `PATH` — so Node is fair there.

**Adding an executable means choosing a directory, and the choice is a promise.** A new
shell script under `bin/` is on every user's `PATH` on the next version bump: it needs a
`/bin/sh` shebang and no bashisms. Anything that is contributor tooling stays under
`scripts/` — including the fixture corpora, which are test data for a shipped script but
are not themselves shipped. Getting this backwards is silent in both directions: a bashism
in `bin/` fails on a user's machine and never in CI on the author's, and a test corpus in
`bin/` lands on strangers' `PATH`. Both halves are enforced in CI, so neither is a
convention to remember: shellcheck reads each script's shebang, and a grep rejects any
path-prefixed `vault-lint.sh` in `skills/`.

Both tiers still have ZERO dependencies, but on supply-chain grounds rather than
convenience: a tool that reads a user's entire private business corpus should not carry
a transitive dependency tree. No `package.json`, no lockfile, no install step, on either
side of the split.

The repo gate stays on Node rather than moving to Python for a narrower reason:
`node --version` either works or reports not-found, while `python3` passes
`command -v` on both macOS and Windows and then fails anyway — an Xcode trampoline stub
on macOS, a Store alias stub on Windows. A runtime that fails honestly is preferable to
one that lies.

**4. Docs ship in the same PR as the behavior they describe — `README.md`,
`AGENTS.md`, and any `skills/*/references/` file that restates it.** v1.1.0 changed
the on-disk vault layout and left `README.md` describing the old one — including a
`vault-lint.sh` invocation pointing at a directory that had stopped existing — and
v1.1.1 exists only to fix that. A behavior change and its documentation belong in one
PR: when you change a skill's behavior, grep the repo for what documents it and fix
every hit before you open the PR. A docs-only follow-up release means the first thing
a new user read was wrong.

## The gate

```
node scripts/check.mjs          # human output, exit 1 on failure
node scripts/check.mjs --json   # machine-readable
sh scripts/fixtures/run-fixtures.sh   # only if you touched bin/vault-lint.sh
```

Sub-second, no install. Run `check.mjs` green before opening a PR. It enforces skill
structure, frontmatter (`name` must match the directory — the plugin loader maps by
directory, so a mismatch registers the skill under the wrong trigger), and that every
relative markdown link resolves inside `skills/`. It also checks the wiring the prose
above asks for: that every dispatched brief interpolates its playbook, that a dimension
playbook is registered everywhere it gets dispatched from, and that a cited `## Heading`
resolves to one a template writes. Each of those fails when its own pattern matches
nothing, because a check that stops matching prints the same green as one that passed.

The fixtures suite is the second half, and it belongs to `bin/vault-lint.sh` rather than
to the repo: it asserts that every check the lint claims to make still fires, against
corpora built to trigger each one. Run it whenever you touch that script. A check that
stops firing and a check that was deleted look identical from the outside, which is why
the assertion has to be written down rather than eyeballed.

CI runs both, plus the checks in `.github/workflows/ci.yml` — each step's comment names
the failure it prevents.

## Writing skills

**Every rule must name the failure it prevents.** A rule with no failure mode behind it
is ceremony, and ceremony is what makes a skill get skipped. If you cannot say what goes
wrong without it, cut it.

**Prefer a worked example to an abstraction.** The rules that survive contact with a
real engagement are the ones with a concrete failure attached — "page count reads
correct while whole sections are dropped" beats "verify rendering carefully".

**A dispatched brief interpolates its playbook; it never restates it.** A skill is prose that
instructs agents, and nothing fails to compile — a rule added to a reference file reads correct
whether or not anything runs it. Interpolation is what runs it: `orchestration.md`'s
`competitors.md` writer passes `${playbookCompetitors}` into its prompt, so every rule added to
that playbook reaches its agent by construction. The profiling call beside it hand-writes a
prompt restating the same playbook in its own words, and that is the one a new dated-traction
rule never reached. A restatement is a second source of truth that nothing keeps in sync, and it
fails in the direction that hides, because the playbook still reads correct. A brief ADDS what
the playbook cannot know — which competitor, which output path — and paraphrases nothing the
playbook already says. `check.mjs` holds the line: an `agent(...)` call that interpolates no
playbook must be listed as an exception, with its reason, in the check itself.

**Prose in a reference file is not a producer.** It produces something only when it is
interpolated into a brief an agent receives, or when the conductor performs the step itself in a
phase. Where construction cannot save you, ask three questions of every rule you add: what
produces it, what consumes it, and what fails if it is absent. The third is the one people skip,
and it is why a rule earns a quality bar or a verification-checklist entry rather than a
statement alone. Two shapes read correct on the page and still lose the rule: an enumeration
that names one of two siblings drops the other, because the agent takes the enumeration as the
checklist and the interpolated playbook as background; and a floor stated as a quantity is read
as the quantity, so "at least two where available" gets an agent that found six to report two.

**Every artifact a phase consumes is named in that phase's verification checklist.** A static
check sees wiring, never payload — a channel can be connected correctly and carry the wrong
thing, and only a consumer that inspects its own input catches that, on the first real run
instead of the seventh. `business-plan`'s Phase 2 "Verify the return" list is the working form:
it names `research/growth-curves.md` outright, and that is what bounces a research run that came
back without it. A generic "all contract files exist" clause does not do this job — the artifact
has to be named.

**Prose style.** Section headings are action titles stating the finding, not labels.
Banned words, each a red flag to the people who read hundreds of these: *revolutionary,
disruptive, game-changing, cutting-edge, delve, tapestry, paramount*, and *seamless* or
*landscape* used as filler. Replace each with the specific fact it stood in for.

**Cross-skill references are load-bearing.** `business-plan` dispatches `market-analysis`
and shares its rendering reference. The two install as a pair; a reference that escapes
`skills/` breaks for anyone who installed only one, and the gate rejects it.

## Workflow

Worktree → PR → merge. Never commit to `main` directly; the helper is
`setup-worktree.sh <branch> main` run from anywhere inside the repo, and it reads
`.agents/worktree.json` for the gate command and house conventions. That file declares
`node scripts/check.mjs` as both `gate` and `scopedCheck` — this repo has one
authoritative check and no separate heavy tier, so there is no gate queue to enqueue
against and no runner to wait for. Run the gate yourself and open an ordinary,
non-draft PR.

**Merge commits, not squash. Never rebase. Never self-merge without review.**

**A slice opens a DRAFT PR, and only the reviewer flips it ready.** The draft PR *is* the
implementer's hand-back — the diff, not the summary. An agent's report is its claim about what it
did; the diff is what it did, and the two diverge in the direction that reads fine. Draft here
means "pushed and self-gated, not yet read"; ready means someone read it. There is no runner to
flip it, so nothing else claims the state.

The flip is the point rather than the label: GitHub refuses to merge a draft, so a PR cannot reach
the integration branch without someone deliberately marking it read. `merge-pr.sh` calls
`gh pr merge` directly and errors on a draft, which is the interlock working — the reviewer runs
`gh pr ready <n>` and then `merge-pr.sh <n>`. Without it the only thing between an unread diff and
the branch is the reviewer's own discipline, and discipline is what fails on the tenth slice of a
long release.

A PR approval would be the native mechanism and does not work here: GitHub blocks approving your
own pull request, and the implementer and the reviewer commit under the same identity.

Branch prefixes: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`.

**Shipping is a version bump, not a merge.** `.claude-plugin/plugin.json` sets `version`,
and an install is pinned to that string, so merging to `main` under an unchanged version
ships nothing while looking like it worked. **Assume your change needs a bump**: CI treats
everything as shipped except `scripts/`, `.github/`, `.agents/`, `AGENTS.md`,
`CHANGELOG.md` and `.gitignore`, so anything else needs `version` moved forward and a
matching `## <version>` heading in `CHANGELOG.md`. The exemption list runs that way round
on purpose — a list of what *does* ship silently excuses the next directory someone adds.

## Layout

```
.claude-plugin/plugin.json    the manifest — name `market`, and the pinned `version`
.github/workflows/ci.yml      every check, each commented with the failure it prevents
skills/market-analysis/       SKILL.md + references/ — the research engine
skills/business-plan/         SKILL.md + references/ — the plan conductor
bin/vault-lint.sh             SHIPPED — POSIX sh only, lands on the user's PATH
scripts/check.mjs             the repo gate — Node, contributors only
scripts/fixtures/             vault-lint's own suite — contributor test data, not shipped
CHANGELOG.md                  what each pinned version actually changed
```

`vault-lint.sh` ships to users and runs read-only against a vault path: no arguments beyond
`--vault` (or `VAULT_PATH`) for the checks, `--json` for an agent consumer, `--unverified`
for the notes asserted with nothing behind them, and `graph <ID>` for one note's
neighbourhood. Rule 3 above has the reasoning for why `bin/` and `scripts/` sit under
different constraints.

**Every invocation in `skills/` is bare — `vault-lint.sh …`, never a path**, and CI rejects
the path form. The pre-plugin layout used a relative path, which resolves against the
*user's own project directory*, where nothing of the sort exists.

`scripts/fixtures/run-fixtures.sh` is the one place that does use a path — it reaches across
to `../../bin/vault-lint.sh`, because the corpora are contributor test data and stay out of
a user's `PATH`.
