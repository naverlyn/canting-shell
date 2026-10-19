pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string cavaScript: Qt.resolvedUrl("./scripts/cava.sh").toString().replace(/^file:\/\//, "")

  property var values: [0, 0, 0, 0, 0, 0, 0, 0]
  property bool hasAudio: false
  property string glyphText: "        "

  // Unicode block characters representing 8 increasing levels of audio
  readonly property var glyphLevels: [" ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

  // Active check: only run cava when it is enabled and placed in at least one bar
  readonly property bool shouldRun: Boolean(BarConfig.showCava) && BarConfig.isWidgetInAnyBar("cava")

  Process {
    id: cavaProc
    command: [
      root.cavaScript,
      String(BarConfig.cavaBars || 8),
      String(BarConfig.cavaFramerate || 30),
      "100",
      BarConfig.cavaStereo ? "stereo" : "mono"
    ]
    running: root.shouldRun

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

        root.values = nums;
        root.hasAudio = active;
        root.glyphText = glyphs;
      }
    }
  }

  // Restart process when parameters change
  Connections {
    target: BarConfig
    function onCavaBarsChanged() { root.restart(); }
    function onCavaModeChanged() { root.restart(); }
    function onCavaFramerateChanged() { root.restart(); }
    function onCavaStereoChanged() { root.restart(); }
    function onShowCavaChanged() { root.restart(); }
  }

  function restart() {
    if (cavaProc.running) {
      cavaProc.running = false;
      restartTimer.start();
    }
  }

  Timer {
    id: restartTimer
    interval: 160
    repeat: false
    onTriggered: {
      if (root.shouldRun) {
        cavaProc.running = true;
      }
    }
  }
}

