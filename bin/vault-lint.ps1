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
function Get-PathPrefix {
	param([string]$Directory)
	$resolved = Resolve-Path -LiteralPath $Directory -ErrorAction SilentlyContinue
	if ($null -eq $resolved) { return '' }
	$full = $resolved.ProviderPath
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
# usage and refusals
#
# Transcribed verbatim from bin/vault-lint.sh's usage() heredoc. The two texts
# are held together by `vault-lint.ps1 --help` against `vault-lint.sh --help`,
# and by the fixture suite's --help census assertion, which runs against
# whichever implementation VAULT_LINT names - so a paragraph added on one side
# and not the other is a mode with a working flag and no help text, which reads
# to its author exactly like a mode that was never added.
#
# ONE BLOCK PER MODE, IN MODE_TABLE ORDER, AND A NEW MODE APPENDS ITS BLOCK
# IMMEDIATELY BEFORE THE `graph` ONE - the same rule bin/vault-lint.sh:71 states,
# for the same reason: interleaving turns a release that adds three modes into
# three edits to the same lines, and git merges two of them textually clean.
#
# THE SYNOPSIS LINES SAY `vault-lint.sh` EVEN HERE, AND THAT IS NOT RIGHT YET.
# A session running this file has no `vault-lint.sh` to run - that is the whole
# reason this file exists - so the help it prints names a command its reader
# does not have. It stays that way for now because
# scripts/fixtures/run-fixtures.sh:838 asserts the census by matching the
# literal string `vault-lint.sh <mode>` against whatever VAULT_LINT points at,
# so renaming the blocks here fails nine assertions on the port and zero on the
# shell. Fixing it is one edit to that assertion plus one substitution here, and
# it belongs in the slice that owns the fixture suite - not in a slice that is
# forbidden to touch it.
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

