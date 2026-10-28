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

Rectangle {
    id: cardRoot
    required property var root
    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 20
    radius: 12
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    readonly property string activeDisplayWallpaper: {
        if (WallpaperService.targetDisplay === "secondary") {
            return WallpaperService.wallpaperB || WallpaperService.currentWallpaper;
        } else if (WallpaperService.targetDisplay === "primary") {
            return WallpaperService.wallpaperA || WallpaperService.currentWallpaper;
        } else {
            return WallpaperService.currentWallpaper || WallpaperService.wallpaperA;
        }
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Top Row: Active Wallpaper Info & Quick Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Active wallpaper thumbnail preview
            Rectangle {
                Layout.preferredWidth: 116
                Layout.preferredHeight: 64
                radius: 6
                color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                clip: true
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Image {
                    anchors.fill: parent
                    source: cardRoot.activeDisplayWallpaper ? ("file://" + cardRoot.activeDisplayWallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 240
                    sourceSize.height: 140
                    asynchronous: true
                    cache: false
                }

                // Small badge showing which display's wallpaper is shown
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 4
                    height: 16
                    width: targetBadgeText.implicitWidth + 8
                    radius: 3
                    color: Qt.rgba(0, 0, 0, 0.65)
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Text {
                        id: targetBadgeText
                        anchors.centerIn: parent
                        text: {
                            if (!WallpaperService.hasMultipleMonitors) return "Active";
                            if (WallpaperService.targetDisplay === "all") return "All";
                            if (WallpaperService.targetDisplay === "secondary") return "Secondary";
                            return "Primary";
                        }
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
                        if (cardRoot.activeDisplayWallpaper) {
                            root.previewPath = cardRoot.activeDisplayWallpaper;
                        }
                    }
                }
            }

            // Metadata details
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: root.extractFilename(cardRoot.activeDisplayWallpaper)
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: cardRoot.activeDisplayWallpaper || "No background set"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        if (WallpaperService.generatingTheme) return "Extracting palette colors...";
                        const modeLabel = (WallpaperService.resizeMode === "fit") ? "Fit"
                            : (WallpaperService.resizeMode === "stretch") ? "Stretch"
                            : (WallpaperService.resizeMode === "no") ? "Center" : "Fill";
                        const syncDesc = WallpaperService.autoSyncPalette
                            ? "Colors synced via " + (WallpaperService.backend || "wallust")
                            : "Color sync disabled";
                        return syncDesc + " · Mode: " + modeLabel;
                    }
                    font.family: root.font
                    font.pixelSize: 10
                    color: WallpaperService.generatingTheme ? root.theme.accentPrimary : root.theme.textMuted
                }
            }

            // Action buttons & Sync toggle
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                // Random & Rescan buttons
                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        implicitWidth: randBtnText.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: randHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        HoverHandler { id: randHover }

                        Text {
                            id: randBtnText
                            anchors.centerIn: parent
                            text: "Random"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectRandomWallpaper()
                        }
                    }

                    Rectangle {
                        implicitWidth: rescanBtnText.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: rescanHov.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        HoverHandler { id: rescanHov }

                        Text {
                            id: rescanBtnText
                            anchors.centerIn: parent
                            text: "Rescan"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.rescan()
                        }
                    }
                }

                // Subtle Divider
                Rectangle {
                    width: 1
                    height: 24
                    color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                }

                // Sync Theme Toggle
                MouseArea {
                    id: syncToggleArea
                    implicitWidth: syncToggleRow.implicitWidth
                    implicitHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperService.setAutoSync(!WallpaperService.autoSyncPalette)

                    RowLayout {
                        id: syncToggleRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        ColumnLayout {
                            spacing: 1
                            Layout.alignment: Qt.AlignRight

                            Text {
                                text: "Sync Theme"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.alignment: Qt.AlignRight
                            }

                            Text {
                                text: WallpaperService.autoSyncPalette ? "Active palette" : "Disabled"
                                font.family: root.font
                                font.pixelSize: 9
                                color: WallpaperService.autoSyncPalette ? root.theme.accentPrimary : root.theme.textSecondary
                                Layout.alignment: Qt.AlignRight
                            }
                        }

                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: WallpaperService.autoSyncPalette ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: WallpaperService.autoSyncPalette ? parent.width - width - 3 : 3
                                color: WallpaperService.autoSyncPalette ? "#ffffff" : (root.theme.textPrimary ?? "#c0caf5")

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                        }
                    }
                }
            }
        }

        // Horizontal Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        }

        // Bottom Row: Target Display Selector (when multi-monitor) & Wallpaper Type Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Target Display Selector (only when multiple monitors are connected!)
            RowLayout {
                visible: WallpaperService.hasMultipleMonitors
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Display:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Rectangle {
                    id: dispSegmentTrack
                    implicitWidth: Math.max(260, dispSegRow.implicitWidth + 8)
                    height: 30
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1
                    clip: true

                    readonly property var options: WallpaperService.displayOptions
                    readonly property int count: options ? options.length : 0
                    readonly property int activeIdx: {
                        if (!options || options.length === 0) return 0;
                        for (let i = 0; i < options.length; i++) {
                            if (WallpaperService.targetDisplay === options[i].id || WallpaperService.targetDisplay === options[i].target) {
                                return i;
                            }
                        }
                        return 0;
                    }
                    readonly property real cellWidth: count > 0 ? (width - 6 - ((count - 1) * 4)) / count : width

                    Rectangle {
                        id: dispSegmentThumb
                        y: 3
                        height: parent.height - 6
                        width: dispSegmentTrack.cellWidth
                        x: 3 + dispSegmentTrack.activeIdx * (dispSegmentTrack.cellWidth + 4)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        id: dispSegRow
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        Repeater {
                            model: dispSegmentTrack.options

                            delegate: Rectangle {
                                id: dispSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: dispSegmentTrack.activeIdx === index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && dispSegHover.hovered ? root.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: dispSegHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: dispSegBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: dispSegBtn.isSel
                                    color: dispSegBtn.isSel ? root.theme.textPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WallpaperService.targetDisplay = dispSegBtn.modelData.target || dispSegBtn.modelData.id;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Single monitor indicator (when only 1 monitor is connected)
            RowLayout {
                visible: !WallpaperService.hasMultipleMonitors
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Display:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Rectangle {
                    height: 26
                    implicitWidth: singleDispText.implicitWidth + 16
                    radius: 5
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    Text {
                        id: singleDispText
                        anchors.centerIn: parent
                        text: "Primary · " + WallpaperService.displayAName
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Wallpaper Type Selector (segmented sliding pill style, text only!)
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: typeSegmentTrack
                    implicitWidth: 260
                    height: 30
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1
                    clip: true

                    readonly property var typeList: ["crop", "fit", "stretch", "no"]
                    readonly property int activeIdx: {
                        const m = (WallpaperService.resizeMode === "scale" || WallpaperService.resizeMode === "fill") ? "crop"
                                : (WallpaperService.resizeMode === "center" ? "no" : WallpaperService.resizeMode);
                        const idx = typeList.indexOf(m);
                        return idx !== -1 ? idx : 0;
                    }
                    readonly property real cellWidth: (width - 6 - (3 * 4)) / 4

                    Rectangle {
                        id: typeSegmentThumb
                        y: 3
                        height: parent.height - 6
                        width: typeSegmentTrack.cellWidth
                        x: 3 + typeSegmentTrack.activeIdx * (typeSegmentTrack.cellWidth + 4)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "Fill",    value: "crop" },
                                { label: "Fit",     value: "fit" },
                                { label: "Stretch", value: "stretch" },
                                { label: "Center",  value: "no" }
                            ]

                            delegate: Rectangle {
                                id: typeSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: typeSegmentTrack.activeIdx === index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && typeSegHover.hovered ? root.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: typeSegHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: typeSegBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: typeSegBtn.isSel
                                    color: typeSegBtn.isSel ? root.theme.textPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WallpaperService.setWallpaperType(typeSegBtn.modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
