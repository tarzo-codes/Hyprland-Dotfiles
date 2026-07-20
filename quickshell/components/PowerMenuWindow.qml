import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powerWindow
    required property var modelData
    screen: modelData
    
    // Cover the full screen
    implicitWidth: screen.width
    implicitHeight: screen.height
    
    // Put it on overlay layer and grab keyboard focus so the user can press Escape to close it
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    color: "#cc0d0f18" // Semi-transparent dark background
    
    property var colors: null
    signal closeRequested()
    
    // Pressing ESC closes the menu
    Shortcut {
        sequence: "Escape"
        onActivated: powerWindow.closeRequested()
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: powerWindow.closeRequested()
    }
    
    Rectangle {
        anchors.centerIn: parent
        width: 650
        height: 240
        color: powerWindow.colors ? powerWindow.colors.background : "#1a1b26"
        border.color: powerWindow.colors ? powerWindow.colors.surface : "#414868"
        border.width: 1
        radius: 16
        
        // Fluid spring-bounce entry animation
        scale: 0.8
        opacity: 0
        
        Component.onCompleted: {
            scale = 1.0;
            opacity = 1.0;
        }
        
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        // Prevent click inside dialog from closing window
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20
            
            Text {
                text: "SYSTEM CONTROL"
                color: powerWindow.colors ? powerWindow.colors.textMuted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                spacing: 20
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                
                // Button Component Helper
                Repeater {
                    model: [
                        { name: "Lock", icon: "\uf023", command: ["hyprlock"] },
                        { name: "Suspend", icon: "\uf186", command: ["systemctl", "suspend"] },
                        { name: "Logout", icon: "\uf2f5", command: ["hyprctl", "dispatch", "exit"] },
                        { name: "Reboot", icon: "\uf021", command: ["systemctl", "reboot"] },
                        { name: "Shutdown", icon: "\uf011", command: ["systemctl", "poweroff"] }
                    ]
                    
                    delegate: Rectangle {
                        width: 110
                        height: 110
                        radius: 14
                        color: hoverArea.containsMouse ? (powerWindow.colors ? powerWindow.colors.surface : "#414868") : "transparent"
                        border.color: hoverArea.containsMouse ? (powerWindow.colors ? powerWindow.colors.accent : "#7aa2f7") : (powerWindow.colors ? powerWindow.colors.surface : "#414868")
                        border.width: 1
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: modelData.icon
                                color: hoverArea.containsMouse ? (powerWindow.colors ? powerWindow.colors.accent : "#7aa2f7") : (powerWindow.colors ? powerWindow.colors.foreground : "#c0caf5")
                                font.pixelSize: 36
                                font.family: "JetBrainsMono Nerd Font"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: modelData.name
                                color: powerWindow.colors ? powerWindow.colors.foreground : "#c0caf5"
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        
                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerWindow.closeRequested();
                                actionProc.command = modelData.command;
                                actionProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
    
    Process {
        id: actionProc
    }
}
