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

