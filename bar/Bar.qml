import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications


Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property bool barVisible: true
  property string memoryUsage: "0.0 / 0 GiB (-100%)"
  property string diskUsage: "Loading..."
  property string weatherInfo: "Loading..."

  // Memory fetch process
  Process {
    id: memProcess
    command: ["sh", "-c", "free -g | awk '/Mem:/ {used=$3; total=$2; pct=(total>0)?(used / total*100):0; printf \"%.1f/%.1f GiB (%.0f%%)\", used, total, pct}'"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        root.memoryUsage = data.trim();
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: memProcess.running = true
  }

  // Disk process
  Process {
    id: diskProcess
    command: ["sh", "-c", "df -h / /home 2>/dev/null | awk 'NR>1 {printf \"%s (%s) \", $6, $5}' | sed 's/ $//'"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        root.diskUsage = data.trim();
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: {
      memProcess.running = true
      diskProcess.running = true
    }
  }

  // Weather process
  Process {
    id: weatherProcess
    command: ["curl", "-s", "wttr.in/Jakarta?format=4"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        root.weatherInfo = data.trim();
      }
    }
  }

  // Timer
  Timer {
    interval: 900000
    running: true
    repeat: true
    onTriggered: {
      memProcess.running = true
      diskProcess.running = true
      weatherProcess.running = true
    }
  }

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
    function toggle(): void { root.barVisible = !root.barVisible; }
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

        // Right section: Time + Workspaces + Now Playing + Weather
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
            height: 24
            width: timeDate.width + 16
            radius: 12
            color: root.theme.bgSurface

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

          // Now Playing (set to disabled)
          // Rectangle {
          //   height: 24
          //   width: nowPlayingContent.width + 16
          //   radius: 12
          //   color: root.theme.bgSurface
          //   visible: root.activePlayer !== null

          //   Accessible.role: Accessible.Button
          //   Accessible.name: {
          //     if (!root.activePlayer) return "No media";
          //     const artist = root.activePlayer.trackArtist || "";
          //     const title = root.activePlayer.trackTitle || "";
          //     return "Now playing: " + (artist ? artist + " - " : "") + title;
          //   }

          //   Row {
          //     id: nowPlayingContent
          //     anchors.verticalCenter: parent.verticalCenter
          //     anchors.left: parent.left
          //     anchors.leftMargin: 8
          //     spacing: 6

          //     Text {
          //       anchors.verticalCenter: parent.verticalCenter
          //       text: root.activePlayer && root.activePlayer.isPlaying ? "󰐊" : "󰏤"
          //       color: root.theme.accentPrimary
          //       font.pixelSize: 14
          //       font.family: root.font
          //     }

          //     Text {
          //       anchors.verticalCenter: parent.verticalCenter
          //       text: {
          //         if (!root.activePlayer) return "";
          //         const artist = root.activePlayer.trackArtist || "";
          //         const title = root.activePlayer.trackTitle || "";
          //         return artist ? artist + " - " + title : title;
          //       }
          //       color: root.theme.textPrimary
          //       font.pixelSize: 11
          //       font.family: root.font
          //       elide: Text.ElideRight
          //       width: Math.min(implicitWidth, 200)
          //     }
          //   }

          //   MouseArea {
          //     anchors.fill: parent
          //     cursorShape: Qt.PointingHandCursor
          //     onClicked: root.activePlayer.togglePlaying()
          //   }
          // }
          // Weather
          Rectangle {
            height: 24
            width: weatherContent.width + 16 
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.StaticText
            Accessible.name: "Weather: " + root.weatherInfo
            Row {
              id: weatherContent
              anchors.centerIn: parent
              spacing: 6
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherInfo
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

          // Control Center (WIP)
          // TODO: Wi-Fi, Bluetooth, Display, Volume, Microphone, switch audio, airplane mode, etc.
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
              color: root.theme.bgSurface
              opacity: controlCenterArea.containsMouse ? 0.0 : 0.15
              Behavior on opacity {
                NumberAnimation { duration: 150 }
              }
            }
            ControlCenter {
              id: controlCenter
              theme: root.theme.accentPrimary
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
          // testRectangle (apps, disabled)
          // Rectangle {
          //   id: testButtonContent
          //   height: 24
          //   width:  testContent.implicitWidth + 16
          //   radius: 12
          //   color: root.theme.bgSurface

          //   Row {
          //     id: testContent
          //     anchors.centerIn: parent
          //     spacing: 6

          //     Text {
          //       anchors.verticalCenter: parent.verticalCenter
          //       text: "󰀻"
          //       color: root.theme.textPrimary
          //       font.pixelSize: 14
          //       font.family: root.font
          //     }
              
          //     Text {
          //       anchors.verticalCenter: parent.verticalCenter
          //       text: "Apps"
          //       color: root.theme.textPrimary
          //       font.pixelSize: 11
          //       font.family: root.font
          //     }
          //   }
          // }

          // Network
            Rectangle {
              height: 24
              width: netContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: {
                if (SystemInfo.networkType === "ethernet") return "Network: Ethernet"
                if (SystemInfo.networkType === "wifi") return "Network: WiFi " + SystemInfo.networkInfo
                return "Network: Disconnected"
              }

              Row {
                id: netContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: {
                    if (SystemInfo.networkType === "ethernet") return "󰈀"
                    if (SystemInfo.networkType === "wifi") return "󰖩"
                    return "󰖪"
                  }
                  color: SystemInfo.networkType === "disconnected" ? root.theme.textMuted : root.theme.accentGreen
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.networkInfo
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }
            }

            
          // Volume
          Rectangle {
            height: 24
            width: volContent.width + 12
            radius: 12
            color: root.theme.bgSurface

            Accessible.role: Accessible.StaticText
            Accessible.name: {
              const sink = Pipewire.defaultAudioSink;
              if (!sink || !sink.audio) return "Volume";
              if (sink.audio.muted) return "Volume: muted";
              return "Volume: " + Math.round(sink.audio.volume * 100) + "%";
            }

            Row {
              id: volContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio || sink.audio.muted || sink.audio.volume <= 0) return "󰖁";
                  if (sink.audio.volume < 0.33) return "󰕿";
                  if (sink.audio.volume < 0.66) return "󰖀";
                  return "󰕾";
                }
                color: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio || sink.audio.muted) return root.theme.textMuted;
                  return root.theme.accentPrimary;
                }
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio) return "–";
                  if (sink.audio.muted) return "Mute";
                  return Math.round(sink.audio.volume * 100) + "%";
                }
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton
              onClicked: {
                const sink = Pipewire.defaultAudioSink;
                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
              }
              onWheel: (wheel) => {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return;
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta));
              }
            }
          }

          // Brightness
          Rectangle {
            height: 24
            width: brightContent.width + 12
            radius: 12
            color: root.theme.bgSurface
            visible: brightnessFile.path !== ""

            Accessible.role: Accessible.StaticText
            Accessible.name: "Brightness: " + Math.round(root.brightnessValue * 100) + "%"

            Row {
              id: brightContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                color: root.theme.accentOrange
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.brightnessValue * 100) + "%"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onWheel: (wheel) => {
                brightnessSetProc.command = wheel.angleDelta.y > 0
                  ? ["brightnessctl", "set", "5%+"]
                  : ["brightnessctl", "set", "5%-"];
                brightnessSetProc.running = true;
              }
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
              height: 24
              width: cpuContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: "CPU: " + SystemInfo.cpuUsage

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

            // Battery (since im on PC, battery set to off)
            // Rectangle {
            //   height: 24
            //   width: battContent.width + 12
            //   radius: 12
            //   color: root.theme.bgSurface
            //   Accessible.role: Accessible.StaticText
            //   Accessible.name: "Battery: " + SystemInfo.batteryLevel

            //   Row {
            //     id: battContent
            //     anchors.centerIn: parent
            //     spacing: 6

            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: SystemInfo.batteryIcon
            //       color: sysInfo.batteryColor
            //       font.pixelSize: 14
            //       font.family: root.font
            //     }
            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: SystemInfo.batteryLevel
            //       color: root.theme.textPrimary
            //       font.pixelSize: 11
            //       font.family: root.font
            //     }
            //   }
            // }

            // Temperature
            Rectangle {
              height: 24
              width: tempContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: "Temperature: " + SystemInfo.temperature

              Row {
                id: tempContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰔏"
                  color: root.theme.accentRed
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
              height: 24
              width: memContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: "Memory Usage: " + root.memoryUsage
              
              Row {
                id: memContent
                anchors.centerIn: parent
                spacing: 6
                
                Text {
                  anchors.verticalCenter: parent.vertical
                  text: ""
                  color: root.theme.accentPrimary
                  font.pixelSize: 14
                  font.family: root.font
                }
                
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.memoryUsage
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
              Accessible.name: "/ (" + root.diskUsage + ")"

              MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
              }

              // Glow when hover
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
                  text: "" + root.diskUsage + "" 
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                }
              }
            }
            // Rectangle {
            //   height: 24
            //   width: diskContent.width + 12
            //   radius: 12
            //   color: root.theme.bgSurface
            //   Accessible.role: Accessible.StaticText
            //   Accessible.name: "/ (" + root.diskUsage + ")"

            //   Row {
            //     id: diskContent
            //     anchors.centerIn: parent
            //     spacing: 6

            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: "" // Ikon Harddisk (Nerd Fonts)
            //       color: root.theme.accentPrimary // Atau sesuaikan warna tema Anda
            //       font.pixelSize: 14
            //       font.family: root.font
            //     }

            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: "" + root.diskUsage + "" // Format output: / (90%)
            //       color: root.theme.textPrimary
            //       font.pixelSize: 11
            //       font.family: root.font
            //     }
            //   }
            // }
          }
        }
      }
    }
  }
}
