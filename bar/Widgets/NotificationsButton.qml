import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../notifications"
import "../../ControlCenter/Components"
import ".."

Rectangle {
  id: notifButton

  required property var hostRoot
  required property var hostContainer
  required property var hostWindow
  required property var hostScope

  readonly property bool isDnd: NotificationService.doNotDisturb
  readonly property int historyCount: NotificationService.historyCount
  readonly property bool popupOpen: notifPopupLoader.item ? notifPopupLoader.item.visible : false

  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert
    ? hostContainer.vertPillWidth
    : ((notifButton.historyCount > 9 && !notifButton.isDnd) ? 34 : 28)
  height: implicitHeight
  width: implicitWidth
  Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
  scale: notifArea.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("notifications", notifArea.containsMouse || notifButton.popupOpen)
  border.color: hostContainer.wBorder("notifications")
  border.width: hostContainer.hasCustomColor("notifications") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: notifButton.isDnd
    ? "Notifications (Do Not Disturb)"
    : (notifButton.historyCount > 0 ? "Notifications (" + notifButton.historyCount + ")" : "Notifications")

  PillIndicator {
    hostRoot: notifButton.hostRoot
    hostContainer: notifButton.hostContainer
    active: notifButton.popupOpen || notifArea.pressed
    hovered: notifArea.containsMouse
    accentColor: hostContainer.wAccent("notifications", hostRoot.theme.accentPrimary)
  }

  Text {
    id: notifIcon
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    text: notifButton.isDnd ? "󰂛" : "󰂚"
    color: (notifButton.popupOpen || notifButton.isDnd || hostContainer.hasCustomColor("notifications"))
      ? hostContainer.wAccent("notifications", hostRoot.theme.accentPrimary)
      : hostRoot.theme.textPrimary
    font.pixelSize: 13
    font.family: hostRoot.font
  }

  Rectangle {
    visible: notifButton.historyCount > 0 && !notifButton.isDnd
    width: Math.max(13, countBadgeText.implicitWidth + 5)
    height: 13
    radius: height / 2
    color: hostRoot.theme.accentPrimary
    anchors.top: notifIcon.top
    anchors.left: notifIcon.right
    anchors.topMargin: -2
    anchors.leftMargin: -4

    Text {
      id: countBadgeText
      anchors.centerIn: parent
      text: notifButton.historyCount > 99 ? "99+" : String(notifButton.historyCount)
      color: hostRoot.theme.bgBase
      font.family: hostRoot.font
      font.pixelSize: 8
      font.bold: true
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: hostContainer.wAccent("notifications", hostRoot.theme.accentPrimary)
    opacity: (hostContainer.activeStyle !== "underline" && (notifArea.containsMouse || notifButton.popupOpen)) ? 0.16 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }
  }

  Timer {
    id: unloadTimer
    interval: 250
    repeat: false
    onTriggered: {
      if (notifPopupLoader.item && !notifPopupLoader.item.visible) {
        notifPopupLoader.active = false;
        Qt.callLater(() => gc());
      }
    }
  }

  MouseArea {
    id: notifArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
        NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
        return;
      }
      unloadTimer.stop();
      if (!notifPopupLoader.active) {
        notifPopupLoader.active = true;
      } else if (notifPopupLoader.item) {
        notifPopupLoader.item.visible = !notifPopupLoader.item.visible;
      }
    }
  }

  Loader {
    id: notifPopupLoader
    active: false
    sourceComponent: Component {
      PanelWindow {
        id: notifPopupWin
        visible: true
        focusable: true
        color: "transparent"

        property real anchorX: 0
        property real anchorY: 0
        property real scrWidth: 1920
        property real scrHeight: 1080

        function updateAnchor() {
          const win = notifButton.QsWindow ? notifButton.QsWindow.window : null;
          const scr = (win && win.screen) ? win.screen : (screen ? screen : null);
          scrWidth = (scr && scr.width > 0) ? scr.width : 1920;
          scrHeight = (scr && scr.height > 0) ? scr.height : 1080;
          try {
            const pt = notifButton.mapToItem(null, notifButton.width / 2, notifButton.height / 2);
            if (pt && !isNaN(pt.x) && !isNaN(pt.y)) {
              anchorX = pt.x;
              anchorY = pt.y;
            }
          } catch (e) {}
        }

        Component.onCompleted: updateAnchor()
        onVisibleChanged: {
          if (visible) {
            unloadTimer.stop();
            updateAnchor();
          } else {
            unloadTimer.restart();
          }
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell-notifications-center"
        exclusionMode: ExclusionMode.Ignore

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        MouseArea {
          anchors.fill: parent
          onClicked: notifPopupWin.visible = false
        }

        Rectangle {
          id: cardContainer
          width: 380
          height: cardContent.implicitHeight
          radius: 14
          color: hostRoot.theme.bgBase
          border.color: hostRoot.theme.bgBorder
          border.width: 1
          clip: true

          readonly property string barPos: hostContainer.barPos
          readonly property int barOffset: hostScope.barThickness + (hostScope.isFloating ? 16 : 8)

          x: {
            if (barPos === "left") return barOffset;
            if (barPos === "right") return Math.max(12, notifPopupWin.width - width - barOffset);
            return Math.max(12, Math.min(notifPopupWin.width - width - 12, notifPopupWin.anchorX - width / 2));
          }
          y: {
            if (barPos === "top") return barOffset;
            if (barPos === "bottom") return Math.max(12, notifPopupWin.height - height - barOffset);
            return Math.max(12, Math.min(notifPopupWin.height - height - 12, notifPopupWin.anchorY - height / 2));
          }

          MouseArea { anchors.fill: parent }

          NotificationsCard {
            id: cardContent
            width: parent.width
            theme: hostRoot.theme
            font: hostRoot.font
          }
        }
      }
    }
  }
}
