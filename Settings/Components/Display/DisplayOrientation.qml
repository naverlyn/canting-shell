import QtQuick
import QtQuick.Layouts
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    implicitHeight: 44
    opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
    enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Orientation"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }
        }

        Item { Layout.fillWidth: true }

        AppDropdown {
            theme: root.theme
            font: root.font
            Layout.preferredWidth: 380
            implicitWidth: 380
            menuWidth: 380
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            options: [
                { desktop: "0", name: "0°",   desc: "" },
                { desktop: "1", name: "90°",  desc: "" },
                { desktop: "2", name: "180°", desc: "" },
                { desktop: "3", name: "270°", desc: "" }
            ]
            currentValue: root.selectedMonitor ? String(root.selectedMonitor.transform) : "0"
            onSelected: (val) => root.selectTransform(Number(val))
        }
    }
}
