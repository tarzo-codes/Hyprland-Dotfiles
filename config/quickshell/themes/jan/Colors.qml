// Colors for the jan theme (Cyberpunk neon)
// Supports both static theme colors and wallust dynamic colors

pragma Singleton

import QtQuick
import ".."

QtObject {
    // Static theme colors (Jan - Cyberpunk neon)
    readonly property string _bg: "#070219"
    readonly property string _fg: "#27fbfe"
    readonly property string _black: "#626483"
    readonly property string _blackb: "#09021f"
    readonly property string _red: "#fb007a"
    readonly property string _green: "#a6e22e"
    readonly property string _yellow: "#f3e430"
    readonly property string _blue: "#19bffe"
    readonly property string _magenta: "#6800d2"
    readonly property string _cyan: "#43fbff"
    readonly property string _white: "#27fbfe"
    readonly property string _pink: "#f200f4"
    readonly property string _teal: "#00B19F"
    readonly property string _lime: "#8df202"
    readonly property string _amber: "#FBC02D"
    readonly property string _indigo: "#8f32e4"
    readonly property string _grey: "#7a8488"
    readonly property string _blue_gray: "#1e80d2"
    readonly property string _blue_arch: "#00c9fe"
    readonly property string _accent_color: "#09021f"

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
