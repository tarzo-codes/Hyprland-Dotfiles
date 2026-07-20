A#!/bin/bash
# Toggle waybar transparency on/off

CONFIG="$HOME/.config/waybar/config.jsonc"
STYLE_OPAQUE="$HOME/.config/waybar/style.css"
STYLE_TRANSPARENT="$HOME/.config/waybar/style-transparent.css"
TRANSPARENCY_FLAG="$HOME/.config/waybar/.transparent"

if [ -f "$TRANSPARENCY_FLAG" ]; then
    # Switch to opaque
    rm -f "$TRANSPARENCY_FLAG"
    if pgrep -x waybar >/dev/null 2>&1; then
        killall -q waybar
        sleep 0.5
    fi
    if command -v waybar >/dev/null 2>&1; then
        waybar -c "$CONFIG" -s "$STYLE_OPAQUE" >/dev/null 2>&1 &
    fi
    notify-send "Waybar" "Transparency disabled"
else
    # Switch to transparent
    touch "$TRANSPARENCY_FLAG"
    if pgrep -x waybar >/dev/null 2>&1; then
        killall -q waybar
        sleep 0.5
    fi
    if command -v waybar >/dev/null 2>&1; then
        waybar -c "$CONFIG" -s "$STYLE_TRANSPARENT" >/dev/null 2>&1 &
    fi
    notify-send "Waybar" "Transparency enabled"
fi