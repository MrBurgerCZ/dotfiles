#!/bin/bash

BRILLO=/usr/bin/brillo
STATE_FILE="/tmp/.backlight_state"

wait_for_brillo() {
  while pgrep -x "$(basename $BRILLO)" > /dev/null; do
    sleep 0.1
  done
}

safe_write_state() {
  if [ ! -f "$STATE_FILE" ]; then
    sudo brillo -r > "$STATE_FILE.tmp"
    mv -n "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null
    rm -f "$STATE_FILE.tmp"
  fi
}

case "$1" in
  set)
    TARGET=${2:-0}
    TIME=${3:-300}
    wait_for_brillo
    safe_write_state
    sudo brillo -u "$TIME"000 -S "$TARGET"
    ;;
  restore)
    MY_STATE="/tmp/.backlight_state.restore.$$"
    if mv "$STATE_FILE" "$MY_STATE" 2>/dev/null; then
      VALUE=$(cat "$MY_STATE")
      wait_for_brillo
      sudo brillo -u ${2:-900}000 -S "$VALUE" -r
      rm -f "$MY_STATE"
    fi
    ;;
  lock)
    hyprlock &
    wait_for_brillo
    safe_write_state
    sudo brillo -u 300000 -S 0
    ;;
  percent)
    PERCENT=${2:-100}
    TIME=${3:-300}
    wait_for_brillo
    safe_write_state
    CURRENT=$(sudo brillo -G)
    TARGET=$(echo "$CURRENT * $PERCENT / 100" | bc)
    sudo brillo -u "$TIME"000 -S "$TARGET"
    ;;
  *)
    echo "Usage: $0 set [target_brightness] | restore | percent [percentage]"
    ;;
esac