import Quickshell
import Quickshell.Io
import QtQuick
import "../ThemeSwitcher" as TS
import "Components"

Scope {
  id: root

  TS.DefaultTheme { id: defaultTheme }
  property var theme: defaultTheme
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property bool panelVisible: false
  property bool annotateSwappy: false
  property int delaySeconds: 0
  property int countdownRemaining: 0
  property string pendingMode: ""

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

  function executeCapture(mode) {
    const swappyFlag = root.annotateSwappy ? "1" : "0";
    const delayArg = (mode === "region" && root.delaySeconds > 0) ? String(root.delaySeconds) : "0";
    const script = [
      "sleep 0.2",
      "dir=\"$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots\"",
      "mkdir -p \"$dir\"",
      "time=$(date \"+%d-%b_%H-%M-%S\")",
      "file=\"$dir/Screenshot_${time}_${RANDOM}.png\"",
      "iDIR=\"$HOME/.config/swaync/icons\"",
      "sDIR=\"$HOME/.config/hypr/Scripts\"",
      "[ ! -d \"$sDIR\" ] && sDIR=\"$HOME/.config/hypr/scripts\"",
      "mode=\"" + mode + "\"",
      "if [ \"$mode\" = \"region\" ]; then",
      "  geom=$(slurp 2>&1) || exit 0",
      "  if [ \"" + delayArg + "\" -gt 0 ]; then sleep " + delayArg + "; fi",
      "  err=$(grim -g \"$geom\" \"$file\" 2>&1) || { notify-send -u critical -a \"Screenshot\" \"Screenshot Failed\" \"$err\"; exit 1; }",
      "elif [ \"$mode\" = \"window\" ]; then",
      "  geom=$(hyprctl activewindow -j 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); a=d.get('at',[0,0]); s=d.get('size',[0,0]); print(f'{a[0]},{a[1]} {s[0]}x{s[1]}') if s[0]>0 and s[1]>0 else sys.exit(1)\" 2>/dev/null) || geom=\"\"",
      "  if [ -n \"$geom\" ]; then",
      "    err=$(grim -g \"$geom\" \"$file\" 2>&1) || { notify-send -u critical -a \"Screenshot\" \"Screenshot Failed\" \"$err\"; exit 1; }",
      "  else",
      "    err=$(grim \"$file\" 2>&1) || { notify-send -u critical -a \"Screenshot\" \"Screenshot Failed\" \"$err\"; exit 1; }",
      "  fi",
      "else",
      "  err=$(grim \"$file\" 2>&1) || { notify-send -u critical -a \"Screenshot\" \"Screenshot Failed\" \"$err\"; exit 1; }",
      "fi",
      "wl-copy --type image/png < \"$file\" >/dev/null 2>&1 &",
      "[ -x \"$sDIR/Sounds.sh\" ] && \"$sDIR/Sounds.sh\" --screenshot >/dev/null 2>&1 &",
      "notify_base=\"notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify -i $iDIR/picture.png\"",
      "if [ \"" + swappyFlag + "\" = \"1\" ]; then",
      "  resp=$($notify_base \" Screenshot:\" \" Captured by Swappy\")",
      "  case \"$resp\" in",
      "    action1) swappy -f \"$file\" >/dev/null 2>&1 & ;;",
      "    action2) rm -f \"$file\" ;;",
      "  esac",
      "else",
      "  resp=$(timeout 10 $notify_base \" Screenshot\" \" Saved\")",
      "  case \"$resp\" in",
      "    action1) xdg-open \"$file\" >/dev/null 2>&1 & ;;",
      "    action2) rm -f \"$file\" ;;",
      "  esac",
      "fi"
    ].join("\n");
    Quickshell.execDetached(["bash", "-c", script]);
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
