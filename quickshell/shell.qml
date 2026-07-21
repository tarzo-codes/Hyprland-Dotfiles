import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "themes"
import "components"

ShellRoot {
    id: shellRoot

    // IPC — Theme control
    IpcHandler {
        target: "ThemeController"
        function toggleTheme() {
            if (ThemeManager.barIsDouble) {
                ThemeManager.themeName = "emilia";
            } else {
                ThemeManager.themeName = "melissa";
            }
        }
        function toggleThemeSelector() {
            shellRoot.themeSelectorVisible = !shellRoot.themeSelectorVisible;
        }
        function nextTheme() {
            ThemeManager.nextTheme();
        }
        function prevTheme() {
            ThemeManager.prevTheme();
        }
    }

    // IPC — Cheat sheet toggle
    IpcHandler {
        target: "CheatSheetController"
        function toggle() {
            shellRoot.cheatSheetVisible = !shellRoot.cheatSheetVisible;
        }
    }

    // Universal colors loader
    property var colors: themeColorsLoader ? themeColorsLoader.item : null
    Loader {
        id: themeColorsLoader
        source: ThemeManager.colorsPath
    }
    FileView {
        path: "/home/tarzo/.config/quickshell/wallust-colors.qml"
        watchChanges: true
        onFileChanged: {
            if (ThemeManager.colorMode === "wallust") {
                var current = themeColorsLoader.source;
                themeColorsLoader.source = "";
                themeColorsLoader.source = current;
            }
        }
    }

    // ─── Global typography & sizes — scale with bar height ─────────────────
    // Font sizes scale proportionally so content shrinks gracefully at low heights
    property int globalFontSize: ThemeManager.globalFontSize
    property int  iconFontSize:   Math.max(10, Math.round(ThemeManager.barHeight * 0.38))
    property string globalFontFamily: "JetBrainsMono Nerd Font"
    property string iconFontFamily:   "JetBrainsMono Nerd Font"

    // ─── Global state ─────────────────────────────────────────────────────────
    property bool powerMenuVisible:      false
    property bool settingsVisible:       false
    property bool themeSelectorVisible:  false
    property bool volumePanelVisible:    false
    property bool brightnessPanelVisible: false
    property bool networkPanelVisible:   false
    property bool mediaPlayerVisible:    false
    property bool cheatSheetVisible:     false
    property string userName:            "user"
    property string hostName:            "host"
    property int  barHeight:       ThemeManager.barHeight
    property real barWidthPercent: ThemeManager.barWidthPercent
    // Write-back so the slider in SettingsPanel updates the persistent store
    onBarHeightChanged:       ThemeManager.barHeight       = barHeight
    onBarWidthPercentChanged: ThemeManager.barWidthPercent = barWidthPercent
    property real brightnessValue:  0.8
    property real volValue:         0.5
    Behavior on brightnessValue { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property bool isAdjustingBrightness: false
    property bool isAdjustingVolume:     false

    Timer {
        id: brightCooldownTimer
        interval: 1500
        repeat: false
        onTriggered: shellRoot.isAdjustingBrightness = false
    }

    Timer {
        id: volCooldownTimer
        interval: 1500
        repeat: false
        onTriggered: shellRoot.isAdjustingVolume = false
    }

    function syncDeviceVolume() {
        shellRoot.isAdjustingVolume = false;
        volCooldownTimer.stop();
        volCommitTimer.stop();
        volumeGetProc.running = true;
    }

    Timer {
        id: brightCommitTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (shellRoot.isAdjustingBrightness) {
                brightnessSetProc.command = ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", Math.round(shellRoot.brightnessValue * 100).toString()];
                brightnessSetProc.running = true;
            }
        }
    }

    Timer {
        id: volCommitTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (shellRoot.isAdjustingVolume) {
                volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(shellRoot.volValue * 100) + "%"];
                volumeSetProc.running = true;
            }
        }
    }
    property bool volMuted:         false
    property bool isPlaying:        false   // media play/pause state
    property string distroName:     "Linux" // loaded dynamically
    property string cpuValue:       "--%"
    property string memValue:       "--GiB"
    property string fsValue:        "--GB"
    property string updatesValue:   "0"
    property string dateValue:      "--:--"
    property string songValue:      ""
    property string artistValue:    ""
    property string activeWinTitle: ""
    property string activeWinClass: ""
    property int    activeWsId:     1
    property string networkType:    "wired"

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netTypeDetectProc.running = true
    }
    Process {
        id: netTypeDetectProc
        command: ["bash", "-c", "IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1); if [ -z \"$IFACE\" ]; then echo \"offline\"; elif [[ \"$IFACE\" == wl* ]]; then echo \"wifi\"; else echo \"wired\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: shellRoot.networkType = this.text.trim()
        }
    }

    function alphaColor(hexStr, alpha) {
        var col = Qt.color(hexStr);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }

    function isWsActive(targetId) {
        if (Hyprland.activeWorkspace && Hyprland.activeWorkspace.id === targetId) return true;
        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === targetId) return true;
        return shellRoot.activeWsId === targetId;
    }

    // Auto-dismiss open panels/applets when user clicks outside onto another window
    Connections {
        target: Hyprland
        function onActiveWindowChanged() {
            shellRoot.volumePanelVisible = false;
            shellRoot.networkPanelVisible = false;
            shellRoot.compSettings = false;
            shellRoot.compThemeSelector = false;
            shellRoot.mediaPlayerVisible = false;
            shellRoot.cheatSheetVisible = false;
        }
    }

    // ─── Color helpers ────────────────────────────────────────────────────────
    function c(name, fallback) {
        return shellRoot.colors ? (shellRoot.colors[name] || fallback) : fallback
    }
    property string _bg:  c("background", "#0d0f18")
    property string _sur: c("surface",    "#1e1e2e")
    property string _fg:  c("foreground", "#c0caf5")
    property string _acc: c("accent",     "#7aa2f7")
    property string _red: c("red",        "#f7768e")
    property string _grn: c("green",      "#9ece6a")
    property string _yel: c("yellow",     "#e0af68")
    property string _blu: c("blue",       "#7aa2f7")
    property string _cyn: c("cyan",       "#7dcfff")
    property string _mag: c("magenta",    "#bb9af7")
    property string _muted: c("textMuted", "#6D8895")

    Binding on _bg  { value: c("background", "#0d0f18") }
    Binding on _sur { value: c("surface",    "#1e1e2e") }
    Binding on _fg  { value: c("foreground", "#c0caf5") }
    Binding on _acc { value: c("accent",     "#7aa2f7") }
    Binding on _red { value: c("red",        "#f7768e") }
    Binding on _grn { value: c("green",      "#9ece6a") }
    Binding on _yel { value: c("yellow",     "#e0af68") }
    Binding on _blu { value: c("blue",       "#7aa2f7") }
    Binding on _cyn { value: c("cyan",       "#7dcfff") }
    Binding on _mag { value: c("magenta",    "#bb9af7") }
    Binding on _muted { value: c("textMuted", "#6D8895") }

    function ensureBright(hex) {
        if (!hex || hex === "" || hex === "transparent") return "#ffffff";
        var c = Qt.color(hex);
        if (c.hslLightness < 0.60) {
            return Qt.hsla(c.hslHue, Math.max(0.70, c.hslSaturation), 0.75, 1.0).toString();
        }
        return hex;
    }

    readonly property string _brightRed: ensureBright(_red)
    readonly property string _brightGrn: ensureBright(_grn)
    readonly property string _brightYel: ensureBright(_yel)
    readonly property string _brightBlu: ensureBright(_blu)
    readonly property string _brightMag: ensureBright(_mag)
    readonly property string _brightCyn: ensureBright(_cyn)
    readonly property string _brightAcc: ensureBright(_acc)

    Process { id: dispatchProc }

    // ─── External theme sync (Mako + Vicinae) ────────────────────────────────
    // Fires 300ms after any theme/colorMode change. Also fires once at startup
    // (with a 1500ms grace so themeColorsLoader has time to fully resolve).
    Timer {
        id: syncDebounceTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            themeSyncProc.running = false
            themeSyncProc.running = true
        }
    }
    // One-shot startup sync — gives the Loader time to resolve colors first
    Timer {
        id: startupSyncTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: syncDebounceTimer.restart()
    }
    Connections {
        target: ThemeManager
        function onThemeNameChanged() { syncDebounceTimer.restart() }
        function onColorModeChanged()  { syncDebounceTimer.restart() }
    }
    // Also resync when wallust regenerates colors (wallpaper change)
    Connections {
        target: themeColorsLoader
        function onLoaded() { syncDebounceTimer.restart() }
    }


    // Helper functions for theme-specific icons
    // Each theme gets its own distinct workspace style
    function getWorkspaceIcon(index, isActive, isOccupied) {
        var theme = ThemeManager.themeName;
        var n = (index + 1).toString();

        // ── Number-based themes ───────────────────────────────────────
        if (theme === "cynthia" || theme === "melissa" || theme === "daniela" || theme === "varinka") {
            return n;  // plain numbers: 1 2 3 …
        }

        // ── Cyberpunk / hacker: brackets + numbers ────────────────────
        if (theme === "jan" || theme === "h4ck3r" || theme === "karla") {
            if (isActive)   return "[" + n + "]";
            if (isOccupied) return " " + n + " ";
            return   "·" + n + "·";
        }

        // ── Cozy / nature: leaf/circle glyphs ────────────────────────
        if (theme === "brenda" || theme === "silvia") {
            if (isActive)   return "󰮯 " + n;   // pac-man open + number
            if (isOccupied) return "󰊠";   // filled circle
            return "󰑊";                   // empty circle
        }

        // ── Minimalist: dot row (pamela, varinka-style) ───────────────
        if (theme === "pamela" || theme === "marisol") {
            if (isActive)   return "● " + n;   // filled dot + number
            if (isOccupied) return "◉";
            return "○";
        }

        // ── Warm/light themes: flower/star ────────────────────────────
        if (theme === "andrea" || theme === "aline") {
            if (isActive)   return "✦ " + n;   // star + number
            if (isOccupied) return "✧";
            return "·";
        }

        // ── Corporate / IBM: squares ──────────────────────────────────
        if (theme === "yael") {
            if (isActive)   return "■ " + n;   // square + number
            if (isOccupied) return "▪";
            return "□";
        }

        // ── jan: nerd font squares ────────────────────────────────────
        if (theme === "jan") {
            if (isActive)   return "󰚦 " + n;
            if (isOccupied) return "󰚩";
            return "•";
        }

        // ── z0mbi3 sidebar: just numbers ─────────────────────────────
        if (theme === "z0mbi3") return n;

        // ── Default fallback (emilia, cristina, isabel, etc.): pacman style
        if (isActive)   return "󰮯 " + n;
        if (isOccupied) return "󰊠";
        return "󰑊";
    }

    function getLauncherIcon() {
        if (ThemeManager.themeName === "andrea") return "󰏚";
        return "\uf303";
    }

    function contrastFg(bgColor, preferredFg) {
        var bgObj = Qt.color(bgColor);
        var fgObj = Qt.color(preferredFg);
        var bgLum = 0.299 * bgObj.r + 0.587 * bgObj.g + 0.114 * bgObj.b;
        var fgLum = 0.299 * fgObj.r + 0.587 * fgObj.g + 0.114 * fgObj.b;
        if (Math.abs(bgLum - fgLum) < 0.32) {
            return bgLum < 0.5 ? "#ffffff" : "#111217";
        }
        if (bgLum < 0.45 && fgLum < 0.45) {
            return "#ffffff";
        }
        if (bgLum >= 0.45 && fgLum >= 0.45) {
            return "#111217";
        }
        return preferredFg;
    }

    // Component map for all widgets
    function getWidget(type) {
        if (type === "launcher")     return compLauncher;
        if (type === "workspaces")        return compWorkspaces;
        if (type === "title")        return compTitle;
        if (type === "cpu")          return compCpu;
        if (type === "memory")       return compMemory;
        if (type === "filesystem")   return compFilesystem;
        if (type === "volume")       return compVolume;
        if (type === "brightness")   return compBrightness;
        if (type === "battery")      return compBattery;
        if (type === "network")      return compNetwork;
        if (type === "updates")      return compUpdates;
        if (type === "date")         return compDate;
        if (type === "power")        return compPower;
        if (type === "settings")     return compSettings;
        if (type === "bluetooth")    return compBluetooth;
        if (type === "colorpicker")  return compColorpicker;
        if (type === "mplayer")      return compMplayer;
        if (type === "weather")      return compWeather;
        if (type === "tray")         return compTray;
        if (type === "apps")         return compApps;
        if (type === "song")         return compSong;
        if (type === "arch_text")    return compArchText;
        if (type === "andrea_stats") return compAndreaStats;
        if (type === "cynthia_prompt") return compCynthiaPrompt;
        if (type === "cynthia_status") return compCynthiaStatus;
        if (type === "compact_player") return compCompactPlayer;
        return null;
    }

    // Decoupled Layout configuration (Top / Bottom) mapped directly from polybar dotfiles
    property var themeLayouts: ({
        aline: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title", "date", "weather"]}],
                right:  [{type: "capsule", modules: ["compact_player", "memory", "cpu", "filesystem", "battery", "network", "volume", "brightness", "bluetooth", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        andrea: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "andrea_stats"]}]
            }
        },
        brenda: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "cpu", "memory", "filesystem", "weather"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "bluetooth", "battery", "network", "volume", "brightness", "updates", "date", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        cristina: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "battery"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "network", "volume", "brightness"]}]
            },
            bottom: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "weather", "bluetooth", "updates", "filesystem", "cpu", "memory", "network", "volume", "brightness", "date", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        cynthia: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "title"]}],
                center: [{type: "capsule", modules: ["workspaces"]}],
                right:  [{type: "capsule", modules: ["compact_player", "filesystem", "cpu", "memory", "battery", "network", "volume", "brightness", "colorpicker", "settings", "power"]}]
            },
            bottom: {
                left:   [{type: "capsule", modules: ["cynthia_prompt"]}],
                center: [{type: "capsule", modules: ["mplayer"]}],
                right:  [{type: "capsule", modules: ["cynthia_status"]}]
            }
        },
        daniela: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "cpu", "memory", "filesystem", "weather", "tray"]}],
                center: [{type: "capsule", modules: ["title", "workspaces"]}],
                right:  [{type: "capsule", modules: ["compact_player", "bluetooth", "battery", "network", "volume", "brightness", "updates", "date", "colorpicker", "settings", "power"]}]
            }
        },
        emilia: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "battery", "memory", "filesystem"]}],
                center: [{type: "capsule", modules: ["title", "workspaces"]}],
                right:  [{type: "capsule", modules: ["compact_player", "network", "volume", "brightness", "updates", "date", "colorpicker", "settings", "power"]}]
            }
        },
        h4ck3r: {
            top: {
                left:   [{type: "capsule", modules: ["launcher"]}],
                center: [{type: "capsule", modules: ["title", "workspaces"]}],
                right:  [{type: "capsule", modules: ["compact_player", "bluetooth", "battery", "cpu", "network", "volume", "brightness", "updates", "date", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        isabel: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "battery"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "network", "volume", "brightness"]}]
            },
            bottom: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "weather"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "bluetooth", "updates", "filesystem", "cpu", "memory", "network", "volume", "brightness", "tray", "date", "colorpicker", "settings", "power"]}]
            }
        },
        jan: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "memory", "cpu", "filesystem", "battery", "network", "volume", "brightness", "updates", "date"]}, {type: "capsule", modules: ["colorpicker", "settings", "power"]}]
            }
        },
        karla: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "battery", "network", "volume", "brightness", "updates", "bluetooth", "tray", "date", "colorpicker", "settings", "power"]}]
            }
        },
        marisol: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title", "date", "weather"]}],
                right:  [{type: "capsule", modules: ["compact_player", "tray", "bluetooth", "battery", "cpu", "memory", "filesystem", "network", "volume", "brightness", "updates", "colorpicker", "settings", "power"]}]
            }
        },
        melissa: {
            top: { left: [], center: [], right: [] },
            bottom: { left: [], center: [], right: [] }
        },
        pamela: {
            top: {
                left:   [{type: "capsule", modules: ["launcher"]}, {type: "capsule", modules: ["workspaces"]}],
                center: [{type: "capsule", modules: ["title", "weather"]}],
                right:  [{type: "capsule", modules: ["compact_player", "battery", "filesystem", "cpu", "memory", "network", "volume"]}, {type: "capsule", modules: ["date"]}, {type: "capsule", modules: ["updates", "bluetooth", "brightness", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        silvia: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "title"]}],
                center: [],
                right:  [{type: "capsule", modules: ["compact_player", "bluetooth", "battery", "weather", "updates", "filesystem", "cpu", "memory", "network", "volume", "brightness", "date", "tray", "colorpicker", "settings", "power"]}]
            }
        },
        varinka: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces"]}],
                center: [{type: "capsule", modules: ["title"]}],
                right:  [{type: "capsule", modules: ["compact_player", "weather", "bluetooth", "battery", "updates", "filesystem", "cpu", "memory", "network", "volume", "brightness", "tray", "date", "colorpicker", "settings", "power"]}]
            }
        },
        yael: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "title"]}],
                center: [{type: "capsule", modules: ["date"]}],
                right:  [{type: "capsule", modules: ["compact_player", "memory", "cpu", "filesystem", "battery", "network", "volume", "brightness", "colorpicker", "settings", "power"]}]
            }
        },
        z0mbi3: {
            top: {
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "title"]}],
                center: [],
                right:  [{type: "capsule", modules: ["compact_player", "colorpicker", "bluetooth", "battery", "filesystem", "memory", "cpu", "network", "volume", "brightness", "updates", "tray", "date", "settings", "power"]}]
            }
        }
    })

    // Component Definition Delegates
    Component {
        id: compLauncher
        Item {
            width: launcherLayout.implicitWidth
            height: 30
            Row {
                id: launcherLayout
                spacing: 6
                anchors.centerIn: parent
                Text {
                    text: getLauncherIcon()
                    color: launcherMouse.containsMouse ? Qt.darker(shellRoot._acc, 1.25) : shellRoot._acc
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; font.bold: true; verticalAlignment: Text.AlignVCenter; height: 30
                }
                Text { text: ":"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30; visible: ThemeManager.barIsTopFloat && ThemeManager.themeName !== "andrea" }
            }
            MouseArea { id: launcherMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: launcherProc.running = true }
        }
    }

    Component {
        id: compWorkspaces
        Item {
            id: wsBox
            implicitWidth: wsRow.implicitWidth
            implicitHeight: 30

            property bool isCircleTheme: ["brenda", "silvia", "pamela", "marisol", "emilia", "cristina", "isabel"].indexOf(ThemeManager.themeName) !== -1

            // ── FLUID ACTIVE CONTAINER PILL ──
            Rectangle {
                id: activeFluidPill
                property int activeIdx: Math.max(0, Math.min(9, shellRoot.activeWsId - 1))
                property var targetItem: wsRepeater.itemAt(activeIdx)

                y: (wsBox.height - height) / 2
                height: wsBox.isCircleTheme ? 22 : 24
                radius: wsBox.isCircleTheme ? 11 : 5
                color: wsBox.isCircleTheme ? shellRoot._acc : shellRoot.alphaColor(shellRoot._acc, 0.35)
                border.color: wsBox.isCircleTheme ? "transparent" : shellRoot._acc
                border.width: wsBox.isCircleTheme ? 0 : 1

                x: targetItem ? targetItem.x + (targetItem.width - width) / 2 : 0
                width: targetItem ? (wsBox.isCircleTheme ? 22 : targetItem.width) : 24
                visible: targetItem != null

                Behavior on x {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.12
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Row {
                id: wsRow
                spacing: 9
                height: parent.height
                Repeater {
                    id: wsRepeater
                    model: 10
                    delegate: Item {
                        id: wsItem
                        property int n: index + 1
                        property bool isActive: shellRoot.isWsActive(n)
                        property bool isOccupied: (function() {
                            if (!Hyprland.workspaces) return false;
                            for (var i = 0; i < Hyprland.workspaces.length; i++) {
                                if (Hyprland.workspaces[i].id === n) return true;
                            }
                            return false;
                        })()

                        width: wsBox.isCircleTheme ? 24 : wsText.implicitWidth + 12
                        height: 30

                        // Subtle hover feedback
                        Rectangle {
                            anchors.fill: parent
                            radius: wsBox.isCircleTheme ? 12 : 5
                            color: wsMouse.containsMouse && !wsItem.isActive ? shellRoot.alphaColor(shellRoot._acc, 0.18) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            id: wsText
                            anchors.centerIn: parent
                            text: wsBox.isCircleTheme ? wsItem.n.toString() : getWorkspaceIcon(index, parent.isActive, parent.isOccupied)
                            color: {
                                if (parent.isActive)           return wsBox.isCircleTheme ? contrastFg(shellRoot._acc, "#ffffff") : contrastFg(shellRoot._bg, shellRoot._acc);
                                if (wsMouse.containsMouse)     return Qt.lighter(shellRoot._acc, 1.3);
                                if (parent.isOccupied)         return shellRoot._fg;
                                return shellRoot._muted;
                            }
                            opacity: wsMouse.containsMouse && !parent.isActive ? 0.75 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                            Behavior on color   { ColorAnimation  { duration: 120 } }
                            font.family:    shellRoot.globalFontFamily
                            font.pixelSize: wsBox.isCircleTheme ? 10 : shellRoot.globalFontSize
                            font.bold:      parent.isActive
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof Hyprland.focusWorkspace === "function") Hyprland.focusWorkspace(wsItem.n);
                                else { dispatchProc.command = ["hyprctl","dispatch","workspace",wsItem.n.toString()]; dispatchProc.running = true; }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: compTitle
        Text {
            text: shellRoot.activeWinClass !== "" ? (shellRoot.activeWinClass + " — " + shellRoot.activeWinTitle) : shellRoot.activeWinTitle
            color: shellRoot._fg
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
            font.bold: true
            elide: Text.ElideRight; width: text !== "" ? Math.min(260, implicitWidth) : 0
            verticalAlignment: Text.AlignVCenter; height: 30
            visible: text !== ""
        }
    }

    Component {
        id: compCpu
        Row {
            spacing: 6
            height: 30
            Text { text: "\uf2db"; color: shellRoot._brightRed; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: shellRoot.cpuValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compMemory
        Row {
            spacing: 6
            height: 30
            Text { text: "󰍛"; color: shellRoot._brightCyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: shellRoot.memValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compFilesystem
        Row {
            spacing: 6
            height: 30
            Text { text: "\uf200"; color: shellRoot._brightYel; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: shellRoot.fsValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compVolume
        Item {
            width: volumeLayout.implicitWidth
            height: 30
            Row {
                id: volumeLayout
                spacing: 6
                anchors.centerIn: parent
                Text {
                    text: shellRoot.volMuted ? "\uf026" : "\uf028"
                    color: volMouse.containsMouse ? Qt.darker(shellRoot._brightBlu, 1.25) : shellRoot._brightBlu
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
                Text {
                    text: Math.round(shellRoot.volValue*100) + "%"
                    color: volMouse.containsMouse ? Qt.darker(shellRoot._fg, 1.25) : shellRoot._fg
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
            }
            MouseArea {
                id: volMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        volumeMuteProc.running = true;
                    } else if (mouse.button === Qt.MiddleButton) {
                        plasmapaProc.running = true; // Opens plasma-pa!
                    } else {
                        // Left click toggles Quickshell's custom volume panel
                        shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible;
                    }
                }
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    shellRoot.isAdjustingVolume = true;
                    shellRoot.volValue = Math.max(0.0, Math.min(1.0, shellRoot.volValue + delta));
                    volCooldownTimer.restart();
                    volCommitTimer.restart();
                }
            }
        }
    }

    Component {
        id: compBrightness
        Item {
            width: brightnessLayout.implicitWidth
            height: 30
            Row {
                id: brightnessLayout
                spacing: 6
                anchors.centerIn: parent
                Text {
                    text: "\uf185"
                    color: brightMouse.containsMouse ? Qt.darker(shellRoot._brightYel, 1.25) : shellRoot._brightYel
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
                Text {
                    text: Math.round(shellRoot.brightnessValue*100) + "%"
                    color: brightMouse.containsMouse ? Qt.darker(shellRoot._fg, 1.25) : shellRoot._fg
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
            }
            MouseArea {
                id: brightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    shellRoot.brightnessPanelVisible = !shellRoot.brightnessPanelVisible;
                }
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    shellRoot.isAdjustingBrightness = true;
                    shellRoot.brightnessValue = Math.max(0.05, Math.min(1.0, shellRoot.brightnessValue + delta));
                    brightCooldownTimer.restart();
                    brightCommitTimer.restart();
                }
            }
        }
    }

    Component {
        id: compBattery
        Row {
            spacing: 6
            height: 30
            visible: UPower.battery !== null && UPower.battery.isPresent
            Text { text: UPower.battery && UPower.battery.charging ? "\uf0e7" : "\uf240"; color: shellRoot._brightGrn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: UPower.battery ? Math.round(UPower.battery.percentage) + "%" : ""; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compNetwork
        Network {
            colors: shellRoot.colors
            rootBar: shellRoot
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component {
        id: compUpdates
        Item {
            width: updatesLayout.implicitWidth
            height: 30
            Row {
                id: updatesLayout
                spacing: 6
                anchors.centerIn: parent
                Text {
                    text: "\uf0ec"
                    color: updatesMouse.containsMouse ? Qt.darker(shellRoot._brightGrn, 1.25) : shellRoot._brightGrn
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
                Text {
                    text: shellRoot.updatesValue
                    color: updatesMouse.containsMouse ? Qt.darker(shellRoot._fg, 1.25) : shellRoot._fg
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                }
            }
            MouseArea { id: updatesMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: checkUpdatesProc.running = true }
        }
    }

    Component {
        id: compDate
        Text {
            text: shellRoot.dateValue
            color: shellRoot._fg
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true
            verticalAlignment: Text.AlignVCenter; height: 30
        }
    }

    Component {
        id: compPower
        Text {
            text: "\uf011"
            color: powerMouse.containsMouse ? Qt.darker(shellRoot._red, 1.25) : shellRoot._red
            Behavior on color { ColorAnimation { duration: 120 } }
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
            MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
        }
    }

    Component {
        id: compSettings
        Text {
            text: "\uf013"
            color: settingsMouse.containsMouse ? Qt.darker(shellRoot._cyn, 1.25) : shellRoot._cyn
            Behavior on color { ColorAnimation { duration: 120 } }
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
            MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.settingsVisible = !shellRoot.settingsVisible }
        }
    }

    Component {
        id: compBluetooth
        Text {
            text: "\uf293"
            color: bluetoothMouse.containsMouse ? Qt.darker(shellRoot._blu, 1.25) : shellRoot._blu
            Behavior on color { ColorAnimation { duration: 120 } }
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
            MouseArea { id: bluetoothMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bluetoothProc.running = true }
        }
    }

    Component {
        id: compColorpicker
        Item {
            width: themeIconText.implicitWidth + 4
            height: 30
            Text {
                id: themeIconText
                anchors.centerIn: parent
                text: "󰏘"  // nf-md-palette — theme/palette icon
                color: themeBtnMouse.containsMouse
                    ? Qt.darker(shellRoot._mag, 1.3)
                    : shellRoot._mag
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily
                font.pixelSize: shellRoot.iconFontSize
                verticalAlignment: Text.AlignVCenter
                scale: themeBtnMouse.pressed ? 0.82 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
            }
            MouseArea {
                id: themeBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.themeSelectorVisible = !shellRoot.themeSelectorVisible
            }
        }
    }

    Component {
        id: compMplayer
        Row {
            spacing: 8
            height: 30

            // ── Prev button ────────────────────────────────────────────
            Item {
                width: prevIcon.implicitWidth + 6
                height: 30
                Text {
                    id: prevIcon
                    anchors.centerIn: parent
                    text: "\uf048"
                    color: prevMouse.containsMouse
                        ? Qt.darker(shellRoot._blu, 1.3)
                        : shellRoot._blu
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.globalFontSize
                    verticalAlignment: Text.AlignVCenter
                    scale: prevMouse.pressed ? 0.82 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { prevIcon.scale = 0.7; prevProc.running = true }
                }
            }

            // ── Play / Pause toggle ────────────────────────────────────
            Item {
                width: playIcon.implicitWidth + 8
                height: 30
                Text {
                    id: playIcon
                    anchors.centerIn: parent
                    // Toggle between play and pause glyphs
                    text: shellRoot.isPlaying ? "\uf04c" : "\uf04b"
                    color: playMouse.containsMouse
                        ? Qt.darker(shellRoot._grn, 1.3)
                        : shellRoot._grn
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on text  {
                        SequentialAnimation {
                            NumberAnimation { target: playIcon; property: "scale"; to: 0.6; duration: 80 }
                            PropertyAction  {}
                            NumberAnimation { target: playIcon; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                        }
                    }
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.globalFontSize + 1  // slightly bigger for play/pause
                    verticalAlignment: Text.AlignVCenter
                    scale: playMouse.pressed ? 0.75 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        shellRoot.isPlaying = !shellRoot.isPlaying
                        playProc.running = true
                    }
                }
            }

            // ── Next button ────────────────────────────────────────────
            Item {
                width: nextIcon.implicitWidth + 6
                height: 30
                Text {
                    id: nextIcon
                    anchors.centerIn: parent
                    text: "\uf051"
                    color: nextMouse.containsMouse
                        ? Qt.darker(shellRoot._blu, 1.3)
                        : shellRoot._blu
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.globalFontSize
                    verticalAlignment: Text.AlignVCenter
                    scale: nextMouse.pressed ? 0.82 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { nextIcon.scale = 0.7; nextProc.running = true }
                }
            }

            // ── Song title ─────────────────────────────────────────────
            Text {
                visible: shellRoot.songValue !== "" && ThemeManager.themeName !== "emilia" && ThemeManager.themeName !== "jan"
                text: "[ " + shellRoot.songValue + " ]"
                color: shellRoot._fg
                font.family: shellRoot.globalFontFamily
                font.pixelSize: shellRoot.globalFontSize + 2
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(240, implicitWidth)
                verticalAlignment: Text.AlignVCenter
                height: 30
            }
        }
    }

    Component {
        id: compWeather
        Row {
            spacing: 6
            height: 30
            Text { text: "☁"; color: shellRoot._cyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: "--°"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compTray
        BackgroundApps {
            rootBar: shellRoot
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // CUSTOM WIDGETS
    Component {
        id: compSong
        Text {
            visible: shellRoot.songValue !== ""
            text: "\uf001 [ " + shellRoot.songValue + " ]"
            color: shellRoot._acc
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
            elide: Text.ElideRight; width: Math.min(90, implicitWidth); clip: true
        }
    }

    Component {
        id: compArchText
        Text {
            text: shellRoot.distroName
            color: shellRoot._fg
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true
            verticalAlignment: Text.AlignVCenter; height: 30
        }
    }

    Component {
        id: compApps
        Row {
            spacing: 12
            height: 30
            Text { text: "💀"; color: shellRoot._acc; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: ""; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: ""; color: shellRoot._yel; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: ""; color: shellRoot._blu; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: ""; color: shellRoot._mag; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: ""; color: shellRoot._cyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    Component {
        id: compAndreaStats
        Row {
            spacing: 10
            height: 30
            Text { text: ""; color: shellRoot._yel; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text {
                text: " " + Math.round(shellRoot.volValue*100) + "%"
                color: andreaVolMouse.containsMouse ? Qt.darker(shellRoot._blu, 1.25) : shellRoot._blu
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                MouseArea {
                    id: andreaVolMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            volumeMuteProc.running = true;
                        } else {
                            shellRoot.networkPanelVisible = false;
                            shellRoot.settingsVisible = false;
                            shellRoot.powerMenuVisible = false;
                            shellRoot.themeSelectorVisible = false;
                            shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible;
                        }
                    }
                    onWheel: (wheel) => { if (wheel.angleDelta.y > 0) volumeUpProc.running = true; else volumeDownProc.running = true; }
                }
            }
            Text {
                text: " Online"
                color: andreaNetMouse.containsMouse ? Qt.darker(shellRoot._grn, 1.25) : shellRoot._grn
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                MouseArea {
                    id: andreaNetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        shellRoot.volumePanelVisible = false;
                        shellRoot.settingsVisible = false;
                        shellRoot.powerMenuVisible = false;
                        shellRoot.themeSelectorVisible = false;
                        shellRoot.networkPanelVisible = !shellRoot.networkPanelVisible;
                    }
                }
            }
            Text { text: " " + shellRoot.userName + "@" + shellRoot.hostName; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text {
                text: "󰏘"
                color: andreaThemeMouse.containsMouse ? Qt.darker(shellRoot._mag, 1.25) : shellRoot._mag
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                MouseArea { id: andreaThemeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.themeSelectorVisible = !shellRoot.themeSelectorVisible }
            }
            Text {
                text: ""
                color: andreaPowerMouse.containsMouse ? Qt.darker(shellRoot._red, 1.25) : shellRoot._red
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                MouseArea { id: andreaPowerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
            }
        }
    }

    Component {
        id: compCompactPlayer
        Rectangle {
            id: compactPlayerBg
            width: Math.min(120, compactPlayerRow.implicitWidth + 10)
            height: 30
            radius: 6
            clip: true
            color: compactPlayerMouse.containsMouse ? shellRoot.alphaColor(shellRoot._brightCyn, 0.2) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Row {
                id: compactPlayerRow
                spacing: 4
                anchors.centerIn: parent
                Text {
                    text: "\uf028"
                    color: shellRoot._brightCyn
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.iconFontSize
                    verticalAlignment: Text.AlignVCenter
                    height: 30
                }
                Text {
                    text: shellRoot.songValue !== "" ? shellRoot.songValue : "Media"
                    color: shellRoot._fg
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.globalFontSize
                    elide: Text.ElideRight
                    width: Math.min(85, implicitWidth)
                    verticalAlignment: Text.AlignVCenter
                    height: 30
                    clip: true
                }
            }
            MouseArea {
                id: compactPlayerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    shellRoot.volumePanelVisible = false;
                    shellRoot.networkPanelVisible = false;
                    shellRoot.settingsVisible = false;
                    shellRoot.powerMenuVisible = false;
                    shellRoot.themeSelectorVisible = false;
                    shellRoot.mediaPlayerVisible = !shellRoot.mediaPlayerVisible;
                }
            }
        }
    }

    Component {
        id: compCynthiaPrompt
        Text {
            text: shellRoot.userName + "@" + shellRoot.hostName + " ~"
            color: shellRoot._acc
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true
            verticalAlignment: Text.AlignVCenter; height: 30
        }
    }

    Component {
        id: compCynthiaStatus
        Row {
            spacing: 10
            height: 30
            Text { text: "Monocle | Float"; color: shellRoot._muted; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: "23°C"; color: shellRoot._cyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text {
                text: "VOL: " + Math.round(shellRoot.volValue*100) + "%"
                color: cynVolMouse.containsMouse ? Qt.darker(shellRoot._blu, 1.25) : shellRoot._blu
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30
                MouseArea {
                    id: cynVolMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            volumeMuteProc.running = true;
                        } else {
                            shellRoot.networkPanelVisible = false;
                            shellRoot.settingsVisible = false;
                            shellRoot.powerMenuVisible = false;
                            shellRoot.themeSelectorVisible = false;
                            shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible;
                        }
                    }
                    onWheel: (wheel) => { if (wheel.angleDelta.y > 0) volumeUpProc.running = true; else volumeDownProc.running = true; }
                }
            }
            Text { text: shellRoot.updatesValue; color: shellRoot._grn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: shellRoot.dateValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true; verticalAlignment: Text.AlignVCenter; height: 30 }
        }
    }

    // Master delegate to draw capsule containers and load inner modules dynamically
    Component {
        id: capsuleDelegate
        Item {
            height: 30
            width: childRow.implicitWidth + (modelData.type === "capsule" ? 24 : 0)
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: modelData.type === "capsule" ? shellRoot._sur : "transparent"
                border.width: 0

                RowLayout {
                    id: childRow
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        model: modelData.type === "capsule" ? modelData.modules : [modelData.type]
                        delegate: Loader {
                            Layout.alignment: Qt.AlignVCenter
                            sourceComponent: getWidget(modelData)
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // TOP BAR — single-top-float, single-top-full, andrea, and double top
    // =========================================================================
    Variants {
        model: (ThemeManager.barIsTop || ThemeManager.barIsDouble) ? Quickshell.screens : []
        delegate: Component {
            PanelWindow {
                id: topBar
                required property var modelData
                screen: modelData
                color: "transparent"
                anchors { top: true; left: true; right: true }
                implicitWidth: screen.width
                implicitHeight: barHeight

                property real animatedMargin: (ThemeManager.barIsTopFloat && ThemeManager.themeName !== "melissa")
                    ? screen.width * (1.0 - shellRoot.barWidthPercent) / 2
                    : 0
                Behavior on animatedMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                // ── Bar container ─────────────────────────────────────────────
                Rectangle {
                    id: barRect
                    anchors {
                        top: parent.top
                        left: parent.left; right: parent.right
                        leftMargin:  topBar.animatedMargin
                        rightMargin: topBar.animatedMargin
                    }
                    height: shellRoot.barHeight
                    color: (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa") ? "transparent" : shellRoot._bg
                    radius: 0
                    border.width: 0

                    Item {
                        anchors.fill: parent
                        // Vertical inset so pills never touch bar edges (disabled for Melissa)
                        anchors.topMargin: ThemeManager.themeName === "melissa" ? 0 : 5
                        anchors.bottomMargin: ThemeManager.themeName === "melissa" ? 0 : 5
                        anchors.leftMargin: (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa") ? 0 : 12
                        anchors.rightMargin: (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa") ? 0 : 12

                        // ══ LEFT ZONE ══
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"
                            
                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.left : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ CENTER ZONE ══
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.center : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ RIGHT ZONE ══
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.right : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // ── MELISSA TOP BAR POWERLINE SHARP RHOMBUSES (LEFT) ──
                        // ══════════════════════════════════════════════════════
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0
                            visible: ThemeManager.themeName === "melissa"

                            // Arch logo + active window title
                            Rectangle {
                                height: parent.height
                                width: melTopArchRow.width + 16
                                color: shellRoot._sur
                                Row {
                                    id: melTopArchRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 8
                                    Text { text: "\uf303"; color: contrastFg(shellRoot._sur, shellRoot._brightAcc); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; font.bold: true; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: shellRoot.distroName; color: contrastFg(shellRoot._sur, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text {
                                        visible: Hyprland.activeWindow !== null
                                        text: Hyprland.activeWindow ? Hyprland.activeWindow.title : ""
                                        color: contrastFg(shellRoot._sur, shellRoot._muted); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
                                        elide: Text.ElideRight; width: Math.min(100, implicitWidth); verticalAlignment: Text.AlignVCenter; height: parent.height
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Colorpicker + Settings + Power block (Moved from bottom bar to top bar left!)
                            Rectangle {
                                height: parent.height
                                width: melPickerPowerRow.width + 16
                                color: shellRoot._muted
                                Row {
                                    id: melPickerPowerRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 6
                                    Item {
                                        width: 24; height: parent.height
                                        Text { anchors.centerIn: parent; text: "\uf1fb"; color: contrastFg(shellRoot._muted, shellRoot._brightGrn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: colorpickerProc.running = true }
                                    }
                                    Item {
                                        width: 24; height: parent.height
                                        Text { anchors.centerIn: parent; text: "\uf013"; color: contrastFg(shellRoot._muted, shellRoot._brightCyn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.settingsVisible = !shellRoot.settingsVisible }
                                    }
                                    Item {
                                        width: 24; height: parent.height
                                        Text { anchors.centerIn: parent; text: "\uf011"; color: contrastFg(shellRoot._muted, shellRoot._brightRed); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: "transparent"
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // ── MELISSA TOP BAR CENTER (ACTIVE APP / WINDOW TITLE) ─
                        // ══════════════════════════════════════════════════════
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0
                            visible: ThemeManager.themeName === "melissa" && shellRoot.activeWinTitle !== ""

                            SlantSeparator {
                                colorLeft: "transparent"
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            Rectangle {
                                height: parent.height
                                width: melCenterTitleRow.width + 24
                                color: shellRoot._sur

                                Row {
                                    id: melCenterTitleRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 8

                                    Text {
                                        text: "󰖯"
                                        color: contrastFg(shellRoot._sur, shellRoot._brightAcc)
                                        font.family: shellRoot.globalFontFamily
                                        font.pixelSize: shellRoot.iconFontSize
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                        height: parent.height
                                    }

                                    Text {
                                        text: shellRoot.activeWinClass !== "" ? (shellRoot.activeWinClass + " — " + shellRoot.activeWinTitle) : shellRoot.activeWinTitle
                                        color: contrastFg(shellRoot._sur, shellRoot._fg)
                                        font.family: shellRoot.globalFontFamily
                                        font.pixelSize: shellRoot.globalFontSize
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: Math.min(320, implicitWidth)
                                        verticalAlignment: Text.AlignVCenter
                                        height: parent.height
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: "transparent"
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // ── MELISSA TOP BAR POWERLINE SHARP RHOMBUSES (RIGHT) ─
                        // ══════════════════════════════════════════════════════
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0
                            visible: ThemeManager.themeName === "melissa"

                            SlantSeparator {
                                colorLeft: "transparent"
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // CPU
                            Rectangle {
                                height: parent.height
                                width: melTopCpu.width + 16
                                color: shellRoot._sur
                                Row {
                                    id: melTopCpu; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: "\uf2db"; color: contrastFg(shellRoot._sur, shellRoot._brightRed); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: "CPU: " + shellRoot.cpuValue; color: contrastFg(shellRoot._sur, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // RAM
                            Rectangle {
                                height: parent.height
                                width: melTopMem.width + 16
                                color: shellRoot._muted
                                Row {
                                    id: melTopMem; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: "󰍛"; color: contrastFg(shellRoot._muted, shellRoot._brightCyn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: shellRoot.memValue; color: contrastFg(shellRoot._muted, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Disk
                            Rectangle {
                                height: parent.height
                                width: melTopFs.width + 16
                                color: shellRoot._sur
                                Row {
                                    id: melTopFs; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: "\uf200"; color: contrastFg(shellRoot._sur, shellRoot._brightYel); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: shellRoot.fsValue; color: contrastFg(shellRoot._sur, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Network
                            Rectangle {
                                height: parent.height
                                width: melTopNet.width + 16
                                color: melNetMouse.containsMouse ? Qt.darker(shellRoot._muted, 1.2) : shellRoot._muted
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row {
                                    id: melTopNet; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: shellRoot.networkType === "wifi" ? "\uf1eb" : (shellRoot.networkType === "wired" ? "\uf0ec" : "\uf127"); color: contrastFg(shellRoot._muted, shellRoot.networkType !== "offline" ? shellRoot._brightBlu : shellRoot._brightRed); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                                MouseArea {
                                    id: melNetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        shellRoot.volumePanelVisible = false;
                                        shellRoot.settingsVisible = false;
                                        shellRoot.powerMenuVisible = false;
                                        shellRoot.themeSelectorVisible = false;
                                        shellRoot.networkPanelVisible = !shellRoot.networkPanelVisible;
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Volume
                            Rectangle {
                                height: parent.height
                                width: melTopVol.width + 16
                                color: melVolTopMouse.containsMouse ? Qt.darker(shellRoot._sur, 1.2) : shellRoot._sur
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row {
                                    id: melTopVol; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text {
                                        text: shellRoot.volMuted ? "\uf026" : "\uf028"
                                        color: contrastFg(shellRoot._sur, shellRoot._brightBlu)
                                        font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height
                                    }
                                    Text {
                                        text: Math.round(shellRoot.volValue*100) + "%"
                                        color: Math.round(shellRoot.volValue*100) > 100 ? shellRoot._brightYel : contrastFg(shellRoot._sur, shellRoot._fg)
                                        font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height
                                    }
                                }
                                MouseArea {
                                    id: melVolTopMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            volumeMuteProc.running = true;
                                        } else {
                                            shellRoot.networkPanelVisible = false;
                                            shellRoot.settingsVisible = false;
                                            shellRoot.powerMenuVisible = false;
                                            shellRoot.themeSelectorVisible = false;
                                            shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible;
                                        }
                                    }
                                    onWheel: (wheel) => { var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05; shellRoot.isAdjustingVolume = true; shellRoot.volValue = Math.max(0.0, Math.min(1.0, shellRoot.volValue + delta)); volCooldownTimer.restart(); volCommitTimer.restart(); }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Brightness
                            Rectangle {
                                height: parent.height
                                width: melTopBright.width + 16
                                color: melBrightTopMouse.containsMouse ? Qt.darker(shellRoot._muted, 1.2) : shellRoot._muted
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row {
                                    id: melTopBright; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: "\uf185"; color: contrastFg(shellRoot._muted, shellRoot._brightYel); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: Math.round(shellRoot.brightnessValue * 100) + "%"; color: contrastFg(shellRoot._muted, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                                MouseArea {
                                    id: melBrightTopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        shellRoot.brightnessPanelVisible = !shellRoot.brightnessPanelVisible;
                                    }
                                    onWheel: (wheel) => {
                                        var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                        shellRoot.isAdjustingBrightness = true;
                                        shellRoot.brightnessValue = Math.max(0.05, Math.min(1.0, shellRoot.brightnessValue + delta));
                                        brightCooldownTimer.restart();
                                        brightCommitTimer.restart();
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                                visible: UPower.battery && UPower.battery.isPresent
                            }

                            // Battery
                            Rectangle {
                                height: parent.height
                                width: melTopBat.width + 16
                                color: shellRoot._sur
                                visible: UPower.battery && UPower.battery.isPresent
                                Row {
                                    id: melTopBat; spacing: 5; anchors.centerIn: parent; height: parent.height
                                    Text { text: UPower.battery && UPower.battery.charging ? "\uf0e7" : "\uf240"; color: contrastFg(shellRoot._sur, shellRoot._brightGrn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    Text { text: UPower.battery ? Math.round(UPower.battery.percentage) + "%" : ""; color: contrastFg(shellRoot._sur, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Date
                            Rectangle {
                                height: parent.height
                                width: melTopDate.width + 16
                                color: shellRoot._muted
                                Row {
                                    id: melTopDate; anchors.centerIn: parent; height: parent.height
                                    Text { text: shellRoot.dateValue; color: contrastFg(shellRoot._muted, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                }
                            }
                        }
                    }
                }

                // ── Overlays attached to top bar ──────────────────────────────
                PowerMenuWindow {
                    modelData: topBar.screen; colors: shellRoot.colors
                    visible: shellRoot.powerMenuVisible
                    onCloseRequested: shellRoot.powerMenuVisible = false
                }
                SettingsPanel {
                    id: settingsPanel
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.settingsVisible
                }
                ThemeSelectorWindow {
                    id: themeWindow
                    modelData: topBar.screen; colors: shellRoot.colors
                    isVisible: shellRoot.themeSelectorVisible
                    onIsVisibleChanged: shellRoot.themeSelectorVisible = isVisible
                }
                VolumePanel {
                    id: volPanel
                    modelData: topBar.screen
                    rootBar: shellRoot
                    visible: shellRoot.volumePanelVisible
                }
                BrightnessPanel {
                    id: brightPanel
                    modelData: topBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: shellRoot.brightnessPanelVisible
                }
                NetworkPanel {
                    id: netPanel
                    modelData: topBar.screen
                    rootBar: shellRoot
                    visible: shellRoot.networkPanelVisible
                }
                MediaPlayerWindow {
                    id: mediaWindow
                    modelData: topBar.screen
                    rootBar: shellRoot
                    visible: shellRoot.mediaPlayerVisible
                }
                CheatSheet {
                    rootBar: shellRoot
                    isVisible: shellRoot.cheatSheetVisible
                    onIsVisibleChanged: shellRoot.cheatSheetVisible = isVisible
                }

            }
        }
    }

    // ─── Multi-Monitor Hardware + Software Brightness Dimming Overlay ──────────
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            mask: Region {} // Empty input region: 100% click-through pass-through

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-brightness-overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Qt.rgba(0, 0, 0, Math.max(0.0, Math.min(0.85, (1.0 - shellRoot.brightnessValue) * 0.75)))
            visible: shellRoot.brightnessValue < 0.98
        }
    }

    // =========================================================================
    // BOTTOM BAR — melissa + cynthia (double) and cristina + isabel (single-bottom)
    // =========================================================================
    Variants {
        model: (ThemeManager.barIsDouble || ThemeManager.barIsBottom) ? Quickshell.screens : []
        delegate: Component {
            PanelWindow {
                id: bottomBar
                required property var modelData
                screen: modelData
                color: "transparent"
                anchors { bottom: true; left: true; right: true }
                implicitWidth: screen.width
                implicitHeight: shellRoot.barHeight

                Rectangle {
                    anchors.fill: parent
                    color: ThemeManager.themeName === "melissa" ? "transparent" : shellRoot._bg
                    opacity: ThemeManager.barIsDualCynthia ? 0.85 : 1.0
                    radius: 0
                    border.width: 0

                    Item {
                        anchors.fill: parent
                        // Vertical inset so pills never touch bar edges (disabled for Melissa)
                        anchors.topMargin: ThemeManager.themeName === "melissa" ? 0 : 5
                        anchors.bottomMargin: ThemeManager.themeName === "melissa" ? 0 : 5
                        anchors.leftMargin: ThemeManager.themeName === "melissa" ? 0 : 12
                        anchors.rightMargin: ThemeManager.themeName === "melissa" ? 0 : 12

                        // ══ LEFT ZONE ══
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].bottom ? themeLayouts[ThemeManager.themeName].bottom.left : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ CENTER ZONE ══
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].bottom ? themeLayouts[ThemeManager.themeName].bottom.center : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ RIGHT ZONE ══
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].bottom ? themeLayouts[ThemeManager.themeName].bottom.right : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // ── MELISSA BOTTOM BAR POWERLINE SHARP RHOMBUSES ──
                        // ══════════════════════════════════════════════════════
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0
                            visible: ThemeManager.themeName === "melissa"

                            // Workspaces block
                            Rectangle {
                                height: parent.height
                                width: melWorkspacesRow.width + 16
                                color: shellRoot._sur

                                // Fluid Sliding Active Accent Container
                                Rectangle {
                                    id: melFluidPill
                                    property int activeIdx: Math.max(0, Math.min(5, shellRoot.activeWsId - 1))
                                    property var targetItem: melRepeater.itemAt(activeIdx)

                                    y: (parent.height - height) / 2
                                    height: parent.height - 8
                                    radius: 4
                                    color: shellRoot._acc

                                    x: targetItem ? (melWorkspacesRow.x + targetItem.x) : 8
                                    width: targetItem ? targetItem.width : 40
                                    visible: targetItem != null

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 240
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 1.12
                                        }
                                    }
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Row {
                                    id: melWorkspacesRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 10
                                    Repeater {
                                        id: melRepeater
                                        model: ["TERM", "SYS", "WWW", "CHAT", "VBOX", "GAMES"]
                                        delegate: Item {
                                            width: 70
                                            height: parent.height
                                            property bool isActive:   shellRoot.isWsActive(index + 1)
                                            property bool isOccupied: (function() {
                                                if (!Hyprland.workspaces) return false;
                                                for (var i = 0; i < Hyprland.workspaces.length; i++) {
                                                    if (Hyprland.workspaces[i].id === (index + 1)) return true;
                                                }
                                                return false;
                                            })()
                                            Text {
                                                id: wsLabel
                                                anchors.centerIn: parent
                                                text: (parent.isActive || wsMouse.containsMouse) ? "[ " + modelData + " ]" : modelData
                                                color: {
                                                    if (parent.isActive)           return contrastFg(shellRoot._acc, shellRoot._bg);
                                                    if (wsMouse.containsMouse)     return contrastFg(shellRoot._sur, shellRoot._acc);
                                                    if (parent.isOccupied)         return contrastFg(shellRoot._sur, shellRoot._fg);
                                                    return contrastFg(shellRoot._sur, shellRoot._muted);
                                                }
                                                font.family: shellRoot.globalFontFamily
                                                font.pixelSize: shellRoot.globalFontSize - 2
                                                font.bold: parent.isActive
                                                verticalAlignment: Text.AlignVCenter
                                                height: parent.height
                                            }
                                            MouseArea {
                                                id: wsMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (typeof Hyprland.focusWorkspace === "function") Hyprland.focusWorkspace(index + 1);
                                                    else { dispatchProc.command = ["hyprctl","dispatch","workspace",(index+1).toString()]; dispatchProc.running = true; }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._sur
                                colorRight: shellRoot._muted
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Media block
                            Rectangle {
                                height: parent.height
                                width: melMediaBlockRow.width + 20
                                color: shellRoot._muted
                                Row {
                                    id: melMediaBlockRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 10
                                    Text { text: "\uf048"; color: contrastFg(shellRoot._muted, shellRoot._brightBlu); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: prevProc.running = true } }
                                    Text { text: "\uf04b"; color: contrastFg(shellRoot._muted, shellRoot._brightGrn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: playProc.running = true } }
                                    Text { text: "\uf051"; color: contrastFg(shellRoot._muted, shellRoot._brightBlu); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: nextProc.running = true } }
                                    Text {
                                         visible: shellRoot.songValue !== ""
                                         text: "[ " + shellRoot.songValue + " ]"
                                         color: contrastFg(shellRoot._muted, shellRoot._brightAcc)
                                         font.family: shellRoot.globalFontFamily
                                         font.pixelSize: shellRoot.globalFontSize
                                         font.bold: true
                                         elide: Text.ElideRight
                                         width: Math.min(480, implicitWidth)
                                         verticalAlignment: Text.AlignVCenter
                                         height: parent.height
                                     }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: "transparent"
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }


                        }
                    }
                }

                // Overlays for bottom-only themes
                PowerMenuWindow {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    visible: ThemeManager.barIsBottom && shellRoot.powerMenuVisible
                    onCloseRequested: shellRoot.powerMenuVisible = false
                }
                SettingsPanel {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: ThemeManager.barIsBottom && shellRoot.settingsVisible
                }
                ThemeSelectorWindow {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    isVisible: ThemeManager.barIsBottom && shellRoot.themeSelectorVisible
                    onIsVisibleChanged: shellRoot.themeSelectorVisible = isVisible
                }
                VolumePanel {
                    modelData: bottomBar.screen
                    rootBar: shellRoot
                    visible: ThemeManager.barIsBottom && shellRoot.volumePanelVisible
                }
                NetworkPanel {
                    modelData: bottomBar.screen
                    rootBar: shellRoot
                    visible: ThemeManager.barIsBottom && shellRoot.networkPanelVisible
                }
            }
        }
    }

    // =========================================================================
    // SIDEBAR — z0mbi3 vertical left panel
    // =========================================================================
    Variants {
        model: ThemeManager.barIsSidebar ? Quickshell.screens : []
        delegate: Component {
            PanelWindow {
                id: sideBar
                required property var modelData
                screen: modelData
                color: "transparent"
                anchors { left: true; top: true; bottom: true }
                implicitWidth: 48
                implicitHeight: screen.height

                Rectangle {
                    anchors { fill: parent; leftMargin: 6; topMargin: 6; bottomMargin: 6 }
                    color: shellRoot._bg; radius: 10
                    border { width: 1; color: shellRoot._sur }

                    Column {
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                        spacing: 10

                        // Arch launcher
                        Item {
                            width: 34; height: 34
                            scale: sbLaunchHov.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 130 } }
                            Text { anchors.centerIn: parent; text: "\uf303"; color: shellRoot._acc; font.pixelSize: 16; font.family: shellRoot.globalFontFamily }
                            MouseArea { id: sbLaunchHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: launcherProc.running = true }
                        }

                        // Workspaces
                        Repeater {
                            model: 10
                            delegate: Item {
                                width: 34; height: 18
                                property bool isActive:   shellRoot.isWsActive(index + 1)
                                property bool isOccupied: (function() {
                                    if (!Hyprland.workspaces) return false;
                                    for (var i=0; i<Hyprland.workspaces.length; i++) {
                                        if (Hyprland.workspaces[i].id === (index+1)) return true;
                                    }
                                    return false;
                                })()
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: parent.isActive
                                        ? shellRoot._acc
                                        : (wsSBMouse.containsMouse ? shellRoot.alphaColor(shellRoot._acc, 0.25) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    id: wsSBText
                                    anchors.centerIn: parent
                                    text: getWorkspaceIcon(index, parent.isActive, parent.isOccupied)
                                    color: {
                                        if (parent.isActive)           return contrastFg(shellRoot._acc, shellRoot._bg);
                                        if (wsSBMouse.containsMouse)   return Qt.lighter(shellRoot._acc, 1.3);
                                        if (parent.isOccupied)         return shellRoot._fg;
                                        return shellRoot._muted;
                                    }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    font.family: shellRoot.globalFontFamily; font.pixelSize: parent.isActive ? 11 : 9
                                }
                                MouseArea {
                                    id: wsSBMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof Hyprland.focusWorkspace === "function") Hyprland.focusWorkspace(index + 1);
                                        else { workspaceDispatcher.command = ["hyprctl","dispatch","workspace",(index+1).toString()]; workspaceDispatcher.running = true; }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
                        spacing: 10

                        // Network button
                        Item {
                            width: 34; height: 34
                            Text { anchors.centerIn: parent; text: shellRoot.networkType === "wifi" ? "\uf1eb" : (shellRoot.networkType === "wired" ? "\uf0ec" : "\uf127"); color: shellRoot.networkType !== "offline" ? shellRoot._blu : shellRoot._red; font.pixelSize: 13; font.family: shellRoot.globalFontFamily }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.volumePanelVisible = false;
                                    shellRoot.settingsVisible = false;
                                    shellRoot.powerMenuVisible = false;
                                    shellRoot.themeSelectorVisible = false;
                                    shellRoot.networkPanelVisible = !shellRoot.networkPanelVisible;
                                }
                            }
                        }

                        // Volume button
                        Item {
                            width: 34; height: 34
                            Text { anchors.centerIn: parent; text: shellRoot.volMuted ? "\uf026" : "\uf028"; color: shellRoot._grn; font.pixelSize: 13; font.family: shellRoot.globalFontFamily }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        volumeMuteProc.running = true;
                                    } else {
                                        shellRoot.networkPanelVisible = false;
                                        shellRoot.settingsVisible = false;
                                        shellRoot.powerMenuVisible = false;
                                        shellRoot.themeSelectorVisible = false;
                                        shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible;
                                    }
                                }
                                onWheel: (wheel) => { if (wheel.angleDelta.y > 0) volumeUpProc.running = true; else volumeDownProc.running = true; }
                            }
                        }

                        Item {
                            width: 34; height: 34
                            Text { anchors.centerIn: parent; text: "\uf013"; color: shellRoot._cyn; font.pixelSize: 13; font.family: shellRoot.globalFontFamily }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.settingsVisible = !shellRoot.settingsVisible }
                        }
                        Item {
                            width: 34; height: 34
                            Text { anchors.centerIn: parent; text: "\uf011"; color: shellRoot._red; font.pixelSize: 13; font.family: shellRoot.globalFontFamily }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
                        }
                    }
                }

                PowerMenuWindow { modelData: sideBar.screen; colors: shellRoot.colors; visible: shellRoot.powerMenuVisible; onCloseRequested: shellRoot.powerMenuVisible = false }
                SettingsPanel { modelData: sideBar.screen; colors: shellRoot.colors; rootBar: shellRoot; visible: shellRoot.settingsVisible }
                ThemeSelectorWindow {
                    modelData: sideBar.screen; colors: shellRoot.colors
                    isVisible: ThemeManager.barIsSidebar && shellRoot.themeSelectorVisible
                    onIsVisibleChanged: shellRoot.themeSelectorVisible = isVisible
                }
                VolumePanel {
                    modelData: sideBar.screen
                    rootBar: shellRoot
                    visible: ThemeManager.barIsSidebar && shellRoot.volumePanelVisible
                }
                NetworkPanel {
                    modelData: sideBar.screen
                    rootBar: shellRoot
                    visible: ThemeManager.barIsSidebar && shellRoot.networkPanelVisible
                }
            }
        }
    }

    // =========================================================================
    // SYSTEM TIMERS
    // =========================================================================
    Timer { interval: 2000;  running: true; repeat: true; onTriggered: cpuProc.running = true }
    Timer { interval: 3000;  running: true; repeat: true; onTriggered: memProc.running = true }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: fsProc.running = true }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: { dateProc.running = true; getUpdatesProc.running = true; } }
    Timer { interval: 1000;  running: true; repeat: true; onTriggered: { volumeGetProc.running = true; brightnessGetProc.running = true; } }
    Timer { interval: 2000;  running: true; repeat: true; onTriggered: { songProc.running = true; artistProc.running = true; playerStatusProc.running = true } }
    Timer { interval: 2000;  running: true; repeat: true; onTriggered: playerStatusProc.running = true }

    // =========================================================================
    // SYSTEM PROCESSES
    // =========================================================================
    Process {
        id: cpuProc; command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.cpuValue = this.text.trim() + "%" }
    }
    Process {
        id: memProc; command: ["bash", "-c", "free -m | awk '/Mem:/ {printf \"%.2f GiB\", $3/1024}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.memValue = this.text.trim() }
    }
    Process {
        id: fsProc; command: ["bash", "-c", "df -h / | awk 'NR==2 {print $3}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.fsValue = this.text.trim() }
    }
    Process {
        id: dateProc; command: ["bash", "-c", "date +\"%I:%M %p\""]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.dateValue = this.text.trim() }
    }
    Process {
        id: getUpdatesProc; command: ["bash", "-c", "cat $HOME/.cache/Updates.txt 2>/dev/null || echo '0'"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.updatesValue = this.text.trim() }
    }
    Process {
        id: brightnessGetProc; command: ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (shellRoot.isAdjustingBrightness) return;
                var val = parseInt(this.text.trim());
                if (!isNaN(val) && val >= 0) shellRoot.brightnessValue = val / 100.0;
            }
        }
    }
    Process {
        id: volumeGetProc; command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (shellRoot.isAdjustingVolume) return;
                var text = this.text.trim();
                var match = text.match(/Volume:\s+(\d+(\.\d+)?)/);
                if (match && match[1]) {
                    var newVol = parseFloat(match[1]);
                    if (Math.abs(shellRoot.volValue - newVol) > 0.005) {
                        shellRoot.volValue = newVol;
                    }
                }
                shellRoot.volMuted = text.indexOf("[MUTED]") !== -1;
            }
        }
    }
    Process {
        id: songProc; command: ["bash", "-c", "playerctl metadata title 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.songValue = this.text.trim() }
    }
    Process {
        id: artistProc; command: ["bash", "-c", "playerctl metadata artist 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.artistValue = this.text.trim() }
    }
    Process {
        id: activeWinProc
        command: ["bash", "-c", "hyprctl activewindow -j 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = this.text.trim();
                    if (raw !== "") {
                        var data = JSON.parse(raw);
                        if (data && data.title) {
                            shellRoot.activeWinTitle = data.title;
                            shellRoot.activeWinClass = data.class ? data.class.toUpperCase() : "";
                        } else {
                            shellRoot.activeWinTitle = "";
                            shellRoot.activeWinClass = "";
                        }
                    } else {
                        shellRoot.activeWinTitle = "";
                        shellRoot.activeWinClass = "";
                    }
                } catch (e) {
                    shellRoot.activeWinTitle = "";
                    shellRoot.activeWinClass = "";
                }
            }
        }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: activeWinProc.running = true
    }
    Process { id: brightnessSetProc }
    Process { id: volumeSetProc }
    Process {
        id: distNameProc
        command: ["bash", "-c", "grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: shellRoot.distroName = this.text.trim()
        }
    }
    Process {
        id: userInfoProc
        command: ["bash", "-c", "echo \"$(whoami)@$(hostname)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("@");
                if (parts.length >= 2) {
                    shellRoot.userName = parts[0];
                    shellRoot.hostName = parts[1];
                }
            }
        }
    }
    Process {
        id: themeSyncProc
        command: [
            "/home/tarzo/.config/quickshell/scripts/sync-theme-externals.sh",
            shellRoot._bg,
            shellRoot._sur,
            shellRoot._fg,
            shellRoot._acc,
            shellRoot._red,
            shellRoot._grn,
            shellRoot._yel,
            shellRoot._blu,
            shellRoot._cyn,
            shellRoot._mag,
            shellRoot._muted,
            ThemeManager.themeName
        ]
        running: false
    }

    Process { id: volumeUpProc;       command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"] }
    Process { id: volumeDownProc;     command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"] }
    Process { id: volumeMuteProc;     command: ["wpctl", "set-mute",   "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: brightnessUpProc;   command: ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", "up"] }
    Process { id: brightnessDownProc; command: ["python3", "/home/tarzo/.config/quickshell/scripts/brightness-ctrl.py", "down"] }
    Process { id: launcherProc;       command: ["vicinae", "open"] }
    Process { id: riceSelectorProc;   command: ["RiceSelector"] }
    Process { id: colorpickerProc;    command: ["hyprpicker", "-a"] }
    Process { id: workspaceDispatcher }
    Process { id: prevProc;           command: ["playerctl", "previous"] }
    Process { id: playProc;           command: ["playerctl", "play-pause"] }
    Process {
        id: playerStatusProc
        command: ["playerctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: shellRoot.isPlaying = (this.text.trim() === "Playing")
        }
    }
    Process {
        id: activeWsProc
        command: ["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null | grep '\"id\":' | head -1 | awk '{print $2}' | tr -d ','"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim());
                if (!isNaN(v) && v > 0) shellRoot.activeWsId = v;
            }
        }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: activeWsProc.running = true
    }
    Process { id: nextProc;           command: ["playerctl", "next"] }
    Process { id: bluetoothProc;      command: ["blueman-manager"] }
    Process { id: pavucontrolProc;    command: ["pavucontrol"] }
    Process { id: networkProc;        command: ["kitty", "--class", "floating_term", "-e", "nmtui"] }
    Process { id: checkUpdatesProc;   command: ["kitty", "-e", "sudo", "pacman", "-Syu"] }
    Process { id: musicProc;          command: ["kitty", "-e", "ncmpcpp"] }
    Process {
        id: volumeDaemonProc
        command: ["python3", "/home/tarzo/.config/quickshell/scripts/volume-daemon.py"]
        running: true
    }

}