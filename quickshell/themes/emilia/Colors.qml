// Colors for the emilia theme (Tokyo Night)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Tokyo Night) - from config.ini and theme-config.bash
    readonly property string _bg: "#1a1b26"
    readonly property string _fg: "#c0caf5"
    readonly property string _black: "#15161e"
    readonly property string _blackb: "#414868"
    readonly property string _red: "#f7768e"
    readonly property string _pink: "#FF0677"
    readonly property string _purple: "#583794"
    readonly property string _magenta: "#bb9af7"
    readonly property string _blue: "#7aa2f7"
    readonly property string _blue_arch: "#0A9CF5"
    readonly property string _cyan: "#7dcfff"
    readonly property string _teal: "#00B19F"
    readonly property string _green: "#9ece6a"
    readonly property string _lime: "#B9C244"
    readonly property string _yellow: "#e0af68"
    readonly property string _amber: "#FBC02D"
    readonly property string _orange: "#E57C46"
    readonly property string _brown: "#AC8476"
    readonly property string _grey: "#8C8C8C"
    readonly property string _indigo: "#6C77BB"
    readonly property string _blue_gray: "#6D8895"
    readonly property string _white: "#a9b1d6"
    readonly property string _accent_color: "#222330"

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
    readonly property string accent: ThemeManager.colorMode === "wallust" ? WallustColors.accent : _blue_arch
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _blackb
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}