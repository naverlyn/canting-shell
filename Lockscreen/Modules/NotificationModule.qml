import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/SocialApps.js" as SocialApps
import ".."
import "../../utils/ColorUtils.js" as ColorUtils

Item {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

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
            appName: "WhatsApp",
            displayAppName: "WhatsApp",
            appIcon: "",
            customGlyph: "󰖣",
            summary: "Alex Rivera",
            body: "Are we still on for the design review at 10:00?",
            displayBody: "Are we still on for the design review at 10:00?",
            urgency: NotificationUrgency.Normal,
            timeStr: "Now",
            isSample: true
        },
        {
            notifId: "sample_2",
            appName: "System Monitor",
            displayAppName: "System",
            appIcon: "",
            customGlyph: "󰂚",
            summary: "Backup Completed",
            body: "Configuration snapshot saved successfully.",
            displayBody: "Configuration snapshot saved successfully.",
            urgency: NotificationUrgency.Low,
            timeStr: "2m",
            isSample: true
        }
    ]

    readonly property var liveHistory: (typeof NotificationService !== "undefined" && NotificationService.history)
        ? NotificationService.history
        : []

    readonly property var activeList: {
        if (liveHistory && liveHistory.length > 0) return liveHistory;
        if (root.isStageEditor) return root.sampleNotifications;
        return [];
    }

    readonly property int totalCount: (liveHistory && liveHistory.length > 0)
        ? liveHistory.length
        : (root.isStageEditor ? root.sampleNotifications.length : 0)

    readonly property var visibleItems: activeList.slice(0, root.maxVisible)
    readonly property int overflowCount: Math.max(0, totalCount - visibleItems.length)
    readonly property var topItem: activeList.length > 0 ? activeList[0] : null
    readonly property bool isDnd: (typeof NotificationService !== "undefined") ? Boolean(NotificationService.doNotDisturb) : false

    readonly property bool shouldHideOnLock: !root.isStageEditor && root.hideWhenEmpty && root.activeList.length === 0

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(root.theme, colStr, root.theme.accentPrimary); }

    readonly property color moduleAccent: resolveColor(root.moduleData ? root.moduleData.color : "$accent")

    function resolveNotifGlyph(item) {
        if (!item) return "󰂚";
        if (item.customGlyph && item.customGlyph !== "") return item.customGlyph;
        const sApp = item.socialApp || SocialApps.detectApp(item.appName, item.appIcon, item.summary, item.body);
        if (sApp && sApp.icon) return sApp.icon;
        const name = String((item.appName || "") + " " + (item.summary || "")).toLowerCase();
        if (item.urgency === NotificationUrgency.Critical) return "󰀦";
        if (name.includes("whatsapp")) return "󰖣";
        if (name.includes("discord"))  return "󰙯";
        if (name.includes("telegram")) return "󰈎";
        if (name.includes("spotify"))  return "󰓇";
        if (name.includes("firefox"))  return "󰈹";
        if (name.includes("chrome") || name.includes("brave")) return "󰊯";
        if (name.includes("mail") || name.includes("gmail")) return "󰊫";
        if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "󰞷";
        return "󰂚";
    }

    function resolveNotifAccent(item) {
        if (!item) return root.moduleAccent;
        if (item.urgency === NotificationUrgency.Critical) return root.theme.accentRed;
        const sApp = item.socialApp || SocialApps.detectApp(item.appName, item.appIcon, item.summary, item.body);
        if (sApp && sApp.color) return sApp.color;
        if (item.urgency === NotificationUrgency.Low) return root.theme.accentCyan;
        return root.moduleAccent;
    }

    visible: !root.shouldHideOnLock

    implicitWidth: isCompact
        ? Math.max(140, Math.round(320 * root.scaleFactor))
        : Math.max(170, Math.round(340 * root.scaleFactor))

    implicitHeight: isCompact
        ? Math.max(32, Math.round(68 * root.scaleFactor))
        : Math.max(64, fullStackCol.implicitHeight + Math.round(22 * root.scaleFactor))

    // =========================================================================
    // 1. COMPACT NOTIFICATION PILL / BANNER
    // =========================================================================
    Rectangle {
        visible: root.isCompact
        anchors.fill: parent
        radius: Math.max(8, Math.round(16 * root.scaleFactor))
        color: root.showCard
            ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
            : "transparent"
        border.width: root.showCard ? 1 : 0
        border.color: root.theme.bgBorder
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.max(4, Math.round(10 * root.scaleFactor))
            spacing: Math.max(4, Math.round(10 * root.scaleFactor))

            // Notification Bell / App Badge
            Rectangle {
                width: Math.max(20, Math.round(44 * root.scaleFactor))
                height: width
                radius: Math.max(4, Math.round(10 * root.scaleFactor))
                color: root.theme.bgBase

                Text {
                    anchors.centerIn: parent
                    text: root.isDnd ? "󰂛" : (root.topItem ? root.resolveNotifGlyph(root.topItem) : "󰂚")
                    font.family: root.font
                    font.pixelSize: Math.max(10, Math.round(20 * root.scaleFactor))
                    color: root.isDnd
                        ? root.theme.accentOrange
                        : (root.topItem ? root.resolveNotifAccent(root.topItem) : root.moduleAccent)
                }

                // Unread count dot badge
                Rectangle {
                    visible: root.totalCount > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: -2
                    width: Math.max(10, Math.round(16 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: root.moduleAccent

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

            // Notification Summary & Body Preview
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (root.isDnd && !root.topItem) return "Do Not Disturb";
                            if (!root.topItem) return "No Notifications";
                            if (!root.showContent) return root.topItem.displayAppName || root.topItem.appName || "Notification";
                            return root.topItem.summary || root.topItem.displayAppName || "Notification";
                        }
                        font.family: root.font
                        font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.topItem !== null
                        text: root.topItem ? (root.topItem.timeStr || "Now") : ""
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
                        return root.topItem.displayBody || root.topItem.body || root.topItem.displayAppName || "New notification";
                    }
                    font.family: root.font
                    font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Clear button when live notifications exist
            Rectangle {
                visible: root.liveHistory.length > 0
                width: Math.max(16, Math.round(26 * root.scaleFactor))
                height: width
                radius: width / 2
                color: clearCompactHover.hovered ? root.theme.bgHover : "transparent"
                HoverHandler { id: clearCompactHover }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
                    color: clearCompactHover.hovered ? root.theme.accentRed : root.theme.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof NotificationService !== "undefined") {
                            NotificationService.clearHistory();
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. FULL / STACK NOTIFICATION CARD
    // =========================================================================
    Rectangle {
        visible: !root.isCompact
        anchors.fill: parent
        radius: Math.max(8, Math.round(16 * root.scaleFactor))
        color: root.showCard
            ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
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
                margins: Math.max(6, Math.round(11 * root.scaleFactor))
            }
            spacing: Math.max(4, Math.round(8 * root.scaleFactor))

            // Header Row: Bell Icon + Title + Count Pill + Clear All
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.max(4, Math.round(6 * root.scaleFactor))

                Text {
                    text: root.isDnd ? "󰂛" : "󰂚"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor))
                    color: root.isDnd ? root.theme.accentOrange : root.moduleAccent
                }

                Text {
                    text: "Notifications"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(12 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textPrimary
                }

                // Count Badge
                Rectangle {
                    visible: root.totalCount > 0
                    implicitWidth: countBadgeTxt.implicitWidth + Math.max(6, Math.round(10 * root.scaleFactor))
                    height: Math.max(12, Math.round(18 * root.scaleFactor))
                    radius: height / 2
                    color: Qt.rgba(root.moduleAccent.r, root.moduleAccent.g, root.moduleAccent.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(root.moduleAccent.r, root.moduleAccent.g, root.moduleAccent.b, 0.4)

                    Text {
                        id: countBadgeTxt
                        anchors.centerIn: parent
                        text: String(root.totalCount)
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                        font.bold: true
                        color: root.moduleAccent
                    }
                }

                Item { Layout.fillWidth: true }

                // Clear All Button
                Rectangle {
                    visible: root.liveHistory.length > 0
                    implicitWidth: clearAllTxt.implicitWidth + Math.max(8, Math.round(14 * root.scaleFactor))
                    height: Math.max(14, Math.round(22 * root.scaleFactor))
                    radius: Math.max(4, Math.round(6 * root.scaleFactor))
                    color: clearAllHover.hovered
                        ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18)
                        : Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.6)
                    border.width: 1
                    border.color: clearAllHover.hovered ? root.theme.accentRed : root.theme.bgBorder
                    HoverHandler { id: clearAllHover }

                    Text {
                        id: clearAllTxt
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.family: root.font
                        font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                        font.bold: true
                        color: clearAllHover.hovered ? root.theme.accentRed : root.theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof NotificationService !== "undefined") {
                                NotificationService.clearHistory();
                            }
                        }
                    }
                }
            }

            // Notification Items Stack
            Repeater {
                model: root.visibleItems

                delegate: Rectangle {
                    id: itemCard
                    required property var modelData
                    required property int index

                    readonly property color itemAccent: root.resolveNotifAccent(modelData)

                    Layout.fillWidth: true
                    implicitHeight: itemRow.implicitHeight + Math.max(8, Math.round(16 * root.scaleFactor))
                    radius: Math.max(6, Math.round(10 * root.scaleFactor))
                    color: itemHover.hovered
                        ? Qt.rgba(root.theme.bgHover.r, root.theme.bgHover.g, root.theme.bgHover.b, 0.65)
                        : Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.55)
                    border.width: 1
                    border.color: itemHover.hovered
                        ? Qt.rgba(itemAccent.r, itemAccent.g, itemAccent.b, 0.45)
                        : Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.5)
                    clip: true

                    HoverHandler { id: itemHover }

                    // Left urgency / app accent strip
                    Rectangle {
                        width: Math.max(2, Math.round(3 * root.scaleFactor))
                        height: parent.height - Math.max(6, Math.round(12 * root.scaleFactor))
                        radius: width / 2
                        anchors.left: parent.left
                        anchors.leftMargin: Math.max(3, Math.round(5 * root.scaleFactor))
                        anchors.verticalCenter: parent.verticalCenter
                        color: itemCard.itemAccent
                    }

                    RowLayout {
                        id: itemRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: Math.max(4, Math.round(8 * root.scaleFactor))
                            leftMargin: Math.max(8, Math.round(13 * root.scaleFactor))
                        }
                        spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                        // App Icon Badge
                        Rectangle {
                            Layout.preferredWidth: Math.max(16, Math.round(30 * root.scaleFactor))
                            Layout.preferredHeight: Layout.preferredWidth
                            Layout.alignment: Qt.AlignTop
                            radius: Math.max(4, Math.round(8 * root.scaleFactor))
                            color: Qt.rgba(itemCard.itemAccent.r, itemCard.itemAccent.g, itemCard.itemAccent.b, 0.15)

                            IconImage {
                                id: itemIconImg
                                anchors.centerIn: parent
                                implicitSize: Math.max(10, Math.round(parent.width * 0.68))
                                source: (itemCard.modelData && itemCard.modelData.appIcon)
                                    ? Quickshell.iconPath(itemCard.modelData.appIcon, true)
                                    : ""
                                visible: status === Image.Ready && (!itemCard.modelData.customGlyph || itemCard.modelData.customGlyph === "")
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !itemIconImg.visible
                                text: root.resolveNotifGlyph(itemCard.modelData)
                                font.family: root.font
                                font.pixelSize: Math.max(8, Math.round(14 * root.scaleFactor))
                                color: itemCard.itemAccent
                            }
                        }

                        // Text Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.max(1, Math.round(2 * root.scaleFactor))

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: itemCard.modelData.displayAppName || itemCard.modelData.appName || "Notification"
                                    font.family: root.font
                                    font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: itemCard.modelData.timeStr || "Now"
                                    font.family: root.font
                                    font.pixelSize: Math.max(6, Math.round(9 * root.scaleFactor))
                                    color: root.theme.textMuted
                                }

                                // Dismiss single notification
                                Rectangle {
                                    visible: !itemCard.modelData.isSample
                                    width: Math.max(12, Math.round(18 * root.scaleFactor))
                                    height: width
                                    radius: width / 2
                                    color: dismissHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    HoverHandler { id: dismissHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: root.font
                                        font.pixelSize: Math.max(6, Math.round(9 * root.scaleFactor))
                                        color: dismissHover.hovered ? root.theme.accentRed : root.theme.textMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof NotificationService !== "undefined" && itemCard.modelData.notifId) {
                                                NotificationService.dismissHistoryItem(itemCard.modelData.notifId);
                                            }
                                        }
                                    }
                                }
                            }

                            // Title / Summary
                            Text {
                                Layout.fillWidth: true
                                text: root.showContent
                                    ? (itemCard.modelData.summary || "Notification")
                                    : "Notification content hidden"
                                font.family: root.font
                                font.pixelSize: Math.max(7, Math.round(11.5 * root.scaleFactor))
                                font.bold: root.showContent
                                font.italic: !root.showContent
                                color: root.showContent ? root.theme.textPrimary : root.theme.textMuted
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            // Body Text
                            Text {
                                visible: root.showContent && text !== ""
                                Layout.fillWidth: true
                                text: itemCard.modelData.displayBody || itemCard.modelData.body || ""
                                font.family: root.font
                                font.pixelSize: Math.max(6, Math.round(10.5 * root.scaleFactor))
                                color: root.theme.textSecondary
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // Overflow "+N more" footer pill
            Rectangle {
                visible: root.overflowCount > 0
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: overflowTxt.implicitWidth + Math.max(12, Math.round(20 * root.scaleFactor))
                height: Math.max(14, Math.round(22 * root.scaleFactor))
                radius: height / 2
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.55)
                border.width: 1
                border.color: root.theme.bgBorder

                Text {
                    id: overflowTxt
                    anchors.centerIn: parent
                    text: "+" + root.overflowCount + " more notification" + (root.overflowCount > 1 ? "s" : "")
                    font.family: root.font
                    font.pixelSize: Math.max(6, Math.round(10 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textSecondary
                }
            }

            // Empty State (shown on lockscreen when no notifications & hideWhenEmpty is false)
            Rectangle {
                visible: root.visibleItems.length === 0
                Layout.fillWidth: true
                implicitHeight: Math.max(30, Math.round(52 * root.scaleFactor))
                radius: Math.max(6, Math.round(10 * root.scaleFactor))
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.4)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Math.max(4, Math.round(8 * root.scaleFactor))

                    Text {
                        text: root.isDnd ? "󰂛" : "󰂚"
                        font.family: root.font
                        font.pixelSize: Math.max(9, Math.round(15 * root.scaleFactor))
                        color: root.theme.textMuted
                    }

                    Text {
                        text: root.isDnd ? "Do Not Disturb Active" : "No New Notifications"
                        font.family: root.font
                        font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                        color: root.theme.textMuted
                    }
                }
            }
        }
    }
}

