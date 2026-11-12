import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: pr
    property string title: ""
    property string subtitle: ""
    default property alias content: rowSlot.data

    Layout.fillWidth: true
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: pr.title
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                visible: pr.subtitle !== ""
                Layout.fillWidth: true
                text: pr.subtitle
                font.family: Style.font
                font.pixelSize: Style.px(11)
                font.weight: Style.fontWeightEnum
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: rowSlot
            spacing: 8
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
    }
}
