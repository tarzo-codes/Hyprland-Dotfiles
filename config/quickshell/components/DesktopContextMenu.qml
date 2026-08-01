import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: contextWindow
    required property var modelData
    screen: modelData

    implicitWidth: screen.width
    implicitHeight: screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "#70000000"

    property var colors: null
    property var rootBar: null
    signal closeRequested()

    Shortcut {
        sequence: "Escape"
        onActivated: contextWindow.closeRequested()
    }

    // Dismiss on clicking backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: contextWindow.closeRequested()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 240
        height: 250
        color: rootBar ? rootBar._bg : "#161622"
        border.color: rootBar ? rootBar._cyn : "#9bced7"
        border.width: 1.5
        radius: 12
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            // Header
            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                Text { text: "󰏘"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 12 }
                Text { text: "DESKTOP ACTIONS"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.0 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootBar ? rootBar.alphaColor(rootBar._muted, 0.3) : "#2a283e" }

            // Action Items
            // 1. Terminal
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item1.containsMouse ? (rootBar ? rootBar._sur : "#2a283e") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰆍"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Open Terminal"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { runProc.command = ["kitty"]; runProc.running = true; contextWindow.closeRequested(); } }
            }

            // 2. Files
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item2.containsMouse ? (rootBar ? rootBar._sur : "#2a283e") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰉋"; color: rootBar ? rootBar._yel : "#f1ca93"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "File Manager"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { runProc.command = ["dolphin"]; runProc.running = true; contextWindow.closeRequested(); } }
            }

            // 3. Browser
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item3.containsMouse ? (rootBar ? rootBar._sur : "#2a283e") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰖟"; color: rootBar ? rootBar._red : "#ea6f91"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Web Browser"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { runProc.command = ["zen-browser"]; runProc.running = true; contextWindow.closeRequested(); } }
            }

            // 4. Rice Control Center
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item4.containsMouse ? (rootBar ? rootBar._sur : "#2a283e") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰒓"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Rice Control Center"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item4; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (rootBar) { rootBar.dismissPanels(); rootBar.riceEditorVisible = true; } contextWindow.closeRequested(); } }
            }

            // 5. Wallpaper Picker
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item5.containsMouse ? (rootBar ? rootBar._sur : "#2a283e") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰸉"; color: rootBar ? rootBar._mag : "#c3a5e6"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Wallpaper Picker"; color: rootBar ? rootBar._fg : "#e0def4"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item5; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (rootBar) { rootBar.dismissPanels(); rootBar.wallpaperSelectorVisible = true; } contextWindow.closeRequested(); } }
            }

            // 6. Power Menu
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: item6.containsMouse ? "#ea6f91" : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Text { text: "󰐥"; color: item6.containsMouse ? "#181628" : "#ea6f91"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Power Menu"; color: item6.containsMouse ? "#181628" : "#ea6f91"; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: item6; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (rootBar) { rootBar.dismissPanels(); rootBar.powerMenuVisible = true; } contextWindow.closeRequested(); } }
            }
        }
    }

    Process {
        id: runProc
        command: ["bash", "-c", "echo idle"]
    }
}
