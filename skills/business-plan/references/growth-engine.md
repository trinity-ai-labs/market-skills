# The growth engine — automation leverage as a plan section

Every plan ships a `## Growth engine` section: the concrete, mostly-automated machine that
executes the GTM, sized to the founder's hours. The framing that makes it real: **the growth
engine is a set of agent skills the founder builds once, not a list of marketing chores** —
each skill grounded in a reference file written once (voice, product truth, asset contracts)
and gated by a mechanical quality bar, so output stays consistent and auditable forever.

## The three per-product skills to spec (the house pattern)

Prescribe these in the plan, with the founder's stack filled in:

1. **Content skill** (blog/SEO/changelog copy): grounded in a `voice.md` the founder writes
   ONCE — Do/Don't pairs, banned-vocabulary list, literal voice samples from real shipped
   copy — plus a lintable frontmatter/CMS contract (required fields, char targets, enums).
   Numeric SEO bars (title 50–60 chars, description 150–160, keyword placement, ≥2 internal
   links) checked post-write, not vibes.
2. **Visual-asset skill** (screenshots/demo media): scripted browser capture against the
   running product — named viewport/DPI presets, fixed output paths, one command per case,
   regenerate-on-demand so marketing/store assets never go stale. Pipeline: capture → device
   frame → one-line caption → export; the raw capture is never the shipped hero asset.
3. **Docs-sync skill** (docs/changelog/landing honesty): a branch-relative audit window, a
   cheap mechanical pre-check (grep/ban-list) before any expensive judgment, present-tense
   discipline, and a defined trigger list for touching the landing page.

Shared discipline for all three: typed inputs → reference docs read first → deterministic
phases → mechanical quality gate → structured report; output lands as reviewable PRs, never
direct edits.

## Content engine rules (what survives Google, 2025–2026)

- Google penalizes **scaled low-value output**, not AI authorship: ~50–100 EDITED AI articles
  gained traffic where 1,000+ unedited ones lost 40–90%. Gate every publish on "does this add
  non-obvious value a competent human would bother writing?" — never on "did AI write it".
- **Kill-metric for programmatic pages**: indexed-pages growing >3× faster than organic
  traffic for two consecutive quarters → hard-stop generation; noindex zero-traffic pages
  after 180 days. Per-page test: if swapping the variable noun leaves the page coherent,
  it's a doorway page — every templated page needs one unique data point (a number, a live
  stat, a real comparison), and shared boilerplate stays under ~40%.
- **Depth beats volume**: default cadence 2 deep articles/week + platform-native derivatives;
  one thorough 3,000-word piece outranks ten shallow ones (and gets cited by AI answer
  engines). Human sample-review 5–10% of early batches, tapering — a config knob, not advice.
- **E-E-A-T's Experience signal is the un-fakeable edge**: every piece carries ≥1 first-hand
  artifact from the product itself — a real screenshot, a real metric, a real edge case. The
  visual-asset skill feeds this automatically.
- **Changelog entries are SEO pages**: one concrete keyword-bearing sentence per shipped
  feature ("cut query latency 300ms", not "improved performance"); the strongest entries fan
  out to blog/social/email.
- **No-full-automation zones**: brand-voice-critical surfaces (ads, hero copy, campaign
  creative) always get a human edit pass — slop backlash is a measured brand liability, and
  disclosure doesn't neutralize it; craft does. Optionally flip it into positioning: a
  visible human-verified line on high-stakes content is now a differentiator.

## Visual & video engine rules

- **Demo videos anchor to the activation moment**: one persona's single workflow in 9–12
  steps (~40% completion, the best bucket), AI voiceover (+14% completion), captions; ONE
  recording distributed everywhere rather than per-channel re-cuts. Answer "what one action
  predicts retention?" before recording — that's the only demo.
- **Creative testing economics inverted**: AI variants cost ~1–2% of traditional production —
  generate many hook/scenario variants cheap, measure early signal (CTR/IPM/completion),
  then re-produce ONLY the winner at high fidelity. AI-UGC owns top-of-funnel volume testing;
  a real human re-shoot of the winning script owns the product page and trust-sensitive
  placements (human UGC still wins conversion +161% and trust).
- **Brief the proven UGC shapes** — expert commentary, scenario-skit (sell the problem
  first), pattern-interrupt, street-interview — never "a testimonial ad" (ring-light
  testimonials are the named dead format).
- **Format per destination** (aspect, pacing, hook) — one render fanned everywhere is the top
  named failure. Before any AI hero asset ships: the slop gut-check — uncanny, generic, or
  interchangeable-with-any-brand fails.

## Distribution engine rules

- **Repurposing is the highest-leverage automation**: every long-form artifact (pillar post,
  demo recording, changelog batch) fans out to ≥4 platform-native formats before it counts as
  shipped. Human judgment sits at exactly two gates: pillar selection, and a voice edit before
  publish — the pipeline never auto-publishes past gate 2.
- **Every automation carries the trio**: a fixed cadence, a feedback loop (next run reads
  last run's results), and a human approval gate before anything goes public.
- **Launch is a system, not a day**: a standing directory-submission queue (Product Hunt,
  AlternativeTo, SaaSHub, the AI directories) running for months as a recurring job.
- **Email fires on product events** (signup, activation, stall), never a calendar drip —
  behavior-triggered sequences convert ~30% better; every send cites the user action that
  triggered it.
- **Communities are adversarial to bot-shaped output**: Reddit/community automations are
  read-only — monitor for buyer-intent language, draft for human review, never auto-post or
  auto-DM. Outbound personalization rule: the first line carries one real fact about the
  specific target; any template sendable to two people unchanged is rejected.
- **The founder's voice is the trust boundary**: AI drafts, repurposes, schedules under a real
  voice profile with review; AI never speaks AS the founder unreviewed, and never fabricates
  build-in-public progress.

## The weekly loop (goes in the plan, sized to grilled hours)

```
{metrics digest} → {feedback triage} → {competitor scan (the analysis's Monitoring plan)}
→ {content batch: 2 deep pieces + derivatives} → {directory/launch queue tick}
→ ONE bounded human review/approval pass → publish
```

Each stage is a scheduled skill; the founder touches only the approval gate. Realistic total:
marketing drops from ~20–30% of founder time to ~5–10%. The plan's milestone section states
which pieces of the engine get built in which month — the engine is itself a roadmap item,
not an assumption.
