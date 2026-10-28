import Quickshell
import Quickshell.Io
import QtQuick
import ".."

// Lightweight data provider & hover controller for SharedInfoPopup.
Item {
  id: provider
  visible: false
  width: 0
  height: 0

  required property Item target
  property Item barItem: null
  property var hostRoot: (target && target.hostRoot !== undefined) ? target.hostRoot : null
  property bool hovered: false
  property bool pinned: false
  property var theme
  property string font: "Lato Nerd Font"
  property string title: ""
  property string icon: ""
  property color accent: "#ffffff"
  property string script: ""
  property string barPosition: barItem && barItem.barPos !== undefined ? barItem.barPos : BarConfig.position

  property bool effectiveHovered: false
  readonly property bool isSharedCardHovered: Boolean(
    barItem && barItem.activeInfoProvider === provider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered
  )
  readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered

  Timer {
    id: closeGraceTimer
    interval: 150
    repeat: false
    onTriggered: {
      if (!provider.hovered && !provider.isSharedCardHovered) {
        provider.effectiveHovered = false;
        if (provider.barItem && provider.barItem.activeInfoProvider === provider && !provider.pinned) {
          provider.barItem.activeInfoProvider = null;
        }
      }
    }
  }

  onHoveredChanged: {
    if (hovered) {
      closeGraceTimer.stop();
      effectiveHovered = true;
      if (barItem) {
        barItem.activeInfoProvider = provider;
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
      if (barItem.activeInfoProvider && barItem.activeInfoProvider !== provider && barItem.activeInfoProvider.target && barItem.activeInfoProvider.target.isPinned !== undefined) {
        barItem.activeInfoProvider.target.isPinned = false;
      }
      barItem.activeInfoProvider = provider;
    } else if (!pinned && !hovered && !isSharedCardHovered && barItem && barItem.activeInfoProvider === provider) {
      barItem.activeInfoProvider = null;
    }
  }

  Component.onDestruction: {
    if (barItem && barItem.activeInfoProvider === provider) {
      barItem.activeInfoProvider = null;
    }
  }

  property var rows: []
  readonly property int columnCount: {
    let n = 1;
    for (const r of rows) if (!r.header) n = Math.max(n, r.cells.length);
    return n;
  }
  readonly property var cellModel: {
    const out = [];
    for (const r of rows) {
      if (r.header) {
        out.push({ text: r.cells[0], header: true, col: 0 });
      } else {
        for (let c = 0; c < columnCount; c++)
          out.push({ text: r.cells[c] ?? "", header: false, col: c });
      }
    }
    return out;
  }

  Process {
    id: proc
    command: ["sh", Qt.resolvedUrl("../scripts/" + provider.script + ".sh").toString().replace("file://", "")]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        provider.rows = text.split("\n")
          .filter(l => l.trim() !== "")
          .map(l => l.startsWith("#")
            ? { header: true, cells: [l.substring(1)] }
            : { header: false, cells: l.split("\t").map(s => s.trim()) });
      }
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: provider.isDetailsActive && (provider.barItem ? provider.barItem.activeInfoProvider === provider : true)
    triggeredOnStart: true
    onTriggered: if (!proc.running && provider.script) proc.running = true
  }

  Component.onCompleted: {
    if (!proc.running && provider.script) {
      proc.running = true;
    }
  }
}
