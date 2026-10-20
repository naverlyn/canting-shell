import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: listContainer
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 180
    radius: 10
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
    border.width: 1
    clip: true

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler {
        id: listHover
        onHoveredChanged: {
            if (!hovered) {
                previewResetTimer.restart();
            }
        }
    }

    Timer {
        id: previewResetTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (!listHover.hovered) {
                root.theme.previewIndex = -1;
            }
        }
    }

    ListView {
        id: themeList
        anchors.fill: parent
        anchors.margins: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 2
        model: root.filteredThemes

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.2)
            }
        }

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index

            width: ListView.view.width - 6
            height: 40
            radius: 8

            readonly property bool isSelected: !root.theme.wallpaperMode && root.theme.currentIndex === modelData.originalIndex
            readonly property bool isPreviewing: root.theme.previewIndex === modelData.originalIndex

            color: isPreviewing
                   ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08))
                   : (isSelected
                      ? root.theme.bgSelected
                      : (hoverArea.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent"))

            Behavior on color { ColorAnimation { duration: 80 } }

            // Indicator bar on left edge
            Rectangle {
                width: 3
                height: 20
                radius: 2
                color: root.theme.accentPrimary
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: isSelected || isPreviewing
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                // Theme name
                Text {
                    text: delegateRoot.modelData.data.name
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: isSelected || isPreviewing
                    color: (isSelected || isPreviewing) ? root.theme.textPrimary : root.theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                    elide: Text.ElideRight
                    Layout.maximumWidth: 220
                }

                // Family tag
                Rectangle {
                    height: 16
                    radius: 4
                    implicitWidth: famTag.implicitWidth + 8
                    color: root.theme.bgBase
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: famTag
                        anchors.centerIn: parent
                        text: delegateRoot.modelData.data.family
                        font.family: root.font
                        font.pixelSize: 9
                        color: root.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Color swatches preview
                Row {
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: [
                            delegateRoot.modelData.data.bgBase,
                            delegateRoot.modelData.data.accentPrimary,
                            delegateRoot.modelData.data.accentGreen,
                            delegateRoot.modelData.data.accentOrange,
                            delegateRoot.modelData.data.accentRed
                        ]

                        Rectangle {
                            required property var modelData
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData
                            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                            border.width: 1
                        }
                    }
                }

                // Fixed-width checkmark slot so swatches always align
                Item {
                    width: 22
                    height: 22
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.accentGreen
                        visible: isSelected
                    }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: {
                    previewResetTimer.stop();
                    root.theme.previewIndex = delegateRoot.modelData.originalIndex;
                }
                onClicked: {
                    previewResetTimer.stop();
                    root.theme.previewIndex = -1;
                    root.theme.setTheme(delegateRoot.modelData.originalIndex);
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "No themes found matching \"" + root.searchText + "\""
            font.family: root.font
            font.pixelSize: 12
            color: root.theme.textMuted
            visible: themeList.count === 0
        }
    }
}
