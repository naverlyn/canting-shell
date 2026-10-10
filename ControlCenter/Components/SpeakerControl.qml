import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root

    property var theme
    property string font: "Hack Nerd Font"
    property bool dropdownOpen: false

    signal dropdownToggled(bool open)

    readonly property var audioSinks: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(n => n.audio !== null && !n.isStream && n.isSink);
    }

    spacing: 6

    Text {
        text: "Speaker"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme ? root.theme.textSecondary : "#a6adc8"
        Layout.fillWidth: true
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
                ? Qt.rgba(1, 0.42, 0.42, 0.18) 
                : (sinkMuteMouse.containsMouse 
                    ? (root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1) : Qt.rgba(1, 1, 1, 0.1))
                    : (root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06) : Qt.rgba(1, 1, 1, 0.05)))
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: parent.isMuted ? "󰝟" : "󰕾"
                font.family: root.font
                font.pixelSize: 15
                color: parent.isMuted 
                    ? (root.theme ? root.theme.accentRed : "#f38ba8") 
                    : (root.theme ? root.theme.textPrimary : "#cdd6f4")
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
            color: root.theme 
                ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18) 
                : Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                id: sinkSliderFill
                height: parent.height
                radius: 4
                width: {
                    const sink = Pipewire.defaultAudioSink;
                    if (!sink || !sink.audio) return 0;
                    return Math.min(parent.width, parent.width * sink.audio.volume);
                }
                color: root.theme ? root.theme.accentPrimary : "#a6e3a1"

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
                color: root.theme ? root.theme.textPrimary : "#cdd6f4"
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
                    if (sink && sink.audio) {
                        const newVol = Math.max(0, Math.min(1.0, mouseX / totalWidth));
                        sink.audio.volume = newVol;
                        if (sink.audio.muted) sink.audio.muted = false;
                    }
                }
            }
        }

        Text {
            text: {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return "0%";
                return sink.audio.muted ? "Muted" : Math.round(sink.audio.volume * 100) + "%";
            }
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme ? root.theme.textSecondary : "#a6adc8"
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
            ? (root.theme ? root.theme.bgSelected : "#313244")
            : (sinkSelectorMouse.containsMouse 
                ? (root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : Qt.rgba(1, 1, 1, 0.08)) 
                : (root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04) : Qt.rgba(0, 0, 0, 0.2)))
        border.color: root.dropdownOpen 
            ? (root.theme ? root.theme.accentPrimary : "#a6e3a1") 
            : (root.theme ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06))
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
                    ? (root.theme ? root.theme.textPrimary : "#cdd6f4") 
                    : (root.theme ? root.theme.textMuted : "#6c7086")
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
                color: root.theme ? root.theme.textPrimary : "#cdd6f4"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: "󰅀"
                font.family: root.font
                font.pixelSize: 14
                color: root.theme ? root.theme.textMuted : "#6c7086"
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
        color: root.theme ? (root.theme.bgSelected || root.theme.bgSurface) : Qt.rgba(0, 0, 0, 0.32)
        border.color: root.theme ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.07)
        border.width: root.dropdownOpen ? 1 : 0

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

        ColumnLayout {
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
                color: root.theme ? root.theme.textMuted : "#6c7086"
                visible: root.audioSinks.length === 0
                Layout.margins: 6
            }

            Repeater {
                model: root.audioSinks

                delegate: Rectangle {
                    id: sinkItemRect
                    readonly property bool isSelected: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    scale: sinkItemMouse.pressed ? 0.98 : 1.0
                    color: isSelected
                        ? (root.theme ? root.theme.bgSelected : "#313244")
                        : (sinkItemMouse.containsMouse 
                            ? (root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : Qt.rgba(1, 1, 1, 0.08)) 
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
                                ? (root.theme ? root.theme.accentPrimary : "#a6e3a1") 
                                : (root.theme ? root.theme.textMuted : "#6c7086")
                            Layout.preferredWidth: 14
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: modelData.description || modelData.nickname || modelData.name || "Audio Output"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: sinkItemRect.isSelected
                            color: sinkItemRect.isSelected 
                                ? (root.theme ? root.theme.textPrimary : "#cdd6f4") 
                                : (root.theme ? root.theme.textSecondary : "#a6adc8")
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
                            Pipewire.preferredDefaultAudioSink = modelData;
                            root.dropdownOpen = false;
                            root.dropdownToggled(false);
                        }
                    }
                }
            }
        }
    }
}
