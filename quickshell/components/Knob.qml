import QtQuick

Item {
    id: root
    width: 26
    height: 26

    property real value: 0.5 // 0.0 to 1.0
    property string icon: ""
    property color activeColor: "#7aa2f7"
    property color trackColor: "#414868"
    property color iconColor: "#c0caf5"

    scale: mouseArea.containsMouse ? 1.12 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    signal scrolled(real delta)
    signal clicked()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = canvas.getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;
            var radius = Math.min(width, height) / 2 - 3;

            // Draw track
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
            ctx.strokeStyle = trackColor;
            ctx.lineWidth = 2.5;
            ctx.stroke();

            // Draw active arc
            if (value > 0) {
                ctx.beginPath();
                ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + value * 2 * Math.PI);
                ctx.strokeStyle = activeColor;
                ctx.lineWidth = 2.5;
                ctx.stroke();
            }
        }
    }

    onValueChanged: canvas.requestPaint()
    onActiveColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: Math.max(6, root.width * 0.4)
        font.family: "Font Awesome 6 Free Solid"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: (wheel) => {
            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.scrolled(delta);
        }
    }
}
