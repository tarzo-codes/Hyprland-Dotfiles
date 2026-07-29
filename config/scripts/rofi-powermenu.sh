#!/usr/bin/env bash

# Set theme
theme="~/.config/rofi/applets/power_menu.rasi"

# Uptime message
uptime_msg="Uptime: $(uptime -p | sed 's/up //')"

# Options
options=" Lock\n Logout\n Suspend\n鈴 Hibernate\n Reboot\n Shutdown"

# Show power menu
choice=$(echo -e "$options" | rofi -dmenu -p "Power Menu" -mesg "$uptime_msg" -theme "$theme")

# Handle choice
case "$choice" in
    *Lock*)     exec betterlockscreen -l ;;
    *Logout*)   exec hyprctl dispatch exit ;;
    *Suspend*)  systemctl suspend ;;
    *Hibernate*) systemctl hibernate ;;
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
