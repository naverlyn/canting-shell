import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: mediaGroup
    required property var root

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Media"
        font.family: mediaGroup.root.font
        font.pixelSize: 13
        font.bold: true
        color: mediaGroup.root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: mediaCol.implicitHeight + 16
        radius: 12
        color: mediaGroup.root.theme.bgSurface
        border.color: mediaGroup.root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: mediaCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            DefaultAppSelectorRow {
                theme: mediaGroup.root.theme
                font: mediaGroup.root.font
                title: "Video Player"
                currentValue: mediaGroup.root.currentVideo
                options: mediaGroup.root.videoOptions
                isOpen: mediaGroup.root.videoDropdownOpen
                onToggleRequested: {
                    if (!mediaGroup.root.videoDropdownOpen) mediaGroup.root.closeOtherDropdowns("video");
                    mediaGroup.root.videoDropdownOpen = !mediaGroup.root.videoDropdownOpen;
                }
                onOptionSelected: (desktopFile, optionData) => {
                    mediaGroup.root.setVideo(desktopFile, optionData);
                    mediaGroup.root.videoDropdownOpen = false;
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            DefaultAppSelectorRow {
                theme: mediaGroup.root.theme
                font: mediaGroup.root.font
                title: "Audio Player"
                currentValue: mediaGroup.root.currentAudio
                options: mediaGroup.root.audioOptions
                isOpen: mediaGroup.root.audioDropdownOpen
                onToggleRequested: {
                    if (!mediaGroup.root.audioDropdownOpen) mediaGroup.root.closeOtherDropdowns("audio");
                    mediaGroup.root.audioDropdownOpen = !mediaGroup.root.audioDropdownOpen;
                }
                onOptionSelected: (desktopFile, optionData) => {
                    mediaGroup.root.setAudio(desktopFile, optionData);
                    mediaGroup.root.audioDropdownOpen = false;
                }
            }
        }
    }
}
