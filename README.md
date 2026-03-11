# claude-tab-title

Dynamic tab titles for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in [Ghostty](https://ghostty.org/).

Uses local [Ollama](https://ollama.com) to summarize your coding session into a short label like **"fixing auth bugs · myproject"** and keeps it as the tab title — even though Claude Code normally overwrites it.

![demo](https://img.shields.io/badge/status-works-brightgreen)

## How it works

1. Every time you send a prompt, the hook logs it and asks Ollama (`llama3.2`) for a 2-4 word summary
2. A background watcher re-applies the title every 2 seconds so Claude Code can't overwrite it
3. When you switch topics mid-session, the title updates on your next prompt

## Requirements

- [Ollama](https://ollama.com) running locally with `llama3.2` pulled
- `jq` and `curl` (likely already installed)
- Ghostty terminal (uses standard OSC escape sequences, may work with other terminals)

## Install

```bash
git clone https://github.com/pavelnovel/claude-tab-title.git
cd claude-tab-title
./install.sh
```

Then start a new Claude Code session. Send a couple of prompts and the tab title will update within a few seconds.

## Uninstall

```bash
cd claude-tab-title
./uninstall.sh
```

## What it installs

- `~/.local/bin/claude-tab-title.sh` — prompt logger + Ollama summarizer
- `~/.local/bin/claude-tab-title-reapply.sh` — background title watcher
- Hooks in `~/.claude/settings.json` for `SessionStart`, `UserPromptSubmit`, and `SessionEnd`

Temp files (cleaned up automatically per session):
- `/tmp/claude-tab-<pid>.log` — session prompt log
- `/tmp/claude-tab-label-<pid>.txt` — cached title
- `/tmp/claude-tab-watcher-<pid>.pid` — watcher process ID
