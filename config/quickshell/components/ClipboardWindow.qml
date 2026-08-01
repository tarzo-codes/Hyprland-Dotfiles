import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: clipWindow
    required property var modelData
    screen: modelData

    implicitWidth: screen.width
    implicitHeight: screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "#b00d0f18"

    property var colors: null
    property var rootBar: null
    property var clipList: []
    property string filterText: ""
    signal closeRequested()

    Shortcut {
        sequence: "Escape"
        onActivated: clipWindow.closeRequested()
    }

    Process {
        id: fetchClipProc
        command: ["bash", "-c", "wl-paste 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var current = this.text.trim();
                if (current !== "") {
                    var list = clipWindow.clipList.slice();
                    if (list.indexOf(current) === -1) {
                        list.unshift(current);
                        if (list.length > 30) list.pop();
                        clipWindow.clipList = list;
                    }
                }
            }
        }
        Component.onCompleted: running = true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 580
        height: 420
        color: rootBar ? rootBar._bg : "#161622"
        border.color: rootBar ? rootBar._cyn : "#9bced7"
        border.width: 1.5
        radius: 14
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header & Search
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "󰅍  CLIPBOARD MANAGER"
                    color: rootBar ? rootBar._cyn : "#9bced7"
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
            }

            // Search Bar Input
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 6
                color: rootBar ? rootBar._sur : "#1e1e2e"
                border.color: rootBar ? rootBar._cyn : "#9bced7"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 8
                    Text { text: "󰍉"; color: rootBar ? rootBar._muted : "#6e6a86"; font.pixelSize: 12 }
                    TextInput {
                        Layout.fillWidth: true
                        text: clipWindow.filterText
                        color: rootBar ? rootBar._fg : "#e0def4"
                        font.pixelSize: 11
                        onTextChanged: clipWindow.filterText = text
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootBar ? rootBar.alphaColor(rootBar._muted, 0.3) : "#2a283e" }

            // Scrollable History Items
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: clipCol.implicitHeight
                clip: true

                Column {
                    id: clipCol
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: clipWindow.clipList.filter(function(item) {
                            return clipWindow.filterText === "" || item.toLowerCase().indexOf(clipWindow.filterText.toLowerCase()) !== -1;
                        })
                        delegate: Rectangle {
                            width: parent.width
                            height: 44
                            radius: 8
                            color: clipMouse.containsMouse ? (rootBar ? rootBar.alphaColor(rootBar._cyn, 0.2) : "#31748f") : (rootBar ? rootBar._sur : "#1e1e2e")
                            border.color: clipMouse.containsMouse ? (rootBar ? rootBar._cyn : "#9bced7") : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: "󰅍"
                                    color: rootBar ? rootBar._cyn : "#9bced7"
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: modelData
                                    color: rootBar ? rootBar._fg : "#e0def4"
                                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Copy 󰆏"
                                    color: clipMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._muted : "#6e6a86")
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: clipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    copyProc.command = ["bash", "-c", "printf '%s' " + JSON.stringify(modelData) + " | wl-copy"];
                                    copyProc.running = true;
                                    clipWindow.closeRequested();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: copyProc
        command: ["bash", "-c", "echo idle"]
    }
}
