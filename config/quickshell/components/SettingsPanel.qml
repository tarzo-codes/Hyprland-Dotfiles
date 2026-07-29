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
    
    implicitWidth: 240
    implicitHeight: 300
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: settingsPanel.rootBar ? settingsPanel.rootBar.barHeight + 4 : 48
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
        color: settingsPanel.rootBar ? settingsPanel.rootBar._bg : "#1a1b26"
        border.color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868"
        border.width: 1
        radius: 10
        
        property real animOffset: -16
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
            
            Text {
                text: "BAR SETTINGS"
                color: settingsPanel.rootBar ? settingsPanel.rootBar._muted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignHCenter
            }
            
            // --- Height Control ---
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Height"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: settingsPanel.rootBar ? settingsPanel.rootBar.barHeight + "px" : "40px"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868"
                    
                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                        width: settingsPanel.rootBar ? 
                                   ((settingsPanel.rootBar.barHeight - 36) / (64 - 36)) * parent.width : 0
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            if (pressed && settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barHeight = Math.round(36 + pct * (64 - 36));
                            }
                        }
                        onPressed: (mouse) => {
                            if (settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barHeight = Math.round(36 + pct * (64 - 36));
                            }
                        }
                    }
                }
            }
            
            // --- Width Control ---
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Width"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: settingsPanel.rootBar ? Math.round(settingsPanel.rootBar.barWidthPercent * 100) + "%" : "96%"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868"
                    
                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                        width: settingsPanel.rootBar ? 
                                   ((settingsPanel.rootBar.barWidthPercent - 0.8) / (1.0 - 0.8)) * parent.width : 0
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            if (pressed && settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barWidthPercent = 0.8 + pct * (1.0 - 0.8);
                            }
                        }
                        onPressed: (mouse) => {
                            if (settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barWidthPercent = 0.8 + pct * (1.0 - 0.8);
                            }
                        }
                    }
                }
            }
            
            // --- Font Size Control ---
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Font Size"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: ThemeManager.globalFontSize + "px"
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868"

                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
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
            
            // --- Wallpaper Selector Launcher Button ---
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: wpBtnHover.containsMouse ? (settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7") : (settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868")
                border.color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "\uf03e"
                        color: wpBtnHover.containsMouse ? "#ffffff" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Wallpaper Selector"
                        color: wpBtnHover.containsMouse ? "#ffffff" : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5")
                        font.family: "JetBrainsMono Nerd Font"
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

            // --- Color Mode Toggle ---
            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: 6
                color: settingsPanel.rootBar ? settingsPanel.rootBar._sur : "#414868"
                border.color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: ThemeManager.colorMode === "wallust" ? "󱥑 Wallust (Dynamic)" : " Static Theme"
                    color: settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ThemeManager.colorMode = (ThemeManager.colorMode === "wallust") ? "static" : "wallust"
                    }
                }
            }

            // --- Dark / Auto / Light mode picker ---
            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 7
                color: settingsPanel.rootBar ? Qt.rgba(
                    Qt.color(settingsPanel.rootBar._bg).r,
                    Qt.color(settingsPanel.rootBar._bg).g,
                    Qt.color(settingsPanel.rootBar._bg).b, 0.6) : "#111118"
                border.color: settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7"
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    spacing: 0

                    // ─── 🌙 Dark ───
                    Rectangle {
                        width: parent.width / 3
                        height: parent.height
                        radius: 7
                        color: settingsPanel.modeChoice === "dark"
                               ? (settingsPanel.rootBar ? settingsPanel.rootBar._acc : "#7aa2f7")
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "🌙 Dark"
                            color: settingsPanel.modeChoice === "dark"
                                   ? "#ffffff"
                                   : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: settingsPanel.modeChoice === "dark"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                applyWallustMode("dark");
                            }
                        }
                    }

                    // ─── 🔆 Auto ───
                    Rectangle {
                        width: parent.width / 3
                        height: parent.height
                        color: settingsPanel.modeChoice === "auto"
                               ? "#16a34a"
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "🔆 Auto"
                            color: settingsPanel.modeChoice === "auto"
                                   ? "#ffffff"
                                   : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: settingsPanel.modeChoice === "auto"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                applyWallustMode("auto");
                            }
                        }
                    }

                    // ─── ☀️ Light ───
                    Rectangle {
                        width: parent.width / 3
                        height: parent.height
                        radius: 7
                        color: settingsPanel.modeChoice === "light"
                               ? "#2563eb"
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "☀️ Light"
                            color: settingsPanel.modeChoice === "light"
                                   ? "#ffffff"
                                   : (settingsPanel.rootBar ? settingsPanel.rootBar._fg : "#c0caf5")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: settingsPanel.modeChoice === "light"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                applyWallustMode("light");
                            }
                        }
                    }
                }
            }
        }
    }

    // mode: "dark" | "light" | "auto"
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
