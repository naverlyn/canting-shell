import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    anchors.fill: parent
    spacing: 12

    /* Top Header with Segmented Pill Toggle */
    WallpaperTopHeader {
        root: self.root
    }

    /* VIEW 0: GALLERY */
    ColumnLayout {
        visible: root.currentView === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        // Compact Active Wallpaper Hero Card
        WallpaperActiveHeroCard {
            root: self.root
        }

        // Gallery Header & Search Bar
        WallpaperGalleryHeader {
            root: self.root
        }

        // Virtualized Wallpaper Grid Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            // Empty State
            Item {
                visible: !root.filteredWallpapers || root.filteredWallpapers.length === 0
                anchors.fill: parent

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "No wallpapers found"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.searchFilter !== "" 
                            ? "Try a different search query"
                            : "Add folders in the Folders tab to index wallpaper files"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // High-performance virtualized GridView
            GridView {
                id: wpGrid
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 150
                visible: root.filteredWallpapers && root.filteredWallpapers.length > 0

                readonly property int columns: Math.max(3, Math.min(6, Math.floor(width / 164)))
                cellWidth: Math.floor(width / columns)
                cellHeight: Math.floor(cellWidth * 0.62) + 6

                model: root.filteredWallpapers

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.2)
                    }
                }

                delegate: Item {
                    id: delItem
                    width: wpGrid.cellWidth
                    height: wpGrid.cellHeight

                    required property string modelData
                    required property int index

                    readonly property bool isCurrent: WallpaperService.currentWallpaper === modelData
                    readonly property string filename: {
                        const p = modelData.split("/");
                        return p[p.length - 1];
                    }

                    Rectangle {
                        id: cardRect
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        scale: itemHover.hovered ? 1.02 : 1.0
                        border.color: delItem.isCurrent
                            ? root.theme.accentPrimary
                            : (itemHover.hovered ? (root.theme.accentPrimary ?? Qt.rgba(1, 1, 1, 0.3)) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                        border.width: delItem.isCurrent ? 2 : 1

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        HoverHandler { id: itemHover }

                        // Masked container so wallpaper image and vignette curve smoothly to match the card radius
                        Item {
                            id: imgContainer
                            anchors.fill: parent
                            anchors.margins: delItem.isCurrent ? 2 : 1
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: cardMask
                            }

                            // High-speed scaled thumbnail
                            Image {
                                anchors.fill: parent
                                source: "file://" + delItem.modelData
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 240
                                sourceSize.height: 150
                                asynchronous: true
                                cache: false
                            }

                            // Vignette at bottom for text readability
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 24
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                                }
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 6
                                text: delItem.filename
                                font.family: root.font
                                font.pixelSize: 10
                                color: "#ffffff"
                                elide: Text.ElideRight
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

                        // Active indicator (Current badge at top)
                        Rectangle {
                            visible: delItem.isCurrent
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            height: 20
                            width: currentBadgeText.implicitWidth + 14
                            radius: 4
                            color: root.theme.accentPrimary

                            Text {
                                id: currentBadgeText
                                anchors.centerIn: parent
                                text: "Current"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.bgBase
                            }
                        }

                        // Hover overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: cardRect.radius
                            color: itemHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    root.previewPath = delItem.modelData;
                                } else {
                                    WallpaperService.setWallpaper(delItem.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer hints row
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 12

            RowLayout {
                spacing: 6
                Rectangle {
                    height: 18
                    width: clickBadge.implicitWidth + 8
                    radius: 4
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Text {
                        id: clickBadge
                        anchors.centerIn: parent
                        text: "click"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textSecondary
                    }
                }
                Text {
                    text: "apply"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textMuted
                }
            }

            RowLayout {
                spacing: 6
                Rectangle {
                    height: 18
                    width: rclickBadge.implicitWidth + 8
                    radius: 4
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Text {
                        id: rclickBadge
                        anchors.centerIn: parent
                        text: "right-click"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textSecondary
                    }
                }
                Text {
                    text: "preview"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Backend: " + (WallpaperService.backend || "awww + wallust")
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }
        }
    }

    /* VIEW 1: FOLDERS */
    ColumnLayout {
        visible: root.currentView === 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        // Top Shortcuts & Quick Jump Bar
        WallpaperQuickJumpShortcuts {
            root: self.root
        }

        // Current Folder Action Bar / Hero Card
        WallpaperFolderBar {
            root: self.root
        }

        // Subdirectories Explorer Card (Vertical ListView)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            ListView {
                id: dirListView
                anchors.fill: parent
                anchors.margins: 6
                model: root.currentView === 1 ? WallpaperService.browseEntries : []
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
                    }
                }

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
                    color: itemHover.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                    scale: itemHover.containsMouse ? 1.01 : 1.0

                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
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

                        // Added Badge (Text only)
                        Rectangle {
                            visible: dirRowItem.isSubAdded
                            height: 20
                            width: addedBadgeText.implicitWidth + 12
                            radius: 4
                            color: Qt.rgba(root.theme.accentGreen.r, root.theme.accentGreen.g, root.theme.accentGreen.b, 0.15)
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

                        // Navigate arrow
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

        // Bottom Bar: Active Configured Sources Card
        WallpaperBottomBar {
            root: self.root
        }

        // Footer hints row
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 12

            Text {
                text: "click: navigate folder"
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Backend: " + (WallpaperService.backend || "awww + wallust")
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }
        }
    }
}
