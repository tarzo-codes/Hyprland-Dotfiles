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

    // Transparent window background so the bar and desktop are completely clear and unobscured
    color: "transparent"

    property var colors: null
    property var rootBar: null
    signal closeRequested()

    property int activeCategory: 0
    property int activeTab: 0

    property int tempRadius: CentralConfig.barRadius
    property int tempHeight: CentralConfig.barHeight
    property real tempWidthPct: CentralConfig.barWidthPercent
    property int tempFontSize: CentralConfig.globalFontSize
    property int tempAppletW: CentralConfig.appletWidth
    property int tempAppletH: CentralConfig.appletHeight
    property int tempAppletX: CentralConfig.appletCustomX
    property int tempAppletY: CentralConfig.appletCustomY
    property string tempAccentHex: CentralConfig.customAccentColor !== "" ? CentralConfig.customAccentColor : (rootBar ? rootBar._cyn : "#9bced7")
    property string statusMsg: ""

    // Confirmation Modal Properties
    property bool confirmModalOpen: false
    property string pendingPresetId: ""
    property string pendingPresetName: ""

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
        interval: 2500
        onTriggered: statusMsg = ""
    }

    function showStatus(msg) {
        statusMsg = msg;
        statusTimer.restart();
    }

    function ensureEditMode() {
        if (!CentralConfig.editMode) {
            CentralConfig.editMode = true;
            showStatus("Edit Mode Activated! Live bar unlocked for editing.");
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
        width: 880
        height: 640
        color: rootBar ? rootBar._bg : "#161622"
        border.color: rootBar ? rootBar._acc : "#31748f"
        border.width: 1.5
        radius: 14
        clip: true

        // Prevent clicks inside editor from closing window
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        scale: 0.94
        opacity: 0
        Component.onCompleted: {
            scale = 1.0;
            opacity = 1.0;
        }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ═════════════════════════════════════════════════════════════════
            // ── LEFT SIDEBAR NAVIGATION ─────────────────────────────────────
            // ═════════════════════════════════════════════════════════════════
            Rectangle {
                Layout.preferredWidth: 220
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
                            MouseArea { id: c0Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: activeCategory = 0 }
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
                            MouseArea { id: c1Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: activeCategory = 1 }
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
                            MouseArea { id: c2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: activeCategory = 2 }
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
                            MouseArea { id: c3Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: activeCategory = 3 }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Save Config Button
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 6
                        color: "#9bced7"
                        Text { anchors.centerIn: parent; text: "󰆓 Save Central Config"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: riceWindow.showStatus("Saved to ~/.config/quickshell/config/!")
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
                spacing: 12

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
                        text: CentralConfig.themeName
                        color: rootBar ? rootBar._yel : "#f1ca93"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: riceWindow.statusMsg
                        color: "#8ec07c"
                        font.family: rootBar ? rootBar.globalFontFamily : "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        visible: riceWindow.statusMsg !== ""
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
                        anchors.fill: parent
                        anchors.margins: 14
                        clip: true

                        Column {
                            width: parent.width - 10
                            spacing: 14

                            // ════ TAB 0: LAYOUT & APPLETS ════
                            Column {
                                width: parent.width; spacing: 12; visible: activeTab === 0

                                Text { text: "󰍹  Active Bar / Theme Selection (18 Bars)"; color: "#f1ca93"; font.pixelSize: 11; font.bold: true }

                                Flow {
                                    width: parent.width
                                    spacing: 6

                                    Repeater {
                                        model: ThemeManager.availableThemes
                                        delegate: Rectangle {
                                            width: (parent.width - 24) / 4
                                            height: 28
                                            radius: 6
                                            color: ThemeManager.themeName === modelData ? (rootBar ? rootBar._cyn : "#9bced7") : (barMouse.containsMouse ? "#2a283e" : "#1e1e2e")
                                            border.color: ThemeManager.themeName === modelData ? "#ffffff" : "#2a283e"
                                            border.width: ThemeManager.themeName === modelData ? 1.5 : 1

                                            Row {
                                                anchors.centerIn: parent; spacing: 4
                                                Text {
                                                    text: modelData
                                                    color: ThemeManager.themeName === modelData ? "#181628" : "#e0def4"
                                                    font.pixelSize: 10
                                                    font.bold: ThemeManager.themeName === modelData
                                                }
                                            }

                                            MouseArea {
                                                id: barMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ThemeManager.themeName = modelData;
                                                    CentralConfig.themeName = modelData;
                                                    riceWindow.showStatus("Switched to Active Bar: " + modelData.toUpperCase());
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: "#2a283e" }

                                Row {
                                    width: parent.width
                                    Text { text: "Corner Radius (" + CentralConfig.barRadius + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempRadius.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempRadius = Math.max(0, Math.min(20, parseInt(text) || 0))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.barRadius = tempRadius; riceWindow.showStatus("Saved Radius: " + tempRadius + "px"); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Bar Height (" + CentralConfig.barHeight + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempHeight.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempHeight = Math.max(32, Math.min(64, parseInt(text) || 40))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.barHeight = tempHeight; if (rootBar) rootBar.barHeight = tempHeight; riceWindow.showStatus("Saved Height: " + tempHeight + "px"); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Bar Width (" + Math.round(CentralConfig.barWidthPercent * 100) + "%)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: Math.round(tempWidthPct * 100).toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempWidthPct = Math.max(0.5, Math.min(1.0, (parseInt(text) || 96) / 100))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.barWidthPercent = tempWidthPct; if (rootBar) rootBar.barWidthPercent = tempWidthPct; riceWindow.showStatus("Saved Width: " + Math.round(tempWidthPct * 100) + "%"); } }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: "#2a283e" }

                                Text { text: "󰈈  Applet Size & Custom Position"; color: "#f1ca93"; font.pixelSize: 11; font.bold: true }

                                Row {
                                    width: parent.width
                                    Text { text: "Use Custom Applet Size"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 80; height: 26; radius: 4; color: CentralConfig.useCustomAppletSize ? "#8ec07c" : "#2a283e"
                                        Text { anchors.centerIn: parent; text: CentralConfig.useCustomAppletSize ? "ON" : "OFF"; color: CentralConfig.useCustomAppletSize ? "#181628" : "#e0def4"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.useCustomAppletSize = !CentralConfig.useCustomAppletSize; riceWindow.showStatus("Custom Applet Size " + (CentralConfig.useCustomAppletSize ? "ON" : "OFF")); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Applet Width (" + CentralConfig.appletWidth + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempAppletW.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempAppletW = Math.max(240, Math.min(600, parseInt(text) || 340))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.appletWidth = tempAppletW; riceWindow.showStatus("Saved Applet Width: " + tempAppletW + "px"); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Applet Height (" + CentralConfig.appletHeight + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempAppletH.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempAppletH = Math.max(240, Math.min(700, parseInt(text) || 440))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.appletHeight = tempAppletH; riceWindow.showStatus("Saved Applet Height: " + tempAppletH + "px"); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Custom Position X (" + CentralConfig.appletCustomX + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempAppletX.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempAppletX = Math.max(0, Math.min(1920, parseInt(text) || 100))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.appletCustomX = tempAppletX; riceWindow.showStatus("Saved Custom X: " + tempAppletX + "px"); } }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text { text: "Custom Position Y (" + CentralConfig.appletCustomY + "px)"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 70; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempAppletY.toString()
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 11; font.bold: true
                                            onTextChanged: tempAppletY = Math.max(0, Math.min(1080, parseInt(text) || 100))
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.appletCustomY = tempAppletY; riceWindow.showStatus("Saved Custom Y: " + tempAppletY + "px"); } }
                                    }
                                }
                            }

                            // ════ TAB 1: STYLE & HARDWARE SAVED VALUES ════
                            Column {
                                width: parent.width; spacing: 12; visible: activeTab === 1

                                Row {
                                    width: parent.width
                                    Text { text: "Active Border Gradient Mode"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 270 }
                                    Rectangle {
                                        width: 140; height: 26; radius: 4
                                        color: CentralConfig.gradientAnimated ? (rootBar ? rootBar._cyn : "#9bced7") : "#2a283e"
                                        border.color: CentralConfig.gradientAnimated ? "#ffffff" : "#9bced7"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: CentralConfig.gradientAnimated ? "󰔡  ANIMATED (SLOW)" : "󰏘  STATIC (45°)"
                                            color: CentralConfig.gradientAnimated ? "#181628" : "#e0def4"
                                            font.pixelSize: 9; font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                CentralConfig.gradientAnimated = !CentralConfig.gradientAnimated;
                                                if (CentralConfig.gradientAnimated) {
                                                    toggleGradientAnimProc.animCmd = "borderangle, 1, 250, linear, loop";
                                                    riceWindow.showStatus("Border Gradient: Animated Slow Flow");
                                                } else {
                                                    toggleGradientAnimProc.animCmd = "borderangle, 0, 1, default";
                                                    riceWindow.showStatus("Border Gradient: Static (45°)");
                                                }
                                                toggleGradientAnimProc.running = false;
                                                toggleGradientAnimProc.running = true;
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
                                        width: 24; height: 24; radius: 12; color: tempAccentHex; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Item { width: 6 }
                                    Rectangle {
                                        width: 90; height: 26; radius: 4; color: "#2a283e"; border.color: rootBar ? rootBar._cyn : "#9bced7"; border.width: 1
                                        TextInput {
                                            anchors.centerIn: parent
                                            text: tempAccentHex
                                            color: rootBar ? rootBar._cyn : "#9bced7"
                                            font.pixelSize: 10; font.bold: true
                                            onTextChanged: tempAccentHex = text
                                        }
                                    }
                                    Item { width: 8 }
                                    Rectangle {
                                        width: 50; height: 26; radius: 4; color: rootBar ? rootBar._cyn : "#9bced7"
                                        Text { anchors.centerIn: parent; text: "Apply"; color: "#181628"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.customAccentColor = tempAccentHex; riceWindow.showStatus("Applied Accent"); } }
                                    }
                                }
                            }

                            // ════ TAB 2: MODULES & ORDERING ════
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

                                // Presets Bar
                                Column {
                                    width: parent.width; spacing: 6
                                    Text { text: "󰆓  Quick Presets:"; color: "#9bced7"; font.pixelSize: 10; font.bold: true }

                                    Row {
                                        spacing: 8
                                        width: parent.width

                                        Rectangle {
                                            width: 110; height: 26; radius: 6; color: "#2a283e"; border.color: "#9bced7"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Emilia Original"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("emilia_default", "Emilia Original"); } }
                                        }

                                        Rectangle {
                                            width: 110; height: 26; radius: 6; color: "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Minimal Ricing"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("minimal", "Minimal Ricing"); } }
                                        }

                                        Rectangle {
                                            width: 110; height: 26; radius: 6; color: "#2a283e"; border.color: "#c3a5e6"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "System Monitor"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("sysmon", "System Monitor"); } }
                                        }

                                        Rectangle {
                                            width: 110; height: 26; radius: 6; color: "#2a283e"; border.color: "#8ec07c"; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Full Powerhouse"; color: "#e0def4"; font.pixelSize: 9; font.bold: true }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); riceWindow.requestPresetConfirmation("full", "Full Powerhouse"); } }
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
                                            { key: "media", name: "Media Controls", icon: "󰎈" },
                                            { key: "song", name: "Song Title Card", icon: "󰓇" },
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
                                            height: hasSubOpts ? 62 : 34
                                            radius: 6
                                            color: "#1e1e2e"
                                            clip: true

                                            property bool isHidden: zoneRow.currentZone === "hidden"
                                            property bool hasSubOpts: !isHidden && (modelData.key === "title" || modelData.key === "song" || modelData.key === "media")

                                            Column {
                                                anchors.fill: parent
                                                spacing: 4

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

                                                        Item { width: parent.width - 240 - zoneRow.implicitWidth }

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
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.setZone(modelData.key, "left"); riceWindow.showStatus("Set " + modelData.key + " -> LEFT"); } }
                                                            }

                                                            // Center Zone Button
                                                            Rectangle {
                                                                width: 50; height: 22; radius: 4
                                                                color: parent.currentZone === "center" ? "#f1ca93" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Center"; color: parent.parent.currentZone === "center" ? "#181628" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.setZone(modelData.key, "center"); riceWindow.showStatus("Set " + modelData.key + " -> CENTER"); } }
                                                            }

                                                            // Right Zone Button
                                                            Rectangle {
                                                                width: 44; height: 22; radius: 4
                                                                color: parent.currentZone === "right" ? "#c3a5e6" : "#2a283e"
                                                                Text { anchors.centerIn: parent; text: "Right"; color: parent.parent.currentZone === "right" ? "#181628" : "#6e6a86"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ensureEditMode(); CentralConfig.setZone(modelData.key, "right"); riceWindow.showStatus("Set " + modelData.key + " -> RIGHT"); } }
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

                                                // Inline Sub-Component Options Row (ONLY SHOWN WHEN NOT HIDDEN!)
                                                Row {
                                                    visible: parent.parent.hasSubOpts
                                                    height: 22
                                                    anchors.left: parent.left; anchors.leftMargin: 28
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

                                                    // Song / Media Sub-Options
                                                    Row {
                                                        visible: modelData.key === "song" || modelData.key === "media"
                                                        spacing: 12

                                                        Row {
                                                            spacing: 4
                                                            Rectangle {
                                                                width: 14; height: 14; radius: 3; color: CentralConfig.showSongEqualizer ? "#f1ca93" : "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                                                Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showSongEqualizer; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showSongEqualizer = !CentralConfig.showSongEqualizer }
                                                            }
                                                            Text { text: "Equalizer Bars"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                        }

                                                        Row {
                                                            spacing: 4
                                                            Rectangle {
                                                                width: 14; height: 14; radius: 3; color: CentralConfig.showSongCoverArt ? "#f1ca93" : "#2a283e"; border.color: "#f1ca93"; border.width: 1
                                                                Text { anchors.centerIn: parent; text: "✓"; visible: CentralConfig.showSongCoverArt; color: "#181628"; font.pixelSize: 9; font.bold: true }
                                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: CentralConfig.showSongCoverArt = !CentralConfig.showSongCoverArt }
                                                            }
                                                            Text { text: "Album Cover Art"; color: "#e0def4"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
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

                            // ════ TAB 3: AUTO-HIDE ════
                            Column {
                                width: parent.width; spacing: 14; visible: activeTab === 3

                                Row {
                                    width: parent.width
                                    Text { text: "Auto-Hide Bar"; color: "#e0def4"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: parent.width - 240 }
                                    Rectangle {
                                        width: 80; height: 26; radius: 4; color: CentralConfig.autoHideBar ? (rootBar ? rootBar._cyn : "#9bced7") : "#2a283e"
                                        Text { anchors.centerIn: parent; text: CentralConfig.autoHideBar ? "ON" : "OFF"; color: CentralConfig.autoHideBar ? "#181628" : "#6e6a86"; font.pixelSize: 10; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { CentralConfig.autoHideBar = !CentralConfig.autoHideBar; riceWindow.showStatus(CentralConfig.autoHideBar ? "Auto-Hide ON" : "Auto-Hide OFF"); } }
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
}
