// CheatSheet.qml — Dynamic Keybind Cheat Sheet
// Dark card containers with bright key pills & high-contrast text. Binds to Wallust & rootBar theme tokens.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: cheatSheet

    property var rootBar: null
    property bool isVisible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-cheatsheet"
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: isVisible

    property var groups: []
    property bool loading: false
    property string _rawBuffer: ""

    // ── Key formatter ───────────────────────────────────────────────────
    function formatKey(mods, key, vars) {
        var combined = mods
        if (vars["$mainMod"]) combined = combined.replace(/\$mainMod/g, vars["$mainMod"])

        combined = combined.split("#")[0].trim()

        var modStr = combined
            .replace(/\bSUPER\b/gi, "Super")
            .replace(/\bCTRL\b/gi, "Ctrl")
            .replace(/\bSHIFT\b/gi, "Shift")
            .replace(/\bALT\b/gi, "Alt")
            .replace(/\+/g, " + ")
            .replace(/\s+/g, " ")
            .trim()

        var k = key.split("#")[0].trim()
        var specialKeys = {
            "XF86AudioRaiseVolume": "Vol ▲",
            "XF86AudioLowerVolume": "Vol ▼",
            "XF86AudioMute":        "Mute",
            "XF86AudioMicMute":     "Mic Mute",
            "XF86MonBrightnessUp":  "Bright ▲",
            "XF86MonBrightnessDown":"Bright ▼",
            "XF86AudioNext":        "⏭",
            "XF86AudioPrev":        "⏮",
            "XF86AudioPlay":        "⏯",
            "XF86AudioPause":       "⏸",
            "Super_L":              "Super",
            "mouse_down":           "Scroll ▼",
            "mouse_up":             "Scroll ▲",
            "mouse:272":            "LMB",
            "mouse:273":            "RMB",
            "RETURN":               "Enter",
            "slash":                "/",
            "space":                "Space"
        }

        if (specialKeys[k]) k = specialKeys[k]
        else if (k.length === 1) k = k.toUpperCase()
        else k = k.charAt(0).toUpperCase() + k.slice(1).toLowerCase()

        if (!modStr || modStr === "—" || modStr === "-") return k
        return modStr + " + " + k
    }

    // ── Action formatter ─────────────────────────────────────────────────
    function formatAction(dispatcher, args, vars) {
        var fullArgs = args ? args.split("#")[0].trim() : ""

        // Expand variables ($terminal, $fileManager, $menu)
        for (var v in vars) {
            fullArgs = fullArgs.replace(new RegExp("\\" + v, "g"), vars[v])
        }

        var actionMap = {
            "killactive":            "Close window",
            "exit":                  "Exit Hyprland",
            "togglefloating":        "Toggle float",
            "pseudo":                "Pseudo tile",
            "layoutmsg togglesplit": "Toggle split",
            "fullscreen":            "Fullscreen",
            "movefocus l":           "Focus ←",
            "movefocus r":           "Focus →",
            "movefocus u":           "Focus ↑",
            "movefocus d":           "Focus ↓",
            "movewindow l":          "Move win ←",
            "movewindow r":          "Move win →",
            "movewindow u":          "Move win ↑",
            "movewindow d":          "Move win ↓",
            "resizeactive 20 0":     "Resize →",
            "resizeactive 0 -20":    "Resize ↑",
            "resizeactive -20 0":    "Resize ←",
            "resizeactive 0 20":     "Resize ↓",
            "movewindow":            "Move window",
            "resizewindow":          "Resize window"
        }

        var full = dispatcher + (fullArgs ? " " + fullArgs : "")
        if (actionMap[full]) return actionMap[full]
        if (actionMap[dispatcher]) return actionMap[dispatcher]

        if (dispatcher === "workspace") return "Go to workspace " + fullArgs
        if (dispatcher === "movetoworkspace") {
            if (fullArgs === "r-1") return "Move to prev workspace"
            if (fullArgs === "r+1") return "Move to next workspace"
            if (fullArgs === "e-1") return "Move to prev (empty)"
            if (fullArgs === "e+1") return "Move to next (empty)"
            if (fullArgs.startsWith("special")) return "Move to scratchpad"
            return "Move to workspace " + fullArgs
        }
        if (dispatcher === "togglespecialworkspace") return "Toggle scratchpad"

        if (dispatcher === "exec") {
            var rawCmd = fullArgs

            if (rawCmd.indexOf("nextTheme") !== -1) return "Next theme"
            if (rawCmd.indexOf("toggleThemeSelector") !== -1) return "Theme selector"
            if (rawCmd.indexOf("CheatSheet") !== -1) return "Cheat sheet"
            if (rawCmd.indexOf("screenshot.sh") !== -1) return "Screenshot"
            if (rawCmd.indexOf("wallpaper_picker") !== -1 || rawCmd.indexOf("wallpaper-switcher") !== -1) return "Wallpaper picker"
            if (rawCmd.indexOf("hyprlock") !== -1) return "Lock screen"

            var binary = rawCmd.split(/\s+/)[0].split("/").pop()
            var binaryMap = {
                "kitty": "Terminal",
                "alacritty": "Terminal",
                "nautilus": "File manager",
                "vicinae": "App launcher",
                "brightnessctl": rawCmd.indexOf("+") !== -1 ? "Brightness ▲" : "Brightness ▼",
                "wpctl": rawCmd.indexOf("5%+") !== -1 ? "Volume ▲" : rawCmd.indexOf("5%-") !== -1 ? "Volume ▼" : "Mute",
                "playerctl": rawCmd.indexOf("next") !== -1 ? "Next track" : rawCmd.indexOf("prev") !== -1 ? "Prev track" : "Play/Pause"
            }
            if (binaryMap[binary]) return binaryMap[binary]
            return binary || dispatcher
        }

        return dispatcher
    }

    // ── Parse conf file ──────────────────────────────────────────────────
    function parseConf(text) {
        var lines = text.split(/\r?\n/)
        var result = []
        var currentGroup = null
        var vars = {}

        // Pre-pass: collect variables ($terminal, $fileManager, $mainMod)
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            var varMatch = line.match(/^\$(\w+)\s*=\s*(.+)/)
            if (varMatch && !line.startsWith("bind")) {
                var val = varMatch[2].split("#")[0].trim()
                vars["$" + varMatch[1]] = val
            }
        }

        for (var j = 0; j < lines.length; j++) {
            var l = lines[j].trim()

            // Header comments
            if (l.startsWith("#")) {
                var title = l.replace(/^#+\s*/, "").split("#")[0].trim()
                if (title.length > 0 &&
                    !title.startsWith("See https") &&
                    !title.startsWith("Example") &&
                    !title.startsWith("http")) {
                    if (title.length > 36) title = title.substring(0, 34) + "…"
                    currentGroup = { title: title, binds: [] }
                    result.push(currentGroup)
                }
                continue
            }

            // Binds
            var bindMatch = l.match(/^bind[elrm]?\s*=\s*(.+)/)
            if (bindMatch) {
                var parts = bindMatch[1].split(",").map(function(s){ return s.trim() })
                if (parts.length >= 3) {
                    var rawMods = parts[0]
                    var rawKey  = parts[1]
                    var disp    = parts[2].trim()
                    var bArgs   = parts.slice(3).join(",").trim()

                    var keyStr = formatKey(rawMods, rawKey, vars)
                    var actStr = formatAction(disp, bArgs, vars)

                    if (!currentGroup) {
                        currentGroup = { title: "General", binds: [] }
                        result.push(currentGroup)
                    }
                    currentGroup.binds.push({ key: keyStr, action: actStr })
                }
            }
        }

        return result.filter(function(g){ return g.binds.length > 0 })
    }

    // ── Process ──────────────────────────────────────────────────────────
    Process {
        id: readProc
        command: ["cat", "/home/tarzo/.config/hypr/config/keybinds.conf"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => cheatSheet._rawBuffer += data
        }
        onExited: {
            cheatSheet.groups = cheatSheet.parseConf(cheatSheet._rawBuffer)
            cheatSheet.loading = false
        }
    }

    onIsVisibleChanged: {
        if (isVisible) {
            _rawBuffer = ""
            loading = true
            readProc.running = true
        }
    }

    // ── UI ───────────────────────────────────────────────────────────────
    Rectangle {
        id: bgOverlay
        anchors.fill: parent
        color: "#F208090E"   // Very dark overlay for high contrast
        focus: cheatSheet.isVisible

        Keys.onEscapePressed: cheatSheet.isVisible = false

        MouseArea { anchors.fill: parent; onClicked: cheatSheet.isVisible = false }

        // ── Main Outer Window ──────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width:  Math.min(parent.width  * 0.84, 940)
            height: Math.min(parent.height * 0.88, 680)
            radius: 16
            color:  rootBar ? rootBar._bg : "#0F1118"
            border.color: rootBar ? rootBar.alphaColor(rootBar._acc, 0.5) : "#7AA2F740"
            border.width: 1.5

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                // ── Header Bar ───────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 36; height: 36; radius: 8
                        color: rootBar ? rootBar.alphaColor(rootBar._acc, 0.22) : "#7AA2F730"
                        border.color: rootBar ? rootBar.alphaColor(rootBar._acc, 0.5) : "#7AA2F780"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "⌨"
                            font.pixelSize: 16
                            color: rootBar ? rootBar._acc : "#7AA2F7"
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "FluxDots Keybinds"
                            color: "#FFFFFF"
                            font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            text: loading ? "Loading…" : (groups.length + " groups · " + countBinds() + " keybinds")
                            color: "#9AA0C0"
                            font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close Button
                    Rectangle {
                        width: 28; height: 28; radius: 6
                        color: closeMouse.containsMouse ? "#3D1A1F" : "#1A1D2B"
                        border.color: closeMouse.containsMouse ? "#F7768E" : "#3A3D52"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMouse.containsMouse ? "#F7768E" : "#9AA0C0"
                            font.pixelSize: 11; font.bold: true
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cheatSheet.isVisible = false
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#232636"
                }

                // ── Grid of Group Cards ──────────────────────────────────
                Flickable {
                    id: flickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: groupsGrid.implicitHeight + 8
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: rootBar ? rootBar.alphaColor(rootBar._acc, 0.6) : "#7AA2F7"
                        }
                    }

                    GridLayout {
                        id: groupsGrid
                        width: flickable.width
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: groups

                            // Dark card container
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: cardCol.implicitHeight + 20
                                radius: 10
                                color: "#161824"   // Darker card box for contrast
                                border.color: "#282B3D"
                                border.width: 1

                                ColumnLayout {
                                    id: cardCol
                                    anchors {
                                        top: parent.top; left: parent.left; right: parent.right
                                        margins: 14; topMargin: 12
                                    }
                                    spacing: 8

                                    // Group Title
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title.toUpperCase()
                                        color: rootBar ? rootBar._acc : "#7AA2F7"
                                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: "#232636"
                                    }

                                    // Keybind items
                                    Repeater {
                                        model: modelData.binds

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            // Lighted Key Pill — High contrast
                                            Rectangle {
                                                Layout.preferredWidth: Math.max(keyLabel.implicitWidth + 14, 60)
                                                height: 22
                                                radius: 5
                                                color: "#222638"   // Lighted pill box
                                                border.color: rootBar ? rootBar.alphaColor(rootBar._acc, 0.5) : "#5A628A"
                                                border.width: 1

                                                Text {
                                                    id: keyLabel
                                                    anchors.centerIn: parent
                                                    text: modelData.key
                                                    color: rootBar ? rootBar._yel : "#FFCC66"   // Bright lighted text
                                                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                }
                                            }

                                            Text {
                                                text: "→"
                                                color: "#5A628A"
                                                font.pixelSize: 9
                                            }

                                            // Lighted Action Text
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.action
                                                color: "#E2E5F8"   // Lighted text for high visibility
                                                font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Footer ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#232636"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Esc  or click outside to close  ·  Super + /  to reopen"
                    color: "#787E9E"
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                }
            }
        }
    }

    function countBinds() {
        var n = 0
        for (var i = 0; i < groups.length; i++) n += groups[i].binds.length
        return n
    }
}
