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
                text: (root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors) ? "Primary Bar Position" : "Bar Position"
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
            options: [
                { desktop: "top",    name: "Top",    desc: "" },
                { desktop: "bottom", name: "Bottom", desc: "" },
                { desktop: "left",   name: "Left",   desc: "" },
                { desktop: "right",  name: "Right",  desc: "" }
            ]
            currentValue: BarConfig.currentBar ? BarConfig.currentBar.position : BarConfig.position
            onSelected: (val) => BarConfig.updateBarProp("position", val)
        }
    }
}
