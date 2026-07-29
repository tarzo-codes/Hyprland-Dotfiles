// Memory Widget - Reusable component for memory monitoring
pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    property string icon: ""
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
            id: memText
            anchors.centerIn: parent
            text: icon + " -- MB"
            color: textColor
            font.pixelSize: fontSize
            font.family: fontFamily

            Process {
                id: memProc
                command: ["bash", "-c", "free -m | awk '/Mem:/ {print $3}'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: memText.text = icon + " " + this.text + " MB"
                }
            }
        }
    }

    function update() {
        memProc.running = true
    }
}