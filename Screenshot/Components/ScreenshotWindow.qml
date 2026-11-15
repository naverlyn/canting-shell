import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: hudWin

  required property var theme
  required property string font
  required property int delaySeconds
  required property int countdownRemaining
  required property bool annotateSwappy

  signal closeRequested()
  signal captureRequested(string mode)
  signal cycleDelayRequested()
  signal toggleAnnotateRequested()

  visible: true
  focusable: true
  color: "transparent"

  implicitWidth: hudCard.width
  implicitHeight: hudCard.height

  property bool closing: false

  function requestClose() {
    if (hudWin.closing) return;
    hudWin.closing = true;
    openAnim.stop();
    closeAnim.start();
  }

  Component.onCompleted: {
    openAnim.start();
    Qt.callLater(() => hudCard.forceActiveFocus());
  }
  onVisibleChanged: {
    if (!visible) hudWin.closeRequested();
  }

  ParallelAnimation {
    id: openAnim
    NumberAnimation { target: hudCard; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    NumberAnimation { target: slideTx; property: "y"; from: 12; to: 0; duration: 160; easing.type: Easing.OutCubic }
  }

  ParallelAnimation {
    id: closeAnim
    NumberAnimation { target: hudCard; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
    NumberAnimation { target: slideTx; property: "y"; to: 10; duration: 110; easing.type: Easing.InCubic }
    onFinished: hudWin.visible = false
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace: "quickshell-screenshot"
  exclusionMode: ExclusionMode.Ignore

  anchors.bottom: true
  margins.bottom: 48

  Rectangle {
    id: hudCard
    anchors.centerIn: parent
    width: mainCol.implicitWidth + 28
    height: mainCol.implicitHeight + 24
    radius: 16
    color: hudWin.theme.bgBase
    border.color: hudWin.theme.bgBorder
    border.width: 1
    opacity: 0.0
    transform: Translate { id: slideTx; y: 12 }

    focus: true
    Keys.onEscapePressed: hudWin.requestClose()
    Keys.onPressed: event => {
      if (event.key === Qt.Key_1) {
        event.accepted = true;
        hudWin.captureRequested("region");
      } else if (event.key === Qt.Key_2) {
        event.accepted = true;
        hudWin.captureRequested("window");
      } else if (event.key === Qt.Key_3) {
        event.accepted = true;
        hudWin.captureRequested("screen");
      } else if (event.key === Qt.Key_A) {
        event.accepted = true;
        hudWin.toggleAnnotateRequested();
      } else if (event.key === Qt.Key_D) {
        event.accepted = true;
        hudWin.cycleDelayRequested();
      }
    }

    ColumnLayout {
      id: mainCol
      anchors.centerIn: parent
      spacing: 10

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ScreenshotPillButton {
          theme: hudWin.theme
          font: hudWin.font
          text: hudWin.delaySeconds > 0 ? ("󰔛 " + hudWin.delaySeconds + "s") : "󰔛 0s"
          active: hudWin.delaySeconds > 0
          onTriggered: hudWin.cycleDelayRequested()
        }

        ScreenshotPillButton {
          theme: hudWin.theme
          font: hudWin.font
          text: "󰏫 Annotate"
          active: hudWin.annotateSwappy
          onTriggered: hudWin.toggleAnnotateRequested()
        }

        Item { Layout.fillWidth: true }

        Text {
          visible: hudWin.countdownRemaining > 0
          text: "Capturing in " + hudWin.countdownRemaining + "s..."
          font.family: hudWin.font
          font.pixelSize: 12
          font.bold: true
          color: hudWin.theme.accentPrimary
        }

        ScreenshotPillButton {
          theme: hudWin.theme
          font: hudWin.font
          text: "󰅖"
          fixedWidth: 24
          onTriggered: hudWin.requestClose()
        }
      }

      RowLayout {
        spacing: 10

        ScreenshotActionButton {
          theme: hudWin.theme
          font: hudWin.font
          iconText: "󰆞"
          label: "Region"
          shortcutHint: "1"
          onTriggered: hudWin.captureRequested("region")
        }

        ScreenshotActionButton {
          theme: hudWin.theme
          font: hudWin.font
          iconText: "󰖯"
          label: "Window"
          shortcutHint: "2"
          onTriggered: hudWin.captureRequested("window")
        }

        ScreenshotActionButton {
          theme: hudWin.theme
          font: hudWin.font
          iconText: "󰹑"
          label: "Screen"
          shortcutHint: "3"
          onTriggered: hudWin.captureRequested("screen")
        }
      }
    }
  }
}
