import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../../bar"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    property alias lockMouseRef: lockMouse
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Display & Sleep"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sleepCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: sleepCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Keep Awake Toggle */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Keep Awake"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Inhibit idle sleep and keep monitors from turning off"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: awakeSwitch
                        width: 44
                        height: 24
                        radius: 12
                        color: root.keepAwake ? (root.theme.accentOrange ?? root.theme.accentPrimary) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.keepAwake ? parent.width - width - 3 : 3
                            color: root.keepAwake ? "#ffffff" : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemInfo.toggleIdleInhibitor()
                        }
                    }
                }
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 2: Automatic Screen Lock */
            Item {
                id: lockItem
                property bool customActive: false

                Connections {
                    target: root
                    function onLockTimeoutMinutesChanged() {
                        const presets = [5, 10, 15, 30];
                        if (presets.indexOf(root.lockTimeoutMinutes) === -1) {
                            lockItem.customActive = true;
                        }
                    }
                }

                Layout.fillWidth: true
                implicitHeight: lockCol.implicitHeight + (customActive ? 20 : 12)

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: lockCol
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Automatic Screen Lock"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Lock session after inactivity via hypridle"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Segmented Track */
                        Rectangle {
                            id: lockSegmentTrack
                            implicitWidth: 320
                            implicitHeight: 32
                            width: 320
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            readonly property int activeIdx: {
                                if (lockItem.customActive) return 4;
                                const presets = [5, 10, 15, 30];
                                const idx = presets.indexOf(root.lockTimeoutMinutes);
                                return idx !== -1 ? idx : 4;
                            }
                            readonly property real cellWidth: (width - 6 - 16) / 5

                            /* Sliding Selection Pill */
                            Rectangle {
                                y: 3
                                height: parent.height - 6
                                width: lockSegmentTrack.cellWidth
                                x: 3 + lockSegmentTrack.activeIdx * (lockSegmentTrack.cellWidth + 4)
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
                                        { label: "5m", value: 5 },
                                        { label: "10m", value: 10 },
                                        { label: "15m", value: 15 },
                                        { label: "30m", value: 30 },
                                        { label: "Custom", value: "custom" }
                                    ]

                                    delegate: Rectangle {
                                        id: lSegBtn
                                        required property var modelData
                                        required property int index
                                        readonly property bool isSel: lockSegmentTrack.activeIdx === lSegBtn.index

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: !isSel && lSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: lSegHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: (lSegBtn.modelData.value === "custom")
                                                ? (lockItem.customActive ? (root.lockTimeoutMinutes + "m") : "Custom")
                                                : lSegBtn.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: lSegBtn.isSel
                                            color: lSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                            opacity: lSegBtn.isSel || lSegHover.hovered ? 1.0 : 0.75
                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on opacity { NumberAnimation { duration: 140 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (lSegBtn.modelData.value === "custom") {
                                                    lockItem.customActive = !lockItem.customActive;
                                                } else {
                                                    lockItem.customActive = false;
                                                    root.lockDebounceTimerRef.stop();
                                                    root.setLockTimeout(lSegBtn.modelData.value);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    /* Custom Slider Row */
                    RowLayout {
                        id: customLockSeekRow
                        visible: lockItem.customActive
                        opacity: lockItem.customActive ? 1.0 : 0.0
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 12

                        Behavior on opacity { NumberAnimation { duration: 160 } }

                        Text {
                            text: "Custom Inactivity Time:"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 160
                            Layout.minimumWidth: 160
                            Layout.maximumWidth: 160
                        }

                        Rectangle {
                            id: lockSeekTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: root.theme.bgSelected
                            Layout.alignment: Qt.AlignVCenter

                            readonly property real minMins: 1.0
                            readonly property real maxMins: 60.0
                            readonly property real frac: Math.max(0.0, Math.min(1.0, (root.lockTimeoutMinutes - minMins) / (maxMins - minMins)))
                            readonly property bool isDragging: lockMouse.pressed

                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width: Math.max(0, Math.min(parent.width, parent.width * lockSeekTrack.frac))
                                color: root.theme.accentPrimary

                                Behavior on width {
                                    NumberAnimation {
                                        duration: lockSeekTrack.isDragging ? 0 : 140
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // Outer halo ring on hover/press
                            Rectangle {
                                anchors.centerIn: lockKnob
                                width: lockKnob.width + (lockMouse.pressed ? 8 : (lockMouse.containsMouse ? 6 : 0))
                                height: width
                                radius: width / 2
                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, lockMouse.pressed ? 0.35 : (lockMouse.containsMouse ? 0.2 : 0))
                                z: 1

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Tactile white knob
                            Rectangle {
                                id: lockKnob
                                width: lockMouse.containsMouse || lockMouse.pressed ? 17 : 15
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: root.theme.accentPrimary
                                border.width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(lockSeekTrack.width - width, (lockSeekTrack.width * lockSeekTrack.frac) - (width / 2)))
                                z: 2

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on x {
                                    NumberAnimation {
                                        duration: lockSeekTrack.isDragging ? 0 : 140
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            MouseArea {
                                id: lockMouse
                                anchors.fill: parent
                                anchors.margins: -8
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                function updateFromPos(mouse) {
                                    if (lockSeekTrack.width <= 0) return;
                                    const trackX = mapToItem(lockSeekTrack, mouse.x, 0).x;
                                    const f = Math.max(0.0, Math.min(1.0, trackX / lockSeekTrack.width));
                                    const val = Math.max(1, Math.min(60, Math.round(lockSeekTrack.minMins + f * (lockSeekTrack.maxMins - lockSeekTrack.minMins))));
                                    root.queueLockTimeout(val);
                                }
                                onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                                onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                            }
                        }

                        Text {
                            text: root.lockTimeoutMinutes + " min"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.accentPrimary
                            Layout.preferredWidth: 50
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 3: Turn Off Displays Now */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Turn Off Displays"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Put monitors into power-saving standby immediately"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: dpmsBtn
                        width: 80
                        height: 32
                        radius: 6
                        color: dpmsHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                        border.color: dpmsHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: dpmsHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Turn Off"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.turnOffDisplaysProcRef.running = true
                        }
                    }
                }
            }
        }
    }
}
