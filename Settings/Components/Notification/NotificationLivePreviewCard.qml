import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../../notifications"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: previewSection
    property bool composerExpanded: false
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Live Preview"
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
        implicitHeight: innerCol.implicitHeight + 12 * 2
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
                margins: 12
            }
            spacing: 12
            // 1. TOP PRESETS & LIVE TEST BAR
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 9
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "Preview Preset:"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    RowLayout {
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "screenshot", label: "Screenshot", icon: "󰄄" },
                                { id: "message",    label: "Message",    icon: "󰖣" },
                                { id: "media",      label: "Media",      icon: "󰓇" },
                                { id: "critical",   label: "Critical",   icon: "󰀦" }
                            ]
                            delegate: Rectangle {
                                id: presetBtn
                                required property var modelData
                                readonly property bool isCurrent: NotificationService.composerPreset === modelData.id

                                implicitWidth: presetBtnRow.implicitWidth + 16
                                height: 28
                                radius: 6
                                color: isCurrent
                                    ? root.theme.bgSelected
                                    : (presetHover.hovered ? root.theme.bgHover : "transparent")
                                border.color: isCurrent ? root.theme.accentPrimary : "transparent"
                                border.width: isCurrent ? 1 : 0
                                scale: presetMouse.pressed ? 0.95 : 1.0

                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                HoverHandler { id: presetHover }

                                RowLayout {
                                    id: presetBtnRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: presetBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: presetBtn.isCurrent
                                        color: presetBtn.isCurrent ? root.theme.accentPrimary : root.theme.textPrimary
                                    }
                                }

                                MouseArea {
                                    id: presetMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.applyComposerPreset(presetBtn.modelData.id);
                                        root.showToast("Loaded '" + presetBtn.modelData.label + "' template into preview");
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        iconText: previewSection.composerExpanded ? "󰅃" : "󰏫"
                        label: previewSection.composerExpanded ? "Hide Test Editor" : "Customize Test"
                        btnHeight: 28
                        onClicked: previewSection.composerExpanded = !previewSection.composerExpanded
                    }

                    Rectangle {
                        id: sendLiveBtn
                        implicitWidth: sendLiveRow.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: sendLiveHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.12) : root.theme.accentPrimary
                        scale: sendLiveMouse.pressed ? 0.96 : 1.0

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 90 } }

                        HoverHandler { id: sendLiveHover }

                        RowLayout {
                            id: sendLiveRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "Send Live Toast"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.bgBase
                            }
                        }

                        MouseArea {
                            id: sendLiveMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.sendCustomNotification({});
                                root.showToast("Dispatched live toast popup to desktop (" + root.getPositionLabel(root.toastPos) + ")");
                            }
                        }
                    }
                }
            }

            // 2. INTERACTIVE SIMULATED DESKTOP STAGE WITH LIVE NOTIFICATION TOAST
            Rectangle {
                id: stageCanvas
                Layout.fillWidth: true
                implicitHeight: Math.max(190, simCard.implicitHeight + 52)
                radius: 12
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1
                clip: true

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Subtle grid / desktop backdrop ambiance
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 9
                    color: root.withAlpha(root.theme.accentPrimary, 0.03)
                    border.color: Style.theme.bgBorder
                    border.width: 1
                }

                // Corner badge showing active inspector selection (click to jump to styling)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 12
                    height: 22
                    implicitWidth: selBadgeRow.implicitWidth + 16
                    radius: 11
                    color: selBadgeHover.hovered ? root.withAlpha(root.theme.accentPrimary, 0.16) : root.withAlpha(root.theme.bgSurface, 0.9)
                    border.color: root.withAlpha(root.theme.accentPrimary, selBadgeHover.hovered ? 0.65 : 0.35)
                    border.width: 1
                    z: 5

                    HoverHandler { id: selBadgeHover }

                    RowLayout {
                        id: selBadgeRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: root.theme.accentPrimary
                        }

                        Text {
                            text: "Selected: " + root.getInspectorLabel(root.selectedInspectorBlock) + " 󰁅"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: selBadgeHover.hovered ? root.theme.accentPrimary : root.theme.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scrollToInspector()
                    }
                }

                // Corner dimensions readout badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    height: 22
                    implicitWidth: dimTxt.implicitWidth + 14
                    radius: 11
                    color: root.withAlpha(root.theme.bgSurface, 0.9)
                    border.color: root.theme.bgBorder
                    border.width: 1
                    z: 5

                    Text {
                        id: dimTxt
                        anchors.centerIn: parent
                        text: NotificationService.toastWidth + "px wide  ·  " + NotificationService.cardRadius + "px radius"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                    }
                }

                // Simulated Live Notification Toast Card
                Rectangle {
                    id: simCard
                    anchors.centerIn: parent
                    width: Math.min(stageCanvas.width - 36, NotificationService.toastWidth)
                    implicitHeight: simOuterRow.implicitHeight + (simPad * 2)
                    height: implicitHeight
                    radius: NotificationService.cardRadius
                    opacity: NotificationService.cardOpacity
                    color: root.theme.bgBase
                    border.color: NotificationService.composerUrgency === NotificationUrgency.Critical
                        ? (root.theme.accentRed ?? "#f7768e")
                        : (NotificationService.composerUrgency === NotificationUrgency.Low
                            ? root.withAlpha(root.theme.textMuted, 0.5)
                            : root.withAlpha(root.theme.accentPrimary, 0.65))
                    border.width: 1.5
                    clip: true

                    readonly property int simPad: NotificationService.cardPadding
                    readonly property string stripPos: NotificationService.showAccentStrip ? NotificationService.accentStripPosition : "none"
                    readonly property color urgencyCol: {
                        if (NotificationService.composerUrgency === NotificationUrgency.Critical) return root.theme.accentRed ?? "#f7768e";
                        if (NotificationService.composerUrgency === NotificationUrgency.Low) return root.theme.textSecondary;
                        return root.theme.accentPrimary;
                    }

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on radius { NumberAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    // Accent Strip (Click to inspect Card & Accent Strip)
                    Rectangle {
                        visible: simCard.stripPos !== "none"
                        width: (simCard.stripPos === "left" || simCard.stripPos === "right")
                            ? NotificationService.accentStripWidth
                            : (parent.width - 20)
                        height: (simCard.stripPos === "top")
                            ? NotificationService.accentStripWidth
                            : (parent.height - 16)
                        radius: NotificationService.accentStripWidth / 2
                        x: simCard.stripPos === "left"
                            ? 6
                            : (simCard.stripPos === "right" ? parent.width - width - 6 : 10)
                        y: simCard.stripPos === "top"
                            ? 5
                            : Math.round((parent.height - height) / 2)
                        color: simCard.urgencyCol

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedInspectorBlock = "card"
                        }
                    }

                    RowLayout {
                        id: simOuterRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: simCard.simPad + (simCard.stripPos === "left" ? NotificationService.accentStripWidth + 4 : 0)
                            rightMargin: simCard.simPad + (simCard.stripPos === "right" ? NotificationService.accentStripWidth + 4 : 0)
                            topMargin: simCard.simPad + (simCard.stripPos === "top" ? NotificationService.accentStripWidth + 2 : 0)
                        }
                        spacing: 10

                        // Left Avatar Icon Column (when Icon Mode is Avatar or Icon is in Zone 2)
                        Rectangle {
                            visible: NotificationService.isAvatarIconEffective
                            Layout.preferredWidth: Math.max(32, NotificationService.iconSize)
                            Layout.preferredHeight: Math.max(32, NotificationService.iconSize)
                            Layout.alignment: Qt.AlignTop
                            radius: NotificationService.iconRadius
                            color: NotificationService.iconShowBg
                                ? Qt.alpha(simCard.urgencyCol, 0.15)
                                : "transparent"
                            border.color: root.selectedInspectorBlock === "icon" ? root.theme.accentPrimary : "transparent"
                            border.width: root.selectedInspectorBlock === "icon" ? 1.5 : 0

                            Text {
                                anchors.centerIn: parent
                                text: NotificationService.composerIcon || "󰂚"
                                color: simCard.urgencyCol
                                font.pixelSize: Math.round(parent.width * 0.56)
                                font.family: root.font
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedInspectorBlock = "icon"
                            }
                        }

                        // 3-Zone Dynamic Stack inside Live Preview Card
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { zoneIdx: 0, blocks: NotificationService.headerBlocks },
                                    { zoneIdx: 1, blocks: NotificationService.contentBlocks },
                                    { zoneIdx: 2, blocks: NotificationService.footerBlocks }
                                ]

                                delegate: ColumnLayout {
                                    id: simZoneCol
                                    required property var modelData
                                    readonly property var zoneBlocks: modelData.blocks || []
                                    readonly property bool hasInlineHeader: {
                                        for (let i = 0; i < zoneBlocks.length; i++) {
                                            const b = zoneBlocks[i];
                                            if (b === "appName" || b === "timestamp" || b === "closeBtn" || (b === "icon" && !NotificationService.isAvatarIconEffective)) {
                                                return true;
                                            }
                                        }
                                        return false;
                                    }
                                    readonly property bool hasPairedBodyAndImage: {
                                        return (zoneBlocks.indexOf("body") !== -1 || zoneBlocks.indexOf("title") !== -1)
                                            && zoneBlocks.indexOf("image") !== -1
                                            && NotificationService.imagePosition !== "banner";
                                    }
                                    readonly property bool hasPairedTitleBodyAndImage: {
                                        return zoneBlocks.indexOf("title") !== -1
                                            && zoneBlocks.indexOf("body") !== -1
                                            && zoneBlocks.indexOf("image") !== -1
                                            && NotificationService.imagePosition !== "banner"
                                            && Math.abs(zoneBlocks.indexOf("title") - zoneBlocks.indexOf("body")) === 1;
                                    }

                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: zoneBlocks.length > 0

                                    // Inline Header Items Row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: simZoneCol.hasInlineHeader

                                        Repeater {
                                            model: simZoneCol.zoneBlocks
                                            delegate: Loader {
                                                id: simInlineLoader
                                                required property string modelData
                                                readonly property bool isInline: modelData === "appName" || modelData === "timestamp" || modelData === "closeBtn" || (modelData === "icon" && !NotificationService.isAvatarIconEffective)
                                                visible: isInline
                                                Layout.fillWidth: modelData === "appName"
                                                Layout.alignment: Qt.AlignVCenter

                                                Binding {
                                                    target: simInlineLoader.item
                                                    property: "width"
                                                    value: simInlineLoader.width
                                                    when: simInlineLoader.item !== null && simInlineLoader.modelData === "appName"
                                                }

                                                sourceComponent: previewBlocks.getInlineComponent(modelData)
                                            }
                                        }
                                    }

                                    // Stacked Content / Footer Items
                                    Repeater {
                                        model: simZoneCol.zoneBlocks
                                        delegate: Loader {
                                            id: simStackLoader
                                            required property string modelData
                                            readonly property bool isStack: {
                                                if (modelData === "title") {
                                                    if (simZoneCol.hasPairedTitleBodyAndImage) return false;
                                                    return NotificationService.composerTitle !== "";
                                                }
                                                if (modelData === "body") {
                                                    return NotificationService.composerBody !== ""
                                                        || (simZoneCol.hasPairedTitleBodyAndImage && NotificationService.composerTitle !== "")
                                                        || (simZoneCol.hasPairedBodyAndImage && NotificationService.composerShowImage);
                                                }
                                                if (modelData === "image") {
                                                    return !simZoneCol.hasPairedBodyAndImage && NotificationService.composerShowImage;
                                                }
                                                if (modelData === "buttons") {
                                                    return NotificationService.composerButtons && NotificationService.composerButtons.length > 0;
                                                }
                                                if (modelData === "progressBar") {
                                                    return NotificationService.composerUrgency !== NotificationUrgency.Critical
                                                        || NotificationService.progressShowCritical;
                                                }
                                                return false;
                                            }
                                            visible: isStack
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: item ? item.implicitHeight : 0

                                            Binding {
                                                target: simStackLoader.item
                                                property: "width"
                                                value: simStackLoader.width
                                                when: simStackLoader.item !== null
                                            }

                                            sourceComponent: previewBlocks.getStackComponent(modelData, simZoneCol.hasPairedTitleBodyAndImage, simZoneCol.hasPairedBodyAndImage)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    NotificationPreviewBlocks {
                        id: previewBlocks
                        root: previewSection.root
                        urgencyColor: simCard.urgencyCol
                    }
                }
            }

            // 3. INTERACTIVE CUSTOM NOTIFICATION COMPOSER (ICON, TITLE, BODY, BUTTONS)
            Item {
                Layout.fillWidth: true
                implicitHeight: previewSection.composerExpanded ? composerPanel.implicitHeight : 0
                opacity: previewSection.composerExpanded ? 1.0 : 0.0
                visible: implicitHeight > 1
                clip: true

                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                NotificationComposerPanel {
                    id: composerPanel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    root: previewSection.root
                }
            }
        }
    }
}
