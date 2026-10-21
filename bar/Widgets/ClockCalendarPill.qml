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
    readonly property bool isCalActive: timeHover.hovered || timeMouse.containsMouse || timeWidget.calPinned

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

    function dismissImmediate() {
      instantClose = true;
      cardContainer.opacity = 0.0;
    }

    onIsCalActiveChanged: {
      if (isCalActive) {
        instantClose = false;
        BarConfig.notifyPopupActive(calendarPopup);
      } else {
        BarConfig.notifyPopupInactive(calendarPopup);
      }
    }

    visible: (isCalActive && !instantClose) || cardContainer.opacity > 0.001
    implicitWidth: {
      if (!fluidEnabled) return 292;
      if (hostContainer.barPos === "left" || hostContainer.barPos === "right") return 280;
      return 280 + (2 * cornerRad);
    }
    implicitHeight: {
      if (!fluidEnabled) return 312;
      if (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") return 300;
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
      if (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") {
        const widgetCenter = widgetRect.x + (widgetRect.width / 2);
        const popupW = calendarPopup.implicitWidth;
        const desiredX = Math.round(widgetCenter - (popupW / 2));
        const scrW = scr ? scr.width : 1920;
        const pad = 8;
        const clampedX = Math.max(pad, Math.min(Math.max(pad, scrW - popupW - pad), desiredX));
        calendarPopup.anchor.rect = Qt.rect(clampedX, bRect.y, popupW, bRect.height);
      } else {
        const widgetCenter = widgetRect.y + (widgetRect.height / 2);
        const popupH = calendarPopup.implicitHeight;
        const desiredY = Math.round(widgetCenter - (popupH / 2));
        const scrH = scr ? scr.height : 1080;
        const pad = 8;
        const clampedY = Math.max(pad, Math.min(Math.max(pad, scrH - popupH - pad), desiredY));
        calendarPopup.anchor.rect = Qt.rect(bRect.x, clampedY, bRect.width, popupH);
      }
    }

    Item {
      id: cardContainer
      opacity: (calendarPopup.isCalActive && !calendarPopup.instantClose) ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation {
          duration: calendarPopup.instantClose ? 0 : ((calendarPopup.isCalActive && BarConfig.isHoveringBarPills) ? 0 : 150)
          easing.type: Easing.OutCubic
        }
      }

      x: calendarPopup.fluidEnabled ? 0 : 6
      y: calendarPopup.fluidEnabled ? 0 : (
        hostContainer.barPos === "top"
          ? (calendarPopup.isCalActive ? 6 : 0)
          : (hostContainer.barPos === "bottom" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
      )
      width: calendarPopup.fluidEnabled ? calendarPopup.implicitWidth : 280
      height: calendarPopup.fluidEnabled ? calendarPopup.implicitHeight : 300

      Behavior on y {
        NumberAnimation {
          duration: (calendarPopup.instantClose || BarConfig.isHoveringBarPills) ? 0 : 160
          easing.type: Easing.OutCubic
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
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: calendarPopup.fluidEnabled && (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") ? (calendarPopup.cornerRad + 16) : 16
        anchors.rightMargin: calendarPopup.fluidEnabled && (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") ? (calendarPopup.cornerRad + 16) : 16
        anchors.topMargin: calendarPopup.fluidEnabled && (hostContainer.barPos === "left" || hostContainer.barPos === "right") ? (calendarPopup.cornerRad + 16) : 16
        anchors.bottomMargin: calendarPopup.fluidEnabled && (hostContainer.barPos === "left" || hostContainer.barPos === "right") ? (calendarPopup.cornerRad + 16) : 16
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
