// Colors for the aline theme (Rose Pinè Dawn - light)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Rose Pinè Dawn - light)
    readonly property string _bg: "#faf4ed"
    readonly property string _fg: "#575279"
    readonly property string _black: "#f2e9e1"
    readonly property string _blackb: "#9893a5"
    readonly property string _red: "#b4637a"
    readonly property string _green: "#286983"
    readonly property string _yellow: "#ea9d34"
    readonly property string _blue: "#56949f"
    readonly property string _magenta: "#907aa9"
    readonly property string _cyan: "#d7827e"
    readonly property string _white: "#575279"
    readonly property string _pink: "#eb6f92"
    readonly property string _teal: "#9ccfd8"
    readonly property string _lime: "#B9C515"
    readonly property string _amber: "#f6c177"
    readonly property string _indigo: "#31748f"
    readonly property string _grey: "#8C8C8C"
    readonly property string _blue_gray: "#6e6a86"
    readonly property string _blue_arch: "#0A9CF5"
    readonly property string _accent_color: "#f2e9e1"

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
    readonly property string accent: ThemeManager.colorMode === "wallust" ? WallustColors.accent : _magenta
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _black
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}