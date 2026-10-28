import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    required property var hostCard
    Layout.fillWidth: true
    spacing: 12

    // Row 1: Alignment, Offset (X, Y), and Font Size
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // Horizontal Alignment
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Horizontal Align"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: hostCard.theme.textSecondary
            }

            Rectangle {
                id: halignTrack
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property var opts: ["left", "center", "right"]
                readonly property int activeIdx: Math.max(0, opts.indexOf(hostCard.editHalign))
                readonly property real cellWidth: (width - 6 - 4) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: halignTrack.cellWidth
                    x: 3 + halignTrack.activeIdx * (halignTrack.cellWidth + 2)
                    radius: 4
                    color: hostCard.theme.bgSelected
                    border.color: hostCard.theme.accentPrimary ?? "#7aa2f7"
                    border.width: 1
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 2

                    Repeater {
                        model: halignTrack.opts
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool isSel: hostCard.editHalign === modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: !isSel && haHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            HoverHandler { id: haHover }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                font.family: hostCard.font
                                font.pixelSize: 10
                                font.bold: isSel
                                color: isSel ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : hostCard.theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hostCard.editHalign = modelData
                            }
                        }
                    }
                }
            }
        }

        // Vertical Alignment
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Vertical Align"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: hostCard.theme.textSecondary
            }

            Rectangle {
                id: valignTrack
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property var opts: ["top", "center", "bottom"]
                readonly property int activeIdx: Math.max(0, opts.indexOf(hostCard.editValign))
                readonly property real cellWidth: (width - 6 - 4) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: valignTrack.cellWidth
                    x: 3 + valignTrack.activeIdx * (valignTrack.cellWidth + 2)
                    radius: 4
                    color: hostCard.theme.bgSelected
                    border.color: hostCard.theme.accentPrimary ?? "#7aa2f7"
                    border.width: 1
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 2

                    Repeater {
                        model: valignTrack.opts
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool isSel: hostCard.editValign === modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: !isSel && vaHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            HoverHandler { id: vaHover }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                font.family: hostCard.font
                                font.pixelSize: 10
                                font.bold: isSel
                                color: isSel ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : hostCard.theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hostCard.editValign = modelData
                            }
                        }
                    }
                }
            }
        }

        // Coordinates (X, Y)
        ColumnLayout {
            Layout.preferredWidth: 150
            spacing: 4

            Text {
                text: "Offset (X, Y)"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: hostCard.theme.textSecondary
            }

            RowLayout {
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: posXInput.activeFocus ? hostCard.theme.accentPrimary : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    TextInput {
                        id: posXInput
                        anchors.fill: parent
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        text: String(hostCard.editPosX)
                        font.family: hostCard.font
                        font.pixelSize: 11
                        color: hostCard.theme.textPrimary
                        selectByMouse: true
                        onTextChanged: {
                            let v = parseInt(text);
                            if (!isNaN(v)) hostCard.editPosX = v;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: posYInput.activeFocus ? hostCard.theme.accentPrimary : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    TextInput {
                        id: posYInput
                        anchors.fill: parent
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        text: String(hostCard.editPosY)
                        font.family: hostCard.font
                        font.pixelSize: 11
                        color: hostCard.theme.textPrimary
                        selectByMouse: true
                        onTextChanged: {
                            let v = parseInt(text);
                            if (!isNaN(v)) hostCard.editPosY = v;
                        }
                    }
                }
            }
        }

        // Font Size
        ColumnLayout {
            Layout.preferredWidth: 90
            spacing: 4

            Text {
                text: "Font Size"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: hostCard.theme.textSecondary
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: fsizeInput.activeFocus ? hostCard.theme.accentPrimary : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                TextInput {
                    id: fsizeInput
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    text: String(hostCard.editFontSize)
                    font.family: hostCard.font
                    font.pixelSize: 11
                    color: hostCard.theme.textPrimary
                    selectByMouse: true
                    onTextChanged: {
                        let v = parseInt(text);
                        if (!isNaN(v) && v > 0) hostCard.editFontSize = v;
                    }
                }
            }
        }
    }

    // Row 2: Font Family Selector (Custom Input + Quick Font Presets with Animated Sliding Pill)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Font Family"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: hostCard.theme.textSecondary
            }

            // Live Typography Sample Pill
            Rectangle {
                height: 20
                implicitWidth: fontSampleText.implicitWidth + 12
                radius: 4
                color: Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.14)
                border.color: Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.3)
                border.width: 1

                Text {
                    id: fontSampleText
                    anchors.centerIn: parent
                    text: {
                        let f = hostCard.editFontFamily.trim();
                        return (f === "$font" || f === "") ? "Default ($font) • Aa 01:23" : (f + " • Aa 01:23");
                    }
                    font.family: {
                        let f = hostCard.editFontFamily.trim();
                        if (f === "$font" || f === "") return "JetBrainsMono Nerd Font";
                        return f.replace(/\s+\d+$/, "");
                    }
                    font.pixelSize: 10
                    font.bold: true
                    color: hostCard.theme.accentPrimary
                }
            }

            Item { Layout.fillWidth: true }

            // Custom Font Family Input Box
            Rectangle {
                width: 240
                height: 28
                radius: 6
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: fontFamInput.activeFocus ? hostCard.theme.accentPrimary : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: fontFamInput.activeFocus ? 1.5 : 1

                TextInput {
                    id: fontFamInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: hostCard.editFontFamily
                    font.family: hostCard.font
                    font.pixelSize: 11
                    color: hostCard.theme.textPrimary
                    selectByMouse: true
                    onTextChanged: {
                        if (text.trim().length > 0 && hostCard.editFontFamily !== text.trim()) {
                            hostCard.editFontFamily = text.trim();
                        }
                    }
                }
            }
        }

        // Segmented Track for Popular Lock Screen Fonts
        Rectangle {
            id: fontPresetTrack
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            readonly property var presets: [
                { label: "Default ($font)", val: "$font", previewFont: "JetBrainsMono Nerd Font" },
                { label: "JetBrainsMono", val: "JetBrainsMono Nerd Font", previewFont: "JetBrainsMono Nerd Font" },
                { label: "Lato Nerd", val: "Lato Nerd Font", previewFont: "Lato Nerd Font" },
                { label: "Fira Code", val: "Fira Code", previewFont: "Fira Code" },
                { label: "Victor Mono", val: "Victor Mono Bold Oblique", previewFont: "Victor Mono" },
                { label: "Adwaita Sans", val: "Adwaita Sans", previewFont: "Adwaita Sans" },
                { label: "Hack Nerd", val: "Hack Nerd Font", previewFont: "Hack Nerd Font" }
            ]
            readonly property int count: presets.length
            readonly property int activeIdx: {
                let cur = hostCard.editFontFamily.trim();
                for (let i = 0; i < presets.length; i++) {
                    if (presets[i].val === cur) return i;
                }
                if (cur === "JetBrains Mono Nerd Font 10") return 1;
                return -1;
            }
            readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

            Rectangle {
                visible: fontPresetTrack.activeIdx >= 0
                y: 3
                height: parent.height - 6
                width: fontPresetTrack.cellWidth
                x: 3 + Math.max(0, fontPresetTrack.activeIdx) * (fontPresetTrack.cellWidth + 3)
                radius: 5
                color: hostCard.theme.bgSelected
                border.color: hostCard.theme.accentPrimary ?? "#7aa2f7"
                border.width: 1
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: fontPresetTrack.presets
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool isSel: fontPresetTrack.activeIdx === index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && fpHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        HoverHandler { id: fpHover }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: modelData.previewFont
                            font.pixelSize: 10
                            font.bold: isSel
                            color: isSel ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : hostCard.theme.textPrimary
                            opacity: isSel || fpHover.hovered ? 1.0 : 0.78
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hostCard.editFontFamily = modelData.val
                        }
                    }
                }
            }
        }
    }
}
