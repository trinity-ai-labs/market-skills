#!/bin/sh
#
# vault-lint.sh - read-only whole-corpus checks over a claim vault.
#
#   vault-lint.sh [check] [--vault PATH] [--json]
#   vault-lint.sh --release-gate [--vault PATH]
#   vault-lint.sh graph <ID> [--depth N] [--vault PATH]
#
# This is shipped tooling: it runs on a user machine as part of the skill, so it
# assumes nothing beyond a POSIX shell. No Node, no Python, no yq, no jq, no
# dependency of any kind - a runtime prerequisite discovered at the moment of use
# is a broken product, and a tool that reads an entire private business corpus
# should not carry a transitive dependency tree.
#
# WHAT THIS SCRIPT IS FOR, AND WHAT IT IS NOT FOR
# Code owns whole-corpus aggregation and transitive closure; the agent owns
# authoring individual notes. One note, one field, one hop is a grep. All notes,
# or more than one hop, is this script. The test is whether a wrong answer is
# visible as wrong - a malformed note is visible when you read it, a corpus-wide
# near-miss is not. There is deliberately no write mode: a write CLI cannot see a
# corpus-wide near-miss, because each note is individually valid, and it would
# round-trip verbatim prose through shell argv quoting.
#
# WHAT --used-in CHECKS, AND WHAT IT DELIBERATELY DOES NOT
# --used-in asserts that a used_in entry RESOLVES: the document exists, and the
# #anchor names a heading in it. It never asserts that the named section carries
# the claim. Plan prose cites [S#] and [F#] codes, and a claim note carries no
# citation code at all - so a scan matching note IDs against prose reports a
# false positive on every correctly cited claim, dozens deep on a healthy vault.
# A check that cries wolf gets switched off, and switching it off takes the half
# that worked along with it. Whether the section agrees with the note is a read
# over a bounded worklist, not a grep, and it is not this script's job - but
# BOUNDING that read is: --supersession-sweep names the sections a supersession
# put in doubt, so the read is over that list rather than over every citation in
# the corpus. A judgment step nobody can size is a judgment step nobody starts.
#
# WHAT A VERDICT CAN SAY ABOUT A READ
# It cannot say the read was done well. It can say whether anything in the
# corpus records that it was done at all, which is the difference between a
# worklist and a gate: `reconciled:` on the superseding note and the
# `## Lenses dispatched` roster in red-team.md are both assertions somebody has
# to write, and both are checkable. Neither is evidence the sections were
# actually re-read - a date can be stamped without reading anything - and that
# is the honest limit of a mechanical check over a judgment step. What it buys
# is that skipping the read becomes something you have to state rather than
# something that happens by default, and the default is what was shipping.
#
# PARSING STRATEGY
# The frontmatter reader is a subset parser over flat scalars, block lists, and
# the four fields allowed a literal block scalar. It COERCES NOTHING - every
# value is treated as text. That is what makes a shell parser adequate: a reader
# that does no type coercion cannot diverge from a real YAML parser, because
# there is nothing left to be wrong about. The schema bans the values a YAML
# parser would coerce, and the ambiguous-value check reports them.
#
# PORTABILITY
# BSD (macOS) and GNU (Linux) userlands differ, so this file sticks to POSIX
# behaviour: /bin/sh with no arrays, no [[ ]], no local; awk rather than chained
# sed (no sed -i, no awk gensub, no grep -P); date +%Y-%m-%d rather than +%F.
# Almost all the work happens inside three awk programs, which keeps the number
# of places a userland difference can bite down to find, sort, date and mktemp.

set -u

PROG="vault-lint.sh"

# ----------------------------------------------------------------------------
# usage and refusals
# ----------------------------------------------------------------------------

# ONE BLOCK PER MODE, IN MODE_TABLE ORDER, AND A NEW MODE APPENDS ITS BLOCK
# IMMEDIATELY BEFORE THE `graph` ONE. Interleaving is what turns a release that
# adds three modes into three edits to the same lines here, and git merges two
# of those textually clean - leaving one mode with a working flag and no help
# text, which reads to its author exactly like a mode that was never added.
usage() {
	cat <<'EOF'
vault-lint.sh - read-only checks over a claim vault.

  vault-lint.sh [check] [--vault PATH] [--json]
      Run every note-level check over the vault. Exits 1 if anything failed.
      A strict subset of what a release owes: it never opens a citation
      target and never asks what a supersession put in doubt, which is what
      --release-gate is for.

  vault-lint.sh --unverified [--vault PATH] [--json]
      Report the notes asserted with nothing behind them: everything with
      status: unverified, and everything carried at Low confidence. A target
      list, not a verdict - it exits 0 whether or not it finds any.

  vault-lint.sh --used-in [--vault PATH] [--json]
      Open every note's used_in target and check that it resolves: the document
      exists under the vault root, and the #anchor names a heading in it. A
      verdict - it exits 1 on any failure. Kept out of `check` because it reads
      documents outside the note directories, which is a different surface.

      An anchor resolves two ways, and a heading offers both. A heading ending
      in an explicit `{#anchor}` attribute answers to that attribute, which is
      what survives a rewording; every heading also answers to the GitHub slug
      of its text with the attribute stripped off, which is what a citation
      written before the document carried attributes still names.

      It checks that the target RESOLVES, never that the section CARRIES the
      claim. Plan prose cites [S#] and [F#] codes and a claim note carries no
      citation code at all, so matching note IDs against prose would report a
      false positive on every correctly cited claim - and a check that cries
      wolf gets switched off, taking the half that worked with it.

  vault-lint.sh --supersession-sweep [--vault PATH] [--json]
      Emit the re-read worklist a supersession owes, and fail when nothing in
      the corpus records that it was read. For every superseded note, the
      document sections its used_in named - unioned across the corpus and
      grouped by section, so two superseded notes citing one section are one
      row naming both rather than two rows for one job. Each row carries the
      superseded note, the note that replaced it, and the supersedes_reason,
      which is the only question anyone ever asks about a superseded note.

      THE WORKLIST STAYS A REPORT; THE VERDICT IS A SEPARATE QUESTION. Finding
      rows is the point of asking, so a healthy vault exits 0 with a worklist
      in it - a mode that went non-zero on a supersession with a blast radius
      would train its caller to ignore the exit code the actual checks depend
      on. What fails is a note carrying `supersedes` with no `reconciled:`
      date, or one earlier than that note's own `created`: the sections were
      never read, or were read before the supersession that put them in doubt
      existed.

      The verdict applies at schemaVersion 2 only. A vault at 1 predates the
      field, cannot owe it, and exits 0 either way - vault-migration.md carries
      the back-fill.

      It reports the row count as well as the rows, because the gate that
      consumes this is a read and a read is bounded only if its size is visible
      before it starts. A superseded note whose used_in named nothing is listed
      as such rather than dropped - it reached no document, which is the good
      case, and a sweep that omitted it silently would look exactly like one
      that failed to read it.

  vault-lint.sh --release-gate [--vault PATH]
      Run every mode a release owes, in order, printing each part's output
      under its own heading. Which modes those are is the gate column of the
      mode table and not a list written out here: this block already went
      one mode short once, because a hand-written enumeration beside a table
      that composes itself is the half nobody edits. The exit status is the
      worst status any part returned, so the gate is clean only when every
      part is.

      It exists because the alternative was three calls made from memory, and
      which of them actually ran was a matter of recall. The bare run's
      success line covers the notes alone, so a corpus with dozens of dead
      anchors clears the only call anybody remembered to make and renders.

      --json is refused here: several JSON documents printed one after
      another are not a JSON document. Run each mode with --json separately
      when a consumer needs to parse the result.

  vault-lint.sh --red-team [--vault PATH] [--json]
      Check red-team.md's panel record against itself: every lens named in its
      `## Lenses dispatched` roster wrote at least one objection row, and every
      row's lens is on the roster. A verdict - it exits 1 on either.

      Nothing else in the corpus records which lenses were dispatched, so
      without the roster a lens that returned findings, saw them folded into
      two documents and never wrote a row is indistinguishable from a lens
      that had no objections - silence and thoroughness read the same, and the
      plan then cites objection codes into a file carrying none of them. The
      reverse direction is checked because otherwise the gate clears by
      deleting a lens from the roster, which is the cheapest way past it.

      A vault with no red-team.md dispatched no panel and passes. A red-team.md
      with no roster fails at schemaVersion 2, where the roster is part of the
      schema, and passes at 1, which predates it.

  vault-lint.sh --roadmap-table [--vault PATH] [--json]
      Check the roadmap table in business-plan.md against the milestone notes,
      both directions. A verdict - it exits 1 on either.

      The table renders sequence, moves and resource off the notes, so its
      item cell IS the milestone title and a correctly generated table matches
      by construction. The match is VERBATIM, character for character, the same
      rule `chosen` is held to against `options` and for the same reason: a row
      that paraphrases its note has stopped being a rendering of it, and
      nothing else in the corpus can tell.

      A row matching no milestone title is an item that escaped the ledger, so
      it moves no assumption anybody can name and the model carries a dated
      change with nothing behind it. A milestone the table never lists is a
      dated change to an assumption row the plan does not show, so the curve
      has a step the reader cannot see.

      Only the FIRST table under the roadmap heading is read. The section
      legitimately carries a second one - the permutation comparison of
      roadmap-sequencing.md Rule 3, whose first column is an ORDER rather than
      an item - and reading it would report every one of its rows as an item
      that escaped the ledger.

      A vault with no milestone notes owes no roadmap and passes, whether or
      not it has a business-plan.md. A vault WITH milestone notes and no
      business-plan.md fails: the roadmap is in the ledger and nowhere a
      reader can see it. Gated on schemaVersion 2, which is where the
      milestone type was added - a vault at 1 carries none and cannot owe this.

  vault-lint.sh --binding-driver [--vault PATH] [--json]
      Check a target verdict against the plan section that renders it: the
      driver that binds, that driver's kind, and the evidence underneath it.
      A verdict - it exits 1 on any of its four failures.

      A verdict is a `claim` or an `assumption` carrying a subject of
      target-verdict or steady-state-ceiling, plus binding_driver,
      driver_kind, evidence_n and evidence_counterparties - and
      conditional_on on top of those four exactly when driver_kind is policy
      or policy-within-band, since a structural verdict has no choice to
      name. The two rules that read nothing but the note - the fields are
      owed as a set, and driver_kind takes one of three words - are in
      `check`. This mode is the half that has to open business-plan.md.

      verdict-unconditional: driver_kind is policy or policy-within-band and
      conditional_on does not appear in the plan section the note renders
      into. `Your target is unreachable` and `your target is unreachable at
      six hours a week across two channels` are indistinguishable in a
      rendered plan, at the same confidence letter, and only the second one
      is true.

      verdict-kind-mismatch: the corner verdict table under the
      {#target-verdict} anchor renders its Kind column off driver_kind, so a
      cell that disagrees with the note its Binding driver cell names is a
      kind the plan asserts and the ledger does not hold. Checked in BOTH
      directions - a verdict note whose driver no row carries fails too,
      because otherwise the rule above is cleared by editing a cell.

      verdict-thin-evidence: the closure under the note reaches fewer than
      three distinct source notes, or they all share one counterparty, and
      the tail is not surfaced. Surfacing it is a CONJUNCTION - the note
      carries evidence_n and evidence_counterparties matching the closure,
      AND the section it renders into carries the one line those two
      generate, `Evidence: 2 sources, 1 counterparty`, matched verbatim.
      Honest counts in the ledger with nothing rendered is the failure this
      exists for: that section reads identically to one whose verdict rests
      on twenty deals across twelve parties, and confidence cannot separate
      them. The line is owed only where the tail is thin, so a
      well-evidenced verdict owes nothing and this never becomes a line on
      every plan. A single counterparty is reportable at any n.
      Counterparty comes from `counterparty`, then `publisher`, then the
      host of url_canonical.

      verdict-unfiled: a non-empty section at the {#target-verdict} anchor
      with no verdict note behind it. This is --roadmap-table inverted - that
      mode fails milestone notes with no business-plan.md to render them, and
      this fails a rendered section with nothing in the ledger behind it.
      WHAT TRIGGERS IT IS THE PRESENCE OF THE SECTION and never a reading of
      the prose inside it. There is deliberately no {#steady-state}
      equivalent: a ceiling section in an existing plan legitimately has no
      field-carrying note behind it.

      Both strings a document renders off a note - conditional_on and the
      Kind cell - are matched VERBATIM, the same rule --roadmap-table holds a
      milestone title to. There is no phrase list and no sentence-shape
      inference anywhere in this mode: a check that cries wolf gets switched
      off, and switching it off takes the half that worked with it.

      THERE IS NO schemaVersion GATE, and the two subjects trigger
      differently. target-verdict is a term this release introduces, so no
      existing corpus carries it and the fields are owed whatever else the
      note carries - a note under that subject holding none of them fails.
      steady-state-ceiling predates its amendment and is required, so every
      existing vault already holds one - there the trigger is field
      presence, and a ceiling claim carrying none of the five owes none of
      them. A vault with no verdict note passes.

  vault-lint.sh --assumption-rows [--vault PATH] [--json]
      Check the assumptions table in financial-model.md against the assumption
      notes that declare themselves inputs to the model, both directions. A
      verdict - it exits 1 on any of its four failures.

      This is --roadmap-table one artifact over, and it exists because the
      rule it inverts had no counterpart. plan-template.md requires that no
      number in a projection is anything but a named assumption row, which is
      load-bearing against fake precision - and nothing asked whether a named
      assumption was MISSING from the table. Observed: two assumptions
      governing a whole revenue line existed as notes, correctly authored with
      subjects and confidence, and were never added as rows. The rule meant to
      enforce rigour then made that revenue line structurally unable to enter
      the projection, the model filed it as revenue outside its scope, and
      every downstream verdict inherited a denominator missing a line the
      roadmap ships. The notes lint clean, the table lints clean, and until
      this mode nothing compared them.

      The key is the assumption `title`, matched VERBATIM, the same rule
      --roadmap-table holds a milestone title to and for the same reason: the
      table renders `value`, its source and its confidence off the note, so a
      correct table matches character for character by construction and a
      mismatch means the row was written by hand.

      assumption-not-in-model: a note carrying `model_input` whose title is no
      row in the table and which carries no `excluded_from_model` reason. The
      trigger is the FIELD, not the version - `model_input` is a term this
      release introduces, so no existing note carries it and no exemption has
      to be bought for one.

      model-row-no-assumption: a row matching no `assumption` note title. The
      reverse direction, and it is what stops the rule above being cleared by
      writing a row nothing in the ledger stands behind.

      excluded-line-on-roadmap: an assumption the roadmap ships a change to -
      a `milestone` whose `moves` names it - that carries
      `excluded_from_model` and that no verdict note's `arr_excludes` declares.
      A model may LEGITIMATELY exclude a revenue line, because a metered layer
      must not be allowed to flatter subscription churn; what it may not do is
      exclude it silently. The identity the verdict solves is ARR at the target
      date times the multiple, so an excluded line is a term missing from the
      denominator every corner is solved against - and on the engagement this
      came from the excluded layer was a roadmap item with roughly ten times
      the revenue per account, three separate re-solves each corrected a
      different term, and the answer never moved. Declaring it at the identity
      is what makes the exclusion arguable.

      model-table-missing: notes declare themselves model inputs and the table
      renders none of them. The inputs are in the ledger and nowhere a reader
      can see them.

      Gated on schemaVersion 3, which is where the fields it reads were added.
      A vault at 1 or 2 carries none of them, cannot owe this, and is told the
      rule was not applied rather than that the table agrees.

  vault-lint.sh --claim-drift [--vault PATH] [--json]
      Check every cited section against the content hash the note recorded
      when it was last reconciled. A verdict - it exits 1 on any of its three
      failures.

      This is the half --used-in deliberately leaves out, obtained without
      reading prose for meaning. --used-in asserts a citation RESOLVES and
      --binding-driver asserts one verbatim string is present; neither can say
      whether a section still carries what it carried yesterday. Observed: a
      claim was written into a plan section, satisfying invariant 20. A later
      re-solve rewrote that block. The heading was untouched, so `used_in`
      still resolved and the gate stayed green while the section no longer
      said what the note says. It was found by hand, days later - the exact
      failure invariant 20 exists to prevent, occurring after the invariant
      had been satisfied once.

      A hash cannot tell you the section still AGREES with the note. It tells
      you whether the text somebody read is the text standing there now, which
      is the difference between a claim that was reconciled and one that was
      reconciled and then quietly rewritten. `reconciled:` records the date
      that read happened; `reconciled_sections` records what was read, one
      entry per citation, so a changed section RE-OPENS the claim instead of
      passing on a date nothing has re-examined since.

      section-hash-drifted: the recorded hash and the section disagree. The
      message carries the current hash, so re-reconciling is re-reading the
      section and pasting one token - the mode is read-only and the paste is
      the assertion that the read happened.

      section-hash-missing: a resolving citation with no entry recording it.
      Without this the whole rule is cleared by omission, which is not an
      exemption.

      section-hash-unused: an entry naming a target the note's `used_in` does
      not name. Bookkeeping for a section this claim no longer cites reads as
      coverage, and reads that way from both sides.

      It reads only `claim` and `assumption` notes whose `status` is current,
      and only entries whose #anchor resolves. A dead anchor is --used-in's
      verdict, and reporting it twice under a name about reconciliation sends
      its reader to the wrong fix. Gated on schemaVersion 3, which is where
      `reconciled_sections` was added - vault-migration.md carries the
      back-fill.

  vault-lint.sh graph <ID> [--depth N] [--vault PATH]
      Print the neighbourhood of one note as text: what it rests on, and what
      rests on it, to the given depth (default 2).

Options
  --vault PATH   the vault root, also accepted as --vault=PATH. Falls back to
                 $VAULT_PATH. There is no upward search from the working
                 directory - you are never inside a vault when you use it, and
                 an upward search finds either nothing or a different
                 engagement corpus.
  --json         machine-readable output for an agent consumer.
  --depth N      graph traversal depth, also accepted as --depth=N (default 2).
  --help         this text.

Exit codes
  0  clean, or a report mode that ran
  1  at least one check failed
  2  refused to run (no vault, no config, unsupported schemaVersion, bad usage)
EOF
}

die() {
	printf '%s: %s\n' "$PROG" "$1" >&2
	exit 2
}

# ----------------------------------------------------------------------------
# the mode table - the seam a new mode registers into
#
# One row per mode. Columns are separated by whitespace and the last one runs
# to the end of the line:
#
#   SELECTOR  the argument that selects the mode - a flag, or `check` for the
#             one mode that is a bare subcommand
#   GATE      `gate` if --release-gate runs it as one of its parts, `-` if not
#   PART      the heading --release-gate prints above that part's output
#
# ADDING A MODE IS ADDING A ROW. The argument parser reads the SELECTOR column
# and --release-gate reads all three, so a new mode needs no arm of its own in
# the `case` block below and no edit to the gate's composition - it needs a row
# here, a block in usage(), and its own dispatch further down. A release that
# adds three modes is what made this a table: three modes each editing the same
# `case` block is three conflicts, and git resolves two of them textually clean
# while one mode silently loses the arm that parses its flag.
#
# There is no MODE column because it would restate its neighbour on every row:
# the MODE token is the SELECTOR with its leading `--` stripped. That is a rule
# a new mode has to follow rather than an accident - a flag and a token that
# disagreed would be a discrepancy this table could not show.
#
# `graph` is deliberately not a row. It takes an operand rather than being
# selected by a flag, so it is parsed in the positional block below - and a
# mode that needs a note ID has nothing --release-gate could run unattended.
#
# --unverified is a row but not a gate part. Its whole population is the
# healthy case - an assumption is supposed to be unverified until its
# validation step runs - so a gate that ran it would either ignore the output
# or fail every vault that has an assumption in it.
MODE_TABLE='
check                gate  note-level checks
--unverified         -     -
--used-in            gate  citation targets
--supersession-sweep gate  supersession blast radius
--release-gate       -     -
--red-team           gate  panel objection rows
--roadmap-table      gate  roadmap table against the milestone set
--binding-driver     gate  verdict drivers and the evidence under them
--assumption-rows    gate  assumption rows against the model table
--claim-drift        gate  cited sections against their recorded hash
'

# The MODE a command-line flag selects, or empty when the flag names no mode.
# `check` is in the table so --release-gate can invoke it, and is skipped here
# because it stays a positional subcommand: accepting it as a flag would make
# `vault-lint.sh --vault PATH check` mean something it has never meant.
mode_for_flag() {
	while read -r sel _; do
		case "$sel" in --?*) ;; *) continue ;; esac
		if [ "$sel" = "$1" ]; then
			printf '%s\n' "${sel#--}"
			break
		fi
	done <<EOF
$MODE_TABLE
EOF
}

# ----------------------------------------------------------------------------
# arguments
# ----------------------------------------------------------------------------

MODE="check"
VAULT=""
JSON=0
DEPTH=2
TARGET=""

if [ $# -gt 0 ]; then
	case "$1" in
	check)
		shift
		;;
	graph)
		MODE="graph"
		shift
		[ $# -gt 0 ] || die "graph needs a note ID, for example: vault-lint.sh graph CLAIM-AS23SD44"
		TARGET="$1"
		shift
		;;
	esac
fi

while [ $# -gt 0 ]; do
	case "$1" in
	--vault)
		[ $# -ge 2 ] || die "--vault needs a path"
		VAULT="$2"
		shift 2
		;;
	--vault=*)
		VAULT="${1#--vault=}"
		shift
		;;
	--json)
		JSON=1
		shift
		;;
	--depth)
		[ $# -ge 2 ] || die "--depth needs a number"
		DEPTH="$2"
		shift 2
		;;
	--depth=*)
		DEPTH="${1#--depth=}"
		shift
		;;
	--help | -h)
		usage
		exit 0
		;;
	# Every mode flag resolves through the mode table rather than through an
	# arm of its own, which is what makes adding a mode a one-line append.
	*)
		SELECTED=$(mode_for_flag "$1")
		[ -n "$SELECTED" ] || die "unexpected argument: $1"
		[ "$MODE" = "graph" ] && die "$1 and graph are separate modes"
		MODE="$SELECTED"
		shift
		;;
	esac
done

case "$DEPTH" in
'' | *[!0-9]*) die "--depth must be a whole number, got: $DEPTH" ;;
esac

[ "$MODE" = "graph" ] && [ "$JSON" -eq 1 ] &&
	die "graph prints text only - its consumer is an agent building a plan, not an eye looking at a picture"

# ----------------------------------------------------------------------------
# locate and validate the vault
#
# Resolution is --vault, then $VAULT_PATH, then refuse. Never an upward search:
# from a code repo that walks to the filesystem root and errors far from its
# cause, or finds a .vault belonging to a different engagement and reads the
# wrong corpus with no error at all.
# ----------------------------------------------------------------------------

[ -n "$VAULT" ] || VAULT="${VAULT_PATH:-}"
[ -n "$VAULT" ] || die "no vault. Pass --vault <path> or set VAULT_PATH."
[ -d "$VAULT" ] || die "not a directory: $VAULT"

VAULT="${VAULT%/}"
CONFIG="$VAULT/.vault/config.json"
[ -f "$CONFIG" ] ||
	die "not a vault - no .vault/config.json under $VAULT. Refusing rather than walking an arbitrary directory of Markdown as if it were a corpus."

# The versions this tool can read, oldest first. A SET rather than a single
# number, because both directions of the mismatch are not the same problem. A
# vault at 1 predates the checks version 2 added and cannot owe them, so
# refusing it would fail every corpus that existed before they did - the tool
# reads it and holds it to exactly the rules it was written under. A version
# from the FUTURE stays refused, which is the whole reason the field exists: an
# older tool half-reading a newer vault reports a clean bill of health over
# every field it never saw.
#
# 3 joins the set for --assumption-rows and --claim-drift. Both read fields no
# corpus written before this release carries, and both would otherwise fire on
# every existing vault the day the plugin updates: --claim-drift would demand a
# recorded hash from every claim already cited into a plan, which is every claim
# in every finished corpus. A version is exactly what that exemption costs, and
# vault-migration.md carries the 2 -> 3 back-fill.
SUPPORTED_SCHEMA="1 2 3"
FOUND_SCHEMA=$(awk '
	match($0, /"schemaVersion"[ \t]*:[ \t]*[0-9]+/) {
		s = substr($0, RSTART, RLENGTH)
		if (match(s, /[0-9]+$/)) { print substr(s, RSTART, RLENGTH); exit }
	}
' "$CONFIG")

[ -n "$FOUND_SCHEMA" ] ||
	die "$CONFIG carries no schemaVersion. A tool that guesses half-reads the vault and reports a clean bill of health over every field it never saw."
case " $SUPPORTED_SCHEMA " in
*" $FOUND_SCHEMA "*) ;;
*) die "vault schemaVersion is $FOUND_SCHEMA and this tool reads only these versions: $SUPPORTED_SCHEMA. Refusing rather than processing the parts it recognises - a green result from a half-read vault is exactly what somebody acts on." ;;
esac

# ----------------------------------------------------------------------------
# --release-gate - every mode a release owes, in one call
#
# The gate before a render was three calls made from memory, so which of them
# actually ran was a matter of recall. This runs the set and carries one
# verdict out, which is the only form a gate can be held to.
#
# EACH PART IS A FRESH INVOCATION OF THIS SCRIPT rather than a function call.
# Every mode below is a top-to-bottom pipeline that ends in `exit`, and `check`
# and --used-in share one failure file - running two of them in one process
# would mean threading a reset between them and letting one mode's failures
# land in the other's verdict. A process boundary is the cheapest thing that
# cannot get that wrong, and the cost is re-reading the corpus once per part on
# a command that runs once per release.
#
# $0 is the path the kernel handed the interpreter, so it is the resolved
# script even when the shell found it on PATH - which is how it is always
# invoked, since Claude Code puts an enabled plugin's bin/ on PATH.
#
# THE EXIT STATUS IS THE WORST STATUS ANY PART RETURNED, not the last one and
# not a flattened 1. A refusal (2) and a failed check (1) are different
# answers - one says the tool would not read the vault, the other says it read
# it and found something - and reporting both as 1 sends a reader hunting for a
# failure in a check that never ran.
# ----------------------------------------------------------------------------

if [ "$MODE" = "release-gate" ]; then
	[ "$JSON" -eq 0 ] ||
		die "--release-gate prints several modes in sequence, and several JSON documents printed one after another are not a JSON document. Run each mode with --json separately."

	GATE_STATUS=0
	GATE_FAILED=""
	printf 'vault-lint release-gate: %s\n' "$VAULT"

	while read -r sel gate part; do
		[ "$gate" = "gate" ] || continue
		printf '\n--- %s: %s ---\n' "$sel" "$part"
		"$0" "$sel" --vault "$VAULT"
		PART_STATUS=$?
		[ "$PART_STATUS" -gt "$GATE_STATUS" ] && GATE_STATUS="$PART_STATUS"
		[ "$PART_STATUS" -eq 0 ] || GATE_FAILED="$GATE_FAILED $sel"
	done <<EOF
$MODE_TABLE
EOF

	if [ "$GATE_STATUS" -eq 0 ]; then
		printf '\nvault-lint release-gate: every part passed - %s\n' "$VAULT"
	else
		printf '\nvault-lint release-gate: did not pass -%s\n' "$GATE_FAILED" >&2
	fi
	exit "$GATE_STATUS"
fi

VOCAB="$VAULT/_vocab.yml"
HAS_VOCAB=0
[ -f "$VOCAB" ] && HAS_VOCAB=1

# The rendered plan at the vault root, and whether it is there. Three modes read
# it - --roadmap-table for the roadmap section, --binding-driver for the verdict
# section, and --used-in through the path index - so the predicate is computed
# once here beside HAS_VOCAB rather than per mode with a prefix on the name. Two
# prefixed copies of a one-line test is how a third arrives.
PLAN="$VAULT/business-plan.md"
HAS_PLAN=0
[ -f "$PLAN" ] && HAS_PLAN=1

# The financial model beside it, on the same terms and for the same reason:
# --assumption-rows reads its assumptions table, so the predicate is computed
# once here rather than prefixed onto a copy of the two lines above.
FINMODEL="$VAULT/financial-model.md"
HAS_FINMODEL=0
[ -f "$FINMODEL" ] && HAS_FINMODEL=1

# Every field whose block-list items name other notes. This is DELIBERATELY
# wider than vault.md's seven edges: `covers` is a question field and
# `assumptions_low` and `option_evidence` come from decisions.md, and none of
# the three is called an edge anywhere - but each holds note IDs, so each has to
# be followed for a dangling target and walked by `graph`. Declared once and
# passed to both awk programs that traverse it: two copies would let `graph` and
# `check` disagree about which fields exist, which is the tool shrinking its own
# blast radius exactly the way it warns notes not to.
#
# `depends_on` and `moves` are here unconditionally rather than behind the
# schema gate below. A vault at 1 carries neither field, so listing them costs
# nothing there - and gating them would mean the schema-2 check that `moves`
# names a note that exists is a rule of its own instead of the dangling-edge
# rule every other edge already gets.
#
# `arr_excludes` is here for the same reason `moves` is: its items are note IDs,
# so a mistyped one has to be a dangling edge rather than a silent exclusion. An
# ARR term that declares it leaves out a note the vault does not hold is the one
# form of that declaration nobody can check by reading it, and `graph` walking
# the edge is what makes the excluded line reachable from the verdict.
EDGE_FIELDS="rests_on supersedes scopes validated_by depends_on moves covers assumptions_low option_evidence arr_excludes"

# ----------------------------------------------------------------------------
# scratch space
# ----------------------------------------------------------------------------

TMP=$(mktemp -d "${TMPDIR:-/tmp}/vault-lint.XXXXXX") || die "cannot create a temporary directory"
trap 'rm -rf "$TMP"' EXIT
trap 'rm -rf "$TMP"; exit 2' HUP INT TERM

FILES="$TMP/files"
RECORDS="$TMP/records"
FAILURES="$TMP/failures"

: >"$RECORDS"
: >"$FAILURES"

# One directory per type, one file per note. Anything outside these seven - the
# research prose, an editor sidecar - is not a note and is never read. These are
# the plural directory names; the singular type names are the req[] keys in the
# checks pass, and vault.md closes the set at seven, so both lists are written
# out by hand and have to move together.
#
# `milestones` is read at every schemaVersion even though the type is only
# legitimate at 2, because a vault at 1 has no such directory by construction -
# so the only vault this reads it in is one that grew the directory without
# moving its version, and reading it there is what makes the checks pass say so
# (`type-agreement`) instead of skipping the notes in silence.
#
# One find per directory rather than one find over seven paths: collapsing them
# means either building an unquoted path list, which breaks the first time a
# vault lives under a directory with a space in its name, or passing all seven
# unconditionally and swallowing find's stderr, which hides a real permissions
# error. Seven spawns cost a few milliseconds and neither failure is worth it.
: >"$FILES"
for d in sources facts claims assumptions questions decisions milestones; do
	[ -d "$VAULT/$d" ] && find "$VAULT/$d" -type f -name '*.md'
done | LC_ALL=C sort >"$FILES"

# ----------------------------------------------------------------------------
# pass 1 - the vocabulary
#
# Appends to the record stream, tab separated:
#   T <term> <required>     one per term, in file order
#   A <alias> <term>        one per alias, mapped to its canonical key
#
# _vocab.yml at the vault root is the file this reads, never the vocabulary.yml
# that ships with the skill: a vault must stay checkable against the vocabulary
# it was written under even after the skill ships new terms.
#
# Only `check` consumes T and A records - graph and --unverified match N, S and
# L alone - so the pass is skipped entirely for them rather than parsed into
# output nobody reads.
# ----------------------------------------------------------------------------

if [ "$HAS_VOCAB" -eq 1 ] && [ "$MODE" = "check" ]; then
	awk '
		# ONE trailing CR off every line, the same treatment the note parser
		# gives every line it reads. Without it a CRLF _vocab.yml parses as an
		# EMPTY vocabulary: `timing-window:\r` fails the term-key pattern below
		# (which requires nothing after the colon), so no T or A record is ever
		# emitted. An empty vocabulary is not an error in this tool, it is a
		# silence - unknown-subject, near-miss-subject and coverage-gap each
		# need a term to compare against, so the vault lints clean while
		# carrying unknown subjects and a thin spine, which is the exact failure
		# this lint exists to break. A _vocab.yml written or edited on Windows
		# is CRLF by default, so a vault shared across platforms hits this as
		# the ordinary case rather than the corner.
		{ sub(/\r$/, "", $0) }

		/^[ \t]*#/ { next }
		/^[ \t]*$/ { next }

		# A term key: two spaces of indent, nothing after the colon.
		/^  [A-Za-z][A-Za-z0-9_-]*:[ \t]*$/ {
			line = $0
			sub(/^  /, "", line)
			sub(/:[ \t]*$/, "", line)
			term = line
			order[++n] = term
			required[term] = ""
			field = ""
			next
		}

		# A field of the current term. Seeing one resets `field`, which is what
		# stops a continuation line of a multi-line plain `definition` being read
		# as a key - and why the format bans ": " inside a definition.
		/^    [A-Za-z][A-Za-z0-9_-]*:/ {
			line = $0
			sub(/^    /, "", line)
			match(line, /^[A-Za-z][A-Za-z0-9_-]*:/)
			field = substr(line, 1, RLENGTH - 1)
			v = substr(line, RLENGTH + 1)
			sub(/^[ \t]+/, "", v)
			sub(/[ \t]+$/, "", v)
			if (field == "required") required[term] = v
			next
		}

		/^      -[ \t]+/ {
			if (field == "aliases") {
				a = $0
				sub(/^[ \t]*-[ \t]+/, "", a)
				sub(/[ \t]+$/, "", a)
				print "A\t" a "\t" term
			}
			next
		}

		END { for (i = 1; i <= n; i++) print "T\t" order[i] "\t" required[order[i]] }
	' "$VOCAB" >>"$RECORDS"
fi

# ----------------------------------------------------------------------------
# pass 2 - the notes
#
# Appends to the record stream, tab separated:
#   N <relpath> <dir> <basename>
#   S <relpath> <key> <value>     scalar, block-scalar body, or a joined
#                                 multi-line plain scalar. A newline inside a
#                                 value is stored as the two characters \n.
#   L <relpath> <key> <item>      one line per block-list item
#
# Parse-level failures go to their own file so they can be re-emitted with the
# note ID attached once every note has been read.
# ----------------------------------------------------------------------------

awk -v root="$VAULT" '
	BEGIN {
		FS = "\n"
		DQ = sprintf("%c", 34)
		SQ = sprintf("%c", 39)
		BS = sprintf("%c", 92)

		# The closed set: a literal block scalar is allowed on these four fields
		# and nowhere else. They are the only values that must survive exactly as
		# written - a verbatim source passage, and the founder reasoning, skill
		# reasoning and reopen trigger on a decision.
		blockok["quote"] = 1
		blockok["reasoning"] = 1
		blockok["reopen_if"] = 1
		blockok["founder_reasoning"] = 1
	}

	function indentof(s,   i, c) {
		i = 0
		while (i < length(s)) {
			c = substr(s, i + 1, 1)
			if (c != " " && c != "\t") break
			i++
		}
		return i
	}

	# Join a multi-line value onto one record line. Done by split and concat
	# rather than gsub because a backslash in a gsub replacement is rescanned,
	# and what awk does with an unrecognised escape there is unspecified.
	function flatten(s,   n, a, i, o) {
		gsub(/\t/, " ", s)
		n = split(s, a, "\n")
		o = a[1]
		for (i = 2; i <= n; i++) o = o BS "n" a[i]
		return o
	}

	# Strip one layer of matching quotes and undo the escape each style uses.
	function unq(s,   q, n) {
		n = length(s)
		if (n < 2) return s
		q = substr(s, 1, 1)
		if (q != DQ && q != SQ) return s
		if (substr(s, n, 1) != q) return s
		s = substr(s, 2, n - 2)
		# The first argument to gsub is an ERE, so a literal backslash has to be
		# written as two. Passing the two characters \" instead matches a bare
		# quote and silently leaves every escape in place - which shows up as
		# stray backslashes in a title and nowhere else.
		if (q == DQ) gsub(BS BS DQ, DQ, s)
		else gsub(SQ SQ, SQ, s)
		return s
	}

	# The coerce-nothing invariant as a test. Returns what leaving the value as
	# written costs, or "" when the value is unambiguous text.
	function ambiguous(v,   lv) {
		if (v == "") return ""
		if (substr(v, 1, 1) == DQ || substr(v, 1, 1) == SQ) return ""
		lv = tolower(v)
		if (lv == "yes" || lv == "no" || lv == "on" || lv == "off" ||
		    lv == "true" || lv == "false" || lv == "y" || lv == "n")
			return "YAML 1.1 reads it as a boolean and YAML 1.2 as the text " lv ", so the note means one thing to the editor and another to every reader"
		if (v ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/)
			return "unquoted it is a date object in most parsers and text in the rest, and the plain string comparison every staleness query relies on stops working"
		if (v ~ /^0[0-9]+$/)
			return "unquoted leading zeros are read as octal by some parsers and truncated by others"
		if (index(v, ": ") > 0)
			return "an unquoted colon-space splits the value into a nested mapping, so the field stops holding what it reads as holding"
		return ""
	}

	# Parse failures ride the same record stream as everything else, tagged E.
	# Writing them to a side file instead would mean a second awk process purely
	# to prefix the tag - and that reshaping pass re-splits on tabs, which
	# truncates any detail carrying one (unparsed-line embeds raw file content,
	# so it can). Pass 3 aggregates by key rather than by order, so an E record
	# arriving before the N record of its own note is fine.
	function perr(rel, ln, check, detail) {
		gsub(/\t/, " ", detail)
		print "E\t" rel "\t" check "\tline " ln ": " detail
	}

	# Emit whatever key is open. Printing is the only side effect, so the caller
	# resets its own state - awk passes scalars by value.
	function flushkey(rel, key, state, val, kline) {
		if (state == "scalar" || state == "block") print "S\t" rel "\t" key "\t" flatten(val)
		else if (state == "pending")
			perr(rel, kline, "null-value", "field `" key "` is present holding nothing. A present key holding nothing is not the same as an absent key, and a consumer expecting a list gets a type it did not plan for - if there is nothing to list, omit the key")
	}

	{
		path = $0
		if (path == "") next
		rel = path
		if (index(rel, root) == 1) rel = substr(rel, length(root) + 2)
		nseg = split(rel, seg, "/")
		print "N\t" rel "\t" ((nseg > 1) ? seg[nseg - 1] : "") "\t" seg[nseg]
		parsefile(path, rel)
	}

	function parsefile(path, rel,
	                   line, lineno, infm, state, key, keyline, keyindent,
	                   val, bindent, ind, blank, k, v, item, wh, r) {
		lineno = 0; infm = 0; state = ""; key = ""; keyline = 0; keyindent = 0
		val = ""; bindent = -1

		r = (getline line < path)
		if (r < 0) { perr(rel, 0, "frontmatter", "the file cannot be read"); return }
		if (r == 0) {
			perr(rel, 0, "frontmatter", "the file is empty, so it carries no note fields at all")
			close(path); return
		}
		lineno = 1
		sub(/\r$/, "", line)
		if (line != "---") {
			perr(rel, 1, "frontmatter", "the file does not open with a --- fence, so it is not a note: every field in it is invisible to every query, and the note reads as absent rather than as broken")
			close(path); return
		}
		infm = 1

		while ((getline line < path) > 0) {
			lineno++
			sub(/\r$/, "", line)
			blank = (line ~ /^[ \t]*$/)
			ind = indentof(line)

			# Inside a block scalar, everything indented further than the key
			# belongs to the value, line by line, until the first line that
			# dedents back to the key indentation or less. A reader that stops
			# at the first blank line returns a note that parsed without error
			# and has no quote in it.
			if (state == "block") {
				if (blank) { val = val "\n"; continue }
				if (ind > keyindent) {
					if (bindent < 0) bindent = ind
					val = val ((val == "") ? "" : "\n") substr(line, bindent + 1)
					continue
				}
				flushkey(rel, key, state, val, keyline)
				state = ""; val = ""; bindent = -1
				# fall through: this line closes the block and is itself a key
			}

			if (blank) continue
			if (line ~ /^[ \t]*#/) continue

			if (ind == 0 && line == "---") {
				flushkey(rel, key, state, val, keyline)
				state = ""; val = ""
				infm = 0
				break
			}

			if (ind == 0 && match(line, /^[A-Za-z_][A-Za-z0-9_-]*:/)) {
				flushkey(rel, key, state, val, keyline)
				state = ""; val = ""; bindent = -1

				k = substr(line, 1, RLENGTH - 1)
				v = substr(line, RLENGTH + 1)
				sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
				key = k; keyline = lineno; keyindent = ind

				if (v == "") {
					state = "pending"
				} else if (substr(v, 1, 1) == "|") {
					# Read the block properly whether or not this field is
					# allowed one. Bailing here would leave every indented line
					# that follows to be read as the next key.
					if (!(k in blockok))
						perr(rel, lineno, "block-scalar-field", "field `" k "` uses a literal block scalar. The block form is allowed on quote, reasoning, reopen_if and founder_reasoning and nowhere else - a reader that tolerates a fifth field has to special-case a sixth and a seventh, and the closed set is what lets it reject instead of guess")
					state = "block"; val = ""; bindent = -1
				} else if (substr(v, 1, 1) == ">") {
					perr(rel, lineno, "folded-scalar", "field `" k "` uses a folded block scalar. Folded style reflows the block onto single lines at read time, joining line breaks into spaces - on a verbatim passage that means it stops being verbatim, which is the one job the field has. Write | instead")
					state = "block"; val = ""; bindent = -1
				} else if (substr(v, 1, 1) == "[") {
					perr(rel, lineno, "inline-flow-list", "field `" k "` is an inline flow list. Obsidian rewrites inline lists into block form when it saves a note, so every edge here is lost the first time somebody opens the vault in an editor - and the blast-radius query then returns a clean result over a corpus it can no longer see, which nobody investigates")
					print "S\t" rel "\t" k "\t" flatten(v)
					state = ""
				} else if (tolower(v) == "null" || v == "~") {
					perr(rel, lineno, "null-value", "field `" k "` is set to " v ". A present key holding nothing is not the same as an absent key - omit the key instead")
					state = ""
				} else {
					wh = ambiguous(v)
					if (wh != "")
						perr(rel, lineno, "ambiguous-value", "field `" k "` has the unquoted value " v " - " wh ". Quote it")
					state = "scalar"; val = unq(v)
				}
				continue
			}

			if (ind > 0 && (state == "pending" || state == "list") && match(line, /^[ \t]*-[ \t]+/)) {
				item = substr(line, RLENGTH + 1)
				sub(/[ \t]+$/, "", item)
				state = "list"
				wh = ambiguous(item)
				if (wh != "")
					perr(rel, lineno, "ambiguous-value", "list item `" item "` under `" key "` is unquoted - " wh ". Quote it")
				print "L\t" rel "\t" key "\t" flatten(unq(item))
				continue
			}

			# An indented line after a scalar is a multi-line plain scalar
			# continuation. Tolerated rather than rejected: that is the shape the
			# vocabulary file uses, and a reader that chokes on it is one people
			# stop running.
			if (ind > 0 && state == "scalar") {
				item = line
				sub(/^[ \t]+/, "", item); sub(/[ \t]+$/, "", item)
				val = val " " item
				continue
			}

			perr(rel, lineno, "unparsed-line", "this line is neither a key, a block-list item, a comment, nor the closing fence, so whatever it was meant to record is not in the ledger: " line)
		}
		close(path)

		if (infm)
			perr(rel, lineno, "frontmatter", "the frontmatter block is never closed by a --- fence, so where the ledger ends and the prose begins is undefined and every reader draws the line somewhere different")
	}
' "$FILES" >>"$RECORDS"

# ----------------------------------------------------------------------------
# graph - the neighbourhood of one note, as text
# ----------------------------------------------------------------------------

if [ "$MODE" = "graph" ]; then
	awk -v target="$TARGET" -v maxdepth="$DEPTH" -v vault="$VAULT" -v edgefields="$EDGE_FIELDS" -F '\t' '
		BEGIN {
			BS = sprintf("%c", 92)
			nedge = split(edgefields, edgef, " ")
		}

		$1 == "N" { files[++nf] = $2; next }
		$1 == "S" { V[$2, $3] = $4; next }
		$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

		# Duplicated in the checks pass. Each awk program is a separate process
		# with its own program text, so sharing would mean assembling the source
		# in a shell variable and losing the top-to-bottom readability each awk
		# program has today. Change one, change the other.
		function isid(s) { return (s ~ /^(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)-[A-Za-z0-9]+$/) }
		function pad(n,   i, s) { s = ""; for (i = 0; i < n; i++) s = s " "; return s }

		# A value stores newlines as the two characters \n, so the first line of
		# a block scalar is everything before the first one. Printing it is what
		# shows the block was read as a block rather than as the literal |.
		function firstline(s,   p) {
			p = index(s, BS "n")
			return (p > 0) ? substr(s, 1, p - 1) : s
		}

		function target_of(item) {
			return (index(item, " :: ") > 0) ? substr(item, index(item, " :: ") + 4) : item
		}

		function label(id,   f, s) {
			f = BYID[id]
			if (f == "") return id "  (no note in this vault carries this ID)"
			s = id "  " V[f, "type"] "  confidence " V[f, "confidence"] "  status " V[f, "status"]
			if (V[f, "subject"] != "") s = s "  subject " V[f, "subject"]
			return s
		}

		function detail(id, p,   f, out) {
			f = BYID[id]
			if (f == "") return ""
			out = p V[f, "title"] "\n"
			if (V[f, "quote"] != "") out = out p "quote: " firstline(V[f, "quote"]) "\n"
			if (V[f, "reasoning"] != "") out = out p "reasoning: " firstline(V[f, "reasoning"]) "\n"
			if (V[f, "founder_reasoning"] != "") out = out p "founder_reasoning: " firstline(V[f, "founder_reasoning"]) "\n"
			if (V[f, "reopen_if"] != "") out = out p "reopen_if: " firstline(V[f, "reopen_if"]) "\n"
			return out
		}

		function walkout(id, d, ind,   f, e, i, k, n, item, tgt) {
			if (d > maxdepth) return
			f = BYID[id]
			if (f == "") return
			for (e = 1; e <= nedge; e++) {
				k = f SUBSEP edgef[e]
				n = LN[k]
				if (n == 0) continue
				printf "%s%s ->\n", pad(ind), edgef[e]
				for (i = 1; i <= n; i++) {
					item = LI[k, i]
					tgt = target_of(item)
					if (!isid(tgt)) { printf "%s%s\n", pad(ind + 2), item; continue }
					printf "%s%s\n", pad(ind + 2), label(tgt)
					printf "%s", detail(tgt, pad(ind + 4))
					if (!(tgt in seenout)) { seenout[tgt] = 1; walkout(tgt, d + 1, ind + 4) }
				}
			}
		}

		# Edges are stored once, on the asserting note, and never mirrored - so
		# the inbound direction has to be derived. Deriving it once into REV
		# rather than rescanning every note per visited node keeps a traversal
		# proportional to the neighbourhood being printed instead of to the size
		# of the corpus, which is the difference between depth 3 on a few hundred
		# notes being instant and being something people stop asking for.
		function buildrev(   i, f, e, k, n, j, src, tgt) {
			for (i = 1; i <= nf; i++) {
				f = files[i]
				src = V[f, "id"]
				if (src == "") continue
				for (e = 1; e <= nedge; e++) {
					k = f SUBSEP edgef[e]
					n = LN[k]
					for (j = 1; j <= n; j++) {
						tgt = target_of(LI[k, j])
						if (tgt == "" || tgt == src) continue
						REV[tgt, ++RN[tgt]] = src SUBSEP edgef[e]
					}
				}
			}
		}

		function walkin(id, d, ind,   r, parts, src, via) {
			if (d > maxdepth) return
			if (d == 1 && RN[id] == 0) {
				printf "%s(nothing in this vault rests on it)\n", pad(ind)
				return
			}
			for (r = 1; r <= RN[id]; r++) {
				split(REV[id, r], parts, SUBSEP)
				src = parts[1]; via = parts[2]
				printf "%s%s   (via %s)\n", pad(ind), label(src), via
				printf "%s", detail(src, pad(ind + 2))
				if (!(src in seenin)) { seenin[src] = 1; walkin(src, d + 1, ind + 2) }
			}
		}

		END {
			for (i = 1; i <= nf; i++) if (V[files[i], "id"] != "") BYID[V[files[i], "id"]] = files[i]
			buildrev()
			if (!(target in BYID)) {
				printf "vault-lint: no note with ID %s under %s\n", target, vault > "/dev/stderr"
				exit 2
			}
			printf "vault-lint graph: %s  (depth %d)\n", target, maxdepth
			printf "  vault: %s\n", vault
			printf "  file:  %s\n\n", BYID[target]
			printf "%s\n", label(target)
			printf "%s\n", detail(target, "  ")
			printf "  rests on\n"
			seenout[target] = 1
			walkout(target, 1, 4)
			printf "\n  rested on by\n"
			seenin[target] = 1
			walkin(target, 1, 4)
		}
	' "$RECORDS"
	exit $?
fi

# ----------------------------------------------------------------------------
# --unverified - the target list, not a verdict
#
# Two populations, and they are different questions. `status: unverified` is what
# the author declared: asserted, nothing behind it yet. Low confidence is what
# the corpus derived: something is behind it, and the weakest link in the chain
# is thin. A red team wants both, and wants to know which notes reached a
# rendered document - `used_in` is the field that answers that, so it is printed
# rather than left for a second query.
#
# This exits 0 whether or not it finds anything. Finding an unverified note is
# the point of asking, not a violation: an assumption is SUPPOSED to be
# unverified until its validation step runs, and a mode that exited non-zero on
# a healthy vault would train its caller to ignore the exit code that the actual
# checks depend on.
# ----------------------------------------------------------------------------

if [ "$MODE" = "unverified" ]; then
	awk -v vault="$VAULT" -v asjson="$JSON" -F '\t' '
		BEGIN {
			DQ = sprintf("%c", 34)
			BS = sprintf("%c", 92)
		}

		$1 == "N" { files[++nf] = $2; next }
		$1 == "S" { V[$2, $3] = $4; next }
		$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

		# One of three identical copies - see the note beside the
		# --supersession-sweep one for why they stay copies and what would
		# change that. Change one, change all three.
		function jesc(s,   i, c, o) {
			o = ""
			for (i = 1; i <= length(s); i++) {
				c = substr(s, i, 1)
				if (c == DQ) o = o BS DQ
				else if (c == BS) o = o BS BS
				else if (c == "\t") o = o " "
				else o = o c
			}
			return o
		}

		function jlist(f, key,   k, i, o) {
			k = f SUBSEP key
			o = "["
			for (i = 1; i <= LN[k]; i++) o = o (i == 1 ? "" : ", ") DQ jesc(LI[k, i]) DQ
			return o "]"
		}

		function plain(f, key, indent,   k, i) {
			k = f SUBSEP key
			for (i = 1; i <= LN[k]; i++) printf "%s%s: %s\n", indent, key, LI[k, i]
		}

		function text(f, id) {
			printf "    %s  %s  confidence %s  status %s\n", id, V[f, "type"], V[f, "confidence"], V[f, "status"]
			printf "      %s\n", V[f, "title"]
			if (V[f, "sensitivity"] != "") printf "      sensitivity: %s\n", V[f, "sensitivity"]
			plain(f, "validated_by", "      ")
			plain(f, "used_in", "      ")
		}

		END {
			for (i = 1; i <= nf; i++) {
				f = files[i]
				id = V[f, "id"]
				if (id == "") continue
				if (V[f, "status"] == "unverified") { un[++nun] = f; reason[f] = "status-unverified" }
				else if (V[f, "confidence"] == "L") { lo[++nlo] = f; reason[f] = "low-confidence" }
			}
			total = nun + nlo

			if (asjson == "1") {
				printf "{\n  " DQ "vault" DQ ": " DQ "%s" DQ ",\n", jesc(vault)
				printf "  " DQ "unverified_count" DQ ": %d,\n", total
				printf "  " DQ "notes" DQ ": ["
				n = 0
				for (pass = 1; pass <= 2; pass++) {
					cnt = (pass == 1) ? nun : nlo
					for (i = 1; i <= cnt; i++) {
						f = (pass == 1) ? un[i] : lo[i]
						printf "%s\n    {", (++n == 1 ? "" : ",")
						printf DQ "id" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "id"])
						printf DQ "file" DQ ": " DQ "%s" DQ ", ", jesc(f)
						printf DQ "type" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "type"])
						printf DQ "status" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "status"])
						printf DQ "confidence" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "confidence"])
						printf DQ "reason" DQ ": " DQ "%s" DQ ", ", jesc(reason[f])
						printf DQ "title" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "title"])
						printf DQ "used_in" DQ ": %s}", jlist(f, "used_in")
					}
				}
				printf "%s]\n}\n", (n == 0 ? "" : "\n  ")
				exit 0
			}

			printf "vault-lint unverified: %d note%s asserted with nothing behind them\n", total, (total == 1 ? "" : "s")
			printf "  vault: %s\n", vault
			printf "\n  asserted, nothing behind it yet (status: unverified)\n"
			if (nun == 0) printf "    (none)\n"
			for (i = 1; i <= nun; i++) text(un[i], V[un[i], "id"])
			printf "\n  carried at Low confidence - the weakest link in the chain below it is thin\n"
			if (nlo == 0) printf "    (none)\n"
			for (i = 1; i <= nlo; i++) text(lo[i], V[lo[i], "id"])
		}
	' "$RECORDS"
	exit 0
fi

# ----------------------------------------------------------------------------
# --supersession-sweep - the re-read worklist a supersession owes
#
# When B supersedes A, every document section named in A's `used_in` is now
# suspect and nothing in the corpus says so: supersession is visible IN THE NOTE
# and invisible everywhere the note was cited. This walks the supersedes edges
# already in the record stream and emits the union of those targets.
#
# THE WORKLIST IS A REPORT AND THE VERDICT IS A SEPARATE QUESTION. Finding rows
# is not a failure: a supersession with a blast radius is the corpus working
# correctly, and a mode that exited non-zero on a healthy vault would train its
# caller to ignore the exit code the actual checks depend on. So a fully
# reconciled vault still prints its worklist, still prints its count, and still
# exits 0. What fails is a supersession nothing says was read - see the
# `reconciled:` block in END below.
#
# GROUPED BY TARGET AND DEDUPED. The unit of work is re-read this section, so
# two superseded notes citing one section are ONE row naming both. Repeating the
# section per note makes a two-item job look like six, and a worklist that
# overstates its own size is one that gets skipped at the moment it matters.
#
# THE SUPERSEDED SET IS BOTH HALVES OF THE TWO-EDIT RULE: every note named by a
# `supersedes` edge, and every note carrying `status: superseded`. Taking either
# half alone would make the worklist depend on the supersession being
# well-formed - and a half-made supersession is exactly the vault where the
# worklist matters most, because `check` has already found something wrong with
# the pair and the documents downstream still say the old thing.
#
# THE COUNT IS PART OF THE PRODUCT. The gate that consumes this is a read, and a
# read is bounded only if its size is visible before it starts - a worklist
# whose length is unknown until it is finished is one that gets skimmed. The row
# count is also the standing instrument for whether a read-shaped gate is still
# the right design at all: when it is routinely past what one pass covers, the
# bounded read has stopped being bounded.
#
# A superseded note with no `used_in` is listed rather than dropped. It reached
# no document, which is the good case - and a sweep that omitted it silently
# would be indistinguishable from one that failed to read it.
#
# LC_ALL=C is pinned for the reason --used-in found the hard way. Every value
# here is note text and `supersedes_reason` is free prose - the field in the
# vault likeliest to carry an em dash or a curly quote - and it goes through a
# byte-at-a-time escaper. macOS awk in a UTF-8 locale aborts the record with
# `illegal byte sequence` the moment it meets a sequence it cannot decode, which
# would end the sweep early and print a short worklist as though it were whole.
# ----------------------------------------------------------------------------

if [ "$MODE" = "supersession-sweep" ]; then
	LC_ALL=C awk -v vault="$VAULT" -v asjson="$JSON" -v schema="$FOUND_SCHEMA" -F '\t' '
		BEGIN {
			DQ = sprintf("%c", 34)
			BS = sprintf("%c", 92)
		}

		$1 == "N" { files[++nf] = $2; next }
		$1 == "S" { V[$2, $3] = $4; next }
		$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

		# The third copy of the escaper --unverified and render_failures carry,
		# one character at a time: a gsub replacement holding a backslash is
		# rescanned by awk and what it does with an unrecognised escape there is
		# unspecified. Copied rather than hoisted because the trigger the other
		# two name has not fired - all three are still the same four cases, and
		# hoisting would mean assembling awk source in a shell variable, which
		# costs every one of these programs the top-to-bottom readability it has
		# today. The moment ANY of the three needs a case the others do not, that
		# is the point to pay that cost. Change one, change all three.
		function jesc(s,   i, c, o) {
			o = ""
			for (i = 1; i <= length(s); i++) {
				c = substr(s, i, 1)
				if (c == DQ) o = o BS DQ
				else if (c == BS) o = o BS BS
				else if (c == "\t") o = o " "
				else o = o c
			}
			return o
		}

		# Both renderers take (note, supersession index) and unpack SB
		# themselves. Unpacking at the four call sites instead would be the same
		# split line copied four times, and a fifth call site added later would
		# be one paste away from reading the pair back in the wrong order.
		function jnote(f, b,   sb) {
			split(SB[f, b], sb, SUBSEP)
			printf "{" DQ "id" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "id"])
			printf DQ "file" DQ ": " DQ "%s" DQ ", ", jesc(f)
			printf DQ "type" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "type"])
			printf DQ "title" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "title"])
			printf DQ "superseded_by" DQ ": " DQ "%s" DQ ", ", jesc(sb[1])
			printf DQ "supersedes_reason" DQ ": " DQ "%s" DQ "}", jesc(sb[2])
		}

		# ------------------------------------------------------------------
		# Two spellings of one section have to collapse to one row
		#
		# A heading is addressable two ways: by an explicit {#anchor}
		# attribute, and by the slug of its text - both registered, so a vault
		# citing the slug keeps working when the template gains explicit
		# anchors. That makes `business-plan.md#business-model` and
		# `business-plan.md#business-model--pricing` the SAME physical section
		# under one `## Business model & pricing {#business-model}` heading, and
		# grouping on the raw anchor emits two worklist rows for one job. A
		# worklist that overstates its own size is one that gets skipped at the
		# moment it matters, which is the whole reason this mode dedupes.
		#
		# WHY THIS IS NOT A SECOND COPY OF THE SLUG RULE IN --used-in. That rule
		# decides whether an anchor RESOLVES and has to be exact, character for
		# character, because a wrong answer reports a working link as dead.
		# This decides whether two anchors are the SAME SECTION, and it is
		# deliberately loose: fold both to their alphanumeric bytes and compare.
		# Every character the slug rule drops is dropped here too, so any two
		# spellings that rule resolves to one heading fold together - without
		# this program having to know which characters those are, which is what
		# keeps it from drifting out of step with a rule it does not own.
		#
		# IT CANNOT UNDER-COUNT, which is the direction that would matter. A
		# fold key claimed by two different headings is retired rather than
		# resolved, so an ambiguous match falls back to the raw anchor and the
		# reader gets the two rows they get today. Being wrong here costs a
		# section nobody re-reads, so ambiguity refuses rather than guesses.
		function fold(s,   i, c, o) {
			o = ""
			for (i = 1; i <= length(s); i++) {
				c = substr(s, i, 1)
				if (c >= "a" && c <= "z") { o = o c; continue }
				if (c >= "A" && c <= "Z") { o = o tolower(c); continue }
				if (c >= "0" && c <= "9") { o = o c; continue }
			}
			return o
		}

		# Register one fold key against one heading, or RETIRE it when a second
		# heading claims the same key. --binding-driver carries the second copy,
		# as claimkey(), so a grep for `claim(` does not find it: change one,
		# change both. Retiring is the whole safety property:
		# two headings that differ only in the punctuation the fold drops are
		# indistinguishable here, so the key resolves to nothing and both
		# citations keep the rows they get today. Zero is the retired marker
		# rather than a second array because heading ordinals start at 1, so a
		# third heading claiming a retired key leaves it retired.
		function claim(doc, k, id,   ak) {
			if (k == "") return
			ak = doc SUBSEP k
			if (ak in ALIAS) {
				if (ALIAS[ak] != id) ALIAS[ak] = 0
				return
			}
			ALIAS[ak] = id
		}

		# Every heading a document offers, as fold keys pointing at the
		# heading ordinal. Read once per document, on first sight.
		#
		# The fence tracking is one of five copies in this file - --used-in
		# scans headings under the same rule, and so do --red-team,
		# --roadmap-table and --binding-driver. All five are the same six
		# lines: a `#` inside a fenced block is an example rather than a section
		# anyone can jump to, and the marker and run length are tracked so a
		# longer nested fence cannot close its parent early. Change one, change
		# all five.
		#
		# The fold() below has two more copies, in --roadmap-table and
		# --binding-driver, which resolve their own section headings by the same
		# rule and for the same reason.
		function sections(doc,   path, line, t, c, n, fc, fn, h, ex, id) {
			path = vault "/" doc
			fc = ""; fn = 0; id = 0
			while ((getline line < path) > 0) {
				sub(/\r$/, "", line)
				t = line
				sub(/^[ \t]+/, "", t)
				if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
					c = substr(t, 1, 1)
					n = 0
					while (substr(t, n + 1, 1) == c) n++
					if (fc == "") { fc = c; fn = n }
					else if (c == fc && n >= fn) { fc = ""; fn = 0 }
					continue
				}
				if (fc != "") continue
				if (!match(t, /^#+[ \t]+/)) continue
				h = substr(t, RLENGTH + 1)
				sub(/[ \t]*#+[ \t]*$/, "", h)
				sub(/[ \t]+$/, "", h)
				id++

				# An explicit {#anchor} attribute is stripped from the heading
				# text and registered beside it, which is exactly what
				# --used-in scan does and what a renderer owes it. Registering
				# the anchor INSTEAD of the slug would break every existing
				# citation the day a template gained anchors, which is why both
				# are addresses - and why one section can be reached two ways
				# at all.
				#
				# The braces are written as bracket expressions rather than
				# escaped, for the reason scan states: a backslash-brace is an
				# interval expression to some awks and a literal to others, and
				# which one runs this is a property of the user machine. The
				# two matches have to stay the same shape, so this one is
				# copied from there rather than written again.
				if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
					ex = substr(h, RSTART, RLENGTH)
					sub(/^[{]#/, "", ex)
					sub(/[}]$/, "", ex)
					claim(doc, fold(ex), id)
					h = substr(h, 1, RSTART - 1)
					sub(/[ \t]+$/, "", h)
				}
				claim(doc, fold(h), id)
			}
			close(path)
		}

		# The grouping key for one target: the heading it names when the
		# document says which, and the anchor as written when it does not.
		# Both forms are namespaced so a raw anchor can never collide with a
		# heading ordinal. An anchor that resolves to nothing keeps the raw
		# form deliberately - whether a citation resolves is --used-in verdict,
		# and a sweep that dropped an unresolvable target would hide the
		# section a reader most needs to look at.
		function resolve(doc, anc,   k) {
			if (anc == "") return "a"
			if (!(doc in SCANNED)) { SCANNED[doc] = 1; sections(doc) }
			k = doc SUBSEP fold(anc)
			if ((k in ALIAS) && ALIAS[k] > 0) return "h" ALIAS[k]
			return "a" anc
		}

		# One superseded note, as the reader of the worklist needs it: what it
		# said, what replaced it, and why. The reason is what stops the row
		# sending its reader back to the ledger before they can even decide
		# whether this section is worth opening.
		function tnote(f, b, pad,   sb) {
			split(SB[f, b], sb, SUBSEP)
			printf "%s%s  %s\n", pad, V[f, "id"], V[f, "type"]
			printf "%s  %s\n", pad, V[f, "title"]
			if (sb[1] == "")
				printf "%s  superseded by: nothing - `status: superseded` with no note naming it in `supersedes`, so the record says this was replaced and not by what\n", pad
			else {
				printf "%s  superseded by %s\n", pad, sb[1]
				printf "%s  reason: %s\n", pad, (sb[2] == "" ? "(none recorded - `supersedes_reason` is absent, so why it was replaced is already gone)" : sb[2])
			}
		}

		END {
			for (i = 1; i <= nf; i++) if (V[files[i], "id"] != "") BYID[V[files[i], "id"]] = files[i]

			# THE VERDICT. `reconciled:` asserts one thing - that the sections
			# this supersession put in doubt have been read - and it is what
			# turns the worklist below from a report into something somebody is
			# obliged to finish. It sits on the note carrying `supersedes`,
			# the side where the edge and the reason already live, so all three
			# halves of a supersession are on one note and a reader checking
			# whether it was closed out opens one file.
			#
			# REQUIRED WHETHER OR NOT THE SUPERSEDED NOTE REACHED A DOCUMENT.
			# Conditioning it on used_in would look tighter and would leave an
			# obligation that comes into existence the day somebody cites the
			# superseded note, with nothing to re-fire it - the vault would
			# acquire an unread supersession by an edit to a different note.
			#
			# A dangling supersedes target is still checked here, unlike in the
			# worklist below which skips it: the worklist would be naming a
			# re-read nobody can perform, while the missing date is a real
			# omission on a note that exists.
			#
			# GATED ON schemaVersion 2. A corpus written before the field
			# existed cannot owe it, and a check that failed every vault
			# authored to date on the day the skill updated is how a gate stops
			# being run. vault-migration.md carries the 1 -> 2 back-fill.
			if (schema + 0 >= 2) {
				for (i = 1; i <= nf; i++) {
					f = files[i]
					k = f SUBSEP "supersedes"
					if (LN[k] == 0) continue
					tg = ""
					for (j = 1; j <= LN[k]; j++) tg = tg (j == 1 ? "" : ", ") LI[k, j]
					rec = V[f, "reconciled"]
					cre = V[f, "created"]
					why = ""
					if (rec == "")
						why = "no `reconciled:` date. Nothing records that the sections this supersession put in doubt were read, so the worklist this mode prints is one nobody is obliged to finish - and the documents go on asserting what the ledger already replaced while every check stays green"
					# Both values are quoted ISO dates the parser stored as
					# written, and both sides are forced to strings so the
					# comparison cannot fall into awk numeric rules on a value
					# that happens to look like a number. This is the payoff
					# the coerce-nothing invariant is claimed for: a plain
					# string comparison, no date library, no parsing.
					#
					# A missing `created` is skipped rather than treated as
					# earlier than everything - it is already a required-field
					# failure from `check`, and reporting it twice under a name
					# about reconciliation sends its reader to the wrong fix.
					else if (cre != "" && (rec "") < (cre ""))
						why = "`reconciled: " rec "` predates the `created: " cre "` on this same note, so the sections were read before the supersession that put them in doubt existed. A date carried over from an earlier pass reads exactly like one stamped after the read, and which of the two it is happens to be the only half of this a check can see"

					if (why == "") continue
					UNREC[++nu] = f
					UTGT[f] = tg
					UWHY[f] = why
				}
			}

			# Half one: every note a supersedes edge names. Walked from the
			# superseding side because that is where the edge and the reason both
			# live - the superseded note records neither. A dangling supersedes
			# target is skipped rather than reported: a dangling supersedes edge
			# is already a dangling-edge failure from `check`, and inventing a
			# worklist row for a note that is not in the vault would name a
			# re-read nobody can perform.
			for (i = 1; i <= nf; i++) {
				f = files[i]
				k = f SUBSEP "supersedes"
				for (j = 1; j <= LN[k]; j++) {
					tgt = LI[k, j]
					if (!(tgt in BYID)) continue
					tf = BYID[tgt]
					SB[tf, ++SN[tf]] = V[f, "id"] SUBSEP V[f, "supersedes_reason"]
				}
			}

			# Half two, and the ordering pass for both. Iterating files[] rather
			# than the edge walk above is what makes the output order the vault
			# order instead of awk hash order, so two runs over an unchanged
			# vault produce the same worklist.
			for (i = 1; i <= nf; i++) {
				f = files[i]
				if (V[f, "id"] == "") continue
				if (SN[f] == 0 && V[f, "status"] != "superseded") continue
				SUP[++nsup] = f
				if (SN[f] == 0) SB[f, ++SN[f]] = "" SUBSEP ""
			}

			for (s = 1; s <= nsup; s++) {
				f = SUP[s]
				k = f SUBSEP "used_in"
				if (LN[k] == 0) { NOUSE[++nnou] = f; continue }
				for (j = 1; j <= LN[k]; j++) {
					entry = LI[k, j]
					# Split and normalised exactly the way --used-in splits it, so
					# both modes group on the same target. Without the strip, one
					# note writing ./business-plan.md#why-now and another writing
					# business-plan.md#why-now would be two rows for one section -
					# which is the double-counting this mode exists to avoid.
					# The five lines below are byte-identical to the copies in
					# --used-in and --binding-driver on purpose, so a diff of the
					# three proves they agree: change one, change all three. What
					# follows them is a step of its own - collapsing two
					# spellings of one heading onto one key, per the block
					# above tnote.
					p = index(entry, "#")
					doc = (p > 0) ? substr(entry, 1, p - 1) : entry
					anc = (p > 0) ? substr(entry, p + 1) : ""
					sub(/^[ \t]+/, "", doc); sub(/[ \t]+$/, "", doc)
					sub(/^\.\//, "", doc)
					sub(/\/+$/, "", doc)

					key = doc SUBSEP resolve(doc, anc)
					if (!(key in SEENT)) {
						SEENT[key] = 1
						TORDER[++nt] = key
						TDOC[key] = doc
						TANC[key] = anc
						TSHOW[key] = doc (anc == "" ? "" : "#" anc)
					}
					# A note that names one section twice is still one re-read of
					# that section by that note.
					if ((key SUBSEP f) in SEENR) continue
					SEENR[key SUBSEP f] = 1
					ROW[key, ++RN[key]] = f
				}
			}

			if (asjson == "1") {
				printf "{\n"
				# `ok` is the verdict as a field rather than only as an exit
				# status, so a consumer parsing the document does not have to
				# have captured the status to know which answer it is holding.
				printf "  " DQ "ok" DQ ": %s,\n", (nu == 0 ? "true" : "false")
				printf "  " DQ "vault" DQ ": " DQ "%s" DQ ",\n", jesc(vault)
				printf "  " DQ "worklist_count" DQ ": %d,\n", nt
				printf "  " DQ "superseded_count" DQ ": %d,\n", nsup
				printf "  " DQ "unreconciled_count" DQ ": %d,\n", nu
				printf "  " DQ "unreconciled" DQ ": ["
				for (i = 1; i <= nu; i++) {
					f = UNREC[i]
					printf "%s\n    {", (i == 1 ? "" : ",")
					printf DQ "id" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "id"])
					printf DQ "file" DQ ": " DQ "%s" DQ ", ", jesc(f)
					printf DQ "type" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "type"])
					printf DQ "title" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "title"])
					printf DQ "supersedes" DQ ": " DQ "%s" DQ ", ", jesc(UTGT[f])
					printf DQ "created" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "created"])
					printf DQ "reconciled" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "reconciled"])
					printf DQ "detail" DQ ": " DQ "%s" DQ "}", jesc(UWHY[f])
				}
				printf "%s],\n", (nu == 0 ? "" : "\n  ")
				printf "  " DQ "worklist" DQ ": ["
				for (t = 1; t <= nt; t++) {
					key = TORDER[t]
					printf "%s\n    {", (t == 1 ? "" : ",")
					printf DQ "target" DQ ": " DQ "%s" DQ ", ", jesc(TSHOW[key])
					printf DQ "document" DQ ": " DQ "%s" DQ ", ", jesc(TDOC[key])
					printf DQ "section" DQ ": " DQ "%s" DQ ", ", jesc(TANC[key])
					printf DQ "notes" DQ ": ["
					m = 0
					for (r = 1; r <= RN[key]; r++) {
						f = ROW[key, r]
						for (b = 1; b <= SN[f]; b++) {
							printf "%s\n      ", (++m == 1 ? "" : ",")
							jnote(f, b)
						}
					}
					printf "%s]}", (m == 0 ? "" : "\n    ")
				}
				printf "%s],\n", (nt == 0 ? "" : "\n  ")
				printf "  " DQ "reached_no_document" DQ ": ["
				m = 0
				for (i = 1; i <= nnou; i++) {
					f = NOUSE[i]
					for (b = 1; b <= SN[f]; b++) {
						printf "%s\n    ", (++m == 1 ? "" : ",")
						jnote(f, b)
					}
				}
				printf "%s]\n}\n", (m == 0 ? "" : "\n  ")
				exit (nu == 0 ? 0 : 1)
			}

			printf "vault-lint supersession-sweep: %d section%s to re-read, from %d superseded note%s\n",
				nt, (nt == 1 ? "" : "s"), nsup, (nsup == 1 ? "" : "s")
			printf "  vault: %s\n", vault
			printf "\n  sections a supersession put in doubt - the note behind each was replaced and the prose was not\n"
			if (nt == 0) printf "    (none)\n"
			for (t = 1; t <= nt; t++) {
				key = TORDER[t]
				printf "    %s\n", TSHOW[key]
				for (r = 1; r <= RN[key]; r++) {
					f = ROW[key, r]
					for (b = 1; b <= SN[f]; b++) tnote(f, b, "      ")
				}
			}
			printf "\n  superseded notes that reached no document - nothing to re-read, which is the good case\n"
			if (nnou == 0) printf "    (none)\n"
			for (i = 1; i <= nnou; i++) {
				f = NOUSE[i]
				for (b = 1; b <= SN[f]; b++) tnote(f, b, "    ")
			}

			# The verdict prints last, because it is the half a reader acts on
			# and the worklist above it can run to dozens of rows. At
			# schemaVersion 1 the section says the rule does not apply rather
			# than printing an empty list: an unconditional `(none)` here would
			# report a vault as reconciled when nothing about it was asked.
			if (schema + 0 < 2) {
				printf "\n  reconciliation is a schemaVersion 2 rule and this vault is at %s - the worklist above is a report here, and nothing was asked about whether it was read\n", schema
				exit 0
			}
			printf "\n  supersessions with nothing recording that the worklist was read\n"
			if (nu == 0) printf "    (none)\n"
			for (i = 1; i <= nu; i++) {
				f = UNREC[i]
				printf "    %s  %s\n", V[f, "id"], V[f, "type"]
				printf "      %s\n", V[f, "title"]
				printf "      supersedes %s\n", UTGT[f]
				printf "      %s\n", UWHY[f]
			}
			if (nu > 0)
				printf "\nvault-lint supersession-sweep: %d supersession%s with nothing recording that its sections were read, under %s\n",
					nu, (nu == 1 ? "" : "s"), vault
			exit (nu == 0 ? 0 : 1)
		}
	' "$RECORDS"
	exit $?
fi

# ----------------------------------------------------------------------------
# what every verdict mode shares
#
# Every mode that emits failure rows and carries a verdict out in its exit status
# builds on what follows, so the date, the path index and the renderer are built
# once here rather than once per mode. That is `check`, --used-in, --red-team,
# --roadmap-table and --binding-driver today, and a mode joins the list by being
# dispatched below this point rather than by registering anywhere - which is why
# this comment names them and the code does not. graph, --unverified and
# --supersession-sweep have already exited above: none of the three produces a
# failure row, and the path index costs a find over the whole vault.
# ----------------------------------------------------------------------------

TODAY=$(date +%Y-%m-%d)

# Every path that exists inside the vault, relative to its root. Read once into
# an array rather than shelling out per note: a source with no public URL carries
# a vault-relative path, a used_in entry names a document at the vault root, and
# the only way to know either resolves is to look. Answering from this index
# rather than from the filesystem also keeps every lookup inside the vault - a
# used_in entry of ../elsewhere.md is reported missing rather than opened.
PATHIDX="$TMP/paths"
(cd "$VAULT" && find . -mindepth 1 2>/dev/null | sed 's|^\./||') >"$PATHIDX" 2>/dev/null || : >"$PATHIDX"

# One awk, branching on asjson internally - the same shape --unverified uses, so
# a further report mode has one pattern to copy rather than two. It also carries
# the exit status out itself, which is what removes the separate counting pass:
# awk already knows how many rows it buffered. `prog` is the name the mode
# answers to, so a --used-in failure is not mistaken for a `check` failure by
# whoever reads the terminal.
#
# Human output goes to stderr and JSON to stdout on purpose: a caller piping
# --json into a parser gets only the document, and a human running it bare still
# sees everything.
#
# The second argument is the line printed when nothing failed, and it is an
# argument rather than a constant because "clean" means something different in
# each mode. `check` looks at note fields and never opens a document, so a
# corpus with dozens of dead anchors used to print the same `clean` as a whole
# corpus in order - and a success line read as a whole-corpus verdict is the
# thing somebody renders on. --used-in's clean genuinely is what it says: every
# target it was asked to open resolved. It keeps the default.
render_failures() {
	LC_ALL=C sort -o "$FAILURES" "$FAILURES"

	awk -v vault="$VAULT" -v today="$TODAY" -v asjson="$JSON" -v prog="$1" -v okline="${2:-clean - $VAULT}" -F '\t' '
		BEGIN {
			DQ = sprintf("%c", 34)
			BS = sprintf("%c", 92)
		}
		# Escaped one character at a time: a gsub replacement containing a backslash
		# is rescanned by awk, and what it does with an unrecognised escape there is
		# unspecified - which would produce invalid JSON on exactly the notes whose
		# text most needs reading.
		# The same escaper as the --unverified and --supersession-sweep
		# renderers. All three are short, stable, and identical; the moment any
		# one of them grows a case the others do not, that is the point to hoist
		# it. Change one, change all three.
		function jesc(s,   i, c, o) {
			o = ""
			for (i = 1; i <= length(s); i++) {
				c = substr(s, i, 1)
				if (c == DQ) o = o BS DQ
				else if (c == BS) o = o BS BS
				else if (c == "\t") o = o " "
				else o = o c
			}
			return o
		}
		{ row[++n] = $0 }
		END {
			if (asjson == "1") {
				printf "{\n"
				printf "  " DQ "ok" DQ ": %s,\n", (n == 0 ? "true" : "false")
				printf "  " DQ "vault" DQ ": " DQ "%s" DQ ",\n", jesc(vault)
				printf "  " DQ "checked_on" DQ ": " DQ "%s" DQ ",\n", jesc(today)
				printf "  " DQ "failure_count" DQ ": %d,\n", n
				printf "  " DQ "failures" DQ ": ["
				for (i = 1; i <= n; i++) {
					split(row[i], p, "\t")
					printf "%s\n    {", (i == 1 ? "" : ",")
					printf DQ "file" DQ ": " DQ "%s" DQ ", ", jesc(p[1])
					printf DQ "check" DQ ": " DQ "%s" DQ ", ", jesc(p[2])
					printf DQ "id" DQ ": " DQ "%s" DQ ", ", jesc(p[3])
					printf DQ "detail" DQ ": " DQ "%s" DQ "}", jesc(p[4])
				}
				printf "%s]\n}\n", (n == 0 ? "" : "\n  ")
			} else if (n == 0) {
				printf "%s: %s\n", prog, okline
			} else {
				printf "%s: %d failure%s under %s\n", prog, n, (n == 1 ? "" : "s"), vault > "/dev/stderr"
				for (i = 1; i <= n; i++) {
					split(row[i], p, "\t")
					if (p[1] != last) { printf "\n%s\n", p[1] > "/dev/stderr"; last = p[1] }
					printf "  [%s] %s\n", p[2], p[4] > "/dev/stderr"
				}
				printf "\n" > "/dev/stderr"
			}
			exit (n == 0 ? 0 : 1)
		}
	' "$FAILURES"
}

# ----------------------------------------------------------------------------
# --used-in - every used_in target resolves
#
# Two checks, named apart because they want different fixes. `used-in-missing-file`
# means the document is absent: either the claim was cited into a file that was
# later renamed, or used_in was back-filled onto a note nothing cites.
# `used-in-dead-anchor` means the document is there and the section is not: a
# heading was renamed or cut while the note went on naming it.
#
# THE BOUNDARY IS THE POINT. This asserts the target RESOLVES and never that the
# section CARRIES the claim - see the header comment for why an ID-matching scan
# would report a false positive on every correctly cited claim.
#
# Pass 2 already emits used_in as L records like every other block list, so the
# record stream has everything except the target documents' headings, which is
# the one new read.
# ----------------------------------------------------------------------------

# LC_ALL=C is load-bearing rather than tidy. A heading and an anchor both carry
# UTF-8, and awk implementations split on whether that is characters or bytes:
# macOS awk in a UTF-8 locale aborts the record with `illegal byte sequence` the
# moment it meets a sequence it cannot decode, so a vault with one accented
# heading would report a clean bill of health over every note after it. Pinning
# the locale makes every implementation read bytes, which is the one behaviour
# the slug rule below is written against.
if [ "$MODE" = "used-in" ]; then
	LC_ALL=C awk -v root="$VAULT" -v out="$FAILURES" -v pathidx="$PATHIDX" -F '\t' '
		BEGIN {
			DQ = sprintf("%c", 34)
			SQ = sprintf("%c", 39)
			BS = sprintf("%c", 92)

			# The printable ASCII the slug rule drops, written out rather than
			# expressed as a negated class: a negated class in a byte-oriented
			# awk also strikes every byte of every non-ASCII letter.
			DROP = "!" DQ "#$%&" SQ "()*+,./:;<=>?@[" BS "]^`{|}~"

			# The non-ASCII punctuation a heading realistically carries, which
			# the slug rule drops exactly as it drops the ASCII kind: en dash,
			# em dash, horizontal bar, the curly single and double quotes, the
			# ellipsis, bullet, middle dot, the daggers, degree, section,
			# pilcrow and the guillemets. awk has no character-class table to
			# ask, so the set is enumerated - and enumerated by CODE POINT
			# rather than written literally, because a literal curly quote in a
			# shell script is indistinguishable from a mistyped ASCII one to
			# every linter and every reader.
			np = split("8211 8212 8213 8216 8217 8218 8220 8221 8222 8226 8230 8224 8225 183 176 167 182 171 187", cp, " ")
			for (pi = 1; pi <= np; pi++) UNIPUNCT = UNIPUNCT (pi == 1 ? "" : "|") utf8(cp[pi] + 0)

			while ((getline pl < pathidx) > 0) EXISTS[pl] = 1
			close(pathidx)
		}

		# One code point as the UTF-8 bytes that carry it. sprintf("%c", n)
		# emits byte n under the C locale this program is pinned to; under a
		# UTF-8 locale the same call emits a CHARACTER and every sequence built
		# here would be wrong, which is the second reason the locale is pinned.
		function utf8(n) {
			if (n < 128) return sprintf("%c", n)
			if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + n % 64)
			return sprintf("%c%c%c", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + n % 64)
		}

		$1 == "N" { files[++nf] = $2; next }
		$1 == "S" { V[$2, $3] = $4; next }
		$1 == "L" { if ($3 == "used_in") UI[$2, ++UN[$2]] = $4; next }

		function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

		# The GitHub slug rule, because that is what every #fragment in a plan
		# document is written against: lowercase, drop punctuation, and turn each
		# whitespace character into its own hyphen. Two details are load-bearing,
		# and each one turns a working link into a reported failure if it is wrong.
		#
		# The repo gate implements the same rule in JavaScript, for the anchors
		# inside skills/ - scripts/check.mjs, slugify(). This is the sanctioned
		# second copy and the language boundary is what forces it: that file is
		# contributor-only, and Node is not on the machine this one runs on. A
		# change to either has to be checked against the other; the comment
		# there says the same thing from the other side.
		#
		# Whitespace runs are NOT collapsed. A heading built around an em dash
		# keeps the two spaces that flanked it once the dash is dropped, so
		# `## Target - verdict` written with a dash slugs to `target--verdict`
		# with a doubled hyphen, which is what the rendered anchor carries.
		#
		# Every byte the two drop lists do not name survives. awk sees UTF-8 as
		# bytes, so a class keeping only [a-z0-9_ -] eats every accented letter
		# and reports a heading that anchors fine as dead. UNIPUNCT is removed
		# first and as whole SEQUENCES: a bracket expression over the same
		# characters would be read as a set of bytes by a byte-oriented awk, and
		# would then strike the continuation byte of an unrelated letter.
		#
		# Case folding is ASCII-only, because that is all a byte-oriented awk can
		# do: a heading whose non-ASCII letter is written uppercase still misses.
		# The trade is deliberate - that heading is rare, and the alternative
		# reports every accented heading as dead.
		function slug(h,   i, c, o) {
			gsub(UNIPUNCT, "", h)
			o = ""
			for (i = 1; i <= length(h); i++) {
				c = substr(h, i, 1)
				if (c == " " || c == "\t") { o = o "-"; continue }
				if (index(DROP, c) > 0) continue
				o = o tolower(c)
			}
			sub(/^-+/, "", o)
			sub(/-+$/, "", o)
			return o
		}

		# Every heading one document offers an anchor for, ATX form only. A `#`
		# inside a fenced code block is an example rather than a section a reader
		# can jump to, so fences are tracked by marker character and run length -
		# which is what stops a longer nested fence from closing its parent early.
		#
		# THAT FENCE BLOCK IS ONE OF FIVE COPIES in this file. The
		# --supersession-sweep sections(), the --red-team row reader, the
		# --roadmap-table readplan() and the --binding-driver readdoc() carry the
		# same six lines, because all five read a document at the vault root and
		# no one of them can call a function defined in another awk program.
		# Change one, change all five.
		#
		# This copy is the one that most needed saying so. It has been edited
		# twice already - the `{#anchor}` attribute below landed here alone -
		# and a contract the other copies knew about while this one did not
		# would have made this the safe-looking place to edit by itself.
		#
		# Setext headings (a title underlined with ===) are deliberately not read.
		# They are document titles and a #fragment cites a section, so reading
		# them would mean carrying a line of lookbehind for a case nothing cites.
		#
		# A trailing `{#anchor}` attribute is the citation address of the heading
		# itself. It is stripped from the heading text before the slug rule runs
		# and registered as an anchor in its own right. What a rendered document owes
		# it - strip it from the visible heading, emit it as the element id, so no
		# reader ever sees `{#foo}` on the page - is the contract in
		# market-analysis/references/rendering.md, which both skills share.
		#
		# BOTH the explicit anchor and the slug of the stripped text are
		# registered, rather than the explicit one replacing the slug. A vault
		# authored before the template carried attributes cites the slug, and
		# those notes must not start failing the moment their author pastes a
		# newer template into the same document - an upgrade that fails an
		# untouched corpus is one nobody takes. Rewording protection is unaffected
		# by registering both: a heading whose TEXT changes loses its old slug
		# under either design, and the explicit anchor is the half that survives,
		# which is the whole reason to write one.
		#
		# The attribute is matched as ASCII - [A-Za-z0-9_-] - because that is the
		# character set an anchor is allowed to carry, and because a byte-oriented
		# awk reading a class over anything wider would strike the continuation
		# byte of an unrelated letter. Nothing below it changes: the heading TEXT
		# still goes through slug(), with UNIPUNCT removed as whole sequences and
		# whitespace runs left uncollapsed.
		function scan(doc,   path, line, t, c, n, fc, fn, h, a) {
			path = root "/" doc
			fc = ""; fn = 0
			while ((getline line < path) > 0) {
				sub(/\r$/, "", line)
				t = line
				sub(/^[ \t]+/, "", t)
				if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
					c = substr(t, 1, 1)
					n = 0
					while (substr(t, n + 1, 1) == c) n++
					if (fc == "") { fc = c; fn = n }
					else if (c == fc && n >= fn) { fc = ""; fn = 0 }
					continue
				}
				if (fc != "") continue
				if (!match(t, /^#+[ \t]+/)) continue
				h = substr(t, RLENGTH + 1)
				sub(/[ \t]*#+[ \t]*$/, "", h)
				sub(/[ \t]+$/, "", h)
				# Braces written as bracket expressions rather than escaped. A
				# backslash-brace is an interval expression to some awks and a
				# literal to others, and which one runs this is a property of the
				# user machine rather than of this file.
				if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
					a = substr(h, RSTART, RLENGTH)
					sub(/^[{]#/, "", a)
					sub(/[}]$/, "", a)
					HAS[doc SUBSEP a] = 1
					h = substr(h, 1, RSTART - 1)
					sub(/[ \t]+$/, "", h)
				}
				HAS[doc SUBSEP slug(h)] = 1
			}
			close(path)
		}

		END {
			for (i = 1; i <= nf; i++) {
				f = files[i]
				id = V[f, "id"]
				for (j = 1; j <= UN[f]; j++) {
					entry = UI[f, j]
					# The split below - document, #anchor, and the leading ./ and
					# trailing / stripped off - is duplicated in the
					# --supersession-sweep pass, which groups its worklist on the
					# result, and in --binding-driver, which resolves the section
					# a verdict renders into. Change one, change all three: if
					# they stop agreeing on what counts as the same target, the
					# sweep emits two rows for a section this mode resolved once,
					# and nothing fails to say so.
					p = index(entry, "#")
					doc = (p > 0) ? substr(entry, 1, p - 1) : entry
					anchor = (p > 0) ? substr(entry, p + 1) : ""
					sub(/^[ \t]+/, "", doc); sub(/[ \t]+$/, "", doc)
					sub(/^\.\//, "", doc)
					sub(/\/+$/, "", doc)

					if (doc == "") {
						report(f, "used-in-missing-file", id, "`used_in` names `" entry "`, which is an anchor with no document in front of it. A bare fragment resolves against nothing, so the note reads as cited while naming no artifact at all - and when its stale_after fires there is no document to go and re-check")
						continue
					}
					if (!(doc in EXISTS)) {
						report(f, "used-in-missing-file", id, "`used_in` names `" entry "` and nothing exists at " doc " under the vault root. Either the document was renamed after the claim was cited into it, or used_in was back-filled onto a note nothing cites - either way the blast radius points at a document no reader can open, so the re-check its stale_after fires has nowhere to go")
						continue
					}
					if (anchor == "") continue
					if (!(doc in SCANNED)) { SCANNED[doc] = 1; scan(doc) }
					if (!((doc SUBSEP anchor) in HAS))
						report(f, "used-in-dead-anchor", id, "`used_in` names `" entry "` and no heading in " doc " carries `{#" anchor "}` or slugs to `" anchor "`. A heading was renamed or cut while the note went on naming it, so the claim reads as cited into a section nobody can find - and a stale_after that fires sends its reader to a document with no such paragraph in it")
				}
			}
		}
	' "$RECORDS"

	render_failures "vault-lint used-in"
	exit $?
fi

# ----------------------------------------------------------------------------
# --red-team - a dispatched lens owes rows
#
# The panel is the most expensive read a plan gets, and until now nothing in the
# corpus recorded which lenses were sent. A lens that returned findings, saw
# them folded into two documents and never wrote a row in red-team.md is
# indistinguishable from a lens that had no objections: silence and thoroughness
# read the same, and the plan then cites objection codes into a file carrying
# none of them. This creates the record it enforces - the `## Lenses dispatched`
# roster - and checks it against the objection table beside it.
#
# BOTH DIRECTIONS, and the second one is what makes the first hold. A roster
# entry with no rows is the failure this exists for. A row whose lens is not on
# the roster is the failure the check would otherwise create: with only the
# forward direction, the cheapest way past a lens that returned nothing is to
# delete it from the roster, and the record stops being a record.
#
# It is a mode rather than a check for the same reason --used-in is: it reads a
# document at the vault root rather than a note in one of the six directories,
# which is a different surface. It shares --used-in's failure renderer, so it
# reports one row per failure with the same JSON shape.
#
# LC_ALL=C for the reason --used-in found the hard way: an objection is free
# prose in a table cell, so it carries em dashes and curly quotes, and macOS awk
# in a UTF-8 locale aborts the record on the first sequence it cannot decode -
# which would end the scan early and pass a document it never finished reading.
# ----------------------------------------------------------------------------

if [ "$MODE" = "red-team" ]; then
	RED_TEAM="$VAULT/red-team.md"
	# A vault with no red-team.md dispatched no panel, which is every vault
	# before Phase 4 runs. Reported by name rather than passing silently: a mode
	# that printed `clean` over a document it never found reads as a panel that
	# was checked. The empty failure file still goes through the renderer, so
	# --json gets a well-formed document either way.
	RED_TEAM_OK="every dispatched lens wrote rows - $VAULT"
	if [ -f "$RED_TEAM" ]; then
		LC_ALL=C awk -v out="$FAILURES" -v schema="$FOUND_SCHEMA" '
			function report(check, id, detail) { print "red-team.md\t" check "\t" id "\t" detail >> out }

			# The key the two halves are matched on: trimmed, whitespace runs
			# collapsed, lowercased. Matching the raw cell would report `Market
			# skeptic` and `market  skeptic` as two lenses, one of them missing
			# every row - and a check that fires on capitalisation is one
			# somebody switches off, which takes the half that worked with it.
			function key(s) {
				sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
				gsub(/[ \t]+/, " ", s)
				return tolower(s)
			}

			# The same trim without the folding, for the message. A failure
			# naming the lens in the case the roster wrote it in is one the
			# reader can find by eye in the document.
			function disp(s) {
				sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
				return s
			}

			{
				line = $0
				sub(/\r$/, "", line)
				t = line
				sub(/^[ \t]+/, "", t)

				# Fenced blocks hold examples, not rows. A document that
				# carries its own row template - which this one is written to -
				# would otherwise register the template as a dispatched lens
				# and fail for documenting its own format. Tracked by marker
				# character and run length so a longer nested fence cannot
				# close its parent early.
				#
				# One of five copies of those six lines: the --used-in scan(),
				# the --supersession-sweep sections(), the --roadmap-table
				# readplan() and the --binding-driver readdoc() carry the same
				# ones, for the same reason - five awk programs reading a
				# document at the vault root, and no way to share a function
				# across them. Change one, change all five.
				if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
					c = substr(t, 1, 1)
					n = 0
					while (substr(t, n + 1, 1) == c) n++
					if (fc == "") { fc = c; fn = n }
					else if (c == fc && n >= fn) { fc = ""; fn = 0 }
					next
				}
				if (fc != "") next

				if (match(t, /^#+[ \t]+/)) {
					h = substr(t, RLENGTH + 1)
					sub(/[ \t]*#+[ \t]*$/, "", h)
					inroster = (key(h) == "lenses dispatched")
					next
				}

				if (substr(t, 1, 1) != "|") next
				row = t
				sub(/^\|/, "", row)
				sub(/\|[ \t]*$/, "", row)
				nc = split(row, cell, "|")
				if (nc < 2) next
				c1 = disp(cell[1])

				# The header row and the |---| rule are skipped by the same
				# test that reads a round, rather than by counting lines: a
				# table written without a header, or with an alignment row
				# carrying colons, is still a roster and its rows still name
				# lenses that owe rows.
				if (inroster) {
					if (c1 !~ /^R?[0-9]+$/) next
					rd = c1
					sub(/^R/, "", rd)
					lens = key(cell[2])
					if (lens == "") next
					rk = rd SUBSEP lens
					if (rk in ROSTER) next
					ROSTER[rk] = 1
					RORDER[++nr] = rk
					RSHOW[rk] = disp(cell[2])
					next
				}

				# An objection row is identified by its ID rather than by the
				# heading it sits under, so a document that splits its rounds
				# across sections is read the same as one with a single table.
				# The round in the ID is the round the row counts for - it is
				# the namespace the ID already carries, so there is no second
				# place for the two to disagree.
				if (c1 !~ /^R[0-9]+-O[0-9]+$/) next
				rd = c1
				sub(/^R/, "", rd)
				sub(/-O[0-9]+$/, "", rd)
				lens = key(cell[2])
				ok = rd SUBSEP lens
				if (ok in ROWS) next
				ROWS[ok] = 1
				OORDER[++no] = ok
				OSHOW[ok] = disp(cell[2])
				OID[ok] = c1
			}

			END {
				# No roster at all. At schemaVersion 2 that is the failure,
				# because the roster is where version 2 put the record. At 1 it
				# is a document that predates the field, and failing it would
				# fail every corpus with a panel in it on the day the skill
				# updated - which is how a gate stops being run.
				if (nr == 0) {
					if (schema + 0 >= 2)
						report("red-team-no-roster", "", "red-team.md carries no `## Lenses dispatched` roster. Nothing else in the corpus records which lenses were sent, so a lens that returned findings and wrote no row is indistinguishable from one that had no objections - and the objection codes the plan cites resolve into a table that never carried them")
					exit
				}

				for (i = 1; i <= nr; i++) {
					rk = RORDER[i]
					if (rk in ROWS) continue
					split(rk, p, SUBSEP)
					report("red-team-lens-no-rows", "R" p[1] " " RSHOW[rk],
						"the roster names `" RSHOW[rk] "` as dispatched in round " p[1] " and no row in red-team.md carries an objection from it. Either the lens returned findings that were folded into the documents and never written down, in which case the plan cites a code the table does not hold, or it genuinely had none - and the whole point of the roster is that those two look identical from outside")
				}

				for (i = 1; i <= no; i++) {
					ok = OORDER[i]
					if (ok in ROSTER) continue
					split(ok, p, SUBSEP)
					report("red-team-lens-unrostered", OID[ok],
						"row `" OID[ok] "` is an objection from `" OSHOW[ok] "` in round " p[1] ", and the roster does not name that lens as dispatched in that round. A roster that omits a lens whose rows are sitting in the table is not the record it claims to be, and the check above it can then be cleared by deleting a line rather than by dispatching a lens")
				}
			}
		' "$RED_TEAM"
	else
		RED_TEAM_OK="no red-team.md under $VAULT - no panel was dispatched, so no lens owes rows"
	fi

	render_failures "vault-lint red-team" "$RED_TEAM_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --roadmap-table - the rendered roadmap against the set it is rendered from
#
# plan-template.md states the contract this reads: every item in the roadmap
# section is a `milestone` note written BEFORE the table, and the table renders
# `sequence`, `moves` and `resource` off the notes - so the two cannot drift.
# That claim was asserted and never checked, and the half that closed itself is
# the other rendering: research/timeline.md is generated, so it cannot drift.
# The hand-written table in business-plan.md can, and did not have to say so.
#
# THE KEY IS THE TITLE, MATCHED VERBATIM, and that is what makes this a check
# rather than a similarity test. A table rendered off the notes carries the
# milestone `title` as its item cell, so a correct table matches character for
# character by construction and a mismatch means somebody edited the table by
# hand. The instrument is already house style - vault.md requires `chosen` to
# match an entry in `options` verbatim, because a paraphrase makes the record
# unreadable later. Same shape, same reason. Nothing here is fuzzy, so nothing
# here cries wolf: this needs no ID column in a document a founder hands an
# investor, and no change to what the plan template says the columns are.
#
# BOTH DIRECTIONS, because each is a different failure. A row matching no
# milestone is an item that escaped the ledger, so it moves no assumption
# anybody can name and the model carries a dated change with nothing behind it.
# A milestone the table never lists is a dated change to an assumption row the
# plan does not show, so the curve has a step the reader cannot see.
#
# It is a mode rather than a check for the reason --used-in and --red-team are:
# it reads a document at the vault root rather than a note in one of the seven
# directories, which is a different surface. It shares the failure renderer, so
# it reports one row per failure with the same JSON shape.
#
# GATED ON schemaVersion 2, like every other milestone rule. A vault at 1 has no
# milestones/ directory by construction, cannot owe this, and passes.
#
# LC_ALL=C for the reason --used-in found the hard way: a milestone title and a
# plan heading both carry free prose, and macOS awk in a UTF-8 locale aborts the
# record on the first sequence it cannot decode - which would stop the read
# partway and report the milestones after it as absent from a table it never
# finished.
# ----------------------------------------------------------------------------

if [ "$MODE" = "roadmap-table" ]; then
	# The success line comes back on stdout and is captured the way FOUND_SCHEMA
	# is, because what `clean` means here depends on what there was to compare:
	# a line saying the table agrees, printed over a vault with no milestones or
	# no document, reads as a roadmap that was checked - which is the failure the
	# bare run success line already had once. Failures go to $FAILURES through
	# report() like every other mode, so stdout carries this line and nothing
	# else.
	ROADMAP_OK=$(LC_ALL=C awk -v out="$FAILURES" -v plan="$PLAN" -v hasplan="$HAS_PLAN" -v vault="$VAULT" -v schema="$FOUND_SCHEMA" -F '\t' '
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# The second copy of the --supersession-sweep fold, and it answers
			# the same question: which heading is THIS section, rather than
			# whether an anchor resolves. Every character the slug rule drops is
			# dropped here too, so any spelling that rule resolves to the roadmap
			# heading folds onto it without this program having to know which
			# characters those are. --binding-driver carries the third copy, for
			# the verdict heading. Change one, change all three.
			function fold(s,   i, c, o) {
				o = ""
				for (i = 1; i <= length(s); i++) {
					c = substr(s, i, 1)
					if (c >= "a" && c <= "z") { o = o c; continue }
					if (c >= "A" && c <= "Z") { o = o tolower(c); continue }
					if (c >= "0" && c <= "9") { o = o c; continue }
				}
				return o
			}

			# The item cells of the first table under the roadmap heading.
			#
			# THE ROW PARSER IS ONE OF TWO COPIES: --binding-driver readdoc()
			# reads the corner verdict table under the same rules - strip the
			# outer pipes, split on `|`, spot the all-dashes alignment rule, read
			# the header for which column matters, and treat a table with no rule
			# as no table. Change one, change both.
			#
			# THE HEADER ROW AND THE |---| RULE ARE BOTH DROPPED, and they are
			# dropped by one test rather than by counting lines. A row whose
			# every cell is dashes with optional colons is the alignment rule,
			# and in a GFM table everything ABOVE that rule is the header - so
			# seeing it discards whatever was buffered, and what survives to the
			# end is the body. Counting instead would take the header as an item
			# on a table written with two header lines, and would take the first
			# real item as a header on a table written with none.
			#
			# THE HEADER ALSO SAYS WHICH COLUMN THE ITEM IS IN, and reading it
			# is what keeps a numbered table from failing every row it has. Both
			# worked tables in roadmap-sequencing.md head their item column
			# `Item`, and the generated research/timeline.md puts an ordinal in
			# column one ahead of it - so a rule that always took the first cell
			# would report `1`, `2` and `3` as three items that escaped the
			# ledger on a table whose every row resolves. The column whose
			# header folds to `item` wins; with no such header, column one does,
			# which is the shape the Rule 1 table is written in.
			#
			# ONLY THE FIRST TABLE IS READ. The section legitimately carries a
			# second one - roadmap-sequencing.md Rule 3 puts the permutation
			# comparison in the plan, and its first column is an ORDER rather
			# than an item - so reading every table here would report each of
			# those rows as an item that escaped the ledger. That is exactly the
			# crying wolf this check was scoped out for once already.
			#
			# The section ends at the next heading of the same depth or
			# shallower, so a subsection under the roadmap heading is still part
			# of it.
			#
			# The fence tracking is the FOURTH copy in this file - --used-in
			# scan(), --supersession-sweep sections() and --red-team carry the
			# same six lines and --binding-driver readdoc() carries the fifth,
			# because each reads a document at the vault root and no one of them
			# can call a function defined in another awk program. A `#` or a `|`
			# inside a fenced block is an example rather than anything a reader
			# can act on. Change one, change all five.
			# The read STOPS the moment the answer can no longer change - at the
			# heading that closes the section, or at the line that ends the first
			# table in it. SEENRM makes the section unre-enterable and only the
			# first table is read, so every line after either point is parsed and
			# discarded. On a plan written to the template that is the whole back
			# half of the document, on every call, including the one folded into
			# every --release-gate run.
			function readplan(path,   line, t, c, n, fc, fn, nh, h, ex, level, inrm, intable, row, nc, cell, i, alldash, item, col, hdr, body) {
				fc = ""; fn = 0; nh = 0; level = 0
				inrm = 0; intable = 0; col = 1; hdr = ""; body = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
						c = substr(t, 1, 1)
						n = 0
						while (substr(t, n + 1, 1) == c) n++
						if (fc == "") { fc = c; fn = n }
						else if (c == fc && n >= fn) { fc = ""; fn = 0 }
						continue
					}
					if (fc != "") continue

					if (match(t, /^#+[ \t]+/)) {
						nh = 0
						while (substr(t, nh + 1, 1) == "#") nh++
						h = substr(t, RLENGTH + 1)
						sub(/[ \t]*#+[ \t]*$/, "", h)
						h = trim(h)
						ex = ""
						# Braces as bracket expressions rather than escaped, for
						# the reason scan() states: a backslash-brace is an
						# interval expression to some awks and a literal to
						# others, and which one runs this is a property of the
						# user machine.
						if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
							ex = substr(h, RSTART, RLENGTH)
							sub(/^[{]#/, "", ex)
							sub(/[}]$/, "", ex)
							h = trim(substr(h, 1, RSTART - 1))
						}
						if (inrm && nh <= level) break
						if (!SEENRM && (fold(ex) == "roadmap" || fold(h) == "roadmap")) {
							inrm = 1; SEENRM = 1; level = nh
						}
						continue
					}

					if (!inrm) continue
					if (substr(t, 1, 1) != "|") {
						if (intable) break
						continue
					}
					intable = 1

					row = t
					sub(/^\|/, "", row)
					sub(/\|[ \t]*$/, "", row)
					nc = split(row, cell, "|")
					if (nc < 1) continue
					alldash = 1
					for (i = 1; i <= nc; i++)
						if (cell[i] !~ /^[ \t]*:?-+:?[ \t]*$/) { alldash = 0; break }
					if (alldash) {
						# The row directly above the rule is the header, and it
						# is read for nothing but which column holds the item.
						if (hdr != "") {
							n = split(hdr, cell, "|")
							for (i = 1; i <= n; i++)
								if (fold(cell[i]) == "item") { col = i; break }
						}
						body = 1
						continue
					}

					# Everything above the rule is header, everything below it
					# is body, and the two are kept apart rather than buffered
					# together and pruned. A table with NO rule is not a table
					# to any renderer - it renders as the literal pipes a reader
					# sees - so its rows stay out of the body and the section
					# reports as one that lists no items, which is what the
					# reader is actually looking at.
					if (body) PEND[++NPEND] = row
					else hdr = row
				}
				close(path)
				for (i = 1; i <= NPEND; i++) {
					n = split(PEND[i], cell, "|")
					item = (col <= n) ? trim(cell[col]) : ""
					if (item != "") ROW[++NROW] = item
				}
			}

			END {
				# GATED ON schemaVersion 2, branched inside the program the way
				# --supersession-sweep, --red-team and the checks pass all branch
				# on it, rather than by the shell choosing whether to run awk at
				# all. A vault at 1 has no milestones/ directory by construction
				# and cannot owe this. Saying the rule was not applied, rather
				# than printing agreement, is the same distinction the sweep
				# makes at 1: an unconditional clean line reports a roadmap as
				# checked when nothing about it was asked.
				if (schema + 0 < 2) {
					printf("the roadmap table is a schemaVersion 2 rule and this vault is at %s - a vault at 1 carries no milestone notes, so there is no set for a table to be read against - %s\n", schema, vault)
					exit
				}

				# Two milestones carrying one title are covered by one row.
				# Nothing in the schema makes a title unique, and a check that
				# demanded it would be a rule about note wording rather than
				# about the table - which is a separate question from whether
				# the table renders the set.
				for (i = 1; i <= nf; i++) {
					f = files[i]
					if (V[f, "type"] != "milestone") continue
					MI[++nm] = f
					if (V[f, "title"] != "") HAS[V[f, "title"]] = 1
				}

				if (hasplan == "1") readplan(plan)

				# The roadmap is in the ledger and nowhere a reader can see it.
				# Reported ONCE against the document rather than once per
				# milestone: the fix is one thing - render the section - and a
				# reader who is handed eight rows for one job stops reading.
				if (nm > 0 && NROW == 0) {
					if (hasplan != "1")
						report("business-plan.md", "roadmap-table-missing", "",
							"the vault carries " nm " milestone note" (nm == 1 ? "" : "s") " and there is no business-plan.md at the vault root. The roadmap is in the ledger and nowhere a reader can see it: every item is a dated change to an assumption row, so a plan that never renders them hands its reader a curve whose steps have no stated cause")
					else if (!SEENRM)
						report("business-plan.md", "roadmap-table-missing", "",
							"the vault carries " nm " milestone note" (nm == 1 ? "" : "s") " and no heading in business-plan.md answers to `roadmap`. The items exist in the ledger and the plan has no section that shows them, so the curve has steps the reader cannot see and no place to go and ask what moved them. The plan template heading is `## Milestones & roadmap {#roadmap}`, which is also what every milestone `used_in` names")
					else
						report("business-plan.md", "roadmap-table-missing", "",
							"the roadmap section of business-plan.md lists no items and the vault carries " nm " milestone note" (nm == 1 ? "" : "s") ". A roadmap left as prose is one nothing can check - which is what let an item name an assumption that was never written - and the reader gets a section describing a sequence it never lists")
					printf("%d milestone note%s and no roadmap the plan renders - %s\n", nm, (nm == 1 ? "" : "s"), vault)
					exit
				}

				for (i = 1; i <= NROW; i++) {
					if (ROW[i] in HAS) { HIT[ROW[i]] = 1; continue }
					report("business-plan.md", "roadmap-row-no-milestone", "",
						"row `" ROW[i] "` in the roadmap section matches no `milestone` note title in this vault, character for character. The table renders `sequence`, `moves` and `resource` off the notes, so a row matching none of them was written by hand: it moves no assumption anybody can name, which roadmap-sequencing.md Rule 1 files as maintenance rather than as a roadmap item, and the model then carries a dated change with nothing behind it. Match the title verbatim, the way `chosen` matches an entry in `options` - or write the milestone note this row is missing")
				}

				for (i = 1; i <= nm; i++) {
					f = MI[i]
					ti = V[f, "title"]
					if (ti in HIT) continue
					report(f, "milestone-not-in-roadmap", V[f, "id"],
						"`title` is `" ti "` and no row in the roadmap section of business-plan.md carries it. The item is a dated change to an assumption row that the plan never shows, so the curve has a step the reader cannot see and cannot ask about - and the table stops being a rendering of this set the moment one member is absent from it. Render the row with the title verbatim, or retract the note")
				}

				if (nm == 0 && NROW == 0)
					printf("no milestone notes and no roadmap rows under %s - there is no roadmap on either side, which is every vault before the plan has one\n", vault)
				else
					printf("%d roadmap row%s against %d milestone note%s, matched verbatim - %s\n",
						NROW, (NROW == 1 ? "" : "s"), nm, (nm == 1 ? "" : "s"), vault)
			}
		' "$RECORDS")

	render_failures "vault-lint roadmap-table" "$ROADMAP_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --binding-driver - the verdict driver, and the evidence under it
#
# Invariant 16 second clause and the thin-evidence rule were prose, and nothing
# read either. A verdict whose binding driver is `policy` is supposed to render
# as *unreachable at six hours a week across two channels* rather than
# *unreachable* - and the second one rendered, at the same confidence letter,
# with nothing in the tool able to tell them apart. Both defects came from the
# same place: a verdict was an ordinary claim, so there was no field for a check
# to read. There is now, and this is the half of the reading that has to open a
# document.
#
# THE TRIGGER IS THE SUBJECT AND THERE IS NO schemaVersion GATE, and the two
# subjects trigger differently on purpose. `target-verdict` is a term this
# release introduces, so no note in any existing corpus carries it: the four
# fields owed outright are owed there whatever the note carries, and a note
# carrying none of them fails. `steady-state-ceiling` is required and predates
# its amendment, so every existing vault already holds one: there the trigger is
# FIELD PRESENCE, which is what exempts a claim written before the fields
# existed. Extending that leniency to the verdict half would pay an exemption
# whole cost over an empty population, and the cost is exact - omitting
# `binding_driver` would become the cheapest way past every rule below. A dodge
# available by omission is not an exemption, which is the same reason --red-team
# checks its roster both ways.
#
# BOTH STRINGS A DOCUMENT RENDERS OFF A NOTE ARE MATCHED VERBATIM - the
# `conditional_on` phrase and the corner table Kind cell - which is the
# --roadmap-table argument one document section over. Where one side renders off
# the other, an exact match is a check: a mismatch means somebody wrote the
# sentence by hand. There is no phrase list here and no sentence-shape
# inference, because a check that cries wolf gets switched off and switching it
# off takes the half that worked with it.
#
# WHAT SECTION A NOTE RENDERS INTO is the anchor its subject renders into in
# business-plan.md - `{#target-verdict}` or `{#steady-state}` - and, only where
# the plan carries no such section, the sections its `used_in` names. The anchor
# comes FIRST rather than joining a union with used_in, and that ordering is
# load-bearing: under a union, a note that also cites `## Why now` clears the
# condition check whenever the phrase appears there, so the verdict corner can
# read *does not clear* and pass. The union looked more permissive in the right
# way and was more permissive in the wrong one. The used_in fallback is what
# keeps a plan that renders its verdict under some other heading checkable at
# all. A note that reaches no section either way is silent rather than failing -
# the failure this exists for is a rendered plan that says less than it knows,
# and a verdict written before the plan has a section for it has nothing
# rendered to be wrong.
#
# It is a mode rather than a check for the reason --used-in, --red-team and
# --roadmap-table are: it reads a document at the vault root rather than a note
# in one of the seven directories, which is a different surface. It shares the
# failure renderer, so it reports one row per failure with the same JSON shape.
#
# LC_ALL=C for the reason --used-in found the hard way: a plan section is free
# prose and a `conditional_on` phrase is written by a founder, so both carry em
# dashes and curly quotes - and macOS awk in a UTF-8 locale aborts the record on
# the first sequence it cannot decode, which would stop the read partway and
# report the notes after it against a section it never finished.
# ----------------------------------------------------------------------------

if [ "$MODE" = "binding-driver" ]; then
	# The success line is captured off stdout the way --roadmap-table one is,
	# because what `clean` means here depends on what there was to compare: a
	# line saying the verdict agrees with the plan, printed over a vault that
	# carries no verdict, reads as a verdict that was checked.
	BD_OK=$(LC_ALL=C awk -v out="$FAILURES" -v vault="$VAULT" -v hasplan="$HAS_PLAN" -F '\t' '
			BEGIN {
				# The two driver_kind values that make a verdict conditional.
				# The full closed word list, and the rule that rejects a fourth
				# word, belong to the checks pass - this program branches on
				# policy-or-not and needs no more than that.
				COND["policy"] = 1
				COND["policy-within-band"] = 1

				# The subject a verdict carries, and the fold key of the plan
				# anchor it renders into. plan-template.md writes those two
				# headings as `## Target & verdict {#target-verdict}` and
				# `## Steady state ... {#steady-state}`.
				ANCHOR["target-verdict"] = "targetverdict"
				ANCHOR["steady-state-ceiling"] = "steadystate"

				# The one document section whose table rows are read, so every
				# other section is parsed and discarded rather than stored. The
				# corner verdict table is a property of the verdict anchor and
				# the ceiling section carries none, so recording rows anywhere
				# else would be dead data with a sync obligation attached.
				TABLEDOC = "business-plan.md"
				TABLEKEY = "targetverdict"

				# The five fields, in the order vault.md lists them. The checks
				# pass carries the same set split four-plus-one, because it is
				# the half that reports a missing field and `conditional_on` is
				# owed conditionally; here the whole set is only ever counted,
				# so it stays one list. Change one, change both.
				nv = split("binding_driver driver_kind conditional_on evidence_n evidence_counterparties", vf, " ")
			}

			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }
			$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# The same present() the checks pass uses, and copied verbatim
			# rather than written as `V[f, k] != ""` for one reason: both
			# programs implement the same trigger, and a field authored as a
			# one-item block list is present to one test and absent to the
			# other. That divergence fails a note in the checks pass while
			# silently skipping it here, which is a half-checked verdict with
			# nothing saying so. Change one, change both.
			function present(f, k) { return (V[f, k] != "" || LN[f SUBSEP k] > 0) }

			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# The third copy of the --supersession-sweep fold, answering the
			# same question --roadmap-table asks it: which heading is THIS
			# section, rather than whether an anchor resolves. Every character
			# the slug rule drops is dropped here too, so any spelling that rule
			# resolves to the verdict heading folds onto it without this program
			# having to know which characters those are. Change one, change all
			# three.
			function fold(s,   i, c, o) {
				o = ""
				for (i = 1; i <= length(s); i++) {
					c = substr(s, i, 1)
					if (c >= "a" && c <= "z") { o = o c; continue }
					if (c >= "A" && c <= "Z") { o = o tolower(c); continue }
					if (c >= "0" && c <= "9") { o = o c; continue }
				}
				return o
			}

			# Register one fold key against one heading ordinal, or RETIRE it
			# when a second heading claims the same key. The second copy of the
			# --supersession-sweep claim(), which states the safety property:
			# two headings differing only in the punctuation the fold drops are
			# indistinguishable here, so an ambiguous key resolves to nothing
			# rather than to a guess. Being wrong costs a section read against
			# the wrong note. Change one, change both.
			function claimkey(doc, k, ord,   ak) {
				if (k == "") return
				ak = doc SUBSEP k
				if (ak in ALIAS) {
					if (ALIAS[ak] != ord) ALIAS[ak] = 0
					return
				}
				ALIAS[ak] = ord
			}

			# One document at the vault root, read once, into three things:
			# every heading as fold keys pointing at its ordinal, the text of
			# every section, and the corner verdict rows of the one section that
			# has them. Memoised on SCANNED, so a document cited by four notes
			# is opened once.
			#
			# A SECTION ENDS AT THE NEXT HEADING OF ANY DEPTH, which is looser
			# than the rule --roadmap-table readplan() uses (next heading of the
			# same depth or shallower). Nothing in plan-template.md puts a
			# subsection under the verdict anchor, so the two agree today; if
			# one is ever added, the phrase a reader sees inside that subsection
			# is outside the body this reads and the condition check would cry
			# wolf. That is the trigger to adopt readplan() depth rule here.
			#
			# THE CORNER TABLE IS IDENTIFIED BY ITS HEADER rather than by being
			# the first table in the section, which is tighter than
			# --roadmap-table needs and for a reason: the verdict section
			# legitimately carries other tables - the stated range and the
			# evidenced range as two labelled rows, and the multiple band an
			# exit target carries - so a positional rule would read one of those
			# and report every row of a correct table as a kind with no note
			# behind it. A table is the corner table when its header names both
			# a `Binding driver` column and a `Kind` column, matched by the same
			# fold as everything else here; the FIRST such table in the section
			# is read and any later one is skipped, so a document quoting its
			# own format below the real table cannot double-count.
			#
			# THE ROW PARSER IS THE SECOND COPY of the one in --roadmap-table
			# readplan(): strip the outer pipes, split on `|`, spot the
			# all-dashes alignment rule, treat everything above it as header and
			# read the header for which column matters. Both carry the rule that
			# a table with NO alignment rule is not a table to any renderer, so
			# its rows are not rows. Change one, change both.
			#
			# The fence tracking is the FIFTH copy in this file - --used-in
			# scan(), --supersession-sweep sections(), --red-team and
			# --roadmap-table readplan() carry the same six lines, because each
			# reads a document at the vault root and no one of them can call a
			# function defined in another awk program. A `#` or a `|` inside a
			# fenced block is an example rather than an assertion the document
			# makes, which is also why fenced lines never reach BODY: a fenced
			# template carrying a condition would otherwise satisfy the check
			# for a section that renders nothing. Change one, change all five.
			function readdoc(doc,   path, line, t, c, n, fc, fn, ord, h, ex, row, nc, cell, i, alldash, hdr, dcol, kcol, intable, wanttable, kk, dv, kv) {
				if (doc in SCANNED) return
				SCANNED[doc] = 1
				path = vault "/" doc
				fc = ""; fn = 0; ord = 0
				hdr = ""; intable = 0; dcol = 0; kcol = 0; wanttable = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
						c = substr(t, 1, 1)
						n = 0
						while (substr(t, n + 1, 1) == c) n++
						if (fc == "") { fc = c; fn = n }
						else if (c == fc && n >= fn) { fc = ""; fn = 0 }
						continue
					}
					if (fc != "") continue

					if (match(t, /^#+[ \t]+/)) {
						h = substr(t, RLENGTH + 1)
						sub(/[ \t]*#+[ \t]*$/, "", h)
						h = trim(h)
						ex = ""
						# Braces written as bracket expressions rather than
						# escaped, for the reason scan() states: a
						# backslash-brace is an interval expression to some
						# awks and a literal to others, and which one runs
						# this is a property of the user machine.
						if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
							ex = substr(h, RSTART, RLENGTH)
							sub(/^[{]#/, "", ex)
							sub(/[}]$/, "", ex)
							h = trim(substr(h, 1, RSTART - 1))
						}
						ord++
						# Both addresses registered, not one: a vault written
						# before the template carried attributes cites the
						# slug, and an implementation where the attribute
						# REPLACED it would stop resolving those entries the
						# day the author pasted a newer template in.
						if (ex != "") claimkey(doc, fold(ex), ord)
						claimkey(doc, fold(h), ord)
						wanttable = (doc == TABLEDOC && (fold(ex) == TABLEKEY || fold(h) == TABLEKEY))
						hdr = ""; intable = 0
						continue
					}

					if (ord == 0) continue
					# A blank line closes a table to every renderer, so it
					# closes one here - otherwise two tables separated by a
					# paragraph read as one and the rows of the second land
					# under the header of the first.
					if (t == "") { hdr = ""; intable = 0; continue }

					BODY[doc, ord] = BODY[doc, ord] t "\n"
					if (substr(t, 1, 1) != "|") { hdr = ""; intable = 0; continue }
					if (!wanttable) continue

					row = t
					sub(/^\|/, "", row)
					sub(/\|[ \t]*$/, "", row)
					nc = split(row, cell, "|")
					if (nc < 1) continue
					alldash = 1
					for (i = 1; i <= nc; i++)
						if (cell[i] !~ /^[ \t]*:?-+:?[ \t]*$/) { alldash = 0; break }

					kk = doc SUBSEP ord
					if (alldash) {
						# The row directly above the rule is the header, and
						# it is read for nothing but which two columns matter.
						dcol = 0; kcol = 0
						if (hdr != "" && KN[kk] == 0) {
							n = split(hdr, cell, "|")
							for (i = 1; i <= n; i++) {
								if (fold(cell[i]) == "bindingdriver") dcol = i
								else if (fold(cell[i]) == "kind") kcol = i
							}
						}
						intable = 1
						continue
					}

					if (!intable) { hdr = row; continue }
					if (dcol == 0 || kcol == 0) continue
					dv = (dcol <= nc) ? trim(cell[dcol]) : ""
					kv = (kcol <= nc) ? trim(cell[kcol]) : ""
					KDRV[kk, ++KN[kk]] = dv
					KKND[kk, KN[kk]] = kv
				}
				close(path)
			}

			# One of three identical copies - the graph pass and the checks pass
			# carry the other two, neither annotated. Change one, change all
			# three.
			function target_of(item) {
				return (index(item, " :: ") > 0) ? substr(item, index(item, " :: ") + 4) : item
			}

			# The counterparty fallback chain vault.md documents, last rung: the
			# host of the canonical URL. It errs toward collapsing two unrelated
			# deals covered by one publication onto one party, which is why the
			# field is authored rather than inferred - and dropping the chain
			# instead errs the other way, where an unwritten field reads as *no
			# counterparty* and every note counts as its own party, so a corpus
			# written before the field reports perfect diversity.
			function hostof(u,   p) {
				if (u == "") return ""
				p = index(u, "/")
				if (p > 0) u = substr(u, 1, p - 1)
				sub(/^www\./, "", u)
				return u
			}

			# The transitive closure over rests_on, down to the source notes,
			# counting distinct sources and distinct counterparties as it goes.
			# The same downward walk `graph` performs in walkout(), narrowed to
			# the one edge that carries provenance: a copy rather than a call
			# because each mode is a separate awk process, and hoisting would
			# mean assembling awk source in a shell variable and costing every
			# program in this file its top-to-bottom readability. SEEN is what
			# makes a cycle terminate and what stops a diamond counting one
			# source twice; the caller resets it, along with the two counters
			# and the two sets, before each walk.
			function closure(id,   f, k, j, cp) {
				if (id == "" || (id in SEEN)) return
				SEEN[id] = 1
				f = BYID[id]
				if (f == "") return
				if (V[f, "type"] == "source") {
					SRC[id] = 1
					nsrc++
					cp = V[f, "counterparty"]
					if (cp == "") cp = V[f, "publisher"]
					if (cp == "") cp = hostof(V[f, "url_canonical"])
					if (cp != "" && !(cp in CP)) { CP[cp] = 1; ncp++ }
				}
				k = f SUBSEP "rests_on"
				for (j = 1; j <= LN[k]; j++) closure(target_of(LI[k, j]))
			}

			# The ONE rendered form of the two counts, generated off the note so
			# the section can be matched against it verbatim - the same property
			# that makes conditional_on and the roadmap table item cell checks
			# rather than similarity tests. plan-template.md states it as the
			# contract a writer owes: both numerals come straight from the
			# fields, and each noun pluralises on its own numeral.
			#
			# WHY A GENERATED STRING RATHER THAN A SCAN FOR THE TWO NUMBERS. An
			# earlier draft looked for each count as a whole-word token, which an
			# unrelated pair of digits in the same paragraph silences - a check
			# that passes for the wrong reason, which is worse here than one that
			# fails for the wrong reason, because nothing ever surfaces it. There
			# is exactly one string to render and one to look for, so a mismatch
			# means the line was written by hand or was never written.
			function evline(n, c) {
				return "Evidence: " n " source" (n == "1" ? "" : "s") ", " c " counterpart" (c == "1" ? "y" : "ies")
			}

			# Whether a corner row states a kind at all. plan-template.md writes
			# one of the three words for every corner where a driver binds, and
			# an em dash both for a corner where nothing binds and for one whose
			# verdict is undetermined - so a cell with no alphanumeric byte in
			# it asserts no kind and there is nothing for a note to disagree
			# with. The test is emptiness after the fold rather than membership
			# of the three words, so a cell carrying a fourth word or a typo
			# still fails against the note instead of slipping out of the check.
			function stateskind(s) { return (fold(s) != "") }

			END {
				for (i = 1; i <= nf; i++) if (V[files[i], "id"] != "") BYID[V[files[i], "id"]] = files[i]

				# The verdict section of business-plan.md, resolved once. Its
				# ordinal is what both the corner table and verdict-unfiled
				# hang off, so it is looked up before any note is read.
				tvord = 0
				if (hasplan == "1") {
					readdoc("business-plan.md")
					ak = "business-plan.md" SUBSEP "targetverdict"
					if ((ak in ALIAS) && ALIAS[ak] > 0) tvord = ALIAS[ak]
				}
				tvkk = "business-plan.md" SUBSEP tvord
				nrow = KN[tvkk] + 0

				# THE ASYMMETRIC TRIGGER, in one place. A target-verdict note is
				# read whatever it carries; a ceiling note is read only once it
				# carries one of the five, which is the exemption for every
				# ceiling claim written before the fields existed.
				for (i = 1; i <= nf; i++) {
					f = files[i]
					ty = V[f, "type"]
					if (ty != "claim" && ty != "assumption") continue
					sj = V[f, "subject"]
					if (!(sj in ANCHOR)) continue
					if (sj == "target-verdict") nvt++
					else {
						carried = 0
						for (j = 1; j <= nv && !carried; j++) if (present(f, vf[j])) carried = 1
						if (!carried) continue
					}
					VN[++nvn] = f
				}

				for (v = 1; v <= nvn; v++) {
					f = VN[v]
					sj = V[f, "subject"]
					id = V[f, "id"]
					bd = V[f, "binding_driver"]
					dk = V[f, "driver_kind"]

					# The section this verdict renders into: the anchor its
					# subject renders into, and only where the plan carries no
					# such section, the sections its used_in names.
					ncand = 0
					if (hasplan == "1") {
						ak = "business-plan.md" SUBSEP ANCHOR[sj]
						if ((ak in ALIAS) && ALIAS[ak] > 0) CK[++ncand] = "business-plan.md" SUBSEP ALIAS[ak]
					}
					k = f SUBSEP "used_in"
					for (j = 1; ncand == 0 && j <= LN[k]; j++) {
						entry = LI[k, j]
						# The third copy of the --used-in split: document,
						# #anchor, and the leading ./ and trailing / stripped
						# off. Byte-identical to the copies in --used-in and
						# --supersession-sweep on purpose, so a diff of the
						# three proves they agree on what an entry names - the
						# `..` guard below is the one deliberate difference.
						# Change one, change all three.
						p = index(entry, "#")
						doc = (p > 0) ? substr(entry, 1, p - 1) : entry
						anc = (p > 0) ? substr(entry, p + 1) : ""
						sub(/^[ \t]+/, "", doc); sub(/[ \t]+$/, "", doc)
						sub(/^\.\//, "", doc)
						sub(/\/+$/, "", doc)

						if (doc == "" || anc == "") continue
						# A path that climbs out of the vault is not opened.
						# --used-in reports it missing rather than reading it,
						# and this mode has no business reading it either.
						if (doc ~ /(^|\/)\.\.(\/|$)/) continue
						readdoc(doc)
						ak = doc SUBSEP fold(anc)
						if ((ak in ALIAS) && ALIAS[ak] > 0) CK[++ncand] = doc SUBSEP ALIAS[ak]
					}

					# --- the condition a policy-bound verdict owes ----------
					# `conditional_on` absent is verdict-fields-incomplete from
					# `check` and is not reported twice here under a name about
					# the plan: with no string there is nothing for a section to
					# be missing.
					co = V[f, "conditional_on"]
					if ((dk in COND) && co != "" && ncand > 0) {
						found = 0
						for (c = 1; c <= ncand; c++)
							if (index(BODY[CK[c]], co) > 0) { found = 1; break }
						if (!found)
							report(f, "verdict-unconditional", id, "`driver_kind` is `" dk "` and `conditional_on` is `" co "`, and the section this note renders into does not carry that string. A policy-bound verdict is not that the target is unreachable - it is unreachable in the stated configuration, and the plan has to say so in the words the note stores. `Your target is unreachable` and `your target is unreachable at " co "` render at the same confidence letter and only the second one is true, so the founder is stopped over a decision they could revisit this week. The match is verbatim because the section renders off this field; render the phrase, or correct the field to the words the section uses")
					}

					# --- the kind, both directions, in one row scan ----------
					# The forward failure is a Kind cell that disagrees with the
					# note its Binding driver cell names. The reverse is a
					# verdict in the ledger that no row names at all, and it is
					# what keeps the forward one honest: with only the forward
					# direction the cheapest way past both is to edit the driver
					# cell until it matches no note.
					#
					# The reverse asks whether a row NAMES the driver and not
					# whether that row states a kind, and the difference is a
					# deliberate trade. plan-template.md writes an em dash in
					# the Kind cell of an undetermined corner whose driver IS
					# named, so a rule that demanded a kind there would report
					# the shipped template. What that leaves open is blanking
					# the Kind cell of a corner that does bind, which the
					# forward half then skips; the template names that as a
					# contract violation, and a check that fires on the worked
					# example is one somebody switches off, which costs both
					# halves.
					#
					# A cell naming no note is NOT a failure either way: a
					# corner that clears legitimately writes an em dash or a
					# parenthetical in that column, and reporting those would be
					# the crying wolf this whole file refuses.
					if (sj == "target-verdict" && nrow > 0 && bd != "" && dk != "") {
						hit = 0
						for (r = 1; r <= nrow; r++) {
							if (KDRV[tvkk, r] != bd) continue
							hit = 1
							if (!stateskind(KKND[tvkk, r])) continue
							if (KKND[tvkk, r] == dk) continue
							report("business-plan.md", "verdict-kind-mismatch", id, "the corner verdict row for driver `" bd "` carries `Kind` cell `" KKND[tvkk, r] "` and " id " carries `driver_kind: " dk "`. The column renders off the field, so the two cannot drift unless the cell was edited by hand - and the direction that matters is a cell reading `structural` over a note reading `policy`, which reports a decision the founder made as a category floor at the same confidence letter as an observation somebody read off a page. Match the field verbatim, or correct the field")
						}
						if (!hit)
							report(f, "verdict-kind-mismatch", id, "`binding_driver` is `" bd "` and no row of the corner verdict table under `{#target-verdict}` names that driver. The table renders its `Binding driver` and `Kind` columns off this note, so a verdict in the ledger that the table never lists is a corner the reader cannot see - and it is the direction that makes the cell check worth having, because a cell edited until it matches nothing would otherwise clear both. Render the row with the driver verbatim, or correct the field to the driver the table names")
					}

					# --- the evidence under the binding driver --------------
					# A SINGLE COUNTERPARTY IS REPORTABLE AT ANY n. Three deals
					# from one counterparty is the terms of one relationship
					# reported as the terms of a market, and a source count of
					# three reads as the opposite - which is the half no other
					# field in the corpus can recover.
					#
					# SURFACING IT IS A CONJUNCTION: the note carries the counts
					# AND the section renders them. vault.md once read as a
					# disjunction - the note OR the section - and that can never
					# be both-false, because `check` owes both fields on every
					# note this mode reads, so it reduced to a rule about the
					# ledger alone. The failure being closed is not that the
					# ledger is wrong. It is that the corpus knew the tail was
					# two deals from one party and the number a founder acts on
					# never said so where anybody read it: rendered without the
					# line, that verdict is typographically identical to one
					# resting on twenty deals across twelve parties, and
					# `confidence` cannot separate them - it is a letter about
					# the weakest link and says nothing about how many links
					# there are.
					#
					# THE LINE IS OWED ONLY WHERE THE TAIL IS ACTUALLY THIN, so
					# a well-evidenced verdict owes nothing and this never
					# becomes a line on every plan that everyone learns to skip.
					# That is what keeps it on the one case that cannot be stated
					# honestly without it.
					#
					# The two halves report under one code and in order, because
					# a wrong pair cannot render a right line: correct the field
					# first, then the section. The stored-pair half fires on
					# absent counts as well as wrong ones, which is deliberately
					# not the `conditional_on` treatment above - there, with no
					# string stored, the question this mode asks has no answer,
					# while here the closure answers it either way and the number
					# is the product. The rendered half is gated on the note
					# reaching a section at all, exactly as the condition check
					# is: a verdict written before the plan has a section for it
					# has nothing rendered to be missing the line.
					split("", SEEN); split("", SRC); split("", CP)
					nsrc = 0; ncp = 0
					closure(id)

					if (nsrc < 3 || ncp < 2) {
						en = V[f, "evidence_n"]
						ec = V[f, "evidence_counterparties"]
						tail = nsrc " distinct source note" (nsrc == 1 ? "" : "s") " and " ncp " distinct counterpart" (ncp == 1 ? "y" : "ies")
						if (en != (nsrc "") || ec != (ncp ""))
							report(f, "verdict-thin-evidence", id, "the closure under this note reaches " tail ", and the note does not say so" (present(f, "evidence_n") ? " - it states `evidence_n: \"" en "\"` and `evidence_counterparties: \"" ec "\"`, which is not what the closure holds" : "") ". A verdict resting on two deals renders identically to one resting on twenty, because `confidence` is a letter about the weakest link and says nothing about how many links there are - and three deals from one counterparty is the terms of one relationship reported as the terms of a market. State the counts, or widen the evidence under the driver")
						else if (ncand > 0) {
							ev = evline(en, ec)
							found = 0
							for (c = 1; c <= ncand; c++)
								if (index(BODY[CK[c]], ev) > 0) { found = 1; break }
							if (!found)
								report(f, "verdict-thin-evidence", id, "the closure under this note reaches " tail " and the note states both counts, and the section it renders into does not carry `" ev "`. Counts that are right in the ledger are not what this rule is for: the section can render *the target lands about a third of the way* with nothing saying the finding rests on " tail ", which is typographically identical to a verdict resting on twenty deals across twelve parties - and `confidence` cannot separate the two, because it is a letter about the weakest link and says nothing about how many links there are. The line is generated off `evidence_n` and `evidence_counterparties` and matched verbatim, so render it exactly as printed here; plan-template.md carries the form, and the em dash a well-evidenced corner uses instead")
						}
					}
				}

				# --- a verdict that reached the plan and never the ledger ---
				# --roadmap-table inverted: that mode fails milestone notes with
				# no business-plan.md to render them, and this fails a rendered
				# section with nothing behind it. WHAT TRIGGERS IT IS THE
				# PRESENCE OF A NON-EMPTY SECTION and never a reading of the
				# prose inside it, for the same reason conditional_on is matched
				# verbatim: a check that infers a verdict from sentence shape
				# cries wolf, and one that cries wolf gets switched off.
				#
				# THERE IS DELIBERATELY NO {#steady-state} EQUIVALENT. A ceiling
				# section in an existing plan legitimately has no
				# field-carrying note behind it - the same asymmetry the trigger
				# above carries, one document over - so a mirror rule here would
				# fail every plan written before this release.
				#
				# `nvt` is the count of target-verdict notes taken in the
				# classification loop, because that subject is admitted to VN
				# unconditionally: a second pass over every note would be the
				# same question asked a third time.
				if (tvord > 0 && BODY["business-plan.md", tvord] != "" && !nvt)
					report("business-plan.md", "verdict-unfiled", "", "business-plan.md carries a non-empty section at the `{#target-verdict}` anchor and no `claim` or `assumption` under `subject: target-verdict` stands behind it. Everything else this mode checks presumes a note exists, and a verdict written straight into the plan has none of the properties the ledger gives a number: no `rests_on`, so no confidence derivation and no cap; no `stale_after`, so nothing ever comes up for re-checking; no supersession when the target is renegotiated, so the superseded finding is simply overwritten; and `--supersession-sweep` cannot name this section when something under it moves. It is the one output of this skill most likely to make a founder stop, held to less than a sourced market-size figure")

				if (nvn == 0 && tvord == 0) {
					if (hasplan == "1")
						printf("no verdict note and no section at the {#target-verdict} anchor of business-plan.md - there is no verdict on either side, which is every vault before a target has one - %s\n", vault)
					else
						printf("no verdict note and no business-plan.md at the vault root - there is no verdict on either side, which is every vault before a target has one - %s\n", vault)
					exit
				}
				printf("%d verdict note%s against %d corner verdict row%s under the {#target-verdict} anchor, matched verbatim - %s\n",
					nvn, (nvn == 1 ? "" : "s"), nrow, (nrow == 1 ? "" : "s"), vault)
			}
		' "$RECORDS")

	render_failures "vault-lint binding-driver" "$BD_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --assumption-rows - the model's inputs against the notes that declare them
#
# THIS MODE IS AN INVERSE, AND THE RULE IT INVERTS IS CORRECT.
# plan-template.md's assumptions section requires that no number appears in a
# projection that is not a named assumption row. That is load-bearing against
# fake precision and nothing here weakens it. What it never had is a counterpart
# asking whether a named assumption is MISSING from the table - so the failure is
# silent in both directions: the notes lint clean, the table lints clean, and
# nothing compared them.
#
# Observed: two assumptions governing a whole revenue line existed as notes,
# correctly authored with subjects and confidence, and were never added as rows.
# The rule intended to enforce rigour then made that revenue line structurally
# unable to enter the projection; the model filed it as revenue outside its
# scope, which reads as a modelling decision and was a consequence of the
# omission; and every downstream verdict inherited a denominator missing a line
# the roadmap ships.
#
# IT IS --roadmap-table ONE ARTIFACT OVER, deliberately, down to the reading
# rules: the same fold on the section heading, the same row parser, the same
# only-the-first-table rule, and the same VERBATIM title match. Where one side
# renders off the other an exact match is a check and anything looser is a
# similarity test that cries wolf until somebody switches it off.
#
# THE ARR TERM DECLARES ITS COMPOSITION, and that is the fourth check. A model
# may legitimately exclude a revenue line - a metered layer must not be allowed
# to flatter subscription churn, and a good model refuses to mix them. What it
# may not do is exclude it silently: the identity a verdict solves is ARR at the
# target date times the multiple, and target.md's own table establishes that none
# of the multiple's inputs is ARR, so an excluded line is a term missing from the
# denominator every corner is solved against. On the engagement this came from
# the excluded layer was a roadmap item with roughly ten times the revenue per
# account, the plan said so in its own one-pager, and three separate verdict
# re-solves each corrected a different term - a rate, a convention, a sample
# size - inherited the same denominator, and the answer never moved.
# roadmap-sequencing.md already makes every roadmap item name the assumption it
# moves; this is the reverse half, and the reverse half is what makes the
# exclusion arguable by somebody who disagrees with it.
#
# GATED ON schemaVersion 3, where `model_input`, `excluded_from_model` and
# `arr_excludes` were added. A vault at 1 or 2 carries none of them and is told
# the rule was not applied rather than that its table agrees - the distinction
# --roadmap-table makes at 1, for the reason a clean line over a question nobody
# asked is what somebody renders on.
#
# LC_ALL=C for the reason --used-in found the hard way: an assumption title and a
# table cell are both free prose, and macOS awk in a UTF-8 locale aborts the
# record on the first sequence it cannot decode - which would stop the read
# partway and report every input after it as absent from a table it never
# finished.
# ----------------------------------------------------------------------------

if [ "$MODE" = "assumption-rows" ]; then
	# The success line is captured off stdout the way --roadmap-table's is,
	# because what clean means here depends on what there was to compare: a line
	# saying the table agrees, printed over a vault with no declared inputs and
	# no document, reads as a model that was checked.
	AR_OK=$(LC_ALL=C awk -v out="$FAILURES" -v model="$FINMODEL" -v hasmodel="$HAS_FINMODEL" -v vault="$VAULT" -v schema="$FOUND_SCHEMA" -F '\t' '
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }
			$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# A block-list item may carry a `:: label` after the ID it names, so
			# every edge walk in this file strips it. The fourth copy - graph,
			# --binding-driver and the checks pass carry the other three, and
			# each awk program is a separate process that cannot call another
			# one. Change one, change all four.
			function target_of(item) {
				return (index(item, " :: ") > 0) ? substr(item, index(item, " :: ") + 4) : item
			}

			# The same fold every section-resolving mode in this file carries -
			# --supersession-sweep sections(), --roadmap-table readplan(),
			# --binding-driver readdoc() and --claim-drift below. It answers
			# which heading THIS section is, not whether an anchor resolves, so
			# it drops every character the slug rule drops without having to
			# know which those are. Change one, change all of them.
			function fold(s,   i, c, o) {
				o = ""
				for (i = 1; i <= length(s); i++) {
					c = substr(s, i, 1)
					if (c >= "a" && c <= "z") { o = o c; continue }
					if (c >= "A" && c <= "Z") { o = o tolower(c); continue }
					if (c >= "0" && c <= "9") { o = o c; continue }
				}
				return o
			}

			# The assumption cells of the first table under the assumptions
			# heading. TRANSCRIBED FROM --roadmap-table readplan() with two
			# changes and no others, so a diff of the two reads as one parser:
			# the heading folds to `assumptions` rather than `roadmap`, and the
			# item column defaults to TWO rather than one.
			#
			# THE DEFAULT COLUMN IS THE ONE DIFFERENCE THAT MATTERS. The
			# template ships `| # | Assumption | Value | Source | Confidence |`,
			# so column one is the `A-n` row label the plan cites in prose and a
			# roadmap `moves` field names. Defaulting to it would report `1`,
			# `2` and `3` as three inputs that escaped the ledger on a table
			# whose every row resolves. The column whose header folds to
			# `assumption` still wins where one exists.
			#
			# The fence tracking is another copy of the six lines every
			# document-reading mode in this file carries, for the reason stated
			# at --used-in scan(): a `#` or a `|` inside a fenced block is an
			# example rather than anything a reader can act on, and no one awk
			# program can call a function defined in another. Change one, change
			# all of them.
			function readmodel(path,   line, t, c, n, fc, fn, nh, h, ex, level, inas, intable, row, nc, cell, i, alldash, item, col, hdr, body) {
				fc = ""; fn = 0; nh = 0; level = 0
				inas = 0; intable = 0; col = 2; hdr = ""; body = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
						c = substr(t, 1, 1)
						n = 0
						while (substr(t, n + 1, 1) == c) n++
						if (fc == "") { fc = c; fn = n }
						else if (c == fc && n >= fn) { fc = ""; fn = 0 }
						continue
					}
					if (fc != "") continue

					if (match(t, /^#+[ \t]+/)) {
						nh = 0
						while (substr(t, nh + 1, 1) == "#") nh++
						h = substr(t, RLENGTH + 1)
						sub(/[ \t]*#+[ \t]*$/, "", h)
						h = trim(h)
						ex = ""
						# Braces as bracket expressions rather than escaped, for
						# the reason scan() states: a backslash-brace is an
						# interval expression to some awks and a literal to
						# others, and which one runs this is a property of the
						# user machine.
						if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
							ex = substr(h, RSTART, RLENGTH)
							sub(/^[{]#/, "", ex)
							sub(/[}]$/, "", ex)
							h = trim(substr(h, 1, RSTART - 1))
						}
						if (inas && nh <= level) break
						if (!SEENAS && (fold(ex) == "assumptions" || fold(h) == "assumptions")) {
							inas = 1; SEENAS = 1; level = nh
						}
						continue
					}

					if (!inas) continue
					if (substr(t, 1, 1) != "|") {
						if (intable) break
						continue
					}
					intable = 1

					row = t
					sub(/^\|/, "", row)
					sub(/\|[ \t]*$/, "", row)
					nc = split(row, cell, "|")
					if (nc < 1) continue
					alldash = 1
					for (i = 1; i <= nc; i++)
						if (cell[i] !~ /^[ \t]*:?-+:?[ \t]*$/) { alldash = 0; break }
					if (alldash) {
						if (hdr != "") {
							n = split(hdr, cell, "|")
							for (i = 1; i <= n; i++)
								if (fold(cell[i]) == "assumption") { col = i; break }
						}
						body = 1
						continue
					}

					# Everything above the alignment rule is header and
					# everything below it is body, kept apart rather than
					# buffered together and pruned. A table with NO rule is not
					# a table to any renderer, so its rows stay out of the body
					# and the section reports as one that lists no inputs.
					if (body) PEND[++NPEND] = row
					else hdr = row
				}
				close(path)
				for (i = 1; i <= NPEND; i++) {
					n = split(PEND[i], cell, "|")
					item = (col <= n) ? trim(cell[col]) : ""
					if (item != "") ROW[++NROW] = item
				}
			}

			END {
				# GATED ON schemaVersion 3, branched inside the program the way
				# every other version gate in this file is, rather than by the
				# shell deciding whether to run awk at all.
				if (schema + 0 < 3) {
					printf("the model table is a schemaVersion 3 rule and this vault is at %s - `model_input`, `excluded_from_model` and `arr_excludes` were added at 3, so a vault before it carries none of them and there is nothing to read a table against - %s\n", schema, vault)
					exit
				}

				# FOUR SETS OVER THE NOTES IN ONE WALK, because every one of
				# them is a question about the note in hand and a second pass
				# would be the same list read twice. The PowerShell twin builds
				# the same four in one loop, so a diff of the two reads as one
				# pass rather than as a structural difference nobody intended.
				#
				# TITLE is every assumption title a row may match - not only the
				# declared inputs - because a row whose note exists and agrees is
				# not a failure whatever else that note declares. MI is the
				# declared inputs, in vault order so two runs print the same
				# list.
				for (i = 1; i <= nf; i++) {
					f = files[i]
					ty = V[f, "type"]
					if (ty == "assumption") {
						if (V[f, "title"] != "") TITLE[V[f, "title"]] = 1
						if (V[f, "model_input"] != "") MI[++nmi] = f
					}

					# What the roadmap ships a change to. `moves` names the note
					# an item moves, which roadmap-sequencing.md already
					# requires - this is the reverse direction of that edge and
					# reads nothing new to get it.
					if (ty == "milestone") {
						k = f SUBSEP "moves"
						for (j = 1; j <= LN[k]; j++) MOVED[target_of(LI[k, j])] = V[f, "id"]
					}

					# What the identity declares it leaves out, collected only
					# from a verdict note. `arr_excludes` anywhere else is not
					# a statement about the ARR term, and accepting it there
					# would let the declaration sit on a note no reader of the
					# verdict ever opens.
					if (V[f, "subject"] != "target-verdict" && V[f, "subject"] != "steady-state-ceiling") continue
					k = f SUBSEP "arr_excludes"
					for (j = 1; j <= LN[k]; j++) DECLARED[target_of(LI[k, j])] = V[f, "id"]
				}

				if (hasmodel == "1") readmodel(model)

				# The inputs are in the ledger and nowhere a reader can see
				# them. Reported ONCE against the document rather than once per
				# note: the fix is one thing - render the table - and a reader
				# handed one row per input stops reading.
				if (nmi > 0 && NROW == 0) {
					if (hasmodel != "1")
						report("financial-model.md", "model-table-missing", "",
							"the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input` and there is no financial-model.md at the vault root. Every one of them is an input the projection is supposed to be built from, so a model that never renders them is a projection whose numbers are buried in formulas - which is the failure the assumptions table exists to prevent, from the other side")
					else if (!SEENAS)
						report("financial-model.md", "model-table-missing", "",
							"the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input` and no heading in financial-model.md answers to `assumptions`. The inputs exist in the ledger and the model has no section that lists them, so a reader cannot tell which numbers the projection stands on. The plan template heading is `## Assumptions (every input lives here - nothing buried in a formula) {#assumptions}`")
					else
						report("financial-model.md", "model-table-missing", "",
							"the assumptions section of financial-model.md lists no rows and the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input`. A table with a heading and no rows reads as a model whose inputs are stated somewhere, and they are stated in the ledger only - so the projection has no visible input list at all")
					printf("%d declared model input%s and no assumptions table the model renders - %s\n", nmi, (nmi == 1 ? "" : "s"), vault)
					exit
				}

				for (i = 1; i <= NROW; i++) {
					if (ROW[i] in TITLE) { HIT[ROW[i]] = 1; continue }
					report("financial-model.md", "model-row-no-assumption", "",
						"row `" ROW[i] "` in the assumptions section matches no `assumption` note title in this vault, character for character. The table renders each input off its note, so a row matching none of them was written by hand: the number in it has no `value`, no `sensitivity` and no `validated_by`, so nothing orders it in the validation queue and nothing will ever revisit it. Match the title verbatim, the way a roadmap row matches a milestone title - or write the assumption note this row is missing")
				}

				for (i = 1; i <= nmi; i++) {
					f = MI[i]
					ti = V[f, "title"]
					ex = V[f, "excluded_from_model"]
					if (ti in HIT) continue
					# Either clears it, and that is the design. A row means the
					# input entered the projection; a stated exclusion means
					# somebody decided it should not and said why. What fails is
					# neither - an input the ledger holds, the model does not
					# carry, and nothing records a decision about.
					if (ex != "") continue
					report(f, "assumption-not-in-model", V[f, "id"],
						"`model_input` is `" V[f, "model_input"] "` and `title` is `" ti "`, and no row in the assumptions section of financial-model.md carries it. The note declares itself an input to the projection and the projection has no row for it, so the value cannot enter the model at all - and the line it governs then reads as revenue the model deliberately left out rather than as an input somebody forgot to add. Every verdict downstream inherits a denominator missing it. Render the row with the title verbatim, or state `excluded_from_model` with the reason the model does not carry it")
				}

				# THE ARR TERM DECLARES ITS COMPOSITION. An exclusion is
				# legitimate; an undeclared one is the defect. The trigger is
				# the conjunction - excluded AND on the roadmap - because an
				# excluded input nothing ships a change to is a line outside the
				# horizon of the plan itself, and failing that would be a rule about
				# scope rather than about the identity.
				for (i = 1; i <= nmi; i++) {
					f = MI[i]
					id = V[f, "id"]
					if (V[f, "excluded_from_model"] == "") continue
					if (!(id in MOVED)) continue
					if (id in DECLARED) continue
					report(f, "excluded-line-on-roadmap", id,
						"`excluded_from_model` is `" V[f, "excluded_from_model"] "` and " MOVED[id] " on the roadmap moves this note, and no verdict note names it in `arr_excludes`. The roadmap ships a change to a line the model does not carry, so the ARR term every corner of the target is solved against is a subset figure and nothing says which subset. A model may exclude a revenue line - a metered layer must not be allowed to flatter subscription churn - but the exclusion is a term of the identity and belongs where the identity is stated: name this note in `arr_excludes` on the verdict note, or give the model a row for it")
				}

				if (nmi == 0 && NROW == 0)
					printf("no declared model inputs and no assumption rows under %s - there is no model on either side, which is every vault before the plan has one\n", vault)
				else
					printf("%d assumption row%s against %d declared model input%s, matched verbatim - %s\n",
						NROW, (NROW == 1 ? "" : "s"), nmi, (nmi == 1 ? "" : "s"), vault)
			}
		' "$RECORDS")

	render_failures "vault-lint assumption-rows" "$AR_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --claim-drift - a cited section against the hash the note recorded
#
# WHAT THIS ADDS TO THE TWO MODES EITHER SIDE OF IT. --used-in asserts a citation
# RESOLVES and says at length why it never asserts the section carries the claim.
# --binding-driver asserts one verbatim string generated off a note is present.
# Neither can answer whether a section still carries what it carried yesterday,
# and that is a different question from both: it needs no reading of prose for
# meaning, because the comparison is against the text somebody already read.
#
# Observed: a claim was written into a plan section, satisfying invariant 20. A
# later re-solve rewrote that block. The heading was untouched, so `used_in`
# still resolved and the gate stayed green while the section no longer said what
# the note says. It was found by hand, days later - the exact failure invariant 20
# exists to prevent, occurring AFTER the invariant had been satisfied once, which
# is the case a one-time check structurally cannot see.
#
# WHAT A HASH CAN AND CANNOT SAY. It cannot say the section agrees with the note;
# that is the read invariant 19 owns. It can say whether the text under the
# reader's eye then is the text standing there now - so a rewritten section
# RE-OPENS the claim instead of passing on a `reconciled:` date nothing has
# re-examined since. That is the same honest limit `reconciled:` itself carries
# and the same payoff: skipping the re-read becomes something somebody has to
# state rather than something that happens by default.
#
# THE FIELD EXTENDS `reconciled:` RATHER THAN PARALLELING IT. 1.12.0 added that
# date for supersessions; `reconciled_sections` is its itemisation - the date
# says a read happened, the entries say what was read and what it looked like. A
# second date field under another name would be two records of one act, and
# nothing would keep them in step.
#
# THE MESSAGE CARRIES THE CURRENT HASH, which is what makes a read-only tool
# usable here. There is deliberately no write mode in this script, so the author
# re-reads the section and pastes one token - and pasting it is the assertion
# that the read happened, exactly as stamping a date is.
#
# WHY A 31-BIT POLYNOMIAL RATHER THAN A REAL DIGEST. This has to be byte-identical
# in POSIX awk and in Windows PowerShell 5.1 with zero dependencies on either
# side, and it is detecting an EDIT rather than resisting an adversary - nobody
# gains anything by forging a section that hashes to its own previous value. A
# polynomial mod 2^31-1 needs no bitwise operators, which BWK awk does not have,
# and every intermediate stays exactly representable in a double. The modulus is
# under 2^31 so `%08x` is safe on every awk rather than only the ones that widen.
#
# NORMALISATION IS THREE RULES AND EVERY ONE OF THEM PREVENTS A FALSE POSITIVE.
# Trailing whitespace is stripped per line, and leading, trailing and repeated
# blank lines are collapsed: all three are invisible in a rendered document, so a
# hash that changed on them would re-open every claim in the corpus the first
# time an editor trimmed a file. Nothing else is touched - a rewrapped paragraph
# IS an edit to the block, and re-reading it is one paste.
#
# LC_ALL=C so the hash is over bytes on every awk. Under a UTF-8 locale macOS awk
# would abort the record on the first sequence it cannot decode, and the two
# implementations would then disagree about the hash of any section carrying an
# em dash - which is most of them.
# ----------------------------------------------------------------------------

if [ "$MODE" = "claim-drift" ]; then
	CD_OK=$(LC_ALL=C awk -v root="$VAULT" -v out="$FAILURES" -v pathidx="$PATHIDX" -v vault="$VAULT" -v schema="$FOUND_SCHEMA" -F '\t' '
			BEGIN {
				# One byte at a time needs a byte value, and awk has no ord().
				# Built under LC_ALL=C, where sprintf("%c", i) is byte i rather
				# than code point i. From 1, because no section text carries a
				# NUL and awk cannot hold one in a subscript.
				for (bi = 1; bi < 256; bi++) ORD[sprintf("%c", bi)] = bi
				while ((getline pl < pathidx) > 0) EXISTS[pl] = 1
				close(pathidx)
			}

			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }
			$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# Another copy of the fold every section-resolving mode carries -
			# see --assumption-rows. Change one, change all of them.
			function fold(s,   i, c, o) {
				o = ""
				for (i = 1; i <= length(s); i++) {
					c = substr(s, i, 1)
					if (c >= "a" && c <= "z") { o = o c; continue }
					if (c >= "A" && c <= "Z") { o = o tolower(c); continue }
					if (c >= "0" && c <= "9") { o = o c; continue }
				}
				return o
			}

			# The polynomial itself. 131 is an odd multiplier above the byte
			# range, 2147483647 is 2^31-1, and the length is mixed in last so
			# two sections differing only in trailing content the normaliser
			# dropped still separate. Every intermediate is under 2^38, well
			# inside the 2^53 an awk double holds exactly, so this is
			# reproducible arithmetic rather than floating-point luck.
			function shash(s,   i, h, n) {
				h = 0
				n = length(s)
				for (i = 1; i <= n; i++) h = (h * 131 + ORD[substr(s, i, 1)]) % 2147483647
				h = (h * 131 + n) % 2147483647
				return sprintf("%08x", h)
			}

			# Every heading in one document as fold keys pointing at its
			# ordinal, and the NORMALISED body of every section beside it. The
			# body is what gets hashed, so the two are read in one pass - a
			# second pass would be a second place the section boundary is
			# decided.
			#
			# A SECTION ENDS AT THE NEXT HEADING OF ANY DEPTH, which is the rule
			# --binding-driver readdoc() uses rather than the
			# same-depth-or-shallower one --roadmap-table readplan() uses. The unit here is the
			# prose a citation points at, and a subsection has its own address:
			# rolling it into its parent would re-open every claim on the parent
			# heading whenever any subsection was touched, and a claim that
			# re-opens for a reason its reader cannot see is one whose hash gets
			# re-stamped without a read.
			#
			# THE HEADING LINE IS OUTSIDE THE BODY IT OPENS. A reworded heading
			# is a dead anchor and --used-in verdict, so hashing it in would
			# report one failure as two, under a name about reconciliation.
			#
			# Fenced lines are CONTENT and only heading detection is suspended
			# inside them: a `#` in a fence is an example rather than a section
			# boundary, and dropping a fenced block from the hash would leave a
			# rewritten example invisible. The six lines are another copy of the
			# scan every document-reading mode here carries.
			function sections(doc,   path, line, t, c, n, fc, fn, h, ex, id, cur, k) {
				path = root "/" doc
				fc = ""; fn = 0; id = 0; cur = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
						c = substr(t, 1, 1)
						n = 0
						while (substr(t, n + 1, 1) == c) n++
						if (fc == "") { fc = c; fn = n }
						else if (c == fc && n >= fn) { fc = ""; fn = 0 }
					} else if (fc == "" && match(t, /^#+[ \t]+/)) {
						h = substr(t, RLENGTH + 1)
						sub(/[ \t]*#+[ \t]*$/, "", h)
						h = trim(h)
						ex = ""
						if (match(h, /[{]#[A-Za-z0-9_-]+[}]$/)) {
							ex = substr(h, RSTART, RLENGTH)
							sub(/^[{]#/, "", ex)
							sub(/[}]$/, "", ex)
							h = trim(substr(h, 1, RSTART - 1))
						}
						id++
						# BOTH addresses registered, the same as --used-in
						# scan(): a vault written before the template carried
						# attributes cites the slug, and an implementation where
						# the attribute replaced it would stop resolving those
						# entries the day somebody pasted a newer template in.
						# Ambiguity is retired rather than resolved - two
						# headings folding to one key leave the key answering to
						# nothing, so a claim citing it is skipped here and stays
						# whatever --used-in makes of it.
						if (fold(ex) != "") claim(doc, fold(ex), id)
						claim(doc, fold(h), id)
						cur = id
						continue
					}
					if (cur == 0) continue

					# Trailing whitespace off every line, and blank lines
					# folded: leading and trailing ones dropped, an interior run
					# collapsed to one. All three are invisible in a rendered
					# document, so a hash sensitive to them re-opens every claim
					# in the corpus the first time a file is trimmed.
					sub(/[ \t]+$/, "", line)
					k = doc SUBSEP cur
					if (line == "") { PENDNL[k] = (RAW[k] == "") ? 0 : 1; continue }
					if (PENDNL[k]) { RAW[k] = RAW[k] "\n"; PENDNL[k] = 0 }
					RAW[k] = (RAW[k] == "") ? line : RAW[k] "\n" line
				}
				close(path)
			}

			# Register one fold key against one heading, or retire it when a
			# second heading claims the same key. The third copy of the
			# --supersession-sweep claim(); --binding-driver carries the second
			# as claimkey(). Change one, change all three.
			function claim(doc, k, id,   ak) {
				if (k == "") return
				ak = doc SUBSEP k
				if (ak in ALIAS) {
					if (ALIAS[ak] != id) ALIAS[ak] = 0
					return
				}
				ALIAS[ak] = id
			}

			# The document and #anchor of one entry, normalised the way
			# --used-in, --supersession-sweep and --binding-driver all normalise
			# it - the leading ./ and any trailing / stripped - so all four modes
			# group on the same target. Change one, change all four.
			function docof(entry,   p, d) {
				p = index(entry, "#")
				d = (p > 0) ? substr(entry, 1, p - 1) : entry
				d = trim(d)
				sub(/^\.\//, "", d)
				sub(/\/+$/, "", d)
				return d
			}

			function ancof(entry,   p) {
				p = index(entry, "#")
				return (p > 0) ? substr(entry, p + 1) : ""
			}

			END {
				# GATED ON schemaVersion 3. Every claim in every finished corpus
				# is already cited into a plan, so a rule demanding a recorded
				# hash from each of them would turn every existing vault red on
				# the day the plugin updates - which is how a gate stops being
				# run. vault-migration.md carries the back-fill.
				if (schema + 0 < 3) {
					printf("cited-section drift is a schemaVersion 3 rule and this vault is at %s - `reconciled_sections` was added at 3, so no note here records what it read and there is nothing to compare a section against - %s\n", schema, vault)
					exit
				}

				for (i = 1; i <= nf; i++) {
					f = files[i]
					ty = V[f, "type"]
					# Only `claim` and `assumption`, and only where the note is
					# current. Invariant 20 is about a claim the prose has to
					# carry; a `fact` reaches the plan as an `[F#]` code that
					# resolves forward whatever the paragraph says, and a
					# retracted or superseded note is the strikethrough rule and
					# the supersession sweep respectively - reporting either
					# here would send its reader to the wrong fix.
					if (ty != "claim" && ty != "assumption") continue
					st = V[f, "status"]
					if (st != "" && st != "current") continue

					id = V[f, "id"]
					uk = f SUBSEP "used_in"
					rk = f SUBSEP "reconciled_sections"

					# What the note records, split once: the target it names and
					# the hash it recorded for it. Keys carry the note file, so
					# nothing has to be deleted between notes - `delete array`
					# without a subscript is an extension some awks have and
					# POSIX does not, and clearing an array by looping it is a
					# second walk over the same data.
					for (j = 1; j <= LN[rk]; j++) {
						it = LI[rk, j]
						sp = index(it, " ")
						tg = (sp == 0) ? it : substr(it, 1, sp - 1)
						tk = f SUBSEP docof(tg) SUBSEP ancof(tg)
						SEEN[tk] = 1
						REC[tk] = (sp == 0) ? "" : trim(substr(it, sp + 1))
					}

					for (j = 1; j <= LN[uk]; j++) {
						entry = LI[uk, j]
						doc = docof(entry)
						anc = ancof(entry)
						# A citation with no anchor names a whole document and
						# there is no section to hash. A missing document or a
						# dead anchor is --used-in verdict; reporting either
						# here would be the same failure under a name about
						# reconciliation.
						if (doc == "" || anc == "" || !(doc in EXISTS)) continue
						if (!(doc in SCANNED)) { SCANNED[doc] = 1; sections(doc) }
						ak = doc SUBSEP fold(anc)
						if (!((ak in ALIAS) && ALIAS[ak] > 0)) continue

						tk = f SUBSEP doc SUBSEP anc
						USED[tk] = 1
						# MEMOISED PER SECTION, NOT PER CITING NOTE. Several
						# claims legitimately cite one section, and the hash is
						# a byte-at-a-time walk over its whole body - recomputing
						# it per citation makes the cost O(citations) where the
						# answer only has O(sections) worth of distinct values in
						# it. Keyed the same way RAW is, beside it.
						bk = doc SUBSEP ALIAS[ak]
						if (!(bk in HASH)) HASH[bk] = shash(RAW[bk])
						now = HASH[bk]
						nchecked++
						if (!(tk in SEEN))
							report(f, "section-hash-missing", id,
								"`used_in` names `" entry "` and `reconciled_sections` records nothing for it. Nothing in the corpus says what that section said when this claim was reconciled against it, so a later rewrite of the block leaves the citation resolving and the claim standing on prose nobody has re-read - which is invariant 20 satisfied once and then quietly undone. Re-read the section and record it: `" entry " " now "`")
						else if (REC[tk] == "")
							report(f, "section-hash-missing", id,
								"`reconciled_sections` names `" entry "` with no hash after it, so the entry records that somebody looked and not what they saw - and a later rewrite of that block is then indistinguishable from no change at all. Record the hash: `" entry " " now "`")
						else if (REC[tk] != now)
							report(f, "section-hash-drifted", id,
								"`reconciled_sections` recorded `" REC[tk] "` for `" entry "` and that section now hashes to `" now "`. The heading is untouched, so `used_in` still resolves and every other check passes while the prose the claim stands on has been rewritten since anybody read it against this note. This is the failure invariant 20 exists to prevent, occurring after the invariant was satisfied once. Re-read the section: if the claim still holds, record `" entry " " now "` and move `reconciled:` to today; if it does not, the claim is what has to change")
					}

					# BOTH DIRECTIONS, for the reason --red-team checks its
					# roster both ways: an entry for a section this claim no
					# longer cites is a hash nothing compares, and it reads as
					# coverage to anybody counting entries against citations.
					for (j = 1; j <= LN[rk]; j++) {
						it = LI[rk, j]
						sp = index(it, " ")
						tg = (sp == 0) ? it : substr(it, 1, sp - 1)
						tk = f SUBSEP docof(tg) SUBSEP ancof(tg)
						if (tk in USED) continue
						if (tk in DONE) continue
						DONE[tk] = 1
						report(f, "section-hash-unused", id,
							"`reconciled_sections` names `" tg "` and `used_in` does not. The note records having read a section it no longer says it is cited into, so the entry is a hash nothing will ever compare - and to anybody checking that every citation has one, it reads as covered. Either restore the `used_in` entry or drop this one")
					}
				}

				if (nchecked == 0)
					printf("no current claim or assumption names a resolving document section under %s - there is nothing whose content a rewrite could drop, which is every vault before drafting cites one\n", vault)
				else
					printf("%d cited section%s hashed against the value the note recorded - %s\n",
						nchecked, (nchecked == 1 ? "" : "s"), vault)
			}
		' "$RECORDS")

	render_failures "vault-lint claim-drift" "$CD_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# pass 3 - the checks
#
# Reads the record stream plus the parse errors, and emits one failure per line:
#     file <TAB> check <TAB> id <TAB> detail
#
# Every message names what is wrong AND what it costs. The message is the
# product here - the person reading it is deciding whether to care, and a
# message that only restates the rule gives them nothing to decide with.
# ----------------------------------------------------------------------------

# `schema` is the version found in the vault's own config, passed in so a check
# added under a later schema can stay silent on a vault written before it. A
# corpus at 1 owes exactly the rules it was written under; failing it on a rule
# that did not exist when it was authored is an upgrade that breaks every
# existing vault, which is what schemaVersion exists to make unnecessary.
awk -v today="$TODAY" -v out="$FAILURES" -v hasvocab="$HAS_VOCAB" -v edgefields="$EDGE_FIELDS" -v pathidx="$PATHIDX" -v schema="$FOUND_SCHEMA" -F '\t' '
	BEGIN {
		BS = sprintf("%c", 92)

		while ((getline pl < pathidx) > 0) EXISTS[pl] = 1
		close(pathidx)

		common = "id type title status confidence created"
		req["source"]     = "url url_canonical pulled quote"
		req["fact"]       = "confidence_own rests_on"
		req["claim"]      = "confidence_own subject stale_after rests_on"
		req["assumption"] = "value sensitivity validated_by"
		req["question"]   = "gaps"
		# The decision-brief fields in references/decisions.md are deliberately
		# NOT required here: the decision note in vault.md is a valid decision
		# note without them, and a lint that fails the schema document own
		# worked example is a lint people switch off. They are checked for
		# COHERENCE instead - see the brief list below.
		req["decision"]   = "confidence_own options chosen reasoning reopen_if rests_on"

		# The type names, for the type-agreement message. Read off one string
		# rather than written into the message, so the set a milestone joins is
		# stated in one place and the message cannot go on naming six types
		# after a seventh is registered below.
		types = "source, fact, claim, assumption, question, decision"

		# THE ONE SCHEMA GATE IN THIS PASS, AND EVERY MILESTONE CHECK HANGS OFF
		# IT. A vault at 1 predates the type and has no milestones/ directory,
		# so registering the type there would turn `milestone` into a legitimate
		# value of `type` in a corpus whose schema never had it - and the check
		# that says so (type-agreement) is the only thing that would notice a
		# directory grown without the version being moved.
		if (schema + 0 >= 2) {
			req["milestone"] = "confidence_own sequence date_confidence moves resource rests_on"
			types = types ", milestone"
		}

		why["id"]             = "nothing can address this note, so every edge that was meant to point at it dangles"
		why["type"]           = "the directory, the ID prefix and the type field stop agreeing, and each consumer answers differently"
		why["title"]          = "a rendered document has nothing to show - the ID is a link target, not a label"
		why["status"]         = "a retracted assertion is indistinguishable from a live one"
		why["confidence"]     = "a hedge anywhere in the chain below this note has nowhere to surface"
		why["created"]        = "there is no way to tell a note written before a source was amended from one written after, which is the distinction a re-check runs on"
		why["url"]            = "the material cannot be found again"
		why["url_canonical"]  = "duplicate detection cannot see this source, so two researchers citing the same page read as two independent citations"
		why["pulled"]         = "there is no record of when the material was actually read, so nobody can tell whether it predates an amendment"
		why["quote"]          = "URLs rot and pages are silently edited - without the passage the note reads as sourced with nothing behind it"
		why["confidence_own"] = "the derived confidence has no input, so min(confidence_own, rests_on) cannot be checked and the stored value is unverifiable"
		why["rests_on"]       = "the note asserts something with no provenance, and it is precisely the note that gets cited without hesitation"
		why["subject"]        = "the claim can never collide with one that contradicts it, so a disagreement stays invisible to every query"
		why["stale_after"]    = "the claim has no declared shelf life, so nothing will ever flag it for re-checking"
		why["value"]          = "there is nothing specific enough to validate, so a validation step reports success whatever it finds"
		why["sensitivity"]    = "every unverified assumption looks equally urgent, so they all get deferred equally"
		why["validated_by"]   = "a permanent unverified belief that nothing is scheduled to revisit"
		why["gaps"]           = "the question is a topic rather than something researchable, and nothing says when it closes"
		why["options"]        = "the rejected set is unrecorded, and reading the rejected set is the entire reason to keep the note"
		why["chosen"]         = "the record says a fork was considered and not which way it went"
		why["reasoning"]      = "the decision cannot be re-evaluated when its basis moves"
		why["reopen_if"]      = "a decision with no trigger is indistinguishable from one nobody may revisit, so it gets filed rather than re-checked"
		why["sequence"]       = "nothing can order this item against another, so the two checks that read order - a prerequisite scheduled after the item needing it, and two items asserted concurrent on one resource - have no field to run on, and a roadmap with no order reads as a set of things that all happen at once"
		why["date_confidence"] = "a month the skill derived and a month the founder stated become the same string, and the derived one gets quoted back as a commitment nobody made"
		why["moves"]          = "the item moves no assumption anyone can name, and roadmap-sequencing.md Rule 1 files that as maintenance rather than as a roadmap item - the model then carries a dated change with no assumption row behind it, so the curve is decoration"
		why["resource"]       = "what the item consumes is unrecorded, so two items competing for the same founder-week read as independent and the plan credits both"

		# The decision-brief fields below are not in any req[] entry - no type
		# requires them - but they share this table because the question it
		# answers is the same one: what does the absence of this field cost.
		# Reached from the decision-brief check rather than from required-field.
		why["criteria"]           = "there is nothing to compare the choice against, so the values-congruence check - the one signal that catches a wrong recommendation - can never be run"
		why["criteria_ranked_by"] = "a skill-ranked list reads later as the ranking the founder gave, and the recommendation then agrees with those criteria by construction"
		why["option_evidence"]    = "the evidence sits on the decision as a whole, so a column that was well sourced and a column with nothing behind it are indistinguishable"
		why["do_nothing"]         = "the mandatory status-quo column stops being mechanically checkable, and a grid that quietly dropped it presented the decision as already made"
		why["founder_reasoning"]  = "the record reads six months later as a choice made on analysis, and the constraint that actually drove it - I do not want to owe anyone money - is gone, unrecoverable, and was the reason the decision was right"
		why["likelihood"]         = "the probability survives only in a hedged verb that fuses it with confidence, so a thin lean and a well-evidenced coin flip become the same sentence"
		why["likelihood_range"]   = "the band term drifts between readers far enough to justify different choices, and neither reader learns they disagreed"
		why["evidence_grade"]     = "the register of the recommendation is set by how the author felt about the call rather than by the evidence"

		# The verdict fields, reached from the verdict check rather than from
		# required-field: no type requires them, and the question the table
		# answers is the same one - what the absence of this field costs.
		why["binding_driver"]  = "the two counts beside it are over nothing in particular, because distinct sources under the verdict is most of the corpus while distinct sources under the driver that binds is a number worth printing - and the binding driver moves, so this is also the record of which driver the stored counts were taken under"
		why["driver_kind"]     = "nothing downstream can tell a constraint the founder chose from one the category sets, so a policy-bound verdict renders at the same confidence letter as a structural one and the founder is talked out of something they could revisit this week"
		why["conditional_on"]  = "the policy variable the verdict is conditional on exists only inside a sentence, so a rendered section that dropped it reads exactly like one that kept it - and only one of the two is true"
		why["evidence_n"]      = "the corpus knows how thin the tail is and the rendered figure does not say so, because confidence is a letter about the weakest link and says nothing about how many links there are"
		why["evidence_counterparties"] = "three deals from one counterparty is the terms of one relationship reported as the terms of a market, and this is the half that cannot be recovered from anything else the corpus records - two write-ups of one party genuinely are two documents with two canonical URLs"

		# What a brief-backed decision note owes, from the field table in
		# references/decisions.md. Keep this list and the trigger split below in
		# sync with that table required column: a field added there, or moved
		# between required and conditional, has to be added or moved here.
		#
		# Presence cannot be required of every decision note, because only a
		# GUIDED fork produces a brief - a direct-posture founder who simply
		# decided writes a decision note carrying none of these, which is
		# exactly vault.md worked example. What CAN be required is coherence:
		# carry one and you owe the rest.
		#
		# `notrigger` marks the members that never themselves demand the rest.
		# Only the option-grid fields trigger, because each is meaningless
		# alone: ranked criteria with no evidence per option, or a likelihood
		# with no evidence grade, is half a brief. `founder_reasoning` is the
		# opposite - a verbatim record of what the founder said is worth having
		# on any decision note, so a note migrated out of older prose can
		# legitimately preserve it and carry nothing else. Triggering on it
		# would fail that note, and the cheapest way to green would be deleting
		# the verbatim words, which is the exact loss the field was split out of
		# `reasoning` to prevent.
		#
		# Absent from the list entirely, on the same reasoning: `assumptions_low`,
		# which decisions.md marks required only when any exist and which names
		# load-bearing beliefs worth recording on any decision, and the review
		# fields (reaffirmed, reviewed, what_happened, was_the_reasoning_right,
		# review_note), which record what happened to a decision afterwards -
		# something a decision with no brief behind it goes through the same.
		brief = "criteria criteria_ranked_by option_evidence do_nothing founder_reasoning likelihood likelihood_range evidence_grade"
		nbrief = split(brief, brieff, " ")
		notrigger["founder_reasoning"] = 1

		# What a target verdict owes, from the verdict block in vault.md. The
		# first four are owed outright; `conditional_on` sits last in the list
		# and is owed on top of them exactly when `driver_kind` is one of the
		# two policy values, which `condonly` marks - a structural verdict has
		# no choice to name, and a rule demanding a condition from every verdict
		# would be met by inventing one. Marking the exception the way the
		# decision brief marks `notrigger` next door keeps one list and one
		# walk. Keep this list and both triggers below in sync with that block,
		# and with the copy in the --binding-driver pass, which counts the same
		# five: a field added there has to be added in both places.
		verdict = "binding_driver driver_kind evidence_n evidence_counterparties conditional_on"
		nverdict = split(verdict, verdictf, " ")
		condonly["conditional_on"] = 1

		# THE FIVE FIELDS HANG OFF THE SUBJECT RATHER THAN THE TYPE, because
		# one verdict is filed under both types inside a single engagement -
		# an `assumption` before the research that settles it and a `claim`
		# after. A rule keyed to `type: claim` would exempt every verdict
		# written before the research came back, which is every verdict at the
		# point where a wrong one is cheapest to fix.
		#
		# THE TWO SUBJECTS TRIGGER DIFFERENTLY AND THAT IS THE DESIGN.
		# `target-verdict` is a term this release introduces, so no note in any
		# existing corpus carries it: the four fields are owed there whatever
		# the note carries, including nothing. `steady-state-ceiling` is
		# required and predates its amendment, so every existing vault already
		# holds one: there the trigger is field PRESENCE, which is the
		# exemption a version would otherwise have to buy. Extending the
		# leniency to the verdict half would spend that exemption over an empty
		# population and make omitting `binding_driver` the cheapest way past
		# every rule that reads it - and a dodge available by omission is not
		# an exemption, which is why --red-team checks its roster both ways.
		vsubject["target-verdict"] = 1
		vsubject["steady-state-ceiling"] = 1

		# The closed driver_kind word list, duplicated in the --binding-driver
		# pass, which owns the four rules that read a document. Each awk
		# program is a separate process and cannot call the other. Change one,
		# change both.
		nkind = split("structural policy policy-within-band", kindw, " ")
		for (ki = 1; ki <= nkind; ki++) knownkind[kindw[ki]] = 1
		condkind["policy"] = 1
		condkind["policy-within-band"] = 1

		# The closed `model_input` word list, on the same terms as driver_kind
		# above: two words, unquoted, and a third is not a value. Closing it is
		# what makes --assumption-rows a check rather than a hint - the field is
		# what says a note is an input to the projection, so an unrecognised
		# value is a note that declares nothing while reading as declared, and
		# the row it owes is then never asked for. A typo is indistinguishable
		# from a deliberate omission, which is the exemption-by-misspelling this
		# refuses. Read here rather than in --assumption-rows because it needs
		# nothing but the note, which is what keeps it in the pass that runs on
		# every bare invocation.
		nminput = split("revenue cost", minputw, " ")
		for (ki = 1; ki <= nminput; ki++) knownminput[minputw[ki]] = 1

		nedge = split(edgefields, edgef, " ")
		rank["L"] = 1; rank["M"] = 2; rank["H"] = 3
		name[1] = "L"; name[2] = "M"; name[3] = "H"
	}

	# Duplicated in the graph pass above - see the note there.
	function isid(s) { return (s ~ /^(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)-[A-Za-z0-9]+$/) }

	# Case and separator drift, collapsed. This is the whole of step 3, and the
	# reason step 3 exists: it catches the most common near-miss for the cost of
	# one pass per term, where an edit-distance routine in shell would be a
	# nested loop per candidate pair over the entire vocabulary.
	function nrm(s,   t, i, c, o) {
		t = tolower(s); o = ""
		for (i = 1; i <= length(t); i++) {
			c = substr(t, i, 1)
			if (c ~ /[a-z0-9]/) o = o c
		}
		return o
	}

	function cpl(a, b,   i, n, m) {
		n = length(a); m = length(b)
		if (m < n) n = m
		for (i = 1; i <= n; i++) if (substr(a, i, 1) != substr(b, i, 1)) return i - 1
		return n
	}

	function target_of(item) {
		return (index(item, " :: ") > 0) ? substr(item, index(item, " :: ") + 4) : item
	}

	function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

	function present(f, k) { return (V[f, k] != "" || LN[f SUBSEP k] > 0) }

	$1 == "T" { terms[++nterm] = $2; isterm[$2] = 1; required[$2] = $3; next }
	$1 == "A" { aliases[++nalias] = $2; aliasof[$2] = $3; next }
	$1 == "N" { files[++nf] = $2; DIR[$2] = $3; BASE[$2] = $4; next }
	$1 == "S" { V[$2, $3] = $4; next }
	$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }
	# A file that never parsed as a note has no fields to be missing. Marking it
	# suppresses the derived required-field and type-agreement failures below, so
	# the one message that matters - this is not a note - is not buried under six
	# consequences of it. A reviewer who reads ten derived failures stops reading.
	$1 == "E" { pe[++npe] = $2 SUBSEP $3 SUBSEP $4; if ($3 == "frontmatter") broken[$2] = 1; next }

	END {
		for (i = 1; i <= nf; i++) {
			f = files[i]
			id = V[f, "id"]
			if (id == "") continue
			if (id in BYID)
				report(f, "duplicate-id", id, "ID " id " is also carried by " BYID[id] ". An ID is an address - two notes at one address means every edge pointing there resolves to whichever file a reader happened to open, and no query can tell them apart")
			else
				BYID[id] = f
		}

		# Parse errors, now with an ID attached where the note had one.
		for (i = 1; i <= npe; i++) {
			split(pe[i], p, SUBSEP)
			report(p[1], p[2], V[p[1], "id"], p[3])
		}

		if (hasvocab != "1")
			report("_vocab.yml", "missing-vocabulary", "", "the vault has no _vocab.yml, so no subject can be checked against anything. Free-text subjects are the same as no subjects: two researchers write wtp and willingness-to-pay for the same thing, and the collision that would have surfaced their disagreement never happens")

		# Normalised candidates, precomputed once. Terms take precedence over
		# aliases so a subject that normalises onto both is reported against the
		# canonical key.
		for (i = 1; i <= nterm; i++) {
			ncand++
			canon[ncand] = terms[i]; cnorm[ncand] = nrm(terms[i])
			if (!(cnorm[ncand] in normto)) normto[cnorm[ncand]] = terms[i]
		}
		for (i = 1; i <= nalias; i++) {
			ncand++
			canon[ncand] = aliasof[aliases[i]]; cnorm[ncand] = nrm(aliases[i])
			if (!(cnorm[ncand] in normto)) normto[cnorm[ncand]] = aliasof[aliases[i]]
		}

		for (i = 1; i <= nf; i++) {
			f = files[i]
			id = V[f, "id"]
			ty = V[f, "type"]

			if (!(f in broken)) {
				# --- required fields per type -----------------------------
				nreq = split(common (ty in req ? " " req[ty] : ""), rf, " ")
				for (j = 1; j <= nreq; j++) {
					if (present(f, rf[j])) continue
					report(f, "required-field", id, "missing required field `" rf[j] "`" (ty != "" ? " on a " ty " note" : "") " - " (rf[j] in why ? why[rf[j]] : "the schema requires it") ". A half-filled note makes later queries return false negatives that read as clean")
				}

				# --- a decision brief is all of its fields or none of them -
				# An option-grid field is what says a brief stands behind this
				# record; from there the rest are owed, including
				# founder_reasoning, which a brief owes without ever being what
				# demands one. The note carrying a grid and a recommendation
				# and no founder_reasoning is the one this exists for - it
				# reads as complete to every consumer, and nothing else in the
				# corpus can tell that it is not.
				#
				# One report per missing field, same as required-field above:
				# eight costs concatenated into a single message is a paragraph
				# nobody reads to the end.
				if (ty == "decision") {
					carried = ""; ncarried = 0; ntrig = 0
					for (b = 1; b <= nbrief; b++) {
						if (!present(f, brieff[b])) continue
						carried = carried (ncarried++ ? ", " : "") "`" brieff[b] "`"
						if (!(brieff[b] in notrigger)) ntrig++
					}
					for (b = 1; ntrig > 0 && b <= nbrief; b++) {
						bf = brieff[b]
						if (present(f, bf)) continue
						report(f, "decision-brief-incomplete", id, "carries the decision-brief field" (ncarried > 1 ? "s" : "") " " carried " but not `" bf "`. A decision note carrying none of the option-grid fields is a founder who simply decided, and is correct as written - only a guided fork produces a brief. One carrying some of them is a brief-backed decision that lost a field, and it reads as complete to every consumer while the missing part answers nothing. Without " bf ", " why[bf])
					}
				}

				# --- a verdict owes its fields as a set, and its kind is ---
				# --- one of three words -----------------------------------
				# The same shape as the decision brief above, one type over
				# and keyed on the subject rather than on the type: a note
				# carrying some of them reads complete to every consumer,
				# while the missing field is precisely the one that would
				# have qualified the number. A verdict naming its driver and
				# labelling it `policy` with no counts is a fully qualified
				# finding to every reader and to every tool, and what it is
				# not saying is that the two deals underneath it came from
				# one counterparty.
				#
				# One report per missing field, same as required-field and
				# the decision brief: four costs concatenated into a single
				# message is a paragraph nobody reads to the end.
				#
				# The four rules that need business-plan.md are
				# --binding-driver, not here. These two read nothing but the
				# note, which is what keeps them in the pass that runs on
				# every bare invocation.
				if ((ty == "claim" || ty == "assumption") && (V[f, "subject"] in vsubject)) {
					vsj = V[f, "subject"]
					vcar = ""; nvcar = 0
					for (b = 1; b <= nverdict; b++) {
						if (!present(f, verdictf[b])) continue
						vcar = vcar (nvcar++ ? ", " : "") "`" verdictf[b] "`"
					}
					dk = V[f, "driver_kind"]

					if (vsj == "target-verdict")
						vwhy = "A target verdict owes them whatever else it carries: the subject is a term this release introduces, so no note written before the fields existed can be exempted by omitting one - and omission would otherwise be the cheapest way past every rule that reads them."
					else
						vwhy = "A ceiling claim carrying none of the five owes none of them, which is what exempts every claim written before the fields existed; carrying one makes the rest owed, because a note carrying some of them reads complete to every consumer while the missing part is the one that would have qualified the number."

					if (vsj == "target-verdict" || nvcar > 0) {
						for (b = 1; b <= nverdict; b++) {
							bf = verdictf[b]
							# `conditional_on` is owed only where the kind
							# makes it owed. Demanding it of a structural
							# verdict would be met by inventing a condition,
							# which is worse than the omission because an
							# invented one renders.
							if ((bf in condonly) && !(dk in condkind)) continue
							if (present(f, bf)) continue
							if (nvcar > 0)
								vhead = "carries the verdict field" (nvcar > 1 ? "s" : "") " " vcar " but not `" bf "`"
							else
								vhead = "carries `subject: target-verdict` and none of the fields a verdict owes outright, `" bf "` among them"
							report(f, "verdict-fields-incomplete", id, vhead ". " vwhy " Without `" bf "`, " why[bf])
						}
					}

					# A fourth word is a classification no downstream rule
					# knows how to read, so it takes the structural path by
					# default and buys exactly the exemption invariant 18
					# exists to refuse - with a typo indistinguishable from a
					# deliberate call.
					if (dk != "" && !(dk in knownkind))
						report(f, "driver-kind-unknown", id, "`driver_kind` is `" dk "` and the enumeration is closed at `structural`, `policy` and `policy-within-band`. Everything downstream branches on policy or not - a policy-bound verdict owes a stated condition and a structural one does not - so an unrecognised value takes the structural path by default, which is the exemption invariant 18 exists to refuse. A typo is then indistinguishable from a deliberate classification, and the plan reports a decision the founder made as a category floor")
				}

				# --- the model-input word list is closed --------------------
				# The trigger is field presence and not the version, for the
				# reason `target-verdict` needs no version: `model_input` is a
				# term this release introduces, so no note in any existing
				# corpus carries it and there is no population an exemption
				# would protect. The rule that reads a document -
				# --assumption-rows - is gated on schemaVersion 3 because it
				# asks the TABLE for something too, and a vault before 3 has no
				# contract saying its rows are note titles.
				mi = V[f, "model_input"]
				if (mi != "" && !(mi in knownminput))
					report(f, "model-input-unknown", id, "`model_input` is `" mi "` and the enumeration is closed at `revenue` and `cost`. The field is what declares this note an input the projection has to carry a row for, and --assumption-rows reads exactly that - so an unrecognised value is a note that declares nothing while reading as declared, and the row it owes is never asked for. That is the same failure the field exists to fix, reintroduced by a typo: the input stays in the ledger, never enters the model, and every verdict downstream inherits a denominator missing it")

				# --- the type is stated three times and all three agree ----
				if (ty != "" && !(ty in req))
					report(f, "type-agreement", id, "type `" ty "` is not one of " types ". Structure that does not fit a type belongs on an edge, not in a new type" (ty == "milestone" ? ". `milestone` is a schemaVersion 2 type and this vault is stamped " schema ", so it does not carry one - move the corpus to 2 the way vault-migration.md describes, doing the work before stamping" : ""))
				if (ty in req && DIR[f] != ty "s")
					report(f, "type-agreement", id, "type is `" ty "` but the note sits in " DIR[f] "/ rather than " ty "s/. The filesystem sees only the directory, so a listing of " ty "s/ silently omits this note")
				if (id != "") {
					pfx = id
					sub(/-.*$/, "", pfx)
					if (ty != "" && pfx != toupper(ty))
						report(f, "type-agreement", id, "ID prefix `" pfx "` does not match type `" ty "`. A grep over IDs sees only the prefix, so those two consumers already answer differently")
					# Reported separately from type-agreement: vault.md keeps
					# these in two different sections, and a file renamed by
					# accident has nothing wrong with its type field. Fusing
					# them sends the reader to look at `type`.
					if (BASE[f] != id ".md")
						report(f, "filename-mismatch", id, "the filename is " BASE[f] " but the ID is " id ". The filename is meant to be exactly the ID plus .md, so that find-the-file-for-this-ID and grep-for-this-ID are the same operation - here they give two answers and one of them is wrong")
				}
			}

			# --- supersession is always two edits ---------------------------
			# vault.md states this as one invariant with two halves, and the
			# second half is the one that fails silently: a replacement with a
			# reason, over a target still marked current, leaves two live notes
			# asserting different values on the same subject - which reads to
			# both a checker and a human as an unresolved contradiction rather
			# than a completed supersession.
			if (LN[f SUBSEP "supersedes"] > 0) {
				if (V[f, "supersedes_reason"] == "")
					report(f, "supersedes-reason", id, "supersedes a note with no `supersedes_reason`. The only question anyone ever asks about a superseded note is why, and by the time it is asked the person who knew has gone")
				k = f SUBSEP "supersedes"
				for (j = 1; j <= LN[k]; j++) {
					tgt = LI[k, j]
					if (!(tgt in BYID)) continue
					if (V[BYID[tgt], "status"] != "superseded")
						report(f, "supersedes-status", id, "supersedes " tgt ", but that note is still `status: " V[BYID[tgt], "status"] "` rather than `superseded`. Supersession is two edits and only one was made, so both notes now read as live and the pair is indistinguishable from an unresolved contradiction")
				}
			}

			# --- the two roadmap order rules, at schemaVersion 2 -----------
			# roadmap-sequencing.md asserts both in prose and nothing has ever
			# read them. That is what makes them worth a check rather than a
			# paragraph: a roadmap is a set of claims about when the inputs
			# to the model change, so an order nobody verified sets the month
			# every downstream number is dated to.
			#
			# `moves` naming a note that does not exist is deliberately NOT
			# here - `moves` is in EDGE_FIELDS, so it is the dangling-edge rule
			# every other edge already gets, for one word, and a `moves` value
			# that is not a note ID at all is the malformed-edge rule in the
			# same loop.
			if (schema + 0 >= 2 && ty == "milestone") {
				sq = V[f, "sequence"]

				# The orderability of `sequence` is checked before anything
				# reads it, because both checks below silently skip a value
				# they cannot compare - and a check that stops firing prints
				# the same green as one that passed.
				if (sq != "" && sq !~ /^[0-9]+$/)
					report(f, "sequence-not-orderable", id, "`sequence` is `" sq "`, which is not a whole number. Ordering is what `sequence` is for - the date the founder said is kept verbatim in `date_stated` precisely so nothing has to parse it - and a value that will not compare takes both order checks down with it, silently, over exactly the roadmap whose order nobody wrote down")

				k = f SUBSEP "depends_on"
				for (j = 1; j <= LN[k]; j++) {
					tgt = LI[k, j]
					# A dangling target is already a dangling-edge failure and
					# an unorderable one is already reported on its own note.
					# Reporting either again here would send the reader to the
					# wrong field.
					if (!(tgt in BYID)) continue
					tsq = V[BYID[tgt], "sequence"]
					if (sq !~ /^[0-9]+$/ || tsq !~ /^[0-9]+$/) continue
					if (tsq + 0 >= sq + 0)
						report(f, "dependency-after-dependent", id, "`depends_on` names " tgt ", whose `sequence` is " tsq ", while the `sequence` here is " sq ". The prerequisite is scheduled at or after the item that needs it, so the roadmap projects a capability landing in a month its own precondition has not reached - and because every item is a dated change to an assumption row, the model credits that month with revenue nothing could have shipped in")
				}

				# roadmap-sequencing.md Rule 4 - the rule it says most often
				# changes the answer and is the one people skip. Collected
				# here and reported after the loop, because the failure is a
				# property of a GROUP and neither member is the wrong one.
				if (V[f, "resource"] != "" && sq != "") {
					rk = V[f, "resource"] SUBSEP sq
					CONC[rk, ++CN[rk]] = f
				}
			}

			# --- edges resolve to real notes --------------------------------
			for (e = 1; e <= nedge; e++) {
				k = f SUBSEP edgef[e]
				for (j = 1; j <= LN[k]; j++) {
					item = LI[k, j]
					tgt = target_of(item)
					if (isid(tgt)) {
						if (!(tgt in BYID))
							report(f, "dangling-edge", id, "`" edgef[e] "` points at " tgt ", which no note in this vault carries. A dangling edge silently shrinks every blast radius that runs through it - the query returns a clean, short answer rather than an error")
					} else if (edgef[e] == "rests_on") {
						# A different failure from a dangling edge, and it wants
						# a different fix: nothing is missing from the vault,
						# the field never named a note in the first place.
						report(f, "malformed-edge", id, "`rests_on` holds `" item "`, which is not a note ID. rests_on is the blast-radius edge and has to name notes, or the chain from an amended source to the documents that inherited it stops here")
					} else if (edgef[e] == "moves") {
						# Same structural failure as rests_on above and a
						# different cost, so a different message. The two are
						# written out rather than folded into one generic
						# sentence because a reader who is told only that the
						# value is not an ID still has to work out what it cost
						# on the field they wrote.
						#
						# This is the half of `moves` the dangling-edge rule
						# cannot reach. A value that IS a well-formed ID naming
						# no note is dangling-edge; a value that is not an ID at
						# all fell through this arm and passed clean. And it is
						# the EXPECTED mis-write rather than a hypothetical one:
						# roadmap-sequencing.md Rule 1 names the assumption an
						# item moves by its `A-n` row label, so the form an
						# author writes after reading the prose was the one form
						# nothing caught.
						report(f, "malformed-edge", id, "`moves` holds `" item "`, which is not a note ID. An `A-n` row label off the assumptions table in the plan is what usually lands here, and the ledger cannot resolve a label to a note - so the item reads as naming the assumption it moves while naming nothing this vault holds, and the one check that makes roadmap-sequencing.md Rule 1 mechanical passes over the exact form authors write. Put the note ID of that assumption here; the table in the plan keeps its `A-n` label in prose")
					}
				}
			}

			# --- confidence propagates -------------------------------------
			if (LN[f SUBSEP "rests_on"] > 0 && (V[f, "confidence"] in rank)) {
				own = V[f, "confidence_own"]
				if (!(own in rank)) own = V[f, "confidence"]
				derived = rank[own]
				weakest = "its own confidence_own of " own
				k = f SUBSEP "rests_on"
				for (j = 1; j <= LN[k]; j++) {
					tgt = LI[k, j]
					if (!(tgt in BYID)) continue
					dc = V[BYID[tgt], "confidence"]
					if (!(dc in rank)) continue
					if (rank[dc] < derived) { derived = rank[dc]; weakest = tgt ", which is " dc }
				}
				if (rank[V[f, "confidence"]] > derived)
					report(f, "confidence-propagation", id, "stored confidence is " V[f, "confidence"] " but min(confidence_own, every rests_on target) is " name[derived] ", set by " weakest ". Without min, a hedged source becomes a fairly confident fact becomes a flat claim - every step locally reasonable, and by the third hop the hedge a stranger needed is gone")
			}

			# --- subject resolution: five steps, first match wins -----------
			if (ty == "claim" && V[f, "subject"] != "" && nterm > 0) {
				s = V[f, "subject"]
				if (s in isterm) {
					seen[s]++
				} else if (s in aliasof) {
					report(f, "near-miss-subject", id, "subject `" s "` is an alias of `" aliasof[s] "`, not a vocabulary key. Store the canonical key: `" s "` and `" aliasof[s] "` never collide, so two claims that disagree stay in agreement as far as any query can tell")
				} else {
					ns = nrm(s)
					if (ns in normto) {
						report(f, "near-miss-subject", id, "subject `" s "` differs from the key `" normto[ns] "` only in case or separators. Drift like this never collides, so the contradiction the subject exists to surface stays hidden")
					} else {
						best = ""; bestlen = 0
						for (c = 1; c <= ncand; c++) {
							cn = cnorm[c]
							if (cn == "" || ns == "") continue
							if (index(ns, cn) > 0 || index(cn, ns) > 0) {
								if (length(cn) > bestlen) { bestlen = length(cn); best = canon[c] }
							} else if (cpl(ns, cn) >= 5 && cpl(ns, cn) > bestlen) {
								bestlen = cpl(ns, cn); best = canon[c]
							}
						}
						if (best != "")
							report(f, "near-miss-subject", id, "subject `" s "` is not a vocabulary key, but it overlaps `" best "`. If it means the same thing, use the key - a near-miss never collides and so never surfaces a contradiction. If it is genuinely a new subject, add it to _vocab.yml with a definition saying what it excludes")
						else
							report(f, "unknown-subject", id, "subject `" s "` matches no vocabulary key and no alias. A term nobody declared cannot collide with anything, and an unresolved contradiction and a corpus with no contradictions look identical")
					}
				}
			}

			# --- a claim past its declared shelf life ----------------------
			if (ty == "claim" && V[f, "stale_after"] != "" &&
			    (V[f, "stale_after"] "") < (today "") &&
			    V[f, "status"] != "superseded" && V[f, "status"] != "retracted")
				report(f, "stale-claim", id, "stale_after is " V[f, "stale_after"] " and today is " today ", with status still `" V[f, "status"] "`. The claim is past the shelf life its own author declared, so everything resting on it is standing on a value nobody has re-checked" (LN[f SUBSEP "used_in"] > 0 ? " - used_in names the documents carrying it" : ""))

			# --- duplicate sources, collected ------------------------------
			if (ty == "source" && V[f, "url_canonical"] != "") {
				u = V[f, "url_canonical"]
				URLMEM[u, ++URLN[u]] = f
			}

			# --- vault-relative source paths that resolve to nothing --------
			# A source with no public URL carries a vault-relative path. That
			# is indistinguishable from a path pointing outside the vault, and
			# a missing file is not a malformed field - so without this check
			# the note passes every other test while its evidence is absent.
			# Anything carrying a scheme or a `host:`/`prefix:` marker is
			# deliberately not vault-relative and is skipped.
			if (ty == "source" && V[f, "url"] != "" && V[f, "url"] !~ /:/) {
				lp = V[f, "url"]
				sub(/\/+$/, "", lp)
				if (lp != "" && !(lp in EXISTS))
					report(f, "unresolved-local-source", id, "url `" V[f, "url"] "` has no scheme, so it reads as vault-relative - and nothing exists at that path inside the vault. Either the file belongs in the vault, or the path points outside it and needs a marker (`slug:research/file.md`) so it is not read as vault-relative. A missing file is not a malformed field, so every other check passes while the evidence is absent")
			}

			k = f SUBSEP "rests_on"
			for (j = 1; j <= LN[k]; j++) restedon[LI[k, j]] = 1
		}

		# Reported against every member of the group, not just the first one
		# seen. Both notes are equally implicated, and a reader who greps the
		# output for one filename has to find it there - attaching the whole
		# group to whichever file sorted first hides the duplicate from exactly
		# the person looking at the other one.
		for (u in URLN) {
			if (URLN[u] < 2) continue
			others = ""
			for (j = 1; j <= URLN[u]; j++) others = others (j == 1 ? "" : ", ") URLMEM[u, j]
			for (j = 1; j <= URLN[u]; j++)
				report(URLMEM[u, j], "duplicate-url", V[URLMEM[u, j], "id"], "url_canonical " u " is carried by " URLN[u] " source notes: " others ". A claim resting on two of them looks doubly sourced when it rests on one document - which is what one newsletter link carrying tracking parameters and one search result turn into")
		}

		# Two milestones sharing a `resource` AND a `sequence` are asserted
		# concurrent on one constrained resource. roadmap-sequencing.md Rule 4
		# says they only compete if they consume the same one - so this is that
		# rule read off the ledger instead of trusted, and a FALSE independence
		# claim is what it catches: the naive value ranking it licenses orders
		# the whole roadmap, and nothing downstream ever revisits it.
		#
		# Reported against every member of the group for the reason duplicate-url
		# is: neither item is the wrong one, and a reader who opens the other
		# file has to find the failure there too. Grouped and iterated exactly
		# the way duplicate-url is, unordered - render_failures sorts the whole
		# failure file before anything prints it, so the order rows are emitted
		# in cannot reach the output.
		for (rk in CN) {
			if (CN[rk] < 2) continue
			split(rk, rkp, SUBSEP)
			others = ""
			for (j = 1; j <= CN[rk]; j++) others = others (j == 1 ? "" : ", ") V[CONC[rk, j], "id"]
			for (j = 1; j <= CN[rk]; j++)
				report(CONC[rk, j], "false-independence", V[CONC[rk, j], "id"], CN[rk] " milestones declare `resource: " rkp[1] "` at `sequence: " rkp[2] "`: " others ". Items competing for one constrained resource cannot be asserted concurrent, so at least one of them is not happening in that slot. Give them distinct sequences, or name the resource each actually consumes - left as is, the plan reads as though both land and every number downstream inherits a week of capacity that was counted twice")
		}

		for (i = 1; i <= nf; i++) {
			f = files[i]
			if (V[f, "type"] != "source") continue
			id = V[f, "id"]
			if (id == "" || (id in restedon)) continue
			report(f, "orphan-source", id, "nothing in the vault rests on this source. Either the research was read and never used, or something that should have cited it cited nothing - both are worth one look, and neither is visible from inside the note")
		}

		for (i = 1; i <= nterm; i++) {
			t = terms[i]
			if (required[t] != "true" || seen[t] > 0) continue
			report("_vocab.yml", "coverage-gap", "", "no claim carries the required subject `" t "`. The note schema cannot catch a thin spine, because you cannot type a fact nobody wrote - a required subject with no claim under it is an omission every document downstream inherits in silence")
		}
	}
' "$RECORDS"

# ----------------------------------------------------------------------------
# render
# ----------------------------------------------------------------------------

# What the bare run did NOT ask, read off the mode table rather than written
# out a second time. A mode added to the gate would otherwise leave this line
# silently understating what it skipped, which is the same hand-maintained
# enumeration the table exists to remove. `check` is excluded because it is the
# mode printing the line.
SKIPPED=""
while read -r sel gate part; do
	[ "$gate" = "gate" ] || continue
	[ "$sel" = "check" ] && continue
	SKIPPED="${SKIPPED:+$SKIPPED, }$part"
done <<EOF
$MODE_TABLE
EOF

render_failures "vault-lint" "note-level checks passed - $VAULT. Not opened: $SKIPPED - --release-gate asks all of them."
