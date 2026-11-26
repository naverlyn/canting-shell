import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8

    readonly property var curBar: BarConfig.currentBar
    readonly property string curPosition: (curBar && curBar.islandPosition) ? String(curBar.islandPosition) : BarConfig.islandPosition
    readonly property string curIdleMode: (curBar && curBar.islandIdleMode) ? String(curBar.islandIdleMode) : BarConfig.islandIdleMode
    readonly property bool curLiveActivity: (curBar && curBar.islandLiveActivity !== undefined) ? Boolean(curBar.islandLiveActivity) : BarConfig.islandLiveActivity
    readonly property string curLayoutMode: (curBar && curBar.islandLayoutMode) ? String(curBar.islandLayoutMode) : BarConfig.islandLayoutMode
    readonly property string curDefaultModule: (curBar && curBar.islandDefaultModule) ? String(curBar.islandDefaultModule) : BarConfig.islandDefaultModule
    readonly property var curSplitModules: (curBar && Array.isArray(curBar.islandSplitModules) && curBar.islandSplitModules.length >= 2)
        ? curBar.islandSplitModules
        : BarConfig.islandSplitModules
    readonly property int curHoverDelay: (curBar && curBar.islandHoverDelay !== undefined) ? Number(curBar.islandHoverDelay) : BarConfig.islandHoverDelay
    readonly property int curCloseDelay: (curBar && curBar.islandCloseDelay !== undefined) ? Number(curBar.islandCloseDelay) : BarConfig.islandCloseDelay
    readonly property int curExpandedW: (curBar && curBar.islandExpandedWidth !== undefined) ? Number(curBar.islandExpandedWidth) : BarConfig.islandExpandedWidth
    readonly property string curNotifMode: (curBar && curBar.islandNotificationMode !== undefined) ? String(curBar.islandNotificationMode) : BarConfig.islandNotificationMode
    readonly property bool curOsdEnabled: (curBar && curBar.islandOsdEnabled !== undefined) ? Boolean(curBar.islandOsdEnabled) : BarConfig.islandOsdEnabled

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "Dynamic Island (Experimental)"
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
        implicitHeight: innerCol.implicitHeight + 16
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

            PreferenceRow {
                title: "Island Placement"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    currentValue: self.curPosition
                    options: [
                        { desktop: "left",   name: "Left",   desc: "" },
                        { desktop: "center", name: "Center", desc: "" },
                        { desktop: "right",  name: "Right",  desc: "" }
                    ]
                    onSelected: (val) => BarConfig.updateBarProp("islandPosition", val)
                }
            }

            RowDivider {}

            PreferenceRow {
                title: "Idle Compact Display"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    currentValue: self.curIdleMode
                    options: [
                        { desktop: "widgets", name: "Assigned Panel Widgets", desc: "" },
                        { desktop: "minimal", name: "Minimal Clock & Media",  desc: "" }
                    ]
                    onSelected: (val) => BarConfig.updateBarProp("islandIdleMode", val)
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Live Media Activity Flanks"
                checked: self.curLiveActivity
                onToggled: (val) => BarConfig.updateBarProp("islandLiveActivity", val)
            }

            RowDivider {}

            PreferenceRow {
                title: "Expanded Hub Layout"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    currentValue: self.curLayoutMode
                    options: [
                        { desktop: "tabs",  name: "Tabbed (Compact)",              desc: "" },
                        { desktop: "split", name: "Split Dashboard (2 Modules)",   desc: "" }
                    ]
                    onSelected: (val) => BarConfig.updateBarProp("islandLayoutMode", val)
                }
            }

            AnimatedSection {
                expanded: self.curLayoutMode === "tabs"

                RowDivider {}

                PreferenceRow {
                    title: "Default Open Module"

                    AppDropdown {
                        theme: self.root.theme
                        font: self.root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: self.curDefaultModule
                        options: [{ desktop: "auto", name: "Auto (MPRIS / Calendar)", desc: "" }].concat(
                            (BarConfig.islandModuleDefinitions || []).map(m => ({ desktop: m.id, name: m.name, desc: "" }))
                        )
                        onSelected: (val) => BarConfig.updateBarProp("islandDefaultModule", val)
                    }
                }
            }

            AnimatedSection {
                expanded: self.curLayoutMode === "split"

                RowDivider {}

                PreferenceRow {
                    title: "Split Left Module"

                    AppDropdown {
                        theme: self.root.theme
                        font: self.root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: self.curSplitModules[0] || "mpris"
                        options: (BarConfig.islandModuleDefinitions || []).map(m => ({ desktop: m.id, name: m.name, desc: "" }))
                        onSelected: (val) => {
                            let pair = (self.curSplitModules || ["mpris", "calendar"]).slice(0, 2);
                            pair[0] = val;
                            BarConfig.updateBarProp("islandSplitModules", pair);
                        }
                    }
                }

                RowDivider {}

                PreferenceRow {
                    title: "Split Right Module"

                    AppDropdown {
                        theme: self.root.theme
                        font: self.root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: self.curSplitModules[1] || "calendar"
                        options: (BarConfig.islandModuleDefinitions || []).map(m => ({ desktop: m.id, name: m.name, desc: "" }))
                        onSelected: (val) => {
                            let pair = (self.curSplitModules || ["mpris", "calendar"]).slice(0, 2);
                            pair[1] = val;
                            BarConfig.updateBarProp("islandSplitModules", pair);
                        }
                    }
                }
            }

            RowDivider {}

            PreferenceRow {
                title: "Expanded Width"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    readonly property int curVal: Math.round(self.curExpandedW)
                    currentValue: String(curVal)
                    options: {
                        const vals = [340, 380, 400, 440, 480, 560, 640];
                        if (vals.indexOf(curVal) === -1) vals.push(curVal);
                        vals.sort((a, b) => a - b);
                        return vals.map(v => ({
                            desktop: String(v),
                            name: v === 340 ? "340px (Compact)" : (v === 400 ? "400px (Default)" : (v === 560 ? "560px (Wide)" : (v + "px"))),
                            desc: ""
                        }));
                    }
                    onSelected: (val) => BarConfig.updateBarProp("islandExpandedWidth", Math.round(Number(val)))
                }
            }

            RowDivider {}

            PreferenceRow {
                title: "Hover Open Delay"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    readonly property int curVal: Math.round(self.curHoverDelay)
                    currentValue: String(curVal)
                    options: {
                        const vals = [0, 60, 120, 200, 300, 400];
                        if (vals.indexOf(curVal) === -1) vals.push(curVal);
                        vals.sort((a, b) => a - b);
                        return vals.map(v => ({
                            desktop: String(v),
                            name: v === 0 ? "Instant (0ms)" : (v === 120 ? "120ms (Default)" : (v + "ms")),
                            desc: ""
                        }));
                    }
                    onSelected: (val) => BarConfig.updateBarProp("islandHoverDelay", Math.round(Number(val)))
                }
            }

            RowDivider {}

            PreferenceRow {
                title: "Hover Close Grace"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    readonly property int curVal: Math.round(self.curCloseDelay)
                    currentValue: String(curVal)
                    options: {
                        const vals = [120, 180, 220, 320, 450, 600];
                        if (vals.indexOf(curVal) === -1) vals.push(curVal);
                        vals.sort((a, b) => a - b);
                        return vals.map(v => ({
                            desktop: String(v),
                            name: v === 220 ? "220ms (Default)" : (v + "ms"),
                            desc: ""
                        }));
                    }
                    onSelected: (val) => BarConfig.updateBarProp("islandCloseDelay", Math.round(Number(val)))
                }
            }

            RowDivider {}

            PreferenceRow {
                title: "Notifications in Dynamic Island"

                AppDropdown {
                    theme: self.root.theme
                    font: self.root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    currentValue: self.curNotifMode
                    options: [
                        { desktop: "island", name: "Dynamic Island Only",     desc: "" },
                        { desktop: "both",   name: "Island + Standard Toast", desc: "" },
                        { desktop: "off",    name: "Off (Standard Toasts)",   desc: "" }
                    ]
                    onSelected: (val) => BarConfig.updateBarProp("islandNotificationMode", val)
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Volume & Brightness OSD in Island"
                checked: self.curOsdEnabled
                onToggled: (val) => BarConfig.updateBarProp("islandOsdEnabled", val)
            }
        }
    }
}
