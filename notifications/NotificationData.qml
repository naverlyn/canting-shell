import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "SocialApps.js" as SocialApps

QtObject {
    id: notificationData

    property Notification notification: null
    property bool closed: false

    property string seqId: ""
    property string notifId: ""

    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string appName: ""
    property string customGlyph: ""
    property string image: ""
    property var    actions: []
    property int    urgency: NotificationUrgency.Normal
    property real   expireTimeout: defaultTimeout
    property date   createdAt: new Date()

    property bool hovered: false

    readonly property int defaultTimeout: NotificationService.defaultTimeout > 0 ? NotificationService.defaultTimeout : 5000

    readonly property string timeLabel: {
        if (NotificationService.timestampFormat === "time") {
            return Qt.formatTime(createdAt, "hh:mm");
        }
        return "Now";
    }

    readonly property var socialApp: SocialApps.detectApp(appName, appIcon, summary, body)
    readonly property bool isSocialApp: socialApp !== null
    readonly property bool isWhatsApp: socialApp !== null && socialApp.id === "whatsapp"

    readonly property string displayAppName: SocialApps.formatAppName(appName, socialApp)

    readonly property string displayBody: SocialApps.cleanBody(body, socialApp)

    readonly property Connections _conn: Connections {
        target: notificationData.notification

        function onClosed(): void {
            if (notificationData.closed) return;
            notificationData.closed = true;
            NotificationService._remove(notificationData);
            notificationData.destroy();
        }

        function onSummaryChanged(): void {
            if (notificationData.notification) {
                notificationData.summary = notificationData.notification.summary || "";
                notificationData.actions = notificationData._parseActions(notificationData.notification);
                notificationData._timer.restart();
                NotificationService._bump(notificationData);
            }
        }
        function onBodyChanged(): void {
            if (notificationData.notification) {
                notificationData.body = notificationData.notification.body || "";
                notificationData.actions = notificationData._parseActions(notificationData.notification);
                notificationData._timer.restart();
                NotificationService._bump(notificationData);
            }
        }
        function onAppIconChanged(): void {
            if (notificationData.notification) notificationData.appIcon = notificationData.notification.appIcon || "";
        }
        function onAppNameChanged(): void {
            if (notificationData.notification) {
                notificationData.appName = notificationData.notification.appName || "";
                notificationData.actions = notificationData._parseActions(notificationData.notification);
            }
        }
        function onImageChanged(): void {
            if (notificationData.notification) notificationData.image = notificationData.notification.image || "";
        }
        function onUrgencyChanged(): void {
            if (notificationData.notification) notificationData.urgency = notificationData.notification.urgency;
        }
        function onExpireTimeoutChanged(): void {
            if (notificationData.notification) notificationData.expireTimeout = notificationData.notification.expireTimeout;
        }
        function onActionsChanged(): void {
            if (!notificationData.notification) return;
            notificationData.actions = notificationData._parseActions(notificationData.notification);
        }
    }

    readonly property Timer _timer: Timer {
        running: !notificationData.closed
                 && !(NotificationService.pauseOnHover && notificationData.hovered)
                 && (notificationData.urgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical)
        interval: notificationData.expireTimeout > 0 ? notificationData.expireTimeout : notificationData.defaultTimeout
        onTriggered: {
            notificationData.dismiss()
        }
    }

    function _parseActions(notif) {
        if (!notif) return [];
        var rawActions = notif.actions || [];
        var res = [];
        var hasExplicitReply = false;
        for (var i = 0; i < rawActions.length; i++) {
            var a = rawActions[i];
            if (!a) continue;
            var text = (a.text !== undefined && a.text !== null ? String(a.text) : "").trim();
            // FreeDesktop spec: 'default' action activates the notification body, not an explicit button.
            // Also skip any actions with empty labels to avoid phantom blank buttons.
            if (a.identifier === "default" || text === "") continue;
            if (a.identifier === "reply" || text.toLowerCase() === "reply") {
                hasExplicitReply = true;
            }
            res.push({ identifier: a.identifier, text: text, isReply: false, customCmd: a.customCmd || "" });
        }

        var detected = SocialApps.detectApp(notif.appName, notif.appIcon, notif.summary, notif.body);
        if (detected && !hasExplicitReply) {
            res.unshift({ identifier: "reply", text: "Reply", isReply: true, customCmd: "" });
        }

        return res;
    }

    Component.onCompleted: {
        createdAt = new Date();
        if (!notification) {
            if (!notifId) notifId = "custom_" + seqId;
            if (expireTimeout <= 0) expireTimeout = defaultTimeout;
            return;
        }
        notifId   = String(notification.id || "");
        summary   = notification.summary   || "";
        body      = notification.body      || "";
        appIcon   = notification.appIcon   || "";
        appName   = notification.appName   || "";
        image     = notification.image     || "";
        urgency   = notification.urgency;

        const rawTimeout = notification.expireTimeout;
        expireTimeout = rawTimeout > 0 ? rawTimeout : defaultTimeout;
        actions   = _parseActions(notification);
    }

    function focusAppWindow(): void {
        if (socialApp) {
            var cmd = SocialApps.getFocusCommand(socialApp);
            if (cmd) {
                Quickshell.execDetached(["sh", "-c", cmd]);
                return;
            }
        }
        var app = (appName || "").toLowerCase();
        if (app.indexOf("spotify") !== -1) {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(spotify)$"]);
        } else if (app !== "" && app !== "notification") {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(" + app + ")$"]);
        }
    }

    function dismiss(): void {
        if (closed) return;
        closed = true;
        NotificationService._remove(notificationData);
        if (notification) try { notification.dismiss(); } catch(e) {}
        destroy();
    }

    function activate(): void {
        if (closed) return;
        if (notification && notification.actions) {
            for (var i = 0; i < notification.actions.length; i++) {
                var a = notification.actions[i];
                if (a && a.identifier === "default") {
                    invokeAction("default");
                    return;
                }
            }
        }
        if (isSocialApp) {
            invokeAction("reply");
            return;
        }
        focusAppWindow();
        dismiss();
    }

    function invokeAction(identifier): void {
        if (!identifier || closed) return;
        closed = true;
        NotificationService._remove(notificationData);

        // Check custom actions first (for synthetic/composer notifications)
        if (actions && actions.length > 0) {
            for (var c = 0; c < actions.length; c++) {
                var act = actions[c];
                if (act && act.identifier === identifier && act.customCmd && String(act.customCmd).trim() !== "") {
                    Quickshell.execDetached(["sh", "-c", String(act.customCmd)]);
                    break;
                }
            }
        }

        var actionToInvoke = identifier;
        if (identifier === "reply") {
            actionToInvoke = "default";
        }

        var invoked = false;
        if (notification && notification.actions) {
            for (var i = 0; i < notification.actions.length; i++) {
                var a = notification.actions[i];
                if (a && a.identifier === actionToInvoke) {
                    try { a.invoke(); invoked = true; } catch(e) {}
                    break;
                }
            }
        }

        if (notification && (!invoked || notification.resident)) {
            try { notification.dismiss(); } catch(e) {}
        }

        if (identifier === "reply" || identifier === "default") {
            focusAppWindow();
        }

        destroy();
    }
}
