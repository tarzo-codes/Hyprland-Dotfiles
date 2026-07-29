#!/bin/bash
source $HOME/.config/scripts/shared/dynamic-color.sh

# Step 2: Get the main accent color from wallust
ACCENT_COLOR=$COLOR4
echo "Accent Color (raw): $ACCENT_COLOR"

# Step 2.5: Strip #
STRIPPED=$(echo "$ACCENT_COLOR" | tr -d '#')
echo "Accent Color (stripped): $STRIPPED"

# Step 3: Map color to closest Tela variant
declare -A color_map=(
  ["blue"]="0000FF"
  ["red"]="FF0000"
  ["green"]="00FF00"
  ["purple"]="800080"
  ["orange"]="FFA500"
  ["pink"]="FFC0CB"
  ["yellow"]="FFFF00"
  ["manjaro"]="008080"
  ["grey"]="808080"
)

function hex_distance() {
  local h1=$1
  local h2=$2
  local r1=$((16#${h1:0:2}))
  local g1=$((16#${h1:2:2}))
  local b1=$((16#${h1:4:2}))
  local r2=$((16#${h2:0:2}))
  local g2=$((16#${h2:2:2}))
  local b2=$((16#${h2:4:2}))
  echo $(( (r1 - r2)**2 + (g1 - g2)**2 + (b1 - b2)**2 ))
}

# Step 4: Find closest match
closest=""
min_dist=1000000
for name in "${!color_map[@]}"; do
  dist=$(hex_distance "$STRIPPED" "${color_map[$name]}")
  if (( dist < min_dist )); then
    min_dist=$dist
    closest=$name
  fi
done

echo "Closest match: $closest"

# Step 5: Set icon theme
ICON_THEME="Tela-$closest"
echo "Setting icon theme to: $ICON_THEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"

# Optional: verify it's set
echo "Current icon theme: $(gsettings get org.gnome.desktop.interface icon-theme)"
