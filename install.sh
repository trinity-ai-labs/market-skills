#!/usr/bin/env bash
# Install the market-analysis + business-plan skills on this machine.
#
#   ./install.sh            # symlink (default) — repo IS the live skills, edits propagate instantly
#   ./install.sh --copy     # copy instead — edit the repo, re-run to sync
#
# Both skills install into EVERY agent skills home that applies:
#   skills/market-analysis/  ->  ~/.claude/skills/market-analysis/   (Claude Code)
#   skills/business-plan/    ->  ~/.claude/skills/business-plan/
#   skills/*                 ->  ~/.agents/skills/*                  (generic ~/.agents convention)
#
# The two skills work together: business-plan dispatches market-analysis as its research
# engine, and business-plan's rendering references market-analysis/references/rendering.md —
# so they install as a pair, always.
#
# Symlinks (the default) mean a `git pull` here updates your live skills with no re-run. The
# script is idempotent: it wipes whatever is at each destination and re-links, so a stale or
# half-broken install is cleaned out every time.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Where skills get installed. Add more homes here and they all stay in sync.
SKILL_HOMES=(
  "${CLAUDE_SKILLS_HOME:-$HOME/.claude/skills}"
  "${AGENTS_SKILLS_HOME:-$HOME/.agents/skills}"
)

MODE="symlink"
[ "${1:-}" = "--copy" ] && MODE="copy"

link() { # link <src> <dest>
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  # Clear whatever's already at dest first. A real file/dir left by a prior `--copy` install
  # (or a hand setup) would otherwise make `ln -sfn` nest the new symlink *inside* the existing
  # directory instead of replacing it — a silent broken install.
  if [ -e "$dest" ] || [ -L "$dest" ]; then rm -rf "$dest"; fi
  if [ "$MODE" = "copy" ]; then
    cp -R "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
  echo "  $dest -> $src"
}

echo "Installing market-skills ($MODE) from $REPO"

for home in "${SKILL_HOMES[@]}"; do
  for skill in "$REPO"/skills/*/; do
    name="$(basename "$skill")"
    link "${skill%/}" "$home/$name"
  done
done

echo
echo "Done. Sanity check:"
for home in "${SKILL_HOMES[@]}"; do
  echo "  ls -la $home/market-analysis $home/business-plan"
done
echo
echo "Next: open Claude Code (or any ~/.agents-aware agent) and the 'market-analysis' and 'business-plan' skills are available."
