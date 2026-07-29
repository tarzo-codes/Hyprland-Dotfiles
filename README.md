# 🌀 Hyprland 0.56.1 Lua + Quickshell Dotfiles

An ultra-modern, high-performance, and visually stunning Wayland desktop environment for **Arch Linux / CachyOS**. Featuring native **Hyprland 0.56.1 Lua configuration**, **Quickshell** status bar & floating panels, **Vicinae** launcher, and an intelligent **Wallust WCAG AA contrast engine**.

<div align="center">

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux%20%7C%20CachyOS-blue?logo=archlinux)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland%200.56.1%20(Lua)-00f5d4?logo=hyprland)](https://hyprland.org)
[![Quickshell](https://img.shields.io/badge/Shell-Quickshell-7f5af0)](https://git.outfoxxed.me/outfoxxed/quickshell)
[![Wallust](https://img.shields.io/badge/Theming-Wallust%20Contrast%20Engine-ff007f)](https://codeberg.org/eownerless/wallust)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## ⚡ Key Features

### 🌙 1. Native Hyprland 0.56.1 Lua Specification
- Fully migrated from legacy `.conf` files to Hyprland's native **Lua configuration format** (`hyprland.lua`).
- **Modular Architecture**: Organized into clean, maintainable Lua modules (`lua/monitors.lua`, `lua/autostart.lua`, `lua/env.lua`, `lua/animations.lua`, `lua/keybinds.lua`, `lua/appearance.lua`, `lua/windowrules.lua`, `lua/misc.lua`).
- Native Lua APIs used throughout: `hl.config()`, `hl.monitor()`, `hl.env()`, `hl.curve()`, `hl.animation()`, `hl.bind()`, and `hl.window_rule()`.

### 🎛️ 2. Quickshell Bar & Floating Interactive Panels
- Powered by **Qt6 / QML** with custom widgets:
  - **PipeWire Volume Panel**: Native `pw-dump` JSON parsing ($< 2\text{ms}$) for sinks, sources, and per-app stream controls with zero process leaks.
  - **Network & Bluetooth Panels**: Real-time Wi-Fi/Bluetooth status and connection management.
  - **Wallpaper Selector & Theme Manager**: Interactive wallpaper picker (`SUPER + W`) and theme switcher (`SUPER + T`).
  - **Power Menu & Cheat Sheet**: Sleek system controls and shortcut cheat sheet (`SUPER + /`).

### 🎨 3. Intelligent Wallust WCAG AA Contrast Engine
Unlike basic color generators, our custom Python color scripts enforce strict **WCAG AA ($\ge 4.5:1$) contrast ratios** against terminal backgrounds for every token:
- **Fish Shell Syntax Highlighting (`fish-smart-colors.py`)**: Evaluates perceptual hue distance to assign distinct Wallust palette colors to commands, keywords, parameters, quotes, options, redirections, and errors. Uses `set -U` for persistent propagation.
- **Fastfetch CachyOS Logo (`fastfetch-smart-logo.py`)**: Renders an ANSI 24-bit truecolor CachyOS logo that automatically adapts to the current wallpaper accent colors.
- **btop System Monitor (`btop-smart-theme.py`)**: Dynamically generates `~/.config/btop/themes/wallust.theme` with high-contrast graph colors and borders.
- **Neovim & Starship**: Enforced code syntax contrast in Neovim and high-contrast segment backgrounds in Starship (`~/.config/starship.toml`).

### 🚀 4. Vicinae Launcher & Tools
- Fast, Raycast-like application launcher (`vicinae server` / `vicinae open`) mapped to `SUPER + L` or left-click launcher icon.
- Automated region screenshot tool (`scripts/screenshot.sh`).

---

## 🛠️ Requirements & Package Dependencies

### Official Pacman Packages
```bash
hyprland quickshell wallust fish starship kitty fastfetch btop mako \
grim slurp cliphist brightnessctl wireplumber pipewire playerctl \
polkit-gnome gnome-keyring hyprlock ttf-jetbrains-mono-nerd python python-pip
```

### AUR Packages (via `yay` or `paru`)
```bash
yay -S vicinae-bin awww waypaper bibata-cursor-theme tela-icon-theme
```

---

## 📦 Installation

Clone the repository and run the automated installer:

```bash
git clone https://github.com/tarzo-codes/Hyprland-Dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### What `install.sh` Features:
1. **Interactive Wizard & CLI Flags**:
   - `./install.sh` launches an interactive menu.
   - `./install.sh --revert` or `-r`: Reverts current configs to any previous timestamped backup.
   - `./install.sh --backup` or `-b`: Creates an instant standalone backup in `~/.config/hypr_dotfiles_backups/`.
   - `./install.sh --wallpapers` or `-w`: Interactively downloads/updates the wallpaper collection (`tarzo-codes/wallpapers`).
2. **Automated Package Installation**: Installs official pacman and AUR dependencies automatically.
3. **Full Backup System**: Automatically generates a timestamped backup before touching existing configs.
4. **Configuration Deployment**: Symlinks dotfile modules (`hypr`, `quickshell`, `scripts`, `fish`, `fastfetch`, `btop`, `kitty`, `wallust`, `nvim`) to `~/.config/`.
5. **Theme Engine Initialization**: Runs Wallust and contrast engines (`fish-smart-colors.py`, `fastfetch-smart-logo.py`, `btop-smart-theme.py`).

---

## ⌨️ Keybindings Cheat Sheet

| Keybinding | Action |
|---|---|
| `SUPER + RETURN` | Open Kitty terminal |
| `SUPER + Q` | Close active window |
| `SUPER + E` | Open Dolphin file manager |
| `SUPER + B` | Open Zen Browser |
| `SUPER + SHIFT + B` | Open Zen Browser (Private window) |
| `SUPER + V` | Toggle floating mode |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + W` | Toggle Wallpaper Selector |
| `SUPER + T` | Toggle Theme Selector |
| `SUPER + /` | Toggle Keybinding Cheat Sheet |
| `SUPER + SHIFT + S` | Capture region screenshot |
| `SUPER + Arrow Keys` | Move focus (Left / Right / Up / Down) |
| `SUPER + SHIFT + Arrow` | Move active window |
| `SUPER + CTRL + Arrow` | Resize active window |
| `SUPER + 1 .. 0` | Switch to workspace 1..10 |
| `SUPER + SHIFT + 1 .. 0` | Move active window to workspace 1..10 |
| `SUPER + S` | Toggle Scratchpad workspace |
| `SUPER + SHIFT + ALT + L` | Lock screen (`hyprlock`) |

---

## 📁 Repository Layout

```
.
├── config/
│   ├── hypr/
│   │   ├── hyprland.lua               # Main Hyprland Lua entry point
│   │   ├── lua/
│   │   │   ├── monitors.lua           # Display outputs & resolutions
│   │   │   ├── autostart.lua          # Startup background processes
│   │   │   ├── env.lua                # Wayland & Qt/KDE environment
│   │   │   ├── animations.lua         # Bezier curves & animation rules
│   │   │   ├── keybinds.lua           # Keyboard & mouse bindings
│   │   │   ├── appearance.lua         # Gaps, borders, shadows & blur
│   │   │   ├── windowrules.lua        # Window floating & position rules
│   │   │   └── misc.lua               # Layouts & misc compositor settings
│   │   └── themes/
│   │       └── wallust.lua            # Dynamic Wallust Lua color module
│   ├── quickshell/                    # Qt6/QML status bar & popup panels
│   ├── scripts/                       # Contrast engine & helper scripts
│   ├── fish/                          # Shell configuration & universal vars
│   ├── fastfetch/                     # Fastfetch config & dynamic logo
│   ├── btop/                          # btop config & wallust theme
│   ├── kitty/                         # Kitty terminal config
│   ├── wallust/                       # Wallust color generator templates
│   └── nvim/                          # Neovim configuration
├── install.sh                         # Automated installation script
├── LICENSE                            # MIT License
└── README.md                          # Documentation
```

---

## 📜 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
