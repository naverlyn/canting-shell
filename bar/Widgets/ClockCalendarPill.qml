import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick.Effects
import "../../ControlCenter"
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: timeWidget
  implicitHeight: hostContainer.isVert ? (vertClockCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (timeDate.implicitWidth + 16)
  height: implicitHeight
  width: implicitWidth
  scale: timeMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  property bool calPinned: false
  color: hostContainer.wBg("clock", timeHover.hovered || timeMouse.containsMouse || timeWidget.calPinned)
  border.color: hostContainer.wBorder("clock")
  border.width: hostContainer.hasCustomColor("clock") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }

  HoverHandler { id: timeHover }

  PillIndicator {
    hostRoot: timeWidget.hostRoot
    hostContainer: timeWidget.hostContainer
    active: timeWidget.calPinned || timeMouse.pressed
    hovered: timeHover.hovered || timeMouse.containsMouse
    accentColor: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
  }

  MouseArea {
    id: timeMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: timeWidget.calPinned = !timeWidget.calPinned
  }

  Row {
    id: timeDate
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 8

    Row {
      id: clockTimeText
      anchors.verticalCenter: parent.verticalCenter
      spacing: 0

      Text {
        text: Time.timeString.split(":")[0] || "00"
        color: hostRoot.theme.textPrimary
        font.pixelSize: 12
        font.bold: true
        font.family: hostRoot.font
      }
      Text {
        text: ":"
        color: hostRoot.theme.textPrimary
        font.pixelSize: 12
        font.bold: true
        font.family: hostRoot.font
      }
      Text {
        text: Time.timeString.split(":").slice(1).join(":") || "00"
        color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
        font.pixelSize: 12
        font.bold: true
        font.family: hostRoot.font
      }
    }

    Text {
      id: clockDateText
      anchors.verticalCenter: parent.verticalCenter
      text: Time.dateString
      visible: BarConfig.showDate
      color: hostRoot.theme.textSecondary
      font.pixelSize: 12
      font.bold: true
      font.family: hostRoot.font
    }
  }

  Column {
    id: vertClockCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 1

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Time.timeString.split(":")[0] || "00"
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.bold: true
      font.family: hostRoot.font
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Time.timeString.split(":")[1] || "00"
      color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
      font.pixelSize: 11
      font.bold: true
      font.family: hostRoot.font
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: BarConfig.showDate && BarConfig.showYear
      text: Qt.formatDateTime(new Date(), "yyyy")
      color: hostRoot.theme.textSecondary
      font.pixelSize: 11
      font.bold: true
      font.family: hostRoot.font
    }
  }

  PopupWindow {
    id: calendarPopup
    property bool effectiveHovered: false
    readonly property bool isCalActive: effectiveHovered || timeWidget.calPinned

    Timer {
      id: calCloseGraceTimer
      interval: 180
      repeat: false
      onTriggered: calendarPopup.effectiveHovered = false
    }

    readonly property bool pillHovered: timeHover.hovered || timeMouse.containsMouse
    onPillHoveredChanged: {
      if (pillHovered) {
        calCloseGraceTimer.stop();
        calendarPopup.effectiveHovered = true;
      } else if (!calHoverHandler.hovered) {
        calCloseGraceTimer.restart();
      }
    }

    // Fluid card blending properties
    readonly property bool isFloatingBar: hostContainer && hostContainer.isFloating !== undefined
      ? hostContainer.isFloating
      : Boolean(BarConfig.floating)
    readonly property bool fluidEnabled: Boolean(BarConfig.fluidCards) && !isFloatingBar
    readonly property int cornerRad: hostContainer && hostContainer.innerCornerRadius !== undefined
      ? hostContainer.innerCornerRadius
      : 16
    readonly property color barColor: hostContainer && hostContainer.barColor !== undefined
      ? hostContainer.barColor
      : (hostRoot.theme
        ? Qt.rgba(hostRoot.theme.bgBase.r, hostRoot.theme.bgBase.g, hostRoot.theme.bgBase.b, (BarConfig.barOpacity !== undefined ? BarConfig.barOpacity : 0.85))
        : "#1a1b26")
    readonly property color cardBorderColor: fluidEnabled
      ? Qt.rgba(hostRoot.theme.textPrimary.r, hostRoot.theme.textPrimary.g, hostRoot.theme.textPrimary.b, 0.15)
      : hostRoot.theme.bgBase
    readonly property real cardBorderWidth: fluidEnabled ? 1 : 2

    property bool instantClose: false
    property int lastClampedX: 0
    property int lastClampedY: 0
    property bool joinTop: false
    property bool joinBottom: false
    property bool joinLeft: false
    property bool joinRight: false

    function syncActivePopupState(active) {
      const hr = hostRoot;
      if (!hr) return;
      if (!active) {
        if (hr.activePopupData && hr.activePopupData.target === calendarPopup) {
          hr.activePopupData = null;
        }
        return;
      }
      const win = timeWidget ? timeWidget.QsWindow.window : null;
      const scr = win ? win.screen : null;
      hr.activePopupData = {
        target: calendarPopup,
        active: true,
        fluidEnabled: calendarPopup.fluidEnabled,
        barPos: hostContainer.barPos,
        x: calendarPopup.lastClampedX,
        y: calendarPopup.lastClampedY,
        width: calendarPopup.implicitWidth,
        height: calendarPopup.implicitHeight,
        screen: scr,
        joinTop: calendarPopup.joinTop,
        joinBottom: calendarPopup.joinBottom,
        joinLeft: calendarPopup.joinLeft,
        joinRight: calendarPopup.joinRight,
        cornerRad: calendarPopup.cornerRad
      };
    }

    function dismissImmediate() {
      instantClose = true;
      effectiveHovered = false;
      calCloseGraceTimer.stop();
      cardContainer.opacity = 0.0;
      syncActivePopupState(false);
    }

    onIsCalActiveChanged: {
      if (isCalActive) {
        instantClose = false;
        BarConfig.notifyPopupActive(calendarPopup);
        syncActivePopupState(true);
      } else {
        BarConfig.notifyPopupInactive(calendarPopup);
        syncActivePopupState(false);
      }
    }

    Component.onDestruction: syncActivePopupState(false)

    visible: (isCalActive && !instantClose) || cardContainer.opacity > 0.001
    implicitWidth: {
      if (!fluidEnabled) return 296;
      if (hostContainer.barPos === "left" || hostContainer.barPos === "right") return 288;
      return 280 + (2 * cornerRad);
    }
    implicitHeight: {
      if (!fluidEnabled) return 316;
      if (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") return 308;
      return 300 + (2 * cornerRad);
    }
    color: "transparent"

    anchor.window: timeWidget.QsWindow.window
    anchor.edges: {
      if (hostContainer.barPos === "bottom") return Edges.Top;
      if (hostContainer.barPos === "left") return Edges.Right;
      if (hostContainer.barPos === "right") return Edges.Left;
      return Edges.Bottom;
    }
    anchor.gravity: {
      if (hostContainer.barPos === "bottom") return Edges.Top;
      if (hostContainer.barPos === "left") return Edges.Right;
      if (hostContainer.barPos === "right") return Edges.Left;
      return Edges.Bottom;
    }
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    anchor.onAnchoring: {
      const win = timeWidget.QsWindow.window;
      if (!win) return;
      const widgetRect = win.contentItem.mapFromItem(
        timeWidget, 0, 0, timeWidget.width, timeWidget.height
      );
      const bRect = win.contentItem.mapFromItem(
        hostContainer, 0, 0, hostContainer.width, hostContainer.height
      );
      const scr = win.screen;
      const pad = 8;
      const joinThreshold = 36;

      if (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") {
        const widgetCenter = widgetRect.x + (widgetRect.width / 2);
        const popupW = calendarPopup.implicitWidth;
        const desiredX = Math.round(widgetCenter - (popupW / 2));
        const scrW = scr ? scr.width : 1920;

        if (calendarPopup.fluidEnabled && desiredX <= joinThreshold) {
          calendarPopup.joinLeft = true;
          calendarPopup.joinRight = false;
          calendarPopup.lastClampedX = 0;
        } else if (calendarPopup.fluidEnabled && (desiredX + popupW >= scrW - joinThreshold)) {
          calendarPopup.joinRight = true;
          calendarPopup.joinLeft = false;
          calendarPopup.lastClampedX = scrW - popupW;
        } else {
          calendarPopup.joinLeft = false;
          calendarPopup.joinRight = false;
          calendarPopup.lastClampedX = Math.max(pad, Math.min(Math.max(pad, scrW - popupW - pad), desiredX));
        }

        calendarPopup.joinTop = false;
        calendarPopup.joinBottom = false;
        calendarPopup.lastClampedY = hostContainer.barPos === "top" ? win.height : 0;
        const anchorY = calendarPopup.fluidEnabled ? (hostContainer.barPos === "top" ? win.height : 0) : bRect.y;
        const anchorH = calendarPopup.fluidEnabled ? 0 : bRect.height;
        calendarPopup.anchor.rect = Qt.rect(calendarPopup.lastClampedX, anchorY, popupW, anchorH);
      } else {
        const widgetCenter = widgetRect.y + (widgetRect.height / 2);
        const popupH = calendarPopup.implicitHeight;
        const desiredY = Math.round(widgetCenter - (popupH / 2));
        const scrH = scr ? scr.height : 1080;

        if (calendarPopup.fluidEnabled && desiredY <= joinThreshold) {
          calendarPopup.joinTop = true;
          calendarPopup.joinBottom = false;
          calendarPopup.lastClampedY = 0;
        } else if (calendarPopup.fluidEnabled && (desiredY + popupH >= scrH - joinThreshold)) {
          calendarPopup.joinBottom = true;
          calendarPopup.joinTop = false;
          calendarPopup.lastClampedY = scrH - popupH;
        } else {
          calendarPopup.joinTop = false;
          calendarPopup.joinBottom = false;
          calendarPopup.lastClampedY = Math.max(pad, Math.min(Math.max(pad, scrH - popupH - pad), desiredY));
        }

        calendarPopup.joinLeft = false;
        calendarPopup.joinRight = false;
        calendarPopup.lastClampedX = hostContainer.barPos === "left" ? win.width : 0;
        const anchorX = calendarPopup.fluidEnabled ? (hostContainer.barPos === "left" ? win.width : 0) : bRect.x;
        const anchorW = calendarPopup.fluidEnabled ? 0 : bRect.width;
        calendarPopup.anchor.rect = Qt.rect(anchorX, calendarPopup.lastClampedY, anchorW, popupH);
      }

      if (calendarPopup.isCalActive) {
        calendarPopup.syncActivePopupState(true);
      }
    }

    Item {
      id: cardContainer
      opacity: (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation {
          duration: calendarPopup.instantClose ? 0 : ((calendarPopup.isCalActive && BarConfig.isHoveringBarPills) ? 0 : 180)
          easing.type: Easing.OutCubic
        }
      }

      anchors.fill: parent

      transform: Translate {
        id: calSlideTransform
        x: {
          if (!calendarPopup.fluidEnabled) return 0;
          if (hostContainer.barPos === "right") return (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 0 : 8;
          if (hostContainer.barPos === "left") return (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 0 : -8;
          return 0;
        }
        y: {
          if (!calendarPopup.fluidEnabled) return (
            hostContainer.barPos === "top"
              ? (calendarPopup.isCalActive ? 6 : 0)
              : (hostContainer.barPos === "bottom" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
          );
          if (hostContainer.barPos === "top") return (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 0 : -8;
          if (hostContainer.barPos === "bottom") return (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 0 : 8;
          return 0;
        }

        Behavior on x {
          NumberAnimation {
            duration: calendarPopup.instantClose ? 0 : ((calendarPopup.isCalActive && BarConfig.isHoveringBarPills) ? 0 : 200)
            easing.type: Easing.OutCubic
          }
        }
        Behavior on y {
          NumberAnimation {
            duration: calendarPopup.instantClose ? 0 : ((calendarPopup.isCalActive && BarConfig.isHoveringBarPills) ? 0 : 200)
            easing.type: Easing.OutCubic
          }
        }
      }

      HoverHandler {
        id: calHoverHandler
        onHoveredChanged: {
          if (hovered) {
            calCloseGraceTimer.stop();
            calendarPopup.effectiveHovered = true;
          } else if (!calendarPopup.pillHovered) {
            calCloseGraceTimer.restart();
          }
        }
      }

      FluidCardBackground {
        anchors.fill: parent
        fluidEnabled: calendarPopup.fluidEnabled
        barPosition: hostContainer.barPos
        cornerRadius: calendarPopup.cornerRad
        cardColor: calendarPopup.fluidEnabled ? calendarPopup.barColor : hostRoot.theme.bgSurface
        borderColor: calendarPopup.cardBorderColor
        borderWidth: calendarPopup.cardBorderWidth
        joinTop: calendarPopup.joinTop
        joinBottom: calendarPopup.joinBottom
        joinLeft: calendarPopup.joinLeft
        joinRight: calendarPopup.joinRight
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: calendarPopup.fluidEnabled
          ? (hostContainer.barPos === "top" || hostContainer.barPos === "bottom" ? (calendarPopup.cornerRad + 16) : (hostContainer.barPos === "right" ? 20 : 16))
          : 16
        anchors.rightMargin: calendarPopup.fluidEnabled
          ? (hostContainer.barPos === "top" || hostContainer.barPos === "bottom" ? (calendarPopup.cornerRad + 16) : (hostContainer.barPos === "left" ? 20 : 16))
          : 16
        anchors.topMargin: calendarPopup.fluidEnabled
          ? (hostContainer.barPos === "left" || hostContainer.barPos === "right" ? (calendarPopup.cornerRad + 16) : (hostContainer.barPos === "bottom" ? 20 : 16))
          : 16
        anchors.bottomMargin: calendarPopup.fluidEnabled
          ? (hostContainer.barPos === "left" || hostContainer.barPos === "right" ? (calendarPopup.cornerRad + 16) : (hostContainer.barPos === "top" ? 20 : 16))
          : 16
        spacing: 12

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(new Date(), "MMMM yyyy")
          color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
          font.pixelSize: 14
          font.bold: true
          font.family: hostRoot.font
        }

        DayOfWeekRow {
          locale: Qt.locale("en_US")
          Layout.fillWidth: true
          delegate: Text {
            text: model.shortName
            color: hostRoot.theme.textSecondary
            font.pixelSize: 12
            font.family: hostRoot.font
            horizontalAlignment: Text.AlignHCenter
          }
        }

        MonthGrid {
          locale: Qt.locale("en_US")
          Layout.fillWidth: true
          Layout.fillHeight: true

          delegate: Item {
            implicitWidth: 24
            implicitHeight: 24

            Rectangle {
              anchors.centerIn: parent
              width: 24
              height: 24
              radius: 12
              color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
              visible: model.today
            }

            Text {
              anchors.centerIn: parent
              text: model.day
              color: model.today ? hostRoot.theme.bgBase : hostRoot.theme.textPrimary
              font.pixelSize: 12
              font.family: hostRoot.font
            }
          }
        }
      }
    }
  }
}
