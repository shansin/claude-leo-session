#!/usr/bin/env bash
# SessionStart hook — launches background FIFO reader for WhatsApp integration.
# Only active when CLAUDE_FIFO_HOOK=1.
[ "$CLAUDE_FIFO_HOOK" = "1" ] || exit 0

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. "$SCRIPT_DIR/env.sh"

# Claude Code runs inside tmux — $TMUX_PANE gives us the target pane
PANE_TARGET="${TMUX_PANE:-}"

# Start FIFO reader in background, detached from this hook process
nohup bash "$SCRIPT_DIR/fifo_reader.sh" "$FIFO_IN" "$PANE_TARGET" \
  </dev/null >/dev/null 2>>/tmp/claude-fifo-hook.log &

# Store PID so SessionEnd hook can clean up
echo $! > /tmp/claude-fifo-reader.pid

exit 0
