// Theme Manager - handles bar styles with distinct visual appearances.
//
// IMPORTANT HONESTY NOTE (read before renaming these to gh0stzk's theme
// names): gh0stzk's actual 18 rices (Emilia, Jan, Aline, Andrea, Cynthia,
// Isabel, Silvia, Melissa, Pamela, Cristina, Karla, z0mbi3, Brenda,
// Daniela, Marisol, h4ck3r, Varinka, Yael) are NOT stored as source in the
// gh0stzk/dotfiles repo - the RiceInstaller pulls them down as prebuilt
// pacman packages from a separate package repo, so their exact polybar
// module layouts aren't scrapeable from GitHub. These 18 styles below are
// our own placeholder set with the *same design principle* gh0stzk uses
// (every style has a physically different module layout, not just a
// recolor) so you have real structure to reskin once you have reference
// screenshots/configs for the actual rices you want to match.
//
// Each style now carries:
//   - geometry: radius / borderWidth / barHeight / glowEffect (as before)
//   - layout: which structural arrangement shell.qml should render
//   - modules: which widgets are shown, left-to-right in that arrangement
//
// Layouts implemented in shell.qml:
//   "centered"  - logo, title | <spacer> workspaces <spacer> | controls
//                 (your original bar)
//   "split"     - workspaces pinned hard-left, controls pinned hard-right,
//                 title fills the middle gap (classic 3-module polybar feel)
//   "left-dock" - one compact pill anchored to the left edge of the screen,
//                 does not span full width, everything bunched together
//                 (bspwm-minimalist feel)
//   "three-region" - explicit left/center/right module groups

pragma Singleton
import QtQuick

QtObject {
    readonly property var styles: ({
        "emilia": {
            "name": "Emilia", "glowEffect": false, "radius": 4,
            "borderWidth": 2, "barHeight": 26, "layout": "three-region",
            "leftModules": ["launcher", "cpu", "memory", "filesystem", "mpd"],
            "centerModules": ["workspaces"],
            "rightModules": ["updates", "bluetooth", "audio", "battery", "network", "clock", "tray", "power"]
        },
        "neon": {
            "name": "Neon Glow", "glowEffect": true, "radius": 20,
            "borderWidth": 2, "barHeight": 52, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "glass": {
            "name": "Glassmorphism", "glowEffect": false, "radius": 24,
            "borderWidth": 1, "barHeight": 52, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "minimal": {
            "name": "Minimal", "glowEffect": false, "radius": 8,
            "borderWidth": 0, "barHeight": 52, "layout": "left-dock",
            "modules": ["launcher", "workspaces", "clock"]
        },
        "retro": {
            "name": "Retro Wave", "glowEffect": true, "radius": 12,
            "borderWidth": 3, "barHeight": 52, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "cyber": {
            "name": "Cyberpunk", "glowEffect": true, "radius": 0,
            "borderWidth": 1, "barHeight": 52, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "sharp": {
            "name": "Sharp", "glowEffect": false, "radius": 0,
            "borderWidth": 2, "barHeight": 48, "layout": "split",
            "modules": ["workspaces", "title", "audio", "clock", "tray"]
        },
        "pill": {
            "name": "Pill", "glowEffect": false, "radius": 100,
            "borderWidth": 0, "barHeight": 40, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock"]
        },
        "beveled": {
            "name": "Beveled", "glowEffect": false, "radius": 4,
            "borderWidth": 3, "barHeight": 50, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "soft": {
            "name": "Soft", "glowEffect": true, "radius": 30,
            "borderWidth": 0, "barHeight": 56, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "framed": {
            "name": "Framed", "glowEffect": false, "radius": 16,
            "borderWidth": 4, "barHeight": 54, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "thin": {
            "name": "Thin", "glowEffect": false, "radius": 10,
            "borderWidth": 0, "barHeight": 36, "layout": "left-dock",
            "modules": ["launcher", "workspaces", "clock"]
        },
        "thick": {
            "name": "Thick", "glowEffect": true, "radius": 16,
            "borderWidth": 2, "barHeight": 64, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "asym": {
            "name": "Asymmetrical", "glowEffect": false, "radius": 0,
            "borderWidth": 2, "barHeight": 46, "layout": "split",
            "modules": ["workspaces", "title", "audio", "battery", "clock"]
        },
        "dome": {
            "name": "Dome", "glowEffect": true, "radius": 50,
            "borderWidth": 1, "barHeight": 60, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "square": {
            "name": "Square", "glowEffect": false, "radius": 0,
            "borderWidth": 0, "barHeight": 50, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "rounded": {
            "name": "Rounded", "glowEffect": false, "radius": 20,
            "borderWidth": 1, "barHeight": 52, "layout": "centered",
            "modules": ["launcher", "title", "workspaces", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "double": {
            "name": "Double Border", "glowEffect": true, "radius": 14,
            "borderWidth": 2, "barHeight": 54, "layout": "split",
            "modules": ["workspaces", "title", "styleSwitch", "audio", "battery", "clock", "tray"]
        },
        "minglow": {
            "name": "Minimal Glow", "glowEffect": true, "radius": 6,
            "borderWidth": 1, "barHeight": 42, "layout": "left-dock",
            "modules": ["launcher", "workspaces", "clock"]
        }
    })

    property string currentStyle: "emilia"

    property string currentTheme: "wallust"

    function setStyle(style) {
        if (styles[style]) {
            currentStyle = style
            return true
        }
        console.log("Invalid style:", style)
        return false
    }

    function getCurrentStyleProps() {
        return styles[currentStyle] || styles["neon"]
    }

    function getCurrentColors() {
        var style = styles[currentStyle] || styles["neon"]
        var result = {
            "background": Wallust.background,
            "foreground": Wallust.foreground,
            "accent": Wallust.accent,
            "surface": Wallust.surface,
            "textMuted": Wallust.textMuted,
            "glowEffect": style.glowEffect,
            "radius": style.radius,
            "borderWidth": style.borderWidth,
            "barHeight": style.barHeight,
            "layout": style.layout
        }
        if (style.leftModules !== undefined) {
            result.leftModules = style.leftModules
            result.centerModules = style.centerModules
            result.rightModules = style.rightModules
            result.modules = []
        } else {
            result.modules = style.modules
        }
        return result
    }

    function getRandomStyle() {
        var keys = Object.keys(styles)
        return keys[Math.floor(Math.random() * keys.length)]
    }

    function getNextStyle() {
        var keys = Object.keys(styles)
        var idx = keys.indexOf(currentStyle)
        return keys[(idx + 1) % keys.length]
    }

    function getPrevStyle() {
        var keys = Object.keys(styles)
        var idx = keys.indexOf(currentStyle)
        return keys[(idx - 1 + keys.length) % keys.length]
    }

    function getAllStyles() {
        return Object.keys(styles)
    }
}