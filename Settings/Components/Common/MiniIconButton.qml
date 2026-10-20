import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: miniBtn
    property string iconText: ""
    property bool dangerHover: false
    property bool btnEnabled: true
    signal clicked()

    readonly property color hoverCol: dangerHover ? Style.theme.accentRed : Style.theme.accentPrimary

    implicitWidth: 24
    implicitHeight: 24
    width: 24
    height: 24
    Layout.preferredWidth: 24
    Layout.preferredHeight: 24
    Layout.alignment: Qt.AlignVCenter
    radius: 6
    scale: btnMouse.pressed ? 0.88 : (btnHover.hovered && miniBtn.btnEnabled ? 1.10 : 1.0)
    color: !btnEnabled
        ? "transparent"
        : (btnMouse.pressed
            ? Style.withAlpha(hoverCol, 0.26)
            : (btnHover.hovered ? Style.withAlpha(hoverCol, 0.16) : "transparent"))
    border.width: 0
    opacity: btnEnabled ? 1.0 : 0.3

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    HoverHandler { id: btnHover; enabled: miniBtn.btnEnabled }

    Text {
        anchors.centerIn: parent
        text: miniBtn.iconText
        font.family: Style.font
        font.pixelSize: 12
        color: miniBtn.btnEnabled
            ? (btnHover.hovered ? miniBtn.hoverCol : Style.theme.textMuted)
            : Style.theme.textMuted

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        enabled: miniBtn.btnEnabled
        cursorShape: miniBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: miniBtn.clicked()
    }
}
