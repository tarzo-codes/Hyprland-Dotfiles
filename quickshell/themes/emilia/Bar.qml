// Bar.qml - Emilia theme bar implementation
// Converted from polybar config (emi-bar)
// Tokyo Night colorscheme

import QtQuick
import Quickshell
import "Colors.qml" as Colors

PanelWindow {
    id: root

    // The screen from the screens list will be injected into this property
    required property var modelData
    screen: modelData

    // Polybar positioning: top anchored with offsets
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 26

    // Background rectangle matching polybar dimensions
    // width = 90%, offset-x = 5%, offset-y = 8
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 8
            leftMargin: parent.width * 0.05
            rightMargin: parent.width * 0.05
        }
        height: 26
        color: Colors.background
        radius: 4.0
        border.color: Colors.surface
        border.width: 1

        Row {
            id: barContent
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            // Left modules from polybar config
            
            // Launcher module
            Text {
                text: "󰣇"
                color: "#0A9CF5"  // blue-arch from config
                font.family: "Material Design Icons Desktop"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // Dots separator
            Text {
                text: " 󰇙 "
                color: "#6D8895"  // blue-gray from config
                font.family: "Material Design Icons Desktop"
                font.pixelSize: 11
            }

            // Bi bracket (left) - mb color background
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }

            // CPU module
            Text {
                id: cpuText
                text: " 0%"
                color: Colors.foreground
                background: Colors.surface
                font.pixelSize: 9
                font.family: "JetBrainsMono"
                padding: 4
            }

            // Bd bracket (right) - mb color background
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }

            Item { width: 8 }

            // Memory module
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }
            Text {
                text: " 0%"
                color: Colors.foreground
                background: Colors.surface
                font.pixelSize: 9
                font.family: "JetBrainsMono"
                padding: 4
            }
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }

            Item { width: 8 }

            // Filesystem module
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }
            Text {
                text: " 0%"
                color: Colors.foreground
                background: Colors.surface
                font.pixelSize: 9
                font.family: "JetBrainsMono"
                padding: 4
            }
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }

            Item { width: 8 }

            // MPD Control
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }
            Text {
                text: "  "
                color: Colors.lime
                background: Colors.surface
                font.pixelSize: 9
                font.family: "Material Design Icons Desktop"
                padding: 4
            }
            Text {
                text: ""
                color: Colors.surface
                font.family: "MesloLGS NF"
                font.pixelSize: 17
            }

            // Spacer to push right modules to the end
            Item { Layout.fillWidth: true }

            // Center/Right: Workspaces
            Text {
                id: workspacesText
                text: "󰊠 󰊠 󰊠"
                color: Colors.yellow
                font.family: "Material Design Icons Desktop"
                font.pixelSize: 11
            }

            // Spacer
            Item { Layout.fillWidth: true }

            // Right modules
            Text {
                text: ""
                color: Colors.green
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 10
            }

            // Power module
            Text {
                text: ""
                color: Colors.red
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 10
            }
        }
    }
}