import QtQuick
import QtQuick.Layouts
import ".."
import "../../utils/FormatUtils.js" as FormatUtils
import "../../ThemeSwitcher"

// Reusable lockscreen metric card with icon, label, value text, and progress bar.
Rectangle {
    id: root

    property var theme: Theme
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    required property string icon
    required property string label
    required property string valueText
    required property color accentColor

    readonly property int percent: FormatUtils.parsePercent(valueText)
    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined) ? Boolean(moduleData.showCard) : true

    implicitWidth: Math.max(90, Math.round(140 * root.scaleFactor))
    implicitHeight: Math.max(22, Math.round(38 * root.scaleFactor))
    radius: Math.max(6, Math.round(12 * root.scaleFactor))
    color: root.showCard
        ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
        : "transparent"
    border.width: root.showCard ? 1 : 0
    border.color: root.theme.bgBorder

    RowLayout {
        anchors.centerIn: parent
        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

        Text {
            text: root.icon
            font.family: root.font
            font.pixelSize: Math.max(10, Math.round(16 * root.scaleFactor))
            color: root.accentColor
            style: root.showCard ? Text.Normal : Text.Outline
            styleColor: root.theme.bgOverlay
        }

        ColumnLayout {
            spacing: 2

            RowLayout {
                spacing: 4

                Text {
                    text: root.label
                    font.family: root.font
                    font.pixelSize: Math.max(7, Math.round(10 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textSecondary
                    style: root.showCard ? Text.Normal : Text.Outline
                    styleColor: root.theme.bgOverlay
                }

                Text {
                    text: root.valueText
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(11 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textPrimary
                    style: root.showCard ? Text.Normal : Text.Outline
                    styleColor: root.theme.bgOverlay
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
                    width: Math.max(2, Math.min(parent.width, parent.width * (root.percent / 100.0)))
                    color: root.accentColor

                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
