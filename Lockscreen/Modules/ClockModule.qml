import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property var currentNow: new Date()

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : false

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentNow = new Date()
    }

    function resolveColor(colStr) {
        const t = root.theme;
        if (!colStr) return t.textPrimary;
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
        return t.textPrimary;
    }

    implicitWidth: root.showCard
        ? (col.implicitWidth + Math.round(32 * root.scaleFactor))
        : col.implicitWidth
    implicitHeight: root.showCard
        ? (col.implicitHeight + Math.round(20 * root.scaleFactor))
        : col.implicitHeight

    radius: Math.max(8, Math.round(16 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Math.max(2, Math.round(4 * root.scaleFactor))

        Text {
            id: timeTxt
            Layout.alignment: (root.moduleData && root.moduleData.halign === "right")
                ? Qt.AlignRight
                : ((root.moduleData && root.moduleData.halign === "center") ? Qt.AlignHCenter : Qt.AlignLeft)
            text: {
                const clockFmt = (root.moduleData && root.moduleData.clockFormat !== undefined)
                    ? root.moduleData.clockFormat
                    : (typeof LockscreenConfig !== "undefined" ? LockscreenConfig.clock_format : "24h");
                const fmt = clockFmt === "12h" ? "hh:mm AP" : "hh:mm";
                return Qt.formatDateTime(root.currentNow, fmt);
            }
            font.family: (root.moduleData && root.moduleData.fontFamily) ? root.moduleData.fontFamily : root.font
            font.pixelSize: {
                const fs = (root.moduleData && Number(root.moduleData.fontSize))
                    ? Number(root.moduleData.fontSize)
                    : (typeof LockscreenConfig !== "undefined" ? LockscreenConfig.clock_font_size : 90);
                return Math.max(12, Math.round(fs * root.scaleFactor));
            }
            font.bold: true
            color: root.resolveColor(root.moduleData ? root.moduleData.color : "$text")
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }

        Text {
            id: dateTxt
            visible: {
                if (root.moduleData && root.moduleData.showDate !== undefined)
                    return Boolean(root.moduleData.showDate);
                return (typeof LockscreenConfig !== "undefined") ? Boolean(LockscreenConfig.show_date) : true;
            }
            Layout.alignment: timeTxt.Layout.alignment
            text: Qt.formatDateTime(root.currentNow, "dddd, dd MMMM yyyy")
            font.family: (root.moduleData && root.moduleData.fontFamily) ? root.moduleData.fontFamily : root.font
            font.pixelSize: Math.max(8, Math.round(timeTxt.font.pixelSize * 0.28))
            font.bold: false
            color: root.theme.textSecondary
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}
