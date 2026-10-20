import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts

        RowLayout {
  id: footerRoot
  required property var hostRoot
          Layout.fillWidth: true
          spacing: 16

          Row {
            spacing: 4
            Rectangle {
              width: hintClick.width + 8; height: 18; radius: 4; color: hostRoot.theme.bgSurface
              Text { id: hintClick; anchors.centerIn: parent; text: "click"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font }
            }
            Text { text: "apply"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintRight.width + 8; height: 18; radius: 4; color: hostRoot.theme.bgSurface
              Text { id: hintRight; anchors.centerIn: parent; text: "right-click"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font }
            }
            Text { text: "preview"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Text { text: "Backend: " + WallpaperService.backend; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Item { Layout.fillWidth: true }
        }
