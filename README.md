# 🚧 Hyprland Dotfiles (Work in Progress)

Welcome to my personal **Hyprland dotfiles** setup — built for a clean, modular, and terminal-focused Arch Linux experience using **Hyprland** as the Wayland compositor.
Check out my Youtube for Video updates: http://youtube.com/@techressolve
> ⚠️ **Note:** This setup is a **Work in Progress**. Configs will change frequently, some features may break, and structure is still being finalized.

[Current Update][(https://www.youtube.com/watch?v=your_video_id](https://youtu.be/3j1-W1-3kJg))


---

## ✨ Features (Planned & In Progress)

- 🧩 Modular config structure (`hypr`, `waybar`, `rofi`, `swaylock`, etc.)
- 🧼 Minimalist and clean design with sensible defaults
- 🖼️ Wallpaper support using `swww`
- 🧠 Smart keybindings and productivity tools
- 🧪 Tiling window manager behavior using Hyprland
- 🧰 Full support for terminal-based workflows
- 🔄 Sync-ready with Git for easy portability

---

## 🗂️ Structure

```bash
Hyprland-Dotfiles/
├── hypr-gtk-tool/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
├── config/
├── themes/
├── kitty/
│   └── kitty.conf
├── wallust.conf
├── mako/
│   └── config
├── rofi/
│   ├── applets/
│   │   └── power_menu.rasi
│   └── shared/
│       ├── config.rasi
│       └── style.rasi
├── scripts/
│   ├── dynamic-icon.sh
│   ├── rofi-launcher.sh
│   ├── rofi-powermenu.sh
│   ├── wallpaper_cycle.sh
│   └── wallpaper_picker.sh
├── wallust/
│   ├── templates/
│   └── wallust.toml
├── waybar/
│   ├── config
│   └── style.css
├── .gitignore
└── README.md
Hyprland-Dotfiles/
├── hypr/
│   ├── config/
│   │   ├── animations.conf
│   │   ├── appearance.conf
│   │   ├── autostart.conf
│   │   ├── env.conf
│   │   ├── keybinds.conf
│   │   ├── misc.conf
│   │   ├── monitors.conf
│   │   └── windowrules.conf
│   ├── wallust.conf
│   ├── hyprland.conf
│   └── hyprlock.conf
├── kitty/
│   └── kitty.conf
├── mako/
│   └── config
├── rofi/
│   ├── applets/
│   │   └── power_menu.rasi
│   └── shared/
│       ├── config.rasi
│       ├── fonts.rasi
│       ├── style.rasi
│       └── wallust.rasi
├── scripts/
│   ├── dynamic-icon.sh
│   ├── rofi-launcher.sh
│   ├── rofi-powermenu.sh
│   ├── wallpaper_cycle.sh
│   └── wallpaper_picker.sh
├── themes/
├── wallust/
│   ├── templates/
│   │   ├── colors-hypr.conf
│   │   ├── colors-mako
│   │   ├── colors-rofi.rasi
│   │   ├── colors-waybar.css
│   │   └── colors-zsh.zsh
│   ├── dynamic-color.sh
│   ├── kitty.conf
│   └── wallust.toml
├── waybar/
│   ├── config
│   └── style.css
├── .gitignore
└── README.md

