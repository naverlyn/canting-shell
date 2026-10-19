import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

PopupWindow {
  id: popup

  required property Item target
  property Item barItem: null
  property bool hovered: false
  property bool pinned: false
  property var theme
  property string font: "Hack Nerd Font"
  readonly property string effectiveMonoFont: {
    const families = Qt.fontFamilies();
    const candidates = ["JetBrainsMono Nerd Font", "JetBrains Mono", "Hack Nerd Font", "Fira Code", "Source Code Pro", "Noto Sans Mono", "monospace"];
    for (let i = 0; i < candidates.length; i++) {
      if (families.indexOf(candidates[i]) !== -1) return candidates[i];
    }
    return "monospace";
  }
  property string location: "Bekasi"
  property color accent: "#ffffff"
  property string barPosition: BarConfig.position

  signal pinToggled()

  readonly property bool isWeatherActive: hovered || pinned
  property string weatherHtml: ""
  property bool isLoading: false

  visible: isWeatherActive || box.opacity > 0
  color: "transparent"
  implicitWidth: box.implicitWidth + 12
  implicitHeight: box.implicitHeight + 12

  anchor.window: target.QsWindow.window
  anchor.edges: {
    if (popup.barPosition === "bottom") return Edges.Top;
    if (popup.barPosition === "left") return Edges.Right;
    if (popup.barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.gravity: {
    if (popup.barPosition === "bottom") return Edges.Top;
    if (popup.barPosition === "left") return Edges.Right;
    if (popup.barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
  anchor.onAnchoring: {
    const win = target.QsWindow.window;
    if (!win) return;
    const widgetRect = win.contentItem.mapFromItem(target, 0, 0, target.width, target.height);
    if (popup.barItem) {
      const bRect = win.contentItem.mapFromItem(popup.barItem, 0, 0, popup.barItem.width, popup.barItem.height);
      if (popup.barPosition === "top" || popup.barPosition === "bottom") {
        anchor.rect = Qt.rect(widgetRect.x, bRect.y, widgetRect.width, bRect.height);
      } else {
        anchor.rect = Qt.rect(bRect.x, widgetRect.y, bRect.width, widgetRect.height);
      }
    } else {
      anchor.rect = widgetRect;
    }
  }

  Process {
    id: proc
    command: ["sh", Qt.resolvedUrl("../scripts/weather.sh").toString().replace("file://", ""), popup.location || "Bekasi", BarConfig.weatherUnit || "m", BarConfig.weatherMode || "compact"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (text && text.trim().length > 0) {
          popup.weatherHtml = text;
        }
        popup.isLoading = false;
      }
    }
    onExited: (code) => {
      popup.isLoading = false;
    }
  }

  readonly property string _cfgWeatherUnit: BarConfig.weatherUnit
  readonly property string _cfgWeatherMode: BarConfig.weatherMode

  on_CfgWeatherUnitChanged: {
    popup.weatherHtml = "";
    popup.refresh();
  }
  on_CfgWeatherModeChanged: {
    popup.weatherHtml = "";
    popup.refresh();
  }

  function refresh() {
    popup.isLoading = true;
    if (proc.running) {
      proc.running = false;
    }
    proc.command = ["sh", Qt.resolvedUrl("../scripts/weather.sh").toString().replace("file://", ""), popup.location || "Bekasi", BarConfig.weatherUnit || "m", BarConfig.weatherMode || "compact"];
    proc.running = true;
  }

  onLocationChanged: {
    popup.weatherHtml = "";
    refresh();
  }

  onIsWeatherActiveChanged: {
    if (isWeatherActive && (!weatherHtml || weatherHtml.length === 0)) {
      refresh();
    }
  }

  Component.onCompleted: {
    refresh();
  }

  // Auto-refresh timer based on BarConfig interval
  Timer {
    interval: Math.max(5, BarConfig.weatherIntervalMinutes || 15) * 60 * 1000
    repeat: true
    running: true
    onTriggered: popup.refresh()
  }

  Rectangle {
    id: box
    opacity: popup.isWeatherActive ? 1 : 0
    x: popup.barPosition === "left"
      ? (popup.isWeatherActive ? 6 : 0)
      : (popup.barPosition === "right" ? (popup.isWeatherActive ? 6 : 12) : 6)
    y: popup.barPosition === "top"
      ? (popup.isWeatherActive ? 6 : 0)
      : (popup.barPosition === "bottom" ? (popup.isWeatherActive ? 6 : 12) : 6)
    transformOrigin: {
      if (popup.barPosition === "bottom") return Item.Bottom;
      if (popup.barPosition === "left") return Item.Left;
      if (popup.barPosition === "right") return Item.Right;
      return Item.Top;
    }
    scale: popup.isWeatherActive ? 1 : 0.96

    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    implicitWidth: {
      const scr = (target && target.QsWindow && target.QsWindow.window && target.QsWindow.window.screen) ? target.QsWindow.window.screen : null;
      return scr ? Math.min(850, scr.width - 32) : 850;
    }
    implicitHeight: {
      const scr = (target && target.QsWindow && target.QsWindow.window && target.QsWindow.window.screen) ? target.QsWindow.window.screen : null;
      return scr ? Math.min(540, scr.height - 90) : 540;
    }
    color: popup.theme.bgSurface
    radius: 12
    border.color: popup.theme.bgBase
    border.width: 2

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 8

      // Header Bar
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "󰖐"
          color: popup.accent
          font.pixelSize: 15
          font.family: popup.font
        }

        Text {
          text: "Weather Forecast" + (popup.location ? (" (" + popup.location + ")") : "")
          color: popup.accent
          font.pixelSize: 13
          font.bold: true
          font.family: popup.font
        }

        Item { Layout.fillWidth: true }

        // Pin Button
        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: pinHover.hovered ? popup.theme.bgBase : "transparent"
          Text {
            anchors.centerIn: parent
            text: popup.pinned ? "󰤱" : "󰤰"
            color: popup.pinned ? popup.accent : popup.theme.textSecondary
            font.pixelSize: 12
            font.family: popup.font
          }
          HoverHandler { id: pinHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.pinToggled()
          }
        }

        // Refresh Button
        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: refHover.hovered ? popup.theme.bgBase : "transparent"
          Text {
            id: refIcon
            anchors.centerIn: parent
            text: "󰑐"
            color: popup.isLoading ? popup.accent : popup.theme.textSecondary
            font.pixelSize: 12
            font.family: popup.font
            RotationAnimation on rotation {
              running: popup.isLoading
              loops: Animation.Infinite
              from: 0
              to: 360
              duration: 900
            }
          }
          HoverHandler { id: refHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.refresh()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: popup.theme.bgBase
      }

      // Weather Content Area
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Text {
          visible: (!popup.weatherHtml || popup.weatherHtml === "") && popup.isLoading
          anchors.centerIn: parent
          text: "Fetching weather forecast from wttr.in..."
          color: popup.theme.textMuted
          font.pixelSize: 11
          font.family: popup.font
        }

        Flickable {
          id: flick
          anchors.fill: parent
          clip: true
          contentWidth: Math.max(width, weatherLabel.implicitWidth)
          contentHeight: Math.max(height, weatherLabel.implicitHeight)
          boundsBehavior: Flickable.StopAtBounds

          ScrollBar.vertical: ScrollBar {
            policy: flick.contentHeight > flick.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            width: 5
            contentItem: Rectangle {
              radius: 3
              color: popup.theme.bgBorder
            }
          }

          ScrollBar.horizontal: ScrollBar {
            policy: flick.contentWidth > flick.width ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            height: 5
            contentItem: Rectangle {
              radius: 3
              color: popup.theme.bgBorder
            }
          }

          Text {
            id: weatherLabel
            textFormat: Text.RichText
            text: "<pre style=\"font-family: '" + popup.effectiveMonoFont + "', monospace; font-size: 10px; line-height: 1.15; margin: 0;\">" + popup.weatherHtml + "</pre>"
            color: popup.theme.textPrimary
            font.family: popup.effectiveMonoFont
            font.pixelSize: 10
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
              if (wheel.angleDelta.y !== 0) {
                flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY - wheel.angleDelta.y));
              }
              if (wheel.angleDelta.x !== 0) {
                flick.contentX = Math.max(0, Math.min(Math.max(0, flick.contentWidth - flick.width), flick.contentX - wheel.angleDelta.x));
              }
            }
          }
        }
      }
    }
  }
}
