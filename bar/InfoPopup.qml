import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Hover details popup anchored below `target`.
// Runs bar/scripts/<script>.sh while hovered. Script output is tab-separated:
// each line is a row, "#Title" lines are section headings.
PopupWindow {
  id: popup

  required property Item target
  property bool hovered: false
  property var theme
  property string font: "Hack Nerd Font"
  property string title: ""
  property string icon: ""
  property color accent: "#ffffff"
  property string script: ""

  // Parsed rows: [{ header: bool, cells: [string] }]
  property var rows: []
  readonly property int columnCount: {
    let n = 1;
    for (const r of rows) if (!r.header) n = Math.max(n, r.cells.length);
    return n;
  }
  // Flattened cells for the grid
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

  // Stay mapped until the fade-out finishes
  visible: hovered || box.opacity > 0
  color: "transparent"
  implicitWidth: box.implicitWidth
  implicitHeight: box.implicitHeight + 8

  anchor.window: target.QsWindow.window
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
  anchor.onAnchoring: {
    const win = target.QsWindow.window;
    anchor.rect = win.contentItem.mapFromItem(target, 0, 0, target.width, target.height);
  }

  Process {
    id: proc
    command: ["sh", Qt.resolvedUrl("scripts/" + popup.script + ".sh").toString().replace("file://", "")]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        popup.rows = text.split("\n")
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
    running: popup.hovered
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }

  Rectangle {
    id: box
    opacity: popup.hovered ? 1 : 0
    y: popup.hovered ? 8 : 0
    transformOrigin: Item.Top
    scale: popup.hovered ? 1 : 0.96

    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    implicitWidth: Math.max(content.implicitWidth + 32, 200)
    implicitHeight: content.implicitHeight + 28
    color: popup.theme.bgSurface
    radius: 12
    border.color: popup.theme.bgBase
    border.width: 2

    ColumnLayout {
      id: content
      anchors.centerIn: parent
      spacing: 10

      // Title
      RowLayout {
        spacing: 6
        Text {
          text: popup.icon
          color: popup.accent
          font.pixelSize: 14
          font.family: popup.font
        }
        Text {
          text: popup.title
          color: popup.accent
          font.pixelSize: 13
          font.bold: true
          font.family: popup.font
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: popup.theme.bgBase
      }

      Text {
        visible: popup.rows.length === 0
        text: "Loading..."
        color: popup.theme.textMuted
        font.pixelSize: 11
        font.family: popup.font
      }

      GridLayout {
        visible: popup.rows.length > 0
        columns: popup.columnCount
        columnSpacing: 18
        rowSpacing: 5
        Layout.fillWidth: true

        Repeater {
          model: popup.cellModel

          Text {
            required property var modelData
            Layout.columnSpan: modelData.header ? popup.columnCount : 1
            Layout.fillWidth: modelData.header || modelData.col === popup.columnCount - 1
            Layout.topMargin: modelData.header ? 4 : 0
            Layout.maximumWidth: 320
            text: modelData.text
            elide: Text.ElideRight
            horizontalAlignment: (!modelData.header && modelData.col > 0) ? Text.AlignRight : Text.AlignLeft
            color: modelData.header ? popup.accent
                 : (modelData.col === 0 ? popup.theme.textSecondary : popup.theme.textPrimary)
            font.pixelSize: modelData.header ? 11 : 11
            font.bold: modelData.header
            font.family: popup.font
          }
        }
      }
    }
  }
}
