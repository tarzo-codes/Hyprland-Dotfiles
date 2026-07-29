import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: lightPromptWindow
    required property var modelData
    screen: modelData

    implicitWidth: 380
    implicitHeight: 200

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-light-prompt"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: lightPromptWindow.rootBar ? lightPromptWindow.rootBar.barHeight + 12 : 50
        right: Math.round(lightPromptWindow.screen.width * 0.05)
    }

    color: "transparent"

    property var rootBar: null
    property string wallpaperPath: ""

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._bg : "#181825"
        border.color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._acc : "#7aa2f7"
        border.width: 1.5
        radius: 14

        property real animOffset: -20
        y: animOffset
        opacity: 0

        Component.onCompleted: {
            animOffset = 0;
            opacity = 1.0;
        }

        Behavior on animOffset { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Title Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "☀️"
                    font.pixelSize: 18
                }

                Text {
                    text: "BRIGHT WALLPAPER DETECTED"
                    color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._fg : "#c0caf5"
                    font.family: lightPromptWindow.rootBar ? lightPromptWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.05)
                    font.bold: true
                    font.letterSpacing: 1.1
                    Layout.fillWidth: true
                }
            }

            // Prompt message body
            Text {
                text: "This wallpaper is bright. Would you like to switch to Light Mode for optimal contrast and readability?"
                color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._muted : "#94a3b8"
                font.family: lightPromptWindow.rootBar ? lightPromptWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            // Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Keep Dark Mode Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: darkBtnMouse.containsMouse ? (lightPromptWindow.rootBar ? lightPromptWindow.rootBar._sur : "#2a2d3d") : "transparent"
                    border.color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._muted : "#565f89"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🌙 Keep Dark Mode"
                        color: lightPromptWindow.rootBar ? lightPromptWindow.rootBar._fg : "#c0caf5"
                        font.family: lightPromptWindow.rootBar ? lightPromptWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: ThemeManager.globalFontSize
                        font.bold: true
                    }

                    MouseArea {
                        id: darkBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ThemeManager.isLightMode = false;
                            lightPromptWindow.runWallust("dark");
                            if (lightPromptWindow.rootBar) lightPromptWindow.rootBar.lightModePromptVisible = false;
                        }
                    }
                }

                // Switch to Light Mode Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: lightBtnMouse.containsMouse ? (lightPromptWindow.rootBar ? lightPromptWindow.rootBar._acc : "#2563eb") : (lightPromptWindow.rootBar ? lightPromptWindow.rootBar.alphaColor(lightPromptWindow.rootBar._acc, 0.85) : "#3b82f6")

                    Text {
                        anchors.centerIn: parent
                        text: "☀️ Switch to Light Mode"
                        color: "#ffffff"
                        font.family: lightPromptWindow.rootBar ? lightPromptWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: ThemeManager.globalFontSize
                        font.bold: true
                    }

                    MouseArea {
                        id: lightBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ThemeManager.isLightMode = true;
                            lightPromptWindow.runWallust("light");
                            if (lightPromptWindow.rootBar) lightPromptWindow.rootBar.lightModePromptVisible = false;
                        }
                    }
                }
            }
        }
    }

    function runWallust(mode) {
        var flag = (mode === "light") ? "true" : "false";
        var script = "mkdir -p ~/.cache/quickshell && " +
                     "echo '" + flag + "' > ~/.cache/quickshell/is_light_mode && " +
                     "bash $HOME/.config/scripts/wallpaper_picker.sh --reapply";
        applyWallustProc.command = ["bash", "-c", script];
        applyWallustProc.running = false;
        applyWallustProc.running = true;
    }

    Process {
        id: applyWallustProc
        command: ["bash", "-c", "echo idle"]
    }
}
