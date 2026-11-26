import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Item {
    id: pickerRow

    required property var root
    required property string title
    required property string subtitle
    required property string colorValue
    property string fallbackColor: String(Style.theme.accentPrimary)
    property var swatches: root.borderColorSwatches

    signal colorSelected(string hex)

    readonly property string normalizedColor: {
        let v = String(colorValue || fallbackColor).trim().toLowerCase();
        return /^#[0-9a-f]{6}$/.test(v) ? v : fallbackColor;
    }

    readonly property var activeSwatch: {
        if (!swatches) return null;
        let cur = normalizedColor;
        for (let i = 0; i < swatches.length; i++) {
            if (String(swatches[i].color).toLowerCase() === cur) return swatches[i];
        }
        return null;
    }

    readonly property bool isOpen: colorPopup.opened

    Layout.fillWidth: true
    implicitHeight: 56

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: pickerRow.title
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: pickerRow.subtitle
                font.family: Style.font
                font.pixelSize: Style.px(11)
                font.weight: Style.fontWeightEnum
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        /* Color Dropdown Trigger Pill */
        Rectangle {
            id: triggerBtn
            Layout.preferredWidth: 380
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            radius: 7
            color: {
                if (pickerRow.isOpen) return Style.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12);
                if (triggerHover.hovered) return Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08);
                return Style.theme.bgBase;
            }
            border.color: {
                if (pickerRow.isOpen) return Style.theme.accentPrimary;
                if (triggerHover.hovered) return Style.withAlpha(Style.theme.accentPrimary, 0.45);
                return Style.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1);
            }
            border.width: pickerRow.isOpen ? 1.5 : 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            HoverHandler { id: triggerHover }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 10
                spacing: 8

                /* Active Color Swatch */
                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    radius: 5
                    color: pickerRow.normalizedColor
                    border.color: Style.theme.bgBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                /* Preset Name or Custom */
                Text {
                    text: pickerRow.activeSwatch ? pickerRow.activeSwatch.name : "Custom"
                    font.family: Style.font
                    font.pixelSize: Style.px(12)
                    font.bold: true
                    font.letterSpacing: Style.letterSpacing
                    font.hintingPreference: Style.fontHintingEnum
                    antialiasing: Style.fontAntialiasing
                    renderType: Style.fontRenderTypeEnum
                    color: Style.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                /* Monospace Hex Badge */
                Text {
                    text: pickerRow.normalizedColor
                    font.family: Style.monoFont
                    font.pixelSize: Style.px(11)
                    font.hintingPreference: Style.fontHintingEnum
                    renderType: Style.fontRenderTypeEnum
                    color: Style.theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                /* Rotating Chevron */
                Text {
                    text: "󰅀"
                    font.family: Style.font
                    font.pixelSize: Style.px(13)
                    color: pickerRow.isOpen ? Style.theme.accentPrimary : Style.theme.textSecondary
                    rotation: pickerRow.isOpen ? 180 : 0
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (colorPopup.opened) {
                        colorPopup.close();
                    } else {
                        colorPopup.open();
                    }
                }
            }
        }
    }

    /* Floating Color Picker Dropdown Menu */
    Popup {
        id: colorPopup
        parent: triggerBtn
        x: triggerBtn.width - width
        y: triggerBtn.height + 4
        width: triggerBtn.width
        padding: 6
        margins: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "y"; from: triggerBtn.height; to: triggerBtn.height + 4; duration: 150; easing.type: Easing.OutCubic }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InQuad }
        }

        background: Rectangle {
            radius: 10
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 2

            Repeater {
                model: pickerRow.swatches
                delegate: Rectangle {
                    id: optDelegate
                    required property var modelData
                    required property int index

                    readonly property string swatchHex: String(modelData.color).toLowerCase()
                    readonly property bool isSelected: pickerRow.normalizedColor === swatchHex

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 6
                    color: {
                        if (isSelected) return Style.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.14);
                        if (optHover.hovered) return Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06);
                        return "transparent";
                    }

                    Behavior on color { ColorAnimation { duration: 110 } }

                    HoverHandler { id: optHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            Layout.alignment: Qt.AlignVCenter
                            radius: 6
                            color: optDelegate.swatchHex
                            border.color: optDelegate.isSelected ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.35)
                            border.width: 1
                        }

                        Text {
                            text: optDelegate.modelData.name
                            font.family: Style.font
                            font.pixelSize: Style.px(12)
                            font.bold: optDelegate.isSelected
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: optDelegate.isSelected ? Style.theme.accentPrimary : Style.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: optDelegate.swatchHex
                            font.family: Style.monoFont
                            font.pixelSize: Style.px(10)
                            font.hintingPreference: Style.fontHintingEnum
                            renderType: Style.fontRenderTypeEnum
                            color: optDelegate.isSelected ? Style.theme.accentPrimary : Style.theme.textMuted
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pickerRow.colorSelected(optDelegate.swatchHex);
                            colorPopup.close();
                        }
                    }
                }
            }
        }
    }
}
