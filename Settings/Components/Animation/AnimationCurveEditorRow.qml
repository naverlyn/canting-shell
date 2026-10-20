import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    id: self
    property alias bezierCanvasRef: bezierCanvas
    property alias canvasMouseRef: canvasMouse
    Layout.fillWidth: true
    Layout.preferredHeight: 330
    spacing: 14

    // LEFT COLUMN: Bézier Curves Manager
    Rectangle {
        id: bezierGraphCard
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 55
        radius: 8
        color: root.theme.bgBase
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Curve Tabs & Action Header Row
            AnimationCurveTabsHeader {
                root: self.root
            }

            // Selected Curve Name & Template Presets Row
            AnimationCurveNameTemplateRow {
                root: self.root
            }

            // Interactive Bezier Curve Canvas
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: bezierCanvas
                    anchors.fill: parent
                    antialiasing: true

                    property string curvePoints: root.newCurvePoints
                    property var coords: root.parseBezierPoints(root.newCurvePoints)
                    property int activeDragHandle: 0 // 0: none, 1: P1, 2: P2

                    onCurvePointsChanged: {
                        coords = root.parseBezierPoints(root.newCurvePoints);
                        requestPaint();
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    readonly property real padX: 34
                    readonly property real padY: 16
                    readonly property real yMin: -0.6
                    readonly property real yMax: 1.6
                    readonly property real ySpan: 2.2

                    function toCanvasX(x) {
                        const w = width - padX * 2;
                        return padX + x * w;
                    }

                    function toCanvasY(y) {
                        const h = height - padY * 2;
                        return padY + ((yMax - y) / ySpan) * h;
                    }

                    function toCurveX(cx) {
                        const w = width - padX * 2;
                        if (w <= 0) return 0.0;
                        const x = (cx - padX) / w;
                        return Math.max(0.0, Math.min(1.0, x));
                    }

                    function toCurveY(cy) {
                        const h = height - padY * 2;
                        if (h <= 0) return 0.0;
                        const norm = (cy - padY) / h;
                        const y = yMax - norm * ySpan;
                        return Math.max(-0.6, Math.min(1.6, y));
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        const x0 = coords[0];
                        const y0 = coords[1];
                        const x1 = coords[2];
                        const y1 = coords[3];

                        const cx0 = toCanvasX(0);
                        const cy0 = toCanvasY(0);
                        const cx1 = toCanvasX(1);
                        const cy1 = toCanvasY(1);

                        const p1x = toCanvasX(x0);
                        const p1y = toCanvasY(y0);
                        const p2x = toCanvasX(x1);
                        const p2y = toCanvasY(y1);

                        // Grid reference lines
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10);
                        ctx.lineWidth = 1;
                        ctx.setLineDash([4, 4]);
                        ctx.beginPath();
                        ctx.moveTo(padX, cy0);
                        ctx.lineTo(width - padX, cy0);
                        ctx.stroke();

                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.12);
                        ctx.beginPath();
                        ctx.moveTo(padX, cy1);
                        ctx.lineTo(width - padX, cy1);
                        ctx.stroke();

                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05);
                        ctx.beginPath();
                        ctx.moveTo(cx0, cy0);
                        ctx.lineTo(cx1, cy1);
                        ctx.stroke();

                        ctx.setLineDash([]);

                        // Axis labels
                        ctx.font = "8px sans-serif";
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.35);
                        ctx.textAlign = "right";
                        ctx.textBaseline = "middle";
                        ctx.fillText("0.0", padX - 5, cy0);
                        ctx.fillText("1.0", padX - 5, cy1);

                        ctx.textAlign = "center";
                        ctx.textBaseline = "top";
                        ctx.fillText("0", cx0, cy0 + 3);
                        ctx.fillText("1", cx1, cy0 + 3);

                        // Tangent lines from anchors to control points
                        ctx.strokeStyle = Qt.rgba(1, 0.42, 0.42, 0.55);
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([3, 3]);
                        ctx.beginPath();
                        ctx.moveTo(cx0, cy0);
                        ctx.lineTo(p1x, p1y);
                        ctx.stroke();

                        ctx.strokeStyle = Qt.rgba(0.3, 0.67, 0.97, 0.55);
                        ctx.beginPath();
                        ctx.moveTo(cx1, cy1);
                        ctx.lineTo(p2x, p2y);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        // Gradient fill under curve
                        ctx.beginPath();
                        ctx.moveTo(cx0, cy0);
                        ctx.bezierCurveTo(p1x, p1y, p2x, p2y, cx1, cy1);
                        ctx.lineTo(cx1, cy0);
                        ctx.lineTo(cx0, cy0);
                        ctx.closePath();
                        const grad = ctx.createLinearGradient(0, cy1, 0, cy0);
                        grad.addColorStop(0, Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16));
                        grad.addColorStop(1, Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.0));
                        ctx.fillStyle = grad;
                        ctx.fill();

                        // Cubic Bezier curve stroke
                        ctx.beginPath();
                        ctx.moveTo(cx0, cy0);
                        ctx.bezierCurveTo(p1x, p1y, p2x, p2y, cx1, cy1);
                        ctx.strokeStyle = root.theme.accentPrimary;
                        ctx.lineWidth = 2.5;
                        ctx.stroke();

                        // Anchors
                        ctx.fillStyle = "#ffffff";
                        ctx.beginPath();
                        ctx.arc(cx0, cy0, 3.5, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.beginPath();
                        ctx.arc(cx1, cy1, 3.5, 0, Math.PI * 2);
                        ctx.fill();

                        // Handle P1 (red/coral)
                        ctx.fillStyle = "#ff6b6b";
                        ctx.beginPath();
                        ctx.arc(p1x, p1y, 5.5, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 1.5;
                        ctx.stroke();

                        // Handle P2 (blue/cyan)
                        ctx.fillStyle = "#4dabf7";
                        ctx.beginPath();
                        ctx.arc(p2x, p2y, 5.5, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 1.5;
                        ctx.stroke();
                    }

                    MouseArea {
                        id: canvasMouse
                        anchors.fill: parent
                        preventStealing: true
                        hoverEnabled: true

                        function checkNear(mx, my, px, py, radius) {
                            const dx = mx - px;
                            const dy = my - py;
                            return (dx * dx + dy * dy) <= (radius * radius);
                        }

                        onPositionChanged: function(mouse) {
                            const p1x = bezierCanvas.toCanvasX(bezierCanvas.coords[0]);
                            const p1y = bezierCanvas.toCanvasY(bezierCanvas.coords[1]);
                            const p2x = bezierCanvas.toCanvasX(bezierCanvas.coords[2]);
                            const p2y = bezierCanvas.toCanvasY(bezierCanvas.coords[3]);

                            if (bezierCanvas.activeDragHandle === 1) {
                                mouse.accepted = true;
                                const nx = bezierCanvas.toCurveX(mouse.x);
                                const ny = bezierCanvas.toCurveY(mouse.y);
                                const c = bezierCanvas.coords;
                                const newPts = nx.toFixed(2) + ", " + ny.toFixed(2) + ", " + c[2].toFixed(2) + ", " + c[3].toFixed(2);
                                root.updateSelectedBezierCurve(newPts);
                                root.newCurvePreset = "Custom";
                            } else if (bezierCanvas.activeDragHandle === 2) {
                                mouse.accepted = true;
                                const nx = bezierCanvas.toCurveX(mouse.x);
                                const ny = bezierCanvas.toCurveY(mouse.y);
                                const c = bezierCanvas.coords;
                                const newPts = c[0].toFixed(2) + ", " + c[1].toFixed(2) + ", " + nx.toFixed(2) + ", " + ny.toFixed(2);
                                root.updateSelectedBezierCurve(newPts);
                                root.newCurvePreset = "Custom";
                            } else {
                                const nearP1 = checkNear(mouse.x, mouse.y, p1x, p1y, 16);
                                const nearP2 = checkNear(mouse.x, mouse.y, p2x, p2y, 16);
                                cursorShape = (nearP1 || nearP2) ? Qt.PointingHandCursor : Qt.ArrowCursor;
                            }
                        }

                        onPressed: function(mouse) {
                            const p1x = bezierCanvas.toCanvasX(bezierCanvas.coords[0]);
                            const p1y = bezierCanvas.toCanvasY(bezierCanvas.coords[1]);
                            const p2x = bezierCanvas.toCanvasX(bezierCanvas.coords[2]);
                            const p2y = bezierCanvas.toCanvasY(bezierCanvas.coords[3]);

                            if (checkNear(mouse.x, mouse.y, p1x, p1y, 20)) {
                                mouse.accepted = true;
                                bezierCanvas.activeDragHandle = 1;
                                cursorShape = Qt.ClosedHandCursor;
                            } else if (checkNear(mouse.x, mouse.y, p2x, p2y, 20)) {
                                mouse.accepted = true;
                                bezierCanvas.activeDragHandle = 2;
                                cursorShape = Qt.ClosedHandCursor;
                            }
                        }

                        onReleased: function(mouse) {
                            if (bezierCanvas.activeDragHandle !== 0) {
                                mouse.accepted = true;
                                bezierCanvas.activeDragHandle = 0;
                                cursorShape = Qt.ArrowCursor;
                                root.triggerPreview();
                            }
                        }
                    }
                }
            }

            // Legend & Coordinates Input
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#ff6b6b" }
                    Text {
                        text: "P1: (" + bezierCanvas.coords[0].toFixed(2) + ", " + bezierCanvas.coords[1].toFixed(2) + ")"
                        font.family: root.font
                        font.pixelSize: 9
                        color: "#ff8787"
                    }
                }

                RowLayout {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#4dabf7" }
                    Text {
                        text: "P2: (" + bezierCanvas.coords[2].toFixed(2) + ", " + bezierCanvas.coords[3].toFixed(2) + ")"
                        font.family: root.font
                        font.pixelSize: 9
                        color: "#74c0fc"
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Points:"
                    font.family: root.font
                    font.pixelSize: 9
                    color: root.theme.textMuted
                }

                Rectangle {
                    width: 140
                    height: 22
                    radius: 4
                    color: root.theme.bgSurface
                    border.color: coordIn.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: 1

                    TextInput {
                        id: coordIn
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 9
                        color: root.theme.textPrimary
                        text: root.newCurvePoints
                        onEditingFinished: {
                            root.updateSelectedBezierCurve(text);
                            root.newCurvePreset = "Custom";
                        }
                    }
                }
            }
        }
    }

    // RIGHT COLUMN: Live Motion Sandbox Preview
    AnimationLiveMotionPreview {
        root: self.root
    }
}
