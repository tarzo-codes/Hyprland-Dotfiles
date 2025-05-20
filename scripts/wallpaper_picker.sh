#!/bin/bash
input=$(waypaper --backend swww)
# Extract the full path using grep and regex
full_path=$(echo "$input" | grep -oP '(?<=Selected file: )[^ ]+')

wallust run $full_path

killall -SIGUSR2 waybar
