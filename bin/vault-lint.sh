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

      The key is the note `title`, matched VERBATIM, the same rule
      --roadmap-table holds a milestone title to and for the same reason: the
      table renders the row off the note - `value` and its confidence where
      that note is an `assumption`, the sourced figure where it is a `claim` -
      so a correct table matches character for character by construction and a
      mismatch means the row was written by hand.

      A ROW IS BACKED BY A LIVE NOTE, AND WHICH ONES COUNT IS DECIDED BY
      `status` RATHER THAN BY WHICH ASSERTING SET HOLDS THE NOTE. An
      `assumption` and a `claim` both back a row; a `superseded` or
      `retracted` note of either type does not. THAT PAIR IS THE WHOLE SET,
      and the other five types are out by argument rather than by omission - a
      `source` and a `fact` are provenance a claim rests ON rather than a
      value the projection carries, and a `milestone`, `question` or
      `decision` asserts no value at all. Reading `assumption` alone made this
      fail a row this method's own promotion rule produces - a structural
      driver with no subject instrument belongs in the indexed set, so filing
      a sourced figure as an unevidenced assumption is the defect, and
      correcting it retires the assumption and mints a `claim` carrying the
      same title. Only the note-side direction is about assumptions
      specifically, because `model_input` is a field a promoted claim does not
      carry.

      assumption-not-in-model: a LIVE note carrying `model_input` whose title
      is no row in the table and which carries no `excluded_from_model`
      reason. The trigger is the FIELD, not the version - `model_input` is a
      term this release introduces, so no existing note carries it and no
      exemption has to be bought for one.

      A RETIRED NOTE OWES NEITHER A ROW NOR AN EXCLUSION, the same live
      predicate the row side reads. Demanding one of a `superseded` or
      `retracted` note cannot be satisfied: the escapes are to render the dead
      title as a row - undoing the repair the row side just asked for - or to
      write `excluded_from_model` onto a corpse, which records a decision
      about a live revenue line on a note nobody will open. The failure calls
      it "an input the ledger holds", and a note the ledger has retired is not
      one. excluded-line-on-roadmap reads the same narrowed set, so a retired
      note a `milestone` still `moves` is silent here too - that is a roadmap
      pointing at a dead note, a different repair this mode should not be
      giving.

      model-row-no-assumption: a row matching no `assumption` or `claim` note
      title at all. The reverse direction, and it is what stops the rule above
      being cleared by writing a row nothing in the ledger stands behind. The
      name is narrower than the rule because the repair is not: what this row
      is missing is the assumption note the table renders inputs off.

      model-row-dead-assumption: a row whose EVERY title match is at
      `status: superseded` or `retracted`. The title match says the row was
      rendered off SOME note; it does not say the ledger still stands behind
      it. A live row backed only by a retired note is an input the projection
      rests on that nothing orders in the validation queue, and the match reads
      as clean - observed as exactly that, a live assumption row backed only by
      a superseded note with the mode reporting `matched verbatim` for days. A
      live `claim` carrying the title clears it, which is what makes a
      promotion pass rather than read as a defect. It is separate from
      model-row-no-assumption because the repair is: point the row at the
      successor, or re-file the note.

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

      THE SUCCESS LINE PRINTS TWO COUNTS AND THEY NEED NOT AGREE. A row backed
      by a `claim` is not a declared model input, and a declared input cleared
      by `excluded_from_model` is not a row - so the line states what each half
      checked instead of reading as a comparison whose two sides have to match.

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

  vault-lint.sh --citation-codes [--vault PATH] [--json]
      Check that every [F#] and [S#] a document cites resolves to a row in
      the index that assigns that code. A verdict - it exits 1 on either of
      its two failures.

      The resolution contract is already written down: [S#] resolves through
      sources.md at the vault root and [F#] through
      research/founder-brief.md. Nothing enforced it. --used-in opens a
      NOTE's citation target; a code in prose is a different address and no
      check opened it, so a plan could cite a code that resolves to nothing
      and clear --release-gate. A dead code is indistinguishable from a
      working one in the rendered document, and the reader who follows it is
      the one person who cannot check it.

      citation-code-no-source-row: an [S#] with no row in sources.md.
      citation-code-no-fact-row: an [F#] with no row in
      research/founder-brief.md. Two codes rather than one because the two
      repairs open different files.

      THE TWO INDEX FILES ARE NOT SCANNED, and that is load-bearing rather
      than an optimisation. An index legitimately discusses its own retired
      numbers - a row recording that a code was withdrawn and deliberately
      left unused names that code - and a scan that read those mentions as
      citations would fail a corpus doing exactly the right thing.

      FORWARD DIRECTION ONLY. Cited with no row is the failure; a row nothing
      cites is not. A recorded fact nothing leans on yet is a healthy state,
      and failing it would push an author toward citing things to silence a
      linter.

      WHAT IT DOES NOT CHECK, AND THE SUCCESS LINE SAYS SO: whether a code
      resolves to the INTENDED source. Resolution is necessary and it is not
      sufficient. A research file legitimately carries its own local S table,
      so a document citing a local code the global log also assigns resolves
      to a row and to a DIFFERENT source - observed on four documents at
      once, every code resolving. --unflattened-source closes the half of
      that a check can reach.

      A missing index file is reported as a half that did not run rather than
      as agreement, the convention --claim-drift uses for a schemaVersion it
      does not apply to.

  vault-lint.sh --unflattened-source [--vault PATH] [--json]
      Check that every row of a research file's own local source table names
      a URL the root sources.md also names. A verdict - it exits 1 on its one
      failure.

      source-unflattened: a local `| S<n> |` row whose URL appears nowhere in
      sources.md. The global log is what assigns a citable [S#], so a source
      that exists only in a research file's local table can be cited from
      research prose and cannot be cited from a plan document at all. It is
      invisible to every other check: the local table is well-formed, the log
      is well-formed, and nothing compared them. Observed: a source lived
      only as one research file's local S14, global [S14] was a DIFFERENT
      source, and four documents cited [S14] meaning the local one.

      THE NAME IS NOT `orphan-source`, which `check` already reports and
      which means close to the opposite - a source note nothing in the vault
      rests on. That one is a source nobody cited; this one is a source
      nobody CAN cite.

      IT READS A DECLARED EXEMPTION OUT OF sources.md'S OWN HEADER, and
      without one the mode is unusable. A corpus may deliberately keep a
      large per-row ledger out of the global log - a per-profile table of a
      hundred rows or more, cited with a qualified suffix - and reporting
      every one of those as a failure is how a check gets switched off. A
      line in the header, before the log's first table row, of the form

          Local ledger: research/<file>.md - why it stays local

      exempts that file. The first whitespace-delimited token after the colon
      is the vault-relative path this mode reads; everything after it is the
      reason, for the person who has to decide whether it still holds. The
      declaration lives in the log rather than in the research file because
      the log is where a corpus states which sources it assigns codes to.

      A row carrying NO URL is neither resolved nor failed - there is no key
      to match it on - and the success line reports how many there were, so a
      table of unlinkable rows cannot read as a table that agreed.

      A missing sources.md is reported as a mode that did not run rather than
      as agreement, the same convention --citation-codes uses.
  vault-lint.sh --subject-orphan [--vault PATH] [--json]
      Check every vocabulary subject with no note filed under it against
      whether the corpus reasons about it anyway. A verdict - it exits 1 on
      its one failure.

      coverage-gap asks this of `required: true` subjects and stops there. A
      subject that is optional IN GENERAL can be load-bearing in a PARTICULAR
      plan, and nothing sees that: the plan argues from it, no note is ever
      filed, and the ledger has nothing to say. A subject with no note cannot
      collide with a contradiction, cannot go stale, cannot be superseded and
      cannot be challenged - every query the ledger supports returns clean over
      it, because there is nothing filed to return. Silent in every direction
      is what makes it a different failure from an ordinary coverage gap, and
      why widening coverage-gap would send its reader to the wrong repair.

      subject-orphan: a term in _vocab.yml NOT marked `required: true`, with no
      `claim` and no `assumption` carrying it as `subject`, WHERE the term or
      one of its `aliases` appears in a markdown document under the vault on a
      line that is not a `subject:` line. The message names the subject, the
      document, the line number and the line itself, because the repair is
      writing one note and the only hard part is knowing which one.

      THE FAILURE IS ATTACHED TO THE DOCUMENT CARRYING THE MENTION, not to
      _vocab.yml where coverage-gap attaches. That check has nothing to show a
      reader; here the mention is the evidence, so the file column names a path
      worth opening.

      THE TWO MODES PARTITION THE VOCABULARY rather than overlapping on it. A
      `required: true` subject owes a note whether or not any document mentions
      it, so a mention adds nothing to a repair coverage-gap already demands -
      and one omission reported as two failures under two names sends its reader
      looking for two.

      THE MENTION IS THE WHOLE TRIGGER, and it is what stops this from being
      coverage-gap over every optional term. A vault that legitimately has
      nothing to say about a subject never mentions it and stays silent here;
      one that argues from a subject it never filed is the state this exists to
      surface.

      A MENTION IS MATCHED ON WORD BOUNDARIES, not as a substring. Both sides
      are cut into lowercase alphanumeric tokens and the term`s tokens have to
      appear in the line as a consecutive run, so `price` matches `Price` and
      `price anchor` and never `priceless`. A substring rule fires on ordinary
      prose, and a check that cries wolf is one somebody switches off.

      _vocab.yml is not markdown and so is never scanned - by construction
      rather than by exclusion. Read, it would find every term inside its own
      definition and its own aliases list, and report every unfiled subject in
      the vault as one the corpus leans on.

      A NOTE FILED UNDER AN ALIAS SPELLING COUNTS AS FILED. The spelling is
      check`s near-miss-subject and has its own repair; reporting it here as
      well would tell a reader to write a note that already exists.

      IT DOES NOT READ `status`. A subject whose only note is `superseded` or
      `retracted` passes here, because a message saying no note is filed under
      it would be false - that is a supersession the sweep already reports,
      and reporting it under this name gives the wrong repair.

      THE ALIAS LIST IS THE SENSITIVITY DIAL, and a one-word alias is a broad
      one: `power` as an alias of `defensibility` fires on any sentence carrying
      the word. The repair for that is the alias rather than the check -
      _vocab.yml is the vault`s own file, curated per engagement, and dropping
      an alias that means something else in this corpus is what it is for.

      WHERE --binding-driver ALREADY REPORTS THE MISSING NOTE, this reports it
      too. A plan rendering a verdict section with no note behind it fails
      verdict-unfiled there and subject-orphan here, and both name the same
      repair - which is redundancy rather than a reader sent to the wrong fix,
      and cheaper than teaching one general mode the name of one subject.

      NOT gated on schemaVersion, and there is nothing to gate it on: the rule
      reads no field a corpus written before it lacks. A vault carrying the gap
      goes red on the version that adds this, and that is the intent - a corpus
      reasoning about a subject it has never filed is exactly the state the
      mode exists to surface, and a vacuous pass is worse than a red gate.

  vault-lint.sh --foreclosed [--vault PATH] [--json]
      List every live note that takes an option off the table, with the
      section its used_in names, and fail one that never says what would put
      the option back. A verdict - it exits 1 on its one failure.

      A note asserting that an option is not viable removes work from the
      roadmap, kills a segment, or takes a configuration off the table. It is
      the highest-consequence class of assertion in a plan and the only one
      nothing attacks: all three panel lenses ask whether the plan can deliver
      what it promises, and none asks whether it wrongly concluded it could
      not. The failure is silent BY CONSTRUCTION - the option is gone, so
      nothing downstream references it, so no other check has a target to fire
      on, and the conclusion is read as settled ground by the founder, by the
      panel and by whoever acts on the plan.

      foreclosure-no-reverse: a `current` note carrying `forecloses` and no
      `reverses_if`. The same shape as an `assumption` carrying no
      `validated_by`, one field over - the assumption owes the step that would
      settle it, and the foreclosure owes the value of `foreclosed_on` that
      would put the option back on the table. Without it the conclusion is
      permanent, and nothing in the corpus records what it was conditional on.


      foreclosed-on-dangling: a note carrying `forecloses` whose
      `foreclosed_on` names an ID no note in this vault carries. The
      conclusion names the input it rests on and that input cannot be opened,
      so nothing can be re-read to overturn it. It is also the brief the
      floor skeptic is dispatched with, so a dangling target sends the one
      lens pointed at this conclusion to a note that does not exist - and a
      lens that found nothing reads exactly like a foreclosure that survived
      being attacked. `check`s dangling-edge rule walks the block-list edge
      fields and never this scalar, so nothing else reports it, which is the
      gap `superseded_by` has and answers the same way.
      IT READS `claim` ONLY, and --subject-orphan's closed pair does not
      transfer. That rule asks which types FILE a position; these three fields
      are claim-only by ARGUMENT - a foreclosure is a conclusion drawn from an
      input, `foreclosed_on` is where that input is named, and a note resting
      on nothing has no input to name. An option taken off the table by an
      `assumption` is not a foreclosure missing a field; it is an assumption
      in the shape of a finding, and the repair is to file the `question` the
      plan stopped asking. Reading both types here would give that reader the
      WRONG REPAIR under the right name - add `reverses_if`, and the category
      error ships dressed in three fields and green. `check` reports it
      instead, under foreclosure-on-assumption, which names the question.

      IT READS `status`, AND A RETIRED FORECLOSURE OWES NOTHING. A `superseded`
      or `retracted` note has already been taken back, so demanding a reversal
      condition of it names a repair on a corpse - the supersession IS the
      repair, and --supersession-sweep is what reports the sections it put in
      doubt.

      NOT gated on schemaVersion, and it does not need to be: the trigger is
      the PRESENCE of `forecloses`, so a corpus that never wrote the field
      cannot owe anything here. That is the exemption a version buys, obtained
      without spending one - the terms `superseded_by`'s two rules are on.

      A vault where nothing forecloses is reported as a mode with nothing to
      run over rather than as agreement, the convention --citation-codes and
      --unflattened-source use for a half that did not run.

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
--monitoring         gate  monitoring axes and the decision each would change
--deliverable        gate  what the rendered deliverable carries out of the vault
--assumption-rows    gate  assumption rows against the model table
--claim-drift        gate  cited sections against their recorded hash
--citation-codes     gate  citation codes against their index rows
--unflattened-source gate  local source rows against the global log
--subject-orphan     gate  unfiled subjects the corpus reasons about
--foreclosed         gate  foreclosed options and what would reverse them
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
#
# 4 joins the set for ONE rule - the `market-size` nesting check in `check`. A
# plan that sized properly already carries several current population claims
# under that subject, a behavioural cut inside a professional population inside
# a broader one, and none of them is wrong. Ungated, the rule would turn every
# corpus that did the work red on the day the plugin updates, for a reason
# having nothing to do with what changed - which is the shape that makes people
# stop upgrading, so the rule would be correct and unusable. A version is
# exactly what that exemption costs, and vault-migration.md carries the 3 -> 4
# back-fill. The fields --foreclosed reads are deliberately NOT behind it: that
# mode fires on the PRESENCE of `forecloses`, so a corpus written before the
# field cannot owe it, and a version spent over an empty population buys
# nothing.
SUPPORTED_SCHEMA="1 2 3 4"
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
#
# `nested_in` is here on exactly those terms, and ungated for `depends_on`'s
# reason - no corpus written before the field carries it, so listing it costs
# nothing at any version. What it buys is the difference between the two ways a
# population claim can be missing its ring: population-unnested resolves the
# edge through BYID, so a MISTYPED `nested_in` links nothing and would read as
# an edge nobody wrote, which is a different repair. Listed here, the typo is a
# dangling-edge failure under its own name, and `graph` shows which population
# a claim sits inside instead of stopping at it.
EDGE_FIELDS="rests_on supersedes scopes validated_by depends_on moves covers assumptions_low option_evidence arr_excludes nested_in"

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
# Only `check` and --subject-orphan consume T and A records - graph and
# --unverified match N, S and L alone - so the pass is skipped entirely for the
# rest rather than parsed into output nobody reads. --subject-orphan needs both
# record types: T is the set of subjects it asks after, and A is half of what
# says the corpus is leaning on one.
# ----------------------------------------------------------------------------

if [ "$HAS_VOCAB" -eq 1 ] && { [ "$MODE" = "check" ] || [ "$MODE" = "subject-orphan" ]; }; then
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
# THE SUPERSEDED SET IS EVERY ADDRESS OF THE SAME FACT: every note named by a
# `supersedes` edge, every note carrying `status: superseded`, and every note
# carrying `superseded_by`. Taking any subset would make the worklist depend on
# the supersession being well-formed - and a half-made supersession is exactly
# the vault where the worklist matters most, because `check` has already found
# something wrong with the pair and the documents downstream still say the old
# thing.
#
# A HALF-WRITTEN EDGE IS A FAILURE, AND A DIFFERENT ONE FROM REPLACED-BY-NOTHING.
# `superseded_by` names the successor from the replaced note's own side, and
# nothing here read it, so a successor that never wrote the matching `supersedes`
# left the pair invisible from both directions - printed as replaced by nothing
# at all, which sends its reader to decide what replaced this instead of to add
# one line to a note the record already names. See the END pass for what that
# cost on a live corpus.
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
			printf DQ "supersedes_reason" DQ ": " DQ "%s" DQ ", ", jesc(sb[2])
			printf DQ "declared_superseded_by" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "superseded_by"])
			printf DQ "edge_state" DQ ": " DQ "%s" DQ "}", jesc(estate(f, sb[1]))
		}

		# Which end of the supersession edge this note is actually reachable
		# from. `superseded_by` is the field a reader writes on the note being
		# replaced, and until now nothing read it - so a note whose successor
		# never wrote the matching `supersedes` was reported as replaced by
		# nothing at all, which is a different repair from the one it needs.
		#   confirmed      - the successor names it back; the edge is whole
		#   unreciprocated - `superseded_by` names a note in this vault that
		#                    does not name it back
		#   dangling       - `superseded_by` names an ID no note carries
		#   absent         - the field is not there
		#
		# SBYST DECIDES WHEREVER THE FIELD IS PRESENT, and s1 only where it is
		# not. Reading s1 first would report `edge_state: confirmed` on a note
		# some OTHER note supersedes while its own `superseded_by` is broken -
		# so the one field whose job is to say which end is reachable would call
		# the edge whole in the same document that lists it under broken_edges.
		# Two call sites, jnote() and tnote(), and the walk that fills SBYST
		# runs once per note in END.
		function estate(f, s1) {
			if (f in SBYST) return SBYST[f]
			return (s1 != "" ? "confirmed" : "absent")
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
		# The fence tracking is one of eight copies in this file - --used-in
		# scans headings under the same rule, and so do --red-team,
		# --roadmap-table, --binding-driver, --monitoring, --claim-drift and the
		# shared $DOC_SCAN_AWK that --citation-codes and --unflattened-source
		# both concatenate. All eight are the same six lines: a `#` inside a
		# fenced block is an example rather than a section anyone can jump to,
		# and the marker and run length are tracked so a longer nested fence
		# cannot close its parent early. Change one, change all eight.
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
		function tnote(f, b, pad,   sb, st) {
			split(SB[f, b], sb, SUBSEP)
			printf "%s%s  %s\n", pad, V[f, "id"], V[f, "type"]
			printf "%s  %s\n", pad, V[f, "title"]
			st = estate(f, sb[1])
			if (st == "confirmed") {
				printf "%s  superseded by %s\n", pad, sb[1]
				printf "%s  reason: %s\n", pad, (sb[2] == "" ? "(none recorded - `supersedes_reason` is absent, so why it was replaced is already gone)" : sb[2])
			}
			# A HALF-WRITTEN EDGE IS NOT REPLACED BY NOTHING, and printing it as
			# though it were is what sent a reader looking for a successor the
			# note already names. The successor is named HERE, where the reader
			# of this row is; why the edge is broken and what to do about it is
			# one paragraph in the half-written section below, rather than a
			# second wording of the same finding on every row it reached.
			else if (st == "unreciprocated" || st == "dangling")
				printf "%s  superseded by %s on its own `superseded_by` only - see the half-written edges below\n", pad, V[f, "superseded_by"]
			else
				printf "%s  superseded by: nothing - `status: superseded` with no note naming it in `supersedes`, so the record says this was replaced and not by what\n", pad
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

			# THE SUPERSESSION HAS TWO ENDS AND ONLY ONE OF THEM WAS EVER READ.
			# Half one above walks `supersedes`, which lives on the SUPERSEDING
			# note. A note carrying `superseded_by` whose named successor never
			# wrote the matching `supersedes` was therefore invisible from both
			# sides at once: half one never reached it, and half two prints it
			# under `superseded by: nothing`, which says the record does not name
			# a replacement when in fact it names one and the other end is
			# missing. Those are different repairs - one line on a named note
			# versus a decision about what replaced this - and reporting the
			# first as the second is what let it sit.
			#
			# Observed: an assumption backing a live row in a financial model
			# carried `superseded_by` naming a claim that never named it back.
			# The sweep reported it as replaced by nothing, and three current
			# claims went on resting on the dead note - one of them the single
			# strongest negative in that corpus - because nothing could see that
			# the edge existed and was half written.
			#
			# RECIPROCITY IS READ OFF SB, THE INDEX HALF ONE JUST BUILT, rather
			# than by re-walking the successor `supersedes` list. That is why
			# this pass sits here and not above: one definition of "that note
			# names this one" means the row a broken edge reports and the row
			# the worklist prints cannot disagree about the same pair. A second
			# walk would also be a third place the `:: label` rule has to be
			# applied the same way, held together by nothing but a comment.
			#
			# NOT GATED ON schemaVersion, and it does not need to be: it fires
			# only on the PRESENCE of `superseded_by`, so a corpus that never
			# wrote the field cannot owe it and no vault reddens on the day the
			# plugin updates. That is the exemption schemaVersion exists to buy,
			# obtained here without spending a version.
			#
			# A DANGLING `superseded_by` IS A SEPARATE ROW rather than folded in
			# with the unreciprocated one. The block-list dangling-edge check in
			# `check` walks the edge FIELDS and never this scalar, so nothing
			# else in the tool reports it - and the repair differs again: there
			# is no note to add the back-edge to, so either the successor was
			# never written or the ID is a typo.
			for (i = 1; i <= nf; i++) {
				f = files[i]
				sby = V[f, "superseded_by"]
				if (sby == "") continue
				SBYST[f] = (sby in BYID) ? "unreciprocated" : "dangling"
				for (b = 1; b <= SN[f]; b++) {
					split(SB[f, b], sbp, SUBSEP)
					if (sbp[1] == sby) { SBYST[f] = "confirmed"; break }
				}
				if (SBYST[f] == "confirmed") continue
				BROKE[++nb] = f
				if (SBYST[f] == "unreciprocated")
					BWHY[f] = "`superseded_by: " sby "` names a note this vault holds, and `supersedes` on " sby " does not name " V[f, "id"] " back. The worklist is built from the superseding side, because that is where the reason and the `reconciled:` date live - so a supersession written from this end only reaches nothing: this note reads as replaced by nothing at all, and the sections it was cited into are never named for re-reading. Add " V[f, "id"] " to `supersedes` on " sby ", with the `supersedes_reason` that pair owes"
				else
					BWHY[f] = "`superseded_by: " sby "` and no note in this vault carries that ID. The record says this note was replaced and names a successor nobody can open, so there is nothing to read the replacement out of and nothing to add the back-edge to - either the successor was never written, or the ID is a typo. The dangling-edge check walks the block-list edge fields and never this scalar, so nothing else in this tool reports it"
			}

			# Half two, and the ordering pass for both. Iterating files[] rather
			# than the edge walk above is what makes the output order the vault
			# order instead of awk hash order, so two runs over an unchanged
			# vault produce the same worklist.
			#
			# `superseded_by` is the THIRD address of the same fact, and it joins
			# the set for the reason the other two are both here: the worklist
			# must not depend on the supersession being well-formed. A note that
			# records its own replacement and never got its `status` flipped is
			# exactly the half-made pair whose cited sections still assert the
			# old value, and taking only the other two halves would leave those
			# sections unnamed.
			for (i = 1; i <= nf; i++) {
				f = files[i]
				if (V[f, "id"] == "") continue
				if (SN[f] == 0 && V[f, "status"] != "superseded" && V[f, "superseded_by"] == "") continue
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
				printf "  " DQ "ok" DQ ": %s,\n", (nu == 0 && nb == 0 ? "true" : "false")
				printf "  " DQ "vault" DQ ": " DQ "%s" DQ ",\n", jesc(vault)
				printf "  " DQ "worklist_count" DQ ": %d,\n", nt
				printf "  " DQ "superseded_count" DQ ": %d,\n", nsup
				printf "  " DQ "unreconciled_count" DQ ": %d,\n", nu
				printf "  " DQ "broken_edge_count" DQ ": %d,\n", nb
				printf "  " DQ "broken_edges" DQ ": ["
				for (i = 1; i <= nb; i++) {
					f = BROKE[i]
					printf "%s\n    {", (i == 1 ? "" : ",")
					printf DQ "id" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "id"])
					printf DQ "file" DQ ": " DQ "%s" DQ ", ", jesc(f)
					printf DQ "type" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "type"])
					printf DQ "title" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "title"])
					printf DQ "check" DQ ": " DQ "%s" DQ ", ", jesc("superseded-by-" SBYST[f])
					printf DQ "superseded_by" DQ ": " DQ "%s" DQ ", ", jesc(V[f, "superseded_by"])
					printf DQ "detail" DQ ": " DQ "%s" DQ "}", jesc(BWHY[f])
				}
				printf "%s],\n", (nb == 0 ? "" : "\n  ")
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
				exit (nu == 0 && nb == 0 ? 0 : 1)
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

			# The half-written edges print above the reconciliation verdict and
			# ABOVE the schemaVersion gate below, because this one is not gated:
			# it fires on the presence of `superseded_by`, so a vault at 1 that
			# writes the field owes the same answer as one at 3.
			printf "\n  supersessions the record only half made - `superseded_by` names a successor that does not name it back\n"
			if (nb == 0) printf "    (none)\n"
			for (i = 1; i <= nb; i++) {
				f = BROKE[i]
				printf "    %s  %s  superseded-by-%s\n", V[f, "id"], V[f, "type"], SBYST[f]
				printf "      %s\n", V[f, "title"]
				printf "      superseded_by %s\n", V[f, "superseded_by"]
				printf "      %s\n", BWHY[f]
			}
			# The verdict prints last, because it is the half a reader acts on
			# and the worklist above it can run to dozens of rows. At
			# schemaVersion 1 the section says the rule does not apply rather
			# than printing an empty list: an unconditional `(none)` here would
			# report a vault as reconciled when nothing about it was asked.
			#
			# A BRANCH RATHER THAN AN EARLY EXIT, so both summary lines below print
			# in one place. A vault at 1 can still carry a half-written edge, and a
			# summary skipped by an early return leaves its reader reconstructing
			# the verdict from the exit code.
			if (schema + 0 < 2)
				printf "\n  reconciliation is a schemaVersion 2 rule and this vault is at %s - the worklist above is a report here, and nothing was asked about whether it was read\n", schema
			else {
				printf "\n  supersessions with nothing recording that the worklist was read\n"
				if (nu == 0) printf "    (none)\n"
				for (i = 1; i <= nu; i++) {
					f = UNREC[i]
					printf "    %s  %s\n", V[f, "id"], V[f, "type"]
					printf "      %s\n", V[f, "title"]
					printf "      supersedes %s\n", UTGT[f]
					printf "      %s\n", UWHY[f]
				}
			}
			if (nb > 0)
				printf "\nvault-lint supersession-sweep: %d half-written supersession edge%s - the record names a successor and the successor does not name it back, under %s\n",
					nb, (nb == 1 ? "" : "s"), vault
			if (nu > 0)
				printf "\nvault-lint supersession-sweep: %d supersession%s with nothing recording that its sections were read, under %s\n",
					nu, (nu == 1 ? "" : "s"), vault
			exit (nu == 0 && nb == 0 ? 0 : 1)
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
# --roadmap-table, --binding-driver, --monitoring and --deliverable today, and a
# mode joins the list by being dispatched below this point rather than by
# registering anywhere - which is why this comment names them and the code does
# not. graph, --unverified and
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
# the one markdown table reader
#
# --roadmap-table and --assumption-rows read the same shape out of two
# documents: the item cells of the FIRST table under a named heading. They were
# two awk functions, readplan() and readmodel(), and readmodel()'s comment
# claimed to be readplan() "with two changes and no others" - a claim only an
# external check could hold, because awk has no way to share a function between
# two programs and this file had no way to share the SOURCE of one. This
# variable is that way: awk takes one program text, and two adjacent shell words
# concatenate into one argument, so `"$TABLE_READER_AWK"'...'` hands awk the
# reader followed by the mode's own program. The two modes now run the same
# bytes, which is a guarantee where a comment was a hazard: a fence rule, an
# alignment-row test or a heading-depth bound fixed in one reader and not the
# other used to ship silently - parity.mjs diffs .sh against .ps1 and never one
# reader against its own twin, and no fixture puts both readers over the same
# table.
#
# IT CARRIES ITS OWN trim() AND fold(), so a program gets the reader by
# concatenating this one variable and owes it nothing. They live here rather than
# in the host because the reader is now their ONLY caller in both modes - leaving
# them behind would have been two exact copies of each with nothing else reading
# them, which is the duplication this collapse exists to remove, one helper down.
# The cost is that a host program must NOT define trim() or fold() itself: awk
# rejects a duplicate function definition, and it rejects it at startup with the
# line number, so a third caller that already has its own finds out immediately
# rather than by printing a wrong answer.
#
# WHY THIS TECHNIQUE IS NOT APPLIED TO THE OTHER DUPLICATED HELPERS in this file.
# The fenced-block scan, target_of(), and the remaining trim()/fold() copies
# could all be shared the same way - concatenation is a general mechanism, and
# the "no awk program can call a function defined in another" those comments
# state is about calling, not about sharing source. They stay duplicated because
# nothing claims they correspond: each was written independently and no comment
# asserts one is a transcription of another, so there is no unheld claim to fail.
# The table readers were the one pair that made that claim, which is why they are
# the one pair collapsed. Reach for this variable when a helper starts asserting
# that it matches another - not merely because it resembles one.
#
# THE FOUR ARGUMENTS ARE THE WHOLE DIFFERENCE between the two callers:
#   path      the document to read
#   wanthead  the folded heading the read opens on: `roadmap`, `assumptions`
#   wantitem  the folded header cell that names the item column: `item`,
#             `assumption`
#   defcol    the column read when no header cell folds to wantitem. THIS IS THE
#             ONE THAT BITES. The roadmap's Rule 1 table puts its item in column
#             one, so one is right there; the assumptions template ships
#             `| # | Assumption | Value | Source | Confidence |`, where column one
#             is the `A-n` row label the plan cites in prose and a roadmap
#             `moves` field names - defaulting to it would report `1`, `2` and `3`
#             as three inputs that escaped the ledger on a table whose every row
#             resolves.
#
# It writes three globals the caller reads: SEEN (the heading was found at all,
# which is what tells "no such section" apart from "the section lists nothing"),
# and ROW[1..NROW] (the item cells). PEND is its own scratch.
#
# ONE CALL PER awk PROCESS. Those globals are never reset on entry, so a second
# call would read the first call's rows back out as its own. Both callers invoke
# it once, in their own awk process, which is what makes that safe; a mode that
# ever wants two tables resets SEEN, NROW and NPEND itself before the second call.
#
# THE HEADER ROW IS READ FOR NOTHING BUT WHICH COLUMN HOLDS THE ITEM, and the row
# directly above the alignment rule is that header. The rule is what separates
# header from body: counting instead would take the header as an item on a table
# written with two header lines, and the first real item as a header on a table
# written with none. A table with NO rule is not a table to any renderer - it
# renders as the literal pipes a reader sees - so its rows stay out of the body
# and the section reports as one that lists nothing.
#
# ONLY THE FIRST TABLE IS READ. A section legitimately carries a second one -
# roadmap-sequencing.md Rule 3 puts its permutation comparison under the roadmap
# heading, and that table's first column is an ORDER rather than an item - so
# reading every table would report each of those rows as an item that escaped the
# ledger. That is exactly the crying wolf this check was scoped out for once
# already.
#
# The section ends at the next heading of the same depth or shallower, so a
# subsection under it is still part of it.
#
# The read STOPS the moment the answer can no longer change - at the heading that
# closes the section, or at the line that ends the first table in it. SEEN makes
# the section unre-enterable and only the first table is read, so every line
# after either point is parsed and discarded. On a document written to the
# template that is the whole back half of it, on every call, including the ones
# folded into every --release-gate run.
#
# The fence tracking is the FOURTH copy in this file - --used-in scan(),
# --supersession-sweep sections() and --red-team carry the same six lines,
# --binding-driver readdoc(), --monitoring and --claim-drift carry the fifth, the
# sixth and the seventh, and the shared $DOC_SCAN_AWK below carries the eighth
# for the two modes that concatenate it, because each reads a document at the
# vault root. Collapsing the two table readers into this one removed one copy;
# the rest stay, so change one and change all eight. A `#` or a `|` inside a fenced block is an example rather than
# anything a reader can act on.
# ----------------------------------------------------------------------------

TABLE_READER_AWK='
			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# The fold every section-resolving mode in this file carries - it
			# answers which heading THIS section is, not whether an anchor
			# resolves, so it drops every character the slug rule drops without
			# having to know which those are. --supersession-sweep sections(),
			# --binding-driver readdoc() and --claim-drift carry the other three
			# copies. Change one, change all four.
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

			function readtable(path, wanthead, wantitem, defcol,   line, t, c, n, fc, fn, nh, h, ex, level, insect, intable, row, nc, cell, i, alldash, item, col, hdr, body) {
				fc = ""; fn = 0; nh = 0; level = 0
				insect = 0; intable = 0; col = defcol; hdr = ""; body = 0
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
						# The heading depth. The FIRST copy of this count -
						# --binding-driver readdoc() carries the second, and
						# both feed the same same-depth-or-shallower
						# boundary. Change one, change both.
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
						if (insect && nh <= level) break
						if (!SEEN && (fold(ex) == wanthead || fold(h) == wanthead)) {
							insect = 1; SEEN = 1; level = nh
						}
						continue
					}

					if (!insect) continue
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
								if (fold(cell[i]) == wantitem) { col = i; break }
						}
						body = 1
						continue
					}

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
'

# ----------------------------------------------------------------------------
# the fence scan two modes share, by the same mechanism the table reader uses
#
# --citation-codes and --unflattened-source both walk a document line by line
# looking for a token, and both have to ignore fenced blocks for the reason every
# other document-reading mode does: a corpus document that carries its own row
# template or its own citation example would otherwise fail for documenting its
# own format, which is exactly why --red-team skips fences over a red-team.md
# that ships a row template.
#
# ONE SOURCE RATHER THAN TWO COPIES, because the two modes are written together
# and neither has a reason to drift from the other. It is a shell variable for
# TABLE_READER_AWK's reason - awk takes one program text and two adjacent shell
# words concatenate into one argument - and it does NOT collapse any of the seven
# copies that already exist: those were each written independently and none
# claims to match another, which is the test AGENTS.md sets for collapsing one.
# It is the EIGHTH copy of the rule in this file, and every one of the other
# seven names it. That count was wrong before this mode existed - --claim-drift's
# section reader is a copy no enumeration had ever counted, so the census said
# six over seven - which is the failure a hand-maintained count has and the
# reason each site restates it rather than pointing at one place.
#
# THE STATE IS GLOBAL AND THE CALLER RESETS IT. FC and FN hold the open fence's
# marker character and run length across calls, so a caller that reads more than
# one document sets FC = "" before each file - a fence left open at the end of
# one document would otherwise swallow the whole of the next.
#
# IT ALSO CARRIES trim() AND firstcell(). Both modes read a source or fact code
# out of the first cell of a table row under identical rules, and the second body
# said so in its own comment - which is the claim, not the resemblance, that makes
# a duplicate worth collapsing: a change to how a cell may be spelled would
# otherwise land in one mode and leave the other reading a different set of rows.
# A host program gets all three by concatenating this one variable and must not
# define any of them itself: awk rejects a duplicate function definition at
# startup, which is what makes the collision loud.
DOC_SCAN_AWK='
			function trim(s) {
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			# 1 when this line opens or closes a fence, or sits inside one,
			# so a caller skips the line on a true answer. The marker
			# character and its run length are both tracked, which is what
			# stops a longer nested fence from closing its parent early.
			#
			# THE TWO MARKERS ARE BUILT FROM BYTE VALUES rather than written
			# as literals, which is the one difference from the seven copies
			# that sit inside an awk program argument. This one travels in a
			# shell variable, and a backtick inside a single-quoted
			# assignment is a shell diagnostic about a string the shell never
			# expands. 96 is the backtick and 126 the tilde, under the LC_ALL=C
			# every caller sets, where %c is the byte rather than the code
			# point. Three or more of either opens a fence, which is what the
			# literal comparison the other copies use tests.
			function fenced(t,   c, n) {
				if (BQ == "") { BQ = sprintf("%c", 96); TL = sprintf("%c", 126) }
				c = substr(t, 1, 1)
				if (c != BQ && c != TL) return (FC != "")
				n = 0
				while (substr(t, n + 1, 1) == c) n++
				if (n < 3) return (FC != "")
				if (FC == "") { FC = c; FN = n }
				else if (c == FC && n >= FN) { FC = ""; FN = 0 }
				return 1
			}

			# The first cell of a markdown table row, trimmed, with the
			# optional square brackets around a code stripped off. "" when the
			# line is not a table row at all - the same answer a row whose first
			# cell is empty gives, and both callers treat the two alike because
			# neither is a code.
			#
			# THE BRACKETS ARE OPTIONAL ON EITHER INDEX. The two documents write
			# the cell differently in the field - a founder brief writes the code
			# bare and a source log writes it bracketed - and holding each to its
			# own spelling alone would fail a document written in the other for a
			# difference no reader can see.
			function firstcell(t,   row, p) {
				if (substr(t, 1, 1) != "|") return ""
				row = substr(t, 2)
				p = index(row, "|")
				row = trim((p > 0) ? substr(row, 1, p - 1) : row)
				sub(/^\[/, "", row)
				sub(/\]$/, "", row)
				return row
			}
'

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
		# THAT FENCE BLOCK IS ONE OF EIGHT COPIES in this file. The
		# --supersession-sweep sections(), the --red-team row reader, the
		# shared readtable(), the --binding-driver readdoc(), --monitoring and
		# --claim-drift and the shared $DOC_SCAN_AWK carry the same six lines,
		# because all eight read a document at the vault root and no one of them
		# can call a function defined in another awk program. Change one, change
		# all eight.
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
				# One of eight copies of those six lines: the --used-in scan(),
				# the --supersession-sweep sections(), the shared readtable(),
				# the --binding-driver readdoc(), --monitoring, --claim-drift and
				# the shared $DOC_SCAN_AWK carry the same ones, for the same
				# reason - eight awk programs reading a document at the vault
				# root, and no way to share a function across them. Change one,
				# change all eight.
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
	#
	# $TABLE_READER_AWK is prepended to the program rather than transcribed into
	# it: --assumption-rows reads the same table shape one artifact over, and the
	# two adjacent shell words below concatenate into the single program text awk
	# takes. It brings readtable() and the trim() and fold() that reader calls, so
	# this program must not define either itself - awk rejects a duplicate.
	ROADMAP_OK=$(LC_ALL=C awk -v out="$FAILURES" -v plan="$PLAN" -v hasplan="$HAS_PLAN" -v vault="$VAULT" -v schema="$FOUND_SCHEMA" -F '\t' "$TABLE_READER_AWK"'
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

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

				# The shared reader, on the four arguments that make this
				# read the roadmap one: the roadmap heading, the `Item`
				# header cell, and column one, which is the shape the Rule 1
				# table is written in. It sets SEEN and ROW[1..NROW].
				if (hasplan == "1") readtable(plan, "roadmap", "item", 1)

				# The roadmap is in the ledger and nowhere a reader can see it.
				# Reported ONCE against the document rather than once per
				# milestone: the fix is one thing - render the section - and a
				# reader who is handed eight rows for one job stops reading.
				if (nm > 0 && NROW == 0) {
					if (hasplan != "1")
						report("business-plan.md", "roadmap-table-missing", "",
							"the vault carries " nm " milestone note" (nm == 1 ? "" : "s") " and there is no business-plan.md at the vault root. The roadmap is in the ledger and nowhere a reader can see it: every item is a dated change to an assumption row, so a plan that never renders them hands its reader a curve whose steps have no stated cause")
					else if (!SEEN)
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
			# A SECTION ENDS AT THE NEXT HEADING OF THE SAME DEPTH OR SHALLOWER,
			# which is the rule the shared readtable() uses, so a subsection
			# under a heading is still part of it. This used to end a section at
			# the next heading of ANY depth, on the reasoning that nothing in
			# plan-template.md puts a subsection under the verdict anchor - and
			# that comment named the arrival of one as the trigger to adopt the
			# depth rule. THE TRIGGER FIRED. A plan opened a `###` one line into
			# the body of the verdict anchor, which put the corner table outside the
			# body this reads: the mode found ZERO rows and printed `1 verdict
			# note against 0 corner verdict rows under the {#target-verdict}
			# anchor, matched verbatim` - a clean pass over a table it never
			# opened, for as long as the note had existed, with the whole
			# corner-row half of the mode silently disabled and the condition
			# check ready to cry wolf over any phrase written below that
			# subsection heading.
			#
			# A LINE THEREFORE REACHES EVERY OPEN ANCESTOR, which is what a
			# nested boundary means: SECT is a stack carrying one entry per
			# section still open, and a heading pops every entry at its own
			# depth or deeper before pushing its own.
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
			# THE ROW PARSER IS THE SECOND COPY of the one in the shared
			# readtable(): strip the outer pipes, split on `|`, spot the
			# all-dashes alignment rule, treat everything above it as header and
			# read the header for which column matters. Both carry the rule that
			# a table with NO alignment rule is not a table to any renderer, so
			# its rows are not rows. Change one, change both.
			#
			# The fence tracking is the FIFTH copy in this file - --used-in
			# scan(), --supersession-sweep sections(), --red-team, the shared
			# readtable(), --monitoring, --claim-drift and the shared
			# $DOC_SCAN_AWK carry the same six lines, because each reads a
			# document at the vault root and no one of them can call a function
			# defined in another awk program. A `#` or a `|` inside a
			# fenced block is an example rather than an assertion the document
			# makes, which is also why fenced lines never reach BODY: a fenced
			# template carrying a condition would otherwise satisfy the check
			# for a section that renders nothing. Change one, change all eight.
			function readdoc(doc,   path, line, t, c, n, fc, fn, ord, h, ex, row, nc, cell, i, si, nh, alldash, hdr, dcol, kcol, intable, SECT, SLEV, nsect, tpos, kk, dv, kv) {
				if (doc in SCANNED) return
				SCANNED[doc] = 1
				path = vault "/" doc
				fc = ""; fn = 0; ord = 0
				hdr = ""; intable = 0; dcol = 0; kcol = 0
				nsect = 0; tpos = 0
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
						# The heading depth: the run of `#` before the space.
						# The SECOND copy of this count - the shared
						# readtable() carries the first, and both feed the
						# same same-depth-or-shallower boundary. Change one,
						# change both.
						nh = 0
						while (substr(t, nh + 1, 1) == "#") nh++
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

						# Close every section this heading ends, then open
						# this one. A subsection leaves its parent on the
						# stack, which is the whole depth rule. SECT holds
						# the FINISHED BODY key rather than the ordinal, so
						# the per-line loop below appends without rebuilding
						# one composite subscript per open ancestor per line.
						#
						# `tpos` is the STACK POSITION of the section that
						# owns the corner table, not a second copy of its
						# ordinal and depth. The table section lives exactly
						# as long as its own stack entry, so the pop above is
						# already the rule that closes it - carrying its
						# depth separately would be the same boundary
						# written twice, in step only for as long as someone
						# kept it there. A second `{#target-verdict}` anchor
						# is therefore a new section rather than an
						# extension of the first, by construction.
						while (nsect > 0 && SLEV[nsect] >= nh) nsect--
						if (tpos > nsect) tpos = 0
						nsect++
						SECT[nsect] = doc SUBSEP ord
						SLEV[nsect] = nh
						if (doc == TABLEDOC && (fold(ex) == TABLEKEY || fold(h) == TABLEKEY)) tpos = nsect
						hdr = ""; intable = 0
						continue
					}

					if (nsect == 0) continue
					# A blank line closes a table to every renderer, so it
					# closes one here - otherwise two tables separated by a
					# paragraph read as one and the rows of the second land
					# under the header of the first.
					if (t == "") { hdr = ""; intable = 0; continue }

					for (si = 1; si <= nsect; si++) BODY[SECT[si]] = BODY[SECT[si]] t "\n"
					if (substr(t, 1, 1) != "|") { hdr = ""; intable = 0; continue }
					if (tpos == 0) continue

					row = t
					sub(/^\|/, "", row)
					sub(/\|[ \t]*$/, "", row)
					nc = split(row, cell, "|")
					if (nc < 1) continue
					alldash = 1
					for (i = 1; i <= nc; i++)
						if (cell[i] !~ /^[ \t]*:?-+:?[ \t]*$/) { alldash = 0; break }

					# Keyed on the SECTION that owns the table rather than on
					# the heading the row sits under, so a corner table inside
					# a subsection is recorded against the anchor the mode
					# resolves.
					kk = SECT[tpos]
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
				# NO CORNER ROWS IS NOT AGREEMENT, and the old line said it was:
				# it read `matched verbatim` over a row count of zero, which is
				# what a section-boundary bug looked like from the outside for as
				# long as it shipped. The kind check is the half that reads those
				# rows, in both directions, so with none of them read there is
				# nothing for the ledger to have agreed with and the line says so.
				#
				# Which document is named is branched on `hasplan` the way the
				# no-verdict-either-side line above branches on it: naming an
				# anchor inside a file that is not there sends its reader to look
				# for a table in a document they do not have, which is the same
				# reporting-past-what-was-opened this whole line exists to stop.
				if (nrow == 0) {
					where = (hasplan == "1") ? "no corner verdict table under the {#target-verdict} anchor of business-plan.md" : "no business-plan.md at the vault root"
					printf("%d verdict note%s and %s - %s. Not checked: the Kind cell against `driver_kind`, in either direction, because there is no corner verdict table to read it from.\n",
						nvn, (nvn == 1 ? "" : "s"), where, vault)
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
# --monitoring - an axis owes an instrument, a cadence and a decision
#
# competitor-analysis.md's Monitoring plan section asked which pricing pages,
# changelogs and job boards to re-check and on what cadence. That is FRESHNESS,
# and freshness is the same question the per-profile research date and a claim
# note's `stale_after` already ask: is this still true. None of the three asks
# which way it is moving, and a direction is the only thing that separates a
# closing window from an open one. A competitor profiled the day before the
# profile was used missed a strategic reversal by that vendor six weeks earlier
# - the single fact that most changed what the competitor meant - because a
# snapshot cannot see a direction and nothing in the method asked for one.
#
# So the section becomes a contract rather than a paragraph: named axes, an
# instrument per axis, a cadence, and the decision each would change. The last
# column is the one that keeps this from becoming a watchlist - a signal nobody
# acts on costs the same to collect as one that matters.
#
# It is a mode rather than a check for the reason --used-in, --red-team and
# --roadmap-table are: it reads a document at the vault root rather than a note
# in one of the seven directories, which is a different surface. The engagement
# folder IS the vault, so a sibling report is the established thing to read here
# and not new architecture.
#
# LC_ALL=C for the reason --used-in found the hard way: an axis and a decision
# are free prose in a table cell, so they carry em dashes and curly quotes, and
# macOS awk in a UTF-8 locale aborts the record on the first sequence it cannot
# decode - which would end the scan early and pass a document it never finished
# reading.
# ----------------------------------------------------------------------------

if [ "$MODE" = "monitoring" ]; then
	COMPETITORS="$VAULT/competitor-analysis.md"
	# A vault with no competitor-analysis.md at its root owes nothing, which is
	# every vault before the competitor dimension runs. The line names the
	# document it could not open and says the axis half did not run, rather than
	# stating what it INFERRED from the absence. The old line said `no competitor
	# set was profiled, so no axis owes an instrument` - a conclusion drawn from a
	# missing file - and printed it over a vault holding 31 competitor profiles
	# and a written monitoring plan, because the document lived somewhere other
	# than the vault root. Absence of the file is not absence of the work, and the
	# only thing this mode can honestly report is what it did not read. The empty
	# failure file still goes through the renderer, so --json gets a well-formed
	# document either way.
	MONITORING_OK="every monitoring axis names an instrument, a cadence and the decision it would change - $VAULT"
	if [ ! -f "$COMPETITORS" ]; then
		MONITORING_OK="no competitor-analysis.md at the vault root - $VAULT. Not read: the monitoring axes, so nothing here was held to an instrument, a cadence and the decision it would change - a competitor set profiled under some other path reads exactly like one that was never profiled."
	elif [ "$FOUND_SCHEMA" -lt 2 ]; then
		# The axes are what version 2 asks the section for. A vault at 1 is held
		# to exactly the rules it was written under, the same exemption
		# --roadmap-table and --red-team's roster take, and named rather than
		# silent so a clean line is never mistaken for a section that was read.
		MONITORING_OK="competitor-analysis.md at schemaVersion $FOUND_SCHEMA - the monitoring axes are a schemaVersion 2 rule and a vault at 1 is held to the rules it was written under"
	else
		LC_ALL=C awk -v out="$FAILURES" '
			function report(check, id, detail) { print "competitor-analysis.md\t" check "\t" id "\t" detail >> out }

			# The key a heading and a header cell are matched on: trimmed,
			# whitespace runs collapsed, lowercased. Matching the raw text would
			# read `## Monitoring Plan` and `## Monitoring  plan` as two
			# different sections, neither of them the one this mode wants - and a
			# check that fires on capitalisation is one somebody switches off,
			# which takes the half that worked with it.
			function key(s) {
				sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
				gsub(/[ \t]+/, " ", s)
				return tolower(s)
			}

			# The same trim without the folding, for the message. A failure
			# naming the axis in the case the document wrote it in is one the
			# reader can find by eye.
			function disp(s) {
				sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
				return s
			}

			# A cell answers the column when it carries a letter or a digit.
			# Anything else - an em dash, a run of hyphens, a lone ellipsis - is
			# the shape of a cell somebody filled in to make the row look
			# complete, and reading it as an answer is what makes this rule
			# clearable without doing the work. Deliberately NOT a placeholder
			# word list: a check that has to be taught every spelling of `TBD` is
			# one that misses the next one, and every spelling of it has no
			# letter-or-digit test to fail anyway.
			function answered(s) { return (s ~ /[A-Za-z0-9]/) }

			{
				line = $0
				sub(/\r$/, "", line)
				t = line
				sub(/^[ \t]+/, "", t)

				# Fenced blocks hold examples, not rows. One of eight copies of
				# those six lines: the --used-in scan(), the
				# --supersession-sweep sections(), the --red-team roster reader,
				# the shared readtable(), the --binding-driver readdoc(),
				# --claim-drift and the shared $DOC_SCAN_AWK carry the same ones,
				# for the same reason - eight awk programs reading a document at
				# the vault root, and no way to share a function across them.
				# Change one, change all eight.
				if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") {
					c = substr(t, 1, 1)
					n = 0
					while (substr(t, n + 1, 1) == c) n++
					if (fc == "") { fc = c; fn = n }
					else if (c == fc && n >= fn) { fc = ""; fn = 0 }
					next
				}
				if (fc != "") next

				# A heading ends the section as reliably as it starts it, so the
				# rows read are the ones under this heading and no others - a
				# `| ... |` row in Threat ranking is not an axis.
				if (match(t, /^#+[ \t]+/)) {
					h = substr(t, RLENGTH + 1)
					sub(/[ \t]*#+[ \t]*$/, "", h)
					insection = (key(h) == "monitoring plan")
					if (insection) seen = 1
					next
				}
				if (!insection) next

				if (substr(t, 1, 1) != "|") next
				row = t
				sub(/^\|/, "", row)
				sub(/\|[ \t]*$/, "", row)
				nc = split(row, cell, "|")
				if (nc < 2) next

				# The |---| rule is skipped by testing every cell rather than by
				# counting lines, so a table written with a colon-carrying
				# alignment row is read the same as one without.
				allrule = 1
				for (i = 1; i <= nc; i++)
					if (cell[i] !~ /^[ \t]*:?-+:?[ \t]*$/) { allrule = 0; break }
				if (allrule) next

				# The FIRST row of the section is the header, and the columns are
				# located by the names it carries rather than by position - the
				# rule --roadmap-table applies to its `Item` cell, and for the
				# same reason: reading a fixed position reports every row of a
				# correct table as incomplete the moment somebody adds a column.
				# Each defaults to its template position, so a table with no
				# recognisable header is still read rather than silently skipped.
				if (!nhdr) {
					nhdr = 1
					icol = 2; ccol = 3; dcol = 4
					for (i = 1; i <= nc; i++) {
						hk = key(cell[i])
						if (hk == "instrument") icol = i
						else if (hk == "cadence") ccol = i
						else if (index(hk, "decision") == 1) dcol = i
					}
					next
				}

				ax = disp(cell[1])
				if (!answered(ax)) next
				axk = key(ax)
				if (axk in SEENAX) next
				SEENAX[axk] = 1
				AORDER[++na] = axk
				ASHOW[axk] = ax
				AINST[axk] = (icol <= nc ? disp(cell[icol]) : "")
				ACAD[axk] = (ccol <= nc ? disp(cell[ccol]) : "")
				ADEC[axk] = (dcol <= nc ? disp(cell[dcol]) : "")
			}

			END {
				# One check for the absent section and the empty one, because
				# they take the same fix - write the axes - and the detail says
				# which of the two it found. Splitting them would be two names
				# for one edit.
				if (na == 0) {
					if (seen)
						report("monitoring-plan-no-axes", "", "competitor-analysis.md carries a `## Monitoring plan` section with no axis in it. The section it replaces asked which pages to re-check and how often, which is freshness - and freshness is the question the per-profile research date and every claim note`s `stale_after` already ask. Neither of them asks which way a competitor is moving, and a direction is the only thing that separates a closing window from an open one: a profile researched the day before it was used missed a strategic reversal six weeks earlier, because a snapshot cannot see one. Name the axes, an instrument per axis, a cadence, and the decision each would change")
					else
						report("monitoring-plan-no-axes", "", "competitor-analysis.md carries no `## Monitoring plan` section at all, so nothing in the corpus says which way any competitor is moving. Every profile in this document is a snapshot dated on the day it was taken, and a snapshot cannot see a direction - a competitor profiled the day before it was used missed a strategic reversal six weeks earlier, which was the single fact that most changed what that competitor meant. Add the section: named axes, an instrument per axis, a cadence, and the decision each would change")
					exit
				}

				for (i = 1; i <= na; i++) {
					axk = AORDER[i]
					# A colon-list rather than a conjunction, because the same
					# sentence has to read correctly at one missing column and at
					# three, and a joiner that changes with the count is one more
					# thing the two implementations can disagree about.
					miss = ""
					if (!answered(AINST[axk])) miss = miss ", instrument"
					if (!answered(ACAD[axk])) miss = miss ", cadence"
					if (!answered(ADEC[axk])) miss = miss ", the decision it would change"
					if (miss == "") continue
					sub(/^, /, "", miss)
					report("monitoring-axis-incomplete", ASHOW[axk],
						"the `" ASHOW[axk] "` axis leaves empty: " miss ". An axis with no instrument is a thing somebody intends to notice, which is not a mechanism; one with no cadence is a re-check with no date, which is the same as no re-check; and one with no decision behind it is a signal nobody acts on, which costs the same to collect as one that matters. A cell carrying no letter or digit - an em dash, a run of hyphens - reads as empty here rather than as an answer, because that is the cheapest way past this rule")
				}
			}
		' "$COMPETITORS"
	fi

	render_failures "vault-lint monitoring" "$MONITORING_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --deliverable - the artifact stops inheriting the ledger's archaeology
#
# Retraction is visible in the vault, and that rule is right: a silently deleted
# claim comes back two drafts later with its cause of death erased. This is its
# counterpart one document over. The rendered deliverable is read by somebody who
# was never in the room, and a note ID or an objection code is a VAULT ADDRESS -
# it resolves for anyone holding the corpus and resolves to nothing for the
# audience the document is for. A struck-through line with its reason beside it
# is a document arguing with its own previous draft. Left unchecked, a finished
# plan and its model carry well over a hundred pieces of that narrative between
# them - into the two documents an investor actually reads.
#
# IT READS THE RENDERED HTML AND NEVER THE MARKDOWN, and that is the design
# rather than a convenience. The markdown is the working document and keeps every
# strikethrough it owes. The HTML is what the outside reader holds, and it is the
# only one a check can hold to this at all, because the fix is a judgement: a
# correction reaches the artifact RESTATED FORWARD, as what is true now, and
# stripping the `~~` mechanically leaves `That multiple was actually...` with no
# antecedent. No script can judge an antecedent, so that half is a read-back item
# in the render loop and this mode covers the half that is mechanical.
#
# There is no fenced-block scan here for the reason the other modes have one:
# a deliverable is prose for an outside reader and does not document its own
# format. The one document in this corpus that does - red-team.md, which carries
# its own row template - is not a deliverable and is not read by this mode.
#
# LC_ALL=C for --used-in's reason: the prose in a deliverable carries em dashes
# and curly quotes, and macOS awk in a UTF-8 locale aborts the record on the
# first sequence it cannot decode, which would end the scan early and pass a
# document it never finished reading.
# ----------------------------------------------------------------------------

if [ "$MODE" = "deliverable" ]; then
	RENDERED="$TMP/rendered"
	: >"$RENDERED"
	[ -d "$VAULT/deliverables" ] &&
		find "$VAULT/deliverables" -type f -name '*.html' | LC_ALL=C sort >"$RENDERED"

	DELIVERABLE_OK="every rendered deliverable carries what is true now and no vault address - $VAULT"
	if [ ! -s "$RENDERED" ]; then
		# Named rather than silent, for --red-team's reason: a mode that printed
		# `clean` over a directory it never found reads as a deliverable that was
		# checked, and the gate runs BEFORE the first render as well as inside
		# the render loop - so the empty case is the ordinary one on the first
		# call and has to say which of the two it is.
		DELIVERABLE_OK="no deliverables/*.html under $VAULT - nothing has been rendered yet, so no artifact carries anything out"
	else
		# One awk per deliverable rather than the whole list as operands. The
		# operand form would let word splitting break the first vault that lives
		# under a directory with a space in its name - every other path in this
		# script is quoted for that reason - and it buys nothing: the relative
		# path is passed in rather than sliced off FILENAME, and NR is per-file
		# because the process is.
		while IFS= read -r doc; do
			[ -n "$doc" ] || continue
			# `rel` is the path a reader opens, relative to the vault root, so
			# every message names deliverables/business-plan.html rather than an
			# absolute path - which differs per machine, and differs between the
			# two implementations on the same machine.
			LC_ALL=C awk -v out="$FAILURES" -v rel="${doc#"$VAULT/"}" '
				BEGIN {
					# Eight character classes rather than one with a brace
					# interval: a `{8}` is an interval expression to some awks and
					# a literal to others, and which one runs this script is a
					# property of the user machine - the same caution the anchor
					# patterns take with `\{`.
					#
					# EIGHT is the length vault.md`s generation rule produces, and
					# requiring it is the whole reason this does not cry wolf.
					# Validating a note`s own ID accepts any length on purpose;
					# DETECTING one that leaked into prose is the opposite job, and
					# the loose form fires on `FACT-CHECKED` and `CLAIM-HANDLING`.
					AN = "[A-Za-z0-9]"
					TYPES = "(SOURCE|FACT|CLAIM|ASSUMPTION|QUESTION|DECISION|MILESTONE)"
					IDRE = TYPES "-" AN AN AN AN AN AN AN AN
					# The objection ID shape --red-team reads in red-team.md.
					OBJRE = "R[0-9]+-O[0-9]+"
					# `<del>`, `<s>` and `<strike>` as OPENING tags, matched on a
					# lowercased copy of the line so a renderer that emits upper
					# case is read the same. The delimiter class is what keeps
					# `<script` and `<span` out: `<s` alone matches both.
					TAGRE = "<(del|s|strike)([ \t>/]|$)"
				}

				function report(check, id, detail) { print rel "\t" check "\t" id "\t" detail >> out }

				# One row per address per line, so two copies of one address on one
				# line are one row and the same address on two pages is two rows.
				# The unit is the place a reader has to go and restate, which is a
				# line. Row ORDER out of here is whatever awk hands back;
				# render_failures sorts the failure file, which is what makes the
				# JSON deterministic and byte-comparable against the PowerShell
				# side.
				function once(check, id, ln,   k) {
					k = check SUBSEP id SUBSEP ln
					if (k in SEEN) return 0
					SEEN[k] = 1
					return 1
				}

				# Every match of `re` in `s`, with the alphanumeric-boundary test
				# the pattern itself cannot carry: awk has no \b, and writing the
				# boundary into the ERE consumes it, so a second address
				# immediately after the first would be skipped. A rejected match is
				# stepped over rather than ending the scan -
				# `XCLAIM-AS23SD44 CLAIM-BB77KK12` carries one real address and it
				# is the second one.
				function scan(s, re, check, ln, what,   rest, tok, before, after, at, end) {
					rest = s
					at = 0
					while (match(rest, re)) {
						tok = substr(rest, RSTART, RLENGTH)
						before = (at + RSTART == 1) ? "" : substr(s, at + RSTART - 1, 1)
						after = substr(rest, RSTART + RLENGTH, 1)
						# The token goes in the DETAIL as well as the id column,
						# because human output prints the check and the detail and
						# nothing else - a message naming no address sends the
						# reader to a page to find it by eye.
						if (before !~ /[A-Za-z0-9]/ && after !~ /[A-Za-z0-9]/ && once(check, tok, ln))
							report(check, tok, "line " ln " carries `" tok "`, " what)
						end = RSTART + RLENGTH - 1
						at = at + end
						rest = substr(rest, end + 1)
					}
				}

				{
					line = $0
					sub(/\r$/, "", line)

					# Lowercased for the tag test only. The two addresses below are
					# matched on the original line because a note ID and an
					# objection code are upper case by construction, which is most
					# of what keeps this off ordinary prose.
					if (match(tolower(line), TAGRE) && once("deliverable-strikethrough", "tag", NR))
						report("deliverable-strikethrough", "line " NR,
							"line " NR " renders a strikethrough element. Invariant 14 is why the markdown carries one - a retraction that is silently deleted comes back two drafts later with its cause of death erased - and this is that rule inverted in the artifact: the reader of this file was never in the room, so a struck-through line with its reason beside it is a document arguing with its own previous draft. The correction reaches here RESTATED FORWARD, as what is true now. Deleting the `~~` is not the fix - it leaves the sentence after it with no antecedent, which is why this is a step in the render loop rather than a filter")

					if (match(line, /~~[^~]+~~/) && once("deliverable-strikethrough", "tildes", NR))
						report("deliverable-strikethrough", "line " NR,
							"line " NR " carries a literal `~~...~~` span, so a markdown strikethrough reached the render and came out as text - this reader sees the tildes. Either way it is the ledger`s correction narrative in the artifact: restate the claim forward as what is true now, and leave the retraction visible in the vault, where invariant 14 wants it")

					scan(line, IDRE, "deliverable-note-id", NR,
						"which is a note ID. An ID is an ADDRESS into the vault: it resolves for anyone holding the corpus and resolves to nothing for the audience this document is for, who has no ledger to look it up in. vault.md says as much outright - a rendered document shows the title, and nobody ever sees a note ID in a sentence. Name the claim, or drop the citation; the traceability lives in the vault, which is the half that does not ship")
					scan(line, OBJRE, "deliverable-objection-code", NR,
						"which is a red-team objection code. That code addresses a row in red-team.md, which this reader does not have, so it reads as a reference to an argument they were not in. If the objection changed the plan, the plan states what it now claims; if it did not, it does not belong here at all")
				}
			' "$doc"
		done <"$RENDERED"
	fi

	render_failures "vault-lint deliverable" "$DELIVERABLE_OK"
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
# THE TITLE IS THE KEY AND THE STATUS IS PART OF THE ANSWER. Matching a row
# against every assumption title regardless of `status` made a live row backed
# only by a `superseded` note match cleanly and print as `matched verbatim` -
# observed on a live model, green for days. A retired note is not a match: the
# title says the row was rendered off some note, and only the status says the
# ledger still stands behind it.
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
	#
	# $TABLE_READER_AWK is prepended the way --roadmap-table prepends it: this
	# mode reads the same table shape one artifact over, and the two adjacent
	# shell words concatenate into the single program text awk takes. It brings
	# readtable() and the trim() and fold() that reader calls, so this program
	# must not define either itself - awk rejects a duplicate.
	AR_OK=$(LC_ALL=C awk -v out="$FAILURES" -v model="$FINMODEL" -v hasmodel="$HAS_FINMODEL" -v vault="$VAULT" -v schema="$FOUND_SCHEMA" -F '\t' "$TABLE_READER_AWK"'
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }
			$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# A block-list item may carry a `:: label` after the ID it names, so
			# every edge walk in this file strips it. The fourth copy - graph,
			# --binding-driver and the checks pass carry the other three, and
			# each awk program is a separate process that cannot call another
			# one. Change one, change all four.
			function target_of(item) {
				return (index(item, " :: ") > 0) ? substr(item, index(item, " :: ") + 4) : item
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
				# TITLE is every title a row may match - not only the declared
				# inputs - because a row whose note exists and agrees is not a
				# failure whatever else that note declares. MI is the declared
				# inputs, in vault order so two runs print the same list.
				#
				# WHICH NOTES BACK A ROW IS DECIDED BY `status`, NOT BY WHICH
				# ASSERTING SET HOLDS THE NOTE. A row is backed when a LIVE
				# `assumption` OR a live `claim` carries its title, so both types
				# feed TITLE and DEAD. THAT PAIR IS THE WHOLE SET and the other
				# five types are out by argument rather than by omission - a
				# `source` and a `fact` are provenance a claim rests ON rather
				# than a value the projection carries, and a `milestone`,
				# `question` or `decision` asserts no value at all. Widening past
				# the pair changes what a model row may stand on; it is not the
				# next step of this fix. Reading `assumption` alone made this
				# fire on a row this method produces by its own promotion rule: a
				# structural driver with no subject instrument belongs in the
				# indexed set, so filing a sourced figure as an unevidenced
				# assumption is the defect, and correcting it retires the
				# assumption and mints a `claim` carrying the same title. The row
				# was then backed by a `current` claim whose `used_in` named the
				# assumptions section directly, every word of the failure was
				# true, and the conclusion did not follow - a corpus that did what
				# the method says was told it had a defect.
				#
				# MI STAYS ASSUMPTION-ONLY, and that is the row->note direction
				# only. `model_input` is a field a promoted claim does not carry,
				# so widening the title index leaves assumption-not-in-model
				# reading exactly the set it read before.
				#
				# A SUPERSEDED OR RETRACTED NOTE IS NOT A MATCH, and DEAD holds
				# it separately rather than beside the live titles. The title
				# key alone says the row was rendered off SOME note; it does not
				# say the ledger still stands behind it, and a row whose only
				# match has been retired is a live input resting on a value
				# nobody is obliged to maintain. Observed: a live row in the
				# assumptions table was backed only by a superseded note, and
				# the gate read `matched verbatim` over it for days. A title
				# carried by both a live note and a retired one still matches
				# live, because the row loop reads TITLE first - which is also
				# what clears the promoted row above.
				for (i = 1; i <= nf; i++) {
					f = files[i]
					ty = V[f, "type"]
					isa = (ty == "assumption")
					if (isa || ty == "claim") {
						ti = V[f, "title"]
						st = V[f, "status"]
						live = (st != "superseded" && st != "retracted")
						if (ti != "") {
							if (live) TITLE[ti] = 1
							else if (!(ti in DEAD)) { DEAD[ti] = V[f, "id"]; DEADST[ti] = st }
						}
						# THE SAME LIVE PREDICATE, and MI reads it for the reason
						# TITLE does. A retired note declaring `model_input` owes no
						# row: the only ways to satisfy the demand are to render the
						# dead title as a row - undoing the repair the row side just
						# asked for - or to write `excluded_from_model` onto a
						# corpse, which records a decision about a live revenue line
						# on a note nobody will open. Observed end to end: the row
						# side flagged a dead-backed row, re-titling it to the live
						# claim cleared that, and this half then demanded a row for
						# the superseded note the repair had just pointed away from.
						# "an input the ledger holds" is what the failure says, and a
						# note the ledger has retired is not one.
						if (isa && live && V[f, "model_input"] != "") MI[++nmi] = f
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

				# The shared reader, on the four arguments that make this read
				# the assumptions one: the assumptions heading, the
				# `Assumption` header cell, and column TWO, because the
				# template ships the `A-n` label in column one. It sets SEEN
				# and ROW[1..NROW].
				if (hasmodel == "1") readtable(model, "assumptions", "assumption", 2)

				# The inputs are in the ledger and nowhere a reader can see
				# them. Reported ONCE against the document rather than once per
				# note: the fix is one thing - render the table - and a reader
				# handed one row per input stops reading.
				if (nmi > 0 && NROW == 0) {
					if (hasmodel != "1")
						report("financial-model.md", "model-table-missing", "",
							"the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input` and there is no financial-model.md at the vault root. Every one of them is an input the projection is supposed to be built from, so a model that never renders them is a projection whose numbers are buried in formulas - which is the failure the assumptions table exists to prevent, from the other side")
					else if (!SEEN)
						report("financial-model.md", "model-table-missing", "",
							"the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input` and no heading in financial-model.md answers to `assumptions`. The inputs exist in the ledger and the model has no section that lists them, so a reader cannot tell which numbers the projection stands on. The plan template heading is `## Assumptions (every input lives here - nothing buried in a formula) {#assumptions}`")
					else
						report("financial-model.md", "model-table-missing", "",
							"the assumptions section of financial-model.md lists no rows and the vault carries " nmi " assumption note" (nmi == 1 ? "" : "s") " declaring `model_input`. A table with a heading and no rows reads as a model whose inputs are stated somewhere, and they are stated in the ledger only - so the projection has no visible input list at all")
					printf("%d live declared model input%s and no assumptions table the model renders - %s\n", nmi, (nmi == 1 ? "" : "s"), vault)
					exit
				}

				for (i = 1; i <= NROW; i++) {
					if (ROW[i] in TITLE) { HIT[ROW[i]] = 1; continue }
					# A RETIRED MATCH IS ONE SITUATION AND GETS ONE FAILURE. HIT
					# is set here too, so the same pair is never also reported as
					# an input the table has no row for - a second, wrong repair.
					# SINCE MI WENT LIVE-ONLY THIS MARKING CANNOT BE THE THING
					# THAT CLEARS IT: an MI member is a live assumption, so its
					# title is in TITLE and a matching row takes the branch above.
					# It stays because the invariant belongs to the row loop
					# rather than to the note predicate - widen MI again and this
					# line is the only thing standing between one situation and
					# two failures pointing at different repairs.
					if (ROW[i] in DEAD) {
						HIT[ROW[i]] = 1
						report("financial-model.md", "model-row-dead-assumption", DEAD[ROW[i]],
							"row `" ROW[i] "` in the assumptions section matches " DEAD[ROW[i]] " and that note is `status: " DEADST[ROW[i]] "`, with no live `assumption` or `claim` note carrying the title. The row is live in the model and everything standing behind it has been retired from the ledger, so the projection rests on a value nobody is obliged to maintain, nothing orders it in the validation queue, and the title matched - which is exactly why every check stayed green. Observed: a live assumption row backed only by a superseded note read as `matched verbatim` for days. Point the row at the note that replaced this one - a title promoted to a `claim` backs the row exactly as an assumption does, both being notes that assert a value, and what disqualifies either is `superseded` or `retracted` - or re-file this note as `current` if it was retired in error")
						continue
					}
					report("financial-model.md", "model-row-no-assumption", "",
						"row `" ROW[i] "` in the assumptions section matches no `assumption` or `claim` note title in this vault, character for character. The table renders each input off its note, so a row matching none of them was written by hand: the number in it has no `value`, no `sensitivity` and no `validated_by`, so nothing orders it in the validation queue and nothing will ever revisit it. Match the title verbatim, the way a roadmap row matches a milestone title - or write the assumption note this row is missing")
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
				# NO DECLARED INPUT IS NOT AGREEMENT. This mode is two checks,
				# and the count it printed was the row half alone: with no note
				# carrying `model_input`, `assumption-not-in-model` iterates over
				# nothing, so the direction this whole mode was written for - an
				# input the ledger holds and the table never renders - reported a
				# matched count over a set it never had. A reader has to be able
				# to tell that half agreeing from that half not running.
				else if (nmi == 0)
					printf("%d assumption row%s against no declared model inputs - %s. Not checked: whether a declared input reached the table, because no live `assumption` note carries `model_input`.\n",
						NROW, (NROW == 1 ? "" : "s"), vault)
				# TWO COUNTS, NOT TWO SIDES OF ONE. `against` read as a
				# comparison between two sets that have to agree, and they do
				# not: a row backed by a `claim` is not a declared model input,
				# and a declared input cleared by `excluded_from_model` is not a
				# row. Both halves ran and both agreed - which is what this says
				# now, one half at a time, rather than implying an equality
				# whose absence would then read as a miscount.
				else
					printf("%d assumption row%s each backed by a live `assumption` or `claim` note, and %d live declared model input%s each rendered as a row or excluded with a reason, matched verbatim - %s\n",
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
			# A SECTION ENDS AT THE NEXT HEADING OF ANY DEPTH, and this is now the
			# only reader in the file on that rule - readtable() and
			# --binding-driver readdoc() both end a section at the next heading
			# of the same depth or shallower. The unit here is the
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
			# rewritten example invisible. The six lines are the SEVENTH copy of
			# the scan every document-reading mode here carries - --used-in
			# scan(), --supersession-sweep sections(), --red-team, the shared
			# readtable(), --binding-driver readdoc() and --monitoring carry
			# the first six, and the shared $DOC_SCAN_AWK carries the eighth.
			# This copy went uncounted for two releases while every other site
			# said six, which is what a census nobody re-derives does: change
			# one, change all eight.
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
# --citation-codes - every cited code resolves to a row in its index
#
# The resolution contract was specified and never enforced: [S#] resolves through
# sources.md, [F#] through research/founder-brief.md. --used-in opens the target
# a NOTE names; a code in prose is a different address, and nothing opened it -
# so a plan could cite a code that resolves to nothing and clear --release-gate.
# A dead code renders exactly like a working one, and the reader who follows it
# is the one person who cannot check it.
#
# THE TWO INDEX FILES ARE EXCLUDED FROM THE SCAN, and that is load-bearing rather
# than an optimisation. An index legitimately discusses its own retired numbers -
# a row recording that a code was withdrawn and deliberately left unused names
# that code in its own prose - and a naive scan reads that mention as a citation
# and fails a corpus doing exactly the right thing.
#
# FORWARD DIRECTION ONLY, which is the opposite call to --red-team's roster and
# to --roadmap-table's two directions, for a reason specific to an index: a
# recorded fact nothing leans on yet is healthy, so failing a row nothing cites
# would push an author toward citing things to silence a linter. There is no
# dodge-by-omission here either way - the failure is cited-with-no-row, and
# deleting the citation is deleting the claim that needed it.
#
# THE BRACKETS ARE OPTIONAL ON BOTH INDEX ROWS. The two documents write the cell
# differently in the field - `| F1 |` in the brief and `| [S1] |` in the log - and
# holding each to only its own spelling would fail a brief written in the other
# for a formatting difference no reader can see.
#
# WHAT THE SUCCESS LINE MUST SAY. Resolution is necessary and it is not
# sufficient: a research file carries its own local S table, so a document citing
# a local code the global log also assigns resolves to a row and to a DIFFERENT
# source. That is the shape of defect this whole family exists to close - a check
# whose success line claims more than it verified - so the line states the limit
# rather than leaving it to be inferred, and --unflattened-source below closes
# the half of it a check can reach.
#
# LC_ALL=C for --used-in's reason: a document carries em dashes and curly quotes,
# and macOS awk in a UTF-8 locale aborts the record on the first sequence it
# cannot decode, which would end the scan early and pass a document it never
# finished reading.
# ----------------------------------------------------------------------------

if [ "$MODE" = "citation-codes" ]; then
	CC_BRIEF="research/founder-brief.md"
	CC_LOG="sources.md"
	CC_HAS_BRIEF=0
	[ -f "$VAULT/$CC_BRIEF" ] && CC_HAS_BRIEF=1
	CC_HAS_LOG=0
	[ -f "$VAULT/$CC_LOG" ] && CC_HAS_LOG=1

	# NEITHER INDEX, NOTHING TO READ. Every code would resolve against nothing,
	# so the line is decided before the first document is opened - and opening
	# them anyway is a full read of the corpus to print a constant. The same
	# shape --deliverable uses when nothing has been rendered.
	if [ "$CC_HAS_BRIEF" -eq 0 ] && [ "$CC_HAS_LOG" -eq 0 ]; then
		render_failures "vault-lint citation-codes" "no $CC_LOG and no $CC_BRIEF under $VAULT - neither index exists, so no \`[F#]\` or \`[S#]\` was resolved against anything and this mode checked nothing"
		exit $?
	fi

	# Every document a reader of this corpus opens, as a vault-relative path:
	# the markdown at the vault root and the markdown in research/. Globs
	# rather than find, because these are the two directory levels the
	# resolution contract names and a glob needs no non-POSIX -maxdepth. The
	# note directories are deliberately not walked - a claim note carries no
	# citation code at all, which is the same fact --used-in's boundary rests
	# on - so scanning them would be a walk over the whole ledger for a pattern
	# it never holds.
	#
	# ORDER DOES NOT MATTER HERE and is not sorted: render_failures sorts the
	# whole failure file before anything prints it, and every count below is
	# keyed rather than positional.
	CC_LIST="$TMP/citation-docs"
	for f in "$VAULT"/*.md "$VAULT"/research/*.md; do
		[ -f "$f" ] || continue
		rel="${f#"$VAULT/"}"
		[ "$rel" = "$CC_LOG" ] && continue
		[ "$rel" = "$CC_BRIEF" ] && continue
		printf '%s\n' "$rel"
	done >"$CC_LIST"

	# $DOC_SCAN_AWK is prepended the way --roadmap-table prepends the table
	# reader: two adjacent shell words concatenate into the single program text
	# awk takes. It brings fenced() and trim(), so this program must not define
	# either itself.
	CC_OK=$(LC_ALL=C awk -v vault="$VAULT" -v out="$FAILURES" -v brief="$CC_BRIEF" -v logdoc="$CC_LOG" \
		-v hasbrief="$CC_HAS_BRIEF" -v haslog="$CC_HAS_LOG" "$DOC_SCAN_AWK"'
			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# The codes one index assigns, read off the FIRST cell of every
			# row. A cell holding anything else is not an assignment and is
			# not read - which is what keeps a prose table in the same
			# document from registering codes.
			function readindex(rel, kind,   path, line, t, cell) {
				path = vault "/" rel
				FC = ""; FN = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (fenced(t)) continue
					cell = firstcell(t)
					if (cell ~ /^[FS][0-9]+$/ && substr(cell, 1, 1) == kind) ASSIGNED[cell] = 1
				}
				close(path)
			}

			# Every [F#] and [S#] one document cites. Reported once per
			# document per code: the repair is one row in one index, and a
			# code cited on six lines is not six repairs. The line of the
			# FIRST occurrence goes in the message, because a failure naming
			# no line sends its reader through the file by eye.
			function scan(rel,   path, line, t, ln, rest, tok, code, kind, k) {
				path = vault "/" rel
				FC = ""; FN = 0
				ln = 0
				while ((getline line < path) > 0) {
					ln++
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (fenced(t)) continue
					rest = line
					while (match(rest, /\[[FS][0-9]+\]/)) {
						tok = substr(rest, RSTART, RLENGTH)
						rest = substr(rest, RSTART + RLENGTH)
						code = substr(tok, 2, length(tok) - 2)
						kind = substr(code, 1, 1)
						# A code whose index is absent is not resolved and
						# not failed. The success line says which half went
						# unread, rather than reporting agreement over an
						# index nobody could open.
						if (kind == "F" && hasbrief != 1) continue
						if (kind == "S" && haslog != 1) continue
						k = rel SUBSEP code
						if (k in DONE) continue
						DONE[k] = 1
						nchecked++
						if (code in ASSIGNED) continue
						if (kind == "F")
							report(rel, "citation-code-no-fact-row", code,
								"line " ln " cites `" tok "` and " brief " carries no `| " code " |` row. The code is an address into the founder brief and it resolves to nothing, so a reader who follows it finds no fact behind the sentence that leaned on one - and the document renders identically to one whose codes all resolve, which is why nothing else in this corpus can see it. Either the row was never written, or the code is a typo for one that was")
						else
							report(rel, "citation-code-no-source-row", code,
								"line " ln " cites `" tok "` and " logdoc " carries no `| " code " |` row. The code is an address into the source log and it resolves to nothing, so the sentence carries the appearance of provenance and none of the substance - and a reader who follows it is the one person who cannot check it. Either the source was never logged, or the code is a typo for one that was")
					}
				}
				close(path)
			}

			BEGIN {
				if (haslog == 1) readindex(logdoc, "S")
				if (hasbrief == 1) readindex(brief, "F")
			}

			{ scan($0) }

			END {
				limit = "Not checked: whether a code resolves to the INTENDED source. A research file legitimately carries its own local `S` table, so a document citing a local code the global log also assigns resolves to a row and to a different source - which no count of resolving codes can see. --unflattened-source is the half of that a check can reach."
				if (hasbrief != 1)
					printf("%d cited `[S#]` code%s, each resolving to a row in %s - %s. Not checked: `[F#]` codes at all, because there is no %s under %s to resolve them against. %s\n",
						nchecked, (nchecked == 1 ? "" : "s"), logdoc, vault, brief, vault, limit)
				else if (haslog != 1)
					printf("%d cited `[F#]` code%s, each resolving to a row in %s - %s. Not checked: `[S#]` codes at all, because there is no %s under %s to resolve them against. %s\n",
						nchecked, (nchecked == 1 ? "" : "s"), brief, vault, logdoc, vault, limit)
				else
					printf("%d cited code%s, each resolving to a row in the index that assigns it - %s. %s\n",
						nchecked, (nchecked == 1 ? "" : "s"), vault, limit)
			}
		' "$CC_LIST")

	render_failures "vault-lint citation-codes" "$CC_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --unflattened-source - a local source row the global log never received
#
# THIS IS THE HALF --citation-codes CANNOT REACH, and the defect is real rather
# than hypothetical. A vault's research files carry their own local `S` tables for
# traceability while the root sources.md assigns the global `[S#]` once. A source
# existed only as one research file's local S14 and was never flattened into the
# log, so it had no citable code at all - while global [S14] was a DIFFERENT
# source. Four documents cited [S14] meaning the local one. Every code resolved,
# and every check passed.
#
# THE FAILURE KIND IS `source-unflattened`, NOT `orphan-source`. `check` already
# emits orphan-source for a source note nothing in the vault rests on, which is
# close to the opposite finding - one is a source nobody cited, this is a source
# nobody CAN cite - and giving two findings one name sends half their readers to
# the wrong repair. Neither is widened into the other.
#
# THE DECLARED EXEMPTION IS THE PART THAT DECIDES WHETHER THIS MODE SURVIVES. A
# corpus may deliberately keep a large per-row ledger out of the global log - a
# per-profile table of a hundred rows or more, cited with a qualified suffix - and
# a mode that reported every one of those as a failure would be switched off
# within a day, taking the working half with it. The exemption is READ FROM THE
# LOG'S OWN HEADER rather than keyed on a filename this script knows, because the
# file that holds the ledger differs per corpus and a hardcoded name is a rule
# that only fits the vault it was written against.
#
# THE HEADER IS THE PROSE BEFORE THE LOG'S FIRST TABLE ROW, which is where a
# corpus already explains what its log does and does not assign. A declaration
# below the first row would be a note buried inside the data.
#
# A ROW WITH NO URL IS NOT RESOLVED AND NOT FAILED. A local row may name a source
# with no public address, and there is then no key to match it on - so it is
# counted and reported as unresolved rather than passed in silence, which is the
# same rule --assumption-rows learned about a half that walks an empty set.
#
# LC_ALL=C for --used-in's reason.
# ----------------------------------------------------------------------------

if [ "$MODE" = "unflattened-source" ]; then
	US_LOG="sources.md"

	# NO LOG, NO READ. There is nothing to compare a local row against, so the
	# mode says it did not run before it walks anything - the same shape
	# --citation-codes reports a missing index with, and the reason the awk
	# below never has to ask whether the log was there.
	if [ ! -f "$VAULT/$US_LOG" ]; then
		render_failures "vault-lint unflattened-source" "no $US_LOG under $VAULT - there is no global log to flatten a local row into, so no research file's own source table was read"
		exit $?
	fi

	US_LIST="$TMP/research-docs"
	for f in "$VAULT"/research/*.md; do
		[ -f "$f" ] || continue
		printf '%s\n' "${f#"$VAULT/"}"
	done >"$US_LIST"

	US_OK=$(LC_ALL=C awk -v vault="$VAULT" -v out="$FAILURES" -v logdoc="$US_LOG" "$DOC_SCAN_AWK"'
			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# One URL compared as bytes, minus the punctuation a sentence
			# leaves on the end of one. The host is case-sensitive here and
			# a path always is - folding either would be a guess about which
			# half of a URL is which.
			# The one URL pattern this mode matches on, held as a string so the
			# two functions below run the same bytes. Written twice, a class
			# widened in one and not the other collects an address the other
			# will never match, and the mode then reports an agreement it did
			# not verify. The class stops at the characters that delimit a URL
			# in markdown and in a table - a space, a tab, a pipe, a closing
			# paren or angle bracket - so a bracketed markdown link and an
			# angle-bracketed bare one both yield the address and not the
			# punctuation around it.
			BEGIN { URLRE = "https?://[^ \t|)>]+" }

			function normurl(u) {
				sub(/[.,;:]+$/, "", u)
				sub(/\/+$/, "", u)
				return u
			}

			# Every URL one line carries, into the global set.
			function collecturls(s,   rest, tok) {
				rest = s
				while (match(rest, URLRE)) {
					tok = substr(rest, RSTART, RLENGTH)
					rest = substr(rest, RSTART + RLENGTH)
					LOGURL[normurl(tok)] = 1
				}
			}

			# The first URL a local row names, which is the key this mode
			# matches on. First rather than every: a row names one source
			# and any further link in it is a secondary reference.
			function firsturl(s) {
				if (!match(s, URLRE)) return ""
				return normurl(substr(s, RSTART, RLENGTH))
			}

			# The log, read once: the URLs it carries anywhere, and the
			# files its header declares exempt. A URL in the header prose
			# counts as carried - the question is whether the corpus has the
			# source in its log at all, not which row holds it.
			function readlog(   path, line, t, intable, v, w) {
				path = vault "/" logdoc
				FC = ""; FN = 0
				intable = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (fenced(t)) continue
					if (substr(t, 1, 1) == "|") intable = 1
					collecturls(line)
					if (intable) continue
					# A bullet is still a header line, so the declaration
					# reads as prose to whoever opens the log.
					sub(/^[-*][ \t]+/, "", t)
					if (t !~ /^Local ledger:/) continue
					# The FIRST whitespace-delimited token after the colon is the
					# path, and everything after it is the reason - so a
					# declaration reads as a sentence to whoever opens the log
					# rather than as a field with a punctuation rule.
					v = trim(substr(t, 14))
					if (v == "") continue
					split(v, w, /[ \t]+/)
					v = w[1]
					sub(/^\.\//, "", v)
					if (v in EXEMPT) continue
					EXEMPT[v] = 1
					DECLARED[++ndecl] = v
				}
				close(path)
			}

			# One research file. A row whose first cell is `S<n>` - brackets
			# optional, the same spelling latitude --citation-codes gives an
			# index row - is a local source assignment, and the alignment
			# rule and the header row fall out because neither cell reads as
			# a code.
			function scanresearch(rel,   path, line, t, cell, u) {
				if (rel in EXEMPT) { EXEMPTHIT[rel] = 1; return }
				path = vault "/" rel
				FC = ""; FN = 0
				while ((getline line < path) > 0) {
					sub(/\r$/, "", line)
					t = line
					sub(/^[ \t]+/, "", t)
					if (fenced(t)) continue
					cell = firstcell(t)
					if (cell !~ /^S[0-9]+$/) continue
					if (!(rel in TABLED)) { TABLED[rel] = 1; nfile++ }
					u = firsturl(line)
					if (u == "") { nourl++; continue }
					nrow++
					if (u in LOGURL) continue
					report(rel, "source-unflattened", cell,
						"this file`s own source table assigns `" cell "` to " u " and " logdoc " carries that URL nowhere. The global log is what assigns a citable `[S#]`, so this source can be cited from research prose and cannot be cited from a plan document at all - and nothing else sees it, because the local table is well-formed, the log is well-formed, and no check compared them. Worse, a plan that cites the local code anyway resolves against whatever the log happens to assign that number to, which is a different source. Flatten it: give it a row in " logdoc ", or declare this file`s ledger exempt with a `Local ledger: " rel " - <why it stays local>` line in the log`s header")
				}
				close(path)
			}

			BEGIN { readlog() }

			{ scanresearch($0) }

			END {
				# What was declared exempt, named in the line rather than
				# left implicit: an exemption nobody sees is a switched-off
				# check that reads as a passing one, and a declaration for a
				# file that no longer exists is only visible here.
				ex = ""
				for (i = 1; i <= ndecl; i++)
					ex = ex (i == 1 ? "" : ", ") DECLARED[i] (DECLARED[i] in EXEMPTHIT ? "" : " (declared, no such file)")
				exline = (ndecl == 0) ? "" : sprintf(" Exempt by declaration in the log`s header: %s.", ex)
				noline = (nourl == 0) ? "" : sprintf(" Not resolved: %d local row%s carrying no URL, each naming a source with no key to match on.", nourl, (nourl == 1 ? "" : "s"))

				if (nfile == 0)
					printf("no research file under %s carries a local `| S<n> |` table - there is no local ledger to flatten, which is every vault whose research keeps no source table of its own.%s\n", vault, exline)
				else
					printf("%d local source row%s across %d research file%s, each naming a URL %s also carries - %s.%s%s\n",
						nrow, (nrow == 1 ? "" : "s"), nfile, (nfile == 1 ? "" : "s"), logdoc, vault, noline, exline)
			}
		' "$US_LIST")

	render_failures "vault-lint unflattened-source" "$US_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --subject-orphan - a subject the corpus argues from and never filed
#
# coverage-gap in `check` asks this of `required: true` subjects and stops
# there, and that boundary is exactly the gap. A subject optional in general is
# routinely load-bearing in one plan: the documents reason from it, the
# vocabulary declares it, and no note is ever written. Nothing else in this tool
# can see that. A subject with no note cannot collide with a contradiction,
# cannot go stale, cannot be superseded and cannot be challenged - every query
# the ledger supports returns clean over it, because there is nothing filed to
# return. Silent in every direction is what separates it from an ordinary
# coverage gap, and why this is a mode beside coverage-gap rather than a widening
# of it: the two send their reader to different repairs.
#
# THE MENTION IS THE WHOLE TRIGGER. Without it this would be coverage-gap over
# every optional term, which fails a vault for declaring a vocabulary richer than
# the position it took - and a check that fires on a corpus doing the right thing
# is one somebody switches off. A vault with nothing to say about a subject never
# writes the word and stays silent here.
#
# MATCHED ON WORD BOUNDARIES, NOT AS A SUBSTRING. Both the candidate and the line
# are cut into lowercase alphanumeric tokens, and the candidate matches only as a
# consecutive run of the line`s tokens. Substring matching would fire `price` on
# `priceless` and `window` on `windows`, which is the crying-wolf shape
# --roadmap-table was scoped out of a release for once already.
#
# THE TERM OWNS ITS KEYS AND ALIASES FILL IN AROUND IT, the same precedence
# `check` applies when it resolves a subject: every term`s own key is registered
# first, then the aliases, and the first claimant of a key keeps it. That is what
# stops one term`s alias reporting a mention that belongs to a different term
# already carrying a note - a mention of `price` under a filed `price-anchor` is
# not evidence for an unfiled term that happens to list `price` as an alias.
#
# _vocab.yml IS NOT SCANNED, by construction rather than by exclusion: it is not
# markdown. Read, every term would match inside its own definition and its own
# aliases list, and every unfiled subject in the vault would report.
#
# A NOTE FILED UNDER AN ALIAS SPELLING COUNTS AS FILED, and `status` is not read.
# The alias spelling is check`s near-miss-subject and the retired note is the
# supersession sweep; reporting either here would name a second repair for a note
# that exists, under a message saying no note is filed at all.
#
# THE ALIAS LIST IS THE SENSITIVITY DIAL AND THE MODE DOES NOT SECOND-GUESS IT. A
# one-word alias is a broad one - `power` under `defensibility` fires on any
# sentence carrying the word - and the repair for that is the alias, not a
# heuristic here. _vocab.yml is the vault`s own file, curated per engagement, and
# a mode that decided which of its aliases to believe would be reasoning about
# the vocabulary instead of reading it.
#
# WHERE --binding-driver ALREADY REPORTS THE MISSING NOTE, this reports it too,
# and that is redundancy rather than a reader sent to the wrong fix: a plan
# rendering a verdict section with no note behind it fails verdict-unfiled there
# and subject-orphan here, and both name the same repair. Suppressing one would
# mean teaching a general mode the name of one subject, which costs more than the
# second line does.
#
# NOT GATED ON schemaVersion, because there is nothing to gate it on - the rule
# reads no field a corpus written before it lacks. It will turn an existing vault
# red on the version that adds it wherever that vault carries the gap, which is
# the intent rather than a cost: a corpus reasoning about a subject it never
# filed is the state this exists to surface, and a vacuous pass is worse than a
# red gate. What the failure message owes in exchange is the diagnosis - which
# note to write, and where the corpus is already leaning on the subject.
#
# LC_ALL=C for --used-in`s reason: plan prose carries em dashes and curly quotes,
# and macOS awk in a UTF-8 locale aborts the record on the first sequence it
# cannot decode, which would end a document scan early and pass a mention it
# never reached.
# ----------------------------------------------------------------------------

if [ "$MODE" = "subject-orphan" ]; then
	# Every markdown document under the vault, relative to its root and sorted
	# the way the PowerShell side sorts, so both implementations read the same
	# files in the same order and report the same FIRST mention of a subject.
	SUBJDOCS="$TMP/mddocs"
	(cd "$VAULT" && find . -type f -name '*.md' 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort) >"$SUBJDOCS" 2>/dev/null || : >"$SUBJDOCS"

	SO_OK=$(LC_ALL=C awk -v out="$FAILURES" -v docs="$SUBJDOCS" -v vault="$VAULT" -v hasvocab="$HAS_VOCAB" -F '\t' '
			BEGIN {
				while ((getline dl < docs) > 0) {
					sub(/\r$/, "", dl)
					if (dl != "") DOC[++ndoc] = dl
				}
				close(docs)
			}

			$1 == "T" { terms[++nterm] = $2; isterm[$2] = 1; required[$2] = $3; next }
			# Aliases are kept per term IN STREAM ORDER, which is file order: the
			# vocabulary pass emits every A record as it reads it and every T
			# record afterwards. Reporting has to be reproducible byte for byte
			# against the PowerShell side, and a set iterated in whatever order
			# the interpreter hands back is not.
			$1 == "A" { aliasof[$2] = $3; ALIAS[$3, ++AN[$3]] = $2; next }
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# Cut a string into lowercase alphanumeric tokens, and return how many.
			# Anything else - a hyphen, a space, punctuation, a byte outside ASCII
			# - is a separator, so `price-anchor`, `Price Anchor` and `price
			# anchor` all cut the same way and `priceless` cuts to one token that
			# is not `price`. Under LC_ALL=C the class is the ASCII range, so a
			# high byte falls outside it exactly as it does under a byte-at-a-time
			# comparison - this runs once per line of the corpus, and a per-byte
			# awk loop over the same text costs about twice the whole mode.
			#
			# split() with a single-space separator is awk`s default field
			# splitting: runs of blanks collapse and the leading and trailing ones
			# are dropped, so the caller gets exactly the non-empty tokens. It also
			# CLEARS arr first, which is what makes reusing one array across every
			# line safe without `delete arr` - a whole-array delete is an extension
			# POSIX awk does not have.
			function tokens(s, arr) {
				s = tolower(s)
				gsub(/[^a-z0-9]/, " ", s)
				return split(s, arr, " ")
			}

			# One candidate as the token run a line has to carry.
			function key(s,   n, i, o) {
				n = tokens(s, KT)
				o = ""
				for (i = 1; i <= n; i++) o = (i == 1) ? KT[i] : o " " KT[i]
				return o
			}

			# Register a key against the term that owns it, first claimant wins.
			# The longest candidate is tracked here because it bounds the scan: a
			# document line builds runs up to that length and no further, so it
			# costs a fixed number of lookups per token rather than one per
			# candidate. Read back off the key with split() rather than carried
			# out of key() in a global - one integer threaded between two
			# functions is a coupling that only holds while the caller keeps
			# evaluating them in the right order.
			#
			# nowners is what BOUNDS THE DOCUMENT SCAN: every registered term can
			# take at most one first mention, so once each has one there is nothing
			# left for a further document to say. Counted here rather than off the
			# unfiled set, because OWNER carries filed and required terms too and a
			# bound that ignored them would end the scan before an unfiled subject`s
			# first mention - a false NEGATIVE, which in this mode is the vacuous
			# pass the check exists to close.
			function own(k, t, spell,   n, part) {
				if (k == "" || (k in OWNER)) return
				OWNER[k] = t
				SPELL[k] = spell
				if (!(t in OWNS)) { OWNS[t] = 1; nowners++ }
				n = split(k, part, " ")
				if (n > maxlen) maxlen = n
				# Every token that OPENS a candidate. The scan skips a start
				# position whose token opens none, which is nearly all of them -
				# without it every position builds and hashes maxlen runs, so
				# lengthening one alias slows the whole corpus read. The alias list
				# is documented as the sensitivity dial, and this is what keeps
				# turning it up from costing runtime.
				FIRST[part[1]] = 1
			}

			# The line as it goes into the message: tabs to spaces, because the
			# failure stream is tab separated and a tab in the detail would split
			# the row; then trimmed. NOT truncated - a byte count and a character
			# count differ between the two implementations the first time a line
			# carries an em dash, and a message that disagrees across platforms is
			# what the parity gate exists to stop.
			function ctx(s) {
				gsub(/\t/, " ", s)
				sub(/^[ \t]+/, "", s)
				sub(/[ \t]+$/, "", s)
				return s
			}

			END {
				if (hasvocab != "1") {
					printf("no _vocab.yml under %s - there is no subject list to hold the corpus against, so no unfiled subject was looked for. `check` reports the missing vocabulary itself\n", vault)
					exit
				}
				if (nterm == 0) {
					printf("_vocab.yml under %s declares no terms, so there is no subject here that could be missing a note\n", vault)
					exit
				}

				for (i = 1; i <= nf; i++) {
					f = files[i]
					ty = V[f, "type"]
					# The pair that FILES a position. A `source` and a `fact` are
					# provenance a position rests on rather than the position, and
					# a `milestone`, `question` or `decision` asserts nothing about
					# the subject at all - the same closed set --assumption-rows
					# states at its own predicate, and stated here rather than left
					# as an omission for the same reason.
					if (ty != "claim" && ty != "assumption") continue
					s = V[f, "subject"]
					if (s == "") continue
					if (s in isterm) FILED[s] = 1
					else if (s in aliasof) FILED[aliasof[s]] = 1
				}

				# A `required: true` subject is coverage-gap`s, and this mode never
				# asks after one. The two partition the vocabulary rather than
				# overlapping on it: a required subject owes a note whether or not
				# any document mentions it, so the mention adds nothing to a repair
				# coverage-gap already demands - and one omission reported as two
				# failures under two names sends its reader looking for two.
				for (i = 1; i <= nterm; i++) {
					t = terms[i]
					if (required[t] == "true") continue
					nasked++
					if (!(t in FILED)) nunfiled++
				}

				# EVERY TERM REGISTERS ITS STRINGS - filed and required ones
				# included - AND THE PARTITION IS APPLIED WHERE THE ROW IS
				# REPORTED, not here. A filed term has to CLAIM its own key and its
				# aliases for that claim to mean anything: registering only the
				# unfiled terms leaves a filed term`s strings unowned, so an unfiled
				# term listing the same alias picks up a mention that was always
				# about the subject the vault has already answered. Observed on a
				# vocabulary where `price` is an alias of a FILED `price-anchor` and
				# of an unfiled `willingness-to-pay`: a sentence discussing
				# price-anchor was reported as evidence that willingness-to-pay is
				# load-bearing, under a message stating the corpus reasons from it.
				# This mode ships failing and ungated, so a confident false positive
				# is the thing that makes somebody stop upgrading.
				#
				# Terms first, then aliases, so a string that is both a term and
				# another term`s alias belongs to the term - the precedence `check`
				# applies when it resolves a subject. Past that it is FIRST CLAIMANT
				# WINS in vocabulary order, and that is now load-bearing rather than
				# incidental: two terms listing one alias is the vault`s own
				# ambiguity, and letting file order settle it is a rule an author
				# can read off _vocab.yml instead of a judgement this mode makes for
				# them.
				for (i = 1; i <= nterm; i++) own(key(terms[i]), terms[i], terms[i])
				for (i = 1; i <= nterm; i++) {
					t = terms[i]
					for (j = 1; j <= AN[t]; j++) own(key(ALIAS[t, j]), t, ALIAS[t, j])
				}

				# Nothing unfiled is nothing to look for, and opening every
				# document to prove it would be a corpus read with no question
				# behind it.
				for (d = 1; nunfiled > 0 && nfound < nowners && d <= ndoc; d++) {
					path = vault "/" DOC[d]
					ln = 0
					while ((getline line < path) > 0) {
						ln++
						sub(/\r$/, "", line)

						# A `subject:` line is the note declaring what it is filed
						# under, which is the one place the word appears without
						# the corpus reasoning from it. Matched wherever it appears
						# rather than only inside frontmatter, so a note template
						# quoted inside a fenced block is out under the same rule.
						if (line ~ /^[ \t]*subject:/) continue

						nt = tokens(line, LT)
						for (i = 1; i <= nt; i++) {
							if (!(LT[i] in FIRST)) continue
							for (L = 1; L <= maxlen && i + L - 1 <= nt; L++) {
								k = (L == 1) ? LT[i] : k " " LT[i + L - 1]
								if (!(k in OWNER)) continue
								t = OWNER[k]
								if (t in HITDOC) continue
								nfound++
								HITDOC[t] = DOC[d]
								HITLN[t] = ln
								HITTXT[t] = ctx(line)
								HITSPELL[t] = SPELL[k]
							}
						}
					}
					close(path)
				}

				# In vocabulary order, so two runs over one vault report in the
				# same order, and the file the failure is attached to is the
				# DOCUMENT CARRYING THE MENTION rather than _vocab.yml - which is
				# where coverage-gap attaches, and the difference is deliberate.
				# That check has nothing to show a reader: the vocabulary declared
				# a subject and no note answered it, and the file column can only
				# name the declaration. Here the mention is the evidence and the
				# place the repair gets decided, so the column carries a path worth
				# opening.
				for (i = 1; i <= nterm; i++) {
					t = terms[i]
					if (!(t in HITDOC)) continue
					# THE PARTITION, APPLIED HERE rather than at registration. A hit
					# whose owner turns out to be filed or required has still
					# CONSUMED the key, so no unfiled term can claim that mention -
					# it just is not a row.
					if (required[t] == "true" || (t in FILED)) continue
					report(HITDOC[t], "subject-orphan", t,
						"no `claim` and no `assumption` is filed under the vocabulary subject `" t "`, and the corpus reasons from it anyway: " HITDOC[t] " line " HITLN[t] " reads `" HITTXT[t] "`" (HITSPELL[t] == t ? "" : ", which carries the alias `" HITSPELL[t] "`") ". Write the note - a `claim` under `subject: " t "` where the position has evidence behind it, an `assumption` where it does not. Unfiled, the subject cannot collide with a contradiction, cannot go stale, cannot be superseded and cannot be challenged, so every query the ledger supports returns clean over it and the document leaning on it is the only place the position exists. This is not coverage-gap, which asks only after subjects marked `required: true`")
				}

				# Which half ran and which had nothing to run over, rather than a
				# verdict the mode did not reach: a vocabulary of nothing but
				# required subjects is coverage-gap`s whole population, and a line
				# reading as a pass over it would report agreement about a question
				# this mode never asked.
				if (nasked == 0)
					printf("every subject in _vocab.yml is marked `required: true`, which is coverage-gap`s question and not this one - no optional subject was asked after here - %s\n", vault)
				else if (nunfiled == 0)
					printf("%d vocabulary subject%s not marked `required: true`, every one of them carrying a `claim` or an `assumption` - %s\n",
						nasked, (nasked == 1 ? "" : "s"), vault)
				else
					printf("%d of the %d vocabulary subject%s not marked `required: true` ha%s no `claim` and no `assumption` filed under it, and no line of the %d markdown document%s under this vault mentions any of them - a subject nothing leans on is not a gap - %s\n",
						nunfiled, nasked, (nasked == 1 ? "" : "s"), (nunfiled == 1 ? "s" : "ve"), ndoc, (ndoc == 1 ? "" : "s"), vault)
			}
		' "$RECORDS")

	render_failures "vault-lint subject-orphan" "$SO_OK"
	exit $?
fi

# ----------------------------------------------------------------------------
# --foreclosed - the assertions that take an option off the table
#
# Every other adversarial mechanism in this method fires on a plan claiming too
# much. A note asserting that an option is NOT viable claims too little, and it
# is the most expensive assertion in the corpus: it removes work from the
# roadmap, kills a segment, or takes a configuration off the table. All three
# panel lenses are pointed at whether the plan can deliver what it promises and
# none at whether it wrongly concluded it could not, so nothing attacks it.
#
# THE FAILURE IS SILENT BY CONSTRUCTION, which is what separates this from
# every check that reads an edge. The option is gone, so nothing downstream
# references it, so no query has a target: the foreclosure cannot dangle,
# cannot go stale in a way anybody notices, and cannot collide with the work it
# cancelled, because that work was never written down. What the corpus can be
# held to is the CONDITION - the input value that would put the option back -
# and that is the whole of this mode.
#
# THE VERDICT MIRRORS `validated_by` ONE FIELD OVER. An assumption owes the step
# that would settle it; a foreclosure owes the value of `foreclosed_on` that
# would reverse it. Both are assertions somebody has to write down, both are
# checkable, and neither is evidence the thinking was done - what they remove is
# skipping it by DEFAULT, which is what a foreclosure held to nothing had been.
#
# `claim` ONLY, AND --subject-orphan's CLOSED PAIR DOES NOT TRANSFER HERE. That
# rule asks which types FILE a position and the answer is both; this one reads
# fields that are claim-only BY ARGUMENT, because a foreclosure is a conclusion
# drawn from an input and `foreclosed_on` is where that input is named - a note
# resting on nothing has no input to name. So an option taken off the table by
# an `assumption` is not a foreclosure missing a field, it is an assumption in
# the shape of a finding, and vault.md`s repair is to file the `question` the
# plan stopped asking rather than to dress the note in these three.
#
# READING BOTH TYPES HERE WOULD GIVE THE WRONG REPAIR UNDER THE RIGHT NAME - a
# reader told to add `reverses_if` dresses the category error in three fields
# and ships it green, which is worse than the gap. The dodge that would open by
# narrowing is closed in `check` instead: an `assumption` carrying any of the
# three is its own failure there, under a name that sends its reader to the
# question. Two rules, two repairs, and neither says the other`s sentence.
#
# `status` IS READ AND A RETIRED FORECLOSURE OWES NOTHING - the live predicate
# --assumption-rows learned. A `superseded` or `retracted` note has already been
# taken back, so demanding a reversal condition of it names a repair on a note
# the ledger has retired.
#
# NOT gated on schemaVersion, and it does not need to be: the trigger is the
# PRESENCE of `forecloses`, so a corpus that never wrote the field cannot owe
# anything here. That is the exemption a version buys, obtained without spending
# one, on the terms `superseded_by`'s two rules are on.
# ----------------------------------------------------------------------------

if [ "$MODE" = "foreclosed" ]; then
	FC_OK=$(awk -v out="$FAILURES" -v vault="$VAULT" -F '\t' '
			$1 == "N" { files[++nf] = $2; next }
			$1 == "S" { V[$2, $3] = $4; next }
			$1 == "L" { k = $2 SUBSEP $3; LI[k, ++LN[k]] = $4; next }

			function report(file, check, id, detail) { print file "\t" check "\t" id "\t" detail >> out }

			# The same present() the checks pass and --binding-driver use, and
			# copied verbatim rather than written as `V[f, k] != ""` for their
			# reason: all three programs implement the same trigger, and a field
			# authored as a one-item block list is present to one test and absent
			# to the other. Here that divergence would exempt a note from the
			# reversal condition purely by how the field was formatted. Three
			# copies now - the checks pass, --binding-driver and this one. Change
			# one, change all three.
			function present(f, k) { return (V[f, k] != "" || LN[f SUBSEP k] > 0) }

			# The same field as TEXT, for the message. Scalar where there is one,
			# otherwise the block-list items joined - so a value the trigger can
			# see is a value the message can print, and the two cannot disagree
			# about whether the field is there.
			function textof(f, k,   kk, i, o) {
				if (V[f, k] != "") return V[f, k]
				kk = f SUBSEP k
				o = ""
				for (i = 1; i <= LN[kk]; i++) o = o (i == 1 ? "" : ", ") LI[kk, i]
				return o
			}

			# The document sections a note reached, which is where a foreclosure
			# has to be argued with. A note carrying none is reported as such
			# rather than skipped: a conclusion that took an option off the table
			# and reached no document is a decision nothing renders.
			function cited(f,   kk, i, o) {
				kk = f SUBSEP "used_in"
				if (LN[kk] == 0) return "no used_in entry"
				o = ""
				for (i = 1; i <= LN[kk]; i++) o = o (i == 1 ? "" : ", ") LI[kk, i]
				return o
			}

			END {
				# Every ID this vault carries, for the dangling test below.
				# Built here rather than threaded in, because this mode is the
				# only reader of `foreclosed_on` and the index costs one pass.
				for (i = 1; i <= nf; i++) {
					if (V[files[i], "id"] != "") HASID[V[files[i], "id"]] = 1
				}

				for (i = 1; i <= nf; i++) {
					f = files[i]
					id = V[f, "id"]
					ty = V[f, "type"]
					if (id == "") continue
					if (ty != "claim") continue
					if (V[f, "status"] != "current") continue
					if (!present(f, "forecloses")) continue

					# Read once and used by both the listing and the failure,
					# because cited() walks the whole used_in list to build its
					# string and calling it twice for one note walks it twice.
					what = textof(f, "forecloses")
					where = cited(f)

					nfc++
					listed = listed (nfc == 1 ? "" : "; ") id " forecloses " what " (" where ")"

					# `foreclosed_on` names the input the conclusion rests on,
					# and it is a SCALAR - so `check`s dangling-edge rule,
					# which walks the block-list edge fields, never opens it.
					# The same gap `superseded_by` has, answered the same way:
					# its own rule rather than a silent omission.
					#
					# What a dangling one costs is specific to this field. The
					# floor skeptic is briefed off this mode`s output with
					# `foreclosed_on` in it, so a target naming nothing sends
					# the one lens pointed at the foreclosure to a note that
					# does not exist. The lens reports nothing, and a lens that
					# found nothing is indistinguishable from a foreclosure
					# that survived attack - the vacuous pass this release
					# exists to close, shipped by the release closing it.
					fon = textof(f, "foreclosed_on")
					if (fon != "" && !(fon in HASID))
						report(f, "foreclosed-on-dangling", id, "`foreclosed_on: " fon "` and no note in this vault carries that ID. The conclusion names the input it rests on and that input cannot be opened, so nothing can be re-read to overturn the foreclosure - either the note was never written, or the ID is a typo. It is the brief the floor skeptic is dispatched with, so a dangling target sends the one lens pointed at this conclusion to a note that does not exist, and a lens that found nothing reads exactly like a foreclosure that survived being attacked. `check`s dangling-edge rule walks the block-list edge fields and never this scalar, so nothing else in this tool reports it")

					if (present(f, "reverses_if")) continue
					report(f, "foreclosure-no-reverse", id, "`forecloses` names " what " and the note carries no `reverses_if`. Taking an option off the table removes work from the roadmap, kills a segment or rules out a configuration, and it is the one class of assertion nothing in this method attacks - every panel lens asks whether the plan can deliver what it promises and none asks whether it wrongly concluded it could not. With no reversal condition the conclusion is permanent and the corpus records nothing it was conditional on, which is unfalsifiable rather than settled: the option is gone, so nothing downstream references it and no other check has a target to fire on. State `reverses_if` - the value of `foreclosed_on` that would put the option back on the table - the way an `assumption` states `validated_by`. Cited into: " where)
				}

				# Which half ran, not what it would have concluded. A vault where
				# nothing forecloses has no population here, and a line reading as
				# a pass over it would report agreement about a question this mode
				# never got to ask.
				if (nfc == 0)
					printf("no `current` claim under %s carries `forecloses` - nothing in this corpus takes an option off the table, so there is no foreclosure here to hold to a reversal condition\n", vault)
				else
					printf("%d `current` note%s take%s an option off the table and every one of them declares what would put it back: %s - %s\n",
						nfc, (nfc == 1 ? "" : "s"), (nfc == 1 ? "s" : ""), listed, vault)
			}
		' "$RECORDS")

	render_failures "vault-lint foreclosed" "$FC_OK"
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

	# The representative of one `market-size` population`s component, for the
	# nesting rule below. Plain union-find over PAR[], with path halving so a
	# long chain does not cost its length on every lookup - three rings is the
	# common case and a deep one is still linear to build. Iterative rather
	# than recursive because the population set is corpus data and a recursive
	# walk over it would be bounded by whatever the corpus happens to hold.
	function pop_root(x) {
		while (PAR[x] != x) {
			PAR[x] = PAR[PAR[x]]
			x = PAR[x]
		}
		return x
	}

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

			# --- nested populations, at schemaVersion 4 ---------------------
			# Two `current` claims under one subject are a collision, and
			# vault.md resolves one three ways: supersede a side, add a
			# `scopes` edge because one is narrower, or discover the two
			# genuinely disagree. Under `market-size` there is a fourth state
			# none of those describes - the populations are BOTH right and one
			# sits inside the other, a behavioural cut inside a professional
			# population inside a broader one - and `nested_in` is the edge
			# that records it.
			#
			# Collected here and reported after the loop, because the failure
			# is a property of a GROUP: neither claim is the wrong one, exactly
			# as false-independence above.
			#
			# A note whose `id` never parsed is left out, because the edge test
			# below matches an ID against an ID and an empty one would relate
			# every unidentified note to every other.
			if (schema + 0 >= 4 && ty == "claim" && id != "" &&
			    V[f, "status"] == "current" && V[f, "subject"] == "market-size") {
				POP[++NPOP] = f
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

		# The `market-size` populations, and whether the corpus says how they
		# sit inside each other. THE TEST IS CONNECTIVITY, NOT WHETHER EACH
		# NOTE CARRIES AN EDGE, and vault.md states the contract in those
		# words: what it asks for is that the claims under one subject are
		# connected, never that every combination carries a direct edge.
		# Reachability is walked TRANSITIVELY, so three rings are satisfied by
		# two edges - the innermost names the middle, the middle names the
		# outermost - which is the shape a plan that sized properly has, and
		# demanding the third edge would ask for a fact already derivable from
		# the other two.
		#
		# A per-note "does this one carry an edge" test passes a corpus the
		# contract fails, and the case is not exotic: two nested PAIRS under
		# one subject, each internally edged and neither related to the other,
		# leaves every note carrying an edge and the set still holding two
		# unrelated ring systems. A share figure is then a percentage of
		# whichever system its reader assumed, which is the whole failure.
		# So the edges are unioned and the components counted.
		#
		# The edge is undirected here, because the question is whether a pair
		# is RELATED and not which way round: A naming B is the same statement
		# about the pair as B naming A, and a rule reading only the narrower
		# end would fail a corpus that wrote the edge from the other one.
		#
		# THIS RULE TESTS RESOLUTION ITSELF rather than leaning on the
		# dangling-edge rule to have caught a bad target first, and the choice
		# matters: `nested_in` is in EDGE_FIELDS so dangling-edge does fire on
		# a typo, but that rule is UNGATED and this one is gated on
		# schemaVersion 4 - two rules with different triggers, and a nesting
		# check that assumed its sibling had already run would be assuming
		# something the gate does not guarantee. So targets resolve through
		# BYID, the index every other edge-reading check in this pass uses, and
		# a `nested_in` naming no note in the vault links NOTHING.
		#
		# The failure that closes: a typo would otherwise satisfy this check.
		# The corpus would read as nested, the rule would clear, and nothing
		# anywhere would say the edge points at a note that does not exist -
		# a vacuous pass of exactly the shape this mode was added to remove.
		# Resolved this way the typo is TWO failures, which is right: a
		# dangling-edge naming the bad target, and a population-unnested saying
		# the ring is still unrecorded. They are different repairs.
		#
		# The scalar and the block-list spelling are both read, for the reason
		# present() reads both: a note that wrote its edge as a list would
		# otherwise be exempt by formatting.
		for (i = 1; i <= NPOP; i++) { POPAT[POP[i]] = i; PAR[i] = i }
		for (i = 1; i <= NPOP; i++) {
			f = POP[i]
			nnest = 0
			if (V[f, "nested_in"] != "") NEST[++nnest] = target_of(V[f, "nested_in"])
			k = f SUBSEP "nested_in"
			for (j = 1; j <= LN[k]; j++) NEST[++nnest] = target_of(LI[k, j])
			for (j = 1; j <= nnest; j++) {
				tgt = NEST[j]
				if (!(tgt in BYID)) continue
				if (!(BYID[tgt] in POPAT)) continue
				ra = pop_root(i)
				rb = pop_root(POPAT[BYID[tgt]])
				if (ra != rb) PAR[ra] = rb
			}
		}

		# Reported per NOTE rather than per group, which is where this differs
		# from false-independence and duplicate-url above. There the whole group
		# is implicated and neither member is the wrong one; here each row names
		# the claims THIS one has no chain to, so the note a reader opens tells
		# them which ring is still unrecorded - and a note already connected to
		# everything is not a row at all.
		if (NPOP >= 2) for (i = 1; i <= NPOP; i++) {
			f = POP[i]
			unreached = ""
			for (j = 1; j <= NPOP; j++) {
				if (j == i || pop_root(j) == pop_root(i)) continue
				unreached = unreached (unreached == "" ? "" : ", ") V[POP[j], "id"]
			}
			if (unreached == "") continue
			report(f, "population-unnested", V[f, "id"], "`subject: market-size` is carried by " NPOP " `current` claims and no `nested_in` chain connects this one to: " unreached ". Two live claims under one subject are a collision, and under this subject the collision is usually not a contradiction - a behavioural cut sits inside a professional population sits inside a broader one, and every one of the figures is right. Nothing in the corpus says which contains which, so a share figure is a percentage of whichever population its reader assumed, and taking the innermost silently produces the smallest share available - which then reads as conservative rather than as a decision nobody made. The chain is walked transitively, so three rings are two edges rather than three: add `nested_in` naming the ring immediately outside this claim, or supersede one side if the two genuinely disagree")
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
