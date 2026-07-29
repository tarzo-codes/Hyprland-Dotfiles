// CPU Widget - Reusable component for CPU monitoring
pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    property string icon: ""
    property string color: "#f7768e"
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
            id: cpuText
            anchors.centerIn: parent
            text: icon + " --%"
            color: textColor
            font.pixelSize: fontSize
            font.family: fontFamily

            Process {
                id: cpuProc
                command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: cpuText.text = icon + " " + this.text + "%"
                }
            }
        }
    }

    function update() {
        cpuProc.running = true
    }
}