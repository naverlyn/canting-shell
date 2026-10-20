import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

Rectangle {
    required property var root
    property alias animationCurveEditorRowInstRef: animationCurveEditorRowInst
    id: customStudioCard
    visible: root.isCreatingCustom
    Layout.fillWidth: true
    radius: 12
    color: root.theme.bgSurface
    border.color: root.theme.accentPrimary
    border.width: 1.5
    implicitHeight: studioCol.implicitHeight + 36
    clip: true

    ColumnLayout {
        id: studioCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // 1. Studio Header & Top Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: root.newAnimName ? ("Animation Studio • " + root.newAnimName) : "Animation Studio • Custom Profile"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Design Bézier curves, motion physics, and Hyprland animation tree rules"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            // Top Action Buttons (Strictly text-only, matching modern theme buttons)
            AnimationTopActionButtons {
                root: customStudioCard.root
            }
        }

        // Profile Name Input Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Profile Name"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
                Layout.preferredWidth: 100
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 7
                color: root.theme.bgBase
                border.color: nameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textPrimary
                    text: root.newAnimName
                    onTextChanged: root.newAnimName = text
                }
            }
        }

        // 2. Side-by-Side: Bézier Curve Manager (Left) & Motion Sandbox Preview (Right)
        AnimationCurveEditorRow {
            id: animationCurveEditorRowInst
            root: customStudioCard.root
        }

        // 3. Categorized Hyprland Animation Rules Tree
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 14

            // Section Header & Global Action
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true

                    Text {
                        text: "Compositor Animation Rules (Hyprland Tree)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Configure target rules, speeds, and Bézier easing curves according to Hyprland's official animation tree"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                // Expand All / Collapse All Toggle Button
                Rectangle {
                    height: 30
                    implicitWidth: expBtnText.implicitWidth + 24
                    radius: 7
                    color: expHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgSurface
                    border.color: expHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: expHover }

                    Text {
                        id: expBtnText
                        anchors.centerIn: parent
                        text: root.expandAllRules ? "Collapse All" : "Expand All"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: expHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expandAllRules = !root.expandAllRules
                    }
                }
            }

            /* Sub-Tab Navigation Bar (Matching HyprlandSettings & BarSettings) */
            Rectangle {
                id: subTabTrack
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "All", label: "All Rules" },
                            { id: "Windows", label: "Windows" },
                            { id: "Layers", label: "Layers" },
                            { id: "Workspaces", label: "Workspaces" },
                            { id: "Fades & Borders", label: "Fades & Borders" }
                        ]
                        delegate: Rectangle {
                            id: subTabItem
                            required property var modelData
                            readonly property bool isCurrent: root.studioCategoryFilter === modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            border.width: 0

                            HoverHandler { id: subTabHover }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                radius: 1
                                width: subTabItem.isCurrent
                                    ? subTabRow.implicitWidth + 16
                                    : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                                opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                                color: subTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }

                            Row {
                                id: subTabRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? root.theme.accentPrimary
                                        : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.studioCategoryFilter = subTabItem.modelData.id
                            }
                        }
                    }
                }
            }

            // Category Groups
            Repeater {
                model: root.studioCategories

                delegate: AnimationRuleCategoryDelegate {
                    root: customStudioCard.root
                }
            }
        }

        // 4. Studio Footer Action Bar
        AnimationStudioFooterButtons {
            root: customStudioCard.root
        }
    }
}
