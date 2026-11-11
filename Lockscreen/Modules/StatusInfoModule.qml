import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property string layoutStr: "English (US)"
    property string uptimeStr: "up 1 hour, 46 minutes"

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : true

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

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t) root.uptimeStr = t;
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            layoutProc.running = true;
            uptimeProc.running = true;
        }
    }

    implicitWidth: root.showCard
        ? (col.implicitWidth + Math.round(24 * root.scaleFactor))
        : col.implicitWidth
    implicitHeight: root.showCard
        ? (col.implicitHeight + Math.round(16 * root.scaleFactor))
        : col.implicitHeight

    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Math.max(2, Math.round(4 * root.scaleFactor))

        RowLayout {
            Layout.alignment: (root.moduleData && root.moduleData.halign === "left")
                ? Qt.AlignLeft
                : ((root.moduleData && root.moduleData.halign === "center") ? Qt.AlignHCenter : Qt.AlignRight)
            spacing: Math.max(3, Math.round(6 * root.scaleFactor))

            Text {
                visible: root.showCard
                text: "󰌌"
                font.family: root.font
                font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor))
                color: root.theme.accentCyan
            }

            Text {
                text: root.layoutStr
                font.family: root.font
                font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 12) * root.scaleFactor))
                font.bold: root.showCard
                color: root.showCard ? root.theme.textPrimary : root.theme.accentCyan
                style: root.showCard ? Text.Normal : Text.Outline
                styleColor: root.theme.bgOverlay
            }
        }

        RowLayout {
            Layout.alignment: (root.moduleData && root.moduleData.halign === "left")
                ? Qt.AlignLeft
                : ((root.moduleData && root.moduleData.halign === "center") ? Qt.AlignHCenter : Qt.AlignRight)
            spacing: Math.max(3, Math.round(6 * root.scaleFactor))

            Text {
                visible: root.showCard
                text: "󰅐"
                font.family: root.font
                font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor))
                color: root.theme.accentPrimary
            }

            Text {
                text: root.uptimeStr
                font.family: root.font
                font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 12) * root.scaleFactor))
                color: root.showCard ? root.theme.textSecondary : root.theme.accentPrimary
                style: root.showCard ? Text.Normal : Text.Outline
                styleColor: root.theme.bgOverlay
            }
        }
    }
}
