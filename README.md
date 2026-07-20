# 🌀 tarzo's Hyprland Dotfiles

> **⚠️ WORK IN PROGRESS** — This config is under active development. Everything may not work properly, expect breaking changes.

Dynamic, wallust-themed Hyprland dotfiles running on **CachyOS Arch Linux**.

---

## 🚀 Installation

### Prerequisites

```bash
# Core Hyprland setup
sudo pacman -S hyprland hyprpicker kitty mako fish fastfetch starship fzf

# Wallust (dynamic colors from wallpaper)
sudo pacman -S wallust

# Quickshell (bar/shell)
sudo pacman -S quickshell

# Vicinae (app launcher)
sudo pacman -S vicinae-bin

# Wallpaper tools
sudo pacman -S waypaper awww

# Screenshot
sudo pacman -S grim slurp swappy wl-clipboard

# Fonts
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-bitstream-vera

# GTK theme support
sudo pacman -S nwg-look gtk-engine-murrine breeze-gtk

# XDG portals
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-user-dirs

# Media / misc
sudo pacman -S playerctl mpd

# Utilities
sudo pacman -S git github-cli python-pip wget curl openssh ripgrep btop unzip polkit-gnome

# AUR helpers
yay -S tela-icon-theme
```

### Setup

```bash
# 1. Backup existing configs
mv ~/.config/hypr ~/.config/hypr.bak 2>/dev/null
mv ~/.config/wallust ~/.config/wallust.bak 2>/dev/null
mv ~/.config/kitty ~/.config/kitty.bak 2>/dev/null
mv ~/.config/mako ~/.config/mako.bak 2>/dev/null
mv ~/.config/fish ~/.config/fish.bak 2>/dev/null
mv ~/.config/gtk-3.0 ~/.config/gtk-3.0.bak 2>/dev/null
mv ~/.config/gtk-4.0 ~/.config/gtk-4.0.bak 2>/dev/null
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null
mv ~/.config/vicinae ~/.config/vicinae.bak 2>/dev/null
mv ~/.config/fastfetch ~/.config/fastfetch.bak 2>/dev/null
mv ~/.config/scripts ~/.config/scripts.bak 2>/dev/null

# 2. Clone repo
git clone https://github.com/tarzo-codes/Hyprland-Dotfiles ~/Hyprland-Dotfiles

# 3. Symlink configs
ln -sf ~/Hyprland-Dotfiles/hypr ~/.config/hypr
ln -sf ~/Hyprland-Dotfiles/wallust ~/.config/wallust
ln -sf ~/Hyprland-Dotfiles/kitty ~/.config/kitty
ln -sf ~/Hyprland-Dotfiles/mako ~/.config/mako
ln -sf ~/Hyprland-Dotfiles/fish ~/.config/fish
ln -sf ~/Hyprland-Dotfiles/gtk-3.0 ~/.config/gtk-3.0
ln -sf ~/Hyprland-Dotfiles/gtk-4.0 ~/.config/gtk-4.0
ln -sf ~/Hyprland-Dotfiles/quickshell ~/.config/quickshell
ln -sf ~/Hyprland-Dotfiles/vicinae ~/.config/vicinae
ln -sf ~/Hyprland-Dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/Hyprland-Dotfiles/scripts ~/.config/scripts
```

### First Run

```bash
# 1. Set a wallpaper (generates all colors)
wallust run ~/Pictures/wallpaper.jpg

# 2. Start Hyprland (or reload)
hyprctl reload

# 3. Change wallpaper with picker (auto-matches icon theme)
~/.config/scripts/wallpaper_picker.sh
```

---

## ✨ Features

### Dynamic Theming
Everything is colored from your wallpaper via wallust. Run `wallust run <image>` and all apps update instantly.

### Quickshell Bar — 18 Themes
The bar is built with **Quickshell**, not Waybar. It includes **18 unique themes** ported from [gh0stzk/dotfiles](https://github.com/gh0stzk/dotfiles):

| Theme | Colorscheme | Layout | Position |
|-------|-------------|--------|----------|
| aline | Rose Pinè Dawn (light) | single-top | Top |
| andrea | Warm cream (light) | single-top | Top |
| brenda | Everforest Dark | single-top | Top |
| cristina | Rosé Pine Moon | single-bottom | Bottom |
| cynthia | Kanagawa Dark | double | Top + Bottom |
| daniela | Catppuccin Mocha | single-top | Top |
| emilia | Tokyo Night | single-top | Top |
| h4ck3r | Matrix hacker green | single-top | Top |
| isabel | One Dark | single-bottom | Bottom |
| jan | Cyberpunk neon | single-top | Top |
| karla | Dark minimal neon | single-top | Top |
| marisol | Dracula | single-top | Top |
| melissa | Nord | double | Top + Bottom |
| pamela | Dark pastel | single-top | Top |
| silvia | Gruvbox Dark | single-top | Top |
| varinka | Monochrome grey | single-top | Top |
| yael | IBM Carbon | single-top | Top |
| z0mbi3 | Decay Dark | sidebar | Left |

**Layouts:**
- `single-top` — Floating capsule bar (14 themes)
- `double` — Top system bar + bottom workspaces bar (2 themes)
- `single-bottom` — Bottom-only bar (2 themes)
- `sidebar` — Vertical left bar (1 theme)

### Keybinds

| Keybind | Action |
|---------|--------|
| `Ctrl+Shift+Alt+T` | Toggle Emilia ↔ Melissa bar layout |
| Left-click launcher | Open app launcher (Vicinae) |
| Right-click launcher | Open rice/theme selector |
| Left-click time | Show/hide full date |
| Scroll volume | Adjust volume |
| Scroll brightness | Adjust brightness |
| Left-click ⚙️ | Open settings panel |
| Left-click ⏻ | Open power menu |

### App Launcher
**Vicinae** replaces Rofi. It's a modern, wallust-themed launcher with fuzzy search.

### Smart Icon Theme Switcher
`wallpaper_picker.sh` analyzes the dominant wallpaper color and auto-selects the best **Tela** icon theme variant from 14 options.

### Wallust Pipeline

```
wallpaper.jpg
      │
      ▼
   wallust run
      │
      ├──→ colors-hypr.conf      → Hyprland borders
      ├──→ colors-waybar.css     → Quickshell bar
      ├──→ colors-mako           → Notifications
      ├──→ colors-rofi.rasi      → Vicinae launcher
      ├──→ kitty.conf            → Terminal
      ├──→ colors-firefox.css    → Firefox userChrome
      ├──→ colors-zsh.zsh        → Zsh prompt
      ├──→ gtk.css               → GTK3/GTK4
      ├──→ nvim-theme.lua        → Neovim
      ├──→ starship.toml         → Starship prompt
      ├──→ quickshell-colors.qml → Quickshell
      ├──→ obs.ovt               → OBS Studio
      └──→ userColors.css        → Custom overrides
```

---

## 📂 Config Reference

| File | Purpose |
|------|---------|
| `hypr/hyprland.conf` | Main compositor config, monitors, env vars, execs |
| `hypr/config/keybinds.conf` | **All keyboard shortcuts** |
| `hypr/config/animations.conf` | Window animations, curves, speed |
| `hypr/config/monitors.conf` | Monitor layout, resolution, scaling |
| `hypr/config/windowrules.conf` | Window behavior rules |
| `hypr/config/autostart.conf` | Apps that start with Hyprland |
| `hypr/config/appearance.conf` | Gaps, padding, corner radius |
| `hypr/config/env.conf` | Environment variables |
| `hypr/config/misc.conf` | Misc compositor settings |
| `hypr/scripts/wallpaper-switcher.sh` | Auto-cycle wallpapers |
| `hypr/scripts/portal.sh` | XDG portal helper |
| `hypr/themes/wallust.conf` | Wallust theme include |
| `wallust/wallust.toml` | Wallust config |
| `wallust/templates/*` | 15 template outputs |
| `quickshell/shell.qml` | **Main Quickshell bar entry** |
| `quickshell/themes/*` | 18 theme QML files |
| `quickshell/components/*` | Bar components (power, settings, network) |
| `quickshell/wallust-colors.qml` | Wallust colors for bar |
| `vicinae/settings.json` | Vicinae launcher config |
| `vicinae/themes/custom.toml` | Vicinae theme |
| `kitty/kitty.conf` | Terminal config |
| `mako/config` | Notification daemon |
| `fish/config.fish` | Shell aliases, prompt |
| `gtk-3.0/settings.ini` | GTK3 theme |
| `gtk-4.0/settings.ini` | GTK4 theme |
| `scripts/wallpaper_picker.sh` | Wallpaper selector + icon theme matcher |
| `scripts/screenshot.sh` | Region screenshot |
| `fastfetch/config.jsonc` | System fetch display |

---

## ⚠️ Notes

- **WORK IN PROGRESS** — may break, things will change
- No lock screen for now (hyprlock not configured)
- This is the actual active setup: Quickshell bar + Vicinae launcher + Wallust theming
- CachyOS Arch Linux with `linux-cachyos` kernel
- Built for Intel with optional AMD GPU

## 📜 License

MIT