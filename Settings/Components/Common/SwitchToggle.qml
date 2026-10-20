import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: sw
    property bool checked: false
    signal toggled(bool newState)

    width: 44
    height: 24
    radius: 12
    color: sw.checked ? (Style.theme.accentPrimary ?? "#7aa2f7") : (Style.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

    Behavior on color { ColorAnimation { duration: 160 } }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? parent.width - width - 3 : 3
        color: sw.checked ? "#ffffff" : (Style.theme.textPrimary ?? "#c0caf5")

        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            sw.checked = !sw.checked;
            sw.toggled(sw.checked);
        }
    }
}
