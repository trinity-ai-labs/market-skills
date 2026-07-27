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
 * Markdown links whose target is a relative path. Skips URLs, anchors, and mail
 * links — and skips fenced code blocks, since an example link inside a code
 * fence documents a pattern rather than pointing at a file that must exist.
 */
function relativeLinks(text) {
  const withoutFences = text.replace(/```[\s\S]*?```/g, '');
  const out = [];
  for (const m of withoutFences.matchAll(/\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) {
    const target = m[1];
    if (/^([a-z][a-z0-9+.-]*:|#|\/\/)/i.test(target)) continue;
    out.push(target.split('#')[0]);
  }
  return out.filter(Boolean);
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
