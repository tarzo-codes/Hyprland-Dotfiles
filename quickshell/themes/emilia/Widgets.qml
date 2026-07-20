// Widgets for the emilia theme (Tokyo Night)
// Converted from polybar config to Quickshell QML

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Time/Date widget
QtObject {
    readonly property string timeFormat: "HH:mm"
    
    // Process for getting time
    readonly property Process timeProc: Process {
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: parent.timeText = this.text
        }
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: timeProc.running = true
        }
    }
}