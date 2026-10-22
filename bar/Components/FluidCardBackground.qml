import QtQuick

Item {
  id: root
  property bool fluidEnabled: true
  property string barPosition: "top" // "top" | "bottom" | "left" | "right"
  property int cornerRadius: 16
  property color cardColor: "#1a1b26"
  property color borderColor: "#32364a"
  property real borderWidth: 1
  property int flyoutRadius: 12

  // Edge docking / joining when near screen edge
  property bool joinTop: false
  property bool joinBottom: false
  property bool joinLeft: false
  property bool joinRight: false

  // Integrated drop shadow settings
  property bool shadowEnabled: true
  property int shadowPad: fluidEnabled ? 8 : 8
  property int shadowBlur: fluidEnabled ? 8 : 10
  property color shadowColor: Qt.rgba(0, 0, 0, 0.36)

  onFluidEnabledChanged: if (canvas.visible) canvas.requestPaint()
  onBarPositionChanged: if (canvas.visible) canvas.requestPaint()
  onJoinTopChanged: if (canvas.visible) canvas.requestPaint()
  onJoinBottomChanged: if (canvas.visible) canvas.requestPaint()
  onJoinLeftChanged: if (canvas.visible) canvas.requestPaint()
  onJoinRightChanged: if (canvas.visible) canvas.requestPaint()
  onCornerRadiusChanged: if (canvas.visible) canvas.requestPaint()
  onCardColorChanged: if (canvas.visible) canvas.requestPaint()
  onBorderColorChanged: if (canvas.visible) canvas.requestPaint()
  onBorderWidthChanged: if (canvas.visible) canvas.requestPaint()
  onShadowEnabledChanged: if (canvas.visible) canvas.requestPaint()
  onShadowPadChanged: if (canvas.visible) canvas.requestPaint()
  onShadowBlurChanged: if (canvas.visible) canvas.requestPaint()
  onShadowColorChanged: if (canvas.visible) canvas.requestPaint()
  onWidthChanged: if (canvas.visible) canvas.requestPaint()
  onHeightChanged: if (canvas.visible) canvas.requestPaint()

  // --- Flyout Mode (Standard Rounded Rectangle) ---
  Rectangle {
    id: flyoutRect
    visible: !root.fluidEnabled
    anchors.fill: parent
    radius: root.flyoutRadius
    color: root.cardColor
    border.color: root.borderColor
    border.width: root.borderWidth
  }

  // --- Fluid Mode (Single-pass Canvas vector path for body + inner corners + integrated shadow) ---
  Canvas {
    id: canvas
    visible: root.fluidEnabled
    anchors.fill: parent
    antialiasing: true
    onAvailableChanged: if (available) requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    function traceFluidPath(ctx, w, h, r, s, pos) {
      if (!root.fluidEnabled) {
        const x0 = s, y0 = s, x1 = w - s, y1 = h - s;
        ctx.moveTo(x0 + r, y0);
        ctx.lineTo(x1 - r, y0);
        ctx.arcTo(x1, y0, x1, y0 + r, r);
        ctx.lineTo(x1, y1 - r);
        ctx.arcTo(x1, y1, x1 - r, y1, r);
        ctx.lineTo(x0 + r, y1);
        ctx.arcTo(x0, y1, x0, y1 - r, r);
        ctx.lineTo(x0, y0 + r);
        ctx.arcTo(x0, y0, x0 + r, y0, r);
        ctx.closePath();
      } else if (pos === "right") {
        if (root.joinTop) {
          ctx.moveTo(w, 0);
          ctx.lineTo(s + r, 0);
          ctx.arcTo(s, 0, s, r, r);
        } else {
          ctx.moveTo(w, 0);
          ctx.arcTo(w, r, w - r, r, r);
          ctx.lineTo(s + r, r);
          ctx.arcTo(s, r, s, r + r, r);
        }

        if (root.joinBottom) {
          ctx.lineTo(s, h - r);
          ctx.arcTo(s, h, s + r, h, r);
          ctx.lineTo(w, h);
        } else {
          ctx.lineTo(s, h - r - r);
          ctx.arcTo(s, h - r, s + r, h - r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w, h - r, w, h, r);
        }
        ctx.lineTo(w, 0);
        ctx.closePath();
      } else if (pos === "left") {
        if (root.joinTop) {
          ctx.moveTo(0, 0);
          ctx.lineTo(w - s - r, 0);
          ctx.arcTo(w - s, 0, w - s, r, r);
        } else {
          ctx.moveTo(0, 0);
          ctx.arcTo(0, r, r, r, r);
          ctx.lineTo(w - s - r, r);
          ctx.arcTo(w - s, r, w - s, r + r, r);
        }

        if (root.joinBottom) {
          ctx.lineTo(w - s, h - r);
          ctx.arcTo(w - s, h, w - s - r, h, r);
          ctx.lineTo(0, h);
        } else {
          ctx.lineTo(w - s, h - r - r);
          ctx.arcTo(w - s, h - r, w - s - r, h - r, r);
          ctx.lineTo(r, h - r);
          ctx.arcTo(0, h - r, 0, h, r);
        }
        ctx.lineTo(0, 0);
        ctx.closePath();
      } else if (pos === "top") {
        if (root.joinLeft) {
          ctx.moveTo(0, 0);
          ctx.lineTo(0, h - s - r);
          ctx.arcTo(0, h - s, r, h - s, r);
        } else {
          ctx.moveTo(0, 0);
          ctx.arcTo(r, 0, r, r, r);
          ctx.lineTo(r, h - s - r);
          ctx.arcTo(r, h - s, r + r, h - s, r);
        }

        if (root.joinRight) {
          ctx.lineTo(w - r, h - s);
          ctx.arcTo(w, h - s, w, h - s - r, r);
          ctx.lineTo(w, 0);
        } else {
          ctx.lineTo(w - r - r, h - s);
          ctx.arcTo(w - r, h - s, w - r, h - s - r, r);
          ctx.lineTo(w - r, r);
          ctx.arcTo(w - r, 0, w, 0, r);
        }
        ctx.lineTo(0, 0);
        ctx.closePath();
      } else if (pos === "bottom") {
        if (root.joinLeft) {
          ctx.moveTo(0, h);
          ctx.lineTo(0, s + r);
          ctx.arcTo(0, s, r, s, r);
        } else {
          ctx.moveTo(0, h);
          ctx.arcTo(r, h, r, h - r, r);
          ctx.lineTo(r, s + r);
          ctx.arcTo(r, s, r + r, s, r);
        }

        if (root.joinRight) {
          ctx.lineTo(w - r, s);
          ctx.arcTo(w, s, w, s + r, r);
          ctx.lineTo(w, h);
        } else {
          ctx.lineTo(w - r - r, s);
          ctx.arcTo(w - r, s, w - r, s + r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w - r, h, w, h, r);
        }
        ctx.lineTo(0, h);
        ctx.closePath();
      }
    }

    function strokeFluidBorder(ctx, w, h, r, s, pos) {
      ctx.beginPath();
      if (!root.fluidEnabled) {
        const x0 = s, y0 = s, x1 = w - s, y1 = h - s;
        ctx.moveTo(x0 + r, y0);
        ctx.lineTo(x1 - r, y0);
        ctx.arcTo(x1, y0, x1, y0 + r, r);
        ctx.lineTo(x1, y1 - r);
        ctx.arcTo(x1, y1, x1 - r, y1, r);
        ctx.lineTo(x0 + r, y1);
        ctx.arcTo(x0, y1, x0, y1 - r, r);
        ctx.lineTo(x0, y0 + r);
        ctx.arcTo(x0, y0, x0 + r, y0, r);
        ctx.stroke();
      } else if (pos === "right") {
        if (root.joinTop) {
          ctx.moveTo(w, 0);
          ctx.lineTo(s + r, 0);
          ctx.arcTo(s, 0, s, r, r);
        } else {
          ctx.moveTo(w, 0);
          ctx.arcTo(w, r, w - r, r, r);
          ctx.lineTo(s + r, r);
          ctx.arcTo(s, r, s, r + r, r);
        }

        if (root.joinBottom) {
          ctx.lineTo(s, h - r);
          ctx.arcTo(s, h, s + r, h, r);
          ctx.lineTo(w, h);
        } else {
          ctx.lineTo(s, h - r - r);
          ctx.arcTo(s, h - r, s + r, h - r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w, h - r, w, h, r);
        }
        ctx.stroke();
      } else if (pos === "left") {
        if (root.joinTop) {
          ctx.moveTo(0, 0);
          ctx.lineTo(w - s - r, 0);
          ctx.arcTo(w - s, 0, w - s, r, r);
        } else {
          ctx.moveTo(0, 0);
          ctx.arcTo(0, r, r, r, r);
          ctx.lineTo(w - s - r, r);
          ctx.arcTo(w - s, r, w - s, r + r, r);
        }

        if (root.joinBottom) {
          ctx.lineTo(w - s, h - r);
          ctx.arcTo(w - s, h, w - s - r, h, r);
          ctx.lineTo(0, h);
        } else {
          ctx.lineTo(w - s, h - r - r);
          ctx.arcTo(w - s, h - r, w - s - r, h - r, r);
          ctx.lineTo(r, h - r);
          ctx.arcTo(0, h - r, 0, h, r);
        }
        ctx.stroke();
      } else if (pos === "top") {
        if (root.joinLeft) {
          ctx.moveTo(0, 0);
          ctx.lineTo(0, h - s - r);
          ctx.arcTo(0, h - s, r, h - s, r);
        } else {
          ctx.moveTo(0, 0);
          ctx.arcTo(r, 0, r, r, r);
          ctx.lineTo(r, h - s - r);
          ctx.arcTo(r, h - s, r + r, h - s, r);
        }

        if (root.joinRight) {
          ctx.lineTo(w - r, h - s);
          ctx.arcTo(w, h - s, w, h - s - r, r);
          ctx.lineTo(w, 0);
        } else {
          ctx.lineTo(w - r - r, h - s);
          ctx.arcTo(w - r, h - s, w - r, h - s - r, r);
          ctx.lineTo(w - r, r);
          ctx.arcTo(w - r, 0, w, 0, r);
        }
        ctx.stroke();
      } else if (pos === "bottom") {
        if (root.joinLeft) {
          ctx.moveTo(0, h);
          ctx.lineTo(0, s + r);
          ctx.arcTo(0, s, r, s, r);
        } else {
          ctx.moveTo(0, h);
          ctx.arcTo(r, h, r, h - r, r);
          ctx.lineTo(r, s + r);
          ctx.arcTo(r, s, r + r, s, r);
        }

        if (root.joinRight) {
          ctx.lineTo(w - r, s);
          ctx.arcTo(w, s, w, s + r, r);
          ctx.lineTo(w, h);
        } else {
          ctx.lineTo(w - r - r, s);
          ctx.arcTo(w - r, s, w - r, s + r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w - r, h, w, h, r);
        }
        ctx.stroke();
      }
    }

    onPaint: {
      const ctx = getContext("2d");
      const w = width;
      const h = height;
      const r = root.cornerRadius;
      const s = root.shadowPad;
      const pos = root.fluidEnabled ? root.barPosition : "flyout";

      if (w <= 0 || h <= 0) return;
      ctx.clearRect(0, 0, w, h);

      let ox = 0, oy = 2;
      if (pos === "right") { ox = -2; oy = 1; }
      else if (pos === "left") { ox = 2; oy = 1; }
      else if (pos === "top") { ox = 0; oy = 2; }
      else if (pos === "bottom") { ox = 0; oy = -2; }

      // 1. Outset-only Drop Shadow
      // Clipped with evenodd so the shadow NEVER penetrates the card interior.
      // This guarantees that the semi-transparent fill is 100% free of darkening
      // and maintains pure 1:1 opacity match with the host bar!
      if (root.shadowEnabled && root.shadowBlur > 0) {
        ctx.save();
        ctx.beginPath();
        ctx.rect(-30, -30, w + 60, h + 60);
        traceFluidPath(ctx, w, h, r, s, pos);
        ctx.clip("evenodd");

        ctx.shadowColor = root.shadowColor;
        ctx.shadowBlur = root.shadowBlur;
        ctx.shadowOffsetX = ox;
        ctx.shadowOffsetY = oy;
        ctx.fillStyle = "rgba(0, 0, 0, 1)";
        ctx.beginPath();
        traceFluidPath(ctx, w, h, r, s, pos);
        ctx.fill();

        ctx.restore();
      }

      // 2. Crisp Single-Pass Card Fill
      ctx.save();
      ctx.shadowColor = "transparent";
      ctx.fillStyle = root.cardColor;
      ctx.beginPath();
      traceFluidPath(ctx, w, h, r, s, pos);
      ctx.fill();
      ctx.restore();

      // 3. Subtle Outer Stroke Border (never stroked against the docked bar edge)
      if (root.borderWidth > 0 && root.borderColor !== "transparent" && root.borderColor !== "#00000000") {
        ctx.save();
        ctx.shadowColor = "transparent";
        ctx.strokeStyle = root.borderColor;
        ctx.lineWidth = root.borderWidth;
        strokeFluidBorder(ctx, w, h, r, s, pos);
        ctx.restore();
      }
    }
  }
}
