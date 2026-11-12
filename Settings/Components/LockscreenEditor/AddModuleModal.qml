import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Lockscreen"

Item {
    id: modalRoot

    property var theme: DefaultTheme {}
    property string font: (modalRoot.theme && modalRoot.theme.fontFamily) ? modalRoot.theme.fontFamily : "Lato Nerd Font"

    signal moduleChosen(string modType)

    visible: false
    anchors.fill: parent
    z: 999

    // Dimmed Backdrop
    Rectangle {
        anchors.fill: parent
        color: modalRoot.theme.bgOverlay
        MouseArea {
            anchors.fill: parent
            onClicked: modalRoot.visible = false
        }
    }

    // Modal Content Card
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(540, parent.width - 40)
        implicitHeight: modalCol.implicitHeight + 28
        radius: 14
        color: modalRoot.theme.bgSurface
        border.color: modalRoot.theme.bgBorder
        border.width: 1

        // Consume click events so clicking card does not close backdrop
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: modalCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 16
            }
            spacing: 14

            // Modal Header
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Add Lock Screen Module"
                        font.family: modalRoot.font
                        font.pixelSize: 15
                        font.bold: true
                        color: modalRoot.theme.textPrimary
                    }
                    Text {
                        text: "Select a component to place on your lock screen"
                        font.family: modalRoot.font
                        font.pixelSize: 11
                        color: modalRoot.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                // Close Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: closeHover.hovered ? modalRoot.theme.bgHover : "transparent"
                    HoverHandler { id: closeHover }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: modalRoot.font
                        font.pixelSize: 11
                        color: modalRoot.theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modalRoot.visible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: modalRoot.theme.bgBorder
            }

            // Grid of Available Modules
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: LockscreenConfig.availableModuleDefs
                    delegate: Rectangle {
                        id: itemCard
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: 8
                        color: itemHover.hovered
                            ? modalRoot.theme.bgHover
                            : modalRoot.theme.bgBase
                        border.color: itemHover.hovered
                            ? modalRoot.theme.accentPrimary
                            : modalRoot.theme.bgBorder
                        border.width: 1

                        HoverHandler { id: itemHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Qt.rgba(modalRoot.theme.accentPrimary.r, modalRoot.theme.accentPrimary.g, modalRoot.theme.accentPrimary.b, 0.12)

                                Text {
                                    anchors.centerIn: parent
                                    text: itemCard.modelData.icon
                                    font.family: modalRoot.font
                                    font.pixelSize: 16
                                    color: modalRoot.theme.accentPrimary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: itemCard.modelData.name
                                    font.family: modalRoot.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modalRoot.theme.textPrimary
                                }

                                Text {
                                    text: itemCard.modelData.desc
                                    font.family: modalRoot.font
                                    font.pixelSize: 10
                                    color: modalRoot.theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modalRoot.moduleChosen(itemCard.modelData.type);
                                modalRoot.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}

