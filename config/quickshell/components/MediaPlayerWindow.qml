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

    implicitWidth: 420
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
        right: Math.round(mediaWindow.screen.width * 0.08)
    }

    color: "transparent"

    property var rootBar: null
    property bool isShuffle: false
    property bool isRepeat: false

    // Outer Main Card
    Rectangle {
        id: container
        anchors.fill: parent
        radius: 16
        color: mediaWindow.rootBar ? mediaWindow.rootBar._bg : "#0f0f18"
        border.color: mediaWindow.rootBar ? mediaWindow.rootBar.alphaColor(mediaWindow.rootBar._sur, 0.8) : "#1e1e2e"
        border.width: 1.5

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ═════════════════════════════════════════════════════════════════
            // ── LEFT SECTION: ALBUM ART CARD & SONG INFO ────────────────────
            // ═════════════════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: mediaWindow.rootBar ? mediaWindow.rootBar._sur : "#181826"
                clip: true

                // Background Art Overlay
                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    source: (mediaWindow.rootBar && mediaWindow.rootBar.artUrl) ? mediaWindow.rootBar.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.28
                    visible: source !== ""
                }

                // Dark Gradient Mask
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: mediaWindow.rootBar ? mediaWindow.rootBar.alphaColor(mediaWindow.rootBar._bg, 0.85) : "#d50d0f18" }
                        GradientStop { position: 1.0; color: mediaWindow.rootBar ? mediaWindow.rootBar.alphaColor(mediaWindow.rootBar._bg, 0.95) : "#e50d0f18" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    // Top Row: Shuffle / Repeat (Left) and Music Note Badge (Right)
                    RowLayout {
                        Layout.fillWidth: true

                        // Shuffle & Repeat icons
                        Row {
                            spacing: 10
                            Text {
                                text: "󰒟"
                                color: isShuffle ? (mediaWindow.rootBar ? mediaWindow.rootBar._grn : "#8ec07c") : (mediaWindow.rootBar ? mediaWindow.rootBar._muted : "#6e6a86")
                                font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: isShuffle = !isShuffle }
                            }
                            Text {
                                text: "󰑖"
                                color: isRepeat ? (mediaWindow.rootBar ? mediaWindow.rootBar._grn : "#8ec07c") : (mediaWindow.rootBar ? mediaWindow.rootBar._muted : "#6e6a86")
                                font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: isRepeat = !isRepeat }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Music Note Badge
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._mag : "#ea6f91"
                            Text {
                                anchors.centerIn: parent
                                text: "󰎈"
                                color: mediaWindow.rootBar ? mediaWindow.rootBar.contrastFg(mediaWindow.rootBar._mag, "#181628") : "#181628"
                                font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Middle: Song Title & Artist Line
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: mediaWindow.rootBar && mediaWindow.rootBar.songValue ? mediaWindow.rootBar.songValue : "Éxtasis"
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._fg : "#ffffff"
                            font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: mediaWindow.rootBar && mediaWindow.rootBar.artistValue ? mediaWindow.rootBar.artistValue : "Cartel De Santa / Millonario"
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._muted : "#907aa9"
                            font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Bottom: Progress Bar & Time Text
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Wallust Green Accent Progress Line
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: mediaWindow.rootBar ? mediaWindow.rootBar.alphaColor(mediaWindow.rootBar._sur, 0.8) : "#2a283e"

                            Rectangle {
                                height: parent.height
                                radius: 3
                                color: mediaWindow.rootBar ? mediaWindow.rootBar._grn : "#8ec07c" // Wallust green progress fill!
                                width: parent.width * 0.35
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }
                        }

                        // Time Display
                        Text {
                            text: "0:45 / 4:50"
                            color: mediaWindow.rootBar ? mediaWindow.rootBar._fg : "#e0def4"
                            font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════════
            // ── RIGHT SECTION: VERTICAL CONTROL BUTTONS ──────────────────────
            // ═════════════════════════════════════════════════════════════════
            ColumnLayout {
                Layout.preferredWidth: 44
                Layout.fillHeight: true
                spacing: 12

                Item { Layout.fillHeight: true }

                // Previous Track
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰒮"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._cyn : "#9bced7"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar && mediaWindow.rootBar.prevProc) {
                                mediaWindow.rootBar.prevProc.running = false;
                                mediaWindow.rootBar.prevProc.running = true;
                            }
                        }
                    }
                }

                // Play / Pause
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: mediaWindow.rootBar && mediaWindow.rootBar.isPlaying ? "󰏤" : "󰐊"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._fg : "#ffffff"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar) {
                                mediaWindow.rootBar.isPlaying = !mediaWindow.rootBar.isPlaying;
                                if (mediaWindow.rootBar.playProc) {
                                    mediaWindow.rootBar.playProc.running = false;
                                    mediaWindow.rootBar.playProc.running = true;
                                }
                            }
                        }
                    }
                }

                // Next Track
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰒭"
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._cyn : "#9bced7"
                    font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar && mediaWindow.rootBar.nextProc) {
                                mediaWindow.rootBar.nextProc.running = false;
                                mediaWindow.rootBar.nextProc.running = true;
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Close Button
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 20; height: 20; radius: 10
                    color: mediaWindow.rootBar ? mediaWindow.rootBar._red : "#ea6f91"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: mediaWindow.rootBar ? mediaWindow.rootBar.contrastFg(mediaWindow.rootBar._red, "#181628") : "#181628"
                        font.family: mediaWindow.rootBar ? mediaWindow.rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaWindow.rootBar) mediaWindow.rootBar.mediaPlayerVisible = false;
                        }
                    }
                }
            }
        }
    }
}
