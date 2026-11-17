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

                AppDropdown {
                    theme: root.theme
                    font: root.font
                    width: 220
                    implicitWidth: 220
                    menuWidth: 220
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    options: [
                        { desktop: "3", name: "3 Fingers", desc: "" },
                        { desktop: "4", name: "4 Fingers", desc: "" }
                    ]
                    currentValue: String(root.gesturesWorkspaceSwipeFingers)
                    onSelected: (val, opt) => {
                        root.gesturesWorkspaceSwipeFingers = Number(val);
                        root.setHyprVar("gestures", "workspace_swipe_fingers", Number(val));
                        root.showToast("Swipe gesture set to " + (opt ? opt.name : val));
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
