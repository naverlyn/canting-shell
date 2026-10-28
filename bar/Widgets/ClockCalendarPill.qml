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
  property alias isPinned: timeWidget.calPinned
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

  // Controller item for SharedInfoPopup
  Item {
    id: calendarProvider
    visible: false

    property Item target: timeWidget
    property Item barItem: hostContainer
    property var hostRoot: timeWidget.hostRoot
    property bool hovered: timeHover.hovered || timeMouse.containsMouse
    property bool pinned: timeWidget.calPinned
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: Qt.formatDateTime(new Date(), "MMMM yyyy")
    property string icon: ""
    property color accent: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
    property bool hideHeader: true
    property int preferredWidth: 260
    property int preferredHeight: 255
    property var rows: []

    property int viewMonth: new Date().getMonth()
    property int viewYear: new Date().getFullYear()

    signal triggerTransition(int direction, int targetMonth, int targetYear)

    function prevMonth() {
      triggerTransition(-1, -1, -1);
    }

    function nextMonth() {
      triggerTransition(1, -1, -1);
    }

    function resetToToday() {
      const now = new Date();
      const nowMonth = now.getMonth();
      const nowYear = now.getFullYear();
      if (nowYear === viewYear && nowMonth === viewMonth) return;
      const dir = (nowYear > viewYear || (nowYear === viewYear && nowMonth > viewMonth)) ? 1 : -1;
      triggerTransition(dir, nowMonth, nowYear);
    }

    function applyChange(dir, tMonth, tYear) {
      if (tMonth !== -1 && tYear !== -1) {
        viewMonth = tMonth;
        viewYear = tYear;
        return;
      }
      if (dir > 0) {
        if (viewMonth === 11) {
          viewMonth = 0;
          viewYear++;
        } else {
          viewMonth++;
        }
      } else {
        if (viewMonth === 0) {
          viewMonth = 11;
          viewYear--;
        } else {
          viewMonth--;
        }
      }
    }

    readonly property bool isCurrentMonth: {
      const now = new Date();
      return viewMonth === now.getMonth() && viewYear === now.getFullYear();
    }

    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(
      barItem && barItem.activeInfoProvider === calendarProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered
    )
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered

    Timer {
      id: calCloseGraceTimer
      interval: 150
      repeat: false
      onTriggered: {
        if (!calendarProvider.hovered && !calendarProvider.isSharedCardHovered) {
          calendarProvider.effectiveHovered = false;
          if (calendarProvider.barItem && calendarProvider.barItem.activeInfoProvider === calendarProvider && !calendarProvider.pinned) {
            calendarProvider.barItem.activeInfoProvider = null;
          }
        }
      }
    }

    onHoveredChanged: {
      if (hovered) {
        calCloseGraceTimer.stop();
        effectiveHovered = true;
        if (barItem) {
          if (barItem.activeInfoProvider && barItem.activeInfoProvider !== calendarProvider) {
            barItem.activeInfoProvider.effectiveHovered = false;
          }
          barItem.activeInfoProvider = calendarProvider;
        }
      } else if (!isSharedCardHovered) {
        calCloseGraceTimer.restart();
      }
    }

    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) {
        calCloseGraceTimer.stop();
        effectiveHovered = true;
      } else if (!hovered) {
        calCloseGraceTimer.restart();
      }
    }

    onPinnedChanged: {
      if (pinned && barItem) {
        if (barItem.activeInfoProvider && barItem.activeInfoProvider !== calendarProvider) {
          barItem.activeInfoProvider.effectiveHovered = false;
          if (barItem.activeInfoProvider.target && barItem.activeInfoProvider.target.isPinned !== undefined) {
            barItem.activeInfoProvider.target.isPinned = false;
          }
        }
        barItem.activeInfoProvider = calendarProvider;
      } else if (!pinned && !hovered && !isSharedCardHovered && barItem && barItem.activeInfoProvider === calendarProvider) {
        barItem.activeInfoProvider = null;
      }
    }

    onIsDetailsActiveChanged: {
      if (!isDetailsActive) {
        calendarProvider.resetToToday();
      }
    }

    Component.onDestruction: {
      if (barItem && barItem.activeInfoProvider === calendarProvider) {
        barItem.activeInfoProvider = null;
      }
    }

    property Component contentComponent: Component {
      Item {
        implicitWidth: 260
        implicitHeight: 255
        width: implicitWidth
        height: implicitHeight

        Connections {
          target: calendarProvider
          function onTriggerTransition(direction, targetMonth, targetYear) {
            if (switchAnim.running) switchAnim.complete();
            switchAnim.direction = direction;
            switchAnim.targetMonth = targetMonth;
            switchAnim.targetYear = targetYear;
            switchAnim.restart();
          }
        }

        SequentialAnimation {
          id: switchAnim
          property int direction: 1
          property int targetMonth: -1
          property int targetYear: -1

          ParallelAnimation {
            NumberAnimation { target: titleItem; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InQuad }
            NumberAnimation { target: titleItem; property: "x"; to: switchAnim.direction * -16; duration: 80; easing.type: Easing.InQuad }
            NumberAnimation { target: gridViewport; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InQuad }
            NumberAnimation { target: gridViewport; property: "x"; to: switchAnim.direction * -20; duration: 80; easing.type: Easing.InQuad }
          }
          ScriptAction {
            script: {
              calendarProvider.applyChange(switchAnim.direction, switchAnim.targetMonth, switchAnim.targetYear);
              titleItem.x = switchAnim.direction * 16;
              gridViewport.x = switchAnim.direction * 20;
            }
          }
          ParallelAnimation {
            NumberAnimation { target: titleItem; property: "opacity"; to: 1; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: titleItem; property: "x"; to: 0; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: gridViewport; property: "opacity"; to: 1; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: gridViewport; property: "x"; to: 0; duration: 130; easing.type: Easing.OutCubic }
          }
        }

        ColumnLayout {
          anchors.fill: parent
          spacing: 10

          // Header row with Next/Previous Month navigation and centered Month & Year
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            // Previous Month Button
            Rectangle {
              id: prevBtn
              width: 26
              height: 26
              radius: 13
              color: prevHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }
              scale: prevMouse.pressed ? 0.9 : (prevHover.hovered ? 1.08 : 1.0)
              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

              HoverHandler { id: prevHover }

              Text {
                anchors.centerIn: parent
                text: "‹"
                font.family: hostRoot.font
                font.pixelSize: 16
                font.bold: true
                color: prevHover.hovered ? hostContainer.wAccent("clock", hostRoot.theme.accentPrimary) : hostRoot.theme.textSecondary
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              MouseArea {
                id: prevMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarProvider.prevMonth()
              }
            }

            // Centered Month & Year with slide transition
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: 26
              clip: true

              Row {
                id: titleItem
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: Qt.formatDateTime(new Date(calendarProvider.viewYear, calendarProvider.viewMonth, 1), "MMMM yyyy")
                  color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
                  font.pixelSize: 13
                  font.bold: true
                  font.family: hostRoot.font
                }

                Rectangle {
                  visible: !calendarProvider.isCurrentMonth
                  anchors.verticalCenter: parent.verticalCenter
                  width: 6
                  height: 6
                  radius: 3
                  color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: !calendarProvider.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!calendarProvider.isCurrentMonth) {
                    calendarProvider.resetToToday();
                  }
                }
              }
            }

            // Next Month Button
            Rectangle {
              id: nextBtn
              width: 26
              height: 26
              radius: 13
              color: nextHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }
              scale: nextMouse.pressed ? 0.9 : (nextHover.hovered ? 1.08 : 1.0)
              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

              HoverHandler { id: nextHover }

              Text {
                anchors.centerIn: parent
                text: "›"
                font.family: hostRoot.font
                font.pixelSize: 16
                font.bold: true
                color: nextHover.hovered ? hostContainer.wAccent("clock", hostRoot.theme.accentPrimary) : hostRoot.theme.textSecondary
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              MouseArea {
                id: nextMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarProvider.nextMonth()
              }
            }
          }

          // Separator line
          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(hostRoot.theme.textPrimary.r, hostRoot.theme.textPrimary.g, hostRoot.theme.textPrimary.b, 0.12)
          }

          // Day of Week Row (stationary header)
          DayOfWeekRow {
            locale: Qt.locale("en_US")
            Layout.fillWidth: true
            delegate: Text {
              text: model.shortName
              color: hostRoot.theme.textSecondary
              font.pixelSize: 12
              font.bold: true
              font.family: hostRoot.font
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }

          // Month Grid Viewport with smooth transition
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Item {
              id: gridViewport
              anchors.fill: parent

              MonthGrid {
                id: monthGrid
                month: calendarProvider.viewMonth
                year: calendarProvider.viewYear
                locale: Qt.locale("en_US")
                anchors.fill: parent

                delegate: Item {
                  implicitWidth: 28
                  implicitHeight: 28

                  Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    color: hostContainer.wAccent("clock", hostRoot.theme.accentPrimary)
                    visible: model.today && calendarProvider.isCurrentMonth
                  }

                  Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: (model.today && calendarProvider.isCurrentMonth)
                      ? hostRoot.theme.bgBase
                      : (model.month === monthGrid.month ? hostRoot.theme.textPrimary : hostRoot.theme.textMuted)
                    font.pixelSize: 12
                    font.bold: model.today && calendarProvider.isCurrentMonth
                    font.family: hostRoot.font
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
