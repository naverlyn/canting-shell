import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: generalSection
    readonly property bool isFloatingOrDashed: root.generalTab.curFloating || root.generalTab.curDashed
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: {
        const cur = BarConfig.currentBar;
        const tgt = cur ? (cur.displayTarget || (cur.allMonitors ? "all" : "primary")) : "primary";
        if (tgt === "all") {
            const isSec = root.hasMultipleMonitors && BarConfig.activeEditingDisplay === "secondary";
            const mName = root.getMonitorNameForTarget(isSec ? "secondary" : "primary");
            return "General Appearance: " + (isSec ? "Secondary Bar" : "Primary Bar") + " (" + mName + (root.isSingleMonitor ? " · Single Monitor" : "") + ")";
        }
        const mName = root.getMonitorNameForTarget(tgt);
        return "General Appearance: " + root.cleanBarName(cur ? cur.name : "") + " (" + mName + (root.isSingleMonitor ? " · Single Monitor" : "") + ")";
    }
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
            SettingToggleRow {
                title: "Show Desktop Bar"
                checked: root.generalTab.curEnabled
                onToggled: (val) => BarConfig.updateBarProp("enabled", val)
            }

            RowDivider {}

            GeneralBarPrimaryPositionRow {
                root: generalSection.root
            }

            RowDivider {
                visible: root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors
            }

            GeneralBarSecondaryPositionRow {
                root: generalSection.root
            }

            RowDivider {
                visible: root.hasMultipleMonitors
            }

            GeneralBarDisplayAssignmentRow {
                root: generalSection.root
            }

            RowDivider {
                visible: root.hasMultipleMonitors && root.generalTab.curDisplayTarget === "all"
            }

            GeneralBarDualDisplayBanner {
                root: generalSection.root
            }

            RowDivider {}

            GeneralBarHeightRow {
                root: generalSection.root
            }

            RowDivider {}

            GeneralBarStyleRow {
                root: generalSection.root
            }

            AnimatedSection {
                expanded: !generalSection.isFloatingOrDashed

                RowDivider {}

                SettingToggleRow {
                    title: "Fluid Widget Cards (Experimental)"
                    checked: BarConfig.currentBar ? (BarConfig.currentBar.fluidCards !== undefined ? Boolean(BarConfig.currentBar.fluidCards) : Boolean(BarConfig.fluidCards)) : Boolean(BarConfig.fluidCards)
                    onToggled: (val) => {
                        BarConfig.fluidCards = val;
                        BarConfig.updateBarProp("fluidCards", val);
                    }
                }
            }

            AnimatedSection {
                expanded: generalSection.isFloatingOrDashed

                RowDivider {}

                SettingSliderRow {
                    title: "Bar Roundness"
                    value: BarConfig.currentBar && BarConfig.currentBar.barRadius !== undefined ? Number(BarConfig.currentBar.barRadius) : BarConfig.barRadius
                    minVal: 0
                    maxVal: 20
                    step: 1
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "6px", val: 6 },
                        { label: "12px", val: 12 },
                        { label: "16px", val: 16 },
                        { label: "20px", val: 20 }
                    ]
                    onValueModified: (val) => BarConfig.updateBarProp("barRadius", Math.round(val))
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Bar Edge Margin"
                    value: BarConfig.currentBar && BarConfig.currentBar.barMargin !== undefined ? Number(BarConfig.currentBar.barMargin) : BarConfig.barMargin
                    minVal: 0
                    maxVal: 24
                    step: 1
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "4px", val: 4 },
                        { label: "6px", val: 6 },
                        { label: "12px", val: 12 },
                        { label: "16px", val: 16 }
                    ]
                    onValueModified: (val) => BarConfig.updateBarProp("barMargin", Math.round(val))
                }
            }

            RowDivider {}

            GeneralBarOpacityRow {
                root: generalSection.root
            }

            RowDivider {}

            SettingToggleRow {
                title: "Hide Pill Backgrounds"
                checked: root.generalTab.curHidePill
                onToggled: (val) => BarConfig.updateBarProp("hidePill", val)
            }

            RowDivider {}

            SettingToggleRow {
                title: "Auto-Scale Widgets"
                checked: root.generalTab.curScaleWidgets
                onToggled: (val) => BarConfig.updateBarProp("scaleWidgets", val)
            }

            RowDivider {}

            GeneralBarActiveStyleRow {
                root: generalSection.root
            }

            RowDivider {
                visible: !generalSection.root.generalTab.curHidePill
            }

            GeneralBarPillRadiusRow {
                root: generalSection.root
            }

            RowDivider {
                visible: !generalSection.root.generalTab.curHidePill
            }

            GeneralBarPillOpacityRow {
                root: generalSection.root
            }
        }
    }
}
