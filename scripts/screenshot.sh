#!/bin/bash
mkdir -p ~/Pictures/Screenshots
FILE=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png

if command -v swappy &>/dev/null; then
    grim -g "$(slurp)" - | swappy -f -
elif command -v ksnip &>/dev/null; then
    ksnip -r
else
    grim -g "$(slurp)" - | tee "$FILE" | wl-copy -t image/png
fi
