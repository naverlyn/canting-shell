import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/Components"
import "../../notifications/NotificationPresentation.js" as NotifPres
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
    const iconInfo = NotifPres.resolveIconInfo(n, root.accent, Quickshell, DesktopEntries);
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

      // Primary notification row
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

        // LEFT fallback: Shared App Icon / Social Badge
        NotifAppIconBadge {
          id: avatarBadge
          readonly property bool showSlot: !root.hasImage && hasAnyVisual
          visible: showSlot
          Layout.preferredWidth: showSlot ? (root.expanded ? 36 : 30) : 0
          Layout.preferredHeight: showSlot ? (root.expanded ? 36 : 30) : 0
          Layout.alignment: Qt.AlignVCenter
          Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          themeSrc: root.cachedAppIconThemeSrc
          fileSrc: root.cachedAppIconFileSrc
          fallbackThemeSrc: root.cachedAppIconFallback
          glyph: root.cachedSocialGlyph
          glyphColor: root.cachedSocialGlyph !== "" ? root.cachedSocialColor : root.cachedUrgencyColor
          font: root.font
          iconSize: root.expanded ? 34 : 28
          glyphSize: root.expanded ? 18 : 15
          badgeRadius: 10
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

        // RIGHT: Swapped App Icon / Social App Badge (when preview image is on left)
        NotifAppIconBadge {
          id: rightAppBadge
          readonly property bool showSlot: root.hasImage && hasAnyVisual
          visible: showSlot
          Layout.preferredWidth: showSlot ? 28 : 0
          Layout.preferredHeight: 28
          Layout.alignment: Qt.AlignVCenter

          themeSrc: root.cachedAppIconThemeSrc
          fileSrc: root.cachedAppIconFileSrc
          fallbackThemeSrc: root.cachedAppIconFallback
          glyph: root.cachedSocialGlyph
          glyphColor: root.cachedSocialColor
          font: root.font
          iconSize: 26
          glyphSize: 15
          badgeRadius: 9
          glyphBgAlpha: 0.16
          glyphBorderAlpha: 0.35
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

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          transform: Translate {
            y: actionsWrap.showActions ? 0 : -5
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
          }

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
