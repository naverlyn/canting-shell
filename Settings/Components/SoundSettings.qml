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
import "./Sound"

Item {
    id: root
    property var theme
    property string font: "Lato Nerd Font"

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
        interactive: !(soundInputSectionInst.srcMouseRef && soundInputSectionInst.srcMouseRef.pressed)

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
            }

            // 1. OUTPUT GROUP
            SoundOutputSection {
                root: root
            }

            // 2. INPUT GROUP
            SoundInputSection {
                id: soundInputSectionInst
                root: root
            }

            // 3. VOLUME LEVELS (APPLICATION MIXER)
            SoundVolumeLevels {
                root: root
            }

            // 4. SYSTEM SOUNDS & ALERT EFFECTS
            SoundSystemSounds {
                root: root
            }

            // 5. ON-SCREEN DISPLAY (OSD) OVERLAY
            SoundOsdSection {
                root: root
            }
        }
    }
}

