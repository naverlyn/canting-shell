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
    id: barHeightItem
    Layout.fillWidth: true
    implicitHeight: customHeightCol.implicitHeight + 20
    height: implicitHeight
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    readonly property var presetValues: [4, 8, 28, 32, 40]
    readonly property int activeH: BarConfig.currentBar ? Number(BarConfig.currentBar.barHeight) : BarConfig.barHeight
    readonly property bool isPreset: presetValues.indexOf(activeH) !== -1
    property bool userForcedCustom: false
    readonly property bool customActive: userForcedCustom || !isPreset

    ColumnLayout {
        id: customHeightCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.generalTab.curIsVert ? "Bar Thickness (Width)" : "Bar Height"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: root.generalTab.curIsVert ? "Horizontal width in pixels for left/right vertical bar" : "Vertical thickness in pixels"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: heightSegmentTrack
                implicitWidth: 360
                implicitHeight: 32
                width: 360
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeIdx: {
                    if (barHeightItem.customActive) return 5;
                    const idx = barHeightItem.presetValues.indexOf(barHeightItem.activeH);
                    return idx !== -1 ? idx : 5;
                }
                readonly property real cellWidth: (width - 6 - 20) / 6

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: heightSegmentTrack.cellWidth
                    x: 3 + heightSegmentTrack.activeIdx * (heightSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "4px", value: 4 },
                            { label: "8px", value: 8 },
                            { label: "28px", value: 28 },
                            { label: "32px", value: 32 },
                            { label: "40px", value: 40 },
                            { label: "Custom", value: "custom" }
                        ]

                        delegate: Rectangle {
                            id: hSegBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: heightSegmentTrack.activeIdx === hSegBtn.index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            scale: hSegMouse.pressed ? 0.95 : 1.0
                            color: !isSel && hSegHover.hovered ? root.theme.bgHover : "transparent"
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: hSegHover }

                            Text {
                                anchors.centerIn: parent
                                text: (hSegBtn.modelData.value === "custom")
                                    ? (barHeightItem.customActive ? (barHeightItem.activeH + "px") : "Custom...")
                                    : hSegBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: hSegBtn.isSel
                                color: hSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: hSegBtn.isSel || hSegHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: hSegMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (hSegBtn.modelData.value === "custom") {
                                        barHeightItem.userForcedCustom = !barHeightItem.customActive;
                                    } else {
                                        barHeightItem.userForcedCustom = false;
                                        BarConfig.updateBarProp("barHeight", hSegBtn.modelData.value);
                                        root.showToast("Bar height set to: " + hSegBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            id: customSeekbarRow
            visible: barHeightItem.customActive
            opacity: barHeightItem.customActive ? 1.0 : 0.0
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12

            Behavior on opacity { NumberAnimation { duration: 160 } }

            Text {
                text: "Custom Height:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 160
                Layout.minimumWidth: 160
                Layout.maximumWidth: 160
            }

            Rectangle {
                id: heightSeekTrack
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: root.theme.bgSelected
                Layout.alignment: Qt.AlignVCenter

                readonly property real minH: 2.0
                readonly property real maxH: 100.0
                readonly property real frac: Math.max(0.0, Math.min(1.0, (barHeightItem.activeH - minH) / (maxH - minH)))
                readonly property bool isDragging: heightMouse.pressed

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(0, Math.min(parent.width, parent.width * heightSeekTrack.frac))
                    color: root.theme.accentPrimary

                    Behavior on width {
                        NumberAnimation {
                            duration: heightSeekTrack.isDragging ? 0 : 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Outer halo ring on hover/press
                Rectangle {
                    anchors.centerIn: heightKnob
                    width: heightKnob.width + (heightMouse.pressed ? 8 : (heightMouse.containsMouse ? 6 : 0))
                    height: width
                    radius: width / 2
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, heightMouse.pressed ? 0.35 : (heightMouse.containsMouse ? 0.2 : 0))
                    z: 1

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Tactile white knob
                Rectangle {
                    id: heightKnob
                    width: heightMouse.containsMouse || heightMouse.pressed ? 17 : 15
                    height: width
                    radius: width / 2
                    color: "#ffffff"
                    border.color: root.theme.accentPrimary
                    border.width: 3
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(heightSeekTrack.width - width, (heightSeekTrack.width * heightSeekTrack.frac) - (width / 2)))
                    z: 2

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on x {
                        NumberAnimation {
                            duration: heightSeekTrack.isDragging ? 0 : 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: heightMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    function updateFromPos(mouse) {
                        if (heightSeekTrack.width <= 0) return;
                        const trackX = mapToItem(heightSeekTrack, mouse.x, 0).x;
                        const f = Math.max(0.0, Math.min(1.0, trackX / heightSeekTrack.width));
                        const val = Math.round(heightSeekTrack.minH + f * (heightSeekTrack.maxH - heightSeekTrack.minH));
                        BarConfig.updateBarProp("barHeight", val);
                    }
                    onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                    onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                    onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                }
            }

            Text {
                text: barHeightItem.activeH + "px"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.accentPrimary
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
