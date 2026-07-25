# Canonical research workflow

The market-analysis research engine as a `Workflow` script. Adapt — don't invent the shape from
scratch: fill in the `args` block, prune/add dimensions per the dossier, keep the structure
(multi-modal discovery → loop-until-dry → per-competitor profiling → split dimension research →
verify panels → completeness critic). Synthesis stays OUT of the workflow — that's the
conductor's job, on the strongest model, after reading everything.

Invoke with real values via `args` (the script can't call `Date.now()` — pass the date in):

```js
Workflow({
  script: <the script below, adapted>,
  args: {
    date: "2026-07-25",
    outDir: "/Users/<user>/Documents/business/<slug>",
    dossier: "<the full product-dossier.md content, inline>",
    boundary: "<the category boundary paragraph>",
    citation: "<the citation contract from SKILL.md, verbatim>",
    dimensions: ["sizing", "customers", "pricing", "trends", "channels", "moats-risks"],
    playbooks: { sizing: "<dimension block from dimensions.md>", ... }
  }
})
```

If the harness has no Workflow tool: keep the same stages and fleets with parallel `Agent`
dispatches per stage (all independent dispatches in one message), and run the dry-loop and
critic loop by hand across turns. The structure is the requirement; the tool is the convenience.

```js
export const meta = {
  name: 'market-analysis-research',
  description: 'Heavy market research: discover + profile competitors, research dimensions, verify claims',
  phases: [
    { title: 'Discover', detail: 'multi-modal competitor sweep, loop until dry' },
    { title: 'Profile', detail: 'one agent per competitor' },
    { title: 'Research', detail: 'dimension fan-out, sizing split bottom-up/top-down' },
    { title: 'Verify', detail: 'refutation panels on load-bearing claims' },
    { title: 'Critique', detail: 'completeness critic, loop until clean' },
  ],
}

const { date, outDir, dossier, boundary, citation, dimensions, playbooks } = args
const CTX = `Product dossier:\n${dossier}\n\nCategory boundary: ${boundary}\n\n${citation}\nDate: ${date}. You have WebSearch and WebFetch — use them heavily.`

const COMP_SCHEMA = { type: 'object', properties: { competitors: { type: 'array', items: {
  type: 'object', properties: { name: {type:'string'}, kind: {enum:['direct','indirect','adjacent']}, why: {type:'string'}, url: {type:'string'} },
  required: ['name','kind','why'] } } }, required: ['competitors'] }
const CLAIMS_SCHEMA = { type: 'object', properties: { summary: {type:'string'}, loadBearing: { type: 'array', items: {
  type: 'object', properties: { claim: {type:'string'}, sources: {type:'array', items:{type:'string'}}, tag: {enum:['H','M','L']} },
  required: ['claim','sources','tag'] } } }, required: ['summary','loadBearing'] }
const VERDICT_SCHEMA = { type: 'object', properties: { refuted: {type:'boolean'}, reason: {type:'string'} }, required: ['refuted','reason'] }
const CRITIC_SCHEMA = { type: 'object', properties: { clean: {type:'boolean'}, gaps: {type:'array', items:{type:'object',
  properties: { gap: {type:'string'}, dispatch: {type:'string'} }, required:['gap','dispatch'] }} }, required: ['clean','gaps'] }

// ---- Phase 1: multi-modal competitor discovery, loop until dry ----
phase('Discover')
const LENSES = [
  'category keyword searches (the category name + synonyms + "tools"/"software")',
  '"alternative to <each known player>" searches and alternatives-listing sites',
  'community threads: relevant subreddits, Hacker News, niche forums — what do users actually name?',
  'marketplaces and app stores relevant to the product surface',
  'funding databases and startup press: who raised money in this category recently',
]
const seen = new Map()
let dry = 0
while (dry < 2 && seen.size < 60) {
  const round = await parallel(LENSES.map((lens, i) => () =>
    agent(`${CTX}\n\nFind competitors via ONE lens only: ${lens}.\nAlready known (do not re-report): ${[...seen.keys()].join(', ') || 'none'}.\nReturn every product plausibly competing inside the category boundary.`,
      { label: `find:${i}`, phase: 'Discover', model: 'sonnet', effort: 'low', schema: COMP_SCHEMA })))
  const fresh = round.filter(Boolean).flatMap(r => r.competitors).filter(c => !seen.has(c.name.toLowerCase()))
  if (!fresh.length) { dry++; continue }
  dry = 0
  fresh.forEach(c => seen.set(c.name.toLowerCase(), c))
  log(`${seen.size} competitors found so far`)
}

// ---- Phase 2: profile each competitor that matters (direct + strong indirect/adjacent) ----
phase('Profile')
const roster = [...seen.values()]
const toProfile = roster.filter(c => c.kind === 'direct').concat(
  roster.filter(c => c.kind !== 'direct').slice(0, 10))
log(`profiling ${toProfile.length} of ${roster.length} discovered (all direct + top others); full roster listed in competitors.md`)
const profiles = await parallel(toProfile.map(c => () =>
  agent(`${CTX}\n\nProfile competitor "${c.name}" (${c.kind}; ${c.url || 'find their site'}): what it does (one paragraph), pricing model + actual price points, disclosed traction (only citable numbers), funding, their positioning claim in their own words, most likely next move (changelogs/job posts/roadmaps/interviews), and the WEDGE LINE — what they structurally don't cover and why. Full source table. Return as a markdown profile block.`,
    { label: `profile:${c.name}`, phase: 'Profile', model: 'sonnet', effort: 'medium' })
    .then(p => ({ name: c.name, kind: c.kind, profile: p }))))

// ---- Phase 3: dimension research (sizing split in two + reconciler; others per playbook) ----
phase('Research')
const compact = toProfile.map(c => `${c.name} (${c.kind})`).join(', ')
const dims = await parallel([
  () => agent(`${CTX}\n\nPlaybook:\n${playbooks.sizing}\n\nDo ONLY the BOTTOM-UP sizing: population proxy x ARPU x explicit penetration guess, formula visible, every factor sourced.`,
    { label: 'sizing:bottom-up', phase: 'Research', model: 'sonnet', effort: 'medium' }),
  () => agent(`${CTX}\n\nPlaybook:\n${playbooks.sizing}\n\nDo ONLY the TOP-DOWN sizing: enclosing-category analyst figures, each with the boundary it assumes and why figures diverge.`,
    { label: 'sizing:top-down', phase: 'Research', model: 'sonnet', effort: 'medium' }),
  ...dimensions.filter(d => d !== 'sizing').map(d => () =>
    agent(`${CTX}\n\nKnown competitive set: ${compact}\n\nPlaybook:\n${playbooks[d]}\n\nWrite your findings to ${outDir}/research/${d}.md per the playbook's skeleton, then return the JSON summary.`,
      { label: `dim:${d}`, phase: 'Research', model: 'sonnet', effort: 'medium', schema: CLAIMS_SCHEMA })),
])
const [bottomUp, topDown, ...dimResults] = dims
const sizing = await agent(
  `${CTX}\n\nReconcile these two sizing passes into ${outDir}/research/sizing.md (playbook skeleton): bottom-up is the ANCHOR, top-down corroborates; ranges + tags, divergence explained. Then return the JSON summary.\n\nBOTTOM-UP:\n${bottomUp}\n\nTOP-DOWN:\n${topDown}`,
  { label: 'sizing:reconcile', phase: 'Research', model: 'opus', effort: 'high', schema: CLAIMS_SCHEMA })

// ---- Phase 4: verify panels on load-bearing claims ----
phase('Verify')
const claims = [sizing, ...dimResults].filter(Boolean).flatMap(r => r.loadBearing.map(c => ({ ...c })))
const verified = await parallel(claims.map(c => () =>
  parallel(['source integrity — does each cited source actually say this, is it primary, is the quote faithful?',
            'category-boundary match — does the figure\'s category match OUR boundary, or is it smuggling a bigger market?',
            'recency & durability — is this stale, superseded, or about to be?']
    .map((lens, i) => () =>
      agent(`Claim: "${c.claim}"\nSources: ${c.sources.join(' ')}\n${CTX}\n\nTry to REFUTE via this lens only: ${lens}. Default refuted=true if uncertain.`,
        { label: `verify:${i}`, phase: 'Verify', model: 'sonnet', effort: 'medium', schema: VERDICT_SCHEMA })))
    .then(vs => ({ ...c, kills: vs.filter(Boolean).filter(v => v.refuted) }))))
const disputed = verified.filter(v => v.kills.length >= 2)
log(`${disputed.length}/${claims.length} load-bearing claims refuted by panel — downgrade or correct in synthesis`)

// ---- Phase 5: completeness critic, loop until clean (max 2 remediation rounds) ----
phase('Critique')
let critique = null
for (let round = 0; round < 3; round++) {
  critique = await agent(
    `${CTX}\n\nAudit the research now on disk at ${outDir}/research/ plus this state: ${toProfile.length} competitors profiled of ${roster.length} discovered; dimensions run: sizing, ${dimensions.filter(d=>d!=='sizing').join(', ')}; ${disputed.length} claims disputed. What is MISSING for an analysis a founder bets money on — dimension not run, segment unexplored, competitor unprofiled that matters, number single-sourced, playbook section skipped? For each gap give the exact dispatch prompt that would close it. clean=true only if nothing material is missing.`,
    { label: `critic:${round}`, phase: 'Critique', model: 'opus', effort: 'high', schema: CRITIC_SCHEMA })
  if (!critique || critique.clean || !critique.gaps.length) break
  log(`critic round ${round + 1}: ${critique.gaps.length} gaps — closing`)
  await parallel(critique.gaps.slice(0, 8).map((g, i) => () =>
    agent(`${CTX}\n\n${g.dispatch}\n\nAppend findings (with sources) to the relevant file under ${outDir}/research/.`,
      { label: `close-gap:${i}`, phase: 'Critique', model: 'sonnet', effort: 'medium' })))
}

return {
  discovered: roster,
  profiles,
  dimensionSummaries: { sizing: sizing?.summary, ...Object.fromEntries(dimensions.filter(d=>d!=='sizing').map((d, i) => [d, dimResults[i]?.summary])) },
  disputedClaims: disputed.map(d => ({ claim: d.claim, why: d.kills.map(k => k.reason) })),
  criticVerdict: critique,
}
```

## After the workflow returns

The conductor (you) now: merges the profiles into `competitor-analysis.md`, folds disputed
claims into downgrades, merges source tables into `sources.md`, and writes the synthesis
(SKILL.md Phase 4) — on the strongest model in the session, never delegated to the fleet.

## Scaling judgment

- Niche/simple product: trim lenses to 3, profile cap ~6, skip add-on dimensions — ~15 agents.
- Standard product: the script as-is — ~25–40 agents.
- Complex/regulated/multi-sided: add the add-on dimensions from `dimensions.md`, raise the
  profile cap, verify more claims — 50+ agents is fine. The tiering table in SKILL.md is the
  cost discipline; never economize by inheriting models or dropping the verify/critic stages.
