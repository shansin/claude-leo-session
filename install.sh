#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SETTINGS="$HOME/.claude/settings.json"

# ── 1. Prerequisite checks ──────────────────────────────────────────────────
for tool in tmux jq python3; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool is required but not found"; exit 1; }
done

# ── 2. Bootstrap .env ───────────────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
  echo "Created .env from .env.example — edit it to customize FIFO paths."
else
  echo ".env already exists, skipping."
fi

# ── 3. Ensure settings.json exists ──────────────────────────────────────────
if [ ! -f "$SETTINGS" ]; then
  mkdir -p "$(dirname "$SETTINGS")"
  echo '{}' > "$SETTINGS"
fi

# ── 4. Build hook command strings ────────────────────────────────────────────
HOOK_CMD_START="bash $SCRIPT_DIR/hook_session_start.sh"
HOOK_CMD_STOP="bash $SCRIPT_DIR/hook_stop.sh"
HOOK_CMD_END="bash $SCRIPT_DIR/hook_cleanup.sh"

# ── 5. Idempotency check ────────────────────────────────────────────────────
already_installed() {
  jq -e --arg cmd "$1" \
    '[.hooks[]?[]?.hooks[]? | select(.command == $cmd)] | length > 0' \
    "$SETTINGS" >/dev/null 2>&1
}

if already_installed "$HOOK_CMD_START"; then
  echo "Hooks already registered in $SETTINGS — nothing to do."
  exit 0
fi

# ── 6. Merge hooks into settings.json ────────────────────────────────────────
NEW_START=$(jq -n --arg cmd "$HOOK_CMD_START" '{"hooks":[{"type":"command","command":$cmd}]}')
NEW_STOP=$(jq -n --arg cmd "$HOOK_CMD_STOP" '{"hooks":[{"type":"command","command":$cmd}]}')
NEW_END=$(jq -n --arg cmd "$HOOK_CMD_END" '{"hooks":[{"type":"command","command":$cmd}]}')

jq \
  --argjson new_start "$NEW_START" \
  --argjson new_stop  "$NEW_STOP"  \
  --argjson new_end   "$NEW_END"   \
  '
  .hooks //= {}
  | .hooks.SessionStart //= []
  | .hooks.Stop //= []
  | .hooks.SessionEnd //= []
  | .hooks.SessionStart += [$new_start]
  | .hooks.Stop         += [$new_stop]
  | .hooks.SessionEnd   += [$new_end]
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo "Hooks registered in $SETTINGS"
echo ""
echo "Next: export CLAUDE_FIFO_HOOK=1 before launching Claude Code inside tmux."
