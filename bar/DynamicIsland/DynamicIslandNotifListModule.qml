import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/SocialApps.js" as SocialApps
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  readonly property var historyList: NotificationService.history || []
  readonly property bool isDnd: NotificationService.doNotDisturb

  property var expandedGroups: ({})
  property string expandedNotifId: ""
  property bool clearingAll: false
  property string clearingGroup: ""

  Timer {
    id: clearAllTimer
    interval: 210
    repeat: false
    onTriggered: {
      NotificationService.clearHistory();
      root.clearingAll = false;
    }
  }

  Timer {
    id: clearGroupTimer
    interval: 210
    repeat: false
    onTriggered: {
      const grp = root.clearingGroup;
      root.clearingGroup = "";
      if (grp) NotificationService.dismissHistoryByApp(grp);
    }
  }

  function isGroupExpanded(appKey) {
    return expandedGroups && expandedGroups[appKey] === true;
  }

  function toggleGroup(appKey) {
    const copy = Object.assign({}, expandedGroups || {});
    copy[appKey] = !copy[appKey];
    expandedGroups = copy;
  }

  function toggleExpanded(nid) {
    const key = String(nid || "");
    expandedNotifId = (expandedNotifId === key) ? "" : key;
  }

  // Group notifications by app (newest first) while preserving all original fields & actions
  readonly property var notifGroups: {
    const raw = (root.historyList || []).slice(0, 20);
    const order = [];
    const map = {};
    for (let i = 0; i < raw.length; i++) {
      const h = raw[i];
      if (!h) continue;
      const appKey = SocialApps.formatAppName(h.displayAppName || h.appName || "", h.socialApp);
      if (!map[appKey]) {
        map[appKey] = { appName: appKey, items: [] };
        order.push(appKey);
      }
      map[appKey].items.push(h);
    }
    return order.map(k => map[k]);
  }

  function resolveDesktopIconByAppName(app) {
    const lower = String(app || "").toLowerCase().trim();
    if (lower === "" || lower === "notify-send" || lower === "notification") return "";
    const entries = (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values)
      ? DesktopEntries.applications.values
      : [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (!e || !e.icon) continue;
      const eName = String(e.name || "").toLowerCase();
      const eId = String(e.id || "").toLowerCase();
      const eCls = String(e.startupClass || "").toLowerCase();
      if (eName === lower || eId === lower || eCls === lower || (lower.length >= 3 && (eName.indexOf(lower) !== -1 || eId.indexOf(lower) !== -1))) {
        const ep = Quickshell.iconPath(e.icon, true);
        if (ep) return ep;
      }
    }
    if (lower.indexOf("brave") !== -1) {
      const bp = Quickshell.iconPath("brave-desktop", true) || Quickshell.iconPath("brave-browser", true);
      if (bp) return bp;
    }
    return Quickshell.iconPath(lower.replace(/\s+/g, "-"), true) || Quickshell.iconPath(lower, true) || "";
  }

  function resolveIconInfo(item) {
    if (!item) return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: root.accent };
    const rawIcon = String(item.appIcon || "").trim();
    const app = String(item.displayAppName || item.appName || "").trim();
    const sum = String(item.summary || "");
    const body = String(item.displayBody || item.body || "");

    // 1. Check SocialApps first so WhatsApp/Discord/Telegram Web show their proper icon instead of browser
    const sApp = item.socialApp || SocialApps.detectApp(item.appName || app, rawIcon, sum, body);
    if (sApp) {
      const sPath = sApp.appIcon ? (Quickshell.iconPath(sApp.appIcon, true) || "") : "";
      const isFile = sPath.startsWith("file://") || sPath.startsWith("/");
      return {
        themeSrc: (!isFile && sPath !== "") ? sPath : "",
        fileSrc: isFile ? (sPath.startsWith("/") ? ("file://" + sPath) : sPath) : "",
        fallbackThemeSrc: "",
        glyph: sApp.icon || "",
        color: sApp.color || root.accent
      };
    }

    const desktopFallback = resolveDesktopIconByAppName(item.appName || app);
    const fbIsFile = desktopFallback.startsWith("file://") || desktopFallback.startsWith("/");
    const fbTheme = (!fbIsFile && desktopFallback !== "") ? desktopFallback : "";
    const fbFile = fbIsFile ? (desktopFallback.startsWith("/") ? ("file://" + desktopFallback) : desktopFallback) : "";

    // 2. Direct appIcon (validate theme icons & route file paths to Image so IconImage never draws a pink checkerboard)
    if (rawIcon !== "") {
      const isVolatileTmp = rawIcon.indexOf("/tmp/") !== -1 || rawIcon.indexOf("scoped_dir") !== -1;
      if (isVolatileTmp && desktopFallback !== "") {
        return { themeSrc: fbTheme, fileSrc: fbFile, fallbackThemeSrc: "", glyph: "", color: root.accent };
      }
      if (rawIcon.startsWith("image://icon//")) {
        return { themeSrc: "", fileSrc: "file://" + rawIcon.slice(13), fallbackThemeSrc: fbTheme, glyph: "", color: root.accent };
      }
      if (rawIcon.startsWith("image://icon/")) {
        const iconName = rawIcon.slice(13);
        const validated = Quickshell.iconPath(iconName, true) || "";
        if (validated !== "") {
          const vFile = validated.startsWith("file://") || validated.startsWith("/");
          return {
            themeSrc: !vFile ? validated : "",
            fileSrc: vFile ? (validated.startsWith("/") ? ("file://" + validated) : validated) : "",
            fallbackThemeSrc: fbTheme,
            glyph: "",
            color: root.accent
          };
        }
      } else if (rawIcon.startsWith("file://")) {
        return { themeSrc: "", fileSrc: rawIcon, fallbackThemeSrc: fbTheme, glyph: "", color: root.accent };
      } else if (rawIcon.startsWith("/")) {
        return { themeSrc: "", fileSrc: "file://" + rawIcon, fallbackThemeSrc: fbTheme, glyph: "", color: root.accent };
      } else if (!rawIcon.startsWith("image://")) {
        const validated = Quickshell.iconPath(rawIcon, true) || "";
        if (validated !== "") {
          const vFile = validated.startsWith("file://") || validated.startsWith("/");
          return {
            themeSrc: !vFile ? validated : "",
            fileSrc: vFile ? (validated.startsWith("/") ? ("file://" + validated) : validated) : "",
            fallbackThemeSrc: fbTheme,
            glyph: "",
            color: root.accent
          };
        }
      }
    }

    // 3. Permanent desktop icon by appName
    if (desktopFallback !== "") {
      return { themeSrc: fbTheme, fileSrc: fbFile, fallbackThemeSrc: "", glyph: "", color: root.accent };
    }

    // 4. No icon — hide icon slot cleanly instead of showing a placeholder box
    return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: root.accent };
  }

  function buildButtonsForItem(item) {
    if (!item) return [];
    const out = [];
    const rawActs = item.actions;
    const count = (rawActs && rawActs.length !== undefined) ? rawActs.length : 0;
    for (let i = 0; i < count && out.length < 3; i++) {
      const a = rawActs[i];
      if (!a) continue;
      const lbl = String(a.label !== undefined ? a.label : (a.text !== undefined ? a.text : "")).trim();
      if (!lbl) continue;
      out.push({
        kind: "action",
        label: lbl,
        identifier: String(a.identifier || ""),
        customCmd: String(a.customCmd || ""),
        danger: lbl.toLowerCase() === "delete"
      });
    }
    if (out.length === 0) {
      const app = String(item.appName || "").toLowerCase().trim();
      if (item.socialApp || (app !== "" && app !== "notify-send" && app !== "notification")) {
        out.push({ kind: "focus", label: "Open", identifier: "open", customCmd: "", danger: false });
      }
      out.push({ kind: "dismiss", label: "Dismiss", identifier: "dismiss", customCmd: "", danger: true });
    }
    return out;
  }

  implicitHeight: notifCol.implicitHeight
  height: implicitHeight

  ColumnLayout {
    id: notifCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 8

    // Header bar: count + DND toggle + Clear All
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Notifications" + (root.historyList.length > 0 ? (" (" + root.historyList.length + ")") : "")
        font.family: root.font
        font.pixelSize: 12
        font.bold: true
        color: root.theme.textPrimary
        Layout.fillWidth: true
      }

      // DND Pill
      Rectangle {
        Layout.preferredWidth: dndRow.implicitWidth + 16
        Layout.preferredHeight: 24
        radius: 12
        color: root.isDnd
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, dndHover.hovered ? 0.30 : 0.22)
          : (dndHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.13) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06))
        border.color: root.isDnd
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
          : (dndHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.16) : "transparent")
        border.width: 1
        scale: dndMouse.pressed ? 0.91 : (dndHover.hovered ? 1.04 : 1.0)

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: dndHover }

        Row {
          id: dndRow
          anchors.centerIn: parent
          spacing: 5
          Text {
            id: dndIcon
            text: root.isDnd ? "󰂛" : "󰂚"
            font.family: root.font
            font.pixelSize: 11
            color: root.isDnd ? root.accent : (dndHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
            Behavior on color { ColorAnimation { duration: 140 } }

            SequentialAnimation {
              id: dndIconPop
              NumberAnimation { target: dndIcon; property: "scale"; to: 1.28; duration: 90; easing.type: Easing.OutQuad }
              NumberAnimation { target: dndIcon; property: "scale"; to: 1.0; duration: 160; easing.type: Easing.OutBack }
            }
          }
          Text {
            text: root.isDnd ? "DND On" : "DND"
            font.family: root.font
            font.pixelSize: 10
            font.bold: root.isDnd
            color: root.isDnd ? root.accent : (dndHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
            Behavior on color { ColorAnimation { duration: 140 } }
          }
        }

        MouseArea {
          id: dndMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
            dndIconPop.restart();
          }
        }
      }

      // Clear All button
      Rectangle {
        readonly property bool hasItems: root.historyList.length > 0
        visible: opacity > 0.01
        opacity: hasItems ? 1.0 : 0.0
        Layout.preferredWidth: hasItems ? (clearTxt.implicitWidth + 16) : 0
        Layout.preferredHeight: 24
        radius: 12
        color: clearHover.hovered
          ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.24)
          : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: clearHover.hovered
          ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.45)
          : "transparent"
        border.width: 1
        scale: clearMouse.pressed ? 0.91 : (clearHover.hovered ? 1.04 : 1.0)
        clip: true

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: clearHover }

        Text {
          id: clearTxt
          anchors.centerIn: parent
          text: "Clear"
          font.family: root.font
          font.pixelSize: 10
          font.bold: true
          color: clearHover.hovered ? root.theme.accentRed : root.theme.textSecondary
          Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
          id: clearMouse
          anchors.fill: parent
          enabled: parent.hasItems && !root.clearingAll
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.clearingAll = true;
            clearAllTimer.restart();
          }
        }
      }
    }

    // Empty State
    Rectangle {
      visible: root.historyList.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: 76
      radius: 10
      color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)

      Text {
        anchors.centerIn: parent
        text: root.isDnd ? "Do Not Disturb is active" : "All caught up — no notifications"
        font.family: root.font
        font.pixelSize: 11
        color: root.theme.textSecondary
      }
    }

    // Grouped Notification Stack List (click stacked card to expand, click card to reveal actions)
    Flickable {
      id: histFlick
      visible: root.historyList.length > 0
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(250, histCol.implicitHeight)
      contentHeight: histCol.implicitHeight
      contentWidth: width
      clip: true
      interactive: contentHeight > height + 2
      boundsBehavior: Flickable.StopAtBounds

      Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }

      ScrollBar.vertical: ScrollBar {
        policy: histFlick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        width: 3
        contentItem: Rectangle {
          radius: 1.5
          color: root.theme.bgBorder
        }
      }

      ColumnLayout {
        id: histCol
        width: histFlick.interactive ? (histFlick.width - 6) : histFlick.width
        spacing: 8

        Repeater {
          model: root.notifGroups
          delegate: ColumnLayout {
            id: groupBlock
            required property var modelData
            required property int index

            readonly property string appName: modelData.appName
            readonly property var items: modelData.items || []
            readonly property bool isMulti: items.length > 1
            readonly property bool isGroupOpen: isMulti && root.isGroupExpanded(appName)
            readonly property bool isCollapsedStack: isMulti && !isGroupOpen

            Layout.fillWidth: true
            spacing: 0

            // Minimal inline Collapse / Clear bar shown ONLY when a multi-card stack is expanded
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: groupBlock.isGroupOpen ? groupHeaderRow.implicitHeight : 0
              Layout.bottomMargin: groupBlock.isGroupOpen ? 6 : 0
              opacity: groupBlock.isGroupOpen ? 1.0 : 0.0
              clip: true

              Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              Behavior on Layout.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

              RowLayout {
                id: groupHeaderRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 6

                Text {
                  text: groupBlock.appName + " (" + groupBlock.items.length + ")"
                  font.family: root.font
                  font.pixelSize: 10
                  font.bold: true
                  color: root.theme.textSecondary
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Rectangle {
                  Layout.preferredWidth: colTxt.implicitWidth + 12
                  Layout.preferredHeight: 20
                  radius: 10
                  color: colHov.hovered ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16) : "transparent"
                  scale: colMs.pressed ? 0.92 : 1.0
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on scale { NumberAnimation { duration: 100 } }
                  HoverHandler { id: colHov }

                  Text {
                    id: colTxt
                    anchors.centerIn: parent
                    text: "Collapse"
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.accent
                  }

                  MouseArea {
                    id: colMs
                    anchors.fill: parent
                    enabled: groupBlock.isGroupOpen
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleGroup(groupBlock.appName)
                  }
                }

                Rectangle {
                  Layout.preferredWidth: grpClrTxt.implicitWidth + 12
                  Layout.preferredHeight: 20
                  radius: 10
                  color: grpClrHov.hovered ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) : "transparent"
                  scale: grpClrMs.pressed ? 0.92 : 1.0
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on scale { NumberAnimation { duration: 100 } }
                  HoverHandler { id: grpClrHov }

                  Text {
                    id: grpClrTxt
                    anchors.centerIn: parent
                    text: "Clear"
                    font.family: root.font
                    font.pixelSize: 10
                    color: grpClrHov.hovered ? root.theme.accentRed : root.theme.textMuted
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }

                  MouseArea {
                    id: grpClrMs
                    anchors.fill: parent
                    enabled: groupBlock.isGroupOpen && root.clearingGroup === ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.clearingGroup = groupBlock.appName;
                      clearGroupTimer.restart();
                    }
                  }
                }
              }
            }

            // Card(s) in this group (smooth slide/fade expand & collapse)
            Repeater {
              model: groupBlock.items
              delegate: Item {
                id: cardSlot
                required property var modelData
                required property int index

                readonly property bool isCardVisible: !groupBlock.isCollapsedStack || index === 0
                readonly property bool showPeek: groupBlock.isCollapsedStack && index === 0
                property bool dismissed: false
                property real revealFrac: (isCardVisible && !dismissed) ? 1.0 : 0.0
                Behavior on revealFrac { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Layout.fillWidth: true
                Layout.topMargin: (index > 0 && isCardVisible && !dismissed) ? Math.round(6 * revealFrac) : 0
                Layout.preferredHeight: Math.round((histItem.height + (showPeek ? 6 : 0)) * revealFrac)
                opacity: revealFrac
                clip: true

                // Subtle stacked card peek strictly below histItem (never bleeds through translucent card)
                Item {
                  visible: cardSlot.showPeek
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  y: histItem.height
                  height: 6
                  clip: true

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    y: -8
                    height: 14
                    radius: 9
                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.035)
                    border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
                    border.width: 1
                  }
                }

                Rectangle {
                  id: histItem
                  readonly property string nid: (cardSlot.modelData && cardSlot.modelData.notifId) ? String(cardSlot.modelData.notifId) : ("hist_" + groupBlock.index + "_" + cardSlot.index)
                  readonly property bool isExpanded: !groupBlock.isCollapsedStack && root.expandedNotifId === nid
                  readonly property var iconInfo: root.resolveIconInfo(cardSlot.modelData)
                  readonly property var buttons: root.buildButtonsForItem(cardSlot.modelData)

                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  height: itemCol.implicitHeight + 16
                  radius: 10
                  opacity: 0.0
                  color: itemHover.hovered
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.09)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.045)
                  border.color: (cardSlot.modelData && cardSlot.modelData.urgency === NotificationUrgency.Critical)
                    ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.45)
                    : (isExpanded ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.38) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.07))
                  border.width: 1
                  clip: true

                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }
                  Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutQuart } }

                  transform: [
                    Translate { id: histSlide; x: 0; y: 10 },
                    Scale { id: histScale; origin.x: histItem.width / 2; origin.y: histItem.height / 2; xScale: 0.97; yScale: 0.97 }
                  ]

                  SequentialAnimation {
                    id: histEnterAnim
                    PauseAnimation { duration: Math.min(140, cardSlot.index * 28) }
                    ParallelAnimation {
                      NumberAnimation { target: histItem; property: "opacity"; from: 0.0; to: 1.0; duration: 190; easing.type: Easing.OutCubic }
                      NumberAnimation { target: histSlide; property: "y"; from: 10; to: 0; duration: 230; easing.type: Easing.OutQuart }
                      NumberAnimation { target: histScale; property: "xScale"; from: 0.97; to: 1.0; duration: 230; easing.type: Easing.OutQuart }
                      NumberAnimation { target: histScale; property: "yScale"; from: 0.97; to: 1.0; duration: 230; easing.type: Easing.OutQuart }
                    }
                  }
                  Component.onCompleted: histEnterAnim.start()

                  SequentialAnimation {
                    id: histDismissAnim
                    ParallelAnimation {
                      NumberAnimation { target: histSlide; property: "x"; to: histItem.width + 28; duration: 170; easing.type: Easing.InCubic }
                      NumberAnimation { target: histItem; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.OutCubic }
                    }
                    ScriptAction { script: cardSlot.dismissed = true }
                    PauseAnimation { duration: 150 }
                    onFinished: NotificationService.dismissHistoryItem(histItem.nid)
                  }

                  readonly property bool isClearing: root.clearingAll || root.clearingGroup === groupBlock.appName
                  onIsClearingChanged: {
                    if (isClearing && !histClearAnim.running) {
                      histClearAnim.restart();
                    }
                  }

                  SequentialAnimation {
                    id: histClearAnim
                    PauseAnimation { duration: Math.min(70, (groupBlock.index + cardSlot.index) * 20) }
                    ParallelAnimation {
                      NumberAnimation { target: histSlide; property: "x"; to: histItem.width + 28; duration: 160; easing.type: Easing.OutCubic }
                      NumberAnimation { target: histItem; property: "opacity"; to: 0.0; duration: 145; easing.type: Easing.OutCubic }
                    }
                  }

                  HoverHandler { id: itemHover }

                  ColumnLayout {
                    id: itemCol
                    anchors {
                      left: parent.left
                      right: parent.right
                      top: parent.top
                      leftMargin: 10
                      rightMargin: 8
                      topMargin: 8
                    }
                    spacing: 0

                    // Clickable card header + body
                    Item {
                      Layout.fillWidth: true
                      Layout.preferredHeight: mainRow.implicitHeight

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (groupBlock.isCollapsedStack) {
                            root.toggleGroup(groupBlock.appName);
                          } else {
                            root.toggleExpanded(histItem.nid);
                          }
                        }
                      }

                      RowLayout {
                        id: mainRow
                        anchors.fill: parent
                        spacing: 10

                        // Profile Picture / Preview Image FIRST (persisted via cachedImage), then App Icon / Social Badge / Wave Glyph
                        Item {
                          id: histIconSlot
                          readonly property string rawImg: cardSlot.modelData ? String(cardSlot.modelData.image || "") : ""
                          readonly property string cachedImg: cardSlot.modelData ? String(cardSlot.modelData.cachedImage || "") : ""
                          readonly property string liveImg: (rawImg !== "" && rawImg !== "__sample__" && rawImg.indexOf("image://qsimage/") === -1)
                            ? (rawImg.startsWith("image://icon//") ? ("file://" + rawImg.slice(13)) : (rawImg.startsWith("/") ? ("file://" + rawImg) : rawImg))
                            : ""
                          readonly property bool hasAvatar: avatarCachedImg.status === Image.Ready || avatarLiveImg.status === Image.Ready
                          readonly property bool hasThemeIcon: !hasAvatar && (appIconImg.status === Image.Ready || fallbackIconImg.status === Image.Ready)
                          readonly property bool hasFileIcon: !hasAvatar && !hasThemeIcon && fileIconImg.status === Image.Ready
                          readonly property bool hasGlyphFallback: !hasAvatar && !hasThemeIcon && !hasFileIcon && histItem.iconInfo.glyph !== ""
                          readonly property bool hasAnyVisual: hasAvatar || hasThemeIcon || hasFileIcon || hasGlyphFallback
                          readonly property bool isSocial: Boolean(cardSlot.modelData && cardSlot.modelData.socialApp)

                          visible: hasAnyVisual
                          Layout.preferredWidth: hasAnyVisual ? (hasAvatar ? 34 : 30) : 0
                          Layout.preferredHeight: hasAnyVisual ? (hasAvatar ? 34 : 30) : 0
                          Layout.alignment: Qt.AlignVCenter

                          // Rounded mask for contact profile pictures
                          Rectangle {
                            id: avatarMask
                            anchors.fill: parent
                            radius: histIconSlot.isSocial ? (width / 2) : 9
                            antialiasing: true
                            visible: false
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.max(2, Math.round(width * 2)), Math.max(2, Math.round(height * 2)))
                          }

                          // Actual Profile Picture / Thumbnail (cached copy survives Chromium temp cleanup)
                          Item {
                            anchors.fill: parent
                            visible: histIconSlot.cachedImg !== "" || histIconSlot.liveImg !== ""
                            opacity: histIconSlot.hasAvatar ? 1.0 : 0.0
                            layer.enabled: histIconSlot.hasAvatar
                            layer.smooth: true
                            layer.effect: MultiEffect {
                              maskEnabled: true
                              maskSource: avatarMask
                              maskThresholdMin: 0.35
                              maskSpreadAtMin: 0.3
                            }

                            Image {
                              id: avatarCachedImg
                              anchors.fill: parent
                              source: histIconSlot.cachedImg
                              sourceSize.width: 72
                              sourceSize.height: 72
                              fillMode: Image.PreserveAspectCrop
                              asynchronous: true
                              cache: false
                              visible: histIconSlot.cachedImg !== "" && status === Image.Ready
                            }

                            Image {
                              id: avatarLiveImg
                              anchors.fill: parent
                              source: (avatarCachedImg.status !== Image.Ready) ? histIconSlot.liveImg : ""
                              sourceSize.width: 72
                              sourceSize.height: 72
                              fillMode: Image.PreserveAspectCrop
                              asynchronous: true
                              cache: false
                              visible: histIconSlot.liveImg !== "" && status === Image.Ready && avatarCachedImg.status !== Image.Ready
                            }
                          }

                          // Subtle tiny social app corner badge on top of contact profile picture
                          Rectangle {
                            visible: histIconSlot.hasAvatar && histIconSlot.isSocial && histItem.iconInfo.glyph !== ""
                            width: 14
                            height: 14
                            radius: 7
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -2
                            anchors.bottomMargin: -2
                            color: root.theme.bgBase
                            border.color: histItem.iconInfo.color
                            border.width: 1

                            Text {
                              anchors.centerIn: parent
                              text: histItem.iconInfo.glyph
                              font.family: root.font
                              font.pixelSize: 8
                              color: histItem.iconInfo.color
                            }
                          }

                          IconImage {
                            id: appIconImg
                            anchors.centerIn: parent
                            implicitSize: 28
                            source: !histIconSlot.hasAvatar ? histItem.iconInfo.themeSrc : ""
                            visible: !histIconSlot.hasAvatar && histItem.iconInfo.themeSrc !== "" && status === Image.Ready
                          }

                          Image {
                            id: fileIconImg
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            source: !histIconSlot.hasAvatar ? histItem.iconInfo.fileSrc : ""
                            sourceSize.width: 56
                            sourceSize.height: 56
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            visible: !histIconSlot.hasAvatar && histItem.iconInfo.fileSrc !== "" && status === Image.Ready && appIconImg.status !== Image.Ready
                          }

                          IconImage {
                            id: fallbackIconImg
                            anchors.centerIn: parent
                            implicitSize: 28
                            source: (!histIconSlot.hasAvatar && appIconImg.status !== Image.Ready && fileIconImg.status !== Image.Ready && histItem.iconInfo.fallbackThemeSrc) ? histItem.iconInfo.fallbackThemeSrc : ""
                            visible: !histIconSlot.hasAvatar && source !== "" && status === Image.Ready && appIconImg.status !== Image.Ready && fileIconImg.status !== Image.Ready
                          }

                          Rectangle {
                            anchors.fill: parent
                            radius: 9
                            visible: histIconSlot.hasGlyphFallback
                            color: Qt.rgba(histItem.iconInfo.color.r, histItem.iconInfo.color.g, histItem.iconInfo.color.b, 0.14)
                            border.color: Qt.rgba(histItem.iconInfo.color.r, histItem.iconInfo.color.g, histItem.iconInfo.color.b, 0.30)
                            border.width: 1
                            Text {
                              anchors.centerIn: parent
                              text: histItem.iconInfo.glyph
                              font.family: root.font
                              font.pixelSize: 15
                              color: histItem.iconInfo.color
                            }
                          }
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1

                          RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                              text: cardSlot.modelData ? SocialApps.formatAppName(cardSlot.modelData.displayAppName || cardSlot.modelData.appName || "", cardSlot.modelData.socialApp) : ""
                              font.family: root.font
                              font.pixelSize: 10
                              font.bold: true
                              color: histItem.iconInfo.glyph !== "" ? histItem.iconInfo.color : root.accent
                              elide: Text.ElideRight
                            }

                            // Compact stack count pill (e.g. "2") when grouped & collapsed
                            Rectangle {
                              visible: groupBlock.isCollapsedStack
                              Layout.preferredWidth: Math.max(16, grpCountTxt.implicitWidth + 8)
                              Layout.preferredHeight: 15
                              radius: 7.5
                              color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                              border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
                              border.width: 1
                              Text {
                                id: grpCountTxt
                                anchors.centerIn: parent
                                text: String(groupBlock.items.length)
                                font.family: root.font
                                font.pixelSize: 9
                                font.bold: true
                                color: root.accent
                              }
                            }

                            Item { Layout.fillWidth: true }
                            Text {
                              text: cardSlot.modelData && cardSlot.modelData.timeStr ? String(cardSlot.modelData.timeStr) : ""
                              font.family: root.font
                              font.pixelSize: 9
                              color: root.theme.textMuted
                            }
                          }

                          Text {
                            text: cardSlot.modelData ? (cardSlot.modelData.summary || "") : ""
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                          }

                          Text {
                            visible: text !== ""
                            text: cardSlot.modelData ? (cardSlot.modelData.displayBody || cardSlot.modelData.body || "") : ""
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            maximumLineCount: histItem.isExpanded ? 6 : 2
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                          }
                        }

                        // Quick dismiss X on hover (dismisses group if collapsed stack, single item if expanded)
                        Rectangle {
                          opacity: itemHover.hovered ? 1.0 : 0.0
                          visible: opacity > 0.01
                          Layout.preferredWidth: 20
                          Layout.preferredHeight: 20
                          Layout.alignment: Qt.AlignTop
                          radius: 10
                          color: rmHover.hovered ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.25) : "transparent"
                          scale: rmMouse.pressed ? 0.85 : (rmHover.hovered ? 1.08 : 1.0)
                          Behavior on opacity { NumberAnimation { duration: 120 } }
                          Behavior on color { ColorAnimation { duration: 120 } }
                          Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                          HoverHandler { id: rmHover }
                          Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: root.font
                            font.pixelSize: 9
                            color: rmHover.hovered ? root.theme.accentRed : root.theme.textMuted
                            Behavior on color { ColorAnimation { duration: 120 } }
                          }
                          MouseArea {
                            id: rmMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (groupBlock.isCollapsedStack) {
                                NotificationService.dismissHistoryByApp(groupBlock.appName);
                              } else {
                                histDismissAnim.start();
                              }
                            }
                          }
                        }
                      }
                    }

                    // Click-to-reveal Action Buttons Drawer (Open, Delete, Reply, Settings, etc.)
                    Item {
                      Layout.fillWidth: true
                      Layout.preferredHeight: histItem.isExpanded ? 36 : 0
                      opacity: histItem.isExpanded ? 1.0 : 0.0
                      clip: true

                      Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                      RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 28
                        spacing: 6
                        transform: Translate {
                          y: histItem.isExpanded ? 0 : -6
                          Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                        }

                        Repeater {
                          model: histItem.buttons
                          delegate: Rectangle {
                            id: histActBtn
                            required property var modelData
                            readonly property bool isDanger: Boolean(modelData && modelData.danger)
                            readonly property color btnAccent: isDanger ? root.theme.accentRed : root.accent

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 28
                            radius: 14
                            color: actHov.hovered
                              ? Qt.rgba(btnAccent.r, btnAccent.g, btnAccent.b, 0.22)
                              : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.07)
                            border.color: actHov.hovered
                              ? Qt.rgba(btnAccent.r, btnAccent.g, btnAccent.b, 0.45)
                              : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.09)
                            border.width: 1
                            scale: actMs.pressed ? 0.93 : (actHov.hovered ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                            HoverHandler { id: actHov }

                            Text {
                              anchors.centerIn: parent
                              text: histActBtn.modelData ? histActBtn.modelData.label : ""
                              font.family: root.font
                              font.pixelSize: 11
                              font.bold: true
                              color: actHov.hovered
                                ? (histActBtn.isDanger ? root.theme.accentRed : root.theme.textPrimary)
                                : (histActBtn.isDanger ? root.theme.textSecondary : root.accent)
                              Behavior on color { ColorAnimation { duration: 130 } }
                              elide: Text.ElideRight
                              width: Math.min(implicitWidth, parent.width - 14)
                              horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                              id: actMs
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: {
                                if (!histActBtn.modelData) return;
                                if (histActBtn.modelData.kind === "dismiss") {
                                  histDismissAnim.start();
                                  return;
                                }
                                if (histActBtn.modelData.kind === "focus") {
                                  NotificationService.openHistoryItem(histItem.nid);
                                  histDismissAnim.start();
                                  return;
                                }
                                if (histActBtn.modelData.identifier) {
                                  NotificationService.invokeHistoryAction(histItem.nid, histActBtn.modelData.identifier);
                                }
                                histDismissAnim.start();
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
