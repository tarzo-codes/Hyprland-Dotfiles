#!/usr/bin/env bash
#  ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ 
#  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
#  ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
#  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
#  ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
#  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ 
#
#  Hyprland 0.56.1 Lua + Quickshell Dotfiles Automated Installer
#  Includes Backup, Revert, and Wallpaper Collection Support
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

banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "  ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
    echo "  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
    echo "  ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
    echo "  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║"
    echo "  ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
    echo "  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${RESET}"
    echo -e "${BOLD}${CYAN}  Hyprland 0.56.1 (Lua Specification) + Quickshell Setup${RESET}\n"
}

# --- Pre-flight Checks ---
preflight_checks() {
    log_info "Performing pre-flight checks..."

    if [ "$(id -u)" -eq 0 ]; then
        log_error "This script must NOT be run as root."
        exit 1
    fi

    if ! command -v pacman &>/dev/null; then
        log_error "pacman not found. This installer requires Arch Linux or CachyOS."
        exit 1
    fi

    AUR_HELPER=""
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        log_warning "Neither 'yay' nor 'paru' found. AUR packages may need manual installation."
    fi

    log_success "Pre-flight checks passed."
}

# --- Backup Support ---
create_backup() {
    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    TARGET_BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$TARGET_BACKUP_DIR"

    log_info "Creating configuration backup in $TARGET_BACKUP_DIR..."

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
            log_info "Backing up $item..."
            cp -rL "$SRC" "$TARGET_BACKUP_DIR/$item" 2>/dev/null || cp -r "$SRC" "$TARGET_BACKUP_DIR/$item"
            echo " - $item" >> "$MANIFEST_FILE"
        fi
    done

    log_success "Backup created successfully at $TARGET_BACKUP_DIR"
    echo "$TARGET_BACKUP_DIR"
}

# --- Revert Support ---
revert_backup() {
    banner
    log_info "Checking for available backups in $BACKUP_ROOT..."

    if [ ! -d "$BACKUP_ROOT" ]; then
        log_error "No backup directory found at $BACKUP_ROOT"
        exit 1
    fi

    BACKUPS=($(ls -d "$BACKUP_ROOT"/backup_* 2>/dev/null | sort -r))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        log_error "No backups found in $BACKUP_ROOT"
        exit 1
    fi

    echo -e "${YELLOW}${BOLD}Available Backups:${RESET}\n"
    for i in "${!BACKUPS[@]}"; do
        DIR_NAME="$(basename "${BACKUPS[$i]}")"
        DATE_STR="${DIR_NAME#backup_}"
        echo -e "  ${CYAN}[$((i+1))]${RESET} $DIR_NAME (${DATE_STR})"
    done
    echo ""

    read -rp "Select a backup to restore [1-${#BACKUPS[@]}]: " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#BACKUPS[@]}" ]; then
        log_error "Invalid selection."
        exit 1
    fi

    SELECTED_BACKUP="${BACKUPS[$((CHOICE-1))]}"
    log_warning "Restoring configuration from: $SELECTED_BACKUP"

    read -rp "Are you sure you want to revert your current configs? [y/N]: " CONFIRM_REVERT
    if [[ ! "$CONFIRM_REVERT" =~ ^[Yy]$ ]]; then
        log_warning "Revert cancelled."
        exit 0
    fi

    CONFIG_DIR="$HOME/.config"
    for item in "$SELECTED_BACKUP"/*; do
        BASENAME="$(basename "$item")"
        if [ "$BASENAME" != "manifest.txt" ]; then
            TARGET_DEST="$CONFIG_DIR/$BASENAME"
            log_info "Restoring $BASENAME -> $TARGET_DEST..."
            rm -rf "$TARGET_DEST"
            cp -r "$item" "$TARGET_DEST"
        fi
    done

    log_success "Configurations successfully restored from $SELECTED_BACKUP"
    log_info "Reloading Hyprland configuration..."
    hyprctl reload 2>/dev/null || true
}

# --- Wallpaper Prompt & Download ---
setup_wallpapers() {
    WALLPAPER_DIR="$HOME/wallpaper"
    REPO_URL="https://github.com/tarzo-codes/wallpapers.git"

    echo ""
    log_info "Wallpaper Collection Setup"
    echo -e "Target directory: ${CYAN}$WALLPAPER_DIR${RESET}"

    read -rp "Would you like to download/update the official wallpaper collection? [y/N]: " CHOICE_WALL
    if [[ "$CHOICE_WALL" =~ ^[Yy]$ ]]; then
        if [ -d "$WALLPAPER_DIR/.git" ]; then
            log_info "Updating existing wallpaper collection in $WALLPAPER_DIR..."
            cd "$WALLPAPER_DIR" && git pull origin main 2>/dev/null || git pull || true
        else
            log_info "Cloning wallpaper repository from $REPO_URL..."
            mkdir -p "$WALLPAPER_DIR"
            git clone "$REPO_URL" "$WALLPAPER_DIR" || log_warning "Failed to clone wallpapers, skipping."
        fi
        log_success "Wallpaper collection setup complete."
    else
        log_info "Skipped wallpaper collection download."
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

    log_success "Packages installed successfully."
}

# --- Configuration Deployment ---
setup_configs() {
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_DIR="$HOME/.config"

    # Always create a full backup first
    create_backup

    log_info "Installing configurations from $DOTFILES_DIR/config..."

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
            log_info "Installing '$dir' -> $DEST"
            rm -rf "$DEST"
            ln -sf "$SRC" "$DEST"
        fi
    done

    # Ensure executable permissions on all custom scripts
    log_info "Setting executable permissions on custom scripts..."
    chmod +x "$CONFIG_DIR"/scripts/*.sh "$CONFIG_DIR"/scripts/*.py 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/quickshell/scripts/*.sh "$CONFIG_DIR"/quickshell/scripts/*.py 2>/dev/null || true
    chmod +x "$CONFIG_DIR"/hypr/scripts/*.sh 2>/dev/null || true

    log_success "Configurations symlinked successfully."
}

# --- Initialize Themes & Wallust ---
init_theme_engine() {
    log_info "Initializing Wallust color engine and dynamic theme scripts..."

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
            log_info "Running Wallust on $CURRENT_WALL..."
            wallust run "$CURRENT_WALL" || true
        fi
    fi

    if [ -f "$HOME/.config/scripts/fish-smart-colors.py" ]; then
        python3 "$HOME/.config/scripts/fish-smart-colors.py" || true
    fi

    if [ -f "$HOME/.config/scripts/fastfetch-smart-logo.py" ]; then
        python3 "$HOME/.config/scripts/fastfetch-smart-logo.py" || true
    fi

    if [ -f "$HOME/.config/scripts/btop-smart-theme.py" ]; then
        python3 "$HOME/.config/scripts/btop-smart-theme.py" || true
    fi

    log_success "Theme engine initialized."
}

# --- Main Full Install Workflow ---
full_install() {
    banner
    preflight_checks

    echo -e "${YELLOW}This wizard will back up your configs, install packages, and deploy Hyprland dotfiles.${RESET}"
    read -rp "Do you wish to proceed? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Installation cancelled."
        exit 0
    fi

    install_packages
    setup_configs
    setup_wallpapers
    init_theme_engine

    banner
    echo -e "${GREEN}${BOLD}🎉 Installation Complete!${RESET}"
    echo -e "${CYAN}Next steps:${RESET}"
    echo -e "  1. Restart Hyprland or run: ${BOLD}hyprctl reload${RESET}"
    echo -e "  2. Open a new Fish shell session: ${BOLD}exec fish${RESET}"
    echo -e "  3. Select your wallpaper via ${BOLD}SUPER + W${RESET}\n"
}

# --- Interactive Main Menu ---
interactive_menu() {
    banner
    echo -e "${BOLD}${CYAN}Select an action:${RESET}"
    echo -e "  ${GREEN}[1]${RESET} Full Installation (Packages + Backup + Dotfiles + Wallpapers)"
    echo -e "  ${GREEN}[2]${RESET} Create Backup of Current Configurations"
    echo -e "  ${GREEN}[3]${RESET} Revert / Restore to a Previous Backup"
    echo -e "  ${GREEN}[4]${RESET} Download / Update Wallpaper Collection"
    echo -e "  ${GREEN}[5]${RESET} Exit\n"

    read -rp "Enter choice [1-5]: " MENU_CHOICE
    case "$MENU_CHOICE" in
        1) full_install ;;
        2) create_backup ;;
        3) revert_backup ;;
        4) setup_wallpapers ;;
        5) exit 0 ;;
        *) log_error "Invalid option."; exit 1 ;;
    esac
}

# --- CLI Options Handling ---
case "$1" in
    --revert|-r)
        revert_backup
        ;;
    --backup|-b)
        create_backup
        ;;
    --wallpapers|-w)
        setup_wallpapers
        ;;
    --full|-f)
        full_install
        ;;
    *)
        interactive_menu
        ;;
esac
