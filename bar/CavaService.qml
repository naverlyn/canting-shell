pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
  id: root

  readonly property string cavaScript: Qt.resolvedUrl("./scripts/cava.sh").toString().replace(/^file:\/\//, "")

  property var values: [0, 0, 0, 0, 0, 0, 0, 0]
  property bool hasAudio: false
  property string glyphText: "        "
  property int externalConsumers: 0

  // Unicode block characters representing 8 increasing levels of audio
  readonly property var glyphLevels: [" ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

  readonly property bool isMediaPlaying: {
    const players = (Mpris && Mpris.players) ? Mpris.players.values : null;
    if (!players) return false;
    for (let i = 0; i < players.length; i++) {
      if (players[i] && players[i].isPlaying) return true;
    }
    return false;
  }

  // Run cava only when visible/needed: bar widget active, ControlCenter CavaCard open, or Dynamic Island with active media
  readonly property bool shouldRun: {
    void BarConfig.panelsRevision;
    void BarConfig.bars;
    void BarConfig.hasSecondaryScreen;
    if (root.externalConsumers > 0) return true;
    if (!BarConfig.barVisible) return false;
    const inBar = Boolean(BarConfig.showCava) && BarConfig.isWidgetInAnyBar("cava");
    if (inBar) return true;
    return Boolean(BarConfig.hasDynamicIslandMediaActive) && root.isMediaPlaying;
  }

  onShouldRunChanged: {
    if (root.shouldRun) {
      root.restart();
    } else {
      restartTimer.stop();
      cavaProc.running = false;
      root.hasAudio = false;
    }
  }

  Process {
    id: cavaProc
    command: [
      root.cavaScript,
      String(BarConfig.cavaBars || 8),
      String(BarConfig.cavaFramerate || 30),
      "100",
      BarConfig.cavaStereo ? "stereo" : "mono"
    ]
    running: false

    onExited: (exitCode, exitStatus) => {
      root.hasAudio = false;
      if (root.shouldRun) {
        restartTimer.restart();
      }
    }

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: (data) => {
        const line = String(data).trim();
        if (!line) return;
        const tokens = line.split(";").filter(x => x.length > 0);
        if (tokens.length === 0) return;

        let nums = [];
        let active = false;
        let glyphs = "";

        for (let i = 0; i < tokens.length; i++) {
          const v = Math.max(0, Math.min(100, parseInt(tokens[i]) || 0));
          nums.push(v);
          if (v > 2) active = true;

          const idx = Math.max(0, Math.min(8, Math.round(v / 12.5)));
          glyphs += root.glyphLevels[idx];
        }

        if (!active && !root.hasAudio) {
          return;
        }
        root.values = nums;
        root.hasAudio = active;
        root.glyphText = glyphs;
      }
    }
  }

  // Restart process only when cava CLI parameters change (shouldRun changes are handled by onShouldRunChanged)
  Connections {
    target: BarConfig
    function onCavaBarsChanged() { if (root.shouldRun) root.restart(); }
    function onCavaModeChanged() { if (root.shouldRun) root.restart(); }
    function onCavaFramerateChanged() { if (root.shouldRun) root.restart(); }
    function onCavaStereoChanged() { if (root.shouldRun) root.restart(); }
  }

  function restart() {
    cavaProc.running = false;
    if (root.shouldRun) {
      restartTimer.restart();
    }
  }

  Timer {
    id: restartTimer
    interval: 200
    repeat: false
    onTriggered: {
      if (root.shouldRun) {
        cavaProc.running = true;
      }
    }
  }

  Component.onCompleted: {
    if (root.shouldRun) {
      restartTimer.start();
    }
  }
}
