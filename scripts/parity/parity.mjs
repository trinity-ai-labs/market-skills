#!/usr/bin/env node
// parity.mjs - hold bin/vault-lint.ps1 to bin/vault-lint.sh, mode by mode.
//
//   node scripts/parity/parity.mjs
//
// Zero dependencies, node: imports only, for the same reason scripts/check.mjs
// is: this repo is public and people clone it to GET the skills, so a
// contributor tool must never require a package manager.
//
// WHY THIS EXISTS
// bin/vault-lint.sh is 3,600+ lines of awk-heavy POSIX shell. bin/vault-lint.ps1
// is a SECOND implementation of the same tool, for a Windows session that has no
// POSIX shell to run the first one. Two implementations of a linter that size
// drift silently: each keeps passing its own reading of the fixtures while
// answering a real vault differently, and the first person to notice is a user
// acting on the wrong answer. This runs every mode over every fixture vault
// through both and diffs the answers, so "is the port correct?" is a mechanical
// question rather than an asserted one.
//
// WHAT IT COMPARES, AND HOW
//   - Seven modes support --json. Those compare the JSON document BYTE FOR BYTE
//     plus the exit code, with no normalization at all.
//   - `graph` and --release-gate refuse --json (bin/vault-lint.sh:423 and :495).
//     Those compare normalized stdout, normalized stderr and the exit code. The
//     normalizer is three rules wide and every one of them is written out at
//     normalize() below, because an over-eager normalizer is exactly how an
//     unchecked mode reads as covered.
//   - Exit codes are part of every comparison. The shell answers 0 (clean),
//     1 (failures found) and 2 (refusal), and those are three different answers.
//
// THE ALLOWLIST
// scripts/parity/unported/<mode> is one marker file per mode not yet ported.
// A directory of files rather than a list in one file, because the port is six
// parallel slices each removing exactly one entry: a single list means six
// branches editing adjacent lines of one file, which conflicts on every merge
// and can silently restore a line during resolution. This fails loudly on both
// directions of rot - a mode that is neither ported nor allowlisted, and a
// marker for a mode that IS ported - so the list cannot go stale unnoticed.
// While the allowlist is non-empty this exits 0 and prints the count, because a
// gate that goes red until the last slice lands makes CI red on every slice PR
// from now until then, which destroys the signal exactly when it is needed.

import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { cpus, tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

// Both implementations are addressed by a path RELATIVE to the repo root, and
// every child process runs with cwd = ROOT. See runLint() for why that matters.
const SH_LINT = 'bin/vault-lint.sh';
const PS_LINT = 'bin/vault-lint.ps1';
const FIXTURES = 'scripts/fixtures';

const UNPORTED_DIR = join(ROOT, 'scripts', 'parity', 'unported');

// The exit status a not-yet-ported mode answers with. The shell uses 0, 1 and 2
// only, so 3 cannot be mistaken for a verdict - which is the whole reason the
// PowerShell stubs use it.
const NOT_PORTED_STATUS = 3;

// The two modes with no --json form, named once here rather than as a per-mode
// flag, next to the lines of bin/vault-lint.sh that refuse it. Asserted rather
// than derived, because a mode's refusal to accept --json and a vault the tool
// refuses to read both answer 2 and probing cannot tell them apart. The cost of
// getting this wrong is that both sides would die identically on --json and the
// empty stdout would compare EQUAL, so a mode wrongly listed as JSON-capable
// would read as compared while never being exercised - which is why every JSON
// mode also has to produce a document at least once (see compareMode).
const TEXT_ONLY_MODES = new Set(['graph', 'release-gate']);

// Two lists, and the exit code is what tells them apart. `problems` holds parity
// findings - the two implementations answered a vault differently - and exits 1.
// `harnessErrors` holds every way this tool failed to put the question at all,
// and exits 2: a child that died instead of answering, a probe that could not be
// classified, and either implementation having no interpreter to run it. That is
// the split assertRunFixturesModesMatchCensus already drew by exiting 2 inline,
// generalised to the cases that arise after the run has started and so have to
// be collected rather than exited on.
//
// THE FAILURE THIS PREVENTS: a caller that retries an infrastructure flake and
// escalates a real regression cannot tell them apart if both exit 1. The three
// one-sided cases above all mean "nothing was compared", and reporting that with
// the code reserved for "the two scripts disagree" names the wrong culprit.
const problems = [];
const harnessErrors = [];

// Two facts are parsed out of the shell implementation rather than copied here -
// the mode census and the note-type directories. Read LAZILY and memoized: at
// import time a parse failure would throw outside main()'s catch, and Node exits
// 1 on an uncaught throw, which is this tool's code for "the implementations
// disagree". A harness that cannot read its own reference must not say that.
let shellSourceCache = null;
const shellSource = () => (shellSourceCache ??= readFileSync(join(ROOT, SH_LINT), 'utf8'));

// ---------------------------------------------------------------------------
// the mode census - derived from bin/vault-lint.sh, never hand-maintained here
//
// Read out of MODE_TABLE rather than written down again, because another copy
// of the census is another place it can rot: a mode added to the shell with no
// entry here would simply never be compared, and this gate would keep printing
// green over a mode nothing checks. Derived, a new mode is both unported and
// unallowlisted the moment its row lands, and this fails until someone says
// which of the two it is.
// ---------------------------------------------------------------------------

/** Every mode bin/vault-lint.sh answers to, in the order MODE_TABLE declares. */
function modeCensus() {
  const table = /^MODE_TABLE='\n([\s\S]*?)\n'$/m.exec(shellSource());
  if (!table) throw new Error(`${SH_LINT}: no MODE_TABLE to read the mode census from`);

  const modes = table[1]
    .split('\n')
    .map((row) => row.trim().split(/\s+/)[0])
    .filter(Boolean)
    // "The MODE token is the SELECTOR with its leading `--` stripped"
    // (bin/vault-lint.sh:315) - the same rule the shell's own mode_for_flag
    // applies, so a flag and a token cannot disagree across the two files.
    .map((selector) => selector.replace(/^--/, ''));

  // `graph` is deliberately not a MODE_TABLE row (bin/vault-lint.sh:320): it
  // takes an operand instead of being selected by a flag, and --release-gate
  // cannot run a mode that needs a note ID. It is still a mode a user invokes
  // and still has to be ported, so it is appended by hand - the one entry that
  // is not derived, and the reason it is not is above.
  modes.push('graph');

  if (modes.length !== new Set(modes).size) throw new Error(`${SH_LINT}: MODE_TABLE names a mode twice`);
  return modes;
}

/**
 * The argv a mode is invoked with against one fixture, or null when this fixture
 * cannot answer it - `graph` needs a note ID and a vault with no notes has none.
 * Returning null rather than throwing is what lets the caller report the skip
 * instead of dropping the fixture silently.
 */
function argvFor(mode, vault) {
  const vaultArg = `${FIXTURES}/${vault}`;
  // `check` stays a positional subcommand and `graph` takes an operand; every
  // other mode is its token with `--` back on the front.
  if (mode === 'check') return ['check', '--vault', vaultArg, '--json'];
  if (mode === 'graph') {
    const target = graphTargetFor(vault);
    return target ? ['graph', target, '--vault', vaultArg] : null;
  }
  const argv = [`--${mode}`, '--vault', vaultArg];
  if (!TEXT_ONLY_MODES.has(mode)) argv.push('--json');
  return argv;
}

// ---------------------------------------------------------------------------
// the third census - scripts/fixtures/run-fixtures.sh's MODES
//
// There are three separate lists of this lint's modes: MODE_TABLE in the shell
// (authoritative - the argument parser and --release-gate both read it),
// modeCensus() above (derived from MODE_TABLE, so it cannot itself drift), and
// MODES in scripts/fixtures/run-fixtures.sh, hand-maintained there because it
// drives that suite's --help census assertion - the one thing MODE_TABLE cannot
// absorb, since a mode's usage() paragraph is written by hand at a shared
// anchor rather than generated from the table (run-fixtures.sh, "every mode has
// help text"). Nothing checks that third list against the other two: a mode
// added to MODE_TABLE with no matching edit to MODES does not fail
// run-fixtures.sh - the --help loop just iterates one fewer mode and the
// assertion under-tests in silence, which is exactly the "check that stops
// firing and a check that was deleted look identical from the outside" failure
// run-fixtures.sh itself is written to prevent, recurring one file over. This
// is why MODE_TABLE exists as a table in the first place (bin/vault-lint.sh
// :305-320) - census drift already bit this repo once.
// ---------------------------------------------------------------------------

const RUN_FIXTURES = join(FIXTURES, 'run-fixtures.sh');

/**
 * The mode list scripts/fixtures/run-fixtures.sh hand-maintains for its --help
 * assertion, parsed the same way modeCensus() reads MODE_TABLE - tokens with a
 * leading `--` stripped - so the two lists compare on equal terms.
 */
function runFixturesModeCensus() {
  const source = readFileSync(join(ROOT, RUN_FIXTURES), 'utf8');
  const line = /^MODES="([^"]*)"$/m.exec(source);
  if (!line) throw new Error(`${RUN_FIXTURES}: no MODES= line to read its mode census from`);
  return line[1]
    .split(/\s+/)
    .filter(Boolean)
    .map((token) => token.replace(/^--/, ''));
}

/**
 * Fail loudly when run-fixtures.sh's MODES has drifted from the census
 * modeCensus() derives from MODE_TABLE - naming the file and what to do about
 * it, the same voice every other rot guard in this file uses.
 *
 * This is a HARNESS error, not a parity finding: the two implementations were
 * never compared, and a contributor's hand-maintained list going stale is a
 * different failure than the shell and PowerShell disagreeing, so it exits 2
 * here rather than joining `problems` (which exits 1). A reader tells the two
 * apart by the exit code alone.
 */
function assertRunFixturesModesMatchCensus(census) {
  const declared = runFixturesModeCensus();
  const wantSet = new Set(census);
  const gotSet = new Set(declared);
  const missing = census.filter((mode) => !gotSet.has(mode));
  const extra = declared.filter((mode) => !wantSet.has(mode));
  if (!missing.length && !extra.length) return;

  const lines = [
    `parity: ${RUN_FIXTURES}: its MODES list has drifted from the mode census ${SH_LINT}'s MODE_TABLE ` +
      `declares - the --help census assertion is under-testing in silence.`,
  ];
  if (missing.length) lines.push(`  in MODE_TABLE but missing from MODES: ${missing.join(', ')}`);
  if (extra.length) lines.push(`  in MODES but not a real mode: ${extra.join(', ')}`);
  lines.push(
    `Edit MODES in ${RUN_FIXTURES} to match: one token per mode, in MODE_TABLE's order, each with its ` +
      `\`--\` back on the front except \`check\` and \`graph\`.`,
  );
  console.error(lines.join('\n'));
  process.exit(2);
}

// ---------------------------------------------------------------------------
// the fixture vaults
// ---------------------------------------------------------------------------

/** Every fixture under scripts/fixtures/ that is actually a vault. */
function fixtureVaults() {
  return readdirSync(join(ROOT, FIXTURES), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .filter((name) => existsSync(join(ROOT, FIXTURES, name, '.vault', 'config.json')))
    .sort();
}

/**
 * The seven directories bin/vault-lint.sh treats as notes, read out of the
 * script rather than copied here for the same reason the mode census is: a
 * hand-copied list stops matching in silence, and a fixture whose notes moved to
 * a directory this does not know about reports as "no notes" and quietly drops
 * out of the `graph` comparison instead of failing.
 */
let noteDirsCache = null;
function noteDirs() {
  if (noteDirsCache) return noteDirsCache;
  const loop = /^for d in ([a-z ]+); do$/m.exec(shellSource());
  if (!loop) throw new Error(`${SH_LINT}: no note-directory loop to read the note types from`);
  noteDirsCache = loop[1].split(' ').filter(Boolean);
  return noteDirsCache;
}

// Keyed by fixture name. graphTargetFor walks every note in a vault, and the
// same vault is asked for its target by the ported-mode probe and again by the
// comparison loop; without this the whole corpus is re-read several times a run.
const graphTargets = new Map();

/**
 * The lowest note ID in a fixture, or null when it carries no notes.
 *
 * Read out of the frontmatter rather than off the filename, because one fixture
 * exists to trip `filename-mismatch` where the two deliberately disagree - and
 * an ID no note carries sends `graph` down its "no note in this vault" branch
 * instead of the traversal this is meant to exercise. Lowest rather than first
 * found, so the target does not move when a note file is added.
 */
function graphTargetFor(vault) {
  if (graphTargets.has(vault)) return graphTargets.get(vault);
  const ids = [];
  for (const dir of noteDirs()) {
    const abs = join(ROOT, FIXTURES, vault, dir);
    if (!existsSync(abs)) continue;
    for (const name of readdirSync(abs)) {
      if (!name.endsWith('.md')) continue;
      const frontmatter = /^---\r?\n([\s\S]*?)\r?\n---/.exec(readFileSync(join(abs, name), 'utf8'));
      if (!frontmatter) continue;
      // Either quote form, as scripts/check.mjs reads a frontmatter scalar: an
      // `id` this failed to read is a note that silently leaves the corpus.
      const id = /^id:[ \t]*(.*)$/m.exec(frontmatter[1]);
      if (id) ids.push(id[1].trim().replace(/^["']|["']$/g, ''));
    }
  }
  // IDs are ASCII, so the default sort is byte order.
  const target = ids.length ? ids.sort()[0] : null;
  graphTargets.set(vault, target);
  return target;
}

// ---------------------------------------------------------------------------
// the two interpreters
// ---------------------------------------------------------------------------

/** Run a candidate binary with a probe argv; true when it answered 7. */
function answersProbe(command, argv) {
  const probe = spawnSync(command, argv, { cwd: ROOT, stdio: 'ignore' });
  return !probe.error && probe.status === 7;
}

/**
 * The first candidate interpreter that answers the probe, or null.
 *
 * An explicit override REPLACES the search rather than heading it: an override
 * that silently fell back to a discovered interpreter would run the gate against
 * a host nobody asked for and still report a pass.
 */
function findInterpreter(override, discovered, argv) {
  const candidates = override ? [override] : discovered;
  return candidates.find((command) => answersProbe(command, argv)) ?? null;
}

/**
 * A POSIX shell to drive bin/vault-lint.sh, or null.
 *
 * Driven through an explicit interpreter rather than executed directly, because
 * on Windows a checkout carries no executable bit and Git Bash is the only way
 * the .sh side runs there at all.
 */
function findPosixShell() {
  const discovered = ['sh', 'bash', 'C:\\Program Files\\Git\\bin\\bash.exe', 'C:\\Program Files\\Git\\usr\\bin\\sh.exe'];
  return findInterpreter(process.env.PARITY_SH, discovered, ['-c', 'exit 7']);
}

/**
 * A PowerShell host to drive bin/vault-lint.ps1, or null.
 *
 * powershell.exe FIRST and pwsh only as a fallback: the port targets Windows
 * PowerShell 5.1 because that is what ships in-box on Windows, and a gate that
 * only ever exercised pwsh would not be testing the thing that ships.
 */
function findPowerShell() {
  const discovered = ['powershell.exe', 'pwsh', 'pwsh.exe'];
  return findInterpreter(process.env.PARITY_POWERSHELL, discovered, ['-NoProfile', '-Command', 'exit 7']);
}

// ---------------------------------------------------------------------------
// one PowerShell startup cache per worker
//
// THE FAILURE THIS PREVENTS: two PowerShell hosts corrupting one another's
// startup cache, which kills a child on SIGABRT mid-run. Before the non-verdict
// rule below that arrived as `.sh 1, .ps1 134` and read as the two
// implementations disagreeing - a parity finding this harness manufactured.
//
// KNOWN: concurrent non-interactive PowerShell sessions corrupt the shared
// ~/.cache/powershell/StartupProfileData-NonInteractive and die with 134 or 139,
// primarily on macOS - https://github.com/PowerShell/PowerShell/issues/26528.
// Every element of that report is present here: runLint spawns -NonInteractive,
// bin/vault-lint.ps1 re-invokes a host per --release-gate part, and nothing
// keeps two of those from overlapping - two contributors gating at once on one
// machine is enough, and running cells concurrently makes it the normal case.
//
// INFERRED: that this is the cause. Five aggressive reproduction attempts at
// concurrency 8 and 10 produced no crash, so the mechanism matches every
// observable without having been demonstrated here. Giving each worker its own
// XDG_CACHE_HOME removes the shared file the report blames and costs nothing if
// the hypothesis is wrong. It is NOT what makes a residual crash readable - the
// non-verdict rule is, whichever way this goes.
//
// PER WORKER, not per cell: the cache has to warm once and be reused, or every
// cell pays a cold PowerShell start - about 300ms of the ~400ms a JSON cell
// takes on the PowerShell side.
//
// Inert where it does not apply, and never a requirement to run: Windows
// PowerShell 5.1 is .NET Framework and keeps no ~/.cache/powershell, so the
// variable is simply unread there, and a directory that cannot be created
// degrades to the unmodified process environment rather than aborting the gate.
// ---------------------------------------------------------------------------

// undefined = not attempted, null = unavailable, string = the directory.
let cacheRoot;
const cacheHomes = [];

function cacheHomeFor(slot) {
  if (cacheRoot === undefined) {
    try {
      cacheRoot = mkdtempSync(join(tmpdir(), 'parity-pwsh-cache-'));
    } catch {
      cacheRoot = null;
    }
  }
  if (!cacheRoot) return null;
  if (cacheHomes[slot] === undefined) {
    const dir = join(cacheRoot, `worker-${slot}`);
    try {
      mkdirSync(dir, { recursive: true });
      cacheHomes[slot] = dir;
    } catch {
      cacheHomes[slot] = null;
    }
  }
  return cacheHomes[slot];
}

// On `exit` rather than in a finally: process.exit() does not unwind the stack,
// and every failure path in this file leaves through it.
process.on('exit', () => {
  if (!cacheRoot) return;
  try {
    rmSync(cacheRoot, { recursive: true, force: true });
  } catch {
    // A temp directory left behind is not worth changing this tool's answer for.
  }
});

// Every child currently running, so an interrupt can take them down with it.
const liveChildren = new Set();

// Ctrl-C during a multi-minute sweep is ordinary, and a signal does not run the
// `exit` handler above - so an interrupted run would strand a cache directory.
// The children have to die FIRST: killing this process alone leaves its
// PowerShell hosts running, and one of those rewrites the startup cache after
// the cleanup has already removed it, which both strands the directory and
// leaves hosts alive to corrupt the cache of whatever runs next - the very
// failure the per-worker directory exists to prevent. Exiting explicitly with
// the conventional 128+N code then runs the cleanup and keeps the status a
// caller sees unchanged. THE LIMIT: SIGKILL cannot be handled at all, so a hard
// kill still leaves the directory and the hosts behind.
for (const [signal, number] of [
  ['SIGINT', 2],
  ['SIGTERM', 15],
]) {
  process.on(signal, () => {
    for (const child of liveChildren) child.kill('SIGKILL');
    process.exit(128 + number);
  });
}

// ---------------------------------------------------------------------------
// running one side
// ---------------------------------------------------------------------------

/**
 * Invoke one implementation and capture raw bytes, exit status and signal.
 *
 * THE VAULT IS ALWAYS A RELATIVE PATH, and cwd is always the repo root. The
 * `vault` field of every JSON document echoes the argument verbatim
 * (`--vault scripts/fixtures/clean` emits `"vault": "scripts/fixtures/clean"`),
 * so a relative argument is what makes byte-identity achievable at all: an
 * absolute one hands `/c/Users/...` to a Git Bash sh and `C:\Users\...` to
 * PowerShell on the same machine, and then no JSON mode can ever match.
 *
 * Buffers, not strings: byte-for-byte has to mean bytes, and decoding first
 * would fold a real encoding difference into an equal comparison.
 *
 * `signal` is returned rather than discarded because a child killed outright
 * has a null status, and reporting that as `.ps1 null` is worse than reporting
 * the 134 the other shape of the same death produces. nonVerdict() reads both.
 *
 * Asynchronous spawn, not spawnSync: spawnSync blocks the event loop, so a pool
 * built on it would run one cell at a time no matter how many workers it had.
 */
function runLint(side, argv, slot) {
  const spawnArgv =
    side.kind === 'sh'
      ? [SH_LINT, ...argv]
      : ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', PS_LINT, ...argv];
  // Only the PowerShell side reads XDG_CACHE_HOME, so only it gets a modified
  // environment - the shell side runs with this process's own, untouched.
  const cacheHome = side.kind === 'ps' ? cacheHomeFor(slot) : null;
  const env = cacheHome ? { ...process.env, XDG_CACHE_HOME: cacheHome } : process.env;

  return new Promise((settle, fail) => {
    const child = spawn(side.interpreter, spawnArgv, { cwd: ROOT, env });
    liveChildren.add(child);
    const stdout = [];
    const stderr = [];
    child.stdout.on('data', (chunk) => stdout.push(chunk));
    child.stderr.on('data', (chunk) => stderr.push(chunk));
    child.on('error', (err) => {
      liveChildren.delete(child);
      fail(new Error(`${side.label}: ${err.message}`));
    });
    child.on('close', (status, signal) => {
      liveChildren.delete(child);
      settle({ stdout: Buffer.concat(stdout), stderr: Buffer.concat(stderr), status, signal });
    });
  });
}

// ---------------------------------------------------------------------------
// a non-verdict exit is a HARNESS error, not a parity finding
//
// THE FAILURE THIS PREVENTS: a PowerShell host killed by SIGABRT mid-cell
// reported as `exit status: .sh 1, .ps1 134`, which reads as the two
// implementations answering a vault differently. It sent a reviewer hunting a
// port bug that did not exist. 134 is 128 + SIGABRT.
//
// The discriminator is the one NOT_PORTED_STATUS already relies on: the tool
// documents 0 (clean), 1 (failures) and 2 (refusal) and nothing else, so
// anything outside that set was not produced by the tool. A signal death
// arrives in two shapes and both are covered - the child killed directly
// (status null, signal 'SIGABRT') and the host exiting 128+N because its OWN
// child died, which is what PowerShell's $LASTEXITCODE propagates (status 134,
// signal null).
//
// THE LIMIT, stated because this repo has just spent a release on success lines
// that claimed more than they verified: this catches a status ABOVE 2 and a
// signal death, and NOTHING ELSE. A host failure that exits 1 - a PowerShell
// parse error is the ordinary one - is indistinguishable from a lint verdict of
// 1 by status alone, so it still arrives as a parity finding and still reads as
// a disagreement. Telling those apart would mean reading stderr for meaning,
// which is a different rule with a different failure behind it.
// ---------------------------------------------------------------------------

const VERDICT_STATUSES = new Set([0, 1, 2]);

/** Why this run is not a verdict this tool produces, or null when it is one. */
function nonVerdict(run) {
  if (run.signal) return `was killed by signal ${run.signal}`;
  if (run.status === null) return 'ended with neither an exit status nor a signal';
  if (VERDICT_STATUSES.has(run.status)) return null;
  if (run.status > 128) {
    return `exited ${run.status}, which is 128 + ${run.status - 128}: a child of its own died on signal ${run.status - 128}`;
  }
  return `exited ${run.status}, outside the 0, 1 and 2 this tool documents`;
}

// ---------------------------------------------------------------------------
// normalization - THREE rules, and only for the two modes that have no --json
//
// This function is the whole risk surface of the text comparison: anything it
// strips is a place a real difference can hide, so each rule states the
// mechanical reason the two implementations CANNOT agree on that substring, and
// nothing else is touched.
//
//   1. The diagnostic prefix. bin/vault-lint.sh:65 hardcodes PROG as its own
//      filename and die() prints `vault-lint.sh: <message>`; the PowerShell side
//      names itself the same way. The two files are named differently by
//      construction, so this one substring can never match. Anchored to the
//      start of a line, so a filename appearing anywhere else still gets
//      compared. The refusal MESSAGE after the prefix is compared in full, and
//      the exit code with it - and scripts/fixtures/run-fixtures.sh asserts both
//      refusal paths against whichever implementation VAULT_LINT names, so this
//      rule is not the only thing holding the two messages together.
//   2. The run date, in the one place the tool injects one into human output:
//      the `stale-claim` message at bin/vault-lint.sh:3534 reads `and today is
//      <date>,`. The two sides run seconds apart, so without this a run that
//      crossed midnight would report a false diff. Bound to that phrase, so a
//      date that came out of a fixture's frontmatter - `stale_after is
//      2020-01-01`, in the same sentence - is still compared exactly.
//   3. The absolute path of the repo root, in each spelling a host might use.
//      It is machine-specific and cannot be part of the contract. This does NOT
//      collapse absolute against relative: the leading separator survives the
//      substitution, so `<repo>/scripts/fixtures/clean` and
//      `scripts/fixtures/clean` still differ and still fail.
//
// Line endings are NOT normalized. A document with CRLF in it is a different
// document to whatever consumes it, so a CRLF divergence is a real finding and
// has to stay visible.
// ---------------------------------------------------------------------------

const REPO_ROOT_SPELLINGS = (() => {
  const spellings = new Set([ROOT, ROOT.replace(/\//g, '\\'), ROOT.replace(/\\/g, '/')]);
  // Git Bash spells C:\Users\x as /c/Users/x, and it is the shell driving the
  // .sh side on Windows while PowerShell drives the other.
  const drive = /^([A-Za-z]):[\\/](.*)$/.exec(ROOT);
  if (drive) spellings.add(`/${drive[1].toLowerCase()}/${drive[2].replace(/\\/g, '/')}`);
  return [...spellings];
})();

function normalize(buffer) {
  let text = buffer.toString('utf8');
  text = text.replace(/^vault-lint\.(?:sh|ps1): /gm, 'vault-lint: ');
  text = text.replace(/ and today is \d{4}-\d{2}-\d{2},/g, ' and today is <today>,');
  for (const spelling of REPO_ROOT_SPELLINGS) text = text.split(spelling).join('<repo>');
  return text;
}

/** The first line where two texts differ, escaped so whitespace stays legible. */
function firstDifference(shText, psText) {
  const shLines = shText.split('\n');
  const psLines = psText.split('\n');
  for (let i = 0; i < Math.max(shLines.length, psLines.length); i++) {
    if (shLines[i] === psLines[i]) continue;
    return [
      `line ${i + 1}:`,
      `.sh  ${JSON.stringify(shLines[i] ?? '<no such line>')}`,
      `.ps1 ${JSON.stringify(psLines[i] ?? '<no such line>')}`,
    ].join('\n');
  }
  return `no differing line, but ${shText.length} vs ${psText.length} characters`;
}

// ---------------------------------------------------------------------------
// comparing one cell - one mode against one fixture, through both scripts
// ---------------------------------------------------------------------------

const indent = (text) => text.replace(/^/gm, '  ');

/**
 * Run both implementations over one cell and reduce the answer to a verdict the
 * report can aggregate: a diff or nothing, whether the shell produced a
 * document, or a harness error saying the two were never compared.
 *
 * The comparison happens HERE rather than in the caller so the output buffers
 * die with the cell - 632 cells holding two buffers each would otherwise all be
 * live at once.
 */
async function compareCell(cell, shSide, psSide, slot) {
  // Started together: the two are independent processes over a read-only vault,
  // and the shell side is roughly a tenth of the PowerShell side's runtime, so
  // awaiting it first would put it on the critical path for nothing.
  const [sh, ps] = await Promise.all([runLint(shSide, cell.argv, slot), runLint(psSide, cell.argv, slot)]);
  const where = `${cell.vault} (${cell.argv.join(' ')})`;

  const shWhy = nonVerdict(sh);
  const psWhy = nonVerdict(ps);
  if (shWhy || psWhy) {
    const sides = [];
    if (shWhy) sides.push(`${SH_LINT} ${shWhy}`);
    if (psWhy) sides.push(`${PS_LINT} ${psWhy}`);
    return {
      harnessError:
        `${cell.mode} on ${where}: ${sides.join(', and ')}. The two implementations were NOT compared for ` +
        `this cell - a crashed child is this harness failing, not the two scripts disagreeing.`,
    };
  }

  const document = sh.stdout.length > 0;

  if (sh.status !== ps.status) {
    return { document, diffs: [`${where}\n  exit status: .sh ${sh.status}, .ps1 ${ps.status}`] };
  }

  if (TEXT_ONLY_MODES.has(cell.mode)) {
    // One diff per differing STREAM, not one per cell: stdout and stderr
    // disagreeing are two findings, and collapsing them would drop one from the
    // report's count.
    const diffs = [];
    for (const stream of ['stdout', 'stderr']) {
      const shText = normalize(sh[stream]);
      const psText = normalize(ps[stream]);
      if (shText === psText) continue;
      diffs.push(`${where}\n  normalized ${stream} differs\n${indent(firstDifference(shText, psText))}`);
    }
    return { document, diffs };
  }

  // JSON modes: the document itself, byte for byte, no normalization. stderr
  // is deliberately excluded - it carries only the die() diagnostic, whose
  // prefix is each script's own filename; the exit code above already tells a
  // refusal (2) from a failure (1) from a clean run (0).
  if (sh.stdout.equals(ps.stdout)) return { document, diffs: [] };
  const detail = firstDifference(sh.stdout.toString('utf8'), ps.stdout.toString('utf8'));
  return { document, diffs: [`${where}\n  JSON differs\n${indent(detail)}`] };
}

// ---------------------------------------------------------------------------
// the worker pool - over CELLS, and the report order is not the finish order
//
// The sweep is 16 modes x 40 fixtures and about 93% of its wall time is the
// PowerShell side starting up, so it is almost entirely waiting. Running cells
// concurrently takes it from roughly 8.5 minutes to 2.5 on an 8-core machine.
//
// OVER CELLS, NOT MODES. Pooled at mode level the speedup caps at 16 and
// --release-gate - alone about half the sweep, because bin/vault-lint.ps1
// re-invokes a host per gate part - becomes a four-minute straggler on one
// worker while the rest idle. Cells spread it across every worker.
//
// THE FAILURE THE ORDERING RULE PREVENTS: a report whose lines arrive in
// completion order varies run to run, so two CI logs cannot be diffed and a
// reviewer cannot tell a new failure from a reordered one. Results are written
// into the cell they came from and read back in MODE_TABLE x fixture order, so
// the pool changes when work happens and never what the report says.
//
// This adds NOTHING to what is compared. Every cell the serial loop ran, the
// pool runs; the per-mode `N compared` counts are the proof and must not move.
// ---------------------------------------------------------------------------

// Floored at 1: cpus() answers an empty array on some hosts, and a pool of zero
// workers would run no cells at all while every per-mode line still printed.
const DEFAULT_JOBS = Math.max(1, Math.min(8, cpus().length));

/** How many cells run at once. Measured knee is 4-8; 8 is 3.4x over serial. */
function poolSize() {
  const declared = process.env.PARITY_JOBS;
  if (declared === undefined || declared === '') return DEFAULT_JOBS;
  const jobs = Number.parseInt(declared, 10);
  if (!Number.isInteger(jobs) || jobs < 1) throw new Error(`PARITY_JOBS=${declared} is not a positive integer`);
  return jobs;
}

/**
 * One cell per mode per fixture, in MODE_TABLE order and then fixture order -
 * the order the report reads them back in. A fixture a mode cannot be invoked
 * against becomes a named skip rather than a missing cell, because an
 * uncompared fixture that says nothing reads exactly like a compared one.
 */
function planCells(modes, vaults) {
  const plan = new Map();
  for (const mode of modes) {
    const cells = [];
    const skipped = [];
    for (const vault of vaults) {
      const argv = argvFor(mode, vault);
      if (!argv) {
        skipped.push(vault);
        continue;
      }
      cells.push({ mode, vault, argv, result: null });
    }
    plan.set(mode, { cells, skipped });
  }
  // Flattened out of `plan` rather than accumulated beside it, so there is one
  // list and the run order cannot drift from the order the report reads back. A
  // Map iterates in insertion order, which is the order `modes` was walked in.
  return { plan, all: [...plan.values()].flatMap((entry) => entry.cells) };
}

/**
 * Run every cell across a bounded pool, each worker holding one slot for the
 * whole run so its PowerShell startup cache warms once.
 */
async function runCells(cells, shSide, psSide) {
  const jobs = Math.min(poolSize(), cells.length);
  let next = 0;
  const worker = async (slot) => {
    for (let i = next++; i < cells.length; i = next++) {
      cells[i].result = await compareCell(cells[i], shSide, psSide, slot);
    }
  };
  await Promise.all(Array.from({ length: jobs }, (_unused, slot) => worker(slot)));
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

async function main() {
  const modes = modeCensus();
  assertRunFixturesModesMatchCensus(modes);
  const vaults = fixtureVaults();

  // A missing directory is an EMPTY allowlist, not an error: git does not track
  // empty directories, so the last slice to remove its marker removes the
  // directory with it, and that state is the finish line rather than a fault.
  const allowlisted = new Set(existsSync(UNPORTED_DIR) ? readdirSync(UNPORTED_DIR).sort() : []);

  console.log(`parity: ${SH_LINT} vs ${PS_LINT}`);
  console.log(`  modes:    ${modes.length} (${modes.join(', ')})`);
  console.log(`  fixtures: ${vaults.length}`);

  for (const marker of allowlisted) {
    if (modes.includes(marker)) continue;
    problems.push(
      `scripts/parity/unported/${marker} names no mode ${SH_LINT} answers to. Either a mode was renamed ` +
        `and this marker was not, or the marker is a typo that has been silently excusing nothing.`,
    );
  }

  const psPresent = existsSync(join(ROOT, PS_LINT));
  const psInterpreter = psPresent ? findPowerShell() : null;
  const psSide = { kind: 'ps', interpreter: psInterpreter, label: PS_LINT };

  /**
   * Which modes the PowerShell side actually answers, or null when it cannot be
   * asked. PROBED rather than declared, so a marker file cannot outlive the port
   * it excuses: an entry for a mode that answers properly now is a stale entry.
   */
  async function portedModes() {
    if (!psPresent) {
      console.log(`  ${PS_LINT}: does not exist yet - nothing to compare, so every mode must be allowlisted`);
      return new Set();
    }
    if (!psInterpreter) {
      harnessErrors.push(
        `one-sided: fixture suite only - ${PS_LINT} exists but no PowerShell host was found to run it ` +
          `(tried powershell.exe, then pwsh). This gate compared nothing and is not reporting a pass. ` +
          `Install Windows PowerShell 5.1 or PowerShell 7, or set PARITY_POWERSHELL.`,
      );
      return null;
    }
    console.log(`  ${PS_LINT}: driven through ${psInterpreter}`);

    // Every mode is probed against one vault that carries notes, so `graph` gets
    // the operand it needs and no mode is classified off a fixture it refuses.
    const probeVault = vaults.find((vault) => graphTargetFor(vault));
    if (!probeVault) throw new Error(`${FIXTURES}: no fixture vault carries a note, so no mode can be probed`);

    const answered = new Set();
    for (const mode of modes) {
      // Slot 0, so the probe warms the cache the first worker will reuse.
      const run = await runLint(psSide, argvFor(mode, probeVault), 0);
      // The stub's sentinel is the one answer outside 0/1/2 that means something
      // here, so it is read FIRST; anything else has to be a verdict. Without
      // this the classification is `status !== 3`, and a probe child killed by a
      // signal answers null - which is not 3, so a crashed probe would be filed
      // as PORTED and could then report a live marker file as stale. That is the
      // same fabricated finding nonVerdict() exists to stop one call site over.
      if (run.status === NOT_PORTED_STATUS) continue;
      const why = nonVerdict(run);
      if (why) {
        harnessErrors.push(
          `probing \`${mode}\` against ${probeVault}: ${PS_LINT} ${why}. Whether the mode is ported could ` +
            `not be established, so nothing about it was compared or excused.`,
        );
        continue;
      }
      answered.add(mode);
    }
    return answered;
  }

  const ported = await portedModes();
  // One name for "the PowerShell side could be asked at all". An empty Set means
  // nothing is ported yet, which is a normal state; null means the question could
  // not be put, which is not.
  const probed = ported !== null;

  if (probed) {
    for (const mode of modes) {
      if (ported.has(mode) && allowlisted.has(mode)) {
        problems.push(
          `scripts/parity/unported/${mode} is stale: ${PS_LINT} answers \`${mode}\` now. ` +
            `Delete the marker so the mode is compared instead of excused.`,
        );
      }
      if (!ported.has(mode) && !allowlisted.has(mode)) {
        problems.push(
          `\`${mode}\` is neither ported nor allowlisted, so nothing checks it. Port it in ${PS_LINT}, ` +
            `or add scripts/parity/unported/${mode} to say so out loud.`,
        );
      }
    }
  }

  const toCompare = probed ? modes.filter((mode) => ported.has(mode) && !allowlisted.has(mode)) : [];
  const shInterpreter = toCompare.length ? findPosixShell() : null;
  const shSide = { kind: 'sh', interpreter: shInterpreter, label: SH_LINT };

  if (toCompare.length && !shInterpreter) {
    // A harness that reports success when it compared nothing is worse than no
    // harness. This is the realistic Windows-runner-without-Git-Bash case: the
    // fixture suite still proves the .ps1 answers correctly, but
    // nothing here proves the two AGREE, and that has to be said rather than
    // swallowed.
    harnessErrors.push(
      `one-sided: fixture suite only - no POSIX shell was found to run ${SH_LINT}, so ` +
        `${toCompare.length} ported mode(s) went uncompared. Set PARITY_SH, or install Git Bash.`,
    );
  } else if (toCompare.length) {
    console.log(`  ${SH_LINT}: driven through ${shInterpreter}`);
  }

  const comparable = shInterpreter ? toCompare : [];
  const { plan, all } = planCells(comparable, vaults);
  await runCells(all, shSide, psSide);

  console.log();

  for (const mode of modes) {
    if (allowlisted.has(mode)) {
      console.log(`  ${mode.padEnd(20)} allowlisted (scripts/parity/unported/${mode})`);
      continue;
    }
    if (!comparable.includes(mode)) {
      console.log(`  ${mode.padEnd(20)} NOT COMPARED - see the failures below`);
      continue;
    }

    // Read back in plan order, never completion order - see runCells.
    const { cells, skipped } = plan.get(mode);
    const diffs = [];
    let compared = 0;
    let documents = 0;
    for (const { result } of cells) {
      if (result.harnessError) {
        harnessErrors.push(result.harnessError);
        continue;
      }
      compared++;
      if (result.document) documents++;
      diffs.push(...result.diffs);
    }

    const how = TEXT_ONLY_MODES.has(mode) ? 'normalized stdout/stderr + exit code' : 'byte-identical JSON + exit code';
    const skipNote = skipped.length ? `, ${skipped.length} skipped (no notes): ${skipped.join(', ')}` : '';
    console.log(`  ${mode.padEnd(20)} ${compared} compared${skipNote} - ${diffs.length ? `${diffs.length} DIFFER` : how}`);

    // Two ways a mode can wear a green line without having been checked, which
    // is the one outcome this whole design exists to make impossible.
    if (!compared) problems.push(`\`${mode}\` was compared over ZERO fixtures, so nothing about it was checked.`);
    if (compared && !documents) {
      problems.push(
        `\`${mode}\` produced no output from ${SH_LINT} on any of ${compared} fixtures, so every comparison ` +
          `was of one empty stream against another. A mode that refuses its own arguments dies the same way ` +
          `on both sides and compares EQUAL - check that TEXT_ONLY_MODES still describes which modes take --json.`,
      );
    }
    for (const diff of diffs) problems.push(`${mode}: ${diff}`);
  }

  // The count is what the PowerShell side actually ANSWERS, not what the
  // allowlist implies: when the two disagree the failures below say so, and a
  // headline derived from the allowlist would report the disagreement as progress.
  console.log();
  console.log(`parity: ${probed ? ported.size : 0}/${modes.length} modes ported, ${allowlisted.size} allowlisted`);

  if (harnessErrors.length || problems.length) {
    const lines = [...harnessErrors, ...problems].map((entry) => `parity: ${entry}`);
    console.error(`\n${lines.join('\n\n')}`);
    // Both lists are printed because both are findings someone has to read, and
    // the exit code is what says which kind this run was: a harness failure wins,
    // because a run that could not put the question cannot report the answer.
    process.exit(harnessErrors.length ? 2 : 1);
  }
}

// Exit 2 on a crash, as scripts/check.mjs does. Node exits 1 on an uncaught
// throw, which here reads as "the two implementations disagree" - the one answer
// a broken harness must never give by accident.
main().catch((err) => {
  console.error('parity: crashed —', err?.stack || err);
  process.exit(2);
});
