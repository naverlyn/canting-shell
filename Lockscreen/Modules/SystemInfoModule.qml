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

    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined) ? Boolean(moduleData.showCard) : true

    implicitWidth: Math.max(160, Math.round(260 * root.scaleFactor))
    implicitHeight: mainCol.implicitHeight + Math.round(16 * root.scaleFactor)
    radius: Math.max(8, Math.round(14 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: Math.max(6, Math.round(10 * root.scaleFactor))
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "󰍛 System Resources"
                font.family: root.font
                font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                font.bold: true
                color: root.theme.textSecondary
                style: root.showCard ? Text.Normal : Text.Outline
                styleColor: root.theme.bgOverlay
            }
            Item { Layout.fillWidth: true }
            Text {
                text: SystemInfo.temperature
                font.family: root.font
                font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor))
                color: root.theme.accentOrange
                style: root.showCard ? Text.Normal : Text.Outline
                styleColor: root.theme.bgOverlay
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Math.max(3, Math.round(6 * root.scaleFactor))
            columnSpacing: Math.max(3, Math.round(6 * root.scaleFactor))

            // CPU
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(20, Math.round(34 * root.scaleFactor))
                radius: Math.max(4, Math.round(8 * root.scaleFactor))
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.max(3, Math.round(6 * root.scaleFactor))
                    spacing: 4
                    Text { text: "󰻠"; font.family: root.font; font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor)); color: root.theme.accentOrange }
                    Text { text: "CPU"; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); color: root.theme.textSecondary }
                    Item { Layout.fillWidth: true }
                    Text { text: SystemInfo.cpuUsage; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); font.bold: true; color: root.theme.textPrimary }
                }
            }

            // RAM
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(20, Math.round(34 * root.scaleFactor))
                radius: Math.max(4, Math.round(8 * root.scaleFactor))
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.max(3, Math.round(6 * root.scaleFactor))
                    spacing: 4
                    Text { text: "󰍛"; font.family: root.font; font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor)); color: root.theme.accentCyan }
                    Text { text: "RAM"; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); color: root.theme.textSecondary }
                    Item { Layout.fillWidth: true }
                    Text { text: SystemInfo.memoryUsage; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); font.bold: true; color: root.theme.textPrimary }
                }
            }

            // Disk
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(20, Math.round(34 * root.scaleFactor))
                radius: Math.max(4, Math.round(8 * root.scaleFactor))
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.max(3, Math.round(6 * root.scaleFactor))
                    spacing: 4
                    Text { text: ""; font.family: root.font; font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor)); color: root.theme.accentGreen }
                    Text { text: "Disk"; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); color: root.theme.textSecondary }
                    Item { Layout.fillWidth: true }
                    Text { text: SystemInfo.diskUsage; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); font.bold: true; color: root.theme.textPrimary }
                }
            }

            // Power
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(20, Math.round(34 * root.scaleFactor))
                radius: Math.max(4, Math.round(8 * root.scaleFactor))
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.max(3, Math.round(6 * root.scaleFactor))
                    spacing: 4
                    Text { text: SystemInfo.batteryIcon || "󰁹"; font.family: root.font; font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor)); color: root.theme.accentPrimary }
                    Text { text: "Power"; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); color: root.theme.textSecondary }
                    Item { Layout.fillWidth: true }
                    Text { text: SystemInfo.batteryLevel; font.family: root.font; font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor)); font.bold: true; color: root.theme.textPrimary }
                }
            }
        }
    }
}
