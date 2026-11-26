import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import "../../notifications"
import "../../notifications/SocialApps.js" as SocialApps
import "../../notifications/NotificationPresentation.js" as NotifPres

Item {
  id: cardSlot

  required property var modelData
  required property int index
  required property int groupIndex
  required property string groupAppName
  required property int groupSize
  required property bool isCollapsedStack
  required property string expandedNotifId
  required property bool isClearing
  required property var theme
  required property string font
  required property color accent

  signal requestToggleGroup(string appName)
  signal requestToggleExpanded(string nid)

  readonly property bool isCardVisible: !isCollapsedStack || index === 0
  readonly property bool showPeek: isCollapsedStack && index === 0
  property bool dismissed: false
  property real revealFrac: (isCardVisible && !dismissed) ? 1.0 : 0.0
  Behavior on revealFrac { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

  Layout.fillWidth: true
  Layout.topMargin: (index > 0 && isCardVisible && !dismissed) ? Math.round(6 * revealFrac) : 0
  Layout.preferredHeight: Math.round((histItem.height + (showPeek ? 6 : 0)) * revealFrac)
  opacity: revealFrac
  clip: true

  // Subtle stacked card peek strictly below histItem
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
      color: Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.035)
      border.color: Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.08)
      border.width: 1
    }
  }

  Rectangle {
    id: histItem
    readonly property string nid: (cardSlot.modelData && cardSlot.modelData.notifId)
      ? String(cardSlot.modelData.notifId)
      : ("hist_" + cardSlot.groupIndex + "_" + cardSlot.index)
    readonly property bool isExpanded: !cardSlot.isCollapsedStack && cardSlot.expandedNotifId === nid
    readonly property var iconInfo: NotifPres.resolveIconInfo(cardSlot.modelData, cardSlot.accent, Quickshell, DesktopEntries)
    readonly property var buttons: NotifPres.buildHistoryButtons(cardSlot.modelData)

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: itemCol.implicitHeight + 16
    radius: 10
    opacity: 0.0
    color: itemHover.hovered
      ? Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.09)
      : Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.045)
    border.color: (cardSlot.modelData && cardSlot.modelData.urgency === NotificationUrgency.Critical)
      ? Qt.rgba(cardSlot.theme.accentRed.r, cardSlot.theme.accentRed.g, cardSlot.theme.accentRed.b, 0.45)
      : (isExpanded ? Qt.rgba(cardSlot.accent.r, cardSlot.accent.g, cardSlot.accent.b, 0.38) : Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.07))
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

    readonly property bool clearingNow: cardSlot.isClearing
    onClearingNowChanged: {
      if (clearingNow && !histClearAnim.running) {
        histClearAnim.restart();
      }
    }

    SequentialAnimation {
      id: histClearAnim
      PauseAnimation { duration: Math.min(70, (cardSlot.groupIndex + cardSlot.index) * 20) }
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

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: mainRow.implicitHeight

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (cardSlot.isCollapsedStack) {
              cardSlot.requestToggleGroup(cardSlot.groupAppName);
            } else {
              cardSlot.requestToggleExpanded(histItem.nid);
            }
          }
        }

        RowLayout {
          id: mainRow
          anchors.fill: parent
          spacing: 10

          // Profile Picture / Preview Image FIRST, then shared NotifAppIconBadge
          Item {
            id: histIconSlot
            readonly property string rawImg: cardSlot.modelData ? String(cardSlot.modelData.image || "") : ""
            readonly property string cachedImg: cardSlot.modelData ? String(cardSlot.modelData.cachedImage || "") : ""
            readonly property string liveImg: (rawImg !== "" && rawImg !== "__sample__" && rawImg.indexOf("image://qsimage/") === -1)
              ? (rawImg.startsWith("image://icon//") ? ("file://" + rawImg.slice(13)) : (rawImg.startsWith("/") ? ("file://" + rawImg) : rawImg))
              : ""
            readonly property bool hasAvatar: avatarCachedImg.status === Image.Ready || avatarLiveImg.status === Image.Ready
            readonly property bool hasAnyVisual: hasAvatar || appIconBadge.hasAnyVisual
            readonly property bool isSocial: Boolean(cardSlot.modelData && cardSlot.modelData.socialApp)

            visible: hasAnyVisual
            Layout.preferredWidth: hasAnyVisual ? (hasAvatar ? 34 : 30) : 0
            Layout.preferredHeight: hasAnyVisual ? (hasAvatar ? 34 : 30) : 0
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
              id: avatarMask
              anchors.fill: parent
              radius: histIconSlot.isSocial ? (width / 2) : 9
              antialiasing: true
              visible: false
              layer.enabled: histIconSlot.hasAvatar && cardSlot.isCardVisible
              layer.smooth: true
              layer.textureSize: Qt.size(Math.max(2, Math.round(width * 2)), Math.max(2, Math.round(height * 2)))
            }

            Item {
              anchors.fill: parent
              visible: histIconSlot.cachedImg !== "" || histIconSlot.liveImg !== ""
              opacity: histIconSlot.hasAvatar ? 1.0 : 0.0
              layer.enabled: histIconSlot.hasAvatar && cardSlot.isCardVisible
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
                source: (histIconSlot.cachedImg === "" || avatarCachedImg.status === Image.Error)
                  ? ((histIconSlot.liveImg.indexOf("/tmp/") !== -1 && histIconSlot.liveImg.indexOf("scoped_dir") !== -1) ? "" : histIconSlot.liveImg)
                  : ""
                sourceSize.width: 72
                sourceSize.height: 72
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: source !== "" && status === Image.Ready && avatarCachedImg.status !== Image.Ready
              }
            }

            Rectangle {
              visible: histIconSlot.hasAvatar && histIconSlot.isSocial && histItem.iconInfo.glyph !== ""
              width: 14
              height: 14
              radius: 7
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.rightMargin: -2
              anchors.bottomMargin: -2
              color: cardSlot.theme.bgBase
              border.color: histItem.iconInfo.color
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: histItem.iconInfo.glyph
                font.family: cardSlot.font
                font.pixelSize: 8
                color: histItem.iconInfo.color
              }
            }

            NotifAppIconBadge {
              id: appIconBadge
              anchors.fill: parent
              visible: !histIconSlot.hasAvatar
              themeSrc: !histIconSlot.hasAvatar ? histItem.iconInfo.themeSrc : ""
              fileSrc: !histIconSlot.hasAvatar ? histItem.iconInfo.fileSrc : ""
              fallbackThemeSrc: !histIconSlot.hasAvatar ? histItem.iconInfo.fallbackThemeSrc : ""
              glyph: !histIconSlot.hasAvatar ? histItem.iconInfo.glyph : ""
              glyphColor: histItem.iconInfo.color
              font: cardSlot.font
              iconSize: 28
              glyphSize: 15
              badgeRadius: 9
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
                font.family: cardSlot.font
                font.pixelSize: 10
                font.bold: true
                color: histItem.iconInfo.glyph !== "" ? histItem.iconInfo.color : cardSlot.accent
                elide: Text.ElideRight
              }

              Rectangle {
                visible: cardSlot.isCollapsedStack
                Layout.preferredWidth: Math.max(16, grpCountTxt.implicitWidth + 8)
                Layout.preferredHeight: 15
                radius: 7.5
                color: Qt.rgba(cardSlot.accent.r, cardSlot.accent.g, cardSlot.accent.b, 0.18)
                border.color: Qt.rgba(cardSlot.accent.r, cardSlot.accent.g, cardSlot.accent.b, 0.35)
                border.width: 1
                Text {
                  id: grpCountTxt
                  anchors.centerIn: parent
                  text: String(cardSlot.groupSize)
                  font.family: cardSlot.font
                  font.pixelSize: 9
                  font.bold: true
                  color: cardSlot.accent
                }
              }

              Item { Layout.fillWidth: true }
              Text {
                text: cardSlot.modelData && cardSlot.modelData.timeStr ? String(cardSlot.modelData.timeStr) : ""
                font.family: cardSlot.font
                font.pixelSize: 9
                color: cardSlot.theme.textMuted
              }
            }

            Text {
              text: cardSlot.modelData ? (cardSlot.modelData.summary || "") : ""
              font.family: cardSlot.font
              font.pixelSize: 12
              font.bold: true
              color: cardSlot.theme.textPrimary
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: text !== ""
              text: cardSlot.modelData ? (cardSlot.modelData.displayBody || cardSlot.modelData.body || "") : ""
              font.family: cardSlot.font
              font.pixelSize: 11
              color: cardSlot.theme.textSecondary
              elide: Text.ElideRight
              maximumLineCount: histItem.isExpanded ? 6 : 2
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }
          }

          // Quick dismiss X on hover
          Rectangle {
            opacity: itemHover.hovered ? 1.0 : 0.0
            visible: opacity > 0.01
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignTop
            radius: 10
            color: rmHover.hovered ? Qt.rgba(cardSlot.theme.accentRed.r, cardSlot.theme.accentRed.g, cardSlot.theme.accentRed.b, 0.25) : "transparent"
            scale: rmMouse.pressed ? 0.85 : (rmHover.hovered ? 1.08 : 1.0)
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            HoverHandler { id: rmHover }
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: cardSlot.font
              font.pixelSize: 9
              color: rmHover.hovered ? cardSlot.theme.accentRed : cardSlot.theme.textMuted
              Behavior on color { ColorAnimation { duration: 120 } }
            }
            MouseArea {
              id: rmMouse
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (cardSlot.isCollapsedStack) {
                  NotificationService.dismissHistoryByApp(cardSlot.groupAppName);
                } else {
                  histDismissAnim.start();
                }
              }
            }
          }
        }
      }

      // Click-to-reveal Action Buttons Drawer
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
              readonly property color btnAccent: isDanger ? cardSlot.theme.accentRed : cardSlot.accent

              Layout.fillWidth: true
              Layout.preferredWidth: 1
              Layout.preferredHeight: 28
              radius: 14
              color: actHov.hovered
                ? Qt.rgba(btnAccent.r, btnAccent.g, btnAccent.b, 0.22)
                : Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.07)
              border.color: actHov.hovered
                ? Qt.rgba(btnAccent.r, btnAccent.g, btnAccent.b, 0.45)
                : Qt.rgba(cardSlot.theme.textPrimary.r, cardSlot.theme.textPrimary.g, cardSlot.theme.textPrimary.b, 0.09)
              border.width: 1
              scale: actMs.pressed ? 0.93 : (actHov.hovered ? 1.02 : 1.0)
              Behavior on color { ColorAnimation { duration: 130 } }
              Behavior on border.color { ColorAnimation { duration: 130 } }
              Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

              HoverHandler { id: actHov }

              Text {
                anchors.centerIn: parent
                text: histActBtn.modelData ? histActBtn.modelData.label : ""
                font.family: cardSlot.font
                font.pixelSize: 11
                font.bold: true
                color: actHov.hovered
                  ? (histActBtn.isDanger ? cardSlot.theme.accentRed : cardSlot.theme.textPrimary)
                  : (histActBtn.isDanger ? cardSlot.theme.textSecondary : cardSlot.accent)
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
