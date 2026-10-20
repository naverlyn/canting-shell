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

    Text {
      id: clockTimeText
      anchors.verticalCenter: parent.verticalCenter
      text: Time.timeString
      color: hostContainer.hasCustomColor("clock")
        ? hostContainer.wAccent("clock", hostRoot.theme.textPrimary)
        : hostRoot.theme.textPrimary
      font.pixelSize: 12
      font.family: hostRoot.font
    }

    Text {
      id: clockDateText
      anchors.verticalCenter: parent.verticalCenter
      text: Time.dateString
      visible: BarConfig.showDate
      color: hostRoot.theme.textSecondary
      font.pixelSize: 12
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
  }

  PopupWindow {
    id: calendarPopup
    readonly property bool isCalActive: timeHover.hovered || timeMouse.containsMouse || timeWidget.calPinned
    visible: isCalActive || calBox.opacity > 0
    implicitWidth: 292
    implicitHeight: 312
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
      if (hostContainer.barPos === "top" || hostContainer.barPos === "bottom") {
        calendarPopup.anchor.rect = Qt.rect(widgetRect.x, bRect.y, widgetRect.width, bRect.height);
      } else {
        calendarPopup.anchor.rect = Qt.rect(bRect.x, widgetRect.y, bRect.width, widgetRect.height);
      }
    }

    Rectangle {
      id: calBox
      opacity: calendarPopup.isCalActive ? 1 : 0
      x: hostContainer.barPos === "left"
        ? (calendarPopup.isCalActive ? 6 : 0)
        : (hostContainer.barPos === "right" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
      y: hostContainer.barPos === "top"
        ? (calendarPopup.isCalActive ? 6 : 0)
        : (hostContainer.barPos === "bottom" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
      transformOrigin: {
        if (hostContainer.barPos === "bottom") return Item.Bottom;
        if (hostContainer.barPos === "left") return Item.Left;
        if (hostContainer.barPos === "right") return Item.Right;
        return Item.Top;
      }
      scale: calendarPopup.isCalActive ? 1 : 0.96
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      width: 280
      height: 300
      color: hostRoot.theme.bgSurface
      radius: 12
      border.color: hostRoot.theme.bgBase
      border.width: 2

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
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
