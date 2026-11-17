import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: editBanner
    required property var hostCenter

    visible: ControlCenterConfig.isLiveEdit
    width: parent.width
    height: 38
    radius: 10
    color: Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.12)
    border.color: Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.55)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        Text {
            text: "󰏫"
            font.family: hostCenter.font
            font.pixelSize: 13
            color: hostCenter.theme.accentPrimary
        }

        Text {
            text: "Edit Mode"
            font.family: hostCenter.font
            font.pixelSize: 12
            font.bold: true
            color: hostCenter.theme.textPrimary
        }

        Text {
            text: "· Drag cards or tiles to reorder"
            font.family: hostCenter.font
            font.pixelSize: 10
            color: hostCenter.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // 1P / 2P / 3P Segmented Panel Count Selector
        Rectangle {
            visible: ControlCenterConfig.panelLayout === "horizontal"
            implicitWidth: pCountRow.implicitWidth + 4
            height: 26
            radius: 6
            color: Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.05)
            border.color: hostCenter.theme.bgBorder
            border.width: 1

            Row {
                id: pCountRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: [1, 2, 3]
                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool isActiveCount: ControlCenterConfig.panelCount === modelData
                        width: 26
                        height: 20
                        radius: 4
                        color: isActiveCount
                            ? hostCenter.theme.accentPrimary
                            : (pCountMouse.containsMouse
                                ? Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.12)
                                : "transparent")
                        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData + "P"
                            font.family: hostCenter.font
                            font.pixelSize: 10
                            font.bold: true
                            color: isActiveCount ? hostCenter.theme.bgBase : hostCenter.theme.textSecondary
                        }

                        MouseArea {
                            id: pCountMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: ControlCenterConfig.setPanelCount(modelData)
                        }
                    }
                }
            }
        }

        // Reset to default button
        Rectangle {
            implicitWidth: resetRow.implicitWidth + 14
            height: 26
            radius: 6
            color: resetMouse.containsMouse
                ? Qt.rgba(hostCenter.theme.accentRed.r, hostCenter.theme.accentRed.g, hostCenter.theme.accentRed.b, 0.16)
                : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06)
            border.color: resetMouse.containsMouse ? hostCenter.theme.accentRed : hostCenter.theme.bgBorder
            border.width: 1
            scale: resetMouse.pressed ? 0.96 : 1.0
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            Row {
                id: resetRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰑐"
                    font.family: hostCenter.font
                    font.pixelSize: 11
                    color: resetMouse.containsMouse ? hostCenter.theme.accentRed : hostCenter.theme.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Reset"
                    font.family: hostCenter.font
                    font.pixelSize: 11
                    color: resetMouse.containsMouse ? hostCenter.theme.accentRed : hostCenter.theme.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                onClicked: ControlCenterConfig.resetDefaults()
            }
        }

        // Done button
        Rectangle {
            implicitWidth: doneRow.implicitWidth + 16
            height: 26
            radius: 6
            color: doneMouse.containsMouse ? Qt.lighter(hostCenter.theme.accentPrimary, 1.12) : hostCenter.theme.accentPrimary
            scale: doneMouse.pressed ? 0.96 : 1.0
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            Row {
                id: doneRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰄬"
                    font.family: hostCenter.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostCenter.theme.bgBase
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Done"
                    font.family: hostCenter.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostCenter.theme.bgBase
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: doneMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                onClicked: ControlCenterConfig.isLiveEdit = false
            }
        }
    }
}
