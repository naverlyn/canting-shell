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
    visible: root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors
    Layout.fillWidth: true
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Secondary Bar Position"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Dock to Top, Bottom, Left, or Right edge on your secondary display"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
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
            currentValue: BarConfig.currentBar ? (BarConfig.currentBar.secondaryPosition || BarConfig.currentBar.position || "top") : (BarConfig.secondaryPosition || BarConfig.position || "top")
            onSelected: (val) => BarConfig.updateBarProp("secondaryPosition", val)
        }
    }
}
