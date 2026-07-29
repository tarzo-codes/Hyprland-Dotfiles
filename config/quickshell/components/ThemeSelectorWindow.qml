import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../themes"

PanelWindow {
    id: themeSelector

    required property var modelData
    screen: modelData

    property var  colors:    null
    property var  rootBar:   null
    property bool isVisible: false
    visible: isVisible

    implicitWidth:  360
    implicitHeight: 480

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-theme-selector"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top:    true
        bottom: true
        left:   true
        right:  true
    }

    margins {
        top:    Math.round((screen.height - implicitHeight) / 2)
        bottom: Math.round((screen.height - implicitHeight) / 2)
        left:   Math.round((screen.width  - implicitWidth)  / 2)
        right:  Math.round((screen.width  - implicitWidth)  / 2)
    }

    color: "transparent"

    Rectangle {
        id: bg
        anchors.fill: parent
        color: rootBar ? rootBar._bg : (themeSelector.colors ? themeSelector.colors.background : "#1a1b26")
        border.color: rootBar ? rootBar._acc : (themeSelector.colors ? themeSelector.colors.accent : "#7aa2f7")
        border.width: 1
        radius: 14

        scale: animReady ? 1.0 : 0.88
        opacity: animReady ? 1.0 : 0.0
        property bool animReady: false
        Component.onCompleted: animReady = true
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 160 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "  Theme Selector"
                    color: rootBar ? rootBar._fg : (themeSelector.colors ? themeSelector.colors.foreground : "#c0caf5")
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 24; height: 24
                    radius: 12
                    color: closeMa.containsMouse
                           ? (rootBar ? rootBar._red : "#f7768e")
                           : (rootBar ? rootBar._sur : "#414868")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMa.containsMouse ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themeSelector.isVisible = false
                    }
                }
            }

            // Color mode toggle
            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: rootBar ? rootBar._sur : "#414868"
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: ThemeManager.colorMode === "wallust" ? "󱥑  Wallust (Dynamic)" : "  Static Theme"
                    color: rootBar ? rootBar._fg : "#c0caf5"
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ThemeManager.colorMode = (ThemeManager.colorMode === "wallust") ? "static" : "wallust"
                }
            }

            // Search
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 7
                color: rootBar ? rootBar._sur : "#414868"
                border.color: searchInput.activeFocus
                             ? (rootBar ? rootBar._acc : "#7aa2f7")
                             : "transparent"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text {
                        text: "🔍"
                        color: rootBar ? rootBar._muted : "#6D8895"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        width: parent.width - 30
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            visible: searchInput.text.length === 0
                            text: "Search themes..."
                            color: rootBar ? rootBar._muted : "#6D8895"
                            font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            selectByMouse: true
                        }
                    }
                }
            }

            // Theme grid
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: 8
                clip: true

                ScrollView {
                    id: sv
                    anchors.fill: parent
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Flow {
                        id: themeFlow
                        width: sv.width - 8
                        spacing: 6
                        padding: 2

                        Repeater {
                            model: {
                                var all = ThemeManager.availableThemes;
                                if (searchInput.text.length === 0) return all;
                                return all.filter(function(t) {
                                    return t.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1;
                                });
                            }
                            delegate: Rectangle {
                                width: (sv.width - 20) / 2
                                height: 32
                                radius: 8
                                color: ThemeManager.themeName === modelData
                                       ? (rootBar ? rootBar._acc : "#7aa2f7")
                                       : (themeHover.containsMouse
                                          ? (rootBar ? rootBar._sur : "#2a2b3d")
                                          : (rootBar ? rootBar.alphaColor(rootBar._sur, 0.4) : "#222330"))
                                border.color: ThemeManager.themeName === modelData ? (rootBar ? rootBar._acc : "#7aa2f7") : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Rectangle {
                                    visible: ThemeManager.themeName === modelData
                                    width: 3; height: parent.height * 0.55
                                    radius: 2
                                    anchors.left: parent.left; anchors.leftMargin: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: rootBar ? rootBar.contrastFg(rootBar._acc, "#ffffff") : "#ffffff"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: ThemeManager.themeName === modelData
                                           ? (rootBar ? rootBar.contrastFg(rootBar._acc, "#ffffff") : "#ffffff")
                                           : (rootBar ? rootBar._fg : "#c0caf5")
                                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: ThemeManager.themeName === modelData
                                }

                                MouseArea {
                                    id: themeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ThemeManager.themeName = modelData
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
