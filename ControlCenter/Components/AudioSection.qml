import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    // Track default devices safely
    PwObjectTracker {
        id: audioTracker
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    width: parent ? parent.width : 300
    height: audioCol.implicitHeight + 24
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1
    clip: true

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: audioCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        Text {
            text: "Volume"
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        // Speaker (Output)
        SpeakerControl {
            id: speakerControl
            Layout.fillWidth: true
            theme: root.theme
            font: root.font
            onDropdownToggled: (open) => {
                if (open) micControl.dropdownOpen = false;
            }
        }

        // Subtle Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
        }

        // Microphone (Input)
        MicControl {
            id: micControl
            Layout.fillWidth: true
            theme: root.theme
            font: root.font
            onDropdownToggled: (open) => {
                if (open) speakerControl.dropdownOpen = false;
            }
        }
    }
}
