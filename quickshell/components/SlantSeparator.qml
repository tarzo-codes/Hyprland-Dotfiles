import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color colorLeft: "transparent"
    property color colorRight: "transparent"
    property bool isRightSlant: true // true: \ slant, false: / slant
    property int slantWidth: 12

    width: slantWidth
    height: parent.height

    // Anti-aliased layer
    layer.enabled: true
    layer.samples: 4

    // Left color block — full rectangle
    // Only shown when colorRight is also opaque; when colorRight is transparent,
    // the override Shape below draws only the visible triangle, so this block
    // must be hidden to allow the transparent area to show through.
    Rectangle {
        id: leftBlock
        anchors.fill: parent
        color: root.colorLeft
        visible: root.colorLeft !== "transparent" && root.colorRight !== "transparent" && root.colorRight.a !== 0
    }

    // The diagonal is drawn as a filled triangle of colorRight
    // overlaid on the colorLeft background.
    // isRightSlant=true  (\): triangle covers top-right corner → colorRight appears top-right
    // isRightSlant=false (/): triangle covers bottom-right corner → colorRight appears bottom-right
    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            fillColor: root.colorRight
            strokeColor: "transparent"
            strokeWidth: 0

            // isRightSlant=true (\) triangle: top-left, top-right, bottom-right
            // isRightSlant=false (/) triangle: bottom-left, top-right, bottom-right
            startX: root.isRightSlant ? 0 : 0
            startY: root.isRightSlant ? 0 : root.height

            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine {
                x: 0
                y: root.isRightSlant ? 0 : root.height
            }
        }
    }

    // For right-exit slant where colorRight is transparent,
    // we need to clip the item so the right portion is actually invisible.
    // We achieve this by painting colorLeft only in the NON-transparent triangle.
    // Override: draw the opaque triangle directly without relying on transparent paint
    Shape {
        anchors.fill: parent
        visible: root.colorRight === "transparent" || root.colorRight.a === 0
        antialiasing: true

        ShapePath {
            fillColor: root.colorLeft
            strokeColor: "transparent"
            strokeWidth: 0

            // Draw only the opaque (left) triangle
            // isRightSlant=true (\): opaque = bottom-left triangle: (0,0),(0,h),(w,h)
            // isRightSlant=false (/): opaque = top-left triangle: (0,0),(w,0),(0,h)
            startX: 0
            startY: 0

            PathLine { x: root.isRightSlant ? 0 : root.width; y: root.height }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }
}
