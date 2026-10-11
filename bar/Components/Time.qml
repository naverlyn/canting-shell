pragma Singleton

import Quickshell
import QtQuick
import ".."

Singleton {
  id: root

  readonly property string timeString: {
    Qt.formatDateTime(clock.date, BarConfig.showSeconds ? "hh:mm:ss" : "hh:mm")
  }

  readonly property string dateString: {
    Qt.formatDateTime(clock.date, "ddd MMM d")
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
