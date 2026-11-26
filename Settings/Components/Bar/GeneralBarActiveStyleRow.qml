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
    id: activeStyleItem
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
                text: "Active Indicator Style"
                font.family: root.font
                font.pixelSize: Style.px(13)
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
                { desktop: "pill",      name: "Pill", desc: "" },
                { desktop: "underline", name: "Line", desc: "" },
                { desktop: "both",      name: "Both", desc: "" }
            ]
            currentValue: root.generalTab.curActiveStyle
            onSelected: (val) => BarConfig.updateBarProp("activeStyle", val)
        }
    }
}
