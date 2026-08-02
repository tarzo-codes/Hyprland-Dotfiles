import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"

PanelWindow {
    id: brightnessPanel
    required property var modelData
    screen: modelData

    implicitWidth: Math.round((CentralConfig.useCustomAppletSize ? CentralConfig.appletWidth : 320) * (CentralConfig.appletScale > 0 ? CentralConfig.appletScale : 1.0))
    implicitHeight: Math.round((CentralConfig.useCustomAppletSize ? CentralConfig.appletHeight : (monitorsModel.count >= 2 ? 220 : 130)) * (CentralConfig.appletScale > 0 ? CentralConfig.appletScale : 1.0))

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-brightness-panel"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            monitorsProc.running = false; monitorsProc.running = true;
        }
    }

    anchors {
        top: CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "custom" || (CentralConfig.appletLocation !== "bottom" && CentralConfig.appletLocation !== "center" && !ThemeManager.barIsBottom)
        bottom: CentralConfig.appletLocation === "bottom"
        left: CentralConfig.appletLocation === "custom"
        right: CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "bottom"
    }

    margins {
        top: CentralConfig.appletLocation === "custom" ? CentralConfig.appletCustomY : ((CentralConfig.appletLocation === "top" || (CentralConfig.appletLocation !== "bottom" && CentralConfig.appletLocation !== "center" && !ThemeManager.barIsBottom)) ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.barHeight + 6 : 48) : 0)
        left: CentralConfig.appletLocation === "custom" ? CentralConfig.appletCustomX : 0
        bottom: CentralConfig.appletLocation === "bottom" ? (brightnessPanel.rootBar ? brightnessPanel.rootBar.barHeight + 6 : 48) : 0
        right: (CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "bottom") ? (brightnessPanel.rootBar ? Math.round(brightnessPanel.screen.width * (1.0 - brightnessPanel.rootBar.barWidthPercent) / 2 + 100) : Math.round(brightnessPanel.screen.width * 0.15)) : 0
    }

    color: "transparent"

    property var colors: null
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

    Timer {
        id: brightDebounceTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (brightnessPanel.rootBar) {
                var pctVal = Math.round(brightnessPanel.rootBar.brightnessValue * 100).toString();
                setBrightProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", pctVal];
                setBrightProc.running = false;
                setBrightProc.running = true;
            }
        }
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: rootBar ? rootBar._bg : (brightnessPanel.rootBar ? brightnessPanel.rootBar._bg : "#1a1b26")
        border.color: rootBar ? rootBar._acc : (brightnessPanel.rootBar ? brightnessPanel.rootBar._acc : "#7aa2f7")
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
                    color: rootBar ? rootBar._acc : (brightnessPanel.rootBar ? brightnessPanel.rootBar._brightYel : "#e0af68")
                    font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                }

                Text {
                    text: "BRIGHTNESS CONTROL"
                    color: rootBar ? rootBar._fg : (brightnessPanel.rootBar ? brightnessPanel.rootBar._fg : "#c0caf5")
                    font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: brightnessPanel.rootBar ? Math.round(brightnessPanel.rootBar.brightnessValue * 100) + "%" : "80%"
                    color: rootBar ? rootBar._acc : (brightnessPanel.rootBar ? brightnessPanel.rootBar._acc : "#7aa2f7")
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
                        color: rootBar ? rootBar._muted : (brightnessPanel.rootBar ? brightnessPanel.rootBar._muted : "#6D8895")
                        font.family: brightnessPanel.rootBar ? brightnessPanel.rootBar.globalFontFamily : "Outfit"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.78)
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: brightnessPanel.syncBothMonitors ? "󰓦 BOTH SYNCED" : "SINGLE DISPLAY"
                        color: brightnessPanel.syncBothMonitors ? (rootBar ? rootBar._grn : "#9ece6a") : (rootBar ? rootBar._muted : "#6D8895")
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
                        color: brightnessPanel.syncBothMonitors ? (rootBar ? rootBar._sur : "#2b2d3a") : (rootBar ? rootBar._bg : "#1a1b26")
                        border.color: brightnessPanel.syncBothMonitors ? (rootBar ? rootBar._acc : "#7aa2f7") : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰓦 BOTH"
                            color: brightnessPanel.syncBothMonitors ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._fg : "#c0caf5")
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
                            color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (rootBar ? rootBar._sur : "#2b2d3a") : (rootBar ? rootBar._bg : "#1a1b26")
                            border.color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (rootBar ? rootBar._acc : "#7aa2f7") : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: model.monName
                                color: (!brightnessPanel.syncBothMonitors && brightnessPanel.selectedMonitor === model.monName) ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._fg : "#c0caf5")
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
                color: rootBar ? rootBar._sur : "#2b2d3a"

                Rectangle {
                    height: parent.height
                    radius: 6
                    color: rootBar ? rootBar._acc : (brightnessPanel.rootBar ? brightnessPanel.rootBar._acc : "#7aa2f7")
                    width: brightnessPanel.rootBar ? Math.max(0, Math.min(1.0, brightnessPanel.rootBar.brightnessValue)) * parent.width : 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        if (pressed && brightnessPanel.rootBar) {
                            brightnessPanel.rootBar.isAdjustingBrightness = true;
                            if (brightnessPanel.rootBar.brightCooldownTimer) {
                                brightnessPanel.rootBar.brightCooldownTimer.restart();
                            }
                            var pct = Math.max(0.05, Math.min(1.0, mouse.x / brightTrackRect.width));
                            brightnessPanel.rootBar.brightnessValue = pct;
                            brightDebounceTimer.restart();
                        }
                    }
                    onPressed: (mouse) => {
                        if (brightnessPanel.rootBar) {
                            brightnessPanel.rootBar.isAdjustingBrightness = true;
                            if (brightnessPanel.rootBar.brightCooldownTimer) {
                                brightnessPanel.rootBar.brightCooldownTimer.restart();
                            }
                            var pct = Math.max(0.05, Math.min(1.0, mouse.x / brightTrackRect.width));
                            brightnessPanel.rootBar.brightnessValue = pct;
                            brightDebounceTimer.restart();
                        }
                    }
                }
            }

            Process { id: setBrightProc }
        }
    }
}
