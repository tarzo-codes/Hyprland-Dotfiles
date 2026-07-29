// Colors for the daniela theme (Catppuccin Mocha)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Catppuccin Mocha)
    readonly property string _bg: "#181825"
    readonly property string _fg: "#CDD6F4"
    readonly property string _black: "#45475A"
    readonly property string _blackb: "#1e1e2e"
    readonly property string _red: "#F38BA8"
    readonly property string _green: "#A6E3A1"
    readonly property string _yellow: "#F9E2AF"
    readonly property string _blue: "#89B4FA"
    readonly property string _magenta: "#CBA6F7"
    readonly property string _cyan: "#94E2D5"
    readonly property string _white: "#CDD6F4"
    readonly property string _pink: "#F5C2E7"
    readonly property string _lavender: "#B4BEFE"
    readonly property string _lime: "#B9C244"
    readonly property string _amber: "#FBC02D"
    readonly property string _indigo: "#9399b2"
    readonly property string _grey: "#73739c"
    readonly property string _blue_gray: "#383857"
    readonly property string _blue_arch: "#0A9CF5"
    readonly property string _accent_color: "#1e1e2e"

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
    readonly property string accent: ThemeManager.colorMode === "wallust" ? WallustColors.accent : _blue
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _blackb
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}
