import QtQuick
import QtQuick.Layouts
import "../../bar"
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    width: parent ? parent.width : 300
    height: cavaCol.implicitHeight + 24
    implicitHeight: cavaCol.implicitHeight + 24
    implicitWidth: width
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: cavaCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        // Header Row: Title & Style Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰝛 Cava Visualizer"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
            }

            Rectangle {
                implicitWidth: statusText.implicitWidth + 10
                height: 18
                radius: 9
                color: CavaService.hasAudio
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
                border.color: CavaService.hasAudio ? root.theme.accentPrimary : "transparent"
                border.width: 1

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: CavaService.hasAudio ? "Active" : "Silent"
                    font.family: root.font
                    font.pixelSize: 9
                    font.bold: true
                    color: CavaService.hasAudio ? root.theme.accentPrimary : root.theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            // Style Switcher Chips (Bars / Glyphs / Line)
            RowLayout {
                spacing: 4

                Repeater {
                    model: [
                        { id: "bars", label: "󰝛 Bars" },
                        { id: "glyphs", label: "󰘦 Glyphs" },
                        { id: "line", label: "󰄲 Line" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: styleChipText.implicitWidth + 10
                        height: 22
                        radius: 4
                        readonly property bool isCur: BarConfig.cavaStyle === modelData.id
                        readonly property bool isHovered: styleMouse.containsMouse

                        color: isCur
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.25)
                            : (isHovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04))
                        border.color: isCur ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1

                        Text {
                            id: styleChipText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: isCur
                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        MouseArea {
                            id: styleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.cavaStyle = modelData.id
                        }
                    }
                }
            }
        }

        // Visualizer Canvas Card
        Rectangle {
            Layout.fillWidth: true
            height: 56
            radius: 8
            color: root.theme.bgBase
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            // Bars visualizer mode
            Row {
                anchors.centerIn: parent
                spacing: 4
                visible: BarConfig.cavaStyle === "bars"

                Repeater {
                    model: (CavaService.values && CavaService.values.length > 0) ? CavaService.values.length : 8
                    delegate: Rectangle {
                        required property int index
                        width: Math.max(4, Math.min(14, (parent.parent.width - 40) / Math.max(1, CavaService.values.length) - 4))
                        height: Math.max(3, Math.min(46, (CavaService.values && CavaService.values[index] !== undefined ? CavaService.values[index] : 0) * 0.46))
                        radius: 2
                        color: root.theme.accentPrimary
                        opacity: CavaService.hasAudio ? 0.95 : 0.25
                        anchors.bottom: parent.bottom
                        Behavior on height { NumberAnimation { duration: 45 } }
                    }
                }
            }

            // Glyphs visualizer mode
            Text {
                anchors.centerIn: parent
                visible: BarConfig.cavaStyle === "glyphs"
                text: CavaService.glyphText || " "
                font.family: root.font
                font.pixelSize: 18
                color: root.theme.accentPrimary
                opacity: CavaService.hasAudio ? 1.0 : 0.35
            }

            // Line visualizer mode
            Row {
                anchors.centerIn: parent
                spacing: 2
                visible: BarConfig.cavaStyle === "line"

                Repeater {
                    model: (CavaService.values && CavaService.values.length > 0) ? CavaService.values.length : 8
                    delegate: Rectangle {
                        required property int index
                        width: Math.max(3, Math.min(10, (parent.parent.width - 40) / Math.max(1, CavaService.values.length) - 2))
                        height: Math.max(2, Math.min(44, (CavaService.values && CavaService.values[index] !== undefined ? CavaService.values[index] : 0) * 0.44))
                        radius: 1
                        color: root.theme.accentPrimary
                        opacity: CavaService.hasAudio ? 0.85 : 0.2
                        anchors.bottom: parent.bottom
                        Behavior on height { NumberAnimation { duration: 40 } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (BarConfig.cavaStyle === "bars") BarConfig.cavaStyle = "glyphs";
                    else if (BarConfig.cavaStyle === "glyphs") BarConfig.cavaStyle = "line";
                    else BarConfig.cavaStyle = "bars";
                }
            }
        }

        // Bottom Controls Row: Stereo / Mono Toggle & Framerate
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Stereo / Mono Toggle Chip
            Rectangle {
                implicitWidth: stereoText.implicitWidth + 12
                height: 22
                radius: 4
                color: stereoMouse.containsMouse
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                border.color: BarConfig.cavaStereo ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: 1

                Text {
                    id: stereoText
                    anchors.centerIn: parent
                    text: BarConfig.cavaStereo ? "󰎈 Stereo" : "󰕾 Mono"
                    font.family: root.font
                    font.pixelSize: 9
                    font.bold: BarConfig.cavaStereo
                    color: BarConfig.cavaStereo ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    id: stereoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarConfig.cavaStereo = !BarConfig.cavaStereo
                }
            }

            // Bars Count Badge
            Text {
                text: (BarConfig.cavaBars || 8) + " Bars · " + (BarConfig.cavaFramerate || 30) + " FPS"
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Click canvas to cycle style"
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.textMuted
            }
        }
    }
}
