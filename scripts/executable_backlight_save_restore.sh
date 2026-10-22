#!/bin/bash

STATE_FILE="/tmp/.backlight_state"

# Check if we have direct write access to brightness sysfs (e.g. via video group)
if [ -w /sys/class/backlight/intel_backlight/brightness ]; then
  BRILLO_CMD="brillo"
else
  BRILLO_CMD="sudo brillo"
fi

wait_for_brillo() {
  while pgrep -x "brillo" > /dev/null 2>&1; do
    sleep 0.05
  done
}

safe_write_state() {
  if [ ! -f "$STATE_FILE" ]; then
    CURRENT=$($BRILLO_CMD -q -G 2>/dev/null)
    # Don't save if current brightness is empty or near zero (< 5%)
    if [ -n "$CURRENT" ] && [ $(awk "BEGIN {print ($CURRENT >= 5)}") -eq 1 ]; then
      echo "$CURRENT" > "$STATE_FILE.tmp"
      mv -n "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null
      rm -f "$STATE_FILE.tmp"
    fi
  fi
}

case "$1" in
  set)
    TARGET=${2:-0}
    TIME=${3:-500}
    wait_for_brillo
    safe_write_state
    $BRILLO_CMD -q -u "$TIME"000 -S "$TARGET"
    ;;
  restore)
    TIME=${2:-500}
    MY_STATE="/tmp/.backlight_state.restore.$$"
    if mv "$STATE_FILE" "$MY_STATE" 2>/dev/null; then
      VALUE=$(cat "$MY_STATE")
      rm -f "$MY_STATE"
      # Fallback to 50% if saved value was corrupted or too dark
      if [ -z "$VALUE" ] || [ $(awk "BEGIN {print ($VALUE < 5)}") -eq 1 ]; then
        VALUE=50
      fi
      wait_for_brillo
      $BRILLO_CMD -q -u "$TIME"000 -S "$VALUE"
    fi
    ;;
  lock)
    wait_for_brillo
    safe_write_state
    $BRILLO_CMD -q -u 400000 -S 0
    ;;
  percent)
    PERCENT=${2:-100}
    TIME=${3:-500}
    wait_for_brillo
    safe_write_state
    CURRENT=$($BRILLO_CMD -q -G 2>/dev/null)
    if [ -n "$CURRENT" ]; then
      TARGET=$(awk "BEGIN {printf \"%.2f\", $CURRENT * $PERCENT / 100}")
      $BRILLO_CMD -q -u "$TIME"000 -S "$TARGET"
    fi
    ;;
  *)
    echo "Usage: $0 set [target_brightness] [time_ms] | restore [time_ms] | percent [percentage] [time_ms]"
    ;;
esac