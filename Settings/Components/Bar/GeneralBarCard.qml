import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: generalSection
    title: {
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
    contentMargins: 8
    contentSpacing: 0

    readonly property bool isFloatingOrDashed: root.generalTab.curFloating || root.generalTab.curDashed

    SettingToggleRow {
        title: "Show Desktop Bar"
        desc: "Display this status bar on the desktop"
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
            desc: "Blend detail popups directly into the bar with curved inner corners (Fluid) vs detached floating cards (Flyout)"
            checked: BarConfig.currentBar ? (BarConfig.currentBar.fluidCards !== undefined ? Boolean(BarConfig.currentBar.fluidCards) : Boolean(BarConfig.fluidCards)) : Boolean(BarConfig.fluidCards)
            onToggled: (val) => {
                BarConfig.fluidCards = val;
                BarConfig.updateBarProp("fluidCards", val);
            }
        }
    }

    AnimatedSection {
        expanded: generalSection.isFloatingOrDashed || root.generalTab.curBumpy

        RowDivider {}

        SettingSliderRow {
            title: "Bar Roundness"
            desc: "Corner and curve radius in pixels for floating, dashed, and bumpy bars"
            value: BarConfig.currentBar && BarConfig.currentBar.barRadius !== undefined ? Number(BarConfig.currentBar.barRadius) : BarConfig.barRadius
            minVal: 0
            maxVal: 20
            step: 1
            unit: "px"
            showCustom: false
            presets: [
                { label: "0px", val: 0 },
                { label: "6px", val: 6 },
                { label: "12px", val: 12 },
                { label: "16px", val: 16 },
                { label: "20px", val: 20 }
            ]
            onValueModified: (val) => BarConfig.updateBarProp("barRadius", Math.round(val))
        }
    }

    AnimatedSection {
        expanded: generalSection.isFloatingOrDashed

        RowDivider {}

        SettingSliderRow {
            title: "Bar Edge Margin"
            desc: "Gap in pixels from the screen edge or border for floating and dashed bars"
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
        desc: "Remove individual widget card backgrounds for a clean, borderless appearance"
        checked: root.generalTab.curHidePill
        onToggled: (val) => BarConfig.updateBarProp("hidePill", val)
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
