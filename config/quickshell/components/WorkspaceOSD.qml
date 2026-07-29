import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Workspace OSD — appears near the mouse cursor for 1.5s on workspace switch.
PanelWindow {
    id: wsOsd
    required property var modelData
    screen: modelData

    // Full-screen transparent overlay on the top layer
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    implicitWidth: screen.width
    implicitHeight: screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-ws-osd"

    // Pass all input through — this window should never steal clicks
    mask: Region {}

    // ── State ────────────────────────────────────────────────────────────
    property int  wsId:    shellRoot.activeWsId
    property string wsName: Hyprland.activeWorkspace ? Hyprland.activeWorkspace.name : wsId.toString()

    property real cursorX: screen.width  / 2
    property real cursorY: screen.height / 2

    property bool osdVisible: false
    property bool isReady: false

    // ── Cursor position polling ──────────────────────────────────────────
    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(",")
                if (parts.length === 2) {
                    var cx = parseInt(parts[0].trim())
                    var cy = parseInt(parts[1].trim())
                    // Only display OSD if cursor is on this screen
                    if (cx >= wsOsd.screen.x && cx < wsOsd.screen.x + wsOsd.screen.width &&
                        cy >= wsOsd.screen.y && cy < wsOsd.screen.y + wsOsd.screen.height) {
                        wsOsd.cursorX = cx - wsOsd.screen.x
                        wsOsd.cursorY = cy - wsOsd.screen.y
                    } else {
                        wsOsd.osdVisible = false
                    }
                }
            }
        }
    }

    // Poll cursor position every 80ms ONLY while OSD is active
    Timer {
        id: pollTimer
        interval: 80
        repeat: true
        running: wsOsd.osdVisible
        onTriggered: {
            cursorProc.running = false
            cursorProc.running = true
        }
    }

    // Auto-hide after 1.5s
    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: wsOsd.osdVisible = false
    }

    // Grace period at startup to avoid popup on launch
    Timer {
        id: startupTimer
        interval: 2000
        running: true
        repeat: false
        onTriggered: wsOsd.isReady = true
    }

    // Show OSD on workspace switch
    onWsIdChanged: {
        if (!isReady || wsId === 0) return
        wsOsd.osdVisible = true
        hideTimer.restart()
        cursorProc.running = false
        cursorProc.running = true
    }

    // ── OSD Badge ────────────────────────────────────────────────────────
    Item {
        id: badge
        width:  badgeRow.implicitWidth  + 30
        height: 36

        // Keep badge on screen, offset slightly above cursor
        property real targetX: Math.max(8, Math.min(wsOsd.cursorX - width  / 2, wsOsd.width  - width  - 8))
        property real targetY: Math.max(8, Math.min(wsOsd.cursorY - height - 20, wsOsd.height - height - 8))

        x: targetX
        y: targetY

        Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        opacity: wsOsd.osdVisible ? 1 : 0
        scale:   wsOsd.osdVisible ? 1 : 0.85

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 150; easing.type: Easing.OutBack  } }

        // Pill background
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color:        shellRoot.alphaColor(shellRoot._bg, 0.93)
            border.color: shellRoot._acc
            border.width: 2

            // Inner glow
            Rectangle {
                anchors { fill: parent; margins: 2 }
                radius: parent.radius - 2
                color: shellRoot.alphaColor(shellRoot._acc, 0.08)
            }
        }

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "\uf24d"
                color: shellRoot._acc
                font.family: shellRoot.globalFontFamily
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }

            Text {
                text: {
                    var n = wsOsd.wsName
                    return (/^\d+$/.test(n)) ? "Workspace " + n : n
                }
                color: shellRoot._fg
                font.family: shellRoot.globalFontFamily
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
        }
    }
}
