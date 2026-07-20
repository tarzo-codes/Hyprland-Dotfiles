import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../themes"

PanelWindow {
    id: settingsPanel
    required property var modelData
    screen: modelData
    
    implicitWidth: 240
    implicitHeight: 220
    
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
    
    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: settingsPanel.colors ? settingsPanel.colors.background : "#1a1b26"
        border.color: settingsPanel.colors ? settingsPanel.colors.surface : "#414868"
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
                color: settingsPanel.colors ? settingsPanel.colors.textMuted : "#6D8895"
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
                        color: settingsPanel.colors ? settingsPanel.colors.foreground : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: settingsPanel.rootBar ? settingsPanel.rootBar.barHeight + "px" : "40px"
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.colors ? settingsPanel.colors.surface : "#414868"
                    
                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
                        width: settingsPanel.rootBar ? 
                                   ((settingsPanel.rootBar.barHeight - 28) / (64 - 28)) * parent.width : 0
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            if (pressed && settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barHeight = Math.round(28 + pct * (64 - 28));
                            }
                        }
                        onPressed: (mouse) => {
                            if (settingsPanel.rootBar) {
                                var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                settingsPanel.rootBar.barHeight = Math.round(28 + pct * (64 - 28));
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
                        color: settingsPanel.colors ? settingsPanel.colors.foreground : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: settingsPanel.rootBar ? Math.round(settingsPanel.rootBar.barWidthPercent * 100) + "%" : "96%"
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.colors ? settingsPanel.colors.surface : "#414868"
                    
                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
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
                        color: settingsPanel.colors ? settingsPanel.colors.foreground : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: ThemeManager.globalFontSize + "px"
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: settingsPanel.colors ? settingsPanel.colors.surface : "#414868"

                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
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
            
            // --- Color Mode Toggle ---
            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: 6
                color: settingsPanel.colors ? settingsPanel.colors.surface : "#414868"
                border.color: settingsPanel.colors ? settingsPanel.colors.accent : "#7aa2f7"
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: ThemeManager.colorMode === "wallust" ? "󱥑 Wallust (Dynamic)" : " Static Theme"
                    color: settingsPanel.colors ? settingsPanel.colors.foreground : "#c0caf5"
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
        }
    }
}
