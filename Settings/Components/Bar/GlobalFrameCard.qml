import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: frameSection
    title: "Screen Frame & Corners (Global)"
    contentMargins: 8
    contentSpacing: 0

    readonly property var barState: {
        void BarConfig.panelsRevision;
        const list = BarConfig.bars || [];
        let anyDocked = false;
        for (let i = 0; i < list.length; i++) {
            const b = list[i];
            if (!b || b.enabled === false) continue;
            if (!Boolean(b.floating) && !Boolean(b.dashed)) {
                anyDocked = true;
                break;
            }
            const bTgt = b.displayTarget || (b.allMonitors ? "all" : "primary");
            if (bTgt === "all") {
                const secFlt = (b.secondaryFloating !== undefined ? Boolean(b.secondaryFloating) : Boolean(b.floating))
                    || (b.secondaryDashed !== undefined ? Boolean(b.secondaryDashed) : Boolean(b.dashed));
                if (!secFlt) {
                    anyDocked = true;
                    break;
                }
            }
        }
        return { hasAnyDocked: anyDocked };
    }

    readonly property bool cornerOrShadowDisabled: !barState.hasAnyDocked && !Boolean(BarConfig.screenBorder)
    readonly property string noEdgeReason: "Requires at least one docked bar or Framed Screen Border"

    SettingToggleRow {
        title: "Inner Corners"
        desc: frameSection.cornerOrShadowDisabled
            ? frameSection.noEdgeReason
            : "Round the inner corners where docked bars or the screen frame meet the desktop"
        checked: Boolean(BarConfig.innerCorners) && !frameSection.cornerOrShadowDisabled
        rowEnabled: !frameSection.cornerOrShadowDisabled
        onToggled: (val) => BarConfig.setInnerCorners(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Framed Screen Border"
        desc: "Add a thin border along un-docked desktop edges to frame the screen"
        checked: Boolean(BarConfig.screenBorder)
        onToggled: (val) => BarConfig.setScreenBorder(val)
    }

    AnimatedSection {
        expanded: Boolean(BarConfig.screenBorder)

        RowDivider {}

        SettingSliderRow {
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

        RowDivider {}

        SettingToggleRow {
            title: "Screen Border Inner Corners"
            desc: "Display smooth concave rounded corners where border edges meet each other or active bars"
            checked: Boolean(BarConfig.screenBorderCorners)
            onToggled: (val) => BarConfig.setScreenBorderCorners(val)
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Inner Shadow"
        desc: frameSection.cornerOrShadowDisabled
            ? frameSection.noEdgeReason
            : "Cast a soft ambient shadow inward from the bar and border frame onto the desktop"
        checked: Boolean(BarConfig.screenBorderShadow) && !frameSection.cornerOrShadowDisabled
        rowEnabled: !frameSection.cornerOrShadowDisabled
        onToggled: (val) => BarConfig.setScreenBorderShadow(val)
    }

    AnimatedSection {
        expanded: Boolean(BarConfig.screenBorderShadow) && !frameSection.cornerOrShadowDisabled

        RowDivider {}

        SettingSliderRow {
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
    }

    RowDivider {}

    SettingSliderRow {
        title: "Frame & Corners Opacity"
        desc: "Background transparency for the global screen border and inner corners"
        value: Math.round((BarConfig.screenFrameOpacity !== undefined ? BarConfig.screenFrameOpacity : 1.0) * 100)
        minVal: 10
        maxVal: 100
        step: 5
        unit: "%"
        presets: [
            { label: "50%", val: 50 },
            { label: "75%", val: 75 },
            { label: "85%", val: 85 },
            { label: "100%", val: 100 }
        ]
        onValueModified: (val) => BarConfig.setScreenFrameOpacity(Math.round(val) / 100)
    }
}
