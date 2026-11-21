import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../ControlCenter"
import "../../ControlCenter/Components"
import ".."

Item {
  id: root

  required property var theme
  required property string font
  required property var hostRoot
  property color accent: theme.accentPrimary
  property var customControlTiles: []

  signal requestCollapse()

  // Use custom ordered tiles when configured, otherwise automatically sync with Control Center
  readonly property var resolvedTileIds: {
    void ControlCenterConfig.cardOrderRevision;
    const seen = {};
    const out = [];

    function pushId(tid) {
      if (!tid || seen[tid]) return;
      if (ControlCenterConfig.getTileDef(tid)) {
        seen[tid] = true;
        out.push(tid);
      }
    }

    if (Array.isArray(customControlTiles) && customControlTiles.length > 0) {
      for (let k = 0; k < customControlTiles.length; k++) {
        pushId(customControlTiles[k]);
      }
      if (out.length > 0) return out;
    }

    const enabled = ControlCenterConfig.enabledTiles || [];
    for (let i = 0; i < enabled.length; i++) {
      if (enabled[i] && enabled[i].id) pushId(enabled[i].id);
    }

    const cards = ControlCenterConfig.enabledCards || [];
    for (let c = 0; c < cards.length; c++) {
      const cid = cards[c] ? String(cards[c].id || "") : "";
      if (cid.indexOf("tile:") === 0) pushId(cid.substring(5));
    }

    if (out.length === 0) {
      return ["wifi", "bluetooth", "dnd", "caffeine", "nightlight", "darkmode"];
    }
    return out;
  }

  readonly property real contentH: ccGrid.implicitHeight
  implicitHeight: Math.min(236, Math.max(58, contentH))
  height: implicitHeight

  Flickable {
    id: tilesFlick
    anchors.fill: parent
    contentWidth: width
    contentHeight: ccGrid.implicitHeight
    clip: true
    interactive: contentHeight > height + 2
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
      policy: tilesFlick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
      width: 3
      contentItem: Rectangle {
        radius: 1.5
        color: root.theme.bgBorder
      }
    }

    QuickSettingsGrid {
      id: ccGrid
      width: tilesFlick.interactive ? (tilesFlick.width - 6) : tilesFlick.width
      theme: root.theme
      font: root.font
      mode: "panelTiles"
      tileIds: root.resolvedTileIds

      onOpenWifiRequested: ccGrid.toggleWifi()
      onCloseParentRequested: root.requestCollapse()
    }
  }
}
