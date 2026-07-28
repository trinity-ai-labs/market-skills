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
	$RX_BD_HEADING = [regex]'\A#+[ \t]+'
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
	# A SECTION ENDS AT THE NEXT HEADING OF ANY DEPTH, which is looser than the
	# rule --roadmap-table readplan() uses (next heading of the same depth or
	# shallower). Nothing in plan-template.md puts a subsection under the verdict
	# anchor, so the two agree today; if one is ever added, the phrase a reader
	# sees inside that subsection is outside the body this reads and the
	# condition check would cry wolf. That is the trigger to adopt readplan()
	# depth rule here.
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
	# THE ROW PARSER IS THE SECOND COPY of the one in --roadmap-table readplan():
	# strip the outer pipes, split on `|`, spot the all-dashes alignment rule,
	# treat everything above it as header and read the header for which column
	# matters. Both carry the rule that a table with NO alignment rule is not a
	# table to any renderer, so its rows are not rows. Change one, change both.
	#
	# The fence tracking is the FIFTH copy in the shell - --used-in scan(),
	# --supersession-sweep sections(), --red-team and --roadmap-table readplan()
	# carry the same six lines, because each reads a document at the vault root.
	# THIS COPY STAYS LOCAL TO THIS BODY: the other four belong to other mode
	# bodies, and hoisting one out is the cross-slice edit the stub seam exists
	# to prevent. A `#` or a `|` inside a fenced block is an example rather than
	# an assertion the document makes, which is also why fenced lines never reach
	# BODY: a fenced template carrying a condition would otherwise satisfy the
	# check for a section that renders nothing. Change one, change all five.
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
		$wanttable = $false

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
				$wanttable = ((Test-BdEqual $Doc $TABLEDOC) -and ((Test-BdEqual $exFold $TABLEKEY) -or (Test-BdEqual $hFold $TABLEKEY)))
				$hdr = ''
				$intable = 0
				continue
			}

			if ($ord -eq 0) { continue }
			# A blank line closes a table to every renderer, so it closes one
			# here - otherwise two tables separated by a paragraph read as one
			# and the rows of the second land under the header of the first.
			if ($t.Length -eq 0) { $hdr = ''; $intable = 0; continue }

			$kk = $Doc + $SUB + $ord
			$BODY[$kk] = (Get-BdBody $kk) + $t + "`n"
			if ([int]$t[0] -ne 124) { $hdr = ''; $intable = 0; continue }
			if (-not $wanttable) { continue }

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
	if ($VN.Count -eq 0 -and $tvord -eq 0) {
		if ($script:HAS_PLAN -eq 1) {
			$bdOk = 'no verdict note and no section at the {#target-verdict} anchor of business-plan.md - there is no verdict on either side, which is every vault before a target has one - ' + $script:VAULT
		} else {
			$bdOk = 'no verdict note and no business-plan.md at the vault root - there is no verdict on either side, which is every vault before a target has one - ' + $script:VAULT
		}
	} else {
		$np = 's'
		if ($VN.Count -eq 1) { $np = '' }
		$rp = 's'
		if ($nrow -eq 1) { $rp = '' }
		$bdOk = [string]$VN.Count + ' verdict note' + $np + ' against ' + [string]$nrow + ' corner verdict row' + $rp + ' under the {#target-verdict} anchor, matched verbatim - ' + $script:VAULT
	}

	exit (Render-Failures 'vault-lint binding-driver' $bdOk)
}

# ----------------------------------------------------------------------------
# 9. check - pass 3, the note-level checks
#
# Ports bin/vault-lint.sh:3003-3629. The largest body in the file, gated on
# schemaVersion throughout, and the mode a bare invocation runs.
# ----------------------------------------------------------------------------
function Invoke-ModeCheck {
	Exit-NotPorted 'check'
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
