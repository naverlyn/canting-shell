import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: actBtn
    property string iconText: ""
    property string label: ""
    property bool danger: false
    property bool btnEnabled: true
    property int btnHeight: 32
    signal clicked()

    readonly property color activeCol: danger ? Style.theme.accentRed : Style.theme.accentPrimary

    implicitWidth: actRow.implicitWidth + 24
    implicitHeight: btnHeight
    width: implicitWidth
    height: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter
    radius: 8
    opacity: btnEnabled ? 1.0 : 0.4
    scale: actMouse.pressed ? 0.95 : (actHover.hovered && actBtn.btnEnabled ? 1.02 : 1.0)
    color: !btnEnabled
        ? Style.theme.bgBase
        : (danger
            ? (actMouse.pressed
                ? Style.withAlpha(Style.theme.accentRed, 0.28)
                : (actHover.hovered ? Style.withAlpha(Style.theme.accentRed, 0.20) : Style.withAlpha(Style.theme.accentRed, 0.10)))
            : (actMouse.pressed
                ? Style.theme.bgSelected
                : (actHover.hovered ? Style.withAlpha(Style.theme.accentPrimary, 0.14) : Style.theme.bgBase)))
    border.color: danger
        ? "transparent"
        : (actHover.hovered && btnEnabled ? Style.withAlpha(Style.theme.accentPrimary, 0.5) : Style.theme.bgBorder)
    border.width: danger ? 0 : 1

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 140 } }

    HoverHandler { id: actHover }

    Row {
        id: actRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: actBtn.iconText !== ""
            width: 14
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text: actBtn.iconText
            font.family: Style.font
            font.pixelSize: 12
            color: actBtn.danger
                ? Style.theme.accentRed
                : (actHover.hovered && actBtn.btnEnabled ? actBtn.activeCol : Style.theme.textSecondary)

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            id: actTxt
            anchors.verticalCenter: parent.verticalCenter
            text: actBtn.label
            font.family: Style.font
            font.pixelSize: 11
            font.bold: true
            color: actBtn.danger
                ? Style.theme.accentRed
                : (actHover.hovered && actBtn.btnEnabled ? actBtn.activeCol : Style.theme.textPrimary)

            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    MouseArea {
        id: actMouse
        anchors.fill: parent
        enabled: actBtn.btnEnabled
        cursorShape: actBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: actBtn.clicked()
    }
}
