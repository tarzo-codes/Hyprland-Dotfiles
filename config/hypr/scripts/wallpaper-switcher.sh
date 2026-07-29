#!/bin/bash

# Wallpaper switcher script with waypaper integration
# Opens waypaper GUI to select wallpaper, then applies colors and reloads all components
# Usage: wallpaper-switcher [--verbose]

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
TELA_BASE="Tela"
VERBOSE="${VERBOSE:-false}"

# Debug output function
debug() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[DEBUG] $1"
  fi
}

# Color name mapping for Tela variants
declare -A TELA_COLORS
TELA_COLORS=(
  ["Tela"]="#5297e0"
  ["Tela-blue"]="#5297e0"
  ["Tela-green"]="#4caf50"
  ["Tela-red"]="#e53935"
  ["Tela-purple"]="#9c27b0"
  ["Tela-pink"]="#e91e63"
  ["Tela-orange"]="#ff9800"
  ["Tela-yellow"]="#ffeb3b"
  ["Tela-brown"]="#795548"
  ["Tela-grey"]="#607d8b"
  ["Tela-black"]="#212121"
  ["Tela-dracula"]="#bd93f9"
  ["Tela-nord"]="#88c0d0"
  ["Tela-manjaro"]="#16a085"
  ["Tela-ubuntu"]="#e95420"
)

# Find the closest Tela icon theme based on a hex color
find_closest_tela() {
  local target_color="$1"
  local best_match="Tela"
  local best_distance=999999

  target_color="${target_color#\#}"

  local tr=$((16#${target_color:0:2}))
  local tg=$((16#${target_color:2:2}))
  local tb=$((16#${target_color:4:2}))

  for theme in "${!TELA_COLORS[@]}"; do
    local theme_color="${TELA_COLORS[$theme]}"
    theme_color="${theme_color#\#}"

    local mr=$((16#${theme_color:0:2}))
    local mg=$((16#${theme_color:2:2}))
    local mb=$((16#${theme_color:4:2}))

    local dr=$((tr - mr))
    local dg=$((tg - mg))
    local db=$((tb - mb))
    local distance=$((dr * dr + dg * dg + db * db))

    if ((distance < best_distance)); then
      best_distance=$distance
      best_match="$theme"
    fi
  done

  debug "Closest Tela theme: $best_match (distance: $best_distance)"
  echo "$best_match"
}

# Set GTK and Qt icon theme
set_icon_theme() {
  local icon_theme="$1"

  debug "Setting icon theme to: $icon_theme"

  # GTK settings
  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
  fi

  # GTK3 settings.ini
  local gtk3_config="$HOME/.config/gtk-3.0/settings.ini"
  if [ -f "$gtk3_config" ]; then
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$gtk3_config"
  fi

  # GTK4 settings.ini
  local gtk4_config="$HOME/.config/gtk-4.0/settings.ini"
  if [ -f "$gtk4_config" ]; then
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$gtk4_config"
  fi

  # Qt/KDE config
  local kde_config="$HOME/.config/kdeglobals"
  if [ -f "$kde_config" ]; then
    sed -i "s/^IconTheme=.*/IconTheme=$icon_theme/" "$kde_config"
  fi

  # xsettingsd for live Qt/GTK sync
  local xsettingsd_config="$HOME/.config/xsettingsd/xsettingsd.conf"
  if [ -f "$xsettingsd_config" ]; then
    sed -i "s#^Net/IconThemeName.*#Net/IconThemeName \"$icon_theme\"#g" "$xsettingsd_config"
    if command -v xsettingsd &>/dev/null; then
      pkill xsettingsd 2>/dev/null || true
      sleep 0.1
      xsettingsd -c "$xsettingsd_config" 2>/dev/null &
    fi
  fi

  if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -q "$HOME/.local/share/icons/$icon_theme" 2>/dev/null || true
  fi

  notify-send "Icon Theme" "Set to $icon_theme"
}

# Apply wallpaper and update all components
apply_wallpaper_and_colors() {
  local image="$1"

  if [ ! -f "$image" ]; then
    return 1
  fi

  debug "Applying wallpaper and colors: $image"

  # Set wallpaper
  if command -v awww &>/dev/null; then
    debug "Using awww for wallpaper"
    awww img "$image"
  elif command -v swww &>/dev/null; then
    debug "Using swww for wallpaper"
    swww img "$image" --transition-fps 60 --transition-type random
  else
    debug "No wallpaper backend found"
  fi

  # Run wallust to generate colors
  if command -v wallust &>/dev/null; then
    debug "Running wallust..."
    wallust run "$image" --quiet 2>/dev/null || wallust run "$image" 2>/dev/null || true
    sleep 0.5
  else
    debug "wallust not found"
  fi

  # Source dynamic colors for Tela icon matching and Hyprland colors
  local color_script="$HOME/.config/scripts/shared/dynamic-color.sh"
  if [ -f "$color_script" ]; then
    debug "Sourcing color script: $color_script"
    # shellcheck source=/dev/null
    source "$color_script"
    ACCENT_COLOR="${COLOR4:-}"
    debug "Accent color: $ACCENT_COLOR"

    if [ -n "$ACCENT_COLOR" ]; then
      BEST_TELA=$(find_closest_tela "$ACCENT_COLOR")
      set_icon_theme "$BEST_TELA"
    fi

    # Apply Hyprland colors directly using hyprctl keyword
    if command -v hyprctl &>/dev/null && [ -n "$COLOR6" ]; then
      COLOR6_STRIPPED="${COLOR6#\#}"
      COLOR0_STRIPPED="${COLOR0#\#}"
      debug "Applying Hyprland border colors: active=${COLOR6_STRIPPED}, inactive=${COLOR0_STRIPPED}"
      hyprctl keyword "general:col.active_border" "rgba(${COLOR6_STRIPPED}ff)" 2>/dev/null || true
      hyprctl keyword "general:col.inactive_border" "rgba(${COLOR0_STRIPPED}ff)" 2>/dev/null || true
    fi
  else
    debug "Color script not found: $color_script"
  fi

  # Reload quickshell to pick up new colors
  debug "Reloading quickshell..."
  pkill -x quickshell 2>/dev/null || true
  sleep 0.3
  if command -v quickshell &>/dev/null; then
    quickshell 2>/dev/null &
    debug "quickshell restarted"
  else
    debug "quickshell not found"
  fi

  # Refresh kitty colors
  if command -v kitty &>/dev/null; then
    debug "Refreshing kitty colors..."
    kitty @ set-colors --all --configured "$HOME/.config/kitty/wallust.conf" 2>/dev/null || true
  fi
  if command -v openrgb &> /dev/null; then
    debug "Refreshing rgb colors..."
    OPENRGB_COLORS=$(cat $HOME/.config/openrgb.txt)
    OPENRGB_COLORS=${OPENRGB_COLORS#"#"}
    openrgb -c $OPENRGB_COLORS 2>/dev/null || true
  fi



  notify-send "Wallpaper" "Changed with wallust colors"
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      export VERBOSE
      shift
      ;;
    *)
      shift
      ;;
  esac
done

  # Main logic - run waypaper first
if command -v waypaper &>/dev/null; then
  debug "Running waypaper..."
  waypaper 2>/dev/null &
  WAYPAPER_PID=$!
  wait $WAYPAPER_PID 2>/dev/null || true
  
    # Read waypaper config.ini to get selected wallpaper
  WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
  if [ -f "$WAYPAPER_CONFIG" ]; then
    debug "Reading waypaper config..."
    SELECTED_WALLPAPER=$(grep "^wallpaper = " "$WAYPAPER_CONFIG" | head -1 | cut -d'=' -f2 | sed 's/^ *//;s|~/|'"$HOME/"'|g')
    if [ -n "$SELECTED_WALLPAPER" ] && [ -f "$SELECTED_WALLPAPER" ]; then
      debug "Selected wallpaper: $SELECTED_WALLPAPER"
      apply_wallpaper_and_colors "$SELECTED_WALLPAPER"
    else
      debug "No wallpaper selected or file not found: $SELECTED_WALLPAPER"
    fi
  else
    debug "Waypaper config not found at $WAYPAPER_CONFIG"
  fi
else
  debug "waypaper not found, using random wallpaper"
  if [ -d "$WALLPAPER_DIR" ]; then
    IMAGE=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
    if [ -n "$IMAGE" ]; then
      apply_wallpaper_and_colors "$IMAGE"
    else
      debug "No wallpapers found in $WALLPAPER_DIR"
    fi
  else
    debug "Wallpaper directory not found: $WALLPAPER_DIR"
  fi
fi
