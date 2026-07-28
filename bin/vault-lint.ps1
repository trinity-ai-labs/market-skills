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
#   9. Invoke-ModeCheck              check                                  3003-3629
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
# keeps five separate copies of one six-line fenced-block scan for exactly that
# reason (bin/vault-lint.sh:1283-1285), and this file inherits the rule.
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
	Exit-NotPorted '--release-gate'
}

# ----------------------------------------------------------------------------
# 2. graph - the neighbourhood of one note, as text
#
# Ports bin/vault-lint.sh:889-1018. Takes a note ID operand and refuses --json;
# both are already handled in the argument parser below.
# ----------------------------------------------------------------------------
function Invoke-ModeGraph {
	Exit-NotPorted 'graph'
}

# ----------------------------------------------------------------------------
# 3. --unverified - the notes asserted with nothing behind them
#
# Ports bin/vault-lint.sh:1019-1128. Carries its OWN JSON escaper, one of three
# deliberate copies (bin/vault-lint.sh:1660) - transcribe that copy rather than
# routing through Render-Failures, and change all three together or none.
# ----------------------------------------------------------------------------
function Invoke-ModeUnverified {
	Exit-NotPorted '--unverified'
}

# ----------------------------------------------------------------------------
# 4. --supersession-sweep - the re-read worklist a supersession owes
#
# Ports bin/vault-lint.sh:1129-1605. Carries the third copy of the escaper, and
# exits above the shared render block for the reason stated there.
# ----------------------------------------------------------------------------
function Invoke-ModeSupersessionSweep {
	Exit-NotPorted '--supersession-sweep'
}

# ----------------------------------------------------------------------------
# 5. --used-in - every used_in target resolves
#
# Ports bin/vault-lint.sh:1709-1942. Renders through Render-Failures with a
# deliberately non-default ok line (bin/vault-lint.sh:1646).
# ----------------------------------------------------------------------------
function Invoke-ModeUsedIn {
	Exit-NotPorted '--used-in'
}

# ----------------------------------------------------------------------------
# 6. --red-team - the panel record against itself
#
# Ports bin/vault-lint.sh:1943-2120. Shares --used-in's failure renderer
# (bin/vault-lint.sh:1962), which is why the two are ported together.
# ----------------------------------------------------------------------------
function Invoke-ModeRedTeam {
	Exit-NotPorted '--red-team'
}

# ----------------------------------------------------------------------------
# 7. --roadmap-table - the roadmap table against the milestone set
#
# Ports bin/vault-lint.sh:2121-2410. Reads only the FIRST table under the
# roadmap heading, and stays silent at schemaVersion 1.
# ----------------------------------------------------------------------------
function Invoke-ModeRoadmapTable {
	Exit-NotPorted '--roadmap-table'
}

# ----------------------------------------------------------------------------
# 8. --binding-driver - verdict drivers and the evidence under them
#
# Ports bin/vault-lint.sh:2411-3002. Every rule has a deliberate silent
# counterpart asserted beside it, and none of them is gated on schemaVersion -
# porting a check without its silent side turns a clean vault red.
# ----------------------------------------------------------------------------
function Invoke-ModeBindingDriver {
	Exit-NotPorted '--binding-driver'
}

# ----------------------------------------------------------------------------
# 9. check - pass 3, the note-level checks
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
# (bin/vault-lint.sh:2513-2517), and the shell keeps five separate copies of one
# fenced-block scan for the same reason (:1283-1285): a helper two modes want is
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

	# EDGE_FIELDS comes from the shared region and is deliberately wider than
	# vault.md's six edges. Consumed, never redeclared: two copies would let
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
$SUPPORTED_SCHEMA = '1 2'
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

# Every field whose block-list items name other notes. DELIBERATELY wider than
# vault.md's six edges: `covers` is a question field and `assumptions_low` and
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
$EDGE_FIELDS = 'rests_on supersedes scopes validated_by depends_on moves covers assumptions_low option_evidence'

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
	foreach ($entry in (Get-ChildItem -LiteralPath $dirPath -Recurse -File -Force -ErrorAction SilentlyContinue)) {
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
# A trailing CR is NOT stripped here, and that is a transcription rather than an
# oversight: the shell's awk does not strip it either, so a CRLF _vocab.yml
# fails the term-key pattern identically on both implementations.
# ----------------------------------------------------------------------------

if ($HAS_VOCAB -eq 1 -and $MODE -ceq 'check') {
	$vocabOrder = New-Object 'System.Collections.Generic.List[string]'
	$vocabRequired = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$term = ''
	$field = ''

	foreach ($line in (Read-TextLines $VOCAB)) {
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
# That is `check`, --used-in, --red-team, --roadmap-table and --binding-driver
# today, and a mode joins the list by being dispatched below this point rather
# than by registering anywhere - which is why this comment names them and the
# code does not.
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
	foreach ($entry in (Get-ChildItem -LiteralPath $VAULT -Recurse -Force -ErrorAction SilentlyContinue)) {
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
	# culture-aware default: all five modes that render through here inherit the
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
Invoke-ModeCheck
