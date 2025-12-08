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
    sudo brillo -r > "$STATE_FILE"
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
    if [ -f "$STATE_FILE" ]; then
      VALUE=$(cat "$STATE_FILE")
      wait_for_brillo
      sudo brillo -u ${2:-900}000 -S "$VALUE" -r
      rm -f "$STATE_FILE"
    fi
    ;;
  lock)
    swaylock &
    wait_for_brillo
    safe_write_state &
    sudo brillo -u 300000 -S 0
    # brightnessctl s 0
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
