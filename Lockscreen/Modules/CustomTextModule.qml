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

    property string cmdOutput: ""

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : false

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.textPrimary); }

    Process {
        id: cmdProc
        command: ["sh", "-c", (root.moduleData && root.moduleData.cmd) ? root.moduleData.cmd : ""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t) root.cmdOutput = t;
            }
        }
    }

    Timer {
        interval: Math.max(1000, Number(root.moduleData ? root.moduleData.interval : 5000) || 5000)
        running: Boolean(root.moduleData && root.moduleData.cmd)
        repeat: true
        triggeredOnStart: true
        onTriggered: if (root.moduleData && root.moduleData.cmd) cmdProc.running = true
    }

    implicitWidth: root.showCard
        ? (lbl.implicitWidth + Math.round(24 * root.scaleFactor))
        : lbl.implicitWidth
    implicitHeight: root.showCard
        ? Math.max(22, lbl.implicitHeight + Math.round(14 * root.scaleFactor))
        : lbl.implicitHeight

    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    Text {
        id: lbl
        anchors.centerIn: parent
        text: (root.moduleData && root.moduleData.cmd) ? (root.cmdOutput || "...") : (root.moduleData ? (root.moduleData.text || "Custom Text") : "")
        font.family: (root.moduleData && root.moduleData.fontFamily && root.moduleData.fontFamily !== "$font") ? root.moduleData.fontFamily : root.font
        font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 14) * root.scaleFactor))
        font.bold: root.showCard
        color: root.resolveColor(root.moduleData ? root.moduleData.color : "$text")
        style: root.showCard ? Text.Normal : Text.Outline
        styleColor: root.theme.bgOverlay
    }
}
