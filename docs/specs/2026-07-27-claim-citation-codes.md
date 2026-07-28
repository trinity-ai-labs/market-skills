# Claim notes and the citation code they do not have

Decision on whether `claim` notes get a `[C#]` citation code and an index file, for the
Phase 3→4 reconciliation gate that checks a document's prose against the ledger it cites.

Status: decided — B now, A later.

## Two of three note types resolve prose to a note; `claim` does not

Checking that a document section actually **carries** a claim it cites needs prose→note
resolution: given a section of rendered prose, find the note IDs it is standing on. The corpus
already has that machinery for two of the three note types a plan cites, and not for the third:

| type | prose code | resolves through |
|---|---|---|
| `source` | `[S#]` | `sources.md` |
| `fact` | `[F#]` | `research/founder-brief.md` |
| `claim` | — | — |

A `fact` or a `source` citation in prose is a code, and the code is a lookup key into a file
that exists for exactly that purpose. A `claim` citation in prose is not a code at all — the
prose states the assertion in its own words, with no token a lint can grep for and no index to
resolve it against. The two working cases make the gap in the third one visible rather than
papering over it: the corpus has already solved this problem twice, in the same shape, and
solved it a third way — not at all — for the note type most of a plan's reasoning rests on.

## Option A: give `claim` notes a `[C#]` code and an index file

Match the existing pattern exactly. Every `claim` note gets a `[C#]` code, assigned the same way
`[S#]` and `[F#]` are — at a single merge point, by the conductor, never by a parallel writer —
and a `claims.md` index resolves each code back to its note. Prose→note resolution then works
uniformly for all three types, and the agreement check becomes mechanical: the lint reads a
section, pulls every code it contains, and asserts the note's ID is among what those codes
resolve to. No judgment step, no read — a grep and a set-membership test.

The cost is what it changes on the way there. A `[C#]` scheme is not a lint-internal detail; it
is a change to what every plan document looks like, because a claim currently reads as an
assertion in the author's own words and would start reading as an assertion plus a bracketed
code. It is also a change to what every migration into the vault has to produce, since an
imported plan citing claims in prose would need codes assigned and back-filled before the new
resolution could apply to it at all. Both changes are real design work — where in the sentence
the code goes, how a multi-claim sentence is coded, what an uncoded legacy claim renders as until
migrated — none of which is settled by this decision.

## Option B: leave the prose alone and bound the read instead

Leave `claim` citations as they are — an assertion in prose, uncoded — and do not build
resolution for them. The Phase 3→4 gate becomes a **read over a bounded worklist that the lint
itself emits**, rather than a mechanical check:

- `--used-in` proves the mechanical half: every target a note's `used_in` field names is a file
  that exists and an anchor inside it that resolves. This is unconditional and already
  independent of the `[C#]` question — it fires for every note type, whatever the set is.
- `--supersession-sweep` names the sections a supersession put in doubt: when a note's status
  moves to `superseded`, the sweep walks every `used_in` target that pointed at the old note and
  reports the section, so nothing has to be re-derived by hand.

The gate is: a conductor reads those named sections against those notes, at the Phase 3→4
boundary, before any red-team panelist is dispatched. The lint's job is to make that worklist
small and specific — a list of (section, note) pairs to look at — not to decide agreement
itself. Nothing about the corpus's citation surface changes; `claim` prose stays exactly as
authors already write it.

## The decision: B now, A later

**B now, A later.** B catches the failure this gate exists to prevent — a red team briefed on a
plan the ledger already disagrees with — without settling the corpus's citation style as a side
effect of a linter. A `[C#]` scheme changes what every plan document looks like and what every
migration into the vault has to produce; that is a real design surface with its own worked
examples and edge cases, and it earns its own design pass rather than arriving as the
implementation detail that happened to make one check convenient to write.

## What B costs: the agreement half is a judgment step, and that is not free

Stated so it is not discovered later, mid-release, by whoever writes the gate: the mechanical
half (`--used-in` resolving) is a lint, and a lint either runs or it does not — there is no
version of "half-ran the resolution check." The agreement half (does the section actually say
what the note claims) is a **read**, and a read is a judgment step a person can skip under
pressure in a way a lint cannot be skipped. A gate that depends on someone choosing to do the
reading, every time, is weaker than one a script enforces — that is the entire tradeoff this
option accepts in exchange for not building the `[C#]` machinery yet.

That is why the agreement check does not live as a line inside the Phase 3→4 gate's own step —
it lands as a numbered invariant in the head block instead. Compaction re-attaches only the head
of a long-running skill file, so a rule stated only inside a phase's body is out of context by
the time that phase actually runs, and a gate that is out of context when its phase runs is a
gate that does not run. Stating it as a head-level invariant is what keeps a judgment-shaped,
skippable check from quietly becoming an optional one.

## What would reopen this toward A

The trigger is the read proving too large to be bounded in practice — a worklist that routinely
runs past what a conductor will actually read before dispatching a panelist. A worklist of a
handful of (section, note) pairs is a read a conductor does; a worklist of dozens, appearing
often enough to become the normal case rather than the unusual one, is a read that gets skimmed
or skipped, which is exactly the failure mode this decision is trying to avoid by picking B in
the first place. `--supersession-sweep`'s own reported count is the instrument for this: it is
already producing a number as a side effect of naming the affected sections, so no separate
measurement has to be built to notice the trend. When that count is routinely too large for a
one-pass read, the case for B is gone and Option A's mechanical resolution — which does not grow
harder to apply as the worklist grows — is worth the design pass it was deferred pending.
