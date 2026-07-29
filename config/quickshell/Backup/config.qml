// Quickshell Bar Configuration
// Edit this file to customize your bar behavior

pragma Singleton
import QtQuick

QtObject {
    // === WORKSPACE CONFIGURATION ===
    // "per-monitor": 5 workspaces per monitor (monitor 1: 1-5, monitor 2: 6-10)
    // "even-odd": even workspaces on monitor 2, odd on monitor 1
    readonly property string workspaceMode: "per-monitor"

    // Total number of workspaces
    readonly property int totalWorkspaces: 10

    // Workspaces per monitor (used in "per-monitor" mode)
    readonly property int workspacesPerMonitor: 5

    // === THEME CONFIGURATION ===
    // "auto": random theme on wallpaper change
    // "random": random theme on each startup
    // or specify theme name: "neon", "glass", "minimal", "retro", "cyber"
    readonly property string themeMode: "auto"

    // Current theme override (empty = use themeMode logic)
    property string currentTheme: ""

    // === BAR APPEARANCE ===
    readonly property int barHeight: 40
    readonly property int barRadius: 12
    readonly property int barMargin: 6
    readonly property int widgetRadius: 8
    readonly property int widgetSpacing: 4
    readonly property int workspaceSize: 32
    readonly property int workspaceSpacing: 2

    // === ANIMATION ===
    readonly property int animationDuration: 300
    readonly property string animationEasing: "Qt.EaseOutCubic"

    // === APPLETS (right side, in order) ===
    // NOTE: not yet consumed by shell.qml - each ThemeManager style
    // currently defines its own `modules` list so every style can have a
    // genuinely different module set. This stays here as the fallback
    // default for a future "custom" style. Names match the module keys
    // shell.qml's moduleComponent() understands: launcher, title,
    // workspaces, styleSwitch, audio, battery, clock, tray.
    readonly property var applets: [
        "clock",
        "tray",
        "audio",
        "battery"
    ]

    // === LAUNCHER ===
    readonly property string launcherCommand: "vicinae toggle"
    readonly property string launcherIcon: ""
}