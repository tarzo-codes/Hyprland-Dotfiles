import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../themes"

Item {
    id: brightnessComp
    required property var rootBar
    width: brightRow.implicitWidth + 12
    height: 30
    visible: rootBar ? rootBar.brightnessValue > 0 : true

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: brightMouse.containsMouse ? (brightnessComp.rootBar ? brightnessComp.rootBar.alphaColor(brightnessComp.rootBar._acc, 0.2) : "#207aa2f7") : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        id: brightRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "\uf185"
            color: brightnessComp.rootBar ? brightnessComp.rootBar._brightYel : "#e0af68"
            font.family: brightnessComp.rootBar ? brightnessComp.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: brightnessComp.rootBar ? brightnessComp.rootBar.iconFontSize : 13
        }

        Text {
            text: brightnessComp.rootBar ? Math.round(brightnessComp.rootBar.brightnessValue * 100) + "%" : "100%"
            color: brightnessComp.rootBar ? brightnessComp.rootBar._fg : "#c0caf5"
            font.family: brightnessComp.rootBar ? brightnessComp.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: brightnessComp.rootBar ? brightnessComp.rootBar.globalFontSize : 11
            font.bold: true
        }
    }

    MouseArea {
        id: brightMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (brightnessComp.rootBar) {
                brightnessComp.rootBar.brightnessPanelVisible = !brightnessComp.rootBar.brightnessPanelVisible;
            }
        }
        onWheel: (wheel) => {
            if (brightnessComp.rootBar) {
                var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                brightnessComp.rootBar.brightnessValue = Math.max(0.05, Math.min(1.0, brightnessComp.rootBar.brightnessValue + delta));
                if (brightnessComp.rootBar.brightCommitTimer) brightnessComp.rootBar.brightCommitTimer.restart();
            }
        }
    }
}
