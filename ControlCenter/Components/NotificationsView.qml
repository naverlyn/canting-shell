import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Notifications
import ".."

Column {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    // 1. Permanent History Array
    property var historyModel: []

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
        historyModel = historyModel.filter(n => n.notifId !== id);
    }

    function dismissGroup(app) {
        historyModel = historyModel.filter(n => n.notifAppName !== app);
    }

    function clearAll() {
        root.historyModel = [];
        if (notifServer.trackedNotifications) {
            let notifs = notifServer.trackedNotifications.values || notifServer.trackedNotifications;
            if (notifs) {
                for (let i = notifs.length - 1; i >= 0; i--) {
                    if (notifs[i] && notifs[i].dismiss) {
                        notifs[i].dismiss();
                    }
                }
            }
        }
    }

    // 2. Official Notification Daemon
    NotificationServer {
        id: notifServer
        actionsSupported:    true
        bodySupported:       true
        bodyMarkupSupported: true
        imageSupported:      true
        keepOnReload:        false
    }

    // 3. The Invisible Bridge: With a Timer delay to ensure properties are loaded
    Instantiator {
        model: notifServer.trackedNotifications
        delegate: Item {
            id: delegateBridge
            property var notif: modelData
            property int lastProcessedGen: -1

            Connections {
                target: delegateBridge.notif
                ignoreUnknownSignals: true
                function onSummaryChanged() {
                    extractTimer.restart();
                }
                function onBodyChanged() {
                    extractTimer.restart();
                }
            }

            Timer {
                id: extractTimer
                interval: 100 // Wait 100ms for DBus payload (Actions, Summary) to fully bind
                running: true
                onTriggered: {
                    if (!delegateBridge.notif) return;
                    let n = delegateBridge.notif;
                    let gen = n.lastGeneration !== undefined ? n.lastGeneration : 0;
                    if (delegateBridge.lastProcessedGen === gen && gen === 0) {
                        // Already processed this exact generation
                    }
                    delegateBridge.lastProcessedGen = gen;
                    
                    let baseId = n.id !== undefined ? n.id : Math.random();
                    let nId = gen > 0 ? (baseId + "_" + gen) : baseId;
                    let arr = root.historyModel;
                    
                    for (let i = 0; i < arr.length; i++) {
                        if (arr[i].notifId === nId) return; 
                    }
                    
                    let extractedActions = [];
                    let acts = n.actions || [];
                    
                    // Safely iterate the native DBus actions using a closure
                    for (let i = 0; i < acts.length; i++) {
                        (function(actionObj) {
                            let lbl = actionObj ? (actionObj.text || actionObj.label || "") : "";
                            if (actionObj && lbl && actionObj.identifier !== "default") {
                                extractedActions.push({
                                    label: lbl + "",
                                    invokeFn: function() { try { actionObj.invoke(); } catch(e) {} },
                                    customCmd: ""
                                });
                            }
                        })(acts[i]);
                    }
                    
                    let summaryStr = (n.summary || "New Notification") + "";
                    let bodyStr = (n.body || "") + "";

                    // WhatsApp Web
                    let isWA = bodyStr.indexOf("web.whatsapp.com") !== -1 ||
                               bodyStr.indexOf("whatsapp.com") !== -1 ||
                               summaryStr.toLowerCase().indexOf("whatsapp") !== -1 ||
                               (n.appName || "").toLowerCase().indexOf("whatsapp") !== -1;

                    if (isWA) {
                        let clean = bodyStr.replace(/^https?:\/\/web\.whatsapp\.com\/?\s*\n*/i, "");
                        clean = clean.replace(/^web\.whatsapp\.com\/?\s*\n*/i, "");
                        clean = clean.trim();
                        if (clean.length > 0) bodyStr = clean;

                        let defaultAct = null;
                        for (let k = 0; k < acts.length; k++) {
                            if (acts[k] && (acts[k].identifier === "default" || acts[k].id === "default")) {
                                defaultAct = acts[k];
                                break;
                            }
                        }

                        let focusCmd = 'if ! hyprctl dispatch focuswindow "title:^(.*WhatsApp.*)$" 2>&1 | grep -q "ok"; then if ! hyprctl dispatch focuswindow "class:^(brave-browser|Brave-browser)$" 2>&1 | grep -q "ok"; then brave "https://web.whatsapp.com" >/dev/null 2>&1 & fi; fi';

                        extractedActions.unshift({
                            label: "Reply",
                            invokeFn: function() {
                                if (defaultAct && defaultAct.invoke) {
                                    try { defaultAct.invoke(); } catch(e) {}
                                }
                                Quickshell.execDetached(["sh", "-c", focusCmd]);
                            },
                            customCmd: ""
                        });
                    }

                    // Swappy screenshots
                    if (bodyStr.indexOf("Swappy") !== -1) {
                        let shotPath = "/tmp/qs-shot-" + Date.now() + "-" + nId + ".png";
                        Quickshell.execDetached(["sh", "-c", "wl-paste --type image/png > '" + shotPath + "'"]);
                        extractedActions = [
                            { label: "Open", invokeFn: null, customCmd: "swappy -f '" + shotPath + "'" },
                            { label: "Delete", invokeFn: null, customCmd: "rm -f '" + shotPath + "'" }
                        ];
                    } else if (/screenshot/i.test(summaryStr) && /saved/i.test(bodyStr) && !/not saved/i.test(bodyStr)) {
                        // Regular grim screenshots
                        let ts = Date.now() / 1000;
                        let findCmd = "d=\"$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots\"; " +
                            "f=\"$(find \"$d\" -maxdepth 1 -type f -name '*.png' -printf '%T@ %p\\n' | " +
                            "awk -v t=" + ts + " '{x=$1-t; if (x<0) x=-x; if (m==\"\" || x<m) {m=x; p=$0}} END {sub(/^[^ ]+ /, \"\", p); print p}')\"; ";
                        extractedActions = [
                            { label: "Open", invokeFn: null, customCmd: findCmd + "[ -n \"$f\" ] && xdg-open \"$f\"" },
                            { label: "Delete", invokeFn: null, customCmd: findCmd + "[ -n \"$f\" ] && rm -f \"$f\"" }
                        ];
                    } else if (extractedActions.length === 0) {
                        // FALLBACK: Provide default Accept and Dismiss buttons
                        extractedActions = [
                            {
                                label: "Accept",
                                invokeFn: (acts && acts.length > 0 && acts[0].invoke)
                                    ? function() { try { acts[0].invoke(); } catch(e) {} }
                                    : null,
                                customCmd: ""
                            },
                            {
                                label: "Dismiss",
                                invokeFn: null,
                                customCmd: ""
                            }
                        ];
                    }

                    let imgStr = (n.image || "") + "";
                    if (imgStr.indexOf("image://qsimage/") !== -1) {
                        imgStr = "";
                    }

                    // Deep copy strings
                    let newItem = {
                        notifId: nId,
                        notifAppName: (isWA ? "WhatsApp Web" : (n.appName || "Notification")) + "",
                        notifAppIcon: (n.appIcon || "") + "",
                        notifImage: imgStr,
                        notifSummary: summaryStr,
                        notifBody: bodyStr,
                        notifActions: extractedActions
                    };

                    root.historyModel = [newItem].concat(arr).slice(0, 50);
                }
            }
        }
    }

    // Process for running manual shell commands if native actions time out
    Process {
        id: customActionProc
        running: false
    }

    width: parent ? parent.width : 300
    spacing: 12

    // Clear All Button Row
    RowLayout {
        width: parent.width
        Item { Layout.fillWidth: true } 
        Rectangle {
            width: 70; height: 26; radius: 4
            color: root.theme.accentPrimary
            Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: root.theme.bgBase
                font.family: root.font
                font.pixelSize: 11
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
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
                                                if (app.includes("whatsapp") || sum.includes("whatsapp") || body.includes("whatsapp"))
                                                    return Quickshell.iconPath("whatsapp", true);
                                                if (app.includes("brave")) return Quickshell.iconPath("brave-desktop", true);
                                                if (app.includes("firefox")) return Quickshell.iconPath("firefox", true);
                                                if (app.includes("discord")) return Quickshell.iconPath("discord", true);
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
                                            fillMode: Image.PreserveAspectFit
                                            visible: status === Image.Ready && appIconImg.status !== Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                let name = (notifDelegate.notif.notifAppName + " " + notifDelegate.notif.notifSummary + " " + notifDelegate.notif.notifBody).toLowerCase();
                                                if (name.includes("whatsapp")) return "󰖣";
                                                if (name.includes("discord"))  return "󰙯";
                                                if (name.includes("firefox"))  return "󰈹";
                                                if (name.includes("chrome") || name.includes("brave")) return "󰊯";
                                                if (name.includes("spotify"))  return "󰓇";
                                                if (name.includes("telegram")) return "󰓓";
                                                if (name.includes("gmail") || name.includes("mail")) return "󰊫";
                                                if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "󰞷";
                                                return "󰂚";
                                            }
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: root.theme.accentPrimary
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
