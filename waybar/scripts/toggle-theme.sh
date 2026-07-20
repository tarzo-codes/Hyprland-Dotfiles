#!/bin/bash
# Waybar theme switcher - applies style variations while using wallust colors
# Usage: toggle-theme.sh [next|prev|random|reload|clear|theme-name]

THEME="${1:-random}"
THEME_CACHE="$HOME/.config/waybar/.current-theme"
STYLE_FILE="$HOME/.config/waybar/theme-override.css"

# Available theme style variations
get_theme_list() {
    echo -e "default\nglass\nminimal\nretro\ncyber"
}

get_current_theme() {
    if [ -f "$THEME_CACHE" ]; then
        cat "$THEME_CACHE"
    else
        echo "default"
    fi
}

reload_waybar() {
    if pgrep -x waybar >/dev/null 2>&1; then
        killall -q waybar 2>/dev/null || true
        sleep 0.3
        waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    fi
}

set_theme() {
    local name="$1"
    
    case "$name" in
        glass)
            # Glass theme - semi-transparent elements using wallust colors
            cat > "$STYLE_FILE" << 'EOF'
/* Glass theme - semi-transparent overlays */
@define-color bgAlt-transparent rgba(0, 0, 0, 0.4);
@define-color accent-transparent rgba(122, 162, 247, 0.6);
@define-color surface-transparent rgba(0, 0, 0, 0.2);
EOF
            ;;
        minimal)
            # Minimal theme - clean look with wallust colors
            cat > "$STYLE_FILE" << 'EOF'
/* Minimal theme - simple styling with wallust colors */
@define-color bgAlt-transparent @bgAlt;
@define-color accent-transparent @accent;
@define-color surface-transparent rgba(0, 0, 0, 0.3);
EOF
            ;;
        neon)
            # Neon theme - dark background with bright accent
            cat > "$STYLE_FILE" << 'EOF'
/* Neon theme - dark with bright cyan accent */
@define-color bgAlt-transparent rgba(13, 13, 26, 0.7);
@define-color accent-transparent #00f5ff;
@define-color surface-transparent rgba(26, 26, 48, 0.5);
EOF
            ;;
        retro)
            # Retro theme - warm tones
            cat > "$STYLE_FILE" << 'EOF'
/* Retro theme - warm styling */
@define-color bgAlt-transparent rgba(26, 10, 46, 0.6);
@define-color accent-transparent #ff6b6b;
@define-color surface-transparent rgba(26, 10, 46, 0.4);
EOF
            ;;
        cyber)
            # Cyber theme - matrix green
            cat > "$STYLE_FILE" << 'EOF'
/* Cyber theme - matrix green styling */
@define-color bgAlt-transparent rgba(0, 0, 0, 0.5);
@define-color accent-transparent rgba(0, 255, 65, 0.8);
@define-color surface-transparent rgba(0, 0, 0, 0.4);
EOF
            ;;
        *)
            # Default - clean look, reset to wallust
            rm -f "$STYLE_FILE"
            ;;
    esac
    
    echo "$name" > "$THEME_CACHE"
    reload_waybar
    notify-send "Waybar Theme" "Switched to: $name"
}

case "$THEME" in
    next|prev)
        current=$(get_current_theme)
        mapfile -t list < <(get_theme_list)
        idx=-1
        for i in "${!list[@]}"; do
            if [ "${list[$i]}" = "$current" ]; then
                idx=$i
                break
            fi
        done
        
        if [ "$THEME" = "next" ]; then
            idx=$(( (idx + 1) % ${#list[@]} ))
        else
            idx=$(( (idx - 1 + ${#list[@]} ) % ${#list[@]} ))
        fi
        
        set_theme "${list[$idx]}"
        ;;
    random)
        mapfile -t list < <(get_theme_list)
        rand_idx=$(( RANDOM % ${#list[@]} ))
        set_theme "${list[$rand_idx]}"
        ;;
    reload)
        reload_waybar
        notify-send "Waybar" "Reloaded with current colors"
        ;;
    clear)
        rm -f "$STYLE_FILE"
        echo "default" > "$THEME_CACHE"
        reload_waybar
        notify-send "Waybar Theme" "Cleared, using wallust colors"
        ;;
    *)
        set_theme "$THEME"
        ;;
esac