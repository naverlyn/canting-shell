import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../../notifications"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    Layout.fillWidth: true
    implicitHeight: composerCol.implicitHeight + 24
    radius: 10
    color: root.theme.bgBase
    border.color: root.theme.bgBorder
    border.width: 1

    ColumnLayout {
        id: composerCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰏫  Test Notification Content"
                font.family: root.font
                font.pixelSize: Style.px(12)
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "·  Customize the sample icon, text, and buttons before sending a live test"
                font.family: root.font
                font.pixelSize: Style.px(11)
                color: root.theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Row A: Icon Selector Chips + Custom Glyph Input
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Icon"
                font.family: root.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 95
            }

            RowLayout {
                spacing: 5
                Repeater {
                    model: ["󰂚", "󰄄", "󰖣", "󰓇", "󰞷", "󰀦", "󰊫", "󰇚"]
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool isChosen: NotificationService.composerIcon === modelData
                        width: 28
                        height: 28
                        radius: 6
                        color: isChosen ? root.theme.bgSelected : (glyphHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                        border.color: isChosen ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1

                        HoverHandler { id: glyphHover }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            color: isChosen ? root.theme.accentPrimary : root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.composerPreset = "custom";
                                NotificationService.composerIcon = modelData;
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 64
                height: 28
                radius: 6
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                TextInput {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: root.font
                    font.pixelSize: Style.px(12)
                    color: root.theme.textPrimary
                    text: NotificationService.composerIcon
                    selectByMouse: true
                    onTextEdited: {
                        NotificationService.composerPreset = "custom";
                        NotificationService.composerIcon = text;
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Urgency Segmented Switch
            Text {
                text: "Urgency:"
                font.family: root.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: root.theme.textSecondary
            }

            Rectangle {
                width: 170
                height: 28
                radius: 6
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 2

                    Repeater {
                        model: [
                            { label: "Low",      val: NotificationUrgency.Low },
                            { label: "Normal",   val: NotificationUrgency.Normal },
                            { label: "Critical", val: NotificationUrgency.Critical }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isUrg: NotificationService.composerUrgency === modelData.val
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: isUrg ? root.theme.bgSelected : "transparent"
                            border.color: isUrg ? root.theme.accentPrimary : "transparent"
                            border.width: isUrg ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: root.font
                                font.pixelSize: Style.px(10)
                                font.bold: isUrg
                                color: isUrg ? root.theme.accentPrimary : root.theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NotificationService.composerPreset = "custom";
                                    NotificationService.composerUrgency = modelData.val;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Row B: App Name & Title Notification
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "App & Title"
                font.family: root.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 95
            }

            Rectangle {
                Layout.preferredWidth: 150
                height: 30
                radius: 6
                color: root.theme.bgSurface
                border.color: appNameInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: appNameInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
                    color: root.theme.textPrimary
                    text: NotificationService.composerAppName
                    selectByMouse: true
                    clip: true
                    onTextEdited: {
                        NotificationService.composerPreset = "custom";
                        NotificationService.composerAppName = text;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: root.theme.bgSurface
                border.color: titleInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: titleInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
                    font.bold: true
                    color: root.theme.textPrimary
                    text: NotificationService.composerTitle
                    selectByMouse: true
                    clip: true
                    onTextEdited: {
                        NotificationService.composerPreset = "custom";
                        NotificationService.composerTitle = text;
                    }
                }
            }
        }

        // Row C: Body Message & Thumbnail Toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Body Message"
                font.family: root.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 95
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: root.theme.bgSurface
                border.color: bodyInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: bodyInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
                    color: root.theme.textPrimary
                    text: NotificationService.composerBody
                    selectByMouse: true
                    clip: true
                    onTextEdited: {
                        NotificationService.composerPreset = "custom";
                        NotificationService.composerBody = text;
                    }
                }
            }

            Rectangle {
                implicitWidth: imgToggleRow.implicitWidth + 16
                height: 30
                radius: 6
                color: NotificationService.composerShowImage ? root.theme.bgSelected : root.theme.bgSurface
                border.color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                RowLayout {
                    id: imgToggleRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "󰋩"
                        font.family: root.font
                        font.pixelSize: Style.px(12)
                        color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.textMuted
                    }

                    Text {
                        text: NotificationService.composerShowImage ? "Thumbnail: ON" : "Thumbnail: OFF"
                        font.family: root.font
                        font.pixelSize: Style.px(10)
                        font.bold: NotificationService.composerShowImage
                        color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.composerPreset = "custom";
                        NotificationService.composerShowImage = !NotificationService.composerShowImage;
                    }
                }
            }
        }

        // Row D: Action Buttons Builder
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Action Buttons"
                font.family: root.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 95
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: NotificationService.composerButtons
                    delegate: Rectangle {
                        id: btnChip
                        required property var modelData
                        required property int index

                        width: 124
                        height: 28
                        radius: 6
                        color: root.theme.bgSurface
                        border.color: btnLblInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 4
                            spacing: 4

                            TextInput {
                                id: btnLblInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: Style.px(11)
                                font.bold: true
                                color: root.theme.accentPrimary
                                text: btnChip.modelData.label || ""
                                selectByMouse: true
                                clip: true
                                onTextEdited: {
                                    NotificationService.composerPreset = "custom";
                                    NotificationService.updateComposerButton(btnChip.index, text, btnChip.modelData.cmd);
                                }
                            }

                            MiniIconButton {
                                iconText: "󰅖"
                                dangerHover: true
                                onClicked: {
                                    NotificationService.composerPreset = "custom";
                                    NotificationService.removeComposerButton(btnChip.index);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: (NotificationService.composerButtons || []).length < 4
                    implicitWidth: addBtnChipRow.implicitWidth + 16
                    height: 28
                    radius: 6
                    color: addBtnChipHover.hovered ? root.theme.bgHover : root.theme.bgSurface
                    border.color: addBtnChipHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    HoverHandler { id: addBtnChipHover }

                    RowLayout {
                        id: addBtnChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰐕"
                            font.family: root.font
                            font.pixelSize: Style.px(10)
                            color: root.theme.accentPrimary
                        }

                        Text {
                            text: "Add Button"
                            font.family: root.font
                            font.pixelSize: Style.px(10)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.addComposerButton("Action", "");
                        }
                    }
                }
            }
        }
    }
}
