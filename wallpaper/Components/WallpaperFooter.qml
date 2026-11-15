import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts

Rectangle {
  id: footerRoot
  required property var hostRoot

  Layout.fillWidth: true
  Layout.leftMargin: -18
  Layout.rightMargin: -18
  Layout.bottomMargin: -18
  height: 32
  color: hostRoot.theme.bgSurface

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 16

    Row {
      spacing: 4
      Text { text: "click"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: hostRoot.browsingFolders ? "open folder" : "apply"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      visible: !hostRoot.browsingFolders
      spacing: 4
      Text { text: "right-click"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "preview"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      spacing: 4
      Text { text: "esc"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "close"; color: hostRoot.theme.textMuted; font.pixelSize: 10; font.family: hostRoot.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Item { Layout.fillWidth: true }

    Text {
      text: "Backend: " + WallpaperService.backend
      color: hostRoot.theme.textMuted
      font.pixelSize: 10
      font.family: hostRoot.font
    }
  }
}
