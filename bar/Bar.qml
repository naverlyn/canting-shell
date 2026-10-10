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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.barVisible

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 32
      color: '#363c3c3c'


      Item {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // Right section: Time + Workspaces + Now Playing
        Row {
          id: rightSection
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          // System Tray
          // There's an issue that some tray not display correctly.
          // https://github.com/quickshell-mirror/quickshell/issues/26
          // https://github.com/quickshell-mirror/quickshell/pull/777
          Rectangle {
            implicitHeight: 24
            implicitWidth: trayIcons.implicitWidth + 4
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
          // Time
          Rectangle {
            id: timeWidget
            height: 24
            width: timeDate.width + 16
            radius: 12
            color: timeHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }

            // Detects when the mouse is over the clock
            HoverHandler {
              id: timeHover
            }

            Row {
              id: timeDate
              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: root.theme.accentPrimary
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.timeString
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.dateString
                color: root.theme.textSecondary
                font.pixelSize: 12
                font.family: root.font
              }
            }

            // The floating calendar popup
            // The floating calendar popup
            PopupWindow {
              id: calendarPopup
              visible: timeHover.hovered || calBox.opacity > 0

              // 1. Explicitly set the Wayland surface size
              implicitWidth: 280
              implicitHeight: 308
              
              // 2. Make the surface background transparent so the border radius shows cleanly
              color: "transparent"

              anchor.window: timeWidget.QsWindow.window
              anchor.edges: Edges.Bottom
              anchor.gravity: Edges.Bottom
              anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
              anchor.onAnchoring: {
                const win = timeWidget.QsWindow.window;
                const widgetRect = win.contentItem.mapFromItem(
                  timeWidget, 0, 0, timeWidget.width, timeWidget.height
                );
                calendarPopup.anchor.rect = widgetRect;
              }

              Rectangle {
                id: calBox
                opacity: timeHover.hovered ? 1 : 0
                y: timeHover.hovered ? 8 : 0
                transformOrigin: Item.Top
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
                      // Using an Item wrapper helps center text and backgrounds perfectly in Grid layouts
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

          // Workspaces
          Row {
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
                height: 24
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

          // Weather Area
          Rectangle {
            height: 24
            width: weatherContent.width + 16 
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.StaticText
            Accessible.name: "Weather: " + SystemInfo.weatherInfo
            Row {
              id: weatherContent
              anchors.centerIn: parent
              spacing: 6
              Text {
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
              onClicked: weatherProcess.running = true
            }
          }
          
          // Control Center Trigger Button
          Rectangle {
            id: controlCenterButton
            height: 24
            width: controlCenterContent.width + 16
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.Button
            Accessible.name: "Control Center"

            Row {
              id: controlCenterContent
              anchors.centerIn: parent
              spacing: 6
              Text {
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
              property var test
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

        // Center section: Window Title (truly centered in bar)
        Rectangle {
          anchors.centerIn: parent
          height: 24
          width: Math.max(0, parent.width - 2 * Math.max(leftSection.width, rightSection.width) - 32)
          radius: 12
          color: root.theme.bgSurface

          Text {
            Accessible.role: Accessible.StaticText
            Accessible.name: "Active window: " + text
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            color: root.theme.textPrimary
            font.pixelSize: 13
            font.family: root.font
            elide: Text.ElideRight
            width: Math.min(implicitWidth, parent.width)
            anchors.centerIn: parent
          }
        }

        // Left section: System Info + System Tray
        Row {
          id: leftSection
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          // App grid launcher button
          Rectangle {
            id: appGridButton
            height: 24
            width: 28
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

          // System Info
          Row {
            id: sysInfo

            readonly property color batteryColor: {
              if (SystemInfo.batteryCharging) return root.theme.accentGreen;
              if (SystemInfo.batteryLevelRaw > 20) return root.theme.batteryGood;
              if (SystemInfo.batteryLevelRaw > 10) return root.theme.batteryWarning;
              return root.theme.batteryCritical;
            }

            spacing: 4

            // CPU
            Rectangle {
              id: cpuPill
              height: 24
              width: cpuContent.width + 12
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
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰻠"
                  color: root.theme.accentOrange
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.cpuUsage
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }
            }

            // Temperature
            Rectangle {
              id: tempPill
              height: 24
              width: tempContent.width + 12
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
                accent: root.theme.accentPrimary
                script: "temp"
              }

              Row {
                id: tempContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰔏"
                  color: root.theme.accentPrimary
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.temperature
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }
            }
            // Memory Usage
            Rectangle {
              id: memPill
              height: 24
              width: memContent.width + 12
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
                  anchors.verticalCenter: parent.verticalCenter
                  text: ""
                  color: root.theme.accentPrimary
                  font.pixelSize: 14
                  font.family: root.font
                }
                
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.memoryUsage
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }
            }

            // Disk usage
            Rectangle {
              id: diskButton
              height: 24
              width: diskContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              
              Accessible.role: Accessible.StaticText
              Accessible.name: "/ (" + SystemInfo.diskUsage + ")"

              MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
              }

              // Glow
              Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: root.theme.accentPrimary 
                opacity: mouseArea.containsMouse ? 0.15 : 0.0

                Behavior on opacity {
                  NumberAnimation { duration: 150 }
                }
              }

              Row {
                id: diskContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "" 
                  color: root.theme.accentPrimary 
                  font.pixelSize: 14
                  font.family: root.font
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "" + SystemInfo.diskUsage + "" 
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }

              InfoPopup {
                target: diskButton
                hovered: mouseArea.containsMouse
                theme: root.theme
                font: root.font
                title: "Disk"
                icon: "\uf0a0"
                accent: root.theme.accentPrimary
                script: "disk"
              }
            }
          }
        }
      }
    }
  }
}
