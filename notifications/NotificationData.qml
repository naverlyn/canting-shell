import QtQuick
import Quickshell
import Quickshell.Services.Notifications

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

    function _checkIsWhatsApp(n) {
        var sBody = ((n && n.body) || notificationData.body || "").toLowerCase();
        var sApp = ((n && n.appName) || notificationData.appName || "").toLowerCase();
        var sSum = ((n && n.summary) || notificationData.summary || "").toLowerCase();
        var sIcon = ((n && n.appIcon) || notificationData.appIcon || "").toLowerCase();

        return sBody.indexOf("web.whatsapp.com") !== -1 ||
               sBody.indexOf("whatsapp.com") !== -1 ||
               sSum.indexOf("whatsapp") !== -1 ||
               sApp.indexOf("whatsapp") !== -1 ||
               sIcon.indexOf("whatsapp") !== -1;
    }

    readonly property bool isWhatsApp: _checkIsWhatsApp(notification)

    readonly property string displayAppName: {
        if (isWhatsApp) {
            if (!appName || appName === "Notification" || appName.toLowerCase() === "brave" || appName.toLowerCase() === "chromium") {
                return "WhatsApp Web";
            }
        }
        return appName || "Notification";
    }

    readonly property string displayBody: {
        if (!body) return "";
        if (isWhatsApp) {
            var clean = body.replace(/^https?:\/\/web\.whatsapp\.com\/?\s*\n*/i, "");
            clean = clean.replace(/^web\.whatsapp\.com\/?\s*\n*/i, "");
            clean = clean.trim();
            if (clean.length > 0) return clean;
        }
        return body;
    }

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

        if (_checkIsWhatsApp(notif) && !hasExplicitReply) {
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
        var app = (appName || "").toLowerCase();
        var b = (body || "").toLowerCase();
        if (isWhatsApp || b.indexOf("web.whatsapp.com") !== -1 || b.indexOf("whatsapp.com") !== -1 || app.indexOf("brave") !== -1) {
            Quickshell.execDetached([
                "sh", "-c",
                'if ! hyprctl dispatch focuswindow "title:^(.*WhatsApp.*)$" 2>&1 | grep -q "ok"; then if ! hyprctl dispatch focuswindow "class:^(brave-browser|Brave-browser)$" 2>&1 | grep -q "ok"; then brave "https://web.whatsapp.com" >/dev/null 2>&1 & fi; fi'
            ]);
        } else if (app.indexOf("discord") !== -1 || app.indexOf("vesktop") !== -1) {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(vesktop|discord)$"]);
        } else if (app.indexOf("telegram") !== -1) {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(telegramdesktop|org.telegram.desktop)$"]);
        } else if (app.indexOf("spotify") !== -1) {
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
        if (isWhatsApp) {
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
