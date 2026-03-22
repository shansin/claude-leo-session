#!/usr/bin/env bash
# Background FIFO reader — reads from input FIFO and injects into Claude's
# tmux pane via send-keys. Launched by hook_session_start.sh.
FIFO_IN="$1"
PANE_TARGET="$2"

if [ -z "$PANE_TARGET" ]; then
  echo "[fifo_reader] No TMUX_PANE provided, cannot inject" >&2
  exit 1
fi

echo "[fifo_reader] Started: reading $FIFO_IN → tmux pane $PANE_TARGET" >&2

while true; do
  if [ -p "$FIFO_IN" ]; then
    # open() blocks until a writer connects; read processes one line at a time
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      echo "[fifo_reader] Injecting: ${line:0:80}" >&2
      # -l = literal text (prevents tmux key-name interpretation of ; C- etc.)
      tmux send-keys -t "$PANE_TARGET" -l "$line"
      # Enter sent separately without -l so tmux sends actual keypress
      tmux send-keys -t "$PANE_TARGET" Enter
    done < "$FIFO_IN"
    # EOF — writer closed, loop back to re-open
  else
    echo "[fifo_reader] FIFO not found: $FIFO_IN, waiting..." >&2
    sleep 1
  fi
done
