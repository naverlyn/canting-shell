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

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : true

    function resolveColor(colStr) {
        const t = root.theme;
        if (!colStr) return t.accentCyan;
        const str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str === "$accent" || str === "$accentPrimary" || str === "$mauve" || str === "$pink" || str === "$color5" || str === "$color13") return t.accentPrimary;
        if (str === "$blue" || str === "$cyan" || str === "$sapphire" || str === "$sky" || str === "$lavender" || str === "$color4" || str === "$color6" || str === "$color12") return t.accentCyan;
        if (str === "$green" || str === "$teal" || str === "$color2" || str === "$color14") return t.accentGreen;
        if (str === "$yellow" || str === "$orange" || str === "$peach" || str === "$color3" || str === "$color11") return t.accentOrange;
        if (str === "$red" || str === "$maroon" || str === "$flamingo" || str === "$color1" || str === "$color9") return t.accentRed;
        if (str === "$text" || str === "$rosewater" || str === "$color15" || str === "$foreground") return t.textPrimary;
        if (str === "$secondary" || str === "$subtext1" || str === "$color10" || str === "$color7") return t.textSecondary;
        if (str === "$muted" || str === "$subtext0" || str === "$overlay2" || str === "$color8") return t.textMuted;
        if (str === "$surface2" || str === "$overlay1") return t.bgSelected;
        if (str === "$surface1" || str === "$overlay0") return t.bgHover;
        if (str === "$surface0" || str === "$color0") return t.bgSurface;
        if (str === "$base" || str === "$mantle" || str === "$crust" || str === "$background") return t.bgBase;
        return t.accentCyan;
    }

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
