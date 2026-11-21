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
    readonly property bool isFloatingOrDashed: root.generalTab.curFloating || root.generalTab.curDashed || root.generalTab.curDynamicIsland
    readonly property bool curDropShadow: BarConfig.currentBar && BarConfig.currentBar.barDropShadow !== undefined
        ? Boolean(BarConfig.currentBar.barDropShadow)
        : Boolean(root.generalTab.curDynamicIsland || BarConfig.barDropShadow)
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

                PreferenceRow {
                    title: "Bar Roundness"

                    AppDropdown {
                        theme: generalSection.root.theme
                        font: generalSection.root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        readonly property int curVal: Math.round(BarConfig.currentBar && BarConfig.currentBar.barRadius !== undefined ? Number(BarConfig.currentBar.barRadius) : BarConfig.barRadius)
                        currentValue: String(curVal)
                        options: {
                            const vals = [0, 4, 6, 8, 12, 16, 20];
                            if (vals.indexOf(curVal) === -1) vals.push(curVal);
                            vals.sort((a, b) => a - b);
                            return vals.map(v => ({
                                desktop: String(v),
                                name: v === 0 ? "0px (Sharp)" : (v === 20 ? "20px (Pill)" : (v + "px")),
                                desc: ""
                            }));
                        }
                        onSelected: (val) => BarConfig.updateBarProp("barRadius", Math.round(Number(val)))
                    }
                }

                RowDivider {}

                PreferenceRow {
                    title: "Bar Edge Margin"

                    AppDropdown {
                        theme: generalSection.root.theme
                        font: generalSection.root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        readonly property int curVal: Math.round(BarConfig.currentBar && BarConfig.currentBar.barMargin !== undefined ? Number(BarConfig.currentBar.barMargin) : BarConfig.barMargin)
                        currentValue: String(curVal)
                        options: {
                            const vals = [0, 4, 6, 8, 12, 16, 20, 24];
                            if (vals.indexOf(curVal) === -1) vals.push(curVal);
                            vals.sort((a, b) => a - b);
                            return vals.map(v => ({
                                desktop: String(v),
                                name: v + "px",
                                desc: ""
                            }));
                        }
                        onSelected: (val) => BarConfig.updateBarProp("barMargin", Math.round(Number(val)))
                    }
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Drop Shadow"
                    checked: generalSection.curDropShadow
                    onToggled: (val) => BarConfig.updateBarProp("barDropShadow", val)
                }

                AnimatedSection {
                    expanded: generalSection.curDropShadow

                    RowDivider {
                        visible: generalSection.root.generalTab.curDynamicIsland
                    }

                    PreferenceRow {
                        visible: generalSection.root.generalTab.curDynamicIsland
                        title: "Drop Shadow Target"

                        AppDropdown {
                            theme: generalSection.root.theme
                            font: generalSection.root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            currentValue: (BarConfig.currentBar && BarConfig.currentBar.barDropShadowTarget) ? String(BarConfig.currentBar.barDropShadowTarget) : BarConfig.barDropShadowTarget
                            options: [
                                { desktop: "all",    name: "Dynamic Island + Side Bars", desc: "" },
                                { desktop: "island", name: "Dynamic Island Only",        desc: "" }
                            ]
                            onSelected: (val) => BarConfig.updateBarProp("barDropShadowTarget", val)
                        }
                    }

                    RowDivider {}

                    PreferenceRow {
                        title: "Shadow Blur"

                        AppDropdown {
                            theme: generalSection.root.theme
                            font: generalSection.root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            readonly property int curVal: Math.round(BarConfig.currentBar && BarConfig.currentBar.barDropShadowBlur !== undefined ? Number(BarConfig.currentBar.barDropShadowBlur) : BarConfig.barDropShadowBlur)
                            currentValue: String(curVal)
                            options: {
                                const vals = [4, 8, 12, 16, 24, 32, 36];
                                if (vals.indexOf(curVal) === -1) vals.push(curVal);
                                vals.sort((a, b) => a - b);
                                return vals.map(v => ({
                                    desktop: String(v),
                                    name: v === 4 ? "4px (Crisp)" : (v === 16 ? "16px (Default)" : (v === 32 ? "32px (Soft)" : (v + "px"))),
                                    desc: ""
                                }));
                            }
                            onSelected: (val) => BarConfig.updateBarProp("barDropShadowBlur", Math.round(Number(val)))
                        }
                    }

                    RowDivider {}

                    PreferenceRow {
                        title: "Shadow Opacity"

                        AppDropdown {
                            theme: generalSection.root.theme
                            font: generalSection.root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            readonly property int curPct: Math.round((BarConfig.currentBar && BarConfig.currentBar.barDropShadowOpacity !== undefined ? Number(BarConfig.currentBar.barDropShadowOpacity) : BarConfig.barDropShadowOpacity) * 100)
                            currentValue: String(curPct)
                            options: {
                                const vals = [15, 25, 35, 45, 60, 75, 85];
                                if (vals.indexOf(curPct) === -1) vals.push(curPct);
                                vals.sort((a, b) => a - b);
                                return vals.map(v => ({
                                    desktop: String(v),
                                    name: v === 45 ? "45% (Default)" : (v + "%"),
                                    desc: ""
                                }));
                            }
                            onSelected: (val) => BarConfig.updateBarProp("barDropShadowOpacity", Math.round(Number(val)) / 100.0)
                        }
                    }

                    RowDivider {}

                    PreferenceRow {
                        title: "Shadow Vertical Offset"

                        AppDropdown {
                            theme: generalSection.root.theme
                            font: generalSection.root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            readonly property int curVal: Math.round(BarConfig.currentBar && BarConfig.currentBar.barDropShadowOffsetY !== undefined ? Number(BarConfig.currentBar.barDropShadowOffsetY) : BarConfig.barDropShadowOffsetY)
                            currentValue: String(curVal)
                            options: {
                                const vals = [0, 2, 4, 6, 8, 12, 16];
                                if (vals.indexOf(curVal) === -1) vals.push(curVal);
                                vals.sort((a, b) => a - b);
                                return vals.map(v => ({
                                    desktop: String(v),
                                    name: v === 0 ? "0px (Centered)" : (v === 4 ? "4px (Default)" : (v + "px")),
                                    desc: ""
                                }));
                            }
                            onSelected: (val) => BarConfig.updateBarProp("barDropShadowOffsetY", Math.round(Number(val)))
                        }
                    }

                    RowDivider {}

                    PreferenceRow {
                        title: "Shadow Color Mode"

                        AppDropdown {
                            theme: generalSection.root.theme
                            font: generalSection.root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            currentValue: (BarConfig.currentBar && BarConfig.currentBar.barDropShadowColorMode) ? String(BarConfig.currentBar.barDropShadowColorMode) : BarConfig.barDropShadowColorMode
                            options: [
                                { desktop: "dark",     name: "Dark (Classic)",             desc: "" },
                                { desktop: "accent",   name: "Theme Accent Glow",          desc: "" },
                                { desktop: "adaptive", name: "Adaptive (Media & Alerts)",  desc: "" }
                            ]
                            onSelected: (val) => BarConfig.updateBarProp("barDropShadowColorMode", val)
                        }
                    }
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
