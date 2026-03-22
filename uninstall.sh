#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SETTINGS="$HOME/.claude/settings.json"

# ── 1. Check settings.json exists ───────────────────────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo "No $SETTINGS found, nothing to do."
  exit 0
fi

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required but not found"; exit 1; }

# ── 2. Build the command strings to match ────────────────────────────────────
HOOK_CMD_START="bash $SCRIPT_DIR/hook_session_start.sh"
HOOK_CMD_STOP="bash $SCRIPT_DIR/hook_stop.sh"
HOOK_CMD_END="bash $SCRIPT_DIR/hook_cleanup.sh"

# ── 3. Remove our hook entries ───────────────────────────────────────────────
jq \
  --arg start "$HOOK_CMD_START" \
  --arg stop  "$HOOK_CMD_STOP"  \
  --arg end   "$HOOK_CMD_END"   \
  '
  .hooks.SessionStart |= (if . then map(select(any(.hooks[]?; .command == $start) | not)) else [] end)
  | .hooks.Stop       |= (if . then map(select(any(.hooks[]?; .command == $stop)  | not)) else [] end)
  | .hooks.SessionEnd |= (if . then map(select(any(.hooks[]?; .command == $end)   | not)) else [] end)
  | .hooks |= with_entries(select(.value | length > 0))
  | if (.hooks | length) == 0 then del(.hooks) else . end
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo "Hooks removed from $SETTINGS."

# ── 4. Optionally remove .env ────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
  read -rp "Remove .env file? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    rm -f "$SCRIPT_DIR/.env"
    echo "Removed .env."
  fi
fi
