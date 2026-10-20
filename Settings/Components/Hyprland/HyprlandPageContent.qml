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
    id: mainCol
    width: parent.width
    spacing: 18

    /* Top Page Header */
    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: 3
            Text {
                text: "Hyprland Settings"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
            }
            Text {
                text: "Window management, decorations, touchpad gestures, and compositor variables"
                font.family: root.font
                font.pixelSize: 12
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }
    }

    ParallelAnimation {
        id: subTabContentAnim
        NumberAnimation {
            target: subTabContentContainer
            property: "opacity"
            from: 0.35
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: subTabContentTranslate
            property: "y"
            from: 8
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Sub-Tab Navigation Bar (Underline indicator style matching BarSettings) */
    Rectangle {
        id: subTabTrack
        Layout.fillWidth: true
        height: 40
        radius: 10
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Repeater {
                model: [
                    { idx: 0, icon: "󰖲", label: "General & Layout" },
                    { idx: 1, icon: "󰏘", label: "Window Decoration" },
                    { idx: 2, icon: "󰌒", label: "Gestures & Touchpad" },
                    { idx: 3, icon: "󰒓", label: "Misc & Compositor" }
                ]
                delegate: Rectangle {
                    id: subTabItem
                    required property var modelData
                    readonly property bool isCurrent: root.currentSubTab === modelData.idx

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.width: 0

                    HoverHandler { id: subTabHover }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 2
                        radius: 1
                        width: subTabItem.isCurrent
                            ? subTabRow.implicitWidth + 16
                            : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                        opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                        color: subTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Row {
                        id: subTabRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            width: 16
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: subTabItem.modelData.icon
                            font.family: root.font
                            font.pixelSize: 13
                            color: subTabItem.isCurrent
                                ? root.theme.accentPrimary
                                : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: subTabItem.modelData.label
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: subTabItem.isCurrent
                            color: subTabItem.isCurrent
                                ? root.theme.accentPrimary
                                : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentSubTab !== subTabItem.modelData.idx) {
                                root.currentSubTab = subTabItem.modelData.idx;
                                subTabContentAnim.restart();
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: subTabContentContainer
        Layout.fillWidth: true
        spacing: 16
        transform: Translate { id: subTabContentTranslate; y: 0 }

    /* ========================================================================= */
    /* TAB 0: GENERAL & LAYOUT                                                   */
    /* ========================================================================= */
    HyprlandLiveWindowLayoutPreview {
        root: mainCol.root
    }

    /* ========================================================================= */
    /* TAB 1: WINDOW DECORATION                                                  */
    /* ========================================================================= */
    HyprlandWindowCornerRounding {
        root: mainCol.root
    }

    /* ========================================================================= */
    /* TAB 2: GESTURES & TOUCHPAD                                                */
    /* ========================================================================= */
    HyprlandTouchpadWorkspaceGestures {
        root: mainCol.root
    }

    /* ========================================================================= */
    /* TAB 3: MISC & COMPOSITOR                                                  */
    /* ========================================================================= */
    HyprlandDisplaySyncRefresh {
        root: mainCol.root
    }
}
}
