import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

SectionCard {
    required property var root
    title: "Installed Font Browser"
    subtitle: root.filteredFonts.length + " matching families"

    // Top Row: Role Target Selector
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Assign Clicked Font To:"
            font.family: Style.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: root.theme.textSecondary
        }

        Repeater {
            model: [
                { id: "ui",   label: "Primary UI Font",           icon: "󰛖" },
                { id: "mono", label: "Monospace / Lock Screen",   icon: "󰅩" },
                { id: "both", label: "Both UI & Mono",            icon: "󰄬" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool active: root.targetRole === modelData.id
                height: 28
                radius: 7
                implicitWidth: roleBtnRow.implicitWidth + 16
                color: active
                    ? Style.withAlpha(root.theme.accentPrimary, 0.16)
                    : (roleBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: active ? 1.5 : 1

                Row {
                    id: roleBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        font.family: Style.font
                        font.pixelSize: 12
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
                    id: roleBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.targetRole = modelData.id
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    // Second Row: Search Input + Category Filter Pills
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 8
            color: root.theme.bgBase
            border.color: fontSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: fontSearchInput.activeFocus ? 1.5 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: Style.font
                    font.pixelSize: 13
                    color: fontSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
                }

                TextInput {
                    id: fontSearchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Style.font
                    font.pixelSize: Style.px(12)
                    color: root.theme.textPrimary
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.searchQuery = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: fontSearchInput.text === ""
                        text: "Search installed fonts (e.g. Lato, JetBrains, Nerd, Fira, Adwaita)..."
                        font.family: Style.font
                        font.pixelSize: Style.px(12)
                        color: root.theme.textMuted
                    }
                }

                Rectangle {
                    visible: fontSearchInput.text !== ""
                    width: 18
                    height: 18
                    radius: 9
                    color: clearSearchMouse.containsMouse ? root.theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Style.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                    }

                    MouseArea {
                        id: clearSearchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            fontSearchInput.text = "";
                            root.searchQuery = "";
                        }
                    }
                }
            }
        }

        // Filter Pills
        Repeater {
            model: [
                { id: "all",  label: "All (" + root.allFonts.length + ")" },
                { id: "nerd", label: "Nerd Fonts (" + root.nerdFontCount + ")" },
                { id: "mono", label: "Monospace (" + root.monoFontCount + ")" },
                { id: "sans", label: "Proportional" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool active: root.activeCategory === modelData.id
                height: 34
                radius: 8
                implicitWidth: catFilterTxt.implicitWidth + 20
                color: active
                    ? root.theme.accentPrimary
                    : (catFilterMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: 130 } }

                Text {
                    id: catFilterTxt
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: Style.font
                    font.pixelSize: Style.px(11)
                    font.bold: active
                    color: active ? root.theme.bgBase : root.theme.textSecondary
                }

                MouseArea {
                    id: catFilterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeCategory = modelData.id
                }
            }
        }
    }

    // Virtualized Font ListView
    Rectangle {
        Layout.fillWidth: true
        height: 310
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true

        ListView {
            id: browserList
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredFonts

            property bool hovered: false

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.2)
                }
            }

            delegate: Rectangle {
                id: fontRow
                required property var modelData
                required property int index

                readonly property string fam: modelData.family
                readonly property bool isUiActive: root.theme.savedFontFamily === fam
                readonly property bool isMonoActive: root.theme.savedMonoFont === fam
                readonly property bool isSelected: isUiActive || isMonoActive

                width: ListView.view.width - 8
                height: 52
                radius: 8
                color: isSelected
                    ? Style.withAlpha(root.theme.accentPrimary, 0.12)
                    : (rowMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                border.color: isUiActive
                    ? root.theme.accentPrimary
                    : (isMonoActive ? root.theme.accentCyan : (rowMouse.containsMouse ? root.theme.bgBorder : "transparent"))
                border.width: isSelected ? 1.5 : 1

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        browserList.hovered = true;
                        root.hoveredBrowserFont = fontRow.fam;
                    }
                    onExited: {
                        browserList.hovered = false;
                        if (root.hoveredBrowserFont === fontRow.fam)
                            root.hoveredBrowserFont = "";
                    }
                    onClicked: root.applyFontForRole(fontRow.fam, root.targetRole)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Left: Family Name + Badges
                    ColumnLayout {
                        Layout.preferredWidth: 250
                        Layout.maximumWidth: 270
                        spacing: 3

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Text {
                                text: fontRow.fam
                                font.family: Style.font
                                font.pixelSize: Style.px(12)
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Row {
                            spacing: 5

                            Rectangle {
                                visible: fontRow.modelData.isNerd
                                height: 15
                                radius: 4
                                implicitWidth: nerdTag.implicitWidth + 8
                                color: Style.withAlpha(root.theme.accentGreen, 0.15)
                                border.color: Style.withAlpha(root.theme.accentGreen, 0.4)
                                border.width: 1
                                Text {
                                    id: nerdTag
                                    anchors.centerIn: parent
                                    text: "NERD FONT"
                                    font.family: Style.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: root.theme.accentGreen
                                }
                            }

                            Rectangle {
                                visible: fontRow.modelData.isMono
                                height: 15
                                radius: 4
                                implicitWidth: monoTag.implicitWidth + 8
                                color: Style.withAlpha(root.theme.accentCyan, 0.15)
                                border.color: Style.withAlpha(root.theme.accentCyan, 0.4)
                                border.width: 1
                                Text {
                                    id: monoTag
                                    anchors.centerIn: parent
                                    text: "MONO"
                                    font.family: Style.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: root.theme.accentCyan
                                }
                            }

                            Rectangle {
                                visible: fontRow.isUiActive
                                height: 15
                                radius: 4
                                implicitWidth: uiActTag.implicitWidth + 8
                                color: root.theme.accentPrimary
                                Text {
                                    id: uiActTag
                                    anchors.centerIn: parent
                                    text: "ACTIVE UI"
                                    font.family: Style.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: root.theme.bgBase
                                }
                            }

                            Rectangle {
                                visible: fontRow.isMonoActive
                                height: 15
                                radius: 4
                                implicitWidth: monoActTag.implicitWidth + 8
                                color: root.theme.accentCyan
                                Text {
                                    id: monoActTag
                                    anchors.centerIn: parent
                                    text: "ACTIVE MONO"
                                    font.family: Style.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: root.theme.bgBase
                                }
                            }
                        }
                    }

                    // Middle: Live Specimen rendered in this font family
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.customSpecimenText !== ""
                            ? root.customSpecimenText
                            : "AaBbCc 0123  󰣇 󰖩 󰕾 — The quick brown fox"
                        font.family: fontRow.fam
                        font.pixelSize: Style.px(14)
                        font.weight: Style.fontWeightEnum
                        font.letterSpacing: Style.letterSpacing
                        color: rowMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                    }

                    // Right: Quick Set UI / Set Mono Pill Buttons
                    Row {
                        spacing: 6

                        Rectangle {
                            height: 26
                            radius: 6
                            implicitWidth: setUiTxt.implicitWidth + 14
                            color: fontRow.isUiActive
                                ? root.theme.accentPrimary
                                : (setUiMouse.containsMouse ? Style.withAlpha(root.theme.accentPrimary, 0.22) : root.theme.bgBase)
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Text {
                                id: setUiTxt
                                anchors.centerIn: parent
                                text: fontRow.isUiActive ? "✓ UI" : "Set UI"
                                font.family: Style.font
                                font.pixelSize: 10
                                font.bold: true
                                color: fontRow.isUiActive ? root.theme.bgBase : root.theme.accentPrimary
                            }

                            MouseArea {
                                id: setUiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyFontForRole(fontRow.fam, "ui")
                            }
                        }

                        Rectangle {
                            height: 26
                            radius: 6
                            implicitWidth: setMonoTxt.implicitWidth + 14
                            color: fontRow.isMonoActive
                                ? root.theme.accentCyan
                                : (setMonoMouse.containsMouse ? Style.withAlpha(root.theme.accentCyan, 0.22) : root.theme.bgBase)
                            border.color: root.theme.accentCyan
                            border.width: 1

                            Text {
                                id: setMonoTxt
                                anchors.centerIn: parent
                                text: fontRow.isMonoActive ? "✓ Mono" : "Set Mono"
                                font.family: Style.font
                                font.pixelSize: 10
                                font.bold: true
                                color: fontRow.isMonoActive ? root.theme.bgBase : root.theme.accentCyan
                            }

                            MouseArea {
                                id: setMonoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyFontForRole(fontRow.fam, "mono")
                            }
                        }
                    }
                }
            }

            // Empty state when no fonts match filter
            Text {
                anchors.centerIn: parent
                visible: root.filteredFonts.length === 0
                text: root.fontsLoading ? "Scanning installed fonts..." : "No installed fonts match \"" + root.searchQuery + "\""
                font.family: Style.font
                font.pixelSize: Style.px(12)
                color: root.theme.textMuted
            }
        }
    }
}
