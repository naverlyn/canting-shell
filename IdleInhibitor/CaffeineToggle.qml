import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../bar"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  readonly property bool active: SystemInfo.idleInhibited

  IpcHandler {
    target: "idle"

    function toggle(): void {
      SystemInfo.toggleIdleInhibitor();
    }

    function enable(): void {
      SystemInfo.setIdleInhibitor(true);
    }

    function disable(): void {
      SystemInfo.setIdleInhibitor(false);
    }
  }

  PanelWindow {
    id: host
    // Always mapped - the Wayland idle inhibitor only holds while this
    // window stays mapped, so this must never be tied to `root.active`.
    visible: true
    focusable: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-idle-inhibitor"

    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    anchors {
      bottom: true
      right: true
    }
    implicitWidth: 1
    implicitHeight: 1

    IdleInhibitor {
      enabled: root.active
      window: host
    }
  }
}
