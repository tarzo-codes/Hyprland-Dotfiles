import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powerWindow
    required property var modelData
    screen: modelData
    
    implicitWidth: screen.width
    implicitHeight: screen.height
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    color: "#b00d0f18"
    
    property var colors: null
    property var rootBar: typeof shellRoot !== "undefined" ? shellRoot : null
    signal closeRequested()
    
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
        width: 660
        height: 230
        color: rootBar ? rootBar._bg : "#1a1b26"
        border.color: rootBar ? rootBar._cyn : "#414868"
        border.width: 1.5
        radius: 16
        
        scale: 0.9
        opacity: 0
        
        Component.onCompleted: {
            scale = 1.0;
            opacity = 1.0;
        }
        
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16
            
            Text {
                text: "󰐥  SYSTEM POWER CONTROL"
                color: rootBar ? rootBar._cyn : "#9bced7"
                font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.1
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                spacing: 14
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                
                Repeater {
                    model: [
                        { name: "Lock", icon: "󰌾", cmd: "hyprlock || loginctl lock-session" },
                        { name: "Suspend", icon: "󰤄", cmd: "systemctl suspend" },
                        { name: "Logout", icon: "󰍃", cmd: "hyprctl dispatch exit || loginctl terminate-user $USER" },
                        { name: "Reboot", icon: "󰜉", cmd: "systemctl reboot" },
                        { name: "Shutdown", icon: "󰐥", cmd: "systemctl poweroff" }
                    ]
                    
                    delegate: Rectangle {
                        width: 110
                        height: 110
                        radius: 14
                        color: hoverArea.containsMouse ? (rootBar ? rootBar._sur : "#414868") : (rootBar ? rootBar.alphaColor(rootBar._sur, 0.4) : "#1e1e2e")
                        border.color: hoverArea.containsMouse ? (rootBar ? rootBar._cyn : "#7aa2f7") : (rootBar ? rootBar.alphaColor(rootBar._muted, 0.3) : "#414868")
                        border.width: hoverArea.containsMouse ? 1.5 : 1
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: modelData.icon
                                color: hoverArea.containsMouse ? (rootBar ? rootBar._cyn : "#7aa2f7") : (rootBar ? rootBar._fg : "#c0caf5")
                                font.pixelSize: 34
                                font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: modelData.name
                                color: rootBar ? rootBar._fg : "#c0caf5"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
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
                                actionProc.command = ["bash", "-c", modelData.cmd];
                                actionProc.running = false;
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
        command: ["bash", "-c", "echo idle"]
    }
}
