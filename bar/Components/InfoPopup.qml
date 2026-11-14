import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Card-styled data provider & hover controller for SharedInfoPopup.
Item {
  id: provider
  visible: false
  width: 0
  height: 0

  required property Item target
  property var barItem: null
  property var hostRoot: (target && target.hostRoot !== undefined) ? target.hostRoot : null
  property bool hovered: false
  property bool pinned: false
  property var theme
  property string font: (provider.theme && provider.theme.fontFamily) ? provider.theme.fontFamily : "Lato Nerd Font"
  property string title: ""
  property string icon: ""
  property string summaryText: ""
  property color accent: "#ffffff"
  property string script: ""
  property string barPosition: barItem && barItem.barPos !== undefined ? barItem.barPos : BarConfig.position

  property bool hideHeader: true
  property int preferredWidth: 264
  property int preferredHeight: 0

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
        if (barItem.activeInfoProvider && barItem.activeInfoProvider !== provider) {
          barItem.activeInfoProvider.effectiveHovered = false;
        }
        barItem.activeInfoProvider = provider;
      }
      if (!proc.running && provider.script) {
        proc.running = true;
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
      if (!proc.running && provider.script) {
        proc.running = true;
      }
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
  readonly property var sections: {
    const out = [];
    let cur = { title: "", items: [] };
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      if (r.header) {
        if (cur.items.length > 0 || cur.title !== "") {
          out.push(cur);
        }
        cur = { title: r.cells[0] || "", items: [] };
      } else {
        cur.items.push(r.cells || []);
      }
    }
    if (cur.items.length > 0 || cur.title !== "") {
      out.push(cur);
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
            ? { header: true, cells: [l.substring(1).trim()] }
            : { header: false, cells: l.split("\t").map(s => s.trim()) });
      }
    }
  }

  Timer {
    interval: 600
    repeat: false
    running: provider.script !== ""
    onTriggered: if (!proc.running && provider.script) proc.running = true
  }

  Timer {
    interval: 2000
    repeat: true
    running: provider.isDetailsActive && (provider.barItem ? provider.barItem.activeInfoProvider === provider : true)
    onTriggered: if (!proc.running && provider.script) proc.running = true
  }

  property Component contentComponent: Component {
    ColumnLayout {
      spacing: 8
      readonly property var th: provider.theme

      // Header Row
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 2
        Layout.rightMargin: 2
        spacing: 8

        Text {
          text: provider.title
          font.family: provider.font
          font.pixelSize: 13
          font.bold: true
          color: th.textPrimary
        }

        Item { Layout.fillWidth: true }
      }

      // Loading card when rows haven't arrived yet
      Rectangle {
        visible: provider.sections.length === 0
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 8
        color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
        border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "Reading sensor data..."
          font.family: provider.font
          font.pixelSize: 11
          color: th.textMuted
        }
      }

      // Grouped Inner Cards
      Repeater {
        model: provider.sections
        delegate: Rectangle {
          required property var modelData
          Layout.fillWidth: true
          implicitHeight: secCol.implicitHeight + 16
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          ColumnLayout {
            id: secCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 5

            Text {
              visible: modelData.title !== ""
              Layout.fillWidth: true
              text: modelData.title
              font.family: provider.font
              font.pixelSize: 10
              font.bold: true
              color: provider.accent
            }

            Rectangle {
              visible: modelData.title !== ""
              Layout.fillWidth: true
              implicitHeight: 1
              height: 1
              color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
            }

            Repeater {
              model: modelData.items
              delegate: ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                  visible: index > 0
                  Layout.fillWidth: true
                  implicitHeight: 1
                  height: 1
                  color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 8

                  Text {
                    Layout.fillWidth: true
                    text: modelData.length > 0 ? modelData[0] : ""
                    font.family: provider.font
                    font.pixelSize: 11
                    color: th.textSecondary
                    elide: Text.ElideRight
                  }

                  Text {
                    visible: modelData.length >= 3
                    text: modelData.length >= 3 ? modelData[1] : ""
                    font.family: provider.font
                    font.pixelSize: 10
                    color: th.textMuted
                  }

                  Text {
                    visible: modelData.length >= 2
                    Layout.maximumWidth: 165
                    text: modelData.length >= 2 ? modelData[modelData.length - 1] : ""
                    font.family: provider.font
                    font.pixelSize: 11
                    font.bold: true
                    color: th.textPrimary
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
