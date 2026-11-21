import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/Components"
import "../../notifications/SocialApps.js" as SocialApps
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property var notification: null
  property int queueCount: 0
  property int currentIndex: 0
  property bool expanded: false
  property color accent: theme.accentPrimary

  signal requestCycle(int delta)

  // Cached visual snapshot so content fades smoothly during island collapse instead of snapping blank
  property string cachedAppName: ""
  property string cachedTimeLabel: ""
  property string cachedSummary: ""
  property string cachedBody: ""
  property string cachedImage: ""
  property string cachedAppIconThemeSrc: ""
  property string cachedAppIconFileSrc: ""
  property string cachedAppIconFallback: ""
  property string cachedSocialGlyph: ""
  property color cachedSocialColor: theme.accentPrimary
  property color cachedUrgencyColor: theme.accentPrimary
  property int cachedUrgency: NotificationUrgency.Normal
  property int cachedTimeout: 5000
  property var cachedActions: []
  property string _lastSeqId: ""

  readonly property bool hasImage: cachedImage !== "" && !cachedImage.startsWith("image://qsimage/")

  // Normalized countdown progress (1.0 -> 0.0) so it stays accurate while island width animates
  property real progressFrac: 1.0

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

  function resolveIconInfo(n) {
    if (!n) return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: root.accent };
    const rawIcon = String(n.appIcon || "").trim();
    const app = String(n.displayAppName || n.appName || "").trim();
    const sum = String(n.summary || "");
    const body = String(n.displayBody || n.body || "");

    // 1. Check SocialApps FIRST so WhatsApp/Discord/Telegram Web show their real icon instead of Brave/Chrome
    const sApp = n.socialApp || SocialApps.detectApp(n.appName || app, rawIcon, sum, body);
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

    const desktopFallback = resolveDesktopIconByAppName(n.appName || app);
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
        const validated = Quickshell.iconPath(rawIcon.slice(13), true) || "";
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

    // 3. DesktopEntries lookup by appName
    if (desktopFallback !== "") {
      return { themeSrc: fbTheme, fileSrc: fbFile, fallbackThemeSrc: "", glyph: "", color: root.accent };
    }

    return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: root.accent };
  }

  function resolveUrgencyColor(n) {
    if (!n) return root.accent;
    if (n.urgency === NotificationUrgency.Critical) return root.theme.accentRed;
    if (n.urgency === NotificationUrgency.Low) return root.theme.textMuted;
    return root.accent;
  }

  function syncSnapshot(n) {
    if (!n) return;
    cachedAppName = n.displayAppName || n.appName || "Notification";
    cachedTimeLabel = n.timeLabel || "";
    cachedSummary = n.summary || "Notification";
    cachedBody = n.displayBody || n.body || "";
    cachedImage = String(n.image || "");
    const iconInfo = resolveIconInfo(n);
    cachedAppIconThemeSrc = iconInfo.themeSrc;
    cachedAppIconFileSrc = iconInfo.fileSrc;
    cachedAppIconFallback = iconInfo.fallbackThemeSrc;
    cachedSocialGlyph = iconInfo.glyph;
    cachedSocialColor = iconInfo.color;
    cachedUrgencyColor = resolveUrgencyColor(n);
    cachedUrgency = n.urgency;
    cachedTimeout = (n.expireTimeout > 0)
      ? n.expireTimeout
      : (NotificationService.defaultTimeout > 0 ? NotificationService.defaultTimeout : 5000);
    const rawActs = n.actions;
    const actCount = (rawActs && rawActs.length !== undefined) ? rawActs.length : 0;
    const actsCopy = [];
    for (let i = 0; i < actCount; i++) {
      if (rawActs[i]) actsCopy.push(rawActs[i]);
    }
    cachedActions = actsCopy;
  }

  Connections {
    target: root.notification
    function onSummaryChanged() { root.syncSnapshot(root.notification); }
    function onBodyChanged() { root.syncSnapshot(root.notification); }
    function onImageChanged() { root.syncSnapshot(root.notification); }
    function onActionsChanged() { root.syncSnapshot(root.notification); }
  }

  onExpandedChanged: {
    if (notification) notification.hovered = expanded;
  }

  onNotificationChanged: {
    if (notification) {
      const seq = String(notification.seqId || notification.notifId || "");
      const isNew = (seq !== _lastSeqId);
      _lastSeqId = seq;
      syncSnapshot(notification);
      notification.hovered = expanded;
      if (isNew) {
        progressAnim.stop();
        progressFrac = 1.0;
        if (cachedUrgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical) {
          progressAnim.start();
        }
        entryAnim.restart();
      }
    } else {
      _lastSeqId = "";
      progressAnim.stop();
    }
  }

  NumberAnimation {
    id: progressAnim
    target: root
    property: "progressFrac"
    from: 1.0
    to: 0.0
    duration: Math.max(800, root.cachedTimeout)
    paused: NotificationService.pauseOnHover && root.expanded
  }

  ParallelAnimation {
    id: entryAnim

    NumberAnimation {
      target: contentMotion
      property: "opacity"
      from: 0.0
      to: 1.0
      duration: 210
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: contentSlide
      property: "y"
      from: -10
      to: 0
      duration: 260
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root.hasImage ? leftPreviewBox : avatarBadge
      property: "scale"
      from: 0.72
      to: 1.0
      duration: 300
      easing.type: Easing.OutBack
      easing.overshoot: 1.4
    }
  }

  implicitHeight: mainCol.implicitHeight
  height: implicitHeight

  Item {
    id: contentMotion
    anchors.left: parent.left
    anchors.right: parent.right
    height: mainCol.implicitHeight
    transform: Translate { id: contentSlide; y: 0 }

    ColumnLayout {
      id: mainCol
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: root.expanded ? 10 : 7

      // Primary notification row (when notification has an image/avatar, image goes LEFT and app icon goes RIGHT)
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // LEFT: Notification Image / Avatar (when present)
        ToastImageBox {
          id: leftPreviewBox
          visible: root.hasImage
          Layout.preferredWidth: root.expanded ? 52 : 36
          Layout.preferredHeight: root.expanded ? 52 : 36
          Layout.alignment: Qt.AlignVCenter
          imageSource: root.cachedImage
          urgencyColor: root.cachedUrgencyColor
          secondaryTextColor: root.theme.textSecondary
          font: root.font
          Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // LEFT fallback: App Icon or Social Badge (hidden cleanly when notification has no icon)
        Item {
          id: avatarBadge
          readonly property bool hasRealIcon: notifAppIconImg.status === Image.Ready || notifAppFileImg.status === Image.Ready || notifAppFallbackImg.status === Image.Ready
          readonly property string displayGlyph: root.cachedSocialGlyph
          readonly property color displayGlyphColor: root.cachedSocialGlyph !== "" ? root.cachedSocialColor : root.cachedUrgencyColor
          readonly property bool showSlot: !root.hasImage && (hasRealIcon || displayGlyph !== "")

          visible: showSlot
          Layout.preferredWidth: showSlot ? (root.expanded ? 36 : 30) : 0
          Layout.preferredHeight: showSlot ? (root.expanded ? 36 : 30) : 0
          Layout.alignment: Qt.AlignVCenter
          Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          IconImage {
            id: notifAppIconImg
            anchors.centerIn: parent
            implicitSize: root.expanded ? 34 : 28
            source: root.cachedAppIconThemeSrc
            visible: root.cachedAppIconThemeSrc !== "" && status === Image.Ready
          }

          Image {
            id: notifAppFileImg
            anchors.centerIn: parent
            width: root.expanded ? 34 : 28
            height: root.expanded ? 34 : 28
            source: root.cachedAppIconFileSrc
            sourceSize.width: 72
            sourceSize.height: 72
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            visible: root.cachedAppIconFileSrc !== "" && status === Image.Ready && notifAppIconImg.status !== Image.Ready
          }

          IconImage {
            id: notifAppFallbackImg
            anchors.centerIn: parent
            implicitSize: root.expanded ? 34 : 28
            source: (notifAppIconImg.status !== Image.Ready && notifAppFileImg.status !== Image.Ready && root.cachedAppIconFallback) ? root.cachedAppIconFallback : ""
            visible: source !== "" && status === Image.Ready && notifAppIconImg.status !== Image.Ready && notifAppFileImg.status !== Image.Ready
          }

          Rectangle {
            anchors.fill: parent
            radius: 10
            visible: !avatarBadge.hasRealIcon && avatarBadge.displayGlyph !== ""
            color: Qt.rgba(avatarBadge.displayGlyphColor.r, avatarBadge.displayGlyphColor.g, avatarBadge.displayGlyphColor.b, 0.14)
            border.color: Qt.rgba(avatarBadge.displayGlyphColor.r, avatarBadge.displayGlyphColor.g, avatarBadge.displayGlyphColor.b, 0.30)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: avatarBadge.displayGlyph
              font.family: root.font
              font.pixelSize: root.expanded ? 18 : 15
              color: avatarBadge.displayGlyphColor
            }
          }
        }

        // App Name + Summary + Body
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
              text: root.cachedAppName
              font.family: root.font
              font.pixelSize: 10
              font.bold: true
              color: root.cachedUrgencyColor
              elide: Text.ElideRight
            }

            // Compact queue count pill placed cleanly before "· Now"
            Rectangle {
              visible: root.queueCount > 1
              Layout.preferredWidth: Math.max(16, qCountTxt.implicitWidth + 8)
              Layout.preferredHeight: 15
              Layout.alignment: Qt.AlignVCenter
              radius: 7.5
              color: qHover.hovered
                ? Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.28)
                : Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.16)
              border.color: qHover.hovered
                ? Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.55)
                : Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.30)
              border.width: 1
              scale: qMouse.pressed ? 0.90 : (qHover.hovered ? 1.06 : 1.0)
              Behavior on color { ColorAnimation { duration: 130 } }
              Behavior on border.color { ColorAnimation { duration: 130 } }
              Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

              HoverHandler { id: qHover }

              WheelHandler {
                onWheel: (event) => {
                  if (event.angleDelta.y > 0) root.requestCycle(-1);
                  else if (event.angleDelta.y < 0) root.requestCycle(1);
                }
              }

              Text {
                id: qCountTxt
                anchors.centerIn: parent
                text: String(root.queueCount)
                font.family: root.font
                font.pixelSize: 9
                font.bold: true
                color: qHover.hovered ? root.theme.textPrimary : root.cachedUrgencyColor
                Behavior on color { ColorAnimation { duration: 130 } }
              }

              MouseArea {
                id: qMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestCycle(1)
              }
            }

            Text {
              visible: root.cachedTimeLabel !== ""
              text: "· " + root.cachedTimeLabel
              font.family: root.font
              font.pixelSize: 10
              color: root.theme.textMuted
            }

            Item { Layout.fillWidth: true }
          }

          Text {
            text: root.cachedSummary
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
            elide: Text.ElideRight
            maximumLineCount: root.expanded ? 2 : 1
            wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
            Layout.fillWidth: true
          }

          Text {
            visible: text !== ""
            text: root.cachedBody
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
            elide: Text.ElideRight
            maximumLineCount: root.expanded ? 4 : 1
            wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
            Layout.fillWidth: true
          }
        }

        // RIGHT: Swapped App Icon / Social App Badge (shown on right when preview image is on left)
        Item {
          id: rightAppBadge
          readonly property bool hasRealIcon: rightAppIconImg.status === Image.Ready || rightAppFileImg.status === Image.Ready || rightAppFallbackImg.status === Image.Ready
          readonly property bool hasSocialBadge: !hasRealIcon && root.cachedSocialGlyph !== ""
          readonly property bool showSlot: root.hasImage && (hasRealIcon || hasSocialBadge)

          visible: showSlot
          Layout.preferredWidth: showSlot ? 28 : 0
          Layout.preferredHeight: 28
          Layout.alignment: Qt.AlignVCenter

          IconImage {
            id: rightAppIconImg
            anchors.centerIn: parent
            implicitSize: 26
            source: root.cachedAppIconThemeSrc
            visible: root.cachedAppIconThemeSrc !== "" && status === Image.Ready
          }

          Image {
            id: rightAppFileImg
            anchors.centerIn: parent
            width: 26
            height: 26
            source: root.cachedAppIconFileSrc
            sourceSize.width: 56
            sourceSize.height: 56
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            visible: root.cachedAppIconFileSrc !== "" && status === Image.Ready && rightAppIconImg.status !== Image.Ready
          }

          IconImage {
            id: rightAppFallbackImg
            anchors.centerIn: parent
            implicitSize: 26
            source: (rightAppIconImg.status !== Image.Ready && rightAppFileImg.status !== Image.Ready && root.cachedAppIconFallback) ? root.cachedAppIconFallback : ""
            visible: source !== "" && status === Image.Ready && rightAppIconImg.status !== Image.Ready && rightAppFileImg.status !== Image.Ready
          }

          Rectangle {
            anchors.fill: parent
            radius: 9
            visible: rightAppBadge.hasSocialBadge
            color: Qt.rgba(root.cachedSocialColor.r, root.cachedSocialColor.g, root.cachedSocialColor.b, 0.16)
            border.color: Qt.rgba(root.cachedSocialColor.r, root.cachedSocialColor.g, root.cachedSocialColor.b, 0.35)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: root.cachedSocialGlyph
              font.family: root.font
              font.pixelSize: 15
              color: root.cachedSocialColor
            }
          }
        }
      }

      // Smoothly expanding Action Buttons Row (reveals on hover)
      Item {
        id: actionsWrap
        readonly property bool showActions: root.expanded && root.cachedActions.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: showActions ? 30 : 0
        opacity: showActions ? 1.0 : 0.0
        visible: root.cachedActions.length > 0
        clip: true

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Repeater {
            model: root.cachedActions.slice(0, 3)
            delegate: Rectangle {
              id: actBtn
              required property var modelData
              required property int index

              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: 14
              color: actHover.hovered
                ? Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.28)
                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.09)
              border.color: actHover.hovered
                ? Qt.rgba(root.cachedUrgencyColor.r, root.cachedUrgencyColor.g, root.cachedUrgencyColor.b, 0.55)
                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
              border.width: 1
              scale: actMouse.pressed ? 0.94 : 1.0
              Behavior on scale { NumberAnimation { duration: 100 } }
              Behavior on color { ColorAnimation { duration: 120 } }

              HoverHandler { id: actHover }

              Text {
                anchors.centerIn: parent
                text: actBtn.modelData ? String(actBtn.modelData.text || "Open") : "Open"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: actHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width - 16)
                horizontalAlignment: Text.AlignHCenter
              }

              MouseArea {
                id: actMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.notification && actBtn.modelData) {
                    root.notification.invokeAction(actBtn.modelData.identifier);
                  }
                }
              }
            }
          }
        }
      }

      // Smooth Normalized Countdown Progress Bar
      Rectangle {
        id: progressTrack
        visible: root.cachedUrgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical
        Layout.fillWidth: true
        Layout.preferredHeight: 3
        radius: 1.5
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.10)
        clip: true

        Rectangle {
          height: parent.height
          radius: parent.radius
          width: Math.max(0, parent.width * root.progressFrac)
          color: root.cachedUrgencyColor
        }
      }
    }
  }
}
