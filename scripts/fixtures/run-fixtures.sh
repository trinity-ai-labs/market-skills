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
#   4. --supersession-sweep emits its worklist over both vaults and exits 0 over
#      both, deduped by section.
#   5. Both JSON outputs are well-formed enough to slice by field.
#   6. The two refusal paths refuse, and exit 2.
#   7. --release-gate runs every part and carries the worst verdict any of
#      them returned, including when only one part fails.
#   8. A schemaVersion 2 vault is read, and a version from the future is not.
#   9. An explicit `{#anchor}` attribute resolves, the slug of the heading text
#      it was stripped from still resolves too, and the attribute carries the
#      citation across a rewording of that text.
#  10. The sweep carries a verdict at schemaVersion 2 - it fails an absent or
#      stale `reconciled:` - and the same notes at 1 do not fail.
#  11. --red-team fails a rostered lens with no rows and a row with no roster
#      entry, and fails a missing roster at schemaVersion 2 only.
#  12. --roadmap-table matches the plan's roadmap rows against the milestone
#      titles verbatim, fails in both directions and when the roadmap is
#      rendered nowhere at all, and stays silent at schemaVersion 1.
#  13. --binding-driver reads a verdict note against the plan section it renders
#      into: the fields are owed as a set under a trigger that is strict for
#      `target-verdict` and lenient for `steady-state-ceiling`, the driver_kind
#      word list is closed, a policy-bound verdict states its configuration
#      verbatim, the corner table's Kind column matches its note in both
#      directions, a thin tail is surfaced in BOTH the note's counts and the line
#      the section renders off them, and a rendered verdict section has a note
#      behind it. Each of those has a silent
#      side asserted beside it - a structural verdict owing no condition, an
#      em-dash corner owing no note, the undetermined corner the template ships,
#      a ceiling section owing no note, an empty section owing none either, a
#      well-evidenced verdict owing no evidence line, and a legacy ceiling claim
#      carrying none of the fields - and none of them is gated on schemaVersion.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
# The implementation under test, overridable so the assertions below run against
# either one. There are two implementations of this lint - bin/vault-lint.sh and
# the PowerShell port a Windows session with no POSIX shell has to use - and
# without this override the port ships with nothing asserting that its checks
# still fire. scripts/parity/parity.mjs proves the two AGREE with each other;
# only this suite proves what they agree on is still correct, and it is the
# cheapest second layer available because it already exists.
LINT="${VAULT_LINT:-$HERE/../../bin/vault-lint.sh}"
[ -x "$LINT" ] || { printf 'run-fixtures: %s is not executable\n' "$LINT" >&2; exit 2; }

# Every check the violating vault is built to trigger. A check that stops firing
# and a check that was deleted look identical from the outside, so this list is
# the thing that has to be edited deliberately when either happens.
EXPECTED="ambiguous-value block-scalar-field confidence-propagation coverage-gap
dangling-edge decision-brief-incomplete duplicate-id duplicate-url
filename-mismatch folded-scalar frontmatter inline-flow-list malformed-edge
near-miss-subject null-value orphan-source required-field stale-claim
supersedes-reason supersedes-status type-agreement unknown-subject
unparsed-line
dependency-after-dependent false-independence sequence-not-orderable
driver-kind-unknown verdict-fields-incomplete"

# Every mode the lint answers to, and the second census in this file for the
# same reason as EXPECTED: a mode whose help block was never written and one
# whose help block was lost in a merge look identical from the outside. The
# argument parser reads MODE_TABLE, so a new mode's flag works the moment its
# row lands - `usage()` is the hand-maintained half, and nothing else in the
# suite ever runs --help. Append a mode here in the same edit that adds its row.
MODES="check --unverified --used-in --supersession-sweep --release-gate --red-team --roadmap-table --binding-driver graph"

PASS=0
FAIL=0

# -r, because one of the scratch paths below is a whole copied vault rather than
# a file: the rewording assertion needs a corpus it can edit, and a plain rm -f
# would leave that directory behind on every run.
PAIRS_FILE=$(mktemp "${TMPDIR:-/tmp}/run-fixtures.XXXXXX") || exit 2
trap 'rm -rf "$PAIRS_FILE" "$PAIRS_FILE".*' EXIT
trap 'rm -rf "$PAIRS_FILE" "$PAIRS_FILE".*; exit 2' HUP INT TERM

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
# Asserted on the new wording rather than on the substring `clean`, because
# `clean` is exactly what the line stopped saying. The bare run checks note
# fields and opens no document, so a corpus with dozens of dead anchors printed
# a whole-corpus verdict - and a success line is what somebody renders on. Both
# halves are asserted: what it did check, and that it points at the mode that
# asks the rest.
case "$CLEAN_OUT" in
*"note-level checks passed"*) ok "the success line names what it checked" ;;
*) no "the success line does not name what it checked (got: $CLEAN_OUT)" ;;
esac
case "$CLEAN_OUT" in
*--release-gate*) ok "the success line names the mode that asks all of them" ;;
*) no "the success line does not point at --release-gate (got: $CLEAN_OUT)" ;;
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
# note's business, so that assertion reads every mode that reports one.
UJSON=$("$LINT" --used-in --vault "$HERE/violations" --json 2>/dev/null)
UI_VIOL_STATUS=$?

# The third document the per-file machinery reads. --red-team reports against
# red-team.md rather than against a note, and that document carries its own
# `Violates:` line exactly as a violating note does - the promise is made by the
# file about a check, and which mode reports it is not the file's business.
RTJSON=$("$LINT" --red-team --vault "$HERE/violations" --json 2>/dev/null)
RT_VIOL_STATUS=$?

# The fourth. --roadmap-table reports against business-plan.md rather than
# against a note, and that document carries its own `Violates:` line for the
# same reason red-team.md does: the promise is made by the file about a check.
RMJSON=$("$LINT" --roadmap-table --vault "$HERE/violations" --json 2>/dev/null)

# The fifth. --binding-driver reports against business-plan.md for the section
# with no note behind it and against a note for everything else, so both kinds of
# `Violates:` promise in the violating vault are read from this one document.
BDJSON=$("$LINT" --binding-driver --vault "$HERE/violations" --json 2>/dev/null)
BD_VIOL_STATUS=$?

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
PAIRS=$(printf '%s\n%s\n%s\n%s\n%s\n' "$VJSON" "$UJSON" "$RTJSON" "$RMJSON" "$BDJSON" |
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

# --- explicit {#anchor} attributes -------------------------------------------
# Appended at the end of the used_in block and deliberately unnumbered: three
# slices append to this file in the same release, and renumbering 2e onward to
# make room is exactly the edit git merges textually clean while dropping
# somebody else's assertions.
#
# Three of the four assertions are already carried by the clean vault being
# required to report nothing, and each fails in its own direction.
# CLAIM-RR55TT19 cites `#competition`, which resolves only through the attribute
# on `## Competition & moat {#competition}` - the slug of that text is
# `competition--moat`. It cites `#business-model--pricing`, the slug of a heading
# whose attribute is `{#business-model}`, so an implementation that let the
# explicit anchor REPLACE the slug fails an entry an existing vault legitimately
# holds. And it cites `#business-model` alongside it, so slugging the raw heading
# line - which would yield `business-model--pricing-business-model` - fails both.
#
# The fourth needs its own corpus, because it is the only reason to write an
# explicit anchor at all: the citation has to survive a rewording of the heading
# TEXT. The copy is rewritten with awk rather than sed -i, which is not portable,
# and the new text is chosen to share no slug with the old, so `#competition` can
# resolve through nothing but the attribute.
printf '\nexplicit anchors\n'

REWORD="$PAIRS_FILE.reword"
rm -rf "$REWORD"
cp -R "$HERE/clean" "$REWORD"
awk '{ if ($0 == "## Competition & moat {#competition}") print "## Why the moat holds {#competition}"; else print }' \
	"$HERE/clean/business-plan.md" >"$REWORD/business-plan.md"

if grep -q '^## Why the moat holds {#competition}$' "$REWORD/business-plan.md"; then
	ok "the reworded copy carries the new heading text"
else
	no "the rewording rewrite did not land - the assertion below would pass over an unchanged vault"
fi

REWORD_OUT=$("$LINT" --used-in --vault "$REWORD" 2>&1)
REWORD_STATUS=$?
[ "$REWORD_STATUS" = "0" ] && ok "--used-in still resolves every citation after the heading text is reworded" ||
	no "--used-in failed a rewording the explicit anchor should have survived (got $REWORD_STATUS: $REWORD_OUT)"

# --- 2e. the supersession sweep, on both vaults ------------------------------
# The sweep is a REPORT and its defining property is that it is not a failure,
# so the assertion with teeth is the pair: it names a worklist AND the vault it
# named it over is still clean and still exits 0 from the default `check`
# (section 1 above). A mode that went non-zero on a healthy vault would train
# its caller to ignore the exit code the actual checks depend on, and nothing
# else in this suite would notice.
#
# It stays out of the EXPECTED/FIRED census and out of PAIRS deliberately. Both
# of those are the `check`-and-`--used-in` FAILURE census, keyed on a note's own
# `Violates:` line - and a superseded note has violated nothing. Folding a
# report into a violations ledger would mean every fixture note declaring a
# check it does not fail, which is the census losing its meaning to reuse a
# loop.
printf '\nsupersession sweep\n'

SWEEP_CLEAN=$("$LINT" --supersession-sweep --vault "$HERE/clean" 2>&1)
SWEEP_CLEAN_STATUS=$?
[ "$SWEEP_CLEAN_STATUS" = "0" ] && ok "--supersession-sweep exits 0 on the clean vault" ||
	no "--supersession-sweep exits 0 on the clean vault (got $SWEEP_CLEAN_STATUS)"

# The seeded pair is complete and well-formed - `check` is silent on it - which
# is exactly the supersession nothing else in the corpus tells the document
# about. The row has to carry the reason too: a worklist that omits it sends its
# reader back to the ledger before they can size a single row.
case "$SWEEP_CLEAN" in
*'business-plan.md#why-now'*) ok "the clean vault's row names the section the superseded note reached" ;;
*) no "the clean vault's row does not name business-plan.md#why-now (got: $SWEEP_CLEAN)" ;;
esac
case "$SWEEP_CLEAN" in
*CLAIM-TR58WQ03*CLAIM-HV21ND76*) ok "the row names the superseded note and the note that replaced it" ;;
*) no "the row does not name both halves of the pair" ;;
esac
case "$SWEEP_CLEAN" in
*'the flattening point moves out by a year'*) ok "the row carries supersedes_reason" ;;
*) no "the row does not carry supersedes_reason" ;;
esac

SC=$("$LINT" --supersession-sweep --vault "$HERE/clean" --json 2>/dev/null)
case "$SC" in
'{'*'"worklist_count": 1'*'}'*) ok "clean --supersession-sweep --json is one row, sliceable by field" ;;
*) no "clean --supersession-sweep --json is not a one-row sliceable object (got: $SC)" ;;
esac

SJSON=$("$LINT" --supersession-sweep --vault "$HERE/violations" --json 2>/dev/null)
SWEEP_VIOL_STATUS=$?
[ "$SWEEP_VIOL_STATUS" = "0" ] && ok "--supersession-sweep exits 0 on the violating vault too" ||
	no "--supersession-sweep exits 0 on the violating vault (got $SWEEP_VIOL_STATUS)"

case "$SJSON" in
*'"worklist_count": 2'*) ok "the violating vault reports its two sections" ;;
*) no "the violating vault's worklist_count is not 2" ;;
esac
case "$SJSON" in
*'"superseded_count": 3'*) ok "the count spans both halves of the two-edit rule" ;;
*) no "superseded_count is not 3 - a supersedes edge or a superseded status was missed" ;;
esac

# The dedup assertion, stated generally rather than against one target: the unit
# of work is re-read this section, so a section reached by two superseded notes
# is one row naming both. A row per note would make a two-item job look like
# three here and like dozens on a real vault, and an overstated worklist is one
# that gets skipped at the moment it matters.
printf '%s\n' "$SJSON" |
	awk -F'"target": "' 'NF > 1 { split($2, a, "\""); print a[1] }' >"$PAIRS_FILE.targets"
ROWS=$(grep -c . <"$PAIRS_FILE.targets")
UNIQ=$(LC_ALL=C sort -u <"$PAIRS_FILE.targets" | grep -c .)
[ "$ROWS" = "$UNIQ" ] && ok "every target appears exactly once in the worklist" ||
	no "the worklist repeats a target ($ROWS rows, $UNIQ distinct)"

# And that the shared row genuinely carries BOTH notes rather than whichever one
# was seen first - dedup that dropped a note would also pass the count above.
WHYNOW=$(printf '%s\n' "$SJSON" |
	awk '/"target": "business-plan.md#why-now"/ { inrow = 1 } inrow { print } inrow && /\]\}/ { exit }')
case "$WHYNOW" in
*CLAIM-STAL0006*DECISION-BLOK0001*) ok "the shared section is one row naming both superseded notes" ;;
*) no "the shared section's row lost one of its two notes (got: $WHYNOW)" ;;
esac

# The report does not depend on the supersession being well-formed, on either
# half. DECISION-SUPS0002 carries no supersedes_reason, and the row says so
# rather than dropping the note that a broken pair left pointing at a document.
case "$SJSON" in
*'"superseded_by": "DECISION-SUPS0002", "supersedes_reason": ""'*)
	ok "a supersession with no reason still reports, with the reason empty" ;;
*) no "a supersession with no supersedes_reason was dropped or mis-reported" ;;
esac

# A superseded note that reached no document is the good case, and reporting it
# is what makes it distinguishable from a note the sweep failed to read.
case "$SJSON" in
*'"reached_no_document": ['*CLAIM-UNKN0001*) ok "a superseded note with no used_in is reported, not dropped" ;;
*) no "a superseded note with no used_in was dropped" ;;
esac

# A vault with no supersessions still owes a document: a caller slicing the JSON
# cannot otherwise tell an empty worklist from an invocation that went wrong.
SN=$("$LINT" --supersession-sweep --vault "$HERE/no-vocab" --json 2>/dev/null)
SN_STATUS=$?
[ "$SN_STATUS" = "0" ] && ok "a vault with no supersessions exits 0" ||
	no "a vault with no supersessions exits 0 (got $SN_STATUS)"
case "$SN" in
'{'*'"worklist_count": 0'*'"worklist": []'*'}'*) ok "an empty worklist is still a sliceable object" ;;
*) no "an empty worklist is not a sliceable object (got: $SN)" ;;
esac

# --- 2f. two spellings of one section are one row ----------------------------
# The dedup assertion above cannot catch this one. A heading is addressable by
# an explicit {#anchor} attribute AND by the slug of its text - both, so a vault
# citing the slug keeps working once a template declares anchors - so two
# used_in entries can name the same physical section under different strings.
# Grouping on the raw anchor emits two rows for one job, and "every target
# appears exactly once" stays green throughout, because under the bug the two
# rows carry genuinely different target strings. What has teeth is the count.
#
# The --used-in call is not decoration. It asserts that the two spellings are
# two live addresses of one heading rather than two strings this file made up,
# and a fixture where either of them were dead would prove nothing at all about
# collapsing them.
printf '\nanchor aliases\n'

AA_UI=$(run_status "$HERE/anchor-alias" --used-in)
[ "$AA_UI" = "0" ] && ok "both spellings resolve - the explicit anchor and the slug beside it" ||
	no "one of the two spellings does not resolve, so the dedup below asserts nothing (got $AA_UI)"

AA=$("$LINT" --supersession-sweep --vault "$HERE/anchor-alias" --json 2>/dev/null)
case "$AA" in
*'"worklist_count": 1'*) ok "one section reached by two spellings is one row" ;;
*) no "two spellings of one section made two rows (got: $AA)" ;;
esac
case "$AA" in
*'"superseded_count": 2'*) ok "both superseded notes are still counted" ;;
*) no "collapsing the rows lost a superseded note (got: $AA)" ;;
esac

# And that the single row genuinely names BOTH notes. A collapse that kept one
# row and dropped a note would pass the count above while hiding half the job -
# which is worse than the double-count it replaced, because the reader cannot
# see what is missing.
case "$AA" in
*CLAIM-AA1CC003*CLAIM-AA1EE005*) ok "the collapsed row names both superseded notes" ;;
*) no "the collapsed row lost one of its two notes (got: $AA)" ;;
esac

# --- 2g. the sweep verdict, and the version it applies at --------------------
# The worklist and the verdict are separate questions and both halves need
# asserting, in both directions. A mode that failed on any supersession would
# pass every assertion about the unreconciled/ vault below and would have turned
# the sweep into something its caller learns to ignore - which is the whole
# reason it stayed a report for two releases. So the passing side is asserted
# first, and it is asserted over a vault that HAS a supersession: schema-2/
# carries a reconciled pair, so exiting 0 there means reconciled rather than
# empty.
printf '\nsupersession reconciliation\n'

SWEEP_S2=$("$LINT" --supersession-sweep --vault "$HERE/schema-2" 2>&1)
SWEEP_S2_STATUS=$?
[ "$SWEEP_S2_STATUS" = "0" ] && ok "a reconciled supersession at schemaVersion 2 exits 0" ||
	no "a reconciled supersession should exit 0 (got $SWEEP_S2_STATUS)"
case "$SWEEP_S2" in
*'1 section to re-read'*) ok "a reconciled vault still prints its worklist and its count" ;;
*) no "a reconciled vault dropped its worklist or its count (got: $SWEEP_S2)" ;;
esac

# reconciled: on the same day as created passes. The rule is that the read
# cannot predate the supersession, not that it has to happen later - a rule
# demanding a later date would fail every reconciliation done in one sitting,
# which is most of them.
case "$SWEEP_S2" in
*'nothing recording that the worklist was read'*'(none)'*) ok "a same-day reconciled: is not reported as stale" ;;
*) no "a same-day reconciled: was reported (got: $SWEEP_S2)" ;;
esac

UR=$("$LINT" --supersession-sweep --vault "$HERE/unreconciled" 2>&1)
UR_STATUS=$?
[ "$UR_STATUS" = "1" ] && ok "an unreconciled supersession at schemaVersion 2 exits 1" ||
	no "an unreconciled supersession should exit 1 (got $UR_STATUS)"
case "$UR" in
*CLAIM-UR1DD004*) ok "the absent reconciled: is reported, by note" ;;
*) no "the note with no reconciled: was not reported (got: $UR)" ;;
esac
case "$UR" in
*'predates the `created: 2026-07-12`'*) ok "a reconciled: earlier than created is reported" ;;
*) no "a stale reconciled: was not reported (got: $UR)" ;;
esac

# The worklist survives the verdict. A mode that started exiting 1 and stopped
# printing the rows would pass every status assertion above while destroying the
# product - the rows are what the read is performed against.
case "$UR" in
*'business-plan.md#why-now'*'business-plan.md#risks'*) ok "a failing sweep still prints its worklist" ;;
*) no "a failing sweep dropped its worklist (got: $UR)" ;;
esac

URJ=$("$LINT" --supersession-sweep --vault "$HERE/unreconciled" --json 2>/dev/null)
case "$URJ" in
'{'*'"ok": false'*'"unreconciled_count": 2'*'}'*) ok "the sweep carries its verdict in --json as well as in its exit status" ;;
*) no "the sweep --json does not carry ok/unreconciled_count (got: $URJ)" ;;
esac

# The same notes at schemaVersion 1, which is the assertion that the upgrade
# path is not a wall. Copied rather than kept as a second fixture: a hand-written
# twin asserts this until the day one of the two is edited.
AT_1="$PAIRS_FILE.at-1"
rm -rf "$AT_1"
cp -R "$HERE/unreconciled" "$AT_1"
printf '{\n  "schemaVersion": 1,\n  "created": "2026-07-27"\n}\n' >"$AT_1/.vault/config.json"

AT1_STATUS=$(run_status "$AT_1" --supersession-sweep)
[ "$AT1_STATUS" = "0" ] && ok "the same notes at schemaVersion 1 do not fail the sweep" ||
	no "schemaVersion 1 must not owe reconciled: (got $AT1_STATUS)"

AT1_OUT=$("$LINT" --supersession-sweep --vault "$AT_1" 2>&1)
case "$AT1_OUT" in
*'schemaVersion 2 rule and this vault is at 1'*) ok "at 1 the sweep says the rule was not applied, rather than reporting none" ;;
*) no "at 1 the sweep reported an empty verdict instead of saying it did not ask (got: $AT1_OUT)" ;;
esac

# --- 2h. the lens roster, both directions and both versions ------------------
# Which note each --red-team failure lands on is asserted by the per-file
# machinery above, which now reads this mode's JSON too: violations/red-team.md
# declares both checks on its own `Violates:` line and has to fire both. Written
# out here is what that machinery cannot see - the exit codes, the clean side,
# and the version gate on the roster itself.
printf '\nlens roster\n'

RT_CLEAN=$("$LINT" --red-team --vault "$HERE/clean" 2>&1)
RT_CLEAN_STATUS=$?
[ "$RT_CLEAN_STATUS" = "0" ] && ok "--red-team exits 0 when every dispatched lens wrote rows" ||
	no "--red-team should exit 0 on the clean vault (got $RT_CLEAN_STATUS)"

# The clean side is where the two easy over-firings would show. `R1-O3` writes
# its lens in lower case and the roster wrote it capitalised, and the fenced
# template names a lens nothing dispatched - either read literally turns the
# clean vault red, and a mode that fires on capitalisation is one somebody
# switches off.
case "$RT_CLEAN" in
*failure*) no "--red-team fired on the clean vault - a case difference or a fenced template row was read as real" ;;
*) ok "a lens case difference and a fenced template row are both ignored" ;;
esac

[ "$RT_VIOL_STATUS" = "1" ] && ok "--red-team exits 1 on the violating vault" ||
	no "--red-team exits 1 on the violating vault (got $RT_VIOL_STATUS)"
case "$RTJSON" in
*'"failure_count": 2'*) ok "--red-team reports exactly the two planted roster failures" ;;
*) no "--red-team failure_count is not 2 - a matching lens was reported, or a gap was not" ;;
esac

# A vault that never dispatched a panel is not a failure, at either version.
# Failing it would fail every corpus before Phase 4 runs, which is the shape of
# check that gets switched off rather than satisfied.
RT_NONE=$("$LINT" --red-team --vault "$HERE/dead-citation" 2>&1)
RT_NONE_STATUS=$?
[ "$RT_NONE_STATUS" = "0" ] && ok "a vault with no red-team.md passes --red-team" ||
	no "a vault with no red-team.md should pass (got $RT_NONE_STATUS)"
case "$RT_NONE" in
*"no red-team.md"*) ok "the absent document is named rather than reported clean" ;;
*) no "--red-team did not say the document was absent (got: $RT_NONE)" ;;
esac

# The missing roster is the version-gated half, and both sides need asserting:
# firing at 2 is the check, and staying silent at 1 is what keeps a corpus with
# a panel in it from going red the day the skill updates. violations/ is at 1
# and its roster is present, so the silent side is asserted where the roster is
# absent - the same document, one version down.
RT_GAP=$(run_status "$HERE/panel-gap" --red-team)
[ "$RT_GAP" = "1" ] && ok "a red-team.md with no roster fails at schemaVersion 2" ||
	no "a missing roster should fail at schemaVersion 2 (got $RT_GAP)"

cp "$HERE/panel-gap/red-team.md" "$AT_1/red-team.md"
RT_AT1=$(run_status "$AT_1" --red-team)
[ "$RT_AT1" = "0" ] && ok "the same document with no roster passes at schemaVersion 1" ||
	no "a missing roster must not fail at schemaVersion 1 (got $RT_AT1)"

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

# --- 5. the release gate runs every part and carries one verdict -------------
# The gate exists because three calls made from memory is a set nobody can be
# held to, so what is asserted here is composition rather than any one part:
# every part's output appears, in order, on a passing vault and a failing one
# alike, and ONE failing part is enough to fail the whole call. That last half
# is what a gate reporting only its first part's verdict would get wrong, and
# it is invisible over clean/ and violations/ - both vaults agree across the
# parts, so a broken composition passes both.
printf '\nrelease gate\n'

RG_CLEAN=$("$LINT" --release-gate --vault "$HERE/clean" 2>&1)
RG_CLEAN_STATUS=$?
[ "$RG_CLEAN_STATUS" = "0" ] && ok "--release-gate exits 0 on the clean vault" ||
	no "--release-gate exits 0 on the clean vault (got $RG_CLEAN_STATUS)"

RG_VIOL=$("$LINT" --release-gate --vault "$HERE/violations" 2>&1)
RG_VIOL_STATUS=$?
[ "$RG_VIOL_STATUS" = "1" ] && ok "--release-gate exits 1 on the violating vault" ||
	no "--release-gate exits 1 on the violating vault (got $RG_VIOL_STATUS)"

# Both vaults, because a gate that stopped at the first failing part would
# still print all three headings over the clean one.
for part in 'check: note-level checks' '--used-in: citation targets' '--supersession-sweep: supersession blast radius' '--red-team: panel objection rows' '--roadmap-table: roadmap table against the milestone set' '--binding-driver: verdict drivers and the evidence under them'; do
	case "$RG_CLEAN" in
	*"$part"*) ok "the clean gate carries the $part part" ;;
	*) no "the clean gate is missing the $part part" ;;
	esac
	case "$RG_VIOL" in
	*"$part"*) ok "the violating gate carries the $part part" ;;
	*) no "the violating gate is missing the $part part" ;;
	esac
done

# dead-citation is the vault built for the one-failing-part case: every note in
# it is well-formed, so `check` is silent, and the one used_in entry names a
# document that is not there. A gate whose verdict was its first part's would
# report it clean and a render would go ahead over a citation reaching nothing.
#
# One capture sliced three ways, per the rule stated above VJSON: the gate's own
# output already carries the passing part's success line, the failing part's
# check name and the composite exit status, so re-invoking the two parts
# separately would cost three more full corpus parses for nothing.
DC_GATE=$("$LINT" --release-gate --vault "$HERE/dead-citation" 2>&1)
DC_GATE_STATUS=$?
case "$DC_GATE" in
*"note-level checks passed"*) ok "dead-citation passes the note-level checks" ;;
*) no "dead-citation should pass the note-level checks (got: $DC_GATE)" ;;
esac
case "$DC_GATE" in
*used-in-missing-file*) ok "dead-citation fails --used-in, on the missing document" ;;
*) no "dead-citation did not fire used-in-missing-file (got: $DC_GATE)" ;;
esac
[ "$DC_GATE_STATUS" = "1" ] && ok "--release-gate fails when only --used-in fails" ||
	no "--release-gate should fail when only --used-in fails (got $DC_GATE_STATUS)"

# A refusal and a failed check are different answers. The gate reports the
# worse of the two rather than flattening both to 1, which would send a reader
# hunting for a failure in a check that never ran.
RG_FUTURE=$(run_status "$HERE/future-schema" --release-gate)
[ "$RG_FUTURE" = "2" ] && ok "--release-gate exits 2 when a part refuses to run" ||
	no "--release-gate exits 2 when a part refuses to run (got $RG_FUTURE)"

# Refused rather than emitting three JSON documents in a row, which is not a
# JSON document and which every consumer would nonetheless try to parse.
RG_JSON=$("$LINT" --release-gate --json --vault "$HERE/clean" 2>&1 >/dev/null || true)
case "$RG_JSON" in
*"not a JSON document"*) ok "--release-gate refuses --json by name" ;;
*) no "--release-gate did not refuse --json clearly (got: $RG_JSON)" ;;
esac

# One vault per newly-failing part, for the reason dead-citation exists: a gate
# whose verdict came from its first part would report both of these clean, and
# neither is visible over clean/ or violations/, where every part agrees.
RG_UNREC=$(run_status "$HERE/unreconciled" --release-gate)
[ "$RG_UNREC" = "1" ] && ok "--release-gate fails when only the sweep fails" ||
	no "--release-gate should fail when only the sweep fails (got $RG_UNREC)"

RG_PANEL=$(run_status "$HERE/panel-gap" --release-gate)
[ "$RG_PANEL" = "1" ] && ok "--release-gate fails when only --red-team fails" ||
	no "--release-gate should fail when only --red-team fails (got $RG_PANEL)"

# And that each names the part that failed rather than only carrying its status,
# since the gate prints a list of the parts that did not pass.
RG_PANEL_ERR=$("$LINT" --release-gate --vault "$HERE/panel-gap" 2>&1 >/dev/null || true)
case "$RG_PANEL_ERR" in
*"did not pass"*--red-team*) ok "the gate names --red-team as the part that failed" ;;
*) no "the gate did not name the failing part (got: $RG_PANEL_ERR)" ;;
esac

# --- 6. the supported schemaVersion set ------------------------------------
# Asserting only that 99 is refused would pass a tool that had narrowed the set
# back to a single version and started refusing every vault scaffolded since -
# the refusal path would look identical and every real corpus would be dead.
printf '\nschema versions\n'

# Captured once and sliced again in section 8, per the rule stated above VJSON:
# --json changes the output format and not what gets computed, so a second
# invocation to read the same result costs a full re-parse of the vault for
# nothing.
M2=$("$LINT" --vault "$HERE/schema-2" --json 2>/dev/null)
S=$?
[ "$S" = "0" ] && ok "a schemaVersion 2 vault is read and reports nothing" ||
	no "a schemaVersion 2 vault should exit 0 (got $S)"

S=$(run_status "$HERE/schema-2" --release-gate)
[ "$S" = "0" ] && ok "--release-gate is clean over a schemaVersion 2 vault" ||
	no "--release-gate over a schemaVersion 2 vault (got $S)"

# --- 7. every mode has help text ---------------------------------------------
# The one thing MODE_TABLE cannot absorb. A mode registers its flag by adding a
# row, but its paragraph in `usage()` is written by hand at a shared anchor -
# and a release that adds three modes is three inserts at the same point, two
# of which git merges textually clean. The mode that loses its block still
# works, so nothing turns red and the miss surfaces the first time a user runs
# --help and cannot find the flag they were told about.
printf '\nhelp text\n'

HELP=$("$LINT" --help 2>&1)
HELP_STATUS=$?
[ "$HELP_STATUS" = "0" ] && ok "--help exits 0" || no "--help exits 0 (got $HELP_STATUS)"

# Brackets dropped before matching: `check` is the one mode whose block writes
# its selector as optional (`vault-lint.sh [check] …`), and the block is what is
# being asserted rather than the exact synopsis punctuation.
HELP_FLAT=$(printf '%s\n' "$HELP" | tr -d '[]')

# Matched against the basename of $LINT, not a literal `vault-lint.sh`: this
# census runs against whichever implementation VAULT_LINT names, and a
# hardcoded literal either fails the port for a cosmetic reason (its own
# --help correctly names itself vault-lint.ps1) or forces the port to print a
# command its reader does not have, just to satisfy this assertion.
LINT_PROG=$(basename "$LINT")

printf '%s\n' "$MODES" | tr ' ' '\n' | grep -v '^$' >"$PAIRS_FILE.modes"
while read -r mode; do
	[ -n "${mode:-}" ] || continue
	case "$HELP_FLAT" in
	*"$LINT_PROG $mode"*) ok "--help documents $mode" ;;
	*) no "--help has no block for $mode" ;;
	esac
done <"$PAIRS_FILE.modes"

# --- 8. the milestone type, its two order rules, and the schema gate ---------
# The census above already asserts that each new check FIRES. What it cannot see
# is the half that decides whether these rules are usable: where each one has to
# stay SILENT. A concurrency rule keyed on `sequence` alone, or an order rule
# that ran at every schemaVersion, fires everywhere the census looks and fails
# only real vaults - and a check that cries wolf gets switched off, taking the
# working half with it.
printf '\nmilestones\n'

# Rule 4 is a rule about a PAIR, and this is the side the per-file `Violates:`
# machinery structurally cannot assert: that the check stays SILENT. schema-2/
# carries two milestones at the same `sequence` with different `resource`
# values - concurrent by design, because one is gated on an external clock the
# founder cannot compress - so a check keyed on the sequence alone would fail
# the vault this suite requires clean. That both members of a real pair are
# reported is already asserted in 2b, where each declares the check.
case "$M2" in
*false-independence*) no "false-independence fired on two milestones that differ on resource" ;;
*) ok "false-independence stays silent on one sequence across two resources" ;;
esac

# `moves` and `depends_on` are walked by graph because they are in EDGE_FIELDS,
# and `unlocks` is DERIVED rather than stored - vault.md bans mirrored edges, so
# what an item unlocks is the reverse of somebody else's depends_on and is read
# off the same traversal that answers `rested on by` for rests_on.
MG=$("$LINT" graph MILESTONE-SV2EE005 --vault "$HERE/schema-2" --depth 1 2>&1)
case "$MG" in
*'moves ->'*ASSUMPTION-SV2DD004*) ok "graph walks moves out of a milestone" ;;
*) no "graph did not walk moves (got: $MG)" ;;
esac
case "$MG" in
*MILESTONE-SV2FF006*'(via depends_on)'*) ok "graph derives what a milestone unlocks from the reverse of depends_on" ;;
*) no "graph did not derive the inbound depends_on edge (got: $MG)" ;;
esac

# Both halves of defect 7 on `moves`, and the line between them. 2b already
# asserts that each fixture fires the check it declares; what it cannot see is
# that the two arms stay SEPARATE and keep their own messages. A `moves` value
# that is a well-formed ID naming no note is dangling-edge - something is missing
# from the vault. A value that is not an ID at all is malformed-edge - nothing is
# missing, the field never named a note. Collapsing either into the other sends
# the author to the wrong fix.
MOVE_MALF=$(printf '%s\n' "$VJSON" | grep 'MILESTONE-ROWL0008.md' | grep 'malformed-edge')
case "$MOVE_MALF" in
*'A-n'*'note ID'*) ok "the moves malformed-edge message names the row label and the note ID that replaces it" ;;
*) no "the moves malformed-edge message does not name the A-n row label (got: $MOVE_MALF)" ;;
esac
case "$MOVE_MALF" in
*'blast-radius edge'*) no "the moves malformed-edge message reuses the rests_on sentence - the two fields cost different things" ;;
*) ok "the moves malformed-edge message is written for moves, not shared with rests_on" ;;
esac
RESTS_MALF=$(printf '%s\n' "$VJSON" | grep 'FACT-MALF0005.md' | grep 'malformed-edge')
case "$RESTS_MALF" in
*'rests_on is the blast-radius edge'*) ok "rests_on keeps its own malformed-edge message" ;;
*) no "the rests_on malformed-edge message changed (got: $RESTS_MALF)" ;;
esac
case "$(printf '%s\n' "$VJSON" | grep 'MILESTONE-MOVE0004.md')" in
*malformed-edge*) no "a well-formed moves target that names no note reported malformed-edge instead of dangling-edge" ;;
*dangling-edge*) ok "a well-formed moves target that names no note is still dangling-edge, not malformed-edge" ;;
*) no "MILESTONE-MOVE0004 reported neither dangling-edge nor malformed-edge" ;;
esac

# The gate on every version-2 rule, asserted from the version-1 side. Its two
# notes share a `resource` and a `sequence`, so at 2 they are false-independence
# and at 1 they are simply not a type this vault may carry. Asserting only that
# the checks fire at 2 would pass a build with no gate at all, which is the
# upgrade that turns every finished corpus red on the day the skill updates.
S1M=$("$LINT" --vault "$HERE/schema-1-milestone" --json 2>/dev/null)
case "$S1M" in
*'"check": "type-agreement"'*) ok "a milestone in a schemaVersion 1 vault is not a type it carries" ;;
*) no "a schemaVersion 1 milestone did not fire type-agreement (got: $S1M)" ;;
esac
case "$S1M" in
*schemaVersion*2*type*) ok "the message names the version that added the type" ;;
*) no "the type-agreement message does not name schemaVersion 2" ;;
esac
for gated in false-independence dependency-after-dependent sequence-not-orderable required-field; do
	case "$S1M" in
	*"$gated"*) no "$gated fired on a schemaVersion 1 vault - the version gate is not holding" ;;
	*) ok "$gated stays silent at schemaVersion 1" ;;
	esac
done

# --- 9. the roadmap table against the milestone set --------------------------
# The check plan-template.md promised and nothing read: the table renders
# `sequence`, `moves` and `resource` off the notes, so its item cell IS the
# milestone title and the two cannot drift. The key is that title matched
# VERBATIM, which is what makes the passing side an assertion rather than a
# tautology - a rule keyed on anything looser passes schema-2/ whatever it does.
#
# Each direction gets a vault of its own, because a single fixture failing both
# would pass a check that had collapsed them into one message. And each of those
# vaults renders its OTHER item correctly, so the failure COUNT is what has
# teeth: a check reporting every row fires the same check name on the same file
# and would clear a name census untouched.
printf '\nroadmap table\n'

RM_S2=$("$LINT" --roadmap-table --vault "$HERE/schema-2" 2>&1)
RM_S2_STATUS=$?
[ "$RM_S2_STATUS" = "0" ] && ok "a table rendered off the notes agrees with them" ||
	no "--roadmap-table should exit 0 over schema-2 (got $RM_S2_STATUS: $RM_S2)"

# The success line names what it compared, for the reason the bare run's does:
# a line saying the table agrees, printed over a vault with nothing to compare,
# reads as a roadmap that was checked. Three rows, three notes - and the second
# table in that section, the Rule 3 permutation comparison, contributes none of
# them.
case "$RM_S2" in
*'3 roadmap rows against 3 milestone notes'*) ok "the success line names both sides it matched" ;;
*) no "the success line does not name what it compared (got: $RM_S2)" ;;
esac

RM_X=$("$LINT" --roadmap-table --vault "$HERE/roadmap-extra-row" --json 2>/dev/null)
RM_X_STATUS=$?
[ "$RM_X_STATUS" = "1" ] && ok "a row naming no milestone fails" ||
	no "a row naming no milestone should exit 1 (got $RM_X_STATUS)"
case "$RM_X" in
*'"failure_count": 1'*) ok "only the row that escaped the ledger is reported" ;;
*) no "--roadmap-table did not report exactly one row over roadmap-extra-row (got: $RM_X)" ;;
esac
case "$RM_X" in
*'"check": "roadmap-row-no-milestone"'*'Mobile client parity'*) ok "the failure names the row it could not resolve" ;;
*) no "the failure does not name the planted row (got: $RM_X)" ;;
esac

RM_M=$("$LINT" --roadmap-table --vault "$HERE/roadmap-missing-row" --json 2>/dev/null)
RM_M_STATUS=$?
[ "$RM_M_STATUS" = "1" ] && ok "a milestone the table never lists fails" ||
	no "an unlisted milestone should exit 1 (got $RM_M_STATUS)"
# The count is what catches the two over-firings that would each look like a
# real finding, so a red here is worth reading before anything else: reading the
# header row as an item reports `Item` as a row with no note behind it on every
# correctly written table there is, and roadmap-missing-row/ heads its table
# `| # | Item | ... |` - the shape research/timeline.md is generated in - so
# taking the FIRST cell rather than the one the header names reports the ordinal
# `1` the same way. Both fire the same check name as a genuine extra row and are
# invisible to a name census; both push this count to 2.
case "$RM_M" in
*'"failure_count": 1'*) ok "only the milestone the table omits is reported" ;;
*) no "--roadmap-table did not report exactly one note over roadmap-missing-row (got: $RM_M)" ;;
esac
case "$RM_M" in
*'"check": "milestone-not-in-roadmap"'*MILESTONE-MR1BB002*) ok "the failure lands on the note the table left out" ;;
*) no "the failure does not name MILESTONE-MR1BB002 (got: $RM_M)" ;;
esac

# A vault with milestones and no business-plan.md at all. The roadmap is in the
# ledger and nowhere a reader can see it, which is a failure rather than an
# absent document to skip - and it is asserted on a COPY of the version-1
# fixture stamped up to 2, so the same notes carry the gate in both directions.
NO_PLAN="$PAIRS_FILE.no-plan"
rm -rf "$NO_PLAN"
cp -R "$HERE/schema-1-milestone" "$NO_PLAN"
printf '{\n  "schemaVersion": 2,\n  "created": "2026-07-27"\n}\n' >"$NO_PLAN/.vault/config.json"

NP=$("$LINT" --roadmap-table --vault "$NO_PLAN" 2>&1)
NP_STATUS=$?
[ "$NP_STATUS" = "1" ] && ok "milestones with no business-plan.md fail" ||
	no "a vault with milestones and no plan should exit 1 (got $NP_STATUS: $NP)"
case "$NP" in
*roadmap-table-missing*) ok "the absent document is reported by name" ;;
*) no "--roadmap-table did not fire roadmap-table-missing (got: $NP)" ;;
esac

# The same notes at the version that predates the type. Asserting only that the
# checks fire at 2 would pass a build with no gate at all, which is the upgrade
# that turns every finished corpus red on the day the skill updates.
RM_S1=$("$LINT" --roadmap-table --vault "$HERE/schema-1-milestone" 2>&1)
RM_S1_STATUS=$?
[ "$RM_S1_STATUS" = "0" ] && ok "the same notes at schemaVersion 1 do not owe a roadmap table" ||
	no "schemaVersion 1 must not owe a roadmap table (got $RM_S1_STATUS: $RM_S1)"
case "$RM_S1" in
*'schemaVersion 2 rule and this vault is at 1'*) ok "at 1 the mode says it did not ask, rather than reporting agreement" ;;
*) no "at 1 the mode reported a clean table instead of saying it did not ask (got: $RM_S1)" ;;
esac

# The two silent sides that would otherwise fail a real vault. panel-gap/ is at
# schemaVersion 2 with no milestones and no business-plan.md, so a mode that
# demanded a roadmap of every version-2 vault would fail every corpus before the
# plan has one. unreconciled/ is the harder half: it HAS a business-plan.md, with
# no roadmap section in it, and no milestones to render there.
RM_PG=$(run_status "$HERE/panel-gap" --roadmap-table)
[ "$RM_PG" = "0" ] && ok "no milestones and no business-plan.md is not a roadmap failure" ||
	no "a vault with no roadmap on either side should pass (got $RM_PG)"

RM_UR=$(run_status "$HERE/unreconciled" --roadmap-table)
[ "$RM_UR" = "0" ] && ok "a plan with no roadmap section is not a failure when nothing owes one" ||
	no "a plan with no milestones behind it should pass (got $RM_UR)"

# --- 10. the verdict, its binding driver, and the evidence under it ----------
# The census above already asserts that the two note-level codes FIRE. What it
# cannot see is the half that decides whether these rules are usable at all:
# where each has to stay SILENT. There is no schemaVersion gate anywhere in this
# mode, so getting the trigger wrong in the strict direction reddens every
# existing vault's legacy ceiling claim on the day the plugin updates, and in the
# lenient direction leaves the omission dodge open. Both sides are asserted.
printf '\nverdict drivers\n'

[ "$BD_VIOL_STATUS" = "1" ] && ok "--binding-driver exits 1 on the violating vault" ||
	no "--binding-driver exits 1 on the violating vault (got $BD_VIOL_STATUS)"

# clean/ is at schemaVersion 1 and carries a complete verdict note, a corner
# table that renders it, and a ceiling claim holding none of the five. Section 1
# already requires that vault to report nothing, so this asserts the mode was
# actually asked - and asked over a version-1 corpus, which is what says the
# trigger is the subject rather than the version.
BD_CLEAN=$("$LINT" --binding-driver --vault "$HERE/clean" 2>&1)
BD_CLEAN_STATUS=$?
[ "$BD_CLEAN_STATUS" = "0" ] && ok "a complete verdict at schemaVersion 1 passes - the trigger is the subject, not the version" ||
	no "--binding-driver should exit 0 over clean (got $BD_CLEAN_STATUS: $BD_CLEAN)"

# The success line names both sides it compared, for the reason the bare run's
# does: a line saying the verdict agrees, printed over a vault with nothing to
# compare, reads as a verdict that was checked. One verdict note and two corner
# rows - the ceiling claim is not counted, because carrying none of the five is
# what exempts it.
case "$BD_CLEAN" in
*'1 verdict note against 2 corner verdict rows'*) ok "the success line names both sides it matched" ;;
*) no "the success line does not name what it compared (got: $BD_CLEAN)" ;;
esac

# THE ASYMMETRY, asserted from the side that would break every existing vault.
# CLAIM-VD05EE55 carries `subject: steady-state-ceiling` and none of the five
# fields, which is the shape every vault authored before this release holds. It
# has to be READ and still not fail - a graph call is what proves it was read,
# because a mode that skipped the note would pass this suite in silence.
BD_CEIL=$("$LINT" graph CLAIM-VD05EE55 --vault "$HERE/clean" --depth 1 2>&1)
case "$BD_CEIL" in
*CLAIM-VD05EE55*steady-state-ceiling*) ok "the legacy ceiling claim is read, and owes none of the five" ;;
*) no "CLAIM-VD05EE55 was not read (got: $BD_CEIL)" ;;
esac

# The lenient half of the trigger, counted rather than pattern-matched: a check
# that named one missing field and stopped would still match every substring
# assertion here. CLAIM-VDCE0014 is a ceiling claim carrying `binding_driver` and
# nothing else, so the three siblings owed outright are reported and
# `conditional_on` is not - with no `driver_kind`, nothing says the driver is
# policy, and demanding a condition of every verdict would be met by inventing
# one.
CEILP=$(printf '%s\n' "$VJSON" | grep -c 'CLAIM-VDCE0014.md.*verdict-fields-incomplete')
[ "$CEILP" = "3" ] && ok "a ceiling claim carrying one of the five owes the other three" ||
	no "a partial ceiling should fail 3 times, got $CEILP"
case "$(printf '%s\n' "$VJSON" | grep 'CLAIM-VDCE0014.md')" in
*conditional_on*) no "conditional_on was demanded of a note with no policy driver_kind - a structural verdict owes no condition" ;;
*) ok "conditional_on is not demanded where driver_kind is not policy" ;;
esac

# THE STRICT HALF, and the release's headline behaviour: a `target-verdict` note
# carrying NONE of the fields owed outright fails, because no corpus written
# before this release carries that subject and an omission would otherwise be the
# cheapest way past every rule that reads one of them. Asserted by count for the
# reason above, and CLAIM-VDTV0016 carries no `driver_kind` either, so the four
# owed outright are reported and `conditional_on` is not - which is what says the
# two halves of the trigger differ in what they demand and not in how they
# enumerate it.
TVP=$(printf '%s\n' "$VJSON" | grep -c 'CLAIM-VDTV0016.md.*verdict-fields-incomplete')
[ "$TVP" = "4" ] && ok "a target-verdict note carrying none of the fields owes all four" ||
	no "a bare target verdict should fail 4 times, got $TVP"
case "$(printf '%s\n' "$VJSON" | grep 'CLAIM-VDTV0016.md')" in
*'none of the fields a verdict owes outright'*) ok "the message says the subject owes them whatever else the note carries" ;;
*) no "the bare-target-verdict message does not name the unconditional trigger" ;;
esac

# The one document-level code, and the trigger that is deliberately not a read of
# the prose. Its vault carries a non-empty `{#target-verdict}` section and no
# notes at all, so the section is the whole trigger - and a non-empty
# `{#steady-state}` section beside it, which must NOT fire: there is deliberately
# no equivalent there, because a ceiling section in an existing plan legitimately
# has no field-carrying note behind it. The failure count is what asserts the
# second half; a mirror rule would report two.
BD_UF=$("$LINT" --binding-driver --vault "$HERE/verdict-unfiled" --json 2>/dev/null)
BD_UF_STATUS=$?
[ "$BD_UF_STATUS" = "1" ] && ok "a rendered verdict section with no note behind it fails" ||
	no "verdict-unfiled should exit 1 (got $BD_UF_STATUS)"
case "$BD_UF" in
*'"failure_count": 1'*) ok "the rendered ceiling section beside it owes no note" ;;
*) no "--binding-driver did not report exactly one failure over verdict-unfiled (got: $BD_UF)" ;;
esac
case "$BD_UF" in
*'"check": "verdict-unfiled"'*'business-plan.md'*) ok "the failure lands on the document, not on a note" ;;
*) no "verdict-unfiled did not report against business-plan.md (got: $BD_UF)" ;;
esac

# And the trigger is PRESENCE of a non-empty section, so an empty one at the same
# anchor owes nothing. Asserted on a copy with the section body stripped, the way
# the rewording and schemaVersion assertions above build the corpus they need -
# a hand-written twin asserts this until the day one of the two is edited. Getting
# this wrong fails every plan that has scaffolded its headings and not yet written
# the verdict, which is every plan before Phase 5.
EMPTY_UF="$PAIRS_FILE.empty-verdict"
rm -rf "$EMPTY_UF"
cp -R "$HERE/verdict-unfiled" "$EMPTY_UF"
awk 'BEGIN { drop = 0 }
	/^## Target & verdict \{#target-verdict\}$/ { print; drop = 1; next }
	/^## / { drop = 0 }
	drop { next }
	{ print }' "$HERE/verdict-unfiled/business-plan.md" >"$EMPTY_UF/business-plan.md"

if grep -q '^## Target & verdict {#target-verdict}$' "$EMPTY_UF/business-plan.md" &&
	! grep -q 'Reach binds' "$EMPTY_UF/business-plan.md"; then
	ok "the emptied copy keeps the heading and loses its body"
else
	no "the section-stripping rewrite did not land - the assertion below would pass over an unchanged vault"
fi

EMPTY_UF_STATUS=$(run_status "$EMPTY_UF" --binding-driver)
[ "$EMPTY_UF_STATUS" = "0" ] && ok "an empty section at the verdict anchor owes no note" ||
	no "an empty verdict section must not fail (got $EMPTY_UF_STATUS)"

# A vault with no verdict note and no rendered verdict section passes, and says
# which rather than reporting agreement. Failing it would fail every corpus
# before a target has been stated, which is the shape of check that gets switched
# off rather than satisfied.
BD_NONE=$("$LINT" --binding-driver --vault "$HERE/panel-gap" 2>&1)
BD_NONE_STATUS=$?
[ "$BD_NONE_STATUS" = "0" ] && ok "a vault with no verdict on either side passes" ||
	no "a vault with no verdict should pass (got $BD_NONE_STATUS: $BD_NONE)"
case "$BD_NONE" in
*'no verdict note and no'*) ok "the absent verdict is named rather than reported clean" ;;
*) no "--binding-driver did not say there was no verdict (got: $BD_NONE)" ;;
esac

# A schemaVersion 2 corpus carrying no verdict subject at all. This is the
# upgrade case: every existing vault is one of these, and a rule that fired here
# would turn a finished corpus red on the day the plugin updates.
BD_S2=$(run_status "$HERE/schema-2" --binding-driver)
[ "$BD_S2" = "0" ] && ok "a schemaVersion 2 corpus with no verdict subject exits 0" ||
	no "a corpus with no verdict subject must not fail (got $BD_S2)"

# Each of the four document-facing codes gets a vault of its own, and each of
# those vaults renders its OTHER verdict correctly - so the failure COUNT is what
# has teeth. A check that reported every verdict fires the same check name on the
# same file and would clear a name census untouched.
BD_UC=$("$LINT" --binding-driver --vault "$HERE/verdict-unconditional" --json 2>/dev/null)
BD_UC_STATUS=$?
[ "$BD_UC_STATUS" = "1" ] && ok "a policy-bound verdict whose section drops the configuration fails" ||
	no "verdict-unconditional should exit 1 (got $BD_UC_STATUS)"
case "$BD_UC" in
*'"failure_count": 1'*) ok "only the policy-bound verdict is reported" ;;
*) no "--binding-driver did not report exactly one note over verdict-unconditional (got: $BD_UC)" ;;
esac
# The negative case, and it carries as much weight as the positive one: a rule
# demanding a condition from every verdict would be met by inventing one, which
# renders. CLAIM-BD1DD004 is structural and sits in the same section.
case "$BD_UC" in
*CLAIM-BD1DD004*) no "a structural verdict was asked for a conditional_on - it has no choice to name" ;;
*) ok "a structural binding driver owes no conditional_on" ;;
esac
case "$BD_UC" in
*'"check": "verdict-unconditional"'*'six hours a week across two channels'*) ok "the failure names the string the section does not carry" ;;
*) no "the failure does not name the conditional_on string (got: $BD_UC)" ;;
esac

# Both directions of the Kind column, one vault each. A single fixture failing
# both would pass a check that had collapsed them into one message - and without
# the reverse direction, editing a driver cell until it matches no note is the
# cheapest way past the forward one.
BD_KC=$("$LINT" --binding-driver --vault "$HERE/verdict-kind-cell" --json 2>/dev/null)
BD_KC_STATUS=$?
[ "$BD_KC_STATUS" = "1" ] && ok "a Kind cell disagreeing with its note fails" ||
	no "verdict-kind-cell should exit 1 (got $BD_KC_STATUS)"
case "$BD_KC" in
*'"failure_count": 1'*) ok "only the row whose kind disagrees is reported" ;;
*) no "--binding-driver did not report exactly one row over verdict-kind-cell (got: $BD_KC)" ;;
esac
# The em-dash corner is the over-firing that would look like a real finding, and
# the count above is what catches it: `plan-template.md` writes an em dash in both
# cells for a corner where nothing binds, so a rule that demanded a note for every
# row would report that row too - the same check name as a genuine mismatch, and
# invisible to a name census.
case "$BD_KC" in
*'"file": "business-plan.md"'*'structural'*) ok "the failure names the cell and the note it disagrees with" ;;
*) no "the failure does not name the planted cell (got: $BD_KC)" ;;
esac

BD_KU=$("$LINT" --binding-driver --vault "$HERE/verdict-kind-unrendered" --json 2>/dev/null)
BD_KU_STATUS=$?
[ "$BD_KU_STATUS" = "1" ] && ok "a verdict note whose driver no row names fails" ||
	no "verdict-kind-unrendered should exit 1 (got $BD_KU_STATUS)"
case "$BD_KU" in
*'"failure_count": 1'*) ok "only the verdict the table omits is reported" ;;
*) no "--binding-driver did not report exactly one note over verdict-kind-unrendered (got: $BD_KU)" ;;
esac
case "$BD_KU" in
*'"check": "verdict-kind-mismatch"'*CLAIM-BD3DD004*) ok "the failure lands on the note the table left out" ;;
*) no "the failure does not name CLAIM-BD3DD004 (got: $BD_KU)" ;;
esac
# The second silent side of the reverse direction, and the reason it asks only
# whether a row NAMES the driver: that vault carries the shape the template
# writes for an undetermined corner - `| multiple | - |`, driver named and kind an
# em dash. Nothing carries `multiple` as a binding driver there, so it demands no
# note, and a rule requiring a kind wherever a driver was named would report the
# worked example the template ships.
case "$BD_KU" in
*multiple*) no "the undetermined corner plan-template.md ships was reported - the check would fire on the template" ;;
*) ok "an undetermined corner naming its driver with an em-dash kind demands no note" ;;
esac

BD_TE=$("$LINT" --binding-driver --vault "$HERE/verdict-thin-evidence" --json 2>/dev/null)
BD_TE_STATUS=$?
[ "$BD_TE_STATUS" = "1" ] && ok "a closure that reaches one counterparty fails at any n" ||
	no "verdict-thin-evidence should exit 1 (got $BD_TE_STATUS)"
# Two of the three notes fail and for different reasons - one states no counts,
# one states a pair the closure does not hold - and the third states the pair
# correctly and is silent. The count is what has teeth: a rule that only checked
# whether the fields were PRESENT would report one instead of two and still fire
# the same check name on the same vault.
case "$BD_TE" in
*'"failure_count": 2'*) ok "an absent pair and a wrong pair are both reported, and the correct one is not" ;;
*) no "--binding-driver did not report exactly two notes over verdict-thin-evidence (got: $BD_TE)" ;;
esac
# The wrong-pair note is reported for its PAIR and not for its missing line: a
# wrong pair cannot render a right line, so correcting the field comes first and a
# message sending its reader to the section would send them to the wrong fix.
case "$BD_TE" in
*CLAIM-BD4GG007*'does not carry'*) no "the wrong-pair note was reported against the section - the field is the thing to correct first" ;;
*) ok "a wrong pair is reported against the field, not against the section" ;;
esac
# The count is computed rather than read, and the concentration is the half no
# other field can recover: three source notes with three distinct canonical URLs
# and one counterparty. A rule keyed on the source count alone passes this vault
# whatever it does.
case "$BD_TE" in
*'3 distinct source notes and 1 distinct counterparty'*) ok "the closure count and the counterparty count are both computed" ;;
*) no "the failure does not report 3 sources and 1 counterparty (got: $BD_TE)" ;;
esac
case "$BD_TE" in
*CLAIM-BD4EE005*) ok "a thin closure with no counts stated is reported" ;;
*) no "the note stating no counts was not reported (got: $BD_TE)" ;;
esac
# The wrong-pair half names what the note claims as well as what the closure
# holds, because the fix is to correct the field and a message that reported only
# the computed numbers leaves the reader diffing two documents to find which.
case "$BD_TE" in
*CLAIM-BD4GG007*'evidence_counterparties: \"3\"'*) ok "a stated pair the closure does not hold is reported, with both numbers named" ;;
*) no "the note stating a wrong pair was not reported with its own numbers (got: $BD_TE)" ;;
esac
# The silent side, and the reason the count above is the assertion: the rule asks
# that the concentration be surfaced, not that it be absent. Its pair matches the
# closure AND its section carries the line those two generate, so both halves of
# the conjunction are satisfied - a check that ignored either would report it.
case "$BD_TE" in
*CLAIM-BD4FF006*) no "a thin closure stated in the note and rendered in the section was reported - both halves are satisfied" ;;
*) ok "a thin closure stated in the note and rendered in the section is not reported" ;;
esac

# --- the rendered half of the conjunction, on its own vault ------------------
# The gap a disjunction between the note and the section could never see: the
# ledger is honest and the plan renders nothing. Both verdicts here state a pair
# the closure holds, so the note-side half passes for both and only the rendered
# half can separate them - which is what makes the failure count the assertion.
BD_EU=$("$LINT" --binding-driver --vault "$HERE/verdict-evidence-unrendered" --json 2>/dev/null)
BD_EU_STATUS=$?
[ "$BD_EU_STATUS" = "1" ] && ok "honest counts with nothing rendered beside them fail" ||
	no "verdict-evidence-unrendered should exit 1 (got $BD_EU_STATUS)"
case "$BD_EU" in
*'"failure_count": 1'*) ok "only the corner whose line is missing is reported" ;;
*) no "--binding-driver did not report exactly one note over verdict-evidence-unrendered (got: $BD_EU)" ;;
esac
# The message quotes the exact string the writer has to render, because the line
# is generated off the two fields and matched verbatim - a failure naming only the
# counts leaves its reader guessing at the wording, and a guess is a mismatch.
case "$BD_EU" in
*CLAIM-EU1FF006*'Evidence: 1 source, 1 counterparty'*) ok "the failure quotes the line the section is missing" ;;
*) no "the failure does not quote the generated line (got: $BD_EU)" ;;
esac
# Each noun pluralises on its own numeral, and this vault is where that is
# asserted in both directions at once: the silent corner renders `2 sources, 2
# counterparties` and the failing one owes `1 source, 1 counterparty`. A generator
# that pluralised off the wrong numeral, or off neither, matches one and not the
# other, so the count above moves.
case "$BD_EU" in
*CLAIM-EU1EE005*) no "the corner whose line IS rendered was reported - the plural form did not match" ;;
*) ok "a rendered line matching the note verbatim satisfies the rule" ;;
esac

# A well-evidenced verdict owes no line at all, which is what stops this becoming
# a line on every plan that everyone learns to skip. clean/ carries a verdict
# whose closure reaches three sources from three counterparties, and its section
# carries no `Evidence:` line anywhere - section 1 already requires that vault to
# report nothing, so this asserts the reason.
case "$(cat "$HERE/clean/business-plan.md")" in
*'Evidence:'*) no "the clean plan carries an Evidence line - the healthy case must owe none" ;;
*) ok "a well-evidenced verdict owes no evidence line" ;;
esac

printf '\nrun-fixtures: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
