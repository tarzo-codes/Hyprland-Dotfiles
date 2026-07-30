#!/bin/bash
if [ -d "$HOME/anime_wallapaper" ]; then
    WALLPAPER_DIR="$HOME/anime_wallapaper"
elif [ -d "$HOME/wallpaper" ]; then
    WALLPAPER_DIR="$HOME/wallpaper"
else
    WALLPAPER_DIR="$HOME/Pictures/wallpapers"
fi
INDEX_FILE="$HOME/.config/hypr/.wallpaper_index"
mapfile -t WALLS < <(find "$WALLPAPER_DIR" -type f | sort)

if [ ! -f "$INDEX_FILE" ]; then
    echo 0 > "$INDEX_FILE"
fi

INDEX=$(cat "$INDEX_FILE")
NEXT_INDEX=$(( (INDEX + 1) % ${#WALLS[@]} ))
echo "$NEXT_INDEX" > "$INDEX_FILE"

swww img "${WALLS[$NEXT_INDEX]}"
wallust run "${WALLS[$NEXT_INDEX]}"
