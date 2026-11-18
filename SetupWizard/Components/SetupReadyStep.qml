import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var theme
    required property string font
    required property var detectedTools

    readonly property var toolItems: [
        { key: "awww", label: "Wallpaper (awww/swww)" },
        { key: "wallust", label: "Palette (wallust/matugen)" },
        { key: "cliphist", label: "Clipboard (cliphist)" },
        { key: "cava", label: "Audio Visualizer (cava)" },
        { key: "grim", label: "Screenshot (grim)" },
        { key: "magick", label: "ImageMagick (magick)" }
    ]

    spacing: 14

    Text {
        text: "Detected Optional Tools"
        font.family: root.font
        font.pixelSize: 14
        font.bold: true
        color: root.theme.textPrimary
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: toolsListCol.implicitHeight + 20
        radius: 10
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: toolsListCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Repeater {
                model: root.toolItems
                delegate: RowLayout {
                    required property var modelData
                    readonly property bool installed: Boolean(root.detectedTools && root.detectedTools[modelData.key])
                    Layout.fillWidth: true
                    height: 26
                    spacing: 5

                    Text {
                        text: modelData.label + " is"
                        font.family: root.font
                        font.pixelSize: 12
                        color: installed ? root.theme.textPrimary : root.theme.textMuted
                    }

                    Text {
                        text: installed ? "installed" : "not installed"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: installed
                        color: installed ? root.theme.accentPrimary : root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: readyInfoCol.implicitHeight + 24
        radius: 10
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: readyInfoCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: "You're ready to go"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "You can reopen this wizard anytime with `qs ipc call setup open`, or fine-tune everything in Settings (`SUPER + I`)."
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    Item { Layout.fillHeight: true }
}
