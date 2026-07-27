# Changelog

Versions are the `version` field in `.claude-plugin/plugin.json`. Because that field is set, an installed plugin only picks up changes when it **changes** — pushing to `main` alone ships nothing. CI enforces the bump.

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
