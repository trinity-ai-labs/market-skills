# Changelog

Versions are the `version` field in `.claude-plugin/plugin.json`. Because that field is set, an installed plugin only picks up changes when it **changes** — pushing to `main` alone ships nothing. CI enforces the bump.

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
