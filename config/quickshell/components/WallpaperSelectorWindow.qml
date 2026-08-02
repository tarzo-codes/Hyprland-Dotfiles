import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../themes"

PanelWindow {
    id: wallpaperWindow
    required property var modelData
    screen: modelData

    implicitWidth: 820
    implicitHeight: 560

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-selector"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.45)

    property var colors: null
    property var rootBar: null
    property string activeWallpaperPath: ""
    property string selectedWallpaperPath: ""
    property bool showAddFolderRow: false
    property bool syncThemeColors: true
    property bool ignoreTints: true
    property bool manualIconMode: false
    property string manualIconTheme: "Tela-blue"
    property string activeAppliedIconInfo: "Auto-detecting from wallpaper spectrum"

    property string recommendedIconTheme: "Tela-blue"
    property string recommendedIconColor: "#3584e4"
    property string savedIconTheme: ""
    property string savedBarTheme: ""
    property bool hasWallpaperMemory: false
    property bool applyMenuOpen: false

    function getIconHexColor(name) {
        var map = {
            "Tela-red": "#e74c3c", "Tela-pink": "#ec407a", "Tela-orange": "#e67e22",
            "Tela-ubuntu": "#e95420", "Tela-yellow": "#f39c12", "Tela-green": "#2ecc71",
            "Tela-manjaro": "#16a085", "Tela-nord": "#5e81ac", "Tela-blue": "#3584e4",
            "Tela-purple": "#9b59b6", "Tela-dracula": "#bd93f9", "Tela-brown": "#8d6e63",
            "Tela-grey": "#787c99", "Tela-black": "#555b6e"
        };
        return map[name] || "#3584e4";
    }

    onSelectedWallpaperPathChanged: {
        if (selectedWallpaperPath !== "") {
            fetchWpMemoryProc.command = ["python3", os.path.expanduser("~/.config/quickshell/scripts/wallpaper_memory.py"), "get", selectedWallpaperPath];
            fetchWpMemoryProc.running = false;
            fetchWpMemoryProc.running = true;
        }
    }

    Process {
        id: fetchWpMemoryProc
        command: ["python3", os.path.expanduser("~/.config/quickshell/scripts/wallpaper_memory.py"), "get", wallpaperWindow.selectedWallpaperPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text.trim());
                    wallpaperWindow.recommendedIconTheme = obj.recommendedIcon || "Tela-blue";
                    wallpaperWindow.recommendedIconColor = wallpaperWindow.getIconHexColor(wallpaperWindow.recommendedIconTheme);
                    wallpaperWindow.savedIconTheme = obj.savedIcon || "";
                    wallpaperWindow.savedBarTheme = obj.savedBar || "";
                    wallpaperWindow.hasWallpaperMemory = obj.hasMemory || false;
                } catch(e) {}
            }
        }
    }

    Process {
        id: saveWpMemoryProc
        property string iconToSave: ""
        property string barToSave: ""
        command: ["python3", os.path.expanduser("~/.config/quickshell/scripts/wallpaper_memory.py"), "set", wallpaperWindow.selectedWallpaperPath, iconToSave, barToSave]
    }

    function doApplyWallpaper(mode) {
        if (selectedWallpaperPath === "") return;
        if (syncThemeColors) {
            ThemeManager.colorMode = "wallust";
            applyWpProc.command = ["bash", "-c",
                "mkdir -p ~/.cache/quickshell && " +
                "touch ~/.cache/quickshell/wp_selector_open && " +
                "echo '" + (manualIconMode ? "true" : "false") + "' > ~/.cache/quickshell/manual_icon_mode && " +
                "echo '" + manualIconTheme + "' > ~/.cache/quickshell/manual_icon_theme && " +
                "bash \"$HOME/.config/scripts/wallpaper_picker.sh\" \"" + selectedWallpaperPath + "\""];
        } else {
            applyWpProc.command = ["bash", "-c",
                "bash \"$HOME/.config/scripts/wallpaper_picker.sh\" --wp-only \"" + selectedWallpaperPath + "\""];
            activeWallpaperPath = selectedWallpaperPath;
        }
        applyWpProc.running = false;
        applyWpProc.running = true;
    }

    ListModel {
        id: wallpaperModel
    }

    onVisibleChanged: {
        if (visible) {
            readActiveWpProc.running = true;
            readIgnoreTintsProc.running = true;
            readManualIconProc.running = true;
            scanWallpapersTimer.restart();
        }
    }

    Process {
        id: readIgnoreTintsProc
        command: ["bash", "-c", "cat ~/.cache/quickshell/ignore_wallpaper_tints 2>/dev/null || echo true"]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperWindow.ignoreTints = (this.text.trim() !== "false");
            }
        }
    }

    Process {
        id: toggleIgnoreTintsProc
        property string cmdStr: "echo true > ~/.cache/quickshell/ignore_wallpaper_tints"
        command: ["bash", "-c", cmdStr]
    }

    Process {
        id: readManualIconProc
        command: ["bash", "-c", "cat ~/.cache/quickshell/manual_icon_mode 2>/dev/null || echo false; echo '---'; cat ~/.cache/quickshell/manual_icon_theme 2>/dev/null || echo Tela-blue"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("---");
                if (parts.length >= 2) {
                    wallpaperWindow.manualIconMode = (parts[0].trim() === "true");
                    wallpaperWindow.manualIconTheme = parts[1].trim() || "Tela-blue";
                }
            }
        }
    }

    Process {
        id: applyManualIconProc
        property string targetTheme: "Tela-blue"
        command: ["bash", "-c", "echo '" + (wallpaperWindow.manualIconMode ? "true" : "false") + "' > ~/.cache/quickshell/manual_icon_mode && echo '" + targetTheme + "' > ~/.cache/quickshell/manual_icon_theme && bash ~/.config/quickshell/scripts/sync-theme-externals.sh"]
    }

    Timer {
        id: scanWallpapersTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: {
            wpScanner.running = true;
        }
    }

    // Process to read current active wallpaper
    Process {
        id: readActiveWpProc
        command: ["bash", "-c", "cat ~/.cache/quickshell/current_wallpaper 2>/dev/null || grep '^wallpaper = ' ~/.config/waypaper/config.ini 2>/dev/null | cut -d'=' -f2 | sed 's/^ *//;s|~/|/home/tarzo/|g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var active = this.text.trim();
                if (active !== "") {
                    wallpaperWindow.activeWallpaperPath = active;
                    if (wallpaperWindow.selectedWallpaperPath === "") {
                        wallpaperWindow.selectedWallpaperPath = active;
                    }
                }
            }
        }
    }

    // Process to scan wallpapers across ~/anime_wallapaper, ~/wallpapers, ~/wallpaper, ~/Pictures/Wallpapers, ~/.local/share/wallpapers and custom user dirs
    Process {
        id: wpScanner
        command: ["bash", "-c", "mkdir -p ~/.config/quickshell && touch ~/.config/quickshell/wallpaper_dirs.txt && find ~/anime_wallapaper ~/wallpapers ~/wallpaper ~/Pictures/Wallpapers ~/.local/share/wallpapers ~/.config/hypr/wallpapers /usr/share/backgrounds $(cat ~/.config/quickshell/wallpaper_dirs.txt 2>/dev/null) -maxdepth 2 -type f \\( -iname \"*.jpg\" -o -iname \"*.png\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" \\) 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path !== "") {
                        var fileName = path.substring(path.lastIndexOf('/') + 1);
                        wallpaperModel.append({
                            "path": path,
                            "name": fileName
                        });
                    }
                }
            }
        }
    }

    // Process to add custom wallpaper directory
    Process {
        id: addFolderProc
        property string folderToAdd: ""
        command: ["bash", "-c", "mkdir -p ~/.config/quickshell && echo \"$1\" | sed \"s|~/|$HOME/|\" >> ~/.config/quickshell/wallpaper_dirs.txt", "_", folderToAdd]
        stdout: StdioCollector {
            onStreamFinished: {
                folderInput.text = "";
                wallpaperWindow.showAddFolderRow = false;
                wpScanner.running = false;
                wpScanner.running = true;
            }
        }
    }

    Process {
        id: browseFolderProc
        command: ["bash", "-c", "zenity --file-selection --directory --title='Select Wallpaper Folder' 2>/dev/null || kdialog --getexistingdirectory 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var folder = this.text.trim();
                if (folder !== "") {
                    folderInput.text = folder;
                    addFolderProc.folderToAdd = folder;
                    addFolderProc.running = false;
                    addFolderProc.running = true;
                    scanCacheProc.folderToScan = folder;
                    scanCacheProc.running = false;
                    scanCacheProc.running = true;
                }
            }
        }
    }

    Process {
        id: scanCacheProc
        property string folderToScan: ""
        command: ["python3", os.path.expanduser("~/.config/quickshell/scripts/wallpaper_cache_builder.py"), "scan", folderToScan]
    }

    // Unified Process to apply selected wallpaper
    Process {
        id: applyWpProc
        command: ["bash", "-c", "echo 'No action'"]
    }

    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 800
        height: 540
        color: rootBar ? rootBar._bg : "#181825"
        border.color: rootBar ? rootBar._sur : "#313244"
        border.width: 1
        radius: 14

        scale: 0.95
        opacity: 0
        Component.onCompleted: {
            scale = 1.0;
            opacity = 1.0;
        }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "\uf03e"
                    color: rootBar ? rootBar._yel : "#fabd2f"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    text: "WALLPAPER SELECTOR"
                    color: rootBar ? rootBar._fg : "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 1.2)
                    font.bold: true
                    font.letterSpacing: 1.2
                    Layout.fillWidth: true
                }

                Text {
                    text: wallpaperModel.count + " wallpapers"
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Math.round(ThemeManager.globalFontSize * 0.9)
                }

                // Icon Color Mode: AUTO / MANUAL Toggle Button
                Rectangle {
                    width: 135; height: 26; radius: 6
                    color: wallpaperWindow.manualIconMode ? (rootBar ? rootBar._acc : "#e67e22") : (rootBar ? rootBar._sur : "#252836")
                    border.color: wallpaperWindow.manualIconMode ? "#ffffff" : (rootBar ? rootBar._sur : "#313244")
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: wallpaperWindow.manualIconMode ? "🎨" : "🪄"
                            font.pixelSize: 10
                        }
                        Text {
                            text: "Icon: " + (wallpaperWindow.manualIconMode ? "MANUAL" : "AUTO")
                            color: wallpaperWindow.manualIconMode ? "#181628" : (rootBar ? rootBar._fg : "#c0caf5")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: iconModeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallpaperWindow.manualIconMode = !wallpaperWindow.manualIconMode;
                            applyManualIconProc.targetTheme = wallpaperWindow.manualIconTheme;
                            applyManualIconProc.running = true;
                        }
                    }
                }

                // Experimental Tint Auto-Ignore Toggle Button
                Rectangle {
                    width: 125; height: 26; radius: 6
                    color: wallpaperWindow.ignoreTints ? (rootBar ? rootBar._sur : "#252836") : "transparent"
                    border.color: wallpaperWindow.ignoreTints ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._sur : "#313244")
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "🧪"
                            font.pixelSize: 10
                        }
                        Text {
                            text: "Ignore Tints: " + (wallpaperWindow.ignoreTints ? "ON" : "OFF")
                            color: wallpaperWindow.ignoreTints ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._muted : "#6D8895")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: tintIgnoreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallpaperWindow.ignoreTints = !wallpaperWindow.ignoreTints;
                            toggleIgnoreTintsProc.cmdStr = wallpaperWindow.ignoreTints ? "echo true > ~/.cache/quickshell/ignore_wallpaper_tints" : "echo false > ~/.cache/quickshell/ignore_wallpaper_tints";
                            toggleIgnoreTintsProc.running = true;
                        }
                    }
                }

                // Add Folder Toggle Button
                Rectangle {
                    width: 100; height: 26; radius: 6
                    color: addFolderMouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                    border.color: rootBar ? rootBar._sur : "#313244"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "\uf07b"
                            color: rootBar ? rootBar._acc : "#7aa2f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                        Text {
                            text: "Add Folder"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: addFolderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wallpaperWindow.showAddFolderRow = !wallpaperWindow.showAddFolderRow
                    }
                }

                // Close Button
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: closeMouse.containsMouse ? "#fb4934" : (rootBar ? rootBar._sur : "#313244")

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: closeMouse.containsMouse ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (wallpaperWindow.rootBar) {
                                wallpaperWindow.rootBar.wallpaperSelectorVisible = false;
                            } else {
                                wallpaperWindow.visible = false;
                            }
                        }
                    }
                }
            }

            // 🪄 RECOMMENDED & SAVED MEMORY DISPLAY CARD
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                visible: wallpaperWindow.selectedWallpaperPath !== ""
                color: rootBar ? rootBar._sur : "#252836"
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 12

                    // Auto Recommended Section
                    Row {
                        spacing: 6
                        Text {
                            text: "🪄 AUTO RECOMMENDED:"
                            color: rootBar ? rootBar._acc : "#7aa2f7"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                        }
                        Rectangle {
                            width: 90; height: 24; radius: 4
                            color: wallpaperWindow.recommendedIconColor
                            border.color: "#ffffff"; border.width: 1
                            Row {
                                anchors.centerIn: parent; spacing: 3
                                Text {
                                    text: wallpaperWindow.recommendedIconTheme.replace("Tela-", "")
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wallpaperWindow.manualIconTheme = wallpaperWindow.recommendedIconTheme;
                                    applyManualIconProc.targetTheme = wallpaperWindow.recommendedIconTheme;
                                    applyManualIconProc.running = true;
                                }
                            }
                        }
                    }

                    // Saved Memory Section
                    Row {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: "💾 MEMORY:"
                            color: rootBar ? rootBar._muted : "#6D8895"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                        }
                        Text {
                            text: wallpaperWindow.hasWallpaperMemory
                                ? ("Icon: " + (wallpaperWindow.savedIconTheme || "Auto") + " | Bar: " + (wallpaperWindow.savedBarTheme || "Current"))
                                : "No memory saved yet for this wallpaper"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                            elide: Text.ElideMiddle; Layout.fillWidth: true
                        }
                    }
                }
            }

            // Manual Icon Palette Selection Panel (collapsible when manualIconMode is true)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: wallpaperWindow.manualIconMode ? 46 : 0
                visible: wallpaperWindow.manualIconMode
                color: rootBar ? rootBar._sur : "#1e1e2e"
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1
                radius: 6
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "🎨 Pick Accent Icon:"
                        color: rootBar ? rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: iconSwatchesRow.width
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Row {
                            id: iconSwatchesRow
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter

                            property var swatches: [
                                {"name": "Tela-red", "color": "#e74c3c", "label": "Red"},
                                {"name": "Tela-pink", "color": "#ec407a", "label": "Pink"},
                                {"name": "Tela-orange", "color": "#e67e22", "label": "Orange"},
                                {"name": "Tela-ubuntu", "color": "#e95420", "label": "Ubuntu"},
                                {"name": "Tela-yellow", "color": "#f39c12", "label": "Yellow"},
                                {"name": "Tela-green", "color": "#2ecc71", "label": "Green"},
                                {"name": "Tela-manjaro", "color": "#16a085", "label": "Manjaro"},
                                {"name": "Tela-nord", "color": "#5e81ac", "label": "Nord"},
                                {"name": "Tela-blue", "color": "#3584e4", "label": "Blue"},
                                {"name": "Tela-purple", "color": "#9b59b6", "label": "Purple"},
                                {"name": "Tela-dracula", "color": "#bd93f9", "label": "Dracula"},
                                {"name": "Tela-brown", "color": "#8d6e63", "label": "Brown"},
                                {"name": "Tela-grey", "color": "#787c99", "label": "Grey"},
                                {"name": "Tela-black", "color": "#555b6e", "label": "Black"}
                            ]

                            Repeater {
                                model: iconSwatchesRow.swatches
                                delegate: Rectangle {
                                    width: 66; height: 26; radius: 5
                                    color: modelData.color
                                    border.color: (wallpaperWindow.manualIconTheme === modelData.name) ? "#ffffff" : "transparent"
                                    border.width: (wallpaperWindow.manualIconTheme === modelData.name) ? 2 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            wallpaperWindow.manualIconTheme = modelData.name;
                                            applyManualIconProc.targetTheme = modelData.name;
                                            applyManualIconProc.running = true;
                                            if (wallpaperWindow.selectedWallpaperPath !== "") {
                                                saveWpMemoryProc.iconToSave = modelData.name;
                                                saveWpMemoryProc.barToSave = ThemeManager.themeName;
                                                saveWpMemoryProc.running = false;
                                                saveWpMemoryProc.running = true;
                                                wallpaperWindow.savedIconTheme = modelData.name;
                                                wallpaperWindow.hasWallpaperMemory = true;
                                            }
                                        }
                                    }
                                }
                            }

                            // 🪄 Auto Recommended Badge
                            Rectangle {
                                width: 110; height: 26; radius: 5
                                color: wallpaperWindow.recommendedIconColor
                                border.color: "#ffffff"
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text { text: "🪄"; font.pixelSize: 9 }
                                    Text {
                                        text: "Auto: " + wallpaperWindow.recommendedIconTheme.replace("Tela-", "")
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wallpaperWindow.manualIconTheme = wallpaperWindow.recommendedIconTheme;
                                        applyManualIconProc.targetTheme = wallpaperWindow.recommendedIconTheme;
                                        applyManualIconProc.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 🎨 18 BAR THEMES SELECTION PANEL (collapsible when manualIconMode is true)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: wallpaperWindow.manualIconMode ? 46 : 0
                visible: wallpaperWindow.manualIconMode
                color: rootBar ? rootBar._sur : "#1e1e2e"
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1
                radius: 6
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "🎨 Bar Theme (18):"
                        color: rootBar ? rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10; font.bold: true
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: barThemeRow.width
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Row {
                            id: barThemeRow
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter

                            property var themes: [
                                "aline", "andrea", "brenda", "cristina", "cynthia", "daniela",
                                "emilia", "h4ck3r", "isabel", "jan", "karla", "marisol",
                                "melissa", "pamela", "silvia", "varinka", "yael", "z0mbi3"
                            ]

                            Repeater {
                                model: barThemeRow.themes
                                delegate: Rectangle {
                                    width: 68; height: 26; radius: 5
                                    color: (ThemeManager.themeName === modelData) ? (rootBar ? rootBar._acc : "#7aa2f7") : (rootBar ? rootBar._bg : "#313244")
                                    border.color: (wallpaperWindow.savedBarTheme === modelData) ? "#fabd2f" : "transparent"
                                    border.width: (wallpaperWindow.savedBarTheme === modelData) ? 1.5 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: (ThemeManager.themeName === modelData) ? "#ffffff" : (rootBar ? rootBar._fg : "#c0caf5")
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ThemeManager.themeName = modelData;
                                            if (wallpaperWindow.selectedWallpaperPath !== "") {
                                                saveWpMemoryProc.iconToSave = wallpaperWindow.manualIconTheme;
                                                saveWpMemoryProc.barToSave = modelData;
                                                saveWpMemoryProc.running = false;
                                                saveWpMemoryProc.running = true;
                                                wallpaperWindow.savedBarTheme = modelData;
                                                wallpaperWindow.hasWallpaperMemory = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Custom Directory Input Row (collapsible)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: wallpaperWindow.showAddFolderRow ? 38 : 0
                visible: wallpaperWindow.showAddFolderRow
                color: rootBar ? rootBar._sur : "#313244"
                border.color: rootBar ? rootBar._acc : "#7aa2f7"
                border.width: 1
                radius: 6
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8

                    Text {
                        text: "Folder Path:"
                        color: rootBar ? rootBar._muted : "#6D8895"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }

                    TextField {
                        id: folderInput
                        placeholderText: "/home/tarzo/Pictures or ~/Downloads"
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: rootBar ? rootBar._fg : "#c0caf5"
                        background: Rectangle {
                            color: "#151520"
                            radius: 4
                            border.color: folderInput.activeFocus ? (rootBar ? rootBar._acc : "#7aa2f7") : "#313244"
                            border.width: 1
                        }

                        onAccepted: {
                            if (text.trim() !== "") {
                                addFolderProc.folderToAdd = text.trim();
                                addFolderProc.running = false;
                                addFolderProc.running = true;
                            }
                        }
                    }

                    Rectangle {
                        width: 75; height: 26; radius: 4
                        color: browseBtnMouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : "#252836"
                        border.color: rootBar ? rootBar._acc : "#7aa2f7"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "📁"; font.pixelSize: 10 }
                            Text { text: "Browse"; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true }
                        }

                        MouseArea {
                            id: browseBtnMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                browseFolderProc.running = false;
                                browseFolderProc.running = true;
                            }
                        }
                    }

                    Rectangle {
                        width: 60; height: 26; radius: 4
                        color: addBtnMouse.containsMouse ? (rootBar ? rootBar._acc : "#7aa2f7") : "#313244"

                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: addBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (folderInput.text.trim() !== "") {
                                    addFolderProc.folderToAdd = folderInput.text.trim();
                                    addFolderProc.running = false;
                                    addFolderProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            // Wallpapers Grid View with High-Performance Asynchronous Thumbnail Loading
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: grid
                    model: wallpaperModel
                    cellWidth: 188
                    cellHeight: 126
                    anchors.fill: parent

                    delegate: Item {
                        width: grid.cellWidth - 10
                        height: grid.cellHeight - 10

                        property bool isSelected: wallpaperWindow.selectedWallpaperPath === path
                        property bool isActive: wallpaperWindow.activeWallpaperPath === path

                        Rectangle {
                            id: card
                            anchors.fill: parent
                            radius: 8
                            color: itemMouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : (rootBar ? rootBar._bg : "#1e1e2e")
                            border.color: isSelected ? (rootBar ? rootBar._acc : "#7aa2f7") : (isActive ? "#fabd2f" : "transparent")
                            border.width: isSelected || isActive ? 2 : 0
                            clip: true

                            scale: itemMouse.containsMouse ? 1.03 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Image {
                                id: thumb
                                anchors.fill: parent
                                anchors.margins: 3
                                source: "file://" + path
                                sourceSize.width: 320
                                sourceSize.height: 200
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                                opacity: isSelected || itemMouse.containsMouse ? 1.0 : 0.82
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            // Active / Selected Badge
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 22; height: 22; radius: 11
                                color: isActive ? "#fabd2f" : "#7aa2f7"
                                visible: isActive || isSelected

                                Text {
                                    anchors.centerIn: parent
                                    text: isActive ? "\uf00c" : "\uf06e"
                                    color: "#181825"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            // Wallpaper Name Overlay on Hover / Selection
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 22
                                color: Qt.rgba(0, 0, 0, 0.78)
                                visible: itemMouse.containsMouse || isSelected

                                Text {
                                    anchors.centerIn: parent
                                    text: name
                                    color: isSelected ? "#fabd2f" : "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: isSelected
                                    elide: Text.ElideMiddle
                                    width: parent.width - 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wallpaperWindow.selectedWallpaperPath = path;
                                }
                            }
                        }
                    }
                }
            }

            // Footer Bar with Apply Button, Sync Checkbox & Status
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: {
                        if (wallpaperWindow.selectedWallpaperPath === wallpaperWindow.activeWallpaperPath) {
                            return "✓ Active Wallpaper selected";
                        } else if (wallpaperWindow.selectedWallpaperPath !== "") {
                            var fn = wallpaperWindow.selectedWallpaperPath.substring(wallpaperWindow.selectedWallpaperPath.lastIndexOf('/') + 1);
                            return "Selected: " + fn;
                        }
                        return "Select a wallpaper and click Apply.";
                    }
                    color: rootBar ? rootBar._muted : "#6D8895"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                // Sync Theme Checkbox
                RowLayout {
                    spacing: 4

                    CheckBox {
                        id: syncThemeCb
                        checked: wallpaperWindow.syncThemeColors
                        onCheckedChanged: wallpaperWindow.syncThemeColors = checked
                    }

                    Text {
                        text: "Sync Theme (Wallust)"
                        color: rootBar ? rootBar._fg : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                // Rescan Button
                Rectangle {
                    width: 75
                    height: 32
                    radius: 6
                    color: refreshBtnMouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                    border.color: rootBar ? rootBar._sur : "#313244"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "\uf021"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                        Text {
                            text: "Rescan"
                            color: rootBar ? rootBar._fg : "#c0caf5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: refreshBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wpScanner.running = false;
                            wpScanner.running = true;
                        }
                    }
                }

                // SPLIT APPLY WALLPAPER & CUSTOM MODE DROPDOWN BUTTON
                Row {
                    spacing: 1

                    // Main Apply Button
                    Rectangle {
                        id: applyBtn
                        width: 110; height: 32
                        radius: 6
                        property bool isAlreadyApplied: wallpaperWindow.selectedWallpaperPath === wallpaperWindow.activeWallpaperPath || wallpaperWindow.selectedWallpaperPath === ""
                        color: isAlreadyApplied ? (rootBar ? rootBar._sur : "#313244") : (applyBtnMouse.containsMouse ? Qt.lighter(rootBar ? rootBar._acc : "#7aa2f7", 1.1) : (rootBar ? rootBar._acc : "#7aa2f7"))
                        opacity: isAlreadyApplied ? 0.6 : 1.0

                        Row {
                            anchors.centerIn: parent; spacing: 5
                            Text {
                                text: "\uf00c"
                                color: applyBtn.isAlreadyApplied ? (rootBar ? rootBar._muted : "#6D8895") : "#ffffff"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true
                            }
                            Text {
                                text: applyBtn.isAlreadyApplied ? "Applied" : "Apply"
                                color: applyBtn.isAlreadyApplied ? (rootBar ? rootBar._muted : "#6D8895") : "#ffffff"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                            }
                        }

                        MouseArea {
                            id: applyBtnMouse
                            anchors.fill: parent
                            hoverEnabled: !applyBtn.isAlreadyApplied
                            cursorShape: applyBtn.isAlreadyApplied ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!applyBtn.isAlreadyApplied && wallpaperWindow.selectedWallpaperPath !== "") {
                                    wallpaperWindow.doApplyWallpaper("auto");
                                }
                            }
                        }
                    }

                    // Dropdown Arrow Button
                    Rectangle {
                        width: 28; height: 32; radius: 6
                        color: dropdownMouse.containsMouse ? Qt.lighter(rootBar ? rootBar._acc : "#7aa2f7", 1.15) : (rootBar ? rootBar._acc : "#7aa2f7")

                        Text {
                            anchors.centerIn: parent
                            text: "▾"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: dropdownMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wallpaperWindow.applyMenuOpen = !wallpaperWindow.applyMenuOpen
                        }
                    }
                }
            }
        }
    }

    // Apply Options Popup Dropdown Menu
    Rectangle {
        id: applyDropdownPopup
        width: 260; height: dropdownColumn.implicitHeight + 16
        anchors.bottom: parent.bottom; anchors.right: parent.right
        anchors.bottomMargin: 48; anchors.rightMargin: 16
        visible: wallpaperWindow.applyMenuOpen
        color: rootBar ? rootBar._bg : "#181825"
        border.color: rootBar ? rootBar._acc : "#7aa2f7"
        border.width: 1
        radius: 8
        z: 999

        ColumnLayout {
            id: dropdownColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                text: "⚡ APPLY OPTIONS"
                color: rootBar ? rootBar._muted : "#6D8895"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9; font.bold: true
            }

            // Option 1: Apply Wallpaper (Auto Spectrum Colors)
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                color: opt1Mouse.containsMouse ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; spacing: 6
                    Text { text: "🪄"; font.pixelSize: 10 }
                    Text { text: "Apply with Auto Icon Theme"; color: rootBar ? rootBar._fg : "#c0caf5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                }
                MouseArea {
                    id: opt1Mouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperWindow.applyMenuOpen = false;
                        wallpaperWindow.doApplyWallpaper("auto");
                    }
                }
            }

            // Option 2: Apply with Saved Memory Icon Theme
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                opacity: wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedIconTheme !== "" ? 1.0 : 0.4
                color: opt2Mouse.containsMouse && wallpaperWindow.hasWallpaperMemory ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; spacing: 6
                    Text { text: "💾"; font.pixelSize: 10 }
                    Text {
                        text: wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedIconTheme !== "" ? ("Apply with Saved Icon: " + wallpaperWindow.savedIconTheme) : "No Saved Icon Memory"
                        color: rootBar ? rootBar._fg : "#c0caf5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                    }
                }
                MouseArea {
                    id: opt2Mouse; anchors.fill: parent
                    cursorShape: (wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedIconTheme !== "") ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedIconTheme !== "") {
                            wallpaperWindow.applyMenuOpen = false;
                            wallpaperWindow.manualIconMode = true;
                            wallpaperWindow.manualIconTheme = wallpaperWindow.savedIconTheme;
                            wallpaperWindow.doApplyWallpaper("saved_icon");
                        }
                    }
                }
            }

            // Option 3: Apply with Customized Bar Theme
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                opacity: wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedBarTheme !== "" ? 1.0 : 0.4
                color: opt3Mouse.containsMouse && wallpaperWindow.hasWallpaperMemory ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; spacing: 6
                    Text { text: "🎨"; font.pixelSize: 10 }
                    Text {
                        text: wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedBarTheme !== "" ? ("Apply with Saved Bar: " + wallpaperWindow.savedBarTheme) : "No Saved Bar Memory"
                        color: rootBar ? rootBar._fg : "#c0caf5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                    }
                }
                MouseArea {
                    id: opt3Mouse; anchors.fill: parent
                    cursorShape: (wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedBarTheme !== "") ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (wallpaperWindow.hasWallpaperMemory && wallpaperWindow.savedBarTheme !== "") {
                            wallpaperWindow.applyMenuOpen = false;
                            ThemeManager.themeName = wallpaperWindow.savedBarTheme;
                            wallpaperWindow.doApplyWallpaper("custom_bar");
                        }
                    }
                }
            }

            // Option 4: Apply All (Wallpaper + Saved Memory Icon + Saved Custom Bar)
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                opacity: wallpaperWindow.hasWallpaperMemory ? 1.0 : 0.4
                color: opt4Mouse.containsMouse && wallpaperWindow.hasWallpaperMemory ? (rootBar ? rootBar._sur : "#313244") : "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; spacing: 6
                    Text { text: "🌟"; font.pixelSize: 10 }
                    Text {
                        text: wallpaperWindow.hasWallpaperMemory ? "Apply All (Wallpaper + Saved Icon + Bar)" : "No Memory Saved"
                        color: rootBar ? rootBar._acc : "#7aa2f7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true
                    }
                }
                MouseArea {
                    id: opt4Mouse; anchors.fill: parent
                    cursorShape: wallpaperWindow.hasWallpaperMemory ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (wallpaperWindow.hasWallpaperMemory) {
                            wallpaperWindow.applyMenuOpen = false;
                            if (wallpaperWindow.savedIconTheme !== "") {
                                wallpaperWindow.manualIconMode = true;
                                wallpaperWindow.manualIconTheme = wallpaperWindow.savedIconTheme;
                            }
                            if (wallpaperWindow.savedBarTheme !== "") {
                                ThemeManager.themeName = wallpaperWindow.savedBarTheme;
                            }
                            wallpaperWindow.doApplyWallpaper("all");
                        }
                    }
                }
            }
        }
    }
}
