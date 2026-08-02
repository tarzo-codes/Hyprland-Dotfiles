import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"

PanelWindow {
    id: bluetoothPanel
    required property var modelData
    screen: modelData

    implicitWidth: Math.round((CentralConfig.useCustomAppletSize ? CentralConfig.appletWidth : 320) * (CentralConfig.appletScale > 0 ? CentralConfig.appletScale : 1.0))
    implicitHeight: Math.round((CentralConfig.useCustomAppletSize ? CentralConfig.appletHeight : 380) * (CentralConfig.appletScale > 0 ? CentralConfig.appletScale : 1.0))

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bluetooth"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "custom" || (CentralConfig.appletLocation !== "bottom" && CentralConfig.appletLocation !== "center" && !ThemeManager.barIsBottom)
        bottom: CentralConfig.appletLocation === "bottom"
        left: CentralConfig.appletLocation === "custom"
        right: CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "bottom"
    }

    margins {
        top: CentralConfig.appletLocation === "custom" ? CentralConfig.appletCustomY : ((CentralConfig.appletLocation === "top" || (CentralConfig.appletLocation !== "bottom" && CentralConfig.appletLocation !== "center" && !ThemeManager.barIsBottom)) ? (bluetoothPanel.rootBar ? bluetoothPanel.rootBar.barHeight + 6 : 48) : 0)
        left: CentralConfig.appletLocation === "custom" ? CentralConfig.appletCustomX : 0
        bottom: CentralConfig.appletLocation === "bottom" ? (bluetoothPanel.rootBar ? bluetoothPanel.rootBar.barHeight + 6 : 48) : 0
        right: (CentralConfig.appletLocation === "top" || CentralConfig.appletLocation === "bottom") ? (bluetoothPanel.rootBar ? Math.round(bluetoothPanel.screen.width * (1.0 - bluetoothPanel.rootBar.barWidthPercent) / 2 + 50) : Math.round(bluetoothPanel.screen.width * 0.03)) : 0
    }

    color: "transparent"

    property var colors: null
    property var rootBar: null

    property bool isBluetoothOn: false
    property bool isScanning: false
    
    ListModel {
        id: deviceModel
    }

    onVisibleChanged: {
        if (visible) {
            refreshTimer.restart();
        } else {
            if (bluetoothPanel.isScanning) {
                scanProc.command = ["bluetoothctl", "scan", "off"];
                scanProc.running = true;
                bluetoothPanel.isScanning = false;
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            btStateProc.running = true;
        }
    }

    Timer {
        id: autoRefreshTimer
        interval: 3000
        running: bluetoothPanel.visible && bluetoothPanel.isBluetoothOn
        repeat: true
        onTriggered: {
            btStateProc.running = true;
        }
    }

    Process {
        id: btStateProc
        command: ["bash", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then echo 'POWER|on'; bluetoothctl devices | while read -r _ mac name; do if bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes'; then echo \"DEV|$mac|connected|$name\"; else echo \"DEV|$mac|disconnected|$name\"; fi; done; else echo 'POWER|off'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                deviceModel.clear();
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("POWER|")) {
                        var state = line.split("|")[1];
                        bluetoothPanel.isBluetoothOn = (state === "on");
                    } else if (line.startsWith("DEV|")) {
                        var parts = line.split("|");
                        if (parts.length >= 4) {
                            var mac = parts[1];
                            var status = parts[2];
                            var name = parts.slice(3).join("|");
                            deviceModel.append({"mac": mac, "status": status, "name": name});
                        }
                    }
                }
            }
        }
    }

    // Process to connect/disconnect/pair
    Process {
        id: connectProc
        property string mac: ""
        property string action: ""
        command: ["bluetoothctl", action, mac]
        onRunningChanged: {
            if (!running) {
                refreshTimer.restart();
            }
        }
    }

    // Process to toggle power
    Process {
        id: powerProc
        property string action: ""
        command: ["bluetoothctl", "power", action]
        onRunningChanged: {
            if (!running) {
                refreshTimer.restart();
            }
        }
    }

    // Process to scan
    Process {
        id: scanProc
    }

    // External manager fallback
    Process {
        id: managerProc
        command: ["blueman-manager"]
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: rootBar ? rootBar._bg : "#181825"
        border.color: rootBar ? rootBar._sur : "#313244"
        border.width: 1
        radius: 12

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

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uf293"
                    color: bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.2)
                    font.bold: true
                }

                Text {
                    text: "BLUETOOTH MANAGER"
                    color: rootBar ? rootBar._fg : "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.05)
                    font.bold: true
                    font.letterSpacing: 1.1
                    Layout.fillWidth: true
                }

                // Refresh / Scan Button
                Rectangle {
                    width: 65; height: 24; radius: 5
                    color: scanMouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                    border.color: rootBar ? rootBar._sur : "#313244"
                    border.width: 1
                    visible: bluetoothPanel.isBluetoothOn

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "\uf021"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                        Text {
                            text: bluetoothPanel.isScanning ? "Stop" : "Scan"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bluetoothPanel.isScanning = !bluetoothPanel.isScanning;
                            scanProc.command = ["bluetoothctl", "scan", bluetoothPanel.isScanning ? "on" : "off"];
                            scanProc.running = false;
                            scanProc.running = true;
                            refreshTimer.restart();
                        }
                    }
                }
            }

            // Power Toggle Section
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 8
                color: rootBar ? rootBar._sur : "#1e1e2e"
                border.color: bluetoothPanel.isBluetoothOn ? (bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7") : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: bluetoothPanel.isBluetoothOn ? "\uf293" : "\uf294"
                        color: bluetoothPanel.isBluetoothOn ? (bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7") : (rootBar ? rootBar._muted : "#6D8895")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.25)
                    }

                    Text {
                        text: bluetoothPanel.isBluetoothOn ? "Bluetooth Enabled" : "Bluetooth Disabled"
                        color: rootBar ? rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: ThemeManager.globalFontSize
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Custom Switch
                    Rectangle {
                        width: 34; height: 20
                        radius: 10
                        color: bluetoothPanel.isBluetoothOn ? (bluetoothPanel.colors ? (bluetoothPanel.colors.green || "#a3be8c") : "#9ece6a") : (rootBar ? rootBar._bg : "#151520")

                        Rectangle {
                            width: 16; height: 16
                            radius: 8
                            color: "#ffffff"
                            x: bluetoothPanel.isBluetoothOn ? 16 : 2
                            y: 2
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerProc.action = bluetoothPanel.isBluetoothOn ? "off" : "on";
                        powerProc.running = false;
                        powerProc.running = true;
                    }
                }
            }

            // Devices Section Header
            RowLayout {
                Layout.fillWidth: true
                visible: bluetoothPanel.isBluetoothOn

                Text {
                    text: "DEVICES (" + deviceModel.count + ")"
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.0
                    Layout.fillWidth: true
                }

                Text {
                    text: bluetoothPanel.isScanning ? "Scanning..." : ""
                    color: bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                }
            }

            // Devices List View
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: bluetoothPanel.isBluetoothOn && deviceModel.count > 0

                ListView {
                    model: deviceModel
                    spacing: 6
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 38
                        radius: 6
                        color: devMouse.containsMouse ? (rootBar ? rootBar._sur : "#1e1e2e") : "#151520"
                        border.color: status === "connected" ? (bluetoothPanel.colors ? (bluetoothPanel.colors.green || "#a3be8c") : "#9ece6a") : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: status === "connected" ? "\uf293" : "\uf294"
                                color: status === "connected" ? (bluetoothPanel.colors ? (bluetoothPanel.colors.green || "#a3be8c") : "#9ece6a") : (rootBar ? rootBar._muted : "#6D8895")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: name
                                    color: rootBar ? rootBar._fg : "#c0caf5"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: ThemeManager.globalFontSize
                                    font.bold: status === "connected"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: mac
                                    color: rootBar ? rootBar._muted : "#6D8895"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                }
                            }

                            // Connect / Disconnect Action Button
                            Rectangle {
                                width: status === "connected" ? 75 : 65
                                height: 22
                                radius: 4
                                color: status === "connected" ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : Qt.rgba(0.4, 0.7, 1.0, 0.15)
                                border.color: status === "connected" ? "#f7768e" : (bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7")
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: status === "connected" ? "Disconnect" : "Connect"
                                    color: status === "connected" ? "#f7768e" : (bluetoothPanel.colors ? (bluetoothPanel.colors.accent || "#7aa2f7") : "#7aa2f7")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        connectProc.mac = mac;
                                        connectProc.action = (status === "connected") ? "disconnect" : "connect";
                                        connectProc.running = false;
                                        connectProc.running = true;
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                connectProc.mac = mac;
                                connectProc.action = (status === "connected") ? "disconnect" : "connect";
                                connectProc.running = false;
                                connectProc.running = true;
                            }
                        }
                    }
                }
            }

            // Fallback when bluetooth is enabled but no devices paired
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: bluetoothPanel.isBluetoothOn && deviceModel.count === 0
                spacing: 6

                Text {
                    text: "No devices found."
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: ThemeManager.globalFontSize
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Click Scan above to pair new devices."
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Fallback when bluetooth is disabled
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !bluetoothPanel.isBluetoothOn
                spacing: 6

                Text {
                    text: "Enable Bluetooth to scan and"
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "connect to wireless devices."
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
