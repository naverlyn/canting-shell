import QtQuick
import QtQuick.Layouts
import ".."

                    Rectangle {
                        id: editBanner
    required property var hostCenter
                        visible: ControlCenterConfig.isLiveEdit
                        width: parent.width
                        height: 36
                        radius: 8
                        color: Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.15)
                        border.color: hostCenter.theme.accentPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
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
                                Layout.fillWidth: true
                            }

                            // 1P / 2P / 3P Panel Count Selector
                            Row {
                                visible: ControlCenterConfig.panelLayout === "horizontal"
                                spacing: 3

                                Repeater {
                                    model: [1, 2, 3]
                                    delegate: Rectangle {
                                        required property int modelData
                                        readonly property bool isActiveCount: ControlCenterConfig.panelCount === modelData
                                        width: 28
                                        height: 22
                                        radius: 4
                                        color: isActiveCount
                                            ? hostCenter.theme.accentPrimary
                                            : (pCountMouse.containsMouse
                                                ? Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.14)
                                                : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06))
                                        border.color: isActiveCount ? hostCenter.theme.accentPrimary : hostCenter.theme.bgBorder
                                        border.width: 1

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

                            // Reset to default button
                            Rectangle {
                                width: 50
                                height: 24
                                radius: 4
                                color: resetMouse.containsMouse ? Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.14) : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06)
                                border.color: hostCenter.theme.bgBorder
                                border.width: 1
                                scale: resetMouse.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    font.family: hostCenter.font
                                    font.pixelSize: 11
                                    color: hostCenter.theme.textSecondary
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
                                width: 50
                                height: 24
                                radius: 4
                                color: doneMouse.containsMouse ? Qt.lighter(hostCenter.theme.accentPrimary, 1.12) : hostCenter.theme.accentPrimary
                                scale: doneMouse.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Done"
                                    font.family: hostCenter.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: hostCenter.theme.bgBase
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
