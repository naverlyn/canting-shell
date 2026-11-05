import QtQuick
import ".."

Item {
  id: canvas

  required property var monitors
  required property int selectedIndex
  required property var theme
  required property string font

  property bool isDragging: false
  property var snapGuides: []
  property var snapGhost: null

  signal monitorSelected(int index)
  signal monitorMoved(int index, real newX, real newY)
  signal monitorsArranged(var newMonitors)

  function _onCanvas(m) { return !m.disabled && m.mirrorOf === ""; }

  readonly property real _minX: {
    let min = Infinity;
    for (const m of monitors) {
      if (!_onCanvas(m)) continue;
      min = Math.min(min, m.x);
    }
    return isFinite(min) ? min : 0;
  }
  readonly property real _minY: {
    let min = Infinity;
    for (const m of monitors) {
      if (!_onCanvas(m)) continue;
      min = Math.min(min, m.y);
    }
    return isFinite(min) ? min : 0;
  }
  readonly property real _totalW: {
    let max = 1;
    for (const m of monitors) {
      if (!_onCanvas(m)) continue;
      max = Math.max(max, m.x + MonitorUtils.logicalW(m));
    }
    return Math.max(1, max - _minX);
  }
  readonly property real _totalH: {
    let max = 1;
    for (const m of monitors) {
      if (!_onCanvas(m)) continue;
      max = Math.max(max, m.y + MonitorUtils.logicalH(m));
    }
    return Math.max(1, max - _minY);
  }

  // Bottom strip holds every monitor that isn't part of the arrangement
  readonly property int _stripCount: {
    let n = 0;
    for (const m of monitors) { if (!_onCanvas(m)) n++; }
    return n;
  }
  readonly property real _stripH: _stripCount > 0 ? 86 : 0

  readonly property real viewScale:
    Math.min((width - 80) / Math.max(_totalW, 1),
             (height - 80 - _stripH) / Math.max(_totalH, 1))

  readonly property real originX: (width - _totalW * viewScale) / 2 - _minX * viewScale
  readonly property real originY: (_stripH === 0
    ? (height - _totalH * viewScale) / 2
    : (height - _stripH - _totalH * viewScale) / 2) - _minY * viewScale

  function _mirroredBy(name) {
    const r = [];
    for (const m of monitors) {
      if (!m.disabled && m.mirrorOf === name) r.push(m.name);
    }
    return r;
  }

  // Canvas background
  Rectangle {
    anchors.fill: parent
    color: canvas.theme.bgSurface
    radius: 8
  }

  // Dot grid background - painted once into a 24×24 tile, then GPU-tiled across the
  // canvas via Image.Tile.  Resizes don't re-run any JS; only theme changes repaint
  // the single tile.
  Canvas {
    id: dotTile
    width: 24
    height: 24
    visible: false

    property color dotColor: canvas.theme.textMuted
    property string dataUrl: ""

    // https://doc.qt.io/qt-6/qtqml-syntax-objectattributes.html#property-change-signal-handlers
    onAvailableChanged: if (available) requestPaint()
    onDotColorChanged:  if (available) requestPaint()

    onPaint: {
      const ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      ctx.fillStyle = `rgba(${Math.round(dotColor.r * 255)}, ${Math.round(dotColor.g * 255)}, ${Math.round(dotColor.b * 255)}, 0.3)`;
      ctx.beginPath();
      ctx.arc(width / 2, height / 2, 1.5, 0, Math.PI * 2);
      ctx.fill();
      dataUrl = toDataURL();
    }
  }

  Image {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.bottomMargin: canvas._stripH
    source: dotTile.dataUrl
    fillMode: Image.Tile
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    smooth: false
    visible: source !== ""
  }

  // Center crosshair
  Rectangle {
    anchors.fill: parent
    color: "transparent"
    Rectangle {
      anchors.centerIn: parent
      width: parent.width; height: 1
      color: canvas.theme.bgBorder
      opacity: 0.4
    }
    Rectangle {
      anchors.centerIn: parent
      width: 1; height: parent.height
      color: canvas.theme.bgBorder
      opacity: 0.4
    }
  }

  Rectangle {
    visible: canvas._stripH > 0
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: canvas._stripH
    radius: 8
    color: Qt.rgba(0, 0, 0, 0.15)

    Text {
      anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 10 }
      text: "Not in arrangement"
      color: canvas.theme.textMuted
      font { pixelSize: 10; family: canvas.font }
    }
  }

  // Translucent snap ghost target showing where it will snap
  Rectangle {
    id: snapGhostRect
    visible: canvas.isDragging && canvas.snapGhost !== null
    x: canvas.snapGhost ? Math.round(canvas.snapGhost.x) : 0
    y: canvas.snapGhost ? Math.round(canvas.snapGhost.y) : 0
    width: canvas.snapGhost ? Math.round(canvas.snapGhost.w) : 0
    height: canvas.snapGhost ? Math.round(canvas.snapGhost.h) : 0
    radius: 6
    color: Qt.rgba(canvas.theme.accentCyan.r, canvas.theme.accentCyan.g, canvas.theme.accentCyan.b, 0.15)
    border.color: canvas.theme.accentCyan ?? "#7dcfff"
    border.width: 1.5
    z: 2
  }

  // Magnetic alignment guide lines
  Item {
    id: guideOverlay
    anchors.fill: parent
    z: 20
    visible: canvas.isDragging && canvas.snapGuides.length > 0

    Repeater {
      model: canvas.snapGuides
      delegate: Item {
        required property var modelData

        x: modelData.type === "v" ? Math.round(modelData.pos) : Math.round(Math.min(modelData.start, modelData.end))
        y: modelData.type === "h" ? Math.round(modelData.pos) : Math.round(Math.min(modelData.start, modelData.end))
        width: modelData.type === "h" ? Math.max(2, Math.round(Math.abs(modelData.end - modelData.start))) : 1
        height: modelData.type === "v" ? Math.max(2, Math.round(Math.abs(modelData.end - modelData.start))) : 1

        // Outer glow
        Rectangle {
          anchors.centerIn: parent
          width: modelData.type === "h" ? parent.width : 5
          height: modelData.type === "v" ? parent.height : 5
          color: canvas.theme.accentCyan ?? "#7dcfff"
          opacity: 0.3
        }

        // Crisp central guide line
        Rectangle {
          anchors.fill: parent
          color: canvas.theme.accentCyan ?? "#7dcfff"
          opacity: 0.95
        }
      }
    }
  }

  function updateSnapGuides(tile, idx, cx, cy) {
    const snap = calculateSnap(idx, cx, cy);
    canvas.snapGuides = snap.guides;
    tile.isSnapped = snap.isSnappedX || snap.isSnappedY;
    if (snap.isSnappedX || snap.isSnappedY) {
      canvas.snapGhost = {
        x: snap.snappedCanvasX,
        y: snap.snappedCanvasY,
        w: MonitorUtils.logicalW(monitors[idx]) * canvas.viewScale,
        h: MonitorUtils.logicalH(monitors[idx]) * canvas.viewScale
      };
    } else {
      canvas.snapGhost = null;
    }
  }

  Repeater {
    id: enabledTiles
    model: canvas.monitors

    delegate: MonitorTile {
      id: enabledTile

      required property var modelData

      monitor:    modelData
      selected:   canvas.selectedIndex === index
      theme:      canvas.theme
      font:       canvas.font
      mirroredBy: canvas._mirroredBy(modelData.name)

      visible: canvas._onCanvas(modelData)
      x: canvas.originX + modelData.x * canvas.viewScale
      y: canvas.originY + modelData.y * canvas.viewScale
      width:  MonitorUtils.logicalW(modelData) * canvas.viewScale
      height: MonitorUtils.logicalH(modelData) * canvas.viewScale

      // Clamp drag so tiles cannot leave the canvas area
      dragMinX: 0
      dragMinY: 0
      dragMaxX: canvas.width  - width
      dragMaxY: canvas.height - canvas._stripH - height

      // Orange border warns the user that two independent monitors are misaligned - a gap
      // or overlap that Hyprland will reject or mis-render.  Only canvas-placed monitors
      // are considered; disabled and mirroring outputs are excluded by definition.
      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: canvas.theme.accentOrange
        border.width: 2
        radius: 6
        visible: {
          for (let i = 0; i < canvas.monitors.length; i++) {
            if (i === enabledTile.index) continue;
            const o = canvas.monitors[i];
            if (!canvas._onCanvas(o)) continue;
            if (MonitorUtils.overlapsAABB(
                  modelData.x, modelData.y, MonitorUtils.logicalW(modelData), MonitorUtils.logicalH(modelData),
                  o.x, o.y, MonitorUtils.logicalW(o), MonitorUtils.logicalH(o)))
              return true;
          }
          return false;
        }
        z: 2
      }

      onClicked: canvas.monitorSelected(index)
      onDragStarted: {
        canvas.isDragging = true;
      }
      onDragMoved: (idx, cx, cy) => {
        canvas.updateSnapGuides(enabledTile, idx, cx, cy);
      }
      onDragCanceled: {
        canvas.isDragging = false;
        canvas.snapGuides = [];
        canvas.snapGhost = null;
        enabledTile.isSnapped = false;
        enabledTile.x = Qt.binding(() => canvas.originX + modelData.x * canvas.viewScale);
        enabledTile.y = Qt.binding(() => canvas.originY + modelData.y * canvas.viewScale);
      }
      onDragEnded: (idx, cx, cy) => {
        canvas.isDragging = false;
        canvas.snapGuides = [];
        canvas.snapGhost = null;
        enabledTile.isSnapped = false;
        canvas.snapAndCommit(idx, cx, cy);
        enabledTile.x = Qt.binding(() => canvas.originX + modelData.x * canvas.viewScale);
        enabledTile.y = Qt.binding(() => canvas.originY + modelData.y * canvas.viewScale);
      }
    }
  }

  Repeater {
    id: stripTiles
    model: {
      const mirrors  = [];
      const disabled = [];
      for (let i = 0; i < canvas.monitors.length; i++) {
        const m = canvas.monitors[i];
        if (m.disabled)            disabled.push({ monitor: m, origIndex: i });
        else if (m.mirrorOf !== "") mirrors.push({ monitor: m, origIndex: i });
      }
      const all = mirrors.concat(disabled);
      return all.map((e, col) => Object.assign({}, e, { col: col }));
    }

    delegate: MonitorTile {
      required property var modelData

      monitor:  modelData.monitor
      index:    modelData.origIndex
      selected: canvas.selectedIndex === modelData.origIndex
      theme:    canvas.theme
      font:     canvas.font

      x: 10 + modelData.col * 128   // left-to-right, 120px tile + 8px gap
      y: canvas.height - canvas._stripH + 26   // 20px label row + 6px gap
      width: 120
      height: 52

      onClicked: idx => canvas.monitorSelected(idx)
      onDragStarted: {}
      onDragCanceled: {}
      onDragEnded: (idx, cx, cy) => {}
    }
  }

  function calculateSnap(index, rawCanvasX, rawCanvasY) {
    let lx = (rawCanvasX - originX) / viewScale;
    let ly = (rawCanvasY - originY) / viewScale;

    const d = monitors[index];
    if (!d) return { snappedCanvasX: rawCanvasX, snappedCanvasY: rawCanvasY, lx: lx, ly: ly, isSnappedX: false, isSnappedY: false, guides: [] };

    const dW = MonitorUtils.logicalW(d);
    const dH = MonitorUtils.logicalH(d);

    // Snap distance: 24 canvas/screen pixels converted to logical coordinates
    const SNAP_PX = 24.0;
    const T = SNAP_PX / Math.max(viewScale, 0.001);

    const guides = [];
    let isSnappedX = false;
    let isSnappedY = false;

    // Active monitors on canvas (excluding dragged)
    const targets = [];
    for (let i = 0; i < monitors.length; i++) {
      if (i !== index && _onCanvas(monitors[i])) {
        targets.push(monitors[i]);
      }
    }

    if (targets.length === 0) {
      if (Math.abs(lx) < T) { lx = 0; isSnappedX = true; }
      if (Math.abs(ly) < T) { ly = 0; isSnappedY = true; }
      return {
        snappedCanvasX: originX + lx * viewScale,
        snappedCanvasY: originY + ly * viewScale,
        lx: lx,
        ly: ly,
        isSnappedX: isSnappedX,
        isSnappedY: isSnappedY,
        guides: guides
      };
    }

    let bestX = null;
    let minDistX = T;
    let bestGuideX = null;

    let bestY = null;
    let minDistY = T;
    let bestGuideY = null;

    for (let i = 0; i < targets.length; i++) {
      const m  = targets[i];
      const mW = MonitorUtils.logicalW(m);
      const mH = MonitorUtils.logicalH(m);

      const vDist = Math.max(0, Math.max(ly, m.y) - Math.min(ly + dH, m.y + mH));
      const vNearby = vDist < T * 1.5;

      const candsX = [
        { val: m.x + mW,           guideX: m.x + mW,           pri: vNearby ? 1.25 : 1.0 },
        { val: m.x - dW,           guideX: m.x,                pri: vNearby ? 1.25 : 1.0 },
        { val: m.x,                guideX: m.x,                pri: 1.0 },
        { val: m.x + mW - dW,      guideX: m.x + mW,           pri: 1.0 },
        { val: m.x + (mW - dW) / 2, guideX: m.x + mW / 2,      pri: 0.95 },
      ];

      for (const c of candsX) {
        const dist = Math.abs(lx - c.val) / c.pri;
        if (dist < minDistX) {
          minDistX = dist;
          bestX = c.val;
          const gCanvasX = originX + c.guideX * viewScale;
          const y1 = Math.min(originY + Math.min(ly, m.y) * viewScale, originY + m.y * viewScale) - 10;
          const y2 = Math.max(originY + Math.max(ly + dH, m.y + mH) * viewScale, originY + (m.y + mH) * viewScale) + 10;
          bestGuideX = {
            type: "v",
            pos: gCanvasX,
            start: Math.max(0, y1),
            end: Math.min(canvas.height - canvas._stripH, y2)
          };
        }
      }

      const hDist = Math.max(0, Math.max(lx, m.x) - Math.min(lx + dW, m.x + mW));
      const hNearby = hDist < T * 1.5;

      const candsY = [
        { val: m.y + mH,           guideY: m.y + mH,           pri: hNearby ? 1.25 : 1.0 },
        { val: m.y - dH,           guideY: m.y,                pri: hNearby ? 1.25 : 1.0 },
        { val: m.y,                guideY: m.y,                pri: 1.0 },
        { val: m.y + mH - dH,      guideY: m.y + mH,           pri: 1.0 },
        { val: m.y + (mH - dH) / 2, guideY: m.y + mH / 2,      pri: 0.95 },
      ];

      for (const c of candsY) {
        const dist = Math.abs(ly - c.val) / c.pri;
        if (dist < minDistY) {
          minDistY = dist;
          bestY = c.val;
          const gCanvasY = originY + c.guideY * viewScale;
          const x1 = Math.min(originX + Math.min(lx, m.x) * viewScale, originX + m.x * viewScale) - 10;
          const x2 = Math.max(originX + Math.max(lx + dW, m.x + mW) * viewScale, originX + (m.x + mW) * viewScale) + 10;
          bestGuideY = {
            type: "h",
            pos: gCanvasY,
            start: Math.max(0, x1),
            end: Math.min(canvas.width, x2)
          };
        }
      }
    }

    if (bestX !== null) {
      lx = bestX;
      isSnappedX = true;
      if (bestGuideX) guides.push(bestGuideX);
    }
    if (bestY !== null) {
      ly = bestY;
      isSnappedY = true;
      if (bestGuideY) guides.push(bestGuideY);
    }

    return {
      snappedCanvasX: originX + lx * viewScale,
      snappedCanvasY: originY + ly * viewScale,
      lx: lx,
      ly: ly,
      isSnappedX: isSnappedX,
      isSnappedY: isSnappedY,
      guides: guides
    };
  }

  function snapAndCommit(index, rawCanvasX, rawCanvasY) {
    const snap = calculateSnap(index, rawCanvasX, rawCanvasY);
    let lx = snap.lx;
    let ly = snap.ly;

    const d  = monitors[index];
    if (!d) return;
    const dW = MonitorUtils.logicalW(d);
    const dH = MonitorUtils.logicalH(d);

    // Resolve any overlaps with other canvas monitors (AABB push-out)
    for (let iter = 0; iter < monitors.length + 2; iter++) {
      let anyOverlap = false;
      for (let i = 0; i < monitors.length; i++) {
        if (i === index || !_onCanvas(monitors[i])) continue;
        const o  = monitors[i];
        const oW = MonitorUtils.logicalW(o);
        const oH = MonitorUtils.logicalH(o);
        if (!MonitorUtils.overlapsAABB(lx, ly, dW, dH, o.x, o.y, oW, oH)) continue;

        const relX = (lx + dW / 2) - (o.x + oW / 2);
        const relY = (ly + dH / 2) - (o.y + oH / 2);

        if (Math.abs(relX) >= Math.abs(relY)) {
          lx = relX >= 0 ? (o.x + oW) : (o.x - dW);
        } else {
          ly = relY >= 0 ? (o.y + oH) : (o.y - dH);
        }

        anyOverlap = true;
        break;
      }
      if (!anyOverlap) break;
    }

    // Build the updated monitor list
    const updated = monitors.map((m, i) => {
      if (i === index) {
        return Object.assign({}, m, { x: Math.round(lx), y: Math.round(ly) });
      }
      return Object.assign({}, m);
    });

    // Auto-normalize coordinates so minX=0, minY=0 (required by Hyprland)
    let minX = Infinity, minY = Infinity;
    for (const m of updated) {
      if (!_onCanvas(m)) continue;
      minX = Math.min(minX, m.x);
      minY = Math.min(minY, m.y);
    }
    if (isFinite(minX) && isFinite(minY) && (minX !== 0 || minY !== 0)) {
      for (let i = 0; i < updated.length; i++) {
        if (_onCanvas(updated[i])) {
          updated[i].x -= minX;
          updated[i].y -= minY;
        }
      }
    }

    canvas.monitorsArranged(updated);
    canvas.monitorMoved(index, Math.round(updated[index].x), Math.round(updated[index].y));
  }
}
