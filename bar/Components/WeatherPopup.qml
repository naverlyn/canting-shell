import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "WeatherUtils.js" as WeatherUtils

Item {
  id: popup
  visible: false
  width: 0
  height: 0

  required property Item target
  property Item barItem: null
  property var hostRoot: (target && target.hostRoot !== undefined) ? target.hostRoot : null
  property bool hovered: false
  property bool pinned: false
  property var theme: DefaultTheme {}
  property string font: (popup.theme && popup.theme.fontFamily) ? popup.theme.fontFamily : "Lato Nerd Font"
  readonly property string effectiveNerdFont: {
    const families = Qt.fontFamilies();
    const monoPref = (popup.theme && popup.theme.monoFont) ? popup.theme.monoFont : "JetBrainsMono Nerd Font";
    const candidates = [
      monoPref,
      "JetBrainsMono Nerd Font",
      "JetBrainsMonoNL Nerd Font",
      "DroidSansM Nerd Font",
      "FantasqueSansM Nerd Font",
      popup.font,
      "Lato Nerd Font",
      "monospace"
    ];
    for (let i = 0; i < candidates.length; i++) {
      if (candidates[i] && families.indexOf(candidates[i]) !== -1) return candidates[i];
    }
    return popup.font || "monospace";
  }
  property string location: "Bekasi"
  property color accent: "#ffffff"
  property string barPosition: BarConfig.position
  property string title: "Weather"
  property string icon: "󰖐"
  property bool hideHeader: true

  readonly property int preferredWidth: {
    const scr = (target && target.QsWindow && target.QsWindow.window && target.QsWindow.window.screen) ? target.QsWindow.window.screen : null;
    return scr ? Math.min(592, scr.width - 52) : 592;
  }
  readonly property int preferredHeight: {
    const scr = (target && target.QsWindow && target.QsWindow.window && target.QsWindow.window.screen) ? target.QsWindow.window.screen : null;
    const isAll = (popup.selectedDayIndex === 3);
    const targetH = isAll ? 572 : 452;
    return scr ? Math.min(targetH, scr.height - 118) : targetH;
  }

  signal pinToggled()

  property bool effectiveHovered: false
  readonly property bool isSharedCardHovered: Boolean(
    barItem && barItem.activeInfoProvider === popup && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered
  )
  readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
  readonly property bool isWeatherActive: isDetailsActive

  Timer {
    id: closeGraceTimer
    interval: 150
    repeat: false
    onTriggered: {
      if (!popup.hovered && !popup.isSharedCardHovered) {
        popup.effectiveHovered = false;
        if (popup.barItem && popup.barItem.activeInfoProvider === popup && !popup.pinned) {
          popup.barItem.activeInfoProvider = null;
        }
      }
    }
  }

  onHoveredChanged: {
    if (hovered) {
      if (barItem && barItem.activeInfoProvider && barItem.activeInfoProvider !== popup && barItem.activeInfoProvider.pinned) return;
      closeGraceTimer.stop();
      effectiveHovered = true;
      if (barItem) {
        if (barItem.activeInfoProvider && barItem.activeInfoProvider !== popup) {
          barItem.activeInfoProvider.effectiveHovered = false;
        }
        barItem.activeInfoProvider = popup;
      }
    } else if (!isSharedCardHovered) {
      closeGraceTimer.restart();
    }
  }

  onIsSharedCardHoveredChanged: {
    if (isSharedCardHovered) {
      closeGraceTimer.stop();
      effectiveHovered = true;
    } else if (!hovered) {
      closeGraceTimer.restart();
    }
  }

  onPinnedChanged: {
    if (pinned && barItem) {
      if (barItem.activeInfoProvider && barItem.activeInfoProvider !== popup && barItem.activeInfoProvider.target && barItem.activeInfoProvider.target.isPinned !== undefined) {
        barItem.activeInfoProvider.target.isPinned = false;
      }
      barItem.activeInfoProvider = popup;
    } else if (!pinned && !hovered && !isSharedCardHovered && barItem && barItem.activeInfoProvider === popup) {
      barItem.activeInfoProvider = null;
    }
  }

  Component.onDestruction: {
    if (barItem && barItem.activeInfoProvider === popup) {
      barItem.activeInfoProvider = null;
    }
  }
  property bool isLoading: false
  property bool hasValidData: false

  // Current conditions state
  property string conditionText: "Loading..."
  property string tempText: "--°C"
  property string feelsLikeText: "--°C"
  property string humidityText: "--%"
  property string windText: "-- km/h"
  property string precipText: "0.0 mm"
  property string uvText: "UV 0"
  property string pressureText: "-- hPa"
  property string sunriseText: "--"
  property string sunsetText: "--"
  property string moonPhaseText: ""

  // Forecast state: array of 3 day objects
  property var forecastDays: []
  property int selectedDayIndex: (BarConfig.weatherMode === "full") ? 3 : 0

  function getWeatherIcon(cond, isNight) { return WeatherUtils.getWeatherIcon(cond, isNight); }
  function formatDayLabel(dateStr, index) { return WeatherUtils.formatDayLabel(dateStr, index); }
  function formatFullDate(dateStr, index) { return WeatherUtils.formatFullDate(dateStr, index); }

  function parseFromSummary(raw) {
    if (!raw || raw === "Loading..." || raw.includes("N/A")) return;
    const tempMatch = raw.match(/([+-]?\d+°[CF])/);
    if (tempMatch && popup.tempText === "--°C") {
      popup.tempText = tempMatch[1].replace(/^\+/, "");
    }
  }

  function parseWeatherData(data) {
    WeatherUtils.parseWeatherData(popup, data, BarConfig.weatherUnit === "u");
  }

  Process {
    id: proc
    command: ["sh", Qt.resolvedUrl("../scripts/weather.sh").toString().replace("file://", ""), popup.location || "Bekasi", BarConfig.weatherUnit || "m", BarConfig.weatherMode || "compact", "false"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        popup.isLoading = false;
        if (text && text.trim().length > 0) {
          try {
            const data = JSON.parse(text);
            if (!data.error) {
              popup.parseWeatherData(data);
            }
          } catch (e) {
            console.warn("[WeatherPopup] JSON parse error:", e);
          }
        }
      }
    }
    onExited: (code) => {
      popup.isLoading = false;
    }
  }

  readonly property string _cfgWeatherUnit: BarConfig.weatherUnit
  readonly property string _cfgWeatherMode: BarConfig.weatherMode

  on_CfgWeatherUnitChanged: {
    popup.refresh(true);
  }
  on_CfgWeatherModeChanged: {
    popup.selectedDayIndex = (BarConfig.weatherMode === "full") ? 3 : 0;
  }

  function refresh(force) {
    popup.parseFromSummary(SystemInfo.weatherInfo);
    popup.isLoading = true;
    if (proc.running) {
      proc.running = false;
    }
    const forceFlag = (force === true) ? "true" : "false";
    proc.command = ["sh", Qt.resolvedUrl("../scripts/weather.sh").toString().replace("file://", ""), popup.location || "Bekasi", BarConfig.weatherUnit || "m", BarConfig.weatherMode || "compact", forceFlag];
    proc.running = true;
  }

  onLocationChanged: {
    refresh(true);
  }

  onIsWeatherActiveChanged: {
    if (isWeatherActive && !hasValidData) {
      refresh(false);
    }
  }

  Component.onCompleted: {
    popup.parseFromSummary(SystemInfo.weatherInfo);
    if (popup.isWeatherActive) {
      popup.refresh(false);
    }
  }

  Timer {
    interval: 900
    repeat: false
    running: true
    onTriggered: {
      if (!popup.hasValidData && !popup.isLoading) {
        popup.refresh(false);
      }
    }
  }

  Timer {
    interval: Math.max(5, BarConfig.weatherIntervalMinutes || 15) * 60 * 1000
    repeat: true
    running: true
    onTriggered: popup.refresh(false)
  }

  property Component contentComponent: Component {
    Item {
      width: popup.preferredWidth
      height: popup.preferredHeight
      implicitWidth: popup.preferredWidth
      implicitHeight: popup.preferredHeight

    ColumnLayout {
      id: mainCol
      anchors.fill: parent
      spacing: 10

      // Header Bar
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          width: 18
          horizontalAlignment: Text.AlignHCenter
          text: "󰖐"
          color: popup.accent
          font.pixelSize: 16
          font.family: popup.effectiveNerdFont
        }

        Text {
          text: "Weather Forecast · " + (popup.location || "Bekasi")
          color: popup.theme.textPrimary
          font.pixelSize: 14
          font.bold: true
          font.family: popup.font
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        // Pin Button
        Rectangle {
          width: 26
          height: 26
          radius: 6
          color: pinHover.hovered ? popup.theme.bgSurface : "transparent"
          scale: pinHover.hovered ? 1.05 : 1.0
          Behavior on scale { NumberAnimation { duration: 120 } }
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: popup.pinned ? "󰤱" : "󰤰"
            color: popup.pinned ? popup.accent : popup.theme.textSecondary
            font.pixelSize: 13
            font.family: popup.effectiveNerdFont
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
          width: 26
          height: 26
          radius: 6
          color: refHover.hovered ? popup.theme.bgSurface : "transparent"
          scale: refHover.hovered ? 1.05 : 1.0
          Behavior on scale { NumberAnimation { duration: 120 } }
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            id: refIcon
            anchors.centerIn: parent
            text: "󰑐"
            color: popup.isLoading ? popup.accent : popup.theme.textSecondary
            font.pixelSize: 13
            font.family: popup.effectiveNerdFont
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
            onClicked: popup.refresh(true)
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.08)
      }

      // Hero Banner (styled identically to Control Center Weather Card with interactive hover polish)
      Rectangle {
        id: heroBanner
        Layout.fillWidth: true
        implicitHeight: 64
        radius: 10
        color: heroHover.hovered
          ? Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.07)
          : Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.05)
        border.color: heroHover.hovered
          ? Qt.rgba(popup.accent.r, popup.accent.g, popup.accent.b, 0.4)
          : Qt.rgba(popup.theme.bgBorder.r, popup.theme.bgBorder.g, popup.theme.bgBorder.b, 0.5)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        HoverHandler { id: heroHover }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 14
          spacing: 12

          Rectangle {
            width: 44
            height: 44
            radius: 10
            color: Qt.rgba(popup.accent.r, popup.accent.g, popup.accent.b, 0.16)

            Text {
              anchors.centerIn: parent
              text: popup.getWeatherIcon(popup.conditionText, false)
              font.family: popup.effectiveNerdFont
              font.pixelSize: 24
              color: popup.accent
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: popup.conditionText
              font.family: popup.font
              font.pixelSize: 16
              font.bold: true
              color: popup.theme.textPrimary
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: (popup.location || "Bekasi") + (popup.forecastDays.length > 0 ? ("  •  High " + popup.forecastDays[0].maxTemp + "  ·  Low " + popup.forecastDays[0].minTemp) : "")
              font.family: popup.font
              font.pixelSize: 12
              color: popup.theme.textMuted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Text {
            text: popup.tempText
            font.family: popup.font
            font.pixelSize: 28
            font.bold: true
            color: popup.accent
          }
        }
      }

      // 4 Detail Pills (Feels, Humid, Wind, Rain) with distinct icon & label spacing
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: [
            { icon: "󰔏", label: "Feels", value: popup.feelsLikeText },
            { icon: "󰖎", label: "Humid", value: popup.humidityText },
            { icon: "󰖝", label: "Wind",  value: popup.windText },
            { icon: "󰖗", label: "Rain",  value: popup.precipText }
          ]

          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 8
            color: pillHover.hovered
              ? Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.08)
              : Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.04)
            border.color: pillHover.hovered
              ? Qt.rgba(popup.accent.r, popup.accent.g, popup.accent.b, 0.4)
              : Qt.rgba(popup.theme.bgBorder.r, popup.theme.bgBorder.g, popup.theme.bgBorder.b, 0.3)
            border.width: 1

            transform: Translate {
              y: pillHover.hovered ? -2 : 0
              Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: pillHover }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3

              Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5

                Text {
                  width: 14
                  horizontalAlignment: Text.AlignHCenter
                  text: modelData.icon
                  font.family: popup.effectiveNerdFont
                  font.pixelSize: 11
                  color: popup.accent
                }

                Text {
                  text: modelData.label
                  font.family: popup.font
                  font.pixelSize: 11
                  color: popup.theme.textMuted
                }
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: modelData.value
                font.family: popup.font
                font.pixelSize: 12
                font.bold: true
                color: popup.theme.textPrimary
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      // Forecast Section Header & Sliding Segmented Tabs
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
          text: "Forecast"
          font.family: popup.font
          font.pixelSize: 13
          font.bold: true
          color: popup.theme.textMuted
          Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Sliding Segmented Tab Controller
        Rectangle {
          id: tabContainer
          implicitHeight: 32
          implicitWidth: tabRow.implicitWidth + 8
          radius: 8
          color: Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.04)
          border.color: Qt.rgba(popup.theme.bgBorder.r, popup.theme.bgBorder.g, popup.theme.bgBorder.b, 0.4)
          border.width: 1

          // Sliding active pill background indicator
          Rectangle {
            id: activePill
            y: 3
            height: parent.height - 6
            radius: 6
            color: Qt.rgba(popup.accent.r, popup.accent.g, popup.accent.b, 0.18)
            border.color: popup.accent
            border.width: 1

            readonly property Item activeItem: (tabRepeater && tabRepeater.count > popup.selectedDayIndex && popup.selectedDayIndex >= 0)
              ? tabRepeater.itemAt(popup.selectedDayIndex)
              : null

            x: activeItem ? (activeItem.x + 4) : 4
            width: activeItem ? activeItem.width : 0

            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          }

          Row {
            id: tabRow
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            spacing: 2

            Repeater {
              id: tabRepeater
              model: [
                { index: 0, label: popup.forecastDays.length > 0 ? popup.forecastDays[0].tabLabel : "Today" },
                { index: 1, label: popup.forecastDays.length > 1 ? popup.forecastDays[1].tabLabel : "Tomorrow" },
                { index: 2, label: popup.forecastDays.length > 2 ? popup.forecastDays[2].tabLabel : "Day 3" },
                { index: 3, label: "All Days" }
              ]

              delegate: Item {
                id: tabDelegate
                required property var modelData
                implicitWidth: tabLabelText.implicitWidth + 18
                implicitHeight: parent.height

                Text {
                  id: tabLabelText
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: popup.font
                  font.pixelSize: 12
                  font.bold: popup.selectedDayIndex === modelData.index
                  color: popup.selectedDayIndex === modelData.index
                    ? popup.accent
                    : (tabHover.hovered ? popup.theme.textPrimary : popup.theme.textSecondary)

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                HoverHandler { id: tabHover }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (popup.selectedDayIndex !== modelData.index) {
                      popup.selectedDayIndex = modelData.index;
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Animated Forecast Content Area
      WeatherForecastContent {
        hostPopup: popup
      }

      // Astronomy / Sun & Moon Footer Bar with distinct accented icons
      Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 6
        color: Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.03)

        RowLayout {
          anchors.centerIn: parent
          spacing: 12

          Row {
            spacing: 5
            Text {
              width: 14
              horizontalAlignment: Text.AlignHCenter
              text: "󰖚"
              font.family: popup.effectiveNerdFont
              font.pixelSize: 13
              color: popup.accent
            }
            Text {
              text: "Sunrise: " + popup.sunriseText
              font.family: popup.font
              font.pixelSize: 11
              color: popup.theme.textMuted
            }
          }

          Text {
            text: "•"
            font.family: popup.font
            font.pixelSize: 10
            color: popup.theme.textMuted
          }

          Row {
            spacing: 5
            Text {
              width: 14
              horizontalAlignment: Text.AlignHCenter
              text: "󰖛"
              font.family: popup.effectiveNerdFont
              font.pixelSize: 13
              color: popup.accent
            }
            Text {
              text: "Sunset: " + popup.sunsetText
              font.family: popup.font
              font.pixelSize: 11
              color: popup.theme.textMuted
            }
          }

          Text {
            visible: popup.moonPhaseText !== ""
            text: "•"
            font.family: popup.font
            font.pixelSize: 10
            color: popup.theme.textMuted
          }

          Row {
            visible: popup.moonPhaseText !== ""
            spacing: 5
            Text {
              width: 14
              horizontalAlignment: Text.AlignHCenter
              text: "󰽥"
              font.family: popup.effectiveNerdFont
              font.pixelSize: 13
              color: popup.accent
            }
            Text {
              text: "Moon: " + popup.moonPhaseText
              font.family: popup.font
              font.pixelSize: 11
              color: popup.theme.textMuted
            }
          }
        }
      }
    }
    }
  }
}

