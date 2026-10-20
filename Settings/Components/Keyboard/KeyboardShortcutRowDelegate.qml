import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

Item {
    required property var root
    id: rowItem
    required property var modelData
    required property int index
    Layout.fillWidth: true
    clip: true
    readonly property bool isEditing: root.editingUid === modelData.uid && root.editingUid !== -1
    readonly property bool isConfirmingUnbind: root.confirmingUnbindUid === modelData.uid

    implicitHeight: isEditing ? (50 + editDrawer.implicitHeight + 8) : 50

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    /* Main Shortcut Row */
    Rectangle {
        id: mainRowRect
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: 4
            rightMargin: 4
        }
        height: 50
        radius: 8
        color: rowItem.isEditing ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)) : (shortcutMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.getFriendlyAction(modelData)
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: (modelData.dispatcher || "") + (modelData.arg ? " " + modelData.arg : "")
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    opacity: 0.8
                }
            }

            /* Keyboard Pills & Edit Trigger */
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Repeater {
                        model: root.getModPills(modelData.modmask, modelData.key)

                        Rectangle {
                            required property var modelData
                            implicitWidth: keyLabel.implicitWidth + 12
                            height: 24
                            radius: 6
                            color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1

                            Text {
                                id: keyLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textPrimary
                            }
                        }
                    }
                }

                /* Edit Button */
                Rectangle {
                    width: 26
                    height: 24
                    radius: 6
                    color: rowItem.isEditing ? root.theme.accentPrimary : (editHoverMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)))
                    border.color: rowItem.isEditing ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰏫"
                        font.family: root.font
                        font.pixelSize: 12
                        color: rowItem.isEditing ? root.theme.bgBase : root.theme.textPrimary
                    }

                    MouseArea {
                        id: editHoverMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.startEditing(modelData)
                    }
                }
            }
        }

        MouseArea {
            id: shortcutMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.startEditing(modelData)
        }
    }

    /* Expandable Edit Drawer */
    KeyboardShortcutEditDrawer {
        id: editDrawer
        root: rowItem.root
        rowItem: rowItem
        mainRowRect: mainRowRect
        modelData: rowItem.modelData
    }
}
