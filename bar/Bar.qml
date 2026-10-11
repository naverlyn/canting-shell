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
import "../ControlCenter"
import "./Components"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property bool barVisible: true

  // MPRIS active player
  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  IpcHandler {
    target: "bar"
    function toggle() { root.barVisible = !root.barVisible; }
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  // Brightness state
  property real brightnessValue: 0
  property real brightnessMax: 1

  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.brightnessMax > 0)
          root.brightnessValue = val / root.brightnessMax;
      }
    }
  }

  Process {
    id: brightnessSetProc
    running: false
  }

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) root.brightnessMax = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  Process {
    id: weatherProcess
    running: false
    onRunningChanged: {
      if (running) {
        SystemInfo.refreshWeather();
        running = false;
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData
      visible: root.barVisible && BarConfig.barVisible && (BarConfig.allMonitors || modelData === Quickshell.screens[0])

      anchors {
        top: BarConfig.position === "top"
        bottom: BarConfig.position === "bottom"
        left: true
        right: true
      }

      implicitHeight: BarConfig.barHeight + (BarConfig.floating ? 12 : 0)
      color: "transparent"

      Rectangle {
        id: barBackground
        anchors.fill: parent
        anchors.topMargin: BarConfig.floating && BarConfig.position === "top" ? 6 : 0
        anchors.bottomMargin: BarConfig.floating && BarConfig.position === "bottom" ? 6 : 0
        anchors.leftMargin: BarConfig.floating ? 12 : 0
        anchors.rightMargin: BarConfig.floating ? 12 : 0
        radius: BarConfig.floating ? 12 : 0
        color: (root.theme && root.theme.bgBase)
          ? Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, BarConfig.barOpacity)
          : Qt.rgba(0.21, 0.23, 0.23, BarConfig.barOpacity)
        border.color: BarConfig.floating ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)) : "transparent"
        border.width: BarConfig.floating ? 1 : 0
      }

      Item {
        id: barContentContainer
        anchors.fill: barBackground
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // Widget building blocks

        // 1. Applications Launcher Button
        Component {
          id: appGridComp
          Rectangle {
            id: appGridButton
            implicitHeight: 24
            implicitWidth: 28
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.Button
            Accessible.name: "Applications"

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: root.theme.accentPrimary
              opacity: appGridMouse.containsMouse ? 0.15 : 0.0
              Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Text {
              anchors.centerIn: parent
              text: "󰀻"
              color: root.theme.accentPrimary
              font.pixelSize: 14
              font.family: root.font
            }

            MouseArea {
              id: appGridMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: appGridProc.running = true
            }

            Process {
              id: appGridProc
              command: ["qs", "ipc", "call", "appgrid", "toggle"]
              running: false
            }
          }
        }

        // 2. CPU Usage Pill
        Component {
          id: cpuComp
          Rectangle {
            id: cpuPill
            implicitHeight: 24
            implicitWidth: cpuContent.implicitWidth + 14
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: cpuHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }
            Accessible.role: Accessible.StaticText
            Accessible.name: "CPU: " + SystemInfo.cpuUsage

            HoverHandler { id: cpuHover }

            InfoPopup {
              target: cpuPill
              hovered: cpuHover.hovered
              theme: root.theme
              font: root.font
              title: "CPU"
              icon: "󰻠"
              accent: root.theme.accentOrange
              script: "cpu"
            }

            Row {
              id: cpuContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                id: cpuIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "󰻠"
                color: root.theme.accentOrange
                font.pixelSize: 14
                font.family: root.font
              }
              Text {
                id: cpuText
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.cpuUsage
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }
          }
        }

        // 3. CPU Temperature Pill
        Component {
          id: tempComp
          Rectangle {
            id: tempPill
            implicitHeight: 24
            implicitWidth: tempContent.implicitWidth + 14
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: tempHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }
            Accessible.role: Accessible.StaticText
            Accessible.name: "Temperature: " + SystemInfo.temperature

            HoverHandler { id: tempHover }

            InfoPopup {
              target: tempPill
              hovered: tempHover.hovered
              theme: root.theme
              font: root.font
              title: "Temperature"
              icon: "󰔏"
              accent: root.theme.accentRed
              script: "temp"
            }

            Row {
              id: tempContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                id: tempIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "󰔏"
                color: root.theme.accentRed
                font.pixelSize: 14
                font.family: root.font
              }
              Text {
                id: tempText
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.temperature
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }
          }
        }

        // 4. Memory (RAM) Pill
        Component {
          id: memoryComp
          Rectangle {
            id: memPill
            implicitHeight: 24
            implicitWidth: memContent.implicitWidth + 14
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: memHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }
            Accessible.role: Accessible.StaticText
            Accessible.name: "Memory Usage: " + SystemInfo.memoryUsage

            HoverHandler { id: memHover }

            InfoPopup {
              target: memPill
              hovered: memHover.hovered
              theme: root.theme
              font: root.font
              title: "Memory"
              icon: "\uf2db"
              accent: root.theme.accentPrimary
              script: "mem"
            }
            
            Row {
              id: memContent
              anchors.centerIn: parent
              spacing: 6
              
              Text {
                id: memIcon
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: root.theme.accentPrimary
                font.pixelSize: 14
                font.family: root.font
              }
              
              Text {
                id: memText
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.memoryUsage
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }
          }
        }

        // 5. Disk Usage Pill
        Component {
          id: diskComp
          Rectangle {
            id: diskButton
            implicitHeight: 24
            implicitWidth: diskContent.implicitWidth + 14
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface
            
            Accessible.role: Accessible.StaticText
            Accessible.name: "/ (" + SystemInfo.diskUsage + ")"

            MouseArea {
              id: diskMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
            }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: root.theme.accentPrimary 
              opacity: diskMouseArea.containsMouse ? 0.15 : 0.0
              Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Row {
              id: diskContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                id: diskIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "" 
                color: root.theme.accentPrimary 
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                id: diskText
                anchors.verticalCenter: parent.verticalCenter
                text: "" + SystemInfo.diskUsage + "" 
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }

            InfoPopup {
              target: diskButton
              hovered: diskMouseArea.containsMouse
              theme: root.theme
              font: root.font
              title: "Disk"
              icon: "\uf0a0"
              accent: root.theme.accentPrimary
              script: "disk"
            }
          }
        }

        // 6. Active Window Title
        Component {
          id: windowTitleComp
          Rectangle {
            id: winTitleWidget
            implicitHeight: 24
            height: implicitHeight
            readonly property string curSec: BarConfig.getWidgetSection("windowTitle")
            readonly property real availableCenterSpace: curSec === "center"
              ? Math.max(60, barContentContainer.width - 2 * Math.max(leftSection.width, rightSection.width) - 32)
              : 260
            implicitWidth: curSec === "center"
              ? (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, availableCenterSpace)) : 0)
              : (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, 260)) : 0)
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface
            clip: true

            Text {
              id: titleText
              Accessible.role: Accessible.StaticText
              Accessible.name: "Active window: " + text
              text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
              color: root.theme.textPrimary
              font.pixelSize: 13
              font.family: root.font
              elide: Text.ElideRight
              width: Math.min(implicitWidth, parent.width - 16)
              anchors.centerIn: parent
            }
          }
        }

        // 7. Workspaces Pill Group
        Component {
          id: workspacesComp
          Row {
            id: wsRow
            height: 24
            width: implicitWidth
            spacing: 4

            Repeater {
              model: Hyprland.workspaces

              Rectangle {
                id: wsPill
                required property var modelData
                property bool urgentBlink: false

                Accessible.role: Accessible.Button
                Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

                width: modelData.focused ? 32 : 24
                implicitWidth: modelData.focused ? 32 : 24
                height: 24
                implicitHeight: 24
                radius: 12
                color: modelData.focused ? root.theme.accentPrimary :
                       modelData.urgent && urgentBlink ? root.theme.accentRed : root.theme.bgSurface

                Behavior on color {
                  ColorAnimation { duration: 150 }
                }

                SequentialAnimation {
                  loops: Animation.Infinite
                  running: wsPill.modelData.urgent && !wsPill.modelData.focused

                  PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
                  PauseAnimation { duration: 500 }
                  PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
                  PauseAnimation { duration: 500 }

                  onStopped: wsPill.urgentBlink = false
                }

                Text {
                  anchors.centerIn: parent
                  text: wsPill.modelData.id
                  color: wsPill.modelData.focused ? root.theme.bgBase : root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                  font.bold: wsPill.modelData.focused
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: wsPill.modelData.activate()
                }

                Behavior on width {
                  NumberAnimation { duration: 150 }
                }
              }
            }
          }
        }

        // 8. Weather Info Pill
        Component {
          id: weatherComp
          Rectangle {
            id: weatherWidget
            implicitHeight: 24
            implicitWidth: weatherContent.implicitWidth + 16
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.Button
            Accessible.name: "Weather: " + SystemInfo.weatherInfo

            Row {
              id: weatherContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                id: weatherText
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.weatherInfo
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: SystemInfo.refreshWeather()
            }
          }
        }

        // 9. Clock & Calendar Popup
        Component {
          id: clockComp
          Rectangle {
            id: timeWidget
            implicitHeight: 24
            implicitWidth: timeDate.implicitWidth + 16
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: timeHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler {
              id: timeHover
            }

            Row {
              id: timeDate
              anchors.centerIn: parent
              spacing: 8

              Text {
                id: clockTimeText
                anchors.verticalCenter: parent.verticalCenter
                text: Time.timeString
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }

              Text {
                id: clockDateText
                anchors.verticalCenter: parent.verticalCenter
                text: Time.dateString
                visible: BarConfig.showDate
                color: root.theme.textSecondary
                font.pixelSize: 12
                font.family: root.font
              }
            }

            PopupWindow {
              id: calendarPopup
              visible: timeHover.hovered || calBox.opacity > 0
              implicitWidth: 280
              implicitHeight: 308
              color: "transparent"

              anchor.window: timeWidget.QsWindow.window
              anchor.edges: BarConfig.position === "bottom" ? Edges.Top : Edges.Bottom
              anchor.gravity: BarConfig.position === "bottom" ? Edges.Top : Edges.Bottom
              anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
              anchor.onAnchoring: {
                const win = timeWidget.QsWindow.window;
                if (!win) return;
                const widgetRect = win.contentItem.mapFromItem(
                  timeWidget, 0, 0, timeWidget.width, timeWidget.height
                );
                calendarPopup.anchor.rect = widgetRect;
              }

              Rectangle {
                id: calBox
                opacity: timeHover.hovered ? 1 : 0
                y: timeHover.hovered ? (BarConfig.position === "bottom" ? -8 : 8) : 0
                transformOrigin: BarConfig.position === "bottom" ? Item.Bottom : Item.Top
                scale: timeHover.hovered ? 1 : 0.96
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                width: 280
                height: 300
                color: root.theme.bgSurface
                radius: 12
                border.color: root.theme.bgBase
                border.width: 2

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 16
                  spacing: 12

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                    color: root.theme.accentPrimary
                    font.pixelSize: 14
                    font.bold: true
                    font.family: root.font
                  }

                  DayOfWeekRow {
                    locale: Qt.locale("en_US")
                    Layout.fillWidth: true
                    delegate: Text {
                      text: model.shortName
                      color: root.theme.textSecondary
                      font.pixelSize: 12
                      font.family: root.font
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
                        color: root.theme.accentPrimary
                        visible: model.today
                      }

                      Text {
                        anchors.centerIn: parent
                        text: model.day
                        color: model.today ? root.theme.bgBase : root.theme.textPrimary
                        font.pixelSize: 12
                        font.family: root.font
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // 10. System Tray
        Component {
          id: trayComp
          Rectangle {
            id: trayWidget
            implicitHeight: 24
            implicitWidth: Math.max(24, trayIcons.implicitWidth + 8)
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface

            RowLayout {
              id: trayIcons
              anchors.centerIn: parent
              spacing: 2

              Repeater {
                model: SystemTray.items

                MouseArea {
                  id: trayDelegate
                  required property SystemTrayItem modelData

                  Accessible.role: Accessible.Button
                  Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

                  Layout.preferredWidth: 24
                  Layout.preferredHeight: 24

                  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                  onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                      modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                      if (modelData.hasMenu) {
                        menuAnchor.open()
                      }
                    } else if (mouse.button === Qt.MiddleButton) {
                      modelData.secondaryActivate()
                    }
                  }

                  IconImage {
                    anchors.centerIn: parent
                    source: trayDelegate.modelData.icon
                    implicitSize: 16
                  }

                  QsMenuAnchor {
                    id: menuAnchor
                    menu: trayDelegate.modelData.menu

                    anchor.window: trayDelegate.QsWindow.window
                    anchor.adjustment: PopupAdjustment.Flip
                    anchor.onAnchoring: {
                      const window = trayDelegate.QsWindow.window;
                      if (!window) return;
                      const widgetRect = window.contentItem.mapFromItem(
                        trayDelegate, 0, trayDelegate.height,
                        trayDelegate.width, trayDelegate.height);
                      menuAnchor.anchor.rect = widgetRect;
                    }
                  }
                }
              }
            }
          }
        }

        // 11. Control Center Button
        Component {
          id: controlCenterComp
          Rectangle {
            id: controlCenterButton
            implicitHeight: 24
            implicitWidth: controlCenterContent.implicitWidth + 16
            height: implicitHeight
            width: implicitWidth
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.Button
            Accessible.name: "Control Center"

            Row {
              id: controlCenterContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                id: ccIcon
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: root.theme.textPrimary
                font.pixelSize: 10
                font.family: root.font
              }
            }

            MouseArea {
              id: controlCenterArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: controlCenter.visible = !controlCenter.visible
            }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: root.theme.accentPrimary 
              opacity: controlCenterArea.containsMouse ? 0.0 : 0.15
              Behavior on opacity {
                NumberAnimation { duration: 150 }
              }
            }

            ControlCenter {
              id: controlCenter
              theme: root.theme
              font: root.font
              anchorTarget: controlCenterButton
            }
          }
        }

        // Widget component resolver
        function getWidgetComponent(widgetId) {
          switch (widgetId) {
            case "appGrid": return appGridComp;
            case "cpu": return cpuComp;
            case "temp": return tempComp;
            case "memory": return memoryComp;
            case "disk": return diskComp;
            case "windowTitle": return windowTitleComp;
            case "workspaces": return workspacesComp;
            case "weather": return weatherComp;
            case "clock": return clockComp;
            case "tray": return trayComp;
            case "controlCenter": return controlCenterComp;
            default: return null;
          }
        }

        // Section layouts

        // 1. Left Section
        Row {
          id: leftSection
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Repeater {
            model: BarConfig.leftWidgets
            delegate: Loader {
              id: leftLoader
              required property string modelData
              sourceComponent: barContentContainer.getWidgetComponent(modelData)
              visible: sourceComponent !== null && BarConfig.isWidgetVisible(modelData)
              width: visible ? (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0) : 0
              height: 24
              anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }
          }
        }

        // 2. Center Section
        Row {
          id: centerSection
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Repeater {
            model: BarConfig.centerWidgets
            delegate: Loader {
              id: centerLoader
              required property string modelData
              sourceComponent: barContentContainer.getWidgetComponent(modelData)
              visible: sourceComponent !== null && BarConfig.isWidgetVisible(modelData)
              width: visible ? (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0) : 0
              height: 24
              anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }
          }
        }

        // 3. Right Section
        Row {
          id: rightSection
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Repeater {
            model: BarConfig.rightWidgets
            delegate: Loader {
              id: rightLoader
              required property string modelData
              sourceComponent: barContentContainer.getWidgetComponent(modelData)
              visible: sourceComponent !== null && BarConfig.isWidgetVisible(modelData)
              width: visible ? (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0) : 0
              height: 24
              anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }
          }
        }
      }
    }
  }
}
