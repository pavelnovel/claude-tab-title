# claude-tab-title

Dynamic tab titles for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Uses a local LLM to summarize your coding session into a short label like **"fixing auth bugs · myproject"** and keeps it as the tab title.

## How it works

1. Every time you send a prompt, the hook logs it and asks your local LLM for a 2-4 word summary
2. A background watcher re-applies the title every 2 seconds so Claude Code can't overwrite it
3. When you switch topics mid-session, the title updates on your next prompt

## Requirements

- A local LLM server with an OpenAI-compatible API (any of these work):
  - [Ollama](https://ollama.com) (default, `ollama pull llama3.2`)
  - [LM Studio](https://lmstudio.ai)
  - [llamafile](https://github.com/Mozilla-Ocho/llamafile)
- `jq` and `curl`
- A terminal that supports OSC title sequences (Ghostty, iTerm2, kitty, etc.)

## Setup

Copy the script somewhere on your PATH:

```bash
cp bin/claude-tab-title ~/.local/bin/
chmod +x ~/.local/bin/claude-tab-title
```

Add these hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "claude-tab-title start" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "claude-tab-title prompt" }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": "claude-tab-title stop" }
        ]
      }
    ]
  }
}
```

## Configuration

Set environment variables to use a different LLM backend:

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_TAB_TITLE_API_URL` | `http://localhost:11434/v1/chat/completions` | OpenAI-compatible chat completions endpoint |
| `CLAUDE_TAB_TITLE_MODEL` | `llama3.2` | Model name |

### Examples

**LM Studio** (default port 1234):
```bash
export CLAUDE_TAB_TITLE_API_URL=http://localhost:1234/v1/chat/completions
export CLAUDE_TAB_TITLE_MODEL=your-model-name
```

**Ollama** (default, no config needed):
```bash
ollama pull llama3.2
# just works
```

## Uninstall

Remove the script and clean up any leftover temp files:

```bash
rm ~/.local/bin/claude-tab-title
rm -f /tmp/claude-tab-*.log /tmp/claude-tab-label-*.txt /tmp/claude-tab-watcher-*.pid
```

Remove the three hook entries from `~/.claude/settings.json`.
