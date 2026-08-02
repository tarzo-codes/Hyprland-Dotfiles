import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"
import "../themes"

PanelWindow {
    id: riceWindow
    required property var modelData
    screen: modelData

    implicitWidth: screen.width
    implicitHeight: screen.height

    // Layer Top so topBar / bottomBar on Overlay layer remain ABOVE RiceEditorWindow!
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Transparent window background so desktop is unobscured
    color: "transparent"

    property var colors: null
    property var rootBar: null
    signal closeRequested()
    onVisibleChanged: {
        if (!visible) {
            CentralConfig.editMode = false;
            BarModules.editMode = false;
        }
    }

    property int activeCategory: 0
    property int activeTab: 0

    // ── Pending / Buffer State (Nothing updates live until APPLY CHANGES is clicked!) ──
    property bool hasUnappliedChanges: false
    property int pendingRadius: CentralConfig.barRadius
    property int pendingHeight: CentralConfig.barHeight
    property real pendingWidthPct: CentralConfig.barWidthPercent
    property int pendingFontSize: CentralConfig.globalFontSize
    property int pendingAppletW: CentralConfig.appletWidth
    property int pendingAppletH: CentralConfig.appletHeight
    property int pendingAppletX: CentralConfig.appletCustomX
    property int pendingAppletY: CentralConfig.appletCustomY
    property string pendingThemeName: CentralConfig.themeName
    property string pendingAccentHex: CentralConfig.customAccentColor !== "" ? CentralConfig.customAccentColor : (rootBar ? rootBar._cyn : "#9bced7")
    property bool pendingGradientAnimated: CentralConfig.gradientAnimated
    property bool pendingAutoHide: CentralConfig.autoHideBar
    property bool pendingCustomAppletSize: CentralConfig.useCustomAppletSize
    property string statusMsg: ""

    // Confirmation Modal Properties
    property bool confirmModalOpen: false
    property string pendingPresetId: ""
    property string pendingPresetName: ""

    // Duplicate Module Modal Properties
    property bool duplicateModalOpen: false
    property string pendingDupKey: ""
    property string pendingDupName: ""
    property string pendingDupZone: ""

    function requestZoneChange(moduleKey, moduleName, targetZone) {
        ensureEditMode();
        var currentZ = CentralConfig.getZone(moduleKey);
        if (targetZone === "hidden") {
            CentralConfig.setZone(moduleKey, "hidden", false);
            showStatus("Set " + moduleKey + " -> HIDDEN");
            return;
        }
        if (currentZ !== "hidden") {
            pendingDupKey = moduleKey;
            pendingDupName = moduleName;
            pendingDupZone = targetZone;
            duplicateModalOpen = true;
        } else {
            CentralConfig.setZone(moduleKey, targetZone, false);
            showStatus("Set " + moduleKey + " -> " + targetZone.toUpperCase());
        }
    }

    // Process to toggle active border gradient animation live via hyprctl
    Process {
        id: toggleGradientAnimProc
        property string animCmd: ""
        command: ["bash", "-c", "hyprctl keyword animation \"" + animCmd + "\" 2>/dev/null || true"]
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (confirmModalOpen) {
                confirmModalOpen = false;
            } else {
                riceWindow.closeRequested();
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: statusMsg = ""
    }

    function showStatus(msg) {
        statusMsg = msg;
        statusTimer.restart();
    }

    function markChanged(detailMsg) {
        hasUnappliedChanges = true;
        showStatus("⚠️ Change recorded! Click [APPLY CHANGES] to apply.");
    }

    function applyAllChanges() {
        // Commit all pending variables to CentralConfig & ThemeManager
        CentralConfig.barRadius = pendingRadius;
        CentralConfig.barHeight = pendingHeight;
        CentralConfig.barWidthPercent = pendingWidthPct;
        CentralConfig.appletWidth = pendingAppletW;
        CentralConfig.appletHeight = pendingAppletH;
        CentralConfig.appletCustomX = pendingAppletX;
        CentralConfig.appletCustomY = pendingAppletY;
        CentralConfig.themeName = pendingThemeName;
        ThemeManager.themeName = pendingThemeName;
        CentralConfig.customAccentColor = pendingAccentHex;
        CentralConfig.gradientAnimated = pendingGradientAnimated;
        CentralConfig.autoHideBar = pendingAutoHide;
        CentralConfig.useCustomAppletSize = pendingCustomAppletSize;

        if (rootBar) {
            rootBar.barHeight = pendingHeight;
            rootBar.barWidthPercent = pendingWidthPct;
        }

        hasUnappliedChanges = false;
        showStatus("✓ All changes successfully applied!");
    }

    function ensureEditMode() {
        if (!CentralConfig.editMode) {
            CentralConfig.editMode = true;
            showStatus("Edit Mode Activated! Live bar unlocked.");
        }
    }

    function requestPresetConfirmation(presetId, presetName) {
        pendingPresetId = presetId;
        pendingPresetName = presetName;
        confirmModalOpen = true;
    }

    function confirmPresetOverwrite() {
        if (pendingPresetId !== "") {
            CentralConfig.applyPreset(pendingPresetId);
            // Sync pending buffers
            pendingRadius = CentralConfig.barRadius;
            pendingHeight = CentralConfig.barHeight;
            pendingWidthPct = CentralConfig.barWidthPercent;
            pendingThemeName = CentralConfig.themeName;
            hasUnappliedChanges = false;
            showStatus("Preset '" + pendingPresetName + "' Applied!");
        }
        confirmModalOpen = false;
        pendingPresetId = "";
        pendingPresetName = "";
    }

    // Dismiss editor when clicking outside dialog card
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (confirmModalOpen) confirmModalOpen = false;
            else riceWindow.closeRequested();
        }
    }

    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        width: 980
        height: 700
        color: rootBar ? rootBar._bg : "#161622"
        border.color: hasUnappliedChanges ? (rootBar ? rootBar._yel : "#f1ca93") : (rootBar ? rootBar._acc : "#31748f")
        border.width: hasUnappliedChanges ? 2.5 : 1.5
        radius: 14
        clip: true

        // Prevent clicks inside editor from closing window
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ═════════════════════════════════════════════════════════════════
            // ── LEFT SIDEBAR NAVIGATION ─────────────────────────────────────
            // ═════════════════════════════════════════════════════════════════
            Rectangle {
                Layout.preferredWidth: 230
                Layout.fillHeight: true
                color: rootBar ? rootBar.alphaColor(rootBar._sur, 0.7) : "#1b192c"

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: 1
                    color: rootBar ? rootBar.alphaColor(rootBar._muted, 0.4) : "#2a283e"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Avatar Box
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 64; height: 64

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "#161622"
                            border.color: rootBar ? rootBar._cyn : "#9bced7"
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                text: "💀"
                                font.pixelSize: 32
                            }
                        }
                    }

                    // Title
                    Text {
                        text: "Centralized Rice Editor"
                        color: "#e0def4"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#2a283e" }

                    // Global Toggles (Edit Mode & Applet Target)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Edit Mode Toggle
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: CentralConfig.editMode ? "#8ec07c" : "#2a283e"
                            border.color: CentralConfig.editMode ? "#a6e3a1" : "#31748f"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Text { text: "󰏫"; color: CentralConfig.editMode ? "#181628" : "#9bced7"; font.pixelSize: 11 }
                                Text { text: "Edit Mode: " + (CentralConfig.editMode ? "ON" : "OFF"); color: CentralConfig.editMode ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    CentralConfig.editMode = !CentralConfig.editMode;
                                    riceWindow.showStatus(CentralConfig.editMode ? "Edit Mode Active on Bar" : "Edit Mode Disabled");
                                }
                            }
                        }

                        // Applet Location Toggle (Top / Bottom / Center / Custom)
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: "#2a283e"
                            border.color: "#9bced7"; border.width: 1

                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Text { text: "󰈈"; color: "#f1ca93"; font.pixelSize: 11 }
                                Text { text: "Applet Loc: " + CentralConfig.appletLocation.toUpperCase(); color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (CentralConfig.appletLocation === "top") CentralConfig.appletLocation = "bottom";
                                    else if (CentralConfig.appletLocation === "bottom") CentralConfig.appletLocation = "center";
                                    else if (CentralConfig.appletLocation === "center") CentralConfig.appletLocation = "custom";
                                    else CentralConfig.appletLocation = "top";
                                    riceWindow.showStatus("Applets Anchored to " + CentralConfig.appletLocation.toUpperCase());
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#2a283e" }

                    // Navigation Category Buttons
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Category 0: Rice Options
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: activeCategory === 0 ? (rootBar ? rootBar._cyn : "#9bced7") : (c0Mouse.containsMouse ? "#2a283e" : "transparent")
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "󰏘"; color: activeCategory === 0 ? "#181628" : "#e0def4"; font.pixelSize: 11 }
                                Text { text: "Rice Options"; color: activeCategory === 0 ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: activeCategory === 0 }
                            }
                            MouseArea { id: c0Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { activeCategory = 0; activeTab = 0; } }
                        }

                        // Category 1: Color & Style
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: activeCategory === 1 ? (rootBar ? rootBar._cyn : "#9bced7") : (c1Mouse.containsMouse ? "#2a283e" : "transparent")
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "󰄛"; color: activeCategory === 1 ? "#181628" : "#e0def4"; font.pixelSize: 11 }
                                Text { text: "Color & Style"; color: activeCategory === 1 ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: activeCategory === 1 }
                            }
                            MouseArea { id: c1Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { activeCategory = 1; activeTab = 1; } }
                        }

                        // Category 2: Modules & Apps
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: activeCategory === 2 ? (rootBar ? rootBar._cyn : "#9bced7") : (c2Mouse.containsMouse ? "#2a283e" : "transparent")
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "󰅀"; color: activeCategory === 2 ? "#181628" : "#e0def4"; font.pixelSize: 11 }
                                Text { text: "Modules & Order"; color: activeCategory === 2 ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: activeCategory === 2 }
                            }
                            MouseArea { id: c2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { activeCategory = 2; activeTab = 2; } }
                        }

                        // Category 3: Auto-Hide & FX
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: activeCategory === 3 ? (rootBar ? rootBar._cyn : "#9bced7") : (c3Mouse.containsMouse ? "#2a283e" : "transparent")
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "󰤈"; color: activeCategory === 3 ? "#181628" : "#e0def4"; font.pixelSize: 11 }
                                Text { text: "Auto-Hide & FX"; color: activeCategory === 3 ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: activeCategory === 3 }
                            }
                            MouseArea { id: c3Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { activeCategory = 3; activeTab = 3; } }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // ── MAIN GLOBAL "APPLY CHANGES" BUTTON ──
                    Rectangle {
                        Layout.fillWidth: true; height: 34; radius: 6
                        color: hasUnappliedChanges ? (rootBar ? rootBar._yel : "#f1ca93") : (rootBar ? rootBar._cyn : "#9bced7")
                        border.color: hasUnappliedChanges ? "#ffffff" : "transparent"
                        border.width: hasUnappliedChanges ? 1.5 : 0

                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: hasUnappliedChanges ? "⚠️" : "󰆓"; font.pixelSize: 12 }
                            Text {
                                text: hasUnappliedChanges ? "APPLY CHANGES" : "Apply & Save Config"
                                color: "#181628"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: riceWindow.applyAllChanges()
                        }
                    }

                    // Close Button
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: 6
                        color: closeBtnMouse.containsMouse ? "#ea6f91" : "transparent"
                        border.color: "#ea6f91"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Close"; color: closeBtnMouse.containsMouse ? "#ffffff" : "#ea6f91"; font.pixelSize: 10; font.bold: true }
                        MouseArea { id: closeBtnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.closeRequested() }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════════
            // ── RIGHT MAIN PANEL & TABS ──────────────────────────────────────
            // ═════════════════════════════════════════════════════════════════
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.margins: 18
                spacing: 10

                // Header Title, Live Preview Toggle & Status Toast
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "Centralized Config  :"
                        color: "#e0def4"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: pendingThemeName
                        color: rootBar ? rootBar._yel : "#f1ca93"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Status Toast
                    Text {
                        text: riceWindow.statusMsg
                        color: hasUnappliedChanges ? "#f1ca93" : "#8ec07c"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        visible: riceWindow.statusMsg !== ""
                    }
                }

                // ── UNAPPLIED CHANGES WARNING BANNER ──
                Rectangle {
                    visible: hasUnappliedChanges
                    Layout.fillWidth: true; height: 30; radius: 6
                    color: rootBar ? rootBar.alphaColor(rootBar._yel, 0.22) : "#382e1e"
                    border.color: rootBar ? rootBar._yel : "#f1ca93"; border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8
                        Text { text: "⚠️"; font.pixelSize: 12 }
                        Text {
                            text: "Unapplied Changes Pending! Click [APPLY CHANGES] to apply to your desktop."
                            color: rootBar ? rootBar._yel : "#f1ca93"
                            font.pixelSize: 10; font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 110; height: 22; radius: 4; color: rootBar ? rootBar._yel : "#f1ca93"
                            Text { anchors.centerIn: parent; text: "APPLY CHANGES"; color: "#181628"; font.pixelSize: 9; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.applyAllChanges() }
                        }
                    }
                }

                // Sub-Tab Navigation
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "#1e1e2e"
                    radius: 6
                    clip: true

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: ["Layout & Applets", "Style & Hardware", "Modules & Ordering", "Auto-Hide"]
                            delegate: Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                color: activeTab === index ? (rootBar ? rootBar.alphaColor(rootBar._cyn, 0.25) : "#31748f") : "transparent"
                                border.color: activeTab === index ? (rootBar ? rootBar._cyn : "#9bced7") : "transparent"
                                border.width: activeTab === index ? 1 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: activeTab === index ? (rootBar ? rootBar._cyn : "#9bced7") : "#6e6a86"
                                    font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: activeTab === index
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        activeTab = index;
                                        activeCategory = index;
                                    }
                                }
                            }
                        }
                    }
                }

                // Form Content Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#141320"
                    border.color: "#2a283e"
                    border.width: 1
                    radius: 8
                    clip: true

                    ScrollView {
                        id: formScroll
                        anchors.fill: parent
                        anchors.margins: 14
                        clip: true

                        Column {
                            id: formColumn
                            width: formScroll.width - 24
                            spacing: 16

                            // ═════════════════════════════════════════════════
                            // ── TAB 0: LAYOUT & APPLETS ──────────────────────
                            // ═════════════════════════════════════════════════
                            Column {
                                width: parent.width; spacing: 14; visible: activeTab === 0

                                Text { text: "💻  Active Bar / Theme Selection (18 Bars)"; color: "#f1ca93"; font.pixelSize: 11; font.bold: true }

                                // FIXED 18-BAR GRID LAYOUT (Explicit widths prevent text overlapping)
                                Grid {
                                    columns: 6
                                    columnSpacing: 6
                                    rowSpacing: 6
                                    width: parent.width

                                    Repeater {
                                        model: ThemeManager.availableThemes
                                        delegate: Rectangle {
                                            width: Math.max(95, Math.floor((formColumn.width - 35) / 6))
                                            height: 32
                                            radius: 6
                                            color: pendingThemeName === modelData ? (rootBar ? rootBar._cyn : "#9bced7") : (barMouse.containsMouse ? "#2a283e" : "#1e1e2e")
                                            border.color: pendingThemeName === modelData ? "#ffffff" : "#2a283e"
                                            border.width: pendingThemeName === modelData ? 1.5 : 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: pendingThemeName === modelData ? "#181628" : "#e0def4"
                                                font.pixelSize: 10
                                                font.bold: pendingThemeName === modelData
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                id: barMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    pendingThemeName = modelData;
                                                    riceWindow.markChanged("Active Bar set to: " + modelData);
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: "#2a283e" }

                                Text { text: "📐  Bar Dimensions & Shape (Sliders)"; color: "#f1ca93"; font.pixelSize: 11; font.bold: true }

                                // Corner Radius Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Corner Radius:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingRadius + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 0; to: 30; stepSize: 1
                                        value: pendingRadius
                                        onMoved: { pendingRadius = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }

                                // Bar Height Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Bar Height:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingHeight + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 24; to: 64; stepSize: 2
                                        value: pendingHeight
                                        onMoved: { pendingHeight = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }

                                // Bar Width Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Bar Width (%):"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: Math.round(pendingWidthPct * 100) + " %"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 50; to: 100; stepSize: 1
                                        value: Math.round(pendingWidthPct * 100)
                                        onMoved: { pendingWidthPct = Math.round(value) / 100; riceWindow.markChanged(); }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: "#2a283e" }

                                Text { text: "󰈈  Applet Size & Position Sliders"; color: "#f1ca93"; font.pixelSize: 11; font.bold: true }

                                Row {
                                    width: parent.width
                                    Text { text: "Use Custom Applet Size"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 80; height: 26; radius: 4; color: pendingCustomAppletSize ? "#8ec07c" : "#2a283e"
                                        Text { anchors.centerIn: parent; text: pendingCustomAppletSize ? "ON" : "OFF"; color: pendingCustomAppletSize ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                pendingCustomAppletSize = !pendingCustomAppletSize;
                                                riceWindow.markChanged();
                                            }
                                        }
                                    }
                                }

                                // Applet Width Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Applet Width:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingAppletW + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 240; to: 650; stepSize: 10
                                        value: pendingAppletW
                                        onMoved: { pendingAppletW = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }

                                // Applet Height Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Applet Height:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingAppletH + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 240; to: 750; stepSize: 10
                                        value: pendingAppletH
                                        onMoved: { pendingAppletH = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }

                                // Applet Custom X Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Custom Position X:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingAppletX + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 0; to: Math.max(800, riceWindow.screen.width - 200); stepSize: 10
                                        value: pendingAppletX
                                        onMoved: { pendingAppletX = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }

                                // Applet Custom Y Slider
                                Column {
                                    width: parent.width; spacing: 4
                                    Row {
                                        width: parent.width
                                        Text { text: "Custom Position Y:"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        Item { width: 10 }
                                        Text { text: pendingAppletY + " px"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 10; font.bold: true }
                                    }
                                    Slider {
                                        width: parent.width; from: 0; to: Math.max(600, riceWindow.screen.height - 200); stepSize: 10
                                        value: pendingAppletY
                                        onMoved: { pendingAppletY = Math.round(value); riceWindow.markChanged(); }
                                    }
                                }
                            }

                            // ═════════════════════════════════════════════════
                            // ── TAB 1: STYLE & HARDWARE ──────────────────────
                            // ═════════════════════════════════════════════════
                            Column {
                                width: parent.width; spacing: 14; visible: activeTab === 1

                                Row {
                                    width: parent.width
                                    Text { text: "Active Border Gradient Mode"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 270 }
                                    Rectangle {
                                        width: 140; height: 26; radius: 4
                                        color: pendingGradientAnimated ? (rootBar ? rootBar._cyn : "#9bced7") : "#2a283e"
                                        border.color: pendingGradientAnimated ? "#ffffff" : "#9bced7"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: pendingGradientAnimated ? "󰔡  ANIMATED (SLOW)" : "󰏘  STATIC (45°)"
                                            color: pendingGradientAnimated ? "#181628" : "#e0def4"
                                            font.pixelSize: 9; font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                pendingGradientAnimated = !pendingGradientAnimated;
                                                riceWindow.markChanged();
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Saved Master Volume (" + Math.round(CentralConfig.volValue * 100) + "%)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        Text { anchors.centerIn: parent; text: Math.round(CentralConfig.volValue * 100) + "%"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 11; font.bold: true }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Saved Screen Brightness (" + Math.round(CentralConfig.brightnessValue * 100) + "%)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        Text { anchors.centerIn: parent; text: Math.round(CentralConfig.brightnessValue * 100) + "%"; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 11; font.bold: true }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Custom Accent Hex"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 24; height: 24; radius: 12; color: pendingAccentHex; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Item { width: 6 }
                                    Rectangle {
                                        width: 100; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: pendingAccentHex
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 10; font.bold: true
                                            onTextChanged: { pendingAccentHex = text; riceWindow.markChanged(); }
                                        }
                                    }
                                }
                            }

                            // ═════════════════════════════════════════════════
                            // ── TAB 2: MODULES & ORDERING ────────────────────
                            // ═════════════════════════════════════════════════
                            Column {
                                width: parent.width
                                spacing: 12
                                visible: activeTab === 2

                                // Edit Mode OFF Warning Banner
                                Rectangle {
                                    visible: !CentralConfig.editMode
                                    width: parent.width; height: 32; radius: 6
                                    color: rootBar ? rootBar.alphaColor(rootBar._yel, 0.18) : "#382e1e"
                                    border.color: rootBar ? rootBar._yel : "#f1ca93"; border.width: 1

                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "⚠️"; font.pixelSize: 11 }
                                        Text {
                                            text: "Edit Mode is OFF. Editing any module will automatically enable Edit Mode!"
                                            color: rootBar ? rootBar._yel : "#f1ca93"
                                            font.pixelSize: 10; font.bold: true
                                        }
                                    }
                                }

                                // Duplicate Modules Active Warning Banner
                                Rectangle {
                                    property var activeDups: CentralConfig.getDuplicateModules()
                                    visible: activeDups.length > 0
                                    width: parent.width; height: 34; radius: 6
                                    color: "#42202b"
                                    border.color: "#ea6f91"; border.width: 1.5

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                        spacing: 8
                                        Text { text: "⚠️"; font.pixelSize: 12 }
                                        Text {
                                            text: "Duplicate Modules Active on Bar (" + activeDups.join(", ") + ")!"
                                            color: "#ea6f91"
                                            font.pixelSize: 10; font.bold: true
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            width: 120; height: 22; radius: 4; color: "#ea6f91"
                                            Text { anchors.centerIn: parent; text: "🧹 Clean Duplicates"; color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ensureEditMode();
                                                    CentralConfig.deduplicateModules();
                                                    riceWindow.showStatus("Removed all duplicate modules!");
                                                }
                                            }
                                        }
                                    }
                                }

                                // Presets Bar
                                Column {
                                    width: parent.width; spacing: 6
                                    Text { text: "󰆓  Quick Presets:"; color: "#9bced7"; font.pixelSize: 10; font.bold: true }

                                    Row {
                                        spacing: 8
                                        width: parent.width

                                        Rectangle {
                                            width: 100; height: 26; radius: 6; color: "#2a283e"; border.color: "#9bced7"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Emilia Original"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("emilia_default", "Emilia Original"); } }
                                        }

                                        Rectangle {
                                            width: 95; height: 26; radius: 6; color: "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Minimal Ricing"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("minimal", "Minimal Ricing"); } }
                                        }

                                        Rectangle {
                                            width: 100; height: 26; radius: 6; color: "#2a283e"; border.color: "#c3a5e6"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "System Monitor"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("sysmon", "System Monitor"); } }
                                        }

                                        Rectangle {
                                            width: 100; height: 26; radius: 6; color: "#2a283e"; border.color: "#8ec07c"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Full Powerhouse"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("full", "Full Powerhouse"); } }
                                        }

                                        // Save Custom Preset Button
                                        Rectangle {
                                            width: 120; height: 26; radius: 6; color: "#312a4a"; border.color: "#b4befe"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "💾 Save Custom Preset"; color: "#b4befe"; font.pixelSize: 9; font.bold: true }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    CentralConfig.saveCustomPreset();
                                                    riceWindow.showStatus("Saved active layout as Custom Preset!");
                                                }
                                            }
                                        }

                                        // Load Saved Custom Preset Button
                                        Rectangle {
                                            visible: CentralConfig.hasCustomPreset
                                            width: 90; height: 26; radius: 6; color: "#312a4a"; border.color: "#a6e3a1"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "⭐ My Preset"; color: "#a6e3a1"; font.pixelSize: 9; font.bold: true }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ensureEditMode();
                                                    riceWindow.requestPresetConfirmation("custom_user", "My Custom Preset");
                                                }
                                            }
                                        }
                                    }
                                }

                                // Module List
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    Repeater {
                                        model: [
                                            { key: "launcher", name: "Start Launcher", icon: "󰆍" },
                                            { key: "workspaces", name: "Workspaces Bar", icon: "󰮯" },
                                            { key: "title", name: "Active Window Title", icon: "󰈈" },
                                            { key: "pinnedApps", name: "Pinned Apps Module", icon: "󰅀" },
                                            { key: "song", name: "Media Player & Song Title", icon: "󰎈" },
                                            { key: "updates", name: "Updates Badge", icon: "󰚰" },
                                            { key: "disk", name: "Disk Usage Badge", icon: "󰋊" },
                                            { key: "cpu", name: "CPU Load Badge", icon: "󰍛" },
                                            { key: "ram", name: "RAM Usage Badge", icon: "󰟜" },
                                            { key: "gpu", name: "GPU Usage Badge", icon: "󰢮" },
                                            { key: "temp", name: "Temperature Badge", icon: "󰔏" },
                                            { key: "volume", name: "Volume Control Badge", icon: "󰕾" },
                                            { key: "brightness", name: "Brightness Control", icon: "󰃠" },
                                            { key: "network", name: "Network/Wifi Badge", icon: "󰤨" },
                                            { key: "bluetooth", name: "Bluetooth Badge", icon: "󰂯" },
                                            { key: "battery", name: "Battery Badge", icon: "󰁹" },
                                            { key: "weather", name: "Weather Widget", icon: "󰖕" },
                                            { key: "clock", name: "Clock & Date", icon: "󰥔" },
                                            { key: "tray", name: "System Tray Expander", icon: "󰅀" },
                                            { key: "settings", name: "Quick Settings Panel", icon: "󰒓" },
                                            { key: "theme", name: "Theme Selector", icon: "󰏘" },
                                            { key: "mode_switcher", name: "Dark / Light / Auto Mode", icon: "󰔎" },
                                            { key: "wallpaper", name: "Wallpaper Picker", icon: "󰸉" },
                                            { key: "colorpicker", name: "Color Picker Tool", icon: "󰃉" },
                                            { key: "power", name: "Power Button", icon: "󰐥" }
                                        ]
                                        delegate: Rectangle {
                                            width: parent.width
                                            height: hasSubOpts ? 58 : 34
                                            radius: 6
                                            color: "#1e1e2e"
                                            clip: true

                                            property bool isHidden: zoneRow.currentZone === "hidden"
                                            property bool hasSubOpts: !isHidden && (modelData.key === "title" || modelData.key === "song")
                                            property int dupCount: CentralConfig.getModuleCount(modelData.key)

                                            Column {
                                                anchors.fill: parent
                                                spacing: 0

                                                // Row 1: Module Info & Zone Controls
                                                Item {
                                                    width: parent.width; height: 34

                                                    Row {
                                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                                        spacing: 8

                                                        Text { text: modelData.icon; color: rootBar ? rootBar._cyn : "#9bced7"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                        Text { text: modelData.name; color: "#e0def4"; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }

                                                        // Index Position Badge
                                                        Rectangle {
                                                            property int modIdx: CentralConfig.getModuleIndex(modelData.key)
                                                            visible: modIdx !== -1
                                                            width: 24; height: 18; radius: 4; color: "#2a283e"
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            Text { anchors.centerIn: parent; text: "#" + (parent.modIdx + 1); color: "#f1ca93"; font.pixelSize: 9; font.bold: true }
                                                        }

                                                        // Duplicate Warning Badge (if active > 1 times)
                                                        Rectangle {
                                                            visible: dupCount > 1
                                                            width: 64; height: 18; radius: 4; color: "#42202b"
                                                            border.color: "#ea6f91"; border.width: 1
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            Text { anchors.centerIn: parent; text: "⚠️ " + dupCount + "x Active"; color: "#ea6f91"; font.pixelSize: 8; font.bold: true }
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        Row {
                                                            id: zoneRow
                                                            spacing: 4
                                                            anchors.verticalCenter: parent.verticalCenter

                                                            property string currentZone: CentralConfig.getZone(modelData.key)

                                                            // Re-order Left Button (◄)
                                                            Rectangle {
                                                                width: 22; height: 22; radius: 4
                                                                color: parent.currentZone !== "hidden" ? "#2a283e" : "#141320"
                                                                visible: parent.currentZone !== "hidden"
                                                                Text { anchors.centerIn: parent; text: "◄"; color: "#9bced7"; font.pixelSize: 10 }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.moveModule(modelData.key, "left"); riceWindow.showStatus("Moved " + modelData.key + " ◄ Left"); } }
                                                            }

                                                            // Re-order Right Button (►)
                                                            Rectangle {
                                                                width: 22; height: 22; radius: 4
                                                                color: parent.currentZone !== "hidden" ? "#2a283e" : "#141320"
                                                                visible: parent.currentZone !== "hidden"
                                                                Text { anchors.centerIn: parent; text: "►"; color: "#9bced7"; font.pixelSize: 10 }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.moveModule(modelData.key, "right"); riceWindow.showStatus("Moved " + modelData.key + " ► Right"); } }
                                                            }

                                                            Item { width: 4 }

                                                            // Left Zone Button
                                                            Rectangle {
                                                                width: 44; height: 22; radius: 4
                                                                color: parent.currentZone === "left" ? "#9bced7" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Left"; color: parent.parent.currentZone === "left" ? "#181628" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.requestZoneChange(modelData.key, modelData.name, "left") }
                                                            }

                                                            // Center Zone Button
                                                            Rectangle {
                                                                width: 50; height: 22; radius: 4
                                                                color: parent.currentZone === "center" ? "#f1ca93" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Center"; color: parent.parent.currentZone === "center" ? "#181628" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.requestZoneChange(modelData.key, modelData.name, "center") }
                                                            }

                                                            // Right Zone Button
                                                            Rectangle {
                                                                width: 44; height: 22; radius: 4
                                                                color: parent.currentZone === "right" ? "#c3a5e6" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Right"; color: parent.parent.currentZone === "right" ? "#181628" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.requestZoneChange(modelData.key, modelData.name, "right") }
                                                            }

                                                            // Hidden Button
                                                            Rectangle {
                                                                width: 48; height: 22; radius: 4
                                                                color: parent.currentZone === "hidden" ? "#ea6f91" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Hidden"; color: parent.parent.currentZone === "hidden" ? "#ffffff" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.setZone(modelData.key, "hidden"); riceWindow.showStatus("Set " + modelData.key + " -> HIDDEN"); } }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Row 2: Inline Sub-Component Options Row (Cleanly placed below Row 1)
                                                Item {
                                                    visible: hasSubOpts
                                                    width: parent.width
                                                    height: 24

                                                    Row {
                                                        anchors.left: parent.left; anchors.leftMargin: 32
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 16

                                                        // Title Sub-Options
                                                        Row {
                                                            visible: modelData.key === "title"
                                                            spacing: 12

                                                            Row {
                                                                spacing: 4
                                                                Rectangle {
                                                                    width: 14; height: 14; radius: 3; color: CentralConfig.showTitleLogo ? "#9bced7" : "#2a283e"; border.color: "#9bced7"; border.width: 1
                                                                    Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showTitleLogo; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showTitleLogo = !CentralConfig.showTitleLogo }
                                                                }
                                                                Text { text: "App Icon"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                            }

                                                            Row {
                                                                spacing: 4
                                                                Rectangle {
                                                                    width: 14; height: 14; radius: 3; color: CentralConfig.showTitleAppName ? "#9bced7" : "#2a283e"; border.color: "#9bced7"; border.width: 1
                                                                    Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showTitleAppName; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showTitleAppName = !CentralConfig.showTitleAppName }
                                                                }
                                                                Text { text: "App Name (Class)"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                            }

                                                            Row {
                                                                spacing: 4
                                                                Rectangle {
                                                                    width: 14; height: 14; radius: 3; color: CentralConfig.showTitleWindowName ? "#9bced7" : "#2a283e"; border.color: "#9bced7"; border.width: 1
                                                                    Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showTitleWindowName; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showTitleWindowName = !CentralConfig.showTitleWindowName }
                                                                }
                                                                Text { text: "Window Title"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                            }
                                                        }

                                                        // Song Sub-Options
                                                        Row {
                                                            visible: modelData.key === "song"
                                                            spacing: 12

                                                            Row {
                                                                spacing: 4
                                                                Rectangle {
                                                                    width: 14; height: 14; radius: 3; color: CentralConfig.showSongCoverArt ? "#f1ca93" : "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                                                    Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showSongCoverArt; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showSongCoverArt = !CentralConfig.showSongCoverArt }
                                                                }
                                                                Text { text: "App Logo & Cover Art"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                            }

                                                            Row {
                                                                spacing: 4
                                                                Rectangle {
                                                                    width: 14; height: 14; radius: 3; color: CentralConfig.showSongArtist ? "#f1ca93" : "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                                                    Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showSongArtist; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showSongArtist = !CentralConfig.showSongArtist }
                                                                }
                                                                Text { text: "Artist Name"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ═════════════════════════════════════════════════
                            // ── TAB 3: AUTO-HIDE ─────────────────────────────
                            // ═════════════════════════════════════════════════
                            Column {
                                width: parent.width; spacing: 14; visible: activeTab === 3

                                Row {
                                    width: parent.width
                                    Text { text: "Auto-Hide Bar"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 80; height: 26; radius: 4; color: pendingAutoHide ? (rootBar ? rootBar._cyn : "#9bced7") : "#2a283e"
                                        Text { anchors.centerIn: parent; text: pendingAutoHide ? "ON" : "OFF"; color: pendingAutoHide ? "#181628" : "#6e6a86"; font.pixelSize: 10; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                pendingAutoHide = !pendingAutoHide;
                                                riceWindow.markChanged();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Preset Confirmation Modal
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: confirmModalOpen

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            Rectangle {
                anchors.centerIn: parent
                width: 440; height: 200
                color: "#181628"
                border.color: "#ea6f91"
                border.width: 2
                radius: 12
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        spacing: 10
                        Text { text: "⚠️"; font.pixelSize: 22 }
                        Text { text: "Overwrite Current Layout?"; color: "#e0def4"; font.pixelSize: 14; font.bold: true }
                    }

                    Text {
                        text: "Applying preset '" + pendingPresetName + "' will overwrite your custom module layout configuration. Are you sure you want to proceed?"
                        color: "#908caa"
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 6
                            color: "#ea6f91"
                            Text { anchors.centerIn: parent; text: "Yes, Overwrite"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: riceWindow.confirmPresetOverwrite() }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 6
                            color: "#2a283e"; border.color: "#6e6a86"; border.width: 1
                            Text { anchors.centerIn: parent; text: "Cancel"; color: "#e0def4"; font.pixelSize: 11; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: confirmModalOpen = false }
                        }
                    }
                }
            }
        }
    }

    // ── DUPLICATE MODULE WARNING MODAL ──
    Rectangle {
        id: duplicateModalRect
        visible: duplicateModalOpen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        z: 99999

        MouseArea { anchors.fill: parent; onClicked: {} } // Block click-through

        Rectangle {
            width: 440; height: 190; radius: 10
            anchors.centerIn: parent
            color: "#1e1e2e"
            border.color: rootBar ? rootBar._yel : "#f1ca93"
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    spacing: 8
                    Text { text: "⚠️"; font.pixelSize: 18 }
                    Text {
                        text: "DUPLICATE MODULE WARNING"
                        color: rootBar ? rootBar._yel : "#f1ca93"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Text {
                    text: "The module '" + pendingDupName + "' is already present in your bar layout.\nAre you sure you want to add a duplicate instance to the " + pendingDupZone.toUpperCase() + " zone?"
                    color: "#e0def4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    // Cancel Button
                    Rectangle {
                        width: 100; height: 30; radius: 6
                        color: "#2a283e"
                        border.color: "#6e6a86"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Cancel"; color: "#e0def4"; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: duplicateModalOpen = false
                        }
                    }

                    // Add Duplicate Button
                    Rectangle {
                        width: 150; height: 30; radius: 6
                        color: rootBar ? rootBar._yel : "#f1ca93"
                        Text { anchors.centerIn: parent; text: "➕ Add Duplicate"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ensureEditMode();
                                CentralConfig.setZone(pendingDupKey, pendingDupZone, true);
                                riceWindow.showStatus("Added duplicate " + pendingDupKey + " -> " + pendingDupZone.toUpperCase());
                                duplicateModalOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
