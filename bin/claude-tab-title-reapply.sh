#!/usr/bin/env bash
set -euo pipefail

# Background watcher that re-applies the cached tab title every 2 seconds.
# Started on SessionStart, killed on SessionEnd.
# Usage: claude-tab-title-reapply.sh start|stop

cat > /dev/null

ACTION="${1:-apply}"
PID_FILE="/tmp/claude-tab-watcher-${PPID}.pid"
LABEL_FILE="/tmp/claude-tab-label-${PPID}.txt"

case "$ACTION" in
  start)
    TTY_NAME=$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ')
    if [ -n "${TTY_NAME:-}" ] && [ "$TTY_NAME" != "??" ] && [ -e "/dev/$TTY_NAME" ]; then
      MY_TTY="/dev/$TTY_NAME"
    else
      exit 0
    fi

    # Kill any existing watcher for this session
    [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null || true

    (
      while true; do
        sleep 2
        [ -f "$LABEL_FILE" ] || continue
        TITLE=$(cat "$LABEL_FILE" 2>/dev/null) || continue
        [ -n "${TITLE:-}" ] || continue
        printf '\e]0;%s\a' "$TITLE" > "${MY_TTY}" 2>/dev/null || true
      done
    ) </dev/null >/dev/null 2>&1 &
    disown
    echo $! > "$PID_FILE"
    ;;

  stop)
    [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE" 2>/dev/null || true
    ;;
esac

exit 0
