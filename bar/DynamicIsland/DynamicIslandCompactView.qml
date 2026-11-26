import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../Components"
import "../Widgets"
import ".."

Item {
  id: root

  required property var hostRoot
  required property var hostWindow
  required property var hostContainer
  required property var hostScope
  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  property var slotWidgets: []
  property string idleMode: "widgets" // "widgets" | "minimal"
  property bool liveActivityEnabled: true
  property int barThickness: 28

  readonly property var activePlayer: {
    const vals = Mpris.players.values;
    if (!vals || vals.length === 0) return null;
    for (let i = 0; i < vals.length; i++) {
      const p = vals[i];
      if (p && p.isPlaying) return p;
    }
    return null;
  }
  readonly property bool hasLiveMedia: liveActivityEnabled && activePlayer !== null
  readonly property bool useWidgetsMode: idleMode === "widgets"
  readonly property int leftFlankW: hasLiveMedia ? Math.max(18, barThickness - 10) : 0
  readonly property int rightFlankW: hasLiveMedia ? 16 : 0
  readonly property int centerContentW: useWidgetsMode ? slotWidgetsRow.implicitWidth : minimalRow.implicitWidth

  implicitWidth: Math.max(
    96,
    centerContentW > 0
      ? (centerContentW + (hasLiveMedia ? (leftFlankW + rightFlankW + 32) : (useWidgetsMode ? 14 : 20)))
      : (hasLiveMedia ? (leftFlankW + rightFlankW + 48) : 96)
  )
  implicitHeight: barThickness
  height: barThickness

  // Lightweight host adapter so slot widgets inherit all Bar styling/colors
  // without spawning a duplicate SharedInfoPopup when hovering the Dynamic Island.
  Item {
    id: islandWidgetHost
    visible: false
    width: root.width
    height: root.barThickness

    readonly property bool isVert: false
    readonly property string barPos: "top"
    readonly property int vertPillWidth: 28
    readonly property int pillRadius: root.hostContainer ? root.hostContainer.pillRadius : BarConfig.pillRadius
    readonly property real pillOpacity: root.hostContainer ? root.hostContainer.pillOpacity : BarConfig.pillOpacity
    readonly property bool hidePill: root.hostContainer ? root.hostContainer.hidePill : BarConfig.hidePill
    readonly property string activeStyle: root.hostContainer ? root.hostContainer.activeStyle : BarConfig.activeStyle
    readonly property string barColorSpec: root.hostContainer ? root.hostContainer.barColorSpec : ""
    readonly property int barThickness: root.barThickness
    readonly property real barScale: root.hostContainer ? root.hostContainer.barScale : 1.0
    readonly property int horizPillHeight: root.hostContainer ? root.hostContainer.horizPillHeight : 24
    readonly property bool isFloating: true
    readonly property int barEdgeOffset: root.hostContainer ? root.hostContainer.barEdgeOffset : 36
    readonly property bool fluidCards: false
    readonly property bool hasInnerCorners: false
    readonly property int innerCornerRadius: 16
    readonly property color barColor: root.hostContainer ? root.hostContainer.barColor : root.theme.bgBase
    property Item activeInfoProvider: null
    readonly property var sharedInfoPopup: null
    readonly property int vHitPadding: Math.max(0, Math.floor((barThickness - 24) / 2))
    readonly property int hHitPadding: 4

    function scaled(px) { return root.hostContainer ? root.hostContainer.scaled(px) : Math.max(1, Math.round(px)); }
    function wSpec(id) { return root.hostContainer ? root.hostContainer.wSpec(id) : ""; }
    function resolveWidgetThemeSpec(s) { return root.hostContainer ? root.hostContainer.resolveWidgetThemeSpec(s) : ""; }
    function hasCustomColor(id) { return root.hostContainer ? root.hostContainer.hasCustomColor(id) : false; }
    function wAccent(id, fb) { return root.hostContainer ? root.hostContainer.wAccent(id, fb) : fb; }
    function wBg(id, hov) { return root.hostContainer ? root.hostContainer.wBg(id, hov) : "transparent"; }
    function wBorder(id) { return root.hostContainer ? root.hostContainer.wBorder(id) : "transparent"; }
  }

  BarWidgetRegistry {
    id: compactRegistry
    hostRoot: root.hostRoot
    hostContainer: islandWidgetHost
    hostWindow: root.hostWindow
    hostScope: root.hostScope
  }

  Item {
    id: compactRow
    anchors.fill: parent

    // Left Live Activity Flank: Mini Album Art / Music Indicator (pinned left)
    Item {
      id: leftFlank
      visible: root.hasLiveMedia
      width: root.leftFlankW
      height: width
      anchors.left: parent.left
      anchors.leftMargin: 7
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        id: miniArtMask
        anchors.fill: parent
        radius: Math.min(6, width / 2)
        visible: false
        layer.enabled: true
        layer.smooth: true
      }

      Rectangle {
        anchors.fill: parent
        radius: Math.min(6, width / 2)
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
        clip: true

        Item {
          anchors.fill: parent
          layer.enabled: miniArtImg.status === Image.Ready
          layer.smooth: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: miniArtMask
            maskThresholdMin: 0.4
            maskSpreadAtMin: 0.3
          }

          Image {
            id: miniArtImg
            anchors.fill: parent
            source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: status === Image.Ready
          }
        }

        Text {
          anchors.centerIn: parent
          visible: miniArtImg.status !== Image.Ready
          text: "󰎆"
          font.family: root.font
          font.pixelSize: Math.max(9, Math.round(parent.width * 0.58))
          color: root.accent
        }
      }
    }

    // Center: User's Assigned Slot Widgets (or Minimal Clock)
    Item {
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: root.hasLiveMedia ? leftFlank.right : parent.left
      anchors.right: root.hasLiveMedia ? rightFlank.left : parent.right
      anchors.leftMargin: root.hasLiveMedia ? 8 : 0
      anchors.rightMargin: root.hasLiveMedia ? 8 : 0

      Row {
        id: slotWidgetsRow
        visible: root.useWidgetsMode
        anchors.centerIn: parent
        spacing: 6

        Repeater {
          model: root.useWidgetsMode ? root.slotWidgets : []
          delegate: Loader {
            required property string modelData
            readonly property string barId: (root.hostScope && root.hostScope.barCfg && root.hostScope.barCfg.id)
              ? String(root.hostScope.barCfg.id)
              : "bar_1"
            active: root.useWidgetsMode && BarConfig.isWidgetVisible(modelData, barId)
            sourceComponent: compactRegistry.getWidgetComponent(modelData)
            visible: active && sourceComponent !== null
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0) : 0
            height: visible ? root.barThickness : 0
          }
        }
      }

      // Fallback / Minimal Dynamic Island Pill Content
      Row {
        id: minimalRow
        visible: !root.useWidgetsMode
        anchors.centerIn: parent
        spacing: 8

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0
          Text {
            text: Time.timeString.split(":")[0] || "00"
            color: root.theme.textPrimary
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
          }
          Text {
            text: ":"
            color: root.theme.textPrimary
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
          }
          Text {
            text: Time.timeString.split(":").slice(1).join(":") || "00"
            color: root.accent
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
          }
        }

        Text {
          visible: !root.hasLiveMedia && BarConfig.showDate
          anchors.verticalCenter: parent.verticalCenter
          text: Time.dateString
          color: root.theme.textSecondary
          font.family: root.font
          font.pixelSize: 11
          font.bold: true
        }

        Text {
          visible: root.hasLiveMedia && root.activePlayer && root.activePlayer.trackTitle
          anchors.verticalCenter: parent.verticalCenter
          text: root.activePlayer ? (root.activePlayer.trackTitle || "") : ""
          color: root.theme.textSecondary
          font.family: root.font
          font.pixelSize: 11
          elide: Text.ElideRight
          width: Math.min(implicitWidth, 120)
        }
      }
    }

    // Right Live Activity Flank: Live 4-bar Mini Cava Waveform (pinned right)
    Row {
      id: rightFlank
      visible: root.hasLiveMedia
      anchors.right: parent.right
      anchors.rightMargin: 9
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      height: Math.max(12, root.barThickness - 14)

      Repeater {
        model: 4
        delegate: Rectangle {
          required property int index
          readonly property int rawVal: {
            const vals = CavaService.values || [];
            if (vals.length === 0) return 28 + ((index * 19) % 45);
            const mapped = Math.floor((index / 4) * vals.length);
            return Math.max(18, vals[Math.min(vals.length - 1, mapped)] || 18);
          }
          width: 2.5
          height: Math.max(3, Math.round((rawVal / 100) * rightFlank.height))
          radius: 1.25
          anchors.verticalCenter: parent.verticalCenter
          color: root.accent

          Behavior on height {
            NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
          }
        }
      }
    }
  }
}
