import QtQuick
import QtQuick.Layouts
import "../Common"

ColumnLayout {
    id: detailsRoot
    required property var theme
    required property string font
    required property string ramSize
    required property string cpuModel
    required property string gpuModel
    required property string diskSize
    required property string osName
    required property string archName
    required property string sessionType
    required property string desktopName
    required property string kernelVer
    required property string uptimeStr

    signal rowCopied(string label, string value)

    readonly property string osTypeText: {
        if (!detailsRoot.archName || detailsRoot.archName === "x86_64" || detailsRoot.archName === "aarch64") {
            return "64-bit (" + (detailsRoot.archName || "x86_64") + ")";
        }
        return detailsRoot.archName;
    }

    readonly property string windowingText: {
        const sess = detailsRoot.sessionType
            ? detailsRoot.sessionType.charAt(0).toUpperCase() + detailsRoot.sessionType.slice(1)
            : "Wayland";
        if (detailsRoot.desktopName !== "" && detailsRoot.desktopName.toLowerCase() !== sess.toLowerCase()) {
            return sess + " (" + detailsRoot.desktopName + ")";
        }
        return sess;
    }

    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            Text {
                text: "Hardware"
                font.family: detailsRoot.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                color: detailsRoot.theme.textSecondary
                Layout.fillWidth: true
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            AboutHardwareTile {
                theme: detailsRoot.theme; font: detailsRoot.font
                iconText: "󰍛"
                label: "Processor"
                value: detailsRoot.cpuModel
                onCopied: (l, v) => detailsRoot.rowCopied(l, v)
            }

            AboutHardwareTile {
                theme: detailsRoot.theme; font: detailsRoot.font
                iconText: "󰘚"
                label: "Memory"
                value: detailsRoot.ramSize
                onCopied: (l, v) => detailsRoot.rowCopied(l, v)
            }

            AboutHardwareTile {
                theme: detailsRoot.theme; font: detailsRoot.font
                iconText: "󰢮"
                label: "Graphics"
                value: detailsRoot.gpuModel
                onCopied: (l, v) => detailsRoot.rowCopied(l, v)
            }

            AboutHardwareTile {
                theme: detailsRoot.theme; font: detailsRoot.font
                iconText: "󰋊"
                label: "Disk Capacity"
                value: detailsRoot.diskSize
                onCopied: (l, v) => detailsRoot.rowCopied(l, v)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "System & Session"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                AboutInfoRow {
                    theme: detailsRoot.theme; font: detailsRoot.font
                    label: "OS Name"; value: detailsRoot.osName
                    onCopied: (l, v) => detailsRoot.rowCopied(l, v)
                }
                AboutInfoRow {
                    theme: detailsRoot.theme; font: detailsRoot.font
                    label: "Architecture"; value: detailsRoot.osTypeText
                    onCopied: (l, v) => detailsRoot.rowCopied(l, v)
                }
                AboutInfoRow {
                    theme: detailsRoot.theme; font: detailsRoot.font
                    label: "Kernel Version"; value: detailsRoot.kernelVer
                    onCopied: (l, v) => detailsRoot.rowCopied(l, v)
                }
                AboutInfoRow {
                    theme: detailsRoot.theme; font: detailsRoot.font
                    label: "Windowing System"; value: detailsRoot.windowingText
                    onCopied: (l, v) => detailsRoot.rowCopied(l, v)
                }
                AboutInfoRow {
                    theme: detailsRoot.theme; font: detailsRoot.font
                    label: "Uptime"; value: detailsRoot.uptimeStr
                    showDivider: false
                    onCopied: (l, v) => detailsRoot.rowCopied(l, v)
                }
            }
        }
    }
}
