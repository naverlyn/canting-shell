import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."

ColumnLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"
    property bool dropdownOpen: false

    signal dropdownToggled(bool open)

    readonly property var audioSinks: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(n => n && n.audio !== null && !n.isStream && n.isSink);
    }

    spacing: 6

    Text {
        text: "Speaker"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
        Layout.fillWidth: true
    }

    function getSinkVolume(sink) {
        if (!sink || !sink.audio) return 0.0;
        if (sink.audio.volumes && sink.audio.volumes.length >= 2) {
            return Math.max(sink.audio.volumes[0], sink.audio.volumes[1]);
        }
        return sink.audio.volume;
    }

    // Slider Row: Mute Button + Slider + Percentage
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            width: 28
            height: 28
            radius: 7
            readonly property bool isMuted: !Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio || Pipewire.defaultAudioSink.audio.muted
            color: isMuted 
                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                : (sinkMuteMouse.containsMouse 
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06))
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: parent.isMuted ? "󰝟" : "󰕾"
                font.family: root.font
                font.pixelSize: 15
                color: parent.isMuted 
                    ? root.theme.accentRed 
                    : root.theme.textPrimary
            }

            MouseArea {
                id: sinkMuteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const sink = Pipewire.defaultAudioSink;
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
                }
            }
        }

        Rectangle {
            id: sinkSliderBg
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18)

            Rectangle {
                id: sinkSliderFill
                height: parent.height
                radius: 4
                width: {
                    const sink = Pipewire.defaultAudioSink;
                    if (!sink || !sink.audio) return 0;
                    return Math.min(parent.width, parent.width * root.getSinkVolume(sink));
                }
                color: root.theme.accentPrimary

                Behavior on width {
                    enabled: !sinkSliderMouse.pressed
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                y: (parent.height - height) / 2
                x: Math.max(0, Math.min(sinkSliderBg.width - width, sinkSliderFill.width - (width / 2)))
                color: root.theme.textPrimary
            }

            MouseArea {
                id: sinkSliderMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => updateVolume(mouse.x, width)
                onPositionChanged: (mouse) => {
                    if (pressed) updateVolume(mouse.x, width);
                }

                function updateVolume(mouseX, totalWidth) {
                    const sink = Pipewire.defaultAudioSink;
                    if (sink && sink.audio && totalWidth > 0) {
                        const newVol = Math.max(0, Math.min(1.0, mouseX / totalWidth));
                        if (sink.audio.volumes && sink.audio.volumes.length >= 2) {
                            const vl = sink.audio.volumes[0];
                            const vr = sink.audio.volumes[1];
                            const maxV = Math.max(vl, vr);
                            if (maxV > 0.001) {
                                sink.audio.volumes = [newVol * (vl / maxV), newVol * (vr / maxV)];
                            } else {
                                sink.audio.volumes = [newVol, newVol];
                            }
                        } else {
                            sink.audio.volume = newVol;
                        }
                        if (sink.audio.muted) sink.audio.muted = false;
                    }
                }
            }
        }

        Text {
            text: {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return "0%";
                return sink.audio.muted ? "Muted" : Math.round(root.getSinkVolume(sink) * 100) + "%";
            }
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textSecondary
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Output Device Selector Pill
    Rectangle {
        Layout.fillWidth: true
        height: 30
        radius: 7
        color: root.dropdownOpen
            ? root.theme.bgSelected
            : (sinkSelectorMouse.containsMouse 
                ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) 
                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04))
        border.color: root.dropdownOpen 
            ? root.theme.accentPrimary 
            : root.theme.bgBorder
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "󰓃"
                font.family: root.font
                font.pixelSize: 13
                color: root.dropdownOpen 
                    ? root.theme.textPrimary 
                    : root.theme.textMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: {
                    const sink = Pipewire.defaultAudioSink;
                    return (sink && (sink.description || sink.nickname || sink.name))
                        ? (sink.description || sink.nickname || sink.name)
                        : "Output Device";
                }
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: "󰅀"
                font.family: root.font
                font.pixelSize: 14
                color: root.theme.textMuted
                rotation: root.dropdownOpen ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: sinkSelectorMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.dropdownOpen = !root.dropdownOpen;
                root.dropdownToggled(root.dropdownOpen);
            }
        }
    }

    // Expandable Output Devices List
    Rectangle {
        id: sinkDropdownBox
        Layout.fillWidth: true
        Layout.preferredHeight: root.dropdownOpen ? (sinkListCol.implicitHeight + 12) : 0
        opacity: root.dropdownOpen ? 1.0 : 0.0
        visible: Layout.preferredHeight > 0
        clip: true
        radius: 8
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: root.dropdownOpen ? 1 : 0

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

        Column {
            id: sinkListCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 6
            }
            spacing: 4

            Text {
                text: "No output devices found"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
                visible: root.audioSinks.length === 0
                padding: 6
            }

            Repeater {
                model: root.audioSinks

                delegate: Rectangle {
                    id: sinkItemRect
                    readonly property bool isSelected: Boolean(modelData && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id)
                    width: parent ? parent.width : 0
                    height: 30
                    radius: 6
                    scale: sinkItemMouse.pressed ? 0.98 : 1.0
                    color: isSelected
                        ? root.theme.bgSelected
                        : (sinkItemMouse.containsMouse 
                            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) 
                            : "transparent")

                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: sinkItemRect.isSelected ? "󰄬" : "󰝥"
                            font.family: root.font
                            font.pixelSize: sinkItemRect.isSelected ? 13 : 8
                            color: sinkItemRect.isSelected 
                                ? root.theme.accentPrimary 
                                : root.theme.textMuted
                            Layout.preferredWidth: 14
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: modelData ? (modelData.description || modelData.nickname || modelData.name || "Audio Output") : "Audio Output"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: sinkItemRect.isSelected
                            color: sinkItemRect.isSelected 
                                ? root.theme.textPrimary 
                                : root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: sinkItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData) Pipewire.preferredDefaultAudioSink = modelData;
                            root.dropdownOpen = false;
                            root.dropdownToggled(false);
                        }
                    }
                }
            }
        }
    }
}
