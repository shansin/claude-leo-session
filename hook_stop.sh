#!/usr/bin/env bash
# Stop hook — sends Claude's last response to the output FIFO for WhatsApp.
# Uses non-blocking write so it never hangs if no reader is connected.
[ "$CLAUDE_FIFO_HOOK" = "1" ] || exit 0

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. "$SCRIPT_DIR/env.sh"
[ -p "$FIFO_OUT" ] || exit 0

# Read JSON payload from stdin, extract last_assistant_message
MSG=$(jq -r '.last_assistant_message // ""')
[ -z "$MSG" ] && exit 0

# Non-blocking write — mirrors write_to_hook() pattern from hooks.py
python3 -c "
import os, sys
try:
    fd = os.open(sys.argv[1], os.O_WRONLY | os.O_NONBLOCK)
    os.write(fd, (sys.argv[2] + '\n').encode())
    os.close(fd)
except OSError:
    pass
" "$FIFO_OUT" "$MSG"

exit 0
