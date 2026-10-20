import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    readonly property string targetTitle: {
        if (root.selectedColorTargetType === "bar") return "Bar Background";
        if (root.selectedColorTargetType === "panel") return "Entire " + BarConfig.getPanelTitle(root.selectedColorPanelIndex);
        return BarConfig.getWidgetMeta(root.selectedColorWidgetId).name;
    }
    title: "2. Assign Color for: " + targetTitle
    titleColor: root.theme.accentPrimary
    subtitle: "Current: " + root.getSpecLabel(root.getActiveTargetSpec())
    subtitleColor: root.resolveThemeSpec(root.getActiveTargetSpec(), root.theme.textSecondary)
    subtitleBold: true
    contentSpacing: 14

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Active Theme Semantic Roles (" + ((root.theme && root.theme.currentName) ? root.theme.currentName : "Current Theme") + ")"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textSecondary
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.themeRoles
                delegate: Rectangle {
                    id: semanticRoleBtn
                    required property var modelData
                    readonly property string activeSpec: root.getActiveTargetSpec()
                    readonly property bool isChosen: activeSpec === modelData.key
                    readonly property color roleCol: modelData.key === ""
                        ? root.theme.accentPrimary
                        : root.resolveThemeSpec(modelData.key, root.theme.accentPrimary)

                    implicitWidth: semanticRoleTxt.implicitWidth + 20
                    implicitHeight: 32
                    width: implicitWidth
                    height: implicitHeight
                    radius: 8
                    scale: sRoleMouse.pressed ? 0.94 : (sRoleHover.hovered ? 1.05 : 1.0)
                    color: isChosen
                        ? root.theme.bgSelected
                        : (sRoleHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                    border.color: isChosen || sRoleHover.hovered ? roleCol : root.theme.bgBorder
                    border.width: isChosen ? 1.5 : 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: sRoleHover }

                    Text {
                        id: semanticRoleTxt
                        anchors.centerIn: parent
                        text: semanticRoleBtn.modelData.label
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: semanticRoleBtn.modelData.key === ""
                            ? (semanticRoleBtn.isChosen ? root.theme.textPrimary : root.theme.textSecondary)
                            : semanticRoleBtn.roleCol
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: sRoleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyColorToActiveTarget(semanticRoleBtn.modelData.key)
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: root.theme.bgBorder
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "All Palettes (" + root.filteredThemesList.length + " themes)"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 280
                height: 30
                radius: 7
                color: root.theme.bgBase
                border.color: themeSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: themeSearchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textPrimary
                    selectByMouse: true
                    onTextChanged: root.themeSearchQuery = text

                    Text {
                        visible: parent.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search (e.g. Night, Mocha, Taiga)..."
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            height: 280
            contentHeight: themesGrid.implicitHeight + 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: root.theme.bgBorder
                }
            }

            GridLayout {
                id: themesGrid
                width: parent.width - 10
                columns: 2
                columnSpacing: 10
                rowSpacing: 8

                Repeater {
                    model: root.filteredThemesList
                    delegate: Rectangle {
                        id: themePaletteCard
                        required property var modelData
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: themeCardHover.hovered ? root.theme.bgHover : root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1

                        HoverHandler { id: themeCardHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            ColumnLayout {
                                spacing: 1
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: themePaletteCard.modelData.name
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: themePaletteCard.modelData.family || "Theme"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    color: root.theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: root.themeAccentKeys
                                    delegate: Rectangle {
                                        id: swatchRect
                                        required property var modelData
                                        readonly property string fullSpec: "theme:" + themePaletteCard.modelData.name + ":" + modelData.key
                                        readonly property bool isChosen: root.getActiveTargetSpec() === fullSpec
                                        readonly property color swatchCol: themePaletteCard.modelData[modelData.key]
                                            ? Qt.color(String(themePaletteCard.modelData[modelData.key]))
                                            : root.theme.accentPrimary

                                        width: 18
                                        height: 14
                                        radius: 4
                                        scale: swatchMouse.pressed ? 0.90 : (swatchHover.hovered ? 1.18 : (isChosen ? 1.08 : 1.0))
                                        color: swatchCol
                                        border.color: isChosen ? root.theme.textPrimary : (swatchHover.hovered ? root.theme.textSecondary : root.theme.bgBorder)
                                        border.width: isChosen ? 2 : 1

                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        HoverHandler { id: swatchHover }

                                        MouseArea {
                                            id: swatchMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyColorToActiveTarget(swatchRect.fullSpec)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
