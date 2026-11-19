import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../Common"
import "../../../Lockscreen"


ColumnLayout {
    id: optionsRoot
    required property var hostCard
    Layout.fillWidth: true
    spacing: 0

// Weather specific options
ColumnLayout {
    visible: optionsRoot.hostCard.modType === "weather"
    Layout.fillWidth: true
    spacing: 0

    PreferenceRow {
        title: "Weather Layout Style"

        Rectangle {
            id: weatherLayoutSegmentTrack
            width: 280
            height: 32
            radius: 7
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            readonly property var modes: [
                { label: "Compact", value: "compact" },
                { label: "Detailed", value: "detailed" }
            ]

            readonly property int activeIdx: optionsRoot.hostCard.editDisplayMode === "compact" ? 0 : 1
            readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

            Rectangle {
                visible: weatherLayoutSegmentTrack.activeIdx >= 0
                y: 3
                height: parent.height - 6
                width: weatherLayoutSegmentTrack.cellWidth
                x: 3 + Math.max(0, weatherLayoutSegmentTrack.activeIdx) * (weatherLayoutSegmentTrack.cellWidth + 3)
                radius: 5
                color: optionsRoot.hostCard.theme.bgSelected
                border.color: optionsRoot.hostCard.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: weatherLayoutSegmentTrack.modes
                    delegate: Rectangle {
                        id: wSegBtn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: weatherLayoutSegmentTrack.activeIdx === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && wSegHover.hovered ? optionsRoot.hostCard.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: wSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: wSegBtn.modelData.label
                            font.family: optionsRoot.hostCard.font
                            font.pixelSize: 11
                            font.bold: wSegBtn.isSel
                            color: wSegBtn.isSel ? optionsRoot.hostCard.theme.accentPrimary : optionsRoot.hostCard.theme.textPrimary
                            opacity: wSegBtn.isSel || wSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                optionsRoot.hostCard.editDisplayMode = wSegBtn.modelData.value;
                                optionsRoot.hostCard.saveChanges();
                            }
                        }
                    }
                }
            }
        }
    }
}

// Clock specific options
ColumnLayout {
    visible: optionsRoot.hostCard.modType === "clock"
    Layout.fillWidth: true
    spacing: 0

    // Time Format (12-Hour / 24-Hour)
    PreferenceRow {
        title: "Time Format"

        Rectangle {
            id: timeFormatSegmentTrack
            width: 280
            height: 32
            radius: 7
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            readonly property var modes: [
                { label: "12-Hour", value: "12h" },
                { label: "24-Hour", value: "24h" }
            ]

            readonly property int activeIdx: optionsRoot.hostCard.editClockFormat === "24h" ? 1 : 0
            readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

            /* Sliding Selection Pill (Matching SettingSliderRow / Image 4) */
            Rectangle {
                visible: timeFormatSegmentTrack.activeIdx >= 0
                y: 3
                height: parent.height - 6
                width: timeFormatSegmentTrack.cellWidth
                x: 3 + Math.max(0, timeFormatSegmentTrack.activeIdx) * (timeFormatSegmentTrack.cellWidth + 3)
                radius: 5
                color: optionsRoot.hostCard.theme.bgSelected
                border.color: optionsRoot.hostCard.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: timeFormatSegmentTrack.modes
                    delegate: Rectangle {
                        id: tfBtn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: timeFormatSegmentTrack.activeIdx === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && tfHover.hovered ? optionsRoot.hostCard.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: tfHover }

                        Text {
                            anchors.centerIn: parent
                            text: tfBtn.modelData.label
                            font.family: optionsRoot.hostCard.font
                            font.pixelSize: 11
                            font.bold: tfBtn.isSel
                            color: tfBtn.isSel ? optionsRoot.hostCard.theme.accentPrimary : optionsRoot.hostCard.theme.textPrimary
                            opacity: tfBtn.isSel || tfHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: tfMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                optionsRoot.hostCard.editClockFormat = tfBtn.modelData.value;
                                optionsRoot.hostCard.saveChanges();
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    PreferenceSlider {
        title: "Clock Font Size"
        minVal: 40
        maxVal: 140
        unit: "px"
        currentVal: optionsRoot.hostCard.editFontSize
        onValueChanged: (val) => {
            optionsRoot.hostCard.editFontSize = val;
            optionsRoot.hostCard.saveChanges();
        }
    }

    RowDivider {}

    PreferenceRow {
        title: "Show Date"
        SwitchToggle {
            checked: optionsRoot.hostCard.editShowDate
            onToggled: (st) => {
                optionsRoot.hostCard.editShowDate = st;
                optionsRoot.hostCard.saveChanges();
            }
        }
    }

    RowDivider {}

    PreferenceRow {
        title: "Show Seconds"
        SwitchToggle {
            checked: optionsRoot.hostCard.editShowSeconds
            onToggled: (st) => {
                optionsRoot.hostCard.editShowSeconds = st;
                optionsRoot.hostCard.saveChanges();
            }
        }
    }
}

// Media Player specific options
ColumnLayout {
    visible: optionsRoot.hostCard.modType === "media"
    Layout.fillWidth: true
    spacing: 0

    PreferenceRow {
        title: "Player Layout Style"

        Rectangle {
            id: mediaLayoutSegmentTrack
            width: 280
            height: 32
            radius: 7
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            readonly property var modes: [
                { label: "Compact", value: "compact" },
                { label: "Full", value: "full" }
            ]

            readonly property int activeIdx: optionsRoot.hostCard.editDisplayMode === "full" ? 1 : 0
            readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

            /* Sliding Selection Pill (Matching SettingSliderRow / Image 4) */
            Rectangle {
                visible: mediaLayoutSegmentTrack.activeIdx >= 0
                y: 3
                height: parent.height - 6
                width: mediaLayoutSegmentTrack.cellWidth
                x: 3 + Math.max(0, mediaLayoutSegmentTrack.activeIdx) * (mediaLayoutSegmentTrack.cellWidth + 3)
                radius: 5
                color: optionsRoot.hostCard.theme.bgSelected
                border.color: optionsRoot.hostCard.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: mediaLayoutSegmentTrack.modes
                    delegate: Rectangle {
                        id: mSegBtn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: mediaLayoutSegmentTrack.activeIdx === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && mSegHover.hovered ? optionsRoot.hostCard.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: mSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: mSegBtn.modelData.label
                            font.family: optionsRoot.hostCard.font
                            font.pixelSize: 11
                            font.bold: mSegBtn.isSel
                            color: mSegBtn.isSel ? optionsRoot.hostCard.theme.accentPrimary : optionsRoot.hostCard.theme.textPrimary
                            opacity: mSegBtn.isSel || mSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: mSegMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                optionsRoot.hostCard.editDisplayMode = mSegBtn.modelData.value;
                                optionsRoot.hostCard.saveChanges();
                            }
                        }
                    }
                }
            }
        }
    }
}

// Notifications specific options
ColumnLayout {
    visible: optionsRoot.hostCard.modType === "notifications" || optionsRoot.hostCard.modType === "notification"
    Layout.fillWidth: true
    spacing: 0

    PreferenceRow {
        title: "Notification Layout Style"

        Rectangle {
            id: notifLayoutSegmentTrack
            width: 280
            height: 32
            radius: 7
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            readonly property var modes: [
                { label: "Compact", value: "compact" },
                { label: "Stack", value: "full" }
            ]

            readonly property int activeIdx: optionsRoot.hostCard.editDisplayMode === "compact" ? 0 : 1
            readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

            Rectangle {
                visible: notifLayoutSegmentTrack.activeIdx >= 0
                y: 3
                height: parent.height - 6
                width: notifLayoutSegmentTrack.cellWidth
                x: 3 + Math.max(0, notifLayoutSegmentTrack.activeIdx) * (notifLayoutSegmentTrack.cellWidth + 3)
                radius: 5
                color: optionsRoot.hostCard.theme.bgSelected
                border.color: optionsRoot.hostCard.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: notifLayoutSegmentTrack.modes
                    delegate: Rectangle {
                        id: nSegBtn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: notifLayoutSegmentTrack.activeIdx === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && nSegHover.hovered ? optionsRoot.hostCard.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: nSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: nSegBtn.modelData.label
                            font.family: optionsRoot.hostCard.font
                            font.pixelSize: 11
                            font.bold: nSegBtn.isSel
                            color: nSegBtn.isSel ? optionsRoot.hostCard.theme.accentPrimary : optionsRoot.hostCard.theme.textPrimary
                            opacity: nSegBtn.isSel || nSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                optionsRoot.hostCard.editDisplayMode = nSegBtn.modelData.value;
                                optionsRoot.hostCard.saveChanges();
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider { visible: optionsRoot.hostCard.editDisplayMode !== "compact" }

    PreferenceSlider {
        visible: optionsRoot.hostCard.editDisplayMode !== "compact"
        title: "Max Visible Notifications"
        minVal: 1
        maxVal: 6
        unit: ""
        currentVal: optionsRoot.hostCard.editMaxVisible
        onValueChanged: (val) => {
            optionsRoot.hostCard.editMaxVisible = val;
            optionsRoot.hostCard.saveChanges();
        }
    }

    RowDivider {}

    PreferenceRow {
        title: "Show Message Content"
        SwitchToggle {
            checked: optionsRoot.hostCard.editShowContent
            onToggled: (st) => {
                optionsRoot.hostCard.editShowContent = st;
                optionsRoot.hostCard.saveChanges();
            }
        }
    }

    RowDivider {}

    PreferenceRow {
        title: "Hide When Empty"
        SwitchToggle {
            checked: optionsRoot.hostCard.editHideWhenEmpty
            onToggled: (st) => {
                optionsRoot.hostCard.editHideWhenEmpty = st;
                optionsRoot.hostCard.saveChanges();
            }
        }
    }
}

// Custom Text / Script options
ColumnLayout {
    visible: optionsRoot.hostCard.modType === "customText"
    Layout.fillWidth: true
    spacing: 0

    PreferenceRow {
        title: "Custom Text Label"
        Rectangle {
            width: 280
            height: 30
            radius: 6
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            TextInput {
                anchors.fill: parent
                anchors.margins: 6
                text: optionsRoot.hostCard.editText
                font.family: optionsRoot.hostCard.font
                font.pixelSize: 11
                color: optionsRoot.hostCard.theme.textPrimary
                onEditingFinished: {
                    optionsRoot.hostCard.editText = text;
                    optionsRoot.hostCard.saveChanges();
                }
            }
        }
    }

    RowDivider {}

    PreferenceRow {
        title: "Shell Command"
        Rectangle {
            width: 280
            height: 30
            radius: 6
            color: optionsRoot.hostCard.theme.bgBase
            border.color: optionsRoot.hostCard.theme.bgBorder
            border.width: 1

            TextInput {
                anchors.fill: parent
                anchors.margins: 6
                text: optionsRoot.hostCard.editCmd
                font.family: optionsRoot.hostCard.font
                font.pixelSize: 11
                color: optionsRoot.hostCard.theme.textPrimary
                onEditingFinished: {
                    optionsRoot.hostCard.editCmd = text;
                    optionsRoot.hostCard.saveChanges();
                }
            }
        }
    }

    RowDivider {}

    PreferenceSlider {
        title: "Update Interval"
        minVal: 1
        maxVal: 60
        unit: "s"
        currentVal: Math.round(optionsRoot.hostCard.editInterval / 1000)
        onValueChanged: (val) => {
            optionsRoot.hostCard.editInterval = val * 1000;
            optionsRoot.hostCard.saveChanges();
        }
    }

    RowDivider {}

    PreferenceSlider {
        title: "Font Size"
        minVal: 9
        maxVal: 48
        unit: "px"
        currentVal: optionsRoot.hostCard.editFontSize
        onValueChanged: (val) => {
            optionsRoot.hostCard.editFontSize = val;
            optionsRoot.hostCard.saveChanges();
        }
    }
}
}
