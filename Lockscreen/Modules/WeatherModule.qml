import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../bar"
import ".."
import "../../utils/ColorUtils.js" as ColorUtils

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property string weatherRawText: ""

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : true

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.textPrimary); }

    // Process to read local weather cache
    Process {
        id: weatherProc
        command: ["sh", "-c", "[ -f ~/.cache/.weather_cache ] && cat ~/.cache/.weather_cache || echo 'Weather Unavailable'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t) root.weatherRawText = t;
            }
        }
    }

    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    readonly property bool isMultiline: (root.moduleData && root.moduleData.displayMode === "compact") ? false : root.weatherRawText.includes("\n")

    implicitWidth: isMultiline
        ? (multilineText.implicitWidth + (root.showCard ? Math.round(24 * root.scaleFactor) : 0))
        : (compactRow.implicitWidth + (root.showCard ? Math.round(24 * root.scaleFactor) : 0))

    implicitHeight: isMultiline
        ? (multilineText.implicitHeight + (root.showCard ? Math.round(16 * root.scaleFactor) : 0))
        : (root.showCard ? Math.max(22, Math.round(38 * root.scaleFactor)) : compactRow.implicitHeight)

    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    // 1. Detailed multi-line view
    Text {
        id: multilineText
        visible: root.isMultiline
        anchors.centerIn: parent
        text: root.weatherRawText || "Weather loading..."
        font.family: root.font
        font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 12) * root.scaleFactor))
        lineHeight: 1.25
        color: root.showCard
            ? root.theme.textPrimary
            : root.resolveColor(root.moduleData ? root.moduleData.color : "$color10")
        style: root.showCard ? Text.Normal : Text.Outline
        styleColor: root.theme.bgOverlay
    }

    // 2. Compact single-line view
    RowLayout {
        id: compactRow
        visible: !root.isMultiline
        anchors.centerIn: parent
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        Text {
            text: "󰖕"
            font.family: root.font
            font.pixelSize: Math.max(10, Math.round(16 * root.scaleFactor))
            color: root.theme.accentCyan
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }

        Text {
            text: SystemInfo.weatherInfo || (root.weatherRawText ? root.weatherRawText.split("\n")[0] : "Weather")
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 12) * root.scaleFactor))
            font.bold: true
            color: root.showCard
                ? root.theme.textPrimary
                : root.resolveColor(root.moduleData ? root.moduleData.color : "$text")
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}
