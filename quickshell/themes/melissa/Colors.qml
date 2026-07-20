// Colors for the melissa theme (Nord colorscheme)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Nord)
    readonly property string _bg: "#2e3440"
    readonly property string _fg: "#d8dee9"
    readonly property string _black: "#3b4252"
    readonly property string _red: "#bf616a"
    readonly property string _green: "#a3be8c"
    readonly property string _yellow: "#ebcb8b"
    readonly property string _blue: "#81a1c1"
    readonly property string _magenta: "#b48ead"
    readonly property string _cyan: "#88c0d0"
    readonly property string _white: "#e5e9f0"
    
    // Additional static colors
    readonly property string _blue_arch: "#0A9CF5"
    readonly property string _blue_gray: "#4c566a"
    readonly property string _accent_color: "#5e81ac"
    readonly property string _surface_color: "#3b4252"
    readonly property string _lime: "#a3be8c"
    readonly property string _amber: "#ebcb8b"
    readonly property string _indigo: "#5e81ac"
    readonly property string _grey: "#4c566a"

    // Switch between static and wallust colors based on ThemeManager.colorMode
    readonly property string background: ThemeManager.colorMode === "wallust" ? WallustColors.background : _bg
    readonly property string foreground: ThemeManager.colorMode === "wallust" ? WallustColors.foreground : _fg
    readonly property string black: ThemeManager.colorMode === "wallust" ? WallustColors.color0 : _black
    readonly property string red: ThemeManager.colorMode === "wallust" ? WallustColors.color1 : _red
    readonly property string green: ThemeManager.colorMode === "wallust" ? WallustColors.color2 : _green
    readonly property string yellow: ThemeManager.colorMode === "wallust" ? WallustColors.color3 : _yellow
    readonly property string blue: ThemeManager.colorMode === "wallust" ? WallustColors.color4 : _blue
    readonly property string magenta: ThemeManager.colorMode === "wallust" ? WallustColors.color5 : _magenta
    readonly property string cyan: ThemeManager.colorMode === "wallust" ? WallustColors.color6 : _cyan
    readonly property string white: ThemeManager.colorMode === "wallust" ? WallustColors.color7 : _white

    // Additional colors (support wallust and static modes)
    readonly property string lime: ThemeManager.colorMode === "wallust" ? WallustColors.lime : _lime
    readonly property string amber: ThemeManager.colorMode === "wallust" ? WallustColors.amber : _amber
    readonly property string indigo: ThemeManager.colorMode === "wallust" ? WallustColors.indigo : _indigo
    readonly property string grey: ThemeManager.colorMode === "wallust" ? WallustColors.grey : _grey

    // Semantic aliases
    readonly property string accent: ThemeManager.colorMode === "wallust" ? WallustColors.accent : _accent_color
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _surface_color
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}
