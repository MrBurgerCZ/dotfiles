#!/bin/bash

# run as root
if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
fi

FAN_FILE="/proc/acpi/ibm/fan"
MUTE_LED_FILE="/sys/class/leds/platform::mute/brightness"
MIC_LED_FILE="/sys/class/leds/platform::micmute/brightness"
LEVELS=("0" "auto" "1" "2" "3" "4" "5" "6" "7" "disengaged")

get_current_level() {
    grep -m1 "level" "$FAN_FILE" | awk '{print $2}'
}

get_current_speed() {
    grep -m1 "speed" "$FAN_FILE" | awk '{print $2}'
}

# Funkce pro ovladani LEDky
update_led() {
    if [[ "$1" == "auto" ]]; then
        echo 0 > "$MUTE_LED_FILE"
    else
        echo 1 > "$MUTE_LED_FILE"
    fi
    if [[ "$1" == "disengaged" ]]; then
        echo 1 > "$MIC_LED_FILE"
    else
        echo 0 > "$MIC_LED_FILE"
    fi
}

set_level() {
    echo "level $1" | tee $FAN_FILE > /dev/null
    update_led "$1"
}

current=$(get_current_level)

case "$1" in
    up)
        for i in "${!LEVELS[@]}"; do
            if [[ "${LEVELS[$i]}" == "$current" ]]; then
                if (( i < ${#LEVELS[@]}-1 )); then
                    set_level "${LEVELS[$((i+1))]}"
                fi
                break
            fi
        done
        ;;
    down)
        for i in "${!LEVELS[@]}"; do
            if [[ "${LEVELS[$i]}" == "$current" ]]; then
                if (( i > 0 )); then
                    set_level "${LEVELS[$((i-1))]}"
                fi
                break
            fi
        done
        ;;
    emergency)
        set_level "disengaged"
        ;;
    auto)
        set_level "auto"
        ;;
    show|*)
        speed=$(get_current_speed)
        # Pro jistotu syncneme LEDku i pri zobrazeni stavu
        update_led "$current"
        echo "${speed} RPM ${current}"
        ;;
esac