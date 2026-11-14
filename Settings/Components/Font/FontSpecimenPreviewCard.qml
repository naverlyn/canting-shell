import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

// ---------------------------------------------------------
SectionCard {
    required property var root
    title: "Live Specimen Preview"
    subtitle: (root.hoveredBrowserFont !== "" ? ("Previewing: " + root.hoveredBrowserFont + "  •  ") : "")
        + "Scale " + Math.round(root.theme.fontScale * 100) + "%  •  Weight: " + root.theme.fontWeight
    subtitleColor: root.hoveredBrowserFont !== "" ? root.theme.accentPrimary : root.theme.textMuted
    subtitleBold: root.hoveredBrowserFont !== ""

    // Specimen Mode Switcher + Custom Text Input
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [
                { id: "ui",      label: "Shell & Bar Mockup", icon: "󰮲" },
                { id: "mono",    label: "Lock Screen & Code", icon: "󰌾" },
                { id: "charset", label: "Scale & Character Set", icon: "󰛖" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool active: root.specimenTab === modelData.id
                height: 28
                radius: 7
                implicitWidth: specTabRow.implicitWidth + 18
                color: active ? root.theme.bgSelected : (specTabMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }

                Row {
                    id: specTabRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        font.family: Style.font
                        font.pixelSize: Style.px(12)
                        color: active ? root.theme.accentPrimary : root.theme.textSecondary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font.family: Style.font
                        font.pixelSize: Style.px(11)
                        font.bold: active
                        color: active ? root.theme.textPrimary : root.theme.textSecondary
                    }
                }

                MouseArea {
                    id: specTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.specimenTab = modelData.id
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Custom specimen text input
        Rectangle {
            Layout.preferredWidth: 280
            height: 28
            radius: 7
            color: root.theme.bgBase
            border.color: customSpecInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: customSpecInput.activeFocus ? 1.5 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "󰏫"
                    font.family: Style.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                }

                TextInput {
                    id: customSpecInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.customSpecimenText
                    font.family: Style.font
                    font.pixelSize: 11
                    color: root.theme.textPrimary
                    selectByMouse: true
                    clip: true
                    Component.onCompleted: cursorPosition = 0
                    onTextChanged: root.customSpecimenText = text
                }
            }
        }
    }

    // Specimen Stage Canvas
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: specimenStack.implicitHeight + 24
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: specimenStack
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            // --- Mode 1: Shell & Bar Mockup ---
            ColumnLayout {
                visible: root.specimenTab === "ui"
                Layout.fillWidth: true
                spacing: 10

                // Simulated Bar strip
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // Left workspace pills
                        Rectangle {
                            height: 22
                            radius: 6
                            implicitWidth: wsRow.implicitWidth + 14
                            color: root.theme.bgSelected

                            Row {
                                id: wsRow
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "󰣇"
                                    font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                    font.pixelSize: Style.px(13)
                                    color: root.theme.accentPrimary
                                }
                                Text {
                                    text: "1   2   3   •   Quickshell Settings"
                                    font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                    font.pixelSize: Style.px(11)
                                    font.weight: Style.fontWeightEnum
                                    font.bold: Style.boldHeadings
                                    font.letterSpacing: Style.letterSpacing
                                    font.hintingPreference: Style.fontHintingEnum
                                    antialiasing: Style.fontAntialiasing
                                    renderType: Style.fontRenderTypeEnum
                                    color: root.theme.textPrimary
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Center clock pill
                        Text {
                            text: "Thu 12 Nov   04:20"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                            font.pixelSize: Style.px(12)
                            font.bold: Style.boldHeadings
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: root.theme.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        // Right status pill
                        Rectangle {
                            height: 22
                            radius: 6
                            implicitWidth: sysRow.implicitWidth + 14
                            color: root.theme.bgHover

                            Row {
                                id: sysRow
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "󰖩  5G   󰕾  78%   󰁹  96%"
                                    font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                    font.pixelSize: Style.px(11)
                                    font.weight: Style.fontWeightEnum
                                    font.letterSpacing: Style.letterSpacing
                                    font.hintingPreference: Style.fontHintingEnum
                                    antialiasing: Style.fontAntialiasing
                                    renderType: Style.fontRenderTypeEnum
                                    color: root.theme.textSecondary
                                }
                            }
                        }
                    }
                }

                // Simulated Notification / UI Typography Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: notifSampleCol.implicitHeight + 20
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: Style.withAlpha(root.theme.accentPrimary, 0.3)
                    border.width: 1

                    ColumnLayout {
                        id: notifSampleCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 10
                        }
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "󰂚  Typography Preview"
                                font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                font.pixelSize: Style.px(13)
                                font.bold: Style.boldHeadings
                                font.letterSpacing: Style.letterSpacing
                                font.hintingPreference: Style.fontHintingEnum
                                antialiasing: Style.fontAntialiasing
                                renderType: Style.fontRenderTypeEnum
                                color: root.theme.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "just now"
                                font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                font.pixelSize: Style.px(10)
                                color: root.theme.textMuted
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: root.customSpecimenText !== ""
                                ? root.customSpecimenText
                                : "The quick brown fox jumps over the lazy dog 0123456789"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                            font.pixelSize: Style.px(12)
                            font.weight: Style.fontWeightEnum
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: root.theme.textSecondary
                        }
                    }
                }
            }

            // --- Mode 2: Lock Screen & Monospace Mockup ---
            ColumnLayout {
                visible: root.specimenTab === "mono"
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "04:20"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                            font.pixelSize: Style.px(38)
                            font.bold: true
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: root.theme.textPrimary
                        }
                        Text {
                            text: "Thursday, 12 November"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                            font.pixelSize: Style.px(11)
                            font.letterSpacing: Style.letterSpacing
                            color: root.theme.accentCyan
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: root.theme.bgBorder
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: "󰍛 CPU 14%   •   󰘚 RAM 4.2 GiB   •   󰁹 BAT 96%"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                            font.pixelSize: Style.px(12)
                            font.bold: Style.boldHeadings
                            font.letterSpacing: Style.letterSpacing
                            color: root.theme.accentPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: "const shell = Quickshell.lock({ font: \"" + (root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont) + "\" }); // !== => <= >="
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                            font.pixelSize: Style.px(11)
                            font.weight: Style.fontWeightEnum
                            font.letterSpacing: Style.letterSpacing
                            color: root.theme.textSecondary
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: "0123456789  Il1O0  [] {} () <>  !@#$%^&*+-=~"
                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                            font.pixelSize: Style.px(11)
                            color: root.theme.textMuted
                        }
                    }
                }
            }

            // --- Mode 3: Scale & Character Set Waterfall ---
            ColumnLayout {
                visible: root.specimenTab === "charset"
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { size: 11, label: "11px" },
                        { size: 14, label: "14px" },
                        { size: 18, label: "18px" }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 48
                            height: 20
                            radius: 5
                            color: root.theme.bgSurface
                            Text {
                                anchors.centerIn: parent
                                text: Style.px(modelData.size) + "px"
                                font.family: root.theme.monoFont
                                font.pixelSize: 10
                                color: root.theme.accentPrimary
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.customSpecimenText !== "" ? root.customSpecimenText : "The quick brown fox jumps over the lazy dog 0123456789"
                            font.family: root.hoveredBrowserFont !== ""
                                ? root.hoveredBrowserFont
                                : (root.targetRole === "mono" ? root.theme.monoFont : root.theme.fontFamily)
                            font.pixelSize: Style.px(modelData.size)
                            font.weight: Style.fontWeightEnum
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: root.theme.textPrimary
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.theme.bgBorder
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: "Nerd Icons:  󰣇  󰖩  󰂯  󰕾  󰂚  󰐥  󰍽  󰌌  󰍹  󰏘  󰮲  󰌾    󰸉  󰕮  󰁯  󰀻  󰅌"
                    font.family: root.hoveredBrowserFont !== ""
                        ? root.hoveredBrowserFont
                        : (root.targetRole === "mono" ? root.theme.monoFont : root.theme.fontFamily)
                    font.pixelSize: Style.px(13)
                    color: root.theme.accentCyan
                }
            }
        }
    }
}
