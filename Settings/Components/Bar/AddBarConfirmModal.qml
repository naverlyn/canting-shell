import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: addBarConfirmModal
    anchors.fill: parent
    z: 9000
    visible: opacity > 0
    opacity: root.addBarModalVisible ? 1.0 : 0.0
    color: Qt.rgba(0, 0, 0, 0.72)

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // Dismiss when clicking backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: root.addBarModalVisible = false
    }

    // Modal Dialog Box
    Rectangle {
        id: addBarConfirmCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 520)
        implicitHeight: modalCol.implicitHeight + 48
        radius: 14
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1
        scale: root.addBarModalVisible ? 1.0 : 0.94

        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // Consume clicks inside the card
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Add Desktop Bar"
                        font.family: root.font
                        font.pixelSize: 16
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Choose which monitor or display target this bar should appear on:"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textMuted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                // Close Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    scale: closeBtnMouse.pressed ? 0.88 : (closeBtnHover.hovered ? 1.08 : 1.0)
                    color: closeBtnHover.hovered ? root.theme.bgSelected : "transparent"

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: root.font
                        font.pixelSize: 12
                        color: closeBtnHover.hovered ? root.theme.textPrimary : root.theme.textMuted
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: closeBtnHover }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addBarModalVisible = false
                    }
                }
            }

            // Monitor / Display Target Choices
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.addBarTargetOptions
                    delegate: Rectangle {
                        id: targetOptCard
                        required property var modelData
                        readonly property bool isSelected: root.addBarChosenTarget === modelData.id
                        readonly property bool isHovered: optHover.hovered

                        Layout.fillWidth: true
                        implicitHeight: optRow.implicitHeight + 20
                        radius: 10
                        scale: optMouse.pressed ? 0.98 : (isHovered ? 1.01 : 1.0)
                        color: isSelected
                            ? (root.theme.bgSelected || root.withAlpha(root.theme.accentPrimary, 0.15))
                            : (isHovered ? root.withAlpha(root.theme.accentPrimary, 0.06) : root.theme.bgBase)
                        border.color: isSelected ? root.theme.accentPrimary : (isHovered ? root.theme.textMuted : root.theme.bgBorder)
                        border.width: isSelected ? 1.5 : 1

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: optRow
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Selection Indicator Circle
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: isSelected ? root.theme.accentPrimary : root.theme.textMuted
                                border.width: isSelected ? 2 : 1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.theme.accentPrimary
                                    visible: isSelected
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    text: targetOptCard.modelData.title
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: isSelected
                                    color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                }

                                Text {
                                    text: targetOptCard.modelData.desc
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }

                        HoverHandler { id: optHover }

                        MouseArea {
                            id: optMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addBarChosenTarget = targetOptCard.modelData.id
                        }
                    }
                }
            }

            // Dock Edge Position Selector
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Dock Edge Position"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textSecondary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "top", label: "Top" },
                            { id: "bottom", label: "Bottom" },
                            { id: "left", label: "Left" },
                            { id: "right", label: "Right" }
                        ]
                        delegate: Rectangle {
                            id: posBtn
                            required property var modelData
                            readonly property bool isSelected: root.addBarChosenPosition === modelData.id
                            readonly property bool isHovered: posHover.hovered

                            Layout.fillWidth: true
                            height: 34
                            radius: 8
                            scale: posMouse.pressed ? 0.95 : (isHovered ? 1.03 : 1.0)
                            color: isSelected
                                ? (root.theme.bgSelected || root.withAlpha(root.theme.accentPrimary, 0.2))
                                : (isHovered ? root.withAlpha(root.theme.accentPrimary, 0.08) : root.theme.bgBase)
                            border.color: isSelected ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: isSelected ? 1.5 : 1

                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: posBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: isSelected
                                color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            HoverHandler { id: posHover }

                            MouseArea {
                                id: posMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.addBarChosenPosition = posBtn.modelData.id
                            }
                        }
                    }
                }
            }

            // Footer Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    implicitWidth: cancelText.implicitWidth + 28
                    height: 34
                    radius: 8
                    scale: cancelMouse.pressed ? 0.95 : (cancelHover.hovered ? 1.03 : 1.0)
                    color: cancelHover.hovered ? root.theme.bgSelected : root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: root.font
                        font.pixelSize: 12
                        color: cancelHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: cancelHover }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addBarModalVisible = false
                    }
                }

                // Confirm & Add Bar Button
                Rectangle {
                    implicitWidth: addConfirmText.implicitWidth + 32
                    height: 34
                    radius: 8
                    scale: addConfirmMouse.pressed ? 0.95 : (addConfirmHover.hovered ? 1.03 : 1.0)
                    color: addConfirmHover.hovered
                        ? (root.theme.accentPrimary || "#7aa2f7")
                        : (root.theme.bgSelected || root.withAlpha(root.theme.accentPrimary, 0.2))
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        id: addConfirmText
                        anchors.centerIn: parent
                        text: "Add Bar"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: addConfirmHover.hovered ? root.theme.bgBase : root.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: addConfirmHover }

                    MouseArea {
                        id: addConfirmMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmAddBar()
                    }
                }
            }
        }
    }
}
