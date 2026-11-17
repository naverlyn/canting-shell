import QtQuick
import QtQuick.Layouts
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    implicitHeight: 52
    opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
    enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

    readonly property var scaleOptions: [
        { desktop: "0.75", name: "75%",  desc: "" },
        { desktop: "1",    name: "100%", desc: "" },
        { desktop: "1.25", name: "125%", desc: "" },
        { desktop: "1.5",  name: "150%", desc: "" },
        { desktop: "1.75", name: "175%", desc: "" },
        { desktop: "2",    name: "200%", desc: "" }
    ]

    RowLayout {
        id: scaleRowLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Scale"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "UI and text scaling factor (" + Math.round((root.selectedMonitor ? root.selectedMonitor.scale : 1.0) * 100) + "%)"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        AppDropdown {
            theme: root.theme
            font: root.font
            width: 220
            implicitWidth: 220
            menuWidth: 220
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            options: scaleOptions
            currentValue: {
                const s = root.selectedMonitor ? Number(root.selectedMonitor.scale) : 1.0;
                for (let i = 0; i < scaleOptions.length; i++) {
                    if (Math.abs(s - Number(scaleOptions[i].desktop)) < 0.02) {
                        return scaleOptions[i].desktop;
                    }
                }
                return Math.round(s * 100) + "%";
            }
            onSelected: (val) => root.selectScale(Number(val))
        }
    }
}
