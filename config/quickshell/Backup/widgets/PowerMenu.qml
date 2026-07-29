// PowerMenu.qml - Reusable power menu widget for all themes
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../themes"

Item {
    id: root
    property var colors: ThemeManager.getCurrentColors()
    
    signal shutdownClicked()
    signal rebootClicked()
    signal logoutClicked()
    
    Rectangle {
        width: 120
        height: 90
        color: colors.background
        radius: 8
        border.color: colors.accent
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 4
                color: hoverShutdown.containsMouse ? colors.accent : colors.background
                Text {
                    anchors.centerIn: parent
                    text: " Shutdown"
                    color: hoverShutdown.containsMouse ? colors.foreground : colors.accent
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
                MouseArea {
                    id: hoverShutdown
                    anchors.fill: parent
                    onClicked: root.shutdownClicked()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 4
                color: hoverReboot.containsMouse ? colors.accent : colors.background
                Text {
                    anchors.centerIn: parent
                    text: " Reboot"
                    color: hoverReboot.containsMouse ? colors.foreground : colors.accent
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
                MouseArea {
                    id: hoverReboot
                    anchors.fill: parent
                    onClicked: root.rebootClicked()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 4
                color: hoverLogout.containsMouse ? colors.accent : colors.background
                Text {
                    anchors.centerIn: parent
                    text: " Logout"
                    color: hoverLogout.containsMouse ? colors.foreground : colors.accent
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
                MouseArea {
                    id: hoverLogout
                    anchors.fill: parent
                    onClicked: root.logoutClicked()
                }
            }
        }
    }
}