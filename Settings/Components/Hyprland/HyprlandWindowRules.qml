import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    id: windowRulesRoot
    required property var root
    visible: root.currentSubTab === 2
    Layout.fillWidth: true
    spacing: 16

    // 1. QUICK CATEGORY OPACITY OVERRIDES CARD
    HyprlandCategoryOpacityCard {
        root: windowRulesRoot.root
    }

    // 2. QUICK SPECIAL & FLOATING BEHAVIORS CARD
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Special Window & Layer Behaviors"
        subtitle: "Quick toggles for Picture-in-Picture, floating dialogs, video blur, and shell layers"

        Repeater {
            model: [
                { ruleName: "Picture-in-Picture",        title: "Picture-in-Picture Floating Pin",    desc: "Float, pin, keep aspect ratio, and position PiP video in top-right corner" },
                { ruleName: "override-multimedia-video", title: "Solid Video Playback (mpv / VLC)",   desc: "Disable background blur and force 100% opacity on video players" },
                { ruleName: "override-games",            title: "Gaming Performance Override",        desc: "Disable blur and optimize fullscreen state for Steam & Gamescope" },
                { ruleName: "idle-inhibit-fullscreen",   title: "Fullscreen Idle Inhibitor",          desc: "Prevent screen sleep / hypridle while any window is fullscreen" },
                { ruleName: "float-settings-tag",        title: "Float Settings & Utility Windows",   desc: "Automatically float and center tagged settings apps (70%x70%)" },
                { ruleName: "float-viewer-tag",          title: "Float System & Document Viewers",    desc: "Automatically float and center system monitor, Evince, and image viewers" },
                { ruleName: "xwayland-video-bridge-fixes", title: "XWayland Video Bridge Hide Fix",   desc: "Hide and suppress focus/blur on xwaylandvideobridge helper window" },
                { ruleName: "layer-qs-overview",         title: "Quickshell Overview Layer Blur",     desc: "Apply background blur and ignore_alpha 0.5 to quickshell:overview" }
            ]

            delegate: ColumnLayout {
                id: specToggleDelegate
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0

                readonly property var ruleObj: root.findRuleByName(modelData.ruleName)
                readonly property bool isRuleEnabled: ruleObj ? ruleObj.enabled : true

                RowDivider {
                    visible: specToggleDelegate.index > 0
                    sideMargin: 0
                    alpha: 1.0
                }

                SettingToggleRow {
                    announce: false
                    title: specToggleDelegate.modelData.title
                    desc: specToggleDelegate.modelData.desc
                    checked: specToggleDelegate.isRuleEnabled
                    onToggled: (val) => {
                        root.toggleWindowRule(specToggleDelegate.modelData.ruleName, val);
                    }
                }
            }
        }
    }

    // 3. INTERACTIVE LUA WINDOW & LAYER RULES STUDIO
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8

            Text {
                text: "Lua Window & Layer Rules"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textSecondary
            }

            Text {
                text: "(" + root.windowRules.length + " in WindowWorkspaces.lua)"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            /* Add Rule Toggle Button */
            Rectangle {
                implicitWidth: addRuleBtnText.implicitWidth + 24
                height: 30
                radius: 7
                scale: addRuleMouse.pressed ? 0.96 : 1.0
                color: addRuleBtnHover.hovered
                    ? root.theme.bgHover
                    : (root.isAddingRule ? root.theme.bgSelected : root.theme.bgSurface)
                border.color: root.isAddingRule || addRuleBtnHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                HoverHandler { id: addRuleBtnHover }

                Text {
                    id: addRuleBtnText
                    anchors.centerIn: parent
                    text: root.isAddingRule ? "Close Rule Form" : "+ Add Lua Rule"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.isAddingRule || addRuleBtnHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: addRuleMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isAddingRule) {
                            root.isAddingRule = false;
                        } else {
                            root.startAddingRule();
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: rulesStudioCol.implicitHeight + 20
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: rulesStudioCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 8

                // ADD / EDIT RULE DRAWER
                HyprlandRuleFormDrawer {
                    root: windowRulesRoot.root
                }

                // FILTER SEGMENTED TRACK & SEARCH BAR
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    /* Segmented Category Filter Track with Sliding Selection Pill */
                    Rectangle {
                        id: filterSegmentTrack
                        Layout.fillWidth: true
                        height: 32
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        readonly property var catIds: ["all", "opacity", "float", "special", "tag", "layer"]
                        readonly property int activeIdx: Math.max(0, catIds.indexOf(root.ruleCategoryFilter))
                        readonly property real cellWidth: (width - 6 - 15) / 6

                        /* Sliding Selection Pill */
                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: filterSegmentTrack.cellWidth
                            x: 3 + filterSegmentTrack.activeIdx * (filterSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: "all",     label: "All Rules" },
                                    { id: "opacity", label: "Opacity" },
                                    { id: "float",   label: "Float & Dialogs" },
                                    { id: "special", label: "Special" },
                                    { id: "tag",     label: "App Tags" },
                                    { id: "layer",   label: "Layers" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    readonly property bool isCatSel: filterSegmentTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isCatSel && catHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: catHover }

                                    Text {
                                        id: catFilterTxt
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: isCatSel
                                        color: isCatSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: isCatSel || catHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.ruleCategoryFilter = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    /* Search Input */
                    Rectangle {
                        Layout.preferredWidth: 215
                        height: 32
                        radius: 7
                        color: root.theme.bgBase
                        border.color: ruleSearchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                        border.width: ruleSearchInput.activeFocus ? 2 : 1

                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "󰍉"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textSecondary
                            }

                            TextInput {
                                id: ruleSearchInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textPrimary
                                clip: true
                                selectByMouse: true
                                onTextChanged: root.ruleSearchQuery = text

                                Text {
                                    text: "Filter rules (firefox, float, pip)..."
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                    visible: !ruleSearchInput.text && !ruleSearchInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                visible: ruleSearchInput.text.length > 0
                                text: "✕"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ruleSearchInput.text = "";
                                        root.ruleSearchQuery = "";
                                    }
                                }
                            }
                        }
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                // RULES REPEATER
                Repeater {
                    model: root.filteredWindowRules

                    delegate: Rectangle {
                        id: ruleRowRect
                        required property var modelData
                        required property int index
                        readonly property bool isBeingEdited: root.editingRuleName === modelData.name

                        Layout.fillWidth: true
                        height: 52
                        radius: 8
                        color: isBeingEdited
                            ? root.theme.bgSelected
                            : (ruleRowHover.hovered ? root.theme.bgHover : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: ruleRowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            /* Enable/Disable Checkbox Pill */
                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: modelData.enabled ? root.theme.accentPrimary : root.theme.bgSelected
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: modelData.enabled ? parent.width - width - 3 : 3
                                    color: modelData.enabled ? "#ffffff" : root.theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleWindowRule(modelData.name, !modelData.enabled)
                                }
                            }

                            /* Rule Name & Match Summary */
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                opacity: modelData.enabled ? 1.0 : 0.5

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.name
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        implicitWidth: rTypeBadge.implicitWidth + 10
                                        height: 16
                                        radius: 4
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            id: rTypeBadge
                                            anchors.centerIn: parent
                                            text: modelData.ruleType === "layer_rule" ? "layer" : modelData.category
                                            font.family: root.font
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: root.theme.textSecondary
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.matchSummary
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            /* Effect Pills */
                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter
                                opacity: modelData.enabled ? 1.0 : 0.5

                                Repeater {
                                    model: modelData.effectPills ? modelData.effectPills.slice(0, 3) : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        implicitWidth: effPillTxt.implicitWidth + 12
                                        height: 22
                                        radius: 6
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            id: effPillTxt
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }
                                    }
                                }
                            }

                            /* Edit Button */
                            Rectangle {
                                width: 32
                                height: 28
                                radius: 6
                                color: ruleRowRect.isBeingEdited ? root.theme.bgSelected : (editBtnMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase)
                                border.color: ruleRowRect.isBeingEdited || editBtnMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1
                                scale: editBtnMouse.pressed ? 0.94 : 1.0

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰏫"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: ruleRowRect.isBeingEdited || editBtnMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: editBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.startEditingRule(modelData)
                                }
                            }
                        }
                    }
                }

                /* Show All Toggle Button if truncated */
                Item {
                    Layout.fillWidth: true
                    height: 40
                    visible: !root.showAllRules && root.ruleSearchQuery === "" && root.ruleCategoryFilter === "all" && root.windowRules.length > 20

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 8
                        color: showAllRulesMouse.containsMouse ? root.theme.bgSelected : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Show all " + root.windowRules.length + " Lua rules"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                            Text {
                                text: "󰅀"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.accentPrimary
                            }
                        }

                        MouseArea {
                            id: showAllRulesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showAllRules = true
                        }
                    }
                }
            }
        }
    }
}

