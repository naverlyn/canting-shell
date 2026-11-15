import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "Components"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

  readonly property bool isHorizontal: OSDService.isHorizontal

  property bool showVolume: false
  property bool showMic: false
  property bool showBrightness: false
  property real volumeValue: 0
  property bool volumeMuted: false
  property real micValue: 0
  property bool micMuted: false
  property real brightnessValue: 0
  property real maxBrightness: 1
  property bool _brightnessReady: false
  property bool _pipewireReady: false

  Timer {
    id: pipewireReadyTimer
    interval: 450
    running: true
    repeat: false
    onTriggered: root._pipewireReady = true
  }

  // PipeWire tracking (Speaker + Microphone)
  PwObjectTracker {
    objects: {
      const list = [];
      if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
      if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
      return list;
    }
  }

  Connections {
    target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null

    function onVolumeChanged() {
      root.updateVolume(true);
    }

    function onVolumesChanged() {
      root.updateVolume(true);
    }

    function onMutedChanged() {
      if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
      root.volumeMuted = Pipewire.defaultAudioSink.audio.muted;
      if (!root._pipewireReady) return;
      root.showVolume = true;
      volumeHideTimer.restart();
    }
  }

  Connections {
    target: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) ? Pipewire.defaultAudioSource.audio : null

    function onVolumeChanged() {
      root.updateMic(true);
    }

    function onVolumesChanged() {
      root.updateMic(true);
    }

    function onMutedChanged() {
      if (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio) return;
      root.micMuted = Pipewire.defaultAudioSource.audio.muted;
      if (!root._pipewireReady) return;
      root.showMic = true;
      micHideTimer.restart();
    }
  }

  Connections {
    target: OSDService
    function onTestTriggered() {
      root.updateVolume(false);
      root.showVolume = true;
      volumeHideTimer.restart();
    }
  }

  function updateVolume(respectReady) {
    if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
    const audio = Pipewire.defaultAudioSink.audio;
    root.volumeValue = (audio.volumes && audio.volumes.length >= 2)
      ? Math.max(audio.volumes[0], audio.volumes[1])
      : audio.volume;
    root.volumeMuted = audio.muted;
    if (respectReady && !root._pipewireReady) return;
    root.showVolume = true;
    volumeHideTimer.restart();
  }

  function updateMic(respectReady) {
    if (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio) return;
    const audio = Pipewire.defaultAudioSource.audio;
    root.micValue = (audio.volumes && audio.volumes.length >= 2)
      ? Math.max(audio.volumes[0], audio.volumes[1])
      : audio.volume;
    root.micMuted = audio.muted;
    if (respectReady && !root._pipewireReady) return;
    root.showMic = true;
    micHideTimer.restart();
  }

  Timer {
    id: volumeHideTimer
    interval: OSDService.timeoutMs
    onTriggered: root.showVolume = false
  }

  Timer {
    id: micHideTimer
    interval: OSDService.timeoutMs
    onTriggered: root.showMic = false
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

  readonly property bool anyActive: root.showVolume || root.showMic || root.showBrightness
  property bool osdMounted: false

  onAnyActiveChanged: {
    if (anyActive) {
      osdUnloadTimer.stop();
      osdMounted = true;
    } else {
      osdUnloadTimer.restart();
    }
  }

  Timer {
    id: osdUnloadTimer
    interval: 220
    repeat: false
    onTriggered: {
      if (!root.anyActive) {
        root.osdMounted = false;
        Qt.callLater(() => gc());
      }
    }
  }

  Variants {
    model: (root.anyActive || root.osdMounted) ? Quickshell.screens : []

    PanelWindow {
      id: osdWindow
      required property var modelData
      screen: modelData

      visible: root.anyActive || volumePill.visible || micPill.visible || brightnessPill.visible
      focusable: false
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "quickshell-osd"

      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

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
            targetY = Math.round((h - colH) / 2) + my;
          }
          return Math.max(12, Math.min(Math.max(12, h - colH - 12), targetY));
        }

        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        OSDPill {
          id: volumePill
          theme: root.theme
          font: root.font
          active: root.showVolume
          isHorizontal: root.isHorizontal
          muted: root.volumeMuted
          value: root.volumeValue
          valueText: root.volumeMuted ? "Mute" : Math.round(root.volumeValue * 100) + "%"
          iconText: {
            if (root.volumeMuted || root.volumeValue <= 0) return "󰖁";
            if (root.volumeValue < 0.33) return "󰕿";
            if (root.volumeValue < 0.66) return "󰖀";
            return "󰕾";
          }
          accessibleLabel: root.volumeMuted ? "Volume: muted" : "Volume: " + Math.round(root.volumeValue * 100) + "%"
        }

        OSDPill {
          id: micPill
          theme: root.theme
          font: root.font
          active: root.showMic
          isHorizontal: root.isHorizontal
          muted: root.micMuted
          value: root.micValue
          valueText: root.micMuted ? "Mute" : Math.round(root.micValue * 100) + "%"
          iconText: root.micMuted ? "󰍭" : "󰍬"
          accessibleLabel: root.micMuted ? "Microphone: muted" : "Microphone: " + Math.round(root.micValue * 100) + "%"
        }

        OSDPill {
          id: brightnessPill
          theme: root.theme
          font: root.font
          active: root.showBrightness
          isHorizontal: root.isHorizontal
          muted: false
          value: root.brightnessValue
          valueText: Math.round(root.brightnessValue * 100) + "%"
          iconText: {
            if (root.brightnessValue < 0.33) return "󰃞";
            if (root.brightnessValue < 0.66) return "󰃟";
            return "󰃠";
          }
          accessibleLabel: "Brightness: " + Math.round(root.brightnessValue * 100) + "%"
        }
      }
    }
  }
}
