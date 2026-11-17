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
  readonly property int shadowSize: Math.max(1, Number(BarConfig.screenBorderShadowSize || 12))
  readonly property real shadowOpacity: Math.max(0.05, Math.min(1.0, Number(BarConfig.screenBorderShadowOpacity !== undefined ? BarConfig.screenBorderShadowOpacity : 0.35)))
  readonly property real shadowBlur: Math.max(0.0, Math.min(1.0, Number(BarConfig.screenBorderShadowBlur !== undefined ? BarConfig.screenBorderShadowBlur : 0.5)))

  readonly property bool hasDockedTop: barRoot.isDockedBarActive("top", undefined, screenIndex)
  readonly property bool hasDockedBottom: barRoot.isDockedBarActive("bottom", undefined, screenIndex)
  readonly property bool hasDockedLeft: barRoot.isDockedBarActive("left", undefined, screenIndex)
  readonly property bool hasDockedRight: barRoot.isDockedBarActive("right", undefined, screenIndex)
  readonly property bool hasFloatingTop: barRoot.isFloatingBarActive("top", undefined, screenIndex)
  readonly property bool hasFloatingBottom: barRoot.isFloatingBarActive("bottom", undefined, screenIndex)
  readonly property bool hasFloatingLeft: barRoot.isFloatingBarActive("left", undefined, screenIndex)
  readonly property bool hasFloatingRight: barRoot.isFloatingBarActive("right", undefined, screenIndex)
  readonly property bool hasAnyDockedBar: hasDockedTop || hasDockedBottom || hasDockedLeft || hasDockedRight
  readonly property bool hasAnyFloatingBar: hasFloatingTop || hasFloatingBottom || hasFloatingLeft || hasFloatingRight
  readonly property bool screenBorderActive: Boolean(BarConfig.screenBorder)
  readonly property bool hasShadow: Boolean(BarConfig.screenBorderShadow) && (hasAnyDockedBar || screenBorderActive)

  readonly property int dockedLeftW: barRoot.getDockedBarThickness("left", undefined, screenIndex)
  readonly property int dockedRightW: barRoot.getDockedBarThickness("right", undefined, screenIndex)
  readonly property int dockedTopH: barRoot.getDockedBarThickness("top", undefined, screenIndex)
  readonly property int dockedBottomH: barRoot.getDockedBarThickness("bottom", undefined, screenIndex)

  readonly property int effectiveDockedLeft: hasDockedLeft ? dockedLeftW : (screenBorderActive ? borderThickness : 0)
  readonly property int effectiveDockedRight: hasDockedRight ? dockedRightW : (screenBorderActive ? borderThickness : 0)
  readonly property int effectiveDockedTop: hasDockedTop ? dockedTopH : (screenBorderActive ? borderThickness : 0)
  readonly property int effectiveDockedBottom: hasDockedBottom ? dockedBottomH : (screenBorderActive ? borderThickness : 0)

  readonly property bool topActive: effectiveDockedTop > 0
  readonly property bool bottomActive: effectiveDockedBottom > 0
  readonly property bool leftActive: effectiveDockedLeft > 0
  readonly property bool rightActive: effectiveDockedRight > 0
  readonly property bool anyEdgeActive: topActive || bottomActive || leftActive || rightActive

  readonly property bool borderCornersEnabled: screenBorderActive && Boolean(BarConfig.screenBorderCorners)
  readonly property bool showTopLeftCorner: Boolean(BarConfig.innerCorners) && (hasAnyDockedBar || screenBorderActive) && (hasDockedTop || hasDockedLeft || (topActive && leftActive && borderCornersEnabled))
  readonly property bool showTopRightCorner: Boolean(BarConfig.innerCorners) && (hasAnyDockedBar || screenBorderActive) && (hasDockedTop || hasDockedRight || (topActive && rightActive && borderCornersEnabled))
  readonly property bool showBottomLeftCorner: Boolean(BarConfig.innerCorners) && (hasAnyDockedBar || screenBorderActive) && (hasDockedBottom || hasDockedLeft || (bottomActive && leftActive && borderCornersEnabled))
  readonly property bool showBottomRightCorner: Boolean(BarConfig.innerCorners) && (hasAnyDockedBar || screenBorderActive) && (hasDockedBottom || hasDockedRight || (bottomActive && rightActive && borderCornersEnabled))
  readonly property bool anyCornerVisible: showTopLeftCorner || showTopRightCorner || showBottomLeftCorner || showBottomRightCorner

  readonly property color resolvedBorderColor: resolveBarColorForPos("top")

  function resolveBarColorForPos(pos) {
    void BarConfig.panelsRevision;
    const spec = BarConfig.screenBorderColor;
    const alpha = (BarConfig.screenFrameOpacity !== undefined && BarConfig.screenFrameOpacity !== null)
      ? Number(BarConfig.screenFrameOpacity)
      : 1.0;
    if (spec && String(spec).trim() !== "") {
      const c = barRoot.resolveThemeSpec(spec, barRoot.theme.bgBase);
      return Qt.rgba(c.r, c.g, c.b, alpha);
    }
    if (borderRoot.screenBorderActive) {
      const base = barRoot.theme.bgBase;
      return Qt.rgba(base.r, base.g, base.b, alpha);
    }
    const list = BarConfig.bars || [];
    let match = null;
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      const bTarget = b.displayTarget || (b.allMonitors ? "all" : "primary");
      const isPrim = (borderRoot.screenIndex === 0);
      if (bTarget === "primary" && !isPrim) continue;
      if (bTarget === "secondary" && isPrim) continue;
      const effectivePos = (!isPrim && bTarget === "all" && b.secondaryPosition) ? b.secondaryPosition : (b.position || "top");
      const effectiveFloating = (!isPrim && bTarget === "all" && b.secondaryFloating !== undefined) ? Boolean(b.secondaryFloating) : Boolean(b.floating);
      const effectiveDashed = (!isPrim && bTarget === "all" && b.secondaryDashed !== undefined) ? Boolean(b.secondaryDashed) : Boolean(b.dashed);
      if (effectivePos === pos && !effectiveFloating && !effectiveDashed) {
        match = b;
        break;
      }
    }
    const bObj = match;
    const isPrim = (borderRoot.screenIndex === 0);
    const bTarget = bObj ? (bObj.displayTarget || (bObj.allMonitors ? "all" : "primary")) : "primary";
    const colSpec = bObj
      ? ((!isPrim && bTarget === "all" && bObj.secondaryBarColor !== undefined)
          ? bObj.secondaryBarColor
          : (bObj.barColor ? bObj.barColor : ""))
      : "";
    const baseCol = barRoot.resolveThemeSpec(colSpec, barRoot.theme.bgBase);
    return Qt.rgba(baseCol.r, baseCol.g, baseCol.b, alpha);
  }

  // Throttled (not debounced) repaint: the shadow redraws right away and then at most every
  // ~33ms while the bar keeps changing, so it follows bumps live instead of snapping at the end.
  property bool _shadowPending: false

  function _paintShadowNow() {
    if (innerOverlayLoader.item && innerOverlayLoader.item.shadowCanvasRef) {
      innerOverlayLoader.item.shadowCanvasRef.requestPaint();
    }
  }

  function requestShadowPaint() {
    if (shadowThrottleTimer.running) {
      borderRoot._shadowPending = true;
    } else {
      borderRoot._paintShadowNow();
      shadowThrottleTimer.start();
    }
    // Final repaint once everything has settled.
    shadowSettleTimer.restart();
  }

  Timer {
    id: shadowThrottleTimer
    interval: 33
    repeat: false
    onTriggered: {
      if (borderRoot._shadowPending) {
        borderRoot._shadowPending = false;
        borderRoot._paintShadowNow();
        shadowThrottleTimer.start();
      }
    }
  }

  Timer {
    id: shadowSettleTimer
    interval: 350
    repeat: false
    onTriggered: borderRoot._paintShadowNow()
  }

  onShadowSizeChanged: requestShadowPaint()
  onShadowOpacityChanged: requestShadowPaint()
  onShadowBlurChanged: requestShadowPaint()
  onHasShadowChanged: requestShadowPaint()
  onShowTopLeftCornerChanged: requestShadowPaint()
  onShowTopRightCornerChanged: requestShadowPaint()
  onShowBottomLeftCornerChanged: requestShadowPaint()
  onShowBottomRightCornerChanged: requestShadowPaint()
  onEffectiveDockedTopChanged: requestShadowPaint()
  onEffectiveDockedBottomChanged: requestShadowPaint()
  onEffectiveDockedLeftChanged: requestShadowPaint()
  onEffectiveDockedRightChanged: requestShadowPaint()

  readonly property var activePopupData: (barRoot && barRoot.activePopupData) ? barRoot.activePopupData : null
  onActivePopupDataChanged: requestShadowPaint()

  Connections {
    target: borderRoot.barRoot
    function onBumpyContourUpdated() {
      borderRoot.requestShadowPaint();
    }
  }

  // Top Border Strip (active when no docked top bar is present)
  Loader {
    active: borderRoot.barRoot.barVisible && borderRoot.screenBorderActive && !borderRoot.hasDockedTop
    sourceComponent: Component {
  PanelWindow {
    id: topBorderWindow
    screen: borderRoot.screen
    visible: true
    color: "transparent"
    mask: Region {}

    anchors {
      top: true
      left: true
      right: true
    }
    exclusionMode: borderRoot.hasAnyFloatingBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: borderRoot.hasAnyFloatingBar ? -1 : borderRoot.borderThickness
    implicitHeight: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolveBarColorForPos("top")
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }
    }
  }

  // Bottom Border Strip (active when no docked bottom bar is present)
  Loader {
    active: borderRoot.barRoot.barVisible && borderRoot.screenBorderActive && !borderRoot.hasDockedBottom
    sourceComponent: Component {
  PanelWindow {
    id: bottomBorderWindow
    screen: borderRoot.screen
    visible: true
    color: "transparent"
    mask: Region {}

    anchors {
      bottom: true
      left: true
      right: true
    }
    exclusionMode: borderRoot.hasAnyFloatingBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: borderRoot.hasAnyFloatingBar ? -1 : borderRoot.borderThickness
    implicitHeight: borderRoot.borderThickness

    Rectangle {
      anchors.fill: parent
      color: borderRoot.resolveBarColorForPos("bottom")
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }
    }
  }

  // Left Border Strip (active when no docked left bar is present)
  Loader {
    active: borderRoot.barRoot.barVisible && borderRoot.screenBorderActive && !borderRoot.hasDockedLeft
    sourceComponent: Component {
  PanelWindow {
    id: leftBorderWindow
    screen: borderRoot.screen
    visible: true
    color: "transparent"
    mask: Region {}

    anchors {
      left: true
      top: true
      bottom: true
    }
    exclusionMode: borderRoot.hasAnyFloatingBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: borderRoot.hasAnyFloatingBar ? -1 : borderRoot.borderThickness
    implicitWidth: borderRoot.borderThickness

    Loader {
      active: !borderRoot.barRoot.reserveExclusionResetting && borderRoot.hasAnyFloatingBar
      sourceComponent: Component {
        PanelWindow {
          screen: borderRoot.screen
          visible: true
          color: "transparent"
          mask: Region {}
          exclusionMode: ExclusionMode.Normal
          anchors {
            left: true
            top: true
            bottom: true
          }
          implicitWidth: borderRoot.borderThickness
          exclusiveZone: borderRoot.borderThickness
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: borderRoot.effectiveDockedTop
      anchors.bottomMargin: borderRoot.effectiveDockedBottom
      color: borderRoot.resolveBarColorForPos("left")
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }
    }
  }

  // Right Border Strip (active when no docked right bar is present)
  Loader {
    active: borderRoot.barRoot.barVisible && borderRoot.screenBorderActive && !borderRoot.hasDockedRight
    sourceComponent: Component {
  PanelWindow {
    id: rightBorderWindow
    screen: borderRoot.screen
    visible: true
    color: "transparent"
    mask: Region {}

    anchors {
      right: true
      top: true
      bottom: true
    }
    exclusionMode: borderRoot.hasAnyFloatingBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: borderRoot.hasAnyFloatingBar ? -1 : borderRoot.borderThickness
    implicitWidth: borderRoot.borderThickness

    Loader {
      active: !borderRoot.barRoot.reserveExclusionResetting && borderRoot.hasAnyFloatingBar
      sourceComponent: Component {
        PanelWindow {
          screen: borderRoot.screen
          visible: true
          color: "transparent"
          mask: Region {}
          exclusionMode: ExclusionMode.Normal
          anchors {
            right: true
            top: true
            bottom: true
          }
          implicitWidth: borderRoot.borderThickness
          exclusiveZone: borderRoot.borderThickness
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: borderRoot.effectiveDockedTop
      anchors.bottomMargin: borderRoot.effectiveDockedBottom
      color: borderRoot.resolveBarColorForPos("right")
      Behavior on color { ColorAnimation { duration: 180 } }
    }
  }
    }
  }

  // Full-Screen Inner Corners & Curved Inner Shadow Overlay
  // Uses ExclusionMode.Ignore (without exclusiveZone) so Hyprland never shifts or shrinks this window;
  // it always maps 1:1 to physical screen coordinates (0, 0, screen.width, screen.height).
  Loader {
    id: innerOverlayLoader
    active: borderRoot.barRoot.barVisible && (borderRoot.anyCornerVisible || (borderRoot.hasShadow && borderRoot.anyEdgeActive))
    sourceComponent: Component {
  PanelWindow {
    id: innerOverlayWindow
    readonly property var shadowCanvasRef: shadowCanvasLoader.item
    screen: borderRoot.screen
    visible: true
    color: "transparent"
    mask: Region {}
    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    Loader {
      id: shadowCanvasLoader
      anchors.fill: parent
      z: 1
      active: borderRoot.hasShadow && borderRoot.anyEdgeActive
      sourceComponent: Component {
        Canvas {
          id: shadowCanvas
          // The shadow is soft, so it is rendered at reduced resolution and scaled back up.
          // A full-screen canvas with ~30 wide strokes was slow enough that the shadow lagged
          // behind the bar and left a visible trail; this makes each repaint several times faster.
          readonly property real k: 0.4
          width: parent.width * k
          height: parent.height * k
          scale: 1.0 / k
          transformOrigin: Item.TopLeft
          smooth: true
          visible: borderRoot.hasShadow && borderRoot.anyEdgeActive
          antialiasing: true

          Component.onCompleted: requestPaint()
          onAvailableChanged: if (available) requestPaint()
          onVisibleChanged: if (visible) requestPaint()
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          function traceDesktopContour(ctx, dL, dT, dR, dB, outTL, outTR, outBR, outBL, bcTop, bcRight, bcBottom, bcLeft, fullW, fullH) {
            // When a bumpy bar's first/last bump does not reach a screen corner, the contour
            // must already sit at the rail level on that corner. Otherwise the path cuts a
            // diagonal from the bump level to the rail level and the shadow stops following the bar.
            const hasIv = (c) => c && c.intervals && c.intervals.length > 0;
            const topNSL = hasIv(bcTop) && bcTop.intervals[0].s > dL + 2 * (bcTop.R || 0);
            const rightNST = hasIv(bcRight) && bcRight.intervals[0].s > dT + 2 * (bcRight.R || 0);
            const bottomNSR = hasIv(bcBottom) && bcBottom.intervals[bcBottom.intervals.length - 1].e < dR - 2 * (bcBottom.R || 0);
            const leftNSB = hasIv(bcLeft) && bcLeft.intervals[bcLeft.intervals.length - 1].e < dB - 2 * (bcLeft.R || 0);

            if (topNSL) ctx.moveTo(dL, bcTop.rail + (bcTop.oy || 0));
            else ctx.moveTo(dL + outTL, dT);

            // 1. Top edge (left -> right)
            if (bcTop && bcTop.intervals && bcTop.intervals.length > 0) {
              const r = bcTop.R || 0;
              const yRail = bcTop.rail + (bcTop.oy || 0);
              const yBump = bcTop.thick + (bcTop.oy || 0);
              const ivs = bcTop.intervals;
              for (let i = 0; i < ivs.length; i++) {
                const s = Math.max(dL, ivs[i].s + (bcTop.ox || 0));
                const e = Math.min(dR, ivs[i].e + (bcTop.ox || 0));
                if (e <= s) continue;
                if (s > dL + 2 * r) {
                  ctx.lineTo(s - r, yRail);
                  if (r > 0) {
                    ctx.arcTo(s, yRail, s, yBump, r);
                    ctx.arcTo(s, yBump, s + r, yBump, r);
                  } else {
                    ctx.lineTo(s, yRail);
                    ctx.lineTo(s, yBump);
                  }
                }
                if (e < dR - 2 * r) {
                  ctx.lineTo(e - r, yBump);
                  if (r > 0) {
                    ctx.arcTo(e, yBump, e, yRail, r);
                    ctx.arcTo(e, yRail, e + r, yRail, r);
                  } else {
                    ctx.lineTo(e, yBump);
                    ctx.lineTo(e, yRail);
                  }
                } else {
                  ctx.lineTo(dR - outTR, yBump);
                }
              }
              const topEndY = (ivs[ivs.length - 1].e >= dR - 2 * r) ? yBump : yRail;
              if (outTR > 0 && topEndY === yBump) ctx.arcTo(dR, dT, dR, dT + outTR, outTR);
              else ctx.lineTo(dR, topEndY);
            } else if (rightNST) {
              ctx.lineTo(fullW - bcRight.rail + (bcRight.ox || 0), dT);
            } else {
              ctx.lineTo(dR - outTR, dT);
              if (outTR > 0) ctx.arcTo(dR, dT, dR, dT + outTR, outTR);
              else ctx.lineTo(dR, dT);
            }

            // 2. Right edge (top -> bottom)
            if (bcRight && bcRight.intervals && bcRight.intervals.length > 0) {
              const r = bcRight.R || 0;
              const xRail = fullW - bcRight.rail + (bcRight.ox || 0);
              const xBump = fullW - bcRight.thick + (bcRight.ox || 0);
              const ivs = bcRight.intervals;
              for (let i = 0; i < ivs.length; i++) {
                const s = Math.max(dT, ivs[i].s + (bcRight.oy || 0));
                const e = Math.min(dB, ivs[i].e + (bcRight.oy || 0));
                if (e <= s) continue;
                if (s > dT + 2 * r) {
                  ctx.lineTo(xRail, s - r);
                  if (r > 0) {
                    ctx.arcTo(xRail, s, xBump, s, r);
                    ctx.arcTo(xBump, s, xBump, s + r, r);
                  } else {
                    ctx.lineTo(xRail, s);
                    ctx.lineTo(xBump, s);
                  }
                }
                if (e < dB - 2 * r) {
                  ctx.lineTo(xBump, e - r);
                  if (r > 0) {
                    ctx.arcTo(xBump, e, xRail, e, r);
                    ctx.arcTo(xRail, e, xRail, e + r, r);
                  } else {
                    ctx.lineTo(xBump, e);
                    ctx.lineTo(xRail, e);
                  }
                } else {
                  ctx.lineTo(xBump, dB - outBR);
                }
              }
              const rightEndX = (ivs[ivs.length - 1].e >= dB - 2 * r) ? xBump : xRail;
              if (outBR > 0 && rightEndX === xBump) ctx.arcTo(dR, dB, dR - outBR, dB, outBR);
              else ctx.lineTo(rightEndX, dB);
            } else if (bottomNSR) {
              ctx.lineTo(dR, fullH - bcBottom.rail + (bcBottom.oy || 0));
            } else {
              ctx.lineTo(dR, dB - outBR);
              if (outBR > 0) ctx.arcTo(dR, dB, dR - outBR, dB, outBR);
              else ctx.lineTo(dR, dB);
            }

            // 3. Bottom edge (right -> left)
            if (bcBottom && bcBottom.intervals && bcBottom.intervals.length > 0) {
              const r = bcBottom.R || 0;
              const yRail = fullH - bcBottom.rail + (bcBottom.oy || 0);
              const yBump = fullH - bcBottom.thick + (bcBottom.oy || 0);
              const ivs = bcBottom.intervals;
              for (let i = ivs.length - 1; i >= 0; i--) {
                const s = Math.max(dL, ivs[i].s + (bcBottom.ox || 0));
                const e = Math.min(dR, ivs[i].e + (bcBottom.ox || 0));
                if (e <= s) continue;
                if (e < dR - 2 * r) {
                  ctx.lineTo(e + r, yRail);
                  if (r > 0) {
                    ctx.arcTo(e, yRail, e, yBump, r);
                    ctx.arcTo(e, yBump, e - r, yBump, r);
                  } else {
                    ctx.lineTo(e, yRail);
                    ctx.lineTo(e, yBump);
                  }
                }
                if (s > dL + 2 * r) {
                  ctx.lineTo(s + r, yBump);
                  if (r > 0) {
                    ctx.arcTo(s, yBump, s, yRail, r);
                    ctx.arcTo(s, yRail, s - r, yRail, r);
                  } else {
                    ctx.lineTo(s, yBump);
                    ctx.lineTo(s, yRail);
                  }
                } else {
                  ctx.lineTo(dL + outBL, yBump);
                }
              }
              const botEndY = (ivs[0].s <= dL + 2 * r) ? yBump : yRail;
              if (outBL > 0 && botEndY === yBump) ctx.arcTo(dL, dB, dL, dB - outBL, outBL);
              else ctx.lineTo(dL, botEndY);
            } else if (leftNSB) {
              ctx.lineTo(bcLeft.rail + (bcLeft.ox || 0), dB);
            } else {
              ctx.lineTo(dL + outBL, dB);
              if (outBL > 0) ctx.arcTo(dL, dB, dL, dB - outBL, outBL);
              else ctx.lineTo(dL, dB);
            }

            // 4. Left edge (bottom -> top)
            if (bcLeft && bcLeft.intervals && bcLeft.intervals.length > 0) {
              const r = bcLeft.R || 0;
              const xRail = bcLeft.rail + (bcLeft.ox || 0);
              const xBump = bcLeft.thick + (bcLeft.ox || 0);
              const ivs = bcLeft.intervals;
              for (let i = ivs.length - 1; i >= 0; i--) {
                const s = Math.max(dT, ivs[i].s + (bcLeft.oy || 0));
                const e = Math.min(dB, ivs[i].e + (bcLeft.oy || 0));
                if (e <= s) continue;
                if (e < dB - 2 * r) {
                  ctx.lineTo(xRail, e + r);
                  if (r > 0) {
                    ctx.arcTo(xRail, e, xBump, e, r);
                    ctx.arcTo(xBump, e, xBump, e - r, r);
                  } else {
                    ctx.lineTo(xRail, e);
                    ctx.lineTo(xBump, e);
                  }
                }
                if (s > dT + 2 * r) {
                  ctx.lineTo(xBump, s + r);
                  if (r > 0) {
                    ctx.arcTo(xBump, s, xRail, s, r);
                    ctx.arcTo(xRail, s, xRail, s - r, r);
                  } else {
                    ctx.lineTo(xBump, s);
                    ctx.lineTo(xRail, s);
                  }
                } else {
                  ctx.lineTo(xBump, dT + outTL);
                }
              }
              const leftEndX = (ivs[0].s <= dT + 2 * r) ? xBump : xRail;
              if (outTL > 0 && leftEndX === xBump) ctx.arcTo(dL, dT, dL + outTL, dT, outTL);
              else ctx.lineTo(leftEndX, dT);
            } else if (topNSL) {
              ctx.lineTo(dL, bcTop.rail + (bcTop.oy || 0));
            } else {
              ctx.lineTo(dL, dT + outTL);
              if (outTL > 0) ctx.arcTo(dL, dT, dL + outTL, dT, outTL);
              else ctx.lineTo(dL, dT);
            }

            ctx.closePath();
          }

          onPaint: {
            const ctx = getContext("2d");
            const fullW = width / k;
            const fullH = height / k;
            if (fullW <= 0 || fullH <= 0) return;
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(0, 0, width, height);
            ctx.scale(k, k);

            if (!borderRoot.hasShadow || !borderRoot.anyEdgeActive) return;

            const s = borderRoot.shadowSize;
            const pad = s * 2 + 4;
            const dL = borderRoot.leftActive ? borderRoot.effectiveDockedLeft : -pad;
            const dR = borderRoot.rightActive ? (fullW - borderRoot.effectiveDockedRight) : (fullW + pad);
            const dT = borderRoot.topActive ? borderRoot.effectiveDockedTop : -pad;
            const dB = borderRoot.bottomActive ? (fullH - borderRoot.effectiveDockedBottom) : (fullH + pad);

            const baseR = borderRoot.cornerRadius;
            const rTL = borderRoot.showTopLeftCorner ? baseR : 0;
            const rTR = borderRoot.showTopRightCorner ? baseR : 0;
            const rBR = borderRoot.showBottomRightCorner ? baseR : 0;
            const rBL = borderRoot.showBottomLeftCorner ? baseR : 0;

            const outTL = rTL > 0 ? Math.max(0, rTL - 0.75) : 0;
            const outTR = rTR > 0 ? Math.max(0, rTR - 0.75) : 0;
            const outBR = rBR > 0 ? Math.max(0, rBR - 0.75) : 0;
            const outBL = rBL > 0 ? Math.max(0, rBL - 0.75) : 0;

            const contours = (borderRoot.barRoot && borderRoot.barRoot.bumpyContours) ? borderRoot.barRoot.bumpyContours : ({});
            const bcTop = contours[borderRoot.screenIndex + "_top"] || null;
            const bcRight = contours[borderRoot.screenIndex + "_right"] || null;
            const bcBottom = contours[borderRoot.screenIndex + "_bottom"] || null;
            const bcLeft = contours[borderRoot.screenIndex + "_left"] || null;

            ctx.save();
            ctx.beginPath();
            traceDesktopContour(ctx, dL, dT, dR, dB, outTL, outTR, outBR, outBL, bcTop, bcRight, bcBottom, bcLeft, fullW, fullH);

            // Omit shadow along fluid popup contour if active
            const ap = borderRoot.activePopupData;
            if (ap && ap.active && ap.fluidEnabled) {
              const sameScreen = !ap.screen || !borderRoot.screen || ap.screen === borderRoot.screen;
              if (sameScreen) {
                const r = ap.cornerRad || 16;
                const depth = Math.max(s, r);
                if (ap.barPos === "top" && borderRoot.topActive && ap.width > 0) {
                  ctx.rect(ap.x, dT, ap.width, depth);
                } else if (ap.barPos === "bottom" && borderRoot.bottomActive && ap.width > 0) {
                  ctx.rect(ap.x, dB - depth, ap.width, depth);
                } else if (ap.barPos === "left" && borderRoot.leftActive && ap.height > 0) {
                  ctx.rect(dL, ap.y, depth, ap.height);
                } else if (ap.barPos === "right" && borderRoot.rightActive && ap.height > 0) {
                  ctx.rect(dR - depth, ap.y, depth, ap.height);
                }
              }
            }
            ctx.clip("evenodd");

            // While a bar slides/fades in (position change), the shadow follows the same fade.
            let fade = 1.0;
            for (const bc of [bcTop, bcRight, bcBottom, bcLeft]) {
              if (bc && bc.op !== undefined) fade = Math.min(fade, Math.max(0, Math.min(1, bc.op)));
            }
            ctx.globalAlpha = fade;

            // Soft falloff: cumulative opacity grows smoothly (power curve) towards the edge,
            // instead of saturating immediately, so the shadow fades out gently.
            const steps = Math.min(32, Math.max(14, Math.round(s)));
            const peak = Math.min(0.9, borderRoot.shadowOpacity * 1.25);
            // blur 0 = tight/firm edge, 1 = very soft, long fade
            const power = 0.6 + borderRoot.shadowBlur * 3.4;
            let prevC = 0;
            for (let i = 1; i <= steps; i++) {
              const C = peak * Math.pow(i / steps, power);
              const ringAlpha = 1.0 - (1.0 - C) / (1.0 - prevC);
              prevC = C;
              if (ringAlpha <= 0.0005) continue;
              ctx.lineWidth = s * (1.0 - (i - 1) / steps) * 2.0;
              ctx.strokeStyle = Qt.rgba(0, 0, 0, ringAlpha);
              ctx.beginPath();
              traceDesktopContour(ctx, dL, dT, dR, dB, outTL, outTR, outBR, outBL, bcTop, bcRight, bcBottom, bcLeft, fullW, fullH);
              ctx.stroke();
            }
            ctx.restore();
          }
        }
      }
    }

    Item {
      id: innerViewport
      z: 2
      anchors.fill: parent
      anchors.topMargin: borderRoot.effectiveDockedTop
      anchors.bottomMargin: borderRoot.effectiveDockedBottom
      anchors.leftMargin: borderRoot.effectiveDockedLeft
      anchors.rightMargin: borderRoot.effectiveDockedRight

      InnerCorner {
        id: cornerTopLeft
        visible: borderRoot.showTopLeftCorner
        cornerPosition: "top-left"
        cornerColor: borderRoot.resolveBarColorForPos("top")
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.top: parent.top
        anchors.left: parent.left
      }

      InnerCorner {
        id: cornerTopRight
        visible: borderRoot.showTopRightCorner
        cornerPosition: "top-right"
        cornerColor: borderRoot.resolveBarColorForPos("top")
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.top: parent.top
        anchors.right: parent.right
      }

      InnerCorner {
        id: cornerBottomLeft
        visible: borderRoot.showBottomLeftCorner
        cornerPosition: "bottom-left"
        cornerColor: borderRoot.resolveBarColorForPos("bottom")
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.bottom: parent.bottom
        anchors.left: parent.left
      }

      InnerCorner {
        id: cornerBottomRight
        visible: borderRoot.showBottomRightCorner
        cornerPosition: "bottom-right"
        cornerColor: borderRoot.resolveBarColorForPos("bottom")
        width: borderRoot.cornerRadius
        height: borderRoot.cornerRadius
        anchors.bottom: parent.bottom
        anchors.right: parent.right
      }
    }
  }
    }
  }
}
