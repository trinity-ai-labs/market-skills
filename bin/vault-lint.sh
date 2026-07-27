#!/bin/sh
#
# vault-lint.sh - read-only whole-corpus checks over a claim vault.
#
#   vault-lint.sh [check] [--vault PATH] [--json]
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

usage() {
	cat <<'EOF'
vault-lint.sh - read-only checks over a claim vault.

  vault-lint.sh [check] [--vault PATH] [--json]
      Run every check over the vault. Exits 1 if anything failed.

  vault-lint.sh --unverified [--vault PATH] [--json]
      Report the notes asserted with nothing behind them: everything with
      status: unverified, and everything carried at Low confidence. A target
      list, not a verdict - it exits 0 whether or not it finds any.

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
	--unverified)
		[ "$MODE" = "graph" ] && die "--unverified and graph are separate modes"
		MODE="unverified"
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
	*)
		die "unexpected argument: $1"
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

SUPPORTED_SCHEMA=1
FOUND_SCHEMA=$(awk '
	match($0, /"schemaVersion"[ \t]*:[ \t]*[0-9]+/) {
		s = substr($0, RSTART, RLENGTH)
		if (match(s, /[0-9]+$/)) { print substr(s, RSTART, RLENGTH); exit }
	}
' "$CONFIG")

[ -n "$FOUND_SCHEMA" ] ||
	die "$CONFIG carries no schemaVersion. A tool that guesses half-reads the vault and reports a clean bill of health over every field it never saw."
[ "$FOUND_SCHEMA" = "$SUPPORTED_SCHEMA" ] ||
	die "vault schemaVersion is $FOUND_SCHEMA and this tool supports $SUPPORTED_SCHEMA. Refusing rather than processing the parts it recognises - a green result from a half-read vault is exactly what somebody acts on."

VOCAB="$VAULT/_vocab.yml"
HAS_VOCAB=0
[ -f "$VOCAB" ] && HAS_VOCAB=1

# Every field whose block-list items name other notes. This is DELIBERATELY
# wider than vault.md's four edges: `covers` is a question field and
# `assumptions_low` and `option_evidence` come from decisions.md, and none of
# the three is called an edge anywhere - but each holds note IDs, so each has to
# be followed for a dangling target and walked by `graph`. Declared once and
# passed to both awk programs that traverse it: two copies would let `graph` and
# `check` disagree about which fields exist, which is the tool shrinking its own
# blast radius exactly the way it warns notes not to.
EDGE_FIELDS="rests_on supersedes scopes validated_by covers assumptions_low option_evidence"

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

# One directory per type, one file per note. Anything outside these six - the
# research prose, an editor sidecar - is not a note and is never read. These are
# the plural directory names; the singular type names are the req[] keys in the
# checks pass, and vault.md closes the set at six, so both lists are written out
# by hand and have to move together.
#
# One find per directory rather than one find over six paths: collapsing them
# means either building an unquoted path list, which breaks the first time a
# vault lives under a directory with a space in its name, or passing all six
# unconditionally and swallowing find's stderr, which hides a real permissions
# error. Six spawns cost a few milliseconds and neither failure is worth it.
: >"$FILES"
for d in sources facts claims assumptions questions decisions; do
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
		function isid(s) { return (s ~ /^(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION)-[A-Za-z0-9]+$/) }
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
# pass 3 - the checks
#
# Reads the record stream plus the parse errors, and emits one failure per line:
#     file <TAB> check <TAB> id <TAB> detail
#
# Every message names what is wrong AND what it costs. The message is the
# product here - the person reading it is deciding whether to care, and a
# message that only restates the rule gives them nothing to decide with.
# ----------------------------------------------------------------------------

TODAY=$(date +%Y-%m-%d)

awk -v today="$TODAY" -v out="$FAILURES" -v hasvocab="$HAS_VOCAB" -v edgefields="$EDGE_FIELDS" -F '\t' '
	BEGIN {
		BS = sprintf("%c", 92)

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

		nedge = split(edgefields, edgef, " ")
		rank["L"] = 1; rank["M"] = 2; rank["H"] = 3
		name[1] = "L"; name[2] = "M"; name[3] = "H"
	}

	# Duplicated in the graph pass above - see the note there.
	function isid(s) { return (s ~ /^(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION)-[A-Za-z0-9]+$/) }

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

				# --- the type is stated three times and all three agree ----
				if (ty != "" && !(ty in req))
					report(f, "type-agreement", id, "type `" ty "` is not one of source, fact, claim, assumption, question, decision. Structure that does not fit a type belongs on an edge, not in a seventh type")
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

LC_ALL=C sort -o "$FAILURES" "$FAILURES"

# One awk, branching on asjson internally - the same shape --unverified uses, so
# a third report mode has one pattern to copy rather than two. It also carries
# the exit status out itself, which is what removes the separate counting pass:
# awk already knows how many rows it buffered.
#
# Human output goes to stderr and JSON to stdout on purpose: a caller piping
# --json into a parser gets only the document, and a human running it bare still
# sees everything.
awk -v vault="$VAULT" -v today="$TODAY" -v asjson="$JSON" -F '\t' '
	BEGIN {
		DQ = sprintf("%c", 34)
		BS = sprintf("%c", 92)
	}
	# Escaped one character at a time: a gsub replacement containing a backslash
	# is rescanned by awk, and what it does with an unrecognised escape there is
	# unspecified - which would produce invalid JSON on exactly the notes whose
	# text most needs reading.
	# The same escaper as the --unverified renderer above. Both are short
	# and stable; if either ever grows a case the other needs, that is the
	# point to hoist it rather than copy it a third time.
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
			printf "vault-lint: clean - %s\n", vault
		} else {
			printf "vault-lint: %d failure%s under %s\n", n, (n == 1 ? "" : "s"), vault > "/dev/stderr"
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
