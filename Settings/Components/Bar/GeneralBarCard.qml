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
