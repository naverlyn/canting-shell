import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Rectangle {
    required property var root
    visible: root.showImportForm
    Layout.fillWidth: true
    implicitHeight: importCol.implicitHeight + 24
    radius: 12
    color: root.theme.bgSurface
    border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.45)
    border.width: 1

    ColumnLayout {
        id: importCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Import Backup Archive (.tar.gz)"
                font.family: root.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }
            MiniIconButton {
                iconText: "󰅖"
                onClicked: root.showImportForm = false
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: importInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: importInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
                    color: root.theme.textPrimary
                    selectByMouse: true
                    text: root.importFilePath
                    onTextChanged: root.importFilePath = text

                    Text {
                        visible: parent.text === "" && !parent.activeFocus
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Choose a .tar.gz archive or paste its path..."
                        font.family: root.font
                        font.pixelSize: Style.px(11)
                        color: root.theme.textMuted
                    }
                }
            }

            ActionButton {
                iconText: "󰉋"
                label: "Browse..."
                btnHeight: 32
                onClicked: {
                        onClicked: root.openFilePicker()
                }
            }

            ActionButton {
                iconText: "󰋺"
                label: "Import"
                btnHeight: 32
                btnEnabled: root.importFilePath.trim() !== ""
                onClicked: root.submitImport()
            }
        }
    }
}
