pragma Singleton
import QtQuick
import QtCore

Item {
    id: root

    readonly property bool _initApps: {
        Qt.application.organization = "FluxDots";
        Qt.application.name = "FluxDots";
        return true;
    }

    // Single Centralized Settings Store for all bars, themes, applets, volume & brightness
    Settings {
        id: cfgStore
        category: "CentralConfig"

        // Theme & Bar Basics
        property string themeName: "cristina"
        property string colorMode: "static"
        property int    barHeight: 40
        property real   barWidthPercent: 0.96
        property int    barRadius: 8
        property int    globalFontSize: 11
        property bool   autoHideBar: false
        property string customAccentColor: ""
        property bool   gradientAnimated: true

        // Applet Configuration (Position & Size)
        property string appletLocation: "top" // "top", "bottom", "center", "custom"
        property real   appletScale: 1.0
        property int    appletWidth: 340
        property int    appletHeight: 440
        property bool   useCustomAppletSize: false
        property int    appletCustomX: 100
        property int    appletCustomY: 100

        property real   borderAnimSpeed: 4.0 // In seconds
        property bool   lockHardwareDefaults: true
        property real   lockedVolValue: 0.50
        property real   lockedBrightnessValue: 0.80

        // Dual Bar & Applet Target Options
        property string activeBarTarget: "top" // "top" or "bottom"
        property string topBarModulesLeft: "launcher,cpu,ram,disk"
        property string topBarModulesCenter: "workspaces"
        property string topBarModulesRight: "song,network,volume,clock,power"
        property string bottomBarModulesLeft: "title"
        property string bottomBarModulesCenter: "pinnedApps"
        property string bottomBarModulesRight: "tray,settings"

        // Saved Hardware Device Values (Volume & Brightness)
        property real   volValue: 0.48
        property real   brightnessValue: 0.88
        property bool   isMuted: false

        // Per-Module Configuration Settings
        property bool showTitleLogo: true
        property bool showTitleAppName: true
        property bool showTitleWindowName: true
        property bool showSongCoverArt: false // Cover art in expanded player only
        property bool showSongEqualizer: false
        property bool showSongArtist: false

        // Bar Layout Mode & Modules
        property string mode: "default" // "default" or "custom"
        property bool   editMode: false
        property string leftModules: "launcher,cpu,ram,disk"
        property string centerModules: "workspaces"
        property string rightModules: "song,network,volume,updates,clock,tray,power"
    }

    // Property Aliases
    property alias borderAnimSpeed:      cfgStore.borderAnimSpeed
    property alias lockHardwareDefaults: cfgStore.lockHardwareDefaults
    property alias lockedVolValue:       cfgStore.lockedVolValue
    property alias lockedBrightnessValue: cfgStore.lockedBrightnessValue
    property alias activeBarTarget:      cfgStore.activeBarTarget
    property alias topBarModulesLeft:    cfgStore.topBarModulesLeft
    property alias topBarModulesCenter:  cfgStore.topBarModulesCenter
    property alias topBarModulesRight:   cfgStore.topBarModulesRight
    property alias bottomBarModulesLeft: cfgStore.bottomBarModulesLeft
    property alias bottomBarModulesCenter: cfgStore.bottomBarModulesCenter
    property alias bottomBarModulesRight: cfgStore.bottomBarModulesRight
    property alias themeName:         cfgStore.themeName
    property alias colorMode:         cfgStore.colorMode
    property alias barHeight:         cfgStore.barHeight
    property alias barWidthPercent:   cfgStore.barWidthPercent
    property alias barRadius:         cfgStore.barRadius
    property alias globalFontSize:    cfgStore.globalFontSize
    property alias autoHideBar:       cfgStore.autoHideBar
    property alias customAccentColor: cfgStore.customAccentColor
    property alias gradientAnimated:  cfgStore.gradientAnimated

    property alias appletLocation:    cfgStore.appletLocation
    property alias appletScale:       cfgStore.appletScale
    property alias appletWidth:       cfgStore.appletWidth
    property alias appletHeight:      cfgStore.appletHeight
    property alias useCustomAppletSize: cfgStore.useCustomAppletSize
    property alias appletCustomX:     cfgStore.appletCustomX
    property alias appletCustomY:     cfgStore.appletCustomY

    property alias showTitleLogo:       cfgStore.showTitleLogo
    property alias showTitleAppName:    cfgStore.showTitleAppName
    property alias showTitleWindowName: cfgStore.showTitleWindowName
    property alias showSongCoverArt:    cfgStore.showSongCoverArt
    property alias showSongEqualizer:   cfgStore.showSongEqualizer
    property alias showSongArtist:      cfgStore.showSongArtist

    property alias volValue:          cfgStore.volValue
    property alias brightnessValue:   cfgStore.brightnessValue
    property alias isMuted:           cfgStore.isMuted

    property alias mode:              cfgStore.mode
    property alias editMode:          cfgStore.editMode
    property alias leftModules:       cfgStore.leftModules
    property alias centerModules:     cfgStore.centerModules
    property alias rightModules:      cfgStore.rightModules

    function setZone(moduleKey, zone, allowDuplicate) {
        var lefts = (leftModules || "").split(",");
        var centers = (centerModules || "").split(",");
        var rights = (rightModules || "").split(",");

        if (!allowDuplicate) {
            lefts = lefts.filter(function(m) { return m !== moduleKey && m !== ""; });
            centers = centers.filter(function(m) { return m !== moduleKey && m !== ""; });
            rights = rights.filter(function(m) { return m !== moduleKey && m !== ""; });
        }

        if (zone === "left") lefts.push(moduleKey);
        else if (zone === "center") centers.push(moduleKey);
        else if (zone === "right") rights.push(moduleKey);

        leftModules = lefts.join(",");
        centerModules = centers.join(",");
        rightModules = rights.join(",");
        mode = "custom";
    }

    function getZone(moduleKey) {
        var lefts = (leftModules || "").split(",");
        var centers = (centerModules || "").split(",");
        var rights = (rightModules || "").split(",");

        if (lefts.indexOf(moduleKey) !== -1) return "left";
        if (centers.indexOf(moduleKey) !== -1) return "center";
        if (rights.indexOf(moduleKey) !== -1) return "right";
        return "hidden";
    }

    function moveModule(moduleKey, dir) {
        var zone = getZone(moduleKey);
        if (zone === "hidden") return;

        var csvStr = (zone === "left") ? leftModules : ((zone === "center") ? centerModules : rightModules);
        var list = (csvStr || "").split(",").filter(function(m) { return m !== ""; });
        var idx = list.indexOf(moduleKey);
        if (idx === -1) return;

        if (dir === "up" || dir === "left") {
            if (idx > 0) {
                var temp = list[idx - 1];
                list[idx - 1] = list[idx];
                list[idx] = temp;
            }
        } else if (dir === "down" || dir === "right") {
            if (idx < list.length - 1) {
                var temp = list[idx + 1];
                list[idx + 1] = list[idx];
                list[idx] = temp;
            }
        }

        var newCsv = list.join(",");
        if (zone === "left") leftModules = newCsv;
        else if (zone === "center") centerModules = newCsv;
        else if (zone === "right") rightModules = newCsv;
        mode = "custom";
    }

    function getModuleIndex(moduleKey) {
        var zone = getZone(moduleKey);
        if (zone === "hidden") return -1;
        var csvStr = (zone === "left") ? leftModules : ((zone === "center") ? centerModules : rightModules);
        var list = (csvStr || "").split(",").filter(function(m) { return m !== ""; });
        return list.indexOf(moduleKey);
    }

    function applyPreset(presetType) {
        if (presetType === "emilia_default" || presetType === "default") {
            leftModules = "launcher,cpu,ram,disk,media";
            centerModules = "workspaces";
            rightModules = "song,network,volume,updates,clock,tray,power";
        } else if (presetType === "minimal") {
            leftModules = "launcher,workspaces";
            centerModules = "title";
            rightModules = "volume,network,clock,power";
        } else if (presetType === "sysmon") {
            leftModules = "workspaces";
            centerModules = "media";
            rightModules = "cpu,gpu,ram,temp,disk,volume,network,clock,power";
        } else if (presetType === "full") {
            leftModules = "launcher,workspaces,title,pinnedApps";
            centerModules = "media,updates,weather";
            rightModules = "disk,cpu,ram,gpu,temp,volume,brightness,network,bluetooth,battery,clock,tray,theme,wallpaper,power";
        } else if (presetType === "custom_user" && savedCustomLeft !== "") {
            leftModules = savedCustomLeft;
            centerModules = savedCustomCenter;
            rightModules = savedCustomRight;
        }
        mode = "custom";
    }

    // ── CUSTOM USER PRESET STORE ──
    property string savedCustomLeft: ""
    property string savedCustomCenter: ""
    property string savedCustomRight: ""
    readonly property bool hasCustomPreset: savedCustomLeft !== "" || savedCustomCenter !== "" || savedCustomRight !== ""

    function saveCustomPreset() {
        savedCustomLeft = leftModules;
        savedCustomCenter = centerModules;
        savedCustomRight = rightModules;
    }

    // ── DUPLICATE MODULE DETECTOR & CLEANER ──
    function getDuplicateModules() {
        var all = (leftModules + "," + centerModules + "," + rightModules).split(",");
        var counts = {};
        var dups = [];
        for (var i = 0; i < all.length; i++) {
            var m = all[i];
            if (!m) continue;
            counts[m] = (counts[m] || 0) + 1;
            if (counts[m] === 2) dups.push(m);
        }
        return dups;
    }

    function getModuleCount(moduleKey) {
        var all = (leftModules + "," + centerModules + "," + rightModules).split(",");
        var c = 0;
        for (var i = 0; i < all.length; i++) {
            if (all[i] === moduleKey) c++;
        }
        return c;
    }

    function deduplicateModules() {
        var lefts = (leftModules || "").split(",").filter(Boolean);
        var centers = (centerModules || "").split(",").filter(Boolean);
        var rights = (rightModules || "").split(",").filter(Boolean);

        var seen = {};
        lefts = lefts.filter(function(m) { if (seen[m]) return false; seen[m] = true; return true; });
        centers = centers.filter(function(m) { if (seen[m]) return false; seen[m] = true; return true; });
        rights = rights.filter(function(m) { if (seen[m]) return false; seen[m] = true; return true; });

        leftModules = lefts.join(",");
        centerModules = centers.join(",");
        rightModules = rights.join(",");
    }
}
