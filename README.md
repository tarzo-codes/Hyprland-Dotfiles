# 🌀 tarzo's Hyprland Dotfiles

Dynamic, themable, wallust-powered Hyprland dotfiles running on **CachyOS Arch Linux**.

## ✨ Overview

This is a **dynamic dotfiles system** — colors are generated on-the-fly from your wallpaper using [wallust](https://codeberg.org/explosion-mental/wallust) (a pywal successor). Every component picks up the color scheme automatically.

### What's included

| Component | Description |
|-----------|-------------|
| **Hyprland** | Tiling Wayland compositor with custom keybinds, animations, and window rules |
| **Waybar** | Status bar with custom modules (system stats, media, GitHub, Tailscale, updates) |
| **Wallust** | Color scheme generator — reads your wallpaper, generates theme files for everything |
| **Kitty** | GPU-accelerated terminal with wallust-colored themes |
| **Mako** | Lightweight notification daemon with themed notifications |
| **Fish Shell** | Feature-rich shell with fzf integration, custom functions, and starship prompt |
| **Rofi** | Application launcher and power menu (wallust-themed) |
| **Fastfetch** | System fetch tool with custom logo |
| **GTK** | Themed GTK3/GTK4 via wallust-generated colors |
| **Neovim** | LazyVim-based editor with wallust color integration |
| **OBS Studio** | Custom wallust template for OBS scene colors |
| **Quickshell** | QML-based shell components with wallust colors |
| **Starship** | Cross-shell prompt themed to match the desktop |
| **Firefox** | UserChrome theming via wallust colors |
| **Vicinae** | System monitoring companion app |

### 🎨 Theming System

The entire desktop is themed dynamically using wallust:

```
wallpaper → wallust → colors-hypr.conf → Hyprland (active window borders, etc.)
                    → colors-waybar.css → Waybar
                    → colors-mako → Mako notifications
                    → colors-rofi.rasi → Rofi launcher/powermenu
                    → kitty.conf → Kitty terminal
                    → colors-firefox.css → Firefox userChrome
                    → colors-zsh.zsh → Zsh (if used)
                    → gtk.css → GTK3/GTK4
                    → nvim-theme.lua → Neovim
                    → starship.toml → Starship prompt
                    → quickshell-colors.qml → Quickshell
                    → obs.ovt → OBS Studio
                    → userColors.css → User-defined apps
```

### 📂 Repo Structure

```
Hyprland-Dotfiles/
├── hypr/              # Hyprland config (animations, binds, monitors, window rules)
│   ├── config/        # Modular hyprland config files
│   ├── scripts/       # Helper scripts (wallpaper, portal)
│   └── themes/        # Wallust-generated theme includes
├── waybar/            # Status bar config & scripts
│   └── scripts/       # Custom modules (media, github, updates, tailscale, etc.)
├── wallust/           # Color generator config & templates
│   └── templates/     # Output templates for every app
├── kitty/             # Terminal config
├── mako/              # Notification daemon
├── fish/              # Shell config, functions, fzf integration
├── gtk-3.0/           # GTK3 theme assets & settings
├── gtk-4.0/           # GTK4 theme settings
├── rofi/              # App launcher & powermenu
├── scripts/           # Standalone utility scripts
├── fastfetch/         # System fetch config
├── packages.txt       # Required packages list
└── README.md          # You are here
```

## 🚀 Installation

### Prerequisites

Install the required packages (see `packages.txt` for full list):

```bash
# Core
sudo pacman -S hyprland hyprlock waybar wallust kitty mako fish fastfetch

# Optional but recommended
sudo pacman -S rofi starship neovim firefox obs-studio quickshell

# AUR (if using)
yay -S wallust
```

### Setup

```bash
# Clone the repo
git clone https://github.com/tarzo-codes/Hyprland-Dotfiles ~/Hyprland-Dotfiles

# Backup your existing config
mv ~/.config/hypr ~/.config/hypr.bak
mv ~/.config/waybar ~/.config/waybar.bak
# ... etc for each component

# Symlink the configs
ln -sf ~/Hyprland-Dotfiles/hypr ~/.config/hypr
ln -sf ~/Hyprland-Dotfiles/waybar ~/.config/waybar
ln -sf ~/Hyprland-Dotfiles/wallust ~/.config/wallust
ln -sf ~/Hyprland-Dotfiles/kitty ~/.config/kitty
ln -sf ~/Hyprland-Dotfiles/mako ~/.config/mako
ln -sf ~/Hyprland-Dotfiles/fish ~/.config/fish
ln -sf ~/Hyprland-Dotfiles/gtk-3.0 ~/.config/gtk-3.0
ln -sf ~/Hyprland-Dotfiles/gtk-4.0 ~/.config/gtk-4.0
ln -sf ~/Hyprland-Dotfiles/rofi ~/.config/rofi
ln -sf ~/Hyprland-Dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/Hyprland-Dotfiles/scripts ~/.config/scripts
```

### First Run

1. Set a wallpaper: `wallust run /path/to/wallpaper.jpg`
2. Reload Hyprland: `hyprctl reload`
3. To change wallpaper, run the wallpaper picker script or use `wallust run`

## 🖼️ Screenshots

*(Add your screenshots here)*

## 📦 Packages

See [`packages.txt`](packages.txt) for the complete list of installed packages relevant to this setup.

## 🔧 Customization

- **Colors**: Change your wallpaper and run `wallust run <image>` — everything updates
- **Waybar modules**: Edit `waybar/modules.jsonc` and `waybar/config.jsonc`
- **Keybinds**: Edit `hypr/config/keybinds.conf`
- **Animations**: Edit `hypr/config/animations.conf`

## 📜 License

MIT

## 🙏 Credits

- [Hyprland](https://hyprland.org/)
- [wallust](https://codeberg.org/explosion-mental/wallust)
- [Waybar](https://github.com/Alexays/Waybar)
- All the open-source projects that make this possible