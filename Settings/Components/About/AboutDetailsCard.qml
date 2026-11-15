import QtQuick
import QtQuick.Layouts

Rectangle {
    id: detailsCard
    required property var theme
    required property string font
    required property string hostModel
    required property string ramSize
    required property string cpuModel
    required property string gpuModel
    required property string diskSize
    required property string osName
    required property string sessionType
    required property string kernelVer
    required property string uptimeStr

    Layout.fillWidth: true
    implicitHeight: infoRows.implicitHeight + 16
    radius: 12
    color: theme.bgSurface
    border.color: theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
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

        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Hardware Model"; value: detailsCard.hostModel }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Memory"; value: detailsCard.ramSize }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Processor"; value: detailsCard.cpuModel }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Graphics"; value: detailsCard.gpuModel }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Disk Capacity"; value: detailsCard.diskSize }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "OS Name"; value: detailsCard.osName }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "OS Type"; value: "64-bit" }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Windowing System"; value: detailsCard.sessionType.charAt(0).toUpperCase() + detailsCard.sessionType.slice(1) }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Kernel Version"; value: detailsCard.kernelVer }
        AboutInfoRow { theme: detailsCard.theme; font: detailsCard.font; label: "Uptime"; value: detailsCard.uptimeStr; showDivider: false }
    }
}
