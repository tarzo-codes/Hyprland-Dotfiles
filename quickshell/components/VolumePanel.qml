import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: volumePanel
    required property var modelData
    screen: modelData

    implicitWidth: 340
    implicitHeight: showAppsMixer ? Math.min(560, 360 + appStreamsModel.count * 50) : 360

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-volume-panel"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            if (volumePanel.rootBar && volumePanel.rootBar.syncDeviceVolume) {
                volumePanel.rootBar.syncDeviceVolume();
            }
            monitorsProc.running = false; monitorsProc.running = true;
            audioDevsProc.running = false; audioDevsProc.running = true;
            micGetProc.running = false; micGetProc.running = true;
            if (showAppsMixer) {
                appStreamsProc.running = false; appStreamsProc.running = true;
            }
        }
    }

    anchors {
        top: !ThemeManager.barIsBottom
        bottom: ThemeManager.barIsBottom
        right: true
    }

    margins {
        top: !ThemeManager.barIsBottom ? (volumePanel.rootBar ? volumePanel.rootBar.barHeight + 6 : 48) : 0
        bottom: ThemeManager.barIsBottom ? (volumePanel.rootBar ? volumePanel.rootBar.barHeight + 6 : 48) : 0
        right: volumePanel.rootBar ? Math.round(volumePanel.screen.width * (1.0 - volumePanel.rootBar.barWidthPercent) / 2 + 60) : Math.round(volumePanel.screen.width * 0.1)
    }

    color: "transparent"

    property var rootBar: null
    property bool showAppsMixer: false
    property bool isDraggingAppVol: false

    property bool syncBothMonitors: true
    property string selectedMonitor: "ALL"

    property real micVolValue: 0.8
    property bool micMuted: false

    ListModel { id: sinksModel }
    ListModel { id: sourcesModel }
    ListModel { id: appStreamsModel }
    ListModel { id: monitorsModel }

    property string activeSinkName: ""
    property string activeSourceName: ""

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

    Process {
        id: audioDevsProc
        command: ["python3", "/home/tarzo/.config/quickshell/scripts/audio-devices.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = this.text.trim();
                    if (raw !== "") {
                        var data = JSON.parse(raw);
                        
                        // Populate Sinks (Output Speakers/Headphones)
                        sinksModel.clear();
                        for (var i = 0; i < data.sinks.length; i++) {
                            sinksModel.append({
                                sinkName: data.sinks[i].name,
                                displayName: data.sinks[i].description
                            });
                        }
                        volumePanel.activeSinkName = data.default_sink;

                        // Populate Sources (Input Microphones)
                        sourcesModel.clear();
                        for (var j = 0; j < data.sources.length; j++) {
                            sourcesModel.append({
                                sourceName: data.sources[j].name,
                                displayName: data.sources[j].description
                            });
                        }
                        volumePanel.activeSourceName = data.default_source;
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: micGetProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim();
                var match = text.match(/Volume:\s+(\d+(\.\d+)?)/);
                if (match && match[1]) volumePanel.micVolValue = parseFloat(match[1]);
                volumePanel.micMuted = text.indexOf("[MUTED]") !== -1;
            }
        }
    }

    Process {
        id: appStreamsProc
        command: ["python3", "/home/tarzo/.config/quickshell/scripts/sink-inputs.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (volumePanel.isDraggingAppVol) return;
                try {
                    var raw = this.text.trim();
                    if (raw !== "") {
                        var data = JSON.parse(raw);
                        if (appStreamsModel.count === data.length) {
                            for (var i = 0; i < data.length; i++) {
                                var sId = data[i].id;
                                var sName = data[i].name || "Audio App";
                                var sVol = parseInt(data[i].volume || "100") / 100.0;
                                var sMuted = data[i].muted || false;
                                var el = appStreamsModel.get(i);
                                if (el) {
                                    if (el.streamId !== sId) appStreamsModel.setProperty(i, "streamId", sId);
                                    if (el.streamName !== sName) appStreamsModel.setProperty(i, "streamName", sName);
                                    if (Math.abs(el.streamVol - sVol) > 0.01) appStreamsModel.setProperty(i, "streamVol", sVol);
                                    if (el.streamMuted !== sMuted) appStreamsModel.setProperty(i, "streamMuted", sMuted);
                                }
                            }
                        } else {
                            appStreamsModel.clear();
                            for (var k = 0; k < data.length; k++) {
                                appStreamsModel.append({
                                    streamId: data[k].id,
                                    streamName: data[k].name || "Audio App",
                                    streamVol: parseInt(data[k].volume || "100") / 100.0,
                                    streamMuted: data[k].muted || false
                                });
                            }
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            audioDevsProc.running = true;
            micGetProc.running = true;
            if (showAppsMixer) appStreamsProc.running = true;
        }
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: volumePanel.rootBar ? volumePanel.rootBar._bg : "#1a1b26"
        border.color: volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7"
        border.width: 1.5
        radius: 12

        property real animOffset: ThemeManager.barIsBottom ? 16 : -16
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

            // --- MASTER VOLUME ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰕾"
                    color: volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                }

                Text {
                    text: "MASTER VOLUME"
                    color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: volumePanel.rootBar ? Math.round(volumePanel.rootBar.volValue * 100) + "%" : "50%"
                    color: volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                    font.bold: true
                }

                // Gear settings button (launches pavucontrol)
                Rectangle {
                    width: 24; height: 24
                    radius: 6
                    color: gearVolMouse.containsMouse ? (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                        font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.0)
                    }

                    MouseArea {
                        id: gearVolMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pavucontrolProc.running = true;
                            volumePanel.visible = false;
                        }
                    }
                }
            }

            Process { id: pavucontrolProc; command: ["env", "GTK_THEME=Breeze-Dark", "pavucontrol"] }

            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._acc, 0.2) : "#2b2d3a"

                Rectangle {
                    height: parent.height
                    radius: 5
                    color: (volumePanel.rootBar && volumePanel.rootBar.volMuted) ? (volumePanel.rootBar._red || "#f7768e") : (volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7")
                    width: volumePanel.rootBar ? Math.max(0, Math.min(1.0, volumePanel.rootBar.volValue)) * parent.width : 0
                    Behavior on width { NumberAnimation { duration: 50 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        if (pressed && volumePanel.rootBar) {
                            volumePanel.rootBar.isAdjustingVolume = true;
                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            volumePanel.rootBar.volValue = pct;
                            setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(pct * 100) + "%"];
                            setVolProc.running = true;
                        }
                    }
                    onPressed: (mouse) => {
                        if (volumePanel.rootBar) {
                            volumePanel.rootBar.isAdjustingVolume = true;
                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            volumePanel.rootBar.volValue = pct;
                            setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(pct * 100) + "%"];
                            setVolProc.running = true;
                        }
                    }
                }
            }

            Process { id: setVolProc }

            // --- MICROPHONE VOLUME ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰍬"
                    color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.1)
                }

                Text {
                    text: "MICROPHONE VOLUME"
                    color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Math.round(volumePanel.micVolValue * 100) + "%"
                    color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                    font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._brightCyn, 0.2) : "#2b2d3a"

                Rectangle {
                    height: parent.height
                    radius: 5
                    color: volumePanel.micMuted ? (volumePanel.rootBar ? volumePanel.rootBar._red : "#f7768e") : (volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff")
                    width: Math.max(0, Math.min(1.0, volumePanel.micVolValue)) * parent.width
                    Behavior on width { NumberAnimation { duration: 50 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            volumePanel.micVolValue = pct;
                            setMicVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(pct * 100) + "%"];
                            setMicVolProc.running = true;
                        }
                    }
                    onPressed: (mouse) => {
                        var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                        volumePanel.micVolValue = pct;
                        setMicVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(pct * 100) + "%"];
                        setMicVolProc.running = true;
                    }
                }
            }

            Process { id: setMicVolProc }

            // --- OUTPUT DEVICES (SPEAKERS / HEADSETS) ---
            Text {
                text: "OUTPUT DEVICE"
                color: volumePanel.rootBar ? volumePanel.rootBar._muted : "#6D8895"
                font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: sinksModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        radius: 5
                        color: (model.sinkName === volumePanel.activeSinkName) ? (volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._acc, 0.25) : "#337aa2f7") : (deviceMouse.containsMouse ? (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a") : "transparent")
                        border.color: (model.sinkName === volumePanel.activeSinkName) ? (volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7") : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: (model.sinkName === volumePanel.activeSinkName) ? "󰓃" : "󰋋"
                                color: (model.sinkName === volumePanel.activeSinkName) ? (volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7") : (volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5")
                                font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                            }

                            Text {
                                text: model.displayName
                                color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                                font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var targetSink = model.sinkName;
                                volumePanel.activeSinkName = targetSink;
                                if (volumePanel.rootBar && volumePanel.rootBar.syncDeviceVolume) {
                                    volumePanel.rootBar.syncDeviceVolume();
                                }
                                setSinkProc.command = ["bash", "-c", "pactl set-default-sink '" + targetSink + "' && sleep 0.1 && wpctl get-volume @DEFAULT_AUDIO_SINK@"];
                                setSinkProc.running = true;
                            }
                        }
                    }
                }
            }

            Process {
                id: setSinkProc
                stdout: StdioCollector {
                    onStreamFinished: {
                        var text = this.text.trim();
                        var match = text.match(/Volume:\s+(\d+(\.\d+)?)/);
                        if (match && match[1] && volumePanel.rootBar) {
                            volumePanel.rootBar.volValue = parseFloat(match[1]);
                            volumePanel.rootBar.volMuted = text.indexOf("[MUTED]") !== -1;
                        }
                    }
                }
            }

            // --- INPUT DEVICES (MICROPHONES) ---
            Text {
                text: "MICROPHONE DEVICE"
                color: volumePanel.rootBar ? volumePanel.rootBar._muted : "#6D8895"
                font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: sourcesModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        radius: 5
                        color: (model.sourceName === volumePanel.activeSourceName) ? (volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._brightCyn, 0.25) : "#337dcfff") : (micDeviceMouse.containsMouse ? (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a") : "transparent")
                        border.color: (model.sourceName === volumePanel.activeSourceName) ? (volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff") : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: (model.sourceName === volumePanel.activeSourceName) ? "󰍬" : "󰍭"
                                color: (model.sourceName === volumePanel.activeSourceName) ? (volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff") : (volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5")
                                font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                            }

                            Text {
                                text: model.displayName
                                color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                                font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                                font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: micDeviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var targetSource = model.sourceName;
                                volumePanel.activeSourceName = targetSource;
                                setSourceProc.command = ["bash", "-c", "pactl set-default-source '" + targetSource + "' && sleep 0.1 && wpctl get-volume @DEFAULT_AUDIO_SOURCE@"];
                                setSourceProc.running = true;
                            }
                        }
                    }
                }
            }

            Process {
                id: setSourceProc
                stdout: StdioCollector {
                    onStreamFinished: {
                        var text = this.text.trim();
                        var match = text.match(/Volume:\s+(\d+(\.\d+)?)/);
                        if (match && match[1]) volumePanel.micVolValue = parseFloat(match[1]);
                        volumePanel.micMuted = text.indexOf("[MUTED]") !== -1;
                    }
                }
            }

            // --- ACTION BUTTONS (APPS MIXER, MIC MUTE, MASTER MUTE) ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 6
                    color: showAppsMixer ? (volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._brightCyn, 0.25) : "#337dcfff") : (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a")
                    border.color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: showAppsMixer ? "󰅃" : "󰅀"
                            color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                            font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.95)
                        }
                        Text {
                            text: showAppsMixer ? "Hide Apps" : "Apps (" + appStreamsModel.count + ")"
                            color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                            font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                            font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            showAppsMixer = !showAppsMixer;
                            if (showAppsMixer) appStreamsProc.running = true;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 6
                    color: volumePanel.micMuted ? (volumePanel.rootBar ? volumePanel.rootBar._red : "#f7768e") : (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a")
                    border.color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: volumePanel.micMuted ? "󰍭 Mic Off" : "󰍬 Mic On"
                        color: volumePanel.micMuted ? "#ffffff" : (volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5")
                        font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: setMicMuteProc.running = true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 6
                    color: (volumePanel.rootBar && volumePanel.rootBar.volMuted) ? volumePanel.rootBar._red : (volumePanel.rootBar ? volumePanel.rootBar._sur : "#2b2d3a")
                    border.color: volumePanel.rootBar ? volumePanel.rootBar._acc : "#7aa2f7"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (volumePanel.rootBar && volumePanel.rootBar.volMuted) ? "󰝟 Muted" : "󰕾 Mute"
                        color: (volumePanel.rootBar && volumePanel.rootBar.volMuted) ? "#ffffff" : (volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5")
                        font.family: volumePanel.rootBar ? volumePanel.rootBar.iconFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: muteToggleProc.running = true
                    }
                }
            }

            Process { id: muteToggleProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
            Process { id: setMicMuteProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"] }

            // --- COLLAPSIBLE APPLICATION MIXER ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: showAppsMixer && appStreamsModel.count > 0

                Text {
                    text: "APPLICATION MIXER"
                    color: volumePanel.rootBar ? volumePanel.rootBar._brightCyn : "#7dcfff"
                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                    font.bold: true
                }

                Repeater {
                    model: appStreamsModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 6
                        color: volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._sur, 0.6) : "#24283b"
                        border.color: volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._brightBlu, 0.3) : "#3b4261"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: model.streamName
                                    color: volumePanel.rootBar ? volumePanel.rootBar._fg : "#c0caf5"
                                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.85)
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: Math.round(model.streamVol * 100) + "%"
                                    color: volumePanel.rootBar ? volumePanel.rootBar._brightBlu : "#7aa2f7"
                                    font.family: volumePanel.rootBar ? volumePanel.rootBar.globalFontFamily : "Outfit"
                                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.8)
                                }
                            }

                            Rectangle {
                                id: appTrackRect
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: volumePanel.rootBar ? volumePanel.rootBar.alphaColor(volumePanel.rootBar._brightBlu, 0.2) : "#1f2335"

                                Rectangle {
                                    height: parent.height
                                    radius: 4
                                    color: model.streamMuted ? (volumePanel.rootBar ? volumePanel.rootBar._red : "#f7768e") : (volumePanel.rootBar ? volumePanel.rootBar._brightBlu : "#7aa2f7")
                                    width: Math.max(0, Math.min(1.0, model.streamVol)) * parent.width
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: (mouse) => {
                                        if (pressed) {
                                            volumePanel.isDraggingAppVol = true;
                                            var pct = Math.max(0.0, Math.min(1.0, mouse.x / appTrackRect.width));
                                            model.streamVol = pct;
                                            var valPct = Math.round(pct * 100).toString();
                                            setStreamVolProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/sink-inputs.py", "--set-app-vol", model.streamName, valPct];
                                            setStreamVolProc.running = true;
                                        }
                                    }
                                    onPressed: (mouse) => {
                                        volumePanel.isDraggingAppVol = true;
                                        var pct = Math.max(0.0, Math.min(1.0, mouse.x / appTrackRect.width));
                                        model.streamVol = pct;
                                        var valPct = Math.round(pct * 100).toString();
                                        setStreamVolProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/sink-inputs.py", "--set-app-vol", model.streamName, valPct];
                                        setStreamVolProc.running = true;
                                    }
                                    onReleased: {
                                        volumePanel.isDraggingAppVol = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Process { id: setStreamVolProc }
        }
    }
}
