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

**3. `bin/` is shipped and assumes only the platform's own shell — POSIX `sh` on macOS
and Linux, Windows PowerShell 5.1 on Windows; `scripts/` is the repo gate and may
assume Node.** The split is a directory, not a convention to remember. Everything under
`bin/` runs on a *user's* machine — Claude Code puts an enabled plugin's `bin/` on the
shell tool's `PATH`, so a script there is invoked bare, from whatever directory that user
is working in — and must assume nothing beyond the shell that ships with the platform: a
user installs a skill to use it, and a runtime prerequisite discovered at the moment of
use is a broken product. Windows PowerShell 5.1 ships in-box on Windows, so it is that
platform's own shell exactly as `sh` is on macOS and Linux — it is not something a user
must go install, and so it is not a discovered prerequisite either. Node is not present
on a machine running Claude Code by default — the native installer, Homebrew, WinGet,
apt, dnf and apk never install it. Everything under `scripts/` (`check.mjs`, `fixtures/`)
runs only for contributors who have already cloned this repo to open a PR — it is never
loaded and never reaches a user's `PATH` — so Node is fair there.

**Every `bin/<name>.sh` has a `bin/<name>.ps1`, and the two are held to each other by a
mechanical JSON parity gate; neither is added alone.** A second implementation of a large
linter is a drift hazard — the shell and PowerShell sides answering the same flag
differently is invisible to a reader of either file alone, and only gets worse the longer
the two are allowed to diverge unchecked. A gate that diffs their `--json` output
fixture-by-fixture is what makes maintaining two implementations tractable instead of a
standing liability: it turns "do these still agree" from a manual re-read into a machine
comparison, so a PR that ports or changes one side without the other fails loudly instead
of shipping a silent behavioural gap between platforms.

**Adding an executable means choosing a directory, and the choice is a promise.** A new
executable under `bin/` is on every user's `PATH` on the next version bump, and the parity
rule above makes that promise a pair: `bin/<name>.sh` needs a `/bin/sh` shebang and no
bashisms, and it ships together with its `bin/<name>.ps1` twin — neither lands alone.
Anything that is contributor tooling stays under `scripts/` — including the fixture
corpora, which are test data for a shipped script but are not themselves shipped. Getting
this backwards is silent in every direction: a bashism in `bin/*.sh` fails on a user's
machine and never in CI on the author's, a `.sh` shipped without its `.ps1` twin is a
promise the parity rule states but that no CI check reads yet, and a test corpus in `bin/`
lands on strangers' `PATH`. Today CI enforces the `.sh` half and the
`scripts/`-stays-out-of-`PATH` half: shellcheck reads each shell script's shebang, and a
grep rejects any path-prefixed `vault-lint.sh` in `skills/`. The `.ps1` twin is the parity
gate's job, not either of those checks — widening CI to enforce it is later work.

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
node scripts/check.mjs                # human output, exit 1 on failure
node scripts/check.mjs --json         # machine-readable
sh scripts/fixtures/run-fixtures.sh   # only if you touched bin/vault-lint.sh or .ps1
node scripts/parity/parity.mjs        # only if you touched bin/vault-lint.sh or .ps1
```

Sub-second, no install. Run `check.mjs` green before opening a PR. It enforces skill
structure, frontmatter (`name` must match the directory — the plugin loader maps by
directory, so a mismatch registers the skill under the wrong trigger), and that every
relative markdown link resolves inside `skills/`. It also checks the wiring the prose
above asks for: that every dispatched brief interpolates its playbook, that a dimension
playbook is registered everywhere it gets dispatched from, and that a cited `## Heading`
resolves to one a template writes. Each of those fails when its own pattern matches
nothing, because a check that stops matching prints the same green as one that passed.

**`--roadmap-table` and `--assumption-rows` read their table with ONE parser per
implementation, and that is the guarantee — there is no check that two parsers agree,
because there is only one.** `--assumption-rows` was written as `--roadmap-table` one
artifact over, so each implementation carried two near-identical markdown table readers,
the second declaring in a comment that it was the first "with two changes and no others."
`parity.mjs` cannot hold that: it diffs `.sh` against `.ps1` and never one reader against
its own twin, and each mode is only ever run over its own document, so no fixture puts the
two readers over the same table. A fence rule, an alignment-row test or a heading-depth
bound fixed in one and not the other shipped silently, and the mode that missed the fix
went on printing green over every fixture written before it. `check.mjs` used to hold the
shell half to its comment by exact byte comparison after a declared substitution list;
the PowerShell half was unheld and had already drifted — its roadmap reader tested an
empty header row with `-cne ''`, which reports a row holding nothing but a zero-width
space EMPTY, where its assumptions reader used `.Length`. Both halves are now collapsed
onto a single parameterised reader — `readtable(path, wanthead, wantitem, defcol)` in the
shell, `Read-FirstItemTable` in PowerShell — and that check is gone with the second parser
it was written for. **Do not reintroduce a second reader and a check that they match. Add
a parameter.** The parameters are the heading the read opens on, the header cell that
names the item column, and the column to use when no header cell names it.

**That rule is about a claim, not about resemblance, and it does not generalise to the
other duplicated helpers in either script.** Both files carry several — a fenced-block
scan once per mode that reads a document, `fold()`, `trim()`, `target_of()` — and the
shell now has the mechanism to share any of them, since `TABLE_READER_AWK` shows that awk
program *source* travels in a shell variable even though awk cannot call across programs.
They stay duplicated on purpose: each was written independently and none asserts that it
matches another, so there is nothing unheld to fail. What made the table readers different
is that one of each pair said in the file that it *was* the other. Collapse a duplicate
when it starts making that claim; leave it alone when it merely looks like a sibling. The
copies that remain say so where they are, and say how many there are, so an edit to one
can find the rest.

**A `{#anchor}` attribute goes only on a heading inside a fenced block, and the gate
enforces it.** Those fenced headings are `plan-template.md`'s templates, where the
attribute is the address a claim note's `used_in` names in the *user's* plan document.
On a live heading in this repo it is silent damage: `slugify()` folds `{`, `#` and `}`
away, so `## Foo {#bar}` slugs to `foo-bar`, and every Contents link pointing at `#foo`
goes dead while the file still reads correct. The same check counts the fenced ones and
fails at zero, so the prohibition cannot outlive the contract it exists to protect.

The fixtures suite is the second half, and it belongs to `bin/vault-lint.sh` and
`bin/vault-lint.ps1` rather than to the repo: it asserts that every check the lint claims
to make still fires, against corpora built to trigger each one, and `VAULT_LINT` points it
at whichever implementation you're testing — `VAULT_LINT=bin/vault-lint.ps1 sh
scripts/fixtures/run-fixtures.sh` runs the same 332 assertions against the PowerShell side.
A check that stops firing and a check that was deleted look identical from the outside,
which is why the assertion has to be written down rather than eyeballed.

The parity gate is the third half: `node scripts/parity/parity.mjs` runs both scripts
across 13 modes × 27 fixture vaults and fails on any byte-level disagreement between their
output — key order, an escaped character, row order, a path separator. The fixtures suite
proves each script still does what it claims; the parity gate proves the two scripts still
agree with each other — a check that stops firing in only *one* implementation is invisible
to a fixtures run pointed at the other, so this is a different failure and neither catches
it for you. Run both whenever you touch either script.

CI runs all three, plus the checks in `.github/workflows/ci.yml` — each step's comment
names the failure it prevents.

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

Worktree → PR → merge. Never commit to `main` directly; the helper is `setup-worktree.sh
<branch> main` run from anywhere inside the repo, and it reads `.agents/worktree.json` for
the gate command and house conventions. That file declares `node scripts/check.mjs` as both
`gate` and `scopedCheck` — this repo has one authoritative check and no separate heavy tier,
so there is no gate queue to enqueue against and no runner to wait for. Run the gate
yourself, and hand back a draft PR per the rule below.

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
bin/vault-lint.sh             SHIPPED — POSIX sh; paired with a required PowerShell
                               bin/vault-lint.ps1 (rule 3), both land on the user's PATH
scripts/check.mjs             the repo gate — Node, contributors only
scripts/fixtures/             vault-lint's own suite — contributor test data, not shipped
scripts/parity/               parity.mjs — the JSON diff gate holding bin/vault-lint.sh
                               and bin/vault-lint.ps1 to each other, contributors only
CHANGELOG.md                  what each pinned version actually changed
```

`vault-lint.sh` and `vault-lint.ps1` ship to users and run read-only against a vault path:
no arguments beyond `--vault` (or `VAULT_PATH`) for the checks, `--json` for an agent
consumer, `--unverified` for the notes asserted with nothing behind them, `--used-in` for
whether each note's citation target still resolves, `--supersession-sweep` for the
document sections a supersession put in doubt, `--red-team` for whether every dispatched
panel lens wrote objection rows, `--roadmap-table` for whether the plan's roadmap table
still matches the milestone set it renders, `--binding-driver` for whether a target
verdict's driver and the evidence under it survive contact with the plan section that
renders them, `--monitoring` for whether the monitoring plan names axes with an instrument, a
cadence and the decision each would change, `--deliverable` for whether the rendered
`deliverables/*.html` carries a vault address out to a reader who has no vault,
`--assumption-rows` for whether the model's assumptions table and the notes that
declare themselves inputs to it are the same set, `--claim-drift` for whether a cited section
still carries what it carried when the claim recorded reading it, `--release-gate` for the ten
parts the composite paragraph below enumerates run as one call — not ten of these, since
`--unverified` is not a gate part and the bare `check` is not in this list, which is the
enumeration trap sitting inside the sentence that warns about it — and
`graph <ID>` for one note's neighbourhood. This sentence is
exhaustive on purpose, so **a new flag lands here in the same PR that adds it, in both
scripts** — an enumeration that has gone stale reads exactly like one that is complete.
Rule 3 above has the reasoning for why `bin/` and `scripts/` sit under different
constraints.

**A new mode is a row in `MODE_TABLE`, not an arm of the argument `case`.** Each of
`bin/vault-lint.sh` and `bin/vault-lint.ps1` holds its own table near the top, one row per
mode — the selector, whether `--release-gate` runs it, and the heading the gate prints
above it — and both the flag parser and the gate's composition read it. The MODE token is
the selector with its leading `--` stripped, which is a rule a new mode follows rather than
a column that would restate its neighbour on every row. Adding a mode is that row, a block
in `usage()` appended immediately before the `graph` one, and the mode's own dispatch —
each done once per script, since the two are separate files with no shared source. It is a
table because a release that adds three modes would otherwise be three edits to the same
`case` block, and git resolves two of those textually clean while the third silently loses
the arm that parses its flag; `node scripts/parity/parity.mjs` is what catches a mode added
to one script's table and not its twin's.

`--release-gate` is a composite rather than another check surface: it runs `check`, `--used-in`,
`--supersession-sweep`, `--red-team`, `--roadmap-table`, `--binding-driver`, `--monitoring`,
`--deliverable`, `--assumption-rows` and `--claim-drift` as separate
invocations of the script and exits with the
**worst** status any part returned, so a refusal (2) is never reported as a failed check (1). It
exists because the render gate was several calls made from memory — which of them ran was a
matter of recall — and because the bare run's success line used to read as a whole-corpus
verdict. That
line now names what it checked and what it did not, with the *did not* half read off the same
table, and `run-fixtures.sh` asserts the new wording rather than the substring `clean`. It also
carries a `MODES` census asserting that every mode has a block in `usage()` — the one thing the
table cannot absorb, since a help paragraph is hand-written at a shared anchor and a mode that
loses its block still works.

**`vault-lint.sh` reads a SET of `schemaVersion`s (`1 2 3`) and refuses anything else.** A vault at
1 is held to exactly the rules it was written under; 2 and 3 are where a check that an existing
corpus could not owe goes, and the found version is passed into every awk program that needs it as
`schema` so a new check can gate on it. Three rules sit behind 2:
the sweep's `reconciled:` verdict, `--red-team`'s demand for a roster in a
`red-team.md` that has none, and `--roadmap-table`, which a vault at 1 cannot owe because it has
no `milestones/` directory to render. Two whole MODES sit behind 3 — `--assumption-rows` and
`--claim-drift` — because both read fields no corpus written before them carries, and
`--claim-drift`'s would otherwise be owed by every claim in every finished corpus at once, which
is the one shape of upgrade that reddens a whole population on the day the plugin updates. Refusing a version from the future stays the point of the field: an
older tool half-reading a newer vault reports a clean bill of health over every field it never
saw. Adding a check that fires unconditionally on every existing corpus is the thing this
mechanism exists to make unnecessary.

`--used-in` is a mode rather than part of `check` because it reads documents outside the
note directories, and it is a verdict rather than a report: it exits 1 when a target file is
missing or a `#anchor` names no heading. **Its boundary is deliberate and belongs in any change
to it** — it asserts that the citation resolves, never that the named section carries the claim.
Plan prose cites `[S#]` and `[F#]` codes and a claim note carries no citation code at all, so a
scan matching note IDs against prose fires on every correctly cited claim; a check that cries
wolf gets switched off, and switching it off takes the working half with it.

`--supersession-sweep` is the other half of that boundary. It answers the question `--used-in`
deliberately leaves open, by naming the sections somebody has to re-read: when B supersedes A,
every document section in A's `used_in` is now suspect, and supersession is visible in the note
and invisible everywhere the note was cited. Two properties are load-bearing in any change to
it. It **groups by section and dedupes**, because the unit of work is *re-read this section* and
a list repeating the section per note makes a two-item job look like six. Deduping means
resolving two spellings of one heading onto one row: a heading is addressable by an explicit
`{#anchor}` attribute *and* by the slug of its text, both, so one section can be reached under
two strings. **The sweep folds an anchor to its alphanumeric bytes and matches that against the
document's headings — deliberately looser than `--used-in`'s slug rule, and not a copy of it.**
That rule decides whether an anchor *resolves* and has to be exact; this decides whether two
anchors are the *same section*, so it can drop every character the slug rule drops without
knowing which those are, which is what keeps it from drifting out of step with a rule it does not
own. A fold key claimed by two different headings is retired rather than resolved, so ambiguity
falls back to two rows — being wrong here costs a section nobody re-reads, so it refuses. And it
**reports the row count**, because the gate that consumes it is a read and a read is bounded only
if its size is visible before it starts — that count is also the instrument
`docs/specs/2026-07-27-claim-citation-codes.md` names as the trigger that would reopen its
decision, so it is part of the product rather than a nicety.

**The worklist is a report and the verdict is a separate question, and the distinction is the
one thing to keep precise here.** Finding rows is not a failure — a healthy vault exits 0 with a
worklist in it, because a supersession with a blast radius is the corpus working and a mode that
went non-zero on that would train its caller to ignore the exit code the checks depend on. What
**fails** is a note carrying `supersedes` with no `reconciled:` date, or one earlier than that
note's own `created`. Both are plain string comparisons over quoted ISO dates, which is the
payoff `vault.md` claims for coercing nothing. Gated on `schemaVersion` 2, so a corpus written
before the field cannot owe it. A date can be stamped without reading anything, so this asserts
that the read was *claimed*, not that it was done — what it removes is skipping it by default,
which is what a worklist nobody was obliged to finish had been shipping.

`--red-team` is the same shape one document over. `red-team.md` carries a `## Lenses dispatched`
roster — a `| Round | Lens |` table — and the mode fails when a lens named there has no row in
the objection table, and when a row names a lens the roster does not. **Both directions are
load-bearing:** with only the forward one, the cheapest way past a lens that returned nothing is
to delete it from the roster. A vault with no `red-team.md` dispatched no panel and passes; a
`red-team.md` with no roster fails at `schemaVersion` 2 and passes at 1. Rows inside fenced
blocks are skipped, because the document carries its own row template and would otherwise fail
for documenting its own format, and lens names are matched case-folded with whitespace runs
collapsed — a check that fires on capitalisation is one somebody switches off.

`--roadmap-table` is the third document at the vault root, and the one place in this tool where
matching is deliberately **not** folded. `plan-template.md` states the contract it reads: every
item in the roadmap section is a `milestone` note written before the table, and the table renders
`sequence`, `moves` and `resource` off the notes — so the item cell **is** the `title`, and the
key is that title matched **verbatim**, the same rule `vault.md` holds `chosen` to against
`options` and for the same reason. That is what makes this a check rather than a similarity test:
a table rendered off the notes matches character for character by construction, so a mismatch
means the table was edited by hand, and no ID column has to appear in a document a founder hands
an investor. **Both directions**, each a different failure: a row matching no milestone is an item
that escaped the ledger, and a milestone the table never lists is a dated change the plan does not
show. Two reading rules keep it from crying wolf, and both belong in any change to it — **only the
FIRST table under the roadmap heading is read** (the section legitimately carries the Rule 3
permutation comparison, whose first column is an *order*), and **the item column is the one the
header names `Item`**, defaulting to the first (a numbered roadmap puts an ordinal ahead of it,
the shape the generated `research/timeline.md` uses). Getting either wrong reports every row of a
correct table as an item with no note behind it — which is what this check was scoped out of
1.10.0 for, on the mistaken premise that the only available key was a fuzzy one.

`--binding-driver` is the fourth document, and the one mode whose trigger is a **`subject`** rather
than a version or a directory. A target verdict is a `claim` or an `assumption` carrying
`subject: target-verdict` or `steady-state-ceiling` plus `binding_driver`, `driver_kind`,
`conditional_on`, `evidence_n` and `evidence_counterparties`; the two rules that read nothing but
the note — the fields are owed as a set, and `driver_kind` takes one of three words — are in
`check`, and the four that have to open `business-plan.md` are here. **Its boundary is that the two
strings the document renders off a note are matched verbatim and no prose is read for meaning
anywhere**: the `conditional_on` phrase against the section the verdict renders into, and the corner
table's `Kind` cell against `driver_kind`, both directions. There is no phrase list and no
sentence-shape inference, for `--roadmap-table`'s reason one section over — a check that infers a
verdict from how a sentence reads cries wolf, and switching it off takes the half that worked with
it. Three things it deliberately does not do belong in any change to it. **The section a verdict
renders into is the anchor its subject names, and only where the plan has no such section the ones
its `used_in` names** — read as a union instead, a note that also cites `## Why now` clears the
condition check whenever the phrase turns up there, so the verdict corner may read *does not clear*
and pass. **`verdict-thin-evidence` is a conjunction and both halves are load-bearing**: the note's
`evidence_n` and `evidence_counterparties` must be what the closure holds, *and* the section must
carry the one line those two generate — `Evidence: 2 sources, 1 counterparty`, matched verbatim like
`conditional_on`. Written as a disjunction it can never be both-false, because `check` already owes
both fields on every note the mode reads, so it collapses to a rule about the ledger alone and leaves
the reported failure shipping: honest counts, and a section that renders the finding with nothing
saying it rests on two deals with one party. The line is generated rather than grepped for, because a
scan for the two numbers as tokens lets an unrelated pair of digits silence it — and it is owed only
where the tail is thin, so a well-evidenced verdict carries nothing and this never becomes a line on
every plan.
**`verdict-unfiled` fires on the presence of a non-empty section at the `{#target-verdict}` anchor
and never on a reading of the prose inside it, and there is no `{#steady-state}` equivalent**,
because a ceiling section in an existing plan legitimately has no field-carrying note behind it.

`--assumption-rows` is the fifth document — `financial-model.md` — and it is `--roadmap-table` one
artifact over, deliberately: the same heading fold, the same row parser, the same only-the-first-table
rule, the same VERBATIM title key. **It exists because the rule it inverts was correct and had no
counterpart.** `plan-template.md` requires that no number appears in a projection that is not a named
assumption row, and nothing asked whether a named assumption was MISSING from the table — so two
assumptions governing a whole revenue line existed as correctly authored notes, never became rows, and
the rule intended to enforce rigour made that line structurally unable to enter the projection. It was
then filed as *revenue outside this model*, which reads as a modelling decision and was a consequence
of the omission, and every downstream verdict inherited a denominator missing a line the roadmap ships.
**One reading rule differs from `--roadmap-table` and it is the one that matters: the item column
defaults to TWO**, because the template ships `| # | Assumption | … |` and column one is the `A-n`
label a milestone's `moves` and the plan's prose both cite — defaulting to it would report every row of
a correct table as an input that escaped the ledger, which is exactly the crying wolf `--roadmap-table`
was scoped out for once already. **Its fourth check is the identity's, not the table's**:
`excluded-line-on-roadmap` fails an assumption carrying `excluded_from_model` that a `milestone`'s
`moves` names and that no verdict note lists in `arr_excludes`. Excluding a revenue line is legitimate
— a metered layer must not be allowed to flatter subscription churn — so what fails is the *silence*,
not the exclusion, and the escape is stating it where the identity is stated rather than inside the
model. Gated on `schemaVersion` 3, where all three fields it reads were added.

`--claim-drift` is the half `--used-in` says at length it will never do, obtained without reading prose
for meaning. `--used-in` asserts a citation RESOLVES; `--binding-driver` asserts one generated string is
present; **neither can say whether a section still carries what it carried yesterday**, and that is a
different question from both because the comparison is against text somebody already read. A claim
records the content hash of each cited section in `reconciled_sections` — `reconciled:` itemised rather
than a second field beside it — and a changed hash **re-opens** the claim. What it caught: a claim
written into a plan section satisfying invariant 20, a later re-solve that rewrote the block, a heading
left untouched so the citation still resolved, a green gate, and the drift found by hand days later.
Three properties belong in any change to it. **The hash is over BYTES with three normalisations and no
others** — trailing whitespace per line, and leading, trailing and repeated blank lines — because all
three are invisible in a rendered document and a hash sensitive to them re-opens every claim in the
corpus the first time an editor trims a file; a rewrapped paragraph IS an edit and does re-open. **The
polynomial is 31-bit and arithmetic-only** (`h = (h·131 + byte) mod 2^31−1`, length mixed in last),
because it has to be byte-identical in POSIX awk — which has no bitwise operators — and in Windows
PowerShell 5.1 with zero dependencies on either side, and it is detecting an edit rather than resisting
an adversary. **The failure message carries the CURRENT hash**, which is what makes a read-only tool
usable here: there is no write mode, so re-reconciling is re-reading the section and pasting one token,
and pasting it is the assertion that the read happened exactly as stamping a date is. It reads only
`current` `claim` and `assumption` notes and only entries whose `#anchor` resolves — a dead anchor is
`--used-in`'s verdict, and reporting it twice under a name about reconciliation sends its reader to the
wrong fix. Gated on `schemaVersion` 3.

**The two subjects trigger differently, and the asymmetry is the design rather than an
inconsistency.** `target-verdict` is a term 1.12.0 introduces, so no existing corpus carries it and
the four fields owed outright are owed whatever the note carries — a note under that subject holding
none of them fails. `steady-state-ceiling` is `required: true` and predates its 1.3.0 amendment, so
every vault already holds one, and there the trigger is **field presence**. That is the exemption
`schemaVersion` exists to provide, obtained without spending a version: a check firing
unconditionally over a subject no older vault can carry fails nothing, while one firing over both
subjects fails every vault authored before it on the day the plugin updates. Extending the leniency
to the verdict half would pay an exemption's whole cost over an empty population and make omitting
`binding_driver` the cheapest way past every rule that reads it — and a dodge available by omission
is not an exemption, which is why `--red-team` checks its roster both ways too.

**Every invocation in `skills/` is bare — `vault-lint.sh …` or `vault-lint.ps1 …`, never a
path**, and CI rejects the path form of either. The pre-plugin layout used a relative path,
which resolves against the *user's own project directory*, where nothing of the sort
exists. A skill's prose doesn't choose the extension — the session does, by picking
whichever matches its shell tool — so every bare invocation in `skills/` already reads
correctly under that rule without being rewritten per site; see
[vault.md](skills/business-plan/references/vault.md#a-session-invokes-whichever-script-its-shell-tool-can-run)
for where that choice is stated.

`scripts/fixtures/run-fixtures.sh` is the one place that does use a path — it reaches across
to `../../bin/vault-lint.sh` by default, or to whatever `VAULT_LINT` names, because the
corpora are contributor test data and stay out of a user's `PATH`.
