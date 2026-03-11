#!/usr/bin/env bash
set -euo pipefail

# Uninstall claude-tab-title: removes scripts, hooks, and temp files.

BIN_DIR="${HOME}/.local/bin"
SETTINGS="${HOME}/.claude/settings.json"

# --- Remove scripts ---

rm -f "$BIN_DIR/claude-tab-title.sh" "$BIN_DIR/claude-tab-title-reapply.sh"
echo "Removed scripts from $BIN_DIR/"

# --- Kill any running watchers ---

for pid_file in /tmp/claude-tab-watcher-*.pid; do
  [ -f "$pid_file" ] && kill "$(cat "$pid_file")" 2>/dev/null || true
  rm -f "$pid_file" 2>/dev/null || true
done

# --- Clean up temp files ---

rm -f /tmp/claude-tab-*.log /tmp/claude-tab-label-*.txt 2>/dev/null || true
echo "Cleaned up temp files."

# --- Remove hooks from settings.json ---

if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  # Remove hook entries that reference our scripts
  CLEANED=$(jq '
    def remove_ours:
      if type == "array" then
        map(
          if type == "object" and .hooks then
            .hooks = [.hooks[] | select(
              (.command // "") |
              (contains("claude-tab-title") or contains("claude-tab-$PPID") or contains("claude-tab-label")) | not
            )] |
            select(.hooks | length > 0)
          else .
          end
        ) |
        select(length > 0) // empty
      else .
      end;

    if .hooks then
      .hooks |= with_entries(
        .value |= remove_ours
      ) |
      .hooks |= with_entries(select(.value != null))
    else .
    end
  ' "$SETTINGS")

  printf '%s\n' "$CLEANED" > "$SETTINGS"
  echo "Removed hooks from $SETTINGS"
fi

echo ""
echo "Done! Claude Code tab titles are back to default."
