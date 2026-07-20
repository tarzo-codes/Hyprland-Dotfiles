import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: brightnessPanel
    required property var modelData
    screen: modelData

    implicitWidth: 320
    implicitHeight: monitorsModel.count >= 2 ? 220 : 130

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-brightness-panel"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            monitorsProc.running = false; monitorsProc.running = true;
        }
    }

    anchors {
        top: !ThemeManager.barIsBottom
        bottom: ThemeManager.barIsBottom
        right: true
    }

    margins {
        top: !ThemeManager.barIsBottom ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.barHeight + 6 : 48) : 0
        bottom: ThemeManager.barIsBottom ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.barHeight + 6 : 48) : 0
        right: brightnessPanel.rootBar ? Math.round(brightnessPanel.screen.width * (1.0 - brightnessPanel.rootBar.barWidthPercent) / 2 + 100) : Math.round(brightnessPanel.screen.width * 0.15)
    }

    color: "transparent"

    property var rootBar: null
    property bool syncBothMonitors: true
    property string selectedMonitor: "ALL"

    ListModel { id: monitorsModel }

    Process {
        id: monitorsProc
        command: ["python3", "/home/tarzo/.config/quickshell/scripts/monitors.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = this.text.trim();
                    if (raw !== "") {
                        var data = JSON.parse(raw);
                        monitorsModel.clear();
                        for (var i = 0; i < data.length; i++) {
                            monitorsModel.append({
                                monId: data[i].id,
                                monName: data[i].name,
                                monDesc: data[i].description
                            });
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: brightnessPanel.rootBar ? brightnessPanel.rootBar._bg : "#1a1b26"
        border.color: brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68"
        border.width: 1.5
        radius: 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰃠"
                    color: brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68"
                    font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                }

                Text {
                    text: "BRIGHTNESS CONTROL"
                    color: brightnessPanel.rootBar ? brightnessPanel.rootBar._fg : "#c0caf5"
                    font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: brightnessPanel.rootBar ? Math.round(brightnessPanel.rootBar.brightnessValue * 100) + "%" : "80%"
                    color: brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68"
                    font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                    font.bold: true
                }
            }

            // --- MONITOR SELECTOR PIS (IF 2+ MONITORS) ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: monitorsModel.count >= 2

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "SELECT DISPLAY TARGET"
                        color: brightnessPanel.rootBar ? brightnessPanel.rootBar._muted : "#6D8895"
                        font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.78)
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: brightnessPanel.syncBothMonitors ? "󰓦 BOTH SYNCED" : "SINGLE DISPLAY"
                        color: brightnessPanel.syncBothMonitors ? (brightnessPanel.rootBar ? brightnessPanel.rootBar._grn : "#9ece6a") : (brightnessPanel.rootBar ? brightnessPanel.rootBar._muted : "#6D8895")
                        font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.75)
                        font.bold: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // BOTH MONITORS
                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        radius: 6
                        color: brightnessPanel.syncBothMonitors ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.alphaColor(brightnessPanel.rootBar._brightYel, 0.25) : "#33e0af68") : (brightnessPanel.rootBar ? brightnessPanel.rootBar._sur : "#2b2d3a")
                        border.color: brightnessPanel.syncBothMonitors ? (brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68") : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰓦 BOTH"
                            color: brightnessPanel.syncBothMonitors ? (brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68") : (brightnessPanel.rootBar ? brightnessPanel.rootBar._fg : "#c0caf5")
                            font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                brightnessPanel.syncBothMonitors = true;
                                brightnessPanel.selectedMonitor = "ALL";
                            }
                        }
                    }

                    // INDIVIDUAL MONITORS
                    Repeater {
                        model: monitorsModel
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: 6
                            color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.alphaColor(brightnessPanel.rootBar._brightYel, 0.25) : "#33e0af68") : (brightnessPanel.rootBar ? brightnessPanel.rootBar._sur : "#2b2d3a")
                            border.color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68") : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: model.monName
                                color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68") : (brightnessPanel.rootBar ? brightnessPanel.rootBar._fg : "#c0caf5")
                                font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    brightnessPanel.syncBothMonitors = false;
                                    brightnessPanel.selectedMonitor = model.monName;
                                }
                            }
                        }
                    }
                }
            }

            // --- MASTER BRIGHTNESS SLIDER ---
            Rectangle {
                id: brightTrackRect
                Layout.fillWidth: true
                height: 12
                radius: 6
                color: brightnessPanel.rootBar ? brightnessPanel.rootBar.alphaColor(brightnessPanel.rootBar._brightYel, 0.2) : "#2b2d3a"

                Rectangle {
                    height: parent.height
                    radius: 6
                    color: brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68"
                    width: brightnessPanel.rootBar ? Math.max(0, Math.min(1.0, brightnessPanel.rootBar.brightnessValue)) * parent.width : 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        if (pressed && brightnessPanel.rootBar) {
                            var pct = Math.max(0.05, Math.min(1.0, mouse.x / brightTrackRect.width));
                            brightnessPanel.rootBar.brightnessValue = pct;
                            setBrightProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", Math.round(pct * 100).toString()];
                            setBrightProc.running = true;
                        }
                    }
                    onPressed: (mouse) => {
                        if (brightnessPanel.rootBar) {
                            var pct = Math.max(0.05, Math.min(1.0, mouse.x / brightTrackRect.width));
                            brightnessPanel.rootBar.brightnessValue = pct;
                            setBrightProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", Math.round(pct * 100).toString()];
                            setBrightProc.running = true;
                        }
                    }
                }
            }

            Process { id: setBrightProc }
        }
    }
}
