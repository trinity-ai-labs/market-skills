#!/usr/bin/env pwsh
#
# vault-lint.ps1 - read-only whole-corpus checks over a claim vault.
#
#   vault-lint.ps1 [check] [--vault PATH] [--json]
#   vault-lint.ps1 --release-gate [--vault PATH]
#   vault-lint.ps1 graph <ID> [--depth N] [--vault PATH]
#
# This is the PowerShell half of a two-implementation tool. bin/vault-lint.sh is
# the other, and it is the reference: every behaviour here is a transcription of
# a numbered region of that file, and scripts/parity/parity.mjs runs both over
# every fixture vault and diffs the answers. Read the shell first - its comments
# carry the reasoning, and this file does not repeat what has not changed.
#
# WHY A SECOND IMPLEMENTATION AT ALL
# A session on a native Windows install is handed the PowerShell tool and has no
# POSIX shell to run the .sh with. A shipped tool whose runtime prerequisite is
# discovered at the moment of use is a broken product, so the platform with no
# `sh` gets the shell it does have. Windows PowerShell 5.1 ships in-box on
# Windows exactly as `sh` does elsewhere, so nothing here is installed either.
#
# TARGET: WINDOWS POWERSHELL 5.1, NOT pwsh 7
# 5.1 is what ships in-box, so it is what has to run. No null-coalescing (`??`),
# no null-conditional (`?.`), no ternary (`? :`), no `-Parallel`. All of them are
# 7-only and all of them are PARSE errors on 5.1, so the whole file fails to load
# rather than one line failing to run - which reads as a broken install.
#
# ASCII ONLY, NO BOM, LF ENDINGS
# 5.1 decodes a BOM-less file as the system ANSI code page rather than as UTF-8,
# so a non-ASCII byte anywhere in this file is read wrongly and the message it
# sits in ships mangled. Keeping the file ASCII removes the question rather than
# betting on a BOM that the harness and git would then have to agree about. LF is
# pinned by .gitattributes, and it has to be: `--help` is emitted from a
# here-string, so a CRLF checkout would emit CRLF help text and diverge from the
# shell on every line of it at once.
#
# BYTES, NOT CMDLETS, FOR OUTPUT
# Write-Host and Write-Output route through PowerShell's formatting and its
# platform newline, which on Windows is CRLF. The parity gate compares stdout
# byte for byte, so every byte this tool emits goes through Write-OutText /
# Write-ErrText below, which write LF explicitly to a UTF-8 stream with no BOM.
#
# WHAT IS NOT PORTED YET
# Nine modes, nine stub functions - see THE STUB SEAM. Each answers exit status
# 3, which the shell never uses, so "not ported" can never be read as a verdict.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$PROG = 'vault-lint.ps1'

# The two characters `sub(/^[ \t]+/, "", v)` strips. Named once because every
# trim in the two parsers below is that pair and nothing else - .Trim() with no
# argument would also eat the non-breaking space and every other Unicode blank,
# which awk's [ \t] does not.
$SPACE_TAB = [char[]]@([char]32, [char]9)

# ----------------------------------------------------------------------------
# output primitives
#
# One place that knows how a byte leaves this process. StreamWriters over the
# raw standard handles, UTF-8 with no BOM, LF supplied by the caller: the
# alternative is [Console]::WriteLine, which appends the platform newline and
# would emit CRLF on the one platform this file exists for.
# ----------------------------------------------------------------------------

$OUT_WRITER = $null
$ERR_WRITER = $null

# How a writer is built lives here and only here. Written out per stream, the
# encoding and the AutoFlush would be two copies of one decision, and a later
# change to either that reached stdout and not stderr is a difference nothing
# reports - the two streams are compared separately.
function New-LfWriter {
	param([System.IO.Stream]$Stream)
	$writer = New-Object System.IO.StreamWriter($Stream, (New-Object System.Text.UTF8Encoding($false)))
	$writer.AutoFlush = $true
	return $writer
}

function Write-OutText {
	param([string]$Text)
	if ($null -eq $script:OUT_WRITER) { $script:OUT_WRITER = New-LfWriter ([Console]::OpenStandardOutput()) }
	$script:OUT_WRITER.Write($Text)
}

function Write-ErrText {
	param([string]$Text)
	if ($null -eq $script:ERR_WRITER) { $script:ERR_WRITER = New-LfWriter ([Console]::OpenStandardError()) }
	$script:ERR_WRITER.Write($Text)
}

# die() in bin/vault-lint.sh:290. THE PREFIX IS PART OF THE CONTRACT: the parity
# gate folds `vault-lint.sh: ` and `vault-lint.ps1: ` to one prefix before it
# compares stderr (scripts/parity/parity.mjs, normalize()). Any other spelling
# does not fold, and `graph` and --release-gate - the two modes whose stderr is
# compared as well as their stdout - then differ on every refusal path.
function Exit-Refusal {
	param([string]$Message)
	Write-ErrText ($script:PROG + ': ' + $Message + "`n")
	exit 2
}

# The answer a mode that has not been ported gives. 3 and nothing else: the
# shell answers 0, 1 and 2 only, so 3 cannot be mistaken for a verdict, and
# scripts/parity/parity.mjs:61 classifies a mode as unported by running it and
# checking for exactly this status. A stub answering anything else would be read
# as a working port and diffed against the shell.
function Exit-NotPorted {
	param([string]$Mode)
	Write-ErrText ($script:PROG + ': ' + $Mode + " is not ported to PowerShell yet. Run it through bin/vault-lint.sh in a POSIX shell until it is.`n")
	exit 3
}

# ----------------------------------------------------------------------------
# reading files the way awk reads them
#
# awk splits records on LF alone and hands the parser whatever bytes were in
# between; Get-Content splits on CR as well and File.ReadAllText strips a BOM.
# Either difference would make this reader disagree with the shell about where a
# line ends - a CR-only file would parse here and not there, and a BOM'd note
# would open with `---` here and with U+FEFF--- there. So: read the bytes,
# decode as UTF-8 with no BOM handling, split on LF only.
# ----------------------------------------------------------------------------

$UTF8_NO_BOM = New-Object System.Text.UTF8Encoding($false)

# The leading comma on every `return` is load-bearing. PowerShell unwraps a
# one-element array on the way out of a function, so a file holding a single
# line would come back as a bare string - and then `$lines[0]` is its first
# CHARACTER rather than its first line, which reads as a note whose `---` fence
# is the single character `-`. The comma wraps the result in an outer array that
# the unwrap consumes instead.
function Split-TextLines {
	param([string]$Text)
	if ($Text.Length -eq 0) { return ,[string[]]@() }
	$lines = $Text.Split([char]10)
	# A trailing LF terminates the last line rather than starting an empty one,
	# which is what `while ((getline line < path) > 0)` does. Without this every
	# file would carry one phantom blank line at EOF.
	if ($lines[$lines.Count - 1].Length -eq 0) {
		if ($lines.Count -eq 1) { return ,[string[]]@() }
		return ,[string[]]$lines[0..($lines.Count - 2)]
	}
	return ,[string[]]$lines
}

function Read-TextLines {
	param([string]$Path)
	return ,[string[]](Split-TextLines $script:UTF8_NO_BOM.GetString([System.IO.File]::ReadAllBytes($Path)))
}

# `sub(/\r$/, "", line)` - ONE trailing CR, not every trailing whitespace
# character. TrimEnd would also eat the trailing spaces a YAML value is allowed
# to carry inside quotes.
function Remove-TrailingCr {
	param([string]$Text)
	if ($Text.EndsWith("`r", [System.StringComparison]::Ordinal)) { return $Text.Substring(0, $Text.Length - 1) }
	return $Text
}

# The absolute path of a directory with a trailing separator, for turning a
# FullName into a path relative to it. Returns '' when the directory cannot be
# resolved, which the caller reads as "nothing to walk" - the shell's `find`
# prints nothing and moves on in the same case.
#
# READ OFF A DirectoryInfo, not off Resolve-Path, because the only consumer of
# this string is Substring against a FullName that Get-ChildItem produced - and
# both walks below now root that Get-ChildItem AT this string. Get-Item and
# Get-ChildItem hand back the same object type from the same .NET enumeration,
# so the prefix and the paths it is stripped from spell the directory the same
# way by construction. Resolve-Path is a separate normalization that need not
# agree: on Windows a directory reached through an 8.3 short name - which is
# what %TEMP% is for any user whose name is over eight characters, so it is the
# ordinary spelling of a temp path rather than a curiosity - has two spellings
# of DIFFERENT LENGTHS, and a Substring against the wrong one cuts into the file
# name rather than off it.
function Get-PathPrefix {
	param([string]$Directory)
	$item = Get-Item -LiteralPath $Directory -Force -ErrorAction SilentlyContinue
	if ($null -eq $item) { return '' }
	$full = $item.FullName
	if ($full.Length -eq 0) { return '' }
	if ($full.EndsWith([string][System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::Ordinal)) { return $full }
	return $full + [System.IO.Path]::DirectorySeparatorChar
}

# A FullName, as a path relative to a prefix Get-PathPrefix returned, with `/`
# separators. THE ONLY PLACE `\` BECOMES `/`. Both index walks below go through
# it, so the note file list and the path index cannot end up disagreeing about
# how a Windows path spells itself - and a rule that ever has to change (a
# `\\?\` long-path prefix, a UNC share) changes in one place rather than in
# whichever of the two the editor happened to open.
function Get-RelativeSlashPath {
	param([string]$FullName, [string]$Prefix)
	return $FullName.Substring($Prefix.Length).Replace([char]92, [char]47)
}

# ----------------------------------------------------------------------------
# the one markdown table reader
#
# --roadmap-table and --assumption-rows read the same shape out of two
# documents: the item cells of the FIRST table under a named heading. They were
# two functions, and the second one's comment claimed it was the first one "with
# two changes and no others" - a claim nothing in this file could hold, because
# the two spelled identical rules through different constructs
# (`StartsWith('|', Ordinal)` in one against `[int]$t[0] -ne 124` in the other,
# `$hdr -cne ''` against `$hdr.Length -ne 0`). scripts/parity/parity.mjs diffs
# .sh against .ps1 and never one reader against its own twin, and no fixture
# puts both readers over the same table - so a fence rule, an alignment-row test
# or a heading-depth bound fixed in one and not the other shipped silently, and
# the mode that missed the fix went on printing green over every fixture written
# before it. There is one reader now, so there is nothing left to diverge:
# everything that genuinely differed between the two is a parameter below.
#
# ONLY THE FIRST TABLE IS READ. A section legitimately carries a second one -
# roadmap-sequencing.md Rule 3 puts its permutation comparison under the roadmap
# heading, and that table's first column is an ORDER rather than an item - so
# reading every table would report each of those rows as an item that escaped
# the ledger. The read STOPS the moment the answer can no longer change: at the
# heading that closes the section, or at the line that ends the first table in
# it.
#
# NO COMPARISON AGAINST DOCUMENT TEXT IS CULTURE-AWARE. `-ceq` on a string and
# `-eq`/`-ge` on a [char] both take PowerShell's culture path, which folds a
# combining sequence onto its precomposed form and reports a heading carrying a
# zero-width space EQUAL to one without - and these two documents are founder
# prose carrying both, while bin/vault-lint.sh compares bytes in awk. So every
# comparison here is ordinal and every character test is a code point. The
# `fence-zwsp` fixture is what fails when one of them goes back to culture, and
# `$hdr.Length -ne 0` is why: `$hdr -cne ''` reports a header row holding
# nothing but a zero-width space EMPTY, and the item column is then never read
# off it.
# ----------------------------------------------------------------------------

# Strips to [a-z0-9], lowercasing letters, so any spelling the slug rule
# resolves to the wanted heading folds onto it here too without this function
# having to know which characters that rule drops. Code points rather than
# `-ge`/`-le` on [char], because awk's `c >= "a" && c <= "z"` is a byte range
# and a [char] comparison is not guaranteed to be one.
#
# --supersession-sweep, --binding-driver and --claim-drift each carry their own
# copy of this fold under the mode-local seam those stubs were built to; this is
# the shared one, for the two modes that share the reader below.
function ConvertTo-TableFold {
	param([string]$Text)
	$sb = New-Object System.Text.StringBuilder
	for ($i = 0; $i -lt $Text.Length; $i++) {
		$cc = [int]$Text[$i]
		if ($cc -ge 97 -and $cc -le 122) { [void]$sb.Append([char]$cc); continue }
		if ($cc -ge 65 -and $cc -le 90) { [void]$sb.Append([char]($cc + 32)); continue }
		if ($cc -ge 48 -and $cc -le 57) { [void]$sb.Append([char]$cc); continue }
	}
	return $sb.ToString()
}

# The item cells of the FIRST table under $Heading, plus whether that heading was
# ever seen - which the caller needs to tell "the document has no such section"
# apart from "the section is there and lists nothing".
#
# THE THREE PARAMETERS ARE THE WHOLE DIFFERENCE between the two modes:
#   -Heading        the folded heading the read opens on: `roadmap`, `assumptions`
#   -ItemHeader     the folded header cell that names the item column: `item`,
#                   `assumption`
#   -DefaultColumn  the 1-based column read when no header cell folds to
#                   -ItemHeader. THIS IS THE ONE THAT BITES. The roadmap's Rule 1
#                   table has no ordinal ahead of its item, so column one is
#                   right there; the assumptions template ships
#                   `| # | Assumption | Value | Source | Confidence |`, where
#                   column one is the `A-n` row label the plan cites in prose and
#                   a roadmap `moves` field names - defaulting to it would report
#                   `1`, `2` and `3` as three inputs that escaped the ledger on a
#                   table whose every row resolves.
#
# THE HEADER ROW IS READ FOR NOTHING BUT WHICH COLUMN HOLDS THE ITEM, and the row
# directly above the alignment rule is that header: the rule is what separates
# header from body, because counting instead would take the header as an item on
# a table written with two header lines and the first real item as a header on a
# table written with none. A table with NO alignment rule is not a table to any
# renderer - it renders as the literal pipes a reader sees - so its rows stay out
# of the body and the section reports as one that lists nothing.
#
# The section ends at the next heading of the same depth or shallower, so a
# subsection under it is still part of it.
#
# The fence tracking is one of six copies in this file, one per mode that reads a
# document at the vault root, and the row parser is one of two - --binding-driver
# readdoc() reads the corner verdict table under the same rules. Collapsing the
# two table readers into this one function removed one copy of each; the rest
# stay, so change one and change all of them.
function Read-FirstItemTable {
	param([string]$Path, [string]$Heading, [string]$ItemHeader, [int]$DefaultColumn)

	$fc = ''
	$fn = 0
	$seenHeading = $false
	$level = 0
	$inSection = $false
	$inTable = $false
	$col = $DefaultColumn
	$hdr = ''
	$inBody = $false
	$pending = New-Object 'System.Collections.Generic.List[string]'
	$items = New-Object 'System.Collections.Generic.List[string]'

	foreach ($rawLine in (Read-TextLines $Path)) {
		$line = Remove-TrailingCr $rawLine
		$t = $line.TrimStart($script:SPACE_TAB)

		# `$fc` stays a string because it carries awk's `fc = ""` sentinel; the
		# fence character it holds is compared as a code point.
		if ($t.StartsWith('```', [System.StringComparison]::Ordinal) -or $t.StartsWith('~~~', [System.StringComparison]::Ordinal)) {
			$fenceChar = [int]$t[0]
			$n = 0
			while ($n -lt $t.Length -and [int]$t[$n] -eq $fenceChar) { $n++ }
			if ($fc.Length -eq 0) { $fc = [string][char]$fenceChar; $fn = $n }
			elseif ([int]$fc[0] -eq $fenceChar -and $n -ge $fn) { $fc = ''; $fn = 0 }
			continue
		}
		if ($fc.Length -ne 0) { continue }

		$headingMatch = [regex]::Match($t, '\A(#+)[ \t]+')
		if ($headingMatch.Success) {
			$nh = $headingMatch.Groups[1].Length
			$h = $t.Substring($headingMatch.Length)
			$h = $h -creplace '[ \t]*#+[ \t]*\z', ''
			$h = $h.Trim($script:SPACE_TAB)
			$explicitAnchor = ''
			$anchorMatch = [regex]::Match($h, '[{]#[A-Za-z0-9_-]+[}]\z')
			if ($anchorMatch.Success) {
				$explicitAnchor = $anchorMatch.Value -creplace '\A[{]#', ''
				$explicitAnchor = $explicitAnchor -creplace '[}]\z', ''
				$h = $h.Substring(0, $anchorMatch.Index).Trim($script:SPACE_TAB)
			}
			if ($inSection -and $nh -le $level) { break }
			if (-not $seenHeading -and ([string]::Equals((ConvertTo-TableFold $explicitAnchor), $Heading, [System.StringComparison]::Ordinal) -or [string]::Equals((ConvertTo-TableFold $h), $Heading, [System.StringComparison]::Ordinal))) {
				$inSection = $true; $seenHeading = $true; $level = $nh
			}
			continue
		}

		if (-not $inSection) { continue }
		if (-not $t.StartsWith('|', [System.StringComparison]::Ordinal)) {
			if ($inTable) { break }
			continue
		}
		$inTable = $true

		$row = $t -creplace '\A\|', ''
		$row = $row -creplace '\|[ \t]*\z', ''
		$cells = $row -split '\|'
		if ($cells.Count -lt 1) { continue }
		$allDash = $true
		foreach ($cell in $cells) {
			if (-not [regex]::IsMatch($cell, '\A[ \t]*:?-+:?[ \t]*\z')) { $allDash = $false; break }
		}
		if ($allDash) {
			if ($hdr.Length -ne 0) {
				$hdrCells = $hdr -split '\|'
				for ($i = 0; $i -lt $hdrCells.Count; $i++) {
					if ([string]::Equals((ConvertTo-TableFold $hdrCells[$i]), $ItemHeader, [System.StringComparison]::Ordinal)) { $col = $i + 1; break }
				}
			}
			$inBody = $true
			continue
		}

		if ($inBody) { [void]$pending.Add($row) } else { $hdr = $row }
	}

	foreach ($p in $pending) {
		$cells = $p -split '\|'
		$item = ''
		if ($col -le $cells.Count) { $item = $cells[$col - 1].Trim($script:SPACE_TAB) }
		if ($item.Length -ne 0) { [void]$items.Add($item) }
	}

	return [pscustomobject]@{ Rows = $items; SeenHeading = $seenHeading }
}

# ----------------------------------------------------------------------------
# usage and refusals
#
# Transcribed verbatim from bin/vault-lint.sh's usage() heredoc, except for the
# binary name itself (see the substitution at the end of Show-Usage). The two
# texts are held together by `vault-lint.ps1 --help` against `vault-lint.sh
# --help`, and by the fixture suite's --help census assertion, which runs
# against whichever implementation VAULT_LINT names - so a paragraph added on
# one side and not the other is a mode with a working flag and no help text,
# which reads to its author exactly like a mode that was never added.
#
# ONE BLOCK PER MODE, IN MODE_TABLE ORDER, AND A NEW MODE APPENDS ITS BLOCK
# IMMEDIATELY BEFORE THE `graph` ONE - the same rule bin/vault-lint.sh:71 states,
# for the same reason: interleaving turns a release that adds three modes into
# three edits to the same lines, and git merges two of them textually clean.
#
# THE SYNOPSIS LINES BELOW ARE WRITTEN AS `vault-lint.sh` AND RENDERED AS
# $PROG. A session running this file has no `vault-lint.sh` to run - that is
# the whole reason this file exists - so printing the literal would send its
# reader after a command their machine does not have. The census assertion in
# scripts/fixtures/run-fixtures.sh matches the basename of whichever
# implementation VAULT_LINT names, not the literal `vault-lint.sh`, so this
# substitution and that assertion move together rather than one hardcoding
# what the other computes.
# ----------------------------------------------------------------------------

function Show-Usage {
	# CRLF is stripped rather than assumed absent. .gitattributes pins this file
	# to LF, but a here-string carries whatever line ending the file on disk has,
	# so a checkout that lost the attribute would emit CRLF help text and diverge
	# from the shell on all of it at once, with nothing on screen to show why.
	$text = @'
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

      superseded-by-unreciprocated: a note whose `superseded_by` names a note
      this vault holds, where that note's `supersedes` does not name it back.
      The worklist is walked from the SUPERSEDING side, because that is where
      the reason and the `reconciled:` date live - so an edge written from the
      replaced note's end only reaches nothing, and the note reads as replaced
      by nothing at all while the record plainly names a successor. Observed:
      an assumption backing a live model row carried `superseded_by`, the named
      claim never named it back, and three current claims went on resting on
      the dead note. The repair is one line on the note the record already
      names, which is why this is not the same row as replaced-by-nothing.

      superseded-by-dangling: a note whose `superseded_by` names an ID no note
      in this vault carries. The record names a successor nobody can open, so
      there is nothing to read the replacement out of and nothing to add the
      back-edge to. The dangling-edge check in `check` walks the block-list
      edge fields and never this scalar, so nothing else reports it.

      Neither is gated on schemaVersion: both fire on the PRESENCE of
      `superseded_by`, so a corpus that never wrote the field cannot owe them
      and no existing vault reddens on the day the skill updates.

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
      The anchor's section runs to the next heading of the SAME DEPTH OR
      SHALLOWER, so a table inside a ### subsection under it is still that
      section's table. Read to the next heading of any depth instead, a plan
      that opens a subsection one line in has its corner table fall outside
      the section, the mode reads zero rows, and the whole corner-row half
      goes quiet while the run still passes.

      A plan whose verdict anchor carries no such table is reported as
      exactly that, and the success line names the kind check as not run:
      zero rows compared is not the same answer as zero rows disagreeing.

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

  vault-lint.sh --monitoring [--vault PATH] [--json]
      Check the monitoring plan in competitor-analysis.md: every axis names an
      instrument, a cadence, and the decision it would change. A verdict - it
      exits 1 on any of them.

      A snapshot cannot see a direction. Every profile in that document carries
      its research date, and every claim note carries `stale_after`, and both
      of those ask the same question - is this still true. Neither asks which
      way it is moving, and that is the only thing separating a closing window
      from an open one: a competitor profiled the day before it was used missed
      a strategic reversal by that vendor six weeks earlier, which was the
      single fact that most changed what the competitor meant. The plan read
      correct and was answering a question nobody asked.

      An axis with no instrument is a thing somebody intends to notice, which
      is not a mechanism. An axis with no cadence is a re-check with no date,
      which is the same as no re-check. An axis with no decision behind it is
      a signal nobody acts on, and collecting it costs the same as collecting
      one that matters - so the decision column is what keeps the plan from
      growing a watchlist instead of a trigger.

      A cell is empty when it carries no letter or digit, so an em dash or a
      run of hyphens is read as empty rather than as an answer. There is no
      placeholder word list: a check that has to be taught every spelling of
      `TBD` is one that misses the next one.

      A vault with no competitor-analysis.md at its root passes, and the
      success line names the document it could not open and says the axes
      went unread - never that no competitor set was profiled, which is a
      conclusion a missing file cannot support. Gated on schemaVersion 2 -
      the axes are what version 2 asks the section for, and a vault at 1 is
      held to the rules it was written under.

  vault-lint.sh --deliverable [--vault PATH] [--json]
      Read every rendered deliverables/*.html and fail on the vault's own
      archaeology reaching a reader who was never in the room: a strikethrough
      span, a note ID, or a red-team objection code. A verdict - it exits 1 on
      any of the three.

      Retraction stays visible in the vault, and that rule is correct - a
      silently deleted claim comes back two drafts later with its cause of
      death erased. The rendered artifact is the other side of it. A note ID
      and an objection code are VAULT ADDRESSES: they resolve for anyone with
      the corpus and resolve to nothing for the audience the document is for,
      and a struck-through line with its reason beside it is a document
      arguing with its own previous draft. Left unchecked, a finished plan and
      its model carry well over a hundred pieces of that narrative between
      them - into the two documents an investor reads.

      IT READS THE RENDERED HTML AND NEVER THE MARKDOWN. The markdown is the
      working document and keeps every strikethrough it owes; the HTML is what
      the outside reader holds. It is also the only one a check can hold to
      this, because the render itself is a judgement - a correction reaches
      the artifact RESTATED FORWARD, as what is true now, and stripping the
      `~~` mechanically leaves `That multiple was actually...` with no
      antecedent. No script can judge an antecedent, so that half stays a
      read-back item in the render loop and this mode covers the half that is
      mechanical.

      A note ID is matched as its type prefix plus EIGHT generated characters,
      the length vault.md's generation rule produces. Validating a note's own
      ID deliberately accepts any length; DETECTING one that leaked into prose
      is the opposite job, and the loose form fires on `FACT-CHECKED` and
      `SOURCE-CONTROL` - a check that cries wolf over ordinary prose gets
      switched off, and switching it off takes the half that worked with it.
      For the same reason `WITHDRAWN` and `RETRACTED` are NOT matched: a plan
      can legitimately discuss a withdrawn product or a retracted filing, and
      those words are the restate-forward step's job rather than a grep's.

      A vault with no deliverables/*.html has rendered nothing and passes. It
      is in --release-gate so the call before a render is still one call, but
      the run that gates what actually ships is the one inside the render loop,
      after the HTML exists - see the render loop in rendering.md.

  vault-lint.sh --assumption-rows [--vault PATH] [--json]
      Check the assumptions table in financial-model.md against the assumption
      notes that declare themselves inputs to the model, both directions. A
      verdict - it exits 1 on any of its five failures.

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

      model-row-dead-assumption: a row whose only title match is an
      `assumption` note at `status: superseded` or `retracted`. The title match
      says the row was rendered off SOME note; it does not say the ledger still
      stands behind it. A live row backed only by a retired note is an input
      the projection rests on that nothing orders in the validation queue, and
      the match reads as clean - observed as exactly that, a live assumption
      row backed only by a superseded note with the mode reporting `matched
      verbatim` for days. It is separate from model-row-no-assumption because
      the repair is: point the row at the successor, or re-file the note.

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

      A vault where NO note declares itself a model input is reported as
      exactly that, and the success line names assumption-not-in-model as not
      run: the row count it prints is the model-row-no-assumption half alone,
      and the half this mode was written for iterated over nothing.

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
'@
	# Substituted from $PROG rather than transcribed a second time: the shell's
	# heredoc names itself literally because it IS vault-lint.sh, but this file is
	# vault-lint.ps1, and a session that reaches for the command this text names
	# would find nothing on a machine with no shell to run it. Routing through
	# $PROG means the two can never drift apart the way two independent literals
	# eventually would.
	$text = $text -replace 'vault-lint\.sh', $PROG
	Write-OutText (($text -replace "`r`n", "`n") + "`n")
}

# ----------------------------------------------------------------------------
# the mode table - the seam a new mode registers into
#
# Held as a TABLE for the reason bin/vault-lint.sh:305-320 gives, which now
# applies twice over: a new mode is a row, not an arm of a switch, because three
# modes each editing one switch block is three conflicts and git resolves two of
# them textually clean while one mode silently loses the arm that parses its
# flag. The mode census now lives in three places - this table, MODE_TABLE in
# the shell, and MODES in scripts/fixtures/run-fixtures.sh - and
# scripts/parity/parity.mjs cross-checks all three.
#
# Columns, whitespace separated, the last running to the end of the line:
#
#   SELECTOR  the argument that selects the mode - a flag, or `check` for the
#             one mode that is a bare subcommand
#   GATE      `gate` if --release-gate runs it as one of its parts, `-` if not
#   PART      the heading --release-gate prints above that part's output
#
# There is no MODE column because it would restate its neighbour on every row:
# the MODE token is the SELECTOR with its leading `--` stripped. That is a rule
# a new mode has to follow rather than an accident - a flag and a token that
# disagreed would be a discrepancy this table could not show.
#
# `graph` is deliberately not a row. It takes an operand rather than being
# selected by a flag, so it is parsed in the positional block below - and a mode
# that needs a note ID has nothing --release-gate could run unattended.
#
# --unverified is a row but not a gate part. Its whole population is the healthy
# case - an assumption is supposed to be unverified until its validation step
# runs - so a gate that ran it would either ignore the output or fail every
# vault that has an assumption in it.
# ----------------------------------------------------------------------------

$MODE_TABLE = @'
check                gate  note-level checks
--unverified         -     -
--used-in            gate  citation targets
--supersession-sweep gate  supersession blast radius
--release-gate       -     -
--red-team           gate  panel objection rows
--roadmap-table      gate  roadmap table against the milestone set
--binding-driver     gate  verdict drivers and the evidence under them
--monitoring         gate  monitoring axes and the decision each would change
--deliverable        gate  what the rendered deliverable carries out of the vault
--assumption-rows    gate  assumption rows against the model table
--claim-drift        gate  cited sections against their recorded hash
'@

# The table's rows as records - the shape `while read -r sel gate part` gives
# the shell, including PART running to the end of the line rather than stopping
# at the first space in it.
function Get-ModeRows {
	$rows = New-Object 'System.Collections.Generic.List[psobject]'
	foreach ($line in $script:MODE_TABLE.Split([char]10)) {
		$trimmed = (Remove-TrailingCr $line).Trim($script:SPACE_TAB)
		if ($trimmed.Length -eq 0) { continue }
		$fields = [regex]::Split($trimmed, '[ \t]+')
		$gate = ''
		$part = ''
		if ($fields.Count -ge 2) { $gate = $fields[1] }
		if ($fields.Count -ge 3) { $part = ($trimmed -creplace '\A[^ \t]+[ \t]+[^ \t]+[ \t]+', '') }
		[void]$rows.Add((New-Object psobject -Property @{ Selector = $fields[0]; Gate = $gate; Part = $part }))
	}
	return $rows
}

# The MODE a command-line flag selects, or '' when the flag names no mode.
# `check` is in the table so --release-gate can invoke it, and is skipped here
# because it stays a positional subcommand: accepting it as a flag would make
# `vault-lint.ps1 --vault PATH check` mean something it has never meant.
function Get-ModeForFlag {
	param([string]$Flag)
	foreach ($row in (Get-ModeRows)) {
		# `--?*` - a flag, and something after the two dashes.
		if ($row.Selector.Length -lt 3) { continue }
		if (-not $row.Selector.StartsWith('--', [System.StringComparison]::Ordinal)) { continue }
		if ($row.Selector -ceq $Flag) { return $row.Selector.Substring(2) }
	}
	return ''
}

# ============================================================================
# THE STUB SEAM - A CONTRACT, NOT A PLACEHOLDER
#
# Nine modes, nine functions, in the order the three dispatch points below
# invoke them:
#
#   1. Invoke-ModeReleaseGate        release-gate         bin/vault-lint.sh  467-518
#   2. Invoke-ModeGraph              graph                                   889-1018
#   3. Invoke-ModeUnverified         unverified                             1019-1128
#   4. Invoke-ModeSupersessionSweep  supersession-sweep                     1129-1605
#   5. Invoke-ModeUsedIn             used-in                                1709-1942
#   6. Invoke-ModeRedTeam            red-team                               1943-2120
#   7. Invoke-ModeRoadmapTable       roadmap-table                          2121-2410
#   8. Invoke-ModeBindingDriver      binding-driver                         2411-3002
#   9. Invoke-ModeMonitoring         monitoring                             3122-3322
#  10. Invoke-ModeDeliverable        deliverable                            3323-3445
#  11. Invoke-ModeAssumptionRows     assumption-rows
#  12. Invoke-ModeClaimDrift         claim-drift
#  13. Invoke-ModeCheck              check
#
# THIS LAYOUT IS A CONTRACT SIX SEPARATE BRANCHES BUILD AGAINST. Each of them
# replaces exactly one function body below and touches nothing else in this
# file. That is the only thing keeping six parallel ports of one file textually
# disjoint: git merges by line, and six branches each appending a mode body
# wherever it happened to land would merge clean into a file whose shared
# helpers disagree - which is worse than a conflict, because nothing reports it.
#
# So: DO NOT reorder these functions, DO NOT rename them, DO NOT merge two of
# them, and DO NOT hoist a helper out of one body into the shared region for
# another body to reuse. A helper two modes want is a helper two slices are both
# editing, which is the cross-slice edit this seam exists to prevent - the shell
# keeps six separate copies of one six-line fenced-block scan for exactly that
# reason (bin/vault-lint.sh:1369), and this file inherits the rule.
#
# Every stub answers exit status 3 through Exit-NotPorted. Porting a mode is
# replacing that one call with the mode's real body; the moment it answers
# anything else, scripts/parity/parity.mjs starts diffing it against the shell,
# so its scripts/parity/unported/<mode> marker file goes in the same commit.
#
# The three dispatch POINTS are further down, at the positions the shell
# dispatches from, and they are one line each. They are not a slice's to edit
# either: a mode that moved between dispatch points would read the corpus at a
# different stage than the shell reads it at.
# ============================================================================

# ----------------------------------------------------------------------------
# 1. --release-gate - every mode a release owes, in one call
#
# Ports bin/vault-lint.sh:467-518. Re-invokes this script once per part on
# purpose - a process boundary is the cheapest thing that cannot leak one mode's
# failures into another's verdict - and the exit status is the WORST status any
# part returned, not the last one and not a flattened 1.
# ----------------------------------------------------------------------------
function Invoke-ModeReleaseGate {
	# The running host's own executable, not a bare 'pwsh' on PATH: this process
	# is already running under whichever host was invoked (powershell.exe 5.1 or
	# pwsh), and re-invoking through that same binary is what MainModule.FileName
	# gives - a bare 'pwsh' would silently switch hosts mid-gate on a machine that
	# has both installed, which is not what "the same host you are running
	# under" means.
	$hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName

	$gateStatus = 0
	$gateFailed = ''
	Write-OutText ('vault-lint release-gate: ' + $script:VAULT + "`n")

	# EACH PART IS A FRESH INVOCATION OF THIS SCRIPT, not a function call - see
	# bin/vault-lint.sh:474-480. check and --used-in share one failure file, so
	# running two of them in one process would mean threading a reset between
	# them and letting one mode's failures land in the other's verdict. A process
	# boundary is the cheapest thing that cannot get that wrong.
	foreach ($row in (Get-ModeRows)) {
		if ($row.Gate -cne 'gate') { continue }
		Write-OutText ("`n--- " + $row.Selector + ': ' + $row.Part + " ---`n")

		& $hostExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:PSCommandPath $row.Selector '--vault' $script:VAULT
		$partStatus = $LASTEXITCODE

		# THE EXIT STATUS IS THE WORST STATUS ANY PART RETURNED, not the last one
		# and not a flattened 1 - bin/vault-lint.sh:486-490. A refusal (2) and a
		# failed check (1) are different answers, and reporting both as 1 sends a
		# reader hunting for a failure in a check that never ran.
		if ($partStatus -gt $gateStatus) { $gateStatus = $partStatus }
		if ($partStatus -ne 0) { $gateFailed = $gateFailed + ' ' + $row.Selector }
	}

	if ($gateStatus -eq 0) {
		Write-OutText ("`nvault-lint release-gate: every part passed - " + $script:VAULT + "`n")
	} else {
		Write-ErrText ("`nvault-lint release-gate: did not pass -" + $gateFailed + "`n")
	}
	exit $gateStatus
}

# ----------------------------------------------------------------------------
# 2. graph - the neighbourhood of one note, as text
#
# Ports bin/vault-lint.sh:889-1018. Takes a note ID operand and refuses --json;
# both are already handled in the argument parser below.
# ----------------------------------------------------------------------------
function Invoke-ModeGraph {
	$sep = [char]28

	# Reads $script:RECORDS the way the shell's graph awk reads $RECORDS: a
	# fresh N/S/L index built from scratch. Every mode that reads the record
	# stream owns its own copy of this loop rather than sharing one - the shell
	# runs each mode as a separate awk process for the same reason (see the
	# fenced-block-scan note at bin/vault-lint.sh:1283), and hoisting this out
	# of the mode body is the cross-slice edit the stub seam forbids.
	$files = New-Object 'System.Collections.Generic.List[string]'
	$v = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$li = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	foreach ($rec in $script:RECORDS) {
		$p = $rec.Split([char]9)
		if ($p[0] -ceq 'N') { [void]$files.Add($p[1]); continue }
		if ($p[0] -ceq 'S') { $v[$p[1] + $sep + $p[2]] = $p[3]; continue }
		if ($p[0] -ceq 'L') {
			$k = $p[1] + $sep + $p[2]
			$items = $null
			if (-not $li.TryGetValue($k, [ref]$items)) {
				$items = New-Object 'System.Collections.Generic.List[string]'
				$li[$k] = $items
			}
			[void]$items.Add($p[3])
			continue
		}
	}

	$edgeFields = $script:EDGE_FIELDS.Split([char]32)
	$maxDepth = [int]$script:DEPTH
	# Duplicated in the checks pass, same as in the shell - see bin/vault-lint.sh:906.
	$rxId = [regex]'\A(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)-[A-Za-z0-9]+\z'

	function Get-GraphValue {
		param([string]$File, [string]$Key)
		$k = $File + $sep + $Key
		if ($v.ContainsKey($k)) { return $v[$k] }
		return ''
	}

	function Test-GraphId {
		param([string]$Text)
		return $rxId.IsMatch($Text)
	}

	function Get-GraphPad {
		param([int]$N)
		return (' ' * $N)
	}

	# A value stores newlines as the two characters \n, so the first line of a
	# block scalar is everything before the first one.
	function Get-GraphFirstLine {
		param([string]$Text)
		$p = $Text.IndexOf('\n', [System.StringComparison]::Ordinal)
		if ($p -ge 0) { return $Text.Substring(0, $p) }
		return $Text
	}

	function Get-GraphTargetOf {
		param([string]$Item)
		$marker = ' :: '
		$p = $Item.IndexOf($marker, [System.StringComparison]::Ordinal)
		if ($p -ge 0) { return $Item.Substring($p + $marker.Length) }
		return $Item
	}

	function Get-GraphLabel {
		param([string]$Id)
		if (-not $byId.ContainsKey($Id)) { return $Id + '  (no note in this vault carries this ID)' }
		$f = $byId[$Id]
		$s = $Id + '  ' + (Get-GraphValue $f 'type') + '  confidence ' + (Get-GraphValue $f 'confidence') + '  status ' + (Get-GraphValue $f 'status')
		$subject = Get-GraphValue $f 'subject'
		if ($subject.Length -gt 0) { $s = $s + '  subject ' + $subject }
		return $s
	}

	function Get-GraphDetail {
		param([string]$Id, [string]$Prefix)
		if (-not $byId.ContainsKey($Id)) { return '' }
		$f = $byId[$Id]
		$out = $Prefix + (Get-GraphValue $f 'title') + "`n"
		$quote = Get-GraphValue $f 'quote'
		if ($quote.Length -gt 0) { $out = $out + $Prefix + 'quote: ' + (Get-GraphFirstLine $quote) + "`n" }
		$reasoning = Get-GraphValue $f 'reasoning'
		if ($reasoning.Length -gt 0) { $out = $out + $Prefix + 'reasoning: ' + (Get-GraphFirstLine $reasoning) + "`n" }
		$founderReasoning = Get-GraphValue $f 'founder_reasoning'
		if ($founderReasoning.Length -gt 0) { $out = $out + $Prefix + 'founder_reasoning: ' + (Get-GraphFirstLine $founderReasoning) + "`n" }
		$reopenIf = Get-GraphValue $f 'reopen_if'
		if ($reopenIf.Length -gt 0) { $out = $out + $Prefix + 'reopen_if: ' + (Get-GraphFirstLine $reopenIf) + "`n" }
		return $out
	}

	# Edges are stored once, on the asserting note, and never mirrored, so the
	# inbound direction has to be derived - once into $rev rather than
	# rescanning every note per visited node, which keeps a traversal
	# proportional to the neighbourhood printed rather than to corpus size.
	function Invoke-GraphBuildRev {
		foreach ($f in $files) {
			$srcId = Get-GraphValue $f 'id'
			if ($srcId.Length -eq 0) { continue }
			foreach ($edge in $edgeFields) {
				$k = $f + $sep + $edge
				$items = $null
				if (-not $li.TryGetValue($k, [ref]$items)) { continue }
				foreach ($item in $items) {
					$tgt = Get-GraphTargetOf $item
					if ($tgt.Length -eq 0 -or $tgt -ceq $srcId) { continue }
					$revList = $null
					if (-not $rev.TryGetValue($tgt, [ref]$revList)) {
						$revList = New-Object 'System.Collections.Generic.List[string]'
						$rev[$tgt] = $revList
					}
					[void]$revList.Add($srcId + $sep + $edge)
				}
			}
		}
	}

	function Invoke-GraphWalkOut {
		param([string]$Id, [int]$Depth, [int]$Indent)
		if ($Depth -gt $maxDepth) { return }
		if (-not $byId.ContainsKey($Id)) { return }
		$f = $byId[$Id]
		$padItem = Get-GraphPad ($Indent + 2)
		$padDetail = Get-GraphPad ($Indent + 4)
		foreach ($edge in $edgeFields) {
			$k = $f + $sep + $edge
			$items = $null
			if (-not $li.TryGetValue($k, [ref]$items)) { continue }
			[void]$sb.Append((Get-GraphPad $Indent) + $edge + " ->`n")
			foreach ($item in $items) {
				$tgt = Get-GraphTargetOf $item
				if (-not (Test-GraphId $tgt)) {
					[void]$sb.Append($padItem + $item + "`n")
					continue
				}
				[void]$sb.Append($padItem + (Get-GraphLabel $tgt) + "`n")
				[void]$sb.Append((Get-GraphDetail $tgt $padDetail))
				if (-not $seenOut.Contains($tgt)) {
					[void]$seenOut.Add($tgt)
					Invoke-GraphWalkOut $tgt ($Depth + 1) ($Indent + 4)
				}
			}
		}
	}

	function Invoke-GraphWalkIn {
		param([string]$Id, [int]$Depth, [int]$Indent)
		if ($Depth -gt $maxDepth) { return }
		$entries = $null
		$hasRev = $rev.TryGetValue($Id, [ref]$entries)
		if ($Depth -eq 1 -and -not $hasRev) {
			[void]$sb.Append((Get-GraphPad $Indent) + "(nothing in this vault rests on it)`n")
			return
		}
		if (-not $hasRev) { return }
		$padLabel = Get-GraphPad $Indent
		$padDetail = Get-GraphPad ($Indent + 2)
		foreach ($entry in $entries) {
			$parts = $entry.Split($sep)
			$src = $parts[0]
			$via = $parts[1]
			[void]$sb.Append($padLabel + (Get-GraphLabel $src) + '   (via ' + $via + ")`n")
			[void]$sb.Append((Get-GraphDetail $src $padDetail))
			if (-not $seenIn.Contains($src)) {
				[void]$seenIn.Add($src)
				Invoke-GraphWalkIn $src ($Depth + 1) ($Indent + 2)
			}
		}
	}

	$byId = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	foreach ($f in $files) {
		$id = Get-GraphValue $f 'id'
		if ($id.Length -gt 0) { $byId[$id] = $f }
	}
	$rev = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	Invoke-GraphBuildRev

	if (-not $byId.ContainsKey($script:TARGET)) {
		# Literal "vault-lint: ", not $PROG - bin/vault-lint.sh:1000 hardcodes this
		# exact prefix in the awk program rather than routing through die(), so
		# this is a transcription of that literal rather than a call to
		# Exit-Refusal.
		Write-ErrText ('vault-lint: no note with ID ' + $script:TARGET + ' under ' + $script:VAULT + "`n")
		exit 2
	}

	$sb = New-Object System.Text.StringBuilder
	$seenOut = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$seenIn = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)

	[void]$sb.Append('vault-lint graph: ' + $script:TARGET + '  (depth ' + $maxDepth + ")`n")
	[void]$sb.Append('  vault: ' + $script:VAULT + "`n")
	[void]$sb.Append('  file:  ' + $byId[$script:TARGET] + "`n`n")
	[void]$sb.Append((Get-GraphLabel $script:TARGET) + "`n")
	[void]$sb.Append((Get-GraphDetail $script:TARGET '  '))
	[void]$sb.Append("`n")
	[void]$sb.Append("  rests on`n")
	[void]$seenOut.Add($script:TARGET)
	Invoke-GraphWalkOut $script:TARGET 1 4
	[void]$sb.Append("`n  rested on by`n")
	[void]$seenIn.Add($script:TARGET)
	Invoke-GraphWalkIn $script:TARGET 1 4

	Write-OutText $sb.ToString()
	exit 0
}

# ----------------------------------------------------------------------------
# 3. --unverified - the notes asserted with nothing behind them
#
# Ports bin/vault-lint.sh:1019-1128. Carries its OWN JSON escaper, one of three
# deliberate copies (bin/vault-lint.sh:1660) - transcribe that copy rather than
# routing through Render-Failures, and change all three together or none.
# ----------------------------------------------------------------------------
function Invoke-ModeUnverified {
	$sep = [char]28

	# Same N/S/L index-building loop as Invoke-ModeGraph, kept as its own copy
	# rather than a shared helper - see the comment at the top of that function
	# for why.
	$files = New-Object 'System.Collections.Generic.List[string]'
	$v = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$li = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	foreach ($rec in $script:RECORDS) {
		$p = $rec.Split([char]9)
		if ($p[0] -ceq 'N') { [void]$files.Add($p[1]); continue }
		if ($p[0] -ceq 'S') { $v[$p[1] + $sep + $p[2]] = $p[3]; continue }
		if ($p[0] -ceq 'L') {
			$k = $p[1] + $sep + $p[2]
			$items = $null
			if (-not $li.TryGetValue($k, [ref]$items)) {
				$items = New-Object 'System.Collections.Generic.List[string]'
				$li[$k] = $items
			}
			[void]$items.Add($p[3])
			continue
		}
	}

	function Get-UnverifiedValue {
		param([string]$File, [string]$Key)
		$k = $File + $sep + $Key
		if ($v.ContainsKey($k)) { return $v[$k] }
		return ''
	}

	# One of three identical copies - see the note beside the
	# --supersession-sweep one, bin/vault-lint.sh:1660, for why they stay
	# copies and what would change that. Change one, change all three.
	function ConvertTo-UnverifiedJsonEscaped {
		param([string]$Text)
		$out = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$c = $Text[$i]
			if ($c -eq [char]34) { [void]$out.Append('\"') }
			elseif ($c -eq [char]92) { [void]$out.Append('\\') }
			elseif ($c -eq [char]9) { [void]$out.Append([char]32) }
			else { [void]$out.Append($c) }
		}
		return $out.ToString()
	}

	function Get-UnverifiedJsonList {
		param([string]$File, [string]$Key)
		$k = $File + $sep + $Key
		$out = '['
		if ($li.ContainsKey($k)) {
			$items = $li[$k]
			for ($i = 0; $i -lt $items.Count; $i++) {
				if ($i -ne 0) { $out = $out + ', ' }
				$out = $out + '"' + (ConvertTo-UnverifiedJsonEscaped $items[$i]) + '"'
			}
		}
		return $out + ']'
	}

	function Get-UnverifiedPlain {
		param([string]$File, [string]$Key, [string]$Indent)
		$k = $File + $sep + $Key
		$out = ''
		if (-not $li.ContainsKey($k)) { return $out }
		foreach ($item in $li[$k]) { $out = $out + $Indent + $Key + ': ' + $item + "`n" }
		return $out
	}

	function Get-UnverifiedText {
		param([string]$File, [string]$Id)
		$out = '    ' + $Id + '  ' + (Get-UnverifiedValue $File 'type') + '  confidence ' + (Get-UnverifiedValue $File 'confidence') + '  status ' + (Get-UnverifiedValue $File 'status') + "`n"
		$out = $out + '      ' + (Get-UnverifiedValue $File 'title') + "`n"
		$sensitivity = Get-UnverifiedValue $File 'sensitivity'
		if ($sensitivity.Length -gt 0) { $out = $out + '      sensitivity: ' + $sensitivity + "`n" }
		$out = $out + (Get-UnverifiedPlain $File 'validated_by' '      ')
		$out = $out + (Get-UnverifiedPlain $File 'used_in' '      ')
		return $out
	}

	$unverified = New-Object 'System.Collections.Generic.List[string]'
	$lowConfidence = New-Object 'System.Collections.Generic.List[string]'
	$reason = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	foreach ($f in $files) {
		$id = Get-UnverifiedValue $f 'id'
		if ($id.Length -eq 0) { continue }
		if ((Get-UnverifiedValue $f 'status') -ceq 'unverified') {
			[void]$unverified.Add($f)
			$reason[$f] = 'status-unverified'
		} elseif ((Get-UnverifiedValue $f 'confidence') -ceq 'L') {
			[void]$lowConfidence.Add($f)
			$reason[$f] = 'low-confidence'
		}
	}
	$total = $unverified.Count + $lowConfidence.Count

	if ($script:JSON -eq 1) {
		$sb = New-Object System.Text.StringBuilder
		[void]$sb.Append("{`n")
		[void]$sb.Append('  "vault": "' + (ConvertTo-UnverifiedJsonEscaped $script:VAULT) + "`",`n")
		[void]$sb.Append('  "unverified_count": ' + $total + ",`n")
		[void]$sb.Append('  "notes": [')
		$n = 0
		for ($pass = 1; $pass -le 2; $pass++) {
			$pool = $unverified
			if ($pass -eq 2) { $pool = $lowConfidence }
			foreach ($f in $pool) {
				$n++
				if ($n -eq 1) { [void]$sb.Append("`n    {") } else { [void]$sb.Append(",`n    {") }
				[void]$sb.Append('"id": "' + (ConvertTo-UnverifiedJsonEscaped (Get-UnverifiedValue $f 'id')) + '", ')
				[void]$sb.Append('"file": "' + (ConvertTo-UnverifiedJsonEscaped $f) + '", ')
				[void]$sb.Append('"type": "' + (ConvertTo-UnverifiedJsonEscaped (Get-UnverifiedValue $f 'type')) + '", ')
				[void]$sb.Append('"status": "' + (ConvertTo-UnverifiedJsonEscaped (Get-UnverifiedValue $f 'status')) + '", ')
				[void]$sb.Append('"confidence": "' + (ConvertTo-UnverifiedJsonEscaped (Get-UnverifiedValue $f 'confidence')) + '", ')
				[void]$sb.Append('"reason": "' + (ConvertTo-UnverifiedJsonEscaped $reason[$f]) + '", ')
				[void]$sb.Append('"title": "' + (ConvertTo-UnverifiedJsonEscaped (Get-UnverifiedValue $f 'title')) + '", ')
				[void]$sb.Append('"used_in": ' + (Get-UnverifiedJsonList $f 'used_in') + '}')
			}
		}
		if ($n -eq 0) { [void]$sb.Append("]`n}`n") } else { [void]$sb.Append("`n  ]`n}`n") }
		Write-OutText $sb.ToString()
		exit 0
	}

	$plural = 's'
	if ($total -eq 1) { $plural = '' }
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append('vault-lint unverified: ' + $total + ' note' + $plural + " asserted with nothing behind them`n")
	[void]$sb.Append('  vault: ' + $script:VAULT + "`n")
	[void]$sb.Append("`n  asserted, nothing behind it yet (status: unverified)`n")
	if ($unverified.Count -eq 0) { [void]$sb.Append("    (none)`n") }
	foreach ($f in $unverified) { [void]$sb.Append((Get-UnverifiedText $f (Get-UnverifiedValue $f 'id'))) }
	[void]$sb.Append("`n  carried at Low confidence - the weakest link in the chain below it is thin`n")
	if ($lowConfidence.Count -eq 0) { [void]$sb.Append("    (none)`n") }
	foreach ($f in $lowConfidence) { [void]$sb.Append((Get-UnverifiedText $f (Get-UnverifiedValue $f 'id'))) }

	Write-OutText $sb.ToString()
	exit 0
}

# ----------------------------------------------------------------------------
# 4. --supersession-sweep - the re-read worklist a supersession owes
#
# Ports bin/vault-lint.sh:1129-1605. Carries the third copy of the escaper, and
# exits above the shared render block for the reason stated there.
# ----------------------------------------------------------------------------
function Invoke-ModeSupersessionSweep {
	# Parses the record stream into the same shape pass 2 emits it in: N rows
	# give the file list in vault order, S rows are a scalar per (file, key) -
	# the last one wins, exactly as awk's V[$2,$3]=$4 overwrites - and L rows
	# are a key's block-list items in stream order. T/A/E rows are for `check`
	# and the vocabulary pass; this mode never asked for them, and a bare
	# pattern-match with no matching arm is how the shell skips them too.
	$files = New-Object 'System.Collections.Generic.List[string]'
	$V = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,string]]' ([System.StringComparer]::Ordinal)
	$L = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]]' ([System.StringComparer]::Ordinal)

	foreach ($rec in $script:RECORDS) {
		$p = $rec.Split([char]9)
		if ($p[0] -ceq 'N') {
			[void]$files.Add($p[1])
		} elseif ($p[0] -ceq 'S') {
			if (-not $V.ContainsKey($p[1])) { $V[$p[1]] = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal) }
			$V[$p[1]][$p[2]] = $p[3]
		} elseif ($p[0] -ceq 'L') {
			if (-not $L.ContainsKey($p[1])) { $L[$p[1]] = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' ([System.StringComparer]::Ordinal) }
			if (-not $L[$p[1]].ContainsKey($p[2])) { $L[$p[1]][$p[2]] = New-Object 'System.Collections.Generic.List[string]' }
			[void]$L[$p[1]][$p[2]].Add($p[3])
		}
	}

	function Get-SweepValue {
		param([string]$File, [string]$Key)
		if (-not $V.ContainsKey($File)) { return '' }
		if (-not $V[$File].ContainsKey($Key)) { return '' }
		return $V[$File][$Key]
	}

	# The leading comma on every return is load-bearing, same as
	# Split-TextLines above: without it, Write-Output enumerates the list on
	# the way out, so a 0-item list vanishes to $null and a 1-item list comes
	# back as a bare string instead of a list its caller can call .Count on.
	function Get-SweepList {
		param([string]$File, [string]$Key)
		if (-not $L.ContainsKey($File)) { return , (New-Object 'System.Collections.Generic.List[string]') }
		if (-not $L[$File].ContainsKey($Key)) { return , (New-Object 'System.Collections.Generic.List[string]') }
		return , $L[$File][$Key]
	}

	# The 's' every count-driven line below needs unless the count is exactly
	# one - three call sites (sections, superseded notes, unreconciled
	# supersessions), one rule.
	function Get-SweepPlural {
		param([int]$Count)
		if ($Count -eq 1) { return '' }
		return 's'
	}

	# The third copy of the escaper --unverified and Render-Failures carry, one
	# character at a time - see the comment beside bin/vault-lint.sh:1660's
	# jesc() for why these stay three separate copies instead of one shared
	# function. Change one, change all three, on both implementations.
	function ConvertTo-SweepJsonEscaped {
		param([string]$Text)
		$sb = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$c = $Text[$i]
			if ($c -eq [char]34) { [void]$sb.Append('\"') }
			elseif ($c -eq [char]92) { [void]$sb.Append('\\') }
			elseif ($c -eq [char]9) { [void]$sb.Append([char]32) }
			else { [void]$sb.Append($c) }
		}
		return $sb.ToString()
	}

	# Folds a heading or a cited anchor to its bare alnum bytes, lower-cased -
	# the loose equality bin/vault-lint.sh:1249-1256 explains: two spellings of
	# one section (an explicit {#anchor} and the slug of its text) fold to the
	# same key, without this function needing to know which characters the
	# slug rule drops. Ordinal by construction - int comparisons on UTF-16 code
	# units, never a culture-aware character class.
	function Get-SweepFold {
		param([string]$Text)
		$sb = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$n = [int]$Text[$i]
			if ($n -ge 97 -and $n -le 122) { [void]$sb.Append($Text[$i]); continue }
			if ($n -ge 65 -and $n -le 90) { [void]$sb.Append([char]($n + 32)); continue }
			if ($n -ge 48 -and $n -le 57) { [void]$sb.Append($Text[$i]); continue }
		}
		return $sb.ToString()
	}

	# One internal-only separator for the two composite keys below (a document
	# paired with a fold key, and a worklist key paired with a note). Never
	# emitted and never split back apart, so any byte that cannot occur in a
	# vault-relative path or a folded heading key does - this one is chosen to
	# stay clear of ordinary text rather than to mirror awk's SUBSEP verbatim.
	$SS = [char]1

	# Registers one fold key against one heading ordinal, or retires it when a
	# second heading claims the same key - bin/vault-lint.sh:1259-1267's
	# claim(), copied rather than hoisted for the reason the seam states.
	$ALIAS = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([System.StringComparer]::Ordinal)

	function Set-SweepClaim {
		param([string]$Doc, [string]$Key, [int]$Id)
		if ($Key.Length -eq 0) { return }
		$ak = $Doc + $SS + $Key
		if ($ALIAS.ContainsKey($ak)) {
			if ($ALIAS[$ak] -ne $Id) { $ALIAS[$ak] = 0 }
			return
		}
		$ALIAS[$ak] = $Id
	}

	$RX_HEADING = [regex]'\A#+[ \t]+'
	$RX_ANCHOR = [regex]'[{]#[A-Za-z0-9_-]+[}]\z'

	# One of six copies of the same six-line fenced-block scan
	# (bin/vault-lint.sh:1369 names the other five) - a `#` inside a
	# fenced block is an example, not a heading anyone can jump to, and the
	# fence marker plus its run length are tracked so a longer nested fence
	# cannot close its parent early. Kept local rather than hoisted: the other
	# five copies belong to other mode slices, and reaching across them is
	# exactly the cross-slice edit the stub seam exists to prevent.
	function Read-SweepSections {
		param([string]$Doc)
		$path = $script:VAULT + '/' + $Doc
		if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
		$id = 0
		$fc = ''
		$fn = 0
		foreach ($rawLine in (Read-TextLines $path)) {
			$line = Remove-TrailingCr $rawLine
			$t = $line.TrimStart($script:SPACE_TAB)

			# NO COMPARISON IN THE FENCE SCAN IS CULTURE-AWARE, the rule
			# bin/vault-lint.ps1's --binding-driver copy states and three sibling
			# copies of this scan did not apply. `-ceq` on a string and `-eq` on a
			# [char] both take PowerShell's culture path, which folds a combining
			# sequence onto its precomposed form and ignores a zero-width space -
			# and a document read by this mode is founder prose carrying both,
			# while bin/vault-lint.sh compares bytes in awk. `$fc` stays a string
			# because it carries awk's `fc = ""` sentinel; the fence character it
			# holds is compared as a code point.
			if ($t.StartsWith('```', [System.StringComparison]::Ordinal) -or $t.StartsWith('~~~', [System.StringComparison]::Ordinal)) {
				$c = [int]$t[0]
				$n = 0
				while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
				if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
				elseif ([int]$fc[0] -eq $c -and $n -ge $fn) { $fc = ''; $fn = 0 }
				continue
			}
			if ($fc.Length -gt 0) { continue }

			$hm = $RX_HEADING.Match($t)
			if (-not $hm.Success) { continue }
			$h = $t.Substring($hm.Length)
			$h = $h -creplace '[ \t]*#+[ \t]*\z', ''
			$h = $h.TrimEnd($script:SPACE_TAB)
			$id++

			# An explicit {#anchor} attribute is stripped from the heading text
			# and registered beside it - what --used-in's scan does and what a
			# renderer owes it, so a template that gains explicit anchors does
			# not break an existing citation of the slug.
			$am = $RX_ANCHOR.Match($h)
			if ($am.Success) {
				$ex = $am.Value.Substring(2, $am.Value.Length - 3)
				Set-SweepClaim $Doc (Get-SweepFold $ex) $id
				$h = $h.Substring(0, $am.Index)
				$h = $h.TrimEnd($script:SPACE_TAB)
			}
			Set-SweepClaim $Doc (Get-SweepFold $h) $id
		}
	}

	$SCANNED = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)

	# The grouping key for one target: the heading ordinal it names when the
	# document resolves it, the anchor as written when it does not. Namespaced
	# ("h"/"a") so a raw anchor can never collide with a heading ordinal.
	function Get-SweepResolve {
		param([string]$Doc, [string]$Anchor)
		if ($Anchor.Length -eq 0) { return 'a' }
		if (-not $SCANNED.Contains($Doc)) {
			[void]$SCANNED.Add($Doc)
			Read-SweepSections $Doc
		}
		$k = $Doc + $SS + (Get-SweepFold $Anchor)
		if ($ALIAS.ContainsKey($k) -and $ALIAS[$k] -gt 0) { return 'h' + $ALIAS[$k] }
		return 'a' + $Anchor
	}

	# Which end of the supersession edge this note is actually reachable from -
	# bin/vault-lint.sh's estate(). `superseded_by` is the field a reader writes
	# on the note being REPLACED, and until now nothing read it, so a note whose
	# successor never wrote the matching `supersedes` reported as replaced by
	# nothing at all. Four values: confirmed, unreciprocated, dangling, absent.
	#
	# $SBYST DECIDES WHEREVER THE FIELD IS PRESENT, and $Confirmed only where it
	# is not. Reading $Confirmed first would report `edge_state: confirmed` on a
	# note some OTHER note supersedes while its own `superseded_by` is broken -
	# so the one field whose job is to say which end is reachable would call the
	# edge whole in the same document that lists it under broken_edges. Two call
	# sites, and the walk that fills $SBYST runs once per note.
	function Get-SweepEdgeState {
		param([string]$File, [string]$Confirmed)
		if ($SBYST.ContainsKey($File)) { return $SBYST[$File] }
		if ($Confirmed.Length -ne 0) { return 'confirmed' }
		return 'absent'
	}

	# One superseded note for the JSON worklist - what it said, what replaced
	# it, and why. $SbEntry is the [id, reason] pair half one or half two
	# recorded for this note.
	function Add-SweepNoteJson {
		param([System.Text.StringBuilder]$Sb, [string]$File, [string[]]$SbEntry)
		[void]$Sb.Append('{"id": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $File 'id')) + '", ')
		[void]$Sb.Append('"file": "' + (ConvertTo-SweepJsonEscaped $File) + '", ')
		[void]$Sb.Append('"type": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $File 'type')) + '", ')
		[void]$Sb.Append('"title": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $File 'title')) + '", ')
		[void]$Sb.Append('"superseded_by": "' + (ConvertTo-SweepJsonEscaped $SbEntry[0]) + '", ')
		[void]$Sb.Append('"supersedes_reason": "' + (ConvertTo-SweepJsonEscaped $SbEntry[1]) + '", ')
		[void]$Sb.Append('"declared_superseded_by": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $File 'superseded_by')) + '", ')
		[void]$Sb.Append('"edge_state": "' + (ConvertTo-SweepJsonEscaped (Get-SweepEdgeState $File $SbEntry[0])) + '"}')
	}

	# The same note, as the human report needs it.
	function Add-SweepNoteText {
		param([System.Text.StringBuilder]$Sb, [string]$File, [string[]]$SbEntry, [string]$Pad)
		[void]$Sb.Append($Pad + (Get-SweepValue $File 'id') + '  ' + (Get-SweepValue $File 'type') + "`n")
		[void]$Sb.Append($Pad + '  ' + (Get-SweepValue $File 'title') + "`n")
		$state = Get-SweepEdgeState $File $SbEntry[0]
		$declared = Get-SweepValue $File 'superseded_by'
		if ($state -ceq 'confirmed') {
			[void]$Sb.Append($Pad + '  superseded by ' + $SbEntry[0] + "`n")
			$reasonText = $SbEntry[1]
			if ($reasonText.Length -eq 0) { $reasonText = '(none recorded - `supersedes_reason` is absent, so why it was replaced is already gone)' }
			[void]$Sb.Append($Pad + '  reason: ' + $reasonText + "`n")
		# A HALF-WRITTEN EDGE IS NOT REPLACED BY NOTHING, and printing it as
		# though it were is what sent a reader looking for a successor the note
		# already names. The successor is named HERE, where the reader of this
		# row is; why the edge is broken and what to do about it is one paragraph
		# in the half-written section below, rather than a second wording of the
		# same finding on every row it reached.
		} elseif ($state -ceq 'unreciprocated' -or $state -ceq 'dangling') {
			[void]$Sb.Append($Pad + '  superseded by ' + $declared + ' on its own `superseded_by` only - see the half-written edges below' + "`n")
		} else {
			[void]$Sb.Append($Pad + '  superseded by: nothing - `status: superseded` with no note naming it in `supersedes`, so the record says this was replaced and not by what' + "`n")
		}
	}

	# BYID: the file naming a given id - bin/vault-lint.sh:1436.
	$BYID = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	foreach ($f in $files) {
		$id = Get-SweepValue $f 'id'
		if ($id.Length -gt 0) { $BYID[$id] = $f }
	}

	# ------------------------------------------------------------------------
	# THE VERDICT - bin/vault-lint.sh:1440-1474. `reconciled:` asserts that the
	# sections a note's own `supersedes` edge put in doubt have been read.
	# Required whether or not the superseded note reached a document, and
	# gated on schemaVersion 2 - a corpus written before the field existed
	# cannot owe it.
	# ------------------------------------------------------------------------
	$UNREC = New-Object 'System.Collections.Generic.List[string]'
	$UTGT = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$UWHY = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)

	if ([int]$script:FOUND_SCHEMA -ge 2) {
		foreach ($f in $files) {
			$sup = Get-SweepList $f 'supersedes'
			if ($sup.Count -eq 0) { continue }
			$tg = [string]::Join(', ', $sup)
			$rec = Get-SweepValue $f 'reconciled'
			$cre = Get-SweepValue $f 'created'
			$why = ''
			if ($rec.Length -eq 0) {
				$why = 'no `reconciled:` date. Nothing records that the sections this supersession put in doubt were read, so the worklist this mode prints is one nobody is obliged to finish - and the documents go on asserting what the ledger already replaced while every check stays green'
			} elseif ($cre.Length -gt 0 -and ([string]::CompareOrdinal($rec, $cre) -lt 0)) {
				$why = '`reconciled: ' + $rec + '` predates the `created: ' + $cre + '` on this same note, so the sections were read before the supersession that put them in doubt existed. A date carried over from an earlier pass reads exactly like one stamped after the read, and which of the two it is happens to be the only half of this a check can see'
			}
			if ($why.Length -eq 0) { continue }
			[void]$UNREC.Add($f)
			$UTGT[$f] = $tg
			$UWHY[$f] = $why
		}
	}

	# Half one: every note a `supersedes` edge names, walked from the
	# superseding side because that is where the edge and the reason both live
	# - bin/vault-lint.sh:1541-1554. A dangling target is skipped: `check`
	# already reports a dangling supersedes edge, and inventing a worklist row
	# for a note that is not in the vault would name a re-read nobody can do.
	$SUPBY = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string[]]]' ([System.StringComparer]::Ordinal)
	foreach ($f in $files) {
		$sup = Get-SweepList $f 'supersedes'
		if ($sup.Count -eq 0) { continue }
		$fid = Get-SweepValue $f 'id'
		$freason = Get-SweepValue $f 'supersedes_reason'
		foreach ($tgt in $sup) {
			if (-not $BYID.ContainsKey($tgt)) { continue }
			$tf = $BYID[$tgt]
			if (-not $SUPBY.ContainsKey($tf)) { $SUPBY[$tf] = New-Object 'System.Collections.Generic.List[string[]]' }
			[void]$SUPBY[$tf].Add([string[]]@($fid, $freason))
		}
	}

	# ------------------------------------------------------------------------
	# THE SUPERSESSION HAS TWO ENDS AND ONLY ONE OF THEM WAS EVER READ - ports
	# the `superseded_by` pass in bin/vault-lint.sh's END. Half one above walks
	# `supersedes`, which lives on the SUPERSEDING note, so a note carrying
	# `superseded_by` whose named successor never wrote the matching
	# `supersedes` was invisible from both sides: half one never reached it and
	# half two prints it under `superseded by: nothing`, which says the record
	# names no replacement when in fact it names one and the other end is
	# missing. Different repairs - one line on a named note versus a decision
	# about what replaced this.
	#
	# Observed: an assumption backing a live row in a financial model carried
	# `superseded_by` naming a claim that never named it back. The sweep
	# reported it as replaced by nothing, and three current claims went on
	# resting on the dead note - one of them the single strongest negative in
	# that corpus - because nothing could see that the edge existed and was half
	# written.
	#
	# RECIPROCITY IS READ OFF $SUPBY, THE INDEX HALF ONE JUST BUILT, rather than
	# by re-walking the successor `supersedes` list. That is why this pass sits
	# here and not above: one definition of "that note names this one" means the
	# row a broken edge reports and the row the worklist prints cannot disagree
	# about the same pair.
	#
	# NOT GATED ON schemaVersion: it fires on the PRESENCE of `superseded_by`,
	# so a corpus that never wrote the field cannot owe it. A dangling
	# `superseded_by` is a SEPARATE row - `check` walks the block-list edge
	# fields and never this scalar, so nothing else reports it, and there is no
	# note to add the back-edge to.
	# ------------------------------------------------------------------------
	$SBYST = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$BROKE = New-Object 'System.Collections.Generic.List[string]'
	$BWHY = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)

	foreach ($f in $files) {
		$sby = Get-SweepValue $f 'superseded_by'
		if ($sby.Length -eq 0) { continue }
		$fid = Get-SweepValue $f 'id'
		if ($BYID.ContainsKey($sby)) { $SBYST[$f] = 'unreciprocated' } else { $SBYST[$f] = 'dangling' }
		if ($SUPBY.ContainsKey($f)) {
			# Ordinal, never `-ceq`: that takes the invariant-culture path, which
			# reports an ID carrying a zero-width space equal to one without, and
			# awk compares bytes.
			foreach ($entry in $SUPBY[$f]) {
				if ([string]::Equals($entry[0], $sby, [System.StringComparison]::Ordinal)) { $SBYST[$f] = 'confirmed'; break }
			}
		}
		if ($SBYST[$f] -ceq 'confirmed') { continue }
		[void]$BROKE.Add($f)
		if ($SBYST[$f] -ceq 'unreciprocated') {
			$BWHY[$f] = '`superseded_by: ' + $sby + '` names a note this vault holds, and `supersedes` on ' + $sby + ' does not name ' + $fid + ' back. The worklist is built from the superseding side, because that is where the reason and the `reconciled:` date live - so a supersession written from this end only reaches nothing: this note reads as replaced by nothing at all, and the sections it was cited into are never named for re-reading. Add ' + $fid + ' to `supersedes` on ' + $sby + ', with the `supersedes_reason` that pair owes'
		} else {
			$BWHY[$f] = '`superseded_by: ' + $sby + '` and no note in this vault carries that ID. The record says this note was replaced and names a successor nobody can open, so there is nothing to read the replacement out of and nothing to add the back-edge to - either the successor was never written, or the ID is a typo. The dangling-edge check walks the block-list edge fields and never this scalar, so nothing else in this tool reports it'
		}
	}

	# Half two, and the ordering pass for both - bin/vault-lint.sh:1556-1567.
	# Walking $files rather than the edge loop above is what makes the output
	# order the vault order instead of a hash order, so two runs over an
	# unchanged vault produce the same worklist.
	#
	# `superseded_by` is the THIRD address of the same fact and joins the set for
	# the reason the other two are here: the worklist must not depend on the
	# supersession being well-formed. A note that records its own replacement and
	# never got its `status` flipped is exactly the half-made pair whose cited
	# sections still assert the old value, and taking only the other two halves
	# would leave those sections unnamed.
	$SUP = New-Object 'System.Collections.Generic.List[string]'
	foreach ($f in $files) {
		$id = Get-SweepValue $f 'id'
		if ($id.Length -eq 0) { continue }
		$status = Get-SweepValue $f 'status'
		$hasEntries = $SUPBY.ContainsKey($f) -and $SUPBY[$f].Count -gt 0
		if (-not $hasEntries -and $status -cne 'superseded' -and (Get-SweepValue $f 'superseded_by').Length -eq 0) { continue }
		[void]$SUP.Add($f)
		if (-not $hasEntries) {
			if (-not $SUPBY.ContainsKey($f)) { $SUPBY[$f] = New-Object 'System.Collections.Generic.List[string[]]' }
			[void]$SUPBY[$f].Add([string[]]@('', ''))
		}
	}

	# The worklist itself - bin/vault-lint.sh:1569-1595. Grouped by target and
	# deduped: two superseded notes citing the same section are one row naming
	# both, and one note naming a section twice is still one re-read of it.
	$NOUSE = New-Object 'System.Collections.Generic.List[string]'
	$SEENT = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$TORDER = New-Object 'System.Collections.Generic.List[string]'
	$TDOC = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$TANC = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$TSHOW = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$SEENR = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$ROW = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' ([System.StringComparer]::Ordinal)

	foreach ($f in $SUP) {
		$usedIn = Get-SweepList $f 'used_in'
		if ($usedIn.Count -eq 0) { [void]$NOUSE.Add($f); continue }
		foreach ($entry in $usedIn) {
			$doc = $entry
			$anc = ''
			$hpos = $entry.IndexOf([char]35)
			if ($hpos -ge 0) {
				$doc = $entry.Substring(0, $hpos)
				$anc = $entry.Substring($hpos + 1)
			}
			$doc = $doc.Trim($script:SPACE_TAB)
			if ($doc.StartsWith('./', [System.StringComparison]::Ordinal)) { $doc = $doc.Substring(2) }
			$doc = $doc.TrimEnd([char]47)

			$key = $doc + $SS + (Get-SweepResolve $doc $anc)
			if (-not $SEENT.Contains($key)) {
				[void]$SEENT.Add($key)
				[void]$TORDER.Add($key)
				$TDOC[$key] = $doc
				$TANC[$key] = $anc
				$show = $doc
				if ($anc.Length -gt 0) { $show = $doc + '#' + $anc }
				$TSHOW[$key] = $show
			}
			$rk = $key + $SS + $f
			if ($SEENR.Contains($rk)) { continue }
			[void]$SEENR.Add($rk)
			if (-not $ROW.ContainsKey($key)) { $ROW[$key] = New-Object 'System.Collections.Generic.List[string]' }
			[void]$ROW[$key].Add($f)
		}
	}

	$nt = $TORDER.Count
	$nsup = $SUP.Count
	$nu = $UNREC.Count
	$nnou = $NOUSE.Count
	$nb = $BROKE.Count

	if ($script:JSON -eq 1) {
		$sb = New-Object System.Text.StringBuilder
		[void]$sb.Append("{`n")
		if ($nu -eq 0 -and $nb -eq 0) { [void]$sb.Append('  "ok": true,' + "`n") } else { [void]$sb.Append('  "ok": false,' + "`n") }
		[void]$sb.Append('  "vault": "' + (ConvertTo-SweepJsonEscaped $script:VAULT) + "`",`n")
		[void]$sb.Append('  "worklist_count": ' + $nt + ",`n")
		[void]$sb.Append('  "superseded_count": ' + $nsup + ",`n")
		[void]$sb.Append('  "unreconciled_count": ' + $nu + ",`n")
		[void]$sb.Append('  "broken_edge_count": ' + $nb + ",`n")
		[void]$sb.Append('  "broken_edges": [')
		for ($i = 0; $i -lt $nb; $i++) {
			$f = $BROKE[$i]
			if ($i -eq 0) { [void]$sb.Append("`n    {") } else { [void]$sb.Append(",`n    {") }
			[void]$sb.Append('"id": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'id')) + '", ')
			[void]$sb.Append('"file": "' + (ConvertTo-SweepJsonEscaped $f) + '", ')
			[void]$sb.Append('"type": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'type')) + '", ')
			[void]$sb.Append('"title": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'title')) + '", ')
			[void]$sb.Append('"check": "superseded-by-' + $SBYST[$f] + '", ')
			[void]$sb.Append('"superseded_by": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'superseded_by')) + '", ')
			[void]$sb.Append('"detail": "' + (ConvertTo-SweepJsonEscaped $BWHY[$f]) + '"}')
		}
		if ($nb -eq 0) { [void]$sb.Append('],' + "`n") } else { [void]$sb.Append("`n  ],`n") }
		[void]$sb.Append('  "unreconciled": [')
		for ($i = 0; $i -lt $nu; $i++) {
			$f = $UNREC[$i]
			if ($i -eq 0) { [void]$sb.Append("`n    {") } else { [void]$sb.Append(",`n    {") }
			[void]$sb.Append('"id": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'id')) + '", ')
			[void]$sb.Append('"file": "' + (ConvertTo-SweepJsonEscaped $f) + '", ')
			[void]$sb.Append('"type": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'type')) + '", ')
			[void]$sb.Append('"title": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'title')) + '", ')
			[void]$sb.Append('"supersedes": "' + (ConvertTo-SweepJsonEscaped $UTGT[$f]) + '", ')
			[void]$sb.Append('"created": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'created')) + '", ')
			[void]$sb.Append('"reconciled": "' + (ConvertTo-SweepJsonEscaped (Get-SweepValue $f 'reconciled')) + '", ')
			[void]$sb.Append('"detail": "' + (ConvertTo-SweepJsonEscaped $UWHY[$f]) + '"}')
		}
		if ($nu -eq 0) { [void]$sb.Append('],' + "`n") } else { [void]$sb.Append("`n  ],`n") }
		[void]$sb.Append('  "worklist": [')
		for ($t = 0; $t -lt $nt; $t++) {
			$key = $TORDER[$t]
			if ($t -eq 0) { [void]$sb.Append("`n    {") } else { [void]$sb.Append(",`n    {") }
			[void]$sb.Append('"target": "' + (ConvertTo-SweepJsonEscaped $TSHOW[$key]) + '", ')
			[void]$sb.Append('"document": "' + (ConvertTo-SweepJsonEscaped $TDOC[$key]) + '", ')
			[void]$sb.Append('"section": "' + (ConvertTo-SweepJsonEscaped $TANC[$key]) + '", ')
			[void]$sb.Append('"notes": [')
			$m = 0
			$rows = $ROW[$key]
			foreach ($rf in $rows) {
				foreach ($entry in $SUPBY[$rf]) {
					$m++
					if ($m -eq 1) { [void]$sb.Append("`n      ") } else { [void]$sb.Append(",`n      ") }
					Add-SweepNoteJson $sb $rf $entry
				}
			}
			if ($m -eq 0) { [void]$sb.Append(']}') } else { [void]$sb.Append("`n    ]}") }
		}
		if ($nt -eq 0) { [void]$sb.Append('],' + "`n") } else { [void]$sb.Append("`n  ],`n") }
		[void]$sb.Append('  "reached_no_document": [')
		$m = 0
		foreach ($f in $NOUSE) {
			foreach ($entry in $SUPBY[$f]) {
				$m++
				if ($m -eq 1) { [void]$sb.Append("`n    ") } else { [void]$sb.Append(",`n    ") }
				Add-SweepNoteJson $sb $f $entry
			}
		}
		if ($m -eq 0) { [void]$sb.Append("]`n}`n") } else { [void]$sb.Append("`n  ]`n}`n") }
		Write-OutText $sb.ToString()
		if ($nu -eq 0 -and $nb -eq 0) { exit 0 } else { exit 1 }
	}

	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append('vault-lint supersession-sweep: ' + $nt + ' section' + (Get-SweepPlural $nt) + ' to re-read, from ' + $nsup + ' superseded note' + (Get-SweepPlural $nsup) + "`n")
	[void]$sb.Append('  vault: ' + $script:VAULT + "`n")
	[void]$sb.Append("`n  sections a supersession put in doubt - the note behind each was replaced and the prose was not`n")
	if ($nt -eq 0) { [void]$sb.Append("    (none)`n") }
	foreach ($key in $TORDER) {
		[void]$sb.Append('    ' + $TSHOW[$key] + "`n")
		foreach ($rf in $ROW[$key]) {
			foreach ($entry in $SUPBY[$rf]) {
				Add-SweepNoteText $sb $rf $entry '      '
			}
		}
	}
	[void]$sb.Append("`n  superseded notes that reached no document - nothing to re-read, which is the good case`n")
	if ($nnou -eq 0) { [void]$sb.Append("    (none)`n") }
	foreach ($f in $NOUSE) {
		foreach ($entry in $SUPBY[$f]) {
			Add-SweepNoteText $sb $f $entry '    '
		}
	}

	# The half-written edges print above the reconciliation verdict and above the
	# schemaVersion gate, because this one is not gated: it fires on the presence
	# of `superseded_by`, so a vault at 1 that writes the field owes the same
	# answer as one at 3.
	[void]$sb.Append("`n  supersessions the record only half made - ``superseded_by`` names a successor that does not name it back`n")
	if ($nb -eq 0) { [void]$sb.Append("    (none)`n") }
	foreach ($f in $BROKE) {
		[void]$sb.Append('    ' + (Get-SweepValue $f 'id') + '  ' + (Get-SweepValue $f 'type') + '  superseded-by-' + $SBYST[$f] + "`n")
		[void]$sb.Append('      ' + (Get-SweepValue $f 'title') + "`n")
		[void]$sb.Append('      superseded_by ' + (Get-SweepValue $f 'superseded_by') + "`n")
		[void]$sb.Append('      ' + $BWHY[$f] + "`n")
	}

	# The verdict prints last, because it is the half a reader acts on and the
	# worklist above it can run to dozens of rows. At schemaVersion 1 the
	# section says the rule does not apply rather than printing an empty list.
	#
	# A BRANCH RATHER THAN AN EARLY RETURN, so both summary lines below print in
	# one place. A vault at 1 can still carry a half-written edge, and a summary
	# skipped by an early return leaves its reader reconstructing the verdict
	# from the exit code.
	if ([int]$script:FOUND_SCHEMA -lt 2) {
		[void]$sb.Append("`n  reconciliation is a schemaVersion 2 rule and this vault is at " + $script:FOUND_SCHEMA + " - the worklist above is a report here, and nothing was asked about whether it was read`n")
	} else {
		[void]$sb.Append("`n  supersessions with nothing recording that the worklist was read`n")
		if ($nu -eq 0) { [void]$sb.Append("    (none)`n") }
		foreach ($f in $UNREC) {
			[void]$sb.Append('    ' + (Get-SweepValue $f 'id') + '  ' + (Get-SweepValue $f 'type') + "`n")
			[void]$sb.Append('      ' + (Get-SweepValue $f 'title') + "`n")
			[void]$sb.Append('      supersedes ' + $UTGT[$f] + "`n")
			[void]$sb.Append('      ' + $UWHY[$f] + "`n")
		}
	}
	if ($nb -gt 0) {
		[void]$sb.Append("`nvault-lint supersession-sweep: " + $nb + ' half-written supersession edge' + (Get-SweepPlural $nb) + ' - the record names a successor and the successor does not name it back, under ' + $script:VAULT + "`n")
	}
	if ($nu -gt 0) {
		[void]$sb.Append("`nvault-lint supersession-sweep: " + $nu + ' supersession' + (Get-SweepPlural $nu) + ' with nothing recording that its sections were read, under ' + $script:VAULT + "`n")
	}
	Write-OutText $sb.ToString()
	if ($nu -eq 0 -and $nb -eq 0) { exit 0 } else { exit 1 }
}

# ----------------------------------------------------------------------------
# 5. --used-in - every used_in target resolves
#
# Ports bin/vault-lint.sh:1709-1942. Renders through Render-Failures with a
# deliberately non-default ok line (bin/vault-lint.sh:1646).
# ----------------------------------------------------------------------------
function Invoke-ModeUsedIn {
	# Non-ASCII punctuation a GitHub-slugged heading commonly carries, by CODE
	# POINT rather than written literally - ports the enumeration at
	# bin/vault-lint.sh:1749. A literal curly quote in this file is
	# indistinguishable from a mistyped ASCII one to every linter and every
	# reader; a .NET string is already Unicode text, so unlike the shell's
	# UTF-8-byte-sequence trick there is no encoding step, only the same list
	# of code points.
	$uniPunctCodePoints = @(8211, 8212, 8213, 8216, 8217, 8218, 8220, 8221, 8222, 8226, 8230, 8224, 8225, 183, 176, 167, 182, 171, 187)
	$uniPunct = New-Object 'System.Collections.Generic.HashSet[char]'
	foreach ($cp in $uniPunctCodePoints) { [void]$uniPunct.Add([char]$cp) }

	# The printable ASCII the slug rule drops, transcribed character for
	# character from DROP at bin/vault-lint.sh:1741. `-` and `_` are not in
	# it, and neither is space/tab - those are turned into a hyphen instead of
	# being dropped, in the loop below.
	$slugDrop = New-Object 'System.Collections.Generic.HashSet[char]'
	foreach ($ch in [char[]]'!"#$%&''()*+,./:;<=>?@[\]^`{|}~') { [void]$slugDrop.Add($ch) }

	# The GitHub slug rule: lowercase, drop punctuation, one hyphen per
	# whitespace CHARACTER (runs are not collapsed). Ports slug() at
	# bin/vault-lint.sh:1799. Case folding is ASCII-only by hand - a
	# [char]::ToLowerInvariant() would fold every Unicode letter, and LC_ALL=C
	# pins the shell's tolower() to bytes 65-90 only.
	function Get-UsedInSlug {
		param([string]$Heading)
		$sb = New-Object System.Text.StringBuilder
		foreach ($ch in $Heading.ToCharArray()) {
			if ($uniPunct.Contains($ch)) { continue }
			if ($ch -eq [char]32 -or $ch -eq [char]9) { [void]$sb.Append('-'); continue }
			if ($slugDrop.Contains($ch)) { continue }
			if ($ch -ge [char]65 -and $ch -le [char]90) { [void]$sb.Append([char]([int]$ch + 32)) }
			else { [void]$sb.Append($ch) }
		}
		return $sb.ToString().Trim('-')
	}

	$rxHeading = [regex]'\A#+[ \t]+'
	$rxAnchorAttr = [regex]'[{]#[A-Za-z0-9_-]+[}]\z'

	# Every heading one document offers an anchor for, ATX form only. Ports
	# scan() at bin/vault-lint.sh:1829 - ONE OF SIX COPIES of the fenced-block
	# scan bin/vault-lint.sh:1369 names; this is the local --used-in copy,
	# kept apart from --red-team's below for the reason THE STUB SEAM states.
	# Setext headings are deliberately not read - they are document titles, not
	# a section a #fragment cites.
	function Get-UsedInHeadings {
		param([string]$Doc)
		$has = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
		$path = $script:VAULT + '/' + $Doc
		if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $has }
		$fc = ''
		$fn = 0
		foreach ($raw in (Read-TextLines $path)) {
			$line = Remove-TrailingCr $raw
			$t = $line.TrimStart($script:SPACE_TAB)

			# Fences tracked by marker character and run length, so a longer
			# nested fence cannot close its parent early.
			# NO COMPARISON IN THE FENCE SCAN IS CULTURE-AWARE, the rule
			# bin/vault-lint.ps1's --binding-driver copy states and three sibling
			# copies of this scan did not apply. `-ceq` on a string and `-eq` on a
			# [char] both take PowerShell's culture path, which folds a combining
			# sequence onto its precomposed form and ignores a zero-width space -
			# and a document read by this mode is founder prose carrying both,
			# while bin/vault-lint.sh compares bytes in awk. `$fc` stays a string
			# because it carries awk's `fc = ""` sentinel; the fence character it
			# holds is compared as a code point.
			if ($t.StartsWith('```', [System.StringComparison]::Ordinal) -or $t.StartsWith('~~~', [System.StringComparison]::Ordinal)) {
				$c = [int]$t[0]
				$n = 0
				while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
				if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
				elseif ([int]$fc[0] -eq $c -and $n -ge $fn) { $fc = ''; $fn = 0 }
				continue
			}
			if ($fc.Length -ne 0) { continue }

			$hm = $rxHeading.Match($t)
			if (-not $hm.Success) { continue }
			$h = $t.Substring($hm.Length)
			$h = $h -creplace '[ \t]*#+[ \t]*\z', ''
			$h = $h.TrimEnd($script:SPACE_TAB)

			# A trailing `{#anchor}` attribute is the heading's own citation
			# address: stripped from the heading text and registered as an
			# anchor in its own right. BOTH the explicit anchor and the slug of
			# the stripped text are registered - the two-address rule - so a
			# vault authored before the template carried attributes keeps
			# citing the slug without starting to fail.
			$am = $rxAnchorAttr.Match($h)
			if ($am.Success) {
				$a = $am.Value
				$a = $a -creplace '\A[{]#', ''
				$a = $a -creplace '[}]\z', ''
				[void]$has.Add($a)
				$h = $h.Substring(0, $am.Index)
				$h = $h.TrimEnd($script:SPACE_TAB)
			}
			[void]$has.Add((Get-UsedInSlug $h))
		}
		return $has
	}

	# The record stream as this mode needs it: the file list in RECORDS order,
	# each file's `id` field, and each file's `used_in` block-list items in
	# order. Ports the $1=="N"/"S"/"L" branches at bin/vault-lint.sh:1774-1776.
	$files = New-Object 'System.Collections.Generic.List[string]'
	$idByFile = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$usedInByFile = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'

	foreach ($rec in $script:RECORDS) {
		$f = $rec.Split([char]9)
		if ($f.Length -lt 2) { continue }
		if ($f[0] -ceq 'N') { [void]$files.Add($f[1]); continue }
		if ($f[0] -ceq 'S') {
			if ($f.Length -ge 4 -and $f[2] -ceq 'id') { $idByFile[$f[1]] = $f[3] }
			continue
		}
		if ($f[0] -ceq 'L') {
			if ($f.Length -ge 4 -and $f[2] -ceq 'used_in') {
				if (-not $usedInByFile.ContainsKey($f[1])) { $usedInByFile[$f[1]] = New-Object 'System.Collections.Generic.List[string]' }
				[void]$usedInByFile[$f[1]].Add($f[3])
			}
			continue
		}
	}

	# THE BOUNDARY IS THE POINT (bin/vault-lint.sh:1712): this asserts a
	# `used_in` target RESOLVES - the document exists and the anchor names a
	# real heading - and never that the section still carries the claim.
	$scannedDocs = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.HashSet[string]]'

	foreach ($f in $files) {
		if (-not $usedInByFile.ContainsKey($f)) { continue }
		$id = ''
		if ($idByFile.ContainsKey($f)) { $id = $idByFile[$f] }

		foreach ($entry in $usedInByFile[$f]) {
			# The split - document, #anchor, and the leading ./ and trailing /
			# stripped off - is duplicated in --supersession-sweep and
			# --binding-driver (bin/vault-lint.sh:1908-1913 says so). Change
			# one, change all three.
			$p = $entry.IndexOf('#')
			if ($p -ge 0) { $doc = $entry.Substring(0, $p); $anchor = $entry.Substring($p + 1) }
			else { $doc = $entry; $anchor = '' }
			$doc = $doc.Trim($script:SPACE_TAB)
			$doc = $doc -creplace '\A\./', ''
			$doc = $doc -creplace '/+\z', ''

			if ($doc.Length -eq 0) {
				[void]$script:FAILURES.Add($f + "`t" + 'used-in-missing-file' + "`t" + $id + "`t" + '`used_in` names `' + $entry + '`, which is an anchor with no document in front of it. A bare fragment resolves against nothing, so the note reads as cited while naming no artifact at all - and when its stale_after fires there is no document to go and re-check')
				continue
			}
			if (-not $script:PATHIDX.Contains($doc)) {
				[void]$script:FAILURES.Add($f + "`t" + 'used-in-missing-file' + "`t" + $id + "`t" + '`used_in` names `' + $entry + '` and nothing exists at ' + $doc + ' under the vault root. Either the document was renamed after the claim was cited into it, or used_in was back-filled onto a note nothing cites - either way the blast radius points at a document no reader can open, so the re-check its stale_after fires has nowhere to go')
				continue
			}
			if ($anchor.Length -eq 0) { continue }
			if (-not $scannedDocs.ContainsKey($doc)) { $scannedDocs[$doc] = Get-UsedInHeadings $doc }
			if (-not $scannedDocs[$doc].Contains($anchor)) {
				[void]$script:FAILURES.Add($f + "`t" + 'used-in-dead-anchor' + "`t" + $id + "`t" + '`used_in` names `' + $entry + '` and no heading in ' + $doc + ' carries `{#' + $anchor + '}` or slugs to `' + $anchor + '`. A heading was renamed or cut while the note went on naming it, so the claim reads as cited into a section nobody can find - and a stale_after that fires sends its reader to a document with no such paragraph in it')
			}
		}
	}

	# One argument, deliberately: --used-in's clean genuinely is what it says
	# (bin/vault-lint.sh:1646), so it keeps Render-Failures' default OkLine
	# rather than supplying its own.
	$status = Render-Failures 'vault-lint used-in'
	exit $status
}

# ----------------------------------------------------------------------------
# 6. --red-team - the panel record against itself
#
# Ports bin/vault-lint.sh:1943-2120. Shares --used-in's failure renderer
# (bin/vault-lint.sh:1962), which is why the two are ported together.
# ----------------------------------------------------------------------------
function Invoke-ModeRedTeam {
	$redTeamPath = $script:VAULT + '/red-team.md'

	# A vault with no red-team.md dispatched no panel - reported by name rather
	# than passing silently, so a mode that printed `clean` over a document it
	# never found does not read as a panel that was checked.
	$okLine = 'every dispatched lens wrote rows - ' + $script:VAULT

	if (Test-Path -LiteralPath $redTeamPath -PathType Leaf) {
		# The key the roster and the objection table are matched on: trimmed,
		# whitespace runs collapsed, ASCII-folded. Ports key() at
		# bin/vault-lint.sh:1980 - a check that fires on capitalisation is one
		# somebody switches off, which takes the half that worked with it.
		function Get-RedTeamKey {
			param([string]$Text)
			$t = $Text.Trim($script:SPACE_TAB)
			$t = $t -creplace '[ \t]+', ' '
			$sb = New-Object System.Text.StringBuilder
			foreach ($ch in $t.ToCharArray()) {
				if ($ch -ge [char]65 -and $ch -le [char]90) { [void]$sb.Append([char]([int]$ch + 32)) }
				else { [void]$sb.Append($ch) }
			}
			return $sb.ToString()
		}

		# The same trim with no folding, for a message that names the lens in
		# the case the document wrote it in. Ports disp() at
		# bin/vault-lint.sh:1987.
		function Get-RedTeamDisplay {
			param([string]$Text)
			return $Text.Trim($script:SPACE_TAB)
		}

		$rxHeading = [regex]'\A#+[ \t]+'
		$rxRosterId = [regex]'\AR?[0-9]+\z'
		$rxObjectionId = [regex]'\AR[0-9]+-O[0-9]+\z'

		# ROSTER and ROWS as one ordered map each, keyed round-then-lens, rather
		# than a HashSet plus a List plus a Dictionary apiece: awk fakes an
		# ordered map with three parallel arrays (ROSTER/RORDER/RSHOW) because
		# it has no such structure, but .NET's OrderedDictionary gives O(1)
		# membership AND insertion order in one object. $roster's value is the
		# lens display text; $rows' value is a two-element array of [display
		# text, the objection ID the row was first seen under].
		$roster = New-Object 'System.Collections.Specialized.OrderedDictionary' -ArgumentList ([System.StringComparer]::Ordinal)
		$rows = New-Object 'System.Collections.Specialized.OrderedDictionary' -ArgumentList ([System.StringComparer]::Ordinal)

		$fc = ''
		$fn = 0
		$inRoster = $false

		foreach ($raw in (Read-TextLines $redTeamPath)) {
			$line = Remove-TrailingCr $raw
			$t = $line.TrimStart($script:SPACE_TAB)

			# ONE OF SIX COPIES of the fenced-block scan (bin/vault-lint.sh:1369
			# names all six) - the local --red-team copy, kept apart from
			# --used-in's above for the reason THE STUB SEAM states. A
			# document that carries its own row template as an example would
			# otherwise register the template as a dispatched lens.
			# NO COMPARISON IN THE FENCE SCAN IS CULTURE-AWARE, the rule
			# bin/vault-lint.ps1's --binding-driver copy states and three sibling
			# copies of this scan did not apply. `-ceq` on a string and `-eq` on a
			# [char] both take PowerShell's culture path, which folds a combining
			# sequence onto its precomposed form and ignores a zero-width space -
			# and a document read by this mode is founder prose carrying both,
			# while bin/vault-lint.sh compares bytes in awk. `$fc` stays a string
			# because it carries awk's `fc = ""` sentinel; the fence character it
			# holds is compared as a code point.
			if ($t.StartsWith('```', [System.StringComparison]::Ordinal) -or $t.StartsWith('~~~', [System.StringComparison]::Ordinal)) {
				$c = [int]$t[0]
				$n = 0
				while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
				if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
				elseif ([int]$fc[0] -eq $c -and $n -ge $fn) { $fc = ''; $fn = 0 }
				continue
			}
			if ($fc.Length -ne 0) { continue }

			$hm = $rxHeading.Match($t)
			if ($hm.Success) {
				$h = $t.Substring($hm.Length)
				$h = $h -creplace '[ \t]*#+[ \t]*\z', ''
				# ORDINAL, never `-ceq`. Get-RedTeamKey lowercases and collapses
				# whitespace runs and drops nothing else, so a zero-width space in
				# this heading survives into the comparison - and culture folding
				# reports the folded heading EQUAL to `lenses dispatched` while awk
				# compares bytes and does not. That is a live divergence on any
				# founder prose carrying one, demonstrated by
				# scripts/fixtures/fence-zwsp.
				$inRoster = [string]::Equals((Get-RedTeamKey $h), 'lenses dispatched', [System.StringComparison]::Ordinal)
				continue
			}

			if (-not $t.StartsWith('|', [System.StringComparison]::Ordinal)) { continue }
			$row = $t.Substring(1)
			$row = $row -creplace '\|[ \t]*\z', ''
			$cell = $row.Split('|')
			if ($cell.Length -lt 2) { continue }
			$c1 = Get-RedTeamDisplay $cell[0]

			# The header row and the |---| rule are skipped by the same test
			# that reads a round, rather than by counting lines - a table
			# written without a header is still a roster.
			if ($inRoster) {
				if (-not $rxRosterId.IsMatch($c1)) { continue }
				$rd = $c1 -creplace '\AR', ''
				$lens = Get-RedTeamKey $cell[1]
				if ($lens.Length -eq 0) { continue }
				$rk = $rd + "`t" + $lens
				if ($roster.Contains($rk)) { continue }
				$roster[$rk] = Get-RedTeamDisplay $cell[1]
				continue
			}

			# An objection row is identified by its ID rather than by the
			# heading it sits under, so a document that splits its rounds
			# across sections is read the same as one with a single table.
			if (-not $rxObjectionId.IsMatch($c1)) { continue }
			$rd = $c1 -creplace '\AR', ''
			$rd = $rd -creplace '-O[0-9]+\z', ''
			$lens = Get-RedTeamKey $cell[1]
			$ok = $rd + "`t" + $lens
			if ($rows.Contains($ok)) { continue }
			$rows[$ok] = @((Get-RedTeamDisplay $cell[1]), $c1)
		}

		# No roster at all. At schemaVersion 2 that is the failure, because the
		# roster is where version 2 put the record. At 1 it is a document that
		# predates the field, and failing it would fail every corpus with a
		# panel in it on the day the skill updated.
		if ($roster.Count -eq 0) {
			if ([int]$script:FOUND_SCHEMA -ge 2) {
				[void]$script:FAILURES.Add('red-team.md' + "`t" + 'red-team-no-roster' + "`t" + '' + "`t" + 'red-team.md carries no `## Lenses dispatched` roster. Nothing else in the corpus records which lenses were sent, so a lens that returned findings and wrote no row is indistinguishable from one that had no objections - and the objection codes the plan cites resolve into a table that never carried them')
			}
		} else {
			# BOTH DIRECTIONS, and the second one is what makes the first hold.
			foreach ($rk in $roster.Keys) {
				if ($rows.Contains($rk)) { continue }
				$parts = $rk.Split([char]9)
				$show = $roster[$rk]
				[void]$script:FAILURES.Add('red-team.md' + "`t" + 'red-team-lens-no-rows' + "`t" + 'R' + $parts[0] + ' ' + $show + "`t" + 'the roster names `' + $show + '` as dispatched in round ' + $parts[0] + ' and no row in red-team.md carries an objection from it. Either the lens returned findings that were folded into the documents and never written down, in which case the plan cites a code the table does not hold, or it genuinely had none - and the whole point of the roster is that those two look identical from outside')
			}

			foreach ($ok in $rows.Keys) {
				if ($roster.Contains($ok)) { continue }
				$parts = $ok.Split([char]9)
				$show = $rows[$ok][0]
				$id = $rows[$ok][1]
				[void]$script:FAILURES.Add('red-team.md' + "`t" + 'red-team-lens-unrostered' + "`t" + $id + "`t" + 'row `' + $id + '` is an objection from `' + $show + '` in round ' + $parts[0] + ', and the roster does not name that lens as dispatched in that round. A roster that omits a lens whose rows are sitting in the table is not the record it claims to be, and the check above it can then be cleared by deleting a line rather than by dispatching a lens')
			}
		}
	} else {
		$okLine = 'no red-team.md under ' + $script:VAULT + ' - no panel was dispatched, so no lens owes rows'
	}

	$status = Render-Failures 'vault-lint red-team' $okLine
	exit $status
}

# ----------------------------------------------------------------------------
# 7. --roadmap-table - the roadmap table against the milestone set
#
# Ports bin/vault-lint.sh:2121-2410. Reads only the FIRST table under the
# roadmap heading, and stays silent at schemaVersion 1.
# ----------------------------------------------------------------------------
function Invoke-ModeRoadmapTable {
	# The table itself is read by the shared Read-FirstItemTable, which
	# --assumption-rows also calls - it was two functions and one of them
	# claimed to be a transcription of the other, so the difference between
	# the two modes is now three arguments rather than a claim. The failure
	# helpers below stay local to this stub: they name this mode's checks.

	function Add-RoadmapFailure {
		param([string]$File, [string]$Check, [string]$Id, [string]$Detail)
		[void]$FAILURES.Add($File + "`t" + $Check + "`t" + $Id + "`t" + $Detail)
	}

	# V[file, key] from awk - '' for a key the note never set, the same way
	# an unset awk array element reads as ''. One lookup per call, not the
	# ContainsKey-then-index pair a caller would otherwise repeat by hand.
	function Get-NoteValue {
		param([string]$File, [string]$Key)
		$value = ''
		[void]$noteValues.TryGetValue($File + "`t" + $Key, [ref]$value)
		return $value
	}

	# GATED ON schemaVersion 2, branched here the way --supersession-sweep,
	# --red-team and the checks pass all branch on it, rather than by the
	# caller deciding whether to run this mode at all. A vault at 1 has no
	# milestones/ directory by construction and cannot owe this rule -
	# saying so, rather than printing agreement, is the same distinction the
	# sweep makes at schemaVersion 1.
	if ([int]$FOUND_SCHEMA -lt 2) {
		$okLine = 'the roadmap table is a schemaVersion 2 rule and this vault is at ' + $FOUND_SCHEMA + ' - a vault at 1 carries no milestone notes, so there is no set for a table to be read against - ' + $VAULT
		exit (Render-Failures 'vault-lint roadmap-table' $okLine)
	}

	# noteValues[file <TAB> key] from the S records; milestones in N-record
	# (sorted-file) order; the set of milestone titles a rendered row may
	# match. Two milestones carrying one title are covered by one row -
	# nothing in the schema makes a title unique, and demanding it would be
	# a rule about note wording rather than about the table.
	$noteValues = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$noteFiles = New-Object 'System.Collections.Generic.List[string]'
	foreach ($rec in $RECORDS) {
		$f = $rec.Split([char]9)
		if ($f[0] -ceq 'N') { [void]$noteFiles.Add($f[1]); continue }
		if ($f[0] -ceq 'S') { $noteValues[$f[1] + "`t" + $f[2]] = $f[3]; continue }
	}

	# Title and id are read once here and carried on the record rather than
	# looked up a second time in the milestone-not-in-roadmap loop below.
	$milestones = New-Object 'System.Collections.Generic.List[psobject]'
	$milestoneTitles = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	foreach ($f in $noteFiles) {
		if ((Get-NoteValue $f 'type') -cne 'milestone') { continue }
		$title = Get-NoteValue $f 'title'
		[void]$milestones.Add([pscustomobject]@{ File = $f; Title = $title; Id = (Get-NoteValue $f 'id') })
		if ($title.Length -ne 0) { [void]$milestoneTitles.Add($title) }
	}
	$nm = $milestones.Count

	$planRows = New-Object 'System.Collections.Generic.List[string]'
	$seenRoadmapHeading = $false
	if ($HAS_PLAN -eq 1) {
		$plan = Read-FirstItemTable -Path $PLAN -Heading 'roadmap' -ItemHeader 'item' -DefaultColumn 1
		$planRows = $plan.Rows
		$seenRoadmapHeading = $plan.SeenHeading
	}
	$nrow = $planRows.Count

	# The roadmap is in the ledger and nowhere a reader can see it. Reported
	# ONCE against the document rather than once per milestone: the fix is
	# one thing - render the section - and a reader handed one row per
	# milestone stops reading.
	if ($nm -gt 0 -and $nrow -eq 0) {
		$plural = 's'
		if ($nm -eq 1) { $plural = '' }
		if ($HAS_PLAN -ne 1) {
			Add-RoadmapFailure 'business-plan.md' 'roadmap-table-missing' '' ('the vault carries ' + $nm + ' milestone note' + $plural + ' and there is no business-plan.md at the vault root. The roadmap is in the ledger and nowhere a reader can see it: every item is a dated change to an assumption row, so a plan that never renders them hands its reader a curve whose steps have no stated cause')
		} elseif (-not $seenRoadmapHeading) {
			Add-RoadmapFailure 'business-plan.md' 'roadmap-table-missing' '' ('the vault carries ' + $nm + ' milestone note' + $plural + ' and no heading in business-plan.md answers to `roadmap`. The items exist in the ledger and the plan has no section that shows them, so the curve has steps the reader cannot see and no place to go and ask what moved them. The plan template heading is `## Milestones & roadmap {#roadmap}`, which is also what every milestone `used_in` names')
		} else {
			Add-RoadmapFailure 'business-plan.md' 'roadmap-table-missing' '' ('the roadmap section of business-plan.md lists no items and the vault carries ' + $nm + ' milestone note' + $plural + '. A roadmap left as prose is one nothing can check - which is what let an item name an assumption that was never written - and the reader gets a section describing a sequence it never lists')
		}
		$okLine = [string]$nm + ' milestone note' + $plural + ' and no roadmap the plan renders - ' + $VAULT
		exit (Render-Failures 'vault-lint roadmap-table' $okLine)
	}

	# BOTH DIRECTIONS, because each is a different failure: a row matching no
	# milestone is an item that escaped the ledger, so it moves no
	# assumption anybody can name; a milestone the table never lists is a
	# dated change to an assumption row the plan does not show, so the curve
	# has a step the reader cannot see.
	$hitTitles = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	foreach ($row in $planRows) {
		if ($milestoneTitles.Contains($row)) { [void]$hitTitles.Add($row); continue }
		Add-RoadmapFailure 'business-plan.md' 'roadmap-row-no-milestone' '' ('row `' + $row + '` in the roadmap section matches no `milestone` note title in this vault, character for character. The table renders `sequence`, `moves` and `resource` off the notes, so a row matching none of them was written by hand: it moves no assumption anybody can name, which roadmap-sequencing.md Rule 1 files as maintenance rather than as a roadmap item, and the model then carries a dated change with nothing behind it. Match the title verbatim, the way `chosen` matches an entry in `options` - or write the milestone note this row is missing')
	}

	foreach ($m in $milestones) {
		if ($hitTitles.Contains($m.Title)) { continue }
		Add-RoadmapFailure $m.File 'milestone-not-in-roadmap' $m.Id ('`title` is `' + $m.Title + '` and no row in the roadmap section of business-plan.md carries it. The item is a dated change to an assumption row that the plan never shows, so the curve has a step the reader cannot see and cannot ask about - and the table stops being a rendering of this set the moment one member is absent from it. Render the row with the title verbatim, or retract the note')
	}

	if ($nm -eq 0 -and $nrow -eq 0) {
		$okLine = 'no milestone notes and no roadmap rows under ' + $VAULT + ' - there is no roadmap on either side, which is every vault before the plan has one'
	} else {
		$rowPlural = 's'
		if ($nrow -eq 1) { $rowPlural = '' }
		$msPlural = 's'
		if ($nm -eq 1) { $msPlural = '' }
		$okLine = [string]$nrow + ' roadmap row' + $rowPlural + ' against ' + [string]$nm + ' milestone note' + $msPlural + ', matched verbatim - ' + $VAULT
	}

	exit (Render-Failures 'vault-lint roadmap-table' $okLine)
}

# ----------------------------------------------------------------------------
# 8. --binding-driver - verdict drivers and the evidence under them
#
# Ports bin/vault-lint.sh:2411-3002. Every rule has a deliberate silent
# counterpart asserted beside it, and none of them is gated on schemaVersion -
# porting a check without its silent side turns a clean vault red.
# ----------------------------------------------------------------------------
function Invoke-ModeBindingDriver {
	# SUBSEP, spelled out. awk joins a multi-subscript index with \034 and every
	# composite key below is a transcription of one of those indices, so the
	# separator is the same byte rather than a character that could turn up in a
	# path, a field name or a fold key.
	$SUB = [string][char]28

	# The record stream, indexed the way the awk program indexes it.
	#
	#   $V   S records - V[file, key] = value
	#   $LI  L records - the block-list items under one key, in file order. The
	#        awk carries LI[k, n] plus a count in LN[k]; a list holds both, and
	#        LN[k] is its Count, so present() below reads the same predicate.
	$V = New-Object 'System.Collections.Generic.Dictionary[string,string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$LI = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' -ArgumentList ([System.StringComparer]::Ordinal)
	$BDFILES = New-Object 'System.Collections.Generic.List[string]'

	# Every document read, once each - SCANNED memoises readdoc.
	$SCANNED = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	# fold key -> heading ordinal, or 0 for a key two headings claim.
	$ALIAS = New-Object 'System.Collections.Generic.Dictionary[string,int]' -ArgumentList ([System.StringComparer]::Ordinal)
	# doc SUBSEP ordinal -> the text of that section.
	$BODY = New-Object 'System.Collections.Generic.Dictionary[string,string]' -ArgumentList ([System.StringComparer]::Ordinal)
	# The corner verdict rows of the one section that has them, as two parallel
	# lists per section - KN[kk] in the awk is their Count.
	$KDRV = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' -ArgumentList ([System.StringComparer]::Ordinal)
	$KKND = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' -ArgumentList ([System.StringComparer]::Ordinal)
	$BYID = New-Object 'System.Collections.Generic.Dictionary[string,string]' -ArgumentList ([System.StringComparer]::Ordinal)

	# The closure state, reset before each walk. closure() only ever ADDS to
	# these three, so the two counts awk keeps beside them are their Counts:
	# SEEN makes every id visited once, so nsrc is SRC.Count, and ncp is
	# incremented under exactly the guard that makes CP a set.
	$SEEN = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$SRC = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$CP = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)

	# The two driver_kind values that make a verdict conditional. The full closed
	# word list, and the rule that rejects a fourth word, belong to the checks
	# pass - this program branches on policy-or-not and needs no more than that.
	#
	# A HashSet with the ordinal comparer rather than a hashtable literal: `@{}`
	# is case-INSENSITIVE in PowerShell, so a `driver_kind` of `Policy` would be
	# conditional here and not in awk, where `in` is an exact key test.
	$COND = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	[void]$COND.Add('policy')
	[void]$COND.Add('policy-within-band')

	# The subject a verdict carries, and the fold key of the plan anchor it
	# renders into. plan-template.md writes those two headings as
	# `## Target & verdict {#target-verdict}` and `## Steady state ...
	# {#steady-state}`. Ordinal for the reason $COND is.
	$ANCHOR = New-Object 'System.Collections.Generic.Dictionary[string,string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$ANCHOR['target-verdict'] = 'targetverdict'
	$ANCHOR['steady-state-ceiling'] = 'steadystate'

	# The one document section whose table rows are read, so every other section
	# is parsed and discarded rather than stored. The corner verdict table is a
	# property of the verdict anchor and the ceiling section carries none, so
	# recording rows anywhere else would be dead data with a sync obligation
	# attached.
	$TABLEDOC = 'business-plan.md'
	$TABLEKEY = 'targetverdict'

	# The five fields, in the order vault.md lists them. The checks pass carries
	# the same set split four-plus-one, because it is the half that reports a
	# missing field and `conditional_on` is owed conditionally; here the whole
	# set is only ever counted, so it stays one list. Change one, change both.
	$VF = @('binding_driver', 'driver_kind', 'conditional_on', 'evidence_n', 'evidence_counterparties')

	# The patterns Read-BdDoc runs inside its per-line loop, held as Regex
	# objects for the reason the shared $RX_* block states: the static
	# [regex]::Match overloads look the pattern up in a process-wide cache of
	# fifteen on every call, and this loop runs several of them per line of
	# every document the mode opens. The patterns that run a handful of times
	# per process - the used_in entry split, the `..` guard, the www. strip -
	# stay inline, where hoisting would buy nothing and only move them away from
	# their one reader. They are declared in this body rather than beside the
	# shared ones for the reason the stub seam states: a pattern two modes want
	# is a pattern two slices are both editing.
	$RX_BD_HEADING = [regex]'\A(#+)[ \t]+'
	$RX_BD_TRAILING_HASH = [regex]'[ \t]*#+[ \t]*\z'
	$RX_BD_ANCHOR_ATTR = [regex]'[{]#[A-Za-z0-9_-]+[}]\z'
	$RX_BD_LEAD_PIPE = [regex]'\A\|'
	$RX_BD_TRAIL_PIPE = [regex]'\|[ \t]*\z'
	$RX_BD_ALIGN_CELL = [regex]'\A[ \t]*:?-+:?[ \t]*\z'

	# Byte equality, never PowerShell's `-ceq`. `-ceq` compares under the
	# invariant CULTURE, which reports "ab" and "a<U+200B>b" equal and a combining
	# sequence equal to its precomposed form - and every verbatim match in this
	# mode runs over founder prose, which is exactly where those turn up. awk
	# compares bytes, so this compares ordinals.
	function Test-BdEqual {
		param([string]$A, [string]$B)
		return [string]::Equals($A, $B, [System.StringComparison]::Ordinal)
	}

	# V[f, k], with awk's answer for a subscript that was never set.
	function Get-BdValue {
		param([string]$File, [string]$Key)
		$kk = $File + $SUB + $Key
		if ($V.ContainsKey($kk)) { return $V[$kk] }
		return ''
	}

	# BODY[doc, ord], same rule.
	function Get-BdBody {
		param([string]$Key)
		if ($BODY.ContainsKey($Key)) { return $BODY[$Key] }
		return ''
	}

	# The same present() the checks pass uses, and copied verbatim rather than
	# written as `V[f, k] != ""` for one reason: both programs implement the same
	# trigger, and a field authored as a one-item block list is present to one
	# test and absent to the other. That divergence fails a note in the checks
	# pass while silently skipping it here, which is a half-checked verdict with
	# nothing saying so. Change one, change both.
	function Test-BdPresent {
		param([string]$File, [string]$Key)
		$kk = $File + $SUB + $Key
		if ($V.ContainsKey($kk) -and $V[$kk].Length -ne 0) { return $true }
		if ($LI.ContainsKey($kk) -and $LI[$kk].Count -gt 0) { return $true }
		return $false
	}

	function Get-BdTrim {
		param([string]$Text)
		return $Text.Trim($script:SPACE_TAB)
	}

	# The third copy of the --supersession-sweep fold, answering the same
	# question --roadmap-table asks it: which heading is THIS section, rather
	# than whether an anchor resolves. Every character the slug rule drops is
	# dropped here too, so any spelling that rule resolves to the verdict heading
	# folds onto it without this program having to know which characters those
	# are. Change one, change all three.
	#
	# Compared as code points rather than with `-ge`/`-le` on [char]: PowerShell
	# routes a char comparison through the same culture-aware path `-ceq` uses,
	# and awk's `c >= "a" && c <= "z"` is a byte range.
	function Get-BdFold {
		param([string]$Text)
		$sb = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$cc = [int]$Text[$i]
			if ($cc -ge 97 -and $cc -le 122) { [void]$sb.Append([char]$cc); continue }
			if ($cc -ge 65 -and $cc -le 90) { [void]$sb.Append([char]($cc + 32)); continue }
			if ($cc -ge 48 -and $cc -le 57) { [void]$sb.Append([char]$cc); continue }
		}
		return $sb.ToString()
	}

	# Register one fold key against one heading ordinal, or RETIRE it when a
	# second heading claims the same key. The second copy of the
	# --supersession-sweep claim(), which states the safety property: two
	# headings differing only in the punctuation the fold drops are
	# indistinguishable here, so an ambiguous key resolves to nothing rather than
	# to a guess. Being wrong costs a section read against the wrong note. Change
	# one, change both.
	function Add-BdClaimKey {
		param([string]$Doc, [string]$Key, [int]$Ord)
		if ($Key.Length -eq 0) { return }
		$ak = $Doc + $SUB + $Key
		if ($ALIAS.ContainsKey($ak)) {
			if ($ALIAS[$ak] -ne $Ord) { $ALIAS[$ak] = 0 }
			return
		}
		$ALIAS[$ak] = $Ord
	}

	# One corner row, appended to both lists in one call. awk encodes the
	# lockstep in the subscript - `KDRV[kk, ++KN[kk]]` and then `KKND[kk,
	# KN[kk]]`, one counter incremented once - and two independently counted
	# lists would hold it only for as long as two call sites stayed adjacent.
	# The read loop bounds itself on the driver list and indexes the kind list
	# at the same offset, where awk answers "" for a subscript past the end and
	# PowerShell throws, so a row that reached one list and not the other is a
	# crash rather than a quiet disagreement.
	function Add-BdKindRow {
		param([string]$Key, [string]$Driver, [string]$Kind)
		if (-not $KDRV.ContainsKey($Key)) {
			$KDRV[$Key] = New-Object 'System.Collections.Generic.List[string]'
			$KKND[$Key] = New-Object 'System.Collections.Generic.List[string]'
		}
		$KDRV[$Key].Add($Driver)
		$KKND[$Key].Add($Kind)
	}

	# KN[kk] - how many corner rows are recorded against one section. Read off
	# the driver list because Add-BdKindRow is the only writer of either.
	function Get-BdKindRowCount {
		param([string]$Key)
		if ($KDRV.ContainsKey($Key)) { return $KDRV[$Key].Count }
		return 0
	}

	# One document at the vault root, read once, into three things: every heading
	# as fold keys pointing at its ordinal, the text of every section, and the
	# corner verdict rows of the one section that has them. Memoised on SCANNED,
	# so a document cited by four notes is opened once.
	#
	# A SECTION ENDS AT THE NEXT HEADING OF THE SAME DEPTH OR SHALLOWER, which is
	# the rule the shared Read-FirstItemTable uses, so a subsection under a
	# heading is still part of it. This used to end a section at the next heading
	# of ANY depth, on the reasoning that nothing in plan-template.md puts a
	# subsection under the verdict anchor - and that comment named the arrival of
	# one as the trigger to adopt the depth rule. THE TRIGGER FIRED. A plan opened
	# a `###` one line into the verdict anchor's body, which put the corner table
	# outside the body this reads: the mode found ZERO rows and printed `1 verdict
	# note against 0 corner verdict rows under the {#target-verdict} anchor,
	# matched verbatim` - a clean pass over a table it never opened, for as long
	# as the note had existed, with the whole corner-row half of the mode silently
	# disabled and the condition check ready to cry wolf over any phrase written
	# below that subsection heading.
	#
	# A LINE THEREFORE REACHES EVERY OPEN ANCESTOR, which is what a nested
	# boundary means: $sect is a stack carrying one entry per section still open,
	# and a heading pops every entry at its own depth or deeper before pushing its
	# own.
	#
	# THE CORNER TABLE IS IDENTIFIED BY ITS HEADER rather than by being the first
	# table in the section, which is tighter than --roadmap-table needs and for a
	# reason: the verdict section legitimately carries other tables - the stated
	# range and the evidenced range as two labelled rows, and the multiple band
	# an exit target carries - so a positional rule would read one of those and
	# report every row of a correct table as a kind with no note behind it. A
	# table is the corner table when its header names both a `Binding driver`
	# column and a `Kind` column, matched by the same fold as everything else
	# here; the FIRST such table in the section is read and any later one is
	# skipped, so a document quoting its own format below the real table cannot
	# double-count.
	#
	# THE ROW PARSER IS THE SECOND COPY of the one in Read-FirstItemTable:
	# strip the outer pipes, split on `|`, spot the all-dashes alignment rule,
	# treat everything above it as header and read the header for which column
	# matters. Both carry the rule that a table with NO alignment rule is not a
	# table to any renderer, so its rows are not rows. Change one, change both.
	#
	# The fence tracking is the FIFTH copy in the shell - --used-in scan(),
	# --supersession-sweep sections(), --red-team and the shared
	# Read-FirstItemTable carry the same six lines, because each reads a document
	# at the vault root. THIS COPY STAYS LOCAL TO THIS BODY: the other three mode
	# bodies keep their own, and hoisting one out is the cross-slice edit the stub
	# seam exists to prevent. The table reader is the exception and states why at
	# its own definition: two copies of it existed and one claimed to be a
	# transcription of the other. A `#` or a `|` inside a fenced block is an example rather than
	# an assertion the document makes, which is also why fenced lines never reach
	# BODY: a fenced template carrying a condition would otherwise satisfy the
	# check for a section that renders nothing. Change one, change all six.
	function Read-BdDoc {
		param([string]$Doc)
		if ($SCANNED.Contains($Doc)) { return }
		[void]$SCANNED.Add($Doc)
		# `while ((getline line < path) > 0)` over a path that cannot be opened
		# returns -1 and runs the body no times. Reading a missing document is
		# reachable: a used_in entry names whatever the note author wrote.
		try { $lines = Read-TextLines ($script:VAULT + '/' + $Doc) } catch { return }

		$fc = ''
		$fn = 0
		$ord = 0
		$hdr = ''
		$intable = 0
		$dcol = 0
		$kcol = 0
		# The open-section stack and the section that owns the corner table.
		# awk's SECT/SLEV are function locals reset per call; these are reset per
		# call by being declared here. $sect holds the FINISHED BODY key, as awk's
		# SECT does, so the per-line loop appends without rebuilding one composite
		# key per open ancestor per line.
		$sect = New-Object 'System.Collections.Generic.List[string]'
		$slev = New-Object 'System.Collections.Generic.List[int]'
		$tpos = 0

		foreach ($raw in $lines) {
			# `sub(/^[ \t]+/, "", t)` through the same named pair every other trim
			# in this file uses, rather than a second spelling of it as a regex.
			$t = (Remove-TrailingCr $raw).TrimStart($script:SPACE_TAB)

			# No comparison in the fence scan is culture-aware. `-ceq` on a
			# string and `-eq` on a [char] both take PowerShell's culture path,
			# which folds a combining sequence onto its precomposed form and
			# ignores a zero-width space - and a document read by this mode is
			# founder prose carrying both. `$fc` stays a string because it
			# carries awk's `fc = ""` sentinel; the fence character it holds is
			# compared as a code point.
			if ($t.Length -ge 3 -and ((Test-BdEqual ($t.Substring(0, 3)) '```') -or (Test-BdEqual ($t.Substring(0, 3)) '~~~'))) {
				$c = [int]$t[0]
				$n = 0
				while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
				if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
				elseif ((Test-BdEqual $fc ([string][char]$c)) -and $n -ge $fn) { $fc = ''; $fn = 0 }
				continue
			}
			if ($fc.Length -ne 0) { continue }

			$hm = $RX_BD_HEADING.Match($t)
			if ($hm.Success) {
				# The heading depth, off the capture group the way
				# Read-FirstItemTable takes it - the run of `#` before the
				# space, which the pattern has already matched. Counted in a
				# second loop instead, the two would be separate mechanisms
				# answering one question, which is the shape that drifts.
				$nh = $hm.Groups[1].Length
				$h = Get-BdTrim ($RX_BD_TRAILING_HASH.Replace($t.Substring($hm.Length), ''))
				$ex = ''
				# Braces written as bracket expressions rather than escaped, for
				# the reason scan() states: a backslash-brace is an interval
				# expression to some awks and a literal to others, and which one
				# runs the shell is a property of the user machine. Transcribed
				# as written so a diff of the two files reads as one pattern.
				$am = $RX_BD_ANCHOR_ATTR.Match($h)
				if ($am.Success) {
					$ex = $am.Value.Substring(2, $am.Value.Length - 3)
					$h = Get-BdTrim $h.Substring(0, $am.Index)
				}
				$ord++
				# Both addresses registered, not one: a vault written before the
				# template carried attributes cites the slug, and an
				# implementation where the attribute REPLACED it would stop
				# resolving those entries the day the author pasted a newer
				# template in.
				$exFold = Get-BdFold $ex
				$hFold = Get-BdFold $h
				if ($ex.Length -ne 0) { Add-BdClaimKey $Doc $exFold $ord }
				Add-BdClaimKey $Doc $hFold $ord

				# Close every section this heading ends, then open this one. A
				# subsection leaves its parent on the stack, which is the whole
				# depth rule.
				#
				# `$tpos` is the STACK POSITION of the section that owns the
				# corner table, not a second copy of its ordinal and depth. The
				# table section lives exactly as long as its own stack entry, so
				# the pop above is already the rule that closes it - carrying its
				# depth separately would be the same boundary written twice, in
				# step only for as long as someone kept it there. A second
				# `{#target-verdict}` anchor is therefore a new section rather
				# than an extension of the first, by construction.
				while ($sect.Count -gt 0 -and $slev[$slev.Count - 1] -ge $nh) {
					$sect.RemoveAt($sect.Count - 1)
					$slev.RemoveAt($slev.Count - 1)
				}
				if ($tpos -gt $sect.Count) { $tpos = 0 }
				$sect.Add($Doc + $SUB + $ord)
				$slev.Add($nh)
				if ((Test-BdEqual $Doc $TABLEDOC) -and ((Test-BdEqual $exFold $TABLEKEY) -or (Test-BdEqual $hFold $TABLEKEY))) {
					$tpos = $sect.Count
				}
				$hdr = ''
				$intable = 0
				continue
			}

			if ($sect.Count -eq 0) { continue }
			# A blank line closes a table to every renderer, so it closes one
			# here - otherwise two tables separated by a paragraph read as one
			# and the rows of the second land under the header of the first.
			if ($t.Length -eq 0) { $hdr = ''; $intable = 0; continue }

			# TryGetValue inline rather than Get-BdBody: this runs once per open
			# ancestor per body line of every document the mode opens, and a
			# PowerShell function call is the expensive part of it. A miss sets
			# the out-param to default(string), which is $null and not '', so the
			# fallback is written out rather than relied on - the same reason
			# Get-ModelNoteValue states for not using TryGetValue bare.
			foreach ($sk in $sect) {
				$cur = $null
				if (-not $BODY.TryGetValue($sk, [ref]$cur)) { $cur = '' }
				$BODY[$sk] = $cur + $t + "`n"
			}
			if ([int]$t[0] -ne 124) { $hdr = ''; $intable = 0; continue }
			if ($tpos -eq 0) { continue }
			# Keyed on the SECTION that owns the table rather than on the heading
			# the row sits under, so a corner table inside a subsection is
			# recorded against the anchor the mode resolves.
			$kk = $sect[$tpos - 1]

			# Both patterns are anchored, so Replace has exactly one match to
			# make and agrees with awk's sub(), which replaces only the first.
			$row = $RX_BD_TRAIL_PIPE.Replace($RX_BD_LEAD_PIPE.Replace($t, ''), '')
			# split() of the empty string is zero fields in awk and one empty
			# field here, and the count is what the `nc < 1` guard reads.
			$cell = $null
			$nc = 0
			if ($row.Length -ne 0) {
				$cell = $row.Split([char]124)
				$nc = $cell.Length
			}
			if ($nc -lt 1) { continue }

			$alldash = $true
			for ($i = 0; $i -lt $nc; $i++) {
				if (-not $RX_BD_ALIGN_CELL.IsMatch($cell[$i])) { $alldash = $false; break }
			}

			if ($alldash) {
				# The row directly above the rule is the header, and it is read
				# for nothing but which two columns matter.
				$dcol = 0
				$kcol = 0
				if ($hdr.Length -ne 0 -and (Get-BdKindRowCount $kk) -eq 0) {
					$hcell = $hdr.Split([char]124)
					for ($i = 0; $i -lt $hcell.Length; $i++) {
						$hf = Get-BdFold $hcell[$i]
						if (Test-BdEqual $hf 'bindingdriver') { $dcol = $i + 1 }
						elseif (Test-BdEqual $hf 'kind') { $kcol = $i + 1 }
					}
				}
				$intable = 1
				continue
			}

			if ($intable -eq 0) { $hdr = $row; continue }
			if ($dcol -eq 0 -or $kcol -eq 0) { continue }
			$dv = ''
			$kv = ''
			if ($dcol -le $nc) { $dv = Get-BdTrim $cell[$dcol - 1] }
			if ($kcol -le $nc) { $kv = Get-BdTrim $cell[$kcol - 1] }
			Add-BdKindRow $kk $dv $kv
		}
	}

	# One of three identical copies - the graph pass and the checks pass carry
	# the other two, neither annotated. Change one, change all three.
	function Get-BdTargetOf {
		param([string]$Item)
		$p = $Item.IndexOf(' :: ', [System.StringComparison]::Ordinal)
		if ($p -ge 0) { return $Item.Substring($p + 4) }
		return $Item
	}

	# The counterparty fallback chain vault.md documents, last rung: the host of
	# the canonical URL. It errs toward collapsing two unrelated deals covered by
	# one publication onto one party, which is why the field is authored rather
	# than inferred - and dropping the chain instead errs the other way, where an
	# unwritten field reads as *no counterparty* and every note counts as its own
	# party, so a corpus written before the field reports perfect diversity.
	function Get-BdHostOf {
		param([string]$Url)
		if ($Url.Length -eq 0) { return '' }
		# awk's index() is 1-based and answers 0 for absent, so its `p > 0` is
		# "found anywhere, first character included". A `-gt 0` on a 0-based
		# IndexOf would silently keep a leading-slash URL whole.
		$p = $Url.IndexOf([char]47)
		if ($p -ge 0) { $Url = $Url.Substring(0, $p) }
		return ($Url -creplace '\Awww\.', '')
	}

	# The transitive closure over rests_on, down to the source notes, collecting
	# distinct sources and distinct counterparties as it goes. The same downward
	# walk `graph` performs in walkout(), narrowed to the one edge that carries
	# provenance: a copy rather than a call because each mode is a separate awk
	# program in the shell, and this file inherits the separation from the stub
	# seam. SEEN is what makes a cycle terminate and what stops a diamond
	# counting one source twice; the caller resets it, along with the two sets,
	# before each walk.
	function Add-BdClosure {
		param([string]$Id)
		if ($Id.Length -eq 0 -or $SEEN.Contains($Id)) { return }
		[void]$SEEN.Add($Id)
		if (-not $BYID.ContainsKey($Id)) { return }
		$f = $BYID[$Id]
		if ($f.Length -eq 0) { return }
		if (Test-BdEqual (Get-BdValue $f 'type') 'source') {
			[void]$SRC.Add($Id)
			# `$party`, not `$cp`: PowerShell variable names are
			# case-INSENSITIVE, so a local `$cp` here IS the `$CP` set this
			# function is filling, and the walk would overwrite its own
			# accumulator with a string on the first source note it reached.
			$party = Get-BdValue $f 'counterparty'
			if ($party.Length -eq 0) { $party = Get-BdValue $f 'publisher' }
			if ($party.Length -eq 0) { $party = Get-BdHostOf (Get-BdValue $f 'url_canonical') }
			if ($party.Length -ne 0) { [void]$CP.Add($party) }
		}
		$k = $f + $SUB + 'rests_on'
		if ($LI.ContainsKey($k)) {
			foreach ($item in $LI[$k]) { Add-BdClosure (Get-BdTargetOf $item) }
		}
	}

	# The ONE rendered form of the two counts, generated off the note so the
	# section can be matched against it verbatim - the same property that makes
	# conditional_on and the roadmap table item cell checks rather than
	# similarity tests. plan-template.md states it as the contract a writer owes:
	# both numerals come straight from the fields, and each noun pluralises on
	# its own numeral.
	#
	# WHY A GENERATED STRING RATHER THAN A SCAN FOR THE TWO NUMBERS. An earlier
	# draft looked for each count as a whole-word token, which an unrelated pair
	# of digits in the same paragraph silences - a check that passes for the
	# wrong reason, which is worse here than one that fails for the wrong reason,
	# because nothing ever surfaces it. There is exactly one string to render and
	# one to look for, so a mismatch means the line was written by hand or was
	# never written.
	function Get-BdEvLine {
		param([string]$N, [string]$C)
		$np = 's'
		if (Test-BdEqual $N '1') { $np = '' }
		$cw = 'ies'
		if (Test-BdEqual $C '1') { $cw = 'y' }
		return 'Evidence: ' + $N + ' source' + $np + ', ' + $C + ' counterpart' + $cw
	}

	# Whether a corner row states a kind at all. plan-template.md writes one of
	# the three words for every corner where a driver binds, and an em dash both
	# for a corner where nothing binds and for one whose verdict is undetermined
	# - so a cell with no alphanumeric byte in it asserts no kind and there is
	# nothing for a note to disagree with. The test is emptiness after the fold
	# rather than membership of the three words, so a cell carrying a fourth word
	# or a typo still fails against the note instead of slipping out of the
	# check.
	function Test-BdStatesKind {
		param([string]$Text)
		return ((Get-BdFold $Text).Length -ne 0)
	}

	function Add-BdReport {
		param([string]$File, [string]$Check, [string]$Id, [string]$Detail)
		[void]$script:FAILURES.Add($File + "`t" + $Check + "`t" + $Id + "`t" + $Detail)
	}

	foreach ($rec in $script:RECORDS) {
		$p = $rec.Split([char]9)
		$tag = Get-RowField $p 0
		if (Test-BdEqual $tag 'N') { [void]$BDFILES.Add((Get-RowField $p 1)); continue }
		if (Test-BdEqual $tag 'S') { $V[(Get-RowField $p 1) + $SUB + (Get-RowField $p 2)] = (Get-RowField $p 3); continue }
		if (Test-BdEqual $tag 'L') {
			$k = (Get-RowField $p 1) + $SUB + (Get-RowField $p 2)
			if (-not $LI.ContainsKey($k)) { $LI[$k] = New-Object 'System.Collections.Generic.List[string]' }
			$LI[$k].Add((Get-RowField $p 3))
		}
	}

	foreach ($f in $BDFILES) {
		$idv = Get-BdValue $f 'id'
		if ($idv.Length -ne 0) { $BYID[$idv] = $f }
	}

	# The verdict section of business-plan.md, resolved once. Its ordinal is what
	# both the corner table and verdict-unfiled hang off, so it is looked up
	# before any note is read.
	$tvord = 0
	if ($script:HAS_PLAN -eq 1) {
		Read-BdDoc $TABLEDOC
		$ak = $TABLEDOC + $SUB + $TABLEKEY
		if ($ALIAS.ContainsKey($ak) -and $ALIAS[$ak] -gt 0) { $tvord = $ALIAS[$ak] }
	}
	$tvkk = $TABLEDOC + $SUB + $tvord
	$nrow = Get-BdKindRowCount $tvkk

	# THE ASYMMETRIC TRIGGER, in one place. A target-verdict note is read
	# whatever it carries; a ceiling note is read only once it carries one of the
	# five, which is the exemption for every ceiling claim written before the
	# fields existed.
	$nvt = 0
	$VN = New-Object 'System.Collections.Generic.List[string]'
	foreach ($f in $BDFILES) {
		$ty = Get-BdValue $f 'type'
		if (-not (Test-BdEqual $ty 'claim') -and -not (Test-BdEqual $ty 'assumption')) { continue }
		$sj = Get-BdValue $f 'subject'
		if (-not $ANCHOR.ContainsKey($sj)) { continue }
		if (Test-BdEqual $sj 'target-verdict') {
			$nvt++
		} else {
			$carried = $false
			foreach ($vfield in $VF) {
				if (Test-BdPresent $f $vfield) { $carried = $true; break }
			}
			if (-not $carried) { continue }
		}
		[void]$VN.Add($f)
	}

	foreach ($f in $VN) {
		$sj = Get-BdValue $f 'subject'
		$id = Get-BdValue $f 'id'
		$bd = Get-BdValue $f 'binding_driver'
		$dk = Get-BdValue $f 'driver_kind'

		# The section this verdict renders into: the anchor its subject renders
		# into, and only where the plan carries no such section, the sections its
		# used_in names.
		$CK = New-Object 'System.Collections.Generic.List[string]'
		if ($script:HAS_PLAN -eq 1) {
			$ak = $TABLEDOC + $SUB + $ANCHOR[$sj]
			if ($ALIAS.ContainsKey($ak) -and $ALIAS[$ak] -gt 0) { [void]$CK.Add($TABLEDOC + $SUB + $ALIAS[$ak]) }
		}
		$k = $f + $SUB + 'used_in'
		if ($LI.ContainsKey($k)) {
			foreach ($entry in $LI[$k]) {
				# THE ANCHOR COMES FIRST AND used_in IS A FALLBACK, NEVER A
				# UNION, and the ordering is load-bearing rather than an early
				# exit worth a line: under a union, a note that also cites `##
				# Why now` clears the condition check whenever its phrase
				# appears in THAT section, so a verdict corner reading *does not
				# clear* passes. The union looked more permissive in the right
				# way and was more permissive in the wrong one. Widening this
				# guard reintroduces that defect in the passing direction, where
				# nothing surfaces it.
				if ($CK.Count -ne 0) { break }
				# The third copy of the --used-in split: document, #anchor, and
				# the leading ./ and trailing / stripped off. Byte-identical to
				# the copies in --used-in and --supersession-sweep on purpose, so
				# a diff of the three proves they agree on what an entry names -
				# the `..` guard below is the one deliberate difference. Change
				# one, change all three.
				$hp = $entry.IndexOf([char]35)
				$doc = $entry
				$anc = ''
				if ($hp -ge 0) {
					$doc = $entry.Substring(0, $hp)
					$anc = $entry.Substring($hp + 1)
				}
				$doc = ((Get-BdTrim $doc) -creplace '\A\./', '') -creplace '/+\z', ''

				if ($doc.Length -eq 0 -or $anc.Length -eq 0) { continue }
				# A path that climbs out of the vault is not opened. --used-in
				# reports it missing rather than reading it, and this mode has no
				# business reading it either.
				if ([regex]::IsMatch($doc, '(\A|/)\.\.(/|\z)')) { continue }
				Read-BdDoc $doc
				$ak = $doc + $SUB + (Get-BdFold $anc)
				if ($ALIAS.ContainsKey($ak) -and $ALIAS[$ak] -gt 0) { [void]$CK.Add($doc + $SUB + $ALIAS[$ak]) }
			}
		}

		# --- the condition a policy-bound verdict owes ----------------------
		# `conditional_on` absent is verdict-fields-incomplete from `check` and
		# is not reported twice here under a name about the plan: with no string
		# there is nothing for a section to be missing.
		$co = Get-BdValue $f 'conditional_on'
		if ($COND.Contains($dk) -and $co.Length -ne 0 -and $CK.Count -gt 0) {
			$found = $false
			# `$cand`, not `$ck`: a loop variable differing from `$CK` only in
			# case is the SAME variable in PowerShell, so the first iteration
			# would replace the candidate list with its own first element.
			foreach ($cand in $CK) {
				if ((Get-BdBody $cand).IndexOf($co, [System.StringComparison]::Ordinal) -ge 0) { $found = $true; break }
			}
			if (-not $found) {
				Add-BdReport $f 'verdict-unconditional' $id ('`driver_kind` is `' + $dk + '` and `conditional_on` is `' + $co + '`, and the section this note renders into does not carry that string. A policy-bound verdict is not that the target is unreachable - it is unreachable in the stated configuration, and the plan has to say so in the words the note stores. `Your target is unreachable` and `your target is unreachable at ' + $co + '` render at the same confidence letter and only the second one is true, so the founder is stopped over a decision they could revisit this week. The match is verbatim because the section renders off this field; render the phrase, or correct the field to the words the section uses')
			}
		}

		# --- the kind, both directions, in one row scan ---------------------
		# The forward failure is a Kind cell that disagrees with the note its
		# Binding driver cell names. The reverse is a verdict in the ledger that
		# no row names at all, and it is what keeps the forward one honest: with
		# only the forward direction the cheapest way past both is to edit the
		# driver cell until it matches no note.
		#
		# The reverse asks whether a row NAMES the driver and not whether that
		# row states a kind, and the difference is a deliberate trade.
		# plan-template.md writes an em dash in the Kind cell of an undetermined
		# corner whose driver IS named, so a rule that demanded a kind there
		# would report the shipped template. What that leaves open is blanking
		# the Kind cell of a corner that does bind, which the forward half then
		# skips; the template names that as a contract violation, and a check
		# that fires on the worked example is one somebody switches off, which
		# costs both halves.
		#
		# A cell naming no note is NOT a failure either way: a corner that clears
		# legitimately writes an em dash or a parenthetical in that column, and
		# reporting those would be the crying wolf this whole file refuses.
		if ((Test-BdEqual $sj 'target-verdict') -and $nrow -gt 0 -and $bd.Length -ne 0 -and $dk.Length -ne 0) {
			$tvDrv = $KDRV[$tvkk]
			$tvKnd = $KKND[$tvkk]
			$hit = $false
			for ($r = 0; $r -lt $nrow; $r++) {
				$rowDrv = $tvDrv[$r]
				$rowKnd = $tvKnd[$r]
				if (-not (Test-BdEqual $rowDrv $bd)) { continue }
				$hit = $true
				if (-not (Test-BdStatesKind $rowKnd)) { continue }
				if (Test-BdEqual $rowKnd $dk) { continue }
				Add-BdReport $TABLEDOC 'verdict-kind-mismatch' $id ('the corner verdict row for driver `' + $bd + '` carries `Kind` cell `' + $rowKnd + '` and ' + $id + ' carries `driver_kind: ' + $dk + '`. The column renders off the field, so the two cannot drift unless the cell was edited by hand - and the direction that matters is a cell reading `structural` over a note reading `policy`, which reports a decision the founder made as a category floor at the same confidence letter as an observation somebody read off a page. Match the field verbatim, or correct the field')
			}
			if (-not $hit) {
				Add-BdReport $f 'verdict-kind-mismatch' $id ('`binding_driver` is `' + $bd + '` and no row of the corner verdict table under `{#target-verdict}` names that driver. The table renders its `Binding driver` and `Kind` columns off this note, so a verdict in the ledger that the table never lists is a corner the reader cannot see - and it is the direction that makes the cell check worth having, because a cell edited until it matches nothing would otherwise clear both. Render the row with the driver verbatim, or correct the field to the driver the table names')
			}
		}

		# --- the evidence under the binding driver --------------------------
		# A SINGLE COUNTERPARTY IS REPORTABLE AT ANY n. Three deals from one
		# counterparty is the terms of one relationship reported as the terms of
		# a market, and a source count of three reads as the opposite - which is
		# the half no other field in the corpus can recover.
		#
		# SURFACING IT IS A CONJUNCTION: the note carries the counts AND the
		# section renders them. vault.md once read as a disjunction - the note OR
		# the section - and that can never be both-false, because `check` owes
		# both fields on every note this mode reads, so it reduced to a rule
		# about the ledger alone. The failure being closed is not that the ledger
		# is wrong. It is that the corpus knew the tail was two deals from one
		# party and the number a founder acts on never said so where anybody read
		# it: rendered without the line, that verdict is typographically
		# identical to one resting on twenty deals across twelve parties, and
		# `confidence` cannot separate them - it is a letter about the weakest
		# link and says nothing about how many links there are.
		#
		# THE LINE IS OWED ONLY WHERE THE TAIL IS ACTUALLY THIN, so a
		# well-evidenced verdict owes nothing and this never becomes a line on
		# every plan that everyone learns to skip. That is what keeps it on the
		# one case that cannot be stated honestly without it.
		#
		# The two halves report under one code and in order, because a wrong pair
		# cannot render a right line: correct the field first, then the section.
		# The stored-pair half fires on absent counts as well as wrong ones,
		# which is deliberately not the `conditional_on` treatment above - there,
		# with no string stored, the question this mode asks has no answer, while
		# here the closure answers it either way and the number is the product.
		# The rendered half is gated on the note reaching a section at all,
		# exactly as the condition check is: a verdict written before the plan
		# has a section for it has nothing rendered to be missing the line.
		$SEEN.Clear()
		$SRC.Clear()
		$CP.Clear()
		Add-BdClosure $id
		$nsrc = $SRC.Count
		$ncp = $CP.Count

		if ($nsrc -lt 3 -or $ncp -lt 2) {
			$en = Get-BdValue $f 'evidence_n'
			$ec = Get-BdValue $f 'evidence_counterparties'
			$sp = 's'
			if ($nsrc -eq 1) { $sp = '' }
			$cpw = 'ies'
			if ($ncp -eq 1) { $cpw = 'y' }
			$tail = [string]$nsrc + ' distinct source note' + $sp + ' and ' + [string]$ncp + ' distinct counterpart' + $cpw
			if (-not (Test-BdEqual $en ([string]$nsrc)) -or -not (Test-BdEqual $ec ([string]$ncp))) {
				$states = ''
				if (Test-BdPresent $f 'evidence_n') {
					$states = ' - it states `evidence_n: "' + $en + '"` and `evidence_counterparties: "' + $ec + '"`, which is not what the closure holds'
				}
				Add-BdReport $f 'verdict-thin-evidence' $id ('the closure under this note reaches ' + $tail + ', and the note does not say so' + $states + '. A verdict resting on two deals renders identically to one resting on twenty, because `confidence` is a letter about the weakest link and says nothing about how many links there are - and three deals from one counterparty is the terms of one relationship reported as the terms of a market. State the counts, or widen the evidence under the driver')
			} elseif ($CK.Count -gt 0) {
				$ev = Get-BdEvLine $en $ec
				$found = $false
				foreach ($cand in $CK) {
					if ((Get-BdBody $cand).IndexOf($ev, [System.StringComparison]::Ordinal) -ge 0) { $found = $true; break }
				}
				if (-not $found) {
					Add-BdReport $f 'verdict-thin-evidence' $id ('the closure under this note reaches ' + $tail + ' and the note states both counts, and the section it renders into does not carry `' + $ev + '`. Counts that are right in the ledger are not what this rule is for: the section can render *the target lands about a third of the way* with nothing saying the finding rests on ' + $tail + ', which is typographically identical to a verdict resting on twenty deals across twelve parties - and `confidence` cannot separate the two, because it is a letter about the weakest link and says nothing about how many links there are. The line is generated off `evidence_n` and `evidence_counterparties` and matched verbatim, so render it exactly as printed here; plan-template.md carries the form, and the em dash a well-evidenced corner uses instead')
				}
			}
		}
	}

	# --- a verdict that reached the plan and never the ledger ---------------
	# --roadmap-table inverted: that mode fails milestone notes with no
	# business-plan.md to render them, and this fails a rendered section with
	# nothing behind it. WHAT TRIGGERS IT IS THE PRESENCE OF A NON-EMPTY SECTION
	# and never a reading of the prose inside it, for the same reason
	# conditional_on is matched verbatim: a check that infers a verdict from
	# sentence shape cries wolf, and one that cries wolf gets switched off.
	#
	# THERE IS DELIBERATELY NO {#steady-state} EQUIVALENT. A ceiling section in
	# an existing plan legitimately has no field-carrying note behind it - the
	# same asymmetry the trigger above carries, one document over - so a mirror
	# rule here would fail every plan written before this release.
	#
	# `$nvt` is the count of target-verdict notes taken in the classification
	# loop, because that subject is admitted to VN unconditionally: a second pass
	# over every note would be the same question asked a third time.
	if ($tvord -gt 0 -and (Get-BdBody $tvkk).Length -ne 0 -and $nvt -eq 0) {
		Add-BdReport $TABLEDOC 'verdict-unfiled' '' 'business-plan.md carries a non-empty section at the `{#target-verdict}` anchor and no `claim` or `assumption` under `subject: target-verdict` stands behind it. Everything else this mode checks presumes a note exists, and a verdict written straight into the plan has none of the properties the ledger gives a number: no `rests_on`, so no confidence derivation and no cap; no `stale_after`, so nothing ever comes up for re-checking; no supersession when the target is renegotiated, so the superseded finding is simply overwritten; and `--supersession-sweep` cannot name this section when something under it moves. It is the one output of this skill most likely to make a founder stop, held to less than a sourced market-size figure'
	}

	# The success line is captured off stdout the way --roadmap-table one is,
	# because what `clean` means here depends on what there was to compare: a
	# line saying the verdict agrees with the plan, printed over a vault that
	# carries no verdict, reads as a verdict that was checked. The shell captures
	# it in a command substitution, which strips the trailing newline the printf
	# writes, so it is built here without one.
	$np = 's'
	if ($VN.Count -eq 1) { $np = '' }
	if ($VN.Count -eq 0 -and $tvord -eq 0) {
		if ($script:HAS_PLAN -eq 1) {
			$bdOk = 'no verdict note and no section at the {#target-verdict} anchor of business-plan.md - there is no verdict on either side, which is every vault before a target has one - ' + $script:VAULT
		} else {
			$bdOk = 'no verdict note and no business-plan.md at the vault root - there is no verdict on either side, which is every vault before a target has one - ' + $script:VAULT
		}
	} elseif ($nrow -eq 0) {
		# NO CORNER ROWS IS NOT AGREEMENT, and the old line said it was: it read
		# `matched verbatim` over a row count of zero, which is what a
		# section-boundary bug looked like from the outside for as long as it
		# shipped. The kind check is the half that reads those rows, in both
		# directions, so with none of them read there is nothing for the ledger to
		# have agreed with and the line says so.
		#
		# Which document is named is branched on HAS_PLAN the way the
		# no-verdict-either-side line above branches on it: naming an anchor
		# inside a file that is not there sends its reader to look for a table in
		# a document they do not have, which is the same reporting-past-what-was-
		# opened this whole line exists to stop.
		$where = 'no business-plan.md at the vault root'
		if ($script:HAS_PLAN -eq 1) { $where = 'no corner verdict table under the {#target-verdict} anchor of business-plan.md' }
		$bdOk = [string]$VN.Count + ' verdict note' + $np + ' and ' + $where + ' - ' + $script:VAULT + '. Not checked: the Kind cell against `driver_kind`, in either direction, because there is no corner verdict table to read it from.'
	} else {
		$rp = 's'
		if ($nrow -eq 1) { $rp = '' }
		$bdOk = [string]$VN.Count + ' verdict note' + $np + ' against ' + [string]$nrow + ' corner verdict row' + $rp + ' under the {#target-verdict} anchor, matched verbatim - ' + $script:VAULT
	}

	exit (Render-Failures 'vault-lint binding-driver' $bdOk)
}

# ----------------------------------------------------------------------------
# 9. --monitoring - an axis owes an instrument, a cadence and a decision
#
# Ports bin/vault-lint.sh:3122-3322. Reads competitor-analysis.md at the vault
# root, so it is a mode for --red-team's reason rather than a check: a document
# outside the seven note directories is a different surface.
# ----------------------------------------------------------------------------
function Invoke-ModeMonitoring {
	$competitorsPath = $script:VAULT + '/competitor-analysis.md'

	$okLine = 'every monitoring axis names an instrument, a cadence and the decision it would change - ' + $script:VAULT

	# A vault with no competitor-analysis.md at its root owes nothing, which is
	# every vault before the competitor dimension runs. The line names the
	# document it could not open and says the axis half did not run, rather than
	# stating what it INFERRED from the absence. The old line said `no competitor
	# set was profiled, so no axis owes an instrument` - a conclusion drawn from a
	# missing file - and printed it over a vault holding 31 competitor profiles
	# and a written monitoring plan, because the document lived somewhere other
	# than the vault root. Absence of the file is not absence of the work, and the
	# only thing this mode can honestly report is what it did not read.
	if (-not (Test-Path -LiteralPath $competitorsPath -PathType Leaf)) {
		exit (Render-Failures 'vault-lint monitoring' ('no competitor-analysis.md at the vault root - ' + $script:VAULT + '. Not read: the monitoring axes, so nothing here was held to an instrument, a cadence and the decision it would change - a competitor set profiled under some other path reads exactly like one that was never profiled.'))
	}
	if ([int]$script:FOUND_SCHEMA -lt 2) {
		exit (Render-Failures 'vault-lint monitoring' ('competitor-analysis.md at schemaVersion ' + $script:FOUND_SCHEMA + ' - the monitoring axes are a schemaVersion 2 rule and a vault at 1 is held to the rules it was written under'))
	}

	$RX_MON_ALNUM = [regex]'[A-Za-z0-9]'
	$RX_MON_HEADING = [regex]'\A#+[ \t]+'
	$RX_MON_TRAILING_HASH = [regex]'[ \t]*#+[ \t]*\z'
	$RX_MON_TRAIL_PIPE = [regex]'\|[ \t]*\z'
	$RX_MON_ALIGN_CELL = [regex]'\A[ \t]*:?-+:?[ \t]*\z'

	# Byte equality, never PowerShell's `-ceq`, for the reason
	# bin/vault-lint.ps1's --binding-driver body states where it does the same:
	# `-ceq` compares under the invariant CULTURE, which reports `a` and
	# `a<U+200B>b` equal and a combining sequence equal to its precomposed form -
	# and every comparison in this body runs over founder prose, which is exactly
	# where those turn up. A zero-width space in `## Monitoring plan` would have
	# this mode read a section the shell does not, over the same document. awk
	# compares bytes, so this compares ordinals. Declared in this body rather
	# than beside the shared helpers for the reason the stub seam states: a
	# helper two modes want is a helper two slices are both editing.
	function Test-MonEqual {
		param([string]$A, [string]$B)
		return [string]::Equals($A, $B, [System.StringComparison]::Ordinal)
	}

	# key() at bin/vault-lint.sh: trimmed, whitespace runs collapsed, lowercased.
	function Get-MonKey {
		param([string]$Text)
		$t = $Text.Trim($script:SPACE_TAB)
		$t = $t -creplace '[ \t]+', ' '
		return $t.ToLowerInvariant()
	}

	# disp() - the same trim without the folding, for a message that names the
	# axis in the case the document wrote it in.
	function Get-MonDisplay {
		param([string]$Text)
		return $Text.Trim($script:SPACE_TAB)
	}

	# answered() - a cell answers its column when it carries a letter or a digit.
	# Deliberately not a placeholder word list; see the shell's comment.
	function Test-MonAnswered {
		param([string]$Text)
		return $RX_MON_ALNUM.IsMatch($Text)
	}

	# An ordered map keyed on the folded axis name, for the reason --red-team's
	# roster is one: awk fakes an ordered map with parallel arrays because it has
	# no such structure, and OrderedDictionary gives membership and insertion
	# order in one object. Ordinal, so a zero-width space is a different key on
	# both sides of the port.
	$axes = New-Object 'System.Collections.Specialized.OrderedDictionary' -ArgumentList ([System.StringComparer]::Ordinal)

	$fc = ''
	$fn = 0
	$inSection = $false
	$seen = $false
	$haveHeader = $false
	$icol = 2
	$ccol = 3
	$dcol = 4

	foreach ($raw in (Read-TextLines $competitorsPath)) {
		$line = Remove-TrailingCr $raw
		$t = $line.TrimStart($script:SPACE_TAB)

		# ONE OF SIX COPIES of the fenced-block scan (bin/vault-lint.sh:1369
		# names them all) - the local --monitoring copy, kept apart from its five
		# siblings for the reason THE STUB SEAM states. Every comparison here is
		# ordinal: `$fc` stays a string because it carries awk's `fc = ""`
		# sentinel, and the fence character inside it is compared as a code point.
		if ($t.StartsWith('```', [System.StringComparison]::Ordinal) -or $t.StartsWith('~~~', [System.StringComparison]::Ordinal)) {
			$c = [int]$t[0]
			$n = 0
			while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
			if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
			elseif ([int]$fc[0] -eq $c -and $n -ge $fn) { $fc = ''; $fn = 0 }
			continue
		}
		if ($fc.Length -ne 0) { continue }

		# A heading ends the section as reliably as it starts it, so the rows read
		# are the ones under this heading and no others - a `| ... |` row in
		# Threat ranking is not an axis.
		$hm = $RX_MON_HEADING.Match($t)
		if ($hm.Success) {
			$h = $RX_MON_TRAILING_HASH.Replace($t.Substring($hm.Length), '')
			$inSection = (Test-MonEqual (Get-MonKey $h) 'monitoring plan')
			if ($inSection) { $seen = $true }
			continue
		}
		if (-not $inSection) { continue }

		if (-not $t.StartsWith('|', [System.StringComparison]::Ordinal)) { continue }
		$row = $RX_MON_TRAIL_PIPE.Replace($t.Substring(1), '')
		$cell = $row.Split('|')
		if ($cell.Length -lt 2) { continue }

		# The |---| rule is skipped by testing every cell rather than by counting
		# lines, so a table written with a colon-carrying alignment row is read
		# the same as one without.
		$allRule = $true
		foreach ($cc in $cell) {
			if (-not $RX_MON_ALIGN_CELL.IsMatch($cc)) { $allRule = $false; break }
		}
		if ($allRule) { continue }

		# The FIRST row of the section is the header, and the columns are located
		# by the names it carries rather than by position - the rule
		# --roadmap-table applies to its `Item` cell. Each defaults to its
		# template position, so a table with no recognisable header is still read
		# rather than silently skipped.
		if (-not $haveHeader) {
			$haveHeader = $true
			for ($i = 0; $i -lt $cell.Length; $i++) {
				$hk = Get-MonKey $cell[$i]
				if (Test-MonEqual $hk 'instrument') { $icol = $i + 1 }
				elseif (Test-MonEqual $hk 'cadence') { $ccol = $i + 1 }
				elseif ($hk.StartsWith('decision', [System.StringComparison]::Ordinal)) { $dcol = $i + 1 }
			}
			continue
		}

		$ax = Get-MonDisplay $cell[0]
		if (-not (Test-MonAnswered $ax)) { continue }
		$axk = Get-MonKey $ax
		if ($axes.Contains($axk)) { continue }
		$inst = ''
		$cad = ''
		$dec = ''
		if ($icol -le $cell.Length) { $inst = Get-MonDisplay $cell[$icol - 1] }
		if ($ccol -le $cell.Length) { $cad = Get-MonDisplay $cell[$ccol - 1] }
		if ($dcol -le $cell.Length) { $dec = Get-MonDisplay $cell[$dcol - 1] }
		$axes[$axk] = @($ax, $inst, $cad, $dec)
	}

	# One check for the absent section and the empty one, because they take the
	# same fix - write the axes - and the detail says which of the two it found.
	if ($axes.Count -eq 0) {
		if ($seen) {
			[void]$script:FAILURES.Add("competitor-analysis.md`tmonitoring-plan-no-axes`t`tcompetitor-analysis.md carries a ``## Monitoring plan`` section with no axis in it. The section it replaces asked which pages to re-check and how often, which is freshness - and freshness is the question the per-profile research date and every claim note``s ``stale_after`` already ask. Neither of them asks which way a competitor is moving, and a direction is the only thing that separates a closing window from an open one: a profile researched the day before it was used missed a strategic reversal six weeks earlier, because a snapshot cannot see one. Name the axes, an instrument per axis, a cadence, and the decision each would change")
		} else {
			[void]$script:FAILURES.Add("competitor-analysis.md`tmonitoring-plan-no-axes`t`tcompetitor-analysis.md carries no ``## Monitoring plan`` section at all, so nothing in the corpus says which way any competitor is moving. Every profile in this document is a snapshot dated on the day it was taken, and a snapshot cannot see a direction - a competitor profiled the day before it was used missed a strategic reversal six weeks earlier, which was the single fact that most changed what that competitor meant. Add the section: named axes, an instrument per axis, a cadence, and the decision each would change")
		}
		exit (Render-Failures 'vault-lint monitoring' $okLine)
	}

	foreach ($axk in @($axes.Keys)) {
		$rec = $axes[$axk]
		# A colon-list rather than a conjunction, because the same sentence has
		# to read correctly at one missing column and at three, and a joiner that
		# changes with the count is one more thing the two implementations can
		# disagree about.
		$miss = ''
		if (-not (Test-MonAnswered $rec[1])) { $miss = $miss + ', instrument' }
		if (-not (Test-MonAnswered $rec[2])) { $miss = $miss + ', cadence' }
		if (-not (Test-MonAnswered $rec[3])) { $miss = $miss + ', the decision it would change' }
		if ($miss.Length -eq 0) { continue }
		$miss = $miss.Substring(2)
		[void]$script:FAILURES.Add("competitor-analysis.md`tmonitoring-axis-incomplete`t" + $rec[0] + "`tthe ``" + $rec[0] + "`` axis leaves empty: " + $miss + ". An axis with no instrument is a thing somebody intends to notice, which is not a mechanism; one with no cadence is a re-check with no date, which is the same as no re-check; and one with no decision behind it is a signal nobody acts on, which costs the same to collect as one that matters. A cell carrying no letter or digit - an em dash, a run of hyphens - reads as empty here rather than as an answer, because that is the cheapest way past this rule")
	}

	exit (Render-Failures 'vault-lint monitoring' $okLine)
}

# ----------------------------------------------------------------------------
# 10. --deliverable - the artifact stops inheriting the ledger's archaeology
#
# Ports bin/vault-lint.sh:3323-3445. Reads the RENDERED deliverables/*.html and
# never the markdown; the header comment on the shell side carries the reasoning
# for that and for why the dangling-antecedent half is a read-back item rather
# than a check.
#
# There is no fenced-block scan in this body, and that is the shell's design
# rather than an omission: a deliverable is prose for an outside reader and does
# not document its own format.
# ----------------------------------------------------------------------------
function Invoke-ModeDeliverable {
	$dir = $script:VAULT + '/deliverables'
	$rendered = New-Object 'System.Collections.Generic.List[string]'
	if (Test-Path -LiteralPath $dir -PathType Container) {
		# THE WALK STARTS AT THE PREFIX, not at $dir, for the reason the note-file
		# walk in the shared region states at length: two resolutions of one
		# directory need not spell it the same way, and a Substring against the
		# wrong spelling cuts into the file name rather than off it. -Force
		# because `find` lists dot-prefixed files and PowerShell marks them
		# hidden; -cnotlike because `find -name '*.html'` matches case-sensitively
		# even on a case-insensitive filesystem.
		$prefix = Get-PathPrefix $dir
		if ($prefix.Length -ne 0) {
			foreach ($entry in (Get-ChildItem -LiteralPath $prefix -Recurse -File -Force -ErrorAction SilentlyContinue)) {
				if ($entry.Name -cnotlike '*.html') { continue }
				[void]$rendered.Add('deliverables/' + (Get-RelativeSlashPath $entry.FullName $prefix))
			}
		}
	}
	# `LC_ALL=C sort` over the paths find hands back, so the two implementations
	# read the same files in the same order. Ordinal, never Sort-Object's
	# culture-aware default - the reason Render-Failures gives for its own sort.
	$paths = $rendered.ToArray()
	[System.Array]::Sort($paths, [System.StringComparer]::Ordinal)

	if ($paths.Length -eq 0) {
		exit (Render-Failures 'vault-lint deliverable' ('no deliverables/*.html under ' + $script:VAULT + ' - nothing has been rendered yet, so no artifact carries anything out'))
	}

	# EIGHT character classes rather than a `{8}` quantifier, transcribed from the
	# shell as written: the length is what keeps this off `FACT-CHECKED` and
	# `CLAIM-HANDLING`, and a pattern written differently on the two sides is a
	# pattern that can be changed on one.
	$AN = '[A-Za-z0-9]'
	$RX_DEL_ID = [regex]('(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)-' + $AN + $AN + $AN + $AN + $AN + $AN + $AN + $AN)
	$RX_DEL_OBJ = [regex]'R[0-9]+-O[0-9]+'
	$RX_DEL_TAG = [regex]'<(del|s|strike)([ \t>/]|$)'
	$RX_DEL_TILDES = [regex]'~~[^~]+~~'
	$RX_DEL_ALNUM = [regex]'\A[A-Za-z0-9]\z'

	# scan() at bin/vault-lint.sh: every match of one pattern on one line, with
	# the alphanumeric-boundary test the pattern itself cannot carry - awk has no
	# \b, and writing the boundary into the ERE consumes it, so a second address
	# immediately after the first would be skipped. Written as an explicit walk
	# rather than as a lookaround, so the two implementations apply the same rule
	# in the same place: a lookaround here and a manual test there is the shape a
	# divergence hides in. A rejected match is stepped over rather than ending the
	# scan, which is what makes `XCLAIM-AS23SD44 CLAIM-BB77KK12` report the second
	# address and not the first.
	function Add-DeliverableAddresses {
		param(
			[string]$Rel,
			[string]$Line,
			[int]$LineNo,
			[System.Collections.Generic.HashSet[string]]$Seen,
			[regex]$Pattern,
			[string]$Check,
			[string]$What
		)
		$at = 0
		while ($at -le $Line.Length) {
			$m = $Pattern.Match($Line, $at)
			if (-not $m.Success) { break }
			$tok = $m.Value
			$before = ''
			if ($m.Index -gt 0) { $before = $Line.Substring($m.Index - 1, 1) }
			$after = ''
			if ($m.Index + $m.Length -lt $Line.Length) { $after = $Line.Substring($m.Index + $m.Length, 1) }
			if (-not $RX_DEL_ALNUM.IsMatch($before) -and -not $RX_DEL_ALNUM.IsMatch($after) -and
				$Seen.Add($Check + "`t" + $tok + "`t" + $LineNo)) {
				# The token goes in the DETAIL as well as the id column, because
				# human output prints the check and the detail and nothing else -
				# a message naming no address sends the reader to a page to find
				# it by eye.
				[void]$script:FAILURES.Add($Rel + "`t" + $Check + "`t" + $tok + "`tline " + $LineNo + " carries ``" + $tok + "``, " + $What)
			}
			$at = $m.Index + $m.Length
		}
	}

	$idWhat ='which is a note ID. An ID is an ADDRESS into the vault: it resolves for anyone holding the corpus and resolves to nothing for the audience this document is for, who has no ledger to look it up in. vault.md says as much outright - a rendered document shows the title, and nobody ever sees a note ID in a sentence. Name the claim, or drop the citation; the traceability lives in the vault, which is the half that does not ship'
	$objWhat = 'which is a red-team objection code. That code addresses a row in red-team.md, which this reader does not have, so it reads as a reference to an argument they were not in. If the objection changed the plan, the plan states what it now claims; if it did not, it does not belong here at all'

	foreach ($rel in $paths) {
		# One row per address per line, so two copies of one address on one line
		# are one row. Per FILE, because the shell runs one awk per deliverable
		# and its SEEN table dies with the process.
		$seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
		$ln = 0
		foreach ($raw in (Read-TextLines ($script:VAULT + '/' + $rel))) {
			$line = Remove-TrailingCr $raw
			$ln++

			# Lowercased for the tag test only. The two addresses below are
			# matched on the original line because a note ID and an objection
			# code are upper case by construction, which is most of what keeps
			# this off ordinary prose.
			if ($RX_DEL_TAG.IsMatch($line.ToLowerInvariant()) -and $seen.Add("tag`t" + $ln)) {
				[void]$script:FAILURES.Add($rel + "`tdeliverable-strikethrough`tline " + $ln + "`tline " + $ln + " renders a strikethrough element. Invariant 14 is why the markdown carries one - a retraction that is silently deleted comes back two drafts later with its cause of death erased - and this is that rule inverted in the artifact: the reader of this file was never in the room, so a struck-through line with its reason beside it is a document arguing with its own previous draft. The correction reaches here RESTATED FORWARD, as what is true now. Deleting the ``~~`` is not the fix - it leaves the sentence after it with no antecedent, which is why this is a step in the render loop rather than a filter")
			}

			if ($RX_DEL_TILDES.IsMatch($line) -and $seen.Add("tildes`t" + $ln)) {
				[void]$script:FAILURES.Add($rel + "`tdeliverable-strikethrough`tline " + $ln + "`tline " + $ln + " carries a literal ``~~...~~`` span, so a markdown strikethrough reached the render and came out as text - this reader sees the tildes. Either way it is the ledger``s correction narrative in the artifact: restate the claim forward as what is true now, and leave the retraction visible in the vault, where invariant 14 wants it")
			}

			Add-DeliverableAddresses $rel $line $ln $seen $RX_DEL_ID 'deliverable-note-id' $idWhat
			Add-DeliverableAddresses $rel $line $ln $seen $RX_DEL_OBJ 'deliverable-objection-code' $objWhat
		}
	}

	exit (Render-Failures 'vault-lint deliverable' ('every rendered deliverable carries what is true now and no vault address - ' + $script:VAULT))
}

# ----------------------------------------------------------------------------
# 11. --assumption-rows - the model's inputs against the notes that declare them
#
# Ports the --assumption-rows body of bin/vault-lint.sh. It is --roadmap-table
# one artifact over, so it reads its table with the same shared
# Read-FirstItemTable that mode calls, on three arguments: the heading folds to
# `assumptions` rather than `roadmap`, the item column's header cell to
# `assumption` rather than `item`, and the item column defaults to TWO rather
# than one, because the template ships `| # | Assumption | ... |` and column one
# is the `A-n` row label the plan cites in prose. Every failure string is
# transcribed character for character from the awk program.
#
# THE FAILURE HELPERS BELOW ARE LOCAL TO THIS BODY, the same rule
# Invoke-ModeRoadmapTable states - they name this mode's checks. The table reader
# is the one thing that is not: two copies of it existed under that rule, the
# second declaring itself a transcription of the first, and nothing in this file
# could hold the claim. One reader with parameters is a guarantee; two functions a
# comment says match are a hazard.
# ----------------------------------------------------------------------------
function Invoke-ModeAssumptionRows {
	$SUB = [string][char]28

	# Byte equality, never PowerShell's `-ceq`. `-ceq` compares under the
	# invariant CULTURE, which reports "ab" and "a<U+200B>b" equal and a combining
	# sequence equal to its precomposed form - and every verbatim match in this
	# mode runs over founder prose, which is exactly where those turn up. awk
	# compares bytes, so this compares ordinals. A local copy rather than a call
	# into --binding-driver's Test-ModelEqual, per the stub seam: a helper two modes
	# want is a helper two slices are both editing.
	function Test-ModelEqual {
		param([string]$A, [string]$B)
		return [string]::Equals($A, $B, [System.StringComparison]::Ordinal)
	}

	# awk's target_of(): a block-list item may carry a `:: label` after the ID it
	# names, and every edge walk in the shell strips it.
	function Get-ModelTargetOf {
		param([string]$Item)
		$p = $Item.IndexOf(' :: ', [System.StringComparison]::Ordinal)
		if ($p -ge 0) { return $Item.Substring($p + 4) }
		return $Item
	}

	function Add-ModelFailure {
		param([string]$File, [string]$Check, [string]$Id, [string]$Detail)
		[void]$FAILURES.Add($File + "`t" + $Check + "`t" + $Id + "`t" + $Detail)
	}

	# V[file, key] from awk - '' for a key the note never set. ContainsKey rather
	# than TryGetValue with an out-param: a Dictionary[string,string] miss sets the
	# out to default(string), which is $null and not '', and every `.Length` on the
	# result downstream then throws instead of reading as absent.
	function Get-ModelNoteValue {
		param([string]$File, [string]$Key)
		$k = $File + "`t" + $Key
		if ($noteValues.ContainsKey($k)) { return $noteValues[$k] }
		return ''
	}

	# GATED ON schemaVersion 3, branched here the way every other version gate in
	# this file is rather than by the caller deciding whether to run the mode at
	# all. A vault at 1 or 2 carries none of the three fields this reads, and
	# saying the rule was not applied rather than printing agreement is the
	# distinction --roadmap-table makes at 1.
	if ([int]$FOUND_SCHEMA -lt 3) {
		$okLine = 'the model table is a schemaVersion 3 rule and this vault is at ' + $FOUND_SCHEMA + ' - `model_input`, `excluded_from_model` and `arr_excludes` were added at 3, so a vault before it carries none of them and there is nothing to read a table against - ' + $VAULT
		exit (Render-Failures 'vault-lint assumption-rows' $okLine)
	}

	# noteValues[file <TAB> key] from the S records, the block lists from the L
	# records, and notes in N-record (sorted-file) order.
	$noteValues = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$noteFiles = New-Object 'System.Collections.Generic.List[string]'
	$li = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	foreach ($rec in $RECORDS) {
		$f = $rec.Split([char]9)
		if ($f[0] -ceq 'N') { [void]$noteFiles.Add($f[1]); continue }
		if ($f[0] -ceq 'S') { $noteValues[$f[1] + "`t" + $f[2]] = $f[3]; continue }
		if ($f[0] -ceq 'L') {
			$k = $f[1] + $SUB + $f[2]
			$items = $null
			if (-not $li.TryGetValue($k, [ref]$items)) {
				$items = New-Object 'System.Collections.Generic.List[string]'
				$li[$k] = $items
			}
			[void]$items.Add($f[3])
			continue
		}
	}

	# Three sets over the notes, in one walk. TITLE is every title a row may
	# match - not only the declared inputs - because a row whose note exists
	# and agrees is not a failure whatever else that note declares.
	#
	# WHICH NOTES BACK A ROW IS DECIDED BY `status`, NOT BY WHICH ASSERTING
	# SET HOLDS THE NOTE. A row is backed when a LIVE `assumption` OR a live
	# `claim` carries its title, so both types feed $titles and $dead. THAT
	# PAIR IS THE WHOLE SET and the other five types are out by argument
	# rather than by omission - a `source` and a `fact` are provenance a
	# claim rests ON rather than a value the projection carries, and a
	# `milestone`, `question` or `decision` asserts no value at all.
	# Widening past the pair changes what a model row may stand on; it is
	# not the next step of this fix. Reading `assumption` alone made this fire
	# on a row the method's own promotion rule produces: a structural driver
	# with no subject instrument belongs in the indexed set, so filing a
	# sourced figure as an unevidenced assumption is the defect, and correcting it
	# retires the assumption and mints a `claim` carrying the same title. The
	# row was then backed by a `current` claim whose `used_in` named the
	# assumptions section directly, every word of the failure was true, and
	# the conclusion did not follow.
	#
	# $inputs STAYS ASSUMPTION-ONLY, and that is the row->note direction only.
	# `model_input` is a field a promoted claim does not carry, so widening
	# the title index leaves assumption-not-in-model reading exactly the set
	# it read before.
	#
	# A SUPERSEDED OR RETRACTED NOTE IS NOT A MATCH, and $dead holds it
	# separately rather than beside the live titles. The title key alone says the
	# row was rendered off SOME note; only the status says the ledger still
	# stands behind it, and a row whose only match has been retired is a live
	# input resting on a value nobody is obliged to maintain. Observed: a live
	# row in the assumptions table was backed only by a superseded note, and this
	# mode read `matched verbatim` over it for days. A title carried by both a
	# live note and a retired one still matches live, because the row loop reads
	# $titles first - which is also what clears the promoted row above.
	$titles = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$dead = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$deadStatus = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
	$inputs = New-Object 'System.Collections.Generic.List[psobject]'
	$declared = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$moved = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	foreach ($f in $noteFiles) {
		$ty = Get-ModelNoteValue $f 'type'
		$title = Get-ModelNoteValue $f 'title'
		$isAssumption = Test-ModelEqual $ty 'assumption'
		if ($isAssumption -or (Test-ModelEqual $ty 'claim')) {
			if ($title.Length -ne 0) {
				$st = Get-ModelNoteValue $f 'status'
				if (-not (Test-ModelEqual $st 'superseded') -and -not (Test-ModelEqual $st 'retracted')) {
					[void]$titles.Add($title)
				} elseif (-not $dead.ContainsKey($title)) {
					$dead[$title] = Get-ModelNoteValue $f 'id'
					$deadStatus[$title] = $st
				}
			}
		}
		if ($isAssumption) {
			# Read once and carried on the record: the guard and the field are the
			# same lookup, and asking twice is the loop-invariant recompute this
			# walk exists to do once.
			$declaredKind = Get-ModelNoteValue $f 'model_input'
			if ($declaredKind.Length -ne 0) {
				[void]$inputs.Add([pscustomobject]@{
					File     = $f
					Title    = $title
					Id       = (Get-ModelNoteValue $f 'id')
					Kind     = $declaredKind
					Excluded = (Get-ModelNoteValue $f 'excluded_from_model')
				})
			}
		}

		# What the identity declares it leaves out, collected only from a verdict
		# note. `arr_excludes` anywhere else is not a statement about the ARR
		# term, and accepting it there would let the declaration sit on a note no
		# reader of the verdict ever opens.
		$subject = Get-ModelNoteValue $f 'subject'
		if ((Test-ModelEqual $subject 'target-verdict') -or (Test-ModelEqual $subject 'steady-state-ceiling')) {
			$k = $f + $SUB + 'arr_excludes'
			if ($li.ContainsKey($k)) {
				foreach ($item in $li[$k]) { $declared[(Get-ModelTargetOf $item)] = (Get-ModelNoteValue $f 'id') }
			}
		}

		# What the roadmap ships a change to. `moves` names the note an item
		# moves, which roadmap-sequencing.md already requires - this is the
		# reverse direction of that edge and reads nothing new to get it.
		if (Test-ModelEqual $ty 'milestone') {
			$k = $f + $SUB + 'moves'
			if ($li.ContainsKey($k)) {
				foreach ($item in $li[$k]) { $moved[(Get-ModelTargetOf $item)] = (Get-ModelNoteValue $f 'id') }
			}
		}
	}
	$nmi = $inputs.Count

	$modelRows = New-Object 'System.Collections.Generic.List[string]'
	$seenAssumptionsHeading = $false
	if ($HAS_FINMODEL -eq 1) {
		$read = Read-FirstItemTable -Path $FINMODEL -Heading 'assumptions' -ItemHeader 'assumption' -DefaultColumn 2
		$modelRows = $read.Rows
		$seenAssumptionsHeading = $read.SeenHeading
	}
	$nrow = $modelRows.Count

	# The inputs are in the ledger and nowhere a reader can see them. Reported
	# ONCE against the document rather than once per note: the fix is one thing -
	# render the table - and a reader handed one row per input stops reading.
	if ($nmi -gt 0 -and $nrow -eq 0) {
		$plural = 's'
		if ($nmi -eq 1) { $plural = '' }
		if ($HAS_FINMODEL -ne 1) {
			Add-ModelFailure 'financial-model.md' 'model-table-missing' '' ('the vault carries ' + $nmi + ' assumption note' + $plural + ' declaring `model_input` and there is no financial-model.md at the vault root. Every one of them is an input the projection is supposed to be built from, so a model that never renders them is a projection whose numbers are buried in formulas - which is the failure the assumptions table exists to prevent, from the other side')
		} elseif (-not $seenAssumptionsHeading) {
			Add-ModelFailure 'financial-model.md' 'model-table-missing' '' ('the vault carries ' + $nmi + ' assumption note' + $plural + ' declaring `model_input` and no heading in financial-model.md answers to `assumptions`. The inputs exist in the ledger and the model has no section that lists them, so a reader cannot tell which numbers the projection stands on. The plan template heading is `## Assumptions (every input lives here - nothing buried in a formula) {#assumptions}`')
		} else {
			Add-ModelFailure 'financial-model.md' 'model-table-missing' '' ('the assumptions section of financial-model.md lists no rows and the vault carries ' + $nmi + ' assumption note' + $plural + ' declaring `model_input`. A table with a heading and no rows reads as a model whose inputs are stated somewhere, and they are stated in the ledger only - so the projection has no visible input list at all')
		}
		$okLine = [string]$nmi + ' declared model input' + $plural + ' and no assumptions table the model renders - ' + $VAULT
		exit (Render-Failures 'vault-lint assumption-rows' $okLine)
	}

	# BOTH DIRECTIONS, because each is a different failure - and the reverse one
	# is what stops the forward rule being cleared by writing a row nothing in
	# the ledger stands behind.
	$hitTitles = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	foreach ($row in $modelRows) {
		if ($titles.Contains($row)) { [void]$hitTitles.Add($row); continue }
		# A RETIRED MATCH IS ONE SITUATION AND GETS ONE FAILURE. $hitTitles is
		# set here too, so the note-side rule below stays exactly as it was: the
		# row IS rendered, and reporting the same pair again as an input the
		# table has no row for would send its reader to a second, wrong repair.
		if ($dead.ContainsKey($row)) {
			[void]$hitTitles.Add($row)
			Add-ModelFailure 'financial-model.md' 'model-row-dead-assumption' $dead[$row] ('row `' + $row + '` in the assumptions section matches ' + $dead[$row] + ' and that note is `status: ' + $deadStatus[$row] + '`, with no live `assumption` or `claim` note carrying the title. The row is live in the model and everything standing behind it has been retired from the ledger, so the projection rests on a value nobody is obliged to maintain, nothing orders it in the validation queue, and the title matched - which is exactly why every check stayed green. Observed: a live assumption row backed only by a superseded note read as `matched verbatim` for days. Point the row at the note that replaced this one - a title promoted to a `claim` backs the row exactly as an assumption does, because the distinction is `status` and not `type` - or re-file this note as `current` if it was retired in error')
			continue
		}
		Add-ModelFailure 'financial-model.md' 'model-row-no-assumption' '' ('row `' + $row + '` in the assumptions section matches no `assumption` or `claim` note title in this vault, character for character. The table renders each input off its note, so a row matching none of them was written by hand: the number in it has no `value`, no `sensitivity` and no `validated_by`, so nothing orders it in the validation queue and nothing will ever revisit it. Match the title verbatim, the way a roadmap row matches a milestone title - or write the assumption note this row is missing')
	}

	# Either escape clears it, and that is the design. A row means the input
	# entered the projection; a stated exclusion means somebody decided it should
	# not and said why. What fails is neither.
	foreach ($mi in $inputs) {
		if ($hitTitles.Contains($mi.Title)) { continue }
		if ($mi.Excluded.Length -ne 0) { continue }
		Add-ModelFailure $mi.File 'assumption-not-in-model' $mi.Id ('`model_input` is `' + $mi.Kind + '` and `title` is `' + $mi.Title + '`, and no row in the assumptions section of financial-model.md carries it. The note declares itself an input to the projection and the projection has no row for it, so the value cannot enter the model at all - and the line it governs then reads as revenue the model deliberately left out rather than as an input somebody forgot to add. Every verdict downstream inherits a denominator missing it. Render the row with the title verbatim, or state `excluded_from_model` with the reason the model does not carry it')
	}

	# THE ARR TERM DECLARES ITS COMPOSITION. An exclusion is legitimate; an
	# undeclared one is the defect. The trigger is the conjunction - excluded AND
	# on the roadmap - because an excluded input nothing ships a change to is a
	# line outside the horizon of the plan itself, and failing that would be a
	# rule about scope rather than about the identity.
	foreach ($mi in $inputs) {
		if ($mi.Excluded.Length -eq 0) { continue }
		if (-not $moved.ContainsKey($mi.Id)) { continue }
		if ($declared.ContainsKey($mi.Id)) { continue }
		Add-ModelFailure $mi.File 'excluded-line-on-roadmap' $mi.Id ('`excluded_from_model` is `' + $mi.Excluded + '` and ' + $moved[$mi.Id] + ' on the roadmap moves this note, and no verdict note names it in `arr_excludes`. The roadmap ships a change to a line the model does not carry, so the ARR term every corner of the target is solved against is a subset figure and nothing says which subset. A model may exclude a revenue line - a metered layer must not be allowed to flatter subscription churn - but the exclusion is a term of the identity and belongs where the identity is stated: name this note in `arr_excludes` on the verdict note, or give the model a row for it')
	}

	$rowPlural = 's'
	if ($nrow -eq 1) { $rowPlural = '' }
	if ($nmi -eq 0 -and $nrow -eq 0) {
		$okLine = 'no declared model inputs and no assumption rows under ' + $VAULT + ' - there is no model on either side, which is every vault before the plan has one'
	} elseif ($nmi -eq 0) {
		# NO DECLARED INPUT IS NOT AGREEMENT. This mode is two checks, and the
		# count it printed was the row half's alone: with no note carrying
		# `model_input`, `assumption-not-in-model` iterates over nothing, so the
		# direction this whole mode was written for - an input the ledger holds
		# and the table never renders - reported a matched count over a set it
		# never had. A reader has to be able to tell that half agreeing from that
		# half not running.
		$okLine = [string]$nrow + ' assumption row' + $rowPlural + ' against no declared model inputs - ' + $VAULT + '. Not checked: whether a declared input reached the table, because no `assumption` note carries `model_input`.'
	} else {
		# TWO COUNTS, NOT TWO SIDES OF ONE. `against` read as a comparison
		# between two sets that have to agree, and they do not: a row backed by
		# a `claim` is not a declared model input, and a declared input cleared
		# by `excluded_from_model` is not a row. Both halves ran and both
		# agreed - which is what this says now, one half at a time, rather than
		# implying an equality whose absence would then read as a miscount.
		$miPlural = 's'
		if ($nmi -eq 1) { $miPlural = '' }
		$okLine = [string]$nrow + ' assumption row' + $rowPlural + ' each backed by a live `assumption` or `claim` note, and ' + [string]$nmi + ' declared model input' + $miPlural + ' each rendered as a row or excluded with a reason, matched verbatim - ' + $VAULT
	}

	exit (Render-Failures 'vault-lint assumption-rows' $okLine)
}

# ----------------------------------------------------------------------------
# 12. --claim-drift - a cited section against the hash the note recorded
#
# Ports the --claim-drift body of bin/vault-lint.sh. The section boundary rule,
# the normaliser and the polynomial are transcribed from the awk program, and all
# three have to agree BYTE FOR BYTE with it or every hash in the corpus differs
# between the two implementations and the parity gate reports a diff on every
# fixture at once.
#
# THE HASH IS OVER UTF-8 BYTES because the shell hashes bytes: awk under LC_ALL=C
# reads the file as bytes, so the string this file decoded has to be encoded back
# before it is fed a byte at a time. A section carrying a sequence that is not
# valid UTF-8 is the one case the two cannot agree on - the decode substitutes
# U+FFFD and the re-encode cannot recover the original bytes - which is the same
# limit every comparison against document text in this file already carries.
#
# THE HELPERS BELOW ARE LOCAL TO THIS BODY, per the stub seam.
# ----------------------------------------------------------------------------
function Invoke-ModeClaimDrift {
	$SUB = [string][char]28

	# Byte equality, never `-ceq`, for the reason Test-ModelEqual states one mode
	# over: `-ceq` takes the culture path, which folds a combining sequence onto
	# its precomposed form and ignores a zero-width space, and every string this
	# mode compares came out of founder prose. A local copy, per the stub seam.
	function Test-DriftEqual {
		param([string]$A, [string]$B)
		return [string]::Equals($A, $B, [System.StringComparison]::Ordinal)
	}

	# The fold every section-resolving mode in this file carries. Code points
	# rather than [char] comparison, for the reason ConvertTo-TableFold states.
	function ConvertTo-DriftFold {
		param([string]$Text)
		$sb = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$cc = [int]$Text[$i]
			if ($cc -ge 97 -and $cc -le 122) { [void]$sb.Append([char]$cc); continue }
			if ($cc -ge 65 -and $cc -le 90) { [void]$sb.Append([char]($cc + 32)); continue }
			if ($cc -ge 48 -and $cc -le 57) { [void]$sb.Append([char]$cc); continue }
		}
		return $sb.ToString()
	}

	# awk's trim().
	function Get-DriftTrim {
		param([string]$Text)
		return $Text.Trim($SPACE_TAB)
	}

	# The polynomial. 131 is an odd multiplier above the byte range, 2147483647 is
	# 2^31-1, and the length is mixed in last so two sections differing only in
	# trailing content the normaliser dropped still separate. [int64] throughout:
	# `h * 131` reaches 2^38, which overflows the [int] PowerShell would otherwise
	# pick and would then differ from awk's exact double arithmetic - silently, and
	# on every section long enough to matter.
	function Get-DriftHash {
		param([string]$Text)
		[int64]$h = 0
		$bytes = $script:UTF8_NO_BOM.GetBytes($Text)
		foreach ($b in $bytes) { $h = ($h * 131 + [int64]$b) % 2147483647 }
		$h = ($h * 131 + [int64]$bytes.Length) % 2147483647
		return ('{0:x8}' -f $h)
	}

	# Register one fold key against one heading ordinal, or RETIRE it when a
	# second heading claims the same key. Another copy of the
	# --supersession-sweep claim(): two headings differing only in the punctuation
	# the fold drops are indistinguishable here, so an ambiguous key resolves to
	# nothing rather than to a guess.
	function Add-DriftClaimKey {
		param([string]$Doc, [string]$Key, [int]$Ord)
		if ($Key.Length -eq 0) { return }
		$ak = $Doc + $SUB + $Key
		if ($alias.ContainsKey($ak)) {
			if ($alias[$ak] -ne $Ord) { $alias[$ak] = 0 }
			return
		}
		$alias[$ak] = $Ord
	}

	# One document at the vault root, read once, into two things: every heading as
	# fold keys pointing at its ordinal, and the NORMALISED body of every section
	# beside it.
	#
	# A SECTION ENDS AT THE NEXT HEADING OF ANY DEPTH, and the heading line itself
	# is outside the body it opens - a reworded heading is a dead anchor and
	# --used-in verdict, so hashing it in would report one failure as two.
	#
	# Fenced lines are CONTENT and only heading detection is suspended inside
	# them. NORMALISATION IS THREE RULES: trailing whitespace off every line, and
	# leading, trailing and repeated blank lines collapsed. All three are invisible
	# in a rendered document, so a hash sensitive to them would re-open every claim
	# in the corpus the first time an editor trimmed a file.
	function Read-DriftSections {
		param([string]$Doc)
		if ($scanned.Contains($Doc)) { return }
		[void]$scanned.Add($Doc)
		# `while ((getline line < path) > 0)` over a path that cannot be opened
		# returns -1 and runs the body no times.
		try { $lines = Read-TextLines ($script:VAULT + '/' + $Doc) } catch { return }

		$fc = ''
		$fn = 0
		$ord = 0
		$cur = 0

		foreach ($rawLine in $lines) {
			$line = Remove-TrailingCr $rawLine
			$t = $line.TrimStart($SPACE_TAB)

			if ($t.Length -ge 3 -and ((Test-DriftEqual ($t.Substring(0, 3)) '```') -or (Test-DriftEqual ($t.Substring(0, 3)) '~~~'))) {
				$c = [int]$t[0]
				$n = 0
				while ($n -lt $t.Length -and [int]$t[$n] -eq $c) { $n++ }
				if ($fc.Length -eq 0) { $fc = [string][char]$c; $fn = $n }
				elseif ((Test-DriftEqual $fc ([string][char]$c)) -and $n -ge $fn) { $fc = ''; $fn = 0 }
			} elseif ($fc.Length -eq 0) {
				$headingMatch = [regex]::Match($t, '\A#+[ \t]+')
				if ($headingMatch.Success) {
					$h = $t.Substring($headingMatch.Length)
					$h = $h -creplace '[ \t]*#+[ \t]*\z', ''
					$h = Get-DriftTrim $h
					$explicitAnchor = ''
					$anchorMatch = [regex]::Match($h, '[{]#[A-Za-z0-9_-]+[}]\z')
					if ($anchorMatch.Success) {
						$explicitAnchor = $anchorMatch.Value -creplace '\A[{]#', ''
						$explicitAnchor = $explicitAnchor -creplace '[}]\z', ''
						$h = Get-DriftTrim $h.Substring(0, $anchorMatch.Index)
					}
					$ord++
					# BOTH addresses registered, the same as --used-in scan(): a
					# vault written before the template carried attributes cites
					# the slug, and an implementation where the attribute replaced
					# it would stop resolving those entries the day somebody
					# pasted a newer template in.
					$exFold = ConvertTo-DriftFold $explicitAnchor
					if ($exFold.Length -ne 0) { Add-DriftClaimKey $Doc $exFold $ord }
					Add-DriftClaimKey $Doc (ConvertTo-DriftFold $h) $ord
					# THE HEADING LINE IS OUTSIDE THE BODY IT OPENS, so the read
					# moves on rather than accumulating it. A fence delimiter
					# below does NOT continue - it toggles the fence and is still
					# content.
					$cur = $ord
					continue
				}
			}
			if ($cur -eq 0) { continue }

			$line = $line -creplace '[ \t]+\z', ''
			$k = $Doc + $SUB + $cur
			$have = ''
			if ($raw.ContainsKey($k)) { $have = $raw[$k] }
			if ($line.Length -eq 0) {
				if ($have.Length -eq 0) { $pendnl[$k] = 0 } else { $pendnl[$k] = 1 }
				continue
			}
			$pend = 0
			if ($pendnl.ContainsKey($k)) { $pend = $pendnl[$k] }
			if ($pend -ne 0) { $have = $have + "`n"; $pendnl[$k] = 0 }
			if ($have.Length -eq 0) { $raw[$k] = $line } else { $raw[$k] = $have + "`n" + $line }
		}
	}

	# The document and #anchor of one entry, normalised the way --used-in,
	# --supersession-sweep and --binding-driver all normalise it - the leading ./
	# and any trailing / stripped - so all four modes group on the same target.
	function Get-DriftDoc {
		param([string]$Entry)
		$p = $Entry.IndexOf([char]35)
		$d = $Entry
		if ($p -ge 0) { $d = $Entry.Substring(0, $p) }
		$d = Get-DriftTrim $d
		$d = $d -creplace '\A\./', ''
		$d = $d -creplace '/+\z', ''
		return $d
	}

	function Get-DriftAnchor {
		param([string]$Entry)
		$p = $Entry.IndexOf([char]35)
		if ($p -ge 0) { return $Entry.Substring($p + 1) }
		return ''
	}

	function Add-DriftFailure {
		param([string]$File, [string]$Check, [string]$Id, [string]$Detail)
		[void]$FAILURES.Add($File + "`t" + $Check + "`t" + $Id + "`t" + $Detail)
	}

	# V[file, key], with awk's answer for a subscript that was never set.
	# ContainsKey rather than TryGetValue, for the reason Get-ModelNoteValue
	# states: a dictionary miss sets an out-param to $null rather than to ''.
	function Get-DriftNoteValue {
		param([string]$File, [string]$Key)
		$k = $File + "`t" + $Key
		if ($noteValues.ContainsKey($k)) { return $noteValues[$k] }
		return ''
	}

	# GATED ON schemaVersion 3. Every claim in every finished corpus is already
	# cited into a plan, so a rule demanding a recorded hash from each of them
	# would turn every existing vault red on the day the plugin updates - which is
	# how a gate stops being run.
	if ([int]$FOUND_SCHEMA -lt 3) {
		$okLine = 'cited-section drift is a schemaVersion 3 rule and this vault is at ' + $FOUND_SCHEMA + ' - `reconciled_sections` was added at 3, so no note here records what it read and there is nothing to compare a section against - ' + $VAULT
		exit (Render-Failures 'vault-lint claim-drift' $okLine)
	}

	$noteValues = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$noteFiles = New-Object 'System.Collections.Generic.List[string]'
	$li = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	foreach ($rec in $RECORDS) {
		$f = $rec.Split([char]9)
		if ($f[0] -ceq 'N') { [void]$noteFiles.Add($f[1]); continue }
		if ($f[0] -ceq 'S') { $noteValues[$f[1] + "`t" + $f[2]] = $f[3]; continue }
		if ($f[0] -ceq 'L') {
			$k = $f[1] + $SUB + $f[2]
			$items = $null
			if (-not $li.TryGetValue($k, [ref]$items)) {
				$items = New-Object 'System.Collections.Generic.List[string]'
				$li[$k] = $items
			}
			[void]$items.Add($f[3])
			continue
		}
	}

	$alias = New-Object 'System.Collections.Generic.Dictionary[string,int]'
	$raw = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$hashed = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$pendnl = New-Object 'System.Collections.Generic.Dictionary[string,int]'
	$scanned = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	# Keys carry the note file, so nothing has to be cleared between notes - the
	# shell does the same, because `delete array` without a subscript is an
	# extension some awks have and POSIX does not.
	$seen = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$rec = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$used = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$done = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
	$nchecked = 0

	foreach ($f in $noteFiles) {
		# Only `claim` and `assumption`, and only where the note is current.
		# Invariant 20 is about a claim the prose has to carry; a `fact` reaches
		# the plan as an `[F#]` code that resolves forward whatever the paragraph
		# says, and a retracted or superseded note is the strikethrough rule and
		# the supersession sweep respectively.
		$ty = Get-DriftNoteValue $f 'type'
		if (-not ((Test-DriftEqual $ty 'claim') -or (Test-DriftEqual $ty 'assumption'))) { continue }
		$st = Get-DriftNoteValue $f 'status'
		if ($st.Length -ne 0 -and -not (Test-DriftEqual $st 'current')) { continue }

		$id = Get-DriftNoteValue $f 'id'
		$uk = $f + $SUB + 'used_in'
		$rk = $f + $SUB + 'reconciled_sections'
		$recorded = New-Object 'System.Collections.Generic.List[string]'
		if ($li.ContainsKey($rk)) { $recorded = $li[$rk] }
		$cited = New-Object 'System.Collections.Generic.List[string]'
		if ($li.ContainsKey($uk)) { $cited = $li[$uk] }

		# What the note records, split once: the target it names and the hash it
		# recorded for it.
		foreach ($item in $recorded) {
			$sp = $item.IndexOf([char]32)
			$tg = $item
			$hash = ''
			if ($sp -ge 0) {
				$tg = $item.Substring(0, $sp)
				$hash = Get-DriftTrim $item.Substring($sp + 1)
			}
			$tk = $f + $SUB + (Get-DriftDoc $tg) + $SUB + (Get-DriftAnchor $tg)
			[void]$seen.Add($tk)
			$rec[$tk] = $hash
		}

		foreach ($entry in $cited) {
			$doc = Get-DriftDoc $entry
			$anc = Get-DriftAnchor $entry
			# A citation with no anchor names a whole document and there is no
			# section to hash. A missing document or a dead anchor is --used-in
			# verdict; reporting either here would be the same failure under a
			# name about reconciliation.
			if ($doc.Length -eq 0 -or $anc.Length -eq 0 -or -not $PATHIDX.Contains($doc)) { continue }
			Read-DriftSections $doc
			$ak = $doc + $SUB + (ConvertTo-DriftFold $anc)
			if (-not $alias.ContainsKey($ak)) { continue }
			$ord = $alias[$ak]
			if ($ord -le 0) { continue }

			$tk = $f + $SUB + $doc + $SUB + $anc
			[void]$used.Add($tk)
			# MEMOISED PER SECTION, NOT PER CITING NOTE. Several claims
			# legitimately cite one section, and the hash is a byte-at-a-time walk
			# over its whole body - recomputing it per citation makes the cost
			# O(citations) where the answer only has O(sections) worth of distinct
			# values in it. Keyed the same way $raw is, beside it.
			$bk = $doc + $SUB + $ord
			$now = ''
			if ($hashed.ContainsKey($bk)) {
				$now = $hashed[$bk]
			} else {
				$body = ''
				if ($raw.ContainsKey($bk)) { $body = $raw[$bk] }
				$now = Get-DriftHash $body
				$hashed[$bk] = $now
			}
			$nchecked++
			if (-not $seen.Contains($tk)) {
				Add-DriftFailure $f 'section-hash-missing' $id ('`used_in` names `' + $entry + '` and `reconciled_sections` records nothing for it. Nothing in the corpus says what that section said when this claim was reconciled against it, so a later rewrite of the block leaves the citation resolving and the claim standing on prose nobody has re-read - which is invariant 20 satisfied once and then quietly undone. Re-read the section and record it: `' + $entry + ' ' + $now + '`')
			} elseif ($rec[$tk].Length -eq 0) {
				Add-DriftFailure $f 'section-hash-missing' $id ('`reconciled_sections` names `' + $entry + '` with no hash after it, so the entry records that somebody looked and not what they saw - and a later rewrite of that block is then indistinguishable from no change at all. Record the hash: `' + $entry + ' ' + $now + '`')
			} elseif (-not (Test-DriftEqual $rec[$tk] $now)) {
				Add-DriftFailure $f 'section-hash-drifted' $id ('`reconciled_sections` recorded `' + $rec[$tk] + '` for `' + $entry + '` and that section now hashes to `' + $now + '`. The heading is untouched, so `used_in` still resolves and every other check passes while the prose the claim stands on has been rewritten since anybody read it against this note. This is the failure invariant 20 exists to prevent, occurring after the invariant was satisfied once. Re-read the section: if the claim still holds, record `' + $entry + ' ' + $now + '` and move `reconciled:` to today; if it does not, the claim is what has to change')
			}
		}

		# BOTH DIRECTIONS, for the reason --red-team checks its roster both ways:
		# an entry for a section this claim no longer cites is a hash nothing
		# compares, and it reads as coverage to anybody counting entries against
		# citations.
		foreach ($item in $recorded) {
			$sp = $item.IndexOf([char]32)
			$tg = $item
			if ($sp -ge 0) { $tg = $item.Substring(0, $sp) }
			$tk = $f + $SUB + (Get-DriftDoc $tg) + $SUB + (Get-DriftAnchor $tg)
			if ($used.Contains($tk)) { continue }
			if ($done.Contains($tk)) { continue }
			[void]$done.Add($tk)
			Add-DriftFailure $f 'section-hash-unused' $id ('`reconciled_sections` names `' + $tg + '` and `used_in` does not. The note records having read a section it no longer says it is cited into, so the entry is a hash nothing will ever compare - and to anybody checking that every citation has one, it reads as covered. Either restore the `used_in` entry or drop this one')
		}
	}

	if ($nchecked -eq 0) {
		$okLine = 'no current claim or assumption names a resolving document section under ' + $VAULT + ' - there is nothing whose content a rewrite could drop, which is every vault before drafting cites one'
	} else {
		$plural = 's'
		if ($nchecked -eq 1) { $plural = '' }
		$okLine = [string]$nchecked + ' cited section' + $plural + ' hashed against the value the note recorded - ' + $VAULT
	}

	exit (Render-Failures 'vault-lint claim-drift' $okLine)
}

# ----------------------------------------------------------------------------
# 13. check - pass 3, the note-level checks
#
# Ports bin/vault-lint.sh:3003-3629. The largest body in the file, gated on
# schemaVersion throughout, and the mode a bare invocation runs.
#
# THE MESSAGES ARE THE PRODUCT (bin/vault-lint.sh:3009-3012). Every one of them
# names what is wrong AND what it costs, because the person reading it is
# deciding whether to care and a message that only restates the rule gives them
# nothing to decide with. Every failure string below is transcribed character
# for character from the awk program; the only edit this port is allowed is
# transliterating a non-ASCII character, and this region carries none.
#
# THE HELPERS BELOW ARE LOCAL TO THIS FUNCTION ON PURPOSE. present() in
# particular is copied verbatim into the --binding-driver pass
# (bin/vault-lint.sh:2513-2517), and the shell keeps six separate copies of one
# fenced-block scan for the same reason (:1369): a helper two modes want is
# a helper two slices are both editing. Hoisting one into the shared region is
# the cross-slice edit the stub seam exists to prevent, and a divergence between
# two copies is what the parity gate is there to report.
#
# The awk program assigns `BS = sprintf("%c", 92)` at :3021 and never reads it.
# It is not transcribed: carried across, a dead assignment reads as a constant
# some check below depends on.
# ----------------------------------------------------------------------------
function Invoke-ModeCheck {
	# awk's SUBSEP - the character it joins a multi-index array key with. Every
	# two-dimensional table below is a flat Dictionary keyed the same way, so the
	# separator is written out once: one that could occur inside a note path or a
	# field name would silently merge two keys into one. The char and the string
	# are the same declaration because the only key this pass ever takes APART
	# again splits on the char - written as a literal there, a later change here
	# would move the join and leave the split behind, and the group key would
	# come back whole in a message that still renders.
	$SUBSEP_CHAR = [char]28
	$SUBSEP = [string]$SUBSEP_CHAR

	# The path index. The shell hands this pass a FILE and reads it into EXISTS
	# (bin/vault-lint.sh:3023); here the shared region has already built the same
	# set, so it is consumed rather than re-walked - `EXISTS[pl] = 1` is all any
	# consumer ever makes of it.
	$EXISTS = $script:PATHIDX

	# The two patterns this pass runs per note, held as Regex objects for the
	# reason the shared region gives at its own pattern block: the static
	# [regex]::IsMatch overloads look the pattern up in a process-wide cache of
	# fifteen on every call, and the ID test below runs once per block-list item
	# of every edge field of every note - so on a vault of any size that lookup,
	# not the matching, is what the check costs.
	$RX_CHECK_ID = [regex]'\A(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)-[A-Za-z0-9]+\z'
	$RX_CHECK_WHOLE = [regex]'\A[0-9]+\z'

	# ------------------------------------------------------------------------
	# the awk helper functions, transcribed (bin/vault-lint.sh:3187-3215)
	#
	# Declared before the tables because two of them build the tables. They read
	# the record maps below through PowerShell's dynamic scope, which is resolved
	# at call time - every map exists by the time the first call is made.
	# ------------------------------------------------------------------------

	# awk's `split(s, a, " ")` - runs of blanks, with leading and trailing ones
	# discarded. Every field list in this pass is written as one space-separated
	# string for the reason the shell gives: a list is one thing to keep in sync
	# with the schema document, and an array of quoted members is eight.
	function Split-CheckWords {
		param([string]$Text)
		$out = New-Object 'System.Collections.Generic.List[string]'
		foreach ($w in [regex]::Split($Text, '[ \t\n]+')) {
			if ($w.Length -ne 0) { [void]$out.Add($w) }
		}
		return , $out.ToArray()
	}

	# `V[f, k]` in awk is the empty string when the key was never set. Indexing a
	# Dictionary that way throws, which would turn an absent field into a stack
	# trace rather than into the failure the absence is supposed to produce.
	function Get-CheckValue {
		param([string]$F, [string]$K)
		$kk = $F + $SUBSEP + $K
		if ($V.ContainsKey($kk)) { return $V[$kk] }
		return ''
	}

	# `LN[f SUBSEP k]` - how many block-list items the note carries under a key.
	function Get-CheckListCount {
		param([string]$F, [string]$K)
		$kk = $F + $SUBSEP + $K
		if ($LI.ContainsKey($kk)) { return $LI[$kk].Count }
		return 0
	}

	# The items themselves, an empty list when the key carries none. The leading
	# comma stops PowerShell unwrapping a one-item list into a bare string, which
	# would make the caller's foreach walk that string's characters.
	function Get-CheckList {
		param([string]$F, [string]$K)
		$kk = $F + $SUBSEP + $K
		if ($LI.ContainsKey($kk)) { return , $LI[$kk] }
		return , (New-Object 'System.Collections.Generic.List[string]')
	}

	# present(f, k) at bin/vault-lint.sh:3215, copied verbatim into the
	# --binding-driver pass at :2513-2517. A field counts as present when it
	# holds a scalar OR at least one block-list item - the two record types a
	# note field can arrive as, and a check that read only one of them would pass
	# every note that wrote its value as a list.
	# It reads the two maps directly rather than through the two accessors above,
	# because it is the most-called helper in the pass - every required field of
	# every note, then the whole brief list twice and the whole verdict list
	# twice - and routing it through them would build the composite key a second
	# time and probe each dictionary twice for one answer.
	function Test-CheckPresent {
		param([string]$F, [string]$K)
		$kk = $F + $SUBSEP + $K
		if ($V.ContainsKey($kk) -and $V[$kk].Length -ne 0) { return $true }
		if ($LI.ContainsKey($kk) -and $LI[$kk].Count -gt 0) { return $true }
		return $false
	}

	# isid(), which the graph pass carries its own copy of for the reason the
	# stub seam above states. \A and \z rather than ^ and $: in .NET `$` also
	# matches before a trailing newline, so a value ending in one would read as a
	# well-formed ID here and not in awk.
	function Test-CheckIsId {
		param([string]$Text)
		return $RX_CHECK_ID.IsMatch($Text)
	}

	# nrm() - case and separator drift, collapsed. This is the whole of step 3 of
	# subject resolution below, and the reason step 3 exists: it catches the most
	# common near-miss for the cost of one pass per term, where an edit-distance
	# routine would be a nested loop per candidate pair over the whole
	# vocabulary. The lowercase is ASCII-only, which is what awk's tolower does
	# in the C locale, and every character outside [a-z0-9] is dropped either
	# way.
	function Get-CheckNorm {
		param([string]$Text)
		$sb = New-Object System.Text.StringBuilder
		for ($i = 0; $i -lt $Text.Length; $i++) {
			$c = $Text[$i]
			if ($c -ge [char]65 -and $c -le [char]90) { $c = [char]([int]$c + 32) }
			if (($c -ge [char]97 -and $c -le [char]122) -or ($c -ge [char]48 -and $c -le [char]57)) { [void]$sb.Append($c) }
		}
		return $sb.ToString()
	}

	# cpl() - the length of the common prefix of two strings.
	function Get-CheckCommonPrefixLength {
		param([string]$A, [string]$B)
		$n = $A.Length
		if ($B.Length -lt $n) { $n = $B.Length }
		for ($i = 0; $i -lt $n; $i++) {
			if ($A[$i] -cne $B[$i]) { return $i }
		}
		return $n
	}

	# target_of() - a block-list item may carry a ` :: ` label after the note ID
	# it names, and it is the ID in front of the label that has to resolve. The
	# 4 is the length of that separator, so the substring starts on the first
	# character past it.
	function Get-CheckEdgeTarget {
		param([string]$Item)
		$at = $Item.IndexOf(' :: ', [System.StringComparison]::Ordinal)
		if ($at -ge 0) { return $Item.Substring($at + 4) }
		return $Item
	}

	# report() at bin/vault-lint.sh:3213. The shell appends to a file that
	# render_failures then sorts; here the rows go straight onto the shared
	# $FAILURES list, which Render-Failures sorts with the same ordinal comparer.
	# So the order rows are emitted in cannot reach the output, which is what
	# lets the two grouped checks below iterate their groups unordered.
	function Add-CheckFailure {
		param([string]$File, [string]$Check, [string]$Id, [string]$Detail)
		[void]$script:FAILURES.Add($File + "`t" + $Check + "`t" + $Id + "`t" + $Detail)
	}

	# ------------------------------------------------------------------------
	# the tables, ported from the awk BEGIN block (bin/vault-lint.sh:3020-3184)
	# ------------------------------------------------------------------------

	$common = 'id type title status confidence created'

	$req = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$req['source'] = 'url url_canonical pulled quote'
	$req['fact'] = 'confidence_own rests_on'
	$req['claim'] = 'confidence_own subject stale_after rests_on'
	$req['assumption'] = 'value sensitivity validated_by'
	$req['question'] = 'gaps'
	# The decision-brief fields in references/decisions.md are deliberately NOT
	# required here: the decision note in vault.md is a valid decision note
	# without them, and a lint that fails the schema document own worked example
	# is a lint people switch off. They are checked for COHERENCE instead - see
	# the brief list below.
	$req['decision'] = 'confidence_own options chosen reasoning reopen_if rests_on'

	# The type names, for the type-agreement message. Read off one string rather
	# than written into the message, so the set a milestone joins is stated in
	# one place and the message cannot go on naming six types after a seventh is
	# registered below.
	$types = 'source, fact, claim, assumption, question, decision'

	# THE ONE SCHEMA GATE IN THIS PASS, AND EVERY MILESTONE CHECK HANGS OFF IT.
	# A vault at 1 predates the type and has no milestones/ directory, so
	# registering the type there would turn `milestone` into a legitimate value
	# of `type` in a corpus whose schema never had it - and the check that says
	# so (type-agreement) is the only thing that would notice a directory grown
	# without the version being moved.
	$SCHEMA_N = [int]$script:FOUND_SCHEMA
	if ($SCHEMA_N -ge 2) {
		$req['milestone'] = 'confidence_own sequence date_confidence moves resource rests_on'
		$types = $types + ', milestone'
	}

	# The required list per type, split once now that the schema gate has settled
	# what the types are. Splitting inside the note loop instead would re-derive
	# one of at most eight constant answers per note, which is the same reason
	# the brief, verdict, driver-kind and edge lists below are split out here.
	# A type with no entry gets the common fields alone, which is what awk's
	# `common (ty in req ? " " req[ty] : "")` says.
	$commonf = Split-CheckWords $common
	$reqf = New-Object 'System.Collections.Generic.Dictionary[string,string[]]'
	foreach ($rt in $req.Keys) { $reqf[$rt] = Split-CheckWords ($common + ' ' + $req[$rt]) }

	$why = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$why['id'] = 'nothing can address this note, so every edge that was meant to point at it dangles'
	$why['type'] = 'the directory, the ID prefix and the type field stop agreeing, and each consumer answers differently'
	$why['title'] = 'a rendered document has nothing to show - the ID is a link target, not a label'
	$why['status'] = 'a retracted assertion is indistinguishable from a live one'
	$why['confidence'] = 'a hedge anywhere in the chain below this note has nowhere to surface'
	$why['created'] = 'there is no way to tell a note written before a source was amended from one written after, which is the distinction a re-check runs on'
	$why['url'] = 'the material cannot be found again'
	$why['url_canonical'] = 'duplicate detection cannot see this source, so two researchers citing the same page read as two independent citations'
	$why['pulled'] = 'there is no record of when the material was actually read, so nobody can tell whether it predates an amendment'
	$why['quote'] = 'URLs rot and pages are silently edited - without the passage the note reads as sourced with nothing behind it'
	$why['confidence_own'] = 'the derived confidence has no input, so min(confidence_own, rests_on) cannot be checked and the stored value is unverifiable'
	$why['rests_on'] = 'the note asserts something with no provenance, and it is precisely the note that gets cited without hesitation'
	$why['subject'] = 'the claim can never collide with one that contradicts it, so a disagreement stays invisible to every query'
	$why['stale_after'] = 'the claim has no declared shelf life, so nothing will ever flag it for re-checking'
	$why['value'] = 'there is nothing specific enough to validate, so a validation step reports success whatever it finds'
	$why['sensitivity'] = 'every unverified assumption looks equally urgent, so they all get deferred equally'
	$why['validated_by'] = 'a permanent unverified belief that nothing is scheduled to revisit'
	$why['gaps'] = 'the question is a topic rather than something researchable, and nothing says when it closes'
	$why['options'] = 'the rejected set is unrecorded, and reading the rejected set is the entire reason to keep the note'
	$why['chosen'] = 'the record says a fork was considered and not which way it went'
	$why['reasoning'] = 'the decision cannot be re-evaluated when its basis moves'
	$why['reopen_if'] = 'a decision with no trigger is indistinguishable from one nobody may revisit, so it gets filed rather than re-checked'
	$why['sequence'] = 'nothing can order this item against another, so the two checks that read order - a prerequisite scheduled after the item needing it, and two items asserted concurrent on one resource - have no field to run on, and a roadmap with no order reads as a set of things that all happen at once'
	$why['date_confidence'] = 'a month the skill derived and a month the founder stated become the same string, and the derived one gets quoted back as a commitment nobody made'
	$why['moves'] = 'the item moves no assumption anyone can name, and roadmap-sequencing.md Rule 1 files that as maintenance rather than as a roadmap item - the model then carries a dated change with no assumption row behind it, so the curve is decoration'
	$why['resource'] = 'what the item consumes is unrecorded, so two items competing for the same founder-week read as independent and the plan credits both'

	# The decision-brief fields below are not in any req[] entry - no type
	# requires them - but they share this table because the question it answers
	# is the same one: what does the absence of this field cost. Reached from the
	# decision-brief check rather than from required-field.
	$why['criteria'] = 'there is nothing to compare the choice against, so the values-congruence check - the one signal that catches a wrong recommendation - can never be run'
	$why['criteria_ranked_by'] = 'a skill-ranked list reads later as the ranking the founder gave, and the recommendation then agrees with those criteria by construction'
	$why['option_evidence'] = 'the evidence sits on the decision as a whole, so a column that was well sourced and a column with nothing behind it are indistinguishable'
	$why['do_nothing'] = 'the mandatory status-quo column stops being mechanically checkable, and a grid that quietly dropped it presented the decision as already made'
	$why['founder_reasoning'] = 'the record reads six months later as a choice made on analysis, and the constraint that actually drove it - I do not want to owe anyone money - is gone, unrecoverable, and was the reason the decision was right'
	$why['likelihood'] = 'the probability survives only in a hedged verb that fuses it with confidence, so a thin lean and a well-evidenced coin flip become the same sentence'
	$why['likelihood_range'] = 'the band term drifts between readers far enough to justify different choices, and neither reader learns they disagreed'
	$why['evidence_grade'] = 'the register of the recommendation is set by how the author felt about the call rather than by the evidence'

	# The verdict fields, reached from the verdict check rather than from
	# required-field: no type requires them, and the question the table answers
	# is the same one - what the absence of this field costs.
	$why['binding_driver'] = 'the two counts beside it are over nothing in particular, because distinct sources under the verdict is most of the corpus while distinct sources under the driver that binds is a number worth printing - and the binding driver moves, so this is also the record of which driver the stored counts were taken under'
	$why['driver_kind'] = 'nothing downstream can tell a constraint the founder chose from one the category sets, so a policy-bound verdict renders at the same confidence letter as a structural one and the founder is talked out of something they could revisit this week'
	$why['conditional_on'] = 'the policy variable the verdict is conditional on exists only inside a sentence, so a rendered section that dropped it reads exactly like one that kept it - and only one of the two is true'
	$why['evidence_n'] = 'the corpus knows how thin the tail is and the rendered figure does not say so, because confidence is a letter about the weakest link and says nothing about how many links there are'
	$why['evidence_counterparties'] = 'three deals from one counterparty is the terms of one relationship reported as the terms of a market, and this is the half that cannot be recovered from anything else the corpus records - two write-ups of one party genuinely are two documents with two canonical URLs'

	# What a brief-backed decision note owes, from the field table in
	# references/decisions.md. Keep this list and the trigger split below in sync
	# with that table required column: a field added there, or moved between
	# required and conditional, has to be added or moved here.
	#
	# Presence cannot be required of every decision note, because only a GUIDED
	# fork produces a brief - a direct-posture founder who simply decided writes
	# a decision note carrying none of these, which is exactly vault.md worked
	# example. What CAN be required is coherence: carry one and you owe the rest.
	#
	# `notrigger` marks the members that never themselves demand the rest. Only
	# the option-grid fields trigger, because each is meaningless alone: ranked
	# criteria with no evidence per option, or a likelihood with no evidence
	# grade, is half a brief. `founder_reasoning` is the opposite - a verbatim
	# record of what the founder said is worth having on any decision note, so a
	# note migrated out of older prose can legitimately preserve it and carry
	# nothing else. Triggering on it would fail that note, and the cheapest way
	# to green would be deleting the verbatim words, which is the exact loss the
	# field was split out of `reasoning` to prevent.
	#
	# Absent from the list entirely, on the same reasoning: `assumptions_low`,
	# which decisions.md marks required only when any exist and which names
	# load-bearing beliefs worth recording on any decision, and the review fields
	# (reaffirmed, reviewed, what_happened, was_the_reasoning_right,
	# review_note), which record what happened to a decision afterwards -
	# something a decision with no brief behind it goes through the same.
	$brieff = Split-CheckWords 'criteria criteria_ranked_by option_evidence do_nothing founder_reasoning likelihood likelihood_range evidence_grade'
	$notrigger = New-Object 'System.Collections.Generic.HashSet[string]'
	[void]$notrigger.Add('founder_reasoning')

	# What a target verdict owes, from the verdict block in vault.md. The first
	# four are owed outright; `conditional_on` sits last in the list and is owed
	# on top of them exactly when `driver_kind` is one of the two policy values,
	# which `condonly` marks - a structural verdict has no choice to name, and a
	# rule demanding a condition from every verdict would be met by inventing
	# one. Marking the exception the way the decision brief marks `notrigger`
	# next door keeps one list and one walk. Keep this list and both triggers
	# below in sync with that block, and with the copy in the --binding-driver
	# pass, which counts the same five: a field added there has to be added in
	# both places.
	$verdictf = Split-CheckWords 'binding_driver driver_kind evidence_n evidence_counterparties conditional_on'
	$condonly = New-Object 'System.Collections.Generic.HashSet[string]'
	[void]$condonly.Add('conditional_on')

	# THE FIVE FIELDS HANG OFF THE SUBJECT RATHER THAN THE TYPE, because one
	# verdict is filed under both types inside a single engagement - an
	# `assumption` before the research that settles it and a `claim` after. A
	# rule keyed to `type: claim` would exempt every verdict written before the
	# research came back, which is every verdict at the point where a wrong one
	# is cheapest to fix.
	#
	# THE TWO SUBJECTS TRIGGER DIFFERENTLY AND THAT IS THE DESIGN.
	# `target-verdict` is a term this release introduces, so no note in any
	# existing corpus carries it: the four fields are owed there whatever the
	# note carries, including nothing. `steady-state-ceiling` is required and
	# predates its amendment, so every existing vault already holds one: there
	# the trigger is field PRESENCE, which is the exemption a version would
	# otherwise have to buy. Extending the leniency to the verdict half would
	# spend that exemption over an empty population and make omitting
	# `binding_driver` the cheapest way past every rule that reads it - and a
	# dodge available by omission is not an exemption, which is why --red-team
	# checks its roster both ways.
	$vsubject = New-Object 'System.Collections.Generic.HashSet[string]'
	[void]$vsubject.Add('target-verdict')
	[void]$vsubject.Add('steady-state-ceiling')

	# The closed driver_kind word list, duplicated in the --binding-driver pass,
	# which owns the four rules that read a document. Each awk program is a
	# separate process and cannot call the other. Change one, change both.
	$knownkind = New-Object 'System.Collections.Generic.HashSet[string]'
	foreach ($kw in (Split-CheckWords 'structural policy policy-within-band')) { [void]$knownkind.Add($kw) }
	$condkind = New-Object 'System.Collections.Generic.HashSet[string]'
	[void]$condkind.Add('policy')
	[void]$condkind.Add('policy-within-band')

	# The closed `model_input` word list, on the same terms as driver_kind above:
	# two words, unquoted, and a third is not a value. Closing it is what makes
	# --assumption-rows a check rather than a hint - the field is what says a note
	# is an input the projection has to carry a row for, so an unrecognised value
	# is a note that declares nothing while reading as declared, and the row it
	# owes is then never asked for.
	$knownminput = New-Object 'System.Collections.Generic.HashSet[string]'
	foreach ($kw in (Split-CheckWords 'revenue cost')) { [void]$knownminput.Add($kw) }

	# EDGE_FIELDS comes from the shared region and is deliberately wider than
	# vault.md's seven edges. Consumed, never redeclared: two copies would let
	# `graph` and `check` disagree about which fields exist.
	$edgef = Split-CheckWords $script:EDGE_FIELDS

	$rank = New-Object 'System.Collections.Generic.Dictionary[string,int]'
	$rank['L'] = 1
	$rank['M'] = 2
	$rank['H'] = 3
	# awk's name[1..3]. Index 0 is unused and holds '' so the ranks index this
	# array with the same numbers they carry in `rank`.
	$rankname = @('', 'L', 'M', 'H')

	# ------------------------------------------------------------------------
	# the record stream, read the way awk's pattern-action rules read it
	# (bin/vault-lint.sh:3217-3226)
	# ------------------------------------------------------------------------

	$terms = New-Object 'System.Collections.Generic.List[string]'
	$isterm = New-Object 'System.Collections.Generic.HashSet[string]'
	$required = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$aliases = New-Object 'System.Collections.Generic.List[string]'
	$aliasof = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$files = New-Object 'System.Collections.Generic.List[string]'
	$DIR = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$BASE = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$V = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$LI = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	$pe = New-Object 'System.Collections.Generic.List[string[]]'
	$broken = New-Object 'System.Collections.Generic.HashSet[string]'

	foreach ($rec in $script:RECORDS) {
		# Split on every tab and read the first four fields, which is what awk's
		# -F '\t' leaves in $1..$4. A field carrying a tab is truncated
		# identically on both sides rather than shifting the columns.
		$p = $rec.Split([char]9)
		$tag = Get-RowField $p 0
		if ($tag -ceq 'T') {
			$t = Get-RowField $p 1
			[void]$terms.Add($t)
			[void]$isterm.Add($t)
			$required[$t] = Get-RowField $p 2
		} elseif ($tag -ceq 'A') {
			$a = Get-RowField $p 1
			[void]$aliases.Add($a)
			$aliasof[$a] = Get-RowField $p 2
		} elseif ($tag -ceq 'N') {
			$f = Get-RowField $p 1
			[void]$files.Add($f)
			$DIR[$f] = Get-RowField $p 2
			$BASE[$f] = Get-RowField $p 3
		} elseif ($tag -ceq 'S') {
			$V[(Get-RowField $p 1) + $SUBSEP + (Get-RowField $p 2)] = Get-RowField $p 3
		} elseif ($tag -ceq 'L') {
			$k = (Get-RowField $p 1) + $SUBSEP + (Get-RowField $p 2)
			if (-not $LI.ContainsKey($k)) { $LI[$k] = New-Object 'System.Collections.Generic.List[string]' }
			[void]$LI[$k].Add((Get-RowField $p 3))
		} elseif ($tag -ceq 'E') {
			# A file that never parsed as a note has no fields to be missing.
			# Marking it suppresses the derived required-field and type-agreement
			# failures below, so the one message that matters - this is not a
			# note - is not buried under six consequences of it. A reviewer who
			# reads ten derived failures stops reading.
			$erel = Get-RowField $p 1
			$echeck = Get-RowField $p 2
			[void]$pe.Add([string[]]@($erel, $echeck, (Get-RowField $p 3)))
			if ($echeck -ceq 'frontmatter') { [void]$broken.Add($erel) }
		}
	}

	# ------------------------------------------------------------------------
	# the END block (bin/vault-lint.sh:3228-3608)
	# ------------------------------------------------------------------------

	$BYID = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	foreach ($f in $files) {
		$id = Get-CheckValue $f 'id'
		if ($id.Length -eq 0) { continue }
		if ($BYID.ContainsKey($id)) {
			Add-CheckFailure $f 'duplicate-id' $id ('ID ' + $id + ' is also carried by ' + $BYID[$id] + '. An ID is an address - two notes at one address means every edge pointing there resolves to whichever file a reader happened to open, and no query can tell them apart')
		} else {
			$BYID[$id] = $f
		}
	}

	# Parse errors, now with an ID attached where the note had one.
	foreach ($e in $pe) {
		Add-CheckFailure $e[0] $e[1] (Get-CheckValue $e[0] 'id') $e[2]
	}

	if ($script:HAS_VOCAB -ne 1) {
		Add-CheckFailure '_vocab.yml' 'missing-vocabulary' '' 'the vault has no _vocab.yml, so no subject can be checked against anything. Free-text subjects are the same as no subjects: two researchers write wtp and willingness-to-pay for the same thing, and the collision that would have surfaced their disagreement never happens'
	}

	# Normalised candidates, precomputed once. Terms take precedence over aliases
	# so a subject that normalises onto both is reported against the canonical
	# key.
	$canon = New-Object 'System.Collections.Generic.List[string]'
	$cnorm = New-Object 'System.Collections.Generic.List[string]'
	$normto = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	foreach ($t in $terms) {
		$nt = Get-CheckNorm $t
		[void]$canon.Add($t)
		[void]$cnorm.Add($nt)
		if (-not $normto.ContainsKey($nt)) { $normto[$nt] = $t }
	}
	foreach ($a in $aliases) {
		$na = Get-CheckNorm $a
		[void]$canon.Add($aliasof[$a])
		[void]$cnorm.Add($na)
		if (-not $normto.ContainsKey($na)) { $normto[$na] = $aliasof[$a] }
	}

	# The two grouped checks collect here and report after the file loop, because
	# each failure is a property of a GROUP and neither member is the wrong one.
	# The Dictionaries are walked unordered, exactly as awk walks them: each
	# member list is filled in note order, so the names INSIDE a message are
	# fixed, and Render-Failures ordinal-sorts every row before anything prints,
	# so which group is visited first cannot reach the output.
	$URLMEM = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	$CONC = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
	$restedon = New-Object 'System.Collections.Generic.HashSet[string]'
	$seen = New-Object 'System.Collections.Generic.HashSet[string]'

	foreach ($f in $files) {
		$id = Get-CheckValue $f 'id'
		$ty = Get-CheckValue $f 'type'
		# Read once and shared by the verdict trigger and subject resolution
		# below. Two reads of one field is two places a later change - a trim, a
		# case fold - can reach only one of, and the two checks would then
		# disagree about what this note's subject is.
		$s = Get-CheckValue $f 'subject'

		if (-not $broken.Contains($f)) {
			# --- required fields per type -----------------------------
			$rfields = $commonf
			if ($reqf.ContainsKey($ty)) { $rfields = $reqf[$ty] }
			foreach ($rf in $rfields) {
				if (Test-CheckPresent $f $rf) { continue }
				$onty = ''
				if ($ty.Length -ne 0) { $onty = ' on a ' + $ty + ' note' }
				$cost = 'the schema requires it'
				if ($why.ContainsKey($rf)) { $cost = $why[$rf] }
				Add-CheckFailure $f 'required-field' $id ('missing required field `' + $rf + '`' + $onty + ' - ' + $cost + '. A half-filled note makes later queries return false negatives that read as clean')
			}

			# --- a decision brief is all of its fields or none of them -
			# An option-grid field is what says a brief stands behind this
			# record; from there the rest are owed, including
			# founder_reasoning, which a brief owes without ever being what
			# demands one. The note carrying a grid and a recommendation and
			# no founder_reasoning is the one this exists for - it reads as
			# complete to every consumer, and nothing else in the corpus can
			# tell that it is not.
			#
			# One report per missing field, same as required-field above:
			# eight costs concatenated into a single message is a paragraph
			# nobody reads to the end.
			if ($ty -ceq 'decision') {
				$carried = ''
				$ncarried = 0
				$ntrig = 0
				foreach ($bf in $brieff) {
					if (-not (Test-CheckPresent $f $bf)) { continue }
					if ($ncarried -ne 0) { $carried = $carried + ', ' }
					$carried = $carried + '`' + $bf + '`'
					$ncarried++
					if (-not $notrigger.Contains($bf)) { $ntrig++ }
				}
				if ($ntrig -gt 0) {
					$bplural = ''
					if ($ncarried -gt 1) { $bplural = 's' }
					foreach ($bf in $brieff) {
						if (Test-CheckPresent $f $bf) { continue }
						Add-CheckFailure $f 'decision-brief-incomplete' $id ('carries the decision-brief field' + $bplural + ' ' + $carried + ' but not `' + $bf + '`. A decision note carrying none of the option-grid fields is a founder who simply decided, and is correct as written - only a guided fork produces a brief. One carrying some of them is a brief-backed decision that lost a field, and it reads as complete to every consumer while the missing part answers nothing. Without ' + $bf + ', ' + $why[$bf])
					}
				}
			}

			# --- a verdict owes its fields as a set, and its kind is ---
			# --- one of three words -----------------------------------
			# The same shape as the decision brief above, one type over and
			# keyed on the subject rather than on the type: a note carrying
			# some of them reads complete to every consumer, while the
			# missing field is precisely the one that would have qualified
			# the number. A verdict naming its driver and labelling it
			# `policy` with no counts is a fully qualified finding to every
			# reader and to every tool, and what it is not saying is that the
			# two deals underneath it came from one counterparty.
			#
			# One report per missing field, same as required-field and the
			# decision brief: four costs concatenated into a single message
			# is a paragraph nobody reads to the end.
			#
			# The four rules that need business-plan.md are --binding-driver,
			# not here. These two read nothing but the note, which is what
			# keeps them in the pass that runs on every bare invocation.
			if (($ty -ceq 'claim' -or $ty -ceq 'assumption') -and $vsubject.Contains($s)) {
				$vsj = $s
				$vcar = ''
				$nvcar = 0
				foreach ($bf in $verdictf) {
					if (-not (Test-CheckPresent $f $bf)) { continue }
					if ($nvcar -ne 0) { $vcar = $vcar + ', ' }
					$vcar = $vcar + '`' + $bf + '`'
					$nvcar++
				}
				$dk = Get-CheckValue $f 'driver_kind'

				if ($vsj -ceq 'target-verdict') {
					$vwhy = 'A target verdict owes them whatever else it carries: the subject is a term this release introduces, so no note written before the fields existed can be exempted by omitting one - and omission would otherwise be the cheapest way past every rule that reads them.'
				} else {
					$vwhy = 'A ceiling claim carrying none of the five owes none of them, which is what exempts every claim written before the fields existed; carrying one makes the rest owed, because a note carrying some of them reads complete to every consumer while the missing part is the one that would have qualified the number.'
				}

				if ($vsj -ceq 'target-verdict' -or $nvcar -gt 0) {
					$vplural = ''
					if ($nvcar -gt 1) { $vplural = 's' }
					foreach ($bf in $verdictf) {
						# `conditional_on` is owed only where the kind makes
						# it owed. Demanding it of a structural verdict would
						# be met by inventing a condition, which is worse
						# than the omission because an invented one renders.
						if ($condonly.Contains($bf) -and -not $condkind.Contains($dk)) { continue }
						if (Test-CheckPresent $f $bf) { continue }
						if ($nvcar -gt 0) {
							$vhead = 'carries the verdict field' + $vplural + ' ' + $vcar + ' but not `' + $bf + '`'
						} else {
							$vhead = 'carries `subject: target-verdict` and none of the fields a verdict owes outright, `' + $bf + '` among them'
						}
						Add-CheckFailure $f 'verdict-fields-incomplete' $id ($vhead + '. ' + $vwhy + ' Without `' + $bf + '`, ' + $why[$bf])
					}
				}

				# A fourth word is a classification no downstream rule knows
				# how to read, so it takes the structural path by default and
				# buys exactly the exemption invariant 18 exists to refuse -
				# with a typo indistinguishable from a deliberate call.
				if ($dk.Length -ne 0 -and -not $knownkind.Contains($dk)) {
					Add-CheckFailure $f 'driver-kind-unknown' $id ('`driver_kind` is `' + $dk + '` and the enumeration is closed at `structural`, `policy` and `policy-within-band`. Everything downstream branches on policy or not - a policy-bound verdict owes a stated condition and a structural one does not - so an unrecognised value takes the structural path by default, which is the exemption invariant 18 exists to refuse. A typo is then indistinguishable from a deliberate classification, and the plan reports a decision the founder made as a category floor')
				}
			}

			# --- the model-input word list is closed --------------------
			# The trigger is field presence and not the version, for the reason
			# `target-verdict` needs no version: `model_input` is a term this
			# release introduces, so no note in any existing corpus carries it and
			# there is no population an exemption would protect. The rule that
			# reads a document - --assumption-rows - is gated on schemaVersion 3
			# because it asks the TABLE for something too.
			$mi = Get-CheckValue $f 'model_input'
			if ($mi.Length -ne 0 -and -not $knownminput.Contains($mi)) {
				Add-CheckFailure $f 'model-input-unknown' $id ('`model_input` is `' + $mi + '` and the enumeration is closed at `revenue` and `cost`. The field is what declares this note an input the projection has to carry a row for, and --assumption-rows reads exactly that - so an unrecognised value is a note that declares nothing while reading as declared, and the row it owes is never asked for. That is the same failure the field exists to fix, reintroduced by a typo: the input stays in the ledger, never enters the model, and every verdict downstream inherits a denominator missing it')
			}

			# --- the type is stated three times and all three agree ----
			if ($ty.Length -ne 0 -and -not $req.ContainsKey($ty)) {
				$mtail = ''
				if ($ty -ceq 'milestone') {
					$mtail = '. `milestone` is a schemaVersion 2 type and this vault is stamped ' + $script:FOUND_SCHEMA + ', so it does not carry one - move the corpus to 2 the way vault-migration.md describes, doing the work before stamping'
				}
				Add-CheckFailure $f 'type-agreement' $id ('type `' + $ty + '` is not one of ' + $types + '. Structure that does not fit a type belongs on an edge, not in a new type' + $mtail)
			}
			if ($req.ContainsKey($ty) -and $DIR[$f] -cne ($ty + 's')) {
				Add-CheckFailure $f 'type-agreement' $id ('type is `' + $ty + '` but the note sits in ' + $DIR[$f] + '/ rather than ' + $ty + 's/. The filesystem sees only the directory, so a listing of ' + $ty + 's/ silently omits this note')
			}
			if ($id.Length -ne 0) {
				$pfx = $id
				$dash = $id.IndexOf([char]45)
				if ($dash -ge 0) { $pfx = $id.Substring(0, $dash) }
				if ($ty.Length -ne 0 -and $pfx -cne $ty.ToUpperInvariant()) {
					Add-CheckFailure $f 'type-agreement' $id ('ID prefix `' + $pfx + '` does not match type `' + $ty + '`. A grep over IDs sees only the prefix, so those two consumers already answer differently')
				}
				# Reported separately from type-agreement: vault.md keeps
				# these in two different sections, and a file renamed by
				# accident has nothing wrong with its type field. Fusing them
				# sends the reader to look at `type`.
				if ($BASE[$f] -cne ($id + '.md')) {
					Add-CheckFailure $f 'filename-mismatch' $id ('the filename is ' + $BASE[$f] + ' but the ID is ' + $id + '. The filename is meant to be exactly the ID plus .md, so that find-the-file-for-this-ID and grep-for-this-ID are the same operation - here they give two answers and one of them is wrong')
				}
			}
		}

		# --- supersession is always two edits ---------------------------
		# vault.md states this as one invariant with two halves, and the
		# second half is the one that fails silently: a replacement with a
		# reason, over a target still marked current, leaves two live notes
		# asserting different values on the same subject - which reads to both
		# a checker and a human as an unresolved contradiction rather than a
		# completed supersession.
		if ((Get-CheckListCount $f 'supersedes') -gt 0) {
			if ((Get-CheckValue $f 'supersedes_reason').Length -eq 0) {
				Add-CheckFailure $f 'supersedes-reason' $id 'supersedes a note with no `supersedes_reason`. The only question anyone ever asks about a superseded note is why, and by the time it is asked the person who knew has gone'
			}
			foreach ($tgt in (Get-CheckList $f 'supersedes')) {
				if (-not $BYID.ContainsKey($tgt)) { continue }
				$tstatus = Get-CheckValue $BYID[$tgt] 'status'
				if ($tstatus -cne 'superseded') {
					Add-CheckFailure $f 'supersedes-status' $id ('supersedes ' + $tgt + ', but that note is still `status: ' + $tstatus + '` rather than `superseded`. Supersession is two edits and only one was made, so both notes now read as live and the pair is indistinguishable from an unresolved contradiction')
				}
			}
		}

		# --- the two roadmap order rules, at schemaVersion 2 -----------
		# roadmap-sequencing.md asserts both in prose and nothing has ever read
		# them. That is what makes them worth a check rather than a paragraph:
		# a roadmap is a set of claims about when the inputs to the model
		# change, so an order nobody verified sets the month every downstream
		# number is dated to.
		#
		# `moves` naming a note that does not exist is deliberately NOT here -
		# `moves` is in EDGE_FIELDS, so it is the dangling-edge rule every
		# other edge already gets, for one word, and a `moves` value that is
		# not a note ID at all is the malformed-edge rule in the same loop.
		if ($SCHEMA_N -ge 2 -and $ty -ceq 'milestone') {
			$sq = Get-CheckValue $f 'sequence'
			$sqok = $RX_CHECK_WHOLE.IsMatch($sq)

			# The orderability of `sequence` is checked before anything reads
			# it, because both checks below silently skip a value they cannot
			# compare - and a check that stops firing prints the same green as
			# one that passed.
			if ($sq.Length -ne 0 -and -not $sqok) {
				Add-CheckFailure $f 'sequence-not-orderable' $id ('`sequence` is `' + $sq + '`, which is not a whole number. Ordering is what `sequence` is for - the date the founder said is kept verbatim in `date_stated` precisely so nothing has to parse it - and a value that will not compare takes both order checks down with it, silently, over exactly the roadmap whose order nobody wrote down')
			}

			foreach ($tgt in (Get-CheckList $f 'depends_on')) {
				# A dangling target is already a dangling-edge failure and an
				# unorderable one is already reported on its own note.
				# Reporting either again here would send the reader to the
				# wrong field.
				if (-not $BYID.ContainsKey($tgt)) { continue }
				$tsq = Get-CheckValue $BYID[$tgt] 'sequence'
				if (-not $sqok -or -not $RX_CHECK_WHOLE.IsMatch($tsq)) { continue }
				# [double] rather than [int], because that is the width awk's
				# `tsq + 0` compares at: a sequence past Int32 would overflow
				# here and compare fine there, which is a check answering
				# differently on the two implementations rather than failing.
				if ([double]$tsq -ge [double]$sq) {
					Add-CheckFailure $f 'dependency-after-dependent' $id ('`depends_on` names ' + $tgt + ', whose `sequence` is ' + $tsq + ', while the `sequence` here is ' + $sq + '. The prerequisite is scheduled at or after the item that needs it, so the roadmap projects a capability landing in a month its own precondition has not reached - and because every item is a dated change to an assumption row, the model credits that month with revenue nothing could have shipped in')
				}
			}

			# roadmap-sequencing.md Rule 4 - the rule it says most often
			# changes the answer and is the one people skip. Collected here and
			# reported after the loop, because the failure is a property of a
			# GROUP and neither member is the wrong one.
			$resource = Get-CheckValue $f 'resource'
			if ($resource.Length -ne 0 -and $sq.Length -ne 0) {
				$rk = $resource + $SUBSEP + $sq
				if (-not $CONC.ContainsKey($rk)) { $CONC[$rk] = New-Object 'System.Collections.Generic.List[string]' }
				[void]$CONC[$rk].Add($f)
			}
		}

		# --- edges resolve to real notes --------------------------------
		foreach ($ef in $edgef) {
			foreach ($item in (Get-CheckList $f $ef)) {
				$tgt = Get-CheckEdgeTarget $item
				if (Test-CheckIsId $tgt) {
					if (-not $BYID.ContainsKey($tgt)) {
						Add-CheckFailure $f 'dangling-edge' $id ('`' + $ef + '` points at ' + $tgt + ', which no note in this vault carries. A dangling edge silently shrinks every blast radius that runs through it - the query returns a clean, short answer rather than an error')
					}
				} elseif ($ef -ceq 'rests_on') {
					# A different failure from a dangling edge, and it wants a
					# different fix: nothing is missing from the vault, the
					# field never named a note in the first place.
					Add-CheckFailure $f 'malformed-edge' $id ('`rests_on` holds `' + $item + '`, which is not a note ID. rests_on is the blast-radius edge and has to name notes, or the chain from an amended source to the documents that inherited it stops here')
				} elseif ($ef -ceq 'moves') {
					# Same structural failure as rests_on above and a different
					# cost, so a different message. The two are written out
					# rather than folded into one generic sentence because a
					# reader who is told only that the value is not an ID still
					# has to work out what it cost on the field they wrote.
					#
					# This is the half of `moves` the dangling-edge rule cannot
					# reach. A value that IS a well-formed ID naming no note is
					# dangling-edge; a value that is not an ID at all fell
					# through this arm and passed clean. And it is the EXPECTED
					# mis-write rather than a hypothetical one:
					# roadmap-sequencing.md Rule 1 names the assumption an item
					# moves by its `A-n` row label, so the form an author writes
					# after reading the prose was the one form nothing caught.
					Add-CheckFailure $f 'malformed-edge' $id ('`moves` holds `' + $item + '`, which is not a note ID. An `A-n` row label off the assumptions table in the plan is what usually lands here, and the ledger cannot resolve a label to a note - so the item reads as naming the assumption it moves while naming nothing this vault holds, and the one check that makes roadmap-sequencing.md Rule 1 mechanical passes over the exact form authors write. Put the note ID of that assumption here; the table in the plan keeps its `A-n` label in prose')
				}
			}
		}

		# --- confidence propagates -------------------------------------
		$conf = Get-CheckValue $f 'confidence'
		if ((Get-CheckListCount $f 'rests_on') -gt 0 -and $rank.ContainsKey($conf)) {
			$own = Get-CheckValue $f 'confidence_own'
			if (-not $rank.ContainsKey($own)) { $own = $conf }
			$derived = $rank[$own]
			$weakest = 'its own confidence_own of ' + $own
			foreach ($tgt in (Get-CheckList $f 'rests_on')) {
				if (-not $BYID.ContainsKey($tgt)) { continue }
				$dc = Get-CheckValue $BYID[$tgt] 'confidence'
				if (-not $rank.ContainsKey($dc)) { continue }
				if ($rank[$dc] -lt $derived) {
					$derived = $rank[$dc]
					$weakest = $tgt + ', which is ' + $dc
				}
			}
			if ($rank[$conf] -gt $derived) {
				Add-CheckFailure $f 'confidence-propagation' $id ('stored confidence is ' + $conf + ' but min(confidence_own, every rests_on target) is ' + $rankname[$derived] + ', set by ' + $weakest + '. Without min, a hedged source becomes a fairly confident fact becomes a flat claim - every step locally reasonable, and by the third hop the hedge a stranger needed is gone')
			}
		}

		# --- subject resolution: five steps, first match wins -----------
		if ($ty -ceq 'claim' -and $s.Length -ne 0 -and $terms.Count -gt 0) {
			if ($isterm.Contains($s)) {
				[void]$seen.Add($s)
			} elseif ($aliasof.ContainsKey($s)) {
				Add-CheckFailure $f 'near-miss-subject' $id ('subject `' + $s + '` is an alias of `' + $aliasof[$s] + '`, not a vocabulary key. Store the canonical key: `' + $s + '` and `' + $aliasof[$s] + '` never collide, so two claims that disagree stay in agreement as far as any query can tell')
			} else {
				$ns = Get-CheckNorm $s
				if ($normto.ContainsKey($ns)) {
					Add-CheckFailure $f 'near-miss-subject' $id ('subject `' + $s + '` differs from the key `' + $normto[$ns] + '` only in case or separators. Drift like this never collides, so the contradiction the subject exists to surface stays hidden')
				} else {
					$best = ''
					$bestlen = 0
					for ($c = 0; $c -lt $canon.Count; $c++) {
						$cn = $cnorm[$c]
						if ($cn.Length -eq 0 -or $ns.Length -eq 0) { continue }
						if ($ns.Contains($cn) -or $cn.Contains($ns)) {
							if ($cn.Length -gt $bestlen) {
								$bestlen = $cn.Length
								$best = $canon[$c]
							}
						} else {
							$pl = Get-CheckCommonPrefixLength $ns $cn
							if ($pl -ge 5 -and $pl -gt $bestlen) {
								$bestlen = $pl
								$best = $canon[$c]
							}
						}
					}
					if ($best.Length -ne 0) {
						Add-CheckFailure $f 'near-miss-subject' $id ('subject `' + $s + '` is not a vocabulary key, but it overlaps `' + $best + '`. If it means the same thing, use the key - a near-miss never collides and so never surfaces a contradiction. If it is genuinely a new subject, add it to _vocab.yml with a definition saying what it excludes')
					} else {
						Add-CheckFailure $f 'unknown-subject' $id ('subject `' + $s + '` matches no vocabulary key and no alias. A term nobody declared cannot collide with anything, and an unresolved contradiction and a corpus with no contradictions look identical')
					}
				}
			}
		}

		# --- a claim past its declared shelf life ----------------------
		$stale = Get-CheckValue $f 'stale_after'
		$status = Get-CheckValue $f 'status'
		if ($ty -ceq 'claim' -and $stale.Length -ne 0 -and
			[string]::CompareOrdinal($stale, $script:TODAY) -lt 0 -and
			$status -cne 'superseded' -and $status -cne 'retracted') {
			$usedin = ''
			if ((Get-CheckListCount $f 'used_in') -gt 0) { $usedin = ' - used_in names the documents carrying it' }
			Add-CheckFailure $f 'stale-claim' $id ('stale_after is ' + $stale + ' and today is ' + $script:TODAY + ', with status still `' + $status + '`. The claim is past the shelf life its own author declared, so everything resting on it is standing on a value nobody has re-checked' + $usedin)
		}

		# --- duplicate sources, collected ------------------------------
		$ucanon = Get-CheckValue $f 'url_canonical'
		if ($ty -ceq 'source' -and $ucanon.Length -ne 0) {
			if (-not $URLMEM.ContainsKey($ucanon)) { $URLMEM[$ucanon] = New-Object 'System.Collections.Generic.List[string]' }
			[void]$URLMEM[$ucanon].Add($f)
		}

		# --- vault-relative source paths that resolve to nothing --------
		# A source with no public URL carries a vault-relative path. That is
		# indistinguishable from a path pointing outside the vault, and a
		# missing file is not a malformed field - so without this check the
		# note passes every other test while its evidence is absent. Anything
		# carrying a scheme or a `host:`/`prefix:` marker is deliberately not
		# vault-relative and is skipped.
		$url = Get-CheckValue $f 'url'
		if ($ty -ceq 'source' -and $url.Length -ne 0 -and -not $url.Contains(':')) {
			# The trailing slash comes off before the lookup because the path
			# index holds a directory under its bare name - `research` and not
			# `research/` - so a value written with one would miss an entry that
			# is there and be reported as evidence that does not exist.
			$lp = $url -creplace '/+\z', ''
			if ($lp.Length -ne 0 -and -not $EXISTS.Contains($lp)) {
				Add-CheckFailure $f 'unresolved-local-source' $id ('url `' + $url + '` has no scheme, so it reads as vault-relative - and nothing exists at that path inside the vault. Either the file belongs in the vault, or the path points outside it and needs a marker (`slug:research/file.md`) so it is not read as vault-relative. A missing file is not a malformed field, so every other check passes while the evidence is absent')
			}
		}

		foreach ($tgt in (Get-CheckList $f 'rests_on')) { [void]$restedon.Add($tgt) }
	}

	# Reported against every member of the group, not just the first one seen.
	# Both notes are equally implicated, and a reader who greps the output for
	# one filename has to find it there - attaching the whole group to whichever
	# file sorted first hides the duplicate from exactly the person looking at
	# the other one.
	foreach ($u in $URLMEM.Keys) {
		$members = $URLMEM[$u]
		if ($members.Count -lt 2) { continue }
		$others = $members -join ', '
		foreach ($m in $members) {
			Add-CheckFailure $m 'duplicate-url' (Get-CheckValue $m 'id') ('url_canonical ' + $u + ' is carried by ' + $members.Count + ' source notes: ' + $others + '. A claim resting on two of them looks doubly sourced when it rests on one document - which is what one newsletter link carrying tracking parameters and one search result turn into')
		}
	}

	# Two milestones sharing a `resource` AND a `sequence` are asserted
	# concurrent on one constrained resource. roadmap-sequencing.md Rule 4 says
	# they only compete if they consume the same one - so this is that rule read
	# off the ledger instead of trusted, and a FALSE independence claim is what
	# it catches: the naive value ranking it licenses orders the whole roadmap,
	# and nothing downstream ever revisits it.
	#
	# Reported against every member of the group for the reason duplicate-url is:
	# neither item is the wrong one, and a reader who opens the other file has to
	# find the failure there too. Grouped and iterated exactly the way
	# duplicate-url is - Render-Failures sorts the whole failure list before
	# anything prints it, so the order rows are emitted in cannot reach the
	# output.
	foreach ($rk in $CONC.Keys) {
		$members = $CONC[$rk]
		if ($members.Count -lt 2) { continue }
		$rkp = $rk.Split($SUBSEP_CHAR)
		$ids = New-Object 'System.Collections.Generic.List[string]'
		foreach ($m in $members) { [void]$ids.Add((Get-CheckValue $m 'id')) }
		$others = $ids -join ', '
		for ($mi = 0; $mi -lt $members.Count; $mi++) {
			Add-CheckFailure $members[$mi] 'false-independence' $ids[$mi] ([string]$members.Count + ' milestones declare `resource: ' + $rkp[0] + '` at `sequence: ' + $rkp[1] + '`: ' + $others + '. Items competing for one constrained resource cannot be asserted concurrent, so at least one of them is not happening in that slot. Give them distinct sequences, or name the resource each actually consumes - left as is, the plan reads as though both land and every number downstream inherits a week of capacity that was counted twice')
		}
	}

	foreach ($f in $files) {
		if ((Get-CheckValue $f 'type') -cne 'source') { continue }
		$id = Get-CheckValue $f 'id'
		if ($id.Length -eq 0 -or $restedon.Contains($id)) { continue }
		Add-CheckFailure $f 'orphan-source' $id 'nothing in the vault rests on this source. Either the research was read and never used, or something that should have cited it cited nothing - both are worth one look, and neither is visible from inside the note'
	}

	foreach ($t in $terms) {
		if ($required[$t] -cne 'true' -or $seen.Contains($t)) { continue }
		Add-CheckFailure '_vocab.yml' 'coverage-gap' '' ('no claim carries the required subject `' + $t + '`. The note schema cannot catch a thin spine, because you cannot type a fact nobody wrote - a required subject with no claim under it is an omission every document downstream inherits in silence')
	}

	# ------------------------------------------------------------------------
	# render (bin/vault-lint.sh:3611-3629)
	# ------------------------------------------------------------------------

	# What the bare run did NOT ask, read off the mode table rather than written
	# out a second time. A mode added to the gate would otherwise leave this line
	# silently understating what it skipped, which is the same hand-maintained
	# enumeration the table exists to remove. `check` is excluded because it is
	# the mode printing the line.
	$SKIPPED = ''
	foreach ($row in (Get-ModeRows)) {
		if ($row.Gate -cne 'gate') { continue }
		if ($row.Selector -ceq 'check') { continue }
		if ($SKIPPED.Length -ne 0) { $SKIPPED = $SKIPPED + ', ' }
		$SKIPPED = $SKIPPED + $row.Part
	}

	exit (Render-Failures 'vault-lint' ('note-level checks passed - ' + $script:VAULT + '. Not opened: ' + $SKIPPED + ' - --release-gate asks all of them.'))
}

# ============================================================================
# END OF THE STUB SEAM
# ============================================================================

# ----------------------------------------------------------------------------
# arguments
#
# Ports bin/vault-lint.sh:354-424.
# ----------------------------------------------------------------------------

$MODE = 'check'
$VAULT = ''
$JSON = 0
$DEPTH = '2'
$TARGET = ''

$ARGV = New-Object 'System.Collections.Generic.List[string]'
foreach ($a in $args) { [void]$ARGV.Add([string]$a) }
$ai = 0

if ($ARGV.Count -gt 0) {
	if ($ARGV[0] -ceq 'check') {
		$ai = 1
	} elseif ($ARGV[0] -ceq 'graph') {
		$MODE = 'graph'
		$ai = 1
		# `vault-lint.sh` and not `vault-lint.ps1`, deliberately: every string
		# this tool prints that names itself is transcribed from the shell, and
		# the ONE exception is the die() prefix, which the parity gate folds by
		# name. Anything else renamed here diverges mid-message, where nothing
		# folds it. See Show-Usage for the same rule and why it is unfinished.
		if ($ai -ge $ARGV.Count) { Exit-Refusal 'graph needs a note ID, for example: vault-lint.sh graph CLAIM-AS23SD44' }
		$TARGET = $ARGV[$ai]
		$ai++
	}
}

while ($ai -lt $ARGV.Count) {
	$arg = $ARGV[$ai]
	if ($arg -ceq '--vault') {
		if ($ARGV.Count - $ai -lt 2) { Exit-Refusal '--vault needs a path' }
		$VAULT = $ARGV[$ai + 1]
		$ai += 2
	} elseif ($arg.StartsWith('--vault=', [System.StringComparison]::Ordinal)) {
		$VAULT = $arg.Substring(8)
		$ai++
	} elseif ($arg -ceq '--json') {
		$JSON = 1
		$ai++
	} elseif ($arg -ceq '--depth') {
		if ($ARGV.Count - $ai -lt 2) { Exit-Refusal '--depth needs a number' }
		$DEPTH = $ARGV[$ai + 1]
		$ai += 2
	} elseif ($arg.StartsWith('--depth=', [System.StringComparison]::Ordinal)) {
		$DEPTH = $arg.Substring(8)
		$ai++
	} elseif ($arg -ceq '--help' -or $arg -ceq '-h') {
		Show-Usage
		exit 0
	} else {
		# Every mode flag resolves through the mode table rather than through an
		# arm of its own, which is what makes adding a mode a one-line append.
		$selected = Get-ModeForFlag $arg
		if ($selected.Length -eq 0) { Exit-Refusal ('unexpected argument: ' + $arg) }
		if ($MODE -ceq 'graph') { Exit-Refusal ($arg + ' and graph are separate modes') }
		$MODE = $selected
		$ai++
	}
}

# \A and \z rather than ^ and $: in .NET `$` also matches immediately before a
# trailing newline, so a `--depth` argument of "2<LF>" would pass a `^[0-9]+$`
# test and then be used as a number. The shell's `*[!0-9]*` case pattern has no
# such hole, and a divergence here is a refusal on one implementation and a run
# on the other.
if (-not [regex]::IsMatch($DEPTH, '\A[0-9]+\z')) {
	Exit-Refusal ('--depth must be a whole number, got: ' + $DEPTH)
}

if ($MODE -ceq 'graph' -and $JSON -eq 1) {
	Exit-Refusal 'graph prints text only - its consumer is an agent building a plan, not an eye looking at a picture'
}

# ----------------------------------------------------------------------------
# locate and validate the vault
#
# Ports bin/vault-lint.sh:426-465. Resolution is --vault, then $VAULT_PATH, then
# refuse. Never an upward search: from a code repo that walks to the filesystem
# root and errors far from its cause, or finds a .vault belonging to a different
# engagement and reads the wrong corpus with no error at all.
# ----------------------------------------------------------------------------

if ($VAULT.Length -eq 0 -and $null -ne $env:VAULT_PATH) { $VAULT = $env:VAULT_PATH }
if ($VAULT.Length -eq 0) { Exit-Refusal 'no vault. Pass --vault <path> or set VAULT_PATH.' }
if (-not (Test-Path -LiteralPath $VAULT -PathType Container)) { Exit-Refusal ('not a directory: ' + $VAULT) }

# One trailing `/` and nothing else, exactly as `${VAULT%/}` does - not `\`, and
# not TrimEnd. The `vault` field of every --json document echoes this string
# verbatim, so anything stripped here that the shell does not strip is a byte
# the parity gate reports as a difference on all eighteen fixtures at once.
if ($VAULT.EndsWith('/', [System.StringComparison]::Ordinal)) { $VAULT = $VAULT.Substring(0, $VAULT.Length - 1) }

$CONFIG = $VAULT + '/.vault/config.json'
if (-not (Test-Path -LiteralPath $CONFIG -PathType Leaf)) {
	Exit-Refusal ('not a vault - no .vault/config.json under ' + $VAULT + '. Refusing rather than walking an arbitrary directory of Markdown as if it were a corpus.')
}

# The versions this tool can read, oldest first. A SET rather than a single
# number, because both directions of the mismatch are not the same problem. A
# vault at 1 predates the checks version 2 added and cannot owe them, so
# refusing it would fail every corpus that existed before they did - the tool
# reads it and holds it to exactly the rules it was written under. A version
# from the FUTURE stays refused, which is the whole reason the field exists: an
# older tool half-reading a newer vault reports a clean bill of health over
# every field it never saw.
$SUPPORTED_SCHEMA = '1 2 3'
$FOUND_SCHEMA = ''
foreach ($line in (Read-TextLines $CONFIG)) {
	$m = [regex]::Match($line, '"schemaVersion"[ \t]*:[ \t]*[0-9]+')
	if (-not $m.Success) { continue }
	$digits = [regex]::Match($m.Value, '[0-9]+\z')
	if ($digits.Success) { $FOUND_SCHEMA = $digits.Value; break }
}

if ($FOUND_SCHEMA.Length -eq 0) {
	Exit-Refusal ($CONFIG + ' carries no schemaVersion. A tool that guesses half-reads the vault and reports a clean bill of health over every field it never saw.')
}
if (-not ((' ' + $SUPPORTED_SCHEMA + ' ').Contains(' ' + $FOUND_SCHEMA + ' '))) {
	Exit-Refusal ('vault schemaVersion is ' + $FOUND_SCHEMA + ' and this tool reads only these versions: ' + $SUPPORTED_SCHEMA + '. Refusing rather than processing the parts it recognises - a green result from a half-read vault is exactly what somebody acts on.')
}

# ----------------------------------------------------------------------------
# DISPATCH POINT 1 - before anything reads the corpus
#
# --release-gate re-invokes this script once per part, so it must not pay for a
# note index it never uses. Same position as bin/vault-lint.sh:493.
#
# THE --json REFUSAL LIVES HERE, NOT IN THE STUB BODY, and it is ported ahead of
# the mode it belongs to. Two reasons. It is asserted today
# (scripts/fixtures/run-fixtures.sh:772 runs it against whichever implementation
# VAULT_LINT names), so an unported --release-gate that answered 3 to
# `--release-gate --json` would fail that assertion while the mode is still
# allowlisted. And keeping it outside the body means porting the mode cannot
# drop it: a refusal is the argument surface answering, not the mode running.
#
# It sits AFTER vault resolution because that is where the shell has it: with no
# vault at all, `--release-gate --json` answers "no vault" on both
# implementations rather than answering the refusal that never got that far.
# ----------------------------------------------------------------------------

if ($MODE -ceq 'release-gate') {
	if ($JSON -eq 1) {
		Exit-Refusal '--release-gate prints several modes in sequence, and several JSON documents printed one after another are not a JSON document. Run each mode with --json separately.'
	}
	Invoke-ModeReleaseGate
}

# ----------------------------------------------------------------------------
# the three things every mode below reads
#
# Ports bin/vault-lint.sh:519-548.
# ----------------------------------------------------------------------------

$VOCAB = $VAULT + '/_vocab.yml'
$HAS_VOCAB = 0
if (Test-Path -LiteralPath $VOCAB -PathType Leaf) { $HAS_VOCAB = 1 }

# The rendered plan at the vault root, and whether it is there. Three modes read
# it - --roadmap-table for the roadmap section, --binding-driver for the verdict
# section, and --used-in through the path index - so the predicate is computed
# once here beside HAS_VOCAB rather than per mode with a prefix on the name. Two
# prefixed copies of a one-line test is how a third arrives.
$PLAN = $VAULT + '/business-plan.md'
$HAS_PLAN = 0
if (Test-Path -LiteralPath $PLAN -PathType Leaf) { $HAS_PLAN = 1 }
# The financial model beside it, on the same terms and for the same reason:
# --assumption-rows reads its assumptions table, so the predicate is computed
# once here rather than prefixed onto a copy of the three lines above.
$FINMODEL = $VAULT + '/financial-model.md'
$HAS_FINMODEL = 0
if (Test-Path -LiteralPath $FINMODEL -PathType Leaf) { $HAS_FINMODEL = 1 }

# Every field whose block-list items name other notes. DELIBERATELY wider than
# vault.md's seven edges: `covers` is a question field and `assumptions_low` and
# `option_evidence` come from decisions.md, and none of the three is called an
# edge anywhere - but each holds note IDs, so each has to be followed for a
# dangling target and walked by `graph`. Declared once and consumed by both
# traversals: two copies would let `graph` and `check` disagree about which
# fields exist, which is the tool shrinking its own blast radius exactly the way
# it warns notes not to.
#
# `depends_on` and `moves` are here unconditionally rather than behind the
# schema gate. A vault at 1 carries neither field, so listing them costs nothing
# there - and gating them would mean the schema-2 check that `moves` names a
# note that exists is a rule of its own instead of the dangling-edge rule every
# other edge already gets.
#
# `arr_excludes` is here for the same reason `moves` is: its items are note IDs,
# so a mistyped one has to be a dangling edge rather than a silent exclusion. An
# ARR term that declares it leaves out a note the vault does not hold is the one
# form of that declaration nobody can check by reading it.
$EDGE_FIELDS = 'rests_on supersedes scopes validated_by depends_on moves covers assumptions_low option_evidence arr_excludes'

# ----------------------------------------------------------------------------
# the record stream
#
# Ports bin/vault-lint.sh:549-888. The shell writes three scratch files under a
# mktemp directory because each of its passes is a separate awk process and a
# pipe cannot be re-read. This file holds the same three streams as in-process
# lists, under the same names, which removes the temp directory and with it the
# EXIT/HUP/INT/TERM traps that clean it up: PowerShell 5.1 has no reliable
# equivalent of a signal trap, so a scratch directory here would be one this
# tool leaks on every interrupt.
#
#   $RECORDS   the tab-separated record stream, in the order the shell appends
#              it - pass 1's A rows, then its T rows, then pass 2's N/S/L/E rows
#   $FILES     the note file list, one path per entry, sorted in byte order
#   $FAILURES  the rows a verdict mode accumulates and Render-Failures renders,
#              `file <TAB> check <TAB> id <TAB> detail`
#
# EVERY PATH IN THESE STREAMS IS VAULT-RELATIVE WITH `/` SEPARATORS, normalized
# HERE, once, where Get-ChildItem replaces `find` - never per mode. Get-ChildItem
# yields `\` on Windows, and a `\` both diverges from the shell AND is then
# doubled by the JSON escaper, so an unnormalized path produces a silently
# different document rather than an obviously broken one.
# ----------------------------------------------------------------------------

# The generic type names are QUOTED. Unquoted, PowerShell parses
# `Dictionary[string, string]` as an array argument to New-Object rather than
# as a type parameter list, and the failure is a runtime cast error deep in the
# vocabulary pass - not a parse error where the type is written. Quoting every
# one of them is a single rule with no exception to remember.
$RECORDS = New-Object 'System.Collections.Generic.List[string]'
$FILES = New-Object 'System.Collections.Generic.List[string]'
$FAILURES = New-Object 'System.Collections.Generic.List[string]'

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
$NOTE_DIRS = @('sources', 'facts', 'claims', 'assumptions', 'questions', 'decisions', 'milestones')

foreach ($d in $NOTE_DIRS) {
	$dirPath = $VAULT + '/' + $d
	if (-not (Test-Path -LiteralPath $dirPath -PathType Container)) { continue }
	$prefix = Get-PathPrefix $dirPath
	if ($prefix.Length -eq 0) { continue }
	# -Force, because `find` lists dot-prefixed files and PowerShell marks them
	# hidden: without it a `.draft.md` left in a note directory is invisible here
	# and read there, which is a note the two implementations disagree about the
	# existence of.
	#
	# THE WALK STARTS AT $prefix, NOT AT $dirPath, so the string being stripped
	# below is the string the enumeration was rooted at. Two resolutions of one
	# directory do not have to spell it the same way: on Windows a path reached
	# through an 8.3 short name (`C:\Users\RUNNER~1\...`, which is what %TEMP%
	# hands a process for a long user name) resolves to a longer spelling, and
	# Substring against a prefix of the other length cuts into the file name
	# instead of off it. Every note then points at a path that does not exist -
	# and because a note that cannot be read is reported as a parse failure
	# rather than as a missing index, a mode that only counts notes of one type
	# sees a vault with none of them and reports agreement.
	foreach ($entry in (Get-ChildItem -LiteralPath $prefix -Recurse -File -Force -ErrorAction SilentlyContinue)) {
		# -cnotlike, not -notlike: `find -name '*.md'` matches case-sensitively
		# even on a case-insensitive filesystem, and PowerShell's -like does not.
		# A README.MD picked up here would be parsed as a note and reported as
		# one missing every required field.
		if ($entry.Name -cnotlike '*.md') { continue }
		[void]$FILES.Add($VAULT + '/' + $d + '/' + (Get-RelativeSlashPath $entry.FullName $prefix))
	}
}

# `LC_ALL=C sort` is byte order, so the comparer is ordinal - never
# Sort-Object's culture-aware default, which would reorder the note list and
# every failure row at once and make each mode's JSON diff read as a bug in
# whichever mode the reader happened to check first. Ordinal compares UTF-16
# code units rather than UTF-8 bytes, which agrees with byte order everywhere
# except between an astral character and U+E000..U+FFFF - a distinction no note
# path has ever made.
$FILES_SORTED = $FILES.ToArray()
[System.Array]::Sort($FILES_SORTED, [System.StringComparer]::Ordinal)
$FILES.Clear()
foreach ($f in $FILES_SORTED) { [void]$FILES.Add($f) }

# ----------------------------------------------------------------------------
# the patterns both parsers run
#
# Held as Regex objects rather than passed as strings to [regex]::IsMatch. The
# static overloads look the pattern up in a process-wide cache of fifteen on
# every call, and the note parser below runs several of these per line of every
# note in the corpus - so on a vault of any size that lookup, not the matching,
# is what the parse costs. Declared once here because the vocabulary pass and
# the note pass share several of them; the patterns that run a handful of times
# per process (the --depth check, the schemaVersion scan) stay inline, where
# hoisting would buy nothing and only move them away from their one reader.
# ----------------------------------------------------------------------------

$RX_COMMENT = [regex]'\A[ \t]*#'
$RX_BLANK = [regex]'\A[ \t]*\z'
$RX_VOCAB_TERM = [regex]'\A  [A-Za-z][A-Za-z0-9_-]*:[ \t]*\z'
$RX_VOCAB_FIELD = [regex]'\A    [A-Za-z][A-Za-z0-9_-]*:'
$RX_VOCAB_FIELD_NAME = [regex]'\A[A-Za-z][A-Za-z0-9_-]*:'
$RX_VOCAB_ALIAS = [regex]'\A      -[ \t]+'
$RX_TOP_KEY = [regex]'\A[A-Za-z_][A-Za-z0-9_-]*:'
$RX_LIST_ITEM = [regex]'\A[ \t]*-[ \t]+'
$RX_ISO_DATE = [regex]'\A[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\z'
$RX_LEADING_ZERO = [regex]'\A0[0-9]+\z'

# ----------------------------------------------------------------------------
# pass 1 - the vocabulary
#
# Ports bin/vault-lint.sh:586-646. Appends to the record stream, tab separated:
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
#
# A TRAILING CR IS STRIPPED, exactly as the note parser strips one on every line
# it reads. An earlier comment here claimed the opposite was a faithful
# transcription - that the shell's awk leaves the CR in place too, so a CRLF
# _vocab.yml fails the term-key pattern identically on both implementations.
# That is false on the one platform this file exists for: Git for Windows'
# awk reads in text mode and hands the pattern a line with no CR, so the shell
# parses a CRLF vocabulary and the port did not. The whole vocabulary went empty
# and `check` silently stopped asking three of its questions - unknown-subject,
# near-miss-subject and coverage-gap all need a term to compare against, and a
# vault with none reports no subject failures rather than reporting that it
# could not check any. A Windows user's _vocab.yml is CRLF by default, so that
# is the ordinary case, not the corner: the vault lints clean while carrying
# unknown subjects and a thin spine, which is the exact silence this lint exists
# to break.
# ----------------------------------------------------------------------------

if ($HAS_VOCAB -eq 1 -and $MODE -ceq 'check') {
	$vocabOrder = New-Object 'System.Collections.Generic.List[string]'
	$vocabRequired = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$term = ''
	$field = ''

	foreach ($rawLine in (Read-TextLines $VOCAB)) {
		$line = Remove-TrailingCr $rawLine
		if ($RX_COMMENT.IsMatch($line)) { continue }
		if ($RX_BLANK.IsMatch($line)) { continue }

		# A term key: two spaces of indent, nothing after the colon.
		if ($RX_VOCAB_TERM.IsMatch($line)) {
			$term = $line.Substring(2) -creplace ':[ \t]*\z', ''
			[void]$vocabOrder.Add($term)
			$vocabRequired[$term] = ''
			$field = ''
			continue
		}

		# A field of the current term. Seeing one resets `field`, which is what
		# stops a continuation line of a multi-line plain `definition` being read
		# as a key - and why the format bans ": " inside a definition.
		if ($RX_VOCAB_FIELD.IsMatch($line)) {
			$rest = $line.Substring(4)
			$m = $RX_VOCAB_FIELD_NAME.Match($rest)
			$field = $rest.Substring(0, $m.Length - 1)
			$v = $rest.Substring($m.Length).Trim($SPACE_TAB)
			if ($field -ceq 'required') { $vocabRequired[$term] = $v }
			continue
		}

		if ($RX_VOCAB_ALIAS.IsMatch($line)) {
			if ($field -ceq 'aliases') {
				$alias = ($line -creplace '\A[ \t]*-[ \t]+', '').TrimEnd($SPACE_TAB)
				[void]$RECORDS.Add("A`t" + $alias + "`t" + $term)
			}
			continue
		}
	}

	# The T rows are emitted after every A row, in term order, because the shell
	# emits them from awk's END block. A consumer that aggregates by key does not
	# care, but the record stream is compared byte for byte through `check`, so
	# the order is part of the contract rather than an accident of structure.
	foreach ($t in $vocabOrder) { [void]$RECORDS.Add("T`t" + $t + "`t" + $vocabRequired[$t]) }
}

# ----------------------------------------------------------------------------
# pass 2 - the notes
#
# Ports bin/vault-lint.sh:648-883. Appends to the record stream, tab separated:
#   N <relpath> <dir> <basename>
#   S <relpath> <key> <value>     scalar, block-scalar body, or a joined
#                                 multi-line plain scalar. A newline inside a
#                                 value is stored as the two characters \n.
#   L <relpath> <key> <item>      one line per block-list item
#   E <relpath> <check> <detail>  a parse failure, riding the same stream so it
#                                 can be re-emitted with the note ID attached
#                                 once every note has been read
#
# The frontmatter reader is a subset parser over flat scalars, block lists, and
# the four fields allowed a literal block scalar. It COERCES NOTHING - every
# value is treated as text. That is what makes a parser this small adequate: a
# reader that does no type coercion cannot diverge from a real YAML parser,
# because there is nothing left to be wrong about. The schema bans the values a
# YAML parser would coerce, and the ambiguous-value check reports them.
# ----------------------------------------------------------------------------

# The closed set: a literal block scalar is allowed on these four fields and
# nowhere else. They are the only values that must survive exactly as written -
# a verbatim source passage, and the founder reasoning, skill reasoning and
# reopen trigger on a decision.
$BLOCK_OK = @{ 'quote' = $true; 'reasoning' = $true; 'reopen_if' = $true; 'founder_reasoning' = $true }

function Get-Indent {
	param([string]$Text)
	$i = 0
	while ($i -lt $Text.Length) {
		$c = $Text[$i]
		if ($c -ne [char]32 -and $c -ne [char]9) { break }
		$i++
	}
	return $i
}

# Join a multi-line value onto one record line. A newline becomes the two
# characters backslash-n, which is what keeps one record on one line.
function ConvertTo-FlatValue {
	param([string]$Text)
	return ($Text.Replace([char]9, [char]32).Split([char]10) -join '\n')
}

# Strip one layer of matching quotes and undo the escape each style uses.
function Remove-YamlQuotes {
	param([string]$Text)
	$n = $Text.Length
	if ($n -lt 2) { return $Text }
	$q = $Text[0]
	if ($q -ne [char]34 -and $q -ne [char]39) { return $Text }
	if ($Text[$n - 1] -ne $q) { return $Text }
	$inner = $Text.Substring(1, $n - 2)
	if ($q -eq [char]34) { return $inner.Replace('\"', '"') }
	return $inner.Replace("''", "'")
}

# The coerce-nothing invariant as a test. Returns what leaving the value as
# written costs, or '' when the value is unambiguous text.
function Test-AmbiguousValue {
	param([string]$Value)
	if ($Value.Length -eq 0) { return '' }
	if ($Value[0] -eq [char]34 -or $Value[0] -eq [char]39) { return '' }
	$lv = $Value.ToLowerInvariant()
	if ($lv -ceq 'yes' -or $lv -ceq 'no' -or $lv -ceq 'on' -or $lv -ceq 'off' -or
		$lv -ceq 'true' -or $lv -ceq 'false' -or $lv -ceq 'y' -or $lv -ceq 'n') {
		return 'YAML 1.1 reads it as a boolean and YAML 1.2 as the text ' + $lv + ', so the note means one thing to the editor and another to every reader'
	}
	if ($RX_ISO_DATE.IsMatch($Value)) {
		return 'unquoted it is a date object in most parsers and text in the rest, and the plain string comparison every staleness query relies on stops working'
	}
	if ($RX_LEADING_ZERO.IsMatch($Value)) {
		return 'unquoted leading zeros are read as octal by some parsers and truncated by others'
	}
	if ($Value.Contains(': ')) {
		return 'an unquoted colon-space splits the value into a nested mapping, so the field stops holding what it reads as holding'
	}
	return ''
}

# Parse failures ride the same record stream as everything else, tagged E. A
# side channel would need a second pass purely to prefix the tag, and that
# reshaping pass re-splits on tabs, which truncates any detail carrying one -
# unparsed-line embeds raw file content, so it can. Pass 3 aggregates by key
# rather than by order, so an E record arriving before its note's N record is
# fine.
function Add-ParseError {
	param([string]$Rel, [int]$LineNo, [string]$Check, [string]$Detail)
	[void]$script:RECORDS.Add("E`t" + $Rel + "`t" + $Check + "`tline " + $LineNo + ': ' + $Detail.Replace([char]9, [char]32))
}

# Emit whatever key is open. Printing is the only side effect, so the caller
# resets its own state.
function Add-FlushedKey {
	param([string]$Rel, [string]$Key, [string]$State, [string]$Value, [int]$KeyLine)
	if ($State -ceq 'scalar' -or $State -ceq 'block') {
		[void]$script:RECORDS.Add("S`t" + $Rel + "`t" + $Key + "`t" + (ConvertTo-FlatValue $Value))
	} elseif ($State -ceq 'pending') {
		Add-ParseError $Rel $KeyLine 'null-value' ('field `' + $Key + '` is present holding nothing. A present key holding nothing is not the same as an absent key, and a consumer expecting a list gets a type it did not plan for - if there is nothing to list, omit the key')
	}
}

function Read-NoteFile {
	param([string]$Path, [string]$Rel)

	$lines = $null
	try {
		$lines = Read-TextLines $Path
	} catch {
		Add-ParseError $Rel 0 'frontmatter' 'the file cannot be read'
		return
	}
	if ($lines.Count -eq 0) {
		Add-ParseError $Rel 0 'frontmatter' 'the file is empty, so it carries no note fields at all'
		return
	}

	$lineno = 1
	$infm = 0
	$state = ''
	$key = ''
	$keyline = 0
	$keyindent = 0
	$val = ''
	$bindent = -1

	if ((Remove-TrailingCr $lines[0]) -cne '---') {
		Add-ParseError $Rel 1 'frontmatter' 'the file does not open with a --- fence, so it is not a note: every field in it is invisible to every query, and the note reads as absent rather than as broken'
		return
	}
	$infm = 1

	for ($li = 1; $li -lt $lines.Count; $li++) {
		$lineno++
		$line = Remove-TrailingCr $lines[$li]
		# `\A[ \t]*\z` without the regex: the indent scan has already walked the
		# leading space and tab, so a line is blank exactly when that scan
		# consumed all of it. One pass over the prefix instead of two.
		$ind = Get-Indent $line
		$blank = ($ind -eq $line.Length)

		# Inside a block scalar, everything indented further than the key belongs
		# to the value, line by line, until the first line that dedents back to
		# the key indentation or less. A reader that stops at the first blank
		# line returns a note that parsed without error and has no quote in it.
		if ($state -ceq 'block') {
			if ($blank) { $val = $val + "`n"; continue }
			if ($ind -gt $keyindent) {
				if ($bindent -lt 0) { $bindent = $ind }
				if ($val.Length -ne 0) { $val = $val + "`n" }
				# substr past the end of the string is '' in awk and an exception
				# here, and it is reachable: a later block line may be indented
				# past the key but short of the first line's indent.
				if ($bindent -lt $line.Length) { $val = $val + $line.Substring($bindent) }
				continue
			}
			Add-FlushedKey $Rel $key $state $val $keyline
			$state = ''; $val = ''; $bindent = -1
			# fall through: this line closes the block and is itself a key
		}

		if ($blank) { continue }
		# `\A[ \t]*#` off the same scan. $blank is false here, so $ind indexes a
		# real character - the first one that is neither space nor tab.
		if ($line[$ind] -eq [char]35) { continue }

		if ($ind -eq 0 -and $line -ceq '---') {
			Add-FlushedKey $Rel $key $state $val $keyline
			$state = ''; $val = ''
			$infm = 0
			break
		}

		# Matched only where it can match. An indented line is never a top-level
		# key and a top-level line is never a list item, so guarding each regex
		# by the indent it needs means a line pays for at most one of them.
		$keyMatch = $null
		if ($ind -eq 0) { $keyMatch = $RX_TOP_KEY.Match($line) }
		if ($null -ne $keyMatch -and $keyMatch.Success) {
			Add-FlushedKey $Rel $key $state $val $keyline
			$state = ''; $val = ''; $bindent = -1

			$k = $line.Substring(0, $keyMatch.Length - 1)
			$v = $line.Substring($keyMatch.Length).Trim($SPACE_TAB)
			$key = $k; $keyline = $lineno; $keyindent = $ind

			if ($v.Length -eq 0) {
				$state = 'pending'
			} elseif ($v[0] -eq [char]124) {
				# Read the block properly whether or not this field is allowed
				# one. Bailing here would leave every indented line that follows
				# to be read as the next key.
				if (-not $BLOCK_OK.ContainsKey($k)) {
					Add-ParseError $Rel $lineno 'block-scalar-field' ('field `' + $k + '` uses a literal block scalar. The block form is allowed on quote, reasoning, reopen_if and founder_reasoning and nowhere else - a reader that tolerates a fifth field has to special-case a sixth and a seventh, and the closed set is what lets it reject instead of guess')
				}
				$state = 'block'; $val = ''; $bindent = -1
			} elseif ($v[0] -eq [char]62) {
				Add-ParseError $Rel $lineno 'folded-scalar' ('field `' + $k + '` uses a folded block scalar. Folded style reflows the block onto single lines at read time, joining line breaks into spaces - on a verbatim passage that means it stops being verbatim, which is the one job the field has. Write | instead')
				$state = 'block'; $val = ''; $bindent = -1
			} elseif ($v[0] -eq [char]91) {
				Add-ParseError $Rel $lineno 'inline-flow-list' ('field `' + $k + '` is an inline flow list. Obsidian rewrites inline lists into block form when it saves a note, so every edge here is lost the first time somebody opens the vault in an editor - and the blast-radius query then returns a clean result over a corpus it can no longer see, which nobody investigates')
				[void]$script:RECORDS.Add("S`t" + $Rel + "`t" + $k + "`t" + (ConvertTo-FlatValue $v))
				$state = ''
			} elseif ($v.ToLowerInvariant() -ceq 'null' -or $v -ceq '~') {
				Add-ParseError $Rel $lineno 'null-value' ('field `' + $k + '` is set to ' + $v + '. A present key holding nothing is not the same as an absent key - omit the key instead')
				$state = ''
			} else {
				$wh = Test-AmbiguousValue $v
				if ($wh.Length -ne 0) {
					Add-ParseError $Rel $lineno 'ambiguous-value' ('field `' + $k + '` has the unquoted value ' + $v + ' - ' + $wh + '. Quote it')
				}
				$state = 'scalar'; $val = (Remove-YamlQuotes $v)
			}
			continue
		}

		$itemMatch = $null
		if ($ind -gt 0 -and ($state -ceq 'pending' -or $state -ceq 'list')) { $itemMatch = $RX_LIST_ITEM.Match($line) }
		if ($null -ne $itemMatch -and $itemMatch.Success) {
			$item = $line.Substring($itemMatch.Length).TrimEnd($SPACE_TAB)
			$state = 'list'
			$wh = Test-AmbiguousValue $item
			if ($wh.Length -ne 0) {
				Add-ParseError $Rel $lineno 'ambiguous-value' ('list item `' + $item + '` under `' + $key + '` is unquoted - ' + $wh + '. Quote it')
			}
			[void]$script:RECORDS.Add("L`t" + $Rel + "`t" + $key + "`t" + (ConvertTo-FlatValue (Remove-YamlQuotes $item)))
			continue
		}

		# An indented line after a scalar is a multi-line plain scalar
		# continuation. Tolerated rather than rejected: that is the shape the
		# vocabulary file uses, and a reader that chokes on it is one people
		# stop running.
		if ($ind -gt 0 -and $state -ceq 'scalar') {
			$val = $val + ' ' + $line.Trim($SPACE_TAB)
			continue
		}

		Add-ParseError $Rel $lineno 'unparsed-line' ('this line is neither a key, a block-list item, a comment, nor the closing fence, so whatever it was meant to record is not in the ledger: ' + $line)
	}

	if ($infm -eq 1) {
		Add-ParseError $Rel $lineno 'frontmatter' 'the frontmatter block is never closed by a --- fence, so where the ledger ends and the prose begins is undefined and every reader draws the line somewhere different'
	}
}

foreach ($path in $FILES) {
	if ($path.Length -eq 0) { continue }
	$rel = $path
	if ($rel.StartsWith($VAULT, [System.StringComparison]::Ordinal) -and $rel.Length -gt $VAULT.Length) {
		$rel = $rel.Substring($VAULT.Length + 1)
	}
	$seg = $rel.Split([char]47)
	$dirSeg = ''
	if ($seg.Count -gt 1) { $dirSeg = $seg[$seg.Count - 2] }
	[void]$RECORDS.Add("N`t" + $rel + "`t" + $dirSeg + "`t" + $seg[$seg.Count - 1])
	Read-NoteFile $path $rel
}

# ----------------------------------------------------------------------------
# DISPATCH POINT 2 - after the record stream, before the path index
#
# None of these three produces a failure row, and the path index costs a walk
# over the whole vault, so all three exit above it - the same positions as
# bin/vault-lint.sh:889, :1019 and :1129.
# ----------------------------------------------------------------------------

if ($MODE -ceq 'graph') { Invoke-ModeGraph }
if ($MODE -ceq 'unverified') { Invoke-ModeUnverified }
if ($MODE -ceq 'supersession-sweep') { Invoke-ModeSupersessionSweep }

# ----------------------------------------------------------------------------
# what every verdict mode shares
#
# Ports bin/vault-lint.sh:1606-1708. Every mode that emits failure rows and
# carries a verdict out in its exit status builds on what follows, so the date,
# the path index and the renderer are built once here rather than once per mode.
# That is `check`, --used-in, --red-team, --roadmap-table, --binding-driver,
# --monitoring and --deliverable today, and a mode joins the list by being
# dispatched below this point rather than by registering anywhere - which is why
# this comment names them and the code does not.
# ----------------------------------------------------------------------------

# InvariantCulture, not the ambient one: a Windows install whose locale has a
# non-Gregorian default calendar (th-TH is the usual one) formats 'yyyy' as the
# Buddhist year, so `checked_on` would come out 543 years off on exactly the
# machines this file exists for, and every JSON document would differ from the
# shell's on that one line.
$TODAY = (Get-Date).ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)

# Every path that exists inside the vault, relative to its root - files AND
# directories, which is what `find . -mindepth 1` gives. Read once rather than
# shelling out per note: a source with no public URL carries a vault-relative
# path, a used_in entry names a document at the vault root, and the only way to
# know either resolves is to look. Answering from this index rather than from
# the filesystem also keeps every lookup inside the vault - a used_in entry of
# ../elsewhere.md is reported missing rather than opened.
#
# A set, because a set is all the shell's consumers make of it (`EXISTS[pl]=1`).
# Enumeration order is `find`'s traversal order, which is unspecified, so no
# mode may depend on it; a mode that needs an order sorts with
# [StringComparer]::Ordinal.
$PATHIDX = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
$VAULT_PREFIX = Get-PathPrefix $VAULT
if ($VAULT_PREFIX.Length -gt 0) {
	# Rooted at $VAULT_PREFIX rather than at $VAULT for the reason the note walk
	# above is: the prefix stripped from each result has to be the prefix the
	# results were built from. Here the mismatch is silent rather than loud - the
	# StartsWith guard below drops every entry - so the index comes back empty
	# and every vault-relative path in the corpus is reported as resolving to
	# nothing.
	foreach ($entry in (Get-ChildItem -LiteralPath $VAULT_PREFIX -Recurse -Force -ErrorAction SilentlyContinue)) {
		$full = $entry.FullName
		if (-not $full.StartsWith($VAULT_PREFIX, [System.StringComparison]::Ordinal)) { continue }
		[void]$PATHIDX.Add((Get-RelativeSlashPath $full $VAULT_PREFIX))
	}
}

# Escaped one character at a time, exactly as the awk escaper is written. THE
# SAME ESCAPER AS THE --unverified AND --supersession-sweep RENDERERS: all three
# are short, stable and identical, and the moment any one of them grows a case
# the others do not, that is the point to hoist it. Change one, change all
# three - and on both implementations.
#
# ConvertTo-Json is not an option here and never will be: Windows PowerShell
# 5.1's serializer differs from this in its escaping, its key order AND its
# indentation, so a document it produced would fail the byte-for-byte comparison
# on every fixture while looking perfectly well-formed to a reader.
function ConvertTo-JsonEscaped {
	param([string]$Text)
	$sb = New-Object System.Text.StringBuilder
	for ($i = 0; $i -lt $Text.Length; $i++) {
		$c = $Text[$i]
		if ($c -eq [char]34) { [void]$sb.Append('\"') }
		elseif ($c -eq [char]92) { [void]$sb.Append('\\') }
		elseif ($c -eq [char]9) { [void]$sb.Append([char]32) }
		else { [void]$sb.Append($c) }
	}
	return $sb.ToString()
}

# A failure row's Nth tab-separated field, or '' when the row is short. awk
# reads an absent field as the empty string; indexing a PowerShell array past
# its end throws under StrictMode, which would turn a malformed row into a stack
# trace instead of an empty cell.
function Get-RowField {
	param([string[]]$Fields, [int]$Index)
	if ($Index -ge $Fields.Length) { return '' }
	return $Fields[$Index]
}

# One renderer, branching on $JSON internally - the same shape --unverified
# uses, so a further report mode has one pattern to copy rather than two. It
# also carries the exit status out itself, which is what removes the separate
# counting pass: it already knows how many rows it buffered. `Prog` is the name
# the mode answers to, so a --used-in failure is not mistaken for a `check`
# failure by whoever reads the terminal.
#
# Human output goes to stderr and JSON to stdout on purpose: a caller piping
# --json into a parser gets only the document, and a human running it bare still
# sees everything.
#
# `OkLine` is the line printed when nothing failed, and it is a parameter rather
# than a constant because "clean" means something different in each mode.
# `check` looks at note fields and never opens a document, so a corpus with
# dozens of dead anchors used to print the same `clean` as a whole corpus in
# order - and a success line read as a whole-corpus verdict is the thing
# somebody renders on. --used-in's clean genuinely is what it says: every target
# it was asked to open resolved. It keeps the default.
#
# RETURNS the exit status the mode exits with - 0 when nothing failed, 1
# otherwise. The caller exits with it; nothing else in this file decides that.
function Render-Failures {
	param([string]$Prog, [string]$OkLine = '')

	if ($OkLine.Length -eq 0) { $OkLine = 'clean - ' + $script:VAULT }

	# `LC_ALL=C sort` over the failure rows. Ordinal, never Sort-Object's
	# culture-aware default: all seven modes that render through here inherit the
	# ordering, so a culture-aware comparer reorders rows in every one of them at
	# once and each JSON diff then reads as a bug in whichever mode was checked
	# first.
	$rows = $script:FAILURES.ToArray()
	[System.Array]::Sort($rows, [System.StringComparer]::Ordinal)
	$n = $rows.Length

	if ($script:JSON -eq 1) {
		$sb = New-Object System.Text.StringBuilder
		[void]$sb.Append("{`n")
		[void]$sb.Append('  "ok": ')
		if ($n -eq 0) { [void]$sb.Append('true') } else { [void]$sb.Append('false') }
		[void]$sb.Append(",`n")
		[void]$sb.Append('  "vault": "' + (ConvertTo-JsonEscaped $script:VAULT) + "`",`n")
		[void]$sb.Append('  "checked_on": "' + (ConvertTo-JsonEscaped $script:TODAY) + "`",`n")
		[void]$sb.Append('  "failure_count": ' + $n + ",`n")
		[void]$sb.Append('  "failures": [')
		for ($i = 0; $i -lt $n; $i++) {
			# Split on every tab and take the first four fields, which is what
			# awk's split() with FS="\t" leaves in p[1]..p[4]. A detail carrying
			# a tab is truncated identically on both sides rather than shifting
			# the columns.
			$p = $rows[$i].Split([char]9)
			if ($i -ne 0) { [void]$sb.Append(',') }
			[void]$sb.Append("`n    {")
			[void]$sb.Append('"file": "' + (ConvertTo-JsonEscaped (Get-RowField $p 0)) + '", ')
			[void]$sb.Append('"check": "' + (ConvertTo-JsonEscaped (Get-RowField $p 1)) + '", ')
			[void]$sb.Append('"id": "' + (ConvertTo-JsonEscaped (Get-RowField $p 2)) + '", ')
			[void]$sb.Append('"detail": "' + (ConvertTo-JsonEscaped (Get-RowField $p 3)) + '"}')
		}
		if ($n -ne 0) { [void]$sb.Append("`n  ") }
		[void]$sb.Append("]`n}`n")
		Write-OutText $sb.ToString()
	} elseif ($n -eq 0) {
		Write-OutText ($Prog + ': ' + $OkLine + "`n")
	} else {
		$plural = 's'
		if ($n -eq 1) { $plural = '' }
		Write-ErrText ($Prog + ': ' + $n + ' failure' + $plural + ' under ' + $script:VAULT + "`n")
		$last = ''
		for ($i = 0; $i -lt $n; $i++) {
			$p = $rows[$i].Split([char]9)
			$file = Get-RowField $p 0
			if ($file -cne $last) {
				Write-ErrText ("`n" + $file + "`n")
				$last = $file
			}
			Write-ErrText ('  [' + (Get-RowField $p 1) + '] ' + (Get-RowField $p 3) + "`n")
		}
		Write-ErrText "`n"
	}

	if ($n -eq 0) { return 0 }
	return 1
}

# ----------------------------------------------------------------------------
# DISPATCH POINT 3 - the verdict modes
#
# `check` is last and unconditional because it is the default mode: the shell
# runs off the end of the file into it (bin/vault-lint.sh:3003), so an `if` here
# would leave a bare invocation doing nothing at all.
# ----------------------------------------------------------------------------

if ($MODE -ceq 'used-in') { Invoke-ModeUsedIn }
if ($MODE -ceq 'red-team') { Invoke-ModeRedTeam }
if ($MODE -ceq 'roadmap-table') { Invoke-ModeRoadmapTable }
if ($MODE -ceq 'binding-driver') { Invoke-ModeBindingDriver }
if ($MODE -ceq 'monitoring') { Invoke-ModeMonitoring }
if ($MODE -ceq 'deliverable') { Invoke-ModeDeliverable }
if ($MODE -ceq 'assumption-rows') { Invoke-ModeAssumptionRows }
if ($MODE -ceq 'claim-drift') { Invoke-ModeClaimDrift }
Invoke-ModeCheck
