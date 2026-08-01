# 🌀 Hyprland + Quickshell Dotfiles

An ultra-modern, high-performance, and visually stunning Wayland desktop environment for **Arch Linux / CachyOS**. Featuring native **Hyprland modular configuration**, **Quickshell** status bar & floating panels with the **Centralized Rice Control Center**, **Vicinae** launcher, and an intelligent **Wallust WCAG AA contrast engine**.

<div align="center">

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux%20%7C%20CachyOS-blue?logo=archlinux)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland%200.56.1-00f5d4?logo=hyprland)](https://hyprland.org)
[![Quickshell](https://img.shields.io/badge/Shell-Quickshell-7f5af0)](https://git.outfoxxed.me/outfoxxed/quickshell)
[![Wallust](https://img.shields.io/badge/Theming-Wallust%20Contrast%20Engine-ff007f)](https://codeberg.org/eownerless/wallust)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## ⚡ Key Features

### 🎛️ 1. Centralized Rice Control Center (`SUPER + R`)
- **Single Source of Truth (`CentralConfig.qml`)**: All bar layouts, dimensions, theme settings, applet locations, volume levels, and brightness levels read and save from a single centralized manager.
- **All 18 Bar Layout Selector Grid**: Switch live between **18 complete desktop bars**:
  `emilia`, `cristina`, `marisol`, `melissa`, `andrea`, `aline`, `silvia`, `daphne`, `janet`, `katarina`, `lucia`, `noelia`, `pola`, `regina`, `teresa`, `vick`, `yuki`, `zorin`.
- **Modular Zone Drag & Re-Ordering**: `◄` and `►` controls shift modules left/right within their zones.
- **Position Sequence Badges (`#1`, `#2`, `#3`...)**: Displays the exact order index of active modules.
- **Preset Overwrite Confirmation Dialogs**: Warning prompts prevent accidental layout overwrites.
- **Interactive Edit Mode**: Displays a glowing green highlight border and active chip on the live desktop bar.

### 📍 2. Dynamic Applet Location, Resizing & Custom X/Y Coordinates
- **4 Applet Anchoring Modes**: Cycle through `TOP` ➔ `BOTTOM` ➔ `CENTER` ➔ `CUSTOM`.
- **Custom X / Y Screen Coordinates**: Position system applets at exact pixel locations (`Custom Position X` & `Custom Position Y`).
- **Custom Applet Width & Height**: Resize volume, network, bluetooth, brightness, and settings popups (`240px` - `600px` width, `240px` - `700px` height).

### 👁️ 3. Smart Auto-Hiding for Idle/Empty Modules
Modules automatically collapse to 0px when idle and pop up when active:
- **Song / Media Title (`song`, `media`)**: Auto-hides when no media is playing; auto-shows when music starts.
- **Active Window Title (`title`)**: Auto-hides on desktop; auto-shows when an app window is focused.
- **Updates Badge (`updates`)**: Auto-hides when up to date; auto-shows when packages require update.
- **System Tray (`tray`)**: Auto-hides when tray is empty; auto-shows when tray icons arrive.

### 🔊 4. Hardware Device Value Persistence
- Master volume levels (`volValue`), screen brightness levels (`brightnessValue`), and mute states persist across reboots and shell reloads.

### 🎨 5. Intelligent Wallust WCAG AA Contrast Engine
- Enforces strict **WCAG AA ($\ge 4.5:1$) contrast ratios** against terminal backgrounds for Fish shell syntax highlighting, Fastfetch CachyOS truecolor logos, btop themes, Neovim syntax, and Starship prompts.

---

## ⌨️ Keybindings Cheat Sheet

| Keybinding | Action |
|---|---|
| `SUPER + RETURN` | Open Kitty terminal |
| `SUPER + R` | Open Centralized Rice Control Center |
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
| `SUPER + 1 .. 0` | Switch to workspace 1..10 |
| `SUPER + SHIFT + 1 .. 0` | Move active window to workspace 1..10 |

---

## 📁 Repository Layout

```
.
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf              # Main Hyprland entry point
│   │   └── config/                    # Modular Hyprland configs
│   │       ├── monitors.conf
│   │       ├── autostart.conf
│   │       ├── env.conf
│   │       ├── animations.conf
│   │       ├── keybinds.conf
│   │       ├── appearance.conf
│   │       ├── windowrules.conf
│   │       └── misc.conf
│   ├── quickshell/                    # Qt6/QML status bar & popup panels
│   │   ├── config/
│   │   │   ├── CentralConfig.qml      # Single centralized configuration manager
│   │   │   └── qmldir
│   │   ├── components/                # Rice Editor, Volume, Network, Bluetooth, Panels
│   │   ├── themes/                    # ThemeManager & BarModules singletons
│   │   └── shell.qml                  # Quickshell entrypoint
│   ├── scripts/                       # Contrast engine & helper scripts
│   ├── fish/                          # Shell configuration
│   ├── fastfetch/                     # Fastfetch config & dynamic logo
│   ├── btop/                          # btop config & wallust theme
│   └── kitty/                         # Kitty terminal config
├── install.sh                         # Automated installation script
├── LICENSE                            # MIT License
└── README.md                          # Documentation
```

---

## 📜 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
