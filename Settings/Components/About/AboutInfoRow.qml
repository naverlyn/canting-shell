import QtQuick
import QtQuick.Layouts
import "../Common"

Rectangle {
    id: infoRow
    required property var theme
    required property string font
    property string iconText: ""
    property string label: ""
    property string value: ""
    property bool showDivider: true

    signal copied(string label, string value)

    Layout.fillWidth: true
    height: 38
    radius: 8
    color: rowMouse.pressed
        ? Style.withAlpha(theme.accentPrimary, 0.14)
        : (rowHover.hovered ? theme.bgHover : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: rowHover }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            visible: infoRow.iconText !== ""
            text: infoRow.iconText
            font.family: infoRow.font
            font.pixelSize: Style.px(14)
            color: rowHover.hovered ? infoRow.theme.accentPrimary : infoRow.theme.textSecondary
            Layout.preferredWidth: 16
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            text: infoRow.label
            font.family: infoRow.font
            font.pixelSize: Style.px(12)
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: infoRow.theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: infoRow.value
            font.family: infoRow.font
            font.pixelSize: Style.px(12)
            font.bold: true
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: infoRow.theme.textPrimary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (infoRow.value !== "") {
                infoRow.copied(infoRow.label, infoRow.value);
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Style.withAlpha(infoRow.theme.bgBorder, 0.5)
        visible: infoRow.showDivider
    }
}
