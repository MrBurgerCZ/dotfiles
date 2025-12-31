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

update_osd() {
    local cmd=""
    case "$1" in
        auto)
            cmd="swayosd-client --custom-progress 0"
            ;;
        disengaged)
            cmd="swayosd-client --custom-progress 1"
            ;;
        *)
            if [[ "$1" =~ ^[0-7]$ ]]; then
                cmd="swayosd-client --custom-segmented-progress $1:7"
            fi
            ;;
    esac

    if [[ -n "$cmd" ]]; then
        # Pokud bezime pres sudo, zkusime to pustit jako puvodni uzivatel, 
        # jinak by swayosd nemusel najit socket.
        if [[ -n "$SUDO_USER" ]]; then
            sudo -u "$SUDO_USER" $cmd &
        else
            $cmd &
        fi
    fi
}

set_level() {
    echo "level $1" | tee $FAN_FILE > /dev/null
    update_osd "$1"
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
