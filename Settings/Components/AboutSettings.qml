import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./About"

Item {
    id: root
    property var theme
    property string font

    property string osName: "Linux"
    property string hostModel: "Generic System"
    property string cpuModel: "Unknown CPU"
    property string ramSize: "Unknown RAM"
    property string gpuModel: "Unknown GPU"
    property string diskSize: "Unknown Storage"
    property string kernelVer: "Unknown"
    property string uptimeStr: "Unknown"
    property string sessionType: "Wayland"

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/get_about_info.sh").toString().replace(/^file:\/\//, "")

    Process {
        id: gnomeInfoProc
        command: [root.scriptPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 9) {
                    root.osName = lines[0].trim() || "Linux";
                    root.hostModel = lines[1].trim() || "Generic System";
                    root.cpuModel = lines[2].trim() || "Unknown CPU";
                    root.ramSize = lines[3].trim() || "Unknown RAM";
                    root.gpuModel = lines[4].trim() || "Unknown GPU";
                    root.diskSize = lines[5].trim() || "Unknown Storage";
                    root.kernelVer = lines[6].trim() || "Unknown";
                    root.uptimeStr = lines[7].trim() || "Unknown";
                    root.sessionType = lines[8].trim() || "Wayland";
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: gnomeInfoProc.running = true
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainLayout
            width: parent.width
            spacing: 16

            Text {
                text: "About System"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            AboutSystemBadgeCard {
                theme: root.theme
                font: root.font
                osName: root.osName
                hostModel: root.hostModel
            }

            AboutDetailsCard {
                theme: root.theme
                font: root.font
                hostModel: root.hostModel
                ramSize: root.ramSize
                cpuModel: root.cpuModel
                gpuModel: root.gpuModel
                diskSize: root.diskSize
                osName: root.osName
                sessionType: root.sessionType
                kernelVer: root.kernelVer
                uptimeStr: root.uptimeStr
            }
        }
    }
}
