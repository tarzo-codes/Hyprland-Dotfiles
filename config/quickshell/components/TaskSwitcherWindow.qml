import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: switcherWindow
    required property var modelData
    screen: modelData

    implicitWidth: screen.width
    implicitHeight: screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-task-switcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    color: "#a00d0f18"

    property var colors: null
    property var rootBar: null
    property var windowList: []
    property int selectedIndex: 0
    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            getClientsProc.running = false;
            getClientsProc.running = true;
            keyFocusItem.forceActiveFocus();
        }
    }

    Item {
        id: keyFocusItem
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) {
                switcherWindow.selectNext();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                switcherWindow.closeRequested();
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr || event.key === Qt.Key_Meta) {
                switcherWindow.activateSelected();
                switcherWindow.closeRequested();
                event.accepted = true;
            }
        }
    }

    function selectNext() {
        if (windowList.length > 0) {
            selectedIndex = (selectedIndex + 1) % windowList.length;
        }
    }

    function activateSelected() {
        if (windowList.length > 0 && selectedIndex < windowList.length) {
            var win = windowList[selectedIndex];
            var inner = "hyprctl dispatch focuswindow address:" + win.address;
            if (win.centerX !== undefined && win.centerY !== undefined) {
                inner += " && hyprctl dispatch movecursor " + win.centerX + " " + win.centerY;
            }
            var luaArg = 'hl.dsp.exec_cmd("' + inner + '")';
            focusWindowProc.command = ["hyprctl", "dispatch", luaArg];
            focusWindowProc.running = false;
            focusWindowProc.running = true;
        }
    }

    Process {
        id: getClientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    var list = [];
                    for (var i = 0; i < data.length; i++) {
                        if (data[i].title && data[i].title !== "") {
                            var at = data[i].at || [0, 0];
                            var sz = data[i].size || [800, 600];
                            var cx = Math.round(at[0] + sz[0] / 2);
                            var cy = Math.round(at[1] + sz[1] / 2);
                            list.push({
                                address: data[i].address,
                                title: data[i].title,
                                class: data[i].class,
                                workspace: data[i].workspace ? data[i].workspace.id : 1,
                                centerX: cx,
                                centerY: cy
                            });
                        }
                    }
                    switcherWindow.windowList = list;
                    if (list.length > 1 && switcherWindow.selectedIndex === 0) {
                        switcherWindow.selectedIndex = 1;
                    }
                } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 620
        height: 380
        color: rootBar ? rootBar._bg : "#161622"
        border.color: rootBar ? rootBar._cyn : "#9bced7"
        border.width: 1.5
        radius: 14
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰕰  TASK SWITCHER"
                    color: rootBar ? rootBar._cyn : "#9bced7"
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: windowList.length + " Active Windows (Hold Alt + Tab)"
                    color: rootBar ? rootBar._muted : "#6e6a86"
                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootBar ? rootBar.alphaColor(rootBar._muted, 0.3) : "#2a283e" }

            // Scrollable List of Windows
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: winCol.implicitHeight
                clip: true

                Column {
                    id: winCol
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: switcherWindow.windowList
                        delegate: Rectangle {
                            width: parent.width
                            height: 52
                            radius: 8
                            color: switcherWindow.selectedIndex === index ? (rootBar ? rootBar.alphaColor(rootBar._cyn, 0.25) : "#31748f") : (rootBar ? rootBar._sur : "#1e1e2e")
                            border.color: switcherWindow.selectedIndex === index ? (rootBar ? rootBar._cyn : "#9bced7") : "transparent"
                            border.width: switcherWindow.selectedIndex === index ? 1.5 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 12

                                // App Icon Badge
                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: rootBar ? rootBar.alphaColor(rootBar._bg, 0.6) : "#111118"

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            var cls = (modelData.class || "").toLowerCase();
                                            if (cls.indexOf("kitty") !== -1) return "󰆍";
                                            if (cls.indexOf("dolphin") !== -1) return "󰉋";
                                            if (cls.indexOf("zen") !== -1 || cls.indexOf("firefox") !== -1) return "󰖟";
                                            if (cls.indexOf("discord") !== -1 || cls.indexOf("vesktop") !== -1) return "󰙯";
                                            if (cls.indexOf("steam") !== -1) return "󰓓";
                                            if (cls.indexOf("lutris") !== -1) return "󰊴";
                                            if (cls.indexOf("code") !== -1) return "󰨞";
                                            if (cls.indexOf("spotify") !== -1) return "󰓇";
                                            return "󰀉";
                                        }
                                        color: {
                                            var cls = (modelData.class || "").toLowerCase();
                                            if (ThemeManager.appColorMode === "real") {
                                                if (cls.indexOf("kitty") !== -1) return "#4A90E2";
                                                if (cls.indexOf("dolphin") !== -1) return "#1C9EFF";
                                                if (cls.indexOf("zen") !== -1) return "#33D17A";
                                                if (cls.indexOf("discord") !== -1 || cls.indexOf("vesktop") !== -1) return "#5865F2";
                                                if (cls.indexOf("steam") !== -1) return "#C7D5E0";
                                                if (cls.indexOf("lutris") !== -1) return "#F57C00";
                                                if (cls.indexOf("code") !== -1) return "#007ACC";
                                                if (cls.indexOf("spotify") !== -1) return "#1DB954";
                                            }
                                            return rootBar ? rootBar._cyn : "#9bced7";
                                        }
                                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 18
                                    }
                                }

                                // Title & Class
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.title
                                        color: rootBar ? rootBar._fg : "#e0def4"
                                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.class + " • Workspace " + modelData.workspace
                                        color: rootBar ? rootBar._muted : "#6e6a86"
                                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    text: switcherWindow.selectedIndex === index ? "Active 󰁔" : ""
                                    color: rootBar ? rootBar._cyn : "#9bced7"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    switcherWindow.selectedIndex = index;
                                    switcherWindow.activateSelected();
                                    switcherWindow.closeRequested();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: focusWindowProc
        command: ["echo", "idle"]
    }
}
