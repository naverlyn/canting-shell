import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: pickerRow

    required property var root
    required property string title
    required property string subtitle
    required property string colorValue
    property string fallbackColor: "#7aa2f7"
    property var swatches: root.borderColorSwatches

    signal colorSelected(string hex)

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text {
                text: pickerRow.title
                font.family: pickerRow.root.font
                font.pixelSize: 13
                font.bold: true
                color: pickerRow.root.theme.textPrimary
            }
            Text {
                text: pickerRow.subtitle
                font.family: pickerRow.root.font
                font.pixelSize: 11
                color: pickerRow.root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: pickerRow.colorValue || pickerRow.fallbackColor
            border.color: Qt.rgba(1, 1, 1, 0.3)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Rectangle {
            width: 105
            height: 30
            radius: 6
            color: pickerRow.root.theme.bgBase
            border.color: hexInput.activeFocus ? pickerRow.root.theme.accentPrimary : pickerRow.root.theme.bgBorder
            border.width: hexInput.activeFocus ? 2 : 1
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            TextInput {
                id: hexInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                text: pickerRow.colorValue
                font.family: pickerRow.root.font
                font.pixelSize: 12
                font.bold: true
                color: pickerRow.root.theme.textPrimary
                selectByMouse: true
                onEditingFinished: {
                    let v = text.trim();
                    if (!v.startsWith("#") && v.length === 6) v = "#" + v;
                    if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                        pickerRow.colorSelected(v.toLowerCase());
                    }
                }
            }
        }
    }

    /* Segmented Color Swatch Track with Sliding Selection Pill */
    Rectangle {
        id: swTrack
        Layout.fillWidth: true
        height: 32
        radius: 7
        color: pickerRow.root.theme.bgBase
        border.color: pickerRow.root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        readonly property int count: pickerRow.swatches.length
        readonly property int activeIdx: {
            let cur = String(pickerRow.colorValue).toLowerCase();
            for (let i = 0; i < pickerRow.swatches.length; i++) {
                if (String(pickerRow.swatches[i].color).toLowerCase() === cur) return i;
            }
            return -1;
        }
        readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

        Rectangle {
            visible: swTrack.activeIdx >= 0
            y: 3
            height: parent.height - 6
            width: swTrack.cellWidth
            x: 3 + Math.max(0, swTrack.activeIdx) * (swTrack.cellWidth + 3)
            radius: 5
            color: pickerRow.root.theme.bgSelected
            border.color: pickerRow.root.theme.accentPrimary
            border.width: 1

            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3

            Repeater {
                model: pickerRow.swatches
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isSel: swTrack.activeIdx === index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: !isSel && swHover.hovered ? (pickerRow.root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                    scale: swMouse.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    HoverHandler { id: swHover }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: modelData.color
                            border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                        }
                        Text {
                            text: modelData.name
                            font.family: pickerRow.root.font
                            font.pixelSize: 11
                            font.bold: isSel
                            color: isSel ? pickerRow.root.theme.accentPrimary : pickerRow.root.theme.textPrimary
                            opacity: isSel || swHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }
                    }

                    MouseArea {
                        id: swMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRow.colorSelected(String(modelData.color).toLowerCase())
                    }
                }
            }
        }
    }
}
