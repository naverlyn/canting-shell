import QtQuick
import QtQuick.Layouts
import "../../bar"
import ".."
import "../../utils/FormatUtils.js" as FormatUtils

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    function parsePercent(str) { return FormatUtils.parsePercent(str); }

    readonly property int batPct: parsePercent(SystemInfo.batteryLevel)
    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined) ? Boolean(moduleData.showCard) : true

    implicitWidth: Math.max(80, Math.round(120 * root.scaleFactor))
    implicitHeight: Math.max(22, Math.round(38 * root.scaleFactor))
    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
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
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }

        Text {
            text: SystemInfo.batteryLevel + (SystemInfo.batteryCharging ? " 󱐋" : "")
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
            font.bold: true
            color: root.theme.textPrimary
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}
