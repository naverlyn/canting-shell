import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Components"

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  property int viewMonth: new Date().getMonth()
  property int viewYear: new Date().getFullYear()

  readonly property bool isCurrentMonth: {
    const now = new Date();
    return viewMonth === now.getMonth() && viewYear === now.getFullYear();
  }

  implicitHeight: calCol.implicitHeight
  height: implicitHeight

  function switchMonth(direction, targetMonth, targetYear) {
    if (monthSwitchAnim.running) monthSwitchAnim.complete();
    monthSwitchAnim.direction = direction;
    monthSwitchAnim.targetMonth = targetMonth;
    monthSwitchAnim.targetYear = targetYear;
    monthSwitchAnim.restart();
  }

  function applyMonthChange(dir, tMonth, tYear) {
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

  function prevMonth() { switchMonth(-1, -1, -1); }
  function nextMonth() { switchMonth(1, -1, -1); }
  function resetToToday() {
    const now = new Date();
    const m = now.getMonth();
    const y = now.getFullYear();
    if (y === viewYear && m === viewMonth) return;
    const dir = (y > viewYear || (y === viewYear && m > viewMonth)) ? 1 : -1;
    switchMonth(dir, m, y);
  }

  onVisibleChanged: {
    if (!visible) {
      const now = new Date();
      viewMonth = now.getMonth();
      viewYear = now.getFullYear();
    }
  }

  SequentialAnimation {
    id: monthSwitchAnim
    property int direction: 1
    property int targetMonth: -1
    property int targetYear: -1

    ParallelAnimation {
      NumberAnimation { target: monthTitleText; property: "opacity"; to: 0; duration: 90; easing.type: Easing.InQuad }
      NumberAnimation { target: monthTitleShift; property: "x"; to: monthSwitchAnim.direction * -12; duration: 90; easing.type: Easing.InQuad }
      NumberAnimation { target: gridSlideWrap; property: "opacity"; to: 0; duration: 90; easing.type: Easing.InQuad }
      NumberAnimation { target: gridSlideShift; property: "x"; to: monthSwitchAnim.direction * -18; duration: 90; easing.type: Easing.InQuad }
    }
    ScriptAction {
      script: {
        root.applyMonthChange(monthSwitchAnim.direction, monthSwitchAnim.targetMonth, monthSwitchAnim.targetYear);
        monthTitleShift.x = monthSwitchAnim.direction * 12;
        gridSlideShift.x = monthSwitchAnim.direction * 18;
      }
    }
    ParallelAnimation {
      NumberAnimation { target: monthTitleText; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { target: monthTitleShift; property: "x"; to: 0; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { target: gridSlideWrap; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { target: gridSlideShift; property: "x"; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }
  }

  ColumnLayout {
    id: calCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 10

    // Clean, Simple Header: Month Year + Date on Left, Centered Live Clock, Nav on Right
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: headerRow.implicitHeight

      RowLayout {
        id: headerRow
        anchors.fill: parent
        spacing: 8

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            clip: true

            Text {
              id: monthTitleText
              anchors.verticalCenter: parent.verticalCenter
              text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
              font.family: root.font
              font.pixelSize: 14
              font.bold: true
              color: root.theme.textPrimary
              transform: Translate { id: monthTitleShift; x: 0 }
            }
          }

          Text {
            text: Qt.formatDateTime(new Date(), "dddd, MMM d")
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

      // "Today" quick-jump pill (only shown when browsing another month)
      Rectangle {
        visible: !root.isCurrentMonth
        Layout.preferredWidth: todayTxt.implicitWidth + 14
        Layout.preferredHeight: 24
        radius: 12
        color: todayHover.hovered
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
          : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
        scale: todayMouse.pressed ? 0.92 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        HoverHandler { id: todayHover }

        Text {
          id: todayTxt
          anchors.centerIn: parent
          text: "Today"
          font.family: root.font
          font.pixelSize: 10
          font.bold: true
          color: root.accent
        }

        MouseArea {
          id: todayMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.resetToToday()
        }
      }

      // Prev / Next Month Circular Buttons
      RowLayout {
        spacing: 4

        Rectangle {
          Layout.preferredWidth: 26
          Layout.preferredHeight: 26
          radius: 13
          color: prevHover.hovered
            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
          scale: prevMouse.pressed ? 0.88 : (prevHover.hovered ? 1.06 : 1.0)
          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

          HoverHandler { id: prevHover }

          Text {
            anchors.centerIn: parent
            text: "\ueab5"
            font.family: root.font
            font.pixelSize: 13
            color: prevHover.hovered ? root.accent : root.theme.textSecondary
            Behavior on color { ColorAnimation { duration: 120 } }
          }

          MouseArea {
            id: prevMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.prevMonth()
          }
        }

        Rectangle {
          Layout.preferredWidth: 26
          Layout.preferredHeight: 26
          radius: 13
          color: nextHover.hovered
            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
          scale: nextMouse.pressed ? 0.88 : (nextHover.hovered ? 1.06 : 1.0)
          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

          HoverHandler { id: nextHover }

          Text {
            anchors.centerIn: parent
            text: "\ueab6"
            font.family: root.font
            font.pixelSize: 13
            color: nextHover.hovered ? root.accent : root.theme.textSecondary
            Behavior on color { ColorAnimation { duration: 120 } }
          }

            MouseArea {
              id: nextMouse
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.nextMonth()
            }
          }
        }
      }

      // Centered Live Clock
      Text {
        anchors.centerIn: parent
        text: Time.timeString
        font.family: root.font
        font.pixelSize: 16
        font.bold: true
        color: root.theme.textPrimary
      }
    }

    // Weekday Header Row
    DayOfWeekRow {
      locale: Qt.locale("en_US")
      Layout.fillWidth: true
      Layout.topMargin: 2

      delegate: Text {
        readonly property bool isWeekend: model.day === 0 || model.day === 6
        text: model.narrowName ? model.shortName.slice(0, 2) : model.shortName
        color: isWeekend ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85) : root.theme.textMuted
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    // Interactive Animated Month Grid (supports scroll wheel to flip months)
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 176
      clip: true

      WheelHandler {
        onWheel: (event) => {
          if (event.angleDelta.y > 0) root.prevMonth();
          else if (event.angleDelta.y < 0) root.nextMonth();
        }
      }

      Item {
        id: gridSlideWrap
        anchors.fill: parent
        transform: Translate { id: gridSlideShift; x: 0 }

        MonthGrid {
          id: monthGrid
          month: root.viewMonth
          year: root.viewYear
          locale: Qt.locale("en_US")
          anchors.fill: parent

          delegate: Item {
            id: dayCell
            readonly property bool isTodayCell: model.today && root.isCurrentMonth
            readonly property bool inCurrentMonth: model.month === monthGrid.month
            readonly property bool isWeekendDay: model.date && (model.date.getDay() === 0 || model.date.getDay() === 6)

            implicitWidth: 32
            implicitHeight: 28

            HoverHandler { id: dayHover }

            // Soft outer halo for today
            Rectangle {
              anchors.centerIn: parent
              visible: dayCell.isTodayCell
              width: 30
              height: 30
              radius: 15
              color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
            }

            // Day circle (today fill or lively hover pill)
            Rectangle {
              anchors.centerIn: parent
              width: 26
              height: 26
              radius: 13
              scale: dayCell.isTodayCell
                ? (dayHover.hovered ? 1.08 : 1.0)
                : (dayHover.hovered ? 1.0 : 0.82)
              opacity: dayCell.isTodayCell ? 1.0 : (dayHover.hovered ? 1.0 : 0.0)
              color: dayCell.isTodayCell
                ? root.accent
                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)

              Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: 120 } }
              Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
              anchors.centerIn: parent
              text: model.day
              color: dayCell.isTodayCell
                ? root.theme.bgBase
                : (dayCell.inCurrentMonth
                    ? (dayCell.isWeekendDay ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.85) : root.theme.textPrimary)
                    : root.theme.textMuted)
              opacity: dayCell.isTodayCell ? 1.0 : (dayCell.inCurrentMonth ? 1.0 : 0.35)
              font.family: root.font
              font.pixelSize: 12
              font.bold: dayCell.isTodayCell || (dayHover.hovered && dayCell.inCurrentMonth)
            }
          }
        }
      }
    }
  }
}
