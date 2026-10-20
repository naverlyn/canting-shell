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

  onFluidEnabledChanged: if (canvas.visible) canvas.requestPaint()
  onBarPositionChanged: if (canvas.visible) canvas.requestPaint()
  onCornerRadiusChanged: if (canvas.visible) canvas.requestPaint()
  onCardColorChanged: if (canvas.visible) canvas.requestPaint()
  onBorderColorChanged: if (canvas.visible) canvas.requestPaint()
  onBorderWidthChanged: if (canvas.visible) canvas.requestPaint()
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

  // --- Fluid Mode (Single-pass Canvas vector path for body + inner corners) ---
  Canvas {
    id: canvas
    visible: root.fluidEnabled
    anchors.fill: parent
    antialiasing: true
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
      const ctx = getContext("2d");
      const w = width;
      const h = height;
      const r = root.cornerRadius;
      if (w <= 0 || h <= 0) return;
      ctx.clearRect(0, 0, w, h);

      ctx.fillStyle = root.cardColor;
      ctx.beginPath();

      if (root.barPosition === "top") {
        ctx.moveTo(0, 0);
        ctx.arcTo(r, 0, r, r, r);
        ctx.lineTo(r, h - r);
        ctx.arcTo(r, h, r + r, h, r);
        ctx.lineTo(w - r - r, h);
        ctx.arcTo(w - r, h, w - r, h - r, r);
        ctx.lineTo(w - r, r);
        ctx.arcTo(w - r, 0, w, 0, r);
        ctx.lineTo(0, 0);
        ctx.closePath();
        ctx.fill();

        if (root.borderWidth > 0 && root.borderColor !== "transparent" && root.borderColor !== "#00000000") {
          ctx.strokeStyle = root.borderColor;
          ctx.lineWidth = root.borderWidth;
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.arcTo(r, 0, r, r, r);
          ctx.lineTo(r, h - r);
          ctx.arcTo(r, h, r + r, h, r);
          ctx.lineTo(w - r - r, h);
          ctx.arcTo(w - r, h, w - r, h - r, r);
          ctx.lineTo(w - r, r);
          ctx.arcTo(w - r, 0, w, 0, r);
          ctx.stroke();
        }
      } else if (root.barPosition === "bottom") {
        ctx.moveTo(0, h);
        ctx.arcTo(r, h, r, h - r, r);
        ctx.lineTo(r, r);
        ctx.arcTo(r, 0, r + r, 0, r);
        ctx.lineTo(w - r - r, 0);
        ctx.arcTo(w - r, 0, w - r, r, r);
        ctx.lineTo(w - r, h - r);
        ctx.arcTo(w - r, h, w, h, r);
        ctx.lineTo(0, h);
        ctx.closePath();
        ctx.fill();

        if (root.borderWidth > 0 && root.borderColor !== "transparent" && root.borderColor !== "#00000000") {
          ctx.strokeStyle = root.borderColor;
          ctx.lineWidth = root.borderWidth;
          ctx.beginPath();
          ctx.moveTo(0, h);
          ctx.arcTo(r, h, r, h - r, r);
          ctx.lineTo(r, r);
          ctx.arcTo(r, 0, r + r, 0, r);
          ctx.lineTo(w - r - r, 0);
          ctx.arcTo(w - r, 0, w - r, r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w - r, h, w, h, r);
          ctx.stroke();
        }
      } else if (root.barPosition === "left") {
        ctx.moveTo(0, 0);
        ctx.arcTo(0, r, r, r, r);
        ctx.lineTo(w - r, r);
        ctx.arcTo(w, r, w, r + r, r);
        ctx.lineTo(w, h - r - r);
        ctx.arcTo(w, h - r, w - r, h - r, r);
        ctx.lineTo(r, h - r);
        ctx.arcTo(0, h - r, 0, h, r);
        ctx.lineTo(0, 0);
        ctx.closePath();
        ctx.fill();

        if (root.borderWidth > 0 && root.borderColor !== "transparent" && root.borderColor !== "#00000000") {
          ctx.strokeStyle = root.borderColor;
          ctx.lineWidth = root.borderWidth;
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.arcTo(0, r, r, r, r);
          ctx.lineTo(w - r, r);
          ctx.arcTo(w, r, w, r + r, r);
          ctx.lineTo(w, h - r - r);
          ctx.arcTo(w, h - r, w - r, h - r, r);
          ctx.lineTo(r, h - r);
          ctx.arcTo(0, h - r, 0, h, r);
          ctx.stroke();
        }
      } else if (root.barPosition === "right") {
        ctx.moveTo(w, 0);
        ctx.arcTo(w, r, w - r, r, r);
        ctx.lineTo(r, r);
        ctx.arcTo(0, r, 0, r + r, r);
        ctx.lineTo(0, h - r - r);
        ctx.arcTo(0, h - r, r, h - r, r);
        ctx.lineTo(w - r, h - r);
        ctx.arcTo(w, h - r, w, h, r);
        ctx.lineTo(w, 0);
        ctx.closePath();
        ctx.fill();

        if (root.borderWidth > 0 && root.borderColor !== "transparent" && root.borderColor !== "#00000000") {
          ctx.strokeStyle = root.borderColor;
          ctx.lineWidth = root.borderWidth;
          ctx.beginPath();
          ctx.moveTo(w, 0);
          ctx.arcTo(w, r, w - r, r, r);
          ctx.lineTo(r, r);
          ctx.arcTo(0, r, 0, r + r, r);
          ctx.lineTo(0, h - r - r);
          ctx.arcTo(0, h - r, r, h - r, r);
          ctx.lineTo(w - r, h - r);
          ctx.arcTo(w, h - r, w, h, r);
          ctx.stroke();
        }
      }
    }
  }
}
