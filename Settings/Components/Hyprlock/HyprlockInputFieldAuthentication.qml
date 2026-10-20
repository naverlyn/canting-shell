import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Input Field & Authentication"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: authCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: authCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            // Immediate Render Toggle
            PreferenceRow {
                title: "Immediate Render"
                subtitle: "Render background instantly without waiting for graphical resources"

                SwitchToggle {
                    checked: root.generalImmediateRender
                    onToggled: (st) => {
                        root.generalImmediateRender = st;
                        root.scheduleSave();
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Placeholder Text Input (Refined Libadwaita styling)
            PreferenceRow {
                title: "Placeholder Text"
                subtitle: "Text shown inside empty password field"

                Rectangle {
                    width: 240
                    height: 32
                    radius: 7
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                    border.color: placeholderInput.activeFocus ? (root.theme.accentPrimary ?? "#7aa2f7") : (phHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: phHover }

                    TextInput {
                        id: placeholderInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.inputPlaceholder
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onEditingFinished: {
                            root.inputPlaceholder = text.trim();
                            root.scheduleSave();
                        }
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Field Width
            PreferenceSlider {
                title: "Input Box Width"
                subtitle: "Horizontal dimensions of the password entry box"
                minVal: 180
                maxVal: 380
                unit: "px"
                currentVal: root.inputWidth
                onValueChanged: (val) => {
                    root.inputWidth = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Field Height
            PreferenceSlider {
                title: "Input Box Height"
                subtitle: "Vertical dimensions of the password entry box"
                minVal: 40
                maxVal: 80
                unit: "px"
                currentVal: root.inputHeight
                onValueChanged: (val) => {
                    root.inputHeight = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Outline Thickness
            PreferenceSlider {
                title: "Outline Border Thickness"
                subtitle: "Border stroke width around input field"
                minVal: 0
                maxVal: 6
                unit: "px"
                currentVal: root.inputOutlineThickness
                onValueChanged: (val) => {
                    root.inputOutlineThickness = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Box Horizontal Position (X)
            PreferenceSlider {
                title: "Horizontal Position (X)"
                subtitle: "Horizontal offset of the password box (or drag directly on the stage)"
                minVal: -800
                maxVal: 800
                unit: "px"
                currentVal: root.inputPosX
                onValueChanged: (val) => {
                    root.inputPosX = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Box Vertical Position (Y)
            PreferenceSlider {
                title: "Vertical Position (Y)"
                subtitle: "Vertical offset of the password box (or drag directly on the stage)"
                minVal: -500
                maxVal: 500
                unit: "px"
                currentVal: root.inputPosY
                onValueChanged: (val) => {
                    root.inputPosY = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Fade on Empty
            PreferenceRow {
                title: "Fade on Empty"
                subtitle: "Fade out field outline when no characters are entered"

                SwitchToggle {
                    checked: root.inputFadeOnEmpty
                    onToggled: (st) => {
                        root.inputFadeOnEmpty = st;
                        root.scheduleSave();
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Center Password Dots
            PreferenceRow {
                title: "Center Password Dots"
                subtitle: "Center typed characters horizontally inside the box"

                SwitchToggle {
                    checked: root.inputDotsCenter
                    onToggled: (st) => {
                        root.inputDotsCenter = st;
                        root.scheduleSave();
                    }
                }
            }
        }
    }
}
