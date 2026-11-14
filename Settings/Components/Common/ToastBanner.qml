import QtQuick
import QtQuick.Layouts
import "../../../utils/ColorUtils.js" as ColorUtils

Rectangle {
    id: toastRoot

    property var theme: Style.theme
    property string font: Style.font
    property int durationMs: 2500

    property string message: ""
    property bool isWarning: false
    property bool shown: false

    function show(msg, warn) {
        toastRoot.message = msg;
        toastRoot.isWarning = Boolean(warn);
        toastRoot.shown = true;
        hideTimer.restart();
    }

    z: 10000
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 16
    implicitWidth: toastRow.implicitWidth + 32
    height: 36
    radius: 18
    color: toastRoot.isWarning
        ? ColorUtils.withAlpha(toastRoot.theme.accentRed, 0.25)
        : (toastRoot.theme.bgSelected || toastRoot.theme.bgSurface || "#283457")
    border.color: toastRoot.isWarning
        ? toastRoot.theme.accentRed
        : (toastRoot.theme.accentPrimary || "#7aa2f7")
    border.width: 1.5
    opacity: toastRoot.shown ? 1.0 : 0.0
    scale: toastRoot.shown ? 1.0 : 0.94
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Timer {
        id: hideTimer
        interval: toastRoot.durationMs
        repeat: false
        onTriggered: toastRoot.shown = false
    }

    RowLayout {
        id: toastRow
        anchors.centerIn: parent
        spacing: 0

        Text {
            text: toastRoot.message
            font.family: toastRoot.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: toastRoot.theme.textPrimary
        }
    }
}
