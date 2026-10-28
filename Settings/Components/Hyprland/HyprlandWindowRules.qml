import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.currentSubTab === 2
    Layout.fillWidth: true
    spacing: 16

    /* ========================================================================= */
    /* 1. QUICK CATEGORY OPACITY OVERRIDES CARD                                  */
    /* ========================================================================= */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Application Category Opacity Rules"
        subtitle: "Tag-based active & inactive transparency from WindowWorkspaces.lua"

        Repeater {
            model: [
                { ruleName: "opacity-tag-browser",      title: "Web Browsers",          desc: "Firefox, Chrome, Brave, Edge, Zen (+browser)",         defAct: 0.99, defInact: 0.80 },
                { ruleName: "opacity-tag-projects",     title: "IDEs & Code Editors",   desc: "VSCode, VSCodium, JetBrains, Zed, Antigravity (+projects)", defAct: 0.90, defInact: 0.80 },
                { ruleName: "opacity-tag-terminal",     title: "Terminals",             desc: "Kitty, Alacritty, dropterm (+terminal)",               defAct: 0.90, defInact: 0.70 },
                { ruleName: "opacity-tag-file-manager", title: "File Managers",         desc: "Thunar, Nautilus, PCManFM, Warp (+file-manager)",      defAct: 0.90, defInact: 0.80 },
                { ruleName: "opacity-tag-im",           title: "Instant Messaging",     desc: "Discord, Vesktop, Telegram, Element, Ferdium (+im)",   defAct: 0.94, defInact: 0.86 },
                { ruleName: "opacity-tag-multimedia",   title: "Multimedia Audio",      desc: "Audacious and music players (+multimedia)",            defAct: 0.94, defInact: 0.86 },
                { ruleName: "opacity-tag-settings",     title: "Settings & Dialogs",    desc: "Pavucontrol, Blueman, NetworkManager, QtCt (+settings)", defAct: 0.80, defInact: 0.70 },
                { ruleName: "opacity-tag-viewer",       title: "System & Doc Viewers",  desc: "Mission Center, System Monitor, Evince, Loupe (+viewer)", defAct: 0.82, defInact: 0.75 }
            ]

            delegate: ColumnLayout {
                id: catOpDelegate
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 6

                property bool customActive: false
                readonly property var ruleObj: root.findRuleByName(modelData.ruleName)
                readonly property bool isRuleEnabled: ruleObj ? ruleObj.enabled : false
                readonly property real actVal: ruleObj ? ruleObj.activeOpacity : modelData.defAct
                readonly property real inactVal: ruleObj ? ruleObj.inactiveOpacity : modelData.defInact

                readonly property var presetModel: [
                    { label: "95/85", a: 0.95, i: 0.85 },
                    { label: "90/80", a: 0.90, i: 0.80 },
                    { label: "90/70", a: 0.90, i: 0.70 },
                    { label: "80/70", a: 0.80, i: 0.70 }
                ]

                readonly property int matchingPresetIdx: {
                    for (let k = 0; k < presetModel.length; k++) {
                        if (Math.abs(actVal - presetModel[k].a) < 0.015 && Math.abs(inactVal - presetModel[k].i) < 0.015) {
                            return k;
                        }
                    }
                    return -1;
                }

                readonly property bool isCustomEffective: customActive || matchingPresetIdx === -1
                readonly property int activeSegmentIdx: isCustomEffective ? presetModel.length : matchingPresetIdx

                RowDivider {
                    visible: catOpDelegate.index > 0
                    sideMargin: 0
                    alpha: 1.0
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.preferredHeight: 52
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            spacing: 8
                            Text {
                                text: catOpDelegate.modelData.title
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Rectangle {
                                visible: catOpDelegate.isRuleEnabled
                                opacity: catOpDelegate.isRuleEnabled ? 1.0 : 0.0
                                implicitWidth: opBadgeTxt.implicitWidth + 12
                                height: 18
                                radius: 9
                                color: root.theme.bgSelected
                                border.color: root.theme.accentPrimary
                                border.width: 1

                                Behavior on opacity { NumberAnimation { duration: 180 } }

                                Text {
                                    id: opBadgeTxt
                                    anchors.centerIn: parent
                                    text: Math.round(catOpDelegate.actVal * 100) + "% / " + Math.round(catOpDelegate.inactVal * 100) + "%"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                }
                            }
                        }

                        Text {
                            text: catOpDelegate.modelData.desc
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    /* Segmented Track with Sliding Selection Pill + Custom (Matching SettingSliderRow) */
                    Rectangle {
                        id: opSegmentTrack
                        visible: opacity > 0
                        opacity: catOpDelegate.isRuleEnabled ? 1.0 : 0.0
                        scale: catOpDelegate.isRuleEnabled ? 1.0 : 0.96
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        implicitWidth: 320
                        height: 32
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        readonly property int count: catOpDelegate.presetModel.length + 1
                        readonly property real cellWidth: (width - 6 - (count - 1) * 3) / count

                        /* Sliding Selection Pill */
                        Rectangle {
                            visible: catOpDelegate.activeSegmentIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: opSegmentTrack.cellWidth
                            x: 3 + Math.max(0, catOpDelegate.activeSegmentIdx) * (opSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: catOpDelegate.presetModel

                                delegate: Rectangle {
                                    id: opSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: catOpDelegate.activeSegmentIdx === opSegBtn.index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && pHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: pHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: opSegBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: isSel
                                        color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: isSel || pHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            catOpDelegate.customActive = false;
                                            root.setRuleOpacity(catOpDelegate.modelData.ruleName, opSegBtn.modelData.a, opSegBtn.modelData.i);
                                        }
                                    }
                                }
                            }

                            /* Custom Segment Button */
                            Rectangle {
                                id: opCustomSegBtn
                                readonly property bool isSel: catOpDelegate.activeSegmentIdx === catOpDelegate.presetModel.length

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && opCustHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: opCustHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: catOpDelegate.isCustomEffective
                                        ? (Math.round(catOpDelegate.actVal * 100) + "/" + Math.round(catOpDelegate.inactVal * 100))
                                        : "Custom"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: opCustomSegBtn.isSel
                                    color: opCustomSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: opCustomSegBtn.isSel || opCustHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        catOpDelegate.customActive = !catOpDelegate.customActive;
                                    }
                                }
                            }
                        }
                    }

                    /* Enable Toggle Switch */
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        scale: catToggleMouse.pressed ? 0.94 : 1.0
                        color: catOpDelegate.isRuleEnabled ? root.theme.accentPrimary : root.theme.bgSelected
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: catOpDelegate.isRuleEnabled ? parent.width - width - 3 : 3
                            color: catOpDelegate.isRuleEnabled ? "#ffffff" : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        MouseArea {
                            id: catToggleMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.toggleWindowRule(catOpDelegate.modelData.ruleName, !catOpDelegate.isRuleEnabled);
                            }
                        }
                    }
                }

                /* Expandable Custom Active / Inactive Dual Sliders Row */
                RowLayout {
                    visible: opacity > 0
                    opacity: (catOpDelegate.isRuleEnabled && catOpDelegate.isCustomEffective) ? 1.0 : 0.0
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: visible ? 6 : 0
                    spacing: 18

                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    /* Active Opacity Mini Slider */
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Active Opacity:"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textSecondary
                        }

                        Rectangle {
                            id: actCustomTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: root.theme.bgSelected
                            readonly property real frac: Math.max(0.0, Math.min(1.0, (catOpDelegate.actVal - 0.5) / 0.5))

                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width: parent.width * actCustomTrack.frac
                                color: root.theme.accentPrimary
                                Behavior on width { NumberAnimation { duration: actMouse.pressed ? 0 : 140; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                id: actKnob
                                width: actMouse.containsMouse || actMouse.pressed ? 16 : 14
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: root.theme.accentPrimary
                                border.width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(actCustomTrack.width - width, (actCustomTrack.width * actCustomTrack.frac) - (width / 2)))
                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on x { NumberAnimation { duration: actMouse.pressed ? 0 : 140; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: actMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                function applyPos(mouse) {
                                    if (actCustomTrack.width <= 0) return;
                                    const tx = mapToItem(actCustomTrack, mouse.x, 0).x;
                                    const f = Math.max(0.0, Math.min(1.0, tx / actCustomTrack.width));
                                    const val = Math.round((0.5 + f * 0.5) * 100) / 100;
                                    root.setRuleOpacity(catOpDelegate.modelData.ruleName, val, catOpDelegate.inactVal);
                                }
                                onPressed: (m) => { m.accepted = true; applyPos(m); }
                                onPositionChanged: (m) => { if (pressed) { m.accepted = true; applyPos(m); } }
                            }
                        }

                        Text {
                            text: Math.round(catOpDelegate.actVal * 100) + "%"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    /* Inactive Opacity Mini Slider */
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Inactive Opacity:"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textSecondary
                        }

                        Rectangle {
                            id: inactCustomTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: root.theme.bgSelected
                            readonly property real frac: Math.max(0.0, Math.min(1.0, (catOpDelegate.inactVal - 0.5) / 0.5))

                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width: parent.width * inactCustomTrack.frac
                                color: root.theme.accentPrimary
                                Behavior on width { NumberAnimation { duration: inactMouse.pressed ? 0 : 140; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                id: inactKnob
                                width: inactMouse.containsMouse || inactMouse.pressed ? 16 : 14
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: root.theme.accentPrimary
                                border.width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(inactCustomTrack.width - width, (inactCustomTrack.width * inactCustomTrack.frac) - (width / 2)))
                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on x { NumberAnimation { duration: inactMouse.pressed ? 0 : 140; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: inactMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                function applyPos(mouse) {
                                    if (inactCustomTrack.width <= 0) return;
                                    const tx = mapToItem(inactCustomTrack, mouse.x, 0).x;
                                    const f = Math.max(0.0, Math.min(1.0, tx / inactCustomTrack.width));
                                    const val = Math.round((0.5 + f * 0.5) * 100) / 100;
                                    root.setRuleOpacity(catOpDelegate.modelData.ruleName, catOpDelegate.actVal, val);
                                }
                                onPressed: (m) => { m.accepted = true; applyPos(m); }
                                onPositionChanged: (m) => { if (pressed) { m.accepted = true; applyPos(m); } }
                            }
                        }

                        Text {
                            text: Math.round(catOpDelegate.inactVal * 100) + "%"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }

    /* ========================================================================= */
    /* 2. QUICK SPECIAL & FLOATING BEHAVIORS CARD                                */
    /* ========================================================================= */
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

    /* ========================================================================= */
    /* 3. INTERACTIVE LUA WINDOW & LAYER RULES STUDIO                            */
    /* ========================================================================= */
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

                /* ============================================================= */
                /* ADD / EDIT RULE DRAWER                                        */
                /* ============================================================= */
                Rectangle {
                    id: ruleFormDrawer
                    readonly property bool isDrawerOpen: root.isAddingRule || root.editingRuleName !== ""
                    Layout.fillWidth: true
                    visible: implicitHeight > 0 || opacity > 0
                    implicitHeight: isDrawerOpen ? (ruleFormCol.implicitHeight + 24) : 0
                    opacity: isDrawerOpen ? 1.0 : 0.0
                    radius: 10
                    color: root.theme.bgBase
                    border.color: root.theme.accentPrimary
                    border.width: 1
                    clip: true

                    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        id: ruleFormCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: root.editingRuleName !== "" ? ("Edit Lua Rule: " + root.editingRuleName) : "Create New Lua Window / Layer Rule"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Configs/WindowWorkspaces.lua"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textMuted
                            }
                        }

                        /* Row 1: Rule Type & Rule Name */
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Type:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            /* Segmented Rule Type Track with Sliding Selection Pill */
                            Rectangle {
                                id: ruleTypeSegmentTrack
                                implicitWidth: 240
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                readonly property int activeIdx: root.formRuleType === "layer_rule" ? 1 : 0
                                readonly property real cellWidth: (width - 6 - 3) / 2

                                Rectangle {
                                    y: 3
                                    height: parent.height - 6
                                    width: ruleTypeSegmentTrack.cellWidth
                                    x: 3 + ruleTypeSegmentTrack.activeIdx * (ruleTypeSegmentTrack.cellWidth + 3)
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
                                            { id: "window_rule", label: "hl.window_rule" },
                                            { id: "layer_rule",  label: "hl.layer_rule" }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: ruleTypeSegmentTrack.activeIdx === index
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && rtHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: rtHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: isSel
                                                color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: isSel || rtHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.formRuleType = modelData.id
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Name:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formNameInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formNameInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formNameInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formRuleName
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formRuleName) root.formRuleName = text

                                    Text {
                                        text: "Unique rule identifier (e.g. my-custom-float)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formNameInput.text && !formNameInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        /* Row 2: Match Class / Namespace */
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Match:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            Rectangle {
                                visible: root.formRuleType === "window_rule"
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formClassInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formClassInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formClassInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formMatchClass
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formMatchClass) root.formMatchClass = text

                                    Text {
                                        text: "class regex (e.g. ^([Ff]irefox|org.mozilla.firefox)$)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formClassInput.text && !formClassInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.formRuleType === "layer_rule"
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formNsInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formNsInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formNsInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formMatchNamespace
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formMatchNamespace) root.formMatchNamespace = text

                                    Text {
                                        text: "layer namespace (e.g. rofi, notifications, quickshell:overview)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formNsInput.text && !formNsInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        /* Row 2b: Title & Tag Match Criteria (for Window Rules) */
                        RowLayout {
                            visible: root.formRuleType === "window_rule"
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Filter:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formTitleInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formTitleInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formTitleInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formMatchTitle
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formMatchTitle) root.formMatchTitle = text

                                    Text {
                                        text: "title regex (optional, e.g. ^(Picture-in-Picture|Save File)$)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formTitleInput.text && !formTitleInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 200
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formTagMatchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formTagMatchInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formTagMatchInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formMatchTag
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formMatchTag) root.formMatchTag = text

                                    Text {
                                        text: "match tag (e.g. browser*)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formTagMatchInput.text && !formTagMatchInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        /* Row 3: Window Rule Effects (Boolean pills + Parameters) */
                        RowLayout {
                            visible: root.formRuleType === "window_rule"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Flags:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            /* Unified Track for Boolean Flags */
                            Rectangle {
                                implicitWidth: flagRow.implicitWidth + 6
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                RowLayout {
                                    id: flagRow
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: [
                                            { key: "float",    label: "Float" },
                                            { key: "center",   label: "Center" },
                                            { key: "pin",      label: "Pin" },
                                            { key: "no_blur",  label: "No Blur" },
                                            { key: "no_anim",  label: "No Anim" },
                                            { key: "no_focus", label: "No Focus" }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            readonly property bool isOn: {
                                                if (modelData.key === "float") return root.formEffectFloat;
                                                if (modelData.key === "center") return root.formEffectCenter;
                                                if (modelData.key === "pin") return root.formEffectPin;
                                                if (modelData.key === "no_blur") return root.formEffectNoBlur;
                                                if (modelData.key === "no_anim") return root.formEffectNoAnim;
                                                if (modelData.key === "no_focus") return root.formEffectNoFocus;
                                                return false;
                                            }
                                            implicitWidth: flagTxt.implicitWidth + 18
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: isOn ? root.theme.bgSelected : (flagHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                            border.color: isOn ? root.theme.accentPrimary : "transparent"
                                            border.width: 1
                                            scale: flagMouse.pressed ? 0.96 : 1.0

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                            HoverHandler { id: flagHover }

                                            Text {
                                                id: flagTxt
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: isOn
                                                color: isOn ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: isOn || flagHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                id: flagMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.key === "float") root.formEffectFloat = !root.formEffectFloat;
                                                    else if (modelData.key === "center") root.formEffectCenter = !root.formEffectCenter;
                                                    else if (modelData.key === "pin") root.formEffectPin = !root.formEffectPin;
                                                    else if (modelData.key === "no_blur") root.formEffectNoBlur = !root.formEffectNoBlur;
                                                    else if (modelData.key === "no_anim") root.formEffectNoAnim = !root.formEffectNoAnim;
                                                    else if (modelData.key === "no_focus") root.formEffectNoFocus = !root.formEffectNoFocus;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        /* Row 4: Window Rule Value Effects (Opacity, Size, Move, Workspace, Tag) */
                        RowLayout {
                            visible: root.formRuleType === "window_rule"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Values:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formOpInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formOpInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formOpInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formEffectOpacity
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formEffectOpacity) root.formEffectOpacity = text

                                    Text {
                                        text: "opacity (e.g. 0.9 0.8)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formOpInput.text && !formOpInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formSizeInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formSizeInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formSizeInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formEffectSize
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formEffectSize) root.formEffectSize = text

                                    Text {
                                        text: "size (e.g. (monitor_w*0.7) (monitor_h*0.7))"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formSizeInput.text && !formSizeInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 120
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formWsInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formWsInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formWsInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formEffectWorkspace
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formEffectWorkspace) root.formEffectWorkspace = text

                                    Text {
                                        text: "workspace (e.g. 2)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formWsInput.text && !formWsInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 135
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formAssignTagInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formAssignTagInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formAssignTagInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formEffectTag
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formEffectTag) root.formEffectTag = text

                                    Text {
                                        text: "assign tag (+browser)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formAssignTagInput.text && !formAssignTagInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        /* Row 4b: Layer Rule Effects */
                        RowLayout {
                            visible: root.formRuleType === "layer_rule"
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Layer:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.preferredWidth: 70
                            }

                            Rectangle {
                                implicitWidth: 116
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 5
                                    color: root.formLayerBlur ? root.theme.bgSelected : (layerBlurHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                    border.color: root.formLayerBlur ? root.theme.accentPrimary : "transparent"
                                    border.width: 1
                                    scale: layerBlurMouse.pressed ? 0.96 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    HoverHandler { id: layerBlurHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Blur Layer"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: root.formLayerBlur
                                        color: root.formLayerBlur ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: root.formLayerBlur || layerBlurHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: layerBlurMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formLayerBlur = !root.formLayerBlur
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 180
                                height: 32
                                radius: 7
                                color: root.theme.bgSurface
                                border.color: formIgnoreAlphaInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: formIgnoreAlphaInput.activeFocus ? 2 : 1
                                clip: true

                                TextInput {
                                    id: formIgnoreAlphaInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.formLayerIgnoreAlpha
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: if (text !== root.formLayerIgnoreAlpha) root.formLayerIgnoreAlpha = text

                                    Text {
                                        text: "ignore_alpha (e.g. 0.5)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textMuted
                                        visible: !formIgnoreAlphaInput.text && !formIgnoreAlphaInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        /* Row 5: Cancel / Delete / Save Buttons */
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                visible: root.editingRuleName !== ""
                                implicitWidth: delRuleTxt.implicitWidth + 24
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 5
                                    color: delRuleHover.hovered ? Qt.rgba(0.95, 0.25, 0.35, 0.2) : "transparent"
                                    border.color: delRuleHover.hovered ? "#f7768e" : "transparent"
                                    border.width: 1
                                    scale: delRuleMouse.pressed ? 0.96 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    HoverHandler { id: delRuleHover }

                                    Text {
                                        id: delRuleTxt
                                        anchors.centerIn: parent
                                        text: "Delete Rule"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: delRuleHover.hovered ? "#f7768e" : root.theme.textSecondary
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: delRuleMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.deleteWindowRule(root.editingRuleName)
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                implicitWidth: cancelRuleTxt.implicitWidth + 28
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 5
                                    color: cancelRuleHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    scale: cancelRuleMouse.pressed ? 0.96 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    HoverHandler { id: cancelRuleHover }

                                    Text {
                                        id: cancelRuleTxt
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: cancelRuleHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: cancelRuleMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isAddingRule = false;
                                            root.editingRuleName = "";
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                readonly property bool canSave: root.formRuleName.trim().length > 0
                                implicitWidth: saveRuleTxt.implicitWidth + 32
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                opacity: canSave ? 1.0 : 0.45

                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 5
                                    color: parent.canSave ? root.theme.bgSelected : "transparent"
                                    border.color: parent.canSave ? root.theme.accentPrimary : "transparent"
                                    border.width: 1
                                    scale: saveRuleMouse.pressed ? 0.96 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    Text {
                                        id: saveRuleTxt
                                        anchors.centerIn: parent
                                        text: root.editingRuleName !== "" ? "Save Rule Changes" : "Add Lua Rule"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: parent.parent.canSave ? root.theme.accentPrimary : root.theme.textMuted
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: saveRuleMouse
                                        anchors.fill: parent
                                        enabled: parent.parent.canSave
                                        cursorShape: parent.parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.saveRuleForm()
                                    }
                                }
                            }
                        }
                    }
                }

                /* ============================================================= */
                /* FILTER SEGMENTED TRACK & SEARCH BAR                           */
                /* ============================================================= */
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

                /* ============================================================= */
                /* RULES REPEATER                                                */
                /* ============================================================= */
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

