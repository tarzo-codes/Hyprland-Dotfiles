# 🔧 Hyprland Dotfiles

Welcome to my personal **Hyprland dotfiles** — a clean, modular, and aesthetic Wayland environment for **CachyOS** / **Arch Linux** featuring **Quickshell**, **Vicinae**, **Mako**, and **Wallust**.

📹 **Watch Setup Overview on YouTube:**  
👉 [youtube.com/@techressolve](http://youtube.com/@techressolve)  
[![Watch the video](https://img.youtube.com/vi/3j1-W1-3kJg/hqdefault.jpg)](https://www.youtube.com/watch?v=3j1-W1-3kJg)

> ⚠️ **Work in Progress:**  
> This setup is actively maintained and modularized.

---

## 📦 Required Applications

### 🛠️ Official Repositories
```bash
sudo pacman -S hyprland kitty waybar mako brightnessctl pamixer \
               pipewire pipewire-pulse wireplumber nautilus dolphin \
               grim slurp hyprpicker ttf-jetbrains-mono-nerd nwg-look
```

### 🧬 AUR (via `yay`)
```bash
yay -S quickshell vicinae wallust awww waypaper tela-icon-theme-git
```

Refer to [`packages.txt`](./packages.txt) for the complete list of system dependencies.

---

## ✨ Features

* 🎨 **Quickshell Desktop Bar & OSD**: Includes 18 customizable themes (`z0mbi3`, `melissa`, `emilia`, `andrea`, `cynthia`, etc.) with dynamic OS name detection, workspace symbols, active workspace badges, and volume/brightness OSD.
* 🔄 **Automated Mako & Vicinae Theme Syncing**: Switching Quickshell themes or Wallust palettes automatically updates and reloads Mako notification styles and Vicinae launcher themes on the fly.
* 🖼️ **Dynamic Wallpapers**: Managed via `waypaper` / `awww` and colorized dynamically using `wallust`.
* ⚡ **Modular Hyprland Structure**: Clean separation of `monitors`, `autostart`, `env`, `animations`, `keybinds`, `appearance`, `windowrules`, and `misc`.
* ⌨️ **Keybindings**:
  * `SUPER + Enter` → Open Terminal (`kitty`)
  * `SUPER` (Release) / `SUPER + Space` → Open Launcher (`vicinae`)
  * `SUPER + T` → Open Quickshell Theme Selector
  * `SUPER + W` → Open Wallpaper Switcher
  * `SUPER + Q` → Close Active Window

---

## 🗂️ Folder Structure

```bash
Hyprland-Dotfiles/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   ├── config/
│   │   ├── animations.conf
│   │   ├── appearance.conf
│   │   ├── autostart.conf
│   │   ├── env.conf
│   │   ├── keybinds.conf
│   │   ├── misc.conf
│   │   ├── monitors.conf
│   │   └── windowrules.conf
│   └── scripts/
│       └── wallpaper-switcher.sh
├── .gitignore
├── packages.txt
└── README.md
```

---

## 🚀 Installation & Symlinking

To link this configuration to your user config directory:

```bash
git clone https://github.com/tarzo-codes/Hyprland-Dotfiles.git ~/Hyprland-Dotfiles
ln -s ~/Hyprland-Dotfiles/hypr ~/.config/hypr
```

---

## 📜 License

MIT — [LICENSE](./LICENSE)
