import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts

        ColumnLayout {
  id: foldersRoot
  required property var hostRoot
  required property var hostPanel
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12
          visible: hostRoot.browsingFolders

          // Shortcuts & Jump Input Row
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Shortcut: Home
            Rectangle {
              width: homeText.implicitWidth + 20
              height: 28
              radius: 6
              color: homeHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
              border.color: hostRoot.theme.bgBorder
              border.width: 1
              scale: homeHover.pressed ? 0.95 : (homeHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: homeText
                anchors.centerIn: parent
                text: "Home"
                color: hostRoot.theme.textPrimary
                font.pixelSize: 11
                font.family: hostRoot.font
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
              color: picHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
              border.color: hostRoot.theme.bgBorder
              border.width: 1
              scale: picHover.pressed ? 0.95 : (picHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: picText
                anchors.centerIn: parent
                text: "Pictures"
                color: hostRoot.theme.textPrimary
                font.pixelSize: 11
                font.family: hostRoot.font
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
              color: dlHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
              border.color: hostRoot.theme.bgBorder
              border.width: 1
              scale: dlHover.pressed ? 0.95 : (dlHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: dlText
                anchors.centerIn: parent
                text: "Downloads"
                color: hostRoot.theme.textPrimary
                font.pixelSize: 11
                font.family: hostRoot.font
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
              color: upHover.containsMouse ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
              border.color: hostRoot.theme.bgBorder
              border.width: 1
              scale: upHover.pressed ? 0.95 : (upHover.containsMouse ? 1.04 : 1.0)

              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                id: upText
                anchors.centerIn: parent
                text: "Up"
                color: hostRoot.theme.textPrimary
                font.pixelSize: 11
                font.family: hostRoot.font
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
              color: hostRoot.theme.bgSurface
              border.color: jumpInput.activeFocus ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
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
                  color: hostRoot.theme.textPrimary
                  font.pixelSize: 11
                  font.family: hostRoot.font
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
                  color: hostRoot.theme.textMuted
                  font.pixelSize: 11
                  font.family: hostRoot.font
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
            color: hostRoot.theme.bgSurface
            border.color: WallpaperService.isConfigured(WallpaperService.browsePath)
              ? hostRoot.theme.accentGreen
              : hostRoot.theme.bgBorder
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
                          color: crumbMouse.containsMouse ? hostRoot.theme.bgHover : "transparent"
                          scale: crumbMouse.pressed ? 0.95 : (crumbMouse.containsMouse ? 1.05 : 1.0)

                          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                          Behavior on color { ColorAnimation { duration: 150 } }

                          Text {
                            id: crumbLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: index === WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                              ? hostRoot.theme.accentPrimary
                              : hostRoot.theme.textPrimary
                            font.pixelSize: 12
                            font.family: hostRoot.font
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
                          color: hostRoot.theme.textMuted
                          font.pixelSize: 11
                          font.family: hostRoot.font
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
                  color: hostRoot.theme.textMuted
                  font.pixelSize: 10
                  font.family: hostRoot.font
                }
              }

              // Add / Remove Action Button (Text Only)
              Rectangle {
                readonly property bool isAdded: WallpaperService.isConfigured(WallpaperService.browsePath)
                implicitWidth: toggleBtnText.implicitWidth + 24
                height: 32
                radius: 6
                color: isAdded
                  ? (currRemoveHover.containsMouse ? hostRoot.theme.accentRed : hostRoot.theme.bgSelected)
                  : hostRoot.theme.accentPrimary
                border.color: isAdded ? hostRoot.theme.accentGreen : "transparent"
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
                    ? (currRemoveHover.containsMouse ? "#ffffff" : hostRoot.theme.textPrimary)
                    : hostRoot.theme.bgBase
                  font.pixelSize: 11
                  font.family: hostRoot.font
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
            color: hostRoot.theme.bgSurface
            border.color: hostRoot.theme.bgBorder
            border.width: 1
            clip: true

            ListView {
              id: dirListView
              anchors.fill: parent
              anchors.margins: 6
              model: hostPanel.visible && hostRoot.browsingFolders ? WallpaperService.browseEntries : []
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
                color: itemHover.containsMouse ? hostRoot.theme.bgHover : "transparent"
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
                    color: dirRowItem.isSubAdded ? hostRoot.theme.accentPrimary : hostRoot.theme.textPrimary
                    font.pixelSize: 12
                    font.family: hostRoot.font
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
                    color: Qt.rgba(hostRoot.theme.accentGreen.r, hostRoot.theme.accentGreen.g, hostRoot.theme.accentGreen.b, 0.2)
                    border.color: hostRoot.theme.accentGreen
                    border.width: 1

                    Text {
                      id: addedBadgeText
                      anchors.centerIn: parent
                      text: "Added"
                      color: hostRoot.theme.accentGreen
                      font.pixelSize: 10
                      font.family: hostRoot.font
                      font.bold: true
                    }
                  }

                  // Navigate Arrow (plain text ›)
                  Text {
                    text: "›"
                    color: itemHover.containsMouse ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                    font.pixelSize: 14
                    font.family: hostRoot.font

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
                color: hostRoot.theme.textMuted
                font.pixelSize: 12
                font.family: hostRoot.font
                visible: !WallpaperService.browseEntries || WallpaperService.browseEntries.length === 0
              }
            }
          }

          // Bottom Bar: Active Configured Sources Chips
          Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 8
            color: hostRoot.theme.bgBase
            border.color: hostRoot.theme.bgBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 10

              Text {
                text: "Active:"
                color: hostRoot.theme.textMuted
                font.pixelSize: 11
                font.family: hostRoot.font
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
                      color: hostRoot.theme.bgSurface
                      border.color: hostRoot.theme.bgBorder
                      border.width: 1

                      RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                          text: WallpaperService.displayPath(modelData)
                          color: hostRoot.theme.textPrimary
                          font.pixelSize: 11
                          font.family: hostRoot.font
                        }

                        Rectangle {
                          width: 14
                          height: 14
                          radius: 7
                          color: chipRemHover.containsMouse ? hostRoot.theme.accentRed : "transparent"
                          scale: chipRemHover.pressed ? 0.9 : (chipRemHover.containsMouse ? 1.15 : 1.0)

                          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                          Behavior on color { ColorAnimation { duration: 120 } }

                          Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: chipRemHover.containsMouse ? "#ffffff" : hostRoot.theme.textMuted
                            font.pixelSize: 11
                            font.family: hostRoot.font
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
                color: resetHover.containsMouse ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                font.pixelSize: 11
                font.family: hostRoot.font
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
