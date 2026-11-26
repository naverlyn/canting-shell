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
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Application Category Opacity Rules"
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
                    spacing: 0

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
                        Layout.preferredHeight: 42
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: catOpDelegate.modelData.title
                                font.family: root.font
                                font.pixelSize: Style.px(13)
                                font.bold: true
                                color: root.theme.textPrimary
                            }
                        }

                        Item { Layout.fillWidth: true }

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
                            border.color: root.theme.bgBorder
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
                                        color: !isSel && pHover.hovered ? root.theme.bgHover : "transparent"
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: pHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: opSegBtn.modelData.label
                                            font.family: root.font
                                            font.pixelSize: Style.px(11)
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
                                    color: !isSel && opCustHover.hovered ? root.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: opCustHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: catOpDelegate.isCustomEffective
                                            ? (Math.round(catOpDelegate.actVal * 100) + "/" + Math.round(catOpDelegate.inactVal * 100))
                                            : "Custom"
                                        font.family: root.font
                                        font.pixelSize: Style.px(11)
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
                        Layout.topMargin: visible ? 4 : 0
                        Layout.bottomMargin: visible ? 8 : 0
                        spacing: 18

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        /* Active Opacity Mini Slider */
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Active Opacity:"
                                font.family: root.font
                                font.pixelSize: Style.px(11)
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
                                font.pixelSize: Style.px(11)
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
                                font.pixelSize: Style.px(11)
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
                                font.pixelSize: Style.px(11)
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
    }
}
