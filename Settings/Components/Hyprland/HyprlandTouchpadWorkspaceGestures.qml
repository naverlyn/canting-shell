import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.currentSubTab === 3
    Layout.fillWidth: true
    spacing: 16

    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Touchpad Workspace Gestures"
        subtitle: "Fluid multi-finger swipe navigation between virtual desktops"

        SettingToggleRow {
            announce: true
            title: "Workspace Swipe Gesture"
            desc: "Swipe horizontally on touchpad to fluidly pan between workspaces"
            checked: root.gesturesWorkspaceSwipe
            onToggled: (val) => {
                root.gesturesWorkspaceSwipe = val;
                root.setHyprVar("gestures", "workspace_swipe", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: root.gesturesWorkspaceSwipe }

        Item {
            visible: root.gesturesWorkspaceSwipe
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
                    Layout.fillWidth: true

                    Text {
                        text: "Swipe Fingers"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Number of fingers required for touchpad workspace swipe"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: fingerSegmentTrack
                    implicitWidth: 200
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var fingerOpts: [3, 4]
                    readonly property int activeIdx: fingerOpts.indexOf(root.gesturesWorkspaceSwipeFingers)
                    readonly property real cellWidth: (width - 6 - 3) / 2

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: fingerSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: fingerSegmentTrack.cellWidth
                        x: 3 + Math.max(0, fingerSegmentTrack.activeIdx) * (fingerSegmentTrack.cellWidth + 3)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: [
                                { val: 3, label: "3 Fingers" },
                                { val: 4, label: "4 Fingers" }
                            ]

                            delegate: Rectangle {
                                id: fingerBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: fingerSegmentTrack.activeIdx === fingerBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && fHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: fHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: fingerBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: fingerBtn.isSel
                                    color: fingerBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: fingerBtn.isSel || fHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.gesturesWorkspaceSwipeFingers = fingerBtn.modelData.val;
                                        root.setHyprVar("gestures", "workspace_swipe_fingers", fingerBtn.modelData.val);
                                        root.showToast("Swipe gesture set to " + fingerBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: root.gesturesWorkspaceSwipe }

        SettingToggleRow {
            announce: true
            visible: root.gesturesWorkspaceSwipe
            title: "Invert Swipe Direction"
            desc: "Natural swipe scrolling direction for workspace transitions"
            checked: root.gesturesWorkspaceSwipeInvert
            onToggled: (val) => {
                root.gesturesWorkspaceSwipeInvert = val;
                root.setHyprVar("gestures", "workspace_swipe_invert", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: root.gesturesWorkspaceSwipe }

        SettingToggleRow {
            announce: true
            visible: root.gesturesWorkspaceSwipe
            title: "Seamless Workspace Looping"
            desc: "Allow swiping past the highest workspace to cycle continuously"
            checked: root.gesturesWorkspaceSwipeForever
            onToggled: (val) => {
                root.gesturesWorkspaceSwipeForever = val;
                root.setHyprVar("gestures", "workspace_swipe_forever", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: root.gesturesWorkspaceSwipe }

        SettingSliderRow {
            announce: true
            visible: root.gesturesWorkspaceSwipe
            title: "Swipe Distance"
            desc: "Distance in px required to complete a full workspace transition"
            value: root.gesturesWorkspaceSwipeDistance
            minVal: 150
            maxVal: 600
            unit: "px"
            presets: [
                { label: "200px", val: 200 },
                { label: "300px", val: 300 },
                { label: "500px", val: 500 }
            ]
            onValueModified: (v) => {
                root.gesturesWorkspaceSwipeDistance = v;
                root.setHyprVar("gestures", "workspace_swipe_distance", v);
            }
        }
    }
}
