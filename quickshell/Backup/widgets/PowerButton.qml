// PowerButton.qml - Reusable power button widget with integrated menu support
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../themes"

Item {
    id: root
    property var colors: ThemeManager.getCurrentColors()
    property int size: 26
    property bool hoverEnabled: true
    
    signal clicked()
    signal menuRequested()
    
    Rectangle {
        id: buttonRect
        width: root.size
        height: root.size
        radius: 6
        color: mouseArea.containsMouse ? colors.accent : colors.background
        border.color: colors.accent
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: ""
            color: mouseArea.containsMouse ? colors.foreground : colors.accent
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: root.hoverEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuRequested()
        }
    }
}