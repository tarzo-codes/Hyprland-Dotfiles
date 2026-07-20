import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    height: 26
    width: netRow.width + 16
    radius: 6
    color: hoverNet.containsMouse ? (colors ? Qt.darker(colors.surface, 1.2) : "#151520") : (colors ? colors.surface : "#1e1e2e")

    property var colors: null
    property var rootBar: null

    property string netType: "wired"
    property string netSpeed: "..."

    scale: hoverNet.containsMouse ? 1.06 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    RowLayout {
        id: netRow
        spacing: 6
        anchors.centerIn: parent

        // Dynamic Icon based on Connection Type (Wired vs Wi-Fi vs Offline)
        Text {
            text: root.netType === "wifi" ? "\uf1eb" : (root.netType === "wired" ? "\uf0ec" : "\uf127")
            color: root.netType !== "offline" ? (root.colors ? root.colors.green : "#9ece6a") : (root.colors ? root.colors.red : "#f7768e")
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: netText
            text: root.netSpeed
            color: root.colors ? root.colors.foreground : "#c0caf5"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: hoverNet
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.rootBar) {
                root.rootBar.volumePanelVisible = false;
                root.rootBar.settingsVisible = false;
                root.rootBar.powerMenuVisible = false;
                root.rootBar.themeSelectorVisible = false;
                root.rootBar.networkPanelVisible = !root.rootBar.networkPanelVisible;
            } else {
                networkProc.running = true;
            }
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netSpeedProc.running = true
    }

    Process {
        id: netSpeedProc
        command: ["bash", "-c", "IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1); if [ -z \"$IFACE\" ]; then echo \"TYPE:offline SPEED:Offline\"; elif [[ \"$IFACE\" == wl* ]]; then read -r rx1 tx1 < <(awk -v dev=\"$IFACE\" '$1 ~ dev {print $2, $10}' /proc/net/dev); sleep 0.5; read -r rx2 tx2 < <(awk -v dev=\"$IFACE\" '$1 ~ dev {print $2, $10}' /proc/net/dev); rx_speed=$(( (rx2 - rx1) * 2 / 1024 )); if [ $rx_speed -ge 1024 ]; then spd=$(printf \"%.1f MB/s\" \"$(echo \"$rx_speed / 1024\" | bc -l)\"); else spd=\"${rx_speed} KB/s\"; fi; echo \"TYPE:wifi SPEED:$spd\"; else read -r rx1 tx1 < <(awk -v dev=\"$IFACE\" '$1 ~ dev {print $2, $10}' /proc/net/dev); sleep 0.5; read -r rx2 tx2 < <(awk -v dev=\"$IFACE\" '$1 ~ dev {print $2, $10}' /proc/net/dev); rx_speed=$(( (rx2 - rx1) * 2 / 1024 )); if [ $rx_speed -ge 1024 ]; then spd=$(printf \"%.1f MB/s\" \"$(echo \"$rx_speed / 1024\" | bc -l)\"); else spd=\"${rx_speed} KB/s\"; fi; echo \"TYPE:wired SPEED:$spd\"; fi"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                var line = data.trim()
                if (line.startsWith("TYPE:")) {
                    var parts = line.split(" ")
                    var t = parts[0].replace("TYPE:", "")
                    var s = parts.slice(1).join(" ").replace("SPEED:", "")
                    root.netType = t
                    root.netSpeed = s
                }
            }
        }
    }

    Process {
        id: networkProc
        command: ["nm-connection-editor"]
    }
}
