#!/usr/bin/env bash
set -euo pipefail

# Called by Claude Code UserPromptSubmit hook.
# Logs user prompts, asks Ollama for a session summary,
# and sets the Ghostty tab title.

SESSION_FILE="/tmp/claude-tab-${PPID}.log"
DIR="${PWD##*/}"

# Read hook JSON from stdin
INPUT=$(cat)

# Extract user prompt
TEXT=$(printf '%s' "$INPUT" | jq -r '
  .prompt // .user_prompt // .message // .content // empty
' 2>/dev/null | head -c 500) || true

[ -z "${TEXT:-}" ] && exit 0

echo "$TEXT" >> "$SESSION_FILE"

# Trim log to last 30 lines once past 50
if [ "$(wc -l < "$SESSION_FILE" 2>/dev/null)" -gt 50 ]; then
  tail -30 "$SESSION_FILE" > "${SESSION_FILE}.tmp"
  mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
fi

# Resolve tty before backgrounding
TTY_NAME=$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ')
if [ -n "${TTY_NAME:-}" ] && [ "$TTY_NAME" != "??" ] && [ -e "/dev/$TTY_NAME" ]; then
  MY_TTY="/dev/$TTY_NAME"
else
  MY_TTY="/dev/tty"
fi

# Background the Ollama call so the hook returns fast
(
  CONTEXT=$(cat "$SESSION_FILE")

  PROMPT="Summarize this coding session in 2-4 words. Terse, no punctuation, no quotes.
Examples: fixing auth bugs, API migration, new dashboard UI, refactoring tests

Session:
$CONTEXT

Summary:"

  LABEL=$(curl -sf --max-time 3 http://localhost:11434/api/generate \
    -d "$(jq -n --arg model llama3.2 --arg prompt "$PROMPT" \
      '{model: $model, prompt: $prompt, stream: false}')" \
    | jq -r '.response // empty' \
    | head -1 \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | cut -c1-30) || true

  if [ -n "${LABEL:-}" ]; then
    TITLE="${LABEL} · ${DIR}"
    printf '%s' "$TITLE" > "/tmp/claude-tab-label-${PPID}.txt"
    printf '\e]0;%s\a' "$TITLE" > "${MY_TTY}" 2>/dev/null || true
  fi
) &

exit 0
