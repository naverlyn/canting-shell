/*
 * HyprlockWallpaperModal.qml
 *
 * Dedicated overlay window for selecting a lock screen wallpaper.
 * Provides a clean gallery grid with search filtering, rescan,
 * and seamless synchronization with .wallpaper_current.
 * Follows Libadwaita aesthetic with text-only controls (no icons).
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../wallpaper"

PanelWindow {
    id: root

    property var theme
    property string font: "Hack Nerd Font"
    property string currentSelected: ""

    signal wallpaperSelected(string path)

    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-hyprlock-wallpaper"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property string searchText: ""

    property var filteredWallpapers: {
        const list = WallpaperService.wallpapers || [];
        const q = searchText.trim().toLowerCase();
        if (q === "") return list;
        return list.filter(p => {
            const name = p.split("/").pop().toLowerCase();
            return name.includes(q);
        });
    }

    onVisibleChanged: {
        if (visible) {
            searchText = "";
            if (!WallpaperService.wallpapers || WallpaperService.wallpapers.length === 0) {
                WallpaperService.rescan();
            }
            searchField.forceActiveFocus();
        }
    }

    // Overlay backdrop: clicking outside closes modal
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false

        Rectangle {
            anchors.fill: parent
            color: root.theme.bgOverlay ?? Qt.rgba(0, 0, 0, 0.65)
        }
    }

    // Centered Dialog Window
    Rectangle {
        id: dialogBox
        anchors.centerIn: parent
        width: 760
        height: 520
        radius: 14
        color: root.theme.bgBase ?? "#1e1e2e"
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        clip: true

        // Trap mouse clicks within dialog
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Keyboard handler for Escape to close
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.visible = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: "Choose Lock Screen Wallpaper"
                        font.family: root.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.theme.textPrimary ?? "#ffffff"
                    }

                    Text {
                        text: {
                            const count = root.filteredWallpapers.length;
                            const total = WallpaperService.wallpapers ? WallpaperService.wallpapers.length : 0;
                            if (root.searchText !== "") {
                                return count + " of " + total + " wallpapers match filter";
                            }
                            return total + " wallpapers available in library";
                        }
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary ?? "#a6adc8"
                    }
                }

                // Search Filter Input
                Rectangle {
                    width: 200
                    height: 32
                    radius: 7
                    color: root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: searchField.activeFocus ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: 1

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.searchText
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary ?? "#ffffff"
                        clip: true

                        onTextChanged: root.searchText = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Search wallpapers..."
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary ?? "#6c7086"
                        }
                    }
                }

                // Rescan Button
                Rectangle {
                    width: rescanText.implicitWidth + 20
                    height: 32
                    radius: 7
                    color: rescanHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.25))
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    HoverHandler { id: rescanHover }

                    Text {
                        id: rescanText
                        anchors.centerIn: parent
                        text: "Rescan"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary ?? "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.rescan()
                    }
                }

                // Close Button
                Rectangle {
                    width: closeText.implicitWidth + 20
                    height: 32
                    radius: 7
                    color: closeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.25))
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    HoverHandler { id: closeHover }

                    Text {
                        id: closeText
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary ?? "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            }

            // --- Wallpaper Grid Content ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.filteredWallpapers.length === 0

                    Text {
                        text: "No wallpapers found"
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.theme.textSecondary ?? "#a6adc8"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.searchText !== "" ? "Try adjusting your search query." : "Ensure ~/Pictures/wallpapers has image files."
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary ?? "#6c7086"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Wallpaper Grid View
                GridView {
                    id: gridView
                    anchors.fill: parent
                    clip: true
                    visible: root.filteredWallpapers.length > 0

                    cellWidth: 178
                    cellHeight: 118

                    model: root.filteredWallpapers

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: delegateRoot
                        width: 170
                        height: 110

                        property bool isCurrent: root.currentSelected === modelData
                        property string filename: modelData.split("/").pop()

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.3)
                            border.color: delegateRoot.isCurrent ? (root.theme.accentPrimary ?? "#7aa2f7") : (cardHover.hovered ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.25)) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                            border.width: delegateRoot.isCurrent ? 2 : 1
                            clip: true

                            HoverHandler { id: cardHover }

                            // Thumbnail Image
                            Image {
                                anchors.fill: parent
                                anchors.margins: delegateRoot.isCurrent ? 2 : 0
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 240
                                sourceSize.height: 150
                            }

                            // Dark gradient bar at bottom for filename label
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 26
                                color: Qt.rgba(0, 0, 0, 0.65)

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: delegateRoot.filename
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                }
                            }

                            // Active check badge
                            Rectangle {
                                visible: delegateRoot.isCurrent
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 48
                                height: 18
                                radius: 4
                                color: root.theme.accentPrimary ?? "#7aa2f7"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Active"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.wallpaperSelected(modelData);
                                    root.visible = false;
                                }
                            }
                        }
                    }
                }
            }

            // --- Footer ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: root.currentSelected !== "" ? ("Current: " + root.currentSelected.split("/").pop()) : "No wallpaper selected"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary ?? "#6c7086"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Text {
                    text: "Click any image to select • Press Esc to cancel"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary ?? "#6c7086"
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
