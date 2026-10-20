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
                text: pr.title
                font.family: Style.font
                font.pixelSize: 13
                font.bold: true
                color: Style.theme.textPrimary
            }

            Text {
                visible: pr.subtitle !== ""
                text: pr.subtitle
                font.family: Style.font
                font.pixelSize: 11
                color: Style.theme.textSecondary
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
