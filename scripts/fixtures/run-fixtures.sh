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
#      The anchor's section runs to the next heading of the SAME DEPTH OR
#      SHALLOWER, so a corner table inside a ### subsection under it is read and
#      the phrases beside it are in the section; and a plan carrying no corner
#      table at all is told the Kind check did not run, rather than that it
#      agreed.
#  14. A vault whose every byte is CRLF still fires the three checks that need a
#      vocabulary term to compare against, and leaks no carriage return into
#      what it prints. This is the input class no other fixture carried, which is
#      why a vocabulary pass that dropped every term on a CRLF file went
#      unnoticed by all of them. Item 17 below is the same shape one character
#      over, and a count is not written out here because it moves every release.
#  15. --monitoring holds competitor-analysis.md's monitoring plan to named axes
#      with an instrument, a cadence and the decision each would change: it fails
#      an absent section, a section carrying prose and no axis table, and a row
#      that leaves a column empty - including an em-dash cell, which is the half a
#      list of placeholder words would get wrong. Each has its silent side beside
#      it: a complete axis, a table outside the section, a vault with no
#      competitor-analysis.md at its root, and the same document at
#      schemaVersion 1. That last-but-one line names the document it could not
#      open and says the axes went unread, rather than concluding from a missing
#      file that nobody was profiled.
#  16. --deliverable reads the RENDERED deliverables/*.html and fails on a
#      strikethrough span, a note ID and a red-team objection code - the vault
#      addresses that resolve to nothing for the reader the document is for. The
#      silent side is a clean file in the same directory carrying every near miss
#      a looser rule fires on: FACT-CHECKED, an address with an alphanumeric
#      character on either boundary, a lowercase anchor slug, and <span>/<script>.
#  17. A zero-width space is a byte in every comparison that reads a document.
#      Parity was green over four copies of one fence scan while three compared
#      under PowerShell's culture rules, which report a ZWSP-carrying heading
#      EQUAL to one without - so this suite pins the behaviour each implementation
#      must have and scripts/parity/parity.mjs diffs the two over the same vault.
#  18. --assumption-rows reads the model's assumptions table against the notes
#      that declare themselves inputs to it, both directions, and its two escapes
#      each clear it on their own: a rendered row, or a stated exclusion reason.
#      The identity rule beside them fails a revenue line excluded from the model
#      while the roadmap ships a change to it, and clears when the verdict note
#      declares the exclusion in `arr_excludes`. A vault where no note declares
#      itself an input passes and is told so: the row half agreed and the half
#      this mode was written for walked an empty set.
#  19. --claim-drift re-opens a claim whose cited section has been rewritten since
#      the note recorded reading it, reports a citation with no recorded hash and
#      an entry naming a section the note no longer cites, clears on a re-record,
#      and ignores the whitespace a renderer ignores while still moving on a real
#      edit.
#      Both modes are gated on schemaVersion 3 and both are asserted SILENT at 1
#      and at 2, because every corpus that exists is at one of those and carries
#      none of the fields either mode reads.
#  20. --supersession-sweep reads the edge from BOTH ends. A note whose
#      `superseded_by` names a successor that never named it back is a
#      half-written edge and not replaced-by-nothing, a `superseded_by` naming
#      no note in the vault is a third row again, and a well-formed pair beside
#      them stays silent. The back-edge written onto the successor clears it,
#      and neither check is gated on schemaVersion - asserted both ways, on a
#      vault that writes no `superseded_by` and on the same broken edges stamped
#      back down to 1.
#  21. --assumption-rows reads a row's match against the note's `status`. A live
#      row whose only title match is `superseded` or `retracted` is its own
#      failure rather than a match, the sibling row backed by a `current` note
#      stays silent, the same pair is never reported twice under two codes, and
#      re-filing the note as `current` clears it.
#  22. --assumption-rows backs a row with a live `claim` exactly as with a live
#      `assumption` - including the promotion this method prescribes, where the
#      assumption behind a row is retired and a claim carrying the same title
#      replaces it - and retiring that claim puts the row back in the failing
#      set, so the check is widened rather than silenced. The success line prints
#      two counts that legitimately differ, because a row backed by a claim is
#      not a declared model input.
#  23. --assumption-rows reads `status` on the NOTE side too. A retired note
#      declaring `model_input` owes no row and no `excluded_from_model` reason,
#      because both escapes are unsatisfiable on a note the ledger has retired;
#      the live note in the same position still fails, which is what says the
#      half was narrowed rather than switched off. excluded-line-on-roadmap
#      walks the same narrowed set and is asserted silent on a retracted note.
#  24. --citation-codes resolves every [F#] and [S#] a document cites against a
#      row in the index that assigns it, in both index files, with a code inside
#      a fenced block asserted silent. The passing side is the one that shapes
#      the mode: an index legitimately names its own retired codes in its own
#      prose, so the two index files are excluded from the scan. A missing index
#      is asserted to report a half that did not run, and the success line is
#      asserted to state the limit - resolution is necessary and not sufficient,
#      and a success line claiming otherwise is the defect this mode is one of.
#  25. --unflattened-source compares each row of a research file's own local
#      source table against the URLs the root sources.md carries, and its
#      declared exemption is asserted on both sides: the exempt ledger passes and
#      is named in the success line, while the research file beside it is still
#      read. A row carrying no URL is asserted reported as unresolved rather than
#      passed, and a missing sources.md as a mode that did not run.
#  26. --subject-orphan reports a vocabulary subject with no `claim` and no
#      `assumption` under it that the corpus reasons from anyway - by its own key
#      in a note body, and through an alias in a plan document, which is the half
#      an alias-blind implementation passes. Its four silent sides are asserted
#      beside it: a subject nothing mentions, a `required: true` subject that is
#      coverage-gap`s, an unfiled term sharing an alias with a FILED one - the
#      mention belongs to the subject already answered, and only registering
#      every term`s strings keeps it there - and a plan carrying three words a
#      substring scan finds an alias inside. The message is asserted as a DIAGNOSIS - where the corpus
#      leans on the subject, and which note to write - because the mode ships
#      failing rather than gated, and it is not gated on schemaVersion at either
#      end.
#  27. --foreclosed reports a live note that takes an option off the table and
#      never says what would put it back, reads the `assumption` half of the
#      pair as well as the `claim` half, and stays silent over a foreclosure the
#      ledger has retired and over one that declares its reversal condition. The
#      listing is asserted on the passing side, because the mode is a report as
#      much as a verdict and a success line that named nothing would say the
#      corpus forecloses nothing.

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
MODES="check --unverified --used-in --supersession-sweep --release-gate --red-team --roadmap-table --binding-driver --monitoring --deliverable --assumption-rows --claim-drift --citation-codes --unflattened-source --subject-orphan --foreclosed graph"

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

# strip_cr - drop every carriage return from a stream. .gitattributes leaves
# *.md unpinned on purpose (see the comment there), so a fixture note checks
# out CRLF on a POSIX box with core.autocrlf=true exactly as it does on
# Windows - and a line read straight out of one, whether captured from awk or
# piped through it for a rewrite, carries a trailing \r that a literal-string
# comparison against an LF value never has. Four more slices land assertion
# blocks in this file this release; route any new line-vs-literal comparison
# through this helper instead of adding a fourth local `tr -d '\r'`.
strip_cr() {
	tr -d '\r'
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
	# strip_cr: awk's sub() only touches the matched "Violates: " prefix, so a
	# CRLF note hands back "unknown-subject\r" - and tr ',' '\n' | tr -d ' '
	# below does not remove a carriage return, so the per-file grep -q
	# "^$rel $want\$" a few lines down never matches.
	decl=$(awk '/^Violates: / { sub(/^Violates: /, ""); print; exit }' "$HERE/violations/$rel" | strip_cr)
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
	# strip_cr: same CRLF-note reason as the forward check above - without it
	# "$chk" never matches the trailing-\r "$decl" and every fired check reads
	# as fired-without-declaring.
	decl=$(awk '/^Violates: / { sub(/^Violates: /, ""); print; exit }' "$HERE/violations/$rel" 2>/dev/null | strip_cr)
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
# strip_cr feeds awk rather than filtering its output: on a CRLF checkout $0
# carries a trailing \r that the string-equality test never has, so the
# rewrite has to see clean input BEFORE the comparison runs, not after.
strip_cr <"$HERE/clean/business-plan.md" |
	awk '{ if ($0 == "## Competition & moat {#competition}") print "## Why the moat holds {#competition}"; else print }' \
		>"$REWORD/business-plan.md"

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

# --- 2i. the monitoring axes, and the version they apply at -------------------
# The mode reads competitor-analysis.md, so none of the note-level machinery
# above sees it - every assertion about it is written out here. Three shapes,
# each with the silent side beside it: an absent section, a section with no axis
# in it, and a table whose rows are incomplete but not all of them.
printf '\nmonitoring axes\n'

MON_GAP=$("$LINT" --monitoring --vault "$HERE/monitoring-gap" 2>&1)
MON_GAP_STATUS=$?
[ "$MON_GAP_STATUS" = "1" ] && ok "a competitor-analysis.md with no monitoring section fails --monitoring" ||
	no "an absent monitoring section should exit 1 (got $MON_GAP_STATUS)"
case "$MON_GAP" in
*'no `## Monitoring plan` section at all'*) ok "the absent section is named as absent rather than as empty" ;;
*) no "--monitoring did not distinguish an absent section from an empty one (got: $MON_GAP)" ;;
esac
# The Threat ranking table in that same document is pipe rows with free prose in
# the first cell. Read as axes it would report two more failures, so the count is
# the assertion that the section boundary holds.
MON_GAP_J=$("$LINT" --monitoring --vault "$HERE/monitoring-gap" --json 2>/dev/null)
case "$MON_GAP_J" in
*'"failure_count": 1'*) ok "a table outside the monitoring section is not read as an axis" ;;
*) no "--monitoring read a table outside its own section (got: $MON_GAP_J)" ;;
esac

# The same document one version down. Firing at 2 is the check; staying silent at
# 1 is what keeps every corpus with a competitor analysis in it from going red the
# day the skill updates.
MON_AT_1="$PAIRS_FILE.mon-1"
rm -rf "$MON_AT_1"
cp -R "$HERE/monitoring-gap" "$MON_AT_1"
printf '{\n  "schemaVersion": 1,\n  "created": "2026-07-27"\n}\n' >"$MON_AT_1/.vault/config.json"
# Captured once and sliced for both halves: the lint is deterministic for a given
# vault, so a separate run_status call over this one costs a second full parse and
# buys nothing - the same reason the CRLF block further down gives.
MON_AT1_OUT=$("$LINT" --monitoring --vault "$MON_AT_1" 2>&1)
MON_AT1_STATUS=$?
[ "$MON_AT1_STATUS" = "0" ] && ok "the same document at schemaVersion 1 does not owe axes" ||
	no "schemaVersion 1 must not owe monitoring axes (got $MON_AT1_STATUS)"
case "$MON_AT1_OUT" in
*'schemaVersion 2 rule and a vault at 1'*) ok "at 1 the mode says it did not ask, rather than reporting clean" ;;
*) no "at 1 --monitoring reported an empty verdict instead of saying it did not ask (got: $MON_AT1_OUT)" ;;
esac

# A section that gained the heading and no table is the shape an existing corpus
# is in: the wording it replaces asked which pages to re-check and how often.
# Appended to a copy rather than kept as a fourth fixture, for the reason the
# schemaVersion twin above is a copy.
MON_PROSE="$PAIRS_FILE.mon-prose"
rm -rf "$MON_PROSE"
cp -R "$HERE/monitoring-gap" "$MON_PROSE"
{
	printf '\n## Monitoring plan\n\n'
	printf 'Re-check the two pricing pages and the changelog monthly. Every profile\n'
	printf 'above carries its research date as signal freshness.\n'
} >>"$MON_PROSE/competitor-analysis.md"
MON_PROSE_OUT=$("$LINT" --monitoring --vault "$MON_PROSE" 2>&1)
MON_PROSE_STATUS=$?
[ "$MON_PROSE_STATUS" = "1" ] && ok "a monitoring section with prose and no axis table fails" ||
	no "a prose-only monitoring section should exit 1 (got $MON_PROSE_STATUS)"
case "$MON_PROSE_OUT" in
*'section with no axis in it'*) ok "the empty section is named as empty rather than as absent" ;;
*) no "--monitoring reported a present-but-empty section as absent (got: $MON_PROSE_OUT)" ;;
esac

MON_THIN=$("$LINT" --monitoring --vault "$HERE/monitoring-thin" 2>&1)
MON_THIN_STATUS=$?
[ "$MON_THIN_STATUS" = "1" ] && ok "an axis missing a column fails --monitoring" ||
	no "an incomplete axis should exit 1 (got $MON_THIN_STATUS)"
case "$MON_THIN" in
*'axis leaves empty: instrument'*) ok "an axis with no instrument is reported, and the column is named" ;;
*) no "the axis with no instrument was not reported (got: $MON_THIN)" ;;
esac
# The em-dash cell. This is the half a placeholder word list would get wrong, and
# the whole reason the test is letter-or-digit.
case "$MON_THIN" in
*'axis leaves empty: the decision it would change'*) ok "an em dash in the decision column reads as empty, not as an answer" ;;
*) no "an em-dash decision cell was accepted as an answer (got: $MON_THIN)" ;;
esac
# The silent side, and the count is what asserts it: the complete axis and the
# Threat ranking table above it are both in this document, and neither may fire.
MON_THIN_J=$("$LINT" --monitoring --vault "$HERE/monitoring-thin" --json 2>/dev/null)
case "$MON_THIN_J" in
*'"failure_count": 2'*) ok "a complete axis stays silent, and so does the table above the section" ;;
*) no "--monitoring failure_count is not 2 - a complete axis fired, or an incomplete one did not (got: $MON_THIN_J)" ;;
esac

# A vault with no competitor-analysis.md at its root owes nothing, at either
# version. Failing it would fail every corpus before the competitor dimension
# runs. What the line may NOT do is state what it inferred from the absence: it
# said `no competitor set was profiled, so no axis owes an instrument` over a
# vault holding 31 competitor profiles and a written monitoring plan, because the
# document lived somewhere other than the vault root. Absence of the file is not
# absence of the work, so the line names the document it could not open and says
# the axis half did not run.
MON_NONE=$("$LINT" --monitoring --vault "$HERE/dead-citation" 2>&1)
MON_NONE_STATUS=$?
[ "$MON_NONE_STATUS" = "0" ] && ok "a vault with no competitor-analysis.md passes --monitoring" ||
	no "a vault with no competitor-analysis.md should pass (got $MON_NONE_STATUS)"
case "$MON_NONE" in
*"no competitor-analysis.md"*) ok "the absent document is named rather than reported clean" ;;
*) no "--monitoring did not say the document was absent (got: $MON_NONE)" ;;
esac
case "$MON_NONE" in
*'Not read: the monitoring axes'*) ok "the line says the axis half did not run" ;;
*) no "--monitoring did not say the axes went unread (got: $MON_NONE)" ;;
esac
case "$MON_NONE" in
*'no competitor set was profiled'*) no "the line still infers that nobody was profiled from a file it could not find" ;;
*) ok "the line reports what it did not read, not what it concluded from the absence" ;;
esac

# --- 2j. what the rendered deliverable carries out of the vault ---------------
# The mode reads deliverables/*.html, which is the artifact an outside reader
# holds and the only one a fixture can assert - the render itself is a model
# action. Both directions on one vault: business-plan.html leaks and
# one-pager.html is clean, in the same directory.
printf '\ndeliverable\n'

# Captured once and sliced every way below. --json changes how the verdict is
# rendered and never what it is, so the exit code comes off this same run.
DELJ=$("$LINT" --deliverable --vault "$HERE/deliverable-leak" --json 2>/dev/null)
DEL_STATUS=$?
[ "$DEL_STATUS" = "1" ] && ok "a deliverable carrying vault archaeology fails --deliverable" ||
	no "a leaking deliverable should exit 1 (got $DEL_STATUS)"

for want in deliverable-strikethrough deliverable-note-id deliverable-objection-code; do
	case "$DELJ" in
	*"\"check\": \"$want\""*) ok "--deliverable fires $want" ;;
	*) no "--deliverable never fired $want" ;;
	esac
done

# A rendered <del> element and a literal ~~...~~ span are the same failure by two
# routes - the markdown strikethrough rendered, or it did not - and an uppercase
# tag is the same as a lowercase one.
case "$DELJ" in
*'"id": "line 15"'*) ok "a rendered <del> element is reported, by line" ;;
*) no "the <del> element on line 15 was not reported (got: $DELJ)" ;;
esac
case "$DELJ" in
*'"id": "line 18"'*) ok "an uppercase <S> tag is read the same as a lowercase one" ;;
*) no "the uppercase tag on line 18 was not reported (got: $DELJ)" ;;
esac
case "$DELJ" in
*'"id": "line 21"'*) ok "a literal ~~...~~ span that reached the render is reported" ;;
*) no "the literal tilde span on line 21 was not reported (got: $DELJ)" ;;
esac

# Two addresses on one line are two rows, because the unit is the place a reader
# has to go and restate.
case "$DELJ" in
*'"id": "SOURCE-K92MZ1QA"'*) ok "the first of two addresses on one line is reported" ;;
*) no "SOURCE-K92MZ1QA was not reported" ;;
esac
case "$DELJ" in
*'"id": "MILESTONE-PJ40XR63"'*) ok "the second of two addresses on one line is reported too" ;;
*) no "MILESTONE-PJ40XR63 was not reported" ;;
esac

# THE SILENT SIDE, and it is most of what makes this mode usable. one-pager.html
# carries FACT-CHECKED (seven characters, so not the eight a generated ID has),
# an address with an alphanumeric character on either boundary, a lowercase
# anchor slug, <span>/<strong>/<script>, and the two citation codes the block
# below is about - every one of which a looser rule fires on. The count is the
# assertion; a named file would pass while another over-fired.
case "$DELJ" in
*'"failure_count": 7'*) ok "the clean deliverable in the same directory fires nothing" ;;
*) no "--deliverable failure_count is not 7 - the clean file fired, or a leak did not (got: $DELJ)" ;;
esac
case "$DELJ" in
*one-pager*) no "--deliverable reported against the clean one-pager.html" ;;
*) ok "no failure lands on one-pager.html, so the report is per file" ;;
esac

# THE ONE EXEMPTION A READER ACTUALLY DEPENDS ON, named rather than left to be
# read off the count above. `[S#]` and `[F#]` are the plan's own source trace -
# the hop from a figure to the table it came from - and the one piece of
# provenance that is SUPPOSED to reach the artifact, so a mode built to strip
# vault archaeology has to let them through. They survive because of how the
# address pattern is CONSTRUCTED - a type prefix plus EIGHT generated characters,
# which a bracketed letter and a number is not - and not because anything
# carves them out, which is the whole hazard: widen that pattern later (drop the
# eight-character anchor, match a bare type letter) and the mode starts stripping
# the citation trace out of every deliverable it reads. The failure_count above
# would move, but it names no cause and reads as an over-fire anywhere in the
# directory; these two rows name the codes, so the red says what broke.
#
# Both halves are asserted, and the presence half is not ceremony: without it a
# later edit that drops the codes from one-pager.html leaves the exemption
# assertion passing over a file with nothing to be exempt, which is a check that
# has stopped firing and looks exactly like one that fires and finds nothing.
DEL_TRACE_FILE="$HERE/deliverable-leak/deliverables/one-pager.html"
for code in S12 F3; do
	if grep -q "\[$code\]" "$DEL_TRACE_FILE"; then
		ok "one-pager.html carries the [$code] citation code the exemption is about"
	else
		no "one-pager.html no longer carries [$code], so the exemption assertion below reads nothing"
	fi
	# The bare token, not the bracketed form: a widened pattern reports the
	# characters it matched, so a `*"[$code]"*` test would go green over the
	# exact widening this block exists to catch.
	case "$DELJ" in
	*"$code"*) no "--deliverable reported $code - a [S#]/[F#] code is the reader's source trace, not a vault address, and stripping it takes the traceability out of the one document that carries any" ;;
	*) ok "the [$code] citation code is exempt, so the reader's source trace survives the render" ;;
	esac
done

# A vault before Phase 5 has rendered nothing, and the gate runs before the first
# render as well as inside the render loop - so the empty case is the ordinary one
# on the first call and has to say which of the two it is.
DEL_NONE=$("$LINT" --deliverable --vault "$HERE/clean" 2>&1)
DEL_NONE_STATUS=$?
[ "$DEL_NONE_STATUS" = "0" ] && ok "a vault with no deliverables/ passes --deliverable" ||
	no "a vault with nothing rendered should pass (got $DEL_NONE_STATUS)"
case "$DEL_NONE" in
*"no deliverables/*.html"*) ok "nothing-rendered-yet is named rather than reported clean" ;;
*) no "--deliverable did not say nothing had been rendered (got: $DEL_NONE)" ;;
esac

# --- 2k. a zero-width space is a byte, in every comparison that reads a doc ----
# The input class no fixture carried, which is why parity was green over four
# copies of one fence scan while three of them compared under PowerShell's
# culture rules. A culture-aware comparison reports `lenses<U+200B> dispatched`
# EQUAL to `lenses dispatched` and awk does not, so the two implementations read
# different documents - and "no demonstrated impact" was a fact about the corpus
# rather than about the code.
#
# This suite runs ONE implementation, so what it asserts is the behaviour each
# must have; scripts/parity/parity.mjs diffs the two --json documents over this
# same fixture, and the pair of them is the assertion. Both green means both
# implementations answer this vault identically and correctly.
printf '\nzero-width space\n'

ZW_RT=$("$LINT" --red-team --vault "$HERE/fence-zwsp" 2>&1)
ZW_RT_STATUS=$?
[ "$ZW_RT_STATUS" = "1" ] && ok "a zero-width space in the roster heading leaves the roster unread" ||
	no "a ZWSP roster heading must not resolve to the roster (got $ZW_RT_STATUS)"
case "$ZW_RT" in
*red-team-no-roster*) ok "the heading a culture-aware comparison would have matched is reported absent" ;;
*) no "--red-team matched a heading carrying a zero-width space (got: $ZW_RT)" ;;
esac

# The fence half. The fenced row template inside the monitoring section carries a
# zero-width space in both its markers, and its row would read as an axis naming
# nothing if the scan folded that character away - so the count is what asserts
# the fence opened and closed on bytes.
ZW_MON_J=$("$LINT" --monitoring --vault "$HERE/fence-zwsp" --json 2>/dev/null)
case "$ZW_MON_J" in
*'"failure_count": 1'*) ok "a fence whose markers carry a zero-width space still closes" ;;
*) no "the fenced template inside the monitoring section was read as an axis (got: $ZW_MON_J)" ;;
esac
# And the axis whose own NAME carries one is matched on bytes like any other, so
# it answers its three columns and stays silent.
case "$ZW_MON_J" in
*'incumbent'*) no "the complete axis carrying a zero-width space in its name fired" ;;
*) ok "an axis name carrying a zero-width space is read as itself" ;;
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
for part in 'check: note-level checks' '--used-in: citation targets' '--supersession-sweep: supersession blast radius' '--red-team: panel objection rows' '--roadmap-table: roadmap table against the milestone set' '--binding-driver: verdict drivers and the evidence under them' '--monitoring: monitoring axes and the decision each would change' '--deliverable: what the rendered deliverable carries out of the vault' '--assumption-rows: assumption rows against the model table' '--claim-drift: cited sections against their recorded hash' '--citation-codes: citation codes against their index rows' '--unflattened-source: local source rows against the global log' '--subject-orphan: unfiled subjects the corpus reasons about' '--foreclosed: foreclosed options and what would reverse them'; do
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

# Anchored on the name the help text gives ITSELF - the first word of its own
# banner - and never on a literal `vault-lint.sh` or on the basename of $LINT.
#
# A literal fails the port for a cosmetic reason: its --help correctly names
# itself vault-lint.ps1, and matching a literal would force it to print a
# command its reader does not have. The basename of $LINT fails for a worse
# reason: VAULT_LINT may name an INDIRECTION rather than the tool. CI pins the
# port to Windows PowerShell 5.1 through a one-line wrapper script, and
# `vault-lint-ps1-winps51.sh` can never appear in a synopsis line - so every
# mode is reported as having no help block on a tool whose help is complete,
# and nine assertions go red without a single one of them being about help text.
#
# Reading the name out of the output tests the property this census is for -
# each mode has a block - through the indirection instead of past it. The banner
# and the synopsis lines are rendered from the same string on both
# implementations, so a mode that loses its block still fails here: nothing in
# the wrapper, or in any future one, can put `<prog> <mode>` back.
HELP_PROG=$(printf '%s\n' "$HELP_FLAT" | sed -n '1s/^\([^ ][^ ]*\).*/\1/p')
[ -n "$HELP_PROG" ] && ok "--help opens by naming the tool it documents" ||
	no "--help has no program name on its first line - the census below would have nothing to anchor on"

printf '%s\n' "$MODES" | tr ' ' '\n' | grep -v '^$' >"$PAIRS_FILE.modes"
while read -r mode; do
	[ -n "${mode:-}" ] || continue
	case "$HELP_FLAT" in
	*"$HELP_PROG $mode"*) ok "--help documents $mode" ;;
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
# strip_cr, same reason as the reword rewrite above: the anchored pattern
# below needs $0 with no trailing \r or it never matches on a CRLF checkout,
# so the whole file drops through unchanged and "Reach binds" survives.
strip_cr <"$HERE/verdict-unfiled/business-plan.md" |
	awk 'BEGIN { drop = 0 }
		/^## Target & verdict \{#target-verdict\}$/ { print; drop = 1; next }
		/^## / { drop = 0 }
		drop { next }
		{ print }' >"$EMPTY_UF/business-plan.md"

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

# --- the section boundary the corner table is read inside --------------------
# The verdict anchor's section runs to the next heading of the SAME DEPTH OR
# SHALLOWER, so a `###` opened one line into its body leaves the corner table,
# both conditional phrases and the evidence line inside the section. Read to the
# next heading of ANY depth instead - which is what this mode did until a live
# plan opened one - all three fall outside: the mode finds zero corner rows, so
# the Kind check runs in NEITHER direction, and the two condition checks and the
# two evidence checks cry wolf over strings the reader can see. That vault
# reported `1 verdict note against 0 corner verdict rows ... matched verbatim` and
# passed, for as long as the note had existed.
#
# The count is the whole assertion, and it moves in both directions at once: four
# failures under the old boundary, one under this one.
BD_SS=$("$LINT" --binding-driver --vault "$HERE/verdict-subsection" --json 2>/dev/null)
BD_SS_STATUS=$?
[ "$BD_SS_STATUS" = "1" ] && ok "a corner table inside a subsection under the anchor is read" ||
	no "verdict-subsection should exit 1 (got $BD_SS_STATUS)"
case "$BD_SS" in
*'"failure_count": 1'*) ok "only the planted Kind cell is reported - the phrases inside the subsection are in the section" ;;
*) no "--binding-driver did not report exactly one row over verdict-subsection (got: $BD_SS)" ;;
esac
case "$BD_SS" in
*'"check": "verdict-kind-mismatch"'*CLAIM-SS1DD004*) ok "the row inside the subsection is compared against its note" ;;
*) no "the corner table inside the subsection was not read (got: $BD_SS)" ;;
esac
# The three silent sides, each of which fires under a boundary that stops at the
# first `###`: the other corner's Kind cell agrees, both conditional_on phrases
# are written inside the subsection, and so is the line the evidence counts
# generate.
case "$BD_SS" in
*'"check": "verdict-unconditional"'*) no "a conditional_on phrase written inside the subsection was reported missing" ;;
*) ok "a conditional_on phrase inside the subsection is inside the section" ;;
esac
case "$BD_SS" in
*'"check": "verdict-thin-evidence"'*) no "an evidence line written inside the subsection was reported missing" ;;
*) ok "the generated evidence line inside the subsection is inside the section" ;;
esac

# --- no corner table is not agreement ----------------------------------------
# The success line over a vault carrying a verdict note and no corner table under
# the anchor. It must name the Kind check as NOT RUN rather than report a count
# and `matched verbatim`: zero rows compared and zero rows disagreeing end in the
# same words, and only one of them means the check happened. That wording is what
# made the boundary bug above ship as a clean pass over a table nothing opened.
BD_NC=$("$LINT" --binding-driver --vault "$HERE/verdict-no-corner-table" 2>&1)
BD_NC_STATUS=$?
[ "$BD_NC_STATUS" = "0" ] && ok "a verdict note with no corner table under the anchor passes" ||
	no "verdict-no-corner-table should exit 0 (got $BD_NC_STATUS: $BD_NC)"
case "$BD_NC" in
*'no corner verdict table'*'Not checked: the Kind cell'*) ok "the success line names the Kind check as not run rather than as agreed" ;;
*) no "--binding-driver reported a vacuous pass over zero corner rows (got: $BD_NC)" ;;
esac
case "$BD_NC" in
*'matched verbatim'*) no "the no-table line still says matched verbatim - there was nothing to match" ;;
*) ok "the no-table line does not claim a verbatim match" ;;
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

# --- 11. a CRLF vault, which is the input class the corpus never carried ------
# Eighteen fixtures and not one carriage return between them, so a vocabulary
# pass that dropped every term on a CRLF file passed all eighteen - and the
# shell's did, reporting `ok: true` over a vault carrying an unknown subject, an
# alias-as-subject and an uncarried required term. crlf-vocab/_vocab.yml states
# the mechanism; what is asserted here is that the three checks needing a
# vocabulary term still fire, and that no carriage return reaches the output.
printf '\nCRLF vault\n'

# FIRST, and before any behaviour: the bytes, because every assertion below
# passes over an LF copy of this vault while testing nothing. Asserted on EVERY
# line of every file rather than on one CR somewhere, since a partial conversion
# is the shape a hand-edit leaves. .gitattributes says why the pin is there.
#
# COUNTED IN BYTES, WITH NO awk ANYWHERE NEAR IT. Git for Windows' awk reads in
# text mode and hands every pattern a line with no CR - which is the whole
# reason the shell parsed a CRLF vocabulary on Windows while failing on macOS
# and Linux. An `awk !/\r$/` guard here would therefore find no carriage return
# on the one platform where the corpus is CRLF by default, and report this
# fixture as unpinned on the runner it matters most on. tr and wc count bytes,
# the way the workflow's own autocrlf check reads the shebang with head rather
# than through a parser. Every line CRLF means the CR count equals the LF count,
# and both being zero is an empty file rather than a pinned one.
CRLF_LF_ONLY=""
find "$HERE/crlf-vocab" -type f | LC_ALL=C sort >"$PAIRS_FILE.crlf"
while read -r cf; do
	[ -n "${cf:-}" ] || continue
	cr=$(tr -cd '\r' <"$cf" | wc -c | tr -d '[:space:]')
	lf=$(wc -l <"$cf" | tr -d '[:space:]')
	[ "$cr" -gt 0 ] && [ "$cr" = "$lf" ] ||
		CRLF_LF_ONLY="$CRLF_LF_ONLY ${cf#"$HERE"/}($cr/$lf)"
done <"$PAIRS_FILE.crlf"
[ -z "$CRLF_LF_ONLY" ] && ok "every file in crlf-vocab/ is CRLF on this checkout" ||
	no "crlf-vocab/ arrived with LF lines, so it tests nothing:$CRLF_LF_ONLY"

# Captured once and sliced for both halves, the same way the violating vault's
# modes are above: the lint is deterministic for a given vault, so a separate
# run_status call over this one costs a second full parse and buys nothing.
CRLFJSON=$("$LINT" --vault "$HERE/crlf-vocab" --json 2>/dev/null)
CRLF_STATUS=$?
[ "$CRLF_STATUS" = "1" ] && ok "a CRLF vault with subject failures exits 1" ||
	no "a CRLF vault with subject failures should exit 1 (got $CRLF_STATUS)"

# Exactly three, which is both halves at once: the three vocabulary-dependent
# checks fired, AND the carriage return leaked into no field value on the way -
# a CR surviving into a required field or a list item shows up here as extra
# required-field and malformed-edge reports rather than as a wrong-looking one.
case "$CRLFJSON" in
*'"failure_count": 3'*) ok "a CRLF vault reports exactly its three subject failures" ;;
*) no "a CRLF vault did not report exactly three failures (got: $CRLFJSON)" ;;
esac

# One assertion per check, each naming the file AND the term it resolved
# against, because the terms are what the bug destroys. coverage-gap needs the
# term and its `required` value; near-miss needs the alias record and the key it
# maps to; unknown-subject needs a term list to have failed to match against.
case "$CRLFJSON" in
*'_vocab.yml'*coverage-gap*'required subject `defensibility`'*)
	ok "coverage-gap fires over CRLF - the term and its required flag parsed" ;;
*) no "coverage-gap did not fire over a CRLF vocabulary (got: $CRLFJSON)" ;;
esac
case "$CRLFJSON" in
*CLAIM-CR1DD004*near-miss-subject*'`pricing` is an alias of `price-anchor`'*)
	ok "near-miss-subject fires over CRLF - the alias record parsed" ;;
*) no "near-miss-subject did not fire over a CRLF vocabulary (got: $CRLFJSON)" ;;
esac
case "$CRLFJSON" in
*CLAIM-CR1EE005*unknown-subject*'subject `despatch-cycle` matches no vocabulary key'*)
	ok "unknown-subject fires over CRLF - there was a term list to miss" ;;
*) no "unknown-subject did not fire over a CRLF vocabulary (got: $CRLFJSON)" ;;
esac

# And the note side, on the same vault: a carriage return that survived parsing
# reappears in what the reader is shown. graph prints a block scalar body and a
# title read straight off the frontmatter, so a stray CR lands in stdout - where
# it overwrites the start of the line on a terminal and makes the output read as
# truncated rather than as wrong.
CRLF_GRAPH=$("$LINT" graph SOURCE-CR1AA001 --vault "$HERE/crlf-vocab" --depth 1 2>/dev/null)
case "$CRLF_GRAPH" in
*'quote: Published list prices in the category clustered'*)
	ok "a CRLF block scalar returns its body" ;;
*) no "a CRLF block scalar body is missing from graph output (got: $CRLF_GRAPH)" ;;
esac
CRLF_CR_COUNT=$(printf '%s' "$CRLF_GRAPH" | tr -cd '\r' | wc -c | tr -d ' ')
[ "$CRLF_CR_COUNT" = "0" ] && ok "no carriage return reaches the output of a CRLF vault" ||
	no "$CRLF_CR_COUNT carriage return(s) leaked into the output of a CRLF vault"

# --- 18. the model's inputs against the notes that declare them --------------
# --assumption-rows is the inverse of a rule that was correct and had no
# counterpart, so the assertions below have to cover the inverse in BOTH
# directions and both of its escapes. The escapes are the half that decides
# whether the rule is usable: an input with a row and an input with a stated
# exclusion are both fine, and a check that failed either would fail every model
# that legitimately leaves a line out.
printf '\nmodel inputs\n'

AR_MRM=$("$LINT" --assumption-rows --vault "$HERE/model-row-missing" --json 2>/dev/null)
AR_MRM_STATUS=$?
[ "$AR_MRM_STATUS" = "1" ] && ok "a declared model input with no row and no exclusion fails" ||
	no "model-row-missing should exit 1 (got $AR_MRM_STATUS)"

# The count is the assertion with teeth. The sibling note in that vault IS
# rendered as a row, so a rule that reported every declared input would fire
# twice here and still clear a census looking only for the check name.
case "$AR_MRM" in
*'"failure_count": 1'*) ok "the input the table does render is not reported" ;;
*) no "--assumption-rows did not report exactly one input over model-row-missing (got: $AR_MRM)" ;;
esac
case "$AR_MRM" in
*'"check": "assumption-not-in-model"'*ASSUMPTION-MR22BB02*) ok "the failure lands on the note the table has no row for" ;;
*) no "assumption-not-in-model did not report ASSUMPTION-MR22BB02 (got: $AR_MRM)" ;;
esac

# ESCAPE ONE - the row. Asserted on a copy with the row appended, the way the
# rewording and section-stripping assertions above build the corpus they need.
# strip_cr on the read, because the anchored grep guard below reads the rewritten
# copy and a CRLF checkout would otherwise leave it comparing a line with a
# trailing carriage return against a literal that has none.
AR_ROW="$PAIRS_FILE.model-row-added"
rm -rf "$AR_ROW"
cp -R "$HERE/model-row-missing" "$AR_ROW"
strip_cr <"$HERE/model-row-missing/financial-model.md" |
	awk '{ print }
		/^\| A-1 \|/ { print "| A-2 | Metered overage is billed on the same invoice as the seats | one invoice | [S2] | L |" }' >"$AR_ROW/financial-model.md"
if grep -q '^| A-2 | Metered overage is billed on the same invoice as the seats |' "$AR_ROW/financial-model.md"; then
	ok "the copy with the row appended carries it"
else
	no "the row-appending rewrite did not land - the assertion below would pass over an unchanged vault"
fi
AR_ROW_STATUS=$(run_status "$AR_ROW" --assumption-rows)
[ "$AR_ROW_STATUS" = "0" ] && ok "adding the row clears assumption-not-in-model" ||
	no "a rendered row must clear the rule (got $AR_ROW_STATUS)"

# ESCAPE TWO - the stated exclusion. Both escapes are asserted because the rule
# is a disjunction: testing only the row would pass an implementation that had
# dropped `excluded_from_model` entirely, and every model that correctly leaves a
# line out would then be red with no way to say so.
AR_EXC="$PAIRS_FILE.model-row-excluded"
rm -rf "$AR_EXC"
cp -R "$HERE/model-row-missing" "$AR_EXC"
strip_cr <"$HERE/model-row-missing/assumptions/ASSUMPTION-MR22BB02.md" |
	awk '{ print }
		/^model_input: revenue$/ { print "excluded_from_model: \"billed on a separate cycle, so it is modelled in the metered sheet rather than here\"" }' >"$AR_EXC/assumptions/ASSUMPTION-MR22BB02.md"
if grep -q '^excluded_from_model: ' "$AR_EXC/assumptions/ASSUMPTION-MR22BB02.md"; then
	ok "the copy with the exclusion reason carries it"
else
	no "the exclusion-adding rewrite did not land - the assertion below would pass over an unchanged vault"
fi
AR_EXC_STATUS=$(run_status "$AR_EXC" --assumption-rows)
[ "$AR_EXC_STATUS" = "0" ] && ok "stating the exclusion reason clears assumption-not-in-model" ||
	no "a stated exclusion must clear the rule (got $AR_EXC_STATUS)"

# THE REVERSE DIRECTION, one vault over. Without it the rule above is cleared by
# writing a row nothing in the ledger stands behind, which is the dodge
# --red-team checks its roster both ways to close. Two of that vault's three rows
# match their notes verbatim, so the count is what says only the planted one is
# reported - and its second table sits outside the assumptions section, which is
# what asserts that only the FIRST table under that heading is read.
AR_MER=$("$LINT" --assumption-rows --vault "$HERE/model-extra-row" --json 2>/dev/null)
AR_MER_STATUS=$?
[ "$AR_MER_STATUS" = "1" ] && ok "a model row matching no assumption note fails" ||
	no "model-extra-row should exit 1 (got $AR_MER_STATUS)"
case "$AR_MER" in
*'"failure_count": 1'*) ok "the two rows that match their notes verbatim are not reported" ;;
*) no "--assumption-rows did not report exactly one row over model-extra-row (got: $AR_MER)" ;;
esac
case "$AR_MER" in
*'"check": "model-row-no-assumption"'*'Referral traffic converts at the paid-channel rate'*)
	ok "the failure quotes the row that escaped the ledger" ;;
*) no "model-row-no-assumption did not name the planted row (got: $AR_MER)" ;;
esac

# THE IDENTITY DECLARES ITS COMPOSITION, and this is the highest-cost defect in
# the release. The excluded line is on the roadmap, so the ARR term every corner
# of the target is solved against is a subset figure - and the count is what says
# the sibling input the model DOES carry is silent, and that the stated exclusion
# has already cleared assumption-not-in-model on the same note.
AR_EOR=$("$LINT" --assumption-rows --vault "$HERE/excluded-on-roadmap" --json 2>/dev/null)
AR_EOR_STATUS=$?
[ "$AR_EOR_STATUS" = "1" ] && ok "a revenue line excluded from the model and shipped on the roadmap fails" ||
	no "excluded-on-roadmap should exit 1 (got $AR_EOR_STATUS)"
case "$AR_EOR" in
*'"failure_count": 1'*) ok "the stated exclusion clears the row rule and only the identity rule fires" ;;
*) no "--assumption-rows did not report exactly one failure over excluded-on-roadmap (got: $AR_EOR)" ;;
esac
case "$AR_EOR" in
*'"check": "excluded-line-on-roadmap"'*MILESTONE-EX33CC03*)
	ok "the failure names the roadmap item that ships the excluded line" ;;
*) no "excluded-line-on-roadmap did not name the milestone (got: $AR_EOR)" ;;
esac

# And declaring it at the identity clears it, which is the whole point: an
# exclusion is legitimate and an undeclared one is the defect. Asserted on a copy
# with `arr_excludes` added to the verdict note - without this half the rule reads
# as banning the exclusion outright, which is a rule about modelling rather than
# about the identity and one a good model would have to break.
AR_DECL="$PAIRS_FILE.arr-declared"
rm -rf "$AR_DECL"
cp -R "$HERE/excluded-on-roadmap" "$AR_DECL"
strip_cr <"$HERE/excluded-on-roadmap/claims/CLAIM-EX44DD04.md" |
	awk '{ print }
		/^evidence_counterparties: "1"$/ { print "arr_excludes:"; print "  - ASSUMPTION-EX22BB02" }' >"$AR_DECL/claims/CLAIM-EX44DD04.md"
if grep -q '^arr_excludes:$' "$AR_DECL/claims/CLAIM-EX44DD04.md"; then
	ok "the copy with arr_excludes on the verdict note carries it"
else
	no "the arr_excludes rewrite did not land - the assertion below would pass over an unchanged vault"
fi
AR_DECL_STATUS=$(run_status "$AR_DECL" --assumption-rows)
[ "$AR_DECL_STATUS" = "0" ] && ok "naming the line in arr_excludes at the identity clears it" ||
	no "a declared exclusion must clear the rule (got $AR_DECL_STATUS)"

# THE REGRESSION THIS MODE MUST NOT CAUSE, and it is the most important assertion
# in this section. Every corpus that exists is at schemaVersion 1 or 2 and
# carries none of the three fields this mode reads, so a rule that fired
# unconditionally would turn every finished vault red on the day the plugin
# updates - which is how a gate stops being run. Both versions, and both are told
# the rule was not applied rather than that their table agrees.
AR_S1=$("$LINT" --assumption-rows --vault "$HERE/clean" 2>&1)
AR_S1_STATUS=$?
[ "$AR_S1_STATUS" = "0" ] && ok "a schemaVersion 1 vault carrying none of the new fields passes" ||
	no "schemaVersion 1 must not owe a model table (got $AR_S1_STATUS: $AR_S1)"
case "$AR_S1" in
*'schemaVersion 3 rule and this vault is at 1'*) ok "at 1 the mode says it did not ask, rather than reporting agreement" ;;
*) no "at 1 --assumption-rows reported a clean table instead of saying it did not ask (got: $AR_S1)" ;;
esac
AR_S2=$("$LINT" --assumption-rows --vault "$HERE/schema-2" 2>&1)
AR_S2_STATUS=$?
[ "$AR_S2_STATUS" = "0" ] && ok "a schemaVersion 2 vault carrying none of the new fields passes" ||
	no "schemaVersion 2 must not owe a model table (got $AR_S2_STATUS: $AR_S2)"

# And the silent side at 3: a vault with no declared inputs and no table owes
# nothing, which is every corpus between the stamp and the first model row.
AR_NONE=$("$LINT" --assumption-rows --vault "$HERE/claim-drift" 2>&1)
AR_NONE_STATUS=$?
[ "$AR_NONE_STATUS" = "0" ] && ok "a vault at 3 with no declared inputs and no table passes" ||
	no "a vault with no model on either side should pass (got $AR_NONE_STATUS: $AR_NONE)"
case "$AR_NONE" in
*'no declared model inputs and no assumption rows'*) ok "the absent model is named rather than reported clean" ;;
*) no "--assumption-rows did not say there was no model (got: $AR_NONE)" ;;
esac

# The half that ran and the half that did not, told apart in the success line.
# This mode is two checks, and with no note carrying `model_input` the direction
# it was WRITTEN for - an input the ledger holds and the table never renders -
# iterates over an empty set. The old line printed the row count and `matched
# verbatim` and said nothing about that, so a vault whose notes never declared an
# input read exactly like one whose declared inputs all reached the table.
AR_ND=$("$LINT" --assumption-rows --vault "$HERE/model-no-declared-input" 2>&1)
AR_ND_STATUS=$?
[ "$AR_ND_STATUS" = "0" ] && ok "a table whose every row matches a note, with no declared input, passes" ||
	no "model-no-declared-input should exit 0 (got $AR_ND_STATUS: $AR_ND)"
case "$AR_ND" in
*'against no declared model inputs'*'Not checked: whether a declared input reached the table'*)
	ok "the success line names assumption-not-in-model as not run" ;;
*) no "--assumption-rows reported a vacuous pass over zero declared inputs (got: $AR_ND)" ;;
esac
case "$AR_ND" in
*'matched verbatim'*) no "the no-input line still says matched verbatim - one of its two halves matched nothing" ;;
*) ok "the no-input line does not claim both halves agreed" ;;
esac

# The closed word list, in `check` rather than here because it reads nothing but
# the note. A third word is a note that declares nothing while reading as
# declared, so the row it owes is never asked for - the same failure the field
# exists to fix, reintroduced by a typo.
AR_WORD="$PAIRS_FILE.model-input-word"
rm -rf "$AR_WORD"
cp -R "$HERE/model-row-missing" "$AR_WORD"
strip_cr <"$HERE/model-row-missing/assumptions/ASSUMPTION-MR11AA01.md" |
	awk '{ sub(/^model_input: revenue$/, "model_input: turnover"); print }' >"$AR_WORD/assumptions/ASSUMPTION-MR11AA01.md"
if grep -q '^model_input: turnover$' "$AR_WORD/assumptions/ASSUMPTION-MR11AA01.md"; then
	ok "the copy with a fourth model_input word carries it"
else
	no "the model_input rewrite did not land - the assertion below would pass over an unchanged vault"
fi
AR_WORD_OUT=$("$LINT" --vault "$AR_WORD" --json 2>/dev/null)
case "$AR_WORD_OUT" in
*'"check": "model-input-unknown"'*turnover*) ok "a fourth model_input word is reported by name" ;;
*) no "model-input-unknown did not fire on an unrecognised value (got: $AR_WORD_OUT)" ;;
esac

# --- 19. a rewritten section re-opens the claim that cited it ----------------
# --claim-drift is the half --used-in deliberately leaves out, and the case it
# exists for is a claim that was reconciled ONCE and then quietly undone: the
# heading is untouched, so the citation still resolves and every other check
# passes while the prose the claim stands on has been rewritten. Each of its three
# codes gets a note in one vault, and one note in that vault records the correct
# hash - so the failure COUNT is what says the mode is not simply re-opening
# everything.
printf '\ncited-section drift\n'

CD_OUT=$("$LINT" --claim-drift --vault "$HERE/claim-drift" --json 2>/dev/null)
CD_STATUS=$?
[ "$CD_STATUS" = "1" ] && ok "--claim-drift exits 1 when a cited section has moved" ||
	no "claim-drift should exit 1 (got $CD_STATUS)"
case "$CD_OUT" in
*'"failure_count": 3'*) ok "the claim whose recorded hash still matches is not reported" ;;
*) no "--claim-drift did not report exactly three failures over claim-drift (got: $CD_OUT)" ;;
esac
case "$CD_OUT" in
*'"check": "section-hash-drifted"'*CLAIM-CD11AA01*) ok "a recorded hash the section no longer matches re-opens the claim" ;;
*) no "section-hash-drifted did not report CLAIM-CD11AA01 (got: $CD_OUT)" ;;
esac

# The message carries the CURRENT hash, and that is what makes a read-only tool
# usable: there is no write mode in this script, so re-reconciling is re-reading
# the section and pasting one token. A failure that named the mismatch without
# the value to paste would send its reader to compute a hash by hand.
case "$CD_OUT" in
*'now hashes to `3a243b97`'*) ok "the failure carries the hash to paste after the re-read" ;;
*) no "section-hash-drifted did not name the current hash (got: $CD_OUT)" ;;
esac

# The omission side. Without it the whole rule is cleared by leaving the field
# off, and a dodge available by omission is not an exemption.
case "$CD_OUT" in
*'"check": "section-hash-missing"'*CLAIM-CD33CC03*) ok "a resolving citation with no recorded hash is reported" ;;
*) no "section-hash-missing did not report CLAIM-CD33CC03 (got: $CD_OUT)" ;;
esac

# And the other direction, for the reason --red-team checks its roster both ways:
# an entry for a section the note no longer cites is a hash nothing compares, and
# to anybody counting entries against citations it reads as covered.
case "$CD_OUT" in
*'"check": "section-hash-unused"'*CLAIM-CD44DD04*) ok "an entry naming a section used_in does not is reported" ;;
*) no "section-hash-unused did not report CLAIM-CD44DD04 (got: $CD_OUT)" ;;
esac

# RE-RECONCILING CLEARS IT. Asserted on a copy where the stale hash is replaced
# with the current one - which is exactly what an author does after re-reading the
# block - because a mode that re-opened a claim no correction could close would be
# a red nobody can clear and therefore one nobody reads.
CD_FIX="$PAIRS_FILE.claim-reconciled"
rm -rf "$CD_FIX"
cp -R "$HERE/claim-drift" "$CD_FIX"
strip_cr <"$HERE/claim-drift/claims/CLAIM-CD11AA01.md" |
	awk '{ sub(/#why-now 00000000/, "#why-now 3a243b97"); print }' >"$CD_FIX/claims/CLAIM-CD11AA01.md"
if grep -q '#why-now 3a243b97' "$CD_FIX/claims/CLAIM-CD11AA01.md"; then
	ok "the re-reconciled copy records the current hash"
else
	no "the re-reconcile rewrite did not land - the assertion below would pass over an unchanged vault"
fi
CD_FIX_OUT=$("$LINT" --claim-drift --vault "$CD_FIX" --json 2>/dev/null)
case "$CD_FIX_OUT" in
*'"failure_count": 2'*) ok "recording the current hash clears section-hash-drifted" ;;
*) no "re-reconciling must clear the drift and leave the other two (got: $CD_FIX_OUT)" ;;
esac
case "$CD_FIX_OUT" in
*section-hash-drifted*) no "the re-reconciled claim is still reported as drifted" ;;
*) ok "no drift is reported once the recorded hash matches" ;;
esac

# THE HASH IS OVER BYTES AND IGNORES WHAT A RENDERER IGNORES. Trailing whitespace
# and a doubled blank line are invisible in a rendered document, so a hash
# sensitive to either would re-open every claim in the corpus the first time an
# editor trimmed a file - and a red that fires on whitespace is one whose fix
# becomes re-stamping the hash without reading anything.
CD_WS="$PAIRS_FILE.claim-whitespace"
rm -rf "$CD_WS"
cp -R "$HERE/claim-drift" "$CD_WS"
strip_cr <"$HERE/claim-drift/business-plan.md" |
	awk '/^Seats, billed monthly/ { print $0 "   "; print ""; next } { print }' >"$CD_WS/business-plan.md"
if grep -q 'Seats, billed monthly, with a metered layer above them\.   $' "$CD_WS/business-plan.md"; then
	ok "the whitespace copy carries the trailing spaces and the extra blank line"
else
	no "the whitespace rewrite did not land - the assertion below would pass over an unchanged vault"
fi
CD_WS_OUT=$("$LINT" --claim-drift --vault "$CD_WS" --json 2>/dev/null)
case "$CD_WS_OUT" in
*CLAIM-CD22BB02*) no "trailing whitespace re-opened a claim - the hash is sensitive to what a renderer drops" ;;
*) ok "trailing whitespace and a doubled blank line leave the hash unchanged" ;;
esac

# And a real edit to the prose DOES move it, which is the other half: a
# normaliser that dropped too much would pass this fixture and the mode would
# assert nothing at all.
CD_ED="$PAIRS_FILE.claim-edited"
rm -rf "$CD_ED"
cp -R "$HERE/claim-drift" "$CD_ED"
strip_cr <"$HERE/claim-drift/business-plan.md" |
	awk '{ sub(/^Seats, billed monthly, with a metered layer above them\.$/, "Seats, billed annually, with no metered layer above them."); print }' >"$CD_ED/business-plan.md"
if grep -q '^Seats, billed annually, with no metered layer above them\.$' "$CD_ED/business-plan.md"; then
	ok "the edited copy carries the rewritten sentence"
else
	no "the prose rewrite did not land - the assertion below would pass over an unchanged vault"
fi
CD_ED_OUT=$("$LINT" --claim-drift --vault "$CD_ED" --json 2>/dev/null)
case "$CD_ED_OUT" in
*'"check": "section-hash-drifted"'*CLAIM-CD22BB02*) ok "a rewritten sentence re-opens the claim that cited that section" ;;
*) no "an edited section did not re-open its claim (got: $CD_ED_OUT)" ;;
esac

# THE REGRESSION THIS MODE MUST NOT CAUSE, and the single most important
# assertion in this section: every claim in every finished corpus is already
# cited into a plan, so a rule demanding a recorded hash from each of them fires
# on every existing vault the moment a user upgrades. Both versions, and both are
# told the rule was not applied.
CD_S1=$("$LINT" --claim-drift --vault "$HERE/clean" 2>&1)
CD_S1_STATUS=$?
[ "$CD_S1_STATUS" = "0" ] && ok "a schemaVersion 1 vault carrying none of the new fields passes" ||
	no "schemaVersion 1 must not owe a recorded section hash (got $CD_S1_STATUS: $CD_S1)"
case "$CD_S1" in
*'schemaVersion 3 rule and this vault is at 1'*) ok "at 1 the mode says it did not ask, rather than reporting agreement" ;;
*) no "at 1 --claim-drift reported clean instead of saying it did not ask (got: $CD_S1)" ;;
esac
CD_S2=$(run_status "$HERE/schema-2" --claim-drift)
[ "$CD_S2" = "0" ] && ok "a schemaVersion 2 vault carrying none of the new fields passes" ||
	no "schemaVersion 2 must not owe a recorded section hash (got $CD_S2)"

# The silent side at 3: a vault whose notes cite no resolving section owes
# nothing, which is every corpus before drafting cites one. A dead anchor is
# --used-in verdict and is deliberately not reported twice here.
CD_NONE=$("$LINT" --claim-drift --vault "$HERE/model-row-missing" 2>&1)
CD_NONE_STATUS=$?
[ "$CD_NONE_STATUS" = "0" ] && ok "a vault at 3 whose notes cite no section passes" ||
	no "a vault with nothing cited should pass (got $CD_NONE_STATUS: $CD_NONE)"
case "$CD_NONE" in
*'no current claim or assumption names a resolving document section'*)
	ok "the absent citation is named rather than reported clean" ;;
*) no "--claim-drift did not say there was nothing cited (got: $CD_NONE)" ;;
esac

# --- 20. the supersession edge has two ends -----------------------------------
# The sweep walks `supersedes`, which lives on the SUPERSEDING note - so until
# now a note recording its own replacement in `superseded_by` whose named
# successor never wrote the other half was invisible from both directions at
# once, and printed under `superseded by: nothing`. That says the record names no
# replacement, when in fact it names one and the other end is missing, and the
# two need different repairs. Observed: an assumption backing a live model row
# carried `superseded_by`, the sweep reported it as replaced by nothing, and
# three current claims went on resting on the dead note.
#
# The vault carries a well-formed pair alongside the two broken ones, so the
# COUNT is the assertion with teeth: a rule that reported every note carrying
# `superseded_by` would fire three times here and still clear a census looking
# only for the check names.
printf '\nhalf-written supersession edges\n'

HE=$("$LINT" --supersession-sweep --vault "$HERE/supersession-half-edge" --json 2>/dev/null)
HE_STATUS=$?
[ "$HE_STATUS" = "1" ] && ok "a half-written supersession edge fails the sweep" ||
	no "supersession-half-edge should exit 1 (got $HE_STATUS)"
case "$HE" in
*'"broken_edge_count": 2'*) ok "the well-formed pair beside them is not reported" ;;
*) no "the sweep did not report exactly two half-written edges (got: $HE)" ;;
esac

# The two codes are separate rows because the repairs differ: one line on a note
# the record already names, versus a successor that has to be written or a typo
# fixed. Folding them into one code would send half the readers to the wrong fix.
case "$HE" in
*'"id": "ASSUMPTION-HE1CC003"'*'"check": "superseded-by-unreciprocated"'*)
	ok "a successor that does not name its predecessor back is reported by name" ;;
*) no "superseded-by-unreciprocated did not name ASSUMPTION-HE1CC003 (got: $HE)" ;;
esac
# Both globs are anchored INSIDE one row - id first, then the code - because a
# `check` glob followed by an ID matches an ID that turns up anywhere later in
# the document, and `reached_no_document` further down carries both of these.
# An assertion satisfied by a different section is one that passes while the row
# it names reports the wrong note.
case "$HE" in
*'"id": "ASSUMPTION-HE1EE005"'*'"check": "superseded-by-dangling"'*)
	ok "a superseded_by naming no note in the vault is a separate row" ;;
*) no "superseded-by-dangling did not name ASSUMPTION-HE1EE005 (got: $HE)" ;;
esac

# THE ROW IT REPLACES. Under the bug this note read as replaced by nothing at
# all, so the assertion that has teeth is the worklist row itself carrying the
# successor the record names - a check that only counted failures would pass
# while the worklist went on telling its reader there was nothing to look for.
case "$HE" in
*'"declared_superseded_by": "CLAIM-HE1DD004", "edge_state": "unreciprocated"'*)
	ok "the worklist row names the successor instead of reporting replaced-by-nothing" ;;
*) no "the worklist row did not carry the declared successor (got: $HE)" ;;
esac
case "$HE" in
*'superseded by: nothing'*) no "a note whose record names a successor still printed replaced-by-nothing" ;;
*) ok "replaced-by-nothing is not printed over a note whose record names a successor" ;;
esac

# THE PASSING COUNTERPART, asserted on a copy with the back-edge written. Without
# it the rule reads as failing every `superseded_by` in existence, and the fix it
# asks for would have no way to clear it.
HE_FIX="$PAIRS_FILE.half-edge-closed"
rm -rf "$HE_FIX"
cp -R "$HERE/supersession-half-edge" "$HE_FIX"
strip_cr <"$HERE/supersession-half-edge/claims/CLAIM-HE1DD004.md" |
	awk '{ print }
		/^stale_after: "2099-12-31"$/ {
			print "supersedes:"
			print "  - ASSUMPTION-HE1CC003"
			print "supersedes_reason: \"Onboarding went self-serve, so the flat-load figure no longer holds.\""
			print "reconciled: \"2026-07-20\""
		}' >"$HE_FIX/claims/CLAIM-HE1DD004.md"
if grep -q '^  - ASSUMPTION-HE1CC003$' "$HE_FIX/claims/CLAIM-HE1DD004.md"; then
	ok "the copy with the back-edge written carries it"
else
	no "the back-edge rewrite did not land - the assertion below would pass over an unchanged vault"
fi
HE_FIX_OUT=$("$LINT" --supersession-sweep --vault "$HE_FIX" --json 2>/dev/null)
case "$HE_FIX_OUT" in
*'"broken_edge_count": 1'*) ok "writing the other end of the edge clears its row" ;;
*) no "the back-edge did not clear superseded-by-unreciprocated (got: $HE_FIX_OUT)" ;;
esac

# NOT GATED ON schemaVersion, and both directions of that need asserting.
# Sliced off $SC rather than re-invoking the lint over the clean vault, per the
# capture-once rule above; 2e already asserts that vault exits 0, and a second
# copy of that assertion here would only make the suite slower.
case "$SC" in
*'"broken_edge_count": 0'*) ok "a vault writing no superseded_by owes neither new check" ;;
*) no "a clean sweep reported a broken edge, or dropped the count (got: $SC)" ;;
esac

# The direction that has teeth: the SAME half-written edges at schemaVersion 1
# still fail. A check gated on the version would go silent here, and every
# corpus in existence is at 1 or 2 - so a rule that only fired at 3 would leave
# the failure this slice exists for invisible on exactly the vaults carrying it.
HE_AT1="$PAIRS_FILE.half-edge-at-1"
rm -rf "$HE_AT1"
cp -R "$HERE/supersession-half-edge" "$HE_AT1"
printf '{\n  "schemaVersion": 1,\n  "created": "2026-07-31"\n}\n' >"$HE_AT1/.vault/config.json"
if grep -q '"schemaVersion": 1' "$HE_AT1/.vault/config.json"; then
	ok "the copy stamped at schemaVersion 1 carries it"
else
	no "the schemaVersion rewrite did not land - the assertion below would pass over an unchanged vault"
fi
HE_AT1_OUT=$("$LINT" --supersession-sweep --vault "$HE_AT1" --json 2>/dev/null)
HE_AT1_STATUS=$?
[ "$HE_AT1_STATUS" = "1" ] && ok "the same half-written edges still fail at schemaVersion 1" ||
	no "a half-written edge must fail at 1 as well (got $HE_AT1_STATUS)"
case "$HE_AT1_OUT" in
*'"broken_edge_count": 2'*) ok "neither new check is gated on the version" ;;
*) no "the count changed at schemaVersion 1 (got: $HE_AT1_OUT)" ;;
esac

# --- 21. a live model row backed only by a retired note -----------------------
# `--assumption-rows` matched a row against every assumption title regardless of
# `status`, so a live row whose only match was `superseded` matched cleanly and
# the mode printed `matched verbatim` over it. Observed as exactly that: a live
# row in the assumptions table backed only by a superseded note, green for days.
# One of the three rows in this vault is backed by a `current` note, so the count
# is what says the status is read rather than the whole table flagged.
printf '\nretired notes behind live model rows\n'

MRS=$("$LINT" --assumption-rows --vault "$HERE/model-row-superseded" --json 2>/dev/null)
MRS_STATUS=$?
[ "$MRS_STATUS" = "1" ] && ok "a live row backed only by a retired note fails" ||
	no "model-row-superseded should exit 1 (got $MRS_STATUS)"
case "$MRS" in
*'"failure_count": 2'*) ok "the row whose note is current is not reported" ;;
*) no "--assumption-rows did not report exactly two rows over model-row-superseded (got: $MRS)" ;;
esac

# BOTH RETIRED STATUSES. A check reading only `superseded` would leave a
# withdrawn assumption backing a live row, which is the same defect under the
# other word the schema allows - and the message has to name the status, because
# re-file and point-at-the-successor are different repairs.
# One case per status, each anchored inside its own row. Written as one glob,
# `status: superseded` matches the FIRST failure and the second note ID then
# matches anywhere after it - so the word `retracted` is never asserted at all,
# and hardcoding `superseded` into the message would still pass.
case "$MRS" in
*'"id": "ASSUMPTION-MS22BB02"'*'status: superseded'*)
	ok "a superseded note behind a live row is reported with its status" ;;
*) no "model-row-dead-assumption did not name the superseded note status (got: $MRS)" ;;
esac
case "$MRS" in
*'"id": "ASSUMPTION-MS33CC03"'*'status: retracted'*)
	ok "a retracted note behind a live row is reported with its status" ;;
*) no "model-row-dead-assumption did not name the retracted note status (got: $MRS)" ;;
esac
case "$MRS" in
*'"check": "model-row-no-assumption"'*)
	no "a retired match was reported as a row matching nothing - the two repairs differ" ;;
*) ok "a retired match is not reported as a row matching no note at all" ;;
esac

# ONE SITUATION, ONE FAILURE. Both retired notes declare `model_input`, and
# neither may ALSO be reported as an input the table has no row for - that is a
# second row pointing at a different repair. Two independent things now hold this:
# the row loop marks the title hit, and the note side skips a retired note
# outright. Section 23 asserts the second directly; this asserts the pair.
case "$MRS" in
*'"check": "assumption-not-in-model"'*)
	no "the retired note was reported twice, as a dead row and as an input with no row" ;;
*) ok "a retired note behind a rendered row is not also an input with no row" ;;
esac

# THE PASSING COUNTERPART. Re-filing the note as current clears its row, which is
# one of the two repairs the message names - without this the rule reads as
# banning a title that ever belonged to a retired note.
MRS_FIX="$PAIRS_FILE.model-row-refiled"
rm -rf "$MRS_FIX"
cp -R "$HERE/model-row-superseded" "$MRS_FIX"
strip_cr <"$HERE/model-row-superseded/assumptions/ASSUMPTION-MS22BB02.md" |
	awk '{ sub(/^status: superseded$/, "status: current"); print }' >"$MRS_FIX/assumptions/ASSUMPTION-MS22BB02.md"
if grep -q '^status: current$' "$MRS_FIX/assumptions/ASSUMPTION-MS22BB02.md"; then
	ok "the copy with the note re-filed as current carries it"
else
	no "the status rewrite did not land - the assertion below would pass over an unchanged vault"
fi
MRS_FIX_OUT=$("$LINT" --assumption-rows --vault "$MRS_FIX" --json 2>/dev/null)
case "$MRS_FIX_OUT" in
*'"failure_count": 1'*) ok "re-filing the note as current clears its row" ;;
*) no "a current note must clear model-row-dead-assumption (got: $MRS_FIX_OUT)" ;;
esac

# --- 22. a live model row backed by a claim -----------------------------------
# The check above read the row->note direction as a question about `type` when it
# is a question about `status`, and a corpus that did what this method prescribes
# was told it had a defect. A structural driver with no subject instrument
# belongs in the indexed set, so filing a sourced figure as an unevidenced
# assumption is the thing that was wrong; correcting it retires the assumption
# and mints a `claim` carrying the same title. Every word of the failure was then
# true - the title matched a `superseded` note and no `current` assumption
# carried it - and the conclusion did not follow, because the row was backed the
# whole time. Two rows here carry the two shapes: A-1 has a claim and no
# assumption at all, A-3 has the promotion pair.
printf '\nlive model rows backed by a claim\n'

# ONE INVOCATION, because exit 0 already carries every silence this vault is
# built to prove. A failure of ANY code exits 1, so a green run says both that
# neither the claim-only row nor the promotion pair was reported AND that
# `assumption-not-in-model` stayed quiet on the retired assumption behind A-3 -
# which still declares `model_input`, so an implementation that cleared the row
# without marking the title hit would report it again as an input the table has
# no row for, the second and wrong repair. Asserting the count separately over
# the same unmutated vault would be a second full walk that cannot fail on its
# own; the mutated copies below are where the counts have teeth.
MRC_OK=$("$LINT" --assumption-rows --vault "$HERE/model-row-claim-backed" 2>&1)
MRC_STATUS=$?
[ "$MRC_STATUS" = "0" ] && ok "a row backed by a current claim passes, and the promoted-away assumption is not reported from the other side" ||
	no "model-row-claim-backed should exit 0 (got $MRC_STATUS: $MRC_OK)"

# THE TWO COUNTS IN THE SUCCESS LINE ARE NOT TWO SIDES OF ONE. Three rows against
# two declared inputs is correct here and always will be: a row backed by a
# `claim` never becomes a declared model input, so a line reading as a comparison
# would send its reader looking for a row that was never owed.
case "$MRC_OK" in
*'3 assumption rows each backed by'*'1 live declared model input each rendered as a row or excluded'*)
	ok "the success line states each half rather than comparing two counts" ;;
*) no "the success line still reads as a comparison of two counts (got: $MRC_OK)" ;;
esac
case "$MRC_OK" in
*'3 assumption rows against 3 declared'*|*'rows against 2 declared'*)
	no "the success line still says rows AGAINST declared inputs" ;;
*) ok "the success line no longer sets the row count against the input count" ;;
esac

# AND THE CHECK IS WIDENED, NOT SILENCED. Retire the claim and the row it backed
# is dead again - which is what says the fix reads `status` on a claim rather
# than treating any `claim` match as a pass. Asserted on the claim-only row, so
# the failure names the claim itself and the message has to read correctly about
# a note that is not an assumption.
MRC_DEAD="$PAIRS_FILE.claim-retired"
rm -rf "$MRC_DEAD"
cp -R "$HERE/model-row-claim-backed" "$MRC_DEAD"
strip_cr <"$HERE/model-row-claim-backed/claims/CLAIM-CB11AA01.md" |
	awk '{ sub(/^status: current$/, "status: superseded"); print }' >"$MRC_DEAD/claims/CLAIM-CB11AA01.md"
if grep -q '^status: superseded$' "$MRC_DEAD/claims/CLAIM-CB11AA01.md"; then
	ok "the copy with the claim retired carries it"
else
	no "the status rewrite did not land - the assertion below would pass over an unchanged vault"
fi
MRC_DEAD_OUT=$("$LINT" --assumption-rows --vault "$MRC_DEAD" --json 2>/dev/null)
MRC_DEAD_STATUS=$?
[ "$MRC_DEAD_STATUS" = "1" ] && ok "retiring the claim puts its row back in the failing set" ||
	no "a row whose only match is a retired claim must fail (got $MRC_DEAD_STATUS: $MRC_DEAD_OUT)"
case "$MRC_DEAD_OUT" in
*'"failure_count": 1'*) ok "only the row whose claim was retired is reported" ;;
*) no "--assumption-rows did not report exactly one row over the retired-claim copy (got: $MRC_DEAD_OUT)" ;;
esac
case "$MRC_DEAD_OUT" in
*'"check": "model-row-dead-assumption"'*'"id": "CLAIM-CB11AA01"'*'status: superseded'*)
	ok "the failure names the retired claim and its status" ;;
*) no "model-row-dead-assumption did not name the retired claim (got: $MRC_DEAD_OUT)" ;;
esac

# THE PROMOTION HALF OF THE SAME RULE. Retire the claim that replaced the
# assumption and A-3 has two retired matches and no live one, so it fails again -
# without this the promotion could be passing because the claim was seen rather
# than because its `status` was read.
MRC_PROM="$PAIRS_FILE.promotion-retired"
rm -rf "$MRC_PROM"
cp -R "$HERE/model-row-claim-backed" "$MRC_PROM"
strip_cr <"$HERE/model-row-claim-backed/claims/CLAIM-CB33CC03.md" |
	awk '{ sub(/^status: current$/, "status: retracted"); print }' >"$MRC_PROM/claims/CLAIM-CB33CC03.md"
if grep -q '^status: retracted$' "$MRC_PROM/claims/CLAIM-CB33CC03.md"; then
	ok "the copy with the superseding claim retracted carries it"
else
	no "the status rewrite did not land - the assertion below would pass over an unchanged vault"
fi
MRC_PROM_OUT=$("$LINT" --assumption-rows --vault "$MRC_PROM" --json 2>/dev/null)
case "$MRC_PROM_OUT" in
*'"check": "model-row-dead-assumption"'*'Gross margin holds at the observed blended rate'*)
	ok "a promotion whose claim is also retired leaves the row dead" ;;
*) no "retiring both notes behind the promoted row did not fail it (got: $MRC_PROM_OUT)" ;;
esac

# --- 23. a retired note owes no row and no exclusion --------------------------
# The SAME defect as sections 21 and 22, on the note side: `assumption-not-in-model`
# walked every note carrying `model_input` without asking whether it was still
# live, so a `superseded` or `retracted` note went on owing a row. That demand
# cannot be satisfied. The escapes are to render the dead title as a row - undoing
# the repair the row side asks for - or to write `excluded_from_model` onto a
# corpse, which records a decision about a live revenue line on a note nobody will
# open. Found end to end on a live corpus: the row side flagged a dead-backed row,
# re-titling it to the live claim cleared that, and this half then demanded a row
# for the superseded note the repair had just pointed away from.
#
# BOTH DIRECTIONS OVER ONE VAULT, because a fix that simply stopped reading the
# note side would pass the retired half and is what the live half catches.
printf '\nretired notes owe no model row\n'

# THE LIVE HALF still fails - asserted above as AR_MRM, whose note is
# `status: unverified`. That is a LIVE status, so the same vault is the control
# and the copy below changes exactly one line of it.
ANM_DEAD="$PAIRS_FILE.input-retired"
rm -rf "$ANM_DEAD"
cp -R "$HERE/model-row-missing" "$ANM_DEAD"
strip_cr <"$HERE/model-row-missing/assumptions/ASSUMPTION-MR22BB02.md" |
	awk '{ sub(/^status: unverified$/, "status: superseded"); print }' >"$ANM_DEAD/assumptions/ASSUMPTION-MR22BB02.md"
if grep -q '^status: superseded$' "$ANM_DEAD/assumptions/ASSUMPTION-MR22BB02.md"; then
	ok "the copy with the declared input retired carries it"
else
	no "the status rewrite did not land - the assertion below would pass over an unchanged vault"
fi
ANM_DEAD_OUT=$("$LINT" --assumption-rows --vault "$ANM_DEAD" --json 2>/dev/null)
ANM_DEAD_STATUS=$?
[ "$ANM_DEAD_STATUS" = "0" ] && ok "a retired note declaring model_input with no row passes" ||
	no "a retired declared input must owe nothing (got $ANM_DEAD_STATUS: $ANM_DEAD_OUT)"
case "$ANM_DEAD_OUT" in
*'assumption-not-in-model'*)
	no "a retired note was still reported as an input the table has no row for" ;;
*) ok "retiring the note clears assumption-not-in-model rather than trading one demand for another" ;;
esac

# AND THE COUNT SAYS WHICH SET IT WALKED. That vault carries TWO notes declaring
# `model_input` - one rendered as a row, one not - so retiring the un-rendered one
# has to drop the count to a single LIVE declared input. A silent pass with the
# count still reading 2 would mean the note was skipped by the row-side hit rather
# than by its status, which is a different fix that happens to look the same here.
ANM_DEAD_OK=$("$LINT" --assumption-rows --vault "$ANM_DEAD" 2>&1)
case "$ANM_DEAD_OK" in
*'1 live declared model input each rendered as a row or excluded'*)
	ok "the retired note leaves the walked set, and the count says so" ;;
*) no "the success line still counts the retired note as a declared input (got: $ANM_DEAD_OK)" ;;
esac

# THE SIBLING RULE READS THE SAME NARROWED SET, and that is a decision rather
# than a side effect: excluded-line-on-roadmap walks the declared inputs, so a
# retired note a milestone still `moves` is silent here too. Its repair - name it
# in `arr_excludes`, or give the model a row - is the corpse-decision this whole
# section refuses. A roadmap pointing at a dead note is a real defect and a
# different one, and no check in this tool reports it yet.
ANM_EOR="$PAIRS_FILE.excluded-retired"
rm -rf "$ANM_EOR"
cp -R "$HERE/excluded-on-roadmap" "$ANM_EOR"
strip_cr <"$HERE/excluded-on-roadmap/assumptions/ASSUMPTION-EX22BB02.md" |
	awk '{ sub(/^status: unverified$/, "status: retracted"); print }' >"$ANM_EOR/assumptions/ASSUMPTION-EX22BB02.md"
if grep -q '^status: retracted$' "$ANM_EOR/assumptions/ASSUMPTION-EX22BB02.md"; then
	ok "the copy with the excluded line retracted carries it"
else
	no "the status rewrite did not land - the assertion below would pass over an unchanged vault"
fi
ANM_EOR_OUT=$("$LINT" --assumption-rows --vault "$ANM_EOR" --json 2>/dev/null)
case "$ANM_EOR_OUT" in
*'excluded-line-on-roadmap'*)
	no "a retracted note still owed an arr_excludes declaration - the repair records a live decision on a corpse" ;;
*) ok "retracting the excluded line stops it owing a declaration at the identity" ;;
esac

# --- 24. every cited [F#] and [S#] resolves to a row in its index -------------
# The resolution contract was specified and never enforced, so a plan could cite
# a code that resolves to nothing and clear --release-gate. Both index files get
# their own dangling code, because the two repairs open different files - and
# the passing side is the one with teeth: an index that names its own retired
# codes in its own prose is a corpus doing the right thing, and a scan that read
# the index files would fail it.
printf '\ncitation codes\n'

CC_F=$("$LINT" --citation-codes --vault "$HERE/citation-dangling-f" --json 2>/dev/null)
CC_F_STATUS=$?
[ "$CC_F_STATUS" = "1" ] && ok "--citation-codes exits 1 on an [F#] with no brief row" ||
	no "--citation-codes should exit 1 on a dangling [F#] (got $CC_F_STATUS)"
case "$CC_F" in
*'"check": "citation-code-no-fact-row"'*'"id": "F7"'*) ok "the dangling [F#] is reported against the founder brief" ;;
*) no "citation-code-no-fact-row did not report F7 (got: $CC_F)" ;;
esac
# The count is what says the resolving code beside it was not swept up too.
case "$CC_F" in
*'"failure_count": 1'*) ok "the [F#] that does resolve is not reported" ;;
*) no "--citation-codes reported more than the one dangling code (got: $CC_F)" ;;
esac

CC_S=$("$LINT" --citation-codes --vault "$HERE/citation-dangling-s" --json 2>/dev/null)
CC_S_STATUS=$?
[ "$CC_S_STATUS" = "1" ] && ok "--citation-codes exits 1 on an [S#] with no sources.md row" ||
	no "--citation-codes should exit 1 on a dangling [S#] (got $CC_S_STATUS)"
case "$CC_S" in
*'"check": "citation-code-no-source-row"'*'"id": "S9"'*) ok "the dangling [S#] is reported against the source log" ;;
*) no "citation-code-no-source-row did not report S9 (got: $CC_S)" ;;
esac
# A fenced block in that same document cites a code no row assigns. A scan that
# read fenced lines would report it, and a check that fires on a document for
# documenting its own format is one somebody switches off.
case "$CC_S" in
*S404*) no "a citation inside a fenced block was read as a citation" ;;
*) ok "a code inside a fenced block is an example, not a citation" ;;
esac

# THE ASSERTION THIS MODE IS SHAPED BY. Both index files carry a mention of a
# code they no longer assign - one in the log's header prose, one inside a row -
# and excluding the two indexes from the scan is what keeps that a pass.
CC_RET=$("$LINT" --citation-codes --vault "$HERE/citation-retired-code" 2>&1)
CC_RET_STATUS=$?
[ "$CC_RET_STATUS" = "0" ] && ok "an index discussing its own retired codes passes" ||
	no "a retired code named inside its own index must not fail (got $CC_RET_STATUS: $CC_RET)"

# THE SUCCESS LINE STATES THE LIMIT, and this is the assertion that keeps it
# there: resolution is necessary and not sufficient, so a line reporting only
# that every code resolved would claim coverage the mode does not have - the
# exact defect family this mode belongs to.
case "$CC_RET" in
*'INTENDED source'*) ok "the success line says which question it did not ask" ;;
*) no "--citation-codes did not state its limit on success (got: $CC_RET)" ;;
esac

# A missing index is a half that did not run, never agreement. The clean vault
# cites [F1] and carries no founder brief at all.
CC_NONE=$("$LINT" --citation-codes --vault "$HERE/clean" 2>&1)
CC_NONE_STATUS=$?
[ "$CC_NONE_STATUS" = "0" ] && ok "a vault with neither index passes" ||
	no "a vault with no index to resolve against should pass (got $CC_NONE_STATUS: $CC_NONE)"
case "$CC_NONE" in
*'neither index exists'*) ok "the absent indexes are named rather than reported clean" ;;
*) no "--citation-codes did not say it had no index to read (got: $CC_NONE)" ;;
esac

# --- 25. a local source row the global log never received ---------------------
# The half --citation-codes cannot reach: a source that exists only in a research
# file's own table has no citable code at all, while a plan citing that local
# number resolves it against whatever the log assigns it to. The exemption is the
# other half of the fixture pair, and it is what keeps the mode switched on.
printf '\nunflattened sources\n'

US_OUT=$("$LINT" --unflattened-source --vault "$HERE/source-unflattened" --json 2>/dev/null)
US_STATUS=$?
[ "$US_STATUS" = "1" ] && ok "--unflattened-source exits 1 on a local row the log never received" ||
	no "--unflattened-source should exit 1 on an unflattened row (got $US_STATUS)"
case "$US_OUT" in
*'"check": "source-unflattened"'*'"id": "S2"'*) ok "the local row whose URL is absent is reported" ;;
*) no "source-unflattened did not report S2 (got: $US_OUT)" ;;
esac
# The sibling row in the same table IS in the log, so the count is what says the
# mode compared URLs rather than reporting every local row it found.
case "$US_OUT" in
*'"failure_count": 1'*) ok "the local row that was flattened is not reported" ;;
*) no "--unflattened-source reported more than the one absent URL (got: $US_OUT)" ;;
esac

# THE DECLARED EXEMPTION, which is what stops this mode reporting a hundred and
# fifty failures over a corpus doing the right thing - and a mode that does that
# is one somebody switches off, taking the working half with it.
US_EX=$("$LINT" --unflattened-source --vault "$HERE/source-ledger-exempt" 2>&1)
US_EX_STATUS=$?
[ "$US_EX_STATUS" = "0" ] && ok "a ledger declared exempt in the log's header passes" ||
	no "a declared local ledger must not fail (got $US_EX_STATUS: $US_EX)"
case "$US_EX" in
*'research/company-profiles.md'*) ok "the success line names what was exempted" ;;
*) no "the exemption is invisible in the success line (got: $US_EX)" ;;
esac
# The file NEXT to the exempt one is still read, which is what says the
# exemption is scoped to a file rather than switching the mode off.
case "$US_EX" in
*'1 local source row across 1 research file'*) ok "the file beside the exempt one is still compared" ;;
*) no "the unexempt research file was not read (got: $US_EX)" ;;
esac
# A row naming a source with no URL has no key to match on. Counted and named
# rather than passed in silence, so a table of unlinkable rows cannot read as a
# table that agreed.
case "$US_EX" in
*'carrying no URL'*) ok "a row with no URL is reported as unresolved, not as agreed" ;;
*) no "the row with no URL was silently passed (got: $US_EX)" ;;
esac

# No sources.md is a mode that did not run, never agreement.
US_NONE=$("$LINT" --unflattened-source --vault "$HERE/clean" 2>&1)
US_NONE_STATUS=$?
[ "$US_NONE_STATUS" = "0" ] && ok "a vault with no global log passes" ||
	no "a vault with no sources.md should pass (got $US_NONE_STATUS: $US_NONE)"
case "$US_NONE" in
*'no global log to flatten a local row into'*) ok "the absent log is named rather than reported clean" ;;
*) no "--unflattened-source did not say it had no log to read (got: $US_NONE)" ;;
esac

# --- 26. a subject the corpus argues from and never filed --------------------
# coverage-gap asks this of `required: true` subjects and stops there, so the
# subjects a particular plan invents its own dependence on are invisible: the
# documents reason from one, the vocabulary declares it, and no note is ever
# written. Both fixtures here carry NOTHING BUT optional subjects, which is what
# makes them impossible for coverage-gap to see - a mode that were merely
# coverage-gap widened would report every unfiled term in both, including the
# ones nothing mentions.
printf '\nunfiled subjects the corpus reasons about\n'

SO_OUT=$("$LINT" --subject-orphan --vault "$HERE/subject-orphan" --json 2>/dev/null)
SO_STATUS=$?
[ "$SO_STATUS" = "1" ] && ok "--subject-orphan exits 1 on a subject the corpus leans on and never filed" ||
	no "--subject-orphan should exit 1 over subject-orphan (got $SO_STATUS)"

# The count is what says the three silent subjects in that vault stayed silent:
# `primary-risk` is unfiled and never mentioned, `steady-state-ceiling` is
# unfiled, mentioned, and coverage-gap`s because it is `required: true`, and
# `willingness-to-pay` is the shared-alias case asserted by name below.
case "$SO_OUT" in
*'"failure_count": 2'*) ok "the unmentioned subject, the required one and the shared alias are not reported" ;;
*) no "--subject-orphan did not report exactly two failures over subject-orphan (got: $SO_OUT)" ;;
esac

# A FILED TERM CLAIMS ITS OWN STRINGS, and this is the assertion that holds the
# mechanism to the claim. `willingness-to-pay` is unfiled and lists `price` as an
# alias; so does `price-anchor`, which the assumption in that vault files. The
# only line carrying `price` is a sentence about price-anchor - a mention the
# vault has already answered, which owes nothing.
#
# Registering only the UNFILED terms leaves the filed term`s strings unowned and
# reports willingness-to-pay against that sentence: a confident false positive in
# the one mode that ships failing and ungated and can turn a finished corpus red
# on upgrade. Asserted BY NAME rather than left to the count above, which moves
# for any of four reasons and only this one points at the registration order.
case "$SO_OUT" in
*willingness-to-pay*)
	no "an unfiled term claimed an alias a FILED term also lists - that mention belongs to the subject already answered" ;;
*) ok "a filed term claims its own aliases, so an unfiled term sharing one reports nothing" ;;
esac

# THE CANONICAL KEY, READ OUT OF A NOTE BODY. `timing-window` is spelled in full
# in a claim that is filed under a different subject - the corpus reasoning about
# a position the ledger has never held, which is the whole rule.
case "$SO_OUT" in
*'"check": "subject-orphan"'*'"id": "timing-window"'*) ok "a subject named by its own key in a note body is reported" ;;
*) no "subject-orphan did not report timing-window (got: $SO_OUT)" ;;
esac

# THE ALIAS PATH, READ OUT OF A PLAN DOCUMENT. `market-growth` never appears in
# business-plan.md under its canonical key - only as `growth rate` - so an
# alias-blind implementation passes this vault and this assertion is the only
# thing that would say so.
case "$SO_OUT" in
*'"id": "market-growth"'*'which carries the alias `growth-rate`'*) ok "a subject reached only through an alias is reported, and the message names the alias" ;;
*) no "subject-orphan did not report market-growth through its alias (got: $SO_OUT)" ;;
esac

# THE MESSAGE IS A DIAGNOSIS, NOT A VERDICT. This ships failing rather than
# gated, so a vault carrying the gap goes red on the version that adds it - and a
# red gate whose message is a diagnosis is a five-minute fix while one that is
# only a verdict is a support request. Both halves are asserted: where the corpus
# is already leaning on the subject, and which note to write.
case "$SO_OUT" in
*'business-plan.md line 5 reads'*) ok "the failure names the document and the line the corpus leans on" ;;
*) no "subject-orphan did not name where the mention is (got: $SO_OUT)" ;;
esac
case "$SO_OUT" in
*'Write the note - a `claim` under `subject: market-growth`'*) ok "the failure names the note to write" ;;
*) no "subject-orphan did not say which note to write (got: $SO_OUT)" ;;
esac

# THE SILENT SIDE, WHICH IS WHAT KEEPS THIS OFF EVERY OPTIONAL TERM. Every
# unfiled subject in subject-unmentioned/ is one nothing in the corpus writes
# down. The plan there also carries `pricing`, `prices` and `priceless`, each of
# which a SUBSTRING scan matches the alias `price` inside - so this is also the
# assertion that mentions are matched on token boundaries.
SO_QUIET=$("$LINT" --subject-orphan --vault "$HERE/subject-unmentioned" 2>&1)
SO_QUIET_STATUS=$(run_status "$HERE/subject-unmentioned" --subject-orphan)
[ "$SO_QUIET_STATUS" = "0" ] && ok "--subject-orphan exits 0 when nothing mentions the unfiled subject" ||
	no "--subject-orphan should exit 0 over subject-unmentioned (got $SO_QUIET_STATUS)"
case "$SO_QUIET" in
*'a subject nothing leans on is not a gap'*) ok "the success line says the subject is unfiled and unmentioned, not that every subject is filed" ;;
*) no "--subject-orphan did not name the unfiled-but-unmentioned half (got: $SO_QUIET)" ;;
esac

# And the vault every other assertion in this suite requires clean stays clean:
# every subject in clean/ carries a note, so the line names what it checked
# rather than reporting a half it never ran.
SO_CLEAN=$("$LINT" --subject-orphan --vault "$HERE/clean" 2>&1)
SO_CLEAN_STATUS=$(run_status "$HERE/clean" --subject-orphan)
[ "$SO_CLEAN_STATUS" = "0" ] && ok "--subject-orphan passes the clean vault" ||
	no "--subject-orphan should pass the clean vault (got $SO_CLEAN_STATUS)"
case "$SO_CLEAN" in
*'every one of them carrying a `claim` or an `assumption`'*) ok "the clean vault is told which half agreed" ;;
*) no "--subject-orphan did not name what it checked over clean (got: $SO_CLEAN)" ;;
esac

# NOT GATED ON schemaVersion, and there is nothing to gate it on - the rule reads
# no field a corpus written before it lacks. Both fixtures above are at 1, so the
# assertions already ran at the oldest version this tool reads; this is the other
# end, and a version gate slipped in later would turn one of the two silent.
SO_AT_2="$PAIRS_FILE.subject-at-2"
rm -rf "$SO_AT_2"
cp -R "$HERE/subject-orphan" "$SO_AT_2"
printf '{\n  "schemaVersion": 2,\n  "created": "2026-03-14"\n}\n' >"$SO_AT_2/.vault/config.json"
SO_AT_2_STATUS=$(run_status "$SO_AT_2" --subject-orphan)
[ "$SO_AT_2_STATUS" = "1" ] && ok "--subject-orphan fires at schemaVersion 2 as well as at 1" ||
	no "--subject-orphan went silent at schemaVersion 2 (got $SO_AT_2_STATUS)"

# A VAULT WITH NO VOCABULARY IS TOLD SO rather than reported clean. There is no
# subject list to hold the corpus against, so the mode did not run - and a
# success line reading as a pass over it is the failure this whole family of
# checks exists to break.
SO_NOVOCAB=$("$LINT" --subject-orphan --vault "$HERE/no-vocab" 2>&1)
case "$SO_NOVOCAB" in
*'no _vocab.yml under'*) ok "a vault with no vocabulary is told no subject was asked after" ;;
*) no "--subject-orphan reported a verdict over a vault with no vocabulary (got: $SO_NOVOCAB)" ;;
esac

# --- 27. foreclosures, and the condition that would reverse one ---------------
# Every other adversarial guard in this method fires on a plan claiming too
# much. A note asserting an option is NOT viable claims too little, removes work
# from the roadmap, and is attacked by nothing - so what is asserted here is the
# whole of what a check can reach: that the conclusion states the input value
# which would put the option back.
printf '\nforeclosed options\n'

FC_OUT=$("$LINT" --foreclosed --vault "$HERE/foreclosed-no-reverse" --json 2>/dev/null)
FC_STATUS=$(run_status "$HERE/foreclosed-no-reverse" --foreclosed)
[ "$FC_STATUS" = "1" ] && ok "--foreclosed exits 1 on a foreclosure with no reversal condition" ||
	no "--foreclosed should exit 1 over foreclosed-no-reverse (got $FC_STATUS)"

# EXACTLY TWO, and which two is the whole assertion. Three of the four notes in
# that vault carry `forecloses`; the one that also carries `reverses_if` and the
# one the ledger has retired are the two that must not appear, and a count alone
# would pass a mode that reported the wrong pair.
case "$FC_OUT" in
*'"failure_count": 2'*) ok "--foreclosed reports exactly the two foreclosures with no reversal condition" ;;
*) no "--foreclosed did not report exactly two failures over foreclosed-no-reverse (got: $FC_OUT)" ;;
esac

case "$FC_OUT" in
*'"check": "foreclosure-no-reverse"'*'"id": "CLAIM-FC11AA01"'*) ok "a claim that forecloses with no reverses_if is reported" ;;
*) no "--foreclosed did not report CLAIM-FC11AA01 (got: $FC_OUT)" ;;
esac

# BOTH TYPES THAT FILE A POSITION ARE READ. Reading `claim` alone would make
# filing the foreclosure as an `assumption` the cheapest way past this rule, and
# a dodge available by omission is not an exemption.
case "$FC_OUT" in
*'"id": "ASSUMPTION-FC12BB02"'*) ok "an assumption that forecloses is held to the same bar as a claim" ;;
*) no "--foreclosed read only claims and missed the assumption half (got: $FC_OUT)" ;;
esac

case "$FC_OUT" in
*CLAIM-FC13CC03*) no "--foreclosed reported the foreclosure that declares its reversal condition (got: $FC_OUT)" ;;
*) ok "a foreclosure declaring reverses_if is silent" ;;
esac

case "$FC_OUT" in
*CLAIM-FC14DD04*) no "--foreclosed reported a superseded foreclosure (got: $FC_OUT)" ;;
*) ok "a foreclosure the ledger has retired owes no reversal condition" ;;
esac

# The message is the repair, not the verdict: the field to write, and the
# section a reader has to go and argue the conclusion in.
case "$FC_OUT" in
*'the value of `foreclosed_on` that would put the option back on the table'*) ok "the failure says which field to write" ;;
*) no "--foreclosed did not name the repair (got: $FC_OUT)" ;;
esac
case "$FC_OUT" in
*'Cited into: business-plan.md#pricing'*) ok "the failure names the section the foreclosure reached" ;;
*) no "--foreclosed did not name where the foreclosure was cited (got: $FC_OUT)" ;;
esac

# THE PASSING SIDE IS A LISTING, not a bare pass. This mode feeds the panel as
# well as the gate, so a success line that named nothing would report a corpus
# taking two options off the table exactly like one taking none.
FC_OK=$("$LINT" --foreclosed --vault "$HERE/foreclosed-declared" 2>&1)
FC_OK_STATUS=$(run_status "$HERE/foreclosed-declared" --foreclosed)
[ "$FC_OK_STATUS" = "0" ] && ok "--foreclosed exits 0 when every foreclosure declares its reversal condition" ||
	no "--foreclosed should exit 0 over foreclosed-declared (got $FC_OK_STATUS)"
case "$FC_OK" in
*'CLAIM-FD21AA01 forecloses the single-seat configuration (business-plan.md#pricing)'*)
	ok "the passing line lists each foreclosure with the section its used_in names" ;;
*) no "--foreclosed did not list the foreclosures it passed (got: $FC_OK)" ;;
esac
case "$FC_OK" in
*'(business-plan.md#market, one-pager.md)'*) ok "a foreclosure cited twice lists both sections" ;;
*) no "--foreclosed listed only one of two used_in entries (got: $FC_OK)" ;;
esac

# A vault where nothing forecloses is told which half did not run, never that
# its conclusions agree - the rule every success line in this tool is held to.
FC_CLEAN=$("$LINT" --foreclosed --vault "$HERE/clean" 2>&1)
FC_CLEAN_STATUS=$(run_status "$HERE/clean" --foreclosed)
[ "$FC_CLEAN_STATUS" = "0" ] && ok "--foreclosed passes the clean vault" ||
	no "--foreclosed should pass the clean vault (got $FC_CLEAN_STATUS)"
case "$FC_CLEAN" in
*'nothing in this corpus takes an option off the table'*) ok "a corpus foreclosing nothing is told so rather than reported clean" ;;
*) no "--foreclosed did not name the half that had nothing to run over (got: $FC_CLEAN)" ;;
esac

printf '\nrun-fixtures: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
