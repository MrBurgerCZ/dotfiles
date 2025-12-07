#!/bin/bash

# run as root
if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
fi

FAN_FILE="/proc/acpi/ibm/fan"
LEVELS=("0" "auto" "1" "2" "3" "4" "5" "6" "7" "disengaged")

get_current_level() {
    grep -m1 "level" "$FAN_FILE" | awk '{print $2}'
}

get_current_speed() {
    grep -m1 "speed" "$FAN_FILE" | awk '{print $2}'
}

set_level() {
    echo "level $1" | tee $FAN_FILE > /dev/null
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
        echo "${speed} RPM ${current}"
        ;;
esac
