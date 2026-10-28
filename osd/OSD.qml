import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Lato Nerd Font"

  readonly property bool isHorizontal: OSDService.isHorizontal

  property bool showVolume: false
  property bool showBrightness: false
  property real volumeValue: 0
  property bool volumeMuted: false
  property real brightnessValue: 0
  property real maxBrightness: 1
  property bool _brightnessReady: false

  // PipeWire tracking
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  Connections {
    target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null

    function onVolumeChanged() {
      root.updateVolume();
    }

    function onVolumesChanged() {
      root.updateVolume();
    }

    function onMutedChanged() {
      if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
      root.volumeMuted = Pipewire.defaultAudioSink.audio.muted;
      root.showVolume = true;
      volumeHideTimer.restart();
    }
  }

  Connections {
    target: OSDService
    function onTestTriggered() {
      root.updateVolume();
      root.showVolume = true;
      volumeHideTimer.restart();
    }
  }

  function updateVolume() {
    if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
    const audio = Pipewire.defaultAudioSink.audio;
    if (audio.volumes && audio.volumes.length >= 2) {
      root.volumeValue = Math.max(audio.volumes[0], audio.volumes[1]);
    } else {
      root.volumeValue = audio.volume;
    }
    root.showVolume = true;
    volumeHideTimer.restart();
  }

  Timer {
    id: volumeHideTimer
    interval: OSDService.timeoutMs
    onTriggered: root.showVolume = false
  }

  // Brightness monitoring
  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "-c", "backlight", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.maxBrightness > 0) {
          root.brightnessValue = val / root.maxBrightness;
          if (root._brightnessReady) {
            root.showBrightness = true;
            brightnessHideTimer.restart();
          }
          root._brightnessReady = true;
        }
      }
    }
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
          if (!isNaN(max) && max > 0) root.maxBrightness = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  Timer {
    id: brightnessHideTimer
    interval: OSDService.timeoutMs
    onTriggered: root.showBrightness = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: osdWindow
      required property var modelData
      screen: modelData

      visible: root.showVolume || root.showBrightness || volumePill.visible || brightnessPill.visible
      focusable: false
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "quickshell-osd"

      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      // Fullscreen overlay with zero input capture
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Column {
        id: osdCol
        spacing: 12

        readonly property string pos: OSDService.position || "right"
        readonly property int mx: OSDService.marginX
        readonly property int my: OSDService.marginY

        x: {
          const w = osdWindow.width > 0 ? osdWindow.width : 1920;
          const colW = implicitWidth > 0 ? implicitWidth : (root.isHorizontal ? 240 : 36);
          let targetX = 0;
          if (pos === "left") {
            targetX = 12 + mx;
          } else if (pos === "right") {
            targetX = w - colW - 12 - mx;
          } else {
            // center, top, bottom
            targetX = Math.round((w - colW) / 2) + mx;
          }
          return Math.max(12, Math.min(Math.max(12, w - colW - 12), targetX));
        }

        y: {
          const h = osdWindow.height > 0 ? osdWindow.height : 1080;
          const colH = implicitHeight > 0 ? implicitHeight : (root.isHorizontal ? 44 : 200);
          let targetY = 0;
          if (pos === "top") {
            targetY = 12 + my;
          } else if (pos === "bottom") {
            targetY = h - colH - 12 - my;
          } else {
            // center, left, right
            targetY = Math.round((h - colH) / 2) + my;
          }
          return Math.max(12, Math.min(Math.max(12, h - colH - 12), targetY));
        }

        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        // Volume pill (Horizontal or Vertical)
        Rectangle {
          id: volumePill
          visible: root.showVolume || opacity > 0.001
          implicitWidth: root.isHorizontal ? 240 : 36
          implicitHeight: root.isHorizontal ? 44 : 200
          width: implicitWidth
          height: implicitHeight
          radius: root.isHorizontal ? 22 : 18
          color: root.theme.bgBase
          border.color: root.theme.bgBorder
          border.width: 1
          opacity: root.showVolume ? 1 : 0
          clip: true

          Behavior on opacity { NumberAnimation { duration: 150 } }
          Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on radius { NumberAnimation { duration: 160 } }

          Accessible.role: Accessible.ProgressBar
          Accessible.name: root.volumeMuted ? "Volume: muted" : "Volume: " + Math.round(root.volumeValue * 100) + "%"

          // Horizontal layout
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            visible: root.isHorizontal

            Text {
              text: {
                if (root.volumeMuted || root.volumeValue <= 0) return "󰖁";
                if (root.volumeValue < 0.33) return "󰕿";
                if (root.volumeValue < 0.66) return "󰖀";
                return "󰕾";
              }
              color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary
              font.pixelSize: 16
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 6
              radius: 3
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true
              Layout.alignment: Qt.AlignVCenter

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, root.volumeMuted ? 0 : root.volumeValue))))
                radius: 3
                color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary

                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: root.volumeMuted ? "Mute" : Math.round(root.volumeValue * 100) + "%"
              color: root.volumeMuted ? root.theme.textMuted : root.theme.textPrimary
              font.pixelSize: 11
              font.bold: true
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
              Layout.preferredWidth: 42
              horizontalAlignment: Text.AlignRight
            }
          }

          // Vertical layout
          ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 8
            visible: !root.isHorizontal

            Text {
              text: root.volumeMuted ? "Mute" : Math.round(root.volumeValue * 100) + "%"
              color: root.theme.textSecondary
              font.pixelSize: 10
              font.family: root.font
              Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
              Layout.fillHeight: true
              Layout.alignment: Qt.AlignHCenter
              width: 8
              radius: 4
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true

              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 2
                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.volumeMuted ? 0 : root.volumeValue)))
                radius: 3
                color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary

                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: {
                if (root.volumeMuted || root.volumeValue <= 0) return "󰖁";
                if (root.volumeValue < 0.33) return "󰕿";
                if (root.volumeValue < 0.66) return "󰖀";
                return "󰕾";
              }
              color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary
              font.pixelSize: 15
              font.family: root.font
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }

        // Brightness pill (Horizontal or Vertical)
        Rectangle {
          id: brightnessPill
          visible: root.showBrightness || opacity > 0.001
          implicitWidth: root.isHorizontal ? 240 : 36
          implicitHeight: root.isHorizontal ? 44 : 200
          width: implicitWidth
          height: implicitHeight
          radius: root.isHorizontal ? 22 : 18
          color: root.theme.bgBase
          border.color: root.theme.bgBorder
          border.width: 1
          opacity: root.showBrightness ? 1 : 0
          clip: true

          Behavior on opacity { NumberAnimation { duration: 150 } }
          Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on radius { NumberAnimation { duration: 160 } }

          Accessible.role: Accessible.ProgressBar
          Accessible.name: "Brightness: " + Math.round(root.brightnessValue * 100) + "%"

          // Horizontal layout
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            visible: root.isHorizontal

            Text {
              text: "󰃠"
              color: root.theme.accentOrange
              font.pixelSize: 16
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 6
              radius: 3
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true
              Layout.alignment: Qt.AlignVCenter

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, root.brightnessValue))))
                radius: 3
                color: root.theme.accentOrange

                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: Math.round(root.brightnessValue * 100) + "%"
              color: root.theme.textPrimary
              font.pixelSize: 11
              font.bold: true
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
              Layout.preferredWidth: 42
              horizontalAlignment: Text.AlignRight
            }
          }

          // Vertical layout
          ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 8
            visible: !root.isHorizontal

            Text {
              text: Math.round(root.brightnessValue * 100) + "%"
              color: root.theme.textSecondary
              font.pixelSize: 10
              font.family: root.font
              Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
              Layout.fillHeight: true
              Layout.alignment: Qt.AlignHCenter
              width: 8
              radius: 4
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true

              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 2
                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.brightnessValue)))
                radius: 3
                color: root.theme.accentOrange

                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: "󰃠"
              color: root.theme.accentOrange
              font.pixelSize: 15
              font.family: root.font
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }
    }
  }
}
