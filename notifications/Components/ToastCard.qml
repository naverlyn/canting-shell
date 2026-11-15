import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: notifCard
    required property var modelData
    required property int index
    required property var theme
    required property string font
    required property bool isLeft
    required property bool isRight
    required property bool isCenter
    required property bool isBottom

    readonly property color urgencyColor: {
        if (modelData.urgency === NotificationUrgency.Critical) return notifCard.theme.urgencyCritical;
        if (modelData.urgency === NotificationUrgency.Low) return notifCard.theme.urgencyLow;
        return notifCard.theme.urgencyNormal;
    }

    readonly property string stripPos: NotificationService.showAccentStrip ? NotificationService.accentStripPosition : "none"
    readonly property int pad: NotificationService.cardPadding
    readonly property bool hasImg: modelData.image !== "" && !modelData.image.startsWith("image://qsimage/")
    readonly property bool isSampleImg: modelData.image === "__sample__" || (modelData.body && modelData.body.indexOf("Swappy") !== -1 && modelData.image !== "")

    function resolveGlyph() {
        if (notifCard.modelData.customGlyph && notifCard.modelData.customGlyph !== "") {
            return notifCard.modelData.customGlyph;
        }
        if (notifCard.modelData.socialApp) return notifCard.modelData.socialApp.icon;
        if (notifCard.modelData.isWhatsApp) return "󰖣";
        const name = (notifCard.modelData.appName || "").toLowerCase();
        if (notifCard.modelData.urgency === NotificationUrgency.Critical) return "󰀦";
        if (name.includes("discord"))  return "󰙯";
        if (name.includes("firefox"))  return "󰈹";
        if (name.includes("chrome") || name.includes("brave")) return "󰈹";
        if (name.includes("telegram")) return "󰈎";
        if (name.includes("spotify"))  return "󰓇";
        if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "󰞷";
        return "󰂚";
    }

    Layout.fillWidth: true
    Layout.preferredHeight: cardOuterRow.implicitHeight + (pad * 2)
    radius: NotificationService.cardRadius
    opacity: NotificationService.cardOpacity
    color: cardHover.hovered ? Qt.lighter(notifCard.theme.bgBase, 1.12) : notifCard.theme.bgBase
    border.color: modelData.urgency === NotificationUrgency.Critical ? notifCard.theme.urgencyCritical :
                  modelData.urgency === NotificationUrgency.Low     ? Qt.alpha(notifCard.theme.urgencyLow, 0.5)
                                                                     : Qt.alpha(notifCard.theme.bgBorder, 0.9)
    border.width: 1
    clip: true

    Behavior on color { ColorAnimation { duration: 150 } }

    Accessible.role: Accessible.StaticText
    Accessible.name: (modelData.urgency === NotificationUrgency.Critical ? "[Critical] " :
                     modelData.urgency === NotificationUrgency.Low       ? "[Low] "      : "") +
                     (modelData.displayAppName || modelData.appName || "Notification") + ": " + modelData.summary

    HoverHandler {
        id: cardHover
        onHoveredChanged: notifCard.modelData.hovered = hovered
    }

    transform: Translate {
        id: slide
        x: notifCard.isLeft ? -30 : (notifCard.isRight ? 30 : 0)
        y: notifCard.isCenter ? (notifCard.isBottom ? 24 : -24) : 0
    }

    ParallelAnimation {
        id: entryAnim
        NumberAnimation {
            target: notifCard; property: "opacity"
            from: 0; to: NotificationService.cardOpacity
            duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide; property: "x"
            from: notifCard.isLeft ? -30 : (notifCard.isRight ? 30 : 0)
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide; property: "y"
            from: notifCard.isCenter ? (notifCard.isBottom ? 24 : -24) : 0
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    Component.onCompleted: entryAnim.start()

    ParallelAnimation {
        id: swipeSnapBackAnim
        NumberAnimation {
            target: slide; property: "x"
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: notifCard; property: "opacity"
            to: NotificationService.cardOpacity
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: swipeDismissAnim
        property real targetX: notifCard.width + 40
        NumberAnimation {
            target: slide; property: "x"
            to: swipeDismissAnim.targetX
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: notifCard; property: "opacity"
            to: 0
            duration: 160
            easing.type: Easing.OutCubic
        }
        onFinished: notifCard.modelData.dismiss()
    }

    function dismissAnimated() {
        if (cardClickArea.dismissing) return;
        cardClickArea.dismissing = true;
        swipeSnapBackAnim.stop();
        swipeDismissAnim.targetX = notifCard.isLeft ? -(notifCard.width + 40) : (notifCard.width + 40);
        swipeDismissAnim.start();
    }

    MouseArea {
        id: cardClickArea
        anchors.fill: parent
        cursorShape: isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        property real pressGlobalX: 0
        property bool isDragging: false
        property bool dismissing: false

        onPressed: (mouse) => {
            if (dismissing) return;
            swipeSnapBackAnim.stop();
            pressGlobalX = cardClickArea.mapToItem(notifCard.parent, mouse.x, mouse.y).x;
            isDragging = false;
        }

        onPositionChanged: (mouse) => {
            if (!pressed || dismissing) return;
            const curX = cardClickArea.mapToItem(notifCard.parent, mouse.x, mouse.y).x;
            const dx = curX - pressGlobalX;
            if (!isDragging && dx > 8) {
                isDragging = true;
            }
            if (isDragging) {
                const clamped = Math.max(0, dx);
                slide.x = clamped;
                notifCard.opacity = NotificationService.cardOpacity * Math.max(0.15, 1.0 - (clamped / (notifCard.width * 0.85)));
            }
        }

        onReleased: (mouse) => {
            if (dismissing) return;
            if (!isDragging) {
                notifCard.modelData.activate();
                return;
            }
            isDragging = false;
            if (slide.x >= Math.min(110, notifCard.width * 0.32)) {
                dismissing = true;
                swipeDismissAnim.targetX = notifCard.width + 40;
                swipeDismissAnim.start();
            } else {
                swipeSnapBackAnim.start();
            }
        }

        onCanceled: {
            if (isDragging && !dismissing) {
                isDragging = false;
                swipeSnapBackAnim.start();
            }
        }
    }

    // Accent / Urgency Strip (Left, Right, or Top)
    Rectangle {
        visible: notifCard.stripPos !== "none"
        width: (notifCard.stripPos === "left" || notifCard.stripPos === "right")
            ? NotificationService.accentStripWidth
            : (parent.width - 20)
        height: (notifCard.stripPos === "top")
            ? NotificationService.accentStripWidth
            : (parent.height - 16)
        radius: NotificationService.accentStripWidth / 2
        x: notifCard.stripPos === "left"
            ? 6
            : (notifCard.stripPos === "right" ? parent.width - width - 6 : 10)
        y: notifCard.stripPos === "top"
            ? 5
            : Math.round((parent.height - height) / 2)
        color: notifCard.urgencyColor
    }

    RowLayout {
        id: cardOuterRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: notifCard.pad + (notifCard.stripPos === "left" ? NotificationService.accentStripWidth + 4 : 0)
            rightMargin: notifCard.pad + (notifCard.stripPos === "right" ? NotificationService.accentStripWidth + 4 : 0)
            topMargin: notifCard.pad + (notifCard.stripPos === "top" ? NotificationService.accentStripWidth + 2 : 0)
        }
        spacing: 10

        // Left Avatar Icon Column (when Icon Mode is Avatar or Icon is in Content Zone)
        Rectangle {
            visible: NotificationService.isAvatarIconEffective
            Layout.preferredWidth: Math.max(32, NotificationService.iconSize)
            Layout.preferredHeight: Math.max(32, NotificationService.iconSize)
            Layout.alignment: Qt.AlignTop
            radius: NotificationService.iconRadius
            color: NotificationService.iconShowBg
                ? (notifCard.modelData.socialApp
                    ? Qt.alpha(notifCard.modelData.socialApp.color, 0.15)
                    : (notifCard.modelData.isWhatsApp
                        ? Qt.alpha("#25D366", 0.15)
                        : Qt.alpha(notifCard.urgencyColor, 0.15)))
                : "transparent"

            IconImage {
                anchors.centerIn: parent
                source: Quickshell.iconPath(notifCard.modelData.appIcon, true)
                implicitSize: Math.round(parent.width * 0.65)
                visible: notifCard.modelData.appIcon !== "" && !notifCard.modelData.isSocialApp && !notifCard.modelData.isWhatsApp && notifCard.modelData.customGlyph === ""
            }

            Text {
                anchors.centerIn: parent
                visible: notifCard.modelData.appIcon === "" || notifCard.modelData.isSocialApp || notifCard.modelData.isWhatsApp || notifCard.modelData.customGlyph !== ""
                text: notifCard.resolveGlyph()
                color: notifCard.modelData.socialApp ? notifCard.modelData.socialApp.color : (notifCard.modelData.isWhatsApp ? "#25D366" : notifCard.urgencyColor)
                font.pixelSize: Math.round(parent.width * 0.56)
                font.family: notifCard.font
            }
        }

        // Main 3-Zone Modular Stack (Header Zone -> Content Zone -> Footer Zone)
        ColumnLayout {
            id: cardContent
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { zoneIdx: 0, blocks: NotificationService.headerBlocks },
                    { zoneIdx: 1, blocks: NotificationService.contentBlocks },
                    { zoneIdx: 2, blocks: NotificationService.footerBlocks }
                ]

                delegate: ColumnLayout {
                    id: zoneContainer
                    required property var modelData
                    readonly property var zoneBlocks: modelData.blocks || []
                    readonly property bool hasInlineHeaderItems: {
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

                    // 1. Inline Header Row for header-type blocks in this zone
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: zoneContainer.hasInlineHeaderItems

                        Repeater {
                            model: zoneContainer.zoneBlocks
                            delegate: Loader {
                                id: inlineBlockLoader
                                required property string modelData
                                required property int index
                                readonly property bool isInlineBlock: modelData === "appName" || modelData === "timestamp" || modelData === "closeBtn" || (modelData === "icon" && !NotificationService.isAvatarIconEffective)
                                visible: isInlineBlock
                                Layout.fillWidth: modelData === "appName"
                                Layout.alignment: Qt.AlignVCenter

                                Binding {
                                    target: inlineBlockLoader.item
                                    property: "width"
                                    value: inlineBlockLoader.width
                                    when: inlineBlockLoader.item !== null && inlineBlockLoader.modelData === "appName"
                                }

                                sourceComponent: {
                                    if (modelData === "icon" && !NotificationService.isAvatarIconEffective) return inlineIconComp;
                                    if (modelData === "appName") return inlineAppNameComp;
                                    if (modelData === "timestamp") return inlineTimestampComp;
                                    if (modelData === "closeBtn") return inlineCloseComp;
                                    return null;
                                }
                            }
                        }
                    }

                    // 2. Vertical Stack for content/footer blocks in this zone (respecting exact user order)
                    Repeater {
                        model: zoneContainer.zoneBlocks
                        delegate: Loader {
                            id: stackBlockLoader
                            required property string modelData
                            required property int index
                            readonly property bool isStackBlock: {
                                if (modelData === "title") {
                                    if (zoneContainer.hasPairedTitleBodyAndImage) return false;
                                    return notifCard.modelData.summary !== "";
                                }
                                if (modelData === "body") {
                                    const bTxt = notifCard.modelData.displayBody || notifCard.modelData.body;
                                    return bTxt !== ""
                                        || (zoneContainer.hasPairedTitleBodyAndImage && notifCard.modelData.summary !== "")
                                        || (zoneContainer.hasPairedBodyAndImage && (notifCard.hasImg || notifCard.isSampleImg));
                                }
                                if (modelData === "image") {
                                    return !zoneContainer.hasPairedBodyAndImage && (notifCard.hasImg || notifCard.isSampleImg);
                                }
                                if (modelData === "buttons") {
                                    return notifCard.modelData.actions && notifCard.modelData.actions.length > 0;
                                }
                                if (modelData === "progressBar") {
                                    return notifCard.modelData.urgency !== NotificationUrgency.Critical
                                        || NotificationService.progressShowCritical;
                                }
                                return false;
                            }

                            visible: isStackBlock
                            Layout.fillWidth: true
                            Layout.preferredHeight: item ? item.implicitHeight : 0

                            Binding {
                                target: stackBlockLoader.item
                                property: "width"
                                value: stackBlockLoader.width
                                when: stackBlockLoader.item !== null
                            }

                            sourceComponent: {
                                if (modelData === "title" && !zoneContainer.hasPairedTitleBodyAndImage) return titleBlockComp;
                                if (modelData === "body") return zoneContainer.hasPairedBodyAndImage ? pairedBodyImageComp : soloBodyComp;
                                if (modelData === "image" && !zoneContainer.hasPairedBodyAndImage) return standaloneImageComp;
                                if (modelData === "buttons") return buttonsBlockComp;
                                if (modelData === "progressBar") return progressBlockComp;
                                return null;
                            }
                        }
                    }
                }
            }
        }
    }

    // MODULAR BUILDING BLOCK COMPONENTS
    Component {
        id: inlineIconComp
        Rectangle {
            width: NotificationService.iconSize
            height: NotificationService.iconSize
            implicitWidth: width
            implicitHeight: height
            radius: NotificationService.iconRadius
            color: NotificationService.iconShowBg
                ? (notifCard.modelData.socialApp
                    ? Qt.alpha(notifCard.modelData.socialApp.color, 0.15)
                    : (notifCard.modelData.isWhatsApp
                        ? Qt.alpha("#25D366", 0.15)
                        : Qt.alpha(notifCard.urgencyColor, 0.15)))
                : "transparent"

            IconImage {
                anchors.centerIn: parent
                source: Quickshell.iconPath(notifCard.modelData.appIcon, true)
                implicitSize: Math.round(parent.width * 0.66)
                visible: notifCard.modelData.appIcon !== "" && !notifCard.modelData.isSocialApp && !notifCard.modelData.isWhatsApp && notifCard.modelData.customGlyph === ""
            }

            Text {
                anchors.centerIn: parent
                visible: notifCard.modelData.appIcon === "" || notifCard.modelData.isSocialApp || notifCard.modelData.isWhatsApp || notifCard.modelData.customGlyph !== ""
                text: notifCard.resolveGlyph()
                color: notifCard.modelData.socialApp ? notifCard.modelData.socialApp.color : (notifCard.modelData.isWhatsApp ? "#25D366" : notifCard.urgencyColor)
                font.pixelSize: Math.round(parent.width * 0.58)
                font.family: notifCard.font
            }
        }
    }

    Component {
        id: inlineAppNameComp
        Text {
            text: notifCard.modelData.displayAppName || notifCard.modelData.appName || "Notification"
            color: notifCard.theme.textMuted
            font.pixelSize: NotificationService.appNameFontSize
            font.family: notifCard.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    Component {
        id: inlineTimestampComp
        Text {
            text: notifCard.modelData.timeLabel || "Now"
            color: notifCard.theme.textMuted
            font.pixelSize: Math.max(9, NotificationService.appNameFontSize - 1)
            font.family: notifCard.font
            opacity: 0.8
            verticalAlignment: Text.AlignVCenter
        }
    }

    Component {
        id: inlineCloseComp
        Rectangle {
            width: 20
            height: 20
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: closeHover.containsMouse ? notifCard.theme.bgBorder : "transparent"
            Accessible.role: Accessible.Button
            Accessible.name: "Dismiss notification"

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: closeHover.containsMouse ? notifCard.theme.accentRed : notifCard.theme.textMuted
                font.pixelSize: 12
                font.family: notifCard.font
            }

            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: notifCard.dismissAnimated()
            }
        }
    }

    Component {
        id: titleBlockComp
        Text {
            text: notifCard.modelData.summary
            color: notifCard.theme.textPrimary
            font.pixelSize: NotificationService.titleFontSize
            font.family: notifCard.font
            font.bold: NotificationService.titleBold
            maximumLineCount: NotificationService.titleMaxLines
            wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
            elide: Text.ElideRight
            horizontalAlignment: NotificationService.titleAlignment === "center"
                ? Text.AlignHCenter
                : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
            visible: text !== ""
        }
    }

    Component {
        id: soloBodyComp
        Text {
            text: notifCard.modelData.displayBody || notifCard.modelData.body
            color: notifCard.theme.textSecondary
            font.pixelSize: NotificationService.bodyFontSize
            font.family: notifCard.font
            wrapMode: Text.Wrap
            maximumLineCount: NotificationService.bodyMaxLines
            elide: Text.ElideRight
            horizontalAlignment: NotificationService.bodyAlignment === "center"
                ? Text.AlignHCenter
                : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
            visible: text !== ""
            textFormat: Text.PlainText
        }
    }

    Component {
        id: pairedBodyImageComp
        RowLayout {
            readonly property string bodyTxt: notifCard.modelData.displayBody || notifCard.modelData.body
            readonly property bool showThumb: notifCard.hasImg || notifCard.isSampleImg
            spacing: 10
            visible: bodyTxt !== "" || notifCard.modelData.summary !== "" || showThumb
            layoutDirection: NotificationService.imagePosition === "left" ? Qt.RightToLeft : Qt.LeftToRight

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 3

                Text {
                    text: notifCard.modelData.summary
                    color: notifCard.theme.textPrimary
                    font.pixelSize: NotificationService.titleFontSize
                    font.family: notifCard.font
                    font.bold: NotificationService.titleBold
                    maximumLineCount: NotificationService.titleMaxLines
                    wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
                    elide: Text.ElideRight
                    horizontalAlignment: NotificationService.titleAlignment === "center"
                        ? Text.AlignHCenter
                        : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                    Layout.fillWidth: true
                    visible: NotificationService.isBlockVisible("title") && text !== ""
                }

                Text {
                    text: parent.parent.bodyTxt
                    color: notifCard.theme.textSecondary
                    font.pixelSize: NotificationService.bodyFontSize
                    font.family: notifCard.font
                    wrapMode: Text.Wrap
                    maximumLineCount: NotificationService.bodyMaxLines
                    elide: Text.ElideRight
                    horizontalAlignment: NotificationService.bodyAlignment === "center"
                        ? Text.AlignHCenter
                        : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                    Layout.fillWidth: true
                    visible: NotificationService.isBlockVisible("body") && text !== ""
                    textFormat: Text.PlainText
                }
            }

            ToastImageBox {
                Layout.preferredWidth: NotificationService.imageSize
                Layout.preferredHeight: NotificationService.imageSize
                Layout.alignment: Qt.AlignTop
                visible: parent.showThumb
                imageSource: notifCard.hasImg && !notifCard.isSampleImg ? notifCard.modelData.image : ""
                urgencyColor: notifCard.urgencyColor
                secondaryTextColor: notifCard.theme.textSecondary
                font: notifCard.font
            }
        }
    }

    Component {
        id: standaloneImageComp
        ToastImageBox {
            readonly property bool showThumb: notifCard.hasImg || notifCard.isSampleImg
            isBanner: NotificationService.imagePosition === "banner"
            implicitHeight: isBanner ? Math.max(56, NotificationService.imageSize) : NotificationService.imageSize
            height: implicitHeight
            visible: showThumb
            imageSource: notifCard.hasImg && !notifCard.isSampleImg ? notifCard.modelData.image : ""
            urgencyColor: notifCard.urgencyColor
            secondaryTextColor: notifCard.theme.textSecondary
            font: notifCard.font
            sourceWidth: 360
            sourceHeight: 180
        }
    }

    Component {
        id: buttonsBlockComp
        RowLayout {
            spacing: 6
            visible: notifCard.modelData.actions && notifCard.modelData.actions.length > 0

            Item {
                visible: NotificationService.buttonStyle !== "fill"
                    && (NotificationService.buttonAlignment === "center" || NotificationService.buttonAlignment === "right")
                Layout.fillWidth: true
            }

            Repeater {
                model: notifCard.modelData.actions

                Rectangle {
                    id: actionBtn
                    required property var modelData

                    readonly property bool isReply: actionBtn.modelData && (actionBtn.modelData.identifier === "reply" || actionBtn.modelData.isReply)
                    readonly property bool isFillStyle: NotificationService.buttonStyle === "fill" || NotificationService.buttonAlignment === "stretch"
                    readonly property bool isGhostStyle: NotificationService.buttonStyle === "ghost"

                    visible: actionBtn.modelData && actionBtn.modelData.text && actionBtn.modelData.text.length > 0
                    Layout.preferredHeight: NotificationService.buttonHeight
                    Layout.preferredWidth: isFillStyle ? 1 : (actionContent.implicitWidth + 24)
                    Layout.fillWidth: isFillStyle
                    radius: NotificationService.buttonRadius
                    color: isReply
                           ? (actionHover.containsMouse ? Qt.lighter(notifCard.theme.accentPrimary, 1.15) : notifCard.theme.accentPrimary)
                           : (isGhostStyle
                               ? (actionHover.containsMouse ? Qt.alpha(notifCard.theme.accentPrimary, 0.16) : "transparent")
                               : (actionHover.containsMouse ? Qt.alpha(notifCard.theme.accentPrimary, 0.28) : Qt.alpha(notifCard.theme.accentPrimary, 0.12)))
                    border.width: isGhostStyle ? (actionHover.containsMouse ? 1 : 0) : 1
                    border.color: isReply
                                  ? (actionHover.containsMouse ? Qt.lighter(notifCard.theme.accentPrimary, 1.25) : notifCard.theme.accentPrimary)
                                  : Qt.alpha(notifCard.theme.accentPrimary, actionHover.containsMouse ? 0.5 : 0.2)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Accessible.role: Accessible.Button
                    Accessible.name: actionBtn.modelData.text || ""

                    RowLayout {
                        id: actionContent
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            id: actionText
                            text: actionBtn.modelData.text || ""
                            color: actionBtn.isReply ? notifCard.theme.bgBase : notifCard.theme.accentPrimary
                            font.pixelSize: 11
                            font.bold: actionBtn.isReply || actionBtn.isFillStyle
                            font.family: notifCard.font
                        }
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifCard.modelData.invokeAction(actionBtn.modelData.identifier)
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
        id: progressBlockComp
        Rectangle {
            implicitHeight: NotificationService.progressHeight
            height: NotificationService.progressHeight
            radius: NotificationService.progressHeight / 2
            color: Qt.alpha(notifCard.theme.bgSurface, 0.7)
            visible: notifCard.modelData.urgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical

            Rectangle {
                id: progressBar
                height: parent.height
                width: parent.width
                radius: parent.radius
                color: notifCard.urgencyColor
                opacity: 0.85

                SequentialAnimation {
                    running: (notifCard.modelData.urgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical)
                             && !(NotificationService.pauseOnHover && notifCard.modelData.hovered)
                    PauseAnimation { duration: 50 }
                    NumberAnimation {
                        target: progressBar
                        property: "width"
                        to: 0
                        duration: notifCard.modelData.expireTimeout > 0
                                  ? notifCard.modelData.expireTimeout
                                  : notifCard.modelData.defaultTimeout
                    }
                }
            }
        }
    }
}
