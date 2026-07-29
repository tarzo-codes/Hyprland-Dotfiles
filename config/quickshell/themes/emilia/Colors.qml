// Colors for the emilia theme (Tokyo Night)
// Uses static theme colors for high contrast consistency

pragma Singleton

import QtQuick

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

    // Always use static colors for Emilia to preserve Tokyo Night identity
    readonly property string background: _bg
    readonly property string foreground: _fg
    readonly property string black: _black
    readonly property string red: _red
    readonly property string green: _green
    readonly property string yellow: _yellow
    readonly property string blue: _blue
    readonly property string magenta: _magenta
    readonly property string cyan: _cyan
    readonly property string white: _white

    readonly property string lime: _lime
    readonly property string amber: _amber
    readonly property string indigo: _indigo
    readonly property string grey: _grey

    // Semantic aliases
    readonly property string accent: _blue_arch
    readonly property string surface: _accent_color
    readonly property string textMuted: _blue_gray
}