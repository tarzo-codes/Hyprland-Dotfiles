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
        function toggleWallpaperSelector() {
            var next = !shellRoot.wallpaperSelectorVisible;
            shellRoot.dismissPanels();
            shellRoot.wallpaperSelectorVisible = next;
        }
        function nextTheme() {
            ThemeManager.nextTheme();
        }
        function prevTheme() {
            ThemeManager.prevTheme();
        }
        function toggleLightMode() {
            ThemeManager.isLightMode = !ThemeManager.isLightMode;
        }
        function promptLightMode() {
            shellRoot.lightModePromptVisible = true;
        }
    }

    // IPC — Cheat sheet toggle
    IpcHandler {
        target: "CheatSheetController"
        function toggle() {
            shellRoot.cheatSheetVisible = !shellRoot.cheatSheetVisible;
        }
    }

    // IPC — Wallpaper selector (called by startup.sh after theme reload)
    IpcHandler {
        target: "WallpaperController"
        function openSelector() {
            shellRoot.dismissPanels();
            shellRoot.wallpaperSelectorVisible = true;
        }
    }

    // IPC — Rice Control Center
    IpcHandler {
        target: "RiceEditorController"
        function toggle() {
            var next = !shellRoot.riceEditorVisible;
            shellRoot.dismissPanels();
            shellRoot.riceEditorVisible = next;
        }
    }

    // IPC — Task Switcher
    IpcHandler {
        target: "TaskSwitcherController"
        function toggle() {
            var next = !shellRoot.taskSwitcherVisible;
            shellRoot.dismissPanels();
            shellRoot.taskSwitcherVisible = next;
        }
        function next() {
            if (!shellRoot.taskSwitcherVisible) {
                shellRoot.dismissPanels();
                shellRoot.taskSwitcherVisible = true;
            } else {
                if (shellRoot.topTaskSwitcher) shellRoot.topTaskSwitcher.selectNext();
                if (shellRoot.botTaskSwitcher) shellRoot.botTaskSwitcher.selectNext();
            }
        }
        function activateAndClose() {
            if (shellRoot.taskSwitcherVisible) {
                if (shellRoot.topTaskSwitcher) shellRoot.topTaskSwitcher.activateSelected();
                if (shellRoot.botTaskSwitcher) shellRoot.botTaskSwitcher.activateSelected();
                shellRoot.taskSwitcherVisible = false;
            }
        }
    }

    // IPC — Clipboard Manager
    IpcHandler {
        target: "ClipboardController"
        function toggle() {
            var next = !shellRoot.clipboardVisible;
            shellRoot.dismissPanels();
            shellRoot.clipboardVisible = next;
        }
    }

    // IPC — Desktop Context Menu
    IpcHandler {
        target: "DesktopMenuController"
        function toggle() {
            var next = !shellRoot.desktopContextMenuVisible;
            shellRoot.dismissPanels();
            shellRoot.desktopContextMenuVisible = next;
        }
    }

    // Sync isLightMode state from cache file on startup (especially for Auto mode)
    Process {
        id: syncLightModeProc
        command: ["bash", "-c", "cat ~/.cache/quickshell/is_light_mode 2>/dev/null || echo false"]
        stdout: SplitParser {
            onRead: function(data) {
                var str = data.trim();
                if (str === "true" || str === "false") {
                    ThemeManager.isLightMode = (str === "true");
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Universal colors loader
    property var colors: themeColorsLoader ? themeColorsLoader.item : null
    Loader {
        id: themeColorsLoader
        source: ThemeManager.colorsPath
    }
    Timer {
        id: reloadColorsTimer
        interval: 40
        repeat: false
        onTriggered: {
            themeColorsLoader.active = true;
        }
    }
    FileView {
        path: "/home/tarzo/.config/quickshell/wallust-colors.qml"
        watchChanges: true
        onFileChanged: {
            if (ThemeManager.colorMode === "wallust") {
                themeColorsLoader.active = false;
                reloadColorsTimer.restart();
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
    property bool riceEditorVisible:     false
    property bool taskSwitcherVisible:   false
    property bool clipboardVisible:      false
    property bool desktopContextMenuVisible: false
    property bool themeSelectorVisible:  false
    property bool volumePanelVisible:    false
    property bool brightnessPanelVisible: false
    property bool networkPanelVisible:   false
    property bool bluetoothPanelVisible: false
    property bool backgroundTasksPanelVisible: false
    property bool wallpaperSelectorVisible: false
    property bool mediaPlayerVisible:    false
    property bool cheatSheetVisible:     false
    property bool lightModePromptVisible: false
    property string lightModePromptWp:   ""
    property string userName:            "user"
    property string hostName:            "host"
    property int  barHeight:       Math.max(36, CentralConfig.barHeight)
    property real barWidthPercent: CentralConfig.barWidthPercent
    // Write-back so CentralConfig is updated persistently
    onBarHeightChanged:       CentralConfig.barHeight       = barHeight
    onBarWidthPercentChanged: CentralConfig.barWidthPercent = barWidthPercent
    property real brightnessValue:  CentralConfig.brightnessValue
    property real volValue:         CentralConfig.volValue
    onVolValueChanged:              CentralConfig.volValue = volValue
    onBrightnessValueChanged:       CentralConfig.brightnessValue = brightnessValue
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
    property string selectedPlayer: ""
    property var activePlayersList: []
    property string activeWinTitle: ""
    property string activeWinClass: ""
    property int    activeWsId:     1
    property string networkType:    "wired"

    function refreshMediaPlayer() {
        listPlayersProc.running = true;
        songProc.running = true;
        artistProc.running = true;
        playerStatusProc.running = true;
    }

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

    // Re-open wallpaper selector on startup if wallpaper was just changed
    Process {
        id: checkWpStateProc
        command: ["bash", "-c", "if [ -f \"$HOME/.cache/quickshell/wp_selector_open\" ]; then rm -f \"$HOME/.cache/quickshell/wp_selector_open\"; echo \"REOPEN\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "REOPEN") {
                    shellRoot.wallpaperSelectorVisible = true;
                }
            }
        }
        Component.onCompleted: running = true
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
        function onFocusedWindowChanged() {
            shellRoot.volumePanelVisible = false;
            shellRoot.networkPanelVisible = false;
            shellRoot.bluetoothPanelVisible = false;
            shellRoot.backgroundTasksPanelVisible = false;
            shellRoot.wallpaperSelectorVisible = false;
            shellRoot.compSettings = false;
            shellRoot.compThemeSelector = false;
            shellRoot.mediaPlayerVisible = false;
            shellRoot.cheatSheetVisible = false;
        }
    }

    function dismissPanels() {
        shellRoot.volumePanelVisible = false;
        shellRoot.networkPanelVisible = false;
        shellRoot.bluetoothPanelVisible = false;
        shellRoot.backgroundTasksPanelVisible = false;
        shellRoot.wallpaperSelectorVisible = false;
        shellRoot.settingsVisible = false;
        shellRoot.powerMenuVisible = false;
        shellRoot.themeSelectorVisible = false;
        shellRoot.mediaPlayerVisible = false;
    }

    // ─── Color helpers ────────────────────────────────────────────────────────
    // In light mode: trust wallust's -p light palette as the primary source.
    // Only fall back to hardcoded safe colors when wallust produces something
    // that would be genuinely unreadable (e.g. dark bg in light mode).
    function getBrightestLightBg(fallback) {
        if (!shellRoot.colors) return fallback;
        var keys = ["background", "color0", "color1", "color2", "color3", "color4", "color5", "color6", "color7", "color8", "color9", "color10", "color11", "color12", "color13", "color14", "color15"];
        var best = fallback;
        var maxL = 0;
        for (var i = 0; i < keys.length; i++) {
            var col = shellRoot.colors[keys[i]];
            if (col && col !== "transparent") {
                var l = luma(col);
                if (l > maxL) {
                    maxL = l;
                    best = col;
                }
            }
        }
        if (maxL < 0.85) {
            best = "#f4f6f8";
        }
        return best;
    }

    function c(name, fallback) {
        var raw = shellRoot.colors ? (shellRoot.colors[name] || fallback) : fallback;
        if (!ThemeManager.isLightMode) return raw;

        // Background/surface: pick the brightest light color
        if (name === "background") return getBrightestLightBg("#f1f5f9");
        if (name === "surface")    return "#ffffff";

        // Foreground/text: must be dark for contrast
        if (name === "foreground") return ensureDark(raw, "#0f172a");
        if (name === "textMuted")  return ensureDark(raw, "#475569");

        // Accent/icon colors: darken only if too bright to read on light bg
        return ensureDarkEnough(raw, 0.35);
    }

    // Returns perceptual luminance 0–1 for a hex string (WCAG formula)
    function luma(hex) {
        if (!hex || hex === "transparent") return 0;
        var s = hex.toString().replace("#", "");
        if (s.length === 3) s = s[0]+s[0]+s[1]+s[1]+s[2]+s[2];
        if (s.length !== 6) return 0;
        var r = parseInt(s.substring(0,2),16)/255;
        var g = parseInt(s.substring(2,4),16)/255;
        var b = parseInt(s.substring(4,6),16)/255;
        r = r <= 0.04045 ? r/12.92 : Math.pow((r+0.055)/1.055, 2.4);
        g = g <= 0.04045 ? g/12.92 : Math.pow((g+0.055)/1.055, 2.4);
        b = b <= 0.04045 ? b/12.92 : Math.pow((b+0.055)/1.055, 2.4);
        return 0.2126*r + 0.7152*g + 0.0722*b;
    }

    function isLightColor(hex) { return luma(hex) > 0.45; }

    // Use wallust color if it is light (luma > 0.45), else hardcoded fallback
    function ensureLight(hex, fallback) {
        if (!hex || hex === "transparent") return fallback;
        return luma(hex) > 0.45 ? hex : fallback;
    }

    // Use wallust color if it is dark (luma < 0.45), else hardcoded fallback
    function ensureDark(hex, fallback) {
        if (!hex || hex === "transparent") return fallback;
        return luma(hex) < 0.45 ? hex : fallback;
    }

    // Darken color iteratively until luminance drops below maxLuma
    function ensureDarkEnough(hex, maxLuma) {
        if (!hex || hex === "transparent") return "#1d4ed8";
        var col = hex.toString();
        var factor = 1.0;
        while (luma(col) > maxLuma && factor < 5.0) {
            factor += 0.25;
            col = Qt.darker(col, factor).toString();
        }
        return col;
    }

    function ensureDarker(hex) { return ensureDarkEnough(hex, 0.35); }

    property string _bg:  c("background", "#0d0f18")
    property string _sur: c("surface",    "#1e1e2e")
    property string _fg:  c("foreground", "#c0caf5")
    property string _acc: ThemeManager.customAccentColor !== "" ? ThemeManager.customAccentColor : c("accent",     "#7aa2f7")
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
    Binding on _acc { value: ThemeManager.customAccentColor !== "" ? ThemeManager.customAccentColor : c("accent",     "#7aa2f7") }
    Binding on _red { value: c("red",        "#f7768e") }
    Binding on _grn { value: c("green",      "#9ece6a") }
    Binding on _yel { value: c("yellow",     "#e0af68") }
    Binding on _blu { value: c("blue",       "#7aa2f7") }
    Binding on _cyn { value: c("cyan",       "#7dcfff") }
    Binding on _mag { value: c("magenta",    "#bb9af7") }
    Binding on _muted { value: c("textMuted", "#6D8895") }

    function getAppColor(appName, defaultColor) {
        if (ThemeManager.appColorMode === "real") {
            if (appName === "kitty") return "#4A90E2";
            if (appName === "dolphin") return "#1C9EFF";
            if (appName === "zen-browser") return "#33D17A";
            if (appName === "vesktop" || appName === "discord") return "#5865F2";
            if (appName === "steam") return "#C7D5E0";
            if (appName === "lutris") return "#F57C00";
            if (appName === "code") return "#007ACC";
        }
        return defaultColor;
    }

    function ensureBright(hex) {
        if (!hex || hex === "" || hex === "transparent") return "#ffffff";
        var c = Qt.color(hex);
        if (c.hslLightness < 0.60) {
            return Qt.hsla(c.hslHue, Math.max(0.70, c.hslSaturation), 0.75, 1.0).toString();
        }
        return hex;
    }

    readonly property string _brightRed: ensureBright(c("brightRed", _red))
    readonly property string _brightGrn: ensureBright(c("brightGreen", _grn))
    readonly property string _brightYel: ensureBright(c("brightYellow", _yel))
    readonly property string _brightBlu: ensureBright(c("brightBlue", _blu))
    readonly property string _brightMag: ensureBright(c("brightMagenta", _mag))
    readonly property string _brightCyn: ensureBright(c("brightCyan", _cyn))
    readonly property string _brightAcc: ensureBright(c("brightAccent", _acc))

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

        // ── Silvia theme (Concentric targets and hollow circles) ──────
        if (theme === "silvia") {
            if (isActive)   return "⦿";
            if (isOccupied) return "⦿";
            return "○";
        }

        // ── Cozy / nature: leaf/circle glyphs ────────────────────────
        if (theme === "brenda" || theme === "silvia") {
            if (theme === "silvia") {
                if (isActive)   return "⦿";
                if (isOccupied) return "⦿";
                return "○";
            }
            if (isActive)   return "󰮯 " + n;   // pac-man open + number
            if (isOccupied) return "󰊠";   // filled circle
            return "󰑊";                   // empty circle
        }

        // ── Pacman & Ghost: marisol ─────────────────────────────────────────
        if (theme === "marisol") {
            if (isActive)   return "󰮯"; // Pacman
            if (isOccupied) return "󰊠"; // Ghost
            return "●";                 // Pink dot
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

        // ── Emilia theme (Pacman style without numbers) ────────────────
        if (theme === "emilia") {
            if (isActive)   return "󰮯";
            if (isOccupied) return "󰊠";
            return "󰑊";
        }

        // ── Silvia theme (Concentric targets and hollow circles) ──────
        if (theme === "silvia") {
            if (isActive)   return "⦿";
            if (isOccupied) return "⦿";
            return "○";
        }

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
        if (type === "workspaces")   return compWorkspaces;
        if (type === "title")        return compTitle;
        if (type === "cpu")          return compCpu;
        if (type === "memory" || type === "ram") return compMemory;
        if (type === "filesystem" || type === "disk") return compFilesystem;
        if (type === "volume")       return compVolume;
        if (type === "brightness")   return compBrightness;
        if (type === "battery")      return compBattery;
        if (type === "network")      return compNetwork;
        if (type === "updates")      return compUpdates;
        if (type === "date" || type === "clock") return compDate;
        if (type === "power")        return compPower;
        if (type === "settings" || type === "theme") return compSettings;
        if (type === "sep")          return compSep;
        if (type === "bluetooth")    return compBluetooth;
        if (type === "background_tasks" || type === "tasks" || type === "bg_tasks") return compBackgroundTaskHandler;
        if (type === "wallpaper" || type === "wallpaper_selector") return compWallpaperSelector;
        if (type === "mode_switcher" || type === "theme_mode") return compModeSwitcher;
        if (type === "colorpicker")  return compColorpicker;
        if (type === "mplayer")      return compMplayer;
        if (type === "weather")      return compWeather;
        if (type === "tray")         return compTray;
        if (type === "apps" || type === "pinnedApps") return compApps;
        if (type === "song")         return compSong;
        if (type === "arch_text")    return compArchText;
        if (type === "andrea_stats") return compAndreaStats;
        if (type === "cynthia_prompt") return compCynthiaPrompt;
        if (type === "cynthia_status") return compCynthiaStatus;
        if (type === "compact_player" || type === "media") return compCompactPlayer;
        return null;
    }

    function getModuleArray(csvStr) {
        if (!csvStr || csvStr === "") return [];
        var arr = csvStr.split(",");
        var result = [];
        var seen = {};
        for (var i = 0; i < arr.length; i++) {
            var m = arr[i].trim();
            if (m !== "" && !seen[m]) {
                seen[m] = true;
                result.push({ type: "capsule", modules: [m] });
            }
        }
        return result;
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
                right:  [{type: "capsule", modules: ["compact_player", "andrea_stats", "date"]}]
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
                right:  [{type: "capsule", modules: ["compact_player", "network", "volume", "brightness", "date"]}]
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
                right:  [{type: "capsule", modules: ["compact_player", "filesystem", "cpu", "memory", "battery", "network", "volume", "brightness", "date", "colorpicker", "settings", "power"]}]
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
                left:   [
                    {type: "launcher"},
                    {type: "capsule", modules: ["cpu"]},
                    {type: "capsule", modules: ["memory"]},
                    {type: "capsule", modules: ["filesystem"]},
                    {type: "capsule", modules: ["mplayer"]}
                ],
                center: [
                    {type: "capsule", modules: ["workspaces"]}
                ],
                right:  [
                    {type: "capsule", modules: ["song"]},
                    {type: "network"},
                    {type: "capsule", modules: ["volume"]},
                    {type: "capsule", modules: ["updates"]},
                    {type: "capsule", modules: ["date"]},
                    {type: "capsule", modules: ["settings", "power"]}
                ]
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
                right:  [{type: "capsule", modules: ["compact_player", "network", "volume", "brightness", "date"]}]
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
                left:   [{type: "capsule", modules: ["launcher", "workspaces", "mplayer", "title"]}],
                center: [{type: "capsule", modules: ["date", "weather"]}],
                right:  [{type: "capsule", modules: ["song", "battery", "cpu", "memory", "filesystem", "network", "volume", "updates", "bluetooth", "brightness", "tray", "colorpicker", "settings", "power"]}]
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
                left:   [
                    {type: "launcher"},
                    {type: "workspaces"},
                    {type: "title"}
                ],
                center: [],
                right:  [
                    {type: "compact_player"},
                    {type: "bluetooth"},
                    {type: "brightness"},
                    {type: "settings"},
                    {type: "power"},
                    {type: "sep"},
                    {type: "weather"},
                    {type: "updates"},
                    {type: "filesystem"},
                    {type: "cpu"},
                    {type: "memory"},
                    {type: "volume"},
                    {type: "network"},
                    {type: "date"}
                ]
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
                right:  [{type: "capsule", modules: ["compact_player", "memory", "cpu", "filesystem", "battery", "network", "volume", "brightness", "date", "colorpicker", "settings", "power"]}]
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
                Text { text: ThemeManager.themeName === "emilia" ? " 󰇙" : ":"; color: shellRoot._muted; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30; visible: (ThemeManager.barIsTopFloat || ThemeManager.themeName === "silvia") && ThemeManager.themeName !== "andrea" }
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

            property bool isCircleTheme: ["brenda", "pamela", "cristina", "isabel"].indexOf(ThemeManager.themeName) !== -1

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
                                if (ThemeManager.themeName === "emilia") {
                                    if (parent.isActive)           return shellRoot._yel;
                                    if (wsMouse.containsMouse)     return Qt.lighter(shellRoot._acc, 1.3);
                                    if (parent.isOccupied)         return shellRoot._blu;
                                    return shellRoot.colors._purple || "#583794";
                                }
                                if (ThemeManager.themeName === "silvia") {
                                    if (parent.isActive || parent.isOccupied) return shellRoot._acc;
                                    if (wsMouse.containsMouse)                return Qt.lighter(shellRoot._acc, 1.25);
                                    return shellRoot._muted;
                                }
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
        Row {
            spacing: 6
            height: 30
            visible: winText.text !== ""
            Text {
                text: "󰆍"
                color: shellRoot._mag
                font.family: shellRoot.globalFontFamily
                font.pixelSize: shellRoot.iconFontSize
                verticalAlignment: Text.AlignVCenter
                height: 30
                visible: ThemeManager.themeName === "marisol"
            }
            Text {
                id: winText
                text: {
                    var prefix = ThemeManager.themeName === "silvia" ? ":  " : "";
                    var body = "";
                    if (ThemeManager.themeName === "silvia") {
                        body = shellRoot.activeWinClass !== "" ? (shellRoot.activeWinClass + ":" + shellRoot.activeWinTitle) : shellRoot.activeWinTitle;
                    } else if (ThemeManager.themeName === "marisol") {
                        body = shellRoot.activeWinClass !== "" ? shellRoot.activeWinClass : shellRoot.activeWinTitle;
                    } else {
                        body = shellRoot.activeWinClass !== "" ? (shellRoot.activeWinClass + " — " + shellRoot.activeWinTitle) : shellRoot.activeWinTitle;
                    }
                    return prefix + body;
                }
                color: ThemeManager.themeName === "silvia" ? shellRoot._acc : (ThemeManager.themeName === "marisol" ? shellRoot._cyn : shellRoot._fg)
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
                font.bold: true
                elide: Text.ElideRight
                width: text !== "" ? Math.min(ThemeManager.themeName === "silvia" ? 180 : 260, implicitWidth) : 0
                verticalAlignment: Text.AlignVCenter; height: 30
            }
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
            visible: !!(UPower.battery && UPower.battery.isPresent)
            Text { text: (UPower.battery && UPower.battery.charging) ? "\uf0e7" : "\uf240"; color: shellRoot._brightGrn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
            Text { text: UPower.battery ? Math.round(UPower.battery.percentage || 0) + "%" : ""; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: 30 }
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
            text: ThemeManager.themeName === "silvia" ? "" : "\uf011"
            color: powerMouse.containsMouse ? Qt.darker(shellRoot._red, 1.25) : shellRoot._red
            Behavior on color { ColorAnimation { duration: 120 } }
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
            MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
        }
    }

    Component {
        id: compSep
        Text {
            text: " :"
            color: shellRoot._muted
            font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
            verticalAlignment: Text.AlignVCenter; height: 30
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
            MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var next = !shellRoot.settingsVisible; shellRoot.dismissPanels(); shellRoot.settingsVisible = next; } }
        }
    }

    Component {
        id: compBluetooth
        Bluetooth {
            colors: shellRoot.colors
            rootBar: shellRoot
        }
    }

    Component {
        id: compBackgroundTaskHandler
        BackgroundTaskHandler {
            colors: shellRoot.colors
            rootBar: shellRoot
        }
    }

    Component {
        id: compWallpaperSelector
        Item {
            width: wpIconText.implicitWidth + 4
            height: 30
            Text {
                id: wpIconText
                anchors.centerIn: parent
                text: "\uf03e"
                color: wpBtnMouse.containsMouse ? Qt.darker(shellRoot._brightYel, 1.2) : shellRoot._brightYel
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: shellRoot.globalFontFamily
                font.pixelSize: shellRoot.iconFontSize
                verticalAlignment: Text.AlignVCenter
                scale: wpBtnMouse.pressed ? 0.82 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
            }
            MouseArea {
                id: wpBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var next = !shellRoot.wallpaperSelectorVisible;
                    shellRoot.dismissPanels();
                    shellRoot.wallpaperSelectorVisible = next;
                }
            }
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
            visible: shellRoot.songValue !== ""
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

    Process {
        id: reapplyThemeProc
        command: ["bash", "-c", "$HOME/.config/scripts/wallpaper_picker.sh --reapply"]
    }

    Component {
        id: compModeSwitcher
        Row {
            spacing: 6
            height: 30
            Rectangle {
                height: 24; width: 68; radius: 6
                anchors.verticalCenter: parent.verticalCenter
                color: modeMouse.containsMouse ? shellRoot._sur : "transparent"
                border.color: shellRoot._cyn; border.width: 1

                Row {
                    anchors.centerIn: parent; spacing: 4
                    Text {
                        text: ThemeManager.modeChoice === "dark" ? "󰔎" : (ThemeManager.modeChoice === "light" ? "󰌵" : "󰄛")
                        color: ThemeManager.modeChoice === "light" ? shellRoot._yel : shellRoot._cyn
                        font.family: shellRoot.iconFontFamily; font.pixelSize: shellRoot.iconFontSize
                    }
                    Text {
                        text: ThemeManager.modeChoice.toUpperCase()
                        color: shellRoot._fg
                        font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize - 1; font.bold: true
                    }
                }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var nextMode = "dark";
                        if (ThemeManager.modeChoice === "dark") nextMode = "light";
                        else if (ThemeManager.modeChoice === "light") nextMode = "auto";
                        else nextMode = "dark";

                        ThemeManager.modeChoice = nextMode;
                        reapplyThemeProc.running = false;
                        reapplyThemeProc.running = true;
                    }
                }
            }
        }
    }

    Timer {
        id: eqTimer
        interval: 100
        running: shellRoot.songValue !== "" && shellRoot.songValue !== "No media playing" && shellRoot.songValue !== "No player found"
        repeat: true
        property var eqHeights: [10, 16, 8, 18]
        onTriggered: {
            eqHeights = [
                Math.floor(Math.random() * 14) + 4,
                Math.floor(Math.random() * 18) + 4,
                Math.floor(Math.random() * 12) + 4,
                Math.floor(Math.random() * 20) + 4
            ];
        }
    }

    Component {
        id: compSong
        Row {
            spacing: 6
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            visible: shellRoot.songValue !== "" || (CentralConfig.editMode || BarModules.editMode)

            // Dynamic Equalizer Animated Bars
            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        width: 3
                        height: eqTimer.running ? eqTimer.eqHeights[index] : 4
                        radius: 1.5
                        color: shellRoot._cyn
                        anchors.bottom: parent.bottom
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Album Cover Art (if available)
            Image {
                visible: shellRoot.artUrl !== ""
                source: shellRoot.artUrl
                width: 20; height: 20
                fillMode: Image.PreserveAspectCrop
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: shellRoot.songValue !== "" ? shellRoot.songValue : "[ EDIT: Song Title ]"
                color: shellRoot._acc
                font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize
                verticalAlignment: Text.AlignVCenter; height: 30
                elide: Text.ElideRight; width: Math.min(140, implicitWidth); clip: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton && shellRoot.activePlayersList.length > 1) {
                        var idx = shellRoot.activePlayersList.indexOf(shellRoot.selectedPlayer);
                        var nextIdx = (idx + 1) % shellRoot.activePlayersList.length;
                        shellRoot.selectedPlayer = shellRoot.activePlayersList[nextIdx];
                        shellRoot.refreshMediaPlayer();
                    } else {
                        shellRoot.volumePanelVisible = false;
                        shellRoot.networkPanelVisible = false;
                        shellRoot.bluetoothPanelVisible = false;
                        shellRoot.settingsVisible = false;
                        shellRoot.powerMenuVisible = false;
                        shellRoot.themeSelectorVisible = false;
                        shellRoot.mediaPlayerVisible = !shellRoot.mediaPlayerVisible;
                    }
                }
            }
        }
    }

    Component {
        id: compArchText
        Text {
            text: ThemeManager.themeName === "silvia" ? ":  " + shellRoot.distroName : shellRoot.distroName
            color: ThemeManager.themeName === "silvia" ? shellRoot._acc : shellRoot._fg
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
                            shellRoot.bluetoothPanelVisible = false;
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
            visible: shellRoot.songValue !== ""
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
                    id: musicIcon
                    text: ThemeManager.themeName === "silvia" ? "\uf001" : "\uf028"
                    color: ThemeManager.themeName === "silvia" ? shellRoot._brightGrn : shellRoot._brightCyn
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.iconFontSize
                    verticalAlignment: Text.AlignVCenter
                    height: 30

                    transform: Translate { id: trans; y: 0 }
                    SequentialAnimation {
                        running: shellRoot.isPlaying && ThemeManager.themeName === "silvia"
                        loops: Animation.Infinite
                        NumberAnimation { target: trans; property: "y"; from: 0; to: -3; duration: 400; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: trans; property: "y"; from: -3; to: 0; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }
                Text {
                    text: shellRoot.songValue !== "" ? shellRoot.songValue : "Media"
                    visible: ThemeManager.themeName !== "silvia"
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
                    shellRoot.bluetoothPanelVisible = false;
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
                            shellRoot.bluetoothPanelVisible = false;
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
            width: visible ? (childRow.implicitWidth + (modelData.type === "capsule" ? 24 : 0)) : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: {
                if (BarModules.editMode || CentralConfig.editMode) return true;
                var mods = modelData.type === "capsule" ? modelData.modules : [modelData.type];
                var hasActiveModule = false;
                for (var i = 0; i < mods.length; i++) {
                    var m = mods[i];
                    if (m === "song" || m === "media" || m === "mplayer" || m === "compact_player") {
                        if (shellRoot.songValue !== "" && shellRoot.songValue !== "No media playing" && shellRoot.songValue !== "No player found") {
                            hasActiveModule = true;
                        }
                    } else if (m === "title") {
                        if (shellRoot.activeTitle !== "" && shellRoot.activeTitle !== "Desktop" && shellRoot.activeTitle !== "Hyprland") {
                            hasActiveModule = true;
                        }
                    } else if (m === "updates") {
                        if (shellRoot.updatesValue !== "" && shellRoot.updatesValue !== "0 updates" && shellRoot.updatesValue !== "0" && shellRoot.updatesValue !== "Up to date") {
                            hasActiveModule = true;
                        }
                    } else if (m === "tray") {
                        if (shellRoot.trayCount > 0) {
                            hasActiveModule = true;
                        }
                    } else {
                        hasActiveModule = true;
                    }
                }
                return hasActiveModule;
            }

            Rectangle {
                anchors.fill: parent
                radius: ThemeManager.themeName === "emilia" ? 4 : 15
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

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                color: {
                    var t = modelData.type;
                    if (t === "weather")    return shellRoot._yel;
                    if (t === "updates")    return shellRoot._grn;
                    if (t === "filesystem") return shellRoot._red;
                    if (t === "cpu")        return shellRoot._cyn;
                    if (t === "memory")     return shellRoot.colors._pink || "#d3869b";
                    if (t === "volume")     return shellRoot._blu;
                    if (t === "network")    return shellRoot.colors._yellow || "#d79921";
                    if (t === "date")       return shellRoot.colors._indigo || "#6C77BB";
                    return "transparent";
                }
                visible: ThemeManager.themeName === "silvia" && color !== "transparent"
            }
        }
    }

    // =========================================================================
    // TOP BAR — single-top-float, single-top-full, andrea, and double top
    // =========================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: topBar
                required property var modelData
                screen: modelData
                visible: ThemeManager.barIsTop || (ThemeManager.barIsDouble && ThemeManager.topBarEnabled)
                color: "transparent"
                anchors { top: true; left: true; right: true }
                implicitWidth: screen.width
                implicitHeight: ThemeManager.barIsTopFloat ? (barHeight + 10) : barHeight

                property bool isTopHovered: topHoverArea.containsMouse || shellRoot.settingsVisible || shellRoot.riceEditorVisible || shellRoot.volumePanelVisible || shellRoot.networkPanelVisible || shellRoot.powerMenuVisible
                property bool topBarShouldHide: false

                Timer {
                    id: topHideTimer
                    interval: 600
                    repeat: false
                    onTriggered: topBar.topBarShouldHide = true
                }

                onIsTopHoveredChanged: {
                    if (isTopHovered) {
                        topHideTimer.stop();
                        topBarShouldHide = false;
                    } else {
                        topHideTimer.restart();
                    }
                }

                property real autoHideTopOffset: (ThemeManager.autoHideBar && topBarShouldHide) ? -(shellRoot.barHeight - 4) : 0
                Behavior on autoHideTopOffset { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                property real animatedMargin: (ThemeManager.barIsTopFloat && ThemeManager.themeName !== "melissa")
                    ? screen.width * (1.0 - shellRoot.barWidthPercent) / 2
                    : 0
                Behavior on animatedMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: topHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                // ── Theme Native Bar Container ─────────────────────────────────
                Rectangle {
                    id: barRect
                    visible: true
                    anchors {
                        top: parent.top
                        topMargin: (ThemeManager.barIsTopFloat ? 8 : 0) + topBar.autoHideTopOffset
                        left: parent.left; right: parent.right
                        leftMargin:  topBar.animatedMargin
                        rightMargin: topBar.animatedMargin
                    }
                    height: shellRoot.barHeight
                    color: {
                        if (ThemeManager.themeName === "emilia") return shellRoot._bg;
                        return (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa" || ThemeManager.themeName === "marisol") ? "transparent" : shellRoot._bg;
                    }
                    radius: ThemeManager.barRadius
                    border.color: BarModules.editMode ? "#8ec07c" : (ThemeManager.themeName === "emilia" ? shellRoot._sur : "transparent")
                    border.width: BarModules.editMode ? 1.5 : (ThemeManager.themeName === "emilia" ? 1 : 0)

                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: -8
                        height: 16; width: 120; radius: 8
                        color: "#8ec07c"
                        visible: BarModules.editMode
                        z: 99
                        Text {
                            anchors.centerIn: parent
                            text: "󰏫 EDIT MODE ACTIVE"
                            color: "#181628"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }

                    Item {
                        anchors.fill: parent
                        // Vertical inset so pills never touch bar edges (disabled for Melissa & Marisol)
                        anchors.topMargin: (ThemeManager.themeName === "melissa" || ThemeManager.themeName === "marisol") ? 0 : 5
                        anchors.bottomMargin: (ThemeManager.themeName === "melissa" || ThemeManager.themeName === "marisol") ? 0 : 5
                        anchors.leftMargin: (ThemeManager.themeName !== "emilia" && (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa" || ThemeManager.themeName === "marisol")) ? 0 : 12
                        anchors.rightMargin: (ThemeManager.themeName !== "emilia" && (ThemeManager.barIsTopFloat || ThemeManager.barIsAndrea || ThemeManager.themeName === "melissa" || ThemeManager.themeName === "marisol")) ? 0 : 12

                        // ══ LEFT ZONE ══
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "marisol"
                            
                            Repeater {
                                model: (BarModules.mode === "custom" || CentralConfig.mode === "custom") ? shellRoot.getModuleArray(CentralConfig.leftModules) : (themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.left : [])
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ CENTER ZONE ══
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "marisol"

                            Repeater {
                                model: (BarModules.mode === "custom" || CentralConfig.mode === "custom") ? shellRoot.getModuleArray(CentralConfig.centerModules) : (themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.center : [])
                                delegate: capsuleDelegate
                            }
                        }

                        // ══ RIGHT ZONE ══
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            height: parent.height
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "marisol"

                            Repeater {
                                model: (BarModules.mode === "custom" || CentralConfig.mode === "custom") ? shellRoot.getModuleArray(CentralConfig.rightModules) : (themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].top ? themeLayouts[ThemeManager.themeName].top.right : [])
                                delegate: capsuleDelegate
                            }
                        }

                        // ═════════════════════════════════════════════════════════════════════
                        // ── MARISOL SHARP POWERLINE BAR (EXACT MATCH TO REFERENCE IMAGE) ─────
                        // ═════════════════════════════════════════════════════════════════════
                        Item {
                            anchors.fill: parent
                            visible: ThemeManager.themeName === "marisol"

                            // ── GRADIENT SHADOW IN THE GAP (DYNAMIC WALLUST OR STATIC BLUE) ──
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.alphaColor(shellRoot._bg, 0.85) }
                                    GradientStop { position: 0.45; color: shellRoot.alphaColor(shellRoot._bg, 0.35) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            // ── THIN 1PX TOP ACCENT LINE ACROSS THE GAP ──
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: shellRoot._sur
                            }

                            // ── LEFT POWERLINE BLOCK ──
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                spacing: 0

                                // Left Slate Box (Arch Logo + Pacman Workspaces + Media Controls)
                                Rectangle {
                                    height: parent.height
                                    width: marisolLeftRow.implicitWidth + 24
                                    color: shellRoot._sur
                                    radius: 0

                                    Row {
                                        id: marisolLeftRow
                                        anchors.centerIn: parent
                                        height: parent.height
                                        spacing: 12

                                        // Arch Logo
                                        Text {
                                            text: "󰣇"
                                            color: shellRoot._fg
                                            font.family: shellRoot.globalFontFamily
                                            font.pixelSize: shellRoot.iconFontSize + 1
                                            verticalAlignment: Text.AlignVCenter
                                            height: parent.height
                                        }

                                        // Pacman Workspaces
                                        Loader {
                                            sourceComponent: compWorkspaces
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Media Controls
                                        Loader {
                                            sourceComponent: compMplayer
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // Sharp Right Slant (/)
                                SlantSeparator {
                                    colorLeft: shellRoot._sur
                                    colorRight: "transparent"
                                    isRightSlant: false
                                    slantWidth: 16
                                    height: parent.height
                                }

                                Item { width: 12; height: parent.height }

                                // Active Window Class Badge (OUTSIDE ON THE TRANSPARENT GAP)
                                Rectangle {
                                    height: parent.height - 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: marisolWinRow.implicitWidth + 16
                                    color: shellRoot.alphaColor(shellRoot._sur, 0.45)
                                    border.color: shellRoot.alphaColor(shellRoot._mag, 0.55)
                                    border.width: 1
                                    radius: 4
                                    visible: shellRoot.activeWinClass !== "" || shellRoot.activeWinTitle !== ""

                                    Row {
                                        id: marisolWinRow
                                        anchors.centerIn: parent
                                        height: parent.height
                                        spacing: 6

                                        Text {
                                            text: "󰆍"
                                            color: shellRoot._mag
                                            font.family: shellRoot.globalFontFamily
                                            font.pixelSize: shellRoot.iconFontSize - 1
                                            verticalAlignment: Text.AlignVCenter
                                            height: parent.height
                                        }
                                        Text {
                                            text: shellRoot.activeWinClass !== "" ? shellRoot.activeWinClass : shellRoot.activeWinTitle
                                            color: shellRoot._cyn
                                            font.family: shellRoot.globalFontFamily
                                            font.pixelSize: shellRoot.globalFontSize
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: Math.min(180, implicitWidth)
                                            verticalAlignment: Text.AlignVCenter
                                            height: parent.height
                                        }
                                    }
                                }
                            }

                            // ── CENTER ZONE (BLANK BAR BACKGROUND, ONLY FLOATING TEXT OVER WALLPAPER) ──
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                spacing: 8

                                Text {
                                    text: shellRoot.dateValue
                                    color: shellRoot._fg
                                    font.family: shellRoot.globalFontFamily
                                    font.pixelSize: shellRoot.globalFontSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    height: parent.height
                                }
                                Text {
                                    text: "󰖙"
                                    color: shellRoot._brightYel
                                    font.family: shellRoot.globalFontFamily
                                    font.pixelSize: shellRoot.iconFontSize
                                    verticalAlignment: Text.AlignVCenter
                                    height: parent.height
                                }
                                Text {
                                    text: shellRoot.weatherTemp
                                    color: shellRoot._fg
                                    font.family: shellRoot.globalFontFamily
                                    font.pixelSize: shellRoot.globalFontSize
                                    verticalAlignment: Text.AlignVCenter
                                    height: parent.height
                                }
                            }

                            // ── RIGHT POWERLINE BLOCK (Left Slant + System Metrics) ──
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                spacing: 0

                                // Sharp Left Slant (\)
                                SlantSeparator {
                                    colorLeft: "transparent"
                                    colorRight: shellRoot._sur
                                    isRightSlant: true
                                    slantWidth: 16
                                    height: parent.height
                                }

                                // Right Slate Box
                                Rectangle {
                                    height: parent.height
                                    width: marisolRightRow.implicitWidth + 24
                                    color: shellRoot._sur
                                    radius: 0

                                    Row {
                                        id: marisolRightRow
                                        anchors.centerIn: parent
                                        height: parent.height
                                        spacing: 12

                                        // Song / Music
                                        Item {
                                            width: 20; height: parent.height
                                            visible: shellRoot.songValue !== ""
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰓇"
                                                color: shellRoot._brightGrn
                                                font.family: shellRoot.globalFontFamily
                                                font.pixelSize: shellRoot.iconFontSize
                                            }
                                        }

                                        // CPU
                                        Row {
                                            spacing: 4; height: parent.height
                                            Text { text: "󰻠"; color: shellRoot._red; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            Text { text: shellRoot.cpuValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                        }

                                        // RAM
                                        Row {
                                            spacing: 4; height: parent.height
                                            Text { text: "󰍛"; color: shellRoot._cyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            Text { text: shellRoot.memValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                        }

                                        // Disk
                                        Row {
                                            spacing: 4; height: parent.height
                                            Text { text: "󰋊"; color: shellRoot._yel; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            Text { text: shellRoot.fsValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                        }

                                        // Wifi / Network Widget
                                        Loader {
                                            sourceComponent: compNetwork
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Bluetooth
                                        Loader {
                                            sourceComponent: compBluetooth
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Brightness
                                        Loader {
                                            sourceComponent: compBrightness
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Volume
                                        Row {
                                            spacing: 4; height: parent.height
                                            Text { text: "󰕾"; color: shellRoot._blu; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            Text { text: Math.round(shellRoot.volumeValue*100).toString(); color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible
                                            }
                                        }

                                        // Updates
                                        Row {
                                            spacing: 4; height: parent.height
                                            Text { text: "󰔁"; color: shellRoot._grn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                            Text { text: shellRoot.updatesValue; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                        }

                                        // Wallpaper Selector
                                        Loader {
                                            sourceComponent: compWallpaperSelector
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Theme Selector / Colorpicker
                                        Loader {
                                            sourceComponent: compColorpicker
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Settings
                                        Item {
                                            width: 20; height: parent.height
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf013"
                                                color: shellRoot._cyn
                                                font.family: shellRoot.globalFontFamily
                                                font.pixelSize: shellRoot.iconFontSize
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: shellRoot.settingsVisible = !shellRoot.settingsVisible
                                            }
                                        }

                                        // Power Button
                                        Item {
                                            width: 20; height: parent.height
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰐥"
                                                color: shellRoot._red
                                                font.family: shellRoot.globalFontFamily
                                                font.pixelSize: shellRoot.iconFontSize
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible
                                            }
                                        }
                                    }
                                }
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
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var next = !shellRoot.settingsVisible; shellRoot.dismissPanels(); shellRoot.settingsVisible = next; } }
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
                                colorRight: shellRoot._sur
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                            }

                            // Background Tasks Handler Module (Top Left next to Power block)
                            Rectangle {
                                height: parent.height
                                width: melBgHandlerLeft.width + 12
                                color: shellRoot._sur
                                Row {
                                    id: melBgHandlerLeft
                                    anchors.centerIn: parent
                                    height: parent.height
                                    BackgroundTaskHandler {
                                        colors: shellRoot.colors
                                        rootBar: shellRoot
                                        anchors.verticalCenter: parent.verticalCenter
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
                                            shellRoot.bluetoothPanelVisible = false;
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
                                visible: !!(UPower.battery && UPower.battery.isPresent)
                            }

                            // Battery
                            Rectangle {
                                height: parent.height
                                width: melTopBat.width + 16
                                color: shellRoot._sur
                                visible: !!(UPower.battery && UPower.battery.isPresent)
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
                RiceEditorWindow {
                    id: riceEditorTop
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.riceEditorVisible
                    onCloseRequested: shellRoot.riceEditorVisible = false
                }
                TaskSwitcherWindow {
                    id: taskSwitcherTop
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.taskSwitcherVisible
                    onCloseRequested: shellRoot.taskSwitcherVisible = false
                }
                ClipboardWindow {
                    id: clipboardTop
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.clipboardVisible
                    onCloseRequested: shellRoot.clipboardVisible = false
                }
                DesktopContextMenu {
                    id: desktopMenuTop
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.desktopContextMenuVisible
                    onCloseRequested: shellRoot.desktopContextMenuVisible = false
                }
                ThemeSelectorWindow {
                    id: themeWindow
                    modelData: topBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot
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
                BluetoothPanel {
                    id: btPanel
                    modelData: topBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: shellRoot.bluetoothPanelVisible
                }
                BackgroundTaskPanel {
                    id: bgTaskPanel
                    modelData: topBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: shellRoot.backgroundTasksPanelVisible
                }
                WallpaperSelectorWindow {
                    id: wpWindow
                    modelData: topBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: shellRoot.wallpaperSelectorVisible
                }
                LightModePromptWindow {
                    id: lightPromptWindow
                    modelData: topBar.screen
                    rootBar: shellRoot
                    wallpaperPath: shellRoot.lightModePromptWp
                    visible: shellRoot.lightModePromptVisible
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

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-brightness-overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            visible: shellRoot.brightnessValue < 0.98

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, Math.max(0.0, Math.min(0.85, (1.0 - shellRoot.brightnessValue) * 0.75)))
            }
        }
    }

    // =========================================================================
    // BOTTOM BAR — melissa + cynthia (double) and cristina + isabel (single-bottom)
    // =========================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: bottomBar
                required property var modelData
                screen: modelData
                visible: ThemeManager.barIsBottom || (ThemeManager.barIsDouble && ThemeManager.bottomBarEnabled)
                color: "transparent"
                anchors { bottom: true; left: true; right: true }
                implicitWidth: screen.width
                implicitHeight: (ThemeManager.themeName === "cristina") ? (shellRoot.barHeight + 16) : shellRoot.barHeight

                property bool isBottomHovered: bottomHoverArea.containsMouse || shellRoot.settingsVisible || shellRoot.riceEditorVisible || shellRoot.volumePanelVisible || shellRoot.networkPanelVisible || shellRoot.powerMenuVisible
                property bool bottomBarShouldHide: false

                Timer {
                    id: bottomHideTimer
                    interval: 600
                    repeat: false
                    onTriggered: bottomBar.bottomBarShouldHide = true
                }

                onIsBottomHoveredChanged: {
                    if (isBottomHovered) {
                        bottomHideTimer.stop();
                        bottomBarShouldHide = false;
                    } else {
                        bottomHideTimer.restart();
                    }
                }

                property real autoHideBottomOffset: (ThemeManager.autoHideBar && bottomBarShouldHide) ? (shellRoot.barHeight - 4) : 0
                Behavior on autoHideBottomOffset { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                property real animatedMargin: (ThemeManager.themeName === "cristina")
                    ? screen.width * (1.0 - shellRoot.barWidthPercent) / 2
                    : 0
                Behavior on animatedMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: bottomHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Rectangle {
                    id: bottomBarRect
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: ((ThemeManager.themeName === "cristina") ? 8 : 0) - bottomBar.autoHideBottomOffset
                        left: parent.left; right: parent.right
                        leftMargin: bottomBar.animatedMargin
                        rightMargin: bottomBar.animatedMargin
                    }
                    height: shellRoot.barHeight
                    color: ThemeManager.themeName === "melissa" ? "transparent" : shellRoot._bg
                    opacity: ThemeManager.barIsDualCynthia ? 0.85 : 1.0
                    radius: (ThemeManager.themeName === "cristina") ? 8 : 0
                    border.color: (ThemeManager.themeName === "cristina") ? shellRoot.alphaColor(shellRoot._sur, 0.8) : "transparent"
                    border.width: (ThemeManager.themeName === "cristina") ? 1 : 0

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
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "cristina"

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
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "cristina"

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
                            visible: ThemeManager.themeName !== "melissa" && ThemeManager.themeName !== "cristina"

                            Repeater {
                                model: themeLayouts[ThemeManager.themeName] && themeLayouts[ThemeManager.themeName].bottom ? themeLayouts[ThemeManager.themeName].bottom.right : []
                                delegate: capsuleDelegate
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // ── CRISTINA BOTTOM BAR POWERLINE SLANTED BADGES ────
                        // ══════════════════════════════════════════════════════
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 8
                            visible: ThemeManager.themeName === "cristina"

                            // Arch / Distro Logo
                            Text {
                                text: "󰣇"
                                color: shellRoot._cyn
                                font.family: shellRoot.globalFontFamily
                                font.pixelSize: shellRoot.iconFontSize + 2
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                            }

                            Text { text: ":"; color: shellRoot._muted; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }

                            // Apps Launchers
                            Row {
                                spacing: 10
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰆍"; color: shellRoot._cyn; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["kitty"]; dispatchProc.running = true } } }
                                Text { text: "󰉋"; color: shellRoot._yel; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["dolphin"]; dispatchProc.running = true } } }
                                Text { text: "󰖟"; color: shellRoot._red; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["zen-browser"]; dispatchProc.running = true } } }
                                Text { text: "󰙯"; color: shellRoot._mag; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["vesktop"]; dispatchProc.running = true } } }
                                Text { text: "󰓓"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["steam"]; dispatchProc.running = true } } }
                                Text { text: "󰊴"; color: shellRoot._blu; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { dispatchProc.command = ["lutris"]; dispatchProc.running = true } } }
                            }

                            Text { text: ":"; color: shellRoot._muted; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }

                            // Active Window Title / Distro Name
                            Row {
                                spacing: 6
                                height: parent.height
                                Text {
                                    text: "󰖯"
                                    color: shellRoot._muted
                                    font.family: shellRoot.globalFontFamily
                                    font.pixelSize: shellRoot.iconFontSize
                                    verticalAlignment: Text.AlignVCenter
                                    height: parent.height
                                }
                                Text {
                                    text: shellRoot.activeWinTitle !== "" ? shellRoot.activeWinTitle : shellRoot.distroName
                                    color: shellRoot._fg
                                    font.family: shellRoot.globalFontFamily
                                    font.pixelSize: shellRoot.globalFontSize
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: Math.min(220, implicitWidth)
                                    verticalAlignment: Text.AlignVCenter
                                    height: parent.height
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 8
                            visible: ThemeManager.themeName === "cristina"

                            // Weather
                            Row {
                                spacing: 4
                                height: parent.height
                                Text { text: "󰖐"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                Text { text: shellRoot.weatherTemp !== "" ? shellRoot.weatherTemp : "22°"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            }

                            // User / Song
                            Row {
                                spacing: 4
                                height: parent.height
                                Text { text: "󰀉"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                Text { text: "󰎈"; color: shellRoot._fg; font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize - 2; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            }

                            // ── Slanted Parallelogram Badges Row ──
                            Row {
                                spacing: 6
                                height: parent.height

                                // Badge 1: Updates (Cyan)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: updatesBadgeRow.implicitWidth
                                    Row {
                                        id: updatesBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._cyn; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._cyn
                                            height: parent.height
                                            width: updatesBadgeContent.implicitWidth + 8
                                            Row {
                                                id: updatesBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: "󰚰"; color: shellRoot.contrastFg(shellRoot._cyn, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: shellRoot.updatesValue; color: shellRoot.contrastFg(shellRoot._cyn, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._cyn; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: checkUpdatesProc.running = true }
                                }

                                // Badge 2: Disk (Magenta/Purple)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: diskBadgeRow.implicitWidth
                                    Row {
                                        id: diskBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._mag; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._mag
                                            height: parent.height
                                            width: diskBadgeContent.implicitWidth + 8
                                            Row {
                                                id: diskBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: "󰋊"; color: shellRoot.contrastFg(shellRoot._mag, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: shellRoot.fsValue; color: shellRoot.contrastFg(shellRoot._mag, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._mag; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                }

                                // Badge 3: CPU (Blue)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: cpuBadgeRow.implicitWidth
                                    Row {
                                        id: cpuBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._blu; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._blu
                                            height: parent.height
                                            width: cpuBadgeContent.implicitWidth + 8
                                            Row {
                                                id: cpuBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: "󰍛"; color: shellRoot.contrastFg(shellRoot._blu, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: shellRoot.cpuValue; color: shellRoot.contrastFg(shellRoot._blu, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._blu; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                }

                                // Badge 4: RAM (Yellow)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: memBadgeRow.implicitWidth
                                    Row {
                                        id: memBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._yel; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._yel
                                            height: parent.height
                                            width: memBadgeContent.implicitWidth + 8
                                            Row {
                                                id: memBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: "󰟜"; color: shellRoot.contrastFg(shellRoot._yel, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: shellRoot.memValue; color: shellRoot.contrastFg(shellRoot._yel, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._yel; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                }

                                // Badge 5: Volume (Red/Salmon)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: volBadgeRow.implicitWidth
                                    Row {
                                        id: volBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._red; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._red
                                            height: parent.height
                                            width: volBadgeContent.implicitWidth + 8
                                            Row {
                                                id: volBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: shellRoot.volMuted ? "󰖁" : "󰕾"; color: shellRoot.contrastFg(shellRoot._red, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: Math.round(shellRoot.volValue * 100).toString(); color: shellRoot.contrastFg(shellRoot._red, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._red; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.volumePanelVisible = !shellRoot.volumePanelVisible
                                    }
                                }

                                // Badge 6: Wifi / Network (Cyan/Teal)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: netBadgeRow.implicitWidth
                                    Row {
                                        id: netBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._cyn; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._cyn
                                            height: parent.height
                                            width: netBadgeContent.implicitWidth + 8
                                            Row {
                                                id: netBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: shellRoot.networkType === "wifi" ? "󰤨" : "󰖟"; color: shellRoot.contrastFg(shellRoot._cyn, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                                Text { text: "2 K"; color: shellRoot.contrastFg(shellRoot._cyn, "#111217"); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._cyn; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.networkPanelVisible = !shellRoot.networkPanelVisible
                                    }
                                }

                                // Badge 7: Clock / Time (Dark Surface / Muted)
                                Item {
                                    height: parent.height - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: dateBadgeRow.implicitWidth
                                    Row {
                                        id: dateBadgeRow
                                        anchors.fill: parent
                                        spacing: 0
                                        SlantSeparator { colorLeft: "transparent"; colorRight: shellRoot._sur; isRightSlant: true; slantWidth: 10; height: parent.height }
                                        Rectangle {
                                            color: shellRoot._sur
                                            height: parent.height
                                            width: dateBadgeContent.implicitWidth + 8
                                            Row {
                                                id: dateBadgeContent
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: shellRoot.dateValue; color: shellRoot.contrastFg(shellRoot._sur, shellRoot._fg); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.globalFontSize; font.bold: true }
                                            }
                                        }
                                        SlantSeparator { colorLeft: shellRoot._sur; colorRight: "transparent"; isRightSlant: true; slantWidth: 10; height: parent.height }
                                    }
                                }
                            }

                            // System Tray Expander (󰅀)
                            Text {
                                text: "󰅀"
                                color: shellRoot._muted
                                font.family: shellRoot.globalFontFamily
                                font.pixelSize: shellRoot.globalFontSize
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.backgroundTasksPanelVisible = !shellRoot.backgroundTasksPanelVisible }
                            }

                            // Settings Button (󰒓)
                            Text {
                                text: "󰒓"
                                color: shellRoot._cyn
                                font.family: shellRoot.globalFontFamily
                                font.pixelSize: shellRoot.iconFontSize - 2
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var next = !shellRoot.riceEditorVisible;
                                        shellRoot.dismissPanels();
                                        shellRoot.riceEditorVisible = next;
                                    }
                                }
                            }

                            // Power Button (󰐥)
                            Text {
                                text: "󰐥"
                                color: shellRoot._red
                                font.family: shellRoot.globalFontFamily
                                font.pixelSize: shellRoot.iconFontSize
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.powerMenuVisible = !shellRoot.powerMenuVisible }
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
                                visible: shellRoot.songValue !== ""
                            }

                            // Media block
                            Rectangle {
                                visible: shellRoot.songValue !== ""
                                height: parent.height
                                width: melMediaBlockRow.width + 20
                                color: shellRoot._muted
                                Row {
                                    id: melMediaBlockRow
                                    anchors.centerIn: parent
                                    height: parent.height
                                    spacing: 10
                                    Text { text: "\uf048"; color: contrastFg(shellRoot._muted, shellRoot._brightBlu); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: prevProc.running = true } }
                                    Text { text: shellRoot.isPlaying ? "\uf04c" : "\uf04b"; color: contrastFg(shellRoot._muted, shellRoot._brightGrn); font.family: shellRoot.globalFontFamily; font.pixelSize: shellRoot.iconFontSize; verticalAlignment: Text.AlignVCenter; height: parent.height; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shellRoot.isPlaying = !shellRoot.isPlaying; playProc.running = true } } }
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
                                         MouseArea {
                                             anchors.fill: parent
                                             acceptedButtons: Qt.LeftButton | Qt.RightButton
                                             cursorShape: Qt.PointingHandCursor
                                             onClicked: (mouse) => {
                                                 if (mouse.button === Qt.RightButton && shellRoot.activePlayersList.length > 1) {
                                                     var idx = shellRoot.activePlayersList.indexOf(shellRoot.selectedPlayer);
                                                     var nextIdx = (idx + 1) % shellRoot.activePlayersList.length;
                                                     shellRoot.selectedPlayer = shellRoot.activePlayersList[nextIdx];
                                                     shellRoot.refreshMediaPlayer();
                                                 } else {
                                                     shellRoot.volumePanelVisible = false;
                                                     shellRoot.networkPanelVisible = false;
                                                     shellRoot.bluetoothPanelVisible = false;
                                                     shellRoot.settingsVisible = false;
                                                     shellRoot.powerMenuVisible = false;
                                                     shellRoot.themeSelectorVisible = false;
                                                     shellRoot.mediaPlayerVisible = !shellRoot.mediaPlayerVisible;
                                                 }
                                             }
                                         }
                                     }
                                }
                            }

                            SlantSeparator {
                                colorLeft: shellRoot._muted
                                colorRight: "transparent"
                                isRightSlant: true
                                slantWidth: 12
                                height: parent.height
                                visible: shellRoot.songValue !== ""
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
                    rootBar: shellRoot; visible: shellRoot.settingsVisible
                }
                RiceEditorWindow {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.riceEditorVisible
                    onCloseRequested: shellRoot.riceEditorVisible = false
                }
                TaskSwitcherWindow {
                    id: botTaskSwitcher
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.taskSwitcherVisible
                    onCloseRequested: shellRoot.taskSwitcherVisible = false
                }
                ClipboardWindow {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.clipboardVisible
                    onCloseRequested: shellRoot.clipboardVisible = false
                }
                DesktopContextMenu {
                    modelData: bottomBar.screen; colors: shellRoot.colors
                    rootBar: shellRoot; visible: shellRoot.desktopContextMenuVisible
                    onCloseRequested: shellRoot.desktopContextMenuVisible = false
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
                BluetoothPanel {
                    modelData: bottomBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsBottom && shellRoot.bluetoothPanelVisible
                }
                BackgroundTaskPanel {
                    modelData: bottomBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsBottom && shellRoot.backgroundTasksPanelVisible
                }
                WallpaperSelectorWindow {
                    modelData: bottomBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsBottom && shellRoot.wallpaperSelectorVisible
                }
            }
        }
    }

    // =========================================================================
    // SIDEBAR — z0mbi3 vertical left panel
    // =========================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: sideBar
                required property var modelData
                screen: modelData
                visible: ThemeManager.barIsSidebar
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
                                    shellRoot.bluetoothPanelVisible = false;
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
                                        shellRoot.bluetoothPanelVisible = false;
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
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var next = !shellRoot.settingsVisible; shellRoot.dismissPanels(); shellRoot.settingsVisible = next; } }
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
                BluetoothPanel {
                    modelData: sideBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsSidebar && shellRoot.bluetoothPanelVisible
                }
                BackgroundTaskPanel {
                    modelData: sideBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsSidebar && shellRoot.backgroundTasksPanelVisible
                }
                WallpaperSelectorWindow {
                    modelData: sideBar.screen
                    colors: shellRoot.colors
                    rootBar: shellRoot
                    visible: ThemeManager.barIsSidebar && shellRoot.wallpaperSelectorVisible
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
    Timer { interval: 2000;  running: true; repeat: true; onTriggered: { listPlayersProc.running = true; songProc.running = true; artistProc.running = true; playerStatusProc.running = true; } }

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
        id: listPlayersProc
        command: ["bash", "-c", "playerctl -l 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim();
                var list = [];
                if (raw !== "") {
                    var lines = raw.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var p = lines[i].trim();
                        if (p !== "") list.push(p);
                    }
                }
                shellRoot.activePlayersList = list;
                if (list.indexOf(shellRoot.selectedPlayer) === -1) {
                    shellRoot.selectedPlayer = list.length > 0 ? list[0] : "";
                }
            }
        }
    }
    Process {
        id: songProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["bash", "-c", "playerctl -p " + p + " metadata title 2>/dev/null || echo ''"];
            } else {
                return ["bash", "-c", "playerctl metadata title 2>/dev/null || echo ''"];
            }
        }
        running: true
        stdout: StdioCollector { onStreamFinished: shellRoot.songValue = this.text.trim() }
    }
    Process {
        id: artistProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["bash", "-c", "playerctl -p " + p + " metadata artist 2>/dev/null || echo ''"];
            } else {
                return ["bash", "-c", "playerctl metadata artist 2>/dev/null || echo ''"];
            }
        }
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
            shellRoot._brightAcc,
            shellRoot._brightRed,
            shellRoot._brightGrn,
            shellRoot._brightYel,
            shellRoot._brightBlu,
            shellRoot._brightCyn,
            shellRoot._brightMag,
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
    Process {
        id: prevProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["playerctl", "-p", p, "previous"];
            } else {
                return ["playerctl", "previous"];
            }
        }
    }
    Process {
        id: playProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["playerctl", "-p", p, "play-pause"];
            } else {
                return ["playerctl", "play-pause"];
            }
        }
    }
    Process {
        id: playerStatusProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["playerctl", "-p", p, "status"];
            } else {
                return ["playerctl", "status"];
            }
        }
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
    Process {
        id: nextProc
        command: {
            var p = shellRoot.selectedPlayer;
            if (p && p !== "") {
                return ["playerctl", "-p", p, "next"];
            } else {
                return ["playerctl", "next"];
            }
        }
    }
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

    // ═════════════════════════════════════════════════════════════════════════
    // ── THEME NOTIFICATION OSD POPUP ─────────────────────────────────────────
    // ═════════════════════════════════════════════════════════════════════════
    PanelWindow {
        id: themeNotificationOSD
        screen: Quickshell.screens[0]
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        anchors { top: true }
        margins { top: isShowing ? 55 : 20 }
        Behavior on margins { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        implicitWidth: osdCard.implicitWidth
        implicitHeight: osdCard.implicitHeight
        visible: osdOpacity > 0

        property bool isShowing: false
        property real osdOpacity: 0.0
        Behavior on osdOpacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        function triggerPopup() {
            themeNotificationOSD.isShowing = true;
            themeNotificationOSD.osdOpacity = 1.0;
            osdHideTimer.restart();
        }

        Timer {
            id: osdHideTimer
            interval: 2400
            onTriggered: {
                themeNotificationOSD.isShowing = false;
                themeNotificationOSD.osdOpacity = 0.0;
            }
        }

        Connections {
            target: ThemeManager
            function onThemeNameChanged() {
                themeNotificationOSD.triggerPopup();
            }
        }

        Component.onCompleted: {
            themeNotificationOSD.triggerPopup();
        }

        Rectangle {
            id: osdCard
            implicitWidth: osdRow.implicitWidth + 40
            implicitHeight: 48
            color: shellRoot.alphaColor(shellRoot._bg, 0.95)
            radius: 24
            border.color: shellRoot.alphaColor(shellRoot._cyn, 0.8)
            border.width: 1.5

            Row {
                id: osdRow
                anchors.centerIn: parent
                spacing: 12
                Text {
                    text: "󰏘"
                    color: shellRoot._cyn
                    font.family: shellRoot.globalFontFamily
                    font.pixelSize: shellRoot.iconFontSize + 4
                    verticalAlignment: Text.AlignVCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: "Theme Changed"
                        color: shellRoot._muted
                        font.family: shellRoot.globalFontFamily
                        font.pixelSize: shellRoot.globalFontSize - 2
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        text: ThemeManager.themeName.charAt(0).toUpperCase() + ThemeManager.themeName.slice(1)
                        color: shellRoot._fg
                        font.family: shellRoot.globalFontFamily
                        font.pixelSize: shellRoot.globalFontSize + 2
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

}