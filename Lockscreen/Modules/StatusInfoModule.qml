import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property string layoutStr: "English (US)"
    property string uptimeStr: "up 1 hour, 46 minutes"

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

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        spacing: Math.max(2, Math.round(4 * root.scaleFactor))

        Text {
            Layout.alignment: (root.moduleData && root.moduleData.halign === "left")
                ? Qt.AlignLeft
                : ((root.moduleData && root.moduleData.halign === "center") ? Qt.AlignHCenter : Qt.AlignRight)
            text: root.layoutStr
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 13) * root.scaleFactor))
            color: root.theme.accentCyan
            style: Text.Outline
            styleColor: root.theme.bgOverlay
        }

        Text {
            Layout.alignment: (root.moduleData && root.moduleData.halign === "left")
                ? Qt.AlignLeft
                : ((root.moduleData && root.moduleData.halign === "center") ? Qt.AlignHCenter : Qt.AlignRight)
            text: root.uptimeStr
            font.family: root.font
            font.pixelSize: Math.max(8, Math.round(((root.moduleData && Number(root.moduleData.fontSize)) ? Number(root.moduleData.fontSize) : 13) * root.scaleFactor))
            color: root.theme.accentPrimary
            style: Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}

