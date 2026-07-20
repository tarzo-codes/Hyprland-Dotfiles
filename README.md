# 🌀 tarzo's Hyprland Dotfiles (WIP)

> **⚠️ WORK IN PROGRESS** — This config is under active development. Everything may not work properly, expect breaking changes.

Dynamic, wallust-themed Hyprland dotfiles running on **CachyOS Arch Linux**.

---

## ✨ What Makes This Unique

### 🎨 Dynamic Color Engine
The entire desktop is **generated from your wallpaper** via [wallust](https://codeberg.org/explosion-mental/wallust) (pywal successor). One command — `wallust run wallpaper.jpg` — and every component gets recolored instantly.

### 📦 What's Included

| Component | Description |
|-----------|-------------|
| **Hyprland** | Modular config with custom animations, keybinds, window rules, monitors |
| **Waybar** | Top bar with **18 bar themes** (toggle with a script), 20+ custom modules |
| **Wallust** | The color heart — generates 15+ template outputs from wallpaper |
| **Kitty** | Terminal with wallust-dynamic colors |
| **Mako** | Notification daemon, wallust-themed |
| **Fish** | Shell with fzf integration, starship prompt |
| **Vicinae** | Application launcher (replaces rofi) |
| **Quickshell** | QML desktop shell components |
| **Fastfetch** | System fetch with custom CachyOS logo |
| **GTK3/GTK4** | Themed via wallust |

### 🎯 Unique Features

| Feature | Details |
|---------|---------|
| **Smart Icon Theme Switching** | `wallpaper_picker.sh` analyzes dominant wallpaper color and auto-selects the best Tela icon theme variant from 14 options |
| **Multi-Monitor Wallpaper Spanning** | `--span` flag with `awww` backend for seamless multi-monitor wallpapers |
| **Waybar Theme Toggling** | `toggle-theme.sh` switches between 18 bar themes dynamically |
| **Transparency Toggle** | `toggle-transparency.sh` makes the bar transparent/opaque on the fly |
| **Wake-on-LAN Module** | `wol.sh` — WOL + Tailscale integration in the bar |
| **GitHub Notifications** | `github.sh` — real-time GH notification count in the bar |
| **Package Update Tracker** | `updates.sh` — shows pending updates (pacman + AUR) |
| **System Maintenance** | `sysmaintenance.sh` — one-click system cleanup |
| **SSH Quick Connect** | `connectssh.sh` — SSH session launcher from the bar |
| **Tailscale Status** | `tailscaleinfo.sh` — VPN status in the bar |
| **Package List Generator** | `listpackages.sh` — exports installed packages from the bar |
| **Now Playing** | `mediaplayer.py` — MPRIS music info in the bar |
| **OBS Studio Theme** | Custom wallust template for OBS scene colors |
| **Auto Color Theme** | Dynamic-color script updates all running apps when wallpaper changes |
| **Screenshot Tool** | `screenshot.sh` — region capture with grim+slurp |

---

## 🎨 Theming System (Wallust Pipeline)

```
wallpaper.jpg
      │
      ▼
   wallust run
      │
      ├──→ colors-hypr.conf      → Hyprland borders, active window
      ├──→ colors-waybar.css     → Waybar bar & modules
      ├──→ colors-mako           → Notification colors
      ├──→ colors-rofi.rasi      → Vicinae launcher colors
      ├──→ kitty.conf            → Kitty terminal palette
      ├──→ colors-firefox.css    → Firefox userChrome
      ├──→ colors-zsh.zsh        → Zsh prompt colors
      ├──→ gtk.css               → GTK3/GTK4 theme
      ├──→ nvim-theme.lua        → Neovim colorscheme
      ├──→ starship.toml         → Starship prompt
      ├──→ quickshell-colors.qml → Quickshell widgets
      ├──→ obs.ovt               → OBS Studio scene colors
      └──→ userColors.css        → Custom app overrides
```

---

## 📂 Repo Structure & Config Reference

| File | What to configure here |
|------|----------------------|
| `hypr/hyprland.conf` | Main compositor settings, monitor bindings, env vars, execs |
| `hypr/config/monitors.conf` | **Monitor layout, resolution, refresh rate, scaling, wallpapers** |
| `hypr/config/keybinds.conf` | **All keyboard shortcuts** (SUPER+key actions) |
| `hypr/config/animations.conf` | Window open/close animations, curves, speed |
| `hypr/config/windowrules.conf` | Window behavior rules (floating, noborder, workspace assignment) |
| `hypr/config/autostart.conf` | **Apps that start with Hyprland** (waybar, wallust, mako, etc.) |
| `hypr/config/appearance.conf` | Gaps, padding, corner radius, default cursor |
| `hypr/config/env.conf` | Environment variables (XCURSOR, QT/QT_WAYLAND) |
| `hypr/config/misc.conf` | Misc: disable_autoreload, enable_swallow, render settings |
| `hypr/hyprlock.conf` | **Lock screen** — background, clock style, colors, date |
| `hypr/xdph.conf` | XDG Desktop Portal — file picker, screenshot backend |
| `hypr/scripts/wallpaper-switcher.sh` | Automatically cycle wallpapers from a directory |
| `hypr/scripts/portal.sh` | XDG portal autostart helper |
| `hypr/themes/wallust.conf` | Wallust theme include (colors from wallpaper) |
| `waybar/config.jsonc` | **Waybar layout** — what goes left/center/right |
| `waybar/modules.jsonc` | **All 20+ module configs** — styles, icons, tooltips |
| `waybar/style.css` | Main bar styling |
| `waybar/style-transparent.css` | Transparent bar variant |
| `waybar/theme-override.css` | Theme-specific overrides |
| `waybar/.current-theme` | Stores active theme name |
| `waybar/scripts/launch.sh` | How waybar is started |
| `waybar/scripts/toggle-theme.sh` | **Switch between 18 bar themes** |
| `waybar/scripts/toggle-transparency.sh` | Toggle bar opacity |
| `waybar/scripts/mediaplayer.py` | Now-playing in the bar |
| `waybar/scripts/updates.sh` | Package update count |
| `waybar/scripts/listpackages.sh` | Export installed packages |
| `waybar/scripts/sysmaintenance.sh` | System cleanup from bar |
| `waybar/scripts/github.sh` | GitHub notification count |
| `waybar/scripts/tailscaleinfo.sh` | Tailscale status in bar |
| `waybar/scripts/wol.sh` | Wake-on-LAN module |
| `waybar/scripts/connectssh.sh` | SSH quick connect |
| `waybar/scripts/installaupdates.sh` | Install updates from bar |
| `wallust/wallust.toml` | Wallust config — palette size, backend, templates |
| `wallust/templates/*` | **15 template files** — each generates a themed output for a component |
| `kitty/kitty.conf` | Terminal font, opacity, background, keybinds |
| `kitty/wallust.conf` | Auto-generated kitty colors (don't edit) |
| `mako/config` | Notification position, timeout, font, max visible |
| `fish/config.fish` | **Fish shell aliases, env vars, prompt config** |
| `fish/fish_variables` | Fish universal variables |
| `fish/conf.d/fzf.fish` | fzf integration for fish |
| `fish/functions/` | Custom fish functions (fzf bindings, search helpers) |
| `gtk-3.0/settings.ini` | GTK3 theme, icon theme, font |
| `gtk-3.0/gtk.css` | GTK3 overrides |
| `gtk-3.0/colors.css` | GTK3 wallust colors |
| `gtk-4.0/settings.ini` | GTK4 theme, icon theme |
| `gtk-4.0/gtk.css` | GTK4 overrides |
| `gtk-4.0/colors.css` | GTK4 wallust colors |
| `scripts/wallpaper_picker.sh` | **Wallpaper selector** with auto icon theme matching |
| `scripts/screenshot.sh` | Region screenshot utility |
| `scripts/shared/dynamic-color.sh` | Shared wallust color reload logic |
| `fastfetch/config.jsonc` | System fetch display config |
| `fastfetch/logo.txt` | Custom ASCII logo |

---

## 🚀 Installation

### Prerequisites

```bash
# Core — required for this dotfiles setup
sudo pacman -S hyprland hyprlock hyprpicker waybar wallust kitty mako fish fastfetch starship fzf

# Launcher
yay -S vicinae-bin

# Wallpaper & Theme Tools
sudo pacman -S imv wl-clipboard python-pip
yay -S tela-icon-theme

# Waybar dependencies (for custom modules)
sudo pacman -S playerctl pulseaudio pavucontrol networkmanager bluez bluez-utils
yay -S tailscale-bin  # if using WOL/Tailscale module

# Screenshot
sudo pacman -S grim slurp swappy wl-clipboard

# Fonts
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-bitstream-vera

# Optional but recommended
yay -S cachyos-fish-config visual-studio-code-bin
```

### Setup

```bash
# 1. Backup existing configs
mv ~/.config/hypr ~/.config/hypr.bak 2>/dev/null
mv ~/.config/waybar ~/.config/waybar.bak 2>/dev/null
mv ~/.config/wallust ~/.config/wallust.bak 2>/dev/null
mv ~/.config/kitty ~/.config/kitty.bak 2>/dev/null
mv ~/.config/mako ~/.config/mako.bak 2>/dev/null
mv ~/.config/fish ~/.config/fish.bak 2>/dev/null
mv ~/.config/gtk-3.0 ~/.config/gtk-3.0.bak 2>/dev/null
mv ~/.config/gtk-4.0 ~/.config/gtk-4.0.bak 2>/dev/null
mv ~/.config/vicinae ~/.config/vicinae.bak 2>/dev/null
mv ~/.config/fastfetch ~/.config/fastfetch.bak 2>/dev/null
mv ~/.config/scripts ~/.config/scripts.bak 2>/dev/null

# 2. Clone
git clone https://github.com/tarzo-codes/Hyprland-Dotfiles ~/Hyprland-Dotfiles

# 3. Symlink
ln -sf ~/Hyprland-Dotfiles/hypr ~/.config/hypr
ln -sf ~/Hyprland-Dotfiles/waybar ~/.config/waybar
ln -sf ~/Hyprland-Dotfiles/wallust ~/.config/wallust
ln -sf ~/Hyprland-Dotfiles/kitty ~/.config/kitty
ln -sf ~/Hyprland-Dotfiles/mako ~/.config/mako
ln -sf ~/Hyprland-Dotfiles/fish ~/.config/fish
ln -sf ~/Hyprland-Dotfiles/gtk-3.0 ~/.config/gtk-3.0
ln -sf ~/Hyprland-Dotfiles/gtk-4.0 ~/.config/gtk-4.0
ln -sf ~/Hyprland-Dotfiles/vicinae ~/.config/vicinae
ln -sf ~/Hyprland-Dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/Hyprland-Dotfiles/scripts ~/.config/scripts
```

### First Run

```bash
# 1. Set a wallpaper (this generates all colors)
wallust run ~/Pictures/wallpaper.jpg

# 2. Start Hyprland (or reload if already in session)
hyprctl reload

# 3. To change wallpaper, use the picker:
~/.config/scripts/wallpaper_picker.sh

# 4. To cycle through 18 bar themes:
~/.config/waybar/scripts/toggle-theme.sh

# 5. To toggle transparency on the bar:
~/.config/waybar/scripts/toggle-transparency.sh
```

---

## 🎯 Waybar Modules Detail

The Waybar has **20+ modules** including these custom ones:

| Custom Module | Script | What it does |
|--------------|--------|-------------|
| `custom/rofi` | vicinae | Opens the Vicinae app launcher |
| `custom/power_btn` | wlogout | Power menu (shutdown/reboot/logout) |
| `custom/lock_screen` | hyprlock | Locks the screen |
| `custom/updates` | `updates.sh` | Shows pending system updates |
| `custom/wol` | `wol.sh` | Wake-on-LAN + Tailscale status |
| `custom/github` | `github.sh` | GitHub unread notification count |
| `custom/media` | `mediaplayer.py` | Now-playing from any MPRIS player |
| `custom/swaync` | swaync | Notification center toggle |
| `custom/wl-gammarelay-temperature` | — | Screen color temperature slider |

---

## 📦 Packages Required

See `packages.txt` for a categorized list.

---

## 📝 Notes

- **This is a WORK IN PROGRESS** — some things may break or be incomplete
- Colors are generated dynamically — edit `wallust/templates/` to change how apps look
- All config files are modular — `hypr/config/*` for Hyprland settings
- The system runs on **CachyOS Arch Linux** with `linux-cachyos` kernel
- Built for **Intel with optional AMD GPU** (dual-GPU setup)

## 📜 License

MIT