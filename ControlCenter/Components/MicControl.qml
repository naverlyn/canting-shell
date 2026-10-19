import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."

ColumnLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property bool dropdownOpen: false

    signal dropdownToggled(bool open)

    readonly property var audioSources: {
        if (!Pipewire.ready) return [];
        return Pipewire.nodes.values.filter(n => n && n.audio !== null && !n.isStream && !n.isSink);
    }

    spacing: 6

    Text {
        text: "Microphone"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
        Layout.fillWidth: true
    }

    // Slider Row: Mic Mute Button + Slider + Percentage
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            width: 28
            height: 28
            radius: 7
            readonly property bool isMuted: !Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio || Pipewire.defaultAudioSource.audio.muted
            color: isMuted 
                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                : (sourceMuteMouse.containsMouse 
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06))
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: parent.isMuted ? "󰍭" : "󰍬"
                font.family: root.font
                font.pixelSize: 15
                color: parent.isMuted 
                    ? root.theme.accentRed 
                    : root.theme.textPrimary
            }

            MouseArea {
                id: sourceMuteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const source = Pipewire.defaultAudioSource;
                    if (source && source.audio) source.audio.muted = !source.audio.muted;
                }
            }
        }

        Rectangle {
            id: sourceSliderBg
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18)

            Rectangle {
                id: sourceSliderFill
                height: parent.height
                radius: 4
                width: {
                    const source = Pipewire.defaultAudioSource;
                    if (!source || !source.audio) return 0;
                    return Math.min(parent.width, parent.width * source.audio.volume);
                }
                color: root.theme.accentPrimary

                Behavior on width {
                    enabled: !sourceSliderMouse.pressed
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                y: (parent.height - height) / 2
                x: Math.max(0, Math.min(sourceSliderBg.width - width, sourceSliderFill.width - (width / 2)))
                color: root.theme.textPrimary
            }

            MouseArea {
                id: sourceSliderMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => updateVolume(mouse.x, width)
                onPositionChanged: (mouse) => {
                    if (pressed) updateVolume(mouse.x, width);
                }

                function updateVolume(mouseX, totalWidth) {
                    const source = Pipewire.defaultAudioSource;
                    if (source && source.audio) {
                        const newVol = Math.max(0, Math.min(1.0, mouseX / totalWidth));
                        source.audio.volume = newVol;
                        if (source.audio.muted) source.audio.muted = false;
                    }
                }
            }
        }

        Text {
            text: {
                const source = Pipewire.defaultAudioSource;
                if (!source || !source.audio) return "0%";
                return source.audio.muted ? "Muted" : Math.round(source.audio.volume * 100) + "%";
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

    // Input Device Selector Pill
    Rectangle {
        Layout.fillWidth: true
        height: 30
        radius: 7
        color: root.dropdownOpen
            ? root.theme.bgSelected
            : (sourceSelectorMouse.containsMouse 
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
                text: "󰍬"
                font.family: root.font
                font.pixelSize: 13
                color: root.dropdownOpen 
                    ? root.theme.textPrimary 
                    : root.theme.textMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: {
                    const source = Pipewire.defaultAudioSource;
                    return (source && (source.description || source.nickname || source.name))
                        ? (source.description || source.nickname || source.name)
                        : "Input Device";
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
            id: sourceSelectorMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.dropdownOpen = !root.dropdownOpen;
                root.dropdownToggled(root.dropdownOpen);
            }
        }
    }

    // Expandable Input Devices List
    Rectangle {
        id: sourceDropdownBox
        Layout.fillWidth: true
        Layout.preferredHeight: root.dropdownOpen ? (sourceListCol.implicitHeight + 12) : 0
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
            id: sourceListCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 6
            }
            spacing: 4

            Text {
                text: "No input devices found"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
                visible: root.audioSources.length === 0
                padding: 6
            }

            Repeater {
                model: root.audioSources

                delegate: Rectangle {
                    id: sourceItemRect
                    readonly property bool isSelected: Boolean(modelData && Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id)
                    width: parent ? parent.width : 0
                    height: 30
                    radius: 6
                    scale: sourceItemMouse.pressed ? 0.98 : 1.0
                    color: isSelected
                        ? root.theme.bgSelected
                        : (sourceItemMouse.containsMouse 
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
                            text: sourceItemRect.isSelected ? "󰄬" : "󰝥"
                            font.family: root.font
                            font.pixelSize: sourceItemRect.isSelected ? 13 : 8
                            color: sourceItemRect.isSelected 
                                ? root.theme.accentPrimary 
                                : root.theme.textMuted
                            Layout.preferredWidth: 14
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: modelData ? (modelData.description || modelData.nickname || modelData.name || "Microphone") : "Microphone"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: sourceItemRect.isSelected
                            color: sourceItemRect.isSelected 
                                ? root.theme.textPrimary 
                                : root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: sourceItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData) Pipewire.preferredDefaultAudioSource = modelData;
                            root.dropdownOpen = false;
                            root.dropdownToggled(false);
                        }
                    }
                }
            }
        }
    }
}
