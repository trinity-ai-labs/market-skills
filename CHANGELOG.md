# Changelog

Versions are the `version` field in `.claude-plugin/plugin.json`. Because that field is set, an installed plugin only picks up changes when it **changes** — pushing to `main` alone ships nothing. CI enforces the bump.

## 1.19.0

**Two issues, and one argument pointed in two directions.** 1.18.0 opened the *absence is not
success* family — a check that cannot find its subject has to say so rather than report agreement.
This release runs that out past the success line and into the corpus. A `[F#]` or `[S#]` that
resolves to nothing renders exactly like one that works, and the reader who follows it is the one
person who cannot check it. A vocabulary subject the documents argue from and no note was ever
filed under returns clean from every query the ledger supports, because there is nothing filed to
return. And a plan claiming **too little** — a segment killed on a technicality, a configuration
ruled out, a share figure counted against the narrowest population in the vault — clears every
guard in the tool, because each of them was built to catch a founder claiming too much. Four new
gate parts, four new note fields, `schemaVersion` 4, and a fourth red-team lens pointed at the
understatement.

**Read this before upgrading: `--subject-orphan` is this release's one breaking check, and it is
not gated on `schemaVersion` because there is no field to gate it on.** Every other rule
shipped here fires on the presence of a field no existing corpus carries, so nothing written
before it can owe anything — the exemption a version buys, obtained without spending one.
`--subject-orphan` reads a vocabulary term, the `subject` on a `claim` or an `assumption`, and the
words already in the documents. Nothing about it is new to a finished vault, so **a corpus that
already carries the gap goes red on the day the plugin updates.** That is the intent rather than a
cost: a plan reasoning about a subject the ledger has never held is exactly the state the mode
exists to surface, and a vacuous pass over it is worse than a red gate.

**The repair is one note per reported subject, and the failure hands you the whole diagnosis.** It
names the subject, the document, the line number, the line the corpus leans on it from, and which
note to write — a `claim` under that `subject` where the position has evidence behind it, an
`assumption` where it does not. Where the mention turns out to be incidental rather than a
dependence, the term was declared in `_vocab.yml` by a corpus with nothing to say about it and the
honest repair is in that file. Either way it is a five-minute fix, which is the whole reason the
message is a diagnosis instead of a verdict: a red gate that only states a verdict is a support
request.

- **`--citation-codes` — a cited code that resolves to nothing cleared the gate.**
  `--used-in` opens the document and section a *note* names; plan prose cites `[F#]` and `[S#]`,
  which resolve through `research/founder-brief.md` and `sources.md`. That contract was written
  down and enforced by nothing, so a dead code was indistinguishable from a working one at render
  time. The mode scans every markdown document at the vault root and under `research/` and reports
  `citation-code-no-source-row` or `citation-code-no-fact-row` — separate kinds because the two
  repairs open different files. **The two index files are excluded from the scan, and that is
  load-bearing rather than an optimisation:** an index legitimately records that a code was
  withdrawn and left unused, which names that code in its own prose, and a scan reading the mention
  as a citation fails a corpus doing the right thing. It runs **forward only** — cited with no row
  fails, a row nothing cites does not — because a recorded fact nothing leans on yet is healthy,
  and failing it would push an author toward citing things to silence a linter.
- **And its success line says what it did not check, because resolution is necessary and not
  sufficient.** A research file carries its own local `S` table, so a document citing a local code
  the global log also assigns resolves to a row *and* to a different source — which no count of
  resolving codes can see. Observed on four documents at once, every code resolving. The line names
  that limit rather than reporting the count alone, which is the same rule 1.18.0 taught the other
  success lines one level down.
- **`--unflattened-source` closes the half of that a check can reach.** Every row of a
  `research/*.md` local source table names a URL, and `source-unflattened` fails one the root
  `sources.md` carries nowhere: the log is what assigns a citable `[S#]`, so such a source can be
  cited from research prose and cannot be cited from a plan document at all. The kind is
  deliberately **not** `orphan-source`, which the bare check already reports for close to the
  opposite finding — one is a source nobody cited, the other a source nobody *can* cite. **The
  declared exemption is what decides whether the mode survives:** a corpus may deliberately keep a
  hundred-and-fifty-row per-profile ledger out of the log, and a mode reporting every one of them
  is switched off within a day, taking the working half with it. So the exemption is read from the
  log's own header — a `Local ledger: <path> - <why>` line before the log's first table row —
  rather than keyed on a filename the script knows, because the file holding a ledger differs per
  corpus and a hardcoded name only ever fits the vault it was written against. A row carrying no
  URL is neither resolved nor failed; the success line counts those, so a table of unlinkable rows
  cannot read as a table that agreed.
- **`--foreclosed` — the first mode in this tool pointed at a plan claiming too little.** A claim
  of the form *X is not credible* or *this rules out Y* does not add a position, it removes one:
  work off the roadmap, a segment killed, a configuration off the table. It is the
  highest-consequence class of claim in a plan and the only one nothing attacked — all three panel
  lenses asked whether the plan can deliver what it promises and none asked whether it wrongly
  concluded it could not. **The failure is silent by construction:** the option is gone, so nothing
  downstream references it, so no check has a target. Three fields make it arguable —
  `forecloses` (the option in the words the plan uses), `foreclosed_on` (the one input the
  conclusion rests on, as an ID so `graph` can walk to it) and `reverses_if` (the value of that
  input that would put the option back). `foreclosure-no-reverse` fails a `current` `claim`
  carrying the first with none of the last. It is `validated_by` pointed the other way and it
  carries that rule's honest limit: a stated reversal condition is not evidence the thinking was
  done, only that skipping it stopped being the default.
- **The passing side of `--foreclosed` is a listing rather than a bare pass**, because the mode
  feeds the red-team panel as well as the gate: it names every foreclosure with the section its
  `used_in` reached, and a vault where nothing forecloses is told which half did not run rather
  than that its conclusions agree.
- **`foreclosed-on-dangling` is the mode's second kind, and it exists because `foreclosed_on` is a
  scalar.** The bare check's dangling-edge rule walks the block-list edge fields and never opens a
  scalar note reference — the same gap `superseded_by` has, and it gets the same answer: a rule of
  its own rather than a silent omission. The cost here is specific. The floor skeptic is briefed
  off this mode's output with `foreclosed_on` in it, so a dangling target dispatches the one lens
  pointed at the foreclosure to a note that does not exist — and a lens that found nothing reads
  exactly like a foreclosure that survived being attacked, which is the vacuous pass this release
  exists to close.
- **`--foreclosed` reads `claim` notes only, and `check`'s `foreclosure-on-assumption` closes the
  dodge that looks like it opens.** A foreclosure is a conclusion drawn from an input and
  `foreclosed_on` is where that input is named, so a note resting on nothing has no input to name:
  an option taken off the table by an *assumption* is not a foreclosure missing a field, it is an
  assumption in the shape of a finding, and the repair is the `question` the plan stopped asking.
  Reading both types would hand that reader the wrong repair under the right name — the message
  says add `reverses_if`, and following it dresses the category error in three fields and ships it
  green. So the bare check reports it under its own name, and deliberately not as `type-agreement`,
  which would send a reader to look at `type`, read `assumption`, and stop.
- **A retired foreclosure owes nothing.** `status` is read, so a `superseded` or `retracted` note
  is not asked for a reversal condition — the same live predicate 1.18.1 taught `--assumption-rows`
  three checks over. Demanding a repair on a note the ledger has already taken back is a repair
  nobody can make.
- **`check`'s `population-unnested` — a share figure was a percentage of whichever population its
  reader assumed.** Where a corpus holds nested populations under one `market-size` subject — a
  behavioural cut inside a professional population inside a broader one — the subject-collision
  query does not fire, because nested populations are not contradictory. Taking the innermost
  silently produces the smallest share available, which then reads as conservative rather than as a
  decision nobody made. `nested_in` records which population contains which, and the rule fails a
  `market-size` subject holding two or more `current` population claims with no such chain between
  them, naming both repairs — either the pair genuinely collides and one figure is wrong, or the
  edge is missing.
- **What it tests is connectivity, not whether each note carries an edge**, and the two look
  equivalent and are not. Reachability is walked transitively, so three rings are satisfied by two
  edges and demanding the third would ask for a fact the other two already derive. The distinction
  is what the rule is for: two nested *pairs* under one subject, each internally edged and neither
  related to the other, leaves every note carrying an edge while the set still holds two unrelated
  ring systems — the exact failure the edge exists to remove, surviving the check added to remove
  it.
- **`nested_in` joins `EDGE_FIELDS`, and the rule also resolves the target itself — both halves,
  for different failures.** In the set, a mistyped edge is a `dangling-edge` under its own name and
  `graph` walks the ring. Resolving it here as well is what stops a typo *satisfying* the check:
  read as a bare relation, `nested_in: CLAIM-TYPO` makes the corpus look nested, the rule clears,
  and nothing anywhere says the edge points at nothing — a vacuous pass handed back by the check
  written to refuse one. A typo is therefore two findings with two repairs, which is correct.
- **`schemaVersion` 4 joins the supported set (`1 2 3 4`), and it buys exactly one rule —
  conflating that with the three new fields would have turned every existing corpus red.** The
  nesting rule is gated because it fires on a shape a correct corpus *already has*: a plan that
  sized properly carries several `current` population claims under `market-size`, none of them
  wrong, so ungated it would fail every vault that did the work, for a reason having nothing to do
  with what changed. Correct and unusable is what a version buys out of. The three foreclosure
  fields ship **additive at the current version and behind no version at all**, because their
  trigger is the *presence* of `forecloses` — a corpus written before the field declares nothing
  and can owe nothing, so a version spent there would buy an exemption over an empty population.
  One release, two decisions, and the distinction is the whole point of the field.
- **A fourth red-team lens: the floor skeptic, briefed to argue the plan is too pessimistic.** Was
  a killed segment killed on a technicality? Is the denominator the narrowest population the corpus
  holds, with wider ones sitting beside it? Does a *not credible* conclusion rest on an input
  nobody sourced? **It arrives with a worklist rather than an instruction to go looking, and that
  is the design.** The other three lenses attack what the plan says; this one attacks what the plan
  stopped saying, which leaves nothing on the page to read — so a brief telling it to find
  understatement would be telling it to find an absence. Its brief carries `--foreclosed`'s output
  and the red-team pre-pass's inputs unmodelled in the pessimistic direction, which until now was a
  report no lens was answerable for.
- **A share figure names the population it is a share of.** The new invariant is the method half of
  the nesting rule: where the corpus holds nested populations under one subject the plan reports
  the set rather than the innermost member alone. What it adds over the lint is that the
  substitution is invisible at the render — the figure is real, the formula behind it is correct,
  and the wider counts sit in the same directory.
- **Contributor tooling only, shipped to nobody: `scripts/parity/parity.mjs` is about three times
  faster and no longer disguises a dead harness as a parity disagreement.** The sweep is almost
  entirely spent waiting on PowerShell startup, so cells now run through a bounded worker pool —
  501s serial to 157s pooled on an idle box — with results read back in mode × fixture order rather
  than completion order, so two runs are byte-identical and a reviewer can diff one log against
  another. Separately, a PowerShell host killed by a signal reported as `exit status: .sh 1,
  .ps1 134`, which reads as the two implementations answering a vault differently and sent a
  reviewer hunting a port bug that did not exist. The tool documents exit 0, 1 and 2 and nothing
  else, so anything outside that set was not produced by the tool: such a cell is now reported in
  its own voice, is not counted as compared, and routes to exit 2. No user-facing behaviour
  changes.

## 1.18.1

**The theme of 1.18.0 pointed at itself.** That release was about checks whose success line could
not tell *agreed* from *had nothing to check*. Three checks in it turned out to have the same shape
one level down: they walked a set without asking whether its members were still **live**, and
answered confidently over notes the ledger had already retired. `model-row-dead-assumption` read
which *type* held the note instead of its status; `assumption-not-in-model` and
`excluded-line-on-roadmap` read the field that declares an input without reading the status beside
it. A set read without its status filter reports cleanly either way, which is why all three shipped.

- **`model-row-dead-assumption`, shipped an hour earlier in 1.18.0, failed a model row that was
  correctly backed — by a `claim` rather than an `assumption`.** The row → note direction indexed
  `assumption` titles only, so a row whose backing note had been *promoted* matched nothing live,
  fell through to the retired-match arm, and was reported as a projection standing on a value
  nobody maintains. Every word of that failure was true — the title did match a `superseded` note,
  and no `current` assumption carried it — and the conclusion did not follow: a `current` claim
  carried the title, with `used_in` naming the assumptions section directly. Worse, the promotion
  that produced it is a pattern this method prescribes. A structural driver with no subject
  instrument belongs in the indexed set rather than degraded to an assumption, so filing a sourced
  figure as unevidenced is the defect, and correcting it retires the assumption and mints a claim.
  A corpus did exactly what the method says and the new check called it broken — which is the
  failure that gets a gate switched off, taking the half that worked with it. **A row is backed
  when any live `assumption` or `claim` carries its title**, and `model-row-dead-assumption` still
  fires where *every* match is `superseded` or `retracted`. **That pair is the whole set, and it
  stays closed** — a `source` and a `fact` are the provenance a claim rests *on* rather than a
  value the projection carries, and a `milestone`, `question` or `decision` asserts no value at
  all, so what widened is which asserting notes count, not whether the note's type is read.
- **`assumption-not-in-model` demanded a row of notes the ledger had retired, and that demand
  could not be satisfied.** It walked every `assumption` carrying `model_input` without reading
  `status`, so a `superseded` or `retracted` note still owed either a row in the table or an
  `excluded_from_model` reason. Both escapes are unsatisfiable on a retired note: rendering the
  dead title as a row undoes the repair the row → note direction asks for, and writing
  `excluded_from_model` records a decision about a live revenue line on a note nobody will open.
  Found end to end — the row side flagged a dead-backed row, re-titling it to the live claim
  cleared that, and this half immediately demanded a row for the superseded note the repair had
  just pointed away from. The failure calls it *an input the ledger holds*, and a note the ledger
  has retired is not one; it now reads the same live predicate the row side does.
- **`excluded-line-on-roadmap` walks that same narrowed set, and this is a decision rather than a
  side effect.** A retired assumption a `milestone` still `moves` no longer owes an `arr_excludes`
  declaration. Where the note was superseded by a live successor, the successor carries the
  obligation and nothing is lost; where it was retracted outright, the defect is a roadmap pointing
  at a dead note — a different repair, and one no check in this tool reports yet. What it was doing
  was giving the *wrong* repair confidently, which is worse than the gap.
- **The note → row direction did not widen to claims, and that asymmetry is deliberate.**
  `assumption-not-in-model` keys on `model_input`, a field a promoted claim does not carry, so a
  claim never becomes a declared input and never owes a row on its own account.
- **The success line counts live declared inputs and says so.** With the note side narrowed, a
  vault whose only declaring notes are retired reports no declared inputs rather than a demand
  nobody can meet.
- **`--assumption-rows`'s success line stopped reading as a comparison.** It set a row count
  *against* a declared-input count, which implies the two have to agree. They do not: a row backed
  by a `claim` is not a declared model input, and a declared input cleared by `excluded_from_model`
  is not a row. The line now states what each half checked, so a legitimate difference between the
  two counts cannot be read as a miscount and send somebody hunting for a row nothing owed.

## 1.18.0

- **Five checks reported a vacuous pass as a pass: when a check could not find its subject, its
  success line was indistinguishable from a real agreement.** A corpus could carry a green
  `--release-gate` while three of its parts had read nothing at all. `SKILL.md`'s invariant 16
  already named the general form — *"the method is strong at preventing false statements and weak
  at noticing missing ones"* — and the bare `check` run had already learned it, since its success
  line enumerates what it did **not** open. The sub-modes never did.
- **`--supersession-sweep` read the supersession edge from one end only.** Every edge was derived
  from the superseding note's `supersedes:` list, so a note carrying `superseded_by:` whose named
  successor never wrote the matching entry was reported as replaced by *nothing* — the same output
  as a genuinely orphaned note, though the repair differs: one needs a line added to a successor
  the record already names, the other needs somebody to decide what replaced it. Observed: an
  assumption that was a live row in a financial model sat half-superseded while **three current
  claims went on resting on it**, one of them the corpus's strongest negative. Now two distinct
  failures — `superseded-by-unreciprocated` and `superseded-by-dangling` (the successor ID exists
  nowhere; the block-list dangling-edge check walks edge *fields* and never this scalar, so nothing
  else reported it). Neither is gated on `schemaVersion`: both fire on the presence of the field,
  so a corpus that never wrote it cannot owe them.
- **`--assumption-rows` matched a model row to a note on title while ignoring `status`.** A live row
  in the assumptions table whose only title match was a `superseded` note matched cleanly and the
  mode printed `matched verbatim`. `model-row-dead-assumption` now names the note it found and that
  note's status — the projection was resting on a value nobody is obliged to maintain, and the
  title matching is exactly why every check stayed green.
- **`--binding-driver` ended the verdict section at the next heading of ANY depth, so a subsection
  hid the corner table.** A plan that opened a `###` one line into the body of the
  `{#target-verdict}` anchor put its corner-verdict table outside the section: the mode found zero
  rows and printed *"1 verdict note against 0 corner verdict rows … matched verbatim"* — a clean
  pass over a table it never opened, with the whole corner-row half silently disabled. The section
  now ends at the next heading of the same depth or shallower, which is the rule the shared
  `readtable()` already used; that code's own comment had named the arrival of such a subsection as
  the trigger to adopt it, and the trigger fired.
- **Three success lines now name the subject they could not find.** `--monitoring` with no
  `competitor-analysis.md` said *"no competitor set was profiled"* over a vault holding 31 profiles
  in another directory; `--binding-driver` printed `matched verbatim` at zero corner rows;
  `--assumption-rows` reported its matched-row count while the missing-row half iterated over
  nothing. All three still **pass** — a vault may legitimately have no competitor set, no verdict
  note and no declared model inputs. What changed is that a reader can now tell *checked and
  agreed* from *had nothing to check*.

## 1.17.0

- **The method could solve a target downward and never upward, so a founder who named a
  conservative number got it computed, verdicted and never questioned.** `target.md` has carried
  *"The nearest reachable target is a solve, not a smaller number chosen by feel"* since early on —
  machinery that holds resources and driver ranges fixed and solves the identity for what is
  actually achievable when the stated target is out of reach. There was no mirror. Nine hundred
  lines of that file guard against overclaiming: the both-directions test, the confidence caps, the
  policy/structural split, the flip test. Not one step asked whether the stated target UNDERSTATES
  the evidence — and the target is the single number every other number in the plan is solved
  against.
- **`SKILL.md` already carried the bar in prose and nothing implemented it**, which is the same
  defect 1.16.0 shipped a fix for one field over. The quality bar reads *"a claim weaker than its
  evidence is an error of the same class as one stronger… an overclaim gets challenged, an
  understatement gets believed"* — stated, and with no producer pointed at the target itself.
  `AGENTS.md`'s rule is the general form: prose in a reference file is not a producer.
- **The furthest defensible target is now a solve with the same shape as the nearest reachable
  one** — same identity, same date, same stated resources, evidenced driver ranges at their
  defensible top rather than their bottom, reported beside the verdict and never instead of it. It
  fires on a `reachable` verdict and on any `undetermined` whose upper corners clear, and stays
  quiet where the verdict is negative at every corner, because there is no upward solve to run
  against a number that is not reachable.
- **It reports the capping driver and its kind, not just a number.** *"The evidenced ranges support
  up to X by the stated date, capped by DRIVER at KIND"* names what would have to move for the
  larger outcome to be a plan rather than a hope, and where that driver is `policy` the ceiling is
  a configuration the founder chose — exactly as it is on the way down. A raised target supersedes
  under the standing rule and the superseded number keeps its reason, so the corpus records that
  the smaller target was set before the solve rather than in spite of it.
- **The failure it prevents is expensive and invisible.** A founder states a number that feels
  safe; the plan solves it, returns reachable, and the roadmap order, the capital path, the pricing
  and the reference class the verdict is graded in are all sequenced to that number. The work
  required was the same. The larger outcome sat inside the evidenced ranges the whole time and no
  step was looking for it, because every check in the file was built to catch a founder claiming
  too much. An overclaim gets challenged on the first read; an understatement is inherited by every
  document downstream and reads as discipline.
- **No lint change.** This is a method rule with two producers — Phase 3's verdict step and a
  quality bar — and no mechanical surface, so `bin/` is untouched and there is no fixture or parity
  exposure.

## 1.16.0

- **`model_input` has been defined in the schema and asked for by nothing, so the half of
  `--assumption-rows` that catches a MISSING row has never once fired.** `vault.md` documents the
  field, states that a declared input obliges the projection to carry a row, and names the failure
  it prevents — a whole revenue line that existed as correctly authored notes, never became rows,
  and was filed as revenue outside the model, so every verdict downstream inherited a denominator
  missing it. That is recorded as the largest miss on file. But `plan-template.md`'s assumptions
  block and `SKILL.md`'s Phase 3 drafting bullet — the two places that actually produce assumption
  notes — never mentioned the field at all. `AGENTS.md` states the rule this breaks: **prose in a
  reference file is not a producer.** It produces something only when a phase performs it or a
  brief interpolates it, and neither did.
- **The consequence, measured on a real engagement rather than argued:** a finished 401-note
  corpus with a complete financial model reports `21 assumption rows against 0 declared model
  inputs`. Twenty-one rows matched, zero inputs declared — so the direction that fails a declared
  input with no row had nothing to range over and passed vacuously. **And the success line still
  reports the rows it did match**, which is what makes this worse than a silent no-op: the gate
  prints a green count over exactly the gap it exists to find, and the count is real, so nothing
  in the output suggests half the check stood down. A reader sees a number and infers coverage.
- **Both producers now carry it.** The template's assumptions block and Phase 3's assumption-first
  bullet each state that every note behind a row declares `model_input` — `revenue` or `cost` — or
  declares `excluded_from_model` with the reason, and each says why: the missing-row direction
  fires only on notes that declared themselves. The template restates the `sensitivity` and
  `validated_by` obligation in the same breath, because a row whose note carries neither is a
  number nothing will ever revisit, and that is the same defect one field over.
- **No lint change, and that is the point.** `vault-lint.sh` and `vault-lint.ps1` already
  implement both directions correctly and are untouched, so there is no parity or fixture
  exposure. What was broken was never the check — it was that nothing in the method ever produced
  the input the check reads. A rule that exists, is implemented, is documented in the schema
  reference, and is wired into no producer is indistinguishable from a rule nobody wrote.

## 1.15.0

- **The method has been telling authors to file a claim the lint was built to reject.**
  `target.md` states outright that the reference class "is not a term in any identity, and it is
  the input every structural driver's value rests on" — it sets conversion, the band retention
  sits in, and the exit multiple at once, one level beneath the arithmetic — and then requires it
  be **named in the readout, classified `structural`, homed to `research/growth-curves.md`, and
  put through the flip test**. That is driver discipline, and driver discipline means a note. But
  `_vocab.yml` carried no term for it, so `subject: reference-class` resolved to nothing: not a
  near-miss with a suggested key, since nothing in the file normalises within five characters of
  it, but an **unknown-subject ERROR with no suggestion**. This is the inverse of the failure the
  vocabulary usually guards — not a rule that quietly stopped firing, but one firing correctly
  against the note the method instructs you to write. The author's cheapest way out was the
  documented wrong one: pick whichever near-enough term the lint would accept. `category-growth`
  and `category` are aliases of `market-growth` and `category-boundary`, so that is where the
  comparable set went, and there it could never collide with anything.
- **`reference-class` and `exit-multiple` are added, and four base definitions are amended —
  `vocabulary_version` 3 → **4**, with an entry per amendment.** Adding a term is not an amendment
  and does not move the stamp; what moves it is that four existing definitions no longer say what
  the method now asks a claim under them to assert. `revenue-forecast` was *the number the
  projection produces* and is now the number **and the trajectory that reaches it**, since the
  shape check against the indexed set landed with nothing recording that a bare horizon figure had
  stopped satisfying the subject — a claim carrying a number and no shape passes the level check
  on its average while asserting a curve no comparable has ever had. `primary-channel` was a
  reachability argument and now cites the mechanism record where one exists, or says the channel is
  **assumed rather than learned** where the record found no origin account. `category-boundary` and
  `market-growth` get the boundary against `reference-class` declared from their side, on the
  precedent 1.7.0 set when `value-delivered` was added and `alternative-cost` was amended to name
  the line: the new term is only half the fix, because the claims already mis-filed are reachable
  only through the term that collected them. Each entry carries the `must_assert` test that decides,
  per claim, whether it is superseded or re-filed.
- **`vault-migration.md` said `steady-state-ceiling` was "the one amendment that has actually
  shipped", and it had been wrong since 1.7.0** — which shipped two more. Left alone it was about
  to be wrong by six. The paragraph is a worked example and now says so, and says the log is the
  scope: reading a count out of prose beside the file instead of out of the file is how a
  reconciliation misses every entry added after that prose was written, which is the same
  stale-enumeration failure the amendment log exists to prevent one level up.
- **No behaviour change to either lint, and no schema rung.** `vault-lint.sh` and
  `vault-lint.ps1` are untouched: they read the vault's own `_vocab.yml` and never the shipped
  file, so nothing here reaches an existing corpus until its owner adopts the amendment through
  Phase 0's advisory and the reconciliation path `vault-migration.md` already carries. A vault
  scaffolded before this release keeps the superseded wording, reports the delta as four log
  entries rather than as "definitions differ", and stays valid at whatever `schemaVersion` it was
  written under.

## 1.14.2

- **`--roadmap-table` and `--assumption-rows` read their table with one parser per
  implementation, so there is nothing left for a fix to land in half of.** `--assumption-rows`
  shipped in 1.14.0 as `--roadmap-table` one artifact over, which left each implementation
  carrying two near-identical markdown table readers — `readplan()`/`readmodel()` in the shell,
  `Read-PlanRoadmapTable`/`Read-ModelAssumptionsTable` in PowerShell — the second of each pair
  declaring in a comment that it was the first "with two changes and no others". `parity.mjs`
  cannot hold that claim: it diffs `.sh` against `.ps1` and never one reader against its own twin,
  and each mode only ever runs over its own document, so no fixture puts the two readers over the
  same table. A fence rule, an alignment-row test or a heading-depth bound fixed in one and not the
  other would ship silently, and the mode that missed the fix would keep printing green over every
  fixture written before it. Each side is now ONE parameterised reader — `readtable(path, wanthead,
  wantitem, defcol)` in the shell, `Read-FirstItemTable` in PowerShell — taking the three things
  that actually differed: the heading the read opens on, the header cell that names the item column,
  and the column to use when no header cell names it. Two functions a comment says match are a
  hazard; one function with parameters is a guarantee. The shell reader carries its own `trim()` and
  `fold()`, because the collapse left it as their only caller in both modes and two exact copies of
  each with nothing else reading them is the same duplication one helper down.
- **The unheld half had already drifted, which is the reason this is a patch and not a tidy-up.**
  `check.mjs` check 11 held the shell pair to its comment by exact byte comparison after a declared
  substitution list, and the two shell readers were in fact identical past the three parameters. The
  PowerShell pair was covered by nothing, and its two readers had diverged: the roadmap reader
  tested an empty header row with `-cne ''`, which takes PowerShell's culture path and reports a row
  holding nothing but a zero-width space EMPTY — so the item column was never read off such a row —
  while the assumptions reader used `.Length` and read it, the way the shell's byte comparison does.
  Its fold also compared `[char]` ranges rather than code points, against the file's own rule that
  no comparison over document text goes through culture. The collapsed reader takes the hardened
  form of both, so the PowerShell side now agrees with the shell on an input no fixture carries.
- **Check 11 is deleted, because its subject no longer exists.** A check that two parsers still
  match is a weaker guarantee than there being one parser, and once the second one is gone the
  check's extraction finds nothing: it would either report "ran on nothing" forever or silently
  start matching something else. `AGENTS.md` now states the rule that replaces it — add a parameter,
  do not add a second reader and a check that they agree. Its stale count of the fixture suite's
  assertions is corrected in the same pass.
- **No user-visible behaviour changes.** This is a refactor and was verified as one: `--roadmap-table
  --json` and `--assumption-rows --json` were captured from both implementations over all 27 fixture
  vaults before and after, and every byte of stdout, stderr and every exit code is identical. Both
  fixture suites report 336 passed / 0 failed, unmoved in either direction, and the parity gate is
  13/13 modes with 0 allowlisted. The version moves because `bin/` is not exempt from CI's bump
  guard, and because a drift hazard removed from a shipped executable under no released version is
  one nobody outside this repo can point at.

## 1.14.1

- **The one `--deliverable` exemption a reader depends on is now asserted by name, and the gate's
  own count in `AGENTS.md` names the right ten.** 1.14.0 added `--deliverable` to keep vault
  addresses out of a rendered artifact, and `[S#]`/`[F#]` citation codes are deliberately exempt —
  they are the reader's own source trace and are the reason a figure in a shipped PDF can be
  followed back to where it came from. That exemption was a property of how the address pattern is
  BUILT — a type prefix plus the eight generated characters an ID carries — and nothing asserted
  it. So widening that pattern later, to drop the length anchor or match a bare type letter, would
  have started stripping the citation trace out of the one document that carries any, with every
  assertion in the suite still green: the exact shape `AGENTS.md` warns about, where a check that
  stopped firing reads identically to one that passed. `deliverable-leak`'s clean deliverable now
  cites two figures at point of use and the suite asserts the exemption **by code**, matched on the
  bare token rather than the bracketed form — a bracketed test would pass over precisely the
  widening the assertion exists to catch, because the widened pattern reports the bare token — with
  a presence guard beside it so an edit that drops the codes cannot leave the exemption passing
  over a file with nothing left to be exempt. Verified by widening the pattern until both rows go
  red, which is the only way to know an assertion works. In the same pass, `AGENTS.md`'s shipped-flag
  sentence said `--release-gate` runs "all ten of those" directly after enumerating ten flags — but
  the gate's ten are the bare `check` plus **nine**, so the referent silently swapped `check` out
  for `--unverified`, whose gate column in `MODE_TABLE` is `-`. The count matching in both readings
  is what kept it looking correct, three lines above that same file's warning that an enumeration
  which has gone stale reads exactly like one that is complete. It now points at the paragraph that
  already enumerates the gate's parts rather than carrying a second copy to go stale on its own.
- **Nothing a user invokes changed.** Both edits are contributor-facing — a fixture, its assertions,
  and a contributor doc — and CI's exempt regex correctly did not demand a version for either. The
  version moves anyway, because a fix that sits on `main` under no released version is a fix nobody
  can point at: the suite that guards a shipped mode is part of what makes the mode trustworthy, and
  "installable" is the only unit of that anyone outside this repo can see.

## 1.14.0

- **Every defect in this release is a rule that exists, is correct, and does not fire — or a
  rule with no inverse — and the through-line is worth stating once before the list, because it
  is a property of how the method was built rather than nine unrelated bugs.** None was found by
  reading the code. All came from running an engagement end to end and noticing which correct
  rule failed to catch a wrong output. **The method is strong at preventing false statements and
  weak at noticing missing ones**: every check was pointed at what is *present* — a number with
  no source, a citation that does not resolve, a cell that disagrees with its note — and a
  method that only inspects what got written cannot see the assumption that never became a row,
  the competitor strength nobody wrote down, or the section a rewrite quietly emptied. This is
  the same shape as the seven defects behind 1.10.0 and the one behind 1.12.0 — the third time
  the fix has been a *counterpart* to a rule already on the page rather than a new idea. So the
  entries below are grouped by which absence they made visible, and the
  release adds no rule whose failure mode is *something incorrect was stated*.
- **The deliverable stops inheriting the ledger's archaeology — `vault-lint.sh --deliverable`
  reads the rendered `deliverables/*.html` and fails on a strikethrough span, a note ID or a
  red-team `R<n>-O<n>` code.** Invariant 14 is unchanged and still right for the vault: a
  retracted claim keeps its reason, because silently deleting a dead claim lets it come back two
  drafts later with its cause of death erased. It had no counterpart on the way out. The reader
  of the artifact was never in the room, and a note ID is a **vault address** — it resolves for
  anyone holding the corpus and resolves to nothing for the audience the document is for — so a
  document that carries both is arguing with its own previous draft in front of the person it is
  trying to convince. **The fix is a step, not a strip filter, and that distinction is the whole
  design**: deleting the `~~` leaves *"That multiple was actually…"* with no antecedent, which
  still renders, still reads like prose, and now asserts nothing. No script can judge an
  antecedent. So Phase 5 gained a named **restate-forward** step — the artifact states what is
  true now and the ledger keeps the archaeology — performed in the render loop's page-by-page
  read-back, and the mode is the mechanical half beneath it. `SKILL.md` now says outright that
  invariant 14 does not change, because a reader hitting two rules that point opposite ways will
  otherwise assume one of them was superseded. `[S#]` and `[F#]` codes are the reader's own
  trace and stay; a note ID is matched as its type prefix plus the eight characters a generated
  ID carries, which is what keeps the check off `FACT-CHECKED` in ordinary prose. A vault that
  has rendered nothing passes.
- **The ARR term now declares its composition — `--assumption-rows`, four checks, and the one
  that matters most is the reverse direction.** `plan-template.md` requires that no number in a
  projection is anything but a named assumption row: correct, load-bearing against fake
  precision, and it has been the wrong half of the pair since it shipped, because nothing ever
  asked whether a named assumption was **missing** from the table. Two assumptions governing a
  whole revenue line existed as properly authored notes, never became rows, and the rule meant
  to enforce rigour made that line structurally unable to enter the projection. It was then
  filed as *revenue outside this model* — which reads as a modelling decision and was a
  consequence of the omission — and every verdict downstream inherited a denominator missing a
  line the roadmap ships. So an `assumption` carrying `model_input: revenue` or `cost` owes
  either a row matched on its `title` **verbatim** or an `excluded_from_model` reason;
  `model-row-no-assumption` runs the table the other way, because otherwise the cheapest way
  past the first check is a row nothing in the ledger stands behind; and `model-table-missing`
  covers notes that declare inputs a table renders none of. **The remaining check belongs to the
  identity rather than to the table, and it is `roadmap-sequencing.md`'s Rule 1 run backwards**:
  that rule says every roadmap item names the assumption it moves, and `excluded-line-on-roadmap`
  reads the same edge from the other end — an assumption carrying `excluded_from_model` that a
  `milestone`'s `moves` names, and that no verdict note lists in `arr_excludes`, is a dated
  change to a revenue line the model does not carry. **Excluding a line is legitimate** — a
  metered layer must not be allowed to flatter subscription churn — so what fails is the
  *silence*, and the escape is stating it where the identity is stated rather than inside the
  model: the exit identity is ARR × multiple and none of the multiple's inputs is ARR, so an
  undeclared exclusion is a denominator nobody can see. One reading rule differs from
  `--roadmap-table` and it is the one that would have cried wolf: the item column defaults to
  **two**, because the template ships `| # | Assumption | … |` and column one is the `A-n` label
  the plan's prose and a milestone's `moves` both cite.
- **Competitor research can now produce product, not only positioning.** A profile ended once —
  where the competitor structurally leaves the market open, which is the wedge — and the other
  direction was left to a founder's own reading of a document they commissioned precisely
  because they could not do that reading. So every profile now ends **twice**, and the second
  half is *what this competitor does better, and what adopting it would cost*, judged against
  the dossier's jobs rather than against a feature list and priced in the two words the plan
  already uses. Absence is recorded as absence — `"nothing to adopt found, checked <date>"` —
  because a profile that simply stops is indistinguishable from one where nobody looked. The
  profiles roll up into `## Adoption candidates` on `competitor-analysis.md`, assembled from the
  profile files rather than re-derived, and `roadmap-sequencing.md` gained **Rule 8**: an
  adoption candidate is the other legitimate source of a roadmap item, since Rules 1–7 all
  assume an item came from the founder's own intent. It is written as a **disjunction with no
  third branch** — every candidate is adopted and dated, or refused with the reason on the
  record — because refusing one costs a sentence while dropping one costs nothing and is
  invisible, and invisible-and-free is what the whole release is about. A candidate that moves
  no assumption is maintenance, and saying so *is* the refusal.
- **Growth research learned mechanisms, not only rates.** `research/growth-curves.md` came back
  with how fast comparable companies grew and nothing about how any of them started, so
  `growth-engine.md` had a reference class it could not use for the one question a pre-launch
  founder actually has, and invented a funnel instead — a plausible one, resting on nothing. A
  mechanism pass now runs beside the rate pass over the origin the rate pass structurally cannot
  reach: per comparable, the launch motion and where the first release was put, **the first
  channel that produced paying customers** (rarely the first channel tried, and often not the
  channel the company is known for now), what the founder did personally that did not scale, what
  compounded, and what was tried and abandoned. `growth-engine.md` now cites that record instead
  of choosing a channel out of its own rules, and where no record exists it says the assumption
  is assumed rather than learned. **`"rates only, no origin account found"` against a comparable
  is a pass**, in those words: it is the record doing its job, and silence is the failure —
  which is the same reason the adopt section has to write down that it found nothing.
- **The monitoring plan became a contract artifact — `--monitoring`.** Every profile carries the
  date it was researched and every claim note carries a `stale_after`, and both of those answer
  *is this still true*. Nothing in the corpus asked **which way is this moving**, which is a
  different question a snapshot cannot answer however fresh it is. The old monitoring section was
  prose naming pages to re-check, so it degraded into a list of URLs with no obligation attached.
  It is now a table — one row per axis, each naming the **instrument** that reads it, the
  **cadence**, and the **decision it would change** — and the mode fails an absent section, a
  section with no axis in it, and any row that leaves one of those columns empty. Each column
  earns its place by what goes wrong without it: an axis with no instrument is a thing somebody
  intends to notice, one with no cadence is a re-check with no date, and one with no decision
  behind it is a signal nobody acts on, which costs exactly as much to collect as one that
  matters. A cell carrying no letter or digit — an em dash, a run of hyphens — reads as empty,
  because that is the cheapest way past the rule. A vault with no `competitor-analysis.md`
  profiled nobody and passes; gated on `schemaVersion` 2.
- **Phase 0 inventories what the product measures, not only what the founder wrote about it —
  and it goes first because it is the cheapest primary evidence the engagement will ever have.**
  The method already ran an infra-cost archaeology pass over repo sources and already inventoried
  the founder's own artifacts, and it walked past the product's own records every time. A form
  field asking arriving users what they came to do is dated, checkable, free, and the one class
  of evidence a competitor cannot obtain and no survey improves on — and its usual state is
  unread with the row count unknown. So a product-instrumentation pass joins the Phase 0 fan-out
  with its own dossier section, one entry per store or event type rather than per call site, each
  naming what it records and at what grain, the quantity in the analysis it could settle, whether
  it has been read, and what reading it would cost. `business-plan`'s Phase 0 is where the
  readable entries actually get read: the instrument becomes a source with no public URL whose
  provenance names the store and the query, and each figure read off it is a `fact` resting on
  that source, so the cheapest evidence in the engagement enters the ledger on the same terms as
  the most expensive. The unreadable ones become a grill question — access to the instruments
  Phase 0 could not open — rather than an estimate nobody revisits, and Phase 2's verify list
  names the inventory outright and reconciles it in both directions. **What enters the corpus is
  the figure, the date and the query**: never the rows, never a free-text answer verbatim, and
  never a copy of a user's data.
- **A rewritten section now re-opens the claim that cited it — `--claim-drift`.** `--used-in`
  says at length that it will only ever prove a citation **resolves**, and it is right to; but a
  heading nobody renamed keeps resolving through any rewrite of the prose beneath it. So a claim
  written into a plan section satisfying every rule there is, a later re-solve that rewrote the
  block, an untouched heading, and a green gate were all consistent with each other, and the
  drift was found by hand days later. A claim therefore records the content hash of each cited
  section in `reconciled_sections` — itemising the `reconciled:` date rather than sitting beside
  it as a second field that can disagree with it — and a changed hash **re-opens** the claim.
  Three properties are load-bearing. **The hash is over bytes with three normalisations and no
  others** — trailing whitespace per line, and leading, trailing and repeated blank lines —
  because all three are invisible in a rendered document and a hash sensitive to them re-opens
  every claim in the corpus the first time an editor trims a file; a rewrapped paragraph *is* an
  edit and does re-open. **The polynomial is 31-bit and arithmetic-only** — `h = (h·131 + byte)
  mod 2³¹−1`, length mixed in last — because it has to be byte-identical in POSIX awk, which has
  no bitwise operators, and in Windows PowerShell 5.1 with zero dependencies on either side, and
  because it is detecting an edit rather than resisting an adversary. **The failure message
  carries the current hash**, which is what makes a read-only tool usable here: there is no write
  mode, so re-reconciling is re-reading the section and pasting one token, and pasting it is the
  assertion that the read happened exactly as stamping a date is. It reads only `current` `claim`
  and `assumption` notes, and only entries whose `#anchor` already resolves — a dead anchor is
  `--used-in`'s verdict, and reporting it twice under a name about reconciliation sends its reader
  to the wrong fix.
- **A gap entry names the instruments tried, not only the sources searched.** *Searched
  extensively, no data found* is unfalsifiable and unquotable, and it cannot be told apart from
  a gap where the disclosure-adjacent instruments were never opened. Publisher and analyst
  search, the regulator's own full-text filing search, a filer's periodic reports and the segment
  notes inside them, and the earnings-call transcripts are **four different instruments**, and
  where a quantity is regulated-disclosure-adjacent a filings check is now required before *no
  data exists* can be written. The entry is `"Not found via <instruments>, as of <date>"` and
  never `"does not exist"` — the first survives being quoted in a document somebody defends, the
  second is a claim about the world made from a failed search. *Unknowable* is likewise narrowed
  to entries whose own instrument list shows those instruments were tried and came back empty.
  A dimension also reads the existing `research/*.md` Sources tables before it starts, so nine
  parallel dimensions stop each paying separately to search the same filer.
- **`schemaVersion` 3, and the two modes that read fields no existing corpus carries are gated on
  it.** `--assumption-rows` reads `model_input`, `excluded_from_model` and `arr_excludes`;
  `--claim-drift` reads `reconciled_sections`. At 1 or 2 each exits 0 **and says the rule was not
  applied**, naming the fields that were added at 3 — not the same thing as reporting that the
  documents agree, and the distinction is the entire reason the version field exists.
  `--claim-drift` is the exact shape of upgrade the mechanism was built for: every claim in a
  finished corpus is already cited into a plan, so a hash rule firing unconditionally would turn
  every existing vault red on the day the plugin updated. `vault-migration.md` gained the 2→3
  section, and it is deliberately two halves with different costs — the `--assumption-rows` half
  is a transcription (copy each row's `Assumption` cell into the note's `title` unchanged, since
  the match is verbatim and a title tidied on the way in fails in both directions), while the
  `--claim-drift` half is a real read, using the mode's own output as the worklist. Running out of
  session is a supported outcome: revert the `3` and come back, and commit the stamp together with
  the entries as the last edit. Migrations stay forward-only — there is no 3→2 path, for the same
  reason there is no 2→1.
- **Cross-platform correctness, in two fixes that were each invisible from the platform they were
  authored on.** The first is the fixture harness's own: a checkout with Git for Windows' default
  `core.autocrlf=true` failed **89 assertions** while the shipped lint was fine, because
  `run-fixtures.sh` compared harness-read document lines against literals in three reader shapes
  across four call sites. That is a defect in the instrument rather than in the product, which is
  the worst place for one — it reddens a correct implementation and sends the reader to the wrong
  file. A single `strip_cr` helper now serves all four, with the rewriting pair fed clean input
  *before* the comparison rather than filtered after it, and the CRLF fixture's own pinning guard
  counts carriage-return bytes instead of pattern-matching lines, because Git for Windows' awk
  reads in text mode and hands every pattern a line with no `\r` in it — so the guard would have
  reported a correctly pinned fixture as unpinned. The second is the PowerShell port's: `bin/`
  compares bytes in awk, so a culture-aware comparison over document text is a parity divergence
  where the two implementations read different documents over the same file. Three sibling copies
  of one fence scan were never converted to ordinal, and a fourth in `--roadmap-table` was not
  either — the enumeration on file said three. **The one with a reachable divergence is
  `--red-team`'s roster heading, through `Get-RedTeamKey`**: that fold lowercases and collapses
  whitespace runs and drops nothing else, so a zero-width space survives into the comparison, and
  culture folding reports `lenses<ZWSP> dispatched` **equal** to `lenses dispatched` while awk
  compares bytes and does not — PowerShell reads a roster the shell does not. Worth naming
  precisely, because `-ceq` is not the fix: `-ceq` on a string and `-eq` on a `[char]` both take
  the culture path, so the conversion is to ordinal APIs. `scripts/fixtures/fence-zwsp` is what
  turns *no demonstrated impact* from a fact about the corpus into a fact about the code — its
  `red-team.md` carries the space in the roster heading and its `competitor-analysis.md` carries
  one inside a fence whose row would read as an axis if the scan folded that character away, so
  the fence half has an observable consequence too rather than only a comment. Reverted, the
  PowerShell side answers `"ok": true` where the shell answers `"ok": false` over the same vault.
  The roadmap pair — the heading fold and the `Item` header cell — is the genuinely unreachable
  one, already folded to ASCII alphanumerics before any comparison happens, and it was converted
  anyway, so the rule is a property of the file rather than a judgement
  re-made per site; re-making it per site is what left three copies of one scan behind.
- **The release then turned the same question on its own new rules, and five of them did not
  fire.** A release whose entire subject is correct rules that never run is the worst possible
  place to add eleven more without checking, and the pass found: quality bars still naming seven
  gate modes after the gate reached ten; a Phase 2 checkpoint that never named the monitoring
  artifact it depends on, so a research return without one passed; Phase 0 scaffolding a new
  vault at a `schemaVersion` below the one whose checks this release added, which would have
  exempted every new corpus from them by default; a partial-refresh instruction still saying
  re-read the pages after monitoring became axes; and a migration whose scaffold version made
  stamping last impossible. `check.mjs` gained a check of its own in the same spirit — it holds
  `--assumption-rows`' `readmodel()` to the transcription of `--roadmap-table`'s `readplan()` that
  the file claims, comments and blank lines dropped and the declared differences substituted,
  compared byte for byte, because `parity.mjs` diffs the `.sh` against the `.ps1` and can never
  diff one reader against its own twin.
- **Two numbers a user can act on.** `--release-gate` is now **ten parts** — the bare `check`
  plus nine flags — so the one call before a render asks every question the tool can ask, and its
  success line names what it did not open off the same mode table it composes itself from. And
  the suites moved with the modes rather than behind them: the fixture suite went from **250
  assertions to 332** across eight new corpora, each failing exactly one new rule while passing
  the rest, and the parity gate from 9 modes × 19 fixture vaults to **13 modes × 27, with 0
  allowlisted**. A composite that silently reported one part's verdict as the whole is the failure
  those corpora exist to catch, and an allowlist entry is how a mode ported to one script and not
  its twin would have hidden.

## 1.13.0

- **A Claude Code session on native Windows with no Git for Windows has the PowerShell tool and
  no shell that can run `vault-lint.sh` — `bin/` now ships `vault-lint.ps1` beside it, held
  byte-identical to the shell script by the parity gate below.** Before this release the lint was
  one POSIX `/bin/sh` script, and on that session it was not a script that failed, it was a command
  that did not exist — the error read as a broken or missing plugin, sending the reader off
  diagnosing the wrong thing instead of the actual cause, which was the wrong shell for the
  machine. A session now picks the extension matching the shell tool it actually has and invokes
  it bare either way.
- **A checkout with Git for Windows' default `core.autocrlf=true` rewrote the shebang to
  `#!/bin/sh\r` and killed `vault-lint.sh` before any Windows-specific behaviour was reachable at
  all — `.gitattributes` now pins both scripts to LF endings.** Porting the lint to PowerShell into
  a checkout that still could not run the *original* script correctly would have shipped a second
  bug on top of the first; pinning both scripts to LF is what stops `core.autocrlf=true` from
  rewriting the shebang in the first place, so the checkout that broke the shell script can no
  longer occur.
- **macOS was never actually exercised by CI — the fixture suite ran only on `ubuntu-latest`, so a
  bashism or a GNU-only flag could ship and only ever surface on a contributor's own Mac.** CI now
  runs the full 241-assertion fixture suite on `macos-latest` too, which is the regression baseline
  the whole cross-platform port is measured against.
- **Two implementations of one 3,600-line linter is a drift hazard no reviewer can hold in their
  head by re-reading both files, so nothing here ships on review alone —
  `scripts/parity/parity.mjs` is the mechanical gate that makes maintaining both tractable.** It
  runs every mode across 19 fixture vaults — 7 modes' `--json` output compared byte-for-byte,
  `graph` and `--release-gate` (which refuse `--json`) on normalized stdout and exit code — and
  fails on any disagreement: key order, an escaped character, row order, a path separator. That is
  exactly the class of defect invisible to a reader of either file alone, and it would otherwise
  ship silently to whichever half of the install base hit the untested side first.
- **`vault-lint.sh` read a `_vocab.yml` whose lines end CRLF as an EMPTY vocabulary, which is a
  silence rather than an error — `unknown-subject`, `near-miss-subject` and `coverage-gap` each
  need a term to compare against, so a vault carrying unknown subjects and a thin spine linted
  clean.** A `_vocab.yml` written or edited on Windows is CRLF by default, so a corpus shared
  across platforms hit this as the ordinary case rather than the corner. The shell was affected on
  macOS and Linux only: Git for Windows' awk strips the carriage return for free, which is why
  adding a Windows runner is what finally exposed a bug that had always been a POSIX one.
- **The corpus never contained a single CRLF byte, which is why neither implementation was caught
  until a Windows runner existed — a CRLF fixture vault now joins the suite, pinned to CRLF
  through checkout by path rather than by extension.** It asserts the behaviour and not just the
  bytes: the vocabulary checks must still fire on it, so a regression that reintroduces
  carriage-return intolerance turns it red rather than passing quietly.
- Docs, `AGENTS.md` and the skills' invocation prose now name both implementations and point at
  the selection rule above, rather than asserting the lint is POSIX shell reached over the Bash
  tool's `PATH` — true of the only implementation there used to be, and false the moment a second
  one shipped.

## 1.12.0

- **A rule that is correct, present and read is still not enforced, which is why invariant 16's
  second clause needed a field rather than a better sentence.** In a real engagement run the plan's
  corner table recorded the binding driver's kind as `policy`, correctly. Invariant 16 already said,
  in those words, that a verdict whose binding driver is policy rather than structural is negative
  for the stated configuration only and never for the target — and it already spelled out the
  failure it prevents: a policy-bound "unreachable" stops a founder over a decision they could
  revisit this week, in the same words and at the same confidence as a constraint no decision of
  theirs can move. The label was right. The rule was right. The rule was read. The verdict was
  written as structural anyway, and it cost a day before somebody caught it and the corner was
  reopened as undetermined. **Nothing downstream of a person reading a rule can tell whether they
  applied it**, and that is the whole case, worth stating plainly because it is uncomfortable: a
  prose invariant is checkable only by the person it is addressed to, at the moment they are least
  able to check it — mid-run, holding the conclusion they have already reached. That is not an
  argument for sharper prose. It is an argument for a field that fails.
  **So this release is the `resource` precedent applied to the verdict, and it is worth naming as
  that.** `vault.md` states the precedent outright — "`resource` is the field that makes
  resource-independence checkable." Before 1.10.0, resource-independence was a paragraph asking an
  author to notice that two items competed for the same constrained thing; after it, `resource` and
  `sequence` are fields on the note and `false-independence` fails two milestones that declare the
  same `resource` at the same `sequence`. Same move one invariant over: `driver_kind` and
  `conditional_on` turn invariant 16's second clause from a paragraph an author has to apply into
  fields a check reads, and `evidence_n` / `evidence_counterparties` do it for a sample size that
  was never written down anywhere at all. It is also the same shape as the seven defects filed as
  the v1.10.0 umbrella (issue #81) — both sets came out of running a full engagement end to end
  rather than out of reading the code, which is why both are rules that were already written down
  and simply never fired.
- **Invariant 18 has two halves and only one of them was ever enforced; the verdict half is now a
  note shape, and `vault-lint.sh --binding-driver` reads it against the plan section that renders
  it.** The ceiling half got its surface in 1.3.0, when `steady-state-ceiling`'s vocabulary
  definition was amended to require the configuration and the structural/policy labels —
  `vocabulary.yml`'s amendments log records exactly that, `amended_at: 2`, `shipped_in: "1.3.0"`.
  The verdict half stayed prose for nine releases, so *your target is unreachable* and *your target
  is unreachable at six hours a week across two channels* rendered identically, in the same
  frontmatter, at the same confidence letter — and only the second one is true. A verdict is the
  single output of this skill most likely to make a founder stop, and a policy-bound one stopped
  them over a decision they could revisit that week. **The reason it stayed prose is worth stating
  plainly: there was nothing structured to check.** A verdict was an ordinary `claim`; nothing
  marked a claim as a verdict, named the driver that binds, recorded that driver's kind, or counted
  the evidence under it, so invariant 16's second clause had no surface to be enforced against and
  any check would have had to read a sentence for meaning. So this release is a note shape first
  and checks second: a new `target-verdict` vocabulary term, sibling of `steady-state-ceiling` and
  named for the plan anchor it renders into, plus five fields — `binding_driver`, `driver_kind`,
  `conditional_on`, `evidence_n` and `evidence_counterparties` — owed as a set the way a decision
  note's brief fields already are. **No eighth note type**, and the five hang off the `subject`
  rather than off the type, because one verdict is filed as an `assumption` before the research
  that settles it and a `claim` after: a rule keyed to `type: claim` would exempt every verdict
  written before the research came back, which is every verdict at the point where a wrong one is
  cheapest to fix.
- **The wording check matches a string the note owns, verbatim, and that is the `--roadmap-table`
  argument from 1.11.0 applied one document section over.** `conditional_on` holds the policy
  variable in the words the plan uses, and the check asks whether that string appears in the
  section the verdict renders into. There is no phrase list and no sentence-shape inference,
  because where one side renders off the other an exact match is a *check* — a mismatch means
  somebody wrote the sentence by hand — while anything looser is a similarity test that fires on
  correctly-written prose whose wording drifted, and a check that cries wolf gets switched off,
  taking the half that worked with it. The same instrument is already house style: `chosen` against
  an entry in `options`, and a milestone `title` against its roadmap row. The corner table's `Kind`
  column is held the same way, so `plan-template.md` now states that column as a contract the
  writer owes rather than a formatting choice, and `target.md` names the token
  `policy-within-band` beside the prose form "policy within a structural band" wherever the cell or
  the field is discussed — a writer copying the prose into a cell would otherwise earn a mismatch
  on a correct plan.
- **`counterparty` on the source note, rather than an `n` field on the verdict, because the source
  count was never the missing half.** Distinct sources under a binding driver is transitive closure
  over `rests_on` — the lint's job, and it already held every edge it needed. Concentration is the
  half nothing in the corpus could compute: two deals with the same counterparty, written up on two
  separate research passes, are two source notes with two `url_canonical` values, and
  deduplication structurally cannot reach them because they genuinely *are* two documents —
  distinct pages, distinct pulls, neither a duplicate of the other. The only thing they share is the
  party on the other side of the table, and nothing recorded it. Unwritten, a count of two reads as
  two independent sources at the same confidence letter, when it is one relationship's terms
  standing in for a market's. The field is optional and omitted where there is no party — a
  published report has none — and a consumer that needs the value falls back to `publisher`, then
  to the `url_canonical` host. **Which way that chain errs is documented rather than left to be
  discovered**: a third party reporting two unrelated deals collapses them onto one party and cries
  wolf, which is exactly why the field is authored rather than inferred; dropping the chain instead
  would be worse in the direction that hides, since an unwritten field would read as *no
  counterparty* rather than *not recorded* and a corpus written before the field would report
  perfect diversity. It reaches researchers through the source-note contract in
  `market-analysis/SKILL.md`, which `orchestration.md` interpolates verbatim into every dimension
  brief as `vaultNotes` — so a new field reached every agent that writes a source note with no
  orchestration change at all, which is the interpolate-never-restate rule paying for itself.
- **The trigger is the `subject` and not `schemaVersion`, and it is deliberately asymmetric across
  the two subjects.** `target-verdict` is a term this release introduces, so no existing corpus
  carries it: there the four unconditional fields are owed **outright**, and a note carrying none
  of them fails. `steady-state-ceiling` is `required: true` and predates its 1.3.0 amendment, so
  every vault already holds one — there the trigger is **field presence**, and an unlabelled legacy
  ceiling claim still passes. That asymmetry is the exemption `schemaVersion` exists to provide,
  obtained without spending a version: `SUPPORTED_SCHEMA` stays `1 2` and no vault needs migrating.
  **The asymmetry is the design rather than an inconsistency to tidy away later.** What field
  presence buys is an exemption for notes written before the fields existed, and only the ceiling
  half has such notes to exempt; extending it to the verdict half would pay an exemption's whole
  cost over an empty population, and the cost is exact — omitting `binding_driver` would become the
  cheapest way past every rule that reads the note. A dodge available by omission is not an
  exemption, which is why `--red-team` checks its roster in both directions too. `vault.md`'s table
  of what each schema version costs deliberately carries no row for this mode, with the reason
  beside it: a row would assert the opposite, and the lint would then disagree with the schema
  about which vaults the mode applies to, in the direction where the schema reads stricter than the
  tool.
- **Surfacing a thin tail is a conjunction, and it shipped through most of this release as a
  disjunction that could never fire.** The rule was written as *the closure is thin and the note
  **or** the rendered section does not say so* — vacuous, because `check` already owes both counts
  on every note the mode reads, so the disjunction could never be both-false and the check
  collapsed to a question about the ledger alone. Which left the reported failure shipping: the
  defect is not that the ledger is wrong, it is that the corpus knew the tail was two deals from one
  party and the number a founder acts on never said so where anybody read it. It is now both
  halves — the note's counts must be what the closure holds, **and** the section must carry the one
  line those two generate, `Evidence: 2 sources, 1 counterparty`, matched verbatim like
  `conditional_on`, with each noun pluralising on its own numeral. **An earlier draft scanned the
  section for the two counts as whole-word tokens, and that was rejected**: an unrelated pair of
  digits in the same paragraph silences it, and a check that passes for the wrong reason is worse
  here than one that fails for the wrong reason, because nothing ever surfaces it. One string
  generated and one string looked for means a mismatch can only mean the line was hand-written or
  never written. `plan-template.md` carries the form — a new `Evidence` column on the corner table
  and the same line as a clause in the ceiling sentence — and the line is owed **only** where the
  tail is actually thin, under three distinct sources or every source from one counterparty at any
  count, so a well-evidenced corner carries an em dash and this never becomes a line on every plan
  that everyone learns to skip.
- **Six rules stand on the five fields, and two of them exist purely to close a dodge.**
  `verdict-fields-incomplete` and `driver-kind-unknown` are in the bare `check`, because they read
  nothing but the note; `verdict-unconditional`, `verdict-kind-mismatch`, `verdict-thin-evidence`
  and `verdict-unfiled` are in `--binding-driver`, because they have to open `business-plan.md`.
  `driver_kind`'s enumeration is closed at three words for a reason worth the sentence: everything
  downstream branches on policy-or-not, so an unrecognised value takes the structural path by
  default and buys exactly the exemption invariant 18 exists to refuse, with a typo
  indistinguishable from a deliberate classification. **`verdict-kind-mismatch` runs both
  directions** because hand-editing a `Kind` cell to `structural` is otherwise the cheapest way
  past `verdict-unconditional` — a structural verdict owes no condition — and a driver cell edited
  until it matches no note would otherwise clear both. **`verdict-unfiled` fails a rendered
  `{#target-verdict}` section with no note behind it**, which is `--roadmap-table` inverted: that
  mode fails a milestone note the plan never renders, this one fails a rendered section the ledger
  never held. It is needed because `target-verdict` is `required: false`, so `coverage-gap` does not
  ask for a note either, and writing the verdict sentence straight into the plan would otherwise
  bypass the ledger entirely — no `rests_on` and so no confidence derivation, no `stale_after` and
  so nothing that ever comes up again, no supersession when the target is renegotiated, and no
  section for `--supersession-sweep` to name when something underneath it moves.
- **Two boundaries are recorded because a later reader will want to reopen them, and both were
  chosen against a stricter form that fires on correct work.** `verdict-kind-mismatch`'s reverse
  direction asks whether a corner row **names a driver**, not whether that row states a kind: the
  stricter form fires on `plan-template.md`'s own worked example, where an undetermined corner
  names its driver and writes an em dash in the `Kind` cell, and a check that reddens the shipped
  template is one somebody switches off, which costs both halves. And **the section a verdict
  renders into is the anchor its subject names first, with `used_in` only as a fallback** rather
  than as a union of every `used_in` target — under the union, a note that also cites `## Why now`
  cleared the condition check whenever the phrase turned up there, so the verdict corner could read
  *does not clear* and pass. The union looked more permissive in the right way and was more
  permissive in the wrong one. `--binding-driver` joins `--release-gate`, making the composite six
  parts, and the fixture suite went from 192 assertions to 241 across six new corpora, each failing
  exactly one of the mode's rules while passing the rest — which is the only shape that catches a
  composite silently reporting one part's verdict as the whole.

## 1.11.0

- **The plan's roadmap table is now read against the milestone set it renders —
  `vault-lint.sh --roadmap-table`, both directions — and the reason 1.10.0 gave for scoping it
  out does not hold.** That release made the *note* side mechanical: `moves` must name a real
  note, `resource` and `sequence` are checked, and `research/timeline.md` is generated rather
  than hand-maintained. It left the table-to-note correspondence unchecked, so an item could sit
  in the plan a reader actually sees with no note behind it at all — the same class of hole the
  release was closing, moved one layer out. **The stated blocker was that both sides are prose**,
  so any match would be fuzzy, would fire on correctly-written rows whose wording drifted, and a
  check that cries wolf gets switched off — taking the working half with it. But
  `plan-template.md`, written in that same release, says the roadmap table **renders off the
  notes**. A table rendered off the notes carries the milestone `title` as its item cell, so the
  key is that title matched **verbatim** rather than fuzzily: a correctly generated table agrees
  character for character by construction, and a mismatch means somebody hand-edited the table,
  which is the failure the check exists for. No `MILESTONE-` ID column in a document a founder
  hands an investor, and no template contract change. **The instrument is already house style** —
  `vault.md` holds `chosen` to a verbatim match against an entry in `options`, for the same
  reason: a paraphrase makes the record unreadable later. Recording the fix without recording
  that the previous reason was wrong is what invites the same reasoning again. **Both directions
  fail, and each costs something different**: a roadmap row matching no milestone title is an
  item that escaped the ledger, so it moves no assumption anybody can name; a milestone the table
  never lists is a dated change to an assumption row the plan does not show, so the model's curve
  has a step the reader cannot see. Milestone notes with no `business-plan.md`, no roadmap
  heading in it, or no table under that heading are reported once against the document rather
  than once per note — the fix is one thing, and eight rows for one job is a report people stop
  reading.
- **Two reading rules are what keep the check from crying wolf, and both ship as things the
  writer has to get right rather than as behaviour buried in the lint.** Only the **first** table
  under the roadmap heading is read, because `roadmap-sequencing.md` Rule 3's permutation
  comparison legitimately lands in that same section and its first column is an *order* — reading
  it would report every one of its rows as an item that escaped the ledger. And the item column
  is the one **headed `Item`**, falling back to the first cell: the generated
  `research/timeline.md` heads its table `| # | Item | … |`, and a numbered roadmap is the shape
  a plan reaches for the moment its rows are numbered, so always taking cell 1 would report the
  ordinals as items with no notes behind them, on a table whose every row resolves. Both worked
  tables in `roadmap-sequencing.md` already head that column `Item`, so this reads a signal the
  method already emits rather than inventing a contract. Getting either wrong reproduces exactly
  the failure this check was scoped out for once already, which is why `plan-template.md` now
  states the order the section is written in instead of leaving it to the lint.
- **The mode is gated on `schemaVersion` 2 like every other milestone check, so a vault at 1 is
  untouched, and the fixture suite went from 174 assertions to 192.** A vault at 1 has no
  `milestones/` directory by construction and owes no roadmap; there the mode reports that the
  rule was not applied rather than printing agreement, which is the distinction
  `--supersession-sweep` already draws. Two new corpora each fail exactly one direction — one row
  with no note, one note with no row — and the second is written in the `| # | Item | … |` shape
  so the header path is covered rather than assumed. `vault-migration.md` gained the back-fill
  note that follows from the gate: stamping 2 is what puts an existing plan's already-written
  table under this check, so each milestone note is minted from the row it renders and the item
  cell is copied into `title` unchanged. A title tidied up on the way in fails twice over — once
  as a row with no note behind it, once as a note the table never lists — and the back-fill is
  the one moment the two lists sit side by side and can be made to agree for free.

## 1.10.0

- **The Phase 5 release gate is one call — `vault-lint.sh --release-gate` — rather than three a
  conductor has to remember.** 1.8.0 made that gate three named invocations (the default check,
  `--used-in`, `--supersession-sweep`), which is three chances to run two, and the one most
  likely to be dropped is the one whose failure is quietest. The composite runs each part under
  its own heading and exits with the **worst** status any part returned, so a refusal is never
  flattened into a failed check — the two mean different things and want different fixes.
  `--json` is refused, because several JSON documents in sequence are not a JSON document. Each
  part is a separate invocation of the script: two modes share one failure file, and a process
  boundary is the cheapest thing that cannot let one mode's failures land in another's verdict.
  **The bare run's success line was the other half of the same defect.** It said `clean`, and a
  corpus with dozens of dead citation anchors said exactly that — a whole-corpus verdict printed
  by a pass that never left the note directories. It now names the vault, says the *note-level*
  checks passed, and lists what it did not open, read off the mode table rather than written by
  hand, so a mode added to the gate cannot leave that line quietly overstating its own coverage.
  A new mode is a row in that table plus its own dispatch, which is what kept four parallel
  changes out of one another's argument parser.
- **A heading's explicit `{#anchor}` attribute is the citation address; the slug is now the
  fallback rather than the contract.** `used_in` entries name `document.md#anchor`, and how a
  heading became that anchor was written down nowhere — so the lint applied the GitHub slug rule
  and the shipped template disagreed with it about the template's own headings. `## Competition &
  moat` slugs to `competition--moat`; an author citing that section writes `#competition`, and a
  corpus authored exactly per `plan-template.md` failed `--used-in`. **The deeper half was that
  there was no way to declare a stable anchor at all**, while the skill actively requires
  headings to be reworded as the finding sharpens — so every sharpened heading silently
  invalidated every citation into that section, and the only available fix was rewriting the
  notes, which re-breaks on the next edit. `rendering.md` now carries the contract both skills
  render against — strip the attribute from the visible heading, emit it as the element `id`, so
  both addresses stay live — `plan-template.md` carries an anchor on every heading, and
  `--used-in` registers **both** the explicit anchor and the slug of the remaining text.
  Registering both is what keeps an existing vault passing: its notes cite the slug, and an
  upgrade that fails an untouched corpus is one nobody takes. Rewording protection is unaffected
  either way — a heading whose text changes loses its old slug under either design, and the
  attribute is the half that survives. Inside this repo the attribute is allowed only in fenced
  template blocks, enforced in both directions: a live heading carrying one would fold `{`, `#`
  and `}` into its own slug and take every Contents link with it, and a count that fails at zero
  stops the prohibition outliving the contract it exists for.
- **A seventh note type, `milestone`, and a generated `research/timeline.md`, because nothing in
  the corpus held what is true at a given month.** The method carries a full reference on roadmap
  sequencing and requires that items unlock each other, but no artifact recorded position — so a
  proposal was judged against the corpus's snapshot of today rather than against the state at the
  month it would land. That is wrong in both directions: it kills a proposal over a gap that is a
  dated roadmap item, and it credits a capability whose prerequisite has not shipped. **Both
  directions read as rigour**, which is why nothing ever surfaced it. A milestone carries `moves`
  (the note the item moves), `resource`, `sequence`, `depends_on` and `date_confidence`, and
  three new checks read off them: `false-independence` when two milestones share a `resource`
  **and** a `sequence`, which asserts them concurrent on one constrained resource;
  `dependency-after-dependent` when a `depends_on` target sequences at or after the item needing
  it; and `sequence-not-orderable`, which exists because both order checks skip a value they
  cannot compare — a `sequence` of `M4` takes them down silently and prints the same green as a
  roadmap that passed them. **"Every roadmap item names the assumption it moves" stops being
  prose nobody verifies for one word**: `moves` joins the edge fields, so the existing
  `dangling-edge` rule covers it. `research/timeline.md` joins the output contract as a **view
  over these notes** rather than a seventh hand-maintained document — state at M0, the sequence
  with what each item unlocks, and chains that walk a proposal to the month it lands with its
  prerequisites counted. Two fields did not ship as originally sketched, and both changes are the
  same argument: `unlocks` is derived from the reverse of `depends_on` rather than stored,
  because a stored backlink is a second copy of a fact that can drift from the first and the two
  queries then disagree with nothing able to say which is right; and `date_confidence` is
  required rather than optional, because an absent field is indistinguishable from a forgotten
  one, and without a positive record a skill-derived month and a founder-stated month are the
  same string on the page.
- **`vault.md` said "Resist adding a seventh" and this release overrules it, with the argument
  written beside the rule it breaks.** A rule overruled in silence stops being a rule: the next
  type arrives citing this one as precedent, and nothing on the page says what precedent it set.
  The ceiling is real and its reasoning is unchanged — past about six types the taxonomy becomes
  ceremony, authors stall between two types that differ only in emphasis, pick inconsistently,
  and the query that depends on the type being right returns a partial answer. **What is written
  beside it is the test an eighth type has to pass, not a licence for one.** Three things had to
  hold. The stated harm cannot occur: nothing in the other six carries a position, a dependency
  or a resource cost, so there is no pair to stall between — a note that says *when this happens*
  is not a near-miss for a note that says *whether this is true*. The edge escape hatch does not
  reach it: "structure that does not fit a type belongs on an edge" presumes two notes to hang
  the edge between, and there was no note anywhere in the vault for a roadmap item. And the set
  was never six grades: five are epistemic, `decision` is a record of a choice with a reopen
  trigger, so a second record type for scheduled work follows that precedent instead of breaking
  it.
- **`--supersession-sweep` now carries a verdict — a supersession nothing says was read is a
  failure.** 1.8.0 shipped the sweep as a report: it printed the sections a supersession put in
  doubt, exited 0 either way, and the skill conceded it was the report half. **A worklist nobody
  is forced to read is not a gate**, and the failure it exists for is the most damaging one
  available — a correction lands in one document, its siblings go on asserting the superseded
  version, and every check passes because every note is individually well-formed. `reconciled:`,
  a quoted ISO date on the note carrying `supersedes`, is that assertion moved into the ledger:
  the sweep fails when it is absent and when it predates that note's own `created`. Both dates
  are quoted and both sides of the comparison are forced to strings, so it stays a plain string
  comparison with no date library anywhere near it. **The worklist is still a report** — a fully
  reconciled vault prints its rows, prints its count, and exits 0, because a supersession with a
  blast radius is the corpus doing its job and a mode that went red on a healthy vault would
  teach a reader to ignore the exit code the real checks depend on. And the field records that
  the read was *claimed*, not that it was done; a date can be stamped without opening a document.
  What the verdict removes is skipping it silently. The sweep also stopped double-counting a
  section: now that a heading is addressable two ways, two `used_in` entries can name one
  physical section and produce two worklist rows for one job — the double-count the row grouping
  exists to prevent, on the count a read is sized by. Anchors are folded to their alphanumeric
  bytes before grouping, deliberately looser than the rule that decides whether an anchor
  *resolves*, and a fold key claimed by two different headings is retired rather than resolved:
  being wrong there costs a section nobody re-reads, so it refuses rather than guesses.
- **`--red-team` fails a dispatched lens that wrote no objection rows, because a silent lens and a
  lens that found nothing are the same silence.** A panel lens returns, its findings get folded
  into two documents, and its rows are never written to `red-team.md` at all — so plan prose
  cites objection codes into a file carrying none of them, and nothing in the corpus could tell.
  The check had to create the record before it could enforce it: `red-team.md` gains a `## Lenses
  dispatched` roster, and the mode fails both when a rostered lens wrote no row **and** when a
  row names a lens the roster does not — the second direction because otherwise the check clears
  by deleting a line from the roster. No `red-team.md` means no panel was dispatched, and it
  passes. **A round's roster rows are written in the edit that folds that round's objections, not
  at dispatch**: a roster written ahead of its rows fails for the whole time the round is in
  flight, and a gate that fails on the normal case is one people learn to skip. The mode also
  joins invariant 19's pre-panel gate, which stays *named calls* rather than becoming
  `--release-gate` — the composite also runs the default check, which that gate deliberately
  excludes so a malformed note written during drafting cannot block a dispatch on a fix unrelated
  to whether the plan and the ledger agree; and invariant 15 gives `--release-gate` one home, at
  the render, because a call with two homes makes "did the gate run" a question of recall again,
  which is the defect the composite was built to remove.
- **Invariant 23 — steelman a founder's statement before checking it, because the cheapest
  adjacent number is the one that gets checked.** The both-directions rules governed values in
  the model and claims about the subject's own product; nothing covered a founder's offhand
  assertion, and the failure shape is specific and repeatable. The founder means the *delivered*
  thing, the analyst checks the *list price*, and the refutation comes back tidy, confident and
  beside the point. Generic shape: a founder says a competing tool costs more than their own
  seat; the competitor's list price is lower, so the claim is filed as false — but that
  competitor bills separately for the compute underneath it, so the delivered cost is roughly
  double the seat and the founder was right about the thing that matters. **This is invariant 3
  aimed at a founder statement instead of at the model**: a metric chosen after the conclusion is
  a conclusion wearing an instrument, and reaching for the checkable number rather than the
  claimed one is that same move made in the analyst's own favour. It ships with its filing rule
  in the same breath, because most of what it surfaces is not a note — a correction that moves no
  number in the plan is a conversation.
- **Objection IDs are namespaced by round — `R<round>-O<n>` — so a re-dispatched panel cannot
  collide with the one before it.** The row template used a bare `#` with no round column, and
  numbering restarts per dispatch, so in a multi-round engagement — a revision, a follow-on
  session — round 2's `O1` and round 4's `O1` are one code for two different objections, and plan
  prose citing that number resolves to whichever the reader happens to find. Round is the count
  of Phase 4 dispatches for the engagement, and **a cited code is never renumbered**, which is
  the rule `[F#]` codes already carry for the same reason: a renumber silently repoints every
  citation already written. The plan template's surviving-objections section carries the
  round-qualified shape too, because a format restated in a second file is only enforced where it
  is restated correctly.
- **`schemaVersion` moves to 2, and the tool reads both 1 and 2 — an existing vault keeps working
  untouched and upgrades on its own schedule.** Every check this release adds that an older
  corpus could not owe is gated on the version the vault declares rather than on a field being
  present, so a vault at 1 behaves exactly as it did: it has no `milestones/` directory by
  construction, it cannot owe a `reconciled:` date on a supersession written before the field
  existed, and a `red-team.md` with no roster passes. A version from the future is still refused,
  which is what the field is for — an older lint reading a newer vault is precisely the case
  `schemaVersion` exists to catch, and that is why a bump is right here rather than optional.
  `vault-migration.md` documents the 1→2 path with the stamp as the **last** step, after the
  vault can already pass at 2: stamped first, the version asserts a shape the corpus does not yet
  have, and every failure that follows reads as a broken vault rather than an unfinished
  migration.
- **The fixture suite went from 95 assertions to 174, and three of the new corpora exist to fail
  exactly one mode.** A suite whose vaults agree across every part cannot catch a gate that
  reports only its first part's verdict: `clean/` is green everywhere and `violations/` is red
  everywhere, so both pass a composite that silently drops the rest. `dead-citation/` passes the
  note-level check and fails `--used-in`; `unreconciled/` passes both of those and fails only the
  sweep; `panel-gap/` fails only `--red-team`. `anchor-alias/` reaches one section by two
  spellings and asserts it produces one worklist row rather than two. The schemaVersion-1 twins
  are **copies** of their version-2 originals with the version rewritten, not hand-written second
  corpora — a twin asserts the same thing only until the day one of the two is edited.
- **The `roadmap-table-vs-milestone-set` drift check did not ship, and issue #92 carries why.**
  The blocker is not which lint pass reads documents at the vault root; it is that there is **no
  non-fuzzy key** between the two sides. A roadmap row in the plan is prose and a milestone note's
  `title` is prose, so matching them is a similarity test that would fire on every
  correctly-written row whose wording drifted from its note — and the lint's own boundary comment
  says what that costs, since a check that cries wolf gets switched off and switching it off
  takes the working half with it. Here the working half is the four milestone checks this release
  did ship. The robust version needs the plan's roadmap table to render the `MILESTONE-` ID per
  row, which changes what a founder hands an investor and earns its own pass rather than arriving
  as the detail that made one lint rule convenient to write. **The half that mattered most is
  already closed**: `research/timeline.md` is generated from the milestone notes, so it cannot
  drift from them; what stays open is a hand-written table drifting from the same set.

## 1.9.0

- **Phase 0 now inventories the founder's own artifacts before the grill, and measures them
  rather than asking about them.** The skill treated the founder as a source of *intent* and the
  market as a source of *fact*, and never treated the founder's own work as a source of
  *evidence* — so the one body of material in an engagement that is simultaneously free, primary,
  checkable and unavailable to a competitor went unopened, and market research is none of those
  four. It is a worklist rather than a question: every repo the founder has written, every repo
  they have worked in for someone else, every document produced for a client, every product in
  the category they have personally used, anything they have published. Establish what exists,
  then open it — what an artifact is measured on lands as a primary observation resting on that
  artifact. **Measuring rather than asking is the whole of it**: asking returns the founder's
  recollection of an artifact, which is commentary and enters at the confidence everything else
  they say enters at, while opening it returns an observation anyone can re-check against the
  same file. The two arrive in the same words and only one is evidence. The failure this
  prevents: the grill asks what the founder's unfair advantages are and gets an adjective the
  plan then carries unsupported, while the repo that would have proved it, the dated report that
  predates the plan's own thesis, and the category tool they used for years and abandoned all sit
  unopened.
- **The founder-writing sweep now reaches the commercial half — what the founder wrote for a
  paying client — and carries it by what it establishes rather than by the file.** The sweep read
  blog, changelog, README, docs, talks, launch threads and issue bodies: all public, all
  marketing-shaped, and missing the class that outweighs them — proposals, audits, strategic
  reports, statements of work, post-mortems. A thesis stated in a dated report to a paying client
  is addressed to a third party, has money attached to being right, and usually predates the
  product by years, which makes it categorically stronger evidence than the same thesis on a
  blog; founders leave it out because it does not occur to them that it counts as theirs to
  offer. **The handling rule ships in the same paragraph, because that paragraph is what creates
  the exposure.** These documents are confidential by default, and the vault is a git repo from
  this phase and is offered a remote in Phase 5 — so without the rule the sweep's own success is
  what puts a client's document into a corpus built to be shared. What enters is the claim and
  its date, resting on a source with **no public URL** whose provenance names the document's kind
  and its year: never the text, never the client, never a copy. Naming that existing shape is
  what makes the rule enforceable rather than advisory — a provenance note pointing at a path
  outside the vault fails the lint by construction, so a rule that said only "a provenance note"
  left two ways to comply and the reachable one was copying the client's document in, which is
  exactly what the rule exists to stop.
- **The grill now interviews the founder as a *user* of the category, and asks for the failure
  rather than the verdict.** Competitor research reads docs, changelogs and pricing pages — every
  one written by the company being profiled, none of them recording the thing that made someone
  leave. The founder is usually the only person in the engagement who has been a *customer*
  here, and nothing in the question bank asked them what they had used and what broke, so the
  only first-hand category evidence available was never collected. **Both halves arrive in the
  same sentence and only one is admissible**: a verdict on a competitor rests on nothing a reader
  can re-check and enters as commentary, never promoted on the strength of who said it, while an
  account of a specific failure the founder hit themselves is dated, specific and primary —
  worth more than any feature matrix, because a matrix records what a product claims to do and
  this records what it did. Filed as one fact the verdict borrows the failure's confidence, and a
  section drafted months later cites a sweeping claim about the incumbents to a single remembered
  incident; so they are filed apart, at their own confidences. The failure then rides into the
  competitor profile as a question rather than a finding — structural, or a defect someone fixes
  next quarter — and only the structural kind is a wedge. **"I haven't used any of them" is
  itself a load-bearing answer**: it says the value hypotheses rest on a category the founder has
  read about rather than lived in, which raises what the research has to establish. It is
  recorded as a fact, never let pass as a question that got skipped. The area is also named in
  the grill's gating list, because that list is the checklist an agent works from, and a question
  living only in the interpolated playbook is one that never gets asked.
- **The plan states the strongest claim its evidence supports, and a claim weaker than its
  evidence is an error of the same class as one stronger.** Every other bar on the list fires on
  optimism, so a claim falling short of its own evidence clears all of them and reads as rigour —
  to the founder, to the panel, and to the reader who acts on it — and the only person who can
  catch it is the one who re-opens the source. **Understatement is not caution: an overclaim gets
  challenged, an understatement gets believed.** The bar generalises 1.8.0's pessimistic-drift
  rule, which was this principle scoped to one population at one phase; that rule now points here
  instead of restating the reasoning, because two overlapping bars in one block leave a reader
  unable to tell which governs — while keeping its worked examples, because an abstraction is
  what makes a bar unreadable at the moment it is being applied. The boundary with the
  neighbouring bar is stated rather than left to inference: the both-directions test governs the
  *values* in the model, and this governs what the prose asserts.
- **Invariant 22 — at every phase boundary, and after any substantive founder exchange, ask what
  was established in conversation that no note carries.** Invariant 20 governs claims that are
  already written and holds them open until the prose they name carries them; 22 governs what was
  never written at all — a constraint, a reframing or a disqualification both parties now treat
  as settled, reasoned from downstream, existing only in the transcript. Neither can substitute
  for the other: 20's worklist is the set of notes, and something that never became a note is not
  on it. Whatever the sweep surfaces is recorded exactly as invariant 21 records a late fact —
  the next `[F#]`, a `fact` note resting on the interview `source`, an appended row in the brief
  — and is then subject to 20 like anything else. It is an invariant rather than a step in one
  phase because value discovered in dialogue is the default state of a good engagement rather
  than an exception to it, and because compaction re-attaches only the head of a long skill file:
  a rule written into a phase body is out of context by the next phase, which is where the
  conversation it needed to sweep just happened. **The failure this prevents:** the engagement
  knows things the corpus does not, and nothing can tell. Every note is correct, the lint is
  clean, the reconciliation passes, and the missing material has no ID to be missing by — it
  surfaces at the walk sign-off, when the founder asks why the thing you both agreed three phases
  ago is not in the plan.

## 1.8.0

- **A citation is now opened, not just recorded.** `vault-lint.sh --used-in` reads the document
  every note's `used_in` names and checks that the file is there and the `#anchor` names a real
  heading. Nothing did that before: the default run reads the six note directories and stops at
  the vault's edge, so a document renamed after the claim was cited into it, or a heading cut
  while the note went on naming it, left the note reading as cited into a section nobody can
  find. The moment that costs the most is the one where it helps least — when a `stale_after`
  fires, the re-check it demands has nowhere to go. Two failures, named apart because they want
  different fixes: `used-in-missing-file` when nothing exists at the named path, and
  `used-in-dead-anchor` when the document is there and no heading slugs to the fragment. It is a
  verdict rather than a report and exits 1 on either. **What it deliberately does not check is
  the part worth writing down**: it asserts that a citation *resolves*, never that the named
  section *carries* the claim. The corpus resolves prose to a note for two of the three types a
  plan cites — `[S#]` through the source index, `[F#]` through the founder brief — and for the
  third it does not, because a claim is stated in the author's own words with no code to grep
  for. A scan matching note IDs against prose would fire on every correctly cited claim in the
  vault, and a check that cries wolf gets switched off, which takes the working half with it.
- **`--supersession-sweep` prints the re-read worklist a supersession owes, because replacing a
  note tells the note and nothing else.** When B supersedes A, every document section A's
  `used_in` named is now in doubt, and the supersession is visible on the note and invisible
  everywhere the note was cited. The sweep walks every superseded note and emits the union of
  those targets, **grouped one row per section** however many notes point at it — the unit of
  work is *re-read this section*, and a list repeating the section once per note makes a two-item
  job look like six — with the **row count printed first**, because the gate that consumes it is
  a read and a read is bounded only if its size is visible before it starts. It is a report and
  not a verdict: it exits 0 whether or not it finds anything, the contract `--unverified` already
  carries. A supersession with a blast radius is the corpus doing its job, and a mode that went
  red on a healthy vault would teach a reader to ignore the exit code the real checks depend on.
- **Invariant 19 — nothing is dispatched to the red team until the plan and the vault have been
  reconciled, and invariant 20 is what it reads for.** Lint ran at the per-dimension checkpoint
  and again before rendering; between drafting and the panel there was nothing. A panel briefed
  on a plan the ledger has already moved past returns objections about a version nobody is
  shipping, at full panel cost, and it cannot be walked back — a panelist already briefed cannot
  be un-briefed, which is why the gate sits on the dispatch rather than on the phase boundary.
  Three steps, and **the third is the gate**: `--used-in` fails, `--supersession-sweep` emits the
  worklist, and then a conductor *reads* every named section against the note behind it. The two
  lint calls bound that read rather than replace it, and bounding is what makes it happen at all
  — "check the plan against the vault" is a task nobody can size, and a task nobody can size is a
  task nobody starts. Invariant 20 states what the read is looking for: **a claim is finished
  when the prose it names carries it, not when the note is written.** Writing the note and
  writing `used_in` are one act, and the claim stays open until the section says what the note
  says. That is an invariant rather than a Phase 3 step because the obligation outlives Phase 3 —
  the vault keeps growing through drafting and into the panel, and a claim minted while the panel
  is running is subject to it exactly as one minted while the plan was being written. Written
  into the drafting phase, the rule would stop applying at the moment the vault is most likely to
  move, and a note minted from a disposed objection is the likeliest of all to sit in the ledger
  unread. The failure both close: a corpus where every note is individually correct and the
  documents built on them have quietly stopped agreeing.
- **Invariant 15 — the Phase 5 release gate is three calls, not one.** The default run never opens
  a citation target, so a plan clears the bare gate while carrying a citation to a document that
  was renamed or a section that was cut, and the next thing that happens is a rendered PDF
  asserting it to the one reader with no way to check. The render gate now runs the default
  check, then `--used-in`, then `--supersession-sweep`, and the sweep is in that set for a
  specific reason: Phase 4's dispositions mint supersessions *after* invariant 19's sweep has
  already run, which makes the render the only point they would be read at all. **Phase 2's
  checkpoint stays the bare run** — no note carries `used_in` until drafting cites it, so
  `--used-in` there checks an empty set, and running it anyway teaches the mode as cadence-wide
  when it belongs to one gate.
- **Invariant 21 — the grill closes as a phase, not as a channel.** Founder input arriving after
  Phase 1 is normal rather than exceptional, and it gets exactly what anything said during the
  grill gets: the same `fact` note resting on the interview source, the next `[F#]` in the
  existing sequence, an appended row in the founder brief, and invariant 20's propagation
  obligation like any other claim. The brief is appended to rather than rewritten, because `[F#]`
  codes are cited from the plan by number and a renumber silently repoints every citation already
  written. The failure this prevents: what a founder volunteers late is the evidence nobody
  thought to ask for, which makes it the least redundant material in the corpus and exactly what
  a model with no channel for it drops. It arrives conversationally mid-drafting and lands
  nowhere — no code, no note, no propagation obligation, because the phase that owned founder
  input is over — so it reaches the plan as something the conductor happened to remember, or not
  at all.
- **Invariant 3 — before a metric is cited as evidence for a mechanism, state what else produces
  that number.** A count says a thing exists; it never says why. Where the alternative explanation
  is not excluded the metric is a description and not evidence — and **a metric chosen after the
  conclusion is a conclusion wearing an instrument.** That second clause is the one worth writing
  down: a careful reader supplies the alternative explanation anyway, while an instrument selected
  to fit a thesis already reached leaves every step downstream of it locally sound, so there is
  nothing further along to catch it. The tell is a second metric introduced to confirm the first;
  chosen after the thesis, it tests the thesis's fit to the instrument rather than the mechanism,
  and it reads as corroboration. The rule bites hardest at the red team, where a matching quality
  bar now applies: a panelist handed a number reads it as the evidenced part of the brief and
  spends the turn elsewhere, so an unexcluded alternative explanation reaches the panel as settled
  ground and comes back unattacked.
- **Phase 3 opens by re-verifying product claims against source at the current commit, and the
  direction is the whole point.** The dossier is the product truth the plan inherits, and it was
  written before the research fleet spent a week running — the product moved underneath it. **A
  plan that only re-checks numbers that look too good drifts pessimistic, and every drift reads as
  rigour.** A capability that shipped, a limit that was raised, a seam that was closed: each one
  now reads as the plan being careful. The skill's existing skepticism fires in one direction only
  — strong rules against unmodelled optimism, a both-directions test on input values — so an
  understated product claim clears every other bar on the list and reaches an acquirer or an
  investor as a fabricated weakness, one the founder then has to argue their own plan out of. The
  four queries that already run before a section is drafted cannot reach it: a claim stale because
  the world moved is what `stale_after` catches, and a claim stale because the product moved has
  no shelf life on it at all. A drift lands as a supersession, not an edit in place, naming the
  release that moved it — edited in place, the plan reads as though it were written against a
  product state its author never saw.
- **The decision that a `claim` note does not get a citation code yet is written down, with the
  trigger that would reopen it** — `docs/specs/2026-07-27-claim-citation-codes.md`. Giving claims
  a code and an index would make the agreement check above mechanical, and would also change what
  every plan document looks like and what every migration into the vault has to produce: a design
  surface that earns its own pass rather than arriving as the implementation detail that made one
  check convenient to write. So the read is bounded instead, and what that costs is stated rather
  than discovered mid-release by whoever writes the gate — a lint either runs or it does not,
  while a read is a judgment step a person can skip under pressure. That is why the agreement rule
  lands as a numbered invariant in the head block rather than as a line inside the phase's own
  step: compaction re-attaches only the head of a long skill file, so a rule stated in a phase
  body is out of context by the time that phase runs, and a gate that is out of context when its
  phase runs is a gate that does not run. The sweep's own reported count is the instrument for the
  reopen — when the worklist routinely runs past what a conductor will read in one pass, the
  bounded read is spent and the mechanical resolution is worth the design pass it was deferred
  pending.

## 1.7.0

- **A price is now defended on two lenses, and `value-delivered` is the one that was missing.**
  All three pricing lenses were cost-side — affordability banned as an argument,
  `alternative-cost` mandatory wherever a price is defended, `switching-cost` pricing the move
  away — so nothing in the vocabulary named what the buyer *produces* with the product.
  Substitute pricing has a ceiling at the cost of the substitute, so a method mandating only that
  side anchors the price under the DIY figure, and it does so invisibly: the substitute number is
  well-sourced and reads as rigour, while the output figure nobody computed is simply absent from
  the page rather than visibly missing. The new term prices what the buyer can produce that they
  could not before, in the buyer's own currency, and excludes the three adjacent terms from both
  sides — `alternative-cost` was amended to declare the same boundary from its side, because a
  boundary stated once is the near-miss the vocabulary exists to kill and existing corpora already
  carry output-value claims filed there for want of anywhere else to put them. It is
  `required: false` on purpose: the output delta is not expressible in the buyer's currency for
  every product, and a required row there produces a fabricated figure to close a coverage gap.
  The obligation is conditional and lives where its condition is visible — the plan template's new
  `## Value delivered` section, fired wherever a price is defended, sibling to
  `## Cost of the alternative` and bound to it in both directions so an agent reading either knows
  both fire.
- **Retention is `policy within a structural band`, the construction `price` already used.** The
  driver-home table filed it `structural`, and the sentence beneath it said what that meant:
  conversion and retention are what they are at the stage the target counts, and no decision the
  founder takes this week moves them. Half of that is right. A consumer utility does not retain
  like an ERP — that band is the category's and it stands — but the position inside the band is
  the product's: the depth of what it does, whether the valuable part is reachable unassisted, and
  the friction between the two. Because the construction already existed for `price`, the change
  needs no new vocabulary and the existing rule
  `## A structural driver may be sourced from the reference class; a policy driver may only be checked by it`
  covers it unedited — the class sources the band and may only *check* the position. What moves is
  what a verdict may conclude: a retention-bound miss now reads *this product as built does not
  retain* with the target under one changed position beside it, never *this market does not
  retain*, and it routes to the roadmap rather than to the founder's calendar. Filed `structural`,
  a research pass could identify the coupling exactly — where value compounds per additional
  teammate the multi-seat cohort churns lower, so one improvement moves seats-per-account and
  churn together and moves the ceiling multiplicatively — write it down, and have the label keep it
  out of the arithmetic anyway. That is a labelling bug, which is why the fix is a `kind` column
  and not a new section.
- **The two ends are one change, because the cross-link is what makes either work.** Delivered
  value is the input and retention is where it becomes observable in the arithmetic: churn is the
  divisor of the steady-state identity, so halving it roughly doubles the equilibrium and with it
  the price the ceiling will carry. Price on delivered value with no retention channel and the
  value claim never touches a number — it sits in a pricing paragraph and the model is unmoved.
  Model retention as product-movable with no value rule behind it and you have a lever with no
  driver. So the template's `## Value delivered` names retention as its channel into the model,
  the retention work names delivered value as what places the product inside its band, and
  `roadmap-sequencing.md` carries the consequence: churn is a term of the identity like any other,
  an item moving it compounds with items moving the numerator, and two items both aimed at
  retention compete rather than add.
- **One guard, applied at both ends, and it is what makes the change shippable.** A claim about
  delivered value or about a retention improvement carries a sourced base and labels its magnitude
  `measured`, `reference-class` or `assumed`, with an `assumed` one taking the both-directions test
  like any other input. Both are the optimistic mirror of the 1.5.0 rule, which only ever fired on
  pessimistic inputs, and both flatter the thing the founder built — which is exactly what makes
  them easy to write and hard to challenge. The guard binds harder at the retention end because
  churn is the divisor: an unguarded improvement claim moves the answer faster than any other input
  in the model, and unguarded the reclassification is a licence to model churn down to whatever the
  target needs. Three quality bars make it checkable rather than merely stated, including one on
  silence — a plan whose roadmap improves the product states what that does to retention or states
  that it does not and why, because silence read as "no effect" is a claim nobody made.
- **`conversion` stays `structural`, and the reason is recorded next to the `kind` column.**
  Onboarding quality moves activation and trial-to-paid too, so the argument above reaches for
  conversion next. It stops there deliberately: conversion is a funnel property of the category
  measured at a stage, while retention is where a product's own value shows up over time. If reach
  is policy, price is split, retention is split and conversion is split as well, the identity keeps
  no structural term at all, every negative verdict becomes conditional on something the founder
  could change this week, and the skill loses the one output it exists to be able to produce, which
  is telling a founder no.
- `vocabulary_version` 2 → **3**, with two entries in the amendment log — `alternative-cost` and
  `churn` — both at `amended_at: 3` and `shipped_in: "1.7.0"`. `churn`'s `must_assert` supersedes a
  bare rate carrying no band and no determinant; `alternative-cost`'s keeps a claim pricing the
  substitute's total cost and re-files one asserting what the buyer produces. One version step, one
  advisory for a founder to act on, one reconciliation pass per vault.

## 1.6.1

- **The vault's generated `README.md` is regenerated by what changed, not by which phase ended.**
  It was written at scaffold and again at each phase boundary, while the vault commits at every
  meaningful write — so between boundaries it stated a target and a verdict status the corpus had
  stopped asserting, and it read as current because its last line says it is generated rather than
  hand-edited. The window is not a rounding error: a renegotiated target settles mid-Phase 3, and
  1.6.0's reference-class re-flip makes a verdict that changes between boundaries a designed-for
  event. Regeneration now rides the commit that invalidates it. The skill already made this exact
  argument one level up — invariant 17 commits at every meaningful write because *phase boundaries
  are too coarse a unit of loss for a phase that writes dozens of files* — while the block below it
  pinned the README to the coarse unit that invariant rejects; the two now state the same cadence,
  and `.gitignore`, whose content does not track the corpus, keeps its phase-boundary cadence in a
  clause of its own.
- **The volatile fields are named, so the rule is decidable at commit time.** Four of them: the
  current target, its verdict status, which phase the corpus is in, and the note-type map when the
  corpus starts asserting a type it did not carry before. An agent about to commit checks its write
  against those four rather than re-reading the generated file — a rule that expensive is one that
  gets skipped — and because nothing else the README carries moves after scaffold, most commits
  touch none of them and leave the file alone. That floor is deliberate: a README rewritten on
  every commit buries the ledger changes the history exists to show, which is the same failure
  `.gitignore` exists to prevent. Phase 3's verdict step names the regeneration where it fires; the
  README stays generated rather than hand-edited, and an existing vault picks the cadence up on its
  next write with no migration.

## 1.6.0

- **A reference class inferred from the subject's own price point or packaging is downstream of a
  policy input, and it inherits that input's mutability.** 1.5.0 made the class a first-class
  input — named, classified `structural`, homed to `research/growth-curves.md` and flip-tested —
  but left unsaid what the class may be *derived from*. `kind` classifies by who sets the value,
  and a class read off the subject's own price point and delivery shape was selected by a founder
  decision rather than by the market; filing it `structural` on the strength of where it landed
  hides that. It stays `structural` — there is no third kind — but it now says what it was
  inferred from wherever it is named, and it is re-flipped when that input settles differently.
  Without it a founder decision selects the comparable set, the set fixes conversion, retention
  and the multiple together one level beneath the arithmetic, and the verdict that follows is
  reported as a property of the market: repricing reads as a pricing question when it is a
  reclassification, and the one change that moves every structural driver at once is never costed.
- **The re-flip now has a moment to fire in, and the trigger fires in both directions.** The class
  is named in Phase 2 from the dossier, while the pricing and capital forks that settle the
  subject's packaging are simulated and settled inside Phase 3 — so the class was fixed before the
  decision it was inferred from was final, and the re-flip was missed by construction on every run
  rather than occasionally. It is attached to Phase 3, the one phase where both halves are open,
  and it covers both gaps: re-flip against whatever pricing, packaging and delivery decision is
  settled at the moment the verdict is computed, **and** re-flip again when a fork settled later in
  that phase — the strategic-fork simulation runs after the verdict, not before it — lands on a
  different packaging than the class was read off. A changed class re-solves the identity rather
  than annotating the verdict, because every structural driver beneath it moves together. The
  verdict checklist carries the re-flip as its own step immediately before the solve step, which is
  where it fires in time, and a quality bar makes it checkable rather than merely stated.

## 1.5.0

- **Every driver value names its driver in both directions, and a low one with none is
  `unmodelled, not conservative`.** Skepticism fired on optimistic inputs and not on pessimistic
  ones: a low number entered the model with nothing behind it and read as rigour, because
  challenging a conservative figure looks like advocacy while challenging an aggressive one looks
  like discipline. In a multiplicative chain that is not a rounding error: seven multiplied terms,
  each filled at roughly half of what the evidence carries and every one of them defensible on its
  own, return the target short by about two orders of magnitude — and the readout names a
  structural driver as binding rather than the stack of unexamined choices that produced it. The
  rule that would have caught it existed, but only for the projection *curve*: a flat stretch had
  to name its operational driver while the numbers the curve was built from did not. It now
  generalises to every model input and every driver value — each of the multiple's four inputs,
  every rate and share the chain multiplies — a conservative figure needs a source exactly as much
  as an aggressive one, and a low value with none takes the same label the flat-curve rule already
  used. The flip test does not cover this and is not asked to: it re-solves at both ends of an
  assumption's plausible range and asks whether the *verdict* moves, so a pessimistic value with
  no driver is a well-formed `assumption` carrying a `value` and a `sensitivity` and passes clean,
  because the band it was given is drawn around a centre nobody chose. The flip test audits how
  wide the uncertainty is; the new one, which runs first and on every value, audits whether the
  number was ever pointed anywhere on purpose.
- **A structural driver may be sourced from the reference class; a policy driver may only be
  checked by it.** The driver-home table already handed the same instrument two different
  authorities — `research/growth-curves.md` *sets* conversion and only *checks* reach — and stated
  the reason for neither, which left the split reading as a per-row accident rather than a
  principle. The principle: a structural driver is a property of the category, so the indexed set
  can source it; a policy driver is the founder's own configuration, so a comparable's value is
  evidence about a different company's choices and can only ever be a check. Sourcing a policy
  driver from a comparable is neither conservative nor aggressive — it answers a different
  question, and the answer comes back well-formed: the figure carries a citation, the identity
  balances, the binding driver is named with the confidence it would have had, and the founder's
  stated hours never entered the arithmetic at all. So `kind` now decides two things at two
  moments — at fill time where a value may come from, at verdict time what a negative verdict may
  conclude — and the target checklist classifies every driver *before* it fills any of them. The
  exit table moves with it: the growth slope at the sale month is a commitment this roadmap makes,
  so it is stated configuration with the indexed set as the check on it, never the plan's own
  projection fed back in.
- **A structural driver with no instrument of its own tries the reference class before it degrades
  to an assumption.** The ladder has three rungs — subject instrument, then the reference class
  where the driver is structural and the indexed set reaches it at the month the target counts,
  then `assumption`. The middle rung produces a `claim` resting on `research/growth-curves.md`,
  carrying that set's `stale_after` and a `validated_by` naming the kill test that would overturn
  it. The failure skipping it causes: invariant 11 caps a claim at its weakest input, so routing
  the only legitimate evidence a pre-launch company has through an `assumption` makes every driver
  weak by construction — and every plan for a company that has not launched then reads as
  unjustified, which is every company at the moment the plan is worth writing. `market-analysis`
  builds the indexed class precisely so a driver can take its value at a stated month; declining
  to let it is the skill refusing its own instrument, and the founder is told the evidence is thin
  when what is thin is the routing. Only what the set genuinely cannot speak to degrades: every
  policy driver, and any structural one the set does not index at the month in question.
- **The reference class is itself an input — named, classified and flip-tested like a driver.**
  Making it load-bearing changed the failure mode rather than removing it: a wrong class used to
  produce a visibly-hedged `assumption` and would now produce a confident `claim`. So which
  companies the subject is compared against is named in the readout, classified `structural`,
  homed to `research/growth-curves.md`, and put through the flip test — re-solved against each
  candidate set a reasonable person would argue for. A verdict that moves between two defensible
  classes is *undetermined*, with both classes named and the cheapest test that settles which one
  the subject belongs to. Left unwritten it is the largest unexamined input in the method, because
  it sets conversion, retention and the multiple at once, one level beneath the arithmetic: the
  whole verdict shifts without a single figure in it looking wrong, and the founder is handed a
  categorisation wearing the authority of the indexed set it was only ever assumed into.
- **A value the indexed set sourced carries the survivorship qualifier wherever it is reported.**
  Every company in that set got far enough to be written about, so the ones that posted the same
  early numbers and then stopped are absent by construction — a property of the set rather than of
  any member, and one that makes a structural driver sourced from it systematically optimistic.
  That is the defect above wearing the opposite sign, and it is harder to catch in this position
  because the number now has a citation behind it; replacing a pessimistic default nobody
  challenged with an optimistic one nobody challenged moves the error rather than removing it. The
  qualifier travels with the value into the readout and into any exhibit that renders it, in the
  same words each time, rather than sitting as a footnote on the research file, which is not where
  the number is read. And where a broad-population figure and a named-company value both exist for
  the same metric, the disagreement is recorded rather than averaged or picked by feel: the two
  routinely differ by most of an order of magnitude, because the named companies are the ones that
  worked, and a run that quietly took the higher of them has sized the plan against a population
  the subject is not in yet. The plan document now says which of the three a driver value came
  from — measured on the subject's own instrument, read off a sourced benchmark, or taken from the
  indexed class at a stated month — because rendered identically, a value extrapolated from
  comparables and one measured on this product are indistinguishable, and the founder acts on both
  equally.
- **Phase 3's both-directions check reaches the model's inputs, not only its curve.** The two
  checks that already ran on the projection read the curve rather than what it was built from: the
  level check places the implied monthly growth *rate* against the observed band, and the shape
  check places the implied *trajectory* against the indexed curves at matching months since
  origin. A chain filled at the low end at every term clears both — in band and in shape, at a
  scale nobody chose. Every input to the revenue build now takes the both-directions test before
  either of those two runs.
- **Phase 4's pre-pass tests the identity it writes.** It grew from three steps to five. It now
  names every input that is unmodelled in the *pessimistic* direction — the direction it
  structurally could not see, since a low number reads as the cautious choice rather than as the
  claim it is, so it passed through the block unremarked and the panel inherited a floor nobody
  sourced. And it reads the terms it wrote back against what the founder stated the business is,
  reporting a term the business has that the identity lacks. Writing the identity out is the right
  instrument and it is not a test of itself: a business with three revenue layers solved as a
  single-layer funnel is internally consistent and solves cleanly, so the arithmetic is correct
  about the wrong business while every value inside it is individually defensible, and no rule
  about input *values* can reach it. Both additions travel in the block every red-team brief
  carries verbatim, and the verification checklist names them there rather than leaving them to
  the paragraph that describes them.
- **Two of the rules above earn a quality bar, because prose in a reference file is not a
  producer.** A rule reaches an agent only when it is interpolated into a brief or performed by
  the conductor in a phase, so a rule stated once in a reference file reads correct on the page
  while nothing runs it. The both-directions test on every model input, and the reference-class
  rung that keeps a pre-launch structural driver out of the `assumption` pile, are each on the
  list that says what may not ship.

## 1.4.0

- **An exit target has its own identity, and its dominant term is a band.** An outcome stated as
  an acquisition or a company valuation was the one shape `business-plan` could not decompose:
  forced into the revenue identity it came back confident about ARR, which is the term an exit
  verdict is least sensitive to, while the term that decides the answer disappeared into an
  assumed figure nobody wrote down. It is now `exit value = ARR at exit × multiple`. The left
  term is one of the existing identities solved at the *sale* date rather than the target date,
  so those shapes are a term of this one and never a substitute for it, and the multiple enters
  as a band and never as a scalar — written as one number it reads as a property of the category
  and the verdict inherits a precision nobody evidenced. The band's ends trace to four inputs,
  each with a named home in the corpus and a `kind` per invariant 18, and not one of them is ARR:
  the growth slope at the moment of sale and the strategic necessity of the asset to a *named*
  acquirer are policy, while scarcity — whether the buyer ships it itself in two quarters — and
  the count of buyers with the same hole are structural. One interested party is a price **floor**
  and not a price, because a single bidder pays whatever the founder's next-best alternative is
  worth. Reporting a slope-bound exit as structural tells a founder their company cannot be sold
  for that, when what is true is that this roadmap cannot sell it for that. The multiple is
  usually the binding driver and always the least evidenced, so an exit solved at a single
  assumed multiple is the existing traces-to-nothing case applied to the term that decides the
  answer: the run returns **undetermined** and names the cheapest test, which is a comparable-exit
  reference class rather than a founder interview — the founder cannot know a price set by buyers
  they have not met, so asking returns their hope wearing the authority of an answer. And the
  window under the band is structural and time-varying, which makes this the first driver whose
  `stale_after` is load-bearing rather than administrative: a multiple assumed three years out
  assumes today's comparables' window is still open then, and a shelf life set to the plan's own
  horizon comes up for re-checking on the one date the answer stops being useful. The exit also
  gets its own lever table — slope, acquirer legibility, date — because hours, capital and price
  all act one term down, through the side of the identity the verdict was least sensitive to. The
  same term reaches the roadmap and the memo: a roadmap item may now earn its place by moving one
  of the multiple's inputs rather than a row in the assumptions table, which models ARR and has no
  row for the multiple at all — so the items aimed at the term that decides the answer were being
  filed as maintenance, and the permutation table that ranks orderings is measured at the sale
  month, since the order maximising twelve-month cumulative can be the one that arrives at the
  sale decelerating. In the venture memo the ask is sized against the slope it holds *through* the
  sale month rather than a revenue level, the moat section asks what stops the *buyer* shipping it
  next quarter, and the financial summary runs to the sale date instead of stopping at 36 months.
- **A target stated as a range is solved at its corners, and a midpoint is a number neither end
  asserts.** Either axis may be stated as a range — a salary replaced in eighteen to twenty-four
  months, a sale at a value range inside a date range — and both at once is how an exit target
  normally arrives rather than an edge case. A value range over a date range is a rectangle, not
  a point: the corners are not equally hard, and which of them clear *is* the verdict. So a ranged
  target returns the set of corner verdicts, with the binding driver and its kind named per
  corner, which tells the founder which part of their own ambition is the problem and leaves the
  rest standing. Collapsed to its centre, a rectangle where three corners clear and one fails
  reads as a clean yes, and the corner that fails is usually the one the founder was aiming at.
  Two distinctions carry the subtle half of it. A stated range is **not** an assumption and does
  not trigger the flip test — that test runs on evidence uncertainty, the plausible range of a
  driver nobody sourced, while the corner solve runs on stated intent, which is the founder's own
  and needs no source; conflating them returns *undetermined* for every ranged target by
  construction, because a rectangle drawn across a real decision boundary is exactly one whose
  corners disagree, and that disagreement is the finding rather than a gap in the evidence. And
  the late end of a date range is not the easy end: it is cheaper on ARR, because the
  reference-class decay has more months to compound, and more exposed on the multiple, because
  the window closes. A founder who widens the date to make the target easier has bought ARR
  headroom with window risk nobody told them about. The plan carries the corners as a table with
  the founder's stated range and the evidence's range on separate labelled rows — both arrive as
  an interval with two ends, and merged the founder reads the whole width as their ambition being
  narrowed when half of it is the evidence admitting what it does not know.
- **A growth rate carries the ARR bucket it was measured in, and rates are compared only within a
  bucket.** Re-basing a comparable's series to months since a named origin controls for calendar
  time and market conditions; it does not control for **scale**, and nothing else recorded the ARR
  level a rate was posted at. So two companies sitting at month 18 — one posting around 20%/mo
  from a few hundred thousand in ARR, one around 4%/mo at tens of millions — were compared as
  commensurable and pooled into a month-18 range neither company's scale supports. It fires in
  both directions, which is why tagging one end of it is not enough: percentage growth off a small
  base is arithmetically easy and reads as a category norm, so a subject at low ARR is told its
  plan is unambitious against companies that were tiny when they posted those rates, while the
  same undifferentiated band makes the high-ARR rate look reachable at a scale nobody in the set
  achieved it at. Buckets are now declared as a property of the reference class, every rate is
  tagged with the one it was measured in, a comparable that crosses a bucket mid-series is tagged
  per stretch rather than per company, the decay is fitted per bucket where the set spans more
  than one, and the projection is checked against the bucket it will actually be in at that month.
  The exhibit carries the bucket too rather than leaving it to the caption — a chart that hides it
  re-creates the cross-bucket comparison in the one artifact a reader trusts without reading the
  prose.
- **A headline acquisition figure is not what the seller received, and the whole reference class
  skews high because of it.** Where the target is an exit, the disclosed acquisitions in the
  category are a second series on the same indexed axis — each sale placed at the month since the
  acquired company's own named origin and at its growth slope running into the sale, because slope
  is what the multiple is set by and a multiple with no slope beside it cannot be read at the
  month a roadmap puts its own sale. Built naively that set lies: earnout contingent on post-close
  targets, escrow released later or not at all, acquirer stock carried at the acquirer's own
  valuation, and retention packages that are compensation for the team rather than price for the
  company all sit inside an announced number. That is not one bad data point to drop — headlines
  are what gets published, and the components that reduce them are disclosed later, elsewhere, in
  less-read documents, so the bias belongs to the class, and naming survivorship does not catch it
  because these deals did close. The set therefore records the headline and what portion was
  actually received at close with the source for the split, and the band is drawn on consideration
  received, cash-only figure beside it. A comparable whose split cannot be found is labelled
  `headline-only, uncorroborated` everywhere it appears and never pooled with decomposed ones:
  pooled, it lifts the band by exactly the amount nobody could verify, and the label is the only
  thing telling a reader which end of the band rests on a figure and which on an announcement.
  Endpoints stay labelled with their company, ARR at exit, stage and slope rather than averaged
  into a mean multiple that describes no deal that happened; too few comparables to bound a band
  is written in those words — "two comparables, no band" — instead of a line run through a pair;
  and survivorship is stated outright beside the band, because nobody publishes the multiple they
  were offered and refused, so the set is what this category paid the sellers who said yes.
- **The red team reads the model's frame before it reads the model's numbers.** All three lenses
  reason *from* the plan document, so all three inherit its frame: a revenue model that assumes a
  flat curve, or that treats a founder's choice as a fixed property of the business, hands every
  panelist that frame as the ground they attack from. A structurally wrong model therefore drew
  three lenses' worth of detail objections and none about its shape, and the plan read as
  thoroughly attacked — the tell being a panel whose severest row argues about a value inside the
  identity while the identity itself carries a term nobody labelled. A pre-pass now runs before
  any brief is written and its output goes into every brief: the identity written out as a chain
  of terms ahead of any value in it, every input labelled `structural` or `policy` in those two
  words and never a coined third (a "semi-structural" is a way of not answering that reads as a
  finer distinction and survives review for exactly that reason), and the curve's shape — flat,
  decaying or compounding — stated as a claim with a named driver behind it rather than as the
  backdrop it was drawn on. A fourth lens would have inherited the same frame and arrived
  alongside the other three, too late to change what the panel was pointed at; that is why it is a
  pre-pass and not another voice. Where the target is an exit, the capital lens also swaps the
  funder's question for the acquirer's — which named buyer has a hole this patches, and is the
  product visibly the patch — because an exit plan otherwise collects a full investor-shaped
  objection table while nobody asks who buys it, and fundable and acquirable have different
  answers often enough that a pass on one says nothing about the other.
- **The vocabulary carries a version, and drift has a reconciliation path instead of an
  advisory.** Phase 0 already reported that a base definition had changed when an existing vault
  was reused, but a report that only says the definitions differ names no term: it hands the
  founder a corpus-wide re-read with no way to size it, and a task nobody can size is a task
  nobody starts, so the drift stays in place and the advisory becomes the noise people learn to
  skip. `vocabulary.yml` now carries a `vocabulary_version` and an `amendments` log, and Phase 0
  reports the delta plus every entry between the vault's stamp and the shipped one — per amended
  term the framing it carried (`was`), the framing it carries now (`now`), and the test each claim
  already filed under it has to pass (`must_assert`). A copy carrying no stamp predates the stamp
  and is older than every entry rather than equal to the current version, since reading an absent
  stamp as current would exempt exactly the vaults most likely to need reconciling. The version is
  owned by that file rather than by the plugin, and adding a term does not move it: bumping on
  additions would fire the advisory on every release that touched the file and train the founder
  to dismiss it before the one release where a definition actually moved. `vault-migration.md`
  carries the procedure as its own entry point — one grep per amended term bounds the entire
  scope, because only claims carry a subject; a claim that no longer asserts what the subject now
  asserts is superseded under the standing two-edit rule with `supersedes_reason` naming the
  amendment, never re-filed in place under wording its author never saw; the paragraph in the plan
  standing on that claim is rewritten with it, or the reconciliation moves the defect rather than
  fixing it; and the vault adopts the amended wording and stamps its copy **last**, because
  adopting first is the silent redefinition the extension rule bans.
- **The vault root is `~/Documents/go-to-market/<product-slug>/`.** `business` named the
  business-plan half of a pair that also produces the whole market analysis, so the folder a user
  goes looking for their competitor research in was named after the other skill. Same layout, same
  slug rule, same boundary — the slug directory itself is still the vault, with no `vault/`
  subdirectory — only the parent changed. A corpus created under the old root is not found by the
  reuse check, which `ls`es the parent for a folder naming the same product: move the slug
  directory and nothing breaks, because every citation, `rests_on` edge and research file inside
  it is vault-relative by design.
- **The gate resolves every `#anchor` in the shipped reference files.** A skill's method lives in
  reference files navigated by their own `## Contents` blocks, and the gate resolved a link by its
  path with the fragment stripped — `other.md#gone` passed on the strength of `other.md` existing,
  and a pure in-file `(#gone)` had no path to resolve at all. So an edit deleted a `## Heading`
  while the file's own Contents block went on linking to it and everything stayed green, caught by
  hand rather than by the check. Check 9 validates every anchor, in-file and cross-file, against
  the headings the target file actually renders, and a file carrying a `## Contents` heading that
  offers no list-item anchor link is itself a failure — an index rewritten out of link form would
  otherwise drop out of the check while body links elsewhere in the same file kept it green. The
  slug rule lives in exactly one place: two checkers with two sluggers drift apart silently and
  both get trusted.
- **Three of the rules above earn a quality bar, because prose in a reference file is not a
  producer.** A rule reaches an agent only when it is interpolated into a brief or performed by
  the conductor in a phase, so a rule stated once in a reference file reads correct on the page
  while nothing runs it. The ranged target's corner readout, the model-identity block every
  red-team brief now carries, and the exit red team's named-acquirer question are each on the list
  that says what may not ship, rather than resting on the paragraph that describes them.

## 1.3.0

- **The projection guard is symmetric — a flat line names its driver exactly as a hockey stick
  does.** The revenue build rejected a curve that was too optimistic and accepted, without a
  word, one that assumed nothing happens: every inflection point had to name an operational
  driver, while a stretch of zero growth had to name nothing at all. But zero growth is not the
  absence of an assumption — it is the assertion that next month's reach, conversion and mix are
  identical to this month's, which needs a driver (a hard channel cap, a fixed-capacity delivery
  model, a deliberate no-growth policy) or it is unmodelled rather than cautious. The two
  directions are not equally dangerous, and the flat one is worse: an over-projection gets
  challenged and an under-projection gets believed, so a flat line reads as conservative,
  therefore credible, therefore unexamined, and reaches the founder's decisions with nothing
  behind it.
- **Every steady-state input is labelled `structural` or `policy`, and a policy-bound ceiling is
  the ceiling of that configuration.** *Structural* is set by the market or the product — churn
  at the evidenced rate, the category conversion benchmark, the price band willingness-to-pay
  supports. *Policy* is set by a founder decision — channel count, hours a week, the price point
  chosen inside that band, headcount, how much of the growth engine gets built. Without the
  label the identity solved to a number and the number was reported as a property of the
  business, so a decision became a law of nature and its consequence was reported as physics —
  and a number reported as physics is one nobody argues with. A ceiling whose binding input is
  policy is now stated in those terms, with the ceiling under at least one changed policy value
  shown beside it: the same arithmetic, relabelled, moving the founder from "the business tops
  out below my goal" to "this configuration does". It rides on a new invariant, 18, because the
  discipline has to hold in a phase the head of the file is all that survives into.
- **A negative verdict may not rest on a driver the founder chooses.** The target decomposed
  into drivers and named the one that binds without ever asking what kind of thing that driver
  was — and reach, the driver that binds most often, is channels crossed with hours, which is a
  decision and not a ceiling. A negative verdict is the single output most likely to make a
  founder stop, and a policy-bound one stopped them over something they could revisit this week,
  reported in the same frontmatter and at the same confidence letter as an observation somebody
  read off a page and quoted. The driver-home table now carries a `kind` column, the
  classification runs before the verdict is written anywhere, and where the binding driver is
  policy the run returns "unreachable in the stated configuration" with that variable named and
  goes straight to the counter-offer and the lever table with it solved. Relieving it is also
  what surfaces the next binding driver — often a structural one, and the one actually worth
  telling the founder about.
- **Comparable growth rates become a band, and the projection is checked against it.**
  `market-analysis` already collected disclosed traction per competitor but never dated those
  points, so no rate was derivable and nothing downstream could tell a plausible curve from an
  invented one. Profiles now carry at least two dated traction points per competitor where
  available, absence is recorded as absence rather than omitted — an omitted competitor and one
  that disclosed nothing were indistinguishable, which let the band narrow to whoever happened
  to publish — and `competitor-analysis.md` emits an `## Observed growth band` as a named output
  alongside the category verdict, both endpoints labelled with their competitor and stage rather
  than averaged into a single number describing no company in the set. `business-plan` then
  places the projection's own implied monthly growth rate against that band and defends any
  excursion in either direction with a named difference, or re-cuts. Category growth and company
  growth are held apart where both appear, since a slow-category finding was otherwise free to
  justify a flat company projection.
- **Comparable growth curves are a research dimension with an indexed exhibit, and the plan
  checks shape as well as level.** The band above is a scalar: it reports a slowest-to-fastest
  %/mo range and carries no trajectory, so it cannot answer what comparables were doing at
  *month 18* — which is the only question a target with a date actually asks. Worse, an averaged
  rate hides growth decay in both directions at once, understating the early months and
  overstating the late ones and reporting one number for both, so a projection could sit
  comfortably mid-band on its average while asserting a shape no comparable in the set had ever
  had: flat where every one of them decayed, or one rate held across the whole horizon. A new
  Tier-1 dimension emits `research/growth-curves.md` and a `## Comparable growth curves` section,
  with each company's series re-based to months since a *named* origin event rather than to
  calendar time — companies founded years apart compared by date compare market conditions, not
  trajectories — and a decay fitted across the set rather than assumed. Where the points are too
  few to fit, the dimension says so as a finding; a two-point average presented as a trajectory
  is the thing it exists to prevent. A company whose origin cannot be dated stays in the corpus
  with its calendar series and is listed as held out of the indexed overlay, because an unlisted
  exclusion reads as a comparable nobody found. `business-plan` now runs both checks: the level
  check against the band, then the shape check placing the projection's implied trajectory
  against the indexed set at matching months since origin. The driver-home table's `conversion`
  and `reach` rows can take a reference-class value from that set too — a category benchmark is
  one figure standing in for every stage at once, which quietly asserts that a company six months
  from its origin converts like one forty months from it.
- **The curve exhibit reaches the plan's own deliverable, and the strategy record behind it has
  two consumers.** Both were authored and neither was connected, which is the defect this release
  kept producing: a rule that reads correct while nothing produces or consumes it. The indexed
  exhibit was written into `market-analysis.md`, and a `business-plan` engagement runs the
  research engine's Phases 1–4 and skips its deliverables — so on the only path that matters the
  chart existed as markdown in a file nothing rendered, and the standalone-research path was the
  one place it became an artifact. It now lands in `business-plan.md`'s Target & verdict section,
  under the verdict it argues about, and Phase 5's render loop checks it page-by-page with
  everything else. That section rather than Market or Financial summary because those are swapped
  out on the bootstrap, lifestyle and lender tracks and Target & verdict is not — parked in one of
  them, the exhibit vanishes from exactly the tracks whose target is a fixed income figure. The
  strategy record — what each comparable was doing to grow across each stretch of its curve,
  sorted into `policy` or `structural` for *this* founder — had no reader at all. Its policy half
  now corroborates the go-to-market motion after the three gates rather than instead of them, and
  its structural half routes to Key risks, where what comparables had and this founder does not is
  pre-stated rather than left for a reader to find. Both halves keep the record as a `claim`: it
  is evidence of what those companies did, never proof of what caused their curves, and since
  nobody publishes the channel that did nothing, adopting a comparable's channel because it worked
  for them buys a survivorship artifact at the price of the plan's primary motion.
- **The red team is told the binding driver's kind, and the flat-line rule finally has a bar.**
  Every panelist brief carried the target, the verdict and the driver named as binding, but not
  that driver's `kind` — so a panel handed "unreachable, reach binds" attacked whether the target
  was reachable, when the question worth attacking was whether the configuration was the one to
  run. The brief now carries the kind, on the same reasoning the paragraph already gave for
  carrying the verdict at all: a panel that is not told the verdict is policy-bound grants the
  configuration it was computed under, and no lens is otherwise tasked with that. The dispatched
  market-analysis brief's `provisionalVerdict` carries it too, because the kind changes what
  researching the binding driver hardest even means — a structural driver wants better evidence
  for the value it has, a policy one wants evidence for what it could be set to. And the symmetric
  flat-line guard, the first gap this release set out to close, was stated in the revenue build
  and diagnosed in the failure-modes table while the quality bars — the list that says what may
  not ship — gated only the checks derived from it. It has its own bar now, above the band and
  trajectory bars that test the same claim: that the curve's shape is asserted, not assumed.
- **An amended base definition is reported when an existing vault is reused.** This release is
  the first time a base definition in `vocabulary.yml` has ever been amended
  (`steady-state-ceiling`), and it exposed a gap: upgrading a vault picks up *new* base terms but
  never an amended definition of a term it already has. `vault-lint.sh` reads the vault's own
  `_vocab.yml` and never the shipped file, which is deliberate and stays — a vault must remain
  checkable against the vocabulary it was written under, or an amendment retroactively invalidates
  claims that were correct when filed. The consequence was that every vault created before this
  release keeps the superseded wording indefinitely, with every claim under that subject written
  against it and nothing saying so. Phase 0 already holds both files — it copies `vocabulary.yml`
  for a new vault and explicitly reuses an existing one — so the comparison is free there and now
  runs there: a base term whose definition changed is reported to the founder as an advisory that
  does not stop the run. It is not an error, because a vault written under an older definition is
  valid and only unreviewed, and erroring would break every existing vault on upgrade — the
  failure that makes people stop upgrading. The claims already filed under an amended subject are
  re-read against the new wording and superseded under the standing two-edit rule, rather than
  silently re-filed under a definition their author never saw.
- **Every dispatched brief now interpolates its playbook, and the exemption table no longer
  documents the defect it exists to catch.** The per-competitor profiling call hand-wrote a prompt
  restating the competitors playbook in its own words, which is how the dated-traction rule above
  reached the playbook and never the agent — and it was then patched by restating the rule a second
  time, leaving two sources of truth that read correct. The sizing reconciler was told to follow a
  playbook skeleton it was never handed. Both take the block itself now, and their hand-written
  halves shrink to what a playbook cannot know: which competitor, which output path, the return
  contract. `close-gap` keeps its exemption on an argued constraint rather than an open bug — the
  critic's gaps name no dimension and several classes have none to name, so a key guessed off the
  free text would hand a gap the wrong playbook, worse than none.

## 1.2.0

- **The target is the input the plan is engineered backwards from.** `business-plan` had no
  destination in it: `ambition` is a category and `timeline` asks only when the first dollar needs
  to arrive, so nothing in a plan could be measured against where the founder was actually trying
  to get, and the skill could not answer the question they came with — *will this get me there?*
  The grill now opens on a concrete outcome and a date, before every other question, because
  every other answer is read against it. A direction stated without a number is converted rather
  than accepted, since an unquantified target cannot be tested and an untestable target turns the
  verdict below into an opinion; "no specific number" is recorded as the answer it is.
- **The verdict on that target is computed from evidenced drivers, and names the driver that
  binds.** The target is decomposed into the identity that produces it — customers × price, and
  what each of those in turn rests on — with every driver taking its value from the research
  rather than from judgement. The output is which driver fails and by how much, not a bare yes or
  no: "unreachable" on its own is neither actionable nor falsifiable. It runs twice —
  provisionally after the grill, before the research fleet spends anything and while changing the
  target is still free, then again on the evidence before the plan drafts, free to overturn the
  first in either direction.
- **A driver with no evidence makes the verdict undetermined, not negative.** Where flipping an
  unevidenced driver within a plausible range flips the answer, the run returns "undetermined —
  and this is the cheapest thing to test", with the test named. A confident "no" resting on a
  guessed conversion rate talks a founder out of something the evidence never spoke to, and the
  vault's formality makes that guess look researched.
- **An unreachable target opens a negotiation, and is never silently swapped.** The run returns
  the nearest target reachable on the founder's stated resources, then hours, capital and price as
  separate counterfactuals of what the outcome becomes if each one moves. The founder chooses, and
  the original stays in the plan as the thing that was tested and failed, carrying its
  `supersedes_reason` — a renegotiated target is a supersession, not a retraction, or "wanted
  $50k, settled on $12k, and here is why" becomes an archaeology exercise instead of one query.
- **The vault is a git repo from its first commit, and gets a remote only when asked.** `git init`
  runs at scaffold and every meaningful write is committed, not only every phase boundary: a
  single research phase writes dozens of files, so the phase is the wrong unit of loss for a crash
  or a bad edit. It also gives a claim ledger the history it was missing — `vault-lint.sh` says
  what the corpus asserts now, `git diff` says what it stopped asserting, and nothing else
  answered the second question. Once there are deliverables worth sharing, the skill asks for a
  destination and a visibility with private preselected, and
  creates a remote only on an explicit answer to both; asked at scaffold it would be asking a
  founder to consent to the visibility of contents neither party has seen. Past that point every
  commit is pushed, because a remote that was opted into and never receives one reads as a backup
  and is not one.
- **A dimension is accepted on its file, never on the summary its own author wrote.**
  `market-analysis` told the conductor it reads summaries rather than raw dumps, which made a
  ten-line self-report the entire basis on which a dimension's numbers entered the plan. Five
  parallel researchers writing straight into `research/` are five unreviewed writers, and where a
  `vault:` path is present they also mint the `source` notes the plan later resolves its citations
  through — so the door the "read summaries" rule left open led directly to a citable number
  nothing had ever reviewed. The summary is now triage: it says which file to open first and
  whether the dimension is worth folding in at all, and the file itself is read before that
  dimension is cited or its notes are trusted. The context economy the old rule existed for is
  untouched, because the reading is targeted — one dimension file at the moment it is about to be
  relied on, not every agent's transcript — and `business-plan`'s per-dimension checkpoint, which
  already linted the vault while the researcher's context was still live, now gates on the read as
  well.

## 1.1.1

- **`README.md` catches up to the portable-vault layout.** `1.1.0` removed the `vault/`
  subdirectory — the engagement folder became the vault — but the README still pointed
  `vault-lint.sh` at a `vault` path that no longer exists, which would find no
  `.vault/config.json` and lint nothing. Fixed both stale paths, added an "On disk" section
  documenting the actual on-disk layout, and renamed the source-tree `## Layout` section to
  `## Repo layout` so the two don't read as the same thing.

## 1.1.0

- **The engagement folder IS the vault — the `vault/` subdirectory is gone.** A source with no public URL carries a *vault-relative* path, so anything a `source` note rests on has to be inside the vault or the path resolves to nothing. Research prose is exactly such a source: a competitor ledger or a dimension file frequently *is* the evidence. With the vault one level down, `research/competitors.md` read as vault-relative, resolved nowhere, and linted clean. Moving the boundary up also makes a corpus **portable** — copy the slug directory and every citation, every `rests_on` edge and every research file travels with it. A ledger whose evidence lives outside it is an index, not a ledger.
- **New lint check: `unresolved-local-source`.** A `url` with no scheme and no `prefix:` marker is read as vault-relative and verified to exist. This is the class of failure the layout change was found through: a missing file is not a malformed field, so every other check passed while the evidence was absent. A path that deliberately points outside the vault now needs an explicit marker (`slug:research/file.md`), and a bare `host/path` needs its scheme.

## 1.0.1

- **Install now points at `trinity-ai-labs/claude-plugins`.** The marketplace catalogue used to live inside `orchestration-skills`, so installing these skills meant adding an unrelated plugin's repo as a marketplace first. The catalogue moved to a repo that ships no plugin of its own. The marketplace *name* is unchanged, so `market@trinity-ai-labs` still resolves — only the `marketplace add` line moves.

## 1.0.0

First release. The `market-analysis` and `business-plan` skills, previously installed by a symlinking shell script, packaged as one plugin.

- `install.sh` is gone. The marketplace installs and updates both skills, so the symlink-into-two-skill-homes script has nothing left to do.
- `vault-lint.sh` moved from `scripts/` to `bin/`, and the skills now invoke it bare as `vault-lint.sh`. Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`; the old relative `scripts/vault-lint.sh` resolved against the user's own project directory, where nothing of the sort exists.
