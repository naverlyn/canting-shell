pragma Singleton

import Quickshell
import QtQuick
import ".."

Singleton {
  id: root

  property string timeString: Qt.formatDateTime(new Date(), "hh:mm:ss")
  property string dateString: Qt.formatDateTime(new Date(), "ddd MMM d")
  property string fullDateString: Qt.formatDateTime(new Date(), "dddd, MMM d")
  property string monthYearString: Qt.formatDateTime(new Date(), "MMMM yyyy")
  property int currentYear: new Date().getFullYear()
  property int currentMonth: new Date().getMonth()
  property int currentDay: new Date().getDate()

  SystemClock {
    id: clock
    precision: (typeof BarConfig !== "undefined" && BarConfig && BarConfig.showSeconds) ? SystemClock.Seconds : SystemClock.Minutes
    onDateChanged: root.updateFormattedTime()
  }

  function updateFormattedTime() {
    var d = (clock && clock.date) ? clock.date : new Date();
    var showSec = true;
    try {
      if (typeof BarConfig !== "undefined" && BarConfig && BarConfig.showSeconds !== undefined) {
        showSec = Boolean(BarConfig.showSeconds);
      }
    } catch (e1) {}
    root.timeString = Qt.formatDateTime(d, showSec ? "hh:mm:ss" : "hh:mm") || "";

    var showYr = true;
    try {
      if (typeof BarConfig !== "undefined" && BarConfig && BarConfig.showYear !== undefined) {
        showYr = Boolean(BarConfig.showYear);
      }
    } catch (e2) {}
    root.dateString = Qt.formatDateTime(d, showYr ? "ddd MMM d yyyy" : "ddd MMM d") || "";
    root.fullDateString = Qt.formatDateTime(d, "dddd, MMM d") || "";
    root.monthYearString = Qt.formatDateTime(d, "MMMM yyyy") || "";
    root.currentYear = d.getFullYear();
    root.currentMonth = d.getMonth();
    root.currentDay = d.getDate();
  }

  Connections {
    target: (typeof BarConfig !== "undefined") ? BarConfig : null
    function onShowSecondsChanged() { root.updateFormattedTime(); }
    function onShowYearChanged() { root.updateFormattedTime(); }
  }

  Component.onCompleted: updateFormattedTime()
}
