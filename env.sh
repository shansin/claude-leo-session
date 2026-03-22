#!/usr/bin/env bash
# Source .env from the same directory as this script.
# Sets FIFO_IN and FIFO_OUT with defaults if not already set.
_ENV_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[ -f "$_ENV_DIR/.env" ] && set -a && . "$_ENV_DIR/.env" && set +a

: "${FIFO_IN:=/tmp/whatsapp-leo-hook-dedicated_number-claude-session-in.fifo}"
: "${FIFO_OUT:=/tmp/whatsapp-leo-hook-dedicated_number-claude-session-out.fifo}"
