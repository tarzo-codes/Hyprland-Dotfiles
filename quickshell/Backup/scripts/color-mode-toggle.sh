#!/bin/bash
# Color mode toggle for Quickshell - switches between Wallust dynamic and fixed themes
# Usage: color-mode-toggle.sh [toggle|dynamic|fixed]

MODE_FILE="$HOME/.config/quickshell/.color-mode"

get_current_mode() {
    if [ -f "$MODE_FILE" ]; then
        cat "$MODE_FILE"
    else
        echo "dynamic"
    fi
}

set_mode() {
    echo "$1" > "$MODE_FILE"
    notify-send "Quickshell Color Mode" "Switched to: $1"
    pkill -x quickshell || true
}

toggle_mode() {
    local current=$(get_current_mode)
    if [ "$current" = "dynamic" ]; then
        set_mode "fixed"
    else
        set_mode "dynamic"
    fi
}

case "${1:-toggle}" in
    toggle)
        toggle_mode
        ;;
    dynamic)
        set_mode "dynamic"
        ;;
    fixed)
        set_mode "fixed"
        ;;
    *)
        echo "Usage: $0 [toggle|dynamic|fixed]"
        exit 1
        ;;
esac