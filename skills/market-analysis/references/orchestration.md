# Canonical research workflows

The market-analysis research engine as TWO `Workflow` invocations with a conductor checkpoint
between them — the split is a hard gate, not an optimization: **Workflow A** (Discover +
Profile) returns a category verdict; the conductor updates the dossier's boundary on it; only
then does **Workflow B** (Research + Verify + Critique) run against the settled boundary.
Sizing a category the competitive set just falsified is the failure this structure exists to
prevent.

Adapt — don't invent the shape from scratch: fill the `args`, prune/add dimensions per the
dossier, keep the structure. Synthesis stays OUT of both workflows — that's the conductor's
job, on its own strongest-model turn, after reading everything.

**Preconditions (conductor, before Workflow A):**
- Confirm web tools work: run one trivial WebSearch. No web access → STOP and tell the user a
  market analysis is not producible without it. Never fall back to memory.
- `outDir` is ABSOLUTE (expand `~` yourself — briefs never carry `~` paths).
- Scripts can't call `Date.now()` — pass `date` in.
- On a re-run, load each existing `research/*.md` into `prior` so agents update instead of
  clobbering.

```js
Workflow({ script: <Workflow A below>, args: {
  date: "2026-07-25",
  outDir: "<absolute, e.g. /Users/you/Documents/business/acme-cli>",
  dossier: "<full product-dossier.md content, inline>",
  boundary: "<the category boundary paragraph>",
  citation: "<the citation contract from SKILL.md, verbatim — including the no-web-access refusal clause>",
  mustProfile: ["<competitor the founder/user named>", ...],   // always profiled, regardless of kind
  profileCap: 12,          // direct profiled up to this; non-direct up to half of it
  maxCompetitors: 60,
  dryRounds: 2,
}})
```

If the harness has no Workflow tool (check your tool list BEFORE planning around it): keep the
same stages and fleets with parallel `Agent` dispatches per stage, and run the dry-loop, the
category checkpoint, and the critic loop by hand across turns. The structure is the
requirement; the tool is the convenience.

## Workflow A — Discover + Profile + category verdict

```js
export const meta = {
  name: 'market-analysis-discover',
  description: 'Multi-modal competitor discovery, per-competitor profiling, category verdict',
  phases: [
    { title: 'Discover', detail: 'multi-modal sweep, loop until dry' },
    { title: 'Profile', detail: 'one agent per competitor + competitors.md writer' },
  ],
}

const { date, outDir, dossier, boundary, citation, mustProfile = [], profileCap = 12,
        maxCompetitors = 60, dryRounds = 2, playbookCompetitors } = args
const CTX = `Product dossier:\n${dossier}\n\nCategory boundary: ${boundary}\n\n${citation}\nDate: ${date}. Use WebSearch and WebFetch for every factual claim.`

const COMP_SCHEMA = { type: 'object', properties: { competitors: { type: 'array', items: {
  type: 'object', properties: { name: {type:'string'}, kind: {enum:['direct','indirect','adjacent','status-quo']}, why: {type:'string'}, url: {type:'string'} },
  required: ['name','kind','why'] } } }, required: ['competitors'] }
const VERDICT_SCHEMA = { type: 'object', properties: {
  confirms: {type:'boolean'}, revisedBoundary: {type:'string'}, why: {type:'string'} },
  required: ['confirms','revisedBoundary','why'] }

// ---- Discover: multi-modal sweep, loop until dry ----
phase('Discover')
const LENSES = [
  'category keyword searches (the category name + synonyms + "tools"/"software")',
  '"alternative to <each known player>" searches and alternatives-listing sites',
  'community threads: relevant subreddits, Hacker News, niche forums — what do users actually name?',
  'marketplaces and app stores relevant to the product surface',
  'funding databases and startup press: who raised money in this category recently',
  'the NON-PRODUCT alternative: what do these people do today with no tool — spreadsheet, manual process, internal build? Search forums and case studies for the workaround being displaced (kind: "status-quo")',
]
const seen = new Map()
mustProfile.forEach(n => seen.set(n.toLowerCase(), { name: n, kind: 'direct', why: 'named by founder/user — must profile' }))
let dry = 0
while (dry < dryRounds && seen.size < maxCompetitors) {
  const round = await parallel(LENSES.map((lens, i) => () =>
    agent(`${CTX}\n\nFind competitors/alternatives via ONE lens only: ${lens}.\nAlready known (do not re-report): ${[...seen.keys()].join(', ') || 'none'}.\nReturn everything plausibly competing inside the category boundary.`,
      { label: `find:${i}`, phase: 'Discover', model: 'sonnet', effort: 'low', schema: COMP_SCHEMA })))
  const fresh = round
    .flatMap(r => Array.isArray(r?.competitors) ? r.competitors : [])
    .filter(c => c?.name && !seen.has(c.name.toLowerCase()))
  if (!fresh.length) { dry++; continue }
  dry = 0
  fresh.forEach(c => seen.set(c.name.toLowerCase(), c))
  log(`${seen.size} competitors/alternatives found so far`)
}

// ---- Profile: deterministic roster, one agent per competitor, files not dumps ----
phase('Profile')
const roster = [...seen.values()]
const byName = (a, b) => a.name.localeCompare(b.name)
const must = roster.filter(c => mustProfile.some(m => m.toLowerCase() === c.name.toLowerCase()))
const direct = roster.filter(c => c.kind === 'direct' && !must.includes(c)).sort(byName).slice(0, profileCap)
const others = roster.filter(c => c.kind !== 'direct' && c.kind !== 'status-quo' && !must.includes(c))
  .sort(byName).slice(0, Math.ceil(profileCap / 2))
const toProfile = [...must, ...direct, ...others]
const skipped = roster.filter(c => !toProfile.includes(c) && c.kind !== 'status-quo').map(c => c.name)
if (skipped.length) log(`NOT profiled (visible omission, listed in competitors.md): ${skipped.join(', ')}`)

const profiles = await parallel(toProfile.map(c => () =>
  agent(`${CTX}\n\nProfile competitor "${c.name}" (${c.kind}; ${c.url || 'find their site'}). Write the full profile to ${outDir}/research/profiles/${c.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}.md: what it does (one paragraph), pricing model + actual price points, pricing-page CTA verbatim (their true GTM motion), disclosed traction (only citable numbers), funding, their positioning claim in their own words, most likely next move — ONLY as a prediction if backed by >=2 independent signal types (hiring patterns, changelog, pricing change, messaging drift, new integrations); with fewer, label it a rumor — and the WEDGE LINE: what they structurally don't cover and why. Full source table in the file. RETURN only: a <=120-word summary ending with the wedge line.`,
    { label: `profile:${c.name}`, phase: 'Profile', model: 'sonnet', effort: 'medium' })
    .then(p => ({ name: c.name, kind: c.kind, summary: p }))))

// competitors.md writer: assembles the dimension contract file from the profile FILES
const verdict = await agent(
  `${CTX}\n\nCompetitive-landscape playbook:\n${playbookCompetitors}\n\nRead every profile in ${outDir}/research/profiles/ plus this roster (incl. unprofiled + status-quo entries): ${roster.map(c => `${c.name} (${c.kind})`).join(', ')}. Write ${outDir}/research/competitors.md per the playbook's skeleton: alternatives-first ordering (status-quo entries OPEN the file), the jobs x competitors capability matrix keyed to the dossier's jobs, per-competitor CTA/motion, the signal-disciplined next-move calls, and the unprofiled names listed as discovered-not-profiled. If the file already exists, UPDATE it — keep prior source rows with their original Pulled dates. End the file with an explicit Category verdict section. Then return the verdict JSON: does the competitive set confirm the dossier's category boundary? revisedBoundary = the boundary as it should now read (unchanged if confirms).`,
  { label: 'competitors:verdict', phase: 'Profile', model: 'opus', effort: 'high', schema: VERDICT_SCHEMA })

return {
  roster: roster.map(c => ({ name: c.name, kind: c.kind })),
  profiled: profiles.filter(Boolean),
  skipped,
  categoryVerdict: verdict,
}
```

**Conductor checkpoint (between A and B):** read `categoryVerdict`. If `confirms: false`,
update `product-dossier.md`'s Category boundary to `revisedBoundary`, note the change to the
user (interactive) or in Assumptions (dispatched), and pass the revised boundary into
Workflow B. Never let B run against a boundary A just falsified.

## Workflow B — Research + Verify + Critique

Args: everything from A plus `boundary` (post-verdict), `dimensions`, `playbooks`, `prior`,
`verifyCap`, and `profiledSummary` (compact roster + wedge lines from A's return).

```js
// dimensions: e.g. ["sizing","customers","pricing","trends","channels","moats-risks"]
// NEVER include "competitors" — Workflow A owns it. Must include "sizing".
// playbooks: { <dimension>: "<verbatim block from dimensions.md>" } — one entry per dimension.
// prior: { <dimension>: "<existing research/<d>.md content>" | null } — re-run merge context.
export const meta = {
  name: 'market-analysis-research',
  description: 'Dimension research fan-out, refutation panels, completeness critic',
  phases: [
    { title: 'Research', detail: 'dimension fan-out, sizing split bottom-up/top-down' },
    { title: 'Verify', detail: 'refutation panels on top load-bearing claims' },
    { title: 'Critique', detail: 'completeness critic, bounded remediation' },
  ],
}

const { date, outDir, dossier, boundary, citation, dimensions, playbooks, prior = {},
        profiledSummary, verifyCap = 12 } = args
if (dimensions.includes('competitors')) throw new Error('competitors is Workflow A\'s job')
for (const d of dimensions) if (!playbooks[d]) throw new Error(`no playbook for dimension "${d}" — author one before dispatching`)
const CTX = `Product dossier:\n${dossier}\n\nCategory boundary (settled after competitor research): ${boundary}\n\nCompetitive set: ${profiledSummary}\n\n${citation}\nDate: ${date}. Use WebSearch and WebFetch for every factual claim.`
const updateRule = (d) => prior[d]
  ? `\n\nThis file EXISTS from a prior run — UPDATE it: keep every prior source row with its original Pulled date, mark superseded figures as superseded (new figure + new date alongside), add new findings. Never delete a prior sourced row. Prior content:\n${prior[d]}`
  : ''

const CLAIMS_SCHEMA = { type: 'object', properties: { summary: {type:'string'},
  loadBearing: { type: 'array', items: { type: 'object', properties: {
    claim: {type:'string'}, sources: {type:'array', items:{type:'string'}}, tag: {enum:['H','M','L']} },
    required: ['claim','sources','tag'] } },
  vhVerdicts: { type: 'array', items: { type: 'object', properties: {
    vh: {type:'string'}, verdict: {enum:['confirmed','weakened','refuted','untested']}, evidence: {type:'string'} },
    required: ['vh','verdict','evidence'] } } }, required: ['summary','loadBearing','vhVerdicts'] }
const REFUTE_SCHEMA = { type: 'object', properties: { refuted: {type:'boolean'}, reason: {type:'string'} }, required: ['refuted','reason'] }
const CRITIC_SCHEMA = { type: 'object', properties: { clean: {type:'boolean'}, gaps: {type:'array', items:{type:'object',
  properties: { gap: {type:'string'}, dispatch: {type:'string'} }, required:['gap','dispatch'] }} }, required: ['clean','gaps'] }

// ---- Research: sizing split in two + opus reconciler; other dimensions per playbook ----
phase('Research')
const nonSizing = dimensions.filter(d => d !== 'sizing')
const dims = await parallel([
  () => agent(`${CTX}\n\nPlaybook:\n${playbooks.sizing}\n\nDo ONLY the BOTTOM-UP sizing: payer-filtered population proxy x ARPU x explicit penetration guess, formula visible, every factor sourced.`,
    { label: 'sizing:bottom-up', phase: 'Research', model: 'sonnet', effort: 'medium' }),
  () => agent(`${CTX}\n\nPlaybook:\n${playbooks.sizing}\n\nDo ONLY the TOP-DOWN sizing: enclosing-category figures, each with the boundary it assumes and why figures diverge.`,
    { label: 'sizing:top-down', phase: 'Research', model: 'sonnet', effort: 'medium' }),
  ...nonSizing.map(d => () =>
    agent(`${CTX}\n\nPlaybook:\n${playbooks[d]}\n\nWrite your findings to ${outDir}/research/${d}.md per the playbook's skeleton (Sources table stays IN this file — never touch sources.md).${updateRule(d)}\nThen return the JSON summary, including a verdict for every value hypothesis your dimension can speak to.`,
      { label: `dim:${d}`, phase: 'Research', model: 'sonnet', effort: 'medium', schema: CLAIMS_SCHEMA })),
])
const [bottomUp, topDown, ...dimResults] = dims
const sizing = await agent(
  `${CTX}\n\nReconcile these two sizing passes into ${outDir}/research/sizing.md (playbook skeleton; Sources table in-file): bottom-up is the ANCHOR, top-down corroborates; ranges + tags; a >30% divergence is a boundary mismatch to explain, never an average to take.${updateRule('sizing')}\nThen return the JSON summary.\n\nBOTTOM-UP:\n${bottomUp}\n\nTOP-DOWN:\n${topDown}`,
  { label: 'sizing:reconcile', phase: 'Research', model: 'opus', effort: 'high', schema: CLAIMS_SCHEMA })

// ---- Verify: refutation panels on the TOP load-bearing claims only ----
phase('Verify')
const V_LENSES = [
  'source integrity — does each cited source actually say this, is it primary, is the quote faithful?',
  'category-boundary match — does the figure\'s category match OUR boundary, or is it smuggling a bigger market?',
  'recency & durability — is this stale, superseded, or about to be?',
]
const tagged = [['sizing', sizing], ...nonSizing.map((d, i) => [d, dimResults[i]])]
const claims = tagged
  .flatMap(([dim, r]) => (Array.isArray(r?.loadBearing) ? r.loadBearing : []).map(c => ({ ...c, dim })))
  .filter(c => c.tag !== 'L')          // L is already a flagged assumption — nothing to refute
  .slice(0, verifyCap)
const verified = []
for (const c of claims) {              // per-claim panels run sequentially; lenses in parallel
  const votes = await parallel(V_LENSES.map((lens, i) => () =>
    agent(`Claim (from the ${c.dim} dimension): "${c.claim}"\nSources: ${c.sources.join(' ')}\n${CTX}\n\nTry to REFUTE via this lens only: ${lens}. Default refuted=true if uncertain.`,
      { label: `verify:${c.dim}:${i}`, phase: 'Verify', model: 'sonnet', effort: 'medium', schema: REFUTE_SCHEMA })))
  const kills = votes.map((v, i) => ({ lens: V_LENSES[i].split(' — ')[0], ...v })).filter(v => v?.refuted)
  verified.push({ claim: c.claim, dim: c.dim, tag: c.tag, kills })
}
// ANY lens refutation is a dispute (the lenses are orthogonal — a boundary smuggle trips exactly one)
const disputed = verified.filter(v => v.kills.length >= 1)
log(`${disputed.length}/${claims.length} verified claims disputed — correct or downgrade at synthesis (kills carry the lens)`)

// ---- Critique: completeness critic, bounded remediation ----
phase('Critique')
let critique = null
const unclosedGaps = []
for (let round = 0; round < 3; round++) {
  critique = await agent(
    `${CTX}\n\nAudit the research on disk at ${outDir}/research/ (incl. profiles/ and competitors.md) plus this state: dimensions run: ${dimensions.join(', ')}; ${disputed.length} of ${claims.length} verified claims disputed. What is MISSING for an analysis a founder bets money on — dimension not run, segment unexplored, competitor unprofiled that matters, number single-sourced, VH with no verdict, playbook section skipped? For each gap give the exact dispatch prompt that would close it. clean=true only if nothing material is missing.`,
    { label: `critic:${round}`, phase: 'Critique', model: 'opus', effort: 'high', schema: CRITIC_SCHEMA })
  const gaps = Array.isArray(critique?.gaps) ? critique.gaps : []
  if (!critique || critique.clean || !gaps.length) break
  if (round === 2) { log('critic still unclean after max rounds — gaps returned for the report'); unclosedGaps.push(...gaps); break }
  if (gaps.length > 8) { log(`closing 8 of ${gaps.length} gaps this round; rest re-audited next round`) }
  log(`critic round ${round + 1}: ${Math.min(gaps.length, 8)} gaps — closing`)
  await parallel(gaps.slice(0, 8).map((g, i) => () =>
    agent(`${CTX}\n\n${g.dispatch}\n\nUPDATE the relevant file under ${outDir}/research/ — append new rows to its Sources table, never delete prior rows.`,
      { label: `close-gap:${i}`, phase: 'Critique', model: 'sonnet', effort: 'medium' })))
}

return {
  dimensionSummaries: Object.fromEntries(tagged.map(([d, r]) => [d, r?.summary ?? null])),
  vhVerdicts: tagged.flatMap(([d, r]) => (Array.isArray(r?.vhVerdicts) ? r.vhVerdicts : []).map(v => ({ ...v, dim: d }))),
  disputedClaims: disputed,
  criticVerdict: critique,
  unclosedGaps,
}
```

## After Workflow B returns

The conductor (you): reads the research files' Sources tables and writes `sources.md` — it is
YOURS alone, `[S#]` numbers are assigned at this merge, no agent ever writes it; folds
`disputedClaims` into corrections/downgrades (the lens tells you which file to fix); resolves
`vhVerdicts` into the report's Value hypothesis verdicts table; and if `criticVerdict.clean`
is false, either runs another Workflow B round or records every `unclosedGaps` entry verbatim
in `Coverage` and `Risks to this analysis` — never ships silently. Then synthesis (SKILL.md
Phase 4), in your own turn, never delegated.

## Scaling judgment

- Niche/simple product: trim discovery lenses to 3 (keep the status-quo lens), `profileCap: 6`,
  skip add-on dimensions — ~15 agents.
- Standard product: as-is — ~25–40 agents.
- Complex/regulated/multi-sided: add add-on dimensions (each needs a real playbook block —
  the script throws on a missing one), raise `profileCap` and `verifyCap` — 50+ agents is
  fine. The tiering table in SKILL.md is the cost discipline; never economize by inheriting
  models or dropping the verify/critic stages.
