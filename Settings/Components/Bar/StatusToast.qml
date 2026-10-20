import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: statusToast
    z: 10000
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 16
    implicitWidth: toastRow.implicitWidth + 32
    height: 38
    radius: 19
    color: root.toastIsWarning ? root.withAlpha(root.theme.accentRed, 0.25) : (root.theme.bgSelected ?? "#283457")
    border.color: root.toastIsWarning ? root.theme.accentRed : (root.theme.accentPrimary ?? "#7aa2f7")
    border.width: 1.5
    opacity: root.toastVisible ? 1.0 : 0.0
    scale: root.toastVisible ? 1.0 : 0.92
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    RowLayout {
        id: toastRow
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: toastText
            text: root.toastMessage
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
        }
    }
}
