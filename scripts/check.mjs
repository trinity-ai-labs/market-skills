#!/usr/bin/env node
// Structure + link integrity gate for the skills in this repo.
//
//   node scripts/check.mjs          # check, print failures, exit 1 on any
//   node scripts/check.mjs --json   # machine-readable, for an agent consumer
//
// Zero dependencies by design: this repo is public and people clone it to GET
// the skills, so checking it must never require a package manager. Everything
// here imports from node: only.
//
// What it enforces, and the failure each rule prevents:
//   1. Every skills/<name>/ has a SKILL.md                — a skill that silently isn't one
//   2. SKILL.md frontmatter parses and carries name+description — the fields the
//      loader dispatches on; a missing description means the skill never triggers
//   3. Frontmatter `name` matches the directory name       — the plugin loader
//      maps by directory, so a mismatch registers the skill under the wrong trigger
//   4. Every relative markdown link resolves to a real file — the reference a
//      skill tells the model to load must exist, or the instruction dead-ends
//   5. Cross-skill references stay inside skills/          — a reference escaping
//      the repo breaks for anyone who installed only one skill
//   6. Every dispatched agent brief interpolates its playbook — a brief that
//      RESTATES its playbook is a second source of truth nothing keeps in sync,
//      so a rule added to the playbook silently never reaches the agent
//   7. Every dimension playbook is registered where it gets dispatched from — a
//      playbook nobody dispatches is a dimension the fleet never runs; a roster
//      entry with no playbook is a dimension dispatched with no brief
//   8. Every backtick-quoted `## Heading` resolves to a real heading — one skill
//      cites another's output sections by literal string, and when the two drift
//      the citing prose still reads correct while the section is never produced
//   9. Every `#anchor` in a markdown link resolves to a heading in the file it
//      points at — these references are navigated by their Contents blocks, and
//      a link whose heading was renamed or deleted lands the reader nowhere.
//      A file carrying a `## Contents` heading must offer at least one list-item
//      anchor link, so an index rewritten out of link form cannot go unchecked
//      while the rest of the file keeps this green
//
// Checks 6-9 each fail when their own source pattern matches NOTHING, because a
// check that quietly stops matching prints the same green as a check that passed.

import { readdir, readFile, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, dirname, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SKILLS_DIR = join(ROOT, 'skills');
const JSON_OUT = process.argv.includes('--json');

const failures = [];
const fail = (file, rule, detail) => failures.push({ file: relative(ROOT, file), rule, detail });

/** Walk a directory recursively, yielding absolute file paths. */
async function* walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const full = join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(full);
    else yield full;
  }
}

/**
 * Minimal YAML frontmatter reader — top-level `key: value` pairs only, which is
 * all a SKILL.md header is. Deliberately not a YAML parser: pulling one in would
 * mean a dependency, and the surface here is a handful of scalar keys.
 * Returns null when the file has no frontmatter block at all.
 */
function readFrontmatter(text) {
  if (!text.startsWith('---')) return null;
  const end = text.indexOf('\n---', 3);
  if (end === -1) return null;
  const body = text.slice(3, end);
  const out = {};
  for (const line of body.split('\n')) {
    const m = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (m) out[m[1]] = m[2].trim().replace(/^["']|["']$/g, '');
  }
  return out;
}

/**
 * Drop fenced code blocks. A link or a heading inside a fence is an EXAMPLE of a
 * pattern — a template showing the shape of an output file — not a live link
 * that must resolve or a heading a reader can jump to.
 */
const stripFences = (text) => text.replace(/```[\s\S]*?```/g, '');

/** Every markdown link target outside a code fence, URLs and mail links dropped. */
function* localLinks(text) {
  for (const m of stripFences(text).matchAll(/\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) {
    const target = m[1];
    if (/^([a-z][a-z0-9+.-]*:|\/\/)/i.test(target)) continue;
    yield target;
  }
}

/**
 * Markdown links whose target is a relative path. Skips URLs, anchors, and mail
 * links — and skips fenced code blocks, since an example link inside a code
 * fence documents a pattern rather than pointing at a file that must exist.
 */
function relativeLinks(text) {
  const out = [];
  for (const target of localLinks(text)) {
    if (target.startsWith('#')) continue;
    out.push(target.split('#')[0]);
  }
  return out.filter(Boolean);
}

/**
 * GitHub's heading-anchor slug, which is what every `#fragment` in these files
 * is written against: lowercase, drop everything that is not a word character,
 * whitespace or a hyphen, THEN map each whitespace character to its OWN hyphen.
 *
 * Two details are load-bearing, and each is a false positive on a known-good
 * file if you get it wrong. Collapsing whitespace runs breaks every heading
 * containing an em dash: dropping the dash leaves the two spaces that flanked
 * it, so `## Stage 5 — Stop` slugs to `stage-5--stop` — the doubled hyphen the
 * Contents blocks in this repo actually carry. And `_` is a word character
 * GitHub keeps, not an emphasis marker to strip: vault-migration.md's
 * `#retrofit-killed_because-…` entry points at a heading holding a
 * `killed_because` code span, and a slugger that eats the underscore reports
 * that working link as broken.
 *
 * This is the one place the rule lives, and every anchor check resolves through
 * it. A second copy of it anywhere — another language, another file — drifts
 * from this one silently, and both copies get trusted; a check that needs a slug
 * calls this rather than writing its own.
 *
 * No file here has two headings that slug alike, so the `-1`/`-2` suffixes
 * GitHub appends to a repeated heading have nothing to model.
 */
function slugify(heading) {
  return heading
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}_\s-]/gu, '')
    .replace(/\s/g, '-')
    .replace(/^-+|-+$/g, '');
}

/** The anchors a file offers: one slug per heading it actually renders. */
function headingSlugs(text) {
  const out = new Set();
  for (const line of stripFences(text).split('\n')) {
    const m = line.match(/^#{1,6}\s+(.*?)\s*$/);
    if (m) out.add(slugify(m[1]));
  }
  return out;
}

const ORCHESTRATION = join(SKILLS_DIR, 'market-analysis', 'references', 'orchestration.md');
const DIMENSIONS = join(SKILLS_DIR, 'market-analysis', 'references', 'dimensions.md');
const MA_SKILL = join(SKILLS_DIR, 'market-analysis', 'SKILL.md');

/**
 * The `agent(...)` calls that legitimately interpolate no playbook, keyed by the
 * static prefix of their `label:`. This table IS the exception mechanism: a new
 * dispatch either interpolates its playbook or someone writes down here why it
 * does not, so an exception is a decision on the record rather than a silence.
 * A key that matches no call is itself a failure — a stale entry is a check
 * quietly narrowed to fit the code it was supposed to constrain.
 */
const PLAYBOOK_EXEMPT = new Map([
  ['find:', 'discovery sweep — returns a roster against one search lens, authors no dimension content'],
  ['verify:', 'refutation panel — argues one already-written claim down, writes nothing'],
  ['critic:', 'completeness critic — reads the research tree and names gaps, writes nothing'],
  ['close-gap:', "per-gap remediation on the critic's own generated dispatch string — the critic returns {gap, dispatch} naming no dimension, and several gap classes have none to name (an unprofiled competitor is Workflow A's playbook, which B never holds), so a key guessed off the free text would hand some gaps the WRONG playbook — worse than none"],
]);

/**
 * Check 6 — every dispatched brief interpolates its playbook.
 *
 * Each `agent(` call is read as the prompt text up to its options object's
 * `label:`, which is where every call in the file puts it. A prompt mentioning
 * `${playbook…}` receives its playbook by construction; anything else has to be
 * on the exemption table above.
 */
async function checkBriefsInterpolatePlaybooks() {
  if (!existsSync(ORCHESTRATION)) {
    fail(ORCHESTRATION, 'wiring', 'no orchestration.md — check 6 ran on nothing');
    return;
  }
  const text = await readFile(ORCHESTRATION, 'utf8');
  const seen = new Set();
  let calls = 0;

  for (const m of text.matchAll(/\bagent\(/g)) {
    const labelAt = text.indexOf('label:', m.index);
    if (labelAt === -1) {
      fail(ORCHESTRATION, 'wiring', 'an agent(...) call with no label: — nothing to key an exception on');
      continue;
    }
    calls += 1;
    const prompt = text.slice(m.index, labelAt);
    const raw = text.slice(labelAt).match(/label:\s*[`'"]([^`'"]*)/);
    // `profile:${c.name}` and 'sizing:reconcile' alike reduce to their static prefix.
    const label = (raw?.[1] ?? '').split('${')[0] || '<unlabelled>';
    if (prompt.includes('${playbook')) continue;
    const why = PLAYBOOK_EXEMPT.get(label);
    if (why) {
      seen.add(label);
      continue;
    }
    fail(
      ORCHESTRATION,
      'wiring',
      `agent(...) "${label}" interpolates no playbook — interpolate one, or add "${label}" to PLAYBOOK_EXEMPT with the reason`,
    );
  }

  if (calls === 0) fail(ORCHESTRATION, 'wiring', 'no agent(...) calls found — check 6 ran on nothing');
  for (const label of PLAYBOOK_EXEMPT.keys()) {
    if (!seen.has(label)) {
      fail(ORCHESTRATION, 'wiring', `PLAYBOOK_EXEMPT has "${label}" but no such agent(...) call — drop the stale exception`);
    }
  }
}

/**
 * Check 7 — a dimension playbook is registered everywhere it gets dispatched from.
 *
 * Three files have to agree: dimensions.md owns the playbook block, SKILL.md's
 * standard-dimensions table is the roster a conductor reads, and orchestration.md's
 * `dimensions:` example array is the shape it passes to Workflow B. The array
 * legitimately omits whatever the file marks `NEVER include` (Workflow A owns
 * competitors), so that exclusion is read from the file rather than hardcoded.
 */
async function checkDimensionsAreRegistered() {
  for (const f of [DIMENSIONS, MA_SKILL, ORCHESTRATION]) {
    if (!existsSync(f)) {
      fail(f, 'wiring', 'missing — check 7 ran on nothing');
      return;
    }
  }
  const stems = (text, re) => new Set([...text.matchAll(re)].map((m) => m[1]));
  const dimsText = await readFile(DIMENSIONS, 'utf8');
  const skillText = await readFile(MA_SKILL, 'utf8');
  const orchText = await readFile(ORCHESTRATION, 'utf8');

  // `## Growth curves & reference class (`research/growth-curves.md`) — runs after…`
  const playbooks = stems(dimsText, /^#{2}\s+[^\n]*?\(`research\/([a-z0-9-]+)\.md`\)/gm);
  // `| Growth curves & reference class | `research/growth-curves.md` | Parallel… |`
  const roster = stems(skillText, /^\|[^|\n]+\|\s*`research\/([a-z0-9-]+)\.md`\s*\|/gm);
  // `// dimensions: e.g. ["growth-curves","sizing",…]`
  const arrayLine = orchText.match(/^\/\/\s*dimensions:[^\n]*$/m);
  const dispatched = new Set([...(arrayLine?.[0] ?? '').matchAll(/"([a-z0-9-]+)"/g)].map((m) => m[1]));
  const ownedElsewhere = new Set([...orchText.matchAll(/NEVER include "([a-z0-9-]+)"/g)].map((m) => m[1]));

  if (playbooks.size === 0) fail(DIMENSIONS, 'wiring', 'no dimension playbook headings matched — check 7 ran on nothing');
  if (roster.size === 0) fail(MA_SKILL, 'wiring', 'no standard-dimensions table rows matched — check 7 ran on nothing');
  if (dispatched.size === 0) fail(ORCHESTRATION, 'wiring', 'no `dimensions:` example array matched — check 7 ran on nothing');

  for (const d of playbooks) {
    if (!roster.has(d)) fail(DIMENSIONS, 'wiring', `playbook \`research/${d}.md\` is in no SKILL.md table row — a dimension the fleet never runs`);
    if (!dispatched.has(d) && !ownedElsewhere.has(d)) {
      fail(DIMENSIONS, 'wiring', `playbook \`research/${d}.md\` is in no \`dimensions:\` array — a dimension the fleet never runs`);
    }
  }
  for (const d of roster) {
    if (!playbooks.has(d)) fail(MA_SKILL, 'wiring', `table row \`research/${d}.md\` has no playbook block — a dimension dispatched with no brief`);
  }
  for (const d of dispatched) {
    if (!playbooks.has(d)) fail(ORCHESTRATION, 'wiring', `\`dimensions:\` lists "${d}" with no playbook block — a dimension dispatched with no brief`);
  }
}

/**
 * Check 8 — a cited `## Heading` resolves to a heading something actually writes.
 *
 * Two normalisations are load-bearing. These files hard-wrap prose, so a citation
 * routinely straddles a line break — matching per line reports a wired contract as
 * unwired, which is the false positive that gets a check switched off. And a
 * heading may carry a trailing annotation (`## Strategy comparison  (in
 * financial-model.md)`), so a citation matches a heading it is a prefix of when
 * the remainder starts with a space or a bracket.
 *
 * A citation opening its own paragraph or list item is that file DECLARING the
 * section — decisions.md's ten literal brief headings are their own only producer
 * — so only mid-sentence citations, the ones asserting something about a section
 * someone else writes, are held to resolve.
 */
async function checkCitedHeadingsExist() {
  const headings = new Set();
  const citations = [];
  for await (const file of walk(SKILLS_DIR)) {
    if (!file.endsWith('.md')) continue;
    const text = await readFile(file, 'utf8');
    for (const line of text.split('\n')) {
      const m = line.match(/^#{2,}\s+(.*?)\s*$/);
      if (m) headings.add(m[1]);
    }
    for (const para of text.split(/\n\s*\n/)) {
      const flat = para.replace(/\s+/g, ' ').trim();
      for (const m of flat.matchAll(/`#{2,}\s+([^`]+)`/g)) {
        const lead = flat.slice(0, m.index).replace(/^[-*>\s]*(\*\*)?\s*(\d+[.)]\s*)?(\*\*)?\s*/, '');
        if (lead !== '') citations.push({ file, cited: m[1].trim() });
      }
    }
  }
  if (citations.length === 0) fail(SKILLS_DIR, 'wiring', 'no `## Heading` citations found — check 8 ran on nothing');
  for (const { file, cited } of citations) {
    const found = [...headings].some((h) => h === cited || (h.startsWith(cited) && /^[\s(]/.test(h.slice(cited.length))));
    if (!found) fail(file, 'wiring', `cites \`## ${cited}\` but no template writes that heading — the section is never produced`);
  }
}

/**
 * Check 9 — every `#anchor` a link carries resolves to a heading in the file it
 * points at.
 *
 * Check 4 validates the PATH half of a link and deliberately strips the
 * fragment, so `other.md#gone` passes on the strength of `other.md` existing and
 * a pure in-file `(#gone)` has no path to resolve at all. That is how an edit
 * deleted a `## Heading` while the file's own Contents block went on linking to
 * it, green the whole way. These references are navigated by those Contents
 * blocks, so a dead anchor is a reader landing nowhere in the file that IS the
 * skill's method.
 *
 * A link whose path does not resolve is check 4's failure, not this one's — it
 * is skipped here rather than reported twice.
 */
async function checkAnchorsResolve() {
  const slugsFor = new Map();
  const slugsOf = async (file) => {
    if (!slugsFor.has(file)) slugsFor.set(file, headingSlugs(await readFile(file, 'utf8')));
    return slugsFor.get(file);
  };

  let anchors = 0;
  for await (const file of walk(SKILLS_DIR)) {
    if (!file.endsWith('.md')) continue;
    const text = await readFile(file, 'utf8');
    for (const target of localLinks(text)) {
      const hash = target.indexOf('#');
      if (hash === -1) continue;
      const path = target.slice(0, hash);
      const anchor = target.slice(hash + 1);
      if (!anchor) continue;

      const dest = path === '' ? file : resolve(dirname(file), path);
      if (!dest.endsWith('.md') || !existsSync(dest)) continue;

      anchors += 1;
      if (!(await slugsOf(dest)).has(anchor)) {
        const where = dest === file ? 'this file' : relative(ROOT, dest);
        fail(file, 'link', `dead anchor -> ${target} — no heading in ${where} slugs to "${anchor}"`);
      }
    }

    // The index itself, guarded separately from the links above: a `## Contents`
    // block that offers no list-item anchor link. Written as plain text, or as
    // raw <a href="#…"> HTML, it drops out of the check while the rest of the
    // file keeps this green — and an index nobody validates is one readers
    // follow into nothing. Neither looser form of the guard closes that: the
    // repo-wide count below only speaks when EVERY file has gone silent, and
    // asking for an anchor merely SOMEWHERE in the file lets body links stand in
    // for the index — decisions.md carries 8 outside its Contents block, enough
    // to mask a gutted one on their own. Indented entries count; they are most
    // of the real index.
    const body = stripFences(text);
    if (/^##\s+Contents\s*$/m.test(body) && !/^\s*- \[.+?\]\(#[^)]+\)\s*$/m.test(body)) {
      fail(file, 'link', 'has a `## Contents` heading but no list-item anchor link — its index is unchecked');
    }
  }
  if (anchors === 0) fail(SKILLS_DIR, 'link', 'no #anchor links found — check 9 ran on nothing');
}

async function main() {
  if (!existsSync(SKILLS_DIR)) {
    fail(SKILLS_DIR, 'structure', 'no skills/ directory');
    return report();
  }

  const skillDirs = (await readdir(SKILLS_DIR, { withFileTypes: true }))
    .filter((e) => e.isDirectory() && !e.name.startsWith('.'))
    .map((e) => e.name);

  if (skillDirs.length === 0) fail(SKILLS_DIR, 'structure', 'skills/ contains no skills');

  for (const name of skillDirs) {
    const skillMd = join(SKILLS_DIR, name, 'SKILL.md');
    if (!existsSync(skillMd)) {
      fail(skillMd, 'structure', `skills/${name}/ has no SKILL.md`);
      continue;
    }
    const fm = readFrontmatter(await readFile(skillMd, 'utf8'));
    if (!fm) {
      fail(skillMd, 'frontmatter', 'no YAML frontmatter block');
      continue;
    }
    if (!fm.name) fail(skillMd, 'frontmatter', 'missing `name`');
    if (!fm.description) fail(skillMd, 'frontmatter', 'missing `description` — the field the model triggers on');
    if (fm.name && fm.name !== name) {
      fail(skillMd, 'frontmatter', `name "${fm.name}" != directory "${name}" — the plugin loader maps by directory`);
    }
  }

  for await (const file of walk(SKILLS_DIR)) {
    if (!file.endsWith('.md')) continue;
    const text = await readFile(file, 'utf8');
    for (const target of relativeLinks(text)) {
      const abs = resolve(dirname(file), target);
      if (!existsSync(abs)) {
        fail(file, 'link', `broken relative link -> ${target}`);
        continue;
      }
      if (!abs.startsWith(SKILLS_DIR + sep)) {
        fail(file, 'link', `link escapes skills/ -> ${target}`);
      }
      // A directory target is only meaningful if it holds a readable entry point.
      const s = await stat(abs);
      if (s.isDirectory() && !existsSync(join(abs, 'SKILL.md')) && !existsSync(join(abs, 'README.md'))) {
        fail(file, 'link', `directory link with no SKILL.md/README.md -> ${target}`);
      }
    }
  }

  await checkBriefsInterpolatePlaybooks();
  await checkDimensionsAreRegistered();
  await checkCitedHeadingsExist();
  await checkAnchorsResolve();

  report();
}

function report() {
  if (JSON_OUT) {
    console.log(JSON.stringify({ ok: failures.length === 0, failures }, null, 2));
  } else if (failures.length === 0) {
    console.log('check: ok — skills well-formed, every reference resolves');
  } else {
    console.error(`check: ${failures.length} failure${failures.length === 1 ? '' : 's'}\n`);
    for (const f of failures) console.error(`  ${f.file}\n    [${f.rule}] ${f.detail}`);
  }
  process.exit(failures.length === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('check: crashed —', err?.stack || err);
  process.exit(2);
});
