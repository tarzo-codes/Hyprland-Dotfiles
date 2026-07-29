#!/usr/bin/env bash
#  ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ 
#  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
#  ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
#  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
#  ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
#  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ 
#
#  Hyprland 0.56.1 Lua + Quickshell Dotfiles TUI Installer
#  Repository: https://github.com/tarzo-codes/Hyprland-Dotfiles
#  Author: tarzo-codes

set -e

# --- Color Definitions ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

BACKUP_ROOT="$HOME/.config/hypr_dotfiles_backups"

log_info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# --- Pre-flight Checks ---
preflight_checks() {
    if [ "$(id -u)" -eq 0 ]; then
        log_error "This script must NOT be run as root."
        exit 1
    fi

    if ! command -v pacman &>/dev/null; then
        log_error "pacman not found. Arch Linux or CachyOS required."
        exit 1
    fi

    AUR_HELPER=""
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    fi
}

# --- TUI Dialog Helpers ---
tui_msg() {
    local title="$1"
    local text="$2"
    if command -v whiptail &>/dev/null; then
        whiptail --title "$title" --msgbox "$text" 12 65
    else
        echo -e "\n${BOLD}${CYAN}=== $title ===${RESET}\n$text\n"
        read -rp "Press Enter to continue..."
    fi
}

tui_yesno() {
    local title="$1"
    local text="$2"
    if command -v whiptail &>/dev/null; then
        whiptail --title "$title" --yesno "$text" 10 65
    else
        read -rp "$text [y/N]: " yn
        [[ "$yn" =~ ^[Yy]$ ]]
    fi
}

# --- Backup Support ---
create_backup() {
    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    TARGET_BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$TARGET_BACKUP_DIR"

    CONFIG_DIR="$HOME/.config"
    BACKUP_DIRS=(
        hypr
        quickshell
        scripts
        fish
        fastfetch
        btop
        kitty
        wallust
        nvim
    )

    MANIFEST_FILE="$TARGET_BACKUP_DIR/manifest.txt"
    echo "Backup Timestamp: $(date)" > "$MANIFEST_FILE"
    echo "User: $USER" >> "$MANIFEST_FILE"
    echo "Backed up items:" >> "$MANIFEST_FILE"

    for item in "${BACKUP_DIRS[@]}"; do
        SRC="$CONFIG_DIR/$item"
        if [ -e "$SRC" ]; then
            cp -rL "$SRC" "$TARGET_BACKUP_DIR/$item" 2>/dev/null || cp -r "$SRC" "$TARGET_BACKUP_DIR/$item"
            echo " - $item" >> "$MANIFEST_FILE"
        fi
    done

    tui_msg "Backup Created" "Configuration backup successfully saved to:\n\n$TARGET_BACKUP_DIR"
}

# --- Revert Support ---
revert_backup() {
    if [ ! -d "$BACKUP_ROOT" ]; then
        tui_msg "Revert Error" "No backup directory found at:\n$BACKUP_ROOT"
        return
    fi

    BACKUPS=($(ls -d "$BACKUP_ROOT"/backup_* 2>/dev/null | sort -r))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        tui_msg "Revert Error" "No existing backups found in:\n$BACKUP_ROOT"
        return
    fi

    MENU_ITEMS=()
    for i in "${!BACKUPS[@]}"; do
        DIR_NAME="$(basename "${BACKUPS[$i]}")"
        DATE_STR="${DIR_NAME#backup_}"
        MENU_ITEMS+=("$DIR_NAME" "Backup from $DATE_STR")
    done

    if command -v whiptail &>/dev/null; then
        SELECTED_NAME=$(whiptail --title "Revert Configuration" \
            --menu "Select a historical backup to restore:" 15 65 6 \
            "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
        [ -z "$SELECTED_NAME" ] && return
        SELECTED_BACKUP="$BACKUP_ROOT/$SELECTED_NAME"
    else
        echo -e "${YELLOW}Available Backups:${RESET}"
        for i in "${!BACKUPS[@]}"; do
            echo -e "  [$((i+1))] $(basename "${BACKUPS[$i]}")"
        done
        read -rp "Select backup number: " idx
        SELECTED_BACKUP="${BACKUPS[$((idx-1))]}"
    fi

    if tui_yesno "Confirm Revert" "Are you sure you want to restore:\n\n$SELECTED_BACKUP\n\nThis will overwrite your current ~/.config files."; then
        CONFIG_DIR="$HOME/.config"
        for item in "$SELECTED_BACKUP"/*; do
            BASENAME="$(basename "$item")"
            if [ "$BASENAME" != "manifest.txt" ]; then
                TARGET_DEST="$CONFIG_DIR/$BASENAME"
                rm -rf "$TARGET_DEST"
                cp -r "$item" "$TARGET_DEST"
            fi
        done
        hyprctl reload 2>/dev/null || true
        tui_msg "Revert Complete" "Configurations successfully restored from:\n\n$SELECTED_BACKUP"
    fi
}

# --- Wallpaper Collection Setup ---
setup_wallpapers() {
    WALLPAPER_DIR="$HOME/wallpaper"
    REPO_URL="https://github.com/tarzo-codes/wallpapers.git"

    if tui_yesno "Wallpaper Download" "Would you like to download/update the official wallpaper collection from GitHub?\n\nTarget: ~/wallpaper"; then
        log_info "Downloading wallpapers..."
        if [ -d "$WALLPAPER_DIR/.git" ]; then
            cd "$WALLPAPER_DIR" && git pull origin main 2>/dev/null || git pull || true
        else
            mkdir -p "$WALLPAPER_DIR"
            git clone "$REPO_URL" "$WALLPAPER_DIR" || log_warning "Failed to clone wallpapers repository."
        fi
        tui_msg "Wallpapers Setup" "Wallpaper collection successfully synchronized to ~/wallpaper"
    fi
}

# --- Package Installation ---
install_packages() {
    log_info "Installing official pacman dependencies..."

    PACMAN_PKGS=(
        hyprland
        quickshell
        wallust
        fish
        starship
        kitty
        fastfetch
        btop
        mako
        grim
        slurp
        cliphist
        brightnessctl
        wireplumber
        pipewire
        playerctl
        polkit-gnome
        gnome-keyring
        hyprlock
        ttf-jetbrains-mono-nerd
        python
        python-pip
    )

    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

    if [ -n "$AUR_HELPER" ]; then
        log_info "Installing AUR dependencies using $AUR_HELPER..."
        AUR_PKGS=(
            vicinae-bin
            awww
            waypaper
            bibata-cursor-theme
            tela-icon-theme
        )
        $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || true
    fi
}

# --- Configuration Deployment ---
setup_configs() {
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_DIR="$HOME/.config"

    log_info "Deploying configurations..."

    TARGET_DIRS=(
        hypr
        quickshell
        scripts
        fish
        fastfetch
        btop
        kitty
        wallust
        nvim
    )

    for dir in "${TARGET_DIRS[@]}"; do
        SRC="$DOTFILES_DIR/config/$dir"
        DEST="$CONFIG_DIR/$dir"

        if [ -d "$SRC" ] || [ -f "$SRC" ]; then
            rm -rf "$DEST"
            ln -sf "$SRC" "$DEST"
        fi
    done

    chmod +x "$CONFIG_DIR"/scripts/*.sh "$CONFIG_DIR"/scripts/*.py 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/quickshell/scripts/*.sh "$CONFIG_DIR"/quickshell/scripts/*.py 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/hypr/scripts/*.sh 2>/dev/null || true
}

# --- Initialize Theme Engines ---
init_theme_engine() {
    log_info "Initializing Wallust color engine and smart themes..."

    mkdir -p "$HOME/.cache/quickshell"

    DEFAULT_WALLPAPER="$HOME/wallpaper/beautiful-shot-snowy-mountain-sunset.jpg"
    if [ ! -f "$HOME/.cache/quickshell/current_wallpaper" ]; then
        if [ -f "$DEFAULT_WALLPAPER" ]; then
            echo "$DEFAULT_WALLPAPER" > "$HOME/.cache/quickshell/current_wallpaper"
        else
            FIRST_WALL=$(find "$HOME/wallpaper" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | head -1 || echo "")
            if [ -n "$FIRST_WALL" ]; then
                echo "$FIRST_WALL" > "$HOME/.cache/quickshell/current_wallpaper"
            fi
        fi
    fi

    if command -v wallust &>/dev/null; then
        CURRENT_WALL=$(cat "$HOME/.cache/quickshell/current_wallpaper" 2>/dev/null || echo "")
        if [ -n "$CURRENT_WALL" ] && [ -f "$CURRENT_WALL" ]; then
            wallust run "$CURRENT_WALL" || true
        fi
    fi

    [ -f "$HOME/.config/scripts/fish-smart-colors.py" ] && python3 "$HOME/.config/scripts/fish-smart-colors.py" || true
    [ -f "$HOME/.config/scripts/fastfetch-smart-logo.py" ] && python3 "$HOME/.config/scripts/fastfetch-smart-logo.py" || true
    [ -f "$HOME/.config/scripts/btop-smart-theme.py" ] && python3 "$HOME/.config/scripts/btop-smart-theme.py" || true
}

# --- Full Installation ---
full_install() {
    preflight_checks

    if tui_yesno "Full Installation" "This wizard will:\n\n1. Create a timestamped backup of current configs\n2. Install required packages (Pacman & AUR)\n3. Symlink Hyprland 0.56.1 Lua & Quickshell configs\n4. Setup wallpapers & initialize theme engines\n\nProceed?"; then
        create_backup
        install_packages
        setup_configs
        setup_wallpapers
        init_theme_engine
        hyprctl reload 2>/dev/null || true

        tui_msg "Installation Complete" "🎉 Hyprland 0.56.1 Lua + Quickshell setup complete!\n\nNext steps:\n- Run 'hyprctl reload'\n- Open Fish shell ('exec fish')\n- Press SUPER + W for Wallpaper Selector"
    fi
}

# --- Main TUI Menu ---
main_menu() {
    preflight_checks

    while true; do
        if command -v whiptail &>/dev/null; then
            CHOICE=$(whiptail --title "Hyprland 0.56.1 Lua + Quickshell Installer TUI" \
                --menu "Select an option below:" 17 68 6 \
                "1" "🚀 Full Installation (Packages + Backup + Configs)" \
                "2" "📂 Create Backup of Current Configurations" \
                "3" "🔄 Revert / Restore Previous Backup" \
                "4" "🖼️ Download / Update Wallpaper Collection" \
                "5" "🎨 Initialize Theme & Wallust Engine" \
                "6" "❌ Exit" 3>&1 1>&2 2>&3)
            
            [ -z "$CHOICE" ] && break

            case "$CHOICE" in
                "1") full_install ;;
                "2") create_backup ;;
                "3") revert_backup ;;
                "4") setup_wallpapers ;;
                "5") init_theme_engine; tui_msg "Theme Engine" "Theme engines initialized." ;;
                "6") break ;;
            esac
        else
            echo -e "\n${BOLD}${CYAN}Hyprland Dotfiles TUI Installer${RESET}"
            echo "1. Full Installation"
            echo "2. Create Backup"
            echo "3. Revert Backup"
            echo "4. Download Wallpapers"
            echo "5. Init Theme Engine"
            echo "6. Exit"
            read -rp "Choice [1-6]: " c
            case "$c" in
                1) full_install ;;
                2) create_backup ;;
                3) revert_backup ;;
                4) setup_wallpapers ;;
                5) init_theme_engine ;;
                6) break ;;
            esac
        fi
    done
}

# --- CLI Arguments ---
case "$1" in
    --full|-f) full_install ;;
    --backup|-b) create_backup ;;
    --revert|-r) revert_backup ;;
    --wallpapers|-w) setup_wallpapers ;;
    *) main_menu ;;
esac
