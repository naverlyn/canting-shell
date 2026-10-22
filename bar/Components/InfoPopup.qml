import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Hover details popup anchored below `target`.
// Runs bar/scripts/<script>.sh while hovered. Script output is tab-separated:
// each line is a row, "#Title" lines are section headings.
PopupWindow {
  id: popup

  required property Item target
  property Item barItem: null
  property var hostRoot: (target && target.hostRoot !== undefined) ? target.hostRoot : null
  property bool hovered: false
  property bool pinned: false
  property var theme
  property string font: "Hack Nerd Font"
  property string title: ""
  property string icon: ""
  property color accent: "#ffffff"
  property string script: ""
  property string barPosition: barItem && barItem.barPos !== undefined ? barItem.barPos : BarConfig.position

  property int lastClampedX: 0
  property int lastClampedY: 0
  property bool joinTop: false
  property bool joinBottom: false
  property bool joinLeft: false
  property bool joinRight: false

  function syncActivePopupState(active) {
    const hr = popup.hostRoot;
    if (!hr) return;
    if (!active) {
      if (hr.activePopupData && hr.activePopupData.target === popup) {
        hr.activePopupData = null;
      }
      return;
    }
    const win = target ? target.QsWindow.window : null;
    const scr = win ? win.screen : null;
    hr.activePopupData = {
      target: popup,
      active: true,
      fluidEnabled: popup.fluidEnabled,
      barPos: popup.barPosition,
      x: popup.lastClampedX,
      y: popup.lastClampedY,
      width: popup.implicitWidth,
      height: popup.implicitHeight,
      screen: scr,
      joinTop: popup.joinTop,
      joinBottom: popup.joinBottom,
      joinLeft: popup.joinLeft,
      joinRight: popup.joinRight,
      cornerRad: popup.cornerRad
    };
  }

  // Activated only by target hover or pin toggle (with grace timer and card hover support)
  property bool effectiveHovered: false
  readonly property bool isDetailsActive: effectiveHovered || pinned

  Timer {
    id: closeGraceTimer
    interval: 180
    repeat: false
    onTriggered: popup.effectiveHovered = false
  }

  onHoveredChanged: {
    if (hovered) {
      closeGraceTimer.stop();
      effectiveHovered = true;
    } else if (!cardHoverHandler.hovered) {
      closeGraceTimer.restart();
    }
  }

  // Fluid vs Flyout mode toggle
  readonly property bool isFloatingBar: barItem && barItem.isFloating !== undefined
    ? barItem.isFloating
    : Boolean(BarConfig.floating)
  readonly property bool fluidEnabled: Boolean(BarConfig.fluidCards) && !isFloatingBar
  readonly property int cornerRad: barItem && barItem.innerCornerRadius !== undefined
    ? barItem.innerCornerRadius
    : 16
  readonly property color barColor: barItem && barItem.barColor !== undefined
    ? barItem.barColor
    : (popup.theme
      ? Qt.rgba(popup.theme.bgBase.r, popup.theme.bgBase.g, popup.theme.bgBase.b, (BarConfig.barOpacity !== undefined ? BarConfig.barOpacity : 0.85))
      : "#1a1b26")
  readonly property color cardBorderColor: fluidEnabled
    ? Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.15)
    : popup.theme.bgBase
  readonly property real cardBorderWidth: fluidEnabled ? 1 : 2

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
  property bool instantClose: false

  function dismissImmediate() {
    instantClose = true;
    effectiveHovered = false;
    closeGraceTimer.stop();
    cardContainer.opacity = 0.0;
    syncActivePopupState(false);
  }

  onIsDetailsActiveChanged: {
    if (isDetailsActive) {
      instantClose = false;
      BarConfig.notifyPopupActive(popup);
      syncActivePopupState(true);
    } else {
      BarConfig.notifyPopupInactive(popup);
      syncActivePopupState(false);
    }
  }

  Component.onDestruction: syncActivePopupState(false)

  Component.onCompleted: {
    if (!proc.running && popup.script) {
      proc.running = true;
    }
  }

  visible: (isDetailsActive && !instantClose) || cardContainer.opacity > 0.001
  color: "transparent"

  readonly property int baseContentW: Math.max(content.implicitWidth + 32, 200)
  readonly property int baseContentH: content.implicitHeight + 28

  implicitWidth: {
    if (!fluidEnabled) return baseContentW + 16;
    if (popup.barPosition === "left" || popup.barPosition === "right") return baseContentW + 8;
    return baseContentW + (2 * cornerRad);
  }
  implicitHeight: {
    if (!fluidEnabled) return baseContentH + 16;
    if (popup.barPosition === "top" || popup.barPosition === "bottom") return baseContentH + 8;
    return baseContentH + (2 * cornerRad);
  }

  anchor.window: target.QsWindow.window
  anchor.edges: {
    if (popup.barPosition === "bottom") return Edges.Top;
    if (popup.barPosition === "left") return Edges.Right;
    if (popup.barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.gravity: {
    if (popup.barPosition === "bottom") return Edges.Top;
    if (popup.barPosition === "left") return Edges.Right;
    if (popup.barPosition === "right") return Edges.Left;
    return Edges.Bottom;
  }
  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
  anchor.onAnchoring: {
    const win = target.QsWindow.window;
    if (!win) return;
    const widgetRect = win.contentItem.mapFromItem(target, 0, 0, target.width, target.height);
    if (popup.barItem) {
      const bRect = win.contentItem.mapFromItem(popup.barItem, 0, 0, popup.barItem.width, popup.barItem.height);
      const scr = win.screen;
      const pad = 8;
      const joinThreshold = 36;

      if (popup.barPosition === "top" || popup.barPosition === "bottom") {
        const widgetCenter = widgetRect.x + (widgetRect.width / 2);
        const popupW = popup.implicitWidth;
        const desiredX = Math.round(widgetCenter - (popupW / 2));
        const scrW = scr ? scr.width : 1920;

        if (popup.fluidEnabled && desiredX <= joinThreshold) {
          popup.joinLeft = true;
          popup.joinRight = false;
          popup.lastClampedX = 0;
        } else if (popup.fluidEnabled && (desiredX + popupW >= scrW - joinThreshold)) {
          popup.joinRight = true;
          popup.joinLeft = false;
          popup.lastClampedX = scrW - popupW;
        } else {
          popup.joinLeft = false;
          popup.joinRight = false;
          popup.lastClampedX = Math.max(pad, Math.min(Math.max(pad, scrW - popupW - pad), desiredX));
        }

        popup.joinTop = false;
        popup.joinBottom = false;
        popup.lastClampedY = popup.barPosition === "top" ? win.height : 0;
        const anchorY = popup.fluidEnabled ? (popup.barPosition === "top" ? win.height : 0) : bRect.y;
        const anchorH = popup.fluidEnabled ? 0 : bRect.height;
        anchor.rect = Qt.rect(popup.lastClampedX, anchorY, popupW, anchorH);
      } else {
        const widgetCenter = widgetRect.y + (widgetRect.height / 2);
        const popupH = popup.implicitHeight;
        const desiredY = Math.round(widgetCenter - (popupH / 2));
        const scrH = scr ? scr.height : 1080;

        if (popup.fluidEnabled && desiredY <= joinThreshold) {
          popup.joinTop = true;
          popup.joinBottom = false;
          popup.lastClampedY = 0;
        } else if (popup.fluidEnabled && (desiredY + popupH >= scrH - joinThreshold)) {
          popup.joinBottom = true;
          popup.joinTop = false;
          popup.lastClampedY = scrH - popupH;
        } else {
          popup.joinTop = false;
          popup.joinBottom = false;
          popup.lastClampedY = Math.max(pad, Math.min(Math.max(pad, scrH - popupH - pad), desiredY));
        }

        popup.joinLeft = false;
        popup.joinRight = false;
        popup.lastClampedX = popup.barPosition === "left" ? win.width : 0;
        const anchorX = popup.fluidEnabled ? (popup.barPosition === "left" ? win.width : 0) : bRect.x;
        const anchorW = popup.fluidEnabled ? 0 : bRect.width;
        anchor.rect = Qt.rect(anchorX, popup.lastClampedY, anchorW, popupH);
      }
    } else {
      anchor.rect = widgetRect;
    }

    if (popup.isDetailsActive) {
      popup.syncActivePopupState(true);
    }
  }

  Process {
    id: proc
    command: ["sh", Qt.resolvedUrl("../scripts/" + popup.script + ".sh").toString().replace("file://", "")]
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
    running: popup.isDetailsActive
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }

  Item {
    id: cardContainer
    opacity: (popup.isDetailsActive && !popup.instantClose) ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: popup.instantClose ? 0 : ((popup.isDetailsActive && BarConfig.isHoveringBarPills) ? 0 : 180)
        easing.type: Easing.OutCubic
      }
    }

    anchors.fill: parent

    transform: Translate {
      id: cardSlideTransform
      x: {
        if (!popup.fluidEnabled) return 0;
        if (popup.barPosition === "right") return (popup.isDetailsActive && !popup.instantClose) ? 0 : 8;
        if (popup.barPosition === "left") return (popup.isDetailsActive && !popup.instantClose) ? 0 : -8;
        return 0;
      }
      y: {
        if (!popup.fluidEnabled) return (
          popup.barPosition === "top"
            ? (popup.isDetailsActive ? 6 : 0)
            : (popup.barPosition === "bottom" ? (popup.isDetailsActive ? 6 : 12) : 6)
        );
        if (popup.barPosition === "top") return (popup.isDetailsActive && !popup.instantClose) ? 0 : -8;
        if (popup.barPosition === "bottom") return (popup.isDetailsActive && !popup.instantClose) ? 0 : 8;
        return 0;
      }

      Behavior on x {
        NumberAnimation {
          duration: popup.instantClose ? 0 : ((popup.isDetailsActive && BarConfig.isHoveringBarPills) ? 0 : 200)
          easing.type: Easing.OutCubic
        }
      }
      Behavior on y {
        NumberAnimation {
          duration: popup.instantClose ? 0 : ((popup.isDetailsActive && BarConfig.isHoveringBarPills) ? 0 : 200)
          easing.type: Easing.OutCubic
        }
      }
    }

    HoverHandler {
      id: cardHoverHandler
      onHoveredChanged: {
        if (hovered) {
          closeGraceTimer.stop();
          popup.effectiveHovered = true;
        } else if (!popup.hovered) {
          closeGraceTimer.restart();
        }
      }
    }

    FluidCardBackground {
      id: cardBg
      anchors.fill: parent
      fluidEnabled: popup.fluidEnabled
      barPosition: popup.barPosition
      cornerRadius: popup.cornerRad
      cardColor: popup.fluidEnabled ? popup.barColor : popup.theme.bgSurface
      borderColor: popup.cardBorderColor
      borderWidth: popup.cardBorderWidth
      joinTop: popup.joinTop
      joinBottom: popup.joinBottom
      joinLeft: popup.joinLeft
      joinRight: popup.joinRight
    }

    ColumnLayout {
      id: content
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.horizontalCenterOffset: popup.fluidEnabled ? (popup.barPosition === "right" ? 4 : (popup.barPosition === "left" ? -4 : 0)) : 0
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: popup.fluidEnabled ? (popup.barPosition === "bottom" ? -4 : (popup.barPosition === "top" ? 4 : 0)) : 0
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
        color: Qt.rgba(popup.theme.textPrimary.r, popup.theme.textPrimary.g, popup.theme.textPrimary.b, 0.12)
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
