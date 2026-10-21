import Quickshell
import QtQuick
import "../Widgets"
import ".."

Item {
  id: borderRoot
  required property var screen
  required property int screenIndex
  required property var barRoot

  readonly property int borderThickness: Math.max(1, Number(BarConfig.screenBorderThickness || 4))
  readonly property int cornerRadius: 16
  readonly property bool hasShadow: Boolean(BarConfig.screenBorderShadow)
  readonly property int shadowSize: Math.max(1, Number(BarConfig.screenBorderShadowSize || 12))
  readonly property real shadowOpacity: 0.38

  readonly property bool hasDockedTop: barRoot.isDockedBarActive("top", undefined, screenIndex)
  readonly property bool hasDockedBottom: barRoot.isDockedBarActive("bottom", undefined, screenIndex)
  readonly property bool hasDockedLeft: barRoot.isDockedBarActive("left", undefined, screenIndex)
  readonly property bool hasDockedRight: barRoot.isDockedBarActive("right", undefined, screenIndex)

  readonly property int dockedLeftW: barRoot.getDockedBarThickness("left", undefined, screenIndex)
  readonly property int dockedRightW: barRoot.getDockedBarThickness("right", undefined, screenIndex)
  readonly property int dockedTopH: barRoot.getDockedBarThickness("top", undefined, screenIndex)
  readonly property int dockedBottomH: barRoot.getDockedBarThickness("bottom", undefined, screenIndex)

  readonly property int effectiveDockedLeft: hasDockedLeft ? dockedLeftW : (BarConfig.screenBorder ? borderThickness : 0)
  readonly property int effectiveDockedRight: hasDockedRight ? dockedRightW : (BarConfig.screenBorder ? borderThickness : 0)
  readonly property int effectiveDockedTop: hasDockedTop ? dockedTopH : (BarConfig.screenBorder ? borderThickness : 0)
  readonly property int effectiveDockedBottom: hasDockedBottom ? dockedBottomH : (BarConfig.screenBorder ? borderThickness : 0)

  readonly property bool topActive: effectiveDockedTop > 0
  readonly property bool bottomActive: effectiveDockedBottom > 0
  readonly property bool leftActive: effectiveDockedLeft > 0
  readonly property bool rightActive: effectiveDockedRight > 0
  readonly property bool anyEdgeActive: topActive || bottomActive || leftActive || rightActive

  readonly property bool borderCornersEnabled: Boolean(BarConfig.screenBorder) && Boolean(BarConfig.screenBorderCorners)
  readonly property bool showTopLeftCorner: Boolean(BarConfig.innerCorners) && (topActive && leftActive) && ((hasDockedTop || hasDockedLeft) ? true : borderCornersEnabled)
  readonly property bool showTopRightCorner: Boolean(BarConfig.innerCorners) && (topActive && rightActive) && ((hasDockedTop || hasDockedRight) ? true : borderCornersEnabled)
  readonly property bool showBottomLeftCorner: Boolean(BarConfig.innerCorners) && (bottomActive && leftActive) && ((hasDockedBottom || hasDockedLeft) ? true : borderCornersEnabled)
  readonly property bool showBottomRightCorner: Boolean(BarConfig.innerCorners) && (bottomActive && rightActive) && ((hasDockedBottom || hasDockedRight) ? true : borderCornersEnabled)
  readonly property bool anyCornerVisible: showTopLeftCorner || showTopRightCorner || showBottomLeftCorner || showBottomRightCorner

  readonly property color resolvedBorderColor: {
    const spec = BarConfig.screenBorderColor;
    if (spec && String(spec).trim() !== "") {
      return barRoot.resolveThemeSpec(spec, barRoot.theme.bgBase);
    }
    const cur = BarConfig.bars && BarConfig.bars.length > 0 ? BarConfig.bars[0] : null;
    const colSpec = cur && cur.barColor ? cur.barColor : BarConfig.barColor;
    const baseCol = barRoot.resolveThemeSpec(colSpec, barRoot.theme.bgBase);
    const alpha = BarConfig.barOpacity !== undefined ? BarConfig.barOpacity : (cur && cur.barOpacity !== undefined ? cur.barOpacity : 1.0);
    return Qt.rgba(baseCol.r, baseCol.g, baseCol.b, alpha);
  }

  onShadowSizeChanged: shadowCanvas.requestPaint()
  onHasShadowChanged: shadowCanvas.requestPaint()
  onShowTopLeftCornerChanged: shadowCanvas.requestPaint()
  onShowTopRightCornerChanged: shadowCanvas.requestPaint()
  onShowBottomLeftCornerChanged: shadowCanvas.requestPaint()
  onShowBottomRightCornerChanged: shadowCanvas.requestPaint()
  onEffectiveDockedTopChanged: shadowCanvas.requestPaint()
  onEffectiveDockedBottomChanged: shadowCanvas.requestPaint()
  onEffectiveDockedLeftChanged: shadowCanvas.requestPaint()
  onEffectiveDockedRightChanged: shadowCanvas.requestPaint()

  // Top Border Strip (active when no docked top bar is present)
  PanelWindow {
    id: topBorderWindow
    screen: borderRoot.screen
    visible: borderRoot.barRoot.barVisible && Boolean(BarConfig.screenBorder) && !borderRoot.hasDockedTop
    color: "transparent"
    mask: Region {}

    anchors {
      top: true
      left: true
      right: true
    }
    exclusiveZone: borderRoot.borderThickness
    implicitHeight: borderRoot.borderThickness
    height: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolvedBorderColor
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }

  // Bottom Border Strip (active when no docked bottom bar is present)
  PanelWindow {
    id: bottomBorderWindow
    screen: borderRoot.screen
    visible: borderRoot.barRoot.barVisible && Boolean(BarConfig.screenBorder) && !borderRoot.hasDockedBottom
    color: "transparent"
    mask: Region {}

    anchors {
      bottom: true
      left: true
      right: true
    }
    exclusiveZone: borderRoot.borderThickness
    implicitHeight: borderRoot.borderThickness
    height: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolvedBorderColor
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }

  // Left Border Strip (active when no docked left bar is present)
  PanelWindow {
    id: leftBorderWindow
    screen: borderRoot.screen
    visible: borderRoot.barRoot.barVisible && Boolean(BarConfig.screenBorder) && !borderRoot.hasDockedLeft
    color: "transparent"
    mask: Region {}

    anchors {
      left: true
      top: true
      bottom: true
    }
    exclusiveZone: borderRoot.borderThickness
    implicitWidth: borderRoot.borderThickness
    width: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolvedBorderColor
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }

  // Right Border Strip (active when no docked right bar is present)
  PanelWindow {
    id: rightBorderWindow
    screen: borderRoot.screen
    visible: borderRoot.barRoot.barVisible && Boolean(BarConfig.screenBorder) && !borderRoot.hasDockedRight
    color: "transparent"
    mask: Region {}

    anchors {
      right: true
      top: true
      bottom: true
    }
    exclusiveZone: borderRoot.borderThickness
    implicitWidth: borderRoot.borderThickness
    width: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolvedBorderColor
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }

  // Full-Screen Inner Corners & Curved Inner Shadow Overlay
  // Uses ExclusionMode.Ignore (without exclusiveZone) so Hyprland never shifts or shrinks this window;
  // it always maps 1:1 to physical screen coordinates (0, 0, screen.width, screen.height).
  PanelWindow {
    id: innerOverlayWindow
    screen: borderRoot.screen
    visible: borderRoot.barRoot.barVisible && (borderRoot.anyCornerVisible || (borderRoot.hasShadow && borderRoot.anyEdgeActive))
    color: "transparent"
    mask: Region {}
    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    Item {
      id: innerViewport
      anchors.fill: parent
      anchors.topMargin: borderRoot.effectiveDockedTop
      anchors.bottomMargin: borderRoot.effectiveDockedBottom
      anchors.leftMargin: borderRoot.effectiveDockedLeft
      anchors.rightMargin: borderRoot.effectiveDockedRight

      Canvas {
        id: shadowCanvas
        anchors.fill: parent
        visible: borderRoot.hasShadow && borderRoot.anyEdgeActive
        antialiasing: true

        Component.onCompleted: requestPaint()
        onAvailableChanged: if (available) requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function addRoundedRectCW(ctx, x, y, w, h, rtl, rtr, rbr, rbl) {
          ctx.moveTo(x + rtl, y);
          ctx.lineTo(x + w - rtr, y);
          if (rtr > 0) ctx.arcTo(x + w, y, x + w, y + rtr, rtr);
          else ctx.lineTo(x + w, y);
          ctx.lineTo(x + w, y + h - rbr);
          if (rbr > 0) ctx.arcTo(x + w, y + h, x + w - rbr, y + h, rbr);
          else ctx.lineTo(x + w, y + h);
          ctx.lineTo(x + rbl, y + h);
          if (rbl > 0) ctx.arcTo(x, y + h, x, y + h - rbl, rbl);
          else ctx.lineTo(x, y + h);
          ctx.lineTo(x, y + rtl);
          if (rtl > 0) ctx.arcTo(x, y, x + rtl, y, rtl);
          else ctx.lineTo(x, y);
          ctx.closePath();
        }

        function addRoundedRectCCW(ctx, x, y, w, h, rtl, rtr, rbr, rbl) {
          ctx.moveTo(x + rtl, y);
          if (rtl > 0) ctx.arcTo(x, y, x, y + rtl, rtl);
          else ctx.lineTo(x, y);
          ctx.lineTo(x, y + h - rbl);
          if (rbl > 0) ctx.arcTo(x, y + h, x + rbl, y + h, rbl);
          else ctx.lineTo(x, y + h);
          ctx.lineTo(x + w - rbr, y + h);
          if (rbr > 0) ctx.arcTo(x + w, y + h, x + w, y + h - rbr, rbr);
          else ctx.lineTo(x + w, y + h);
          ctx.lineTo(x + w, y + rtr);
          if (rtr > 0) ctx.arcTo(x + w, y, x + w - rtr, y, rtr);
          else ctx.lineTo(x + w, y);
          ctx.closePath();
        }

        onPaint: {
          const ctx = getContext("2d");
          const w = width;
          const h = height;
          if (w <= 0 || h <= 0) return;
          ctx.clearRect(0, 0, w, h);

          if (!borderRoot.hasShadow || !borderRoot.anyEdgeActive) return;

          const s = borderRoot.shadowSize;
          const baseR = borderRoot.cornerRadius;
          const rTL = borderRoot.showTopLeftCorner ? baseR : 0;
          const rTR = borderRoot.showTopRightCorner ? baseR : 0;
          const rBR = borderRoot.showBottomRightCorner ? baseR : 0;
          const rBL = borderRoot.showBottomLeftCorner ? baseR : 0;

          const outTL = rTL > 0 ? Math.max(0, rTL - 0.75) : 0;
          const outTR = rTR > 0 ? Math.max(0, rTR - 0.75) : 0;
          const outBR = rBR > 0 ? Math.max(0, rBR - 0.75) : 0;
          const outBL = rBL > 0 ? Math.max(0, rBL - 0.75) : 0;

          const pad = s * 2 + 4;
          const x0 = borderRoot.leftActive ? 0 : -pad;
          const y0 = borderRoot.topActive ? 0 : -pad;
          const x1 = borderRoot.rightActive ? w : w + pad;
          const y1 = borderRoot.bottomActive ? h : h + pad;
          const rw = x1 - x0;
          const rh = y1 - y0;

          ctx.save();
          ctx.beginPath();
          addRoundedRectCW(ctx, 0, 0, w, h, outTL, outTR, outBR, outBL);
          ctx.clip();

          const steps = Math.min(32, Math.max(16, s));
          for (let i = 1; i <= steps; i++) {
            const u = i / steps;
            const inset = s * u;
            const ringAlpha = (borderRoot.shadowOpacity * 2.4 / steps) * Math.pow(1.0 - u, 1.35);
            if (ringAlpha <= 0.001) continue;

            ctx.fillStyle = Qt.rgba(0, 0, 0, ringAlpha);

            const ix = x0 + inset;
            const iy = y0 + inset;
            const iw = rw - inset * 2;
            const ih = rh - inset * 2;
            if (iw <= 0 || ih <= 0) continue;

            const maxR = Math.min(iw * 0.5, ih * 0.5);
            const inTL = rTL > 0 ? Math.min(maxR, rTL * Math.exp(-inset / (rTL * 1.1))) : 0;
            const inTR = rTR > 0 ? Math.min(maxR, rTR * Math.exp(-inset / (rTR * 1.1))) : 0;
            const inBR = rBR > 0 ? Math.min(maxR, rBR * Math.exp(-inset / (rBR * 1.1))) : 0;
            const inBL = rBL > 0 ? Math.min(maxR, rBL * Math.exp(-inset / (rBL * 1.1))) : 0;

            ctx.beginPath();
            addRoundedRectCW(ctx, x0, y0, rw, rh, outTL, outTR, outBR, outBL);
            addRoundedRectCCW(ctx, ix, iy, iw, ih, inTL, inTR, inBR, inBL);
            ctx.fill();
          }
          ctx.restore();
        }
      }

      InnerCorner {
        id: cornerTopLeft
        visible: borderRoot.showTopLeftCorner
        cornerPosition: "top-left"
        cornerColor: borderRoot.resolvedBorderColor
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.top: parent.top
        anchors.left: parent.left
      }

      InnerCorner {
        id: cornerTopRight
        visible: borderRoot.showTopRightCorner
        cornerPosition: "top-right"
        cornerColor: borderRoot.resolvedBorderColor
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.top: parent.top
        anchors.right: parent.right
      }

      InnerCorner {
        id: cornerBottomLeft
        visible: borderRoot.showBottomLeftCorner
        cornerPosition: "bottom-left"
        cornerColor: borderRoot.resolvedBorderColor
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.bottom: parent.bottom
        anchors.left: parent.left
      }

      InnerCorner {
        id: cornerBottomRight
        visible: borderRoot.showBottomRightCorner
        cornerPosition: "bottom-right"
        cornerColor: borderRoot.resolvedBorderColor
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.bottom: parent.bottom
        anchors.right: parent.right
      }
    }
  }
}
