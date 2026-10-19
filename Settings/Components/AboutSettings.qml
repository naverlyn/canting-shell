import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

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

            // GNOME-style Top System Badge
            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: root.osName
                            font.family: root.font
                            font.pixelSize: 18
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        
                        Text {
                            text: root.hostModel
                            font.family: root.font
                            font.pixelSize: 13
                            color: root.theme.textSecondary
                        }
                    }
                }
            }

            // GNOME-style Details Group Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoRows.implicitHeight + 16
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    id: infoRows
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    spacing: 0

                    // Helper Row Component
                    component InfoRow: Rectangle {
                        property string label
                        property string value
                        property bool showDivider: true

                        Layout.fillWidth: true
                        height: 38
                        radius: 6
                        color: rowHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                text: label
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.textSecondary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: value
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 320
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                            visible: showDivider
                        }
                    }

                    InfoRow { label: "Hardware Model"; value: root.hostModel }
                    InfoRow { label: "Memory"; value: root.ramSize }
                    InfoRow { label: "Processor"; value: root.cpuModel }
                    InfoRow { label: "Graphics"; value: root.gpuModel }
                    InfoRow { label: "Disk Capacity"; value: root.diskSize }
                    InfoRow { label: "OS Name"; value: root.osName }
                    InfoRow { label: "OS Type"; value: "64-bit" }
                    InfoRow { label: "Windowing System"; value: root.sessionType.charAt(0).toUpperCase() + root.sessionType.slice(1) }
                    InfoRow { label: "Kernel Version"; value: root.kernelVer }
                    InfoRow { label: "Uptime"; value: root.uptimeStr; showDivider: false }
                }
            }
        }
    }
}
