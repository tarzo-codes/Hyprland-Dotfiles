// BaseButton.qml - Reusable base button widget for all themes
import QtQuick
import "../themes"

Rectangle {
    id: root
    property var colors: ThemeManager.getCurrentColors()
    property string symbol: ""
    property int fontSize: 12
    property int buttonWidth: 26
    property int buttonHeight: 26
    
    signal clicked()
    
    width: buttonWidth
    height: buttonHeight
    radius: 6
    color: hoverMouse.containsMouse ? colors.accent : colors.background
    border.color: colors.accent
    border.width: 1
    
    Text {
        anchors.centerIn: parent
        text: root.symbol
        color: hoverMouse.containsMouse ? colors.foreground : colors.accent
        font.pixelSize: root.fontSize
        font.family: "JetBrainsMono Nerd Font"
    }
    
    MouseArea {
        id: hoverMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}