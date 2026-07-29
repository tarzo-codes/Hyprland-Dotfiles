#!/bin/bash

# Launch waypaper and capture output
input=$(waypaper --backend swww)

# Extract the full wallpaper path
full_path=$(echo "$input" | grep -oP '(?<=Selected file: )[^ ]+')

# Check if a valid path was extracted
if [[ -z "$full_path" ]]; then
  echo "No file selected or path could not be extracted."
  exit 1
fi

# Apply color scheme using wallust
wallust run "$full_path"

# Reload waybar if running
if pgrep -x waybar > /dev/null; then
  killall -SIGUSR2 waybar
else
  echo "Waybar is not running."
fi

kill -USR1 $(pidof mako)
mako --config ~/.config/mako/config;

~/.config/scripts/dynamic-icon.sh

notify-send "Theme Changed" "Your Whole theme just changed"
