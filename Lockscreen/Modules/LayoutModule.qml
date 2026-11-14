import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../../utils/ColorUtils.js" as ColorUtils

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property string layoutStr: "English (US)"

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : true

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.accentCyan); }

    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // \"English (US)\"' 2>/dev/null || echo 'English (US)'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t) root.layoutStr = t;
            }
        }
    }

    implicitWidth: root.showCard
        ? (row.implicitWidth + Math.round(24 * root.scaleFactor))
        : row.implicitWidth
    implicitHeight: root.showCard
        ? Math.max(22, Math.round(38 * root.scaleFactor))
        : row.implicitHeight

    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        Text {
            text: "󰌌"
            font.family: root.font
            font.pixelSize: Math.max(9, Math.round(15 * root.scaleFactor))
            color: root.resolveColor(root.moduleData ? root.moduleData.color : "$color12")
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }

        Text {
            text: root.layoutStr
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 12) * root.scaleFactor))
            font.bold: root.showCard
            color: root.showCard
                ? root.theme.textPrimary
                : root.resolveColor(root.moduleData ? root.moduleData.color : "$color12")
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}
