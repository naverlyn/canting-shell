import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: pillRadiusItem
    Layout.fillWidth: true
    height: 64
    readonly property int activeRadius: root.generalTab.curPillRadius
    opacity: root.generalTab.curHidePill ? 0.45 : 1.0
    enabled: !root.generalTab.curHidePill
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.preferredWidth: 160
            Layout.minimumWidth: 160
            Layout.maximumWidth: 160
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Pill Corner Radius"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "Widget pill rounded corners"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    id: pillRadiusTrack
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.theme.bgSelected
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real maxRadius: 14.0
                    readonly property real frac: Math.max(0.0, Math.min(1.0, pillRadiusItem.activeRadius / maxRadius))
                    readonly property bool isDragging: pillRadMouse.pressed

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(0, Math.min(parent.width, parent.width * pillRadiusTrack.frac))
                        color: root.theme.accentPrimary

                        Behavior on width {
                            NumberAnimation {
                                duration: pillRadiusTrack.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Outer halo ring on hover/press
                    Rectangle {
                        anchors.centerIn: pillRadKnob
                        width: pillRadKnob.width + (pillRadMouse.pressed ? 8 : (pillRadMouse.containsMouse ? 6 : 0))
                        height: width
                        radius: width / 2
                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, pillRadMouse.pressed ? 0.35 : (pillRadMouse.containsMouse ? 0.2 : 0))
                        z: 1

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Tactile white knob
                    Rectangle {
                        id: pillRadKnob
                        width: pillRadMouse.containsMouse || pillRadMouse.pressed ? 17 : 15
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        border.color: root.theme.accentPrimary
                        border.width: 3
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(pillRadiusTrack.width - width, (pillRadiusTrack.width * pillRadiusTrack.frac) - (width / 2)))
                        z: 2

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on x {
                            NumberAnimation {
                                duration: pillRadiusTrack.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: pillRadMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        function updateFromPos(mouse) {
                            if (pillRadiusTrack.width <= 0) return;
                            const trackX = mapToItem(pillRadiusTrack, mouse.x, 0).x;
                            const frac = Math.max(0.0, Math.min(1.0, trackX / pillRadiusTrack.width));
                            const val = Math.round(frac * pillRadiusTrack.maxRadius);
                            BarConfig.updateBarProp("pillRadius", val);
                        }
                        onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                        onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                        onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                    }
                }

                Text {
                    text: pillRadiusItem.activeRadius + "px"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            RowLayout {
                spacing: 6
                Repeater {
                    model: [
                        { label: "Sharp", r: 0 },
                        { label: "Subtle", r: 4 },
                        { label: "Default", r: 10 },
                        { label: "Capsule", r: 14 }
                    ]
                    delegate: Rectangle {
                        id: rPresetBtn
                        required property var modelData
                        readonly property bool isSel: pillRadiusItem.activeRadius === modelData.r
                        implicitWidth: 62
                        implicitHeight: 22
                        radius: 4
                        scale: rPresetMouse.pressed ? 0.94 : (rPresetHover.hovered ? 1.04 : 1.0)
                        color: isSel ? root.theme.bgSelected : (rPresetHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                        border.color: isSel ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        HoverHandler { id: rPresetHover }

                        Text {
                            anchors.centerIn: parent
                            text: rPresetBtn.modelData.label + " (" + rPresetBtn.modelData.r + ")"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: rPresetBtn.isSel
                            color: rPresetBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: rPresetMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.updateBarProp("pillRadius", rPresetBtn.modelData.r)
                        }
                    }
                }
            }
        }
    }
}
