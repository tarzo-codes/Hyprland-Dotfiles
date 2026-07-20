// Volume Widget - Reusable component for volume monitoring
pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    property string icon: ""
    property string bgColor: "#414868"
    property string textColor: "#c0caf5"
    property int fontSize: 9
    property string fontFamily: "JetBrainsMono"
    width: 50
    height: 20

    Rectangle {
        anchors.fill: parent
        color: bgColor
        Text {
            id: volText
            anchors.centerIn: parent
            text: icon + " 100%"
            color: textColor
            font.pixelSize: fontSize
            font.family: fontFamily

            Process {
                id: volProc
                command: ["bash", "-c", "pamixer --get-volume 2>/dev/null || echo 100"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: volText.text = icon + " " + this.text + "%"
                }
            }
        }
    }

    function update() {
        volProc.running = true
    }
}