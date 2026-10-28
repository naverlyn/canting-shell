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
    visible: root.currentSubTab === 4
    Layout.fillWidth: true
    spacing: 16

    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Display Sync & Refresh"
        subtitle: "Adaptive sync (VRR) and variable frame rate performance"

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
                    Layout.fillWidth: true

                    Text {
                        text: "Variable Refresh Rate (VRR)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Adaptive sync (G-Sync / FreeSync) for variable refresh rate displays"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: vrrSegmentTrack
                    implicitWidth: 320
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var vrrOpts: [0, 1, 2]
                    readonly property int activeIdx: vrrOpts.indexOf(root.miscVrr)
                    readonly property real cellWidth: (width - 6 - 6) / 3

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: vrrSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: vrrSegmentTrack.cellWidth
                        x: 3 + Math.max(0, vrrSegmentTrack.activeIdx) * (vrrSegmentTrack.cellWidth + 3)
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
                                { val: 0, label: "Off" },
                                { val: 1, label: "Always On" },
                                { val: 2, label: "Fullscreen" }
                            ]

                            delegate: Rectangle {
                                id: vrrBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: vrrSegmentTrack.activeIdx === vrrBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && vHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: vHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: vrrBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: vrrBtn.isSel
                                    color: vrrBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: vrrBtn.isSel || vHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.miscVrr = vrrBtn.modelData.val;
                                        root.setHyprVar("misc", "vrr", vrrBtn.modelData.val);
                                        root.showToast("VRR set to " + vrrBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Variable Frame Rate (VFR)"
            desc: "Drop rendering rate when screen is static to significantly reduce GPU and battery usage"
            checked: root.miscVfr
            onToggled: (val) => {
                root.miscVfr = val;
                root.setHyprVar("misc", "vfr", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Mouse Movement Wakes Monitors"
            desc: "Wake screens from DPMS / display standby sleep when mouse moves"
            checked: root.miscMouseMoveDpms
            onToggled: (val) => {
                root.miscMouseMoveDpms = val;
                root.setHyprVar("misc", "mouse_move_enables_dpms", val);
            }
        }
    }

    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Interaction & System Branding"
        subtitle: "Clipboard behavior and compositor boot elements"

        SettingToggleRow {
            announce: true
            title: "Middle-Click Paste"
            desc: "Paste primary selection buffer when clicking middle mouse button"
            checked: root.miscMiddleClickPaste
            onToggled: (val) => {
                root.miscMiddleClickPaste = val;
                root.setHyprVar("misc", "middle_click_paste", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Hide Hyprland Boot Logo"
            desc: "Suppress default Hyprland anime mascot logo on compositor startup"
            checked: root.miscDisableLogo
            onToggled: (val) => {
                root.miscDisableLogo = val;
                root.setHyprVar("misc", "disable_hyprland_logo", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Hide Splash Rendering"
            desc: "Disable random witty splash text rendering on startup screen"
            checked: root.miscDisableSplash
            onToggled: (val) => {
                root.miscDisableSplash = val;
                root.setHyprVar("misc", "disable_splash_rendering", val);
            }
        }
    }
}
