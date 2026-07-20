// Colors for the cristina theme (Rosé Pine Moon)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Rosé Pine Moon)
    readonly property string _bg: "#232136"
    readonly property string _fg: "#e0def4"
    readonly property string _black: "#393552"
    readonly property string _blackb: "#2a2740"
    readonly property string _red: "#ea6f91"
    readonly property string _green: "#9bced7"
    readonly property string _yellow: "#f1ca93"
    readonly property string _blue: "#34738e"
    readonly property string _magenta: "#c3a5e6"
    readonly property string _cyan: "#eabbb9"
    readonly property string _white: "#e0def4"
    readonly property string _pink: "#d3869b"
    readonly property string _teal: "#00B19F"
    readonly property string _lime: "#8ec07c"
    readonly property string _amber: "#fac33b"
    readonly property string _indigo: "#6C77BB"
    readonly property string _grey: "#384148"
    readonly property string _blue_gray: "#6D8895"
    readonly property string _blue_arch: "#0A9CF5"
    readonly property string _accent_color: "#2a2740"

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
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _blackb
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}
