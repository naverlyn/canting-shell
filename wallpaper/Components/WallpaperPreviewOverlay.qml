import Quickshell
import ".."
import QtQuick

    Rectangle {
  id: previewRoot
  required property var hostRoot
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.85)
      visible: hostRoot.previewPath !== ""

      MouseArea {
        anchors.fill: parent
        onClicked: hostRoot.previewPath = ""
      }

      Image {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        source: hostRoot.previewPath !== "" ? "file://" + hostRoot.previewPath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      // Apply button
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40
        width: applyText.implicitWidth + 36
        height: 38
        radius: 19
        color: applyBtnHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.accentPrimary
        border.color: hostRoot.theme.accentPrimary
        border.width: 1
        scale: applyBtnHover.pressed ? 0.95 : (applyBtnHover.containsMouse ? 1.04 : 1.0)
        Accessible.role: Accessible.Button
        Accessible.name: "Apply wallpaper"

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
          id: applyText
          anchors.centerIn: parent
          text: "Apply Wallpaper"
          color: applyBtnHover.containsMouse ? hostRoot.theme.textPrimary : hostRoot.theme.bgBase
          font.pixelSize: 13
          font.family: hostRoot.font
          font.bold: true
        }

        MouseArea {
          id: applyBtnHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            WallpaperService.setWallpaper(hostRoot.previewPath);
            hostRoot.previewPath = "";
          }
        }
      }
    }
