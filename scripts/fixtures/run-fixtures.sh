#!/bin/sh
#
# run-fixtures.sh - assert vault-lint.sh still fires the checks it claims to.
#
#   scripts/fixtures/run-fixtures.sh
#
# This is a contributor tool, not shipped tooling, but it is written to the same
# constraint as the script it tests: POSIX shell, zero dependencies, no test
# framework. Run it from anywhere. The fixtures stay under scripts/ while the
# script under test lives in bin/, because bin/ is put on the agent's PATH when
# the plugin is enabled - test corpora do not belong on a user's PATH.
#
# WHY THIS EXISTS
# Without it, `scripts/fixtures/` is documentation. Every violating note says
# "Violates: <check>" in its body, and nothing verifies the claim - so a change
# to, say, the near-miss prefix length can silently stop firing on
# CLAIM-NEAR0004 and the only thing that turns red is a human comparing thirty
# lines of output against twenty prose comments. A lint whose own regressions
# are invisible is exactly the shape of failure the vault schema exists to
# prevent, reintroduced one level up.
#
# WHAT IT ASSERTS
#   1. The clean vault reports nothing and exits 0.
#   2. The violating vault fires every check in EXPECTED below, and exits 1.
#   3. --used-in resolves every target in the clean vault and fires both of its
#      checks in the violating one, on both sides and both exit codes.
#   4. Both JSON outputs are well-formed enough to slice by field.
#   5. The two refusal paths refuse, and exit 2.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
LINT="$HERE/../../bin/vault-lint.sh"
[ -x "$LINT" ] || { printf 'run-fixtures: %s is not executable\n' "$LINT" >&2; exit 2; }

# Every check the violating vault is built to trigger. A check that stops firing
# and a check that was deleted look identical from the outside, so this list is
# the thing that has to be edited deliberately when either happens.
EXPECTED="ambiguous-value block-scalar-field confidence-propagation coverage-gap
dangling-edge decision-brief-incomplete duplicate-id duplicate-url
filename-mismatch folded-scalar frontmatter inline-flow-list malformed-edge
near-miss-subject null-value orphan-source required-field stale-claim
supersedes-reason supersedes-status type-agreement unknown-subject
unparsed-line"

PASS=0
FAIL=0

PAIRS_FILE=$(mktemp "${TMPDIR:-/tmp}/run-fixtures.XXXXXX") || exit 2
trap 'rm -f "$PAIRS_FILE" "$PAIRS_FILE".*' EXIT
trap 'rm -f "$PAIRS_FILE" "$PAIRS_FILE".*; exit 2' HUP INT TERM

ok() {
	PASS=$((PASS + 1))
	printf '  ok    %s\n' "$1"
}

no() {
	FAIL=$((FAIL + 1))
	printf '  FAIL  %s\n' "$1" >&2
}

# Run the lint and report its exit status without tripping set -u or aborting.
# The optional second argument is a mode flag, so a mode's exit code - which is
# half of what a verdict mode promises - is asserted the same way as `check`'s.
run_status() {
	"$LINT" ${2:+"$2"} --vault "$1" >/dev/null 2>&1
	printf '%s\n' "$?"
}

printf 'run-fixtures: %s\n\n' "$LINT"

# --- 1. the clean vault passes ----------------------------------------------
printf 'clean vault\n'
CLEAN_OUT=$("$LINT" --vault "$HERE/clean" 2>&1)
CLEAN_STATUS=$(run_status "$HERE/clean")
[ "$CLEAN_STATUS" = "0" ] && ok "exits 0" || no "exits 0 (got $CLEAN_STATUS)"
case "$CLEAN_OUT" in
*clean*) ok "reports clean" ;;
*) no "reports clean (got: $CLEAN_OUT)" ;;
esac

# The clean vault is also where correct parsing is asserted. A parser that
# returned the literal | for a block scalar would leave `quote` non-empty and
# pass the required-field check, so the only way to see the bug is to read the
# value back - which is what graph prints.
GRAPH=$("$LINT" graph SOURCE-K92MZ1QA --vault "$HERE/clean" --depth 1 2>&1)
case "$GRAPH" in
*"quote: Pre-packaged goods sold direct to consumers"*) ok "block scalar returns its body, not the literal |" ;;
*) no "block scalar body missing from graph output" ;;
esac
case "$GRAPH" in
*'quote: |'*) no "block scalar returned the literal | - the bug this design exists to prevent" ;;
*) ok "block scalar is not the literal |" ;;
esac

# Escaped quotes inside a double-quoted scalar have to survive the unquote.
UNVER=$("$LINT" --unverified --vault "$HERE/clean" 2>&1)
case "$UNVER" in
*'a "nice to have"'*) ok "embedded quotes unescape" ;;
*) no "embedded quotes did not unescape" ;;
esac
case "$UNVER" in
*'\"nice'*) no "embedded quotes kept their backslashes" ;;
*) ok "no stray backslashes in unquoted text" ;;
esac

# --- 2. the violating vault fires every check --------------------------------
printf '\nviolating vault\n'
VIOL_STATUS=$(run_status "$HERE/violations")
[ "$VIOL_STATUS" = "1" ] && ok "exits 1" || no "exits 1 (got $VIOL_STATUS)"

# Captured once and sliced three ways below. The lint is deterministic for a
# given vault, so re-invoking it per assertion buys nothing and costs a full
# re-parse of every fixture note each time.
VJSON=$("$LINT" --vault "$HERE/violations" --json 2>/dev/null)

# The same document from the separate mode. EXPECTED and FIRED below stay the
# `check` census and deliberately do not merge it - `check` and `--used-in` are
# separate modes and a check name that moved between them should turn something
# red. The per-file `Violates:` contract in 2b is the opposite case: it is a
# promise made by one note about one check, and which mode reports it is not the
# note's business, so that assertion reads both documents.
UJSON=$("$LINT" --used-in --vault "$HERE/violations" --json 2>/dev/null)
UI_VIOL_STATUS=$?

FIRED=$(printf '%s\n' "$VJSON" |
	awk -F'"check": "' 'NF > 1 { split($2, a, "\""); print a[1] }' |
	LC_ALL=C sort -u)

# Iterated by reading lines rather than by unquoted word splitting: zsh does not
# word-split unquoted expansions, so a `for x in $LIST` here silently collapses
# to one iteration and the suite reports a handful of passes instead of running.
printf '%s\n' "$EXPECTED" | tr ' ' '\n' | grep -v '^$' >"$PAIRS_FILE.want"
while read -r want; do
	[ -n "${want:-}" ] || continue
	if printf '%s\n' "$FIRED" | grep -q "^$want\$"; then
		ok "fires $want"
	else
		no "never fired $want"
	fi
done <"$PAIRS_FILE.want"

# A check firing that nothing expects is also a regression - either a new check
# landed without being listed here, or one is firing where it should not.
printf '%s\n' "$FIRED" >"$PAIRS_FILE.got"
while read -r got; do
	[ -n "${got:-}" ] || continue
	case " $(printf '%s' "$EXPECTED" | tr '\n' ' ') " in
	*" $got "*) ;;
	*) no "fired $got, which EXPECTED does not list" ;;
	esac
done <"$PAIRS_FILE.got"

# --- 2b. per-file, which is the assertion that has teeth ---------------------
# Asserting only that a check name appears somewhere lets a whole branch die
# unnoticed: break step 4 of the near-miss order and `near-miss-subject` still
# fires from steps 2 and 3, so the corpus-wide assertion stays green over a
# resolution order that has stopped resolving. Every violating note declares its
# own checks on a `Violates:` line, and each is asserted against that file.
printf '\nper-file expectations\n'
PAIRS=$(printf '%s\n%s\n' "$VJSON" "$UJSON" |
	awk -F'"file": "' 'NF > 1 {
		split($2, a, "\"")
		split($0, b, "\"check\": \"")
		split(b[2], c, "\"")
		print a[1] " " c[1]
	}' | LC_ALL=C sort -u)

(cd "$HERE/violations" && find . -name '*.md' | LC_ALL=C sort) >"$PAIRS_FILE.notes"
while read -r note; do
	rel=${note#./}
	decl=$(awk '/^Violates: / { sub(/^Violates: /, ""); print; exit }' "$HERE/violations/$rel")
	[ -n "$decl" ] || continue
	printf '%s\n' "$decl" | tr ',' '\n' | tr -d ' ' | grep -v '^$' >"$PAIRS_FILE.decl"
	while read -r want; do
		[ -n "${want:-}" ] || continue
		if printf '%s\n' "$PAIRS" | grep -q "^$rel $want\$"; then
			ok "$rel declares and fires $want"
		else
			no "$rel declares $want but it never fired"
		fi
	done <"$PAIRS_FILE.decl"
done <"$PAIRS_FILE.notes"

# And the reverse: a note that fires a check it never declared means either the
# fixture drifted or a check is over-firing. Read from a file rather than a pipe
# - a `while read` on the right of a pipe runs in a subshell, so every FAIL it
# counted would be discarded on exit and the suite would go green on a real
# regression that it had already printed.
printf '%s\n' "$PAIRS" >"$PAIRS_FILE"
while read -r rel chk; do
	[ -n "${rel:-}" ] || continue
	case "$rel" in _vocab.yml) continue ;; esac
	decl=$(awk '/^Violates: / { sub(/^Violates: /, ""); print; exit }' "$HERE/violations/$rel" 2>/dev/null)
	case " $(printf '%s' "$decl" | tr ',' ' ') " in
	*" $chk "*) ;;
	*) no "$rel fired $chk without declaring it" ;;
	esac
done <"$PAIRS_FILE"

# --- 2c. the decision-brief boundary, both sides -----------------------------
# decision-brief-incomplete is the one check that has to stay silent on two
# whole legitimate shapes of note, so firing is only half of what needs
# asserting. Not firing is the half that would go unnoticed: a coherence check
# turned into a presence check still fires everywhere the fixtures look, and
# only fails a real vault - and the note it would fail is one whose author gets
# to green by deleting the founder's own words.
printf '\ndecision-brief boundary\n'

HALF=$(printf '%s\n' "$VJSON" | grep 'DECISION-HALF0003.md' | grep 'decision-brief-incomplete')
case "$HALF" in
*'but not `founder_reasoning`'*) ok "a full grid with no founder_reasoning fails" ;;
*) no "a full grid with no founder_reasoning did not fail" ;;
esac
case "$HALF" in
*assumptions_low*) no "assumptions_low was demanded of a note with no Low assumptions - decisions.md marks it conditional" ;;
*) ok "conditional assumptions_low is not demanded" ;;
esac

# One report per missing field, so a partial grid fails once for each. Counted
# rather than pattern-matched: a check that named one missing field and stopped
# would still match every substring assertion above.
GRID=$(printf '%s\n' "$VJSON" | grep -c 'DECISION-GRID0004.md.*decision-brief-incomplete')
[ "$GRID" = "4" ] && ok "a partial grid fails once per missing field" ||
	no "a partial grid should fail 4 times, got $GRID"

# The two shapes that must stay silent, both in the clean vault: a decision note
# in vault.md's minimal shape, and a migrated one that preserved the founder's
# words and nothing else. The clean vault is already required to report nothing,
# so these assert the notes are genuinely read rather than skipped.
for note in DECISION-DR07KK21 DECISION-MG18QW42; do
	G=$("$LINT" graph "$note" --vault "$HERE/clean" --depth 1 2>&1)
	case "$G" in
	*"$note"*decision*) ok "$note is read, and the clean vault stays silent on it" ;;
	*) no "$note was not read (got: $G)" ;;
	esac
done

# --- 2d. used_in targets resolve, both sides ---------------------------------
# Which note each --used-in failure lands on is already asserted, in both
# directions, by the per-file machinery above: PAIRS reads the mode's JSON too,
# so CLAIM-GONE0011 and CLAIM-ANCH0012 have to fire what they declare, and
# CLAIM-STAL0006 - whose target resolves - fails the suite the moment the mode
# reports it. Written out here is only what a separate mode owns and that
# machinery cannot see: its exit codes, its clean side, and its failure COUNT.
#
# The count is the assertion with teeth. A slug rule that reported every heading
# as dead would still fire both check names on the violating vault and pass a
# name census; what catches it is the clean vault staying silent and the
# violating one reporting two failures rather than five. Two of CLAIM-ANCH0012's
# three entries resolve - one through an em-dash heading that slugs to a doubled
# hyphen, one through an accented heading - so the count is what asserts that
# whitespace runs are not collapsed and that non-ASCII letters survive.
printf '\nused_in targets\n'

UI_CLEAN=$("$LINT" --used-in --vault "$HERE/clean" 2>&1)
UI_CLEAN_STATUS=$?
[ "$UI_CLEAN_STATUS" = "0" ] && ok "--used-in exits 0 on the clean vault" ||
	no "--used-in exits 0 on the clean vault (got $UI_CLEAN_STATUS)"
case "$UI_CLEAN" in
*clean*) ok "--used-in resolves every clean target, anchored and bare" ;;
*) no "--used-in did not report the clean vault clean (got: $UI_CLEAN)" ;;
esac

[ "$UI_VIOL_STATUS" = "1" ] && ok "--used-in exits 1 on the violating vault" ||
	no "--used-in exits 1 on the violating vault (got $UI_VIOL_STATUS)"

case "$UJSON" in
*'"failure_count": 2'*) ok "--used-in reports exactly the two planted failures" ;;
*) no "--used-in failure_count is not 2 - a resolving target was reported dead, or a broken one was not" ;;
esac

# --- 3. JSON is well-formed enough to slice ---------------------------------
printf '\njson\n'
for v in clean violations; do
	J=$("$LINT" --vault "$HERE/$v" --json 2>/dev/null)
	case "$J" in
	'{'*'}'*) ok "$v --json is a JSON object" ;;
	*) no "$v --json is not a JSON object" ;;
	esac
	case "$J" in
	*'"failure_count":'*) ok "$v --json carries failure_count" ;;
	*) no "$v --json has no failure_count" ;;
	esac
done

# A verdict mode with nothing to report still owes a document: a caller that
# slices --used-in --json cannot tell an empty result from a mode that printed
# nothing at all, and the difference is whether the vault is clean or the
# invocation was wrong.
UI=$("$LINT" --used-in --vault "$HERE/clean" --json 2>/dev/null)
case "$UI" in
'{'*'"failure_count": 0'*'}'*) ok "clean --used-in --json is a JSON object carrying failure_count" ;;
*) no "clean --used-in --json is not a sliceable object (got: $UI)" ;;
esac

U=$("$LINT" --unverified --vault "$HERE/clean" --json 2>/dev/null)
case "$U" in
*'"unverified_count": 2'*) ok "--unverified --json counts both populations" ;;
*) no "--unverified --json count wrong" ;;
esac

# --- 4. the refusal paths refuse --------------------------------------------
printf '\nrefusals\n'
S=$(run_status "$HERE/future-schema")
[ "$S" = "2" ] && ok "unsupported schemaVersion exits 2" || no "unsupported schemaVersion exits 2 (got $S)"

S=$(run_status "$HERE/no-vocab")
[ "$S" = "1" ] && ok "missing _vocab.yml is a failure, not a crash" || no "missing _vocab.yml (got $S)"

NOVAULT=$("$LINT" --vault "$HERE/does-not-exist" 2>&1 >/dev/null || true)
case "$NOVAULT" in
*"not a directory"*) ok "a missing vault path is refused by name" ;;
*) no "a missing vault path was not refused clearly" ;;
esac

printf '\nrun-fixtures: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
