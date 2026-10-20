import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

ColumnLayout {
    id: self
    required property var root
    Layout.fillWidth: true
    spacing: 10

    // Header & Filters
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Animation Profiles & Presets"
            font.family: root.font
            font.pixelSize: 14
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            text: "(" + root.filteredPresets.length + " profiles)"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
        }

        Item { Layout.fillWidth: true }

        // Search input
        Rectangle {
            width: 180
            height: 28
            radius: 14
            color: root.theme.bgSurface
            border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textPrimary
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter
                    onTextChanged: root.searchQuery = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search presets..."
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }
            }
        }
    }

    // Family Filter Pills
    Row {
        spacing: 6
        Layout.fillWidth: true

        Repeater {
            model: root.families

            Rectangle {
                required property var modelData
                height: 26
                implicitWidth: famText.implicitWidth + 16
                radius: 13
                color: root.selectedFamily === modelData
                    ? root.theme.bgSelected
                    : (famMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgSurface)
                border.color: root.selectedFamily === modelData ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    id: famText
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: root.selectedFamily === parent.modelData
                    color: root.selectedFamily === parent.modelData ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    id: famMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedFamily = parent.modelData
                }
            }
        }
    }

    // Presets Grid Layout
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: root.filteredPresets

            Rectangle {
                id: presetCard
                required property var modelData
                required property int index

                Layout.fillWidth: true
                height: 84
                radius: 10
                color: modelData.active
                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                    : (cardMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : root.theme.bgSurface)
                border.color: modelData.active
                    ? root.theme.accentPrimary
                    : (cardMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                border.width: modelData.active ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                scale: cardMouse.pressed ? 0.98 : 1.0

                // Background card click area
                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: presetCard.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!presetCard.modelData.active) {
                            root.applyPreset(presetCard.modelData.id, presetCard.modelData.displayName);
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    z: 2

                    // Details column
                    ColumnLayout {
                        spacing: 3
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            spacing: 6

                            Text {
                                text: presetCard.modelData.displayName || presetCard.modelData.name
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: presetCard.modelData.active ? root.theme.accentPrimary : root.theme.textPrimary
                                elide: Text.ElideRight
                            }

                            // Family tag
                            Rectangle {
                                height: 16
                                implicitWidth: famTagText.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    id: famTagText
                                    anchors.centerIn: parent
                                    text: presetCard.modelData.family
                                    font.family: root.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }
                            }
                        }

                        Text {
                            text: presetCard.modelData.description || ""
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Bezier and rule count pills
                        Row {
                            spacing: 6

                            Text {
                                text: presetCard.modelData.bezierCount + " beziers • " + presetCard.modelData.animCount + " rules"
                                font.family: root.font
                                font.pixelSize: 9
                                color: root.theme.textMuted
                            }
                        }
                    }

                    // Action Buttons (Edit + Delete for Custom + Apply / Active)
                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        // Edit button to modify custom or clone built-in presets
                        Rectangle {
                            height: 28
                            implicitWidth: editBtnText.implicitWidth + 16
                            radius: 6
                            color: editMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : Qt.rgba(1, 1, 1, 0.05)
                            border.color: editMouse.containsMouse ? root.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                id: editBtnText
                                anchors.centerIn: parent
                                text: "Edit"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: editMouse.containsMouse ? root.theme.accentPrimary : root.theme.textSecondary
                            }

                            MouseArea {
                                id: editMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.editPreset(presetCard.modelData);
                                }
                            }
                        }

                        // Delete button for user custom profiles
                        Rectangle {
                            visible: Boolean(presetCard.modelData.isCustom)
                            height: 28
                            implicitWidth: delBtnText.implicitWidth + 16
                            radius: 6
                            color: delMouse.containsMouse ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                            border.color: delMouse.containsMouse ? "#f7768e" : Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                id: delBtnText
                                anchors.centerIn: parent
                                text: "Delete"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: delMouse.containsMouse ? "#f7768e" : root.theme.textMuted
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.deleteCustomPreset(presetCard.modelData.id);
                                }
                            }
                        }

                        // Apply / Active Button
                        Rectangle {
                            height: 28
                            implicitWidth: actionBtnText.implicitWidth + 18
                            radius: 6
                            color: presetCard.modelData.active
                                ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                                : (applyBtnMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)))
                            border.color: presetCard.modelData.active ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: actionBtnText
                                anchors.centerIn: parent
                                text: presetCard.modelData.active ? "Active" : "Apply"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: presetCard.modelData.active
                                    ? root.theme.accentPrimary
                                    : (applyBtnMouse.containsMouse ? "#ffffff" : root.theme.textPrimary)
                            }

                            MouseArea {
                                id: applyBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: presetCard.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (!presetCard.modelData.active) {
                                        root.applyPreset(presetCard.modelData.id, presetCard.modelData.displayName);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state when filter has no results
        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            height: 90
            radius: 10
            visible: root.filteredPresets.length === 0
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "No animation profiles match your filter"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: root.selectedFamily === "Custom"
                        ? "Click 'New Animation' above to create your own profile"
                        : "Try selecting 'All' or clearing your search query"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
