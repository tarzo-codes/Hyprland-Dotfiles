import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: settingsPanel
    required property var modelData
    screen: modelData

    implicitWidth: 330
    implicitHeight: 520

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: !ThemeManager.barIsBottom
        bottom: ThemeManager.barIsBottom
        right: true
    }

    margins {
        top: !ThemeManager.barIsBottom ? (settingsPanel.rootBar ? settingsPanel.rootBar.barHeight + 6 : 48) : 0
        bottom: ThemeManager.barIsBottom ? (settingsPanel.rootBar ? settingsPanel.rootBar.barHeight + 6 : 48) : 0
        right: settingsPanel.rootBar ? Math.round(settingsPanel.screen.width * (1.0 - settingsPanel.rootBar.barWidthPercent) / 2) : Math.round(settingsPanel.screen.width * 0.03)
    }

    color: "transparent"

    property var colors: null
    property var rootBar: null
    property string modeChoice: ThemeManager.modeChoice

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: settingsPanel.rootBar ? settingsPanel.rootBar._bg : "#181628"
        border.color: settingsPanel.rootBar ? settingsPanel.rootBar.alphaColor(settingsPanel.rootBar._cyn, 0.6) : "#414868"
        border.width: 1.5
        radius: 14
        clip: true

        property real animOffset: ThemeManager.barIsBottom ? 16 : -16
        y: animOffset
        opacity: 0

        Component.onCompleted: {
            animOffset = 0;
            opacity = 1.0;
        }

        Behavior on animOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "󰒓"
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                    font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }
                Text {
                    text: "ADVANCED BAR SETTINGS"
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"
                    font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "󰅖"
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#6e6a86"
                    font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsPanel.rootBar) settingsPanel.rootBar.settingsVisible = false;
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: settingsPanel.rootBar ? settingsPanel.rootBar.alphaColor(settingsPanel.rootBar._muted, 0.3) : "#31748f" }

            // ── Scrollable Body ──
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: settingsCol.width
                contentHeight: settingsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: settingsCol
                    width: parent.width - 4
                    spacing: 14

                    // ════ 1. DIMENSIONS SECTION ════
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "󰈈 DIMENSIONS & LAYOUT"
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#907aa9"
                            font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        // Bar Height Slider
                        Column {
                            width: parent.width
                            spacing: 4
                            Row {
                                width: parent.width
                                Text { text: "Height"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10 }
                                Item { width: parent.width - 60 - heightVal.implicitWidth }
                                Text { id: heightVal; text: (settingsPanel.rootBar ? settingsPanel.rootBar.barHeight : 40) + "px"; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                            }
                            Rectangle {
                                width: parent.width; height: 6; radius: 3
                                color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                                Rectangle {
                                    height: parent.height; radius: 3; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                                    width: settingsPanel.rootBar ? ((settingsPanel.rootBar.barHeight - 32) / (64 - 32)) * parent.width : 0
                                    Behavior on width { NumberAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPositionChanged: (mouse) => {
                                        if (pressed && settingsPanel.rootBar) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                            settingsPanel.rootBar.barHeight = Math.round(32 + pct * (64 - 32));
                                        }
                                    }
                                    onPressed: (mouse) => {
                                        if (settingsPanel.rootBar) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                            settingsPanel.rootBar.barHeight = Math.round(32 + pct * (64 - 32));
                                        }
                                    }
                                }
                            }
                        }

                        // Bar Width Percent Slider
                        Column {
                            width: parent.width
                            spacing: 4
                            Row {
                                width: parent.width
                                Text { text: "Width"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10 }
                                Item { width: parent.width - 50 - widthVal.implicitWidth }
                                Text { id: widthVal; text: (settingsPanel.rootBar ? Math.round(settingsPanel.rootBar.barWidthPercent * 100) : 96) + "%"; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                            }
                            Rectangle {
                                width: parent.width; height: 6; radius: 3
                                color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                                Rectangle {
                                    height: parent.height; radius: 3; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                                    width: settingsPanel.rootBar ? ((settingsPanel.rootBar.barWidthPercent - 0.5) / (1.0 - 0.5)) * parent.width : 0
                                    Behavior on width { NumberAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPositionChanged: (mouse) => {
                                        if (pressed && settingsPanel.rootBar) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                            settingsPanel.rootBar.barWidthPercent = 0.5 + pct * (1.0 - 0.5);
                                        }
                                    }
                                    onPressed: (mouse) => {
                                        if (settingsPanel.rootBar) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                            settingsPanel.rootBar.barWidthPercent = 0.5 + pct * (1.0 - 0.5);
                                        }
                                    }
                                }
                            }
                        }

                        // Font Size Slider
                        Column {
                            width: parent.width
                            spacing: 4
                            Row {
                                width: parent.width
                                Text { text: "Font Size"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10 }
                                Item { width: parent.width - 65 - fontVal.implicitWidth }
                                Text { id: fontVal; text: ThemeManager.globalFontSize + "px"; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                            }
                            Rectangle {
                                width: parent.width; height: 6; radius: 3
                                color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                                Rectangle {
                                    height: parent.height; radius: 3; color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                                    width: Math.max(0, Math.min(1.0, (ThemeManager.globalFontSize - 8) / (16 - 8))) * parent.width
                                    Behavior on width { NumberAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPositionChanged: (mouse) => {
                                        if (pressed) {
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                            ThemeManager.globalFontSize = Math.round(8 + pct * (16 - 8));
                                        }
                                    }
                                    onPressed: (mouse) => {
                                        var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        ThemeManager.globalFontSize = Math.round(8 + pct * (16 - 8));
                                    }
                                }
                            }
                        }
                    }

                    // ════ 2. AUTO-HIDE & BAR BEHAVIOR ════
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "󰘔 BAR BEHAVIOR & AUTO-HIDE"
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#907aa9"
                            font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width; height: 32; radius: 8
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                            border.color: ThemeManager.autoHideBar ? (settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7") : "transparent"
                            border.width: 1

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: "󰤈 Auto-Hide Bar"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 120 - autoHideTxt.implicitWidth }
                                Text {
                                    id: autoHideTxt
                                    text: ThemeManager.autoHideBar ? "󰄬 ON" : "󰅖 OFF"
                                    color: ThemeManager.autoHideBar ? "#9bced7" : (settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#6e6a86")
                                    font.pixelSize: 10; font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.autoHideBar = !ThemeManager.autoHideBar
                            }
                        }
                    }

                    // ════ 3. CUSTOM COLORS & PALETTE ════
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "󰏘 CUSTOM COLOR SUPPORT"
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#907aa9"
                            font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        // Color mode toggle (Wallust vs Static)
                        Rectangle {
                            width: parent.width; height: 28; radius: 7
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                            border.color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ThemeManager.colorMode === "wallust" ? "󱥑 Wallust (Dynamic)" : "󰏘 Static Theme Colors"
                                color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"
                                font.pixelSize: 10; font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.colorMode = (ThemeManager.colorMode === "wallust") ? "static" : "wallust"
                            }
                        }

                        // Accent Color Swatches
                        Column {
                            width: parent.width; spacing: 4
                            Text { text: "Custom Accent Palette:"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 9 }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: ["#9bced7", "#ea6f91", "#f1ca93", "#c3a5e6", "#00B19F", "#f6c177", "#8ec07c", "#eb6f92"]
                                    delegate: Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: modelData
                                        border.color: ThemeManager.customAccentColor === modelData ? "#ffffff" : "transparent"
                                        border.width: 2
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: ThemeManager.customAccentColor = modelData
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    color: "transparent"
                                    border.color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#6e6a86"
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "↺"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10 }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: ThemeManager.customAccentColor = ""
                                    }
                                }
                            }
                        }

                        // Dark / Auto / Light mode picker
                        Rectangle {
                            width: parent.width; height: 28; radius: 7
                            color: settingsPanel.rootBar ? Qt.rgba(Qt.color(settingsPanel.rootBar._bg).r, Qt.color(settingsPanel.rootBar._bg).g, Qt.color(settingsPanel.rootBar._bg).b, 0.6) : "#111118"
                            border.color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                            border.width: 1
                            clip: true

                            Row {
                                anchors.fill: parent
                                Rectangle {
                                    width: parent.width / 3; height: parent.height; radius: 7
                                    color: settingsPanel.modeChoice === "dark" ? (settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7") : "transparent"
                                    Text { anchors.centerIn: parent; text: "🌙 Dark"; color: settingsPanel.modeChoice === "dark" ? "#181628" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"); font.pixelSize: 9; font.bold: true }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: applyWallustMode("dark") }
                                }
                                Rectangle {
                                    width: parent.width / 3; height: parent.height
                                    color: settingsPanel.modeChoice === "auto" ? "#16a34a" : "transparent"
                                    Text { anchors.centerIn: parent; text: "🔆 Auto"; color: settingsPanel.modeChoice === "auto" ? "#ffffff" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"); font.pixelSize: 9; font.bold: true }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: applyWallustMode("auto") }
                                }
                                Rectangle {
                                    width: parent.width / 3; height: parent.height; radius: 7
                                    color: settingsPanel.modeChoice === "light" ? "#2563eb" : "transparent"
                                    Text { anchors.centerIn: parent; text: "☀️ Light"; color: settingsPanel.modeChoice === "light" ? "#ffffff" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"); font.pixelSize: 9; font.bold: true }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: applyWallustMode("light") }
                                }
                            }
                        }
                    }

                    // ════ 4. PINNED APPS MODULE & APP COLOR MODE ════
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "󰅀 PINNED APPS MODULE"
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#907aa9"
                            font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        // App Icon Color Mode (Theme Colors vs Real Branding Colors)
                        Rectangle {
                            width: parent.width; height: 30; radius: 8
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                            border.color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                            border.width: 1

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: "App Icon Colors:"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 125 - appModeTxt.implicitWidth }
                                Text {
                                    id: appModeTxt
                                    text: ThemeManager.appColorMode === "real" ? "󰏎 Real Colors" : "󰏘 Theme Accent"
                                    color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                                    font.pixelSize: 10; font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.appColorMode = (ThemeManager.appColorMode === "real") ? "theme" : "real"
                            }
                        }

                        // Show/Hide Pinned Apps Module Toggle
                        Rectangle {
                            width: parent.width; height: 28; radius: 7
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: "Show Pinned Apps"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 130 - pinState.implicitWidth }
                                Text {
                                    id: pinState
                                    text: ThemeManager.showPinnedApps ? "󰄬 Visible" : "󰅖 Hidden"
                                    color: ThemeManager.showPinnedApps ? "#8ec07c" : (settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#6e6a86")
                                    font.pixelSize: 10; font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.showPinnedApps = !ThemeManager.showPinnedApps
                            }
                        }
                    }

                    // ════ 5. DUAL BAR & THEME MODULES ════
                    Column {
                        width: parent.width
                        spacing: 8
                        visible: ThemeManager.barIsDouble

                        Text {
                            text: "󰓠 DUAL BAR MODULE CONTROLS"
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#907aa9"
                            font.family: settingsPanel.rootBar ? settingsPanel.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        // Top Bar Toggle
                        Rectangle {
                            width: parent.width; height: 28; radius: 7
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: "Top Bar"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 80 - topState.implicitWidth }
                                Text { id: topState; text: ThemeManager.topBarEnabled ? "󰄬 ON" : "󰅖 OFF"; color: ThemeManager.topBarEnabled ? "#9bced7" : "#6e6a86"; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ThemeManager.topBarEnabled = !ThemeManager.topBarEnabled }
                        }

                        // Bottom Bar Toggle
                        Rectangle {
                            width: parent.width; height: 28; radius: 7
                            color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e"
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: "Bottom Bar"; color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 90 - botState.implicitWidth }
                                Text { id: botState; text: ThemeManager.bottomBarEnabled ? "󰄬 ON" : "󰅖 OFF"; color: ThemeManager.bottomBarEnabled ? "#9bced7" : "#6e6a86"; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ThemeManager.bottomBarEnabled = !ThemeManager.bottomBarEnabled }
                        }
                    }

                    // ════ 6. WALLPAPER SELECTOR BUTTON ════
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: wpBtnHover.containsMouse ? (settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7") : (settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#2a283e")
                        border.color: settingsPanel.rootBar ? settingsPanel.rootBar._cyn : "#9bced7"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰸉"
                                color: wpBtnHover.containsMouse ? "#181628" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4")
                                font.pixelSize: 12
                            }
                            Text {
                                text: "Launch Wallpaper Selector"
                                color: wpBtnHover.containsMouse ? "#181628" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#e0def4")
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: wpBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (settingsPanel.rootBar) {
                                    settingsPanel.rootBar.dismissPanels();
                                    settingsPanel.rootBar.wallpaperSelectorVisible = true;
                                }
                            }
                        }
                    }

                    Item { width: parent.width; height: 10 }
                }
            }
        }
    }

    function applyWallustMode(mode) {
        ThemeManager.modeChoice = mode;
        var flagCmd = "";
        if (mode === "light") {
            ThemeManager.isLightMode = true;
            flagCmd = "echo true > ~/.cache/quickshell/is_light_mode && ";
        } else if (mode === "dark") {
            ThemeManager.isLightMode = false;
            flagCmd = "echo false > ~/.cache/quickshell/is_light_mode && ";
        }
        var script = "mkdir -p ~/.cache/quickshell && " +
                     "echo '" + mode + "' > ~/.cache/quickshell/mode_choice && " +
                     flagCmd +
                     "bash $HOME/.config/scripts/wallpaper_picker.sh --reapply";
        toggleWallustProc.command = ["bash", "-c", script];
        toggleWallustProc.running = false;
        toggleWallustProc.running = true;
    }

    Process {
        id: toggleWallustProc
        command: ["bash", "-c", "echo idle"]
    }
}
