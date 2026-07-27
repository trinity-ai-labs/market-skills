# Changelog

Versions are the `version` field in `.claude-plugin/plugin.json`. Because that field is set, an installed plugin only picks up changes when it **changes** — pushing to `main` alone ships nothing. CI enforces the bump.

## 1.0.1

- **Install now points at `trinity-ai-labs/claude-plugins`.** The marketplace catalogue used to live inside `orchestration-skills`, so installing these skills meant adding an unrelated plugin's repo as a marketplace first. The catalogue moved to a repo that ships no plugin of its own. The marketplace *name* is unchanged, so `market@trinity-ai-labs` still resolves — only the `marketplace add` line moves.

## 1.0.0

First release. The `market-analysis` and `business-plan` skills, previously installed by a symlinking shell script, packaged as one plugin.

- `install.sh` is gone. The marketplace installs and updates both skills, so the symlink-into-two-skill-homes script has nothing left to do.
- `vault-lint.sh` moved from `scripts/` to `bin/`, and the skills now invoke it bare as `vault-lint.sh`. Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`; the old relative `scripts/vault-lint.sh` resolved against the user's own project directory, where nothing of the sort exists.
