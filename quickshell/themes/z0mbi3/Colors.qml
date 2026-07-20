// Colors for the z0mbi3 theme (Decay dark - originally a vertical EWW sidebar)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (z0mbi3 - Decay/Decayce dark)
    readonly property string _bg: "#0d0f18"
    readonly property string _fg: "#a5b6cf"
    readonly property string _black: "#3d414f"
    readonly property string _blackb: "#151720"
    readonly property string _red: "#dd6777"
    readonly property string _green: "#90ceaa"
    readonly property string _yellow: "#ecd3a0"
    readonly property string _blue: "#86aaec"
    readonly property string _magenta: "#c296eb"
    readonly property string _cyan: "#93cee9"
    readonly property string _white: "#cbced3"
    readonly property string _pink: "#c296eb"
    readonly property string _teal: "#00B19F"
    readonly property string _lime: "#B9C244"
    readonly property string _amber: "#FBC02D"
    readonly property string _indigo: "#6C77BB"
    readonly property string _grey: "#8C8C8C"
    readonly property string _blue_gray: "#6D8895"
    readonly property string _blue_arch: "#0f94d2"
    readonly property string _accent_color: "#151720"

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
    readonly property string accent: ThemeManager.colorMode === "wallust" ? WallustColors.accent : _cyan
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _blackb
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}