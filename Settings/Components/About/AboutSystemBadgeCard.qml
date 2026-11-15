import QtQuick
import QtQuick.Layouts

Rectangle {
    id: badgeCard
    required property var theme
    required property string font
    required property string osName
    required property string hostModel

    Layout.fillWidth: true
    height: 72
    radius: 12
    color: theme.bgSurface
    border.color: theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: badgeCard.osName
                font.family: badgeCard.font
                font.pixelSize: 18
                font.bold: true
                color: badgeCard.theme.textPrimary
            }

            Text {
                text: badgeCard.hostModel
                font.family: badgeCard.font
                font.pixelSize: 13
                color: badgeCard.theme.textSecondary
            }
        }
    }
}
