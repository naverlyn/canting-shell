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

    readonly property int memPct: parsePercent(SystemInfo.memoryUsage)

    implicitWidth: Math.max(90, Math.round(140 * root.scaleFactor))
    implicitHeight: Math.max(22, Math.round(38 * root.scaleFactor))
    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
    border.width: 1
    border.color: root.theme.bgBorder

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        Text {
            text: "󰍛"
            font.family: root.font
            font.pixelSize: Math.max(10, Math.round(16 * root.scaleFactor))
            color: root.theme.accentCyan
        }

        ColumnLayout {
            spacing: 2
            RowLayout {
                spacing: 4
                Text {
                    text: "RAM"
                    font.family: root.font
                    font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textSecondary
                }
                Text {
                    text: SystemInfo.memoryUsage
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(11 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Rectangle {
                width: Math.max(30, Math.round(60 * root.scaleFactor))
                height: Math.max(2, Math.round(4 * root.scaleFactor))
                radius: height / 2
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.15)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(2, Math.min(parent.width, parent.width * (root.memPct / 100.0)))
                    color: root.theme.accentCyan
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
