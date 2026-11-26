import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../Common"

ColumnLayout {
    id: generalTabContent

    required property var root
    property bool showInactiveWidgets: false
    Layout.fillWidth: true
    spacing: 20

    readonly property var activeWidgetIds: {
        void BarConfig.panelsRevision;
        void BarConfig.selectedBarIndex;
        void BarConfig.activeEditingDisplay;
        void BarConfig.bars;
        const p = BarConfig.panels || [];
        const map = {};
        for (let i = 0; i < p.length; i++) {
            const sec = p[i];
            if (!sec) continue;
            for (let j = 0; j < sec.length; j++) {
                if (sec[j]) map[String(sec[j])] = true;
            }
        }
        return map;
    }

    function isCardActive(ids) {
        for (let i = 0; i < ids.length; i++) {
            if (activeWidgetIds[ids[i]]) return true;
        }
        return false;
    }

    Component { id: appGridComp;        AppGridOptionsCard { root: generalTabContent.root } }
    Component { id: networkSpeedComp;   NetworkSpeedOptionsCard { root: generalTabContent.root } }
    Component { id: clockComp;          ClockOptionsCard { root: generalTabContent.root } }
    Component { id: workspacesComp;     WorkspacesOptionsCard { root: generalTabContent.root } }
    Component { id: taskSwitcherComp;   TaskSwitcherOptionsCard { root: generalTabContent.root } }
    Component { id: globalMenuComp;     GlobalMenuOptionsCard { root: generalTabContent.root } }
    Component { id: weatherComp;        WeatherOptionsCard { root: generalTabContent.root } }
    Component { id: batteryComp;        BatteryOptionsCard { root: generalTabContent.root } }
    Component { id: cavaComp;           CavaOptionsCard { root: generalTabContent.root } }
    Component { id: mediaComp;          MediaOptionsCard { root: generalTabContent.root } }
    Component { id: hardwareMonComp;    HardwareMonitorOptionsCard { root: generalTabContent.root } }
    Component { id: wifiBtComp;         WifiBluetoothOptionsCard { root: generalTabContent.root } }
    Component { id: brightnessComp;     BrightnessOptionsCard { root: generalTabContent.root } }
    Component { id: customScriptComp;   CustomScriptOptionsCard { root: generalTabContent.root } }

    readonly property var widgetEntries: [
        { ids: ["appGrid"],                              filter: "app grid launcher icon",                         comp: appGridComp },
        { ids: ["network"],                              filter: "network speed down up compact",                  comp: networkSpeedComp },
        { ids: ["clock"],                                filter: "clock time date seconds year calendar",          comp: clockComp },
        { ids: ["workspaces"],                           filter: "workspaces index scroll hyprland",               comp: workspacesComp },
        { ids: ["taskSwitcher"],                         filter: "task switcher window scope label width",         comp: taskSwitcherComp },
        { ids: ["globalMenu"],                           filter: "global menu appmenu",                            comp: globalMenuComp },
        { ids: ["weather"],                              filter: "weather location unit forecast",                 comp: weatherComp },
        { ids: ["battery"],                              filter: "battery percentage low threshold",               comp: batteryComp },
        { ids: ["cava"],                                 filter: "cava audio visualizer bars stereo",              comp: cavaComp },
        { ids: ["media"],                                filter: "media player mpris album art seekbar popup",     comp: mediaComp },
        { ids: ["cpu", "gpu", "temp", "memory", "disk"], filter: "hardware cpu gpu memory disk temp alert",        comp: hardwareMonComp },
        { ids: ["wifi", "bluetooth"],                    filter: "wifi bluetooth connectivity labels",             comp: wifiBtComp },
        { ids: ["brightness"],                           filter: "brightness night light step",                    comp: brightnessComp },
        { ids: ["customScript"],                         filter: "custom script command interval png image",       comp: customScriptComp }
    ]

    readonly property int activeWidgetCardCount: {
        void activeWidgetIds;
        let c = 0;
        for (let i = 0; i < widgetEntries.length; i++) {
            if (isCardActive(widgetEntries[i].ids)) c++;
        }
        return c;
    }

    readonly property int inactiveWidgetCardCount: widgetEntries.length - activeWidgetCardCount

    GeneralBarCard {
        root: generalTabContent.root
    }

    AnimatedSection {
        expanded: generalTabContent.root.generalTab.curDynamicIsland
        DynamicIslandOptionsCard {
            root: generalTabContent.root
        }
    }

    GlobalFrameCard {
        root: generalTabContent.root
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Layout.topMargin: 4
        spacing: 12

        Text {
            text: "Widget Settings"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 260
            height: 32
            radius: 7
            color: generalTabContent.root.theme.bgSurface
            border.color: optionSearchInput.activeFocus ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.bgBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "󰍉"
                    font.family: generalTabContent.root.font
                    font.pixelSize: Style.px(13)
                    color: optionSearchInput.activeFocus ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                TextInput {
                    id: optionSearchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: generalTabContent.root.font
                    font.pixelSize: Style.px(12)
                    color: generalTabContent.root.theme.textPrimary
                    selectByMouse: true
                    clip: true
                    text: generalTabContent.root.optionSearchQuery
                    onTextChanged: generalTabContent.root.optionSearchQuery = text

                    Text {
                        visible: parent.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search widget settings..."
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(11)
                        color: generalTabContent.root.theme.textMuted
                    }
                }

                Rectangle {
                    visible: optionSearchInput.text !== ""
                    width: 18
                    height: 18
                    radius: 9
                    color: clearOptionSearchHover.hovered ? generalTabContent.root.theme.bgHover : "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    HoverHandler { id: clearOptionSearchHover }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(10)
                        color: clearOptionSearchHover.hovered ? generalTabContent.root.theme.textPrimary : generalTabContent.root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            optionSearchInput.text = "";
                            generalTabContent.root.optionSearchQuery = "";
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        readonly property var r: generalTabContent.root
        readonly property bool isSearching: r.optionSearchQuery.trim() !== ""
        readonly property bool hasAnyMatch: {
            for (let i = 0; i < generalTabContent.widgetEntries.length; i++) {
                if (r.matchesOptionFilter(generalTabContent.widgetEntries[i].filter)) return true;
            }
            return false;
        }

        // Empty state when no configurable widgets are active on this bar (and not searching)
        AnimatedSection {
            expanded: generalTabContent.activeWidgetCardCount === 0 && !parent.isSearching
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 54
                radius: 10
                color: Style.theme.bgSurface
                border.color: Style.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "No configurable widgets are active on this bar."
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(12)
                        color: generalTabContent.root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        height: 28
                        implicitWidth: goLayoutTxt.implicitWidth + 20
                        radius: 6
                        color: goLayoutHover.hovered ? generalTabContent.root.theme.bgHover : generalTabContent.root.theme.bgBase
                        border.color: goLayoutHover.hovered ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.bgBorder
                        border.width: 1

                        HoverHandler { id: goLayoutHover }

                        Text {
                            id: goLayoutTxt
                            anchors.centerIn: parent
                            text: "Configure in Layout & Panels"
                            font.family: generalTabContent.root.font
                            font.pixelSize: Style.px(11)
                            font.bold: true
                            color: goLayoutHover.hovered ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                generalTabContent.root.currentSubTab = 0;
                                generalTabContent.root.subTabContentAnimation.restart();
                            }
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true; height: 16 }
        }

        // 1. Active widgets on the currently selected bar
        Repeater {
            model: generalTabContent.widgetEntries
            delegate: AnimatedSection {
                required property var modelData
                expanded: generalTabContent.isCardActive(modelData.ids)
                    && generalTabContent.root.matchesOptionFilter(modelData.filter)
                Loader {
                    Layout.fillWidth: true
                    active: parent.expanded || parent.visible
                    sourceComponent: modelData.comp
                }
                Item { Layout.fillWidth: true; height: 20 }
            }
        }

        // 2. Collapsible section for widgets not active on the currently selected bar
        AnimatedSection {
            expanded: generalTabContent.inactiveWidgetCardCount > 0 && !parent.isSearching
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                color: inactiveToggleHover.hovered ? generalTabContent.root.theme.bgHover : generalTabContent.root.theme.bgSurface
                border.color: generalTabContent.root.theme.bgBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                HoverHandler { id: inactiveToggleHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: generalTabContent.showInactiveWidgets ? "󰅀" : "󰅂"
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(13)
                        color: generalTabContent.root.theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Not Active on This Bar (" + generalTabContent.inactiveWidgetCardCount + ")"
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: generalTabContent.root.theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: generalTabContent.showInactiveWidgets ? "Hide" : "Show"
                        font.family: generalTabContent.root.font
                        font.pixelSize: Style.px(11)
                        color: inactiveToggleHover.hovered ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: generalTabContent.showInactiveWidgets = !generalTabContent.showInactiveWidgets
                }
            }
            Item { Layout.fillWidth: true; height: generalTabContent.showInactiveWidgets ? 16 : 0 }
        }

        Repeater {
            model: generalTabContent.widgetEntries
            delegate: AnimatedSection {
                required property var modelData
                expanded: !generalTabContent.isCardActive(modelData.ids)
                    && (generalTabContent.showInactiveWidgets || generalTabContent.root.optionSearchQuery.trim() !== "")
                    && generalTabContent.root.matchesOptionFilter(modelData.filter)
                opacity: 0.85
                Loader {
                    Layout.fillWidth: true
                    active: parent.expanded || parent.visible
                    sourceComponent: modelData.comp
                }
                Item { Layout.fillWidth: true; height: 20 }
            }
        }

        AnimatedSection {
            expanded: !parent.hasAnyMatch && parent.isSearching
            Item {
                Layout.fillWidth: true
                height: 64
                Text {
                    anchors.centerIn: parent
                    text: "No widget settings matching \"" + generalTabContent.root.optionSearchQuery.trim() + "\""
                    font.family: generalTabContent.root.font
                    font.pixelSize: Style.px(12)
                    color: generalTabContent.root.theme.textMuted
                }
            }
        }
    }
}
