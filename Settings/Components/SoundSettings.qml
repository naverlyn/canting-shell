/*
 * SoundSettings.qml
 *
 * GNOME-style grouped card layout for system sound controls.
 * Features:
 *   - Grouped Output & Input cards with row dividers
 *   - Device selector dropdown with inline Test button
 *   - Clean horizontal volume slider with mute icon
 *   - Powered natively by Quickshell.Services.Pipewire
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Item {
    id: root
    property var theme
    property string font

    /* Dropdown expansion states */
    property bool outputDropdownOpen: false
    property bool inputDropdownOpen: false

    /* PipeWire state and default device tracking */
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    PwObjectTracker {
        id: audioTracker
        objects: [root.defaultSink, root.defaultSource]
    }

    readonly property var audioSinks: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(node => node.audio !== null && !node.isStream && node.isSink);
    }

    readonly property var audioSources: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(node => node.audio !== null && !node.isStream && !node.isSink);
    }

    readonly property int sinkVolumePercent: (defaultSink && defaultSink.audio) 
        ? Math.round(defaultSink.audio.volume * 100) 
        : 0
    readonly property bool isSinkMuted: !defaultSink || !defaultSink.audio || defaultSink.audio.muted

    readonly property int sourceVolumePercent: (defaultSource && defaultSource.audio) 
        ? Math.round(defaultSource.audio.volume * 100) 
        : 0
    readonly property bool isSourceMuted: !defaultSource || !defaultSource.audio || defaultSource.audio.muted

    /* Helper functions */
    function setSinkVolumeFromMouse(mouseX, trackWidth) {
        if (defaultSink && defaultSink.audio && trackWidth > 0) {
            const fraction = Math.max(0, Math.min(1.0, mouseX / trackWidth));
            defaultSink.audio.volume = fraction;
        }
    }

    function toggleSinkMute() {
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.muted = !defaultSink.audio.muted;
        }
    }

    function setSourceVolumeFromMouse(mouseX, trackWidth) {
        if (defaultSource && defaultSource.audio && trackWidth > 0) {
            const fraction = Math.max(0, Math.min(1.0, mouseX / trackWidth));
            defaultSource.audio.volume = fraction;
        }
    }

    function toggleSourceMute() {
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.muted = !defaultSource.audio.muted;
        }
    }

    Process {
        id: testSoundProcess
        command: ["canberra-gtk-play", "-i", "bell"]
        running: false
    }

    /* Main Scrollable View */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Sound"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* Output Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Output"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: outputCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: outputCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Output Device & Test */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Output Device"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                /* Device Dropdown Selector Button */
                                Rectangle {
                                    id: sinkDropdownBtn
                                    width: 260
                                    height: 32
                                    radius: 6
                                    color: sinkDropHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.outputDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: sinkDropHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: root.defaultSink ? (root.defaultSink.description || root.defaultSink.name || "Default Output") : "No output device"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "󰅀"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textSecondary
                                            rotation: root.outputDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.outputDropdownOpen = !root.outputDropdownOpen
                                    }
                                }

                                /* Test Sound Button */
                                Rectangle {
                                    id: testBtn
                                    width: 58
                                    height: 32
                                    radius: 6
                                    color: testHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: testHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: testHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Test"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: testSoundProcess.running = true
                                    }
                                }
                            }
                        }

                        /* Expandable Output Devices Dropdown Menu */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.outputDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.audioSinks
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.defaultSink && root.defaultSink.id === modelData.id
                                    color: isSelected ? root.theme.bgSelected : (itemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: itemHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.description || modelData.name || "Output"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Pipewire.preferredDefaultAudioSink = modelData;
                                            root.outputDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Volume Slider */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                Text {
                                    text: "Volume"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.preferredWidth: 100
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                /* Slider Track */
                                Rectangle {
                                    id: sinkSliderTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * (root.sinkVolumePercent / 100)))
                                        color: root.theme.accentPrimary
                                    }

                                    Rectangle {
                                        width: sinkMouse.containsMouse || sinkMouse.pressed ? 16 : 14
                                        height: width
                                        radius: width / 2
                                        color: root.theme.accentPrimary
                                        border.color: root.theme.bgBase
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(sinkSliderTrack.width - width, (sinkSliderTrack.width * (root.sinkVolumePercent / 100)) - (width / 2)))

                                        Behavior on width { NumberAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: sinkMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: (mouse) => {
                                            if (pressed) root.setSinkVolumeFromMouse(mouse.x, width);
                                        }
                                        onClicked: (mouse) => root.setSinkVolumeFromMouse(mouse.x, width)
                                    }
                                }

                                /* Mute Icon / Percentage */
                                Rectangle {
                                    width: 32
                                    height: 28
                                    radius: 6
                                    color: muteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    HoverHandler { id: muteHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isSinkMuted ? "󰝟" : "󰕾"
                                        font.family: root.font
                                        font.pixelSize: 15
                                        color: root.isSinkMuted ? root.theme.accentRed : root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleSinkMute()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Input Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Input"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: inputCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: inputCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Input Device */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Input Device"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                /* Input Device Dropdown Selector Button */
                                Rectangle {
                                    id: srcDropdownBtn
                                    width: 326
                                    height: 32
                                    radius: 6
                                    color: srcDropHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.inputDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: srcDropHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: root.defaultSource ? (root.defaultSource.description || root.defaultSource.name || "Default Microphone") : "No input device"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "󰅀"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textSecondary
                                            rotation: root.inputDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.inputDropdownOpen = !root.inputDropdownOpen
                                    }
                                }
                            }
                        }

                        /* Expandable Input Devices Dropdown Menu */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.inputDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.audioSources
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.defaultSource && root.defaultSource.id === modelData.id
                                    color: isSelected ? root.theme.bgSelected : (srcItemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: srcItemHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.description || modelData.name || "Microphone"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Pipewire.preferredDefaultAudioSource = modelData;
                                            root.inputDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Input Volume Slider */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                Text {
                                    text: "Volume"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.preferredWidth: 100
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                /* Slider Track */
                                Rectangle {
                                    id: srcSliderTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * (root.sourceVolumePercent / 100)))
                                        color: root.theme.accentPrimary
                                    }

                                    Rectangle {
                                        width: srcMouse.containsMouse || srcMouse.pressed ? 16 : 14
                                        height: width
                                        radius: width / 2
                                        color: root.theme.accentPrimary
                                        border.color: root.theme.bgBase
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(srcSliderTrack.width - width, (srcSliderTrack.width * (root.sourceVolumePercent / 100)) - (width / 2)))

                                        Behavior on width { NumberAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: srcMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: (mouse) => {
                                            if (pressed) root.setSourceVolumeFromMouse(mouse.x, width);
                                        }
                                        onClicked: (mouse) => root.setSourceVolumeFromMouse(mouse.x, width)
                                    }
                                }

                                /* Mic Mute Icon */
                                Rectangle {
                                    width: 32
                                    height: 28
                                    radius: 6
                                    color: srcMuteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    HoverHandler { id: srcMuteHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isSourceMuted ? "󰍭" : "󰍬"
                                        font.family: root.font
                                        font.pixelSize: 15
                                        color: root.isSourceMuted ? root.theme.accentRed : root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleSourceMute()
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
