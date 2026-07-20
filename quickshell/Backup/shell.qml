// Quickshell Bar - Multi-monitor support with modular widget system
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets
import "themes"

// Main container for multi-monitor support
Repeater {
    model: Quickshell.screens

    delegate: PanelWindow {
        WlrLayershell.layer: WlrLayer.Top
        screen: modelData

        // 1. FIX WHITE BOX: Make the window background transparent
        color: "transparent"

        // Bar dimensions (extends when menu is open so QML has room to render the popup)
        implicitHeight: powerMenuVisible ? 140 : 40
        implicitWidth: screen.width

        // 2. FIX WINDOW SHIFTING: Keep exclusiveZone fixed at 40 so desktop windows never jump
        exclusiveZone: 40

        anchors {
            top: true
            left: true
            right: true
        }

        // Window type hint for Hyprland
        WlrLayershell.namespace: "quickshell-bar"

        property var colors: ThemeManager.getCurrentColors()

        // ... [Your existing Process blocks stay unchanged] ...

        property bool powerMenuVisible: false

        // ... [Your existing moduleComponent function stays unchanged] ...

        // ============================================================
        // 3. FIX BAR STRETCHING: Anchor to top and lock height to 40
        // ============================================================
        Rectangle {
            id: barBackground
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            radius: colors.radius
            color: colors.background
            border.color: colors.accent
            border.width: colors.borderWidth
        }

        // ============================================================
        // Bar content
        // ============================================================
        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 7
            height: 26
            spacing: 6

            // Left modules (Emilia style)
            Repeater {
                model: colors.leftModules || []
                delegate: Loader { sourceComponent: moduleComponent(modelData) }
            }
            Item { Layout.fillWidth: true }
            // Center modules (workspaces)
            Repeater {
                model: colors.centerModules || []
                delegate: Loader { sourceComponent: moduleComponent(modelData) }
            }
            Item { Layout.fillWidth: true }
            // Right modules (excluding power which is separate)
            Repeater {
                model: colors.rightModules || []
                delegate: Loader { 
                    sourceComponent: modelData !== "power" ? moduleComponent(modelData) : null
                }
            }
        }

        // ============================================================
        // 4. FIX BUTTON JUMPING: Anchor to barBackground instead of parent
        // ============================================================
        Rectangle {
            id: powerButtonRect
            anchors.verticalCenter: barBackground.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            width: 26; height: 26; radius: 6
            color: powerHover.containsMouse ? colors.accent : colors.background
            border.color: colors.accent
            border.width: 1
            z: 10
            Text {
                anchors.centerIn: parent
                text: ""
                color: powerHover.containsMouse ? colors.foreground : colors.accent
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
            }
            MouseArea {
                id: powerHover
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: powerMenuVisible = !powerMenuVisible
            }
        }

        // ============================================================
        // Power menu popup
        // ============================================================
        Rectangle {
            id: powerMenuPopup
            anchors.top: powerButtonRect.bottom
            anchors.topMargin: 4
            anchors.right: powerButtonRect.right
            width: 120
            height: 95
            visible: powerMenuVisible
            color: colors.background
            radius: 8
            border.color: colors.accent
            border.width: 1
            z: 999

            // ... [Rest of your powerMenuPopup ColumnLayout stays unchanged] ...

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 4
                    color: msh.containsMouse ? colors.accent : colors.background
                    Text {
                        anchors.centerIn: parent
                        text: " Shutdown"
                        color: msh.containsMouse ? colors.foreground : colors.accent
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    MouseArea {
                        id: msh
                        anchors.fill: parent
                        onClicked: {
                            powerMenuVisible = false
                            shutdownProcess.running = true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 4
                    color: mrh.containsMouse ? colors.accent : colors.background
                    Text {
                        anchors.centerIn: parent
                        text: " Reboot"
                        color: mrh.containsMouse ? colors.foreground : colors.accent
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    MouseArea {
                        id: mrh
                        anchors.fill: parent
                        onClicked: {
                            powerMenuVisible = false
                            rebootProcess.running = true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 4
                    color: mlh.containsMouse ? colors.accent : colors.background
                    Text {
                        anchors.centerIn: parent
                        text: " Logout"
                        color: mlh.containsMouse ? colors.foreground : colors.accent
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    MouseArea {
                        id: mlh
                        anchors.fill: parent
                        onClicked: {
                            powerMenuVisible = false
                            logoutProcess.running = true
                        }
                    }
                }
            }
        }

        // ============================================================
        // Module components
        // ============================================================
        Component { id: compLauncher; Rectangle { width: 36; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: launcherProcess.running = true } } }
        Component { id: compTitle; Text { text: Hyprland.activeWindow?.title ?? ""; color: colors.textMuted; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideMiddle; Layout.maximumWidth: 220; Layout.fillWidth: true; visible: text !== "" } }
        Component { id: compWorkspaces; Row { spacing: 2; Repeater { model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; delegate: Rectangle { width: 22; height: 22; radius: 11; color: Hyprland.activeWorkspace?.id === modelData ? colors.accent : colors.background; Text { anchors.centerIn: parent; text: modelData; color: Hyprland.activeWorkspace?.id === modelData ? colors.foreground : colors.textMuted; font.pixelSize: 11; font.bold: Hyprland.activeWorkspace?.id === modelData; font.family: "JetBrainsMono Nerd Font" } MouseArea { anchors.fill: parent; onClicked: Hyprland.focusWorkspace(modelData) } } } } }
        Component { id: compStyleSwitch; Rectangle { width: 36; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cycleStyle() } } }
        Component { id: compAudio; Rectangle { width: 65; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; visible: Pipewire.defaultAudioSink != null; RowLayout { anchors.centerIn: parent; spacing: 4; Text { text: Pipewire.defaultAudioSink?.mute ? "" : ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" } Text { text: Pipewire.defaultAudioSink?.volume ? Math.round(Pipewire.defaultAudioSink.volume * 100) + "%" : ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" } } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.mute = !Pipewire.defaultAudioSink.mute } } } }
        Component { id: compBattery; Rectangle { width: 65; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; visible: UPower.battery != null; RowLayout { anchors.centerIn: parent; spacing: 4; Text { text: UPower.battery?.charging ? "" : ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" } Text { text: UPower.battery?.percentage ? Math.round(UPower.battery.percentage) + "%" : ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" } } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: powerProfileProcess.running = true } } }
        Component { id: compClock; Rectangle { width: 75; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { id: clockText; anchors.centerIn: parent; text: new Date().toLocaleTimeString(Qt.locale(), "HH:mm"); color: colors.accent; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" } Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = new Date().toLocaleTimeString(Qt.locale(), "HH:mm") } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: launcherProcess.running = true } } }
        Component { id: compNetwork; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compPower; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compCpu; Rectangle { width: 40; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: "CPU"; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compMemory; Rectangle { width: 40; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: "MEM"; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compFilesystem; Rectangle { width: 40; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: "FS"; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compMpd; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compUpdates; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compBluetooth; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
        Component { id: compTray; Rectangle { width: 26; height: 26; radius: 6; color: hoverMouse.containsMouse ? colors.accent : colors.background; border.color: colors.accent; border.width: 1; Text { anchors.centerIn: parent; text: ""; color: hoverMouse.containsMouse ? colors.foreground : colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" } MouseArea { id: hoverMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor } } }
    }
}