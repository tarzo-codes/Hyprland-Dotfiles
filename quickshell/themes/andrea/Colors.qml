// Colors for the andrea theme (Warm light cream - EWW horizontal bar)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Andrea - warm light pastel)
    readonly property string _bg: "#f5eee6"
    readonly property string _fg: "#151515"
    readonly property string _black: "#e6dfd7"
    readonly property string _blackb: "#5c595e"
    readonly property string _red: "#DA103F"
    readonly property string _green: "#1EB980"
    readonly property string _yellow: "#ffc338"
    readonly property string _blue: "#67d4f1"
    readonly property string _magenta: "#b0a5ed"
    readonly property string _cyan: "#2eccca"
    readonly property string _white: "#e1e2e7"
    readonly property string _pink: "#F075B7"
    readonly property string _lime: "#B9C244"
    readonly property string _amber: "#ffc338"
    readonly property string _indigo: "#6C77BB"
    readonly property string _grey: "#8C8C8C"
    readonly property string _blue_gray: "#5c595e"
    readonly property string _blue_arch: "#0f94d2"
    readonly property string _accent_color: "#e5ded6"
    readonly property string _border: "#161616"

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
    readonly property string surface: ThemeManager.colorMode === "wallust" ? WallustColors.surface : _black
    readonly property string textMuted: ThemeManager.colorMode === "wallust" ? WallustColors.textMuted : _blue_gray
}
