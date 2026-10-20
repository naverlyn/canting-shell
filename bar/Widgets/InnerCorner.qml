import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick.Effects
import "../../ControlCenter"
import "../Components"
import ".."

Canvas {
  id: cornerCanvas
  property color cornerColor: "black"
  property string cornerPosition: "top-left"
  antialiasing: true

  onCornerColorChanged: requestPaint()
  onCornerPositionChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    const w = width;
    const h = height;
    if (w <= 0 || h <= 0) return;
    ctx.clearRect(0, 0, w, h);

    ctx.fillStyle = cornerCanvas.cornerColor;
    ctx.beginPath();

    if (cornerPosition === "top-left") {
      ctx.moveTo(w, 0);
      ctx.arcTo(0, 0, 0, h, Math.min(w, h));
      ctx.lineTo(0, 0);
    } else if (cornerPosition === "top-right") {
      ctx.moveTo(0, 0);
      ctx.arcTo(w, 0, w, h, Math.min(w, h));
      ctx.lineTo(w, 0);
    } else if (cornerPosition === "bottom-left") {
      ctx.moveTo(w, h);
      ctx.arcTo(0, h, 0, 0, Math.min(w, h));
      ctx.lineTo(0, h);
    } else if (cornerPosition === "bottom-right") {
      ctx.moveTo(0, h);
      ctx.arcTo(w, h, w, 0, Math.min(w, h));
      ctx.lineTo(w, h);
    }

    ctx.closePath();
    ctx.fill();
  }
}
