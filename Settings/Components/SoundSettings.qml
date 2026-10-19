/*
 * SoundSettings.qml
 *
 * Grouped preferences for system audio output & input routing, stereo balance,
 * speaker channel testing, per-application audio mixer, and system alert sounds.
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwActionRow).
 *
 * Strictly text-only UI (no icons or glyphs), with tactile slider balls and smooth micro-animations.
 * Standardized button metrics (32px height, 80px width for row actions, 90px for dual test buttons).
 * Powered natively by Quickshell.Services.Pipewire & Quickshell.Io.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../osd"
import ".."

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    /* Standardized button dimensions */
    readonly property int btnHeight: 32
    readonly property int actionBtnWidth: 80
    readonly property int dualBtnWidth: 90
    readonly property int btnRadius: 6
    readonly property int labelColWidth: 120

    /* Dropdown expansion states */
    property bool outputDropdownOpen: false
    property bool inputDropdownOpen: false

    /* Alert sound selection */
    property string selectedAlertSound: "bell"

    /* PipeWire state and default device tracking */
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    /* Active application audio streams (apps outputting sound) */
    readonly property var appStreams: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(node => {
            if (!node || !node.isStream || !node.audio) return false;
            const name = (node.name || "").toLowerCase();
            const desc = (node.description || "").toLowerCase();
            if (name.includes("monitor") || desc.includes("monitor")) return false;

            const props = node.properties || {};
            const bin = String(props["application.process.binary"] || "").toLowerCase();
            const app = String(props["application.name"] || "").toLowerCase();
            const role = String(props["media.role"] || "").toLowerCase();
            const mediaName = String(props["media.name"] || "").toLowerCase();

            // Exclude system alert, test, and notification event streams
            if (role === "event" || role === "test" || role === "alert") return false;
            if (bin.includes("canberra") || app.includes("canberra") || name.includes("canberra") || desc.includes("canberra")) return false;
            if (bin.includes("pw-play") || bin.includes("paplay") || bin.includes("aplay") || bin.includes("speaker-test")) return false;
            if (bin.includes("speech-dispatcher") || app.includes("speech-dispatcher")) return false;
            if (mediaName.includes("bell") || mediaName.includes("audio-channel")) return false;

            return true;
        });
    }

    PwObjectTracker {
        id: audioTracker
        objects: {
            let list = [root.defaultSink, root.defaultSource].filter(Boolean);
            if (root.appStreams && root.appStreams.length > 0) {
                list = list.concat(root.appStreams);
            }
            return list;
        }
    }

    readonly property var audioSinks: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(node => node && node.audio !== null && !node.isStream && node.isSink);
    }

    readonly property var audioSources: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(node => node && node.audio !== null && !node.isStream && !node.isSink);
    }

    readonly property real currentSinkMasterVolume: {
        if (!defaultSink || !defaultSink.audio) return 0.0;
        if (defaultSink.audio.volumes && defaultSink.audio.volumes.length >= 2) {
            return Math.max(defaultSink.audio.volumes[0], defaultSink.audio.volumes[1]);
        }
        return defaultSink.audio.volume;
    }

    readonly property int sinkVolumePercent: Math.round(currentSinkMasterVolume * 100)
    readonly property bool isSinkMuted: !defaultSink || !defaultSink.audio || defaultSink.audio.muted

    readonly property int sourceVolumePercent: (defaultSource && defaultSource.audio) 
        ? Math.round(defaultSource.audio.volume * 100) 
        : 0
    readonly property bool isSourceMuted: !defaultSource || !defaultSource.audio || defaultSource.audio.muted

    /* Balance state (-1.0 Left to +1.0 Right) */
    property real balance: 0.0
    property real balanceDragBaseVol: 1.0
    property bool isDraggingBalance: false

    Connections {
        target: (root.defaultSink && root.defaultSink.audio) ? root.defaultSink.audio : null
        function onVolumesChanged() {
            if (!root.isDraggingBalance) {
                root.readBalanceFromSink();
            }
        }
        function onVolumeChanged() {
            if (!root.isDraggingBalance) {
                root.readBalanceFromSink();
            }
        }
    }

    onDefaultSinkChanged: {
        root.readBalanceFromSink();
    }

    function readBalanceFromSink() {
        if (!defaultSink || !defaultSink.audio || !defaultSink.audio.volumes || defaultSink.audio.volumes.length < 2) {
            return;
        }
        const vl = defaultSink.audio.volumes[0];
        const vr = defaultSink.audio.volumes[1];
        const maxV = Math.max(vl, vr);
        if (maxV <= 0.001) {
            root.balance = 0.0;
            return;
        }
        if (vl > vr) {
            root.balance = -(1.0 - (vr / maxV));
        } else if (vr > vl) {
            root.balance = (1.0 - (vl / maxV));
        } else {
            root.balance = 0.0;
        }
    }

    function setBalance(bal) {
        root.balance = Math.max(-1.0, Math.min(1.0, bal));
        if (!defaultSink || !defaultSink.audio) return;
        
        let baseVol = root.isDraggingBalance ? root.balanceDragBaseVol : root.currentSinkMasterVolume;
        if (baseVol <= 0.001) {
            baseVol = defaultSink.audio.volume;
        }
        if (baseVol <= 0.001) {
            baseVol = 0.5;
        }

        let lMult = 1.0;
        let rMult = 1.0;
        if (root.balance < 0) {
            rMult = Math.max(0.0, 1.0 + root.balance);
        } else if (root.balance > 0) {
            lMult = Math.max(0.0, 1.0 - root.balance);
        }
        try {
            if (defaultSink.audio.volumes && defaultSink.audio.volumes.length >= 2) {
                defaultSink.audio.volumes = [baseVol * lMult, baseVol * rMult];
            } else {
                defaultSink.audio.volume = baseVol;
            }
        } catch(e) {
            // Channel volumes setter fallback
        }
    }

    /* Helper functions for volume controls */
    function setSinkVolumeFromMouse(mouseX, trackWidth) {
        if (defaultSink && defaultSink.audio && trackWidth > 0) {
            const fraction = Math.max(0, Math.min(1.0, mouseX / trackWidth));
            root.balanceDragBaseVol = fraction;
            let lMult = 1.0;
            let rMult = 1.0;
            if (root.balance < 0) {
                rMult = Math.max(0.0, 1.0 + root.balance);
            } else if (root.balance > 0) {
                lMult = Math.max(0.0, 1.0 - root.balance);
            }
            try {
                if (defaultSink.audio.volumes && defaultSink.audio.volumes.length >= 2) {
                    defaultSink.audio.volumes = [fraction * lMult, fraction * rMult];
                } else {
                    defaultSink.audio.volume = fraction;
                }
            } catch(e) {
                defaultSink.audio.volume = fraction;
            }
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

    function getStreamAppName(node) {
        if (!node) return "Application";
        if (node.properties) {
            if (node.properties["application.name"]) return String(node.properties["application.name"]);
            if (node.properties["application.process.binary"]) return String(node.properties["application.process.binary"]);
            if (node.properties["media.name"]) return String(node.properties["media.name"]);
            if (node.properties["node.description"]) return String(node.properties["node.description"]);
        }
        if (node.description && node.description.length > 0) return node.description;
        if (node.name && node.name.length > 0) return node.name;
        return "Audio Stream";
    }

    /* Process for sound playback */
    Process {
        id: soundPlayProcess
        running: false
    }

    function playSound(soundId) {
        soundPlayProcess.command = ["canberra-gtk-play", "-i", soundId];
        soundPlayProcess.running = false;
        soundPlayProcess.running = true;
    }

    /* Main Scrollable View */
    Flickable {
        id: soundFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !sinkMouse.pressed && !balMouse.pressed && !srcMouse.pressed

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 24

            /* Page Title & Subtitle */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Sound"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Manage audio routing, stereo balance, channel tests, and application volume levels"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }

            /* ========================================================= */
            /* 1. OUTPUT GROUP                                            */
            /* ========================================================= */
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

                        /* Row 1: Output Device Selector */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Output Device"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.defaultSink ? (root.defaultSink.description || root.defaultSink.name || "Default Output") : "No output device available"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Standardized Expand / Change Button */
                                Rectangle {
                                    id: sinkChangeBtn
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: root.outputDropdownOpen 
                                        ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)) 
                                        : (sinkChangeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                                    border.color: root.outputDropdownOpen 
                                        ? root.theme.accentPrimary 
                                        : (sinkChangeHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: sinkChangeHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.outputDropdownOpen ? "Done" : "Change"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.outputDropdownOpen ? root.theme.accentPrimary : root.theme.textPrimary
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
                            }
                        }

                        /* Expandable Output Devices List */
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

                            Column {
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
                                        width: parent ? parent.width : 0
                                        height: 38
                                        radius: root.btnRadius
                                        readonly property bool isSelected: Boolean(modelData && root.defaultSink && root.defaultSink.id === modelData.id)
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
                                                text: modelData ? (modelData.description || modelData.name || "Output Device") : "Output Device"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: isSelected
                                                color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            /* Text Badge: Current */
                                            Rectangle {
                                                visible: isSelected
                                                implicitWidth: currentSinkLabel.implicitWidth + 14
                                                height: 22
                                                radius: 4
                                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                                                border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                                                border.width: 1

                                                Text {
                                                    id: currentSinkLabel
                                                    anchors.centerIn: parent
                                                    text: "Current"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData) Pipewire.preferredDefaultAudioSink = modelData;
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

                        /* Row 2: Master Volume Slider & Mute Toggle */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.preferredWidth: root.labelColWidth
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
                                    Layout.preferredHeight: 6
                                    implicitHeight: 6
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * (root.sinkVolumePercent / 100)))
                                        color: root.isSinkMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                    }

                                    // Outer halo ring on hover/press
                                    Rectangle {
                                        anchors.centerIn: sinkKnob
                                        width: sinkKnob.width + (sinkMouse.pressed ? 8 : (sinkMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, sinkMouse.pressed ? 0.35 : (sinkMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: sinkKnob
                                        width: sinkMouse.containsMouse || sinkMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.isSinkMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(sinkSliderTrack.width - width, (sinkSliderTrack.width * (root.sinkVolumePercent / 100)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            enabled: !sinkMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        id: sinkMouse
                                        anchors.fill: parent
                                        anchors.topMargin: -8
                                        anchors.bottomMargin: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            root.setSinkVolumeFromMouse(mouse.x, sinkSliderTrack.width);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                root.setSinkVolumeFromMouse(mouse.x, sinkSliderTrack.width);
                                            }
                                        }
                                    }
                                }

                                /* Standardized Text Mute Pill Button */
                                Rectangle {
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: root.isSinkMuted 
                                        ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                                        : (muteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                                    border.color: root.isSinkMuted 
                                        ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                                        : (muteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: muteHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isSinkMuted ? "Muted" : "Mute"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
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

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 3: Stereo Balance Slider */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.preferredWidth: root.labelColWidth
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        text: "Balance"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: Math.abs(root.balance) < 0.04 
                                            ? "Balanced" 
                                            : (root.balance < 0 ? ("Left " + Math.round(-root.balance * 100) + "%") : ("Right " + Math.round(root.balance * 100) + "%"))
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Math.abs(root.balance) < 0.04 ? root.theme.textSecondary : root.theme.accentPrimary
                                    }
                                }

                                /* Balance Slider Track */
                                Rectangle {
                                    id: balTrack
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 6
                                    implicitHeight: 6
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    // Center detent notch
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 2
                                        height: 12
                                        radius: 1
                                        color: Qt.rgba(1, 1, 1, 0.25)
                                    }

                                    // Visual balance fill from center
                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        property real normPos: (root.balance + 1.0) / 2.0
                                        x: root.balance < 0 ? (balTrack.width * normPos) : (balTrack.width * 0.5)
                                        width: Math.abs((balTrack.width * normPos) - (balTrack.width * 0.5))
                                        color: root.theme.accentPrimary
                                    }

                                    // Outer halo ring
                                    Rectangle {
                                        anchors.centerIn: balKnob
                                        width: balKnob.width + (balMouse.pressed ? 8 : (balMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, balMouse.pressed ? 0.35 : (balMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: balKnob
                                        width: balMouse.containsMouse || balMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(balTrack.width - width, (balTrack.width * ((root.balance + 1.0) / 2.0)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            enabled: !balMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        id: balMouse
                                        anchors.fill: parent
                                        anchors.topMargin: -8
                                        anchors.bottomMargin: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            root.isDraggingBalance = true;
                                            root.balanceDragBaseVol = (root.currentSinkMasterVolume > 0.001)
                                                ? root.currentSinkMasterVolume 
                                                : (defaultSink && defaultSink.audio && defaultSink.audio.volume > 0.001 ? defaultSink.audio.volume : 0.5);
                                            updateBalanceFromPos(mouse.x);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                updateBalanceFromPos(mouse.x);
                                            }
                                        }
                                        onReleased: {
                                            root.isDraggingBalance = false;
                                        }
                                        onCanceled: {
                                            root.isDraggingBalance = false;
                                        }
                                        function updateBalanceFromPos(mouseX) {
                                            if (balTrack.width > 0) {
                                                const frac = Math.max(0, Math.min(1.0, mouseX / balTrack.width));
                                                let bal = (frac * 2.0) - 1.0;
                                                // Center snapping: snap to 0.0 within 5% of center
                                                if (Math.abs(bal) < 0.05) bal = 0.0;
                                                root.setBalance(bal);
                                            }
                                        }
                                    }
                                }

                                /* Standardized Center Reset Button */
                                Rectangle {
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: centerHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                                    border.color: centerHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: centerHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Center"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setBalance(0.0)
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

                        /* Row 4: Stereo Speaker Channel Test */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Channel Test"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Verify stereo speaker channel positioning"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter

                                    /* Standardized Test Left Button */
                                    Rectangle {
                                        width: root.dualBtnWidth
                                        height: root.btnHeight
                                        radius: root.btnRadius
                                        color: leftTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                                        border.color: leftTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: leftTestHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Test Left"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.playSound("audio-channel-front-left")
                                        }
                                    }

                                    /* Standardized Test Right Button */
                                    Rectangle {
                                        width: root.dualBtnWidth
                                        height: root.btnHeight
                                        radius: root.btnRadius
                                        color: rightTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                                        border.color: rightTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: rightTestHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Test Right"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.playSound("audio-channel-front-right")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 2. INPUT GROUP                                             */
            /* ========================================================= */
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

                        /* Row 1: Input Device Selector */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Input Device"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.defaultSource ? (root.defaultSource.description || root.defaultSource.name || "Default Microphone") : "No input device available"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Standardized Expand / Change Button */
                                Rectangle {
                                    id: srcChangeBtn
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: root.inputDropdownOpen 
                                        ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)) 
                                        : (srcChangeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                                    border.color: root.inputDropdownOpen 
                                        ? root.theme.accentPrimary 
                                        : (srcChangeHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: srcChangeHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.inputDropdownOpen ? "Done" : "Change"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.inputDropdownOpen ? root.theme.accentPrimary : root.theme.textPrimary
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

                        /* Expandable Input Devices List */
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

                            Column {
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
                                        width: parent ? parent.width : 0
                                        height: 38
                                        radius: root.btnRadius
                                        readonly property bool isSelected: Boolean(modelData && root.defaultSource && root.defaultSource.id === modelData.id)
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
                                                text: modelData ? (modelData.description || modelData.name || "Microphone") : "Microphone"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: isSelected
                                                color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            /* Text Badge: Current */
                                            Rectangle {
                                                visible: isSelected
                                                implicitWidth: currentSrcLabel.implicitWidth + 14
                                                height: 22
                                                radius: 4
                                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                                                border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                                                border.width: 1

                                                Text {
                                                    id: currentSrcLabel
                                                    anchors.centerIn: parent
                                                    text: "Current"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData) Pipewire.preferredDefaultAudioSource = modelData;
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

                        /* Row 2: Input Volume Slider & Mute Toggle */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.preferredWidth: root.labelColWidth
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
                                    Layout.preferredHeight: 6
                                    implicitHeight: 6
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * (root.sourceVolumePercent / 100)))
                                        color: root.isSourceMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                    }

                                    // Outer halo ring
                                    Rectangle {
                                        anchors.centerIn: srcKnob
                                        width: srcKnob.width + (srcMouse.pressed ? 8 : (srcMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, srcMouse.pressed ? 0.35 : (srcMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: srcKnob
                                        width: srcMouse.containsMouse || srcMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.isSourceMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(srcSliderTrack.width - width, (srcSliderTrack.width * (root.sourceVolumePercent / 100)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            enabled: !srcMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        id: srcMouse
                                        anchors.fill: parent
                                        anchors.topMargin: -8
                                        anchors.bottomMargin: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            root.setSourceVolumeFromMouse(mouse.x, srcSliderTrack.width);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                root.setSourceVolumeFromMouse(mouse.x, srcSliderTrack.width);
                                            }
                                        }
                                    }
                                }

                                /* Standardized Text Mute Pill Button */
                                Rectangle {
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: root.isSourceMuted 
                                        ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                                        : (srcMuteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                                    border.color: root.isSourceMuted 
                                        ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                                        : (srcMuteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: srcMuteHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isSourceMuted ? "Muted" : "Mute"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
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

            /* ========================================================= */
            /* 3. VOLUME LEVELS (APPLICATION MIXER)                       */
            /* ========================================================= */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Volume Levels"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.leftMargin: 4
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.appStreams.length > 0 ? (root.appStreams.length + (root.appStreams.length === 1 ? " application" : " applications")) : "No active streams"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.rightMargin: 4
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: streamCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Column {
                        id: streamCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Empty State when no apps are streaming */
                        Item {
                            visible: root.appStreams.length === 0
                            width: parent.width
                            height: visible ? 64 : 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "No applications currently playing audio"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "Streams will appear here automatically when apps produce sound"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        /* Active Audio Streams Repeater */
                        Repeater {
                            model: root.appStreams
                            delegate: Item {
                                width: streamCol.width > 0 ? streamCol.width : (parent ? parent.width : 0)
                                height: 53

                                readonly property var streamNode: modelData
                                readonly property bool isStreamMuted: !streamNode || !streamNode.audio || streamNode.audio.muted
                                readonly property int streamVolPct: (streamNode && streamNode.audio) ? Math.round(streamNode.audio.volume * 100) : 0

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 16

                                    ColumnLayout {
                                        Layout.preferredWidth: root.labelColWidth
                                        Layout.minimumWidth: root.labelColWidth
                                        Layout.maximumWidth: root.labelColWidth
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            text: root.getStreamAppName(streamNode)
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: isStreamMuted ? "Muted" : (streamVolPct + "%")
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: isStreamMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
                                        }
                                    }

                                    /* App Slider Track */
                                    Rectangle {
                                        id: appTrack
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 6
                                        implicitHeight: 6
                                        height: 6
                                        radius: 3
                                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1
                                        Layout.alignment: Qt.AlignVCenter

                                        // Active progress fill bar
                                        Rectangle {
                                            id: appFillBar
                                            height: parent.height
                                            radius: parent.radius
                                            width: Math.max(0, Math.min(parent.width, parent.width * (streamVolPct / 100)))
                                            color: isStreamMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                        }

                                        // Outer halo ring
                                        Rectangle {
                                            anchors.centerIn: appKnob
                                            width: appKnob.width + (appMouse.pressed ? 8 : (appMouse.containsMouse ? 6 : 0))
                                            height: width
                                            radius: width / 2
                                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, appMouse.pressed ? 0.35 : (appMouse.containsMouse ? 0.2 : 0))
                                            z: 1

                                            Behavior on width { NumberAnimation { duration: 120 } }
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }

                                        // Tactile white knob
                                        Rectangle {
                                            id: appKnob
                                            width: appMouse.containsMouse || appMouse.pressed ? 17 : 15
                                            height: width
                                            radius: width / 2
                                            color: "#ffffff"
                                            border.color: isStreamMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                            border.width: 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(appTrack.width - width, (appTrack.width * (streamVolPct / 100)) - (width / 2)))
                                            z: 2

                                            Behavior on width { NumberAnimation { duration: 120 } }
                                            Behavior on x {
                                                enabled: !appMouse.pressed
                                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        MouseArea {
                                            id: appMouse
                                            anchors.fill: parent
                                            anchors.topMargin: -8
                                            anchors.bottomMargin: -8
                                            preventStealing: true
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: (mouse) => {
                                                mouse.accepted = true;
                                                if (streamNode && streamNode.audio && appTrack.width > 0) {
                                                    const frac = Math.max(0, Math.min(1.0, mouse.x / appTrack.width));
                                                    streamNode.audio.volume = frac;
                                                }
                                            }
                                            onPositionChanged: (mouse) => {
                                                if (pressed && streamNode && streamNode.audio && appTrack.width > 0) {
                                                    mouse.accepted = true;
                                                    const frac = Math.max(0, Math.min(1.0, mouse.x / appTrack.width));
                                                    streamNode.audio.volume = frac;
                                                }
                                            }
                                        }
                                    }

                                    /* Standardized App Mute Pill Button */
                                    Rectangle {
                                        width: root.actionBtnWidth
                                        height: root.btnHeight
                                        radius: root.btnRadius
                                        color: isStreamMuted 
                                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                                            : (appMuteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                                        border.color: isStreamMuted 
                                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                                            : (appMuteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                        border.width: 1
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: appMuteHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: isStreamMuted ? "Muted" : "Mute"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: isStreamMuted ? root.theme.accentRed : root.theme.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (streamNode && streamNode.audio) {
                                                    streamNode.audio.muted = !streamNode.audio.muted;
                                                }
                                            }
                                        }
                                    }
                                }

                                /* Row Divider between streams */
                                Rectangle {
                                    visible: index < root.appStreams.length - 1
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    height: 1
                                    color: Qt.rgba(1, 1, 1, 0.05)
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 4. SYSTEM SOUNDS & ALERT EFFECTS                           */
            /* ========================================================= */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "System Sounds"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sysSoundsCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: sysSoundsCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Alert Sound Selector */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: root.labelColWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Alert Sound"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Theme event sound"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Sound Options Segmented Pill Track */
                                Rectangle {
                                    id: soundSegmentTrack
                                    implicitWidth: 440
                                    width: 440
                                    height: root.btnHeight
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property var soundOptions: [
                                        { id: "bell", label: "Bell" },
                                        { id: "dialog-information", label: "Information" },
                                        { id: "window-attention", label: "Attention" },
                                        { id: "message", label: "Message" },
                                        { id: "complete", label: "Complete" }
                                    ]
                                    readonly property int activeIdx: {
                                        for (let i = 0; i < soundOptions.length; i++) {
                                            if (soundOptions[i].id === root.selectedAlertSound) return i;
                                        }
                                        return 0;
                                    }
                                    readonly property real cellWidth: (width - 6 - ((soundOptions.length - 1) * 4)) / soundOptions.length

                                    // Animated sliding indicator
                                    Rectangle {
                                        y: 3
                                        height: parent.height - 6
                                        width: soundSegmentTrack.cellWidth
                                        x: 3 + soundSegmentTrack.activeIdx * (soundSegmentTrack.cellWidth + 4)
                                        radius: 5
                                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: soundSegmentTrack.soundOptions

                                            delegate: Rectangle {
                                                id: soundSegBtn
                                                required property var modelData
                                                readonly property bool isSel: root.selectedAlertSound === modelData.id

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && soundSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: soundSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: soundSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: soundSegBtn.isSel
                                                    color: soundSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: soundSegBtn.isSel || soundSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    preventStealing: true
                                                    onClicked: {
                                                        root.selectedAlertSound = soundSegBtn.modelData.id;
                                                        root.playSound(soundSegBtn.modelData.id);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                /* Standardized Play Alert Button */
                                Rectangle {
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: playAlertHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                                    border.color: playAlertHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: playAlertHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Play"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
                                        onClicked: root.playSound(root.selectedAlertSound)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 5. ON-SCREEN DISPLAY (OSD) OVERLAY                         */
            /* ========================================================= */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "On-Screen Display (OSD)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: "· Volume overlay position and placement"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Active: " + OSDService.getPositionLabel(OSDService.position)
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: osdGroupCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: osdGroupCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Position Selection */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: root.labelColWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Screen Position"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Overlay screen placement"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Position Segmented Pill Track */
                                Rectangle {
                                    id: osdPosSegmentTrack
                                    implicitWidth: 400
                                    width: 400
                                    height: root.btnHeight
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property var posList: ["left", "center", "right", "top", "bottom"]
                                    readonly property int activePosIndex: {
                                        const idx = posList.indexOf(OSDService.position);
                                        return idx !== -1 ? idx : 4;
                                    }
                                    readonly property real cellWidth: (width - 6 - ((OSDService.positionOptions.length - 1) * 4)) / OSDService.positionOptions.length

                                    // Animated sliding indicator
                                    Rectangle {
                                        y: 3
                                        height: parent.height - 6
                                        width: osdPosSegmentTrack.cellWidth
                                        x: 3 + osdPosSegmentTrack.activePosIndex * (osdPosSegmentTrack.cellWidth + 4)
                                        radius: 5
                                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: OSDService.positionOptions

                                            delegate: Rectangle {
                                                id: posSegBtn
                                                required property var modelData
                                                readonly property bool isSel: OSDService.position === modelData.id

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && posSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: posSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: posSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: posSegBtn.isSel
                                                    color: posSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    preventStealing: true
                                                    onClicked: {
                                                        OSDService.setPosition(posSegBtn.modelData.id);
                                                        OSDService.testOSD();
                                                    }
                                                }
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

                        /* Row 2: Test OSD */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: root.labelColWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Test Overlay"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Display active volume OSD"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: root.actionBtnWidth
                                    height: root.btnHeight
                                    radius: root.btnRadius
                                    color: testOsdHoverSound.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                                    border.color: testOsdHoverSound.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: testOsdHoverSound }

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
                                        preventStealing: true
                                        onClicked: OSDService.testOSD()
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

