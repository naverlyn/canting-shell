import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
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
      "set -e",
      "sleep 0.18",
      "dir=\"$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots\"",
      "mkdir -p \"$dir\"",
      "file=\"$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png\"",
      "mode=\"" + mode + "\"",
      "if [ \"$mode\" = \"region\" ]; then",
      "  geom=$(slurp) || exit 0",
      "  [ \"" + delayArg + "\" -gt 0 ] && sleep " + delayArg,
      "  grim -g \"$geom\" \"$file\"",
      "elif [ \"$mode\" = \"window\" ]; then",
      "  geom=$(hyprctl activewindow -j | python3 -c \"import json,sys; d=json.load(sys.stdin); a=d.get('at',[0,0]); s=d.get('size',[0,0]); print(f'{a[0]},{a[1]} {s[0]}x{s[1]}')\" 2>/dev/null) || exit 1",
      "  grim -g \"$geom\" \"$file\"",
      "else",
      "  grim \"$file\"",
      "fi",
      "wl-copy < \"$file\"",
      "if [ \"" + swappyFlag + "\" = \"1\" ]; then",
      "  swappy -f \"$file\" &",
      "else",
      "  notify-send -a \"Screenshot\" \"Screenshot Saved\" \"$file\"",
      "fi"
    ].join("\n");
    captureProc.command = ["sh", "-c", script];
    captureProc.running = true;
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

  Process {
    id: captureProc
    running: false
  }

  Loader {
    active: root.panelVisible
    sourceComponent: Component {
      PanelWindow {
        id: hudWin
        visible: true
        focusable: true
        color: "transparent"

        Component.onCompleted: hudCard.forceActiveFocus()
        onVisibleChanged: {
          if (!visible) {
            root.cancelCountdown();
            root.panelVisible = false;
          }
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-screenshot"
        exclusionMode: ExclusionMode.Ignore

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        MouseArea {
          anchors.fill: parent
          onClicked: hudWin.visible = false
        }

        Rectangle {
          id: hudCard
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 48
          width: mainCol.implicitWidth + 28
          height: mainCol.implicitHeight + 24
          radius: 16
          color: root.theme.bgBase
          border.color: root.theme.bgBorder
          border.width: 1

          focus: true
          Keys.onEscapePressed: hudWin.visible = false
          Keys.onPressed: event => {
            if (event.key === Qt.Key_1) {
              event.accepted = true;
              root.startCapture("region");
            } else if (event.key === Qt.Key_2) {
              event.accepted = true;
              root.startCapture("window");
            } else if (event.key === Qt.Key_3) {
              event.accepted = true;
              root.startCapture("screen");
            } else if (event.key === Qt.Key_A) {
              event.accepted = true;
              root.annotateSwappy = !root.annotateSwappy;
            } else if (event.key === Qt.Key_D) {
              event.accepted = true;
              root.cycleDelay();
            }
          }

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            id: mainCol
            anchors.centerIn: parent
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "󰄄"
                font.family: root.font
                font.pixelSize: 15
                color: root.theme.accentPrimary
              }

              Text {
                text: root.countdownRemaining > 0
                  ? ("Capturing in " + root.countdownRemaining + "s...")
                  : "Screenshot"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
              }

              Item { Layout.fillWidth: true }

              // Delay toggle pill
              Rectangle {
                implicitWidth: delayLbl.implicitWidth + 14
                height: 24
                radius: 12
                color: root.delaySeconds > 0
                  ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.24)
                  : root.theme.bgSurface
                border.color: root.delaySeconds > 0 ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.cycleDelay()
                }

                Text {
                  id: delayLbl
                  anchors.centerIn: parent
                  text: root.delaySeconds > 0 ? ("󰔛 " + root.delaySeconds + "s") : "󰔛 0s"
                  font.family: root.font
                  font.pixelSize: 11
                  font.bold: root.delaySeconds > 0
                  color: root.delaySeconds > 0 ? root.theme.accentPrimary : root.theme.textSecondary
                }
              }

              // Annotate (Swappy) toggle pill
              Rectangle {
                implicitWidth: annotLbl.implicitWidth + 14
                height: 24
                radius: 12
                color: root.annotateSwappy
                  ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.24)
                  : root.theme.bgSurface
                border.color: root.annotateSwappy ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.annotateSwappy = !root.annotateSwappy
                }

                Text {
                  id: annotLbl
                  anchors.centerIn: parent
                  text: "󰏫 Annotate"
                  font.family: root.font
                  font.pixelSize: 11
                  font.bold: root.annotateSwappy
                  color: root.annotateSwappy ? root.theme.accentPrimary : root.theme.textSecondary
                }
              }
            }

            RowLayout {
              spacing: 10

              ScreenshotActionButton {
                theme: root.theme
                font: root.font
                iconText: "󰆞"
                label: "Region"
                shortcutHint: "1"
                onTriggered: root.startCapture("region")
              }

              ScreenshotActionButton {
                theme: root.theme
                font: root.font
                iconText: "󰖯"
                label: "Window"
                shortcutHint: "2"
                onTriggered: root.startCapture("window")
              }

              ScreenshotActionButton {
                theme: root.theme
                font: root.font
                iconText: "󰹑"
                label: "Screen"
                shortcutHint: "3"
                onTriggered: root.startCapture("screen")
              }
            }
          }
        }
      }
    }
  }
}
