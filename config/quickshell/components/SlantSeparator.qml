import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color colorLeft: "transparent"
    property color colorRight: "transparent"
    property bool isRightSlant: true // true: \ slant, false: / slant
    property int slantWidth: 16

    width: slantWidth
    height: parent.height

    layer.enabled: true
    layer.samples: 4

    readonly property bool leftIsOpaque: colorLeft !== "transparent" && colorLeft.a > 0
    readonly property bool rightIsOpaque: colorRight !== "transparent" && colorRight.a > 0

    // ── Case 1: Both sides opaque ──
    Rectangle {
        anchors.fill: parent
        color: root.colorLeft
        visible: root.leftIsOpaque && root.rightIsOpaque
    }

    Shape {
        anchors.fill: parent
        visible: root.leftIsOpaque && root.rightIsOpaque
        antialiasing: true

        ShapePath {
            fillColor: root.colorRight
            strokeColor: "transparent"
            strokeWidth: 0

            // isRightSlant=true  (\): top-right triangle of colorRight
            // isRightSlant=false (/): bottom-right triangle of colorRight
            startX: root.isRightSlant ? 0 : 0
            startY: root.isRightSlant ? 0 : root.height

            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: root.isRightSlant ? 0 : 0; y: root.isRightSlant ? 0 : root.height }
        }
    }

    // ── Case 2: colorRight is transparent (Right exit slant) ──
    // Draw colorLeft in left polygon
    Shape {
        anchors.fill: parent
        visible: root.leftIsOpaque && !root.rightIsOpaque
        antialiasing: true

        ShapePath {
            fillColor: root.colorLeft
            strokeColor: "transparent"
            strokeWidth: 0

            // isRightSlant=true  (\): bottom-left triangle (0,0) -> (0,h) -> (w,h)
            // isRightSlant=false (/): top-left triangle (0,0) -> (w,0) -> (0,h)
            startX: 0
            startY: 0

            PathLine { x: root.isRightSlant ? 0 : root.width; y: root.isRightSlant ? root.height : 0 }
            PathLine { x: root.isRightSlant ? root.width : 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // ── Case 3: colorLeft is transparent (Left entry slant) ──
    // Draw colorRight in right polygon
    Shape {
        anchors.fill: parent
        visible: !root.leftIsOpaque && root.rightIsOpaque
        antialiasing: true

        ShapePath {
            fillColor: root.colorRight
            strokeColor: "transparent"
            strokeWidth: 0

            // isRightSlant=true  (\): top-right triangle (0,0) -> (w,0) -> (w,h)
            // isRightSlant=false (/): bottom-right triangle (0,h) -> (w,0) -> (w,h)
            startX: root.isRightSlant ? 0 : 0
            startY: root.isRightSlant ? 0 : root.height

            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: root.isRightSlant ? 0 : 0; y: root.isRightSlant ? 0 : root.height }
        }
    }
}
