# Quickshell Configuration — All 18 Themes

A complete Quickshell bar configuration ported from [gh0stzk/dotfiles](https://github.com/gh0stzk/dotfiles), featuring 18 fully-themed bar layouts with dynamic color support via Wallust.

---

## Features

- **18 unique themes** with authentic color palettes from the original BSPWM dotfiles
- **4 bar layout types**: single-top floating capsule, double bar, single-bottom, and vertical sidebar
- **Dynamic colors** — toggle Wallust mode in Settings to use colors from your current wallpaper
- **Persistent state** — theme selection and color mode survive restarts
- **`Ctrl+Shift+Alt+T`** — instantly toggle between Emilia (single-top) and Melissa (double-bar) layouts

---

## Keybinds

| Keybind | Action |
|---|---|
| `Ctrl+Shift+Alt+T` | Toggle between Emilia ↔ Melissa bar layout |
| Left-click on 🌙 icon | Cycle to next theme |
| Left-click on launcher | Open app launcher |
| Right-click on launcher | Open rice/theme selector |
| Left-click on time | Show/hide full date |
| Scroll on volume | Adjust volume |
| Scroll on brightness | Adjust brightness |
| Left-click on ⚙️ | Open settings panel (theme switcher + wallust toggle) |
| Left-click on ⏻ | Open power menu |

---

## Bar Layout Types

### `single-top` — Floating Capsule Bar (14 themes)

A single horizontal bar at the top of the screen with rounded corners and left/right margins.

**Modules:**
- **Left:** Launcher, window title, battery, CPU, memory, disk, media controls
- **Center:** Workspace indicators (clickable)
- **Right:** Network, clock, volume, brightness, color picker, settings, power

**Themes using this layout:**
`aline` `andrea` `brenda` `daniela` `emilia` `h4ck3r` `jan` `karla` `marisol` `pamela` `silvia` `varinka` `yael`

---

### `double` — Top System Bar + Bottom Workspaces Bar (2 themes)

Two bars: a transparent top bar showing system metrics, and a bottom bar with workspaces and media controls.

**Top bar modules:**
- **Right:** CPU, Memory, Disk, Network, Clock, Settings

**Bottom bar modules:**
- **Left:** Workspaces, Color picker, Power
- **Center:** Volume, Brightness, Updates, Battery
- **Right:** Settings

**Themes:** `melissa` (Nord) · `cynthia` (Kanagawa)

---

### `single-bottom` — Bottom-Only Bar (2 themes)

A single horizontal bar anchored to the bottom of the screen. All modules in one bar.

**Modules:**
- **Left:** Launcher, Workspaces, Color picker, Power
- **Center:** Volume, Brightness, Updates, Battery, CPU, Memory
- **Right:** Network, Clock, Settings

**Themes:** `cristina` (Rosé Pine Moon) · `isabel` (One Dark)

---

### `sidebar` — Vertical Left Bar (1 theme)

A slim vertical bar (52px wide) anchored to the left edge of the screen.

**Modules (top to bottom):** Launcher, Workspace indicators, Settings, Power

**Theme:** `z0mbi3` (Decay Dark)

---

## All 18 Themes

| Theme | Colorscheme | Layout | Bar Position |
|---|---|---|---|
| **aline** | Rose Pinè Dawn (light) | single-top | Top |
| **andrea** | Warm cream (light) | single-top | Top |
| **brenda** | Everforest Dark | single-top | Top |
| **cristina** | Rosé Pine Moon | single-bottom | Bottom |
| **cynthia** | Kanagawa Dark | double | Top + Bottom |
| **daniela** | Catppuccin Mocha | single-top | Top |
| **emilia** | Tokyo Night | single-top | Top |
| **h4ck3r** | Matrix hacker green | single-top | Top |
| **isabel** | One Dark | single-bottom | Bottom |
| **jan** | Cyberpunk neon | single-top | Top |
| **karla** | Dark minimal neon | single-top | Top |
| **marisol** | Dracula | single-top | Top |
| **melissa** | Nord | double | Top + Bottom |
| **pamela** | Dark pastel | single-top | Top |
| **silvia** | Gruvbox Dark | single-top | Top |
| **varinka** | Monochrome grey | single-top | Top |
| **yael** | IBM Carbon | single-top | Top |
| **z0mbi3** | Decay Dark | sidebar | Left |

---

## Theme Previews

> These preview images show the original BSPWM rice layouts that inspired each Quickshell theme.
> The Quickshell bar faithfully replicates the color palette while adapting to a Wayland/Hyprland environment.

### Aline — Rose Pinè Dawn (Light)
![Aline Preview](/home/tarzo/dotfiles/config/bspwm/rices/aline/preview.webp)

### Andrea — Warm Cream (Light)
![Andrea Preview](/home/tarzo/dotfiles/config/bspwm/rices/andrea/preview.webp)

### Brenda — Everforest Dark
![Brenda Preview](/home/tarzo/dotfiles/config/bspwm/rices/brenda/preview.webp)

### Cristina — Rosé Pine Moon
![Cristina Preview](/home/tarzo/dotfiles/config/bspwm/rices/cristina/preview.webp)

### Cynthia — Kanagawa Dark
![Cynthia Preview](/home/tarzo/dotfiles/config/bspwm/rices/cynthia/preview.webp)

### Daniela — Catppuccin Mocha
![Daniela Preview](/home/tarzo/dotfiles/config/bspwm/rices/daniela/preview.webp)

### Emilia — Tokyo Night
![Emilia Preview](/home/tarzo/dotfiles/config/bspwm/rices/emilia/preview.webp)

### H4ck3r — Matrix Hacker Green
![H4ck3r Preview](/home/tarzo/dotfiles/config/bspwm/rices/h4ck3r/preview.webp)

### Isabel — One Dark
![Isabel Preview](/home/tarzo/dotfiles/config/bspwm/rices/isabel/preview.webp)

### Jan — Cyberpunk Neon
![Jan Preview](/home/tarzo/dotfiles/config/bspwm/rices/jan/preview.webp)

### Karla — Dark Minimal Neon
![Karla Preview](/home/tarzo/dotfiles/config/bspwm/rices/karla/preview.webp)

### Marisol — Dracula
![Marisol Preview](/home/tarzo/dotfiles/config/bspwm/rices/marisol/preview.webp)

### Melissa — Nord
![Melissa Preview](/home/tarzo/dotfiles/config/bspwm/rices/melissa/preview.webp)

### Pamela — Dark Pastel
![Pamela Preview](/home/tarzo/dotfiles/config/bspwm/rices/pamela/preview.webp)

### Silvia — Gruvbox Dark
![Silvia Preview](/home/tarzo/dotfiles/config/bspwm/rices/silvia/preview.webp)

### Varinka — Monochrome Grey
![Varinka Preview](/home/tarzo/dotfiles/config/bspwm/rices/varinka/preview.webp)

### Yael — IBM Carbon
![Yael Preview](/home/tarzo/dotfiles/config/bspwm/rices/yael/preview.webp)

### Z0mbi3 — Decay Dark (Vertical Sidebar)
![Z0mbi3 Preview](/home/tarzo/dotfiles/config/bspwm/rices/z0mbi3/preview.webp)

---

## Dynamic Colors (Wallust)

Each theme supports dynamic colors from your wallpaper via Wallust integration:

1. Set a wallpaper with `waypaper` or `swww`
2. Run `wallust run <wallpaper-path>` to generate `/home/tarzo/.config/quickshell/wallust-colors.qml`
3. In the Quickshell settings panel, toggle **"Dynamic Colors (Wallust)"**

The bar will instantly update to use your wallpaper's extracted color palette while keeping the original theme's layout and structure.

---

## File Structure

```
~/.config/quickshell/
├── shell.qml                    # Main entry point (all layouts)
├── themes/
│   ├── ThemeManager.qml         # Persistent theme + color mode state
│   ├── WallustColors.qml        # Wallust dynamic color definitions
│   ├── qmldir
│   ├── aline/Colors.qml         # Rose Pinè Dawn
│   ├── andrea/Colors.qml        # Warm cream
│   ├── brenda/Colors.qml        # Everforest Dark
│   ├── cristina/Colors.qml      # Rosé Pine Moon
│   ├── cynthia/Colors.qml       # Kanagawa Dark
│   ├── daniela/Colors.qml       # Catppuccin Mocha
│   ├── emilia/Colors.qml        # Tokyo Night
│   ├── h4ck3r/Colors.qml        # Matrix hacker green
│   ├── isabel/Colors.qml        # One Dark
│   ├── jan/Colors.qml           # Cyberpunk neon
│   ├── karla/Colors.qml         # Dark minimal neon
│   ├── marisol/Colors.qml       # Dracula
│   ├── melissa/Colors.qml       # Nord
│   ├── pamela/Colors.qml        # Dark pastel
│   ├── silvia/Colors.qml        # Gruvbox Dark
│   ├── varinka/Colors.qml       # Monochrome grey
│   ├── yael/Colors.qml          # IBM Carbon
│   └── z0mbi3/Colors.qml        # Decay Dark
└── components/
    ├── Network.qml
    ├── PowerMenuWindow.qml
    └── SettingsPanel.qml
```
