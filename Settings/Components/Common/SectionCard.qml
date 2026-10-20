import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: secCard
    property string title: ""
    property string subtitle: ""
    property color titleColor: Style.theme.textSecondary
    property color subtitleColor: Style.theme.textMuted
    property bool subtitleBold: false
    property real subtitleMaxRatio: 0.62
    property int contentMargins: 12
    property int contentSpacing: 12
    default property alias content: secInnerCol.data

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: secCard.title
            font.family: Style.font
            font.pixelSize: 13
            font.bold: true
            color: secCard.titleColor
        }
        Item { Layout.fillWidth: true }
        Text {
            visible: secCard.subtitle !== ""
            text: secCard.subtitle
            font.family: Style.font
            font.pixelSize: 11
            font.bold: secCard.subtitleBold
            color: secCard.subtitleColor
            elide: Text.ElideRight
            Layout.maximumWidth: Math.max(180, secCard.width * secCard.subtitleMaxRatio)
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: secInnerCol.implicitHeight + secCard.contentMargins * 2
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1
        Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: secInnerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: secCard.contentMargins
            }
            spacing: secCard.contentSpacing
        }
    }
}
