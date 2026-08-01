#!/bin/bash

# Wallpaper picker script with wallust color caching (both Dark & Light modes)
# and Tela icon theme matching derived strictly from the Dark Mode Accent color.
# Usage: ./wallpaper_picker.sh [path-to-image] [--wp-only] [--span] [--regenerate] [--verbose]

set -e

if [ -d "$HOME/anime_wallapaper" ]; then
  WALLPAPER_DIR="$HOME/anime_wallapaper"
elif [ -d "$HOME/wallpaper" ]; then
  WALLPAPER_DIR="$HOME/wallpaper"
else
  WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
fi
CACHE_DIR="$HOME/.cache/wallust"
TELA_BASE="Tela-blue"
VERBOSE="${VERBOSE:-false}"
WP_ONLY=false
SPAN=false
NO_QS_RESTART=false
REAPPLY=false
REGENERATE=false
IMAGE_PATH=""

# Debug output function
debug() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[DEBUG] $1" >&2
  fi
}

# Find the closest Tela base icon theme name using HSV hue-weighted color matching.
# Returns base name (e.g. "Tela-purple", "Tela-red", "Tela-dracula").
find_closest_tela() {
  local target_color="$1"
  python3 -c "
import colorsys
target_color = '$target_color'.lstrip('#')
if len(target_color) != 6:
    print('Tela-blue')
    exit(0)
colors = {
    'Tela-blue': '#5297e0', 'Tela-green': '#4caf50', 'Tela-red': '#e53935',
    'Tela-purple': '#9c27b0', 'Tela-pink': '#e91e63', 'Tela-orange': '#ff9800',
    'Tela-yellow': '#ffeb3b', 'Tela-brown': '#795548', 'Tela-grey': '#607d8b',
    'Tela-black': '#212121', 'Tela-dracula': '#bd93f9', 'Tela-nord': '#88c0d0',
    'Tela-manjaro': '#16a085', 'Tela-ubuntu': '#e95420'
}
tr, tg, tb = int(target_color[0:2],16)/255.0, int(target_color[2:4],16)/255.0, int(target_color[4:6],16)/255.0
th, ts, tv = colorsys.rgb_to_hsv(tr, tg, tb)
if ts < 0.15:
    print('Tela-grey' if tv > 0.3 else 'Tela-black')
    exit(0)

best_name, best_dist = 'Tela-blue', 999999
for name, hc in colors.items():
    hc = hc.lstrip('#')
    mr, mg, mb = int(hc[0:2],16)/255.0, int(hc[2:4],16)/255.0, int(hc[4:6],16)/255.0
    mh, ms, mv = colorsys.rgb_to_hsv(mr, mg, mb)
    dh = min(abs(th - mh), 1.0 - abs(th - mh))
    ds = abs(ts - ms)
    dv = abs(tv - mv)
    dist = dh * 4.0 + ds * 1.0 + dv * 0.5
    if dist < best_dist:
        best_dist, best_name = dist, name
print(best_name)
" 2>/dev/null || echo "Tela-blue"
}

# Set GTK and Qt icon theme
set_icon_theme() {
  local icon_theme="$1"

  debug "Setting icon theme to: $icon_theme"

  if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
  fi

  local gtk3_config="$HOME/.config/gtk-3.0/settings.ini"
  if [ -f "$gtk3_config" ]; then
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$gtk3_config"
  fi

  local gtk4_config="$HOME/.config/gtk-4.0/settings.ini"
  if [ -f "$gtk4_config" ]; then
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$gtk4_config"
  fi

  local xsettingsd_config="$HOME/.config/xsettingsd/xsettingsd.conf"
  if [ -f "$xsettingsd_config" ]; then
    sed -i "s#^Net/IconThemeName.*#Net/IconThemeName \"$icon_theme\"#g" "$xsettingsd_config"
    if command -v xsettingsd &> /dev/null; then
      pkill xsettingsd 2>/dev/null || true
      sleep 0.1
      xsettingsd -c "$xsettingsd_config" 2>/dev/null &
    fi
  fi
}

# Set wallpaper using awww (preferred) or swww (fallback)
set_wallpaper_backend() {
  local image="$1"
  local span="$2"

  if command -v awww &> /dev/null; then
    if [ "$span" = "true" ]; then
      awww img "$image" 2>/dev/null || {
        awww query 2>/dev/null | grep -oP 'outputs:\s*\K\S+' | while read -r output; do
          awww img -o "$output" "$image" 2>/dev/null || true
        done
      }
    else
      awww img "$image"
    fi
  elif command -v swww &> /dev/null; then
    swww img "$image" --transition-fps 60 --transition-type random
  else
    notify-send -u critical "Wallpaper" "No wallpaper backend found (install awww or swww)"
    return 1
  fi
}

## Shared helper: update all wallust-linked apps from the generated color script
update_apps() {
  local color_script="$HOME/.config/scripts/shared/dynamic-color.sh"
  if [ -f "$color_script" ]; then
    # shellcheck source=/dev/null
    source "$color_script"

    # ALWAYS USE DARK MODE ACCENT COLOR TO GENERATE ICON THEME!
    local dark_accent=""
    if [ -n "${CURRENT_WP_CACHE_DIR:-}" ] && [ -f "$CURRENT_WP_CACHE_DIR/dark_accent.txt" ]; then
      dark_accent=$(cat "$CURRENT_WP_CACHE_DIR/dark_accent.txt" 2>/dev/null || true)
    fi
    if [ -z "$dark_accent" ]; then
      dark_accent="${COLOR4:-${COLOR6:-#7aa2f7}}"
    fi

    # Pick correct Tela variant (-dark or -light) based on current mode
    IS_LIGHT_MODE=$(cat "$HOME/.cache/quickshell/is_light_mode" 2>/dev/null || echo "false")
    TELA_SUFFIX="-dark"
    [ "$IS_LIGHT_MODE" = "true" ] && TELA_SUFFIX="-light"

    if [ -n "$dark_accent" ]; then
      TELA_BASE=$(find_closest_tela "$dark_accent")
      BEST_TELA="${TELA_BASE}${TELA_SUFFIX}"
      # Verify it exists, fall back to base if variant directory missing
      if [ ! -d "$HOME/.local/share/icons/$BEST_TELA" ] && [ ! -d "/usr/share/icons/$BEST_TELA" ]; then
        BEST_TELA="$TELA_BASE"
      fi
      set_icon_theme "$BEST_TELA"
    fi

    if [ "$IS_LIGHT_MODE" = "true" ]; then
      read -r RUN_BG RUN_SUR RUN_FG < <(python3 -c "
colors = ['$BACKGROUND', '$COLOR0', '$COLOR1', '$COLOR2', '$COLOR3', '$COLOR4', '$COLOR5', '$COLOR6', '$COLOR7', '$COLOR8', '$COLOR9', '$COLOR10', '$COLOR11', '$COLOR12', '$COLOR13', '$COLOR14', '$COLOR15', '$FOREGROUND']
def luma(hex_str):
    if not hex_str or not hex_str.startswith('#'): return 0
    s = hex_str.lstrip('#')
    if len(s) != 6: return 0
    r, g, b = int(s[0:2],16)/255, int(s[2:4],16)/255, int(s[4:6],16)/255
    return 0.2126*r + 0.7152*g + 0.0722*b

valid = [c for c in colors if c and c.startswith('#')]
valid_sorted = sorted(valid, key=luma, reverse=True)
brightest = valid_sorted[0] if valid_sorted else '#f1f5f9'
if luma(brightest) < 0.85:
    brightest = '#f4f6f8'
print(f'{brightest} #ffffff #0f172a')
")
    else
      RUN_BG="${COLOR0:-#0d0f18}"
      RUN_SUR="${COLOR8:-#1e1e2e}"
      RUN_FG="${COLOR7:-#c0caf5}"
    fi

    # Update KDE / Dolphin / GTK / Mako / Neovim / Vicinae
    if [ -x "$HOME/.config/quickshell/scripts/sync-theme-externals.sh" ]; then
      "$HOME/.config/quickshell/scripts/sync-theme-externals.sh" \
        "$RUN_BG" \
        "$RUN_SUR" \
        "$RUN_FG" \
        "${COLOR4:-#7aa2f7}" \
        "${COLOR1:-#f7768e}" \
        "${COLOR2:-#9ece6a}" \
        "${COLOR3:-#e0af68}" \
        "${COLOR4:-#7aa2f7}" \
        "${COLOR6:-#7dcfff}" \
        "${COLOR5:-#bb9af7}" \
        "${COLOR8:-#6D8895}" \
        "wallust" 2>/dev/null &
    fi

    # Update Hyprland border colors live
    if command -v hyprctl &>/dev/null && [ -n "${COLOR6:-}" ]; then
      COLOR6_STRIPPED="${COLOR6#\#}"
      COLOR0_STRIPPED="${COLOR0#\#}"
      hyprctl keyword "general:col.active_border"   "rgba(${COLOR6_STRIPPED}ff)" 2>/dev/null || true
      hyprctl keyword "general:col.inactive_border" "rgba(${COLOR0_STRIPPED}ff)" 2>/dev/null || true
    fi

    # Regenerate starship, fish, fastfetch, btop
    [ -f "$HOME/.config/scripts/starship-smart-colors.py" ] && python3 "$HOME/.config/scripts/starship-smart-colors.py" 2>/dev/null || true
    [ -f "$HOME/.config/scripts/fish-smart-colors.py" ] && python3 "$HOME/.config/scripts/fish-smart-colors.py" 2>/dev/null || true
    [ -f "$HOME/.config/scripts/fastfetch-smart-logo.py" ] && python3 "$HOME/.config/scripts/fastfetch-smart-logo.py" 2>/dev/null || true
    [ -f "$HOME/.config/scripts/btop-smart-theme.py" ] && python3 "$HOME/.config/scripts/btop-smart-theme.py" 2>/dev/null || true
  fi

  # Kitty reload
  if command -v kitty &>/dev/null; then
    IS_LIGHT_KITTY=$(cat "$HOME/.cache/quickshell/is_light_mode" 2>/dev/null || echo "false")
    if [ "$IS_LIGHT_KITTY" = "true" ]; then
      KITTY_BG=$(python3 -c "
import subprocess, re
colors_str = '''${COLOR0:-#f4f6f8} ${COLOR1:-#f4f6f8} ${COLOR2:-#f4f6f8} ${COLOR3:-#f4f6f8} ${COLOR4:-#f4f6f8} ${COLOR5:-#f4f6f8} ${COLOR6:-#f4f6f8} ${COLOR7:-#f4f6f8} ${COLOR8:-#f4f6f8} ${COLOR9:-#f4f6f8} ${COLOR10:-#f4f6f8} ${COLOR11:-#f4f6f8} ${COLOR12:-#f4f6f8} ${COLOR13:-#f4f6f8} ${COLOR14:-#f4f6f8} ${COLOR15:-#f4f6f8} ${BACKGROUND:-#f4f6f8}'''
colors = [c for c in colors_str.split() if c.startswith('#') and len(c)==7]
def luma(h):
    s=h[1:]; r,g,b=int(s[0:2],16)/255,int(s[2:4],16)/255,int(s[4:6],16)/255
    return 0.2126*r+0.7152*g+0.0722*b
valid_sorted = sorted(colors, key=luma, reverse=True)
best = valid_sorted[0] if valid_sorted else '#f4f6f8'
print(best if luma(best)>=0.85 else '#f4f6f8')
" 2>/dev/null || echo "#f4f6f8")
      cp "$HOME/.config/kitty/wallust.conf" "$HOME/.config/kitty/wallust.conf.bak" 2>/dev/null || true
      sed -i \
        -e "s/^background .*/background   $KITTY_BG/" \
        -e "s/^foreground .*/foreground   #0f172a/" \
        -e "s/^cursor     .*/cursor       #334155/" \
        -e "s/^selection_background .*/selection_background #cbd5e1/" \
        -e "s/^selection_foreground .*/selection_foreground #0f172a/" \
        "$HOME/.config/kitty/wallust.conf" 2>/dev/null || true
    fi
    kitty @ set-colors --all --configured "$HOME/.config/kitty/wallust.conf" 2>/dev/null || true
  fi
}

get_palette_mode() {
  local image="$1"
  [ -z "$image" ] && image=$(cat "$HOME/.cache/quickshell/current_wallpaper" 2>/dev/null)
  
  MODE_CHOICE=$(cat "$HOME/.cache/quickshell/mode_choice" 2>/dev/null || echo "dark")

  if [ "$MODE_CHOICE" = "light" ]; then
    PALETTE_MODE="light"
    echo "true" > "$HOME/.cache/quickshell/is_light_mode"
  elif [ "$MODE_CHOICE" = "dark" ]; then
    PALETTE_MODE="dark"
    echo "false" > "$HOME/.cache/quickshell/is_light_mode"
  elif [ "$MODE_CHOICE" = "auto" ] && [ -n "$image" ] && [ -f "$image" ]; then
    LUMI_MEAN=$(python3 -c "import sys; from PIL import Image, ImageStat; im=Image.open(sys.argv[1]).convert('L'); print(int(ImageStat.Stat(im).mean[0]))" "$image" 2>/dev/null || echo 100)
    if [ "$LUMI_MEAN" -gt 160 ]; then
      PALETTE_MODE="light"
      echo "true" > "$HOME/.cache/quickshell/is_light_mode"
    else
      PALETTE_MODE="dark"
      echo "false" > "$HOME/.cache/quickshell/is_light_mode"
    fi
  else
    PALETTE_MODE="dark"
    if [ -f "$HOME/.cache/quickshell/is_light_mode" ] && [ "$(cat "$HOME/.cache/quickshell/is_light_mode")" = "true" ]; then
      PALETTE_MODE="light"
    fi
  fi
}

# Main wallpaper setting function — called when user picks a wallpaper
set_wallpaper() {
  local image="$1"
  local span="${2:-false}"

  if [ ! -f "$image" ]; then
    notify-send -u critical "Wallpaper" "File not found: $image"
    exit 1
  fi

  debug "Setting wallpaper: $image"

  # Save active wallpaper path to cache and config
  mkdir -p "$HOME/.cache/quickshell"
  echo "$image" > "$HOME/.cache/quickshell/current_wallpaper"
  if [ -f "$HOME/.config/waypaper/config.ini" ]; then
    sed -i "s|^wallpaper =.*|wallpaper = $image|" "$HOME/.config/waypaper/config.ini" 2>/dev/null || true
  fi

  # Set wallpaper image
  set_wallpaper_backend "$image" "$span"

  # If Wallpaper Only mode is enabled, skip theme update
  if [ "$WP_ONLY" = "true" ]; then
    notify-send "Wallpaper" "Wallpaper updated (Theme colors unchanged)"
    return 0
  fi

  # Determine wallust palette mode (dark / light / auto)
  get_palette_mode "$image"

  # Wallpaper MD5 Cache Setup
  local wp_hash
  wp_hash=$(md5sum "$image" | awk '{print $1}')
  export CURRENT_WP_CACHE_DIR="$HOME/.cache/wallust_cache/$wp_hash"

  local is_cached=false
  if [ "$REGENERATE" != "true" ] && [ -f "$CURRENT_WP_CACHE_DIR/dark_colors.sh" ] && [ -f "$CURRENT_WP_CACHE_DIR/light_colors.sh" ] && [ -f "$CURRENT_WP_CACHE_DIR/dark_accent.txt" ]; then
    is_cached=true
  fi

  if [ "$is_cached" = "true" ]; then
    echo "Using cached colors"
    notify-send "Wallpaper & Theme" "Using cached colors"
    mkdir -p "$HOME/.config/scripts/shared"
    cp "$CURRENT_WP_CACHE_DIR/${PALETTE_MODE}_colors.sh" "$HOME/.config/scripts/shared/dynamic-color.sh"
  else
    echo "Generating dark & light color schemes..."
    notify-send "Wallpaper & Theme" "Generating dark & light color schemes…"
    mkdir -p "$CURRENT_WP_CACHE_DIR"

    if command -v wallust &>/dev/null; then
      # 1. Generate Dark mode colors
      wallust run -p dark "$image" --quiet 2>/dev/null || wallust run "$image" 2>/dev/null || true
      sleep 0.2
      mkdir -p "$HOME/.config/scripts/shared"
      cp "$HOME/.config/scripts/shared/dynamic-color.sh" "$CURRENT_WP_CACHE_DIR/dark_colors.sh" 2>/dev/null || true

      # Extract Dark Mode Accent Color (COLOR4 or COLOR6)
      python3 -c "
import re
src = open('$CURRENT_WP_CACHE_DIR/dark_colors.sh').read()
m = re.search(r'COLOR4=[\"\']?(#[A-Fa-f0-9]{6})', src)
accent = m.group(1) if m else '#7aa2f7'
open('$CURRENT_WP_CACHE_DIR/dark_accent.txt', 'w').write(accent)
" 2>/dev/null || echo "#7aa2f7" > "$CURRENT_WP_CACHE_DIR/dark_accent.txt"

      # 2. Generate Light mode colors
      wallust run -p light "$image" --quiet 2>/dev/null || wallust run "$image" 2>/dev/null || true
      sleep 0.2
      cp "$HOME/.config/scripts/shared/dynamic-color.sh" "$CURRENT_WP_CACHE_DIR/light_colors.sh" 2>/dev/null || true

      # Copy active palette mode colors to dynamic-color.sh
      cp "$CURRENT_WP_CACHE_DIR/${PALETTE_MODE}_colors.sh" "$HOME/.config/scripts/shared/dynamic-color.sh" 2>/dev/null || true
    fi
  fi

  # Update all linked apps (including icon theme derived from dark_accent)
  update_apps

  # Check wallpaper brightness — prompt for light mode if very bright
  if [ "${MODE_CHOICE:-}" != "auto" ]; then
    LUMI_MEAN=$(python3 -c "import sys; from PIL import Image, ImageStat; im=Image.open(sys.argv[1]).convert('L'); print(int(ImageStat.Stat(im).mean[0]))" "$image" 2>/dev/null || echo 100)
    if [ "$LUMI_MEAN" -gt 160 ]; then
      touch "$HOME/.cache/quickshell/prompt_light_mode"
    else
      rm -f "$HOME/.cache/quickshell/prompt_light_mode"
    fi
  fi

  notify-send "Wallpaper & Theme" "Theme applied — reloading shell…"

  sleep 0.2
  nohup "$HOME/.config/quickshell/scripts/startup.sh" >/dev/null 2>&1 &
}

## Reapply colors to all apps using the cached wallpaper
reapply_colors() {
  local image
  image=$(cat "$HOME/.cache/quickshell/current_wallpaper" 2>/dev/null)
  if [ -z "$image" ] || [ ! -f "$image" ]; then
    notify-send -u critical "Theme" "No cached wallpaper found."
    exit 1
  fi

  debug "Reapplying colors from: $image"

  get_palette_mode "$image"
  debug "Palette mode: $PALETTE_MODE"

  local wp_hash
  wp_hash=$(md5sum "$image" | awk '{print $1}')
  export CURRENT_WP_CACHE_DIR="$HOME/.cache/wallust_cache/$wp_hash"

  if [ "$REGENERATE" != "true" ] && [ -f "$CURRENT_WP_CACHE_DIR/${PALETTE_MODE}_colors.sh" ]; then
    echo "Using cached colors"
    notify-send "Theme Updated" "Using cached colors ($PALETTE_MODE mode)"
    cp "$CURRENT_WP_CACHE_DIR/${PALETTE_MODE}_colors.sh" "$HOME/.config/scripts/shared/dynamic-color.sh"
  else
    if command -v wallust &>/dev/null; then
      wallust run -p "$PALETTE_MODE" "$image" --quiet 2>/dev/null || wallust run "$image" 2>/dev/null || true
      sleep 0.3
    fi
  fi

  update_apps

  notify-send "Theme Updated" "Switched to $PALETTE_MODE mode — reloading shell…"

  sleep 0.2
  nohup "$HOME/.config/quickshell/scripts/startup.sh" >/dev/null 2>&1 &
}

while [ $# -gt 0 ]; do
  case "$1" in
    --wp-only|--wallpaper-only)
      WP_ONLY=true
      shift
      ;;
    --span)
      SPAN=true
      shift
      ;;
    --no-qs-restart)
      NO_QS_RESTART=true
      shift
      ;;
    --reapply)
      REAPPLY=true
      shift
      ;;
    --regenerate|--force-regenerate|-r)
      REGENERATE=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      export VERBOSE
      shift
      ;;
    *)
      IMAGE_PATH="$1"
      shift
      ;;
  esac
done

# Main logic
if [ "$REAPPLY" = "true" ]; then
  reapply_colors
elif [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
  set_wallpaper "$IMAGE_PATH" "$SPAN"
elif [ -n "$IMAGE_PATH" ] && [ -d "$IMAGE_PATH" ]; then
  IMAGE=$(find "$IMAGE_PATH" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
  if [ -n "$IMAGE" ]; then
    set_wallpaper "$IMAGE" "$SPAN"
  fi
else
  if [ -d "$WALLPAPER_DIR" ] || [ -d "$HOME/wallpaper" ]; then
    IMAGE=$(find "$WALLPAPER_DIR" "$HOME/wallpaper" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)
    if [ -n "$IMAGE" ]; then
      set_wallpaper "$IMAGE" "$SPAN"
    fi
  fi
fi