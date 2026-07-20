import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: backgroundApps
    required property var rootBar
    spacing: 6
    visible: SystemTray.items.count > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            width: 22
            height: 22

            Rectangle {
                id: iconBg
                anchors.fill: parent
                radius: 5
                color: itemMouse.containsMouse ? (backgroundApps.rootBar ? backgroundApps.rootBar.alphaColor(backgroundApps.rootBar._acc, 0.25) : "#337aa2f7") : "transparent"
                border.color: itemMouse.containsMouse ? (backgroundApps.rootBar ? backgroundApps.rootBar._acc : "#7aa2f7") : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: trayItem.modelData.icon || ""
                    fillMode: Image.PreserveAspectFit
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        trayItem.modelData.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        trayItem.modelData.secondaryActivate();
                    }
                }
            }
        }
    }
}
