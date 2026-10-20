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

    SettingToggleRow {
        title: "Floating Bar"
        desc: "Add screen margins and rounded outer corners"
        checked: BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating
        onToggled: (val) => BarConfig.updateBarProp("floating", val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Inner Rounded Corners"
        desc: "Display concave rounded corners connecting docked bar edges to screen borders"
        checked: BarConfig.currentBar ? (BarConfig.currentBar.innerCorners !== undefined ? Boolean(BarConfig.currentBar.innerCorners) : Boolean(BarConfig.innerCorners)) : Boolean(BarConfig.innerCorners)
        rowEnabled: !(BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating)
        onToggled: (val) => {
            BarConfig.innerCorners = val;
            BarConfig.updateBarProp("innerCorners", val);
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Screen Border Frame"
        desc: "Frame un-docked desktop edges with a sleek customizable border line and inner rounded corners"
        checked: Boolean(BarConfig.screenBorder)
        onToggled: (val) => BarConfig.setScreenBorder(val)
    }

    RowDivider {
        visible: Boolean(BarConfig.screenBorder)
    }

    SettingSliderRow {
        visible: Boolean(BarConfig.screenBorder)
        title: "Screen Border Thickness"
        desc: "Pixel thickness of the border along un-docked desktop edges"
        value: BarConfig.screenBorderThickness
        minVal: 1
        maxVal: 32
        step: 1
        unit: "px"
        presets: [
            { label: "2px", val: 2 },
            { label: "4px", val: 4 },
            { label: "8px", val: 8 },
            { label: "16px", val: 16 }
        ]
        onValueModified: (val) => BarConfig.setScreenBorderThickness(val)
    }

    RowDivider {
        visible: Boolean(BarConfig.screenBorder)
    }

    SettingToggleRow {
        visible: Boolean(BarConfig.screenBorder)
        title: "Screen Border Inner Corners"
        desc: "Display smooth concave rounded corners where border edges meet each other or active bars"
        checked: Boolean(BarConfig.screenBorderCorners)
        onToggled: (val) => BarConfig.setScreenBorderCorners(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Inner Shadow"
        desc: "Cast a soft ambient shadow inward from the bar and border frame onto the desktop"
        checked: Boolean(BarConfig.screenBorderShadow)
        onToggled: (val) => BarConfig.setScreenBorderShadow(val)
    }

    RowDivider {
        visible: Boolean(BarConfig.screenBorderShadow)
    }

    SettingSliderRow {
        visible: Boolean(BarConfig.screenBorderShadow)
        title: "Inner Shadow Size"
        desc: "Spread distance in pixels for the ambient inner shadow"
        value: BarConfig.screenBorderShadowSize
        minVal: 2
        maxVal: 64
        step: 1
        unit: "px"
        presets: [
            { label: "4px", val: 4 },
            { label: "8px", val: 8 },
            { label: "12px", val: 12 },
            { label: "16px", val: 16 },
            { label: "24px", val: 24 }
        ]
        onValueModified: (val) => BarConfig.setScreenBorderShadowSize(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Fluid Widget Cards"
        desc: "Blend detail popups directly into the bar with curved inner corners (Fluid) vs detached floating cards (Flyout)"
        checked: BarConfig.currentBar ? (BarConfig.currentBar.fluidCards !== undefined ? Boolean(BarConfig.currentBar.fluidCards) : Boolean(BarConfig.fluidCards)) : Boolean(BarConfig.fluidCards)
        onToggled: (val) => {
            BarConfig.fluidCards = val;
            BarConfig.updateBarProp("fluidCards", val);
        }
    }

    RowDivider {}

    GeneralBarOpacityRow {
        root: generalSection.root
    }

    RowDivider {}

    GeneralBarColorRow {
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

    RowDivider {}

    GeneralBarPillRadiusRow {
        root: generalSection.root
    }

    RowDivider {}

    GeneralBarPillOpacityRow {
        root: generalSection.root
    }
}
