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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Touchpad Workspace Gestures"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingToggleRow {
                    announce: true
                    title: "Workspace Swipe Gesture"
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
                                font.pixelSize: Style.px(13)
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "Number of fingers required for touchpad workspace swipe"
                                font.family: root.font
                                font.pixelSize: Style.px(11)
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AppDropdown {
                            theme: root.theme
                            font: root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
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
    }
}
