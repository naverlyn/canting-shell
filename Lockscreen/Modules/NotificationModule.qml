import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/SocialApps.js" as SocialApps
import "../../notifications/NotificationPresentation.js" as NotificationPresentation
import ".."
import "../../utils/ColorUtils.js" as ColorUtils
import "../../ThemeSwitcher"

Item {
    id: root

    property var theme: Theme
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0
    property var expandedApps: ({})

    readonly property bool isStageEditor: root.scaleFactor < 0.98
    readonly property bool isCompact: Boolean(moduleData && moduleData.displayMode === "compact")
    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined) ? Boolean(moduleData.showCard) : true
    readonly property int maxVisible: (moduleData && moduleData.maxVisible !== undefined)
        ? Math.max(1, Math.min(6, Number(moduleData.maxVisible) || 3))
        : 3
    readonly property bool showContent: (moduleData && moduleData.showContent !== undefined)
        ? Boolean(moduleData.showContent)
        : true
    readonly property bool hideWhenEmpty: (moduleData && moduleData.hideWhenEmpty !== undefined)
        ? Boolean(moduleData.hideWhenEmpty)
        : false

    readonly property var sampleNotifications: [
        {
            notifId: "sample_1",
            appName: "Telegram",
            displayAppName: "Telegram",
            appIcon: "telegram",
            summary: "Alex Rivera",
            body: "Are we still on for the design review at 10:00?",
            displayBody: "Are we still on for the design review at 10:00?",
            urgency: NotificationUrgency.Normal,
            timeStr: "Now",
            isSample: true
        },
        {
            notifId: "sample_2",
            appName: "Telegram",
            displayAppName: "Telegram",
            appIcon: "telegram",
            summary: "Design Team",
            body: "Updated mockups pushed to main.",
            displayBody: "Updated mockups pushed to main.",
            urgency: NotificationUrgency.Normal,
            timeStr: "2m",
            isSample: true
        },
        {
            notifId: "sample_3",
            appName: "System",
            displayAppName: "System",
            appIcon: "",
            customGlyph: "󰄀",
            summary: "Screenshot Captured",
            body: "Saved to Pictures/Screenshots",
            displayBody: "Saved to Pictures/Screenshots",
            urgency: NotificationUrgency.Low,
            timeStr: "5m",
            isSample: true
        }
    ]

    readonly property var liveHistory: (typeof NotificationService !== "undefined" && NotificationService.history)
        ? NotificationService.history
        : []

    readonly property var rawList: {
        if (liveHistory && liveHistory.length > 0) return liveHistory;
        if (root.isStageEditor) return root.sampleNotifications;
        return [];
    }

    function cleanText(val) {
        if (!val) return "";
        return String(val).replace(/^[ \t]+|[ \t]+$/gm, "").trim();
    }

    readonly property var historyModel: (rawList || []).map(h => {
        const rawImg = String(h.cachedImage || h.image || "").trim();
        const normImg = rawImg.startsWith("image://icon//")
            ? ("file://" + rawImg.slice(13))
            : (rawImg.startsWith("/") ? ("file://" + rawImg) : rawImg);
        const imgStr = (normImg.indexOf("image://qsimage/") !== -1 || normImg === "__sample__") ? "" : normImg;
        const appFormatted = SocialApps.formatAppName(h.displayAppName || h.appName || "", h.socialApp);
        const acts = (!h.isSample && h.actions) ? (h.actions || []).map(a => ({
            label: a.label || a.text || "",
            identifier: String(a.identifier || ""),
            customCmd: String(a.customCmd || "")
        })).filter(a => a.label !== "") : [];
        return {
            rawItem: h,
            notifId: h.notifId,
            notifAppName: (appFormatted && appFormatted.trim() !== "") ? appFormatted.trim() : "System",
            notifAppIcon: h.appIcon || "",
            notifImage: imgStr,
            notifSummary: root.cleanText(h.summary || "New Notification"),
            notifBody: root.cleanText(h.displayBody || h.body || ""),
            notifTime: h.timeStr || "Now",
            notifUrgency: h.urgency !== undefined ? h.urgency : NotificationUrgency.Normal,
            customGlyph: h.customGlyph || "",
            isSample: Boolean(h.isSample),
            notifActions: acts
        };
    })

    // Grouped per app (newest first), matching ControlCenter NotificationsView
    readonly property var notifGroups: {
        const order = [];
        const map = {};
        for (const n of historyModel) {
            const key = n.notifAppName;
            if (!map[key]) {
                map[key] = { appName: key, items: [] };
                order.push(key);
            }
            map[key].items.push(n);
        }
        const groups = order.map(k => map[k]);
        return root.isStageEditor ? groups.slice(0, root.maxVisible) : groups;
    }

    readonly property int totalCount: historyModel.length
    readonly property var topItem: historyModel.length > 0 ? historyModel[0] : null
    readonly property bool isDnd: (typeof NotificationService !== "undefined") ? Boolean(NotificationService.doNotDisturb) : false
    readonly property bool shouldHideOnLock: !root.isStageEditor && root.hideWhenEmpty && totalCount === 0

    function toggleGroup(app) {
        if (root.isStageEditor) return;
        const copy = Object.assign({}, root.expandedApps);
        copy[app] = !copy[app];
        root.expandedApps = copy;
    }

    function dismissNotif(id) {
        if (typeof NotificationService !== "undefined" && id) {
            NotificationService.dismissHistoryItem(id);
        }
    }

    function dismissGroup(app) {
        if (typeof NotificationService !== "undefined" && app) {
            NotificationService.dismissHistoryByApp(app);
        }
    }

    function clearAll() {
        root.expandedApps = ({});
        if (typeof NotificationService !== "undefined") {
            NotificationService.clearHistory();
        }
    }

    function resolveColor(colStr) {
        return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.accentPrimary);
    }

    readonly property color moduleAccent: resolveColor(root.moduleData ? root.moduleData.color : "$accent")

    function resolveNotifGlyph(notif) {
        if (!notif) return "󰂚";
        if (notif.customGlyph && notif.customGlyph !== "") return notif.customGlyph;
        const sApp = SocialApps.detectApp(notif.notifAppName, notif.notifAppIcon, notif.notifSummary, notif.notifBody);
        if (sApp && sApp.icon) return sApp.icon;
        const name = String(notif.notifAppName + " " + notif.notifSummary + " " + notif.notifBody).toLowerCase();
        if (notif.notifUrgency === NotificationUrgency.Critical) return "󰀦";
        if (name.indexOf("screenshot") !== -1 || name.indexOf("swappy") !== -1 || name.indexOf("grim") !== -1) return "󰄀";
        if (name.indexOf("firefox") !== -1) return "󰈹";
        if (name.indexOf("chrome") !== -1 || name.indexOf("brave") !== -1) return "󰊯";
        if (name.indexOf("spotify") !== -1) return "󰓇";
        if (name.indexOf("gmail") !== -1 || name.indexOf("mail") !== -1) return "󰊫";
        if (name.indexOf("terminal") !== -1 || name.indexOf("kitty") !== -1 || name.indexOf("alacritty") !== -1) return "󰞷";
        return "󰂚";
    }

    function resolveNotifAccent(notif) {
        if (!notif) return root.moduleAccent;
        if (notif.notifUrgency === NotificationUrgency.Critical) return root.theme.accentRed;
        const sApp = SocialApps.detectApp(notif.notifAppName, notif.notifAppIcon, notif.notifSummary, notif.notifBody);
        if (sApp && sApp.color) return sApp.color;
        return root.moduleAccent;
    }

    onTotalCountChanged: {
        if (root.totalCount > 0) badgePopAnim.restart();
    }

    onTopItemChanged: {
        if (root.isCompact && root.topItem) compactTextPopAnim.restart();
    }

    opacity: root.shouldHideOnLock ? 0.0 : 1.0
    scale: root.shouldHideOnLock ? 0.94 : 1.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    implicitWidth: isCompact
        ? Math.max(150, Math.round(336 * root.scaleFactor))
        : Math.max(180, Math.round(368 * root.scaleFactor))

    implicitHeight: isCompact
        ? Math.max(34, Math.round(68 * root.scaleFactor))
        : Math.max(64, fullStackCol.implicitHeight + Math.round((root.showCard ? 24 : 8) * root.scaleFactor))

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // 1. COMPACT NOTIFICATION PILL / BANNER
    Rectangle {
        visible: root.isCompact
        anchors.fill: parent
        radius: Math.max(8, Math.round(14 * root.scaleFactor))
        color: root.showCard
            ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.82)
            : "transparent"
        border.width: root.showCard ? 1 : 0
        border.color: root.theme.bgBorder
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.max(5, Math.round(10 * root.scaleFactor))
            spacing: Math.max(5, Math.round(10 * root.scaleFactor))

            Rectangle {
                id: compactIconBox
                readonly property var tInfo: root.topItem
                    ? NotificationPresentation.resolveIconInfo(root.topItem.rawItem, root.resolveNotifAccent(root.topItem), Quickshell, DesktopEntries)
                    : ({ themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: root.moduleAccent })
                readonly property bool hasAvatar: !root.isDnd && root.topItem !== null && compactAvatarImg.status === Image.Ready
                readonly property bool hasRealIcon: hasAvatar || compactThemeIcon.visible || compactFileIcon.visible

                width: Math.max(20, Math.round(40 * root.scaleFactor))
                height: width
                radius: Math.max(4, Math.round(8 * root.scaleFactor))
                color: hasRealIcon ? "transparent" : Qt.rgba(1, 1, 1, 0.08)

                Image {
                    id: compactAvatarImg
                    anchors.fill: parent
                    source: (!root.isDnd && root.topItem && root.topItem.notifImage) ? root.topItem.notifImage : ""
                    sourceSize: Qt.size(72, 72)
                    cache: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    visible: source !== "" && status === Image.Ready
                }

                IconImage {
                    id: compactThemeIcon
                    anchors.centerIn: parent
                    implicitSize: Math.max(12, Math.round(parent.width * 0.75))
                    source: (!compactIconBox.hasAvatar && compactIconBox.tInfo.themeSrc) ? compactIconBox.tInfo.themeSrc : ""
                    visible: !root.isDnd && !compactIconBox.hasAvatar && source !== "" && status === Image.Ready
                }

                Image {
                    id: compactFileIcon
                    anchors.centerIn: parent
                    width: Math.max(12, Math.round(parent.width * 0.75))
                    height: width
                    sourceSize: Qt.size(64, 64)
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: (!compactIconBox.hasAvatar && !compactThemeIcon.visible && compactIconBox.tInfo.fileSrc) ? compactIconBox.tInfo.fileSrc : ""
                    visible: !root.isDnd && !compactIconBox.hasAvatar && source !== "" && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !compactIconBox.hasRealIcon
                    text: root.isDnd ? "󰂛" : (root.topItem ? root.resolveNotifGlyph(root.topItem) : "󰂚")
                    font.family: root.font
                    font.pixelSize: Math.max(10, Math.round(18 * root.scaleFactor))
                    color: root.isDnd ? root.theme.accentOrange : (root.topItem ? root.resolveNotifAccent(root.topItem) : root.moduleAccent)
                }

                Rectangle {
                    id: compactUnreadBadge
                    visible: root.totalCount > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: -2
                    width: Math.max(10, Math.round(16 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: root.moduleAccent

                    SequentialAnimation {
                        id: badgePopAnim
                        NumberAnimation { target: compactUnreadBadge; property: "scale"; to: 1.25; duration: 130; easing.type: Easing.OutCubic }
                        NumberAnimation { target: compactUnreadBadge; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.totalCount > 9 ? "9+" : String(root.totalCount)
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(9 * root.scaleFactor))
                        font.bold: true
                        color: root.theme.bgBase
                    }
                }
            }

            ColumnLayout {
                id: compactTextCol
                Layout.fillWidth: true
                spacing: 2

                ParallelAnimation {
                    id: compactTextPopAnim
                    NumberAnimation { target: compactTextCol; property: "opacity"; from: 0.25; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: compactTextCol; property: "Layout.topMargin"; from: 4; to: 0; duration: 220; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (root.isDnd && !root.topItem) return "Do Not Disturb";
                            if (!root.topItem) return "No Notifications";
                            if (!root.showContent) return root.topItem.notifAppName;
                            return root.topItem.notifSummary || root.topItem.notifAppName;
                        }
                        font.family: root.font
                        font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.topItem !== null
                        text: root.topItem ? root.topItem.notifTime : ""
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                        color: root.theme.textMuted
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (!root.topItem) return root.isDnd ? "Alerts silenced on lock screen" : "You're all caught up";
                        if (!root.showContent) {
                            return root.totalCount === 1 ? "1 unread notification" : (root.totalCount + " unread notifications");
                        }
                        return root.topItem.notifBody || root.topItem.notifAppName;
                    }
                    font.family: root.font
                    font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: root.liveHistory.length > 0
                width: Math.max(16, Math.round(24 * root.scaleFactor))
                height: width
                radius: width / 2
                color: clearCompactHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                HoverHandler { id: clearCompactHover }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(11 * root.scaleFactor))
                    color: clearCompactHover.hovered ? root.theme.accentRed : root.theme.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()
                }
            }
        }
    }

    // 2. GROUPED NOTIFICATION STACKS (matching NotificationsView / Picture 2)
    Rectangle {
        visible: !root.isCompact
        anchors.fill: parent
        radius: Math.max(8, Math.round(16 * root.scaleFactor))
        color: root.showCard
            ? Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.84)
            : "transparent"
        border.width: root.showCard ? 1 : 0
        border.color: root.theme.bgBorder
        clip: true

        ColumnLayout {
            id: fullStackCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Math.max(4, Math.round((root.showCard ? 12 : 4) * root.scaleFactor))
            }
            spacing: Math.max(6, Math.round(10 * root.scaleFactor))

            // Top Header Row (only shown when outer card frame is enabled or multiple app groups exist)
            RowLayout {
                visible: root.showCard || root.notifGroups.length > 1 || root.totalCount === 0
                Layout.fillWidth: true
                Layout.leftMargin: Math.round(2 * root.scaleFactor)
                Layout.rightMargin: Math.round(2 * root.scaleFactor)
                spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                Text {
                    text: "Notifications"
                    color: root.theme.textPrimary
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor))
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    visible: root.totalCount > 0
                    implicitWidth: Math.max(Math.round(20 * root.scaleFactor), totalBadgeTxt.implicitWidth + Math.round(10 * root.scaleFactor))
                    height: Math.max(12, Math.round(16 * root.scaleFactor))
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        id: totalBadgeTxt
                        anchors.centerIn: parent
                        text: String(root.totalCount)
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                        font.bold: true
                        color: root.moduleAccent
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: root.liveHistory.length > 0
                    implicitWidth: clearTopTxt.implicitWidth + Math.max(10, Math.round(16 * root.scaleFactor))
                    height: Math.max(16, Math.round(24 * root.scaleFactor))
                    radius: Math.max(4, Math.round(6 * root.scaleFactor))
                    color: clearTopMouse.containsMouse
                        ? Qt.rgba(root.moduleAccent.r, root.moduleAccent.g, root.moduleAccent.b, 0.9)
                        : root.moduleAccent
                    scale: clearTopMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Text {
                        id: clearTopTxt
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: root.theme.bgBase
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(10.5 * root.scaleFactor))
                        font.bold: true
                    }

                    MouseArea {
                        id: clearTopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAll()
                    }
                }
            }

            // Grouped Per-App Stacks ListView
            ListView {
                id: notificationList
                visible: root.historyModel.length > 0
                Layout.fillWidth: true
                readonly property real maxStackHeight: Math.round((root.maxVisible * 126) * root.scaleFactor)
                height: root.isStageEditor ? contentHeight : Math.min(contentHeight, Math.max(Math.round(180 * root.scaleFactor), maxStackHeight))
                implicitHeight: height
                clip: true
                spacing: Math.max(6, Math.round(12 * root.scaleFactor))
                interactive: !root.isStageEditor && contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: notificationList.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: 1.5
                        color: Qt.rgba(root.theme.textMuted.r, root.theme.textMuted.g, root.theme.textMuted.b, 0.4)
                    }
                }

                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
                }

                model: root.visible ? root.notifGroups : []

                delegate: Column {
                    id: groupDelegate
                    required property var modelData
                    readonly property string appName: modelData.appName
                    readonly property var items: modelData.items
                    readonly property bool multi: items.length > 1
                    readonly property bool expanded: Boolean(root.expandedApps[appName])

                    width: ListView.view ? (ListView.view.width - (notificationList.interactive ? 6 : 0)) : 340
                    spacing: 0

                    // Group Header (shown for multi-notification app stacks: AppName + [count] ... Expand v  Clear)
                    Rectangle {
                        width: parent.width
                        height: groupDelegate.multi ? Math.max(16, Math.round(28 * root.scaleFactor)) : 0
                        implicitHeight: height
                        visible: groupDelegate.multi
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(4 * root.scaleFactor)
                            anchors.rightMargin: Math.round(4 * root.scaleFactor)
                            spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                            Text {
                                text: groupDelegate.appName
                                font.family: root.font
                                font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            Rectangle {
                                implicitWidth: Math.max(Math.round(20 * root.scaleFactor), groupCountTxt.implicitWidth + Math.round(8 * root.scaleFactor))
                                height: Math.max(11, Math.round(16 * root.scaleFactor))
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.08)

                                Text {
                                    id: groupCountTxt
                                    anchors.centerIn: parent
                                    text: String(groupDelegate.items.length)
                                    font.family: root.font
                                    font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                    font.bold: true
                                    color: root.moduleAccent
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: groupDelegate.expanded ? "Collapse 󰅃" : "Expand 󰅀"
                                font.family: root.font
                                font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                color: root.moduleAccent

                                MouseArea {
                                    enabled: !root.isStageEditor
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleGroup(groupDelegate.appName)
                                }
                            }

                            Text {
                                visible: !root.isStageEditor
                                text: "Clear"
                                font.family: root.font
                                font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                color: clearGrpMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted

                                MouseArea {
                                    id: clearGrpMouse
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dismissGroup(groupDelegate.appName)
                                }
                            }
                        }
                    }

                    // Cards in Stack (newest card + peek strips when collapsed; all cards when expanded)
                    Column {
                        width: parent.width
                        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                        Repeater {
                            model: groupDelegate.items

                            delegate: Item {
                                id: notifWrap
                                required property var modelData
                                required property int index

                                readonly property bool isPrimary: index === 0
                                readonly property bool isVisibleInStack: isPrimary || groupDelegate.expanded
                                property bool isDismissing: false
                                property real dismissTargetX: 0

                                width: parent.width
                                readonly property real naturalHeight: notifDelegate.implicitHeight + (isPrimary ? peekLayers.height : 0)
                                readonly property real targetHeight: (isVisibleInStack && !isDismissing) ? naturalHeight : 0

                                height: targetHeight
                                implicitHeight: height
                                visible: height > 0 || opacity > 0
                                clip: true

                                Behavior on height {
                                    enabled: !notifWrap.isDismissing
                                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                                }
                                Behavior on opacity {
                                    enabled: !notifWrap.isDismissing && !dragArea.drag.active
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }

                                opacity: (isVisibleInStack && !isDismissing)
                                    ? (1.0 - Math.min(0.65, Math.abs(notifDelegate.x) / Math.max(1, width * 0.75)))
                                    : 0

                                function triggerDismiss(directionX) {
                                    if (isDismissing || notifWrap.modelData.isSample) return;
                                    isDismissing = true;
                                    dismissTargetX = directionX !== undefined ? directionX : (width + 40);
                                    dismissAnim.start();
                                }

                                ParallelAnimation {
                                    id: dismissAnim
                                    NumberAnimation {
                                        target: notifDelegate
                                        property: "x"
                                        to: notifWrap.dismissTargetX
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: notifWrap
                                        property: "opacity"
                                        to: 0
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: notifWrap
                                        property: "height"
                                        to: 0
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                    onFinished: root.dismissNotif(notifDelegate.currentNotifId)
                                }

                                Rectangle {
                                    id: notifDelegate
                                    readonly property var notif: notifWrap.modelData
                                    readonly property string currentNotifId: String(notifWrap.modelData.notifId || "")
                                    readonly property color cardAccent: root.resolveNotifAccent(notif)
                                    readonly property var iconInfo: NotificationPresentation.resolveIconInfo(notif.rawItem, cardAccent, Quickshell, DesktopEntries)

                                    width: parent.width
                                    height: notifCardCol.implicitHeight + Math.max(12, Math.round(22 * root.scaleFactor))
                                    implicitHeight: height
                                    radius: Math.max(5, Math.round(8 * root.scaleFactor))
                                    color: root.showCard
                                        ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
                                        : Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.84)
                                    border.color: root.theme.bgBorder
                                    border.width: 1
                                    clip: true

                                    transform: Translate {
                                        y: (!notifWrap.isPrimary && !groupDelegate.expanded) ? -12 : 0
                                        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }

                                    Behavior on x {
                                        enabled: !dragArea.drag.active && !notifWrap.isDismissing
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }

                                    MouseArea {
                                        id: dragArea
                                        enabled: !root.isStageEditor && !notifDelegate.notif.isSample
                                        anchors.fill: parent
                                        drag.target: notifDelegate
                                        drag.axis: Drag.XAxis
                                        drag.minimumX: -notifWrap.width * 1.2
                                        drag.maximumX: notifWrap.width * 1.2
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
                                        z: 0

                                        onReleased: {
                                            if (notifWrap.isDismissing) return;
                                            const threshold = 80;
                                            if (notifDelegate.x > threshold) {
                                                notifWrap.triggerDismiss(notifWrap.width + 40);
                                            } else if (notifDelegate.x < -threshold) {
                                                notifWrap.triggerDismiss(-notifWrap.width - 40);
                                            } else {
                                                notifDelegate.x = 0;
                                            }
                                        }
                                    }

                                    // Left vertical accent line (matching Picture 2)
                                    Rectangle {
                                        width: Math.max(2, Math.round(3 * root.scaleFactor))
                                        height: parent.height - Math.max(8, Math.round(16 * root.scaleFactor))
                                        radius: Math.max(1, Math.round(2 * root.scaleFactor))
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.max(3, Math.round(6 * root.scaleFactor))
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: notifDelegate.cardAccent
                                    }

                                    ColumnLayout {
                                        id: notifCardCol
                                        z: 1
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: Math.max(5, Math.round(10 * root.scaleFactor))
                                            leftMargin: Math.max(8, Math.round(16 * root.scaleFactor))
                                        }
                                        spacing: Math.max(3, Math.round(6 * root.scaleFactor))

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Math.max(6, Math.round(12 * root.scaleFactor))

                                            // Left: Notification Image / Avatar FIRST (e.g. Antigravity logo), then Desktop/App Icon, then Glyph
                                            Rectangle {
                                                id: ccIconBox
                                                readonly property bool hasAvatar: notifAvatarImg.status === Image.Ready
                                                readonly property bool hasAnyIcon: hasAvatar || appIconImg.visible || notifImg.visible || ccGlyphText.text !== ""
                                                readonly property bool isSocial: SocialApps.detectApp(
                                                    notifDelegate.notif.notifAppName,
                                                    notifDelegate.notif.notifAppIcon,
                                                    notifDelegate.notif.notifSummary,
                                                    notifDelegate.notif.notifBody
                                                ) !== null
                                                readonly property int boxSize: Math.max(18, Math.round(36 * root.scaleFactor))

                                                visible: hasAnyIcon
                                                Layout.preferredWidth: hasAnyIcon ? boxSize : 0
                                                Layout.preferredHeight: hasAnyIcon ? boxSize : 0
                                                radius: (hasAvatar && isSocial) ? (boxSize / 2) : Math.max(4, Math.round(8 * root.scaleFactor))
                                                color: (hasAvatar || appIconImg.visible || notifImg.visible)
                                                    ? "transparent"
                                                    : Qt.rgba(1, 1, 1, 0.08)
                                                Layout.alignment: Qt.AlignTop
                                                clip: true

                                                Rectangle {
                                                    id: ccAvatarMask
                                                    anchors.fill: parent
                                                    radius: ccIconBox.isSocial ? (width / 2) : Math.max(4, Math.round(8 * root.scaleFactor))
                                                    antialiasing: true
                                                    visible: false
                                                    layer.enabled: ccIconBox.hasAvatar && notifWrap.isVisibleInStack
                                                    layer.smooth: true
                                                    layer.textureSize: Qt.size(72, 72)
                                                }

                                                Item {
                                                    anchors.fill: parent
                                                    visible: Boolean(notifDelegate.notif.notifImage)
                                                    opacity: ccIconBox.hasAvatar ? 1.0 : 0.0
                                                    layer.enabled: ccIconBox.hasAvatar && notifWrap.isVisibleInStack
                                                    layer.smooth: true
                                                    layer.effect: MultiEffect {
                                                        maskEnabled: true
                                                        maskSource: ccAvatarMask
                                                        maskThresholdMin: 0.35
                                                        maskSpreadAtMin: 0.3
                                                    }

                                                    Image {
                                                        id: notifAvatarImg
                                                        anchors.fill: parent
                                                        source: notifDelegate.notif.notifImage || ""
                                                        sourceSize: Qt.size(72, 72)
                                                        cache: false
                                                        asynchronous: true
                                                        fillMode: Image.PreserveAspectCrop
                                                        visible: source !== "" && status === Image.Ready
                                                    }
                                                }

                                                IconImage {
                                                    id: appIconImg
                                                    anchors.centerIn: parent
                                                    implicitSize: Math.max(14, Math.round(28 * root.scaleFactor))
                                                    property bool triedFallback: false
                                                    readonly property string primarySrc: (!ccIconBox.hasAvatar && notifDelegate.iconInfo.themeSrc) ? notifDelegate.iconInfo.themeSrc : ""
                                                    onPrimarySrcChanged: triedFallback = false
                                                    source: (!triedFallback || !notifDelegate.iconInfo.fallbackThemeSrc) ? primarySrc : notifDelegate.iconInfo.fallbackThemeSrc
                                                    onStatusChanged: {
                                                        if (status === Image.Error && !triedFallback && notifDelegate.iconInfo.fallbackThemeSrc !== "") {
                                                            triedFallback = true;
                                                        }
                                                    }
                                                    visible: !ccIconBox.hasAvatar && source !== "" && status === Image.Ready && (!notifDelegate.notif.customGlyph || notifDelegate.notif.customGlyph === "")
                                                }

                                                Image {
                                                    id: notifImg
                                                    anchors.centerIn: parent
                                                    width: Math.max(14, Math.round(28 * root.scaleFactor))
                                                    height: width
                                                    source: (!ccIconBox.hasAvatar && !appIconImg.visible && notifDelegate.iconInfo.fileSrc) ? notifDelegate.iconInfo.fileSrc : ""
                                                    sourceSize: Qt.size(56, 56)
                                                    cache: false
                                                    asynchronous: true
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: !ccIconBox.hasAvatar && !appIconImg.visible && source !== "" && status === Image.Ready && (!notifDelegate.notif.customGlyph || notifDelegate.notif.customGlyph === "")
                                                }

                                                Text {
                                                    id: ccGlyphText
                                                    anchors.centerIn: parent
                                                    text: root.resolveNotifGlyph(notifDelegate.notif)
                                                    font.family: root.font
                                                    font.pixelSize: Math.max(8, Math.round(14 * root.scaleFactor))
                                                    color: notifDelegate.cardAccent
                                                    visible: !ccIconBox.hasAvatar && !appIconImg.visible && !notifImg.visible && text !== ""
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignTop
                                                spacing: Math.max(2, Math.round(4 * root.scaleFactor))

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Math.max(3, Math.round(6 * root.scaleFactor))

                                                    Text {
                                                        text: notifDelegate.notif.notifAppName
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                    }

                                                    Text {
                                                        text: "•"
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                                        color: root.theme.textMuted
                                                    }

                                                    Text {
                                                        text: notifDelegate.notif.notifTime
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                                        color: root.theme.textMuted
                                                        Layout.fillWidth: true
                                                    }

                                                    // Dismiss single notification button
                                                    Rectangle {
                                                        visible: !notifDelegate.notif.isSample
                                                        width: Math.max(12, Math.round(20 * root.scaleFactor))
                                                        height: width
                                                        radius: width / 2
                                                        color: closeHover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                                        Layout.alignment: Qt.AlignVCenter

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "󰅖"
                                                            font.family: root.font
                                                            font.pixelSize: Math.max(6, Math.round(11 * root.scaleFactor))
                                                            color: closeHover.containsMouse ? root.theme.accentRed : root.theme.textMuted
                                                        }

                                                        MouseArea {
                                                            id: closeHover
                                                            enabled: !root.isStageEditor
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: notifWrap.triggerDismiss(notifWrap.width + 40)
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Math.max(1, Math.round(3 * root.scaleFactor))

                                                    Text {
                                                        text: root.showContent
                                                            ? notifDelegate.notif.notifSummary
                                                            : "Notification content hidden"
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(7, Math.round(12 * root.scaleFactor))
                                                        font.bold: root.showContent
                                                        font.italic: !root.showContent
                                                        color: root.showContent ? root.theme.textPrimary : root.theme.textMuted
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        visible: text !== ""
                                                    }

                                                    Text {
                                                        text: notifDelegate.notif.notifBody
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(6, Math.round(11 * root.scaleFactor))
                                                        color: root.theme.textSecondary
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 3
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        visible: root.showContent && text !== ""
                                                    }
                                                }
                                            }
                                        }

                                        // Bottom-right Stack Badge Pill (+N) when grouped stack is collapsed
                                        RowLayout {
                                            Layout.fillWidth: true
                                            visible: groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary

                                            Item { Layout.fillWidth: true }

                                            Rectangle {
                                                Layout.preferredWidth: badgeText.implicitWidth + Math.max(6, Math.round(10 * root.scaleFactor))
                                                Layout.preferredHeight: Math.max(12, Math.round(18 * root.scaleFactor))
                                                radius: Layout.preferredHeight / 2
                                                color: Qt.rgba(1, 1, 1, 0.1)

                                                Text {
                                                    id: badgeText
                                                    anchors.centerIn: parent
                                                    text: "+" + (groupDelegate.items.length - 1)
                                                    font.family: root.font
                                                    font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                                    font.bold: true
                                                    color: root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    enabled: !root.isStageEditor
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.toggleGroup(groupDelegate.appName)
                                                }
                                            }
                                        }

                                        // Interactive Inline Actions
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: Math.max(16, Math.round(28 * root.scaleFactor))
                                            spacing: Math.max(4, Math.round(6 * root.scaleFactor))
                                            Layout.topMargin: Math.round(2 * root.scaleFactor)
                                            visible: root.showContent && !root.isStageEditor && notifDelegate.notif.notifActions && notifDelegate.notif.notifActions.length > 0

                                            Repeater {
                                                model: notifDelegate.notif.notifActions
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Layout.preferredWidth: 1
                                                    Layout.preferredHeight: Math.max(16, Math.round(28 * root.scaleFactor))
                                                    height: Layout.preferredHeight
                                                    radius: height / 2
                                                    color: actionHover.containsMouse
                                                        ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                                                        : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: root.moduleAccent
                                                        font.family: root.font
                                                        font.pixelSize: Math.max(6, Math.round(11 * root.scaleFactor))
                                                        font.bold: true
                                                    }

                                                    MouseArea {
                                                        id: actionHover
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (typeof NotificationService !== "undefined" && notifDelegate.currentNotifId && modelData.identifier) {
                                                                NotificationService.invokeHistoryAction(notifDelegate.currentNotifId, modelData.identifier);
                                                            } else if (modelData.customCmd && modelData.customCmd !== "") {
                                                                Quickshell.execDetached(["sh", "-c", modelData.customCmd]);
                                                            }
                                                            notifWrap.triggerDismiss(notifWrap.width + 40);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Stacked Deck "Peek" Layers underneath collapsed group card (matching Picture 2)
                                Item {
                                    id: peekLayers
                                    y: notifDelegate.height
                                    width: parent.width
                                    readonly property int peekH: Math.max(8, Math.round(14 * root.scaleFactor))
                                    height: (groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary) ? peekH : 0
                                    visible: height > 0 || opacity > 0
                                    opacity: (groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary) ? 1.0 : 0.0

                                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        y: Math.round(2 * root.scaleFactor)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width - Math.round(16 * root.scaleFactor)
                                        height: Math.max(4, Math.round(8 * root.scaleFactor))
                                        radius: Math.max(3, Math.round(6 * root.scaleFactor))
                                        color: Qt.rgba(1, 1, 1, 0.05)
                                        border.color: Qt.rgba(1, 1, 1, 0.06)
                                        border.width: 1
                                    }
                                    Rectangle {
                                        y: Math.round(8 * root.scaleFactor)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width - Math.round(32 * root.scaleFactor)
                                        height: Math.max(3, Math.round(6 * root.scaleFactor))
                                        radius: Math.max(3, Math.round(6 * root.scaleFactor))
                                        color: Qt.rgba(1, 1, 1, 0.03)
                                        border.color: Qt.rgba(1, 1, 1, 0.06)
                                        border.width: 1
                                    }
                                    MouseArea {
                                        enabled: !root.isStageEditor
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleGroup(groupDelegate.appName)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty State
            Item {
                Layout.fillWidth: true
                height: root.historyModel.length === 0 ? Math.max(36, Math.round(64 * root.scaleFactor)) : 0
                implicitHeight: height
                visible: root.historyModel.length === 0

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                    Text {
                        text: root.isDnd ? "󰂛" : "󰂚"
                        font.family: root.font
                        font.pixelSize: Math.max(9, Math.round(14 * root.scaleFactor))
                        color: root.theme.textMuted
                    }

                    Text {
                        text: root.isDnd ? "Do Not Disturb Active" : "No Notifications"
                        font.family: root.font
                        font.pixelSize: Math.max(7, Math.round(12 * root.scaleFactor))
                        color: root.theme.textMuted
                    }
                }
            }
        }
    }
}
