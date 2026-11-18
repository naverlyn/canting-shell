import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: rowSelf
    visible: root.hasMultipleMonitors
    Layout.fillWidth: true
    height: 40

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Display Assignment"
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
            width: 200
            implicitWidth: 200
            menuWidth: 200
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            options: root.hasMultipleMonitors
                ? [
                    { desktop: "all",       name: "All Displays", desc: "" },
                    { desktop: "primary",   name: "Primary",      desc: "" },
                    { desktop: "secondary", name: "Secondary",    desc: "" }
                  ]
                : [
                    { desktop: "all",     name: "All Displays", desc: "" },
                    { desktop: "primary", name: "Primary",      desc: "" }
                  ]
            currentValue: root.generalTab.curDisplayTarget
            onSelected: (val) => BarConfig.updateBarProp("displayTarget", val)
        }
    }
}
