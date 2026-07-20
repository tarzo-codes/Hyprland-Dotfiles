import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: networkPanel
    required property var modelData
    screen: modelData

    implicitWidth: 340
    implicitHeight: 430

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-network-panel"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            refreshProc.running = false;
            refreshProc.running = true;
        }
    }

    anchors {
        top: !ThemeManager.barIsBottom
        bottom: ThemeManager.barIsBottom
        right: true
    }

    margins {
        top: !ThemeManager.barIsBottom ? (networkPanel.rootBar ? networkPanel.rootBar.barHeight + 6 : 48) : 0
        bottom: ThemeManager.barIsBottom ? (networkPanel.rootBar ? networkPanel.rootBar.barHeight + 6 : 48) : 0
        right: networkPanel.rootBar ? Math.round(networkPanel.screen.width * (1.0 - networkPanel.rootBar.barWidthPercent) / 2 + 80) : Math.round(networkPanel.screen.width * 0.12)
    }

    color: "transparent"

    property var rootBar: null
    
    function getSignalIcon(sig) {
        return "󰤨";
    }

    property bool wiredConnected: false
    property string wiredName: "Ethernet"
    property string wiredIp: "Disconnected"
    
    property bool wifiEnabled: true
    property var wifiNetworks: []
    property string connectingSsid: ""
    property string statusMessage: ""

    property bool showPasswordPrompt: false
    property string promptSsid: ""
    property string passwordInput: ""

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: networkPanel.rootBar ? networkPanel.rootBar._bg : "#1a1b26"
        border.color: networkPanel.rootBar ? networkPanel.rootBar._acc : "#7aa2f7"
        border.width: 1.5
        radius: 12

        property real animOffset: ThemeManager.barIsBottom ? 16 : -16
        y: animOffset
        opacity: 0

        Component.onCompleted: {
            animOffset = 0;
            opacity = 1.0;
            refreshProc.running = true;
        }

        Behavior on animOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header Title Bar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰤨"
                    color: networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a"
                    font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                }

                Text {
                    text: "NETWORK MANAGER"
                    color: networkPanel.rootBar ? networkPanel.rootBar._fg : "#c0caf5"
                    font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true }

                // Gear settings button (launches nm-connection-editor)
                Rectangle {
                    width: 24; height: 24
                    radius: 6
                    color: gearNetMouse.containsMouse ? (networkPanel.rootBar ? networkPanel.rootBar._sur : "#2b2d3a") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: networkPanel.rootBar ? networkPanel.rootBar._brightCyn : "#7dcfff"
                        font.family: networkPanel.rootBar ? networkPanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                    }

                    MouseArea {
                        id: gearNetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            nmEditorProc.running = true;
                            networkPanel.visible = false;
                        }
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 24; height: 24
                    radius: 6
                    color: refMouse.containsMouse ? (networkPanel.rootBar ? networkPanel.rootBar._sur : "#2b2d3a") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89"
                        font.family: networkPanel.rootBar ? networkPanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                    }

                    MouseArea {
                        id: refMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            networkPanel.statusMessage = "Refreshing...";
                            refreshProc.running = true;
                        }
                    }
                }
            }

            Process { id: nmEditorProc; command: ["env", "GTK_THEME=Breeze-Dark", "nm-connection-editor"] }

            // --- SECTION 1: WIRED NETWORK ---
            Text {
                text: "󰈀  WIRED CONNECTION"
                color: networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89"
                font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                font.bold: true
                font.letterSpacing: 1.0
            }

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: networkPanel.rootBar ? networkPanel.rootBar._sur : "#24283b"
                border.color: networkPanel.wiredConnected ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._sur : "#1f2335")
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Rectangle {
                        width: 28; height: 28
                        radius: 6
                        color: networkPanel.wiredConnected ? networkPanel.rootBar.alphaColor(networkPanel.rootBar._grn, 0.2) : networkPanel.rootBar.alphaColor(networkPanel.rootBar._muted, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: "󰈀"
                            color: networkPanel.wiredConnected ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89")
                            font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: networkPanel.wiredName
                            color: networkPanel.rootBar ? networkPanel.rootBar._fg : "#c0caf5"
                            font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: networkPanel.wiredConnected ? ("IP: " + networkPanel.wiredIp) : "Disconnected"
                            color: networkPanel.wiredConnected ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89")
                            font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                        }
                    }
                }
            }

            // --- SECTION 2: WI-FI NETWORKS ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰤨  WI-FI NETWORKS"
                    color: networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89"
                    font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 40; height: 20
                    radius: 10
                    color: networkPanel.wifiEnabled ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89")

                    Rectangle {
                        width: 16; height: 16
                        radius: 8
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: networkPanel.wifiEnabled ? 22 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            networkPanel.wifiEnabled = !networkPanel.wifiEnabled;
                            toggleWifiProc.command = ["nmcli", "radio", "wifi", networkPanel.wifiEnabled ? "on" : "off"];
                            toggleWifiProc.running = true;
                        }
                    }
                }
            }

            // Status message feedback
            Text {
                visible: networkPanel.statusMessage !== ""
                text: networkPanel.statusMessage
                color: networkPanel.rootBar ? networkPanel.rootBar._brightCyn : "#7dcfff"
                font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                font.italic: true
            }

            // Wi-Fi Scroll Area
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width - 4
                    spacing: 4

                    Repeater {
                        model: networkPanel.wifiNetworks
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 6
                            color: modelData.active ? (networkPanel.rootBar ? networkPanel.rootBar.alphaColor(networkPanel.rootBar._grn, 0.2) : "#253b2f") : (netMouse.containsMouse ? (networkPanel.rootBar ? networkPanel.rootBar._sur : "#24283b") : "transparent")
                            border.color: modelData.active ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "󰤨"
                                    color: modelData.active ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._fg : "#c0caf5")
                                    font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.ssid
                                        color: networkPanel.rootBar ? networkPanel.rootBar._fg : "#c0caf5"
                                        font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.active ? "Connected" : (modelData.security !== "" ? ("Secured (" + modelData.security + ")") : "Open")
                                        color: modelData.active ? (networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a") : (networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89")
                                        font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.75)
                                    }
                                }

                                Text {
                                    text: modelData.signal + "%"
                                    color: networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89"
                                    font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                                }
                            }

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.active) {
                                        if (modelData.security !== "" && modelData.security !== "--") {
                                            networkPanel.promptSsid = modelData.ssid;
                                            networkPanel.passwordInput = "";
                                            networkPanel.showPasswordPrompt = true;
                                        } else {
                                            networkPanel.connectingSsid = modelData.ssid;
                                            networkPanel.statusMessage = "Connecting to " + modelData.ssid + "...";
                                            connectProc.command = ["nmcli", "device", "wifi", "connect", modelData.ssid];
                                            connectProc.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- PASSWORD PROMPT DIALOG ---
            Rectangle {
                Layout.fillWidth: true
                height: 90
                radius: 8
                visible: networkPanel.showPasswordPrompt
                color: networkPanel.rootBar ? networkPanel.rootBar._sur : "#1f2335"
                border.color: networkPanel.rootBar ? networkPanel.rootBar._brightCyn : "#7dcfff"
                border.width: 1.5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        text: "Password for " + networkPanel.promptSsid
                        color: networkPanel.rootBar ? networkPanel.rootBar._fg : "#c0caf5"
                        font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                        font.bold: true
                    }

                    TextField {
                        Layout.fillWidth: true
                        height: 24
                        echoMode: TextInput.Password
                        placeholderText: "Enter Wi-Fi Password"
                        text: networkPanel.passwordInput
                        onTextChanged: networkPanel.passwordInput = text
                        font.family: networkPanel.rootBar ? networkPanel.rootBar.globalFontFamily : "Outfit"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 22
                            radius: 4
                            color: networkPanel.rootBar ? networkPanel.rootBar._muted : "#565f89"
                            Text { anchors.centerIn: parent; text: "Cancel"; color: "#ffffff"; font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8) }
                            MouseArea { anchors.fill: parent; onClicked: networkPanel.showPasswordPrompt = false }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 22
                            radius: 4
                            color: networkPanel.rootBar ? networkPanel.rootBar._grn : "#9ece6a"
                            Text { anchors.centerIn: parent; text: "Connect"; color: "#ffffff"; font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8); font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    networkPanel.showPasswordPrompt = false;
                                    networkPanel.statusMessage = "Connecting to " + networkPanel.promptSsid + "...";
                                    connectProc.command = ["nmcli", "device", "wifi", "connect", networkPanel.promptSsid, "password", networkPanel.passwordInput];
                                    connectProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            Process { id: toggleWifiProc }
            Process { id: connectProc }

            Process {
                id: refreshProc
                command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION,IP4.ADDRESS dev 2>/dev/null; echo '---'; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        var parts = this.text.trim().split("---");
                        if (parts.length >= 2) {
                            // Parse Devs
                            var devLines = parts[0].trim().split("\n");
                            for (var d = 0; d < devLines.length; d++) {
                                var devFields = devLines[d].split(":");
                                if (devFields[0] === "ethernet") {
                                    networkPanel.wiredConnected = (devFields[1] === "connected");
                                    networkPanel.wiredName = devFields[2] || "Ethernet";
                                    networkPanel.wiredIp = devFields[3] || "Disconnected";
                                }
                            }

                            // Parse Wi-Fi List
                            var wifiLines = parts[1].trim().split("\n");
                            var nets = [];
                            var seen = {};
                            for (var w = 0; w < wifiLines.length; w++) {
                                var wFields = wifiLines[w].split(":");
                                if (wFields.length >= 3) {
                                    var active = (wFields[0] === "*");
                                    var ssid = wFields[1];
                                    var signal = wFields[2];
                                    var sec = wFields[3] || "";
                                    if (ssid && !seen[ssid]) {
                                        seen[ssid] = true;
                                        nets.push({
                                            active: active,
                                            ssid: ssid,
                                            signal: signal,
                                            security: sec
                                        });
                                    }
                                }
                            }
                            networkPanel.wifiNetworks = nets;
                        }
                    }
                }
            }
        }
    }
}
