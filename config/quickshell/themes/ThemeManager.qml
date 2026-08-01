// ThemeManager - FluxDots Dynamic Theme Engine
// Always in flux. Themes that breathe, shift, and evolve.

pragma Singleton

import QtQuick
import QtCore

Item {
    id: root

    // FluxDots branding
    readonly property bool _initApps: {
        Qt.application.organization = "FluxDots";
        Qt.application.name = "FluxDots";
        return true;
    }

    // Persistent storage
    Settings {
        id: stateStore
        category: "ThemeState"
        property string themeName: "cristina"
        property string colorMode: "static"
        property int    barHeight: 40
        property real   barWidthPercent: 0.96
        property int    barRadius: 8
        property int    globalFontSize: 11
        property bool   isLightMode: false
        property string modeChoice: "dark"
        property bool   autoHideBar: false
        property string appColorMode: "theme"
        property bool   topBarEnabled: true
        property bool   bottomBarEnabled: true
        property string customAccentColor: ""
        property bool   showPinnedApps: true
        property bool   showBadges: true
        property bool   useCustomModuleLayout: false
        property string leftModules: "launcher,workspaces,title"
        property string centerModules: "pinnedApps,media"
        property string rightModules: "updates,disk,cpu,ram,volume,network,clock,tray,power"
    }

    property alias themeName:         stateStore.themeName
    property alias colorMode:         stateStore.colorMode
    property alias barHeight:         stateStore.barHeight
    property alias barWidthPercent:   stateStore.barWidthPercent
    property alias barRadius:         stateStore.barRadius
    property alias globalFontSize:    stateStore.globalFontSize
    property alias isLightMode:       stateStore.isLightMode
    property alias modeChoice:       stateStore.modeChoice
    property alias autoHideBar:       stateStore.autoHideBar
    property alias appColorMode:     stateStore.appColorMode
    property alias topBarEnabled:     stateStore.topBarEnabled
    property alias bottomBarEnabled:  stateStore.bottomBarEnabled
    property alias customAccentColor: stateStore.customAccentColor
    property alias showPinnedApps:        stateStore.showPinnedApps
    property alias showBadges:            stateStore.showBadges
    property alias useCustomModuleLayout: stateStore.useCustomModuleLayout
    property alias leftModules:           stateStore.leftModules
    property alias centerModules:         stateStore.centerModules
    property alias rightModules:          stateStore.rightModules

    // Resolved colors path
    readonly property string colorsPath: colorMode === "wallust" ?
                                             Qt.resolvedUrl("./WallustColors.qml") :
                                             Qt.resolvedUrl("./" + themeName + "/Colors.qml")

    // ── Available themes (internal names map to directory names) ──────────
    readonly property var availableThemes: [
        "aline",
        "andrea",
        "brenda",
        "cristina",
        "cynthia",
        "daniela",
        "emilia",
        "h4ck3r",
        "isabel",
        "jan",
        "karla",
        "marisol",
        "melissa",
        "pamela",
        "silvia",
        "varinka",
        "yael",
        "z0mbi3"
    ]

    // ── Display names — shown in the UI ───────────────────────────────────
    readonly property var themeDisplayNames: ({
        "aline":    "Aurora",
        "andrea":   "Archipelago",
        "brenda":   "Blaze",
        "cristina": "Crystal",
        "cynthia":  "Synthwave",
        "daniela":  "Dusk",
        "emilia":   "Ember",
        "h4ck3r":   "Matrix",
        "isabel":   "Iris",
        "jan":      "Jade",
        "karla":    "Koi",
        "marisol":  "Mirage",
        "melissa":  "Melissa",
        "pamela":   "Prism",
        "silvia":   "Silver",
        "varinka":  "Velvet",
        "yael":     "Yonder",
        "z0mbi3":   "Noir"
    })

    // ── Descriptors — personality tags shown as subtitle ─────────────────
    readonly property var themeDescriptors: ({
        "aline":    "Drift",
        "andrea":   "Trident",
        "brenda":   "Ignite",
        "cristina": "Fracture",
        "cynthia":  "84",
        "daniela":  "Fade",
        "emilia":   "Glow",
        "h4ck3r":   "Override",
        "isabel":   "Bloom",
        "jan":      "Canopy",
        "karla":    "Ripple",
        "marisol":  "Haze",
        "melissa":  "Powerline",
        "pamela":   "Scatter",
        "silvia":   "Grain",
        "varinka":  "Crush",
        "yael":     "Horizon",
        "z0mbi3":   "Static"
    })

    // Convenience accessors for current theme
    readonly property string displayName: themeDisplayNames[themeName] || themeName
    readonly property string descriptor:  themeDescriptors[themeName]  || ""
    readonly property string fullName:    displayName + (descriptor ? " · " + descriptor : "")

    // Helper method to get theme path
    function themePath(theme) {
        return Qt.resolvedUrl("./" + (theme || themeName))
    }

    // ── Bar layout type ───────────────────────────────────────────────────
    readonly property string barLayout: {
        if (themeName === "melissa")  return "double-melissa";
        if (themeName === "cynthia")  return "double-cynthia";
        if (themeName === "z0mbi3")   return "sidebar";
        if (themeName === "andrea")   return "andrea";
        var bottomBar = ["cristina", "isabel"];
        if (bottomBar.indexOf(themeName) !== -1) return "single-bottom";
        var floatBar = ["emilia", "aline", "pamela", "karla", "brenda"];
        if (floatBar.indexOf(themeName) !== -1) return "single-top-float";
        return "single-top-full";
    }

    readonly property bool barIsTopFloat:    barLayout === "single-top-float"
    readonly property bool barIsTopFull:     barLayout === "single-top-full"
    readonly property bool barIsTop:         barIsTopFloat || barIsTopFull || barLayout === "andrea"
    readonly property bool barIsBottom:      barLayout === "single-bottom"
    readonly property bool barIsDualMelissa: barLayout === "double-melissa"
    readonly property bool barIsDualCynthia: barLayout === "double-cynthia"
    readonly property bool barIsDouble:      barIsDualMelissa || barIsDualCynthia
    readonly property bool barIsSidebar:     barLayout === "sidebar"
    readonly property bool barIsAndrea:      barLayout === "andrea"

    // ── Theme cycling — wraps around ──────────────────────────────────────
    function nextTheme() {
        var idx = availableThemes.indexOf(themeName)
        var nextIdx = (idx + 1) % availableThemes.length
        themeName = availableThemes[nextIdx]
    }

    function prevTheme() {
        var idx = availableThemes.indexOf(themeName)
        var prevIdx = (idx - 1 + availableThemes.length) % availableThemes.length
        themeName = availableThemes[prevIdx]
    }
}