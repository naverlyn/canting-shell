import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Scope {
  id: root
  property var theme: Theme
  property string font: "Hack Nerd Font"

  property string searchText: ""
  property string previewPath: ""
  property bool browsingFolders: false

  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      wallpaperPanel.visible = !wallpaperPanel.visible;
      if (wallpaperPanel.visible) {
        root.searchText = "";
        root.previewPath = "";
        root.browsingFolders = false;
        searchInput.forceActiveFocus();
        if (WallpaperService.wallpapers.length === 0) WallpaperService.rescan();
      }
    }

    function addFolder(path: string): void {
      WallpaperService.addDirectory(path);
    }

    function removeFolder(path: string): void {
      WallpaperService.removeDirectory(path);
    }

    function rescan(): void {
      WallpaperService.rescan();
    }
  }

  property var filteredWallpapers: {
    if (!wallpaperPanel.visible) return [];
    const q = searchText.toLowerCase().trim();
    let list = WallpaperService.wallpapers || [];
    if (q !== "") {
      list = list.filter(p => {
        const name = p.split("/").pop().toLowerCase();
        return name.includes(q);
      });
    }
    const current = WallpaperService.currentWallpaper;
    if (current && list.includes(current)) {
      list = [current].concat(list.filter(p => p !== current));
    }
    return list;
  }

  PanelWindow {
    id: wallpaperPanel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wallpaper"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Dark overlay backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.previewPath !== "") {
          root.previewPath = "";
        } else {
          wallpaperPanel.visible = false;
        }
      }

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Main wallpaper box
    Rectangle {
      anchors.centerIn: parent
      width: 840
      height: 640
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      MouseArea {
        anchors.fill: parent
        onClicked: event => event.accepted = true
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          // Title / Back toggle
          RowLayout {
            spacing: 8

            Rectangle {
              visible: root.browsingFolders
              implicitWidth: backText.implicitWidth + 18
              height: 28
              radius: 6
              color: backHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
              border.color: root.theme.bgBorder
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
                color: root.theme.accentPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: root.font
              }

              MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.browsingFolders = false;
                  searchInput.forceActiveFocus();
                }
              }
            }

            Text {
              text: root.browsingFolders ? "Browse Folders" : "Wallpapers"
              color: root.theme.accentPrimary
              font.pixelSize: 15
              font.family: root.font
              font.bold: true

              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }

          Item { Layout.fillWidth: true }

          // Status info
          Text {
            text: {
              if (root.browsingFolders) {
                const count = WallpaperService.directories ? WallpaperService.directories.length : 0;
                return count + " active source" + (count === 1 ? "" : "s");
              }
              return WallpaperService.generatingTheme
                ? "Generating wallust palette..."
                : root.filteredWallpapers.length + " images";
            }
            color: WallpaperService.generatingTheme ? root.theme.accentPrimary : root.theme.textMuted
            font.pixelSize: 11
            font.family: root.font
          }

          // Header action button (Folders toggle / Done)
          Rectangle {
            implicitWidth: folderBtnText.implicitWidth + 24
            height: 28
            radius: 6
            color: root.browsingFolders
              ? (folderBtnHover.containsMouse ? root.theme.bgHover : root.theme.bgSelected)
              : (folderBtnHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
            border.color: root.browsingFolders ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1
            scale: folderBtnHover.pressed ? 0.95 : (folderBtnHover.containsMouse ? 1.03 : 1.0)
            Accessible.role: Accessible.Button
            Accessible.name: root.browsingFolders ? "Return to wallpaper picker" : "Open built-in folder browser"

            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
              id: folderBtnText
              anchors.centerIn: parent
              text: root.browsingFolders ? "Done" : "Folders"
              color: root.browsingFolders ? root.theme.accentPrimary : root.theme.textPrimary
              font.pixelSize: 11
              font.bold: true
              font.family: root.font
            }

            MouseArea {
              id: folderBtnHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.browsingFolders = !root.browsingFolders;
                if (root.browsingFolders) {
                  WallpaperService.loadBrowseEntries();
                } else {
                  searchInput.forceActiveFocus();
                }
              }
            }
          }

          // Refresh button
          Rectangle {
            implicitWidth: refreshBtnText.implicitWidth + 20
            height: 28
            radius: 6
            color: refreshHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
            border.color: root.theme.bgBorder
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
              color: refreshHover.containsMouse ? root.theme.textPrimary : root.theme.textMuted
              font.pixelSize: 11
              font.bold: true
              font.family: root.font
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

        /* View 1: Folder browser */
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12
          visible: root.browsingFolders

          // Shortcuts & Jump Input Row
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Shortcut: Home
            Rectangle {
              width: homeText.implicitWidth + 20
              height: 28
              radius: 6
              color: homeHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              scale: homeHover.pressed ? 0.95 : (homeHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: homeText
                anchors.centerIn: parent
                text: "Home"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
              }

              MouseArea {
                id: homeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.navigateTo(Quickshell.env("HOME"))
              }
            }

            // Shortcut: Pictures
            Rectangle {
              width: picText.implicitWidth + 20
              height: 28
              radius: 6
              color: picHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              scale: picHover.pressed ? 0.95 : (picHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: picText
                anchors.centerIn: parent
                text: "Pictures"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
              }

              MouseArea {
                id: picHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.navigateTo(Quickshell.env("HOME") + "/Pictures")
              }
            }

            // Shortcut: Downloads
            Rectangle {
              width: dlText.implicitWidth + 20
              height: 28
              radius: 6
              color: dlHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              scale: dlHover.pressed ? 0.95 : (dlHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: dlText
                anchors.centerIn: parent
                text: "Downloads"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
              }

              MouseArea {
                id: dlHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.navigateTo(Quickshell.env("HOME") + "/Downloads")
              }
            }

            // Shortcut: Parent (Up)
            Rectangle {
              width: upText.implicitWidth + 20
              height: 28
              radius: 6
              color: upHover.containsMouse ? root.theme.bgHover : root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              scale: upHover.pressed ? 0.95 : (upHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: upText
                anchors.centerIn: parent
                text: "Up"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
              }

              MouseArea {
                id: upHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.navigateUp()
              }
            }

            // Quick Jump Text Field
            Rectangle {
              Layout.fillWidth: true
              height: 28
              radius: 6
              color: root.theme.bgSurface
              border.color: jumpInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
              border.width: 1

              Behavior on border.color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                TextInput {
                  id: jumpInput
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: root.font
                  clip: true
                  selectByMouse: true
                  onAccepted: {
                    if (text.trim() !== "") {
                      WallpaperService.navigateTo(text.trim());
                      text = "";
                    }
                  }
                }

                Text {
                  text: "Jump to path (e.g. ~/Wallpapers)..."
                  color: root.theme.textMuted
                  font.pixelSize: 11
                  font.family: root.font
                  visible: jumpInput.text === "" && !jumpInput.activeFocus
                }
              }
            }
          }

          // Combined Breadcrumbs & Current Folder Action Bar
          Rectangle {
            Layout.fillWidth: true
            height: 50
            radius: 10
            color: root.theme.bgSurface
            border.color: WallpaperService.isConfigured(WallpaperService.browsePath)
              ? root.theme.accentGreen
              : root.theme.bgBorder
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 16
              anchors.rightMargin: 16
              spacing: 12

              ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                // Clickable Breadcrumbs
                Flickable {
                  Layout.fillWidth: true
                  height: 20
                  contentWidth: breadcrumbRow.implicitWidth
                  contentHeight: height
                  clip: true
                  boundsBehavior: Flickable.StopAtBounds

                  Row {
                    id: breadcrumbRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                      model: WallpaperService.getBreadcrumbs(WallpaperService.browsePath)

                      delegate: Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                          height: 20
                          width: crumbLabel.implicitWidth + 8
                          radius: 4
                          color: crumbMouse.containsMouse ? root.theme.bgHover : "transparent"
                          scale: crumbMouse.pressed ? 0.95 : (crumbMouse.containsMouse ? 1.05 : 1.0)

                          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                          Behavior on color { ColorAnimation { duration: 150 } }

                          Text {
                            id: crumbLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: index === WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                              ? root.theme.accentPrimary
                              : root.theme.textPrimary
                            font.pixelSize: 12
                            font.family: root.font
                            font.bold: index === WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                          }

                          MouseArea {
                            id: crumbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.navigateTo(modelData.path)
                          }
                        }

                        Text {
                          text: "/"
                          color: root.theme.textMuted
                          font.pixelSize: 11
                          font.family: root.font
                          anchors.verticalCenter: parent.verticalCenter
                          visible: index < WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                        }
                      }
                    }
                  }
                }

                // Image Count Info
                Text {
                  text: WallpaperService.browseLoading
                    ? "Scanning images..."
                    : (WallpaperService.browseImageCount + " images in this folder")
                  color: root.theme.textMuted
                  font.pixelSize: 10
                  font.family: root.font
                }
              }

              // Add / Remove Action Button (Text Only)
              Rectangle {
                readonly property bool isAdded: WallpaperService.isConfigured(WallpaperService.browsePath)
                implicitWidth: toggleBtnText.implicitWidth + 24
                height: 32
                radius: 6
                color: isAdded
                  ? (currRemoveHover.containsMouse ? root.theme.accentRed : root.theme.bgSelected)
                  : root.theme.accentPrimary
                border.color: isAdded ? root.theme.accentGreen : "transparent"
                border.width: 1
                scale: currRemoveHover.pressed ? 0.95 : (currRemoveHover.containsMouse ? 1.03 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                  id: toggleBtnText
                  anchors.centerIn: parent
                  text: parent.isAdded
                    ? (currRemoveHover.containsMouse ? "Remove Folder" : "Added as Source")
                    : "+ Add This Folder"
                  color: parent.isAdded
                    ? (currRemoveHover.containsMouse ? "#ffffff" : root.theme.textPrimary)
                    : root.theme.bgBase
                  font.pixelSize: 11
                  font.family: root.font
                  font.bold: true
                }

                MouseArea {
                  id: currRemoveHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (parent.isAdded) {
                      WallpaperService.removeDirectory(WallpaperService.browsePath);
                    } else {
                      WallpaperService.addDirectory(WallpaperService.browsePath);
                    }
                  }
                }
              }
            }
          }

          // Subdirectories Explorer List
          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            ListView {
              id: dirListView
              anchors.fill: parent
              anchors.margins: 6
              model: wallpaperPanel.visible && root.browsingFolders ? WallpaperService.browseEntries : []
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                id: dirRowItem
                required property string modelData
                required property int index

                readonly property string fullSubPath: {
                  const base = WallpaperService.browsePath;
                  return base.endsWith("/") ? (base + modelData) : (base + "/" + modelData);
                }
                readonly property bool isSubAdded: WallpaperService.isConfigured(fullSubPath)

                width: dirListView.width
                height: 38
                radius: 6
                color: itemHover.containsMouse ? root.theme.bgHover : "transparent"
                scale: itemHover.pressed ? 0.99 : 1.0

                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  spacing: 12

                  Text {
                    text: dirRowItem.modelData
                    color: dirRowItem.isSubAdded ? root.theme.accentPrimary : root.theme.textPrimary
                    font.pixelSize: 12
                    font.family: root.font
                    font.bold: dirRowItem.isSubAdded
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }

                  // Badge if added (Text only)
                  Rectangle {
                    visible: dirRowItem.isSubAdded
                    height: 20
                    width: addedBadgeText.implicitWidth + 12
                    radius: 4
                    color: Qt.rgba(root.theme.accentGreen.r, root.theme.accentGreen.g, root.theme.accentGreen.b, 0.2)
                    border.color: root.theme.accentGreen
                    border.width: 1

                    Text {
                      id: addedBadgeText
                      anchors.centerIn: parent
                      text: "Added"
                      color: root.theme.accentGreen
                      font.pixelSize: 10
                      font.family: root.font
                      font.bold: true
                    }
                  }

                  // Navigate Arrow (plain text ›)
                  Text {
                    text: "›"
                    color: itemHover.containsMouse ? root.theme.accentPrimary : root.theme.textMuted
                    font.pixelSize: 14
                    font.family: root.font

                    Behavior on color { ColorAnimation { duration: 120 } }
                  }
                }

                MouseArea {
                  id: itemHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: WallpaperService.navigateTo(dirRowItem.fullSubPath)
                }
              }

              // Empty directory message
              Text {
                anchors.centerIn: parent
                text: WallpaperService.browseLoading
                  ? "Scanning directory..."
                  : "No subdirectories found in this folder"
                color: root.theme.textMuted
                font.pixelSize: 12
                font.family: root.font
                visible: !WallpaperService.browseEntries || WallpaperService.browseEntries.length === 0
              }
            }
          }

          // Bottom Bar: Active Configured Sources Chips
          Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 8
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 10

              Text {
                text: "Active:"
                color: root.theme.textMuted
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
              }

              Flickable {
                Layout.fillWidth: true
                height: 26
                contentWidth: activeChipsRow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                  id: activeChipsRow
                  spacing: 6
                  anchors.verticalCenter: parent.verticalCenter

                  Repeater {
                    model: WallpaperService.directories

                    delegate: Rectangle {
                      required property string modelData
                      height: 24
                      width: chipRow.implicitWidth + 14
                      radius: 6
                      color: root.theme.bgSurface
                      border.color: root.theme.bgBorder
                      border.width: 1

                      RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                          text: WallpaperService.displayPath(modelData)
                          color: root.theme.textPrimary
                          font.pixelSize: 11
                          font.family: root.font
                        }

                        Rectangle {
                          width: 14
                          height: 14
                          radius: 7
                          color: chipRemHover.containsMouse ? root.theme.accentRed : "transparent"
                          scale: chipRemHover.pressed ? 0.9 : (chipRemHover.containsMouse ? 1.15 : 1.0)

                          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                          Behavior on color { ColorAnimation { duration: 120 } }

                          Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: chipRemHover.containsMouse ? "#ffffff" : root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                          }

                          MouseArea {
                            id: chipRemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.removeDirectory(modelData)
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Reset defaults
              Text {
                text: "Reset"
                color: resetHover.containsMouse ? root.theme.accentPrimary : root.theme.textMuted
                font.pixelSize: 11
                font.family: root.font
                font.underline: true
                scale: resetHover.pressed ? 0.95 : (resetHover.containsMouse ? 1.05 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                  id: resetHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: WallpaperService.resetDefaultDirectories()
                }
              }
            }
          }
        }

        /* View 2: Wallpaper picker grid */
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12
          visible: !root.browsingFolders

          // Search bar
          Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 8
            color: root.theme.bgSurface
            border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
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
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: root.font
                clip: true
                selectByMouse: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Search wallpapers"
                onTextChanged: root.searchText = text

                Keys.onEscapePressed: {
                  if (root.previewPath !== "") {
                    root.previewPath = "";
                  } else {
                    wallpaperPanel.visible = false;
                  }
                }
              }

              Text {
                text: "Search wallpapers..."
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                visible: searchInput.text === "" && !searchInput.activeFocus
              }
            }
          }

          // Wallpaper grid
          GridView {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.floor(width / 4)
            cellHeight: cellWidth * 0.6 + 8
            clip: true
            cacheBuffer: 0
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredWallpapers

            delegate: Item {
              required property string modelData
              required property int index

              Accessible.role: Accessible.Button
              Accessible.name: modelData.split("/").pop() + (WallpaperService.currentWallpaper === modelData ? ", current wallpaper" : "")

              width: wallpaperGrid.cellWidth
              height: wallpaperGrid.cellHeight

              Rectangle {
                id: cardRect
                anchors.fill: parent
                anchors.margins: 4
                radius: 8
                color: root.theme.bgSurface
                border.color: WallpaperService.currentWallpaper === modelData ? root.theme.accentPrimary : (imgHover.containsMouse ? root.theme.bgBorder : "transparent")
                border.width: WallpaperService.currentWallpaper === modelData ? 2 : 1
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
                      color: root.theme.bgSurface
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
                      font.family: root.font
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
                    radius: Math.max(2, cardRect.radius - (WallpaperService.currentWallpaper === modelData ? 2 : 1))
                    color: "black"
                  }
                }

                // Active indicator (Current badge at top)
                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: 6
                  height: 20
                  width: currentBadgeText.implicitWidth + 14
                  radius: 4
                  color: root.theme.accentPrimary
                  visible: WallpaperService.currentWallpaper === modelData

                  Text {
                    id: currentBadgeText
                    anchors.centerIn: parent
                    text: "Current"
                    color: root.theme.bgBase
                    font.pixelSize: 10
                    font.bold: true
                    font.family: root.font
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
                      root.previewPath = modelData;
                    } else {
                      WallpaperService.setWallpaper(modelData);
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
                text: root.searchText !== ""
                  ? "No wallpapers match \"" + root.searchText + "\""
                  : "No wallpapers found in configured folders"
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
              }

              Rectangle {
                width: emptyBrowseText.implicitWidth + 24
                height: 32
                radius: 6
                color: emptyBrowseHover.containsMouse ? root.theme.bgHover : root.theme.accentPrimary
                scale: emptyBrowseHover.pressed ? 0.95 : (emptyBrowseHover.containsMouse ? 1.04 : 1.0)
                Accessible.role: Accessible.Button
                Accessible.name: "Open folder browser"
                Layout.alignment: Qt.AlignHCenter
                visible: root.searchText === ""

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  id: emptyBrowseText
                  anchors.centerIn: parent
                  text: "Browse Folders"
                  color: emptyBrowseHover.containsMouse ? root.theme.textPrimary : root.theme.bgBase
                  font.pixelSize: 12
                  font.family: root.font
                  font.bold: true
                }

                MouseArea {
                  id: emptyBrowseHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.browsingFolders = true;
                    WallpaperService.loadBrowseEntries();
                  }
                }
              }
            }
          }
        }

        // Footer
        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          Row {
            spacing: 4
            Rectangle {
              width: hintClick.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Text { id: hintClick; anchors.centerIn: parent; text: "click"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "apply"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintRight.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Text { id: hintRight; anchors.centerIn: parent; text: "right-click"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "preview"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Text { text: "Backend: " + WallpaperService.backend; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Item { Layout.fillWidth: true }
        }
      }
    }

    // Preview overlay
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.85)
      visible: root.previewPath !== ""

      MouseArea {
        anchors.fill: parent
        onClicked: root.previewPath = ""
      }

      Image {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        source: root.previewPath !== "" ? "file://" + root.previewPath : ""
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
        color: applyBtnHover.containsMouse ? root.theme.bgHover : root.theme.accentPrimary
        border.color: root.theme.accentPrimary
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
          color: applyBtnHover.containsMouse ? root.theme.textPrimary : root.theme.bgBase
          font.pixelSize: 13
          font.family: root.font
          font.bold: true
        }

        MouseArea {
          id: applyBtnHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            WallpaperService.setWallpaper(root.previewPath);
            root.previewPath = "";
          }
        }
      }
    }
  }
}