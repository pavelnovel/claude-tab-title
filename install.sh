#!/usr/bin/env bash
set -euo pipefail

# Install claude-tab-title: copies scripts and merges hooks into
# Claude Code's ~/.claude/settings.json.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SETTINGS="${HOME}/.claude/settings.json"

# --- Preflight checks ---

for cmd in jq curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not installed." >&2
    exit 1
  fi
done

if ! curl -sf --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "Warning: Ollama is not running at localhost:11434."
  echo "The tab title feature requires Ollama with llama3.2."
  echo "Install: https://ollama.com  then: ollama pull llama3.2"
  echo ""
fi

# --- Install scripts ---

mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/claude-tab-title.sh" "$BIN_DIR/"
cp "$SCRIPT_DIR/bin/claude-tab-title-reapply.sh" "$BIN_DIR/"
chmod +x "$BIN_DIR/claude-tab-title.sh" "$BIN_DIR/claude-tab-title-reapply.sh"
echo "Installed scripts to $BIN_DIR/"

# --- Merge hooks into settings.json ---

mkdir -p "${HOME}/.claude"

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Build the hooks object to merge
HOOKS_JSON=$(cat <<'HOOKEOF'
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": ": > /tmp/claude-tab-$PPID.log 2>/dev/null || true"
        },
        {
          "type": "command",
          "command": "~/.local/bin/claude-tab-title-reapply.sh start"
        }
      ]
    }
  ],
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "~/.local/bin/claude-tab-title.sh"
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "~/.local/bin/claude-tab-title-reapply.sh stop; rm -f /tmp/claude-tab-$PPID.log /tmp/claude-tab-label-$PPID.txt 2>/dev/null || true"
        }
      ]
    }
  ]
}
HOOKEOF
)

# Merge: append our hook entries to any existing ones per event
MERGED=$(jq --argjson new_hooks "$HOOKS_JSON" '
  .hooks //= {} |
  .hooks.SessionStart = (.hooks.SessionStart // []) + $new_hooks.SessionStart |
  .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + $new_hooks.UserPromptSubmit |
  .hooks.SessionEnd = (.hooks.SessionEnd // []) + $new_hooks.SessionEnd
' "$SETTINGS")

printf '%s\n' "$MERGED" > "$SETTINGS"
echo "Merged hooks into $SETTINGS"

echo ""
echo "Done! Start a new Claude Code session to activate."
echo "Send a few prompts and the tab title will update."
