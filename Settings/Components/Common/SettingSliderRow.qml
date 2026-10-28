import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: sliderRow
    property string title: ""
    property string desc: ""
    property real value: 0
    property real minVal: 0
    property real maxVal: 100
    property real step: 1
    property string unit: "px"
    property var presets: []
    property bool isFloat: false
    property bool customActive: false
    signal valueModified(real val)
    property bool announce: false  // emit Style.toast when a preset is chosen

    function formatLabel(lbl) {
        if (!lbl) return "";
        let s = String(lbl);
        let match = s.match(/\(([^)]+)\)/);
        if (match && match[1]) return match[1];
        return s;
    }

    readonly property int matchingPresetIdx: {
        if (!presets || presets.length === 0) return -1;
        for (let i = 0; i < presets.length; i++) {
            if (Math.abs(sliderRow.value - presets[i].val) < (sliderRow.isFloat ? 0.005 : 0.01)) {
                return i;
            }
        }
        return -1;
    }

    readonly property bool isCustomEffective: customActive || (presets.length > 0 && matchingPresetIdx === -1)

    readonly property int activeIdx: {
        if (presets.length === 0) return -1;
        if (isCustomEffective) return presets.length;
        return matchingPresetIdx;
    }

    Layout.fillWidth: true
    implicitHeight: (presets.length > 0 && isCustomEffective) ? 94 : 52
    height: implicitHeight

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 6

        /* Top Main Row */
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.maximumWidth: sliderRow.presets.length > 0 ? 320 : 420

                Text {
                    text: sliderRow.title
                    font.family: Style.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Style.theme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: sliderRow.desc !== ""
                    text: sliderRow.desc
                    font.family: Style.font
                    font.pixelSize: 11
                    color: Style.theme.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            /* Case A: Has Presets -> Segmented Track with Presets + Custom */
            Rectangle {
                id: segmentTrack
                visible: sliderRow.presets.length > 0
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                implicitWidth: Math.min(380, Math.max(260, (sliderRow.presets.length + 1) * 70))
                height: 32
                radius: 7
                color: Style.theme.bgBase
                border.color: Style.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property int count: sliderRow.presets.length + 1
                readonly property real cellWidth: (width - 6 - (count - 1) * 3) / count

                /* Sliding Selection Pill */
                Rectangle {
                    visible: sliderRow.activeIdx >= 0
                    y: 3
                    height: parent.height - 6
                    width: segmentTrack.cellWidth
                    x: 3 + Math.max(0, sliderRow.activeIdx) * (segmentTrack.cellWidth + 3)
                    radius: 5
                    color: Style.theme.bgSelected
                    border.color: Style.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: sliderRow.presets
                        delegate: Rectangle {
                            id: segBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: sliderRow.activeIdx === segBtn.index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && segHover.hovered ? (Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: segHover }

                            Text {
                                anchors.centerIn: parent
                                text: sliderRow.formatLabel(segBtn.modelData.label)
                                font.family: Style.font
                                font.pixelSize: 11
                                font.bold: segBtn.isSel
                                color: segBtn.isSel ? Style.theme.accentPrimary : Style.theme.textPrimary
                                opacity: segBtn.isSel || segHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sliderRow.customActive = false;
                                    sliderRow.valueModified(segBtn.modelData.val);
                                    if (sliderRow.announce) Style.toast(sliderRow.title + " set to " + sliderRow.formatLabel(segBtn.modelData.label));
                                }
                            }
                        }
                    }

                    /* Custom Segment Button */
                    Rectangle {
                        id: customSegBtn
                        readonly property bool isSel: sliderRow.activeIdx === sliderRow.presets.length

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && cHover.hovered ? (Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: cHover }

                        Text {
                            anchors.centerIn: parent
                            text: sliderRow.isCustomEffective
                                ? (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                                : "Custom"
                            font.family: Style.font
                            font.pixelSize: 11
                            font.bold: customSegBtn.isSel
                            color: customSegBtn.isSel ? Style.theme.accentPrimary : Style.theme.textPrimary
                            opacity: customSegBtn.isSel || cHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sliderRow.customActive = !sliderRow.customActive;
                            }
                        }
                    }
                }
            }

            /* Case B: No Presets -> Right-Aligned Slider directly in main row */
            RowLayout {
                visible: sliderRow.presets.length === 0
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                spacing: 12
                implicitWidth: 260

                Rectangle {
                    id: sTrackDirect
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Style.theme.bgSelected
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real frac: Math.max(0.0, Math.min(1.0, (sliderRow.value - sliderRow.minVal) / (sliderRow.maxVal - sliderRow.minVal)))
                    readonly property bool isDragging: sMouseDirect.pressed

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(0, Math.min(parent.width, parent.width * sTrackDirect.frac))
                        color: Style.theme.accentPrimary

                        Behavior on width {
                            NumberAnimation {
                                duration: sTrackDirect.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Outer halo ring on hover/press
                    Rectangle {
                        anchors.centerIn: sKnobDirect
                        width: sKnobDirect.width + (sMouseDirect.pressed ? 8 : (sMouseDirect.containsMouse ? 6 : 0))
                        height: width
                        radius: width / 2
                        color: Qt.rgba(Style.theme.accentPrimary.r, Style.theme.accentPrimary.g, Style.theme.accentPrimary.b, sMouseDirect.pressed ? 0.35 : (sMouseDirect.containsMouse ? 0.2 : 0))
                        z: 1

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Tactile white knob
                    Rectangle {
                        id: sKnobDirect
                        width: sMouseDirect.containsMouse || sMouseDirect.pressed ? 17 : 15
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        border.color: Style.theme.accentPrimary
                        border.width: 3
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(sTrackDirect.width - width, (sTrackDirect.width * sTrackDirect.frac) - (width / 2)))
                        z: 2

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on x {
                            NumberAnimation {
                                duration: sTrackDirect.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: sMouseDirect
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        function updateFromPos(mouse) {
                            if (sTrackDirect.width <= 0) return;
                            const trackX = mapToItem(sTrackDirect, mouse.x, 0).x;
                            const f = Math.max(0.0, Math.min(1.0, trackX / sTrackDirect.width));
                            let raw = sliderRow.minVal + f * (sliderRow.maxVal - sliderRow.minVal);
                            let val = sliderRow.isFloat ? (Math.round(raw * 100) / 100) : Math.round(raw);
                            sliderRow.valueModified(val);
                        }
                        onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                        onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                        onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                    }
                }

                Text {
                    text: (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                    font.family: Style.font
                    font.pixelSize: 12
                    font.bold: true
                    color: Style.theme.accentPrimary
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        /* Expandable Custom Slider Row */
        RowLayout {
            visible: sliderRow.presets.length > 0 && sliderRow.isCustomEffective
            opacity: (sliderRow.presets.length > 0 && sliderRow.isCustomEffective) ? 1.0 : 0.0
            Layout.fillWidth: true
            Layout.topMargin: -2
            Layout.bottomMargin: 4
            spacing: 12

            Behavior on opacity { NumberAnimation { duration: 160 } }

            Text {
                text: "Custom " + sliderRow.title + ":"
                font.family: Style.font
                font.pixelSize: 11
                font.bold: true
                color: Style.theme.textSecondary
                Layout.preferredWidth: 160
                Layout.minimumWidth: 160
                Layout.maximumWidth: 160
                elide: Text.ElideRight
            }

            Rectangle {
                id: sTrackCustom
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Style.theme.bgSelected
                Layout.alignment: Qt.AlignVCenter

                readonly property real frac: Math.max(0.0, Math.min(1.0, (sliderRow.value - sliderRow.minVal) / (sliderRow.maxVal - sliderRow.minVal)))
                readonly property bool isDragging: sMouseCustom.pressed

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(0, Math.min(parent.width, parent.width * sTrackCustom.frac))
                    color: Style.theme.accentPrimary

                    Behavior on width {
                        NumberAnimation {
                            duration: sTrackCustom.isDragging ? 0 : 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Outer halo ring on hover/press
                Rectangle {
                    anchors.centerIn: sKnobCustom
                    width: sKnobCustom.width + (sMouseCustom.pressed ? 8 : (sMouseCustom.containsMouse ? 6 : 0))
                    height: width
                    radius: width / 2
                    color: Qt.rgba(Style.theme.accentPrimary.r, Style.theme.accentPrimary.g, Style.theme.accentPrimary.b, sMouseCustom.pressed ? 0.35 : (sMouseCustom.containsMouse ? 0.2 : 0))
                    z: 1

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Tactile white knob
                Rectangle {
                    id: sKnobCustom
                    width: sMouseCustom.containsMouse || sMouseCustom.pressed ? 17 : 15
                    height: width
                    radius: width / 2
                    color: "#ffffff"
                    border.color: Style.theme.accentPrimary
                    border.width: 3
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(sTrackCustom.width - width, (sTrackCustom.width * sTrackCustom.frac) - (width / 2)))
                    z: 2

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on x {
                        NumberAnimation {
                            duration: sTrackCustom.isDragging ? 0 : 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: sMouseCustom
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    function updateFromPos(mouse) {
                        if (sTrackCustom.width <= 0) return;
                        const trackX = mapToItem(sTrackCustom, mouse.x, 0).x;
                        const f = Math.max(0.0, Math.min(1.0, trackX / sTrackCustom.width));
                        let raw = sliderRow.minVal + f * (sliderRow.maxVal - sliderRow.minVal);
                        let val = sliderRow.isFloat ? (Math.round(raw * 100) / 100) : Math.round(raw);
                        sliderRow.valueModified(val);
                    }
                    onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                    onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                    onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                }
            }

            Text {
                text: (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                font.family: Style.font
                font.pixelSize: 12
                font.bold: true
                color: Style.theme.accentPrimary
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
