# 🚧 Hyprland Dotfiles (Work in Progress)

Welcome to my personal **Hyprland dotfiles** — built for a clean, modular, and terminal-focused Arch Linux experience using **Hyprland** as the Wayland compositor.

📹 **Watch Setup Overview on YouTube:**
👉 [youtube.com/@techressolve](http://youtube.com/@techressolve)
[![Watch the video](https://img.youtube.com/vi/3j1-W1-3kJg/hqdefault.jpg)](https://www.youtube.com/watch?v=3j1-W1-3kJg)

> ⚠️ **Work in Progress:**
> This setup is under active development. Expect frequent changes, occasional breakage, and evolving file structures.

---

## 📦 Required Applications

### 🛠️ Official Repositories

```bash
apps=(
  hyprland rofi-wayland waybar kitty gtk3 gtk4
  xdg-desktop-portal-hyprland polkit uwsm zsh hyprlock
  ttf-jetbrains-mono ttf-jetbrains-mono-mono nwg-look
  gtk-engine-murrine gnome-themes-extra hyprpolkitagent mako
  gtk-menu-meta hyprsunset python-gobject brightnessctl pamixer
  ffmpeg mpd mpv mpv-uosc-git fastfetch swww
)
```

### 🧬 AUR (via `yay`)

```bash
yay_apps=(
  wallust hyperls-git waypaper
)
```

### 📅 Manual Install

* [`Orchis Theme`](https://github.com/vinceliuice/Orchis-theme) (`orchis-theme-git`)
* [`Tela Icon Theme`](https://github.com/vinceliuice/Tela-icon-theme) (`tela-icon-theme-git`)

---

## ✨ Features (In Progress)

* 🪩 Modular config structure (`hypr`, `waybar`, `rofi`, `lockscreen`, etc.)
* 🩼 Minimalist and clean design with sensible defaults
* 🖼️ Wallpaper management via `swww` and `wallust`
* ⌘️ Smart keybindings and productive workflows
* 📦 Terminal-first UX with minimal dependencies
* 🔄 Git-syncable and portable across machines

---

## 🗂️ Folder Structure

```bash
Hyprland-Dotfiles/
├── hypr-gtk-tool/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   └── config/
│       ├── animations.conf
│       ├── appearance.conf
│       ├── autostart.conf
│       ├── env.conf
│       ├── keybinds.conf
│       ├── misc.conf
│       ├── monitors.conf
│       └── windowrules.conf
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
│   ├── wallust.toml
│   ├── dynamic-color.sh
│   ├── kitty.conf
│   └── templates/
│       ├── colors-hypr.conf
│       ├── colors-mako
│       ├── colors-rofi.rasi
│       ├── colors-waybar.css
│       └── colors-zsh.zsh
├── waybar/
│   ├── config
│   └── style.css
├── .gitignore
└── README.md
```

---

## 🔧 Notes

* `wallust` is used to sync wallpaper colors across `rofi`, `waybar`, `mako`, `zsh`, and `kitty`.
* Scripts are designed to be modular and follow XDG spec where possible.
* `hypr-gtk-tool/` will manage GTK theme and icons automatically (planned).

---

## ✅ To Do

* [ ] Add setup script
* [ ] Split `scripts/` into functional subdirs
* [ ] Rofi styles switcher
* [ ] Add theme preview images
* [ ] Create install guide (`install.md`)

---

## 🙌 Contributing

This is a personal dotfiles setup. If you're inspired, feel free to fork or open issues/discussions.

---

## 📜 License

MIT — [LICENSE](./LICENSE)
