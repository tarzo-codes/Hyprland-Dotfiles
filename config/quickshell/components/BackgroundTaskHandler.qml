import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Item {
    id: root
    height: 24
    width: bgAppsModel.count > 0 ? appsRow.implicitWidth : 0
    visible: bgAppsModel.count > 0

    property var colors: null
    property var rootBar: null

    ListModel {
        id: bgAppsModel
    }

    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Timer {
        id: scanTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procScanner.running = true
    }

    // Process to scan running background apps using python to parse ps cleanly
    Process {
        id: procScanner
        command: ["python3", "-c", "import subprocess\ntry:\n    out = subprocess.check_output(['ps', '-u', 'tarzo', '-o', 'comm=,pid=']).decode('utf-8')\n    seen = set()\n    for line in out.splitlines():\n        parts = line.strip().split()\n        if len(parts) >= 2:\n            comm, pid = parts[0], parts[1]\n            for key in ['antigravity', 'discord', 'vesktop', 'spotify', 'steam', 'telegram', 'obs', 'slack', 'element', 'thunderbird', 'syncthing', 'dropbox']:\n                if key in comm.lower() and comm.lower() not in seen:\n                    seen.add(comm.lower())\n                    print(f'APP|{comm}|{pid}')\nexcept Exception:\n    pass"]
        stdout: StdioCollector {
            onStreamFinished: {
                bgAppsModel.clear();
                var addedNames = {};
                
                // Add SystemTray items first if any exist
                if (SystemTray.items && SystemTray.items.count > 0) {
                    for (var t = 0; t < SystemTray.items.count; t++) {
                        var item = SystemTray.items.get(t);
                        var title = item.title || item.id || "App";
                        var icon = item.icon || "";
                        addedNames[title.toLowerCase()] = true;
                        bgAppsModel.append({
                            "name": title,
                            "icon": icon,
                            "isTray": true,
                            "trayItem": item,
                            "pid": ""
                        });
                    }
                }

                // Add scanned processes
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("APP|")) {
                        var parts = line.split("|");
                        if (parts.length >= 3) {
                            var appName = parts[1];
                            var pid = parts[2];
                            var lowerName = appName.toLowerCase();
                            
                            if (!addedNames[lowerName]) {
                                addedNames[lowerName] = true;
                                bgAppsModel.append({
                                    "name": appName,
                                    "icon": "",
                                    "isTray": false,
                                    "pid": pid
                                });
                            }
                        }
                    }
                }
            }
        }
    }

    // Smart workspace focus & launch handler:
    // 1. If in magic workspace (special:magic), toggles special workspace & focuses window.
    // 2. If in another workspace, switches to that workspace & focuses window.
    // 3. If closed / not found, reopens application via gtk-launch or hyprctl dispatch exec.
    Process {
        id: openAppProc
        property string targetPid: ""
        property string targetName: ""
        command: ["python3", "-c", "import json, sys, subprocess; target_pid = '" + targetPid + "'; target_name = '" + targetName + "'; clients_json = subprocess.check_output(['hyprctl', 'clients', '-j']).decode('utf-8'); clients = json.loads(clients_json); matched = None;\nfor c in clients:\n    pid = str(c.get('pid', '')); cls = (c.get('class', '') or '').lower(); init_cls = (c.get('initialClass', '') or '').lower(); title = (c.get('title', '') or '').lower(); t_name = target_name.lower();\n    if (target_pid and pid == target_pid) or (t_name and (t_name in cls or t_name in init_cls or t_name in title)):\n        matched = c; break\nif matched:\n    ws = matched.get('workspace', {}); ws_name = ws.get('name', ''); ws_id = ws.get('id', 0); pid = matched.get('pid');\n    if ws_name.startswith('special:'):\n        sp_name = ws_name.replace('special:', ''); sp_name = sp_name if sp_name else 'magic';\n        subprocess.run(['hyprctl', 'dispatch', 'togglespecialworkspace', sp_name]);\n        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', f'pid:{pid}']);\n    else:\n        subprocess.run(['hyprctl', 'dispatch', 'workspace', str(ws_id)]);\n        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', f'pid:{pid}']);\nelse:\n    bin_name = target_name.lower();\n    if bin_name == 'antigravity':\n        subprocess.run(['hyprctl', 'dispatch', 'exec', 'gtk-launch antigravity']);\n    else:\n        subprocess.run(['hyprctl', 'dispatch', 'exec', f'gtk-launch {bin_name} || {bin_name}'])"]
    }

    RowLayout {
        id: appsRow
        spacing: 8
        anchors.centerIn: parent

        Repeater {
            model: bgAppsModel

            delegate: Item {
                id: trayDelegate
                width: 20
                height: 20

                scale: appMouse.containsMouse ? 1.25 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                function triggerOpenApp() {
                    if (isTray && trayItem) {
                        trayItem.activate();
                    }
                    openAppProc.running = false;
                    openAppProc.targetPid = pid || "";
                    openAppProc.targetName = name || "";
                    openAppProc.running = true;
                }

                Image {
                    id: appIconImg
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: icon || ""
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready && source != ""
                }

                // Fallback bright NerdFont icon if image source isn't available
                Text {
                    anchors.centerIn: parent
                    visible: !appIconImg.visible
                    text: {
                        var n = name.toLowerCase();
                        if (n.indexOf("discord") !== -1 || n.indexOf("vesktop") !== -1) return "󰙯";
                        if (n.indexOf("spotify") !== -1) return "󰓇";
                        if (n.indexOf("steam") !== -1) return "󰓓";
                        if (n.indexOf("telegram") !== -1) return "󰔁";
                        if (n.indexOf("obs") !== -1) return "󰑋";
                        if (n.indexOf("antigravity") !== -1) return "󰚩";
                        return "\uf2d0";
                    }
                    color: {
                        var n = name.toLowerCase();
                        if (n.indexOf("discord") !== -1 || n.indexOf("vesktop") !== -1) return "#7289da"; // Bright Discord Purple
                        if (n.indexOf("spotify") !== -1) return "#1db954"; // Bright Spotify Green
                        if (n.indexOf("antigravity") !== -1) return "#fabd2f"; // Bright Gruvbox Yellow
                        return root.colors ? (root.colors.brightYellow || "#fabd2f") : "#fabd2f";
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onDoubleClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            trayDelegate.triggerOpenApp();
                        }
                    }

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton && isTray && trayItem) {
                            trayItem.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
