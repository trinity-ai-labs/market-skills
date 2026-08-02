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
scripts/fixtures/run-fixtures.sh` runs the same assertions against the PowerShell side.
A check that stops firing and a check that was deleted look identical from the outside,
which is why the assertion has to be written down rather than eyeballed. **Neither the
assertion count nor the fixture count is written down here** — both tools print their own
totals, and a number in this file rots on the next fixture anybody adds, which is the reads
correct while stale shape the enumeration rule two sections down warns about.

The parity gate is the third half: `node scripts/parity/parity.mjs` runs both scripts
over every mode against every fixture vault and fails on any byte-level disagreement between their
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
still carries what it carried when the claim recorded reading it, `--citation-codes` for whether
every `[F#]` and `[S#]` a document cites resolves to a row in the index that assigns it,
`--unflattened-source` for whether every row of a research file's own local source table names a
URL the root `sources.md` also names, `--subject-orphan` for a vocabulary subject the corpus
reasons about and has never filed a note under, `--foreclosed` for the live notes that take an
option off the table and whether each says what would put it back, `--release-gate` for the
parts the composite paragraph below enumerates run as one call — and they are not simply the flags
in this sentence, since `--unverified` is not a gate part and the bare `check` is not in this list,
which is the enumeration trap sitting inside the sentence that warns about it; the count is left
out for the reason the fixture counts are, that a number here rots on the next mode anybody adds —
and `graph <ID>` for one note's neighbourhood. This sentence is
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
`--deliverable`, `--assumption-rows`, `--claim-drift`, `--citation-codes`,
`--unflattened-source`, `--subject-orphan` and `--foreclosed` as separate
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

**That rule about the bare run's line is a rule about EVERY success line, and the sub-modes learned
it late.** A mode that cannot see its subject must name the subject and say which half did not run —
never report what it would have concluded had it looked. Three lines were failing that and each cost
a real read: `--monitoring` printed *no competitor set was profiled, so no axis owes an instrument*
over a vault holding 31 profiles and a written monitoring plan whose document lived somewhere other
than the vault root; `--binding-driver` printed *matched verbatim* over zero corner rows, which is
what a section-boundary bug looked like from the outside for as long as it shipped; and
`--assumption-rows` printed its matched-row count with nothing about the half that walks the
declared inputs, which is empty whenever no note carries `model_input`. None of the three becomes a
failure — a vault legitimately has no competitor set, no verdict table and no declared inputs. What
has to be readable is *checked and agreed* against *had nothing to check*, and `run-fixtures.sh`
asserts each line both ways: the new wording present, and the old *matched verbatim* absent.

**Two lines of that same shape are still unfixed, and they are named here so the next change to
either one finds this rule rather than the sentence beside it.** `--red-team` prints *no red-team.md
under $VAULT - no panel was dispatched, so no lens owes rows*, and `--deliverable` prints *no
deliverables/\*.html under $VAULT - nothing has been rendered yet, so no artifact carries anything
out*. Both infer the state of the work from one absent path, which is exactly what `--monitoring`
was doing over a vault with 31 profiles in it. Neither has a real failure behind it yet — the rule
in *Writing skills* below is that a rule with no failure mode gets cut, and these two would be
rewritten on the strength of a sibling's incident rather than their own — so they are recorded
rather than changed. Rewrite them when one of them costs a read, or when a slice owns those modes.

**`vault-lint.sh` reads a SET of `schemaVersion`s (`1 2 3 4`) and refuses anything else.** A vault at
1 is held to exactly the rules it was written under; 2, 3 and 4 are where a check that an existing
corpus could not owe goes, and the found version is passed into every awk program that needs it as
`schema` so a new check can gate on it. Three rules sit behind 2:
the sweep's `reconciled:` verdict, `--red-team`'s demand for a roster in a
`red-team.md` that has none, and `--roadmap-table`, which a vault at 1 cannot owe because it has
no `milestones/` directory to render. Two whole MODES sit behind 3 — `--assumption-rows` and
`--claim-drift` — because both read fields no corpus written before them carries, and
`--claim-drift`'s would otherwise be owed by every claim in every finished corpus at once, which
is the one shape of upgrade that reddens a whole population on the day the plugin updates. ONE
rule sits behind 4 — `check`'s `population-unnested` — and it is bought for the same reason one
version down: a plan that sized properly already carries several `current` population claims under
`market-size`, none of them wrong, so the ungated rule reddens every corpus that did the work for a
reason having nothing to do with what changed. Correct and unusable is what a version buys out of.
**The three fields `--foreclosed` reads are deliberately NOT behind it**, which is the same call
`superseded_by`'s two rules make: the mode fires on the PRESENCE of `forecloses`, so a corpus that
never wrote the field cannot owe anything, and a version spent over an empty population buys an
exemption nobody needed. Refusing a version from the future stays the point of the field: an
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

**The sweep reads the edge from BOTH ends, and the second one is a failure rather than a worklist
row.** Everything above walks `supersedes`, which lives on the superseding note, because that is
where the reason and the `reconciled:` date live. A note carrying `superseded_by` whose named
successor never wrote the matching `supersedes` was therefore invisible from both directions at
once and printed under *superseded by: nothing* — which says the record names no replacement, when
it names one and only the other end is missing. Those are different repairs, and reporting the
first as the second is what let it sit: on a live corpus an assumption backing a financial-model
row named its replacement, nothing named it back, and three current claims went on resting on the
dead note. `superseded-by-unreciprocated` and `superseded-by-dangling` are separate codes for the
same reason — one needs a line added to a note the record already names, the other needs the
successor written or a typo fixed, and `check`'s dangling-edge rule walks the block-list edge
fields and never this scalar. **Neither is gated on `schemaVersion`, and neither needs to be:**
both fire on the PRESENCE of `superseded_by`, so a corpus that never wrote the field cannot owe
them — the exemption a version buys, obtained without spending one. `superseded_by` is also the
third address of the superseded set, beside a `supersedes` edge and `status: superseded`, for the
reason the other two are both there.

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
it. **A section runs to the next heading of the SAME DEPTH OR SHALLOWER**, the rule the shared
`readtable()` uses, so a `###` subsection under the verdict anchor is part of the verdict section
and a corner table inside it is read. Ended at the next heading of ANY depth instead — which is what
this mode did until a plan opened one — the table falls outside the body, the mode compares ZERO
rows, and it printed `1 verdict note against 0 corner verdict rows under the {#target-verdict}
anchor, matched verbatim`: a clean pass over a table it never opened, with the whole corner-row half
disabled and the condition check ready to cry wolf over a phrase written below that heading.
Three further things it deliberately does not do belong in any change to it. **The section a verdict
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
was scoped out for once already. **The row side reads `status` as well as the title, and that is a
fifth failure rather than a looser match**: `model-row-dead-assumption` fires on a live row whose every
title match is at `status: superseded` or `retracted`, and the message names the note
and its status because the two repairs — point the row at the successor, or re-file the note — are
chosen off exactly that. Matching every title regardless of status made a live row backed only by a
superseded note report as *matched verbatim*, observed green for days over a live model. It is not
folded into `model-row-no-assumption`, because the row DID match a note and a reader told nothing
stands behind it goes and writes a second one; and it marks the row hit, so the same pair is never
also reported as an input the table has no row for. Ungated, since the trigger is a `status` value a
corpus only carries where a note was actually retired.

**And a live `claim` backs a row exactly as a live `assumption` does — reading only `assumption`
titles shipped a false positive inside an hour.** The title index the row direction matches against
holds every live note of either type, because a row is backed by whatever the ledger still stands
behind. **The pair is still a closed set and the type test is still load-bearing** — a `source` or
`fact` is provenance a claim rests *on* rather than a value the projection carries, and a
`milestone`, `question` or `decision` asserts no value at all, which is why the enumeration is
stated at the predicate in both scripts rather than left as an omission. Reading `assumption`
alone, the check fired on a row this method's own promotion rule
produces: a structural driver with no subject instrument belongs in the indexed set rather than
degraded to an assumption, so filing a sourced figure as unevidenced is the defect, and correcting it
retires the assumption and mints a `claim` carrying the same title. The failure then said the row's
only match was `superseded` with no `current` assumption carrying the title — both halves true, the
conclusion false, and the corpus it fired on had done exactly what the method says. **The note → row
direction did not widen to claims**, and that asymmetry is deliberate: `assumption-not-in-model` keys
on `model_input`, a field a promoted claim does not carry, so a claim never becomes a declared input.

**The note side had the SAME defect one field over, and it is the third in this release.**
`assumption-not-in-model` walked every assumption carrying `model_input` without reading `status`, so
a `superseded` or `retracted` note still owed a row or an `excluded_from_model` reason — and neither
escape is satisfiable on a retired note: rendering the dead title as a row undoes the repair the row
side asks for, and writing `excluded_from_model` records a decision about a live revenue line on a
corpse. Found end to end, in the order that makes it obvious: the row side flagged a dead-backed row,
re-titling it to the live claim cleared that, and this half instantly demanded a row for the note the
repair had pointed away from. **`MI` / `$inputs` now take the same live predicate `TITLE` does.**
The consequence worth stating is that **`excluded-line-on-roadmap` reads that same narrowed set** —
so a retired assumption a `milestone` still `moves` is silent. Where a live successor exists it
carries the obligation; where the note was retracted outright, the real defect is a roadmap pointing
at a dead note, which `check`'s `dangling-edge` does not cover (it fires on an ID no note carries,
never on a retired target) and nothing else reports. Giving the wrong repair confidently was worse
than the gap, and the gap is now written down rather than papered over. **One line survives the
narrowing on purpose**: the row loop still marks `HIT` on a retired match even though an `MI` member
is by construction live and therefore always hits via `TITLE` — widen the predicate again and that
marking is the only thing between one situation and two failures pointing at different repairs.

**And the success line stopped reading as a comparison** — a row backed by a
`claim` is not a declared model input and a declared input cleared by `excluded_from_model` is not a
row, so the two counts legitimately differ and a line setting one *against* the other sends its reader
looking for a row nothing owed. **Its fourth check is the identity's, not the
table's**:
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

`--citation-codes` is the same boundary one address over. `--used-in` opens the document and section
a NOTE names; plan prose cites `[F#]` and `[S#]`, which resolve through `research/founder-brief.md`
and `sources.md` — a contract `docs/specs/2026-07-27-claim-citation-codes.md` wrote down and nothing
enforced, so a code resolving to nothing rendered exactly like a working one and cleared the gate.
Two properties belong in any change to it. **The two index files are excluded from the scan, and
that is load-bearing rather than an optimisation**: an index legitimately records that a code was
withdrawn and deliberately left unused, which names that code in its own prose, and a scan reading
the mention as a citation fails a corpus doing the right thing. **It runs forward only**, which is
the opposite call to `--red-team`'s roster and `--roadmap-table`'s two directions and is specific to
an index: a recorded fact nothing leans on yet is healthy, so failing an uncited row would push an
author toward citing things to silence a linter, and there is no dodge by omission either way
because deleting the citation deletes the claim that needed it. **Its success line states the
limit**, which is the point of the mode rather than a footnote — resolution is necessary and not
sufficient, because a research file carries its own local `S` table and a document citing a local
code the global log also assigns resolves to a row and to a different source. Observed on four
documents at once, every code resolving. Ungated: the trigger is an index file the corpus either has
or does not.

`--unflattened-source` closes the half of that a check can reach — every row of a `research/*.md`
local source table must name a URL the root `sources.md` also names, because the log is what assigns
a citable `[S#]` and a source that never reached it can be cited from research prose and not from a
plan document at all. **The failure kind is `source-unflattened` and NOT `orphan-source`**, which
`check` already emits for close to the opposite finding — a source note nothing rests on — and
neither is widened into the other, because one is a source nobody cited and the other a source
nobody can cite. **The declared exemption decides whether the mode survives**: a corpus may
deliberately keep a per-row ledger of a hundred and fifty profile rows out of the log, and a mode
reporting all of them is switched off within a day, taking the working half with it. So the
exemption is read from the LOG'S OWN HEADER — a `Local ledger: <path> - <why>` line before the
log's first table row — rather than keyed on a filename this script knows, because the file holding
a ledger differs per corpus and a hardcoded name is a rule that only fits the vault it was written
against. A row carrying no URL is neither resolved nor failed and is counted in the success line
instead, the same rule `--assumption-rows` learned about a half that walks an empty set.

`--subject-orphan` is `coverage-gap` over the half of the vocabulary that rule cannot see, and the
two **partition** `_vocab.yml` rather than overlapping on it. `coverage-gap` fires on a
`required: true` subject with no claim under it; a subject optional in general is routinely
load-bearing in one plan, and there nothing notices that the documents argue from it and no note
was ever written. **A subject with no note cannot collide, cannot go stale, cannot be superseded
and cannot be challenged** — every query the ledger supports returns clean over it, because there
is nothing filed to return, and silent in every direction is what makes it a different failure from
an ordinary coverage gap. Three properties belong in any change to it. **The MENTION is the whole
trigger** — the term or one of its `aliases` on a line of a markdown document under the vault that
is not a `subject:` line — because without it this is `coverage-gap` over every optional term,
which fails a vault for declaring a vocabulary richer than the position it took. **A mention is
matched on TOKEN BOUNDARIES, never as a substring**: both sides are cut into lowercase alphanumeric
tokens and the candidate has to appear as a consecutive run, so `price` matches `Price` and never
`priceless` — a substring rule fires on ordinary prose, which is `--roadmap-table`'s crying-wolf
shape one mode over. And **the message is a diagnosis rather than a verdict** — the subject, the
document, the line number, the line, and which note to write — because this is the one check gated
on nothing that can turn a finished corpus red on the version that adds it. That is deliberate: a
corpus reasoning about a subject it has never filed is the state the mode exists to surface, and a
vacuous pass is worse than a red gate. Nothing is gated because there is nothing to gate on — it
reads no field a corpus written before it lacks — which is the exemption `schemaVersion` buys,
here declined rather than obtained cheaply.

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

`--foreclosed` is the first mode in this tool pointed at a plan claiming TOO LITTLE, and that is the
whole reason it exists rather than a framing. Every other guard here — the target verdict, the
citation codes, the assumption rows, the section hashes — fires on an overclaim, and the asymmetry
was already recognised twice in `skills/business-plan` (the furthest-defensible target, and
red-team pre-pass step 4) with both fixes stopping at the identity's own terms. A note asserting an
option is NOT viable removes work from the roadmap, kills a segment or takes a configuration off
the table, and **nothing attacks it**: all three panel lenses ask whether the plan can deliver what
it promises and none asks whether it wrongly concluded it could not. **The failure is silent by
construction, which is what makes it a different shape from every check that reads an edge** — the
option is gone, so nothing downstream references it, so no query has a target; the foreclosure
cannot dangle, cannot go stale in a way anybody notices, and cannot collide with the work it
cancelled, because that work was never written down. What a check can reach is the CONDITION, and
that is the whole of the mode: `foreclosure-no-reverse` fails a `current` note carrying `forecloses`
with no `reverses_if`. It is `validated_by` one field over and carries that rule's honest limit —
a stated reversal condition is not evidence the thinking was done, only that skipping it stopped
being the default. Three boundaries belong in any change to it. **It reads `claim` only, and
`--subject-orphan`'s closed pair does not transfer** — that rule asks which types *file* a
position, while these three fields are claim-only *by argument*: a foreclosure is a conclusion
drawn from an input, `foreclosed_on` names that input, and a note resting on nothing has no input
to name. Reading both types would give the wrong repair under the right name, because this mode's
message says to add `reverses_if` and the documented repair for an assumption in the shape of a
finding is the `question` the plan stopped asking. The dodge that narrowing looks like it opens is
closed by `check`'s `foreclosure-on-assumption` instead — **reported separately from
`type-agreement` for the reason `filename-mismatch` is**: the `type` field is correct and the
directory matches, so a reader sent to look at `type` reads `assumption`, concludes it is right,
and stops. Two rules, two repairs, and neither says the other's sentence. **`status` is read
and a retired foreclosure owes nothing**, the live predicate `--assumption-rows` learned — a
`superseded` or `retracted` note has already been taken back, so demanding a reversal condition of
it names a repair on a note the ledger retired. And **the passing side is a LISTING, not a bare
pass**: the mode feeds the panel as well as the gate, so its success line names every foreclosure
with the section its `used_in` reached, and a vault where nothing forecloses is told which half did
not run rather than that its conclusions agree. **`foreclosed-on-dangling` is the mode's second
kind, and it exists because `foreclosed_on` is a SCALAR note reference** — `check`'s dangling-edge
rule walks the block-list edge fields and never opens one, which is the gap `superseded_by` has and
which the repo answers the same way: a rule of its own rather than a silent omission. The cost is
specific to this field. The floor skeptic is briefed off this mode's output with `foreclosed_on` in
it, so a dangling target dispatches the one lens pointed at the foreclosure to a note that does not
exist — and a lens that found nothing is indistinguishable from a foreclosure that survived being
attacked, which is the vacuous pass this release exists to close, shipped by the release closing
it. It is a separate kind from `foreclosure-no-reverse` because the repairs differ: write the
missing note or fix the typo, against state the condition. **Ungated, and the absence of a gating sentence
here would be the wrong reading** — the three fields ship additive at the current `schemaVersion`
and this rule is deliberately behind no version at all, because the trigger is the PRESENCE of
`forecloses`: a corpus written before the field declares nothing and can owe nothing, so a version
spent here would buy an exemption over an empty population. That is the exemption `schemaVersion`
exists to provide, obtained without spending one, on the terms `superseded_by`'s two rules are on.

**`check`'s `population-unnested` is the collision rule one subject over, and the version it costs
is the point of it.** Two `current` claims sharing a `subject` are a collision, and `vault.md`
resolves one three ways — supersede a side, add a `scopes` edge because one is narrower, or go
settle the disagreement. Under `market-size` there is a fourth state none of those describes: the
populations are BOTH right and one sits inside the other, a behavioural cut inside a professional
population inside a broader one, and `nested_in` is the edge that records it. Without it a
percentage-of-market figure is a share of whichever population its reader assumed, and taking the
innermost silently produces the smallest share available — which then reads as conservative rather
than as a decision nobody made. Three properties belong in any change to it. **Both ends of the edge
count as one relation**, because the question is whether the pair is related and not which way
round, and a rule reading only the narrower end fails a corpus that wrote the edge from the other.
**The test is CONNECTIVITY and not whether each note carries an edge** — `vault.md` states the
contract in those words, and reachability is walked transitively, so three rings are satisfied by
two edges and demanding the third would ask for a fact already derivable from the other two. The
two forms look equivalent and are not, which is why this is written down rather than left to the
next reader: **two nested pairs under one subject, each internally edged and neither related to the
other, leaves every note carrying an edge and the set still holding two unrelated ring systems**,
so a share figure is a percentage of whichever system its reader assumed — the failure the edge
exists to remove, surviving the check that was added to remove it. The edges are unioned and the
components counted. And **it reports per NOTE rather than per group**, where `false-independence`
and `duplicate-url` report per member: there the whole group is implicated and neither member is
the wrong one, here each row names the claims *that* note has no chain to, so the note a reader
opens tells them which ring is still unrecorded and a note already connected to everything is not
a row at all. Gated on `schemaVersion` 4 — the paragraph above has why —
and the suite asserts the GATE rather than only the rule, by running
`scripts/fixtures/population-no-edge` and then a copy of it restamped to 3, which is the idiom
`--subject-orphan` already uses: the two vaults cannot differ in anything but the version, where a
second checked-in fixture tree would desync the first time somebody edited one of them.
**`nested_in` is in `EDGE_FIELDS`, and the rule ALSO resolves the target itself — both halves, for
different failures.** In the set, a mistyped edge is a `dangling-edge` under its own name and
`graph` walks the ring; that is what the other ten edge fields already buy. Resolving it here as
well is what stops a typo *satisfying* this check: read as a bare relation, `nested_in: CLAIM-TYPO`
makes the corpus look nested, the rule clears, and nothing anywhere says the edge points at
nothing — a vacuous pass handed back by the check written to refuse one. It resolves through the
same `BYID` index every other edge-reading rule uses, so an unresolvable edge links nothing. **It
does not lean on `dangling-edge` having run first, and that is deliberate:** that rule is ungated
and this one is gated on 4, so a nesting check assuming its sibling already fired would be assuming
something the gate does not guarantee. A typo is therefore two failures, which is correct — fix the
target, and record the ring are different repairs.

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
