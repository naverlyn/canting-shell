import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Installed Font Browser"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }
        Text {
            text: root.filteredFonts.length + " matching families"
            font.family: Style.font
            font.pixelSize: Style.px(11)
            font.bold: false
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textMuted
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 12 * 2
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 12
            // Search Input + Category Filter Pills
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
                    Behavior on border.color { ColorAnimation { duration: 140 } }

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
                            ? root.theme.bgSelected
                            : (catFilterMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                        border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: active ? 1.5 : 1
                        scale: catFilterMouse.pressed ? 0.95 : (catFilterMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Text {
                            id: catFilterTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Style.font
                            font.pixelSize: Style.px(11)
                            font.bold: active
                            color: active ? root.theme.accentPrimary : (catFilterMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary)
                            Behavior on color { ColorAnimation { duration: 130 } }
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
                height: Math.max(460, root.height - 210)
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
                            color: root.theme.bgBorder
                        }
                    }

                    delegate: Rectangle {
                        id: fontRow
                        required property var modelData
                        required property int index

                        readonly property string fam: modelData.family
                        readonly property bool isUiActive: root.theme.savedFontFamily === fam
                        readonly property bool isLockActive: root.theme.savedLockscreenFont === fam
                        readonly property bool isSelected: isUiActive || isLockActive

                        width: ListView.view.width - 8
                        height: 58
                        radius: 8
                        color: isSelected
                            ? Style.withAlpha(root.theme.accentPrimary, 0.12)
                            : (rowMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                        border.color: isUiActive
                            ? root.theme.accentPrimary
                            : (isLockActive ? root.theme.accentCyan : (rowMouse.containsMouse ? root.theme.bgBorder : "transparent"))
                        border.width: isSelected ? 1.5 : 1
                        scale: rowMouse.pressed ? 0.99 : 1.0

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

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
                                        font.pixelSize: Style.px(13)
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
                                        visible: fontRow.isLockActive
                                        height: 15
                                        radius: 4
                                        implicitWidth: monoActTag.implicitWidth + 8
                                        color: root.theme.accentCyan
                                        Text {
                                            id: monoActTag
                                            anchors.centerIn: parent
                                            text: "ACTIVE LOCK"
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
                                font.pixelSize: Style.px(15)
                                font.weight: Style.fontWeightEnum
                                font.letterSpacing: Style.letterSpacing
                                color: rowMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                            }

                            // Right: Quick Set UI / Set Mono Pill Buttons
                            Row {
                                spacing: 6

                                Rectangle {
                                    height: 28
                                    radius: 6
                                    implicitWidth: Math.max(70, setUiTxt.implicitWidth + 16)
                                    color: fontRow.isUiActive
                                        ? root.theme.bgSelected
                                        : (setUiMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                                    border.color: fontRow.isUiActive || setUiMouse.containsMouse
                                        ? root.theme.accentPrimary
                                        : root.theme.bgBorder
                                    border.width: fontRow.isUiActive ? 1.5 : 1
                                    scale: setUiMouse.pressed ? 0.94 : (setUiMouse.containsMouse ? 1.04 : 1.0)

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Text {
                                        id: setUiTxt
                                        anchors.centerIn: parent
                                        text: fontRow.isUiActive ? "UI" : "Set UI"
                                        font.family: Style.font
                                        font.pixelSize: Style.px(11)
                                        font.bold: true
                                        color: fontRow.isUiActive || setUiMouse.containsMouse
                                            ? root.theme.accentPrimary
                                            : root.theme.textSecondary
                                        Behavior on color { ColorAnimation { duration: 140 } }
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
                                    height: 28
                                    radius: 6
                                    implicitWidth: Math.max(70, setLockTxt.implicitWidth + 16)
                                    color: fontRow.isLockActive
                                        ? Style.withAlpha(root.theme.accentCyan, 0.16)
                                        : (setLockMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                                    border.color: fontRow.isLockActive || setLockMouse.containsMouse
                                        ? root.theme.accentCyan
                                        : root.theme.bgBorder
                                    border.width: fontRow.isLockActive ? 1.5 : 1
                                    scale: setLockMouse.pressed ? 0.94 : (setLockMouse.containsMouse ? 1.04 : 1.0)

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Text {
                                        id: setLockTxt
                                        anchors.centerIn: parent
                                        text: fontRow.isLockActive ? "Lock" : "Set Lock"
                                        font.family: Style.font
                                        font.pixelSize: Style.px(11)
                                        font.bold: true
                                        color: fontRow.isLockActive || setLockMouse.containsMouse
                                            ? root.theme.accentCyan
                                            : root.theme.textSecondary
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: setLockMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.applyFontForRole(fontRow.fam, "lockscreen")
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
    }
}
