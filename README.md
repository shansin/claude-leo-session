# claude-leo-session

Claude Code hooks for WhatsApp integration via named FIFOs. Allows a WhatsApp bot to send messages into a running Claude Code session and receive responses back.

ref: https://github.com/shansin/whatsapp-leo

## How it works

The integration uses two named FIFOs (named pipes) to bridge WhatsApp and a Claude Code session running inside tmux:

```
WhatsApp bot  ──write──▶  FIFO_IN  ──▶  fifo_reader.sh  ──tmux send-keys──▶  Claude Code
Claude Code   ──hook──▶   hook_stop.sh  ──write──▶  FIFO_OUT  ──▶  WhatsApp bot
```

- **Input:** A background FIFO reader watches the input pipe and injects messages into Claude's tmux pane using `tmux send-keys`.
- **Output:** A Stop hook captures Claude's last assistant message and writes it to the output pipe for the WhatsApp bot to consume.

## Files

| File | Hook type | Purpose |
|------|-----------|---------|
| `hook_session_start.sh` | `SessionStart` | Launches the background FIFO reader when a Claude session begins |
| `fifo_reader.sh` | — | Background process that reads from the input FIFO and injects text into the tmux pane |
| `hook_stop.sh` | `Stop` | Extracts Claude's last response and writes it to the output FIFO |
| `hook_cleanup.sh` | `SessionEnd` | Kills the background FIFO reader on session exit |
| `env.sh` | — | Loads `.env` and sets `FIFO_IN`/`FIFO_OUT` with defaults |
| `.env.example` | — | Example configuration file |
| `install.sh` | — | Registers hooks in `~/.claude/settings.json` |
| `uninstall.sh` | — | Removes hooks from `~/.claude/settings.json` |

## Prerequisites

- **tmux** — Claude Code must be running inside a tmux session
- **jq** — used by `hook_stop.sh` to parse the hook JSON payload
- **python3** — used for non-blocking FIFO writes

## Installation

```bash
git clone https://github.com/shansin/claude-leo-session.git
cd claude-leo-session
bash install.sh
```

The install script will:
- Check that `tmux`, `jq`, and `python3` are available
- Create `.env` from `.env.example` (edit it to customize FIFO paths)
- Register the hooks in `~/.claude/settings.json` (merges safely with existing hooks)

Then set the activation flag before launching Claude Code inside tmux:

```bash
export CLAUDE_FIFO_HOOK=1
```

The WhatsApp bot should create the FIFOs, but you can also create them manually:

```bash
mkfifo /tmp/whatsapp-leo-hook-dedicated_number-claude-session-in.fifo
mkfifo /tmp/whatsapp-leo-hook-dedicated_number-claude-session-out.fifo
```

## Uninstallation

```bash
bash uninstall.sh
```

Removes hook entries from `~/.claude/settings.json` and optionally deletes `.env`.

## Configuration

FIFO paths are configured via `.env` (or environment variables). Defaults if unset:

| Variable | Default | Direction |
|----------|---------|-----------|
| `FIFO_IN` | `/tmp/whatsapp-leo-hook-dedicated_number-claude-session-in.fifo` | WhatsApp → Claude |
| `FIFO_OUT` | `/tmp/whatsapp-leo-hook-dedicated_number-claude-session-out.fifo` | Claude → WhatsApp |

## Debugging

Logs from the FIFO reader are written to `/tmp/claude-fifo-hook.log`.
