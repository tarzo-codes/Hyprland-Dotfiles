// Time Widget - Reusable component for date/time display
pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    property string format: "%I:%M %P"
    property string bgColor: "#414868"
    property string textColor: "#c0caf5"
    property int fontSize: 9
    property string fontFamily: "JetBrainsMono"
    width: 60
    height: 20

    Rectangle {
        anchors.fill: parent
        color: bgColor
        Text {
            id: timeText
            anchors.centerIn: parent
            text: "--:-- PM"
            color: textColor
            font.pixelSize: fontSize
            font.family: fontFamily

            Process {
                id: timeProc
                command: ["date", "+%I:%M %P"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: timeText.text = " " + this.text + " "
                }
            }
        }
    }

    function update() {
        timeProc.running = true
    }
}