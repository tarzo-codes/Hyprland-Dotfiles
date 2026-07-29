import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../themes"

Rectangle {
    id: root
    height: 26
    width: btRow.width + 16
    radius: 6
    color: hoverBt.containsMouse ? (colors ? Qt.darker(colors.surface, 1.2) : "#151520") : (colors ? colors.surface : "#1e1e2e")

    property var colors: null
    property var rootBar: null

    property bool isPowered: false
    property string connectedDevice: ""

    scale: hoverBt.containsMouse ? 1.06 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    RowLayout {
        id: btRow
        spacing: 6
        anchors.centerIn: parent

        // Dynamic Icon based on Bluetooth status
        Text {
            text: root.isPowered ? (root.connectedDevice !== "" ? "\uf293" : "\uf294") : "\uf294"
            color: root.isPowered ? (root.connectedDevice !== "" ? (root.colors ? root.colors.green : "#9ece6a") : (root.colors ? root.colors.blue : "#7aa2f7")) : (root.colors ? root.colors.textMuted : "#6D8895")
            font.pixelSize: root.rootBar ? root.rootBar.iconFontSize : Math.max(10, Math.round(ThemeManager.globalFontSize * 1.1))
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: btText
            text: !root.isPowered ? "Off" : (root.connectedDevice !== "" ? root.connectedDevice : "On")
            color: root.colors ? root.colors.foreground : "#c0caf5"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.rootBar ? root.rootBar.globalFontSize : ThemeManager.globalFontSize
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: hoverBt
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.rootBar) {
                root.rootBar.volumePanelVisible = false;
                root.rootBar.networkPanelVisible = false;
                root.rootBar.settingsVisible = false;
                root.rootBar.powerMenuVisible = false;
                root.rootBar.themeSelectorVisible = false;
                root.rootBar.bluetoothPanelVisible = !root.rootBar.bluetoothPanelVisible;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btQueryProc.running = true
    }

    Process {
        id: btQueryProc
        command: ["bash", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then dev=$(bluetoothctl devices Connected | head -n1 | cut -d' ' -f3-); if [ -n \"$dev\" ]; then echo \"POWERED:yes CONNECTED:$dev\"; else echo \"POWERED:yes CONNECTED:\"; fi; else echo \"POWERED:no CONNECTED:\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = this.text.trim()
                if (line.startsWith("POWERED:")) {
                    var isPoweredStr = line.split(" ")[0].replace("POWERED:", "")
                    var device = line.substring(line.indexOf("CONNECTED:") + 10)
                    root.isPowered = (isPoweredStr === "yes")
                    root.connectedDevice = device
                }
            }
        }
    }
}
