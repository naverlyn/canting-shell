import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Item {
    id: colorRow

    required property string title
    required property string currentValue
    required property color resolvedColor
    required property var swatches

    signal valueSelected(string val)

    readonly property var activeSwatch: {
        if (!swatches) return null;
        for (let i = 0; i < swatches.length; i++) {
            if (swatches[i].val === currentValue) return swatches[i];
        }
        return null;
    }

    readonly property string resolvedHex: String(resolvedColor).toLowerCase()
    readonly property bool isOpen: colorPopup.opened

    Layout.fillWidth: true
    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Text {
            text: colorRow.title
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
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: triggerBtn
            Layout.preferredWidth: 380
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            radius: 7
            color: {
                if (colorRow.isOpen) return Style.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12);
                if (triggerHover.hovered) return Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08);
                return Style.theme.bgBase;
            }
            border.color: {
                if (colorRow.isOpen) return Style.theme.accentPrimary;
                if (triggerHover.hovered) return Style.withAlpha(Style.theme.accentPrimary, 0.45);
                return Style.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1);
            }
            border.width: colorRow.isOpen ? 1.5 : 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            HoverHandler { id: triggerHover }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 10
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    radius: 5
                    color: colorRow.resolvedColor
                    border.color: Qt.rgba(1, 1, 1, 0.25)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Text {
                    text: colorRow.activeSwatch ? colorRow.activeSwatch.name : "Custom"
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

                Text {
                    text: colorRow.resolvedHex
                    font.family: Style.monoFont
                    font.pixelSize: Style.px(11)
                    font.hintingPreference: Style.fontHintingEnum
                    renderType: Style.fontRenderTypeEnum
                    color: Style.theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "󰅀"
                    font.family: Style.font
                    font.pixelSize: Style.px(13)
                    color: colorRow.isOpen ? Style.theme.accentPrimary : Style.theme.textSecondary
                    rotation: colorRow.isOpen ? 180 : 0
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
                model: colorRow.swatches
                delegate: Rectangle {
                    id: optDelegate
                    required property var modelData
                    required property int index

                    readonly property string swatchHex: String(modelData.color).toLowerCase()
                    readonly property bool isSelected: colorRow.currentValue === modelData.val

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
                            color: optDelegate.modelData.color
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
                            colorRow.valueSelected(optDelegate.modelData.val);
                            colorPopup.close();
                        }
                    }
                }
            }
        }
    }
}
