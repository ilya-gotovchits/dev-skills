#!/usr/bin/env bash
# Symlink every skill folder in this repo into ~/.claude/skills/
# (read by both Claude Code and opencode). Idempotent. Use --dry-run to preview.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

mkdir -p "$TARGET_DIR"

for skill_dir in "$REPO_DIR"/*/; do
  name="$(basename "$skill_dir")"
  # only folders that actually hold a SKILL.md are skills
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  link="$TARGET_DIR/$name"

  # already the correct symlink? skip.
  if [[ -L "$link" && "$(readlink "$link")" == "${skill_dir%/}" ]]; then
    echo "ok      $name (already linked)"
    continue
  fi

  # a real (non-symlink) dir with the same name → refuse, let the human resolve it
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "SKIP    $name — $link exists and is not a symlink (move/remove it first)" >&2
    continue
  fi

  if $DRY_RUN; then
    echo "link    $name  ->  ${skill_dir%/}"
  else
    ln -sfn "${skill_dir%/}" "$link"
    echo "linked  $name"
  fi
done
