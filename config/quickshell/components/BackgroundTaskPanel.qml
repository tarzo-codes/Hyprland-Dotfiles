import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../themes"

PanelWindow {
    id: taskPanel
    required property var modelData
    screen: modelData

    implicitWidth: 320
    implicitHeight: 360

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-background-tasks"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: taskPanel.rootBar ? taskPanel.rootBar.barHeight + 4 : 48
        right: taskPanel.rootBar ? Math.round(taskPanel.screen.width * (1.0 - taskPanel.rootBar.barWidthPercent) / 2) + 10 : Math.round(taskPanel.screen.width * 0.03)
    }

    color: "transparent"

    property var colors: null
    property var rootBar: null

    ListModel {
        id: bgProcModel
    }

    onVisibleChanged: {
        if (visible) {
            scanProcTimer.restart();
        }
    }

    Timer {
        id: scanProcTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            procScanner.running = true;
        }
    }

    Timer {
        id: autoRefreshTimer
        interval: 3000
        running: taskPanel.visible
        repeat: true
        onTriggered: {
            procScanner.running = true;
        }
    }

    // Process to scan for background apps (antigravity, discord, vesktop, spotify, steam, etc.)
    Process {
        id: procScanner
        command: ["bash", "-c", "ps -u \"$USER\" -o pid,comm,args | grep -iE 'antigravity|discord|vesktop|spotify|steam|telegram|obs|slack|element|thunderbird|syncthing|dropbox|electron|blueman' | grep -v grep | head -n 20 | while read -r pid comm args; do echo \"PROC|$pid|$comm\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                bgProcModel.clear();
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("PROC|")) {
                        var parts = line.split("|");
                        if (parts.length >= 3) {
                            var pid = parts[1];
                            var comm = parts[2];
                            bgProcModel.append({"pid": pid, "name": comm});
                        }
                    }
                }
            }
        }
    }

    // Process to kill process
    Process {
        id: killProc
        property string targetPid: ""
        command: ["kill", "-9", targetPid]
        onRunningChanged: {
            if (!running) {
                scanProcTimer.restart();
            }
        }
    }

    // Process to focus window via hyprctl
    Process {
        id: focusProc
        property string targetName: ""
        command: ["hyprctl", "dispatch", "focuswindow", targetName]
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: rootBar ? rootBar._bg : "#1a1b26"
        border.color: rootBar ? rootBar._sur : "#414868"
        border.width: 1
        radius: 10

        property real animOffset: -16
        y: animOffset
        opacity: 0

        Component.onCompleted: {
            animOffset = 0;
            opacity = 1.0;
        }

        Behavior on animOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                text: "BACKGROUND TASK HANDLER"
                color: rootBar ? rootBar._muted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignHCenter
            }

            // System Tray Apps Section
            Text {
                text: "TRAY APPS (" + SystemTray.items.count + ")"
                color: rootBar ? rootBar._muted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
                visible: SystemTray.items.count > 0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: SystemTray.items.count > 0 ? Math.min(120, SystemTray.items.count * 34) : 0
                clip: true
                visible: SystemTray.items.count > 0

                ListView {
                    model: SystemTray.items
                    spacing: 4
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 30
                        radius: 5
                        color: trayMouse.containsMouse ? (rootBar ? rootBar._sur : "#1e1e2e") : "transparent"
                        border.color: rootBar ? rootBar._sur : "#33414868"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Image {
                                width: 16
                                height: 16
                                source: modelData.icon || ""
                                fillMode: Image.PreserveAspectFit
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: modelData.title || modelData.id || "Background App"
                                color: rootBar ? rootBar._fg : "#c0caf5"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 52
                                height: 20
                                radius: 4
                                color: actMouse.containsMouse ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._sur : "#1e1e2e")

                                Text {
                                    anchors.centerIn: parent
                                    text: "Open"
                                    color: actMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: true
                                }

                                MouseArea {
                                    id: actMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.activate()
                                }
                            }
                        }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            // Running Background Processes Section
            Text {
                text: "BACKGROUND PROCESSES (" + bgProcModel.count + ")"
                color: rootBar ? rootBar._muted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
                visible: bgProcModel.count > 0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: bgProcModel.count > 0

                ListView {
                    model: bgProcModel
                    spacing: 4
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 30
                        radius: 5
                        color: procMouse.containsMouse ? (rootBar ? rootBar._sur : "#1e1e2e") : "transparent"
                        border.color: rootBar ? rootBar._sur : "#33414868"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Text {
                                text: "\uf085"
                                color: taskPanel.colors ? (taskPanel.colors.brightYellow || "#fabd2f") : "#fabd2f"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Text {
                                text: name + " (PID: " + pid + ")"
                                color: rootBar ? rootBar._fg : "#c0caf5"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Focus Button
                            Rectangle {
                                width: 44
                                height: 20
                                radius: 4
                                color: focMouse.containsMouse ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._sur : "#1e1e2e")

                                Text {
                                    anchors.centerIn: parent
                                    text: "Focus"
                                    color: focMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                }

                                MouseArea {
                                    id: focMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        focusProc.targetName = name;
                                        focusProc.running = true;
                                    }
                                }
                            }

                            // Terminate Button
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: termMouse.containsMouse ? (taskPanel.colors ? taskPanel.colors.brightRed || "#fb4934" : "#fb4934") : (rootBar ? rootBar._sur : "#1e1e2e")

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: termMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._muted : "#6D8895")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: termMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        killProc.targetPid = pid;
                                        killProc.running = true;
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: procMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            // Fallback when no background tasks detected
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: SystemTray.items.count === 0 && bgProcModel.count === 0
                spacing: 4

                Text {
                    text: "No active background tasks."
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Refresh Button
            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: 6
                color: refreshBtnMouse.containsMouse ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._sur : "#1e1e2e")
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Refresh Tasks"
                    color: refreshBtnMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: refreshBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        procScanner.running = true;
                    }
                }
            }
        }
    }
}
