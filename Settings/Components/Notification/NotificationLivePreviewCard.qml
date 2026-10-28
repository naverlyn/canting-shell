import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../../notifications"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: previewSection
    title: "Interactive Notification Stage & Live Composer"
    subtitle: "Click any building block on the preview toast to inspect its style · Customize icon, title, body, and buttons to test live"

    property bool composerExpanded: true

    // =========================================================================
    // 1. TOP PRESETS & LIVE TEST BAR
    // =========================================================================
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
                                text: presetBtn.modelData.icon
                                font.family: root.font
                                font.pixelSize: 12
                                color: presetBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary
                            }

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
                label: previewSection.composerExpanded ? "Hide Composer" : "Edit Content"
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
                        text: "󰂚"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.bgBase
                    }

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

    // =========================================================================
    // 2. INTERACTIVE SIMULATED DESKTOP STAGE WITH LIVE NOTIFICATION TOAST
    // =========================================================================
    Rectangle {
        id: stageCanvas
        Layout.fillWidth: true
        implicitHeight: Math.max(190, simCard.implicitHeight + 52)
        radius: 12
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true

        // Subtle grid / desktop backdrop ambiance
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: 9
            color: root.withAlpha(root.theme.accentPrimary, 0.03)
            border.color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
        }

        // Corner badge showing active inspector selection
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 12
            height: 22
            implicitWidth: selBadgeRow.implicitWidth + 14
            radius: 11
            color: root.withAlpha(root.theme.bgSurface, 0.9)
            border.color: root.withAlpha(root.theme.accentPrimary, 0.35)
            border.width: 1
            z: 5

            RowLayout {
                id: selBadgeRow
                anchors.centerIn: parent
                spacing: 5

                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: root.theme.accentPrimary
                }

                Text {
                    text: "Inspecting: " + root.getInspectorLabel(root.selectedInspectorBlock)
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.theme.textSecondary
                }
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
                text: NotificationService.toastWidth + "px  ·  R" + NotificationService.cardRadius
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
            Behavior on radius { NumberAnimation { duration: 140 } }

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

                                        sourceComponent: {
                                            if (modelData === "icon" && !NotificationService.isAvatarIconEffective) return previewInlineIconComp;
                                            if (modelData === "appName") return previewAppNameComp;
                                            if (modelData === "timestamp") return previewTimestampComp;
                                            if (modelData === "closeBtn") return previewCloseComp;
                                            return null;
                                        }
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

                                    sourceComponent: {
                                        if (modelData === "title" && !simZoneCol.hasPairedTitleBodyAndImage) return previewTitleComp;
                                        if (modelData === "body") return simZoneCol.hasPairedBodyAndImage ? previewPairedBodyImgComp : previewSoloBodyComp;
                                        if (modelData === "image" && !simZoneCol.hasPairedBodyAndImage) return previewStandaloneImgComp;
                                        if (modelData === "buttons") return previewButtonsComp;
                                        if (modelData === "progressBar") return previewProgressComp;
                                        return null;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // PREVIEW BUILDING BLOCK COMPONENTS (CLICK TO INSPECT)
            // =================================================================
            Component {
                id: previewInlineIconComp
                Rectangle {
                    width: NotificationService.iconSize
                    height: NotificationService.iconSize
                    implicitWidth: width
                    implicitHeight: height
                    radius: NotificationService.iconRadius
                    color: NotificationService.iconShowBg ? Qt.alpha(simCard.urgencyCol, 0.16) : "transparent"
                    border.color: root.selectedInspectorBlock === "icon" ? root.theme.accentPrimary : "transparent"
                    border.width: root.selectedInspectorBlock === "icon" ? 1.5 : 0

                    Text {
                        anchors.centerIn: parent
                        text: NotificationService.composerIcon || "󰂚"
                        color: simCard.urgencyCol
                        font.pixelSize: Math.round(parent.width * 0.58)
                        font.family: root.font
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "icon"
                    }
                }
            }

            Component {
                id: previewAppNameComp
                Rectangle {
                    implicitHeight: appNameTxt.implicitHeight + 4
                    height: implicitHeight
                    radius: 4
                    color: root.selectedInspectorBlock === "appName" ? root.withAlpha(root.theme.accentPrimary, 0.12) : "transparent"

                    Text {
                        id: appNameTxt
                        anchors.verticalCenter: parent.verticalCenter
                        text: NotificationService.composerAppName || "notify-send"
                        color: root.theme.textMuted
                        font.pixelSize: NotificationService.appNameFontSize
                        font.family: root.font
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "appName"
                    }
                }
            }

            Component {
                id: previewTimestampComp
                Rectangle {
                    implicitWidth: tsTxt.implicitWidth + 8
                    implicitHeight: tsTxt.implicitHeight + 4
                    radius: 4
                    color: root.selectedInspectorBlock === "timestamp" ? root.withAlpha(root.theme.accentPrimary, 0.15) : "transparent"

                    Text {
                        id: tsTxt
                        anchors.centerIn: parent
                        text: NotificationService.timestampFormat === "time" ? Qt.formatTime(new Date(), "hh:mm") : "Now"
                        color: root.theme.textMuted
                        font.pixelSize: Math.max(9, NotificationService.appNameFontSize - 1)
                        font.family: root.font
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "timestamp"
                    }
                }
            }

            Component {
                id: previewCloseComp
                Rectangle {
                    width: 20
                    height: 20
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: root.selectedInspectorBlock === "closeBtn"
                        ? root.withAlpha(root.theme.accentPrimary, 0.18)
                        : (simCloseHover.containsMouse ? root.theme.bgBorder : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: simCloseHover.containsMouse ? root.theme.accentRed : root.theme.textMuted
                        font.pixelSize: 12
                        font.family: root.font
                    }

                    MouseArea {
                        id: simCloseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "closeBtn"
                    }
                }
            }

            Component {
                id: previewTitleComp
                Rectangle {
                    implicitHeight: simTitleTxt.implicitHeight + 4
                    height: implicitHeight
                    radius: 4
                    color: root.selectedInspectorBlock === "title" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                    visible: simTitleTxt.text !== ""

                    Text {
                        id: simTitleTxt
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        text: NotificationService.composerTitle
                        color: root.theme.textPrimary
                        font.pixelSize: NotificationService.titleFontSize
                        font.family: root.font
                        font.bold: NotificationService.titleBold
                        maximumLineCount: NotificationService.titleMaxLines
                        wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
                        elide: Text.ElideRight
                        horizontalAlignment: NotificationService.titleAlignment === "center"
                            ? Text.AlignHCenter
                            : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "title"
                    }
                }
            }

            Component {
                id: previewSoloBodyComp
                Rectangle {
                    implicitHeight: simSoloBodyTxt.implicitHeight + 4
                    height: implicitHeight
                    radius: 4
                    color: root.selectedInspectorBlock === "body" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                    visible: simSoloBodyTxt.text !== ""

                    Text {
                        id: simSoloBodyTxt
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        text: NotificationService.composerBody
                        color: root.theme.textSecondary
                        font.pixelSize: NotificationService.bodyFontSize
                        font.family: root.font
                        wrapMode: Text.Wrap
                        maximumLineCount: NotificationService.bodyMaxLines
                        elide: Text.ElideRight
                        horizontalAlignment: NotificationService.bodyAlignment === "center"
                            ? Text.AlignHCenter
                            : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "body"
                    }
                }
            }

            Component {
                id: previewPairedBodyImgComp
                RowLayout {
                    spacing: 10
                    visible: NotificationService.composerBody !== "" || NotificationService.composerTitle !== "" || NotificationService.composerShowImage
                    layoutDirection: NotificationService.imagePosition === "left" ? Qt.RightToLeft : Qt.LeftToRight

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 3

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: simPairedTitleTxt.implicitHeight + 2
                            height: implicitHeight
                            radius: 4
                            color: root.selectedInspectorBlock === "title" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                            visible: NotificationService.isBlockVisible("title") && NotificationService.composerTitle !== ""

                            Text {
                                id: simPairedTitleTxt
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
                                text: NotificationService.composerTitle
                                color: root.theme.textPrimary
                                font.pixelSize: NotificationService.titleFontSize
                                font.family: root.font
                                font.bold: NotificationService.titleBold
                                maximumLineCount: NotificationService.titleMaxLines
                                wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
                                elide: Text.ElideRight
                                horizontalAlignment: NotificationService.titleAlignment === "center"
                                    ? Text.AlignHCenter
                                    : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedInspectorBlock = "title"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: simBodyTxt.implicitHeight + 2
                            height: implicitHeight
                            radius: 4
                            color: root.selectedInspectorBlock === "body" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                            visible: NotificationService.isBlockVisible("body") && NotificationService.composerBody !== ""

                            Text {
                                id: simBodyTxt
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
                                text: NotificationService.composerBody
                                color: root.theme.textSecondary
                                font.pixelSize: NotificationService.bodyFontSize
                                font.family: root.font
                                wrapMode: Text.Wrap
                                maximumLineCount: NotificationService.bodyMaxLines
                                elide: Text.ElideRight
                                horizontalAlignment: NotificationService.bodyAlignment === "center"
                                    ? Text.AlignHCenter
                                    : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedInspectorBlock = "body"
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: NotificationService.imageSize
                        Layout.preferredHeight: NotificationService.imageSize
                        Layout.alignment: Qt.AlignTop
                        radius: NotificationService.imageRadius
                        color: Qt.alpha(simCard.urgencyCol, 0.15)
                        border.color: root.selectedInspectorBlock === "image"
                            ? root.theme.accentPrimary
                            : Qt.alpha(simCard.urgencyCol, 0.35)
                        border.width: root.selectedInspectorBlock === "image" ? 1.5 : 1
                        clip: true
                        visible: NotificationService.composerShowImage

                        Text {
                            anchors.centerIn: parent
                            text: "󰋩"
                            font.family: root.font
                            font.pixelSize: Math.round(NotificationService.imageSize * 0.45)
                            color: simCard.urgencyCol
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedInspectorBlock = "image"
                        }
                    }
                }
            }

            Component {
                id: previewStandaloneImgComp
                Rectangle {
                    readonly property bool isBanner: NotificationService.imagePosition === "banner"
                    implicitHeight: isBanner ? Math.max(56, NotificationService.imageSize) : NotificationService.imageSize
                    height: implicitHeight
                    radius: NotificationService.imageRadius
                    color: Qt.alpha(simCard.urgencyCol, 0.15)
                    border.color: root.selectedInspectorBlock === "image"
                        ? root.theme.accentPrimary
                        : Qt.alpha(simCard.urgencyCol, 0.35)
                    border.width: root.selectedInspectorBlock === "image" ? 1.5 : 1
                    clip: true
                    visible: NotificationService.composerShowImage

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰋩"
                            font.family: root.font
                            font.pixelSize: 16
                            color: simCard.urgencyCol
                        }
                        Text {
                            visible: parent.parent.isBanner
                            text: "Preview Thumbnail Banner"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "image"
                    }
                }
            }

            Component {
                id: previewButtonsComp
                RowLayout {
                    spacing: 6
                    visible: NotificationService.composerButtons && NotificationService.composerButtons.length > 0

                    Item {
                        visible: NotificationService.buttonStyle !== "fill"
                            && (NotificationService.buttonAlignment === "center" || NotificationService.buttonAlignment === "right")
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: NotificationService.composerButtons

                        Rectangle {
                            id: simActBtn
                            required property var modelData
                            readonly property bool isReply: String(modelData.label || "").toLowerCase() === "reply"
                            readonly property bool isFill: NotificationService.buttonStyle === "fill" || NotificationService.buttonAlignment === "stretch"
                            readonly property bool isGhost: NotificationService.buttonStyle === "ghost"

                            Layout.preferredHeight: NotificationService.buttonHeight
                            Layout.preferredWidth: isFill ? 1 : (simActContent.implicitWidth + 24)
                            Layout.fillWidth: isFill
                            radius: NotificationService.buttonRadius
                            color: isReply
                                ? root.theme.accentPrimary
                                : (isGhost
                                    ? (simActHover.containsMouse ? Qt.alpha(root.theme.accentPrimary, 0.16) : "transparent")
                                    : (simActHover.containsMouse ? Qt.alpha(root.theme.accentPrimary, 0.28) : Qt.alpha(root.theme.accentPrimary, 0.12)))
                            border.width: root.selectedInspectorBlock === "buttons" ? 1.5 : (isGhost ? 0 : 1)
                            border.color: root.selectedInspectorBlock === "buttons"
                                ? root.theme.accentPrimary
                                : Qt.alpha(root.theme.accentPrimary, 0.28)

                            RowLayout {
                                id: simActContent
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    visible: simActBtn.isReply
                                    text: "󰈎"
                                    color: root.theme.bgBase
                                    font.pixelSize: 11
                                    font.family: root.font
                                }

                                Text {
                                    text: simActBtn.modelData.label || "Action"
                                    color: simActBtn.isReply ? root.theme.bgBase : root.theme.accentPrimary
                                    font.pixelSize: 11
                                    font.bold: simActBtn.isReply || simActBtn.isFill
                                    font.family: root.font
                                }
                            }

                            MouseArea {
                                id: simActHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedInspectorBlock = "buttons"
                            }
                        }
                    }

                    Item {
                        visible: NotificationService.buttonStyle !== "fill"
                            && (NotificationService.buttonAlignment === "left" || NotificationService.buttonAlignment === "center")
                        Layout.fillWidth: true
                    }
                }
            }

            Component {
                id: previewProgressComp
                Rectangle {
                    implicitHeight: NotificationService.progressHeight
                    height: NotificationService.progressHeight
                    radius: NotificationService.progressHeight / 2
                    color: Qt.alpha(root.theme.bgSurface, 0.7)
                    visible: NotificationService.composerUrgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical

                    Rectangle {
                        height: parent.height
                        width: parent.width * 0.68
                        radius: parent.radius
                        color: simCard.urgencyCol
                        opacity: 0.85
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = "progressBar"
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. INTERACTIVE CUSTOM NOTIFICATION COMPOSER (ICON, TITLE, BODY, BUTTONS)
    // =========================================================================
    Rectangle {
        visible: previewSection.composerExpanded
        Layout.fillWidth: true
        implicitHeight: composerCol.implicitHeight + 24
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: composerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰏫  Custom Notification Payload Builder"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "·  Compose custom icon, title, body message, thumbnail, and action buttons"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Row A: Icon Selector Chips + Custom Glyph Input
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Icon"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 95
                }

                RowLayout {
                    spacing: 5
                    Repeater {
                        model: ["󰂚", "󰄄", "󰖣", "󰓇", "󰞷", "󰀦", "󰊫", "󰇚"]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool isChosen: NotificationService.composerIcon === modelData
                            width: 28
                            height: 28
                            radius: 6
                            color: isChosen ? root.theme.bgSelected : (glyphHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                            border.color: isChosen ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            HoverHandler { id: glyphHover }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.font
                                font.pixelSize: 13
                                color: isChosen ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NotificationService.composerPreset = "custom";
                                    NotificationService.composerIcon = modelData;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 64
                    height: 28
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        text: NotificationService.composerIcon
                        selectByMouse: true
                        onTextEdited: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.composerIcon = text;
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Urgency Segmented Switch
                Text {
                    text: "Urgency:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Rectangle {
                    width: 170
                    height: 28
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 2

                        Repeater {
                            model: [
                                { label: "Low",      val: NotificationUrgency.Low },
                                { label: "Normal",   val: NotificationUrgency.Normal },
                                { label: "Critical", val: NotificationUrgency.Critical }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isUrg: NotificationService.composerUrgency === modelData.val
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: isUrg ? root.theme.bgSelected : "transparent"
                                border.color: isUrg ? root.theme.accentPrimary : "transparent"
                                border.width: isUrg ? 1 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: isUrg
                                    color: isUrg ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.composerPreset = "custom";
                                        NotificationService.composerUrgency = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Row B: App Name & Title Notification
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "App & Title"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 95
                }

                Rectangle {
                    Layout.preferredWidth: 150
                    height: 30
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: appNameInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        id: appNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        text: NotificationService.composerAppName
                        selectByMouse: true
                        clip: true
                        onTextEdited: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.composerAppName = text;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: titleInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        id: titleInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                        text: NotificationService.composerTitle
                        selectByMouse: true
                        clip: true
                        onTextEdited: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.composerTitle = text;
                        }
                    }
                }
            }

            // Row C: Body Message & Thumbnail Toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Body Message"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 95
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: bodyInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        id: bodyInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        text: NotificationService.composerBody
                        selectByMouse: true
                        clip: true
                        onTextEdited: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.composerBody = text;
                        }
                    }
                }

                Rectangle {
                    implicitWidth: imgToggleRow.implicitWidth + 16
                    height: 30
                    radius: 6
                    color: NotificationService.composerShowImage ? root.theme.bgSelected : root.theme.bgSurface
                    border.color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    RowLayout {
                        id: imgToggleRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰋩"
                            font.family: root.font
                            font.pixelSize: 12
                            color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.textMuted
                        }

                        Text {
                            text: NotificationService.composerShowImage ? "Thumbnail: ON" : "Thumbnail: OFF"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: NotificationService.composerShowImage
                            color: NotificationService.composerShowImage ? root.theme.accentPrimary : root.theme.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.composerPreset = "custom";
                            NotificationService.composerShowImage = !NotificationService.composerShowImage;
                        }
                    }
                }
            }

            // Row D: Action Buttons Builder
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Action Buttons"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 95
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: NotificationService.composerButtons
                        delegate: Rectangle {
                            id: btnChip
                            required property var modelData
                            required property int index

                            width: 124
                            height: 28
                            radius: 6
                            color: root.theme.bgSurface
                            border.color: btnLblInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 4

                                TextInput {
                                    id: btnLblInput
                                    Layout.fillWidth: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                    text: btnChip.modelData.label || ""
                                    selectByMouse: true
                                    clip: true
                                    onTextEdited: {
                                        NotificationService.composerPreset = "custom";
                                        NotificationService.updateComposerButton(btnChip.index, text, btnChip.modelData.cmd);
                                    }
                                }

                                MiniIconButton {
                                    iconText: "󰅖"
                                    dangerHover: true
                                    onClicked: {
                                        NotificationService.composerPreset = "custom";
                                        NotificationService.removeComposerButton(btnChip.index);
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (NotificationService.composerButtons || []).length < 4
                        implicitWidth: addBtnChipRow.implicitWidth + 16
                        height: 28
                        radius: 6
                        color: addBtnChipHover.hovered ? root.theme.bgHover : root.theme.bgSurface
                        border.color: addBtnChipHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1

                        HoverHandler { id: addBtnChipHover }

                        RowLayout {
                            id: addBtnChipRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰐕"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.accentPrimary
                            }

                            Text {
                                text: "Add Button"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.textPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.composerPreset = "custom";
                                NotificationService.addComposerButton("Action", "");
                            }
                        }
                    }
                }
            }
        }
    }
}
