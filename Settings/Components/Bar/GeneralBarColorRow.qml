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
    id: barColorSettingRow
    Layout.fillWidth: true
    height: 52

    readonly property string barSpec: root.generalTab.curBarColor
    readonly property color resolvedColor: root.resolveThemeSpec(barSpec, root.theme.bgBase)
    readonly property bool isCustom: barSpec !== ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Bar Background Color"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Custom color for desktop bar and matching inner corners"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 20
                height: 20
                radius: 5
                color: barColorSettingRow.resolvedColor
                border.color: root.theme.bgBorder
                border.width: 1
            }

            Text {
                text: barColorSettingRow.isCustom ? root.getSpecLabel(barColorSettingRow.barSpec) : "Auto (Default)"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: barColorSettingRow.isCustom ? root.theme.accentPrimary : root.theme.textSecondary
            }

            ActionButton {
                iconText: "󰏘"
                label: "Customize Color..."
                btnHeight: 28
                onClicked: {
                    root.selectedColorTargetType = "bar";
                    root.currentSubTab = 1;
                    root.subTabContentAnimation.restart();
                }
            }

            ActionButton {
                visible: barColorSettingRow.isCustom
                iconText: "󰦛"
                label: "Reset"
                danger: true
                btnHeight: 28
                onClicked: BarConfig.updateBarProp("barColor", "")
            }
        }
    }
}
