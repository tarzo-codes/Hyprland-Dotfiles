#!/bin/bash
# Sync quickshell colors to Mako, Vicinae, KDE, GTK, Kvantum & Neovim
# Called automatically by shell.qml / wallpaper_picker.sh whenever theme/colors change.
# Uses a lockfile + atomic writes to prevent corruption on rapid calls.

# Arguments:
# $1 = background hex     $7  = yellow hex
# $2 = surface hex        $8  = blue hex
# $3 = foreground hex     $9  = cyan hex
# $4 = accent hex         $10 = magenta hex
# $5 = red hex            $11 = textMuted hex
# $6 = green hex          $12 = themeName

BG="$1";   SUR="$2";  FG="$3";   ACC_RAW="$4"
RED="$5";  GRN="$6";  YEL="$7";  BLU="$8"
CYN="$9";  MAG="${10}"; MUT="${11}"; THEME="${12}"

# Fallback defaults if args are missing
[ -z "$BG"  ] && BG="#0d0f18";    [ -z "$SUR" ] && SUR="#1e1e2e"
[ -z "$FG"  ] && FG="#c0caf5";    [ -z "$ACC_RAW" ] && ACC_RAW="#7aa2f7"
[ -z "$RED" ] && RED="#f7768e";   [ -z "$GRN" ] && GRN="#9ece6a"
[ -z "$YEL" ] && YEL="#e0af68";   [ -z "$BLU" ] && BLU="#7aa2f7"
[ -z "$CYN" ] && CYN="#7dcfff";   [ -z "$MAG" ] && MAG="#bb9af7"
[ -z "$MUT" ] && MUT="#6D8895"

# Prevent parallel runs stomping on each other
LOCK="/tmp/qs-theme-sync.lock"
exec 9>"$LOCK"
flock -x 9

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r,$g,$b"
}

# ──────────────────────────────────────────────────────────────────────────
# 0. RESOLVE TELA ICON THEME & MATCHING ACCENT COLOR (with Experimental Tint Auto-Ignore Mode)
# ──────────────────────────────────────────────────────────────────────────
ICON_THEME=$(python3 -c "
import os, colorsys
from PIL import Image

wp_path = os.path.expanduser('~/.cache/wallust/current_wallpaper')
if wp_path and os.path.isfile(wp_path):
    try:
        with open(wp_path) as f:
            line = f.read().strip()
            if line and os.path.isfile(line): wp_path = line
    except Exception: pass

if not os.path.isfile(wp_path):
    wp_path = os.path.expanduser('~/.cache/quickshell/current_wallpaper')
    if wp_path and os.path.isfile(wp_path):
        try:
            with open(wp_path) as f:
                line = f.read().strip()
                if line and os.path.isfile(line): wp_path = line
        except Exception: pass

is_light_cache = os.path.expanduser('~/.cache/quickshell/is_light_mode')
if os.path.isfile(is_light_cache):
    with open(is_light_cache) as f:
        is_light_wp = f.read().strip() == 'true'
else:
    is_light_wp = False

ignore_tint_cache = os.path.expanduser('~/.cache/quickshell/ignore_wallpaper_tints')
if os.path.isfile(ignore_tint_cache):
    with open(ignore_tint_cache) as f:
        ignore_tint = f.read().strip() != 'false'
else:
    ignore_tint = True

best_base = 'Tela-blue'

if wp_path and os.path.isfile(wp_path):
    try:
        im = Image.open(wp_path).convert('RGB')
        im_small = im.resize((150, 150))
        colors = im_small.getcolors(30000)
        
        total_px = sum(c for c, _ in colors) if colors else 1
        r_mean = sum(c * r for c, (r, g, b) in colors) / total_px if colors else 128
        g_mean = sum(c * g for c, (r, g, b) in colors) / total_px if colors else 128
        b_mean = sum(c * b for c, (r, g, b) in colors) / total_px if colors else 128
        k_mean = (r_mean + g_mean + b_mean) / 3.0

        avg_luma = sum(c * (0.299*r + 0.587*g + 0.114*b) for c, (r, g, b) in colors) / (total_px * 255.0) if colors else 0.5
        avg_sat = sum(c * ((max(r,g,b) - min(r,g,b)) / (max(r,g,b) if max(r,g,b)>0 else 1)) for c, (r, g, b) in colors) / total_px if colors else 0.0

        # Statistical Color Cast Index (Gray-World Matrix Distance)
        cast_index = ((r_mean - k_mean)**2 + (g_mean - k_mean)**2 + (b_mean - k_mean)**2)**0.5
        is_tinted = (cast_index > 10.0) and (avg_sat < 0.48)

        r_factor = (k_mean / r_mean) if (is_tinted and ignore_tint and r_mean > 0) else 1.0
        g_factor = (k_mean / g_mean) if (is_tinted and ignore_tint and g_mean > 0) else 1.0
        b_factor = (k_mean / b_mean) if (is_tinted and ignore_tint and b_mean > 0) else 1.0

        if avg_luma > 0.50:
            is_light_wp = True
            with open(os.path.expanduser('~/.cache/quickshell/is_light_mode'), 'w') as f:
                f.write('true')
        else:
            with open(os.path.expanduser('~/.cache/quickshell/is_light_mode'), 'w') as f:
                f.write('false')

        hue_scores = {
            'Tela-red': 0.0, 'Tela-pink': 0.0, 'Tela-ubuntu': 0.0,
            'Tela-orange': 0.0, 'Tela-yellow': 0.0, 'Tela-green': 0.0,
            'Tela-manjaro': 0.0, 'Tela-nord': 0.0, 'Tela-blue': 0.0,
            'Tela-dracula': 0.0, 'Tela-purple': 0.0, 'Tela-brown': 0.0,
            'Tela-grey': 0.0, 'Tela-black': 0.0
        }
        
        if colors:
            for count, (r, g, b) in colors:
                if is_tinted and ignore_tint:
                    r_norm = min(255, max(0, int(r * r_factor)))
                    g_norm = min(255, max(0, int(g * g_factor)))
                    b_norm = min(255, max(0, int(b * b_factor)))
                else:
                    r_norm, g_norm, b_norm = r, g, b

                h, s, v = colorsys.rgb_to_hsv(r_norm/255.0, g_norm/255.0, b_norm/255.0)
                luma = 0.299*(r_norm/255.0) + 0.587*(g_norm/255.0) + 0.114*(b_norm/255.0)
                deg = h * 360.0

                if s >= 0.06 and 0.05 <= luma <= 0.95:
                    weight = count * (s ** 1.8)

                    if deg >= 345 or deg < 12:
                        if s > 0.35 and luma < 0.60: hue_scores['Tela-red'] += weight * 1.5
                        else: hue_scores['Tela-pink'] += weight * 1.5
                    elif 12 <= deg < 28:
                        hue_scores['Tela-ubuntu'] += weight * 1.5
                        hue_scores['Tela-orange'] += weight
                    elif 28 <= deg < 48:
                        hue_scores['Tela-orange'] += weight * 1.5
                        hue_scores['Tela-ubuntu'] += weight * 0.8
                    elif 48 <= deg < 70: hue_scores['Tela-yellow'] += weight * 1.5
                    elif 70 <= deg < 140: hue_scores['Tela-green'] += weight * 1.5
                    elif 140 <= deg < 175: hue_scores['Tela-manjaro'] += weight * 1.5
                    elif 175 <= deg < 205:
                        hue_scores['Tela-nord'] += weight * 1.4
                        hue_scores['Tela-blue'] += weight * 0.8
                    elif 205 <= deg < 255: hue_scores['Tela-blue'] += weight * 1.4
                    elif 255 <= deg < 285: hue_scores['Tela-dracula'] += weight * 1.5
                    elif 285 <= deg < 345: hue_scores['Tela-purple'] += weight * 1.5

        colorful_scores = {k: v for k, v in hue_scores.items() if k not in ['Tela-grey', 'Tela-black', 'Tela-brown']}
        top_color = max(colorful_scores.items(), key=lambda x: x[1])

        if is_light_wp:
            if top_color[1] > 0.15:
                best_base = top_color[0]
            else:
                best_base = 'Tela-nord' if avg_luma > 0.70 else 'Tela-blue'
        else:
            if top_color[1] > 0.15:
                best_base = top_color[0]
            elif avg_sat < 0.10:
                best_base = 'Tela-black' if avg_luma < 0.30 else 'Tela-grey'
            else:
                best_base = max(hue_scores.items(), key=lambda x: x[1])[0]
    except Exception:
        pass

suffix = '-light' if is_light_wp else '-dark'
candidate = f'{best_base}{suffix}'
icon_dirs = [os.path.expanduser(f'~/.local/share/icons/{candidate}'), f'/usr/share/icons/{candidate}']
if any(os.path.isdir(d) for d in icon_dirs):
    print(candidate)
else:
    print(best_base)
")

# Resolve Icon Accent Color matching Tela Icon Theme
ICON_ACCENT=$(python3 -c "
icon_theme = '$ICON_THEME'
base = icon_theme.replace('-light','').replace('-dark','')
accents = {
    'Tela-blue': '#3584e4',
    'Tela-nord': '#5e81ac',
    'Tela-manjaro': '#16a085',
    'Tela-green': '#2ecc71',
    'Tela-yellow': '#f39c12',
    'Tela-orange': '#e67e22',
    'Tela-ubuntu': '#e95420',
    'Tela-red': '#e74c3c',
    'Tela-pink': '#ec407a',
    'Tela-purple': '#9b59b6',
    'Tela-dracula': '#bd93f9',
    'Tela-brown': '#8d6e63',
    'Tela-grey': '#787c99',
    'Tela-black': '#555b6e'
}
print(accents.get(base, '#3584e4'))
")

# Set primary accent to ICON_ACCENT so Mako, Dolphin, Vicinae & Kvantum match icon theme!
ACC="$ICON_ACCENT"
ACC_RGB=$(hex_to_rgb "$ACC")
BG_HEX="${BG#\#}"

# Apply GTK & KDE Icon Theme
[ -f "$HOME/.config/gtk-3.0/settings.ini" ] && sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
[ -f "$HOME/.config/gtk-4.0/settings.ini" ] && sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" 2>/dev/null

# Update xsettingsd if running
if [ -f "$HOME/.config/xsettingsd/xsettingsd.conf" ]; then
    sed -i "s#^Net/IconThemeName.*#Net/IconThemeName \"$ICON_THEME\"#g" "$HOME/.config/xsettingsd/xsettingsd.conf"
    pkill -HUP xsettingsd 2>/dev/null || true
fi

# ──────────────────────────────────────────────────────────────────────────
# 1. Update Mako Configuration with Matching Icon Accent Border
# ──────────────────────────────────────────────────────────────────────────
MAKO_CONF="$HOME/.config/mako/config"
MAKO_TMP="$(mktemp)"

cat <<EOF > "$MAKO_TMP"
# Take a look at the mako manpage with the command:
#   man 5 mako
# Automatically generated by quickshell theme sync — do not hand-edit.

font=JetBrains Mono Nerd Font 11
format=<b>%a ⏵</b> %s\n%b
sort=-time
layer=overlay
anchor=top-center
width=500
height=50
margin=5
padding=8,12,12
border-size=2
icons=1
max-icon-size=20
default-timeout=5000
ignore-timeout=1

# System Colors (synced from icon accent: $ACC)
background-color=#${BG_HEX}dd
text-color=$FG
border-color=$ACC
border-radius=12

[urgency=normal]
border-color=$ACC

[urgency=high]
border-color=$RED
default-timeout=0

[app-name=lightcord]
border-color=$MUT

[summary~="log-.*"]
border-color=$SUR
EOF

mv -f "$MAKO_TMP" "$MAKO_CONF"
makoctl reload 2>/dev/null

# ──────────────────────────────────────────────────────────────────────────
# 2. Update Vicinae Theme (atomic write via temp file)
# ──────────────────────────────────────────────────────────────────────────
VICINAE_THEME_DIR="$HOME/.local/share/vicinae/themes"
mkdir -p "$VICINAE_THEME_DIR"
VICINAE_TMP="$(mktemp)"

cat <<EOF > "$VICINAE_TMP"
# Automatically generated by quickshell theme sync — do not hand-edit.
[meta]
name = "Custom theme"
description = "Synchronized with quickshell theme: $THEME"
variant = "dark"
inherits = "vicinae-dark"

[colors.core]
accent             = "$ACC"
accent_foreground  = "$BG"
background         = "$BG"
foreground         = "$FG"
secondary_background = "$SUR"
border             = "$SUR"

[colors.main_window]
border = "$SUR"
footer = { background = "colors.core.secondary_background" }

[colors.settings_window]
border = "$SUR"

[colors.accents]
blue    = "$BLU"
green   = "$GRN"
magenta = "$MAG"
orange  = "$YEL"
red     = "$RED"
yellow  = "$YEL"
cyan    = "$CYN"
purple  = "$MAG"

[colors.shortcut]
border = "$SUR"
EOF

mv -f "$VICINAE_TMP" "$VICINAE_THEME_DIR/custom.toml"
vicinae theme set custom 2>/dev/null

# ──────────────────────────────────────────────────────────────────────────
# 3. Update Neovim Theme & Live Reload Active Neovim Instances
# ──────────────────────────────────────────────────────────────────────────
NVIM_THEME_DIR="$HOME/dotfiles/config/nvim/lua/generated"
mkdir -p "$NVIM_THEME_DIR"
NVIM_TMP="$(mktemp)"

IS_LIGHT=false
if [ -f "$HOME/.cache/quickshell/is_light_mode" ] && [ "$(cat "$HOME/.cache/quickshell/is_light_mode" 2>/dev/null)" = "true" ]; then
    IS_LIGHT=true
fi

python3 -c "
import os, colorsys

is_light = '$IS_LIGHT' == 'true'
bg = '$BG'
fg = '$FG'
acc = '$ACC'
red = '$RED'
grn = '$GRN'
yel = '$YEL'
blu = '$BLU'
cyn = '$CYN'
mag = '$MAG'
mut = '$MUT'

def hex_to_rgb(h):
    s = h.lstrip('#')
    if len(s) != 6: return (0,0,0)
    return int(s[0:2],16)/255, int(s[2:4],16)/255, int(s[4:6],16)/255

def luma(h):
    r, g, b = hex_to_rgb(h)
    def lin(c): return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
    return 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b)

def contrast_ratio(a, b_col):
    la, lb = luma(a)+0.05, luma(b_col)+0.05
    return max(la, lb) / min(la, lb)

def ensure_contrast(hex_col, bg_col, min_ratio=4.5):
    r, g, b = hex_to_rgb(hex_col)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    is_bg_light = luma(bg_col) > 0.50
    curr_col = hex_col
    step = -0.04 if is_bg_light else 0.04
    for _ in range(25):
        if contrast_ratio(curr_col, bg_col) >= min_ratio:
            break
        l = max(0.05, min(0.95, l + step))
        r_new, g_new, b_new = colorsys.hls_to_rgb(h, l, s)
        curr_col = '#{:02X}{:02X}{:02X}'.format(int(r_new*255), int(g_new*255), int(b_new*255))
    return curr_col

if is_light:
    bg_out   = bg if luma(bg) >= 0.85 else '#f8fafc'
    fg_out   = '#0f172a'
    sur_out  = '#e2e8f0'
    comment  = ensure_contrast(mut if mut != bg else '#57606a', bg_out, 4.5)
    keyword  = ensure_contrast(yel, bg_out, 4.5)
    func     = ensure_contrast(blu, bg_out, 4.5)
    string   = ensure_contrast(grn, bg_out, 4.5)
    type_col = ensure_contrast(cyn, bg_out, 4.5)
    ret_col  = ensure_contrast(mag, bg_out, 4.5)
    param    = ensure_contrast(red, bg_out, 4.5)
    acc_out  = ensure_contrast(acc, bg_out, 4.5)
    error    = ensure_contrast(red, bg_out, 4.5)
else:
    bg_out   = bg
    fg_out   = '#f8fafc'
    sur_out  = '#282c37'
    comment  = ensure_contrast(mut if mut != bg else '#8b949e', bg_out, 4.5)
    keyword  = ensure_contrast(yel, bg_out, 4.5)
    func     = ensure_contrast(blu, bg_out, 4.5)
    string   = ensure_contrast(grn, bg_out, 4.5)
    type_col = ensure_contrast(cyn, bg_out, 4.5)
    ret_col  = ensure_contrast(mag, bg_out, 4.5)
    param    = ensure_contrast(red, bg_out, 4.5)
    acc_out  = ensure_contrast(acc, bg_out, 4.5)
    error    = ensure_contrast(red, bg_out, 4.5)

theme_content = f'''-- Automatically generated by quickshell theme sync for theme: $THEME
return {{
    base00 = \"{bg_out}\",
    base01 = \"{bg_out}\",
    base02 = \"{sur_out}\",
    base03 = \"{comment}\",
    base04 = \"{fg_out}\",
    base05 = \"{fg_out}\",
    base06 = \"{keyword}\",
    base07 = \"{fg_out}\",
    base08 = \"{param}\",
    base09 = \"{ret_col}\",
    base0A = \"{keyword}\",
    base0B = \"{acc_out}\",
    base0C = \"{type_col}\",
    base0D = \"{func}\",
    base0E = \"{ret_col}\",
    base0F = \"{error}\",

    bg             = \"{bg_out}\",
    fg             = \"{fg_out}\",
    error          = \"{error}\",
    keyword        = \"{keyword}\",
    keyword_return = \"{ret_col}\",
    func           = \"{func}\",
    string         = \"{string}\",
    number         = \"{keyword}\",
    type           = \"{type_col}\",
    comment        = \"{comment}\",
    parameter      = \"{param}\",
    property       = \"{type_col}\",
    operator       = \"{fg_out}\",
    bracket        = \"{fg_out}\",
    builtin        = \"{keyword}\",
}}
'''

with open('$NVIM_TMP', 'w') as f:
    f.write(theme_content)
"

mv -f "$NVIM_TMP" "$NVIM_THEME_DIR/theme.lua"
mkdir -p "$HOME/.config/nvim/lua/generated"
cp -f "$NVIM_THEME_DIR/theme.lua" "$HOME/.config/nvim/lua/generated/theme.lua"

for socket in /tmp/nvim*/* /run/user/1000/nvim*/* /run/user/1000/nvim.*; do
    if [ -S "$socket" ]; then
        nvim --server "$socket" --remote-send "<Cmd>lua if pcall(require, 'neopywal') then require('neopywal').setup(); vim.cmd('colorscheme neopywal') end<CR>" 2>/dev/null &
    fi
done

# ──────────────────────────────────────────────────────────────────────────
# 4. Update KDE & Dolphin Accent Scheme
# ──────────────────────────────────────────────────────────────────────────
KDE_SCHEME_DIR="$HOME/.local/share/color-schemes"
mkdir -p "$KDE_SCHEME_DIR"

BG_RGB=$(hex_to_rgb "$BG")
SUR_RGB=$(hex_to_rgb "$SUR")
FG_RGB=$(hex_to_rgb "$FG")

if [ "$IS_LIGHT" = "true" ]; then
    GTK_THEME="Breeze"
    PREFER_DARK="false"
    GSETTINGS_SCHEME="prefer-light"
    KDE_LOOKANDFEEL="org.kde.breeze.desktop"
    INACT_RGB=$(hex_to_rgb "#475569")
else
    GTK_THEME="Breeze-Dark"
    PREFER_DARK="true"
    GSETTINGS_SCHEME="prefer-dark"
    KDE_LOOKANDFEEL="org.kde.breezedark.desktop"
    INACT_RGB="220,225,245"
fi

KDE_TMP="$(mktemp)"
cat <<EOF > "$KDE_TMP"
[General]
ColorScheme=FluxDots
Name=FluxDots
accentColor=$ACC_RGB
LastUsedCustomAccentColor=$ACC_RGB

[Icons]
Theme=$ICON_THEME

[UiSettings]
ColorScheme=FluxDots

[KDE]
LookAndFeelPackage=$KDE_LOOKANDFEEL
contrast=7

[Colors:Window]
BackgroundNormal=$BG_RGB
ForegroundNormal=$FG_RGB
BackgroundAlternate=$SUR_RGB
ForegroundInactive=$INACT_RGB
ForegroundActive=$ACC_RGB

[Colors:View]
BackgroundNormal=$BG_RGB
ForegroundNormal=$FG_RGB
BackgroundAlternate=$SUR_RGB
ForegroundInactive=$INACT_RGB
ForegroundActive=$ACC_RGB

[Colors:Button]
BackgroundNormal=$SUR_RGB
ForegroundNormal=$FG_RGB
BackgroundAlternate=$BG_RGB
ForegroundInactive=$INACT_RGB

[Colors:Selection]
BackgroundNormal=$ACC_RGB
ForegroundNormal=255,255,255
BackgroundAlternate=$ACC_RGB
ForegroundInactive=255,255,255

[Colors:Header]
BackgroundNormal=$BG_RGB
ForegroundNormal=$FG_RGB

[Colors:Tooltip]
BackgroundNormal=$SUR_RGB
ForegroundNormal=$FG_RGB

[Colors:Complementary]
BackgroundNormal=$BG_RGB
ForegroundNormal=$FG_RGB
BackgroundAlternate=$SUR_RGB
ForegroundInactive=$INACT_RGB
ForegroundActive=$ACC_RGB

[WM]
activeBackground=$BG_RGB
activeBlend=$BG_RGB
activeForeground=$FG_RGB
inactiveBackground=$BG_RGB
inactiveBlend=$BG_RGB
inactiveForeground=$INACT_RGB
EOF

mv -f "$KDE_TMP" "$KDE_SCHEME_DIR/FluxDots.colors"
cp -f "$KDE_SCHEME_DIR/FluxDots.colors" "$HOME/.config/kdeglobals"
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "FluxDots" 2>/dev/null
kwriteconfig6 --file kdeglobals --group General --key accentColor "$ACC_RGB" 2>/dev/null
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor "$ACC_RGB" 2>/dev/null
plasma-apply-colorscheme FluxDots 2>/dev/null || true
kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme "FluxDots" 2>/dev/null

if [ "$IS_LIGHT" = "true" ]; then
    kwriteconfig6 --file plasmarc --group Theme --key name breeze 2>/dev/null
else
    kwriteconfig6 --file plasmarc --group Theme --key name breeze-dark 2>/dev/null
fi

# Notify KDE & Dolphin of accent change
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true

# ──────────────────────────────────────────────────────────────────────────
# 5. Update Kvantum Theme (FluxDots) with Matching Icon Accent
# ──────────────────────────────────────────────────────────────────────────
KVANTUM_DIR="$HOME/.config/Kvantum/FluxDots"
mkdir -p "$KVANTUM_DIR"

cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=FluxDots
EOF

KV_TMP="$(mktemp)"
cat <<EOF > "$KV_TMP"
[General]
author=FluxDots
comment="Dynamic Kvantum theme for Wallust & Quickshell static themes ($THEME)"

[Applications]
Default=FluxDots

[GeneralColors]
window.color=$BG
window.text.color=$FG
base.color=$SUR
alt.base.color=$SUR
text.color=$FG
highlight.color=$ACC
highlight.text.color=#FFFFFF
button.color=$SUR
button.text.color=$FG
tooltip.color=$SUR
tooltip.text.color=$FG
inactive.window.color=$BG
inactive.text.color=$FG
EOF

mv -f "$KV_TMP" "$KVANTUM_DIR/FluxDots.kvconfig"

# ──────────────────────────────────────────────────────────────────────────
# 6. Update GTK 3/4 & System-wide XDG Desktop Portal Color Scheme (Zen Browser, Firefox, Dolphin, Electron)
# ──────────────────────────────────────────────────────────────────────────
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "$GSETTINGS_SCHEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
fi

# Update GTK 3.0 settings.ini
mkdir -p "$HOME/.config/gtk-3.0"
cat <<EOF > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-cursor-theme-name=Breeze_Snow
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=$PREFER_DARK
EOF

# Update GTK 4.0 settings.ini
mkdir -p "$HOME/.config/gtk-4.0"
cat <<EOF > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-cursor-theme-name=Breeze_Snow
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$PREFER_DARK
EOF

# Broadcast XDG Desktop Portal settings update over DBus to Zen Browser, Firefox & Electron apps
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings ReadOne ss "org.freedesktop.appearance" "color-scheme" 2>/dev/null || true

if command -v hyprctl &>/dev/null && [ -n "${ACC:-}" ]; then
  ACC_STRIPPED="${ACC#\#}"
  SUR_STRIPPED="${SUR#\#}"
  BG_STRIPPED="${BG#\#}"
  hyprctl keyword "general:col.active_border" "rgba(${ACC_STRIPPED}ff) rgba(${SUR_STRIPPED}ff) 45deg" 2>/dev/null || true
  hyprctl keyword "general:col.inactive_border" "rgba(${BG_STRIPPED}ff)" 2>/dev/null || true
fi

notify-send -a "Quickshell" -i "preferences-desktop-icons" "Icon & Theme Accent Synced" "Icon: $ICON_THEME | Accent: $ACC" 2>/dev/null || true
echo "[Quickshell] Icon theme updated to: $ICON_THEME (Accent: $ACC)"
