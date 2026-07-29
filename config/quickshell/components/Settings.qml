// Settings Panel - Adjust bar height and other settings
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: settingsPanel
    required property var modelData
    screen: modelData

    // Position on right side of screen
    anchors {
        right: true
        top: true
    }

    implicitWidth: 200
    implicitHeight: 100

    visible: false

    Rectangle {
        anchors.fill: parent
        color: "#1a1b26"
        radius: 4.0
        border.color: "#414868"

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Bar Settings"
                color: "#c0caf5"
                font.family: "JetBrainsMono"
                font.pixelSize: 12
            }

            Row {
                Text {
                    text: "Height:"
                    color: "#c0caf5"
                    font.family: "JetBrainsMono"
                    font.pixelSize: 10
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: 80
                    height: 20
                    color: "#414868"
                    radius: 2

                    TextInput {
                        anchors.centerIn: parent
                        text: "28"
                        color: "#c0caf5"
                        font.family: "JetBrainsMono"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        validator: IntValidator { bottom: 20; top: 50 }
                        onAccepted: {
                            // Update bar height
                            settingsPanel.applyHeight(text)
                        }
                    }
                }

                Text {
                    text: "px"
                    color: "#6D8895"
                    font.family: "JetBrainsMono"
                    font.pixelSize: 10
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 80
                    height: 24
                    color: "#414868"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: "#9ece6a"
                        font.family: "JetBrainsMono"
                        font.pixelSize: 9
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            settingsPanel.applyHeight(settingsPanel.findHeightInput().text)
                            settingsPanel.visible = false
                        }
                    }
                }

                Rectangle {
                    width: 80
                    height: 24
                    color: "#f7768e"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: "#1a1b26"
                        font.family: "JetBrainsMono"
                        font.pixelSize: 9
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: settingsPanel.visible = false
                    }
                }
            }
        }
    }

    function applyHeight(heightStr) {
        var height = parseInt(heightStr)
        if (height >= 20 && height <= 50) {
            // Write to config file
            var configPath = Qt.resolvedUrl("../../shell.qml")
            // Update would need to be implemented with file I/O
            console.log("Applying height: " + height)
        }
    }

    function findHeightInput() {
        return settingsPanel.children[0].children[1].children[1]
    }
}