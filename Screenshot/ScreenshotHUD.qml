import Quickshell
import Quickshell.Io
import QtQuick
import "../ThemeSwitcher"
import "Components"

Scope {
  id: root

  property var theme: Theme
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property bool panelVisible: false
  property bool annotateSwappy: false
  property int delaySeconds: 0
  property int countdownRemaining: 0
  property string pendingMode: ""
  readonly property string captureScript: Qt.resolvedUrl("scripts/capture.sh").toString().replace(/^file:\/\//, "")

  IpcHandler {
    target: "screenshot"

    function toggle() {
      if (root.panelVisible) {
        root.cancelCountdown();
        root.panelVisible = false;
      } else {
        root.panelVisible = true;
      }
    }

    function full() {
      root.cancelCountdown();
      root.panelVisible = false;
      root.executeCapture("full");
    }

    function area() {
      root.cancelCountdown();
      root.panelVisible = false;
      root.executeCapture("region");
    }

    function swappy() {
      root.cancelCountdown();
      root.panelVisible = false;
      root.executeCapture("region", true);
    }

    function window() {
      root.cancelCountdown();
      root.panelVisible = false;
      root.executeCapture("window");
    }
  }

  function cycleDelay() {
    if (root.delaySeconds === 0) root.delaySeconds = 3;
    else if (root.delaySeconds === 3) root.delaySeconds = 5;
    else root.delaySeconds = 0;
  }

  function cancelCountdown() {
    countdownTimer.stop();
    root.countdownRemaining = 0;
    root.pendingMode = "";
  }

  function startCapture(mode) {
    root.pendingMode = mode;
    if (root.delaySeconds > 0 && mode !== "region") {
      root.countdownRemaining = root.delaySeconds;
      countdownTimer.restart();
    } else {
      root.panelVisible = false;
      executeCapture(mode);
    }
  }

  function executeCapture(mode, forceSwappy) {
    const swappyFlag = (forceSwappy === true || root.annotateSwappy) ? "1" : "0";
    const delayArg = (mode === "region" && root.delaySeconds > 0) ? String(root.delaySeconds) : "0";
    Quickshell.execDetached(["bash", root.captureScript, mode, swappyFlag, delayArg]);
  }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    onTriggered: {
      if (root.countdownRemaining > 1) {
        root.countdownRemaining -= 1;
      } else {
        const m = root.pendingMode;
        root.cancelCountdown();
        root.panelVisible = false;
        if (m !== "") root.executeCapture(m);
      }
    }
  }

  Loader {
    active: root.panelVisible
    sourceComponent: Component {
      ScreenshotWindow {
        theme: root.theme
        font: root.font
        delaySeconds: root.delaySeconds
        countdownRemaining: root.countdownRemaining
        annotateSwappy: root.annotateSwappy

        onCloseRequested: {
          root.cancelCountdown();
          root.panelVisible = false;
        }
        onCaptureRequested: mode => root.startCapture(mode)
        onCycleDelayRequested: root.cycleDelay()
        onToggleAnnotateRequested: root.annotateSwappy = !root.annotateSwappy
      }
    }
  }
}
