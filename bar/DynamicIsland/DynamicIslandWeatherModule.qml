import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  property string conditionText: SystemInfo._cachedWeatherCond || ""
  property string tempText: SystemInfo._cachedWeatherTemp || "--°C"
  property string feelsLikeText: SystemInfo._cachedWeatherFeels || "--°C"
  property string humidityText: SystemInfo._cachedWeatherHum || "--%"
  property string windText: SystemInfo._cachedWeatherWind || "--"
  property bool isRefreshing: false

  readonly property string locationLabel: SystemInfo.effectiveWeatherLocation || "Local Weather"

  implicitHeight: weatherCol.implicitHeight
  height: implicitHeight

  function parseSummary(raw) {
    if (!raw || raw === "Loading..." || raw.indexOf("N/A") !== -1) return;
    const tempMatch = raw.match(/([+-]?\d+°[CF])/);
    if (tempMatch && (root.tempText === "--°C" || root.tempText === "--")) {
      root.tempText = tempMatch[1].replace(/^\+/, "");
    }
    const windMatch = raw.match(/(\d+\s*km\/h|\d+\s*mph)/i);
    if (windMatch && root.windText === "--") {
      root.windText = windMatch[1];
    }
  }

  function refresh(force) {
    parseSummary(SystemInfo.weatherInfo);
    if (detailProc.running) return;
    const now = Date.now();
    const rawLoc = SystemInfo.effectiveWeatherLocation || "";
    const u = (BarConfig.weatherUnit === "u") ? "u" : "m";
    const cacheKey = rawLoc + "|" + u;
    if (!force && SystemInfo._cachedWeatherKey === cacheKey && SystemInfo._cachedWeatherMs > 0 && (now - SystemInfo._cachedWeatherMs) < 300000) {
      return;
    }
    const reqLoc = rawLoc.trim().replace(/\s+/g, "+").replace(/"/g, "");
    root.isRefreshing = true;
    detailProc._reqKey = cacheKey;
    detailProc.command = [
      "sh", "-c",
      "curl -s --connect-timeout 5 \"https://wttr.in/" + reqLoc + "?format=%C|%t|%f|%h|%w&" + u + "\" 2>/dev/null | head -n 1"
    ];
    detailProc.running = true;
  }

  Process {
    id: detailProc
    property string _reqKey: ""
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.isRefreshing = false;
        const line = text.trim();
        if (!line || line.indexOf("<") !== -1 || line.indexOf("Unknown") !== -1) return;
        const parts = line.split("|");
        if (parts.length >= 5) {
          if (parts[0].trim()) root.conditionText = parts[0].trim();
          if (parts[1].trim()) root.tempText = parts[1].trim().replace(/^\+/, "");
          if (parts[2].trim()) root.feelsLikeText = parts[2].trim().replace(/^\+/, "");
          if (parts[3].trim()) root.humidityText = parts[3].trim();
          if (parts[4].trim()) {
            // Strip leading arrow glyphs so wind stays clean text
            root.windText = parts[4].trim().replace(/^[↑↓←→↖↗↘↙\s]+/, "");
          }
          SystemInfo._cachedWeatherCond = root.conditionText;
          SystemInfo._cachedWeatherTemp = root.tempText;
          SystemInfo._cachedWeatherFeels = root.feelsLikeText;
          SystemInfo._cachedWeatherHum = root.humidityText;
          SystemInfo._cachedWeatherWind = root.windText;
          SystemInfo._cachedWeatherKey = detailProc._reqKey;
          SystemInfo._cachedWeatherMs = Date.now();
        }
      }
    }
    onExited: root.isRefreshing = false
  }

  Component.onCompleted: {
    parseSummary(SystemInfo.weatherInfo);
    refresh(false);
  }

  Connections {
    target: SystemInfo
    function onWeatherInfoChanged() {
      root.parseSummary(SystemInfo.weatherInfo);
    }
  }

  ColumnLayout {
    id: weatherCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 10

    // Main typography row (no icon box, no raw emojis)
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: root.locationLabel
          font.family: root.font
          font.pixelSize: 13
          font.bold: true
          color: root.accent
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: root.conditionText !== "" ? root.conditionText : (root.isRefreshing ? "Updating weather..." : "Current conditions")
          font.family: root.font
          font.pixelSize: 11
          color: root.theme.textSecondary
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      Text {
        text: root.tempText
        font.family: root.font
        font.pixelSize: 24
        font.bold: true
        color: root.theme.textPrimary
        Layout.alignment: Qt.AlignVCenter
      }

      Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: 13
        color: refreshHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
        scale: refreshMouse.pressed ? 0.88 : (refreshHover.hovered ? 1.06 : 1.0)
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        HoverHandler { id: refreshHover }

        Text {
          id: refreshIcon
          anchors.centerIn: parent
          text: "󰑐"
          font.family: root.font
          font.pixelSize: 13
          color: refreshHover.hovered ? root.accent : root.theme.textMuted
          Behavior on color { ColorAnimation { duration: 130 } }

          RotationAnimation {
            id: refreshSpin
            target: refreshIcon
            from: 0
            to: 360
            duration: 420
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          id: refreshMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            refreshSpin.restart();
            SystemInfo.refreshWeather();
            root.refresh(true);
          }
        }
      }
    }

    // Minimal clean metrics row (plain typography, no icons)
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { label: "Feels like", value: root.feelsLikeText },
          { label: "Humidity",   value: root.humidityText },
          { label: "Wind",       value: root.windText }
        ]
        delegate: Rectangle {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          radius: 9
          color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.045)

          ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 10
            spacing: 1

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: modelData.label
              font.family: root.font
              font.pixelSize: 9
              color: root.theme.textMuted
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: modelData.value
              font.family: root.font
              font.pixelSize: 11
              font.bold: true
              color: root.theme.textPrimary
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
