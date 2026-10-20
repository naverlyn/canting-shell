import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts

        RowLayout {
  id: headerRoot
  required property var hostRoot
  required property var searchInputRef
          Layout.fillWidth: true
          spacing: 10

          // Title / Back toggle
          RowLayout {
            spacing: 8

            Rectangle {
              visible: hostRoot.browsingFolders
              implicitWidth: backText.implicitWidth + 18
              height: 28
              radius: 6
              color: backHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
              border.color: hostRoot.theme.bgBorder
              border.width: 1
              scale: backHover.pressed ? 0.95 : (backHover.containsMouse ? 1.03 : 1.0)
              Accessible.role: Accessible.Button
              Accessible.name: "Back to wallpapers"

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: backText
                anchors.centerIn: parent
                text: "‹ Back"
                color: hostRoot.theme.accentPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: hostRoot.font
              }

              MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  hostRoot.browsingFolders = false;
                  searchInputRef.forceActiveFocus();
                }
              }
            }

            Text {
              text: hostRoot.browsingFolders ? "Browse Folders" : "Wallpapers"
              color: hostRoot.theme.accentPrimary
              font.pixelSize: 15
              font.family: hostRoot.font
              font.bold: true

              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }

          Item { Layout.fillWidth: true }

          // Status info
          Text {
            text: {
              if (hostRoot.browsingFolders) {
                const count = WallpaperService.directories ? WallpaperService.directories.length : 0;
                return count + " active source" + (count === 1 ? "" : "s");
              }
              return WallpaperService.generatingTheme
                ? "Generating wallust palette..."
                : hostRoot.filteredWallpapers.length + " images";
            }
            color: WallpaperService.generatingTheme ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
            font.pixelSize: 11
            font.family: hostRoot.font
          }

          // Header action button (Folders toggle / Done)
          Rectangle {
            implicitWidth: folderBtnText.implicitWidth + 24
            height: 28
            radius: 6
            color: hostRoot.browsingFolders
              ? (folderBtnHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSelected)
              : (folderBtnHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface)
            border.color: hostRoot.browsingFolders ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1
            scale: folderBtnHover.pressed ? 0.95 : (folderBtnHover.containsMouse ? 1.03 : 1.0)
            Accessible.role: Accessible.Button
            Accessible.name: hostRoot.browsingFolders ? "Return to wallpaper picker" : "Open built-in folder browser"

            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
              id: folderBtnText
              anchors.centerIn: parent
              text: hostRoot.browsingFolders ? "Done" : "Folders"
              color: hostRoot.browsingFolders ? hostRoot.theme.accentPrimary : hostRoot.theme.textPrimary
              font.pixelSize: 11
              font.bold: true
              font.family: hostRoot.font
            }

            MouseArea {
              id: folderBtnHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                hostRoot.browsingFolders = !hostRoot.browsingFolders;
                if (hostRoot.browsingFolders) {
                  WallpaperService.loadBrowseEntries();
                } else {
                  searchInputRef.forceActiveFocus();
                }
              }
            }
          }

          // Refresh button
          Rectangle {
            implicitWidth: refreshBtnText.implicitWidth + 20
            height: 28
            radius: 6
            color: refreshHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
            border.color: hostRoot.theme.bgBorder
            border.width: 1
            scale: refreshHover.pressed ? 0.95 : (refreshHover.containsMouse ? 1.03 : 1.0)
            Accessible.role: Accessible.Button
            Accessible.name: "Refresh wallpaper list"

            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
              id: refreshBtnText
              anchors.centerIn: parent
              text: "Refresh"
              color: refreshHover.containsMouse ? hostRoot.theme.textPrimary : hostRoot.theme.textMuted
              font.pixelSize: 11
              font.bold: true
              font.family: hostRoot.font
            }

            MouseArea {
              id: refreshHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: WallpaperService.rescan()
            }
          }
        }
