#!/usr/bin/env bash
# SessionEnd hook — kills the background FIFO reader process.
[ "$CLAUDE_FIFO_HOOK" = "1" ] || exit 0

PID_FILE="/tmp/claude-fifo-reader.pid"
if [ -f "$PID_FILE" ]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null
  rm -f "$PID_FILE"
fi
exit 0
