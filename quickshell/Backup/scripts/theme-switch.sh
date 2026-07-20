#!/bin/bash
# Quickshell style switcher - 18 bar styles that physically change the bar
# Colors are provided by Wallust - this only changes visual structure
# Usage: theme-switch.sh [random|next|prev|style-name]

STYLE_FILE="$HOME/.config/quickshell/.saved-style"

# 18 Visual Styles - each with distinct appearance
get_style_list() {
    echo -e "neon\nglass\nminimal\nretro\ncyber\nsharp\npill\nbeveled\nsoft\nframed\nthin\nthick\nasym\ndome\nsquare\nrounded\ndouble\ninglow"
}

switch_style() {
    local name="$1"
    echo "$name" > "$STYLE_FILE"
    pkill -x quickshell || true
    sleep 0.3
    nohup quickshell &>/dev/null &
    notify-send "Quickshell Style" "Switched to: $name"
}

case "${1:-next}" in
    random)
        mapfile -t list < <(get_style_list)
        rand_idx=$(( RANDOM % ${#list[@]} ))
        switch_style "${list[$rand_idx]}"
        ;;
    next)
        current=$(cat "$STYLE_FILE" 2>/dev/null || echo "neon")
        mapfile -t list < <(get_style_list)
        idx=-1
        for i in "${!list[@]}"; do
            if [ "${list[$i]}" = "$current" ]; then
                idx=$i
                break
            fi
        done
        idx=$(( (idx + 1) % ${#list[@]} ))
        switch_style "${list[$idx]}"
        ;;
    prev)
        current=$(cat "$STYLE_FILE" 2>/dev/null || echo "neon")
        mapfile -t list < <(get_style_list)
        idx=-1
        for i in "${!list[@]}"; do
            if [ "${list[$i]}" = "$current" ]; then
                idx=$i
                break
            fi
        done
        idx=$(( (idx - 1 + ${#list[@]} ) % ${#list[@]} ))
        switch_style "${list[$idx]}"
        ;;
    *)
        switch_style "$1"
        ;;
esac