/*
 * SoundSettings.qml
 *
 * Grouped preferences for system audio output & input routing and volume levels.
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwExpanderRow, AdwActionRow).
 *
 * Features:
 *   - Grouped Output & Input cards with row dividers (AdwPreferencesGroup style)
 *   - Polished inline expandable device selectors with smooth cubic animations (AdwExpanderRow style)
 *   - Inset sub-container styling for option lists matching GNOME nested rows
 *   - Clean horizontal volume sliders with mute icons (AdwActionRow with GtkScale)
 *   - Canberra sound bell test trigger
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
    property string font: "Hack Nerd Font"

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

            /* Output group */
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

                        /* Row 1: Output device & audio test */
                        Item {
                            Layout.fillWidth: true
                            height: 50

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

                                /* Device Selector Pill */
                                Rectangle {
                                    id: sinkDropdownBtn
                                    width: 260
                                    height: 32
                                    radius: 6
                                    color: root.outputDropdownOpen 
                                        ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                                        : (sinkDropHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04)))
                                    border.color: root.outputDropdownOpen ? root.theme.accentPrimary : (sinkDropHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)))
                                    border.width: root.outputDropdownOpen ? 1.5 : 1
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
                                            color: root.outputDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                                            rotation: root.outputDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.outputDropdownOpen) root.inputDropdownOpen = false;
                                            root.outputDropdownOpen = !root.outputDropdownOpen;
                                        }
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

                        // Expandable output devices list
                        Rectangle {
                            id: sinkExpandBox
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.bottomMargin: root.outputDropdownOpen ? 8 : 0
                            Layout.preferredHeight: root.outputDropdownOpen ? (sinkListCol.implicitHeight + 8) : 0
                            opacity: root.outputDropdownOpen ? 1.0 : 0.0
                            clip: true
                            radius: 8
                            color: Qt.rgba(0, 0, 0, 0.18)
                            border.color: root.outputDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            border.width: 1

                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                            Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

                            ColumnLayout {
                                id: sinkListCol
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 4
                                }
                                spacing: 2

                                Repeater {
                                    model: root.audioSinks
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 6
                                        readonly property bool isSelected: root.defaultSink && root.defaultSink.id === modelData.id
                                        color: isSelected 
                                            ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                                            : (itemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                        border.color: isSelected 
                                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3) 
                                            : "transparent"
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        Behavior on border.color { ColorAnimation { duration: 130 } }

                                        HoverHandler { id: itemHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 8

                                            Text {
                                                text: modelData.description || modelData.name || "Output"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: isSelected
                                                color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: isSelected
                                                text: "󰄬"
                                                font.family: root.font
                                                font.pixelSize: 13
                                                font.bold: true
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
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Volume slider & mute toggle */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        text: "Volume"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.isSinkMuted ? "Muted" : (root.sinkVolumePercent + "%")
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.isSinkMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
                                    }
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

            /* Input group */
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

                        /* Row 1: Input device selector */
                        Item {
                            Layout.fillWidth: true
                            height: 50

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
                                    color: root.inputDropdownOpen 
                                        ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                                        : (srcDropHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04)))
                                    border.color: root.inputDropdownOpen ? root.theme.accentPrimary : (srcDropHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)))
                                    border.width: root.inputDropdownOpen ? 1.5 : 1
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
                                            color: root.inputDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                                            rotation: root.inputDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.inputDropdownOpen) root.outputDropdownOpen = false;
                                            root.inputDropdownOpen = !root.inputDropdownOpen;
                                        }
                                    }
                                }
                            }
                        }

                        // Expandable input devices list
                        Rectangle {
                            id: srcExpandBox
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.bottomMargin: root.inputDropdownOpen ? 8 : 0
                            Layout.preferredHeight: root.inputDropdownOpen ? (srcListCol.implicitHeight + 8) : 0
                            opacity: root.inputDropdownOpen ? 1.0 : 0.0
                            clip: true
                            radius: 8
                            color: Qt.rgba(0, 0, 0, 0.18)
                            border.color: root.inputDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            border.width: 1

                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                            Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

                            ColumnLayout {
                                id: srcListCol
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 4
                                }
                                spacing: 2

                                Repeater {
                                    model: root.audioSources
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 6
                                        readonly property bool isSelected: root.defaultSource && root.defaultSource.id === modelData.id
                                        color: isSelected 
                                            ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                                            : (srcItemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                        border.color: isSelected 
                                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3) 
                                            : "transparent"
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        Behavior on border.color { ColorAnimation { duration: 130 } }

                                        HoverHandler { id: srcItemHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 8

                                            Text {
                                                text: modelData.description || modelData.name || "Microphone"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: isSelected
                                                color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: isSelected
                                                text: "󰄬"
                                                font.family: root.font
                                                font.pixelSize: 13
                                                font.bold: true
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
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Input volume slider & mic mute toggle */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        text: "Volume"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.isSourceMuted ? "Muted" : (root.sourceVolumePercent + "%")
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.isSourceMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
                                    }
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
