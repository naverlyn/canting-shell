import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
  id: sharedPopup

  required property var barWindow
  required property var barContainer
  required property var hostRoot

  readonly property Item provider: barContainer ? barContainer.activeInfoProvider : null
  readonly property Item targetPill: provider ? provider.target : null
  readonly property bool isDetailsActive: provider !== null && provider.isDetailsActive
  property bool cardHovered: cardHoverHandler.hovered

  readonly property var theme: (provider && provider.theme) ? provider.theme : hostRoot.theme
  readonly property string font: (provider && provider.font) ? provider.font : hostRoot.font
  readonly property string title: provider ? provider.title : ""
  readonly property string icon: provider ? provider.icon : ""
  readonly property color accent: provider ? provider.accent : (theme ? theme.accentPrimary : "#7aa2f7")
  readonly property var rows: (provider && provider.rows) ? provider.rows : []
  readonly property int columnCount: (provider && provider.columnCount) ? provider.columnCount : 1
  readonly property var cellModel: (provider && provider.cellModel) ? provider.cellModel : []
  readonly property bool hideHeader: Boolean(provider && provider.hideHeader)

  readonly property string barPosition: barWindow ? barWindow.windowBarPos : BarConfig.position
  readonly property bool isVert: barPosition === "left" || barPosition === "right"
  readonly property bool isFloatingBar: barContainer ? barContainer.isFloating : Boolean(BarConfig.floating)
  readonly property bool fluidEnabled: (barContainer && barContainer.fluidCards !== undefined ? Boolean(barContainer.fluidCards) : Boolean(BarConfig.fluidCards)) && !isFloatingBar
  readonly property int cornerRad: (barContainer && barContainer.innerCornerRadius !== undefined) ? barContainer.innerCornerRadius : 16
  readonly property color barColor: (barContainer && barContainer.barColor !== undefined)
    ? barContainer.barColor
    : (theme ? Qt.rgba(theme.bgBase.r, theme.bgBase.g, theme.bgBase.b, BarConfig.barOpacity) : "#1a1b26")
  readonly property color cardBorderColor: fluidEnabled
    ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.15)
    : theme.bgBase
  readonly property real cardBorderWidth: fluidEnabled ? 1 : 2

  // Calculate target dimensions from hidden layout measurer
  readonly property int baseContentW: (provider && provider.preferredWidth !== undefined && provider.preferredWidth > 0)
    ? provider.preferredWidth
    : Math.max(contentLayout.implicitWidth + 32, 200)
  readonly property int baseContentH: (provider && provider.preferredHeight !== undefined && provider.preferredHeight > 0)
    ? provider.preferredHeight
    : Math.max(contentLayout.implicitHeight + 28, 64)

  readonly property int targetCardW: {
    if (!fluidEnabled) return baseContentW + 16;
    if (isVert) return baseContentW + 8;
    return baseContentW + (2 * cornerRad);
  }
  readonly property int targetCardH: {
    if (!fluidEnabled) return baseContentH + 16;
    if (!isVert) return baseContentH + 8;
    return baseContentH + (2 * cornerRad);
  }

  property real targetX: 0
  property real targetY: 0
  property bool joinTop: false
  property bool joinBottom: false
  property bool joinLeft: false
  property bool joinRight: false
  property bool wasVisible: false

  function updateTargetPosition() {
    if (!barWindow || !targetPill) return;
    const win = barWindow;
    const widgetRect = win.contentItem.mapFromItem(targetPill, 0, 0, targetPill.width, targetPill.height);
    const scr = win.screen;
    const pad = 8;
    const joinThreshold = 36;

    if (!isVert) {
      const widgetCenter = widgetRect.x + (widgetRect.width / 2);
      const popupW = sharedPopup.targetCardW;
      const desiredX = Math.round(widgetCenter - (popupW / 2));
      const scrW = scr ? scr.width : win.width;

      if (sharedPopup.fluidEnabled && desiredX <= joinThreshold) {
        sharedPopup.joinLeft = true;
        sharedPopup.joinRight = false;
        sharedPopup.targetX = 0;
      } else if (sharedPopup.fluidEnabled && (desiredX + popupW >= scrW - joinThreshold)) {
        sharedPopup.joinRight = true;
        sharedPopup.joinLeft = false;
        sharedPopup.targetX = scrW - popupW;
      } else {
        sharedPopup.joinLeft = false;
        sharedPopup.joinRight = false;
        sharedPopup.targetX = Math.max(pad, Math.min(Math.max(pad, scrW - popupW - pad), desiredX));
      }
      sharedPopup.joinTop = false;
      sharedPopup.joinBottom = false;
      sharedPopup.targetY = 0;
    } else {
      const widgetCenter = widgetRect.y + (widgetRect.height / 2);
      const popupH = sharedPopup.targetCardH;
      const desiredY = Math.round(widgetCenter - (popupH / 2));
      const scrH = scr ? scr.height : win.height;

      if (sharedPopup.fluidEnabled && desiredY <= joinThreshold) {
        sharedPopup.joinTop = true;
        sharedPopup.joinBottom = false;
        sharedPopup.targetY = 0;
      } else if (sharedPopup.fluidEnabled && (desiredY + popupH >= scrH - joinThreshold)) {
        sharedPopup.joinBottom = true;
        sharedPopup.joinTop = false;
        sharedPopup.targetY = scrH - popupH;
      } else {
        sharedPopup.joinTop = false;
        sharedPopup.joinBottom = false;
        sharedPopup.targetY = Math.max(pad, Math.min(Math.max(pad, scrH - popupH - pad), desiredY));
      }
      sharedPopup.joinLeft = false;
      sharedPopup.joinRight = false;
      sharedPopup.targetX = 0;
    }
  }

  onTargetPillChanged: updateTargetPosition()
  onTargetCardWChanged: updateTargetPosition()
  onTargetCardHChanged: updateTargetPosition()
  onFluidEnabledChanged: updateTargetPosition()
  onBarPositionChanged: updateTargetPosition()

  onIsDetailsActiveChanged: {
    if (isDetailsActive) {
      updateTargetPosition();
      wasVisible = true;
      BarConfig.notifyPopupActive(sharedPopup);
      syncShadowCutout();
    } else {
      BarConfig.notifyPopupInactive(sharedPopup);
      syncShadowCutout();
    }
  }

  function syncShadowCutout() {
    if (!hostRoot) return;
    if (!isDetailsActive && morphCard.opacity <= 0.01) {
      if (hostRoot.activePopupData && hostRoot.activePopupData.target === sharedPopup) {
        hostRoot.activePopupData = null;
      }
      return;
    }
    const scr = barWindow ? barWindow.screen : null;
    hostRoot.activePopupData = {
      target: sharedPopup,
      active: isDetailsActive,
      fluidEnabled: sharedPopup.fluidEnabled,
      barPos: sharedPopup.barPosition,
      x: Math.round(sharedPopup.isVert ? (sharedPopup.barPosition === "left" ? barWindow.width : 0) : morphCard.x),
      y: Math.round(!sharedPopup.isVert ? (sharedPopup.barPosition === "top" ? barWindow.height : 0) : morphCard.y),
      width: Math.round(morphCard.width),
      height: Math.round(morphCard.height),
      screen: scr,
      joinTop: sharedPopup.joinTop,
      joinBottom: sharedPopup.joinBottom,
      joinLeft: sharedPopup.joinLeft,
      joinRight: sharedPopup.joinRight,
      cornerRad: sharedPopup.cornerRad
    };
  }

  visible: isDetailsActive || morphCard.opacity > 0.005
  onVisibleChanged: {
    if (!visible) {
      wasVisible = false;
      syncShadowCutout();
    }
  }

  color: "transparent"

  readonly property int maxPopupExtent: 560
  implicitWidth: isVert ? maxPopupExtent : (barWindow && barWindow.screen ? barWindow.screen.width : 1920)
  implicitHeight: !isVert ? maxPopupExtent : (barWindow && barWindow.screen ? barWindow.screen.height : 1080)

  // Only capture pointer events inside the animated morphCard
  mask: Region {
    item: morphCard
  }

  anchor.window: barWindow
  anchor.edges: {
    if (barPosition === "bottom") return Edges.Top;
    if (barPosition === "left") return Edges.Right;
    if (barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.gravity: {
    if (barPosition === "bottom") return Edges.Top;
    if (barPosition === "left") return Edges.Right;
    if (barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.onAnchoring: {
    if (!barWindow) return;
    if (barPosition === "top") {
      anchor.rect = Qt.rect(0, barWindow.height, implicitWidth, 0);
    } else if (barPosition === "bottom") {
      anchor.rect = Qt.rect(0, 0, implicitWidth, 0);
    } else if (barPosition === "left") {
      anchor.rect = Qt.rect(barWindow.width, 0, 0, implicitHeight);
    } else {
      anchor.rect = Qt.rect(0, 0, 0, implicitHeight);
    }
    updateTargetPosition();
  }

  Item {
    id: morphCard
    x: sharedPopup.isVert
      ? (sharedPopup.barPosition === "right" ? (sharedPopup.implicitWidth - width - (sharedPopup.fluidEnabled ? 0 : 6)) : (sharedPopup.fluidEnabled ? 0 : 6))
      : sharedPopup.targetX
    y: !sharedPopup.isVert
      ? (sharedPopup.barPosition === "bottom" ? (sharedPopup.implicitHeight - height - (sharedPopup.fluidEnabled ? 0 : 6)) : (sharedPopup.fluidEnabled ? 0 : 6))
      : sharedPopup.targetY
    width: sharedPopup.targetCardW
    height: sharedPopup.targetCardH
    opacity: sharedPopup.isDetailsActive ? 1.0 : 0.0

    property color animatedAccent: sharedPopup.accent
    Behavior on animatedAccent { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Behavior on x {
      enabled: sharedPopup.wasVisible
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on y {
      enabled: sharedPopup.wasVisible
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on width {
      enabled: sharedPopup.wasVisible
      NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }
    Behavior on height {
      enabled: sharedPopup.wasVisible
      NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
      NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
    }

    onXChanged: {
      cardBg.requestRepaint();
      sharedPopup.syncShadowCutout();
    }
    onYChanged: {
      cardBg.requestRepaint();
      sharedPopup.syncShadowCutout();
    }
    onWidthChanged: {
      cardBg.requestRepaint();
      sharedPopup.syncShadowCutout();
    }
    onHeightChanged: {
      cardBg.requestRepaint();
      sharedPopup.syncShadowCutout();
    }
    onOpacityChanged: sharedPopup.syncShadowCutout()

    transform: Translate {
      x: {
        if (sharedPopup.barPosition === "right") return sharedPopup.isDetailsActive ? 0 : 8;
        if (sharedPopup.barPosition === "left") return sharedPopup.isDetailsActive ? 0 : -8;
        return 0;
      }
      y: {
        if (sharedPopup.barPosition === "top") return sharedPopup.isDetailsActive ? 0 : -8;
        if (sharedPopup.barPosition === "bottom") return sharedPopup.isDetailsActive ? 0 : 8;
        return 0;
      }
      Behavior on x { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
    }

    HoverHandler {
      id: cardHoverHandler
    }

    FluidCardBackground {
      id: cardBg
      anchors.fill: parent
      fluidEnabled: sharedPopup.fluidEnabled
      barPosition: sharedPopup.barPosition
      cornerRadius: sharedPopup.cornerRad
      cardColor: sharedPopup.fluidEnabled ? sharedPopup.barColor : sharedPopup.theme.bgSurface
      borderColor: sharedPopup.cardBorderColor
      borderWidth: sharedPopup.cardBorderWidth
      joinTop: sharedPopup.joinTop
      joinBottom: sharedPopup.joinBottom
      joinLeft: sharedPopup.joinLeft
      joinRight: sharedPopup.joinRight
    }

    Item {
      anchors.fill: parent
      clip: true

      ColumnLayout {
        id: contentLayout
        width: sharedPopup.baseContentW
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: sharedPopup.fluidEnabled ? (sharedPopup.barPosition === "right" ? 4 : (sharedPopup.barPosition === "left" ? -4 : 0)) : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: sharedPopup.fluidEnabled ? (sharedPopup.barPosition === "bottom" ? -4 : (sharedPopup.barPosition === "top" ? 4 : 0)) : 0
        spacing: 10

        RowLayout {
          visible: !sharedPopup.hideHeader
          spacing: 6
          Text {
            visible: sharedPopup.icon !== ""
            text: sharedPopup.icon
            color: morphCard.animatedAccent
            font.pixelSize: 14
            font.family: sharedPopup.font
          }
          Text {
            text: sharedPopup.title
            color: morphCard.animatedAccent
            font.pixelSize: 13
            font.bold: true
            font.family: sharedPopup.font
          }
        }

        Rectangle {
          visible: !sharedPopup.hideHeader
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(sharedPopup.theme.textPrimary.r, sharedPopup.theme.textPrimary.g, sharedPopup.theme.textPrimary.b, 0.12)
        }

        Loader {
          Layout.fillWidth: true
          Layout.fillHeight: true
          active: provider && provider.contentComponent !== undefined && provider.contentComponent !== null
          sourceComponent: provider ? provider.contentComponent : null
        }

        Text {
          visible: (!provider || provider.contentComponent === undefined || provider.contentComponent === null) && sharedPopup.rows.length === 0
          text: "Loading..."
          color: sharedPopup.theme.textMuted
          font.pixelSize: 11
          font.family: sharedPopup.font
        }

        GridLayout {
          visible: (!provider || provider.contentComponent === undefined || provider.contentComponent === null) && sharedPopup.rows.length > 0
          columns: sharedPopup.columnCount
          columnSpacing: 18
          rowSpacing: 5
          Layout.fillWidth: true

          Repeater {
            model: sharedPopup.cellModel

            Text {
              required property var modelData
              Layout.columnSpan: modelData.header ? sharedPopup.columnCount : 1
              Layout.fillWidth: modelData.header || modelData.col === sharedPopup.columnCount - 1
              Layout.topMargin: modelData.header ? 4 : 0
              Layout.maximumWidth: 320
              text: modelData.text
              elide: Text.ElideRight
              horizontalAlignment: (!modelData.header && modelData.col > 0) ? Text.AlignRight : Text.AlignLeft
              color: modelData.header ? morphCard.animatedAccent
                   : (modelData.col === 0 ? sharedPopup.theme.textSecondary : sharedPopup.theme.textPrimary)
              font.pixelSize: 11
              font.bold: modelData.header
              font.family: sharedPopup.font
            }
          }
        }
      }
    }
  }
}
