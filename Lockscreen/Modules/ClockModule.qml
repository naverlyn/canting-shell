import QtQuick
import QtQuick.Layouts
import ".."
import "../../utils/ColorUtils.js" as ColorUtils

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

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.textPrimary); }

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
            font.family: (root.moduleData && root.moduleData.fontFamily && root.moduleData.fontFamily !== "$font") ? root.moduleData.fontFamily : root.font
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
            font.family: (root.moduleData && root.moduleData.fontFamily && root.moduleData.fontFamily !== "$font") ? root.moduleData.fontFamily : root.font
            font.pixelSize: Math.max(8, Math.round(timeTxt.font.pixelSize * 0.28))
            font.bold: false
            color: root.theme.textSecondary
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }
    }
}
