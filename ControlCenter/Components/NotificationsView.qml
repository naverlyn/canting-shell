import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Notifications
import ".."
import "../../notifications"
import "../../notifications/SocialApps.js" as SocialApps

Column {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"

    // 1. Live History Array backed by NotificationService (single source of truth)
    readonly property var historyModel: (NotificationService.history || []).map(h => {
        const rawImg = String(h.image || "");
        const imgStr = rawImg.indexOf("image://qsimage/") !== -1 ? "" : rawImg;
        const acts = (h.actions || []).map(a => ({
            label: a.label || "",
            invokeFn: function() { NotificationService.invokeHistoryAction(h.notifId, a.identifier); },
            customCmd: ""
        }));
        return {
            notifId: h.notifId,
            notifAppName: h.displayAppName || h.appName || "Notification",
            notifAppIcon: h.appIcon || "",
            notifImage: imgStr,
            notifSummary: h.summary || "New Notification",
            notifBody: h.displayBody || h.body || "",
            notifActions: acts
        };
    })

    // Notifications grouped by app (newest first); each group keeps its own items/actions
    property var expandedApps: ({})
    readonly property var notifGroups: {
        const order = [];
        const map = {};
        for (const n of historyModel) {
            const key = n.notifAppName;
            if (!map[key]) { map[key] = { appName: key, items: [] }; order.push(key); }
            map[key].items.push(n);
        }
        return order.map(k => map[k]);
    }

    function toggleGroup(app) {
        const copy = Object.assign({}, expandedApps);
        copy[app] = !copy[app];
        expandedApps = copy;
    }

    function dismissNotif(id) {
        NotificationService.dismissHistoryItem(id);
    }

    function dismissGroup(app) {
        NotificationService.dismissHistoryByApp(app);
    }

    function clearAll() {
        NotificationService.clearHistory();
    }

    // Process for running manual shell commands if native actions time out
    Process {
        id: customActionProc
        running: false
    }

    width: parent ? parent.width : 300
    spacing: 12

    // Header Row: Notifications Title + Clear All Button
    RowLayout {
        width: parent.width
        spacing: 8

        Text {
            text: "Notifications"
            color: root.theme.textPrimary
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }
        Rectangle {
            width: 70; height: 26; radius: 6
            color: root.theme.accentPrimary
            opacity: root.historyModel.length > 0 ? 1.0 : 0.45
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: root.theme.bgBase
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.historyModel.length > 0
                cursorShape: root.historyModel.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.clearAll()
            }
        }
    }

    // Notification List (grouped per app, Android-style stacks)
    ListView {
        id: notificationList
        width: parent.width
        height: Math.min(contentHeight, 400)
        implicitHeight: height
        clip: true
        spacing: 12
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
        }
        
        model: root.visible ? root.notifGroups : []
        visible: root.historyModel.length > 0

        delegate: Column {
            id: groupDelegate
            property var group: modelData
            property string appName: modelData.appName
            property var items: modelData.items
            property bool multi: items.length > 1
            property bool expanded: root.expandedApps[appName] === true

            width: ListView.view.width
            spacing: 0

            // Group header (only for stacks): app, count, expand toggle, clear group
            Rectangle {
                width: parent.width
                height: groupDelegate.multi ? 28 : 0
                implicitHeight: height
                visible: groupDelegate.multi
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8

                    Text {
                        text: groupDelegate.appName
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }
                    Rectangle {
                        width: 20; height: 16; radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        Text {
                            anchors.centerIn: parent
                            text: groupDelegate.items.length
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: groupDelegate.expanded ? "Collapse 󰅃" : "Expand 󰅀"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.accentPrimary
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleGroup(groupDelegate.appName)
                        }
                    }
                    Text {
                        text: "Clear"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dismissGroup(groupDelegate.appName)
                        }
                    }
                }
            }

            // Cards: all when expanded, otherwise only the newest
            Column {
                width: parent.width
                spacing: 8

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
                            ? (1.0 - Math.min(0.65, Math.abs(notifDelegate.x) / (width * 0.75)))
                            : 0

                        function triggerDismiss(directionX) {
                            if (isDismissing) return;
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
                            onFinished: {
                                root.dismissNotif(notifDelegate.currentNotifId);
                            }
                        }

                        Rectangle {
                            id: notifDelegate
                            property var notif: notifWrap.modelData
                            property int currentNotifId: notifWrap.modelData.notifId

                            width: parent.width
                            height: notifCardCol.implicitHeight + 24
                            implicitHeight: height
                            radius: 8
                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
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

                            // Left vertical accent line
                            Rectangle {
                                width: 3
                                height: parent.height - 16
                                radius: 2
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.theme.accentPrimary
                            }

                            ColumnLayout {
                                id: notifCardCol
                                z: 1
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                anchors.leftMargin: 16
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    // Left: App Icon / Notification Image
                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 6
                                        color: (appIconImg.status === Image.Ready || notifImg.status === Image.Ready)
                                            ? "transparent"
                                            : Qt.rgba(1, 1, 1, 0.08)
                                        Layout.alignment: Qt.AlignTop
                                        clip: true

                                        IconImage {
                                            id: appIconImg
                                            anchors.centerIn: parent
                                            implicitSize: 28
                                            source: {
                                                let icon = notifDelegate.notif.notifAppIcon;
                                                if (icon && icon !== "") return Quickshell.iconPath(icon, true);
                                                let app = (notifDelegate.notif.notifAppName || "").toLowerCase();
                                                let sum = (notifDelegate.notif.notifSummary || "").toLowerCase();
                                                let body = (notifDelegate.notif.notifBody || "").toLowerCase();
                                                let sApp = SocialApps.detectApp(app, icon, sum, body);
                                                if (sApp && sApp.appIcon) return Quickshell.iconPath(sApp.appIcon, true);
                                                if (app.includes("brave")) return Quickshell.iconPath("brave-desktop", true);
                                                if (app.includes("firefox")) return Quickshell.iconPath("firefox", true);
                                                if (app.includes("spotify")) return Quickshell.iconPath("spotify", true);
                                                return "";
                                            }
                                            visible: status === Image.Ready
                                        }

                                        Image {
                                            id: notifImg
                                            anchors.centerIn: parent
                                            width: 28; height: 28
                                            source: notifDelegate.notif.notifImage ? notifDelegate.notif.notifImage : ""
                                            sourceSize.width: 56
                                            sourceSize.height: 56
                                            cache: false
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectFit
                                            visible: status === Image.Ready && appIconImg.status !== Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                let sApp = SocialApps.detectApp(notifDelegate.notif.notifAppName, notifDelegate.notif.notifAppIcon, notifDelegate.notif.notifSummary, notifDelegate.notif.notifBody);
                                                if (sApp) return sApp.icon;
                                                let name = (notifDelegate.notif.notifAppName + " " + notifDelegate.notif.notifSummary + " " + notifDelegate.notif.notifBody).toLowerCase();
                                                if (name.includes("firefox"))  return "󰈹";
                                                if (name.includes("chrome") || name.includes("brave")) return "󰊯";
                                                if (name.includes("spotify"))  return "󰓇";
                                                if (name.includes("gmail") || name.includes("mail")) return "󰊫";
                                                if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "󰞷";
                                                return "󰂚";
                                            }
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: {
                                                let sApp = SocialApps.detectApp(notifDelegate.notif.notifAppName, notifDelegate.notif.notifAppIcon, notifDelegate.notif.notifSummary, notifDelegate.notif.notifBody);
                                                return sApp ? sApp.color : root.theme.accentPrimary;
                                            }
                                            visible: appIconImg.status !== Image.Ready && notifImg.status !== Image.Ready
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: notifDelegate.notif.notifAppName
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textPrimary
                                            }

                                            Text {
                                                text: "•"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }

                                            Text {
                                                text: "Now"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                                Layout.fillWidth: true
                                            }

                                            // Dismiss single notification button
                                            Rectangle {
                                                width: 20
                                                height: 20
                                                radius: 10
                                                color: closeHover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰅖"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: closeHover.containsMouse 
                                                        ? root.theme.accentRed 
                                                        : root.theme.textMuted
                                                }

                                                MouseArea {
                                                    id: closeHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: notifWrap.triggerDismiss(notifWrap.width + 40)
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            // Summary / Title
                                            Text {
                                                text: notifDelegate.notif.notifSummary
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                                visible: text !== ""
                                            }

                                            // Body Text
                                            Text {
                                                text: notifDelegate.notif.notifBody
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.theme.textSecondary
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                                visible: text !== ""
                                            }
                                        }
                                    }
                                }

                                // Stack badge pill row (+N) if grouped stack & collapsed
                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        Layout.preferredWidth: badgeText.implicitWidth + 10
                                        Layout.preferredHeight: 18
                                        radius: 9
                                        color: Qt.rgba(1, 1, 1, 0.1)

                                        Text {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: "+" + (groupDelegate.items.length - 1)
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleGroup(groupDelegate.appName)
                                        }
                                    }
                                }

                                // Interactive Inline Actions
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    spacing: 6
                                    Layout.topMargin: 4
                                    Layout.bottomMargin: 2
                                    visible: notifDelegate.notif.notifActions && notifDelegate.notif.notifActions.length > 0

                                    Repeater {
                                        model: notifDelegate.notif.notifActions
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            Layout.preferredHeight: 28
                                            height: 28
                                            radius: 14
                                            color: actionHover.containsMouse 
                                                ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                                                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: root.theme.accentPrimary
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            MouseArea {
                                                id: actionHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.invokeFn) {
                                                        try { modelData.invokeFn(); } catch(e) {}
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

                        // Stack "peek" layers directly under the top card while collapsed
                        Item {
                            id: peekLayers
                            y: notifDelegate.height
                            width: parent.width
                            height: (groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary) ? 14 : 0
                            visible: height > 0 || opacity > 0
                            opacity: (groupDelegate.multi && !groupDelegate.expanded && notifWrap.isPrimary) ? 1.0 : 0.0

                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Rectangle {
                                y: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 16
                                height: 8; radius: 6
                                color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                            }
                            Rectangle {
                                y: 8
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 32
                                height: 6; radius: 6
                                color: Qt.rgba(1, 1, 1, 0.03); border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                            }
                            MouseArea {
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
        width: parent.width
        height: root.historyModel.length === 0 ? 160 : 0
        implicitHeight: height
        visible: root.historyModel.length === 0
        
        Text {
            anchors.centerIn: parent
            text: "No Notifications"
            font.family: root.font
            font.pixelSize: 14
            color: root.theme.textMuted
        }
    }
}
