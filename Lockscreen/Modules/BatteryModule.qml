import QtQuick
import QtQuick.Layouts
import "../../bar"
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    function parsePercent(str) {
        if (!str) return 0;
        const val = parseInt(str.toString().replace("%", "").trim());
        return isNaN(val) ? 0 : Math.max(0, Math.min(100, val));
    }

    readonly property int batPct: parsePercent(SystemInfo.batteryLevel)

    implicitWidth: Math.max(80, Math.round(120 * root.scaleFactor))
    implicitHeight: Math.max(22, Math.round(38 * root.scaleFactor))
    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
    border.width: 1
    border.color: root.theme.bgBorder

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        Text {
            text: SystemInfo.batteryIcon || "󰁹"
            font.family: root.font
            font.pixelSize: Math.max(10, Math.round(17 * root.scaleFactor))
            color: root.batPct > 20 ? root.theme.accentGreen : root.theme.accentRed
        }

        Text {
            text: SystemInfo.batteryLevel + (SystemInfo.batteryCharging ? " 󱐋" : "")
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
            font.bold: true
            color: root.theme.textPrimary
        }
    }
}
