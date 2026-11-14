import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import Quickshell.Io
import Quickshell.Widgets
import "../../../AppLauncher"
import "../.."
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 2

    SectionCard {
        title: "Manage Installed Applications"
        subtitle: root.totalAppCount + " total apps • " + root.favoriteCount + " favorites • " + root.hiddenCount + " hidden"
        contentMargins: 12
        contentSpacing: 10

        // Search & Filter Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Search Input Box
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 7
                color: root.theme.bgBase
                border.color: appSearchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: root.font
                        font.pixelSize: 13
                        color: appSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
                    }

                    TextInput {
                        id: appSearchInput
                        Layout.fillWidth: true
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        clip: true
                        selectByMouse: true
                        text: root.appSearchQuery
                        onTextChanged: root.appSearchQuery = text

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.text && !parent.activeFocus
                            text: "Filter applications by name, class, or generic tag..."
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textMuted
                        }
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: clearSearchHover.hovered ? root.theme.bgHover : "transparent"
                        visible: appSearchInput.text.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }

                        HoverHandler { id: clearSearchHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appSearchInput.text = ""
                        }
                    }
                }
            }

            // Filter Segmented Track: All / Favorites / Hidden
            Rectangle {
                id: appFilterSegmentTrack
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 290
                height: 36
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property var filterModes: ["all", "favorites", "hidden"]
                readonly property int activeIdx: Math.max(0, filterModes.indexOf(root.appFilterMode))
                readonly property real cellWidth: (width - 6 - 2 * 3) / 3

                /* Sliding Selection Pill */
                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: appFilterSegmentTrack.cellWidth
                    x: 3 + appFilterSegmentTrack.activeIdx * (appFilterSegmentTrack.cellWidth + 3)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { id: "all",       label: "All (" + root.totalAppCount + ")" },
                            { id: "favorites", label: "Favorites (" + root.favoriteCount + ")" },
                            { id: "hidden",    label: "Hidden (" + root.hiddenCount + ")" }
                        ]
                        delegate: Rectangle {
                            id: filterSegBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: appFilterSegmentTrack.activeIdx === filterSegBtn.index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && filterSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: filterSegHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.appFilterMode = filterSegBtn.modelData.id
                            }

                            Text {
                                anchors.centerIn: parent
                                text: filterSegBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: filterSegBtn.isSel
                                color: filterSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: filterSegBtn.isSel || filterSegHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }
                        }
                    }
                }
            }
        }

        // App List View Box
        Rectangle {
            Layout.fillWidth: true
            height: 440
            radius: 8
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            ListView {
                id: appListView
                anchors.fill: parent
                anchors.margins: 4
                model: root.filteredAppsList
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: root.theme.bgBorder
                    }
                }

                // Empty state placeholder
                Item {
                    anchors.centerIn: parent
                    visible: appListView.count === 0
                    width: 260
                    height: 100

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰀻"
                            font.family: root.font
                            font.pixelSize: 32
                            color: root.theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.appSearchQuery ? "No applications found" : "No applications in this category"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textSecondary
                        }
                    }
                }

                delegate: Rectangle {
                    id: appRowItem
                    required property var modelData
                    readonly property string appKey: root.getAppKey(modelData)
                    readonly property bool isFav: AppLauncherConfig.isAppFavorite(appKey)
                    readonly property bool isHid: AppLauncherConfig.isAppHidden(appKey)

                    width: appListView.width - 8
                    height: 48
                    radius: 6
                    color: appRowHover.hovered ? root.theme.bgHover : "transparent"
                    opacity: isHid ? 0.55 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    HoverHandler { id: appRowHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // App Icon
                        Rectangle {
                            id: appIconBox
                            width: 32
                            height: 32
                            radius: 6
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            readonly property string resolvedIcon: {
                                const raw = (appRowItem.modelData && appRowItem.modelData.icon) ? appRowItem.modelData.icon : "";
                                if (raw) {
                                    const p = Quickshell.iconPath(raw, true);
                                    if (p) return p;
                                }
                                return Quickshell.iconPath("application-x-executable", true);
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 22
                                source: appIconBox.resolvedIcon
                                visible: appIconBox.resolvedIcon !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰀻"
                                font.family: root.font
                                font.pixelSize: 16
                                color: root.theme.accentPrimary
                                visible: appIconBox.resolvedIcon === ""
                            }
                        }

                        // App Titles
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                Layout.alignment: Qt.AlignLeft
                                spacing: 6
                                Text {
                                    text: (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Unknown Application"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: isHid ? root.theme.textMuted : root.theme.textPrimary
                                }

                                // Favorite Badge
                                Rectangle {
                                    visible: appRowItem.isFav
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    color: Qt.rgba(1, 0.8, 0.2, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰓎"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.accentOrange
                                    }
                                }

                                // Hidden Badge
                                Rectangle {
                                    visible: appRowItem.isHid
                                    implicitWidth: hiddenBadgeText.implicitWidth + 8
                                    implicitHeight: 16
                                    radius: 4
                                    color: Qt.rgba(0.9, 0.3, 0.3, 0.15)
                                    Text {
                                        id: hiddenBadgeText
                                        anchors.centerIn: parent
                                        text: "Hidden"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: root.theme.accentRed
                                    }
                                }
                            }

                            Text {
                                text: {
                                    let sub = (appRowItem.modelData && appRowItem.modelData.genericName) ? appRowItem.modelData.genericName : "";
                                    if (!sub && appRowItem.appKey) sub = appRowItem.appKey;
                                    return sub;
                                }
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Action Buttons: Favorite Star & Hide Eye
                        RowLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            // Toggle Favorite Button
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 6
                                color: appRowItem.isFav
                                    ? Qt.rgba(1, 0.8, 0.2, 0.2)
                                    : (favHover.hovered ? root.theme.bgSurface : "transparent")
                                border.color: appRowItem.isFav ? root.theme.accentOrange : (favHover.hovered ? root.theme.bgBorder : "transparent")
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 120 } }

                                HoverHandler { id: favHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AppLauncherConfig.toggleFavoriteApp(appRowItem.appKey);
                                        const isNowFav = AppLauncherConfig.isAppFavorite(appRowItem.appKey);
                                        const appName = (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Application";
                                        root.showToast(isNowFav ? (appName + " pinned to favorites") : (appName + " unpinned from favorites"));
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: appRowItem.isFav ? "󰓎" : "󰤱"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: appRowItem.isFav ? root.theme.accentOrange : (favHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
                                }
                            }

                            // Toggle Hide/Unhide Button
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 6
                                color: appRowItem.isHid
                                    ? Qt.rgba(0.9, 0.3, 0.3, 0.15)
                                    : (hidHover.hovered ? root.theme.bgSurface : "transparent")
                                border.color: appRowItem.isHid ? root.theme.accentRed : (hidHover.hovered ? root.theme.bgBorder : "transparent")
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 120 } }

                                HoverHandler { id: hidHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AppLauncherConfig.toggleHiddenApp(appRowItem.appKey);
                                        const isNowHidden = AppLauncherConfig.isAppHidden(appRowItem.appKey);
                                        const appName = (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Application";
                                        root.showToast(isNowHidden ? (appName + " hidden from launcher") : (appName + " restored to launcher"));
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: appRowItem.isHid ? "󰈈" : "󰈉"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: appRowItem.isHid ? root.theme.accentRed : (hidHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
