import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

        ColumnLayout {
  id: gridSectionRoot
  required property var hostRoot
  required property var hostPanel
  property alias searchInput: searchInput
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12
          visible: !hostRoot.browsingFolders

          // Search bar
          Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 8
            color: hostRoot.theme.bgSurface
            border.color: searchInput.activeFocus ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 8

              TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: hostRoot.theme.textPrimary
                font.pixelSize: 13
                font.family: hostRoot.font
                clip: true
                selectByMouse: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Search wallpapers"
                onTextChanged: hostRoot.searchText = text

                Keys.onEscapePressed: {
                  if (hostRoot.previewPath !== "") {
                    hostRoot.previewPath = "";
                  } else {
                    hostPanel.visible = false;
                  }
                }
              }

              Text {
                text: "Search wallpapers..."
                color: hostRoot.theme.textMuted
                font.pixelSize: 13
                font.family: hostRoot.font
                visible: searchInput.text === "" && !searchInput.activeFocus
              }
            }
          }

          // Wallpaper grid
          GridView {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max(120, Math.floor((width > 0 ? width : 800) / 4))
            cellHeight: cellWidth * 0.6 + 8
            clip: true
            cacheBuffer: 0
            boundsBehavior: Flickable.StopAtBounds
            model: (hostPanel.visible && !hostRoot.browsingFolders) ? hostRoot.filteredWallpapers : []

            delegate: Item {
              id: delItem
              required property string modelData
              required property int index

              readonly property bool isCurrentA: WallpaperService.wallpaperA === modelData
              readonly property bool isCurrentB: WallpaperService.wallpaperB === modelData
              readonly property bool isCurrentGlobal: WallpaperService.currentWallpaper === modelData
              readonly property bool isCurrent: isCurrentA || isCurrentB || isCurrentGlobal

              Accessible.role: Accessible.Button
              Accessible.name: modelData.split("/").pop() + (delItem.isCurrent ? ", current wallpaper" : "")

              width: wallpaperGrid.cellWidth
              height: wallpaperGrid.cellHeight

              Rectangle {
                id: cardRect
                anchors.fill: parent
                anchors.margins: 4
                radius: 8
                color: hostRoot.theme.bgSurface
                border.color: delItem.isCurrent
                  ? ((WallpaperService.hasMultipleMonitors && delItem.isCurrentB && !delItem.isCurrentA)
                      ? (hostRoot.theme.accentCyan ?? hostRoot.theme.accentPrimary)
                      : hostRoot.theme.accentPrimary)
                  : (imgHover.containsMouse ? hostRoot.theme.bgBorder : "transparent")
                border.width: delItem.isCurrent ? 2 : 1
                scale: imgHover.pressed ? 0.96 : (imgHover.containsMouse ? 1.03 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Masked container so wallpaper image and filename bar curve smoothly to match the card radius
                Item {
                  id: imgContainer
                  anchors.fill: parent
                  anchors.margins: WallpaperService.currentWallpaper === modelData ? 2 : 1
                  layer.enabled: true
                  layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: cardMask
                  }

                  Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 200
                    sourceSize.height: 120
                    asynchronous: true
                    cache: false

                    Rectangle {
                      anchors.fill: parent
                      color: hostRoot.theme.bgSurface
                      visible: parent.status !== Image.Ready
                    }
                  }

                  // Filename label
                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22
                    color: Qt.rgba(0, 0, 0, 0.6)

                    Text {
                      anchors.centerIn: parent
                      text: modelData.split("/").pop()
                      color: "#ffffff"
                      font.pixelSize: 9
                      font.family: hostRoot.font
                      elide: Text.ElideMiddle
                      width: parent.width - 8
                      horizontalAlignment: Text.AlignHCenter
                    }
                  }
                }

                // Mask item providing matching inner corner radius
                Item {
                  id: cardMask
                  anchors.fill: imgContainer
                  visible: false
                  layer.enabled: true

                  Rectangle {
                    anchors.fill: parent
                    radius: Math.max(2, cardRect.radius - (delItem.isCurrent ? 2 : 1))
                    color: "black"
                  }
                }

                // Active indicator badge at top
                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: 6
                  height: 20
                  width: currentBadgeText.implicitWidth + 14
                  radius: 4
                  color: (WallpaperService.hasMultipleMonitors && delItem.isCurrentB && !delItem.isCurrentA)
                    ? (hostRoot.theme.accentCyan ?? hostRoot.theme.accentPrimary)
                    : hostRoot.theme.accentPrimary
                  visible: delItem.isCurrent

                  Text {
                    id: currentBadgeText
                    anchors.centerIn: parent
                    text: {
                      if (WallpaperService.hasMultipleMonitors) {
                        if (delItem.isCurrentA && delItem.isCurrentB) return "All";
                        if (delItem.isCurrentA) return "Primary";
                        if (delItem.isCurrentB) return "Secondary";
                      }
                      return "Active";
                    }
                    color: hostRoot.theme.bgBase
                    font.pixelSize: 10
                    font.bold: true
                    font.family: hostRoot.font
                  }
                }

                MouseArea {
                  id: imgHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                      hostRoot.previewPath = modelData;
                    } else {
                      WallpaperService.setWallpaper(modelData, WallpaperService.targetDisplay, WallpaperService.resizeMode);
                    }
                  }
                }
              }
            }

            // Empty state
            ColumnLayout {
              anchors.centerIn: parent
              spacing: 12
              visible: wallpaperGrid.count === 0

              Text {
                text: hostRoot.searchText !== ""
                  ? "No wallpapers match \"" + hostRoot.searchText + "\""
                  : "No wallpapers found in configured folders"
                color: hostRoot.theme.textMuted
                font.pixelSize: 13
                font.family: hostRoot.font
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
              }

              Rectangle {
                width: emptyBrowseText.implicitWidth + 24
                height: 32
                radius: 6
                color: emptyBrowseHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.accentPrimary
                scale: emptyBrowseHover.pressed ? 0.95 : (emptyBrowseHover.containsMouse ? 1.04 : 1.0)
                Accessible.role: Accessible.Button
                Accessible.name: "Open folder browser"
                Layout.alignment: Qt.AlignHCenter
                visible: hostRoot.searchText === ""

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  id: emptyBrowseText
                  anchors.centerIn: parent
                  text: "Browse Folders"
                  color: emptyBrowseHover.containsMouse ? hostRoot.theme.textPrimary : hostRoot.theme.bgBase
                  font.pixelSize: 12
                  font.family: hostRoot.font
                  font.bold: true
                }

                MouseArea {
                  id: emptyBrowseHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    hostRoot.browsingFolders = true;
                    WallpaperService.loadBrowseEntries();
                  }
                }
              }
            }
          }
        }
