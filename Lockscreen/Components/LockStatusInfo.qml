import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: statusRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property string weatherText: ""
    property string uptimeText: ""
    property string keyboardLayout: "English (US)"

    function refresh() {
        if (LockscreenConfig.showWeather) weatherProc.running = true;
        if (LockscreenConfig.showUptime) uptimeProc.running = true;
        if (LockscreenConfig.showLayout) layoutProc.running = true;
    }

    // Weather Reader
    Process {
        id: weatherProc
        command: ["sh", "-c", "[ -f ~/.cache/.weather_cache ] && cat ~/.cache/.weather_cache || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                statusRoot.weatherText = text.trim();
            }
        }
    }

    // Uptime Reader
    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                statusRoot.uptimeText = text.trim();
            }
        }
    }

    // Keyboard Layout Reader
    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // \"English (US)\"' 2>/dev/null || echo 'English (US)'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const cleaned = text.trim();
                if (cleaned) statusRoot.keyboardLayout = cleaned;
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: statusRoot.refresh()
    }

    Component.onCompleted: statusRoot.refresh()

    anchors.fill: parent

    // Bottom-Left: Weather Info
    Item {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 36
        anchors.bottomMargin: 32
        visible: LockscreenConfig.showWeather && statusRoot.weatherText.length > 0
        width: weatherCol.implicitWidth
        height: weatherCol.implicitHeight

        ColumnLayout {
            id: weatherCol
            spacing: 3

            Repeater {
                model: statusRoot.weatherText.split("\n")
                delegate: Text {
                    text: modelData
                    font.family: statusRoot.font
                    font.pixelSize: index === 0 ? 13 : (index === 1 ? 14 : 12)
                    font.bold: index === 1
                    color: index === 1
                           ? statusRoot.theme.accentPrimary
                           : statusRoot.theme.textSecondary
                    style: Text.Outline
                    styleColor: statusRoot.theme.bgOverlay
                }
            }
        }
    }

    // Bottom-Right: Keyboard Layout & Uptime Pills
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 36
        anchors.bottomMargin: 32
        spacing: 12

        // Keyboard Layout Pill
        Rectangle {
            visible: LockscreenConfig.showLayout
            radius: 12
            height: 32
            implicitWidth: layoutRow.implicitWidth + 24
            color: Qt.rgba(statusRoot.theme.bgSurface.r, statusRoot.theme.bgSurface.g, statusRoot.theme.bgSurface.b, 0.7)
            border.width: 1
            border.color: statusRoot.theme.bgBorder

            RowLayout {
                id: layoutRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰌌"
                    font.family: statusRoot.font
                    font.pixelSize: 13
                    color: statusRoot.theme.accentCyan
                }

                Text {
                    text: statusRoot.keyboardLayout
                    font.family: statusRoot.font
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: statusRoot.theme.textPrimary
                }
            }
        }

        // Uptime Pill
        Rectangle {
            visible: LockscreenConfig.showUptime && statusRoot.uptimeText.length > 0
            radius: 12
            height: 32
            implicitWidth: uptimeRow.implicitWidth + 24
            color: Qt.rgba(statusRoot.theme.bgSurface.r, statusRoot.theme.bgSurface.g, statusRoot.theme.bgSurface.b, 0.7)
            border.width: 1
            border.color: statusRoot.theme.bgBorder

            RowLayout {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰔟"
                    font.family: statusRoot.font
                    font.pixelSize: 13
                    color: statusRoot.theme.accentGreen
                }

                Text {
                    text: statusRoot.uptimeText
                    font.family: statusRoot.font
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: statusRoot.theme.textPrimary
                }
            }
        }
    }
}
