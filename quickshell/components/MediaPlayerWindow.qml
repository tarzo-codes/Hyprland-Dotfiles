import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: mediaWindow
    required property var modelData
    screen: modelData

    implicitWidth: 340
    implicitHeight: 180

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-media-player"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: !ThemeManager.barIsBottom
        bottom: ThemeManager.barIsBottom
        right: true
    }

    margins {
        top: !ThemeManager.barIsBottom ? (mediaWindow.rootBar ? mediaWindow.rootBar.barHeight + 6 : 48) : 0
        bottom: ThemeManager.barIsBottom ? (mediaWindow.rootBar ? mediaWindow.rootBar.barHeight + 6 : 48) : 0
        right: Math.round(mediaWindow.screen.width * 0.20)
    }

    color: "transparent"

    property var rootBar: null

    Rectangle {
        id: container
        anchors.fill: parent
        radius: 12
        color: mediaWindow.rootBar ? mediaWindow.rootBar._bg : "#1a1b26"
        border.color: mediaWindow.rootBar ? mediaWindow.rootBar._sur : "#24283b"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header: Title & Close Button
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰎈 Media Player"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._brightAcc : "#7aa2f7"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontSize + 1 : 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "✕"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._muted : "#565f89"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar) mediaWindow.rootBar.mediaPlayerVisible = false;
                        }
                    }
                }
            }

            // Song Info Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 8
                color: mediaWindow.rootBar ? mediaWindow.rootBar._sur : "#24283b"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Text {
                        text: "󰎆"
                        color: mediaWindow.rootBar ? mediaWindow.rootBar._brightCyn : "#7dcfff"
                        font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: mediaWindow.rootBar && mediaWindow.rootBar.songValue ? mediaWindow.rootBar.songValue : "No Track Playing"
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._fg : "#c0caf5"
                            font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontSize + 1 : 12
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: mediaWindow.rootBar && mediaWindow.rootBar.artistValue ? mediaWindow.rootBar.artistValue : (mediaWindow.rootBar && mediaWindow.rootBar.isPlaying ? "Playing" : "Paused")
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._brightBlu : "#7aa2f7"
                            font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontSize : 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Media Controls (Prev, Play/Pause, Next)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Text {
                    text: "\uf048"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._brightBlu : "#7aa2f7"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar && mediaWindow.rootBar.prevProc) mediaWindow.rootBar.prevProc.running = true;
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._brightGrn : "#9ece6a"

                    Text {
                        anchors.centerIn: parent
                        text: mediaWindow.rootBar && mediaWindow.rootBar.isPlaying ? "\uf04c" : "\uf04b"
                        color: mediaWindow.rootBar ? mediaWindow.rootBar._bg : "#1a1b26"
                        font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar && mediaWindow.rootBar.playProc) mediaWindow.rootBar.playProc.running = true;
                        }
                    }
                }

                Text {
                    text: "\uf051"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._brightBlu : "#7aa2f7"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar && mediaWindow.rootBar.nextProc) mediaWindow.rootBar.nextProc.running = true;
                        }
                    }
                }
            }
        }
    }
}
