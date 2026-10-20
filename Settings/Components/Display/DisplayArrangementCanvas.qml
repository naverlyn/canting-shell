import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

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
            text: "Display Arrangement"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
        }

        Text {
            text: root.editState.length > 1
                ? "·  Drag displays to arrange layout or click to configure"
                : "·  Live preview of active display geometry and orientation"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: root.selectedMonitor !== null
            text: root.selectedMonitor
                ? ("Selected: " + root.selectedMonitor.name)
                : ""
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.accentPrimary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: arrangementCol.implicitHeight + 24
        radius: 12
        color: root.theme.bgSurface
        border.color: root.hasUnsavedChanges
            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.45)
            : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 160 } }

        ColumnLayout {
            id: arrangementCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 12

            /* Embedded Interactive MonitorCanvas */
            Rectangle {
                Layout.fillWidth: true
                height: 195
                radius: 10
                color: root.theme.bgBase
                border.color: root.hasOverlap
                    ? (root.theme.accentOrange ?? "#ff9e64")
                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: root.hasOverlap ? 1.5 : 1
                clip: true

                MonitorCanvas {
                    id: inlineCanvas
                    anchors.fill: parent
                    anchors.margins: 2
                    monitors: root.editState
                    selectedIndex: root.selectedIndex
                    theme: root.theme
                    font: root.font

                    onMonitorSelected: idx => {
                        root.selectedIndex = idx;
                        root.closeAllDropdowns();
                    }
                    onMonitorMoved: (idx, nx, ny) => {
                        const copy = root.editState.slice();
                        copy[idx] = Object.assign({}, root.editState[idx], { x: nx, y: ny });
                        root.editState = copy;
                    }
                }

                /* Top-left subtle coordinate badge for selected monitor */
                Rectangle {
                    visible: root.selectedMonitor !== null && !root.selectedMonitor.disabled
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 10
                    height: 22
                    implicitWidth: coordText.implicitWidth + 14
                    radius: 6
                    color: Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.88)
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    Text {
                        id: coordText
                        anchors.centerIn: parent
                        text: root.selectedMonitor
                            ? (Math.round(MonitorUtils.logicalW(root.selectedMonitor)) + " × " +
                               Math.round(MonitorUtils.logicalH(root.selectedMonitor)) + " logical  ·  (" +
                               Math.round(root.selectedMonitor.x) + ", " + Math.round(root.selectedMonitor.y) + ")")
                            : ""
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textSecondary
                    }
                }
            }

            /* Monitor Selector Pills */
            Flow {
                Layout.fillWidth: true
                spacing: 8
                visible: root.editState.length > 0

                Repeater {
                    model: root.editState
                    delegate: Rectangle {
                        id: monTabPill
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: root.selectedIndex === index

                        height: 34
                        implicitWidth: monPillRow.implicitWidth + 22
                        radius: 8
                        color: isCurrent
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16)
                            : (monPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase)
                        border.color: isCurrent
                            ? root.theme.accentPrimary
                            : (monPillHover.hovered ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.18)) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                        border.width: isCurrent ? 1.5 : 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: monPillHover }

                        RowLayout {
                            id: monPillRow
                            anchors.centerIn: parent
                            spacing: 8

                            /* Active status dot */
                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: monTabPill.modelData.disabled
                                    ? root.theme.textMuted
                                    : (root.theme.accentGreen ?? root.theme.accentPrimary)
                            }

                            Text {
                                text: monTabPill.modelData.name
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: monTabPill.isCurrent
                                color: monTabPill.isCurrent ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            Text {
                                text: monTabPill.modelData.disabled
                                    ? "Disabled"
                                    : (monTabPill.modelData.selectedMode || "").replace("Hz", " Hz")
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = monTabPill.index;
                                root.closeAllDropdowns();
                            }
                        }
                    }
                }
            }

            /* Error / Overlap Warning Banner (Text-only) */
            Rectangle {
                Layout.fillWidth: true
                visible: root.applyError !== "" || root.hasOverlap
                height: 38
                radius: 8
                color: Qt.rgba((root.theme.accentRed ?? "#f7768e").r, (root.theme.accentRed ?? "#f7768e").g, (root.theme.accentRed ?? "#f7768e").b, 0.14)
                border.color: root.theme.accentRed ?? "#f7768e"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.applyError !== ""
                            ? root.applyError
                            : "Displays are overlapping — drag them apart before applying."
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentRed ?? "#f7768e"
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.applyError !== ""
                        text: "Dismiss"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentRed ?? "#f7768e"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyError = ""
                        }
                    }
                }
            }

            /* Unsaved Changes Action Bar (Text-only) */
            Rectangle {
                Layout.fillWidth: true
                visible: root.hasUnsavedChanges || root.isApplying
                height: 46
                radius: 8
                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.1)
                border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true

                        Text {
                            text: root.isApplying ? "Applying display changes…" : "Unsaved Display Changes"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: MonitorService.persistenceAvailable
                                ? ("Will apply live and save to ~/.config/hypr/monitors." + MonitorService.configFormat)
                                : "Will apply live to current Hyprland session"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    /* Revert Button */
                    Rectangle {
                        width: 68
                        height: 30
                        radius: 6
                        color: revertHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : root.theme.bgBase
                        border.color: revertHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        enabled: !root.isApplying

                        HoverHandler { id: revertHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Revert"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.revertDisplayChanges()
                        }
                    }

                    /* Apply & Save Button */
                    Rectangle {
                        width: 108
                        height: 30
                        radius: 6
                        readonly property bool canApply: !root.isApplying && !MonitorService.loading && !root.hasOverlap
                        color: !canApply
                            ? root.theme.bgSelected
                            : (applyBtnHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                        opacity: canApply ? 1.0 : 0.5

                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: applyBtnHover }

                        Text {
                            anchors.centerIn: parent
                            text: root.isApplying ? "Applying…" : "Apply & Save"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: parent.canApply ? root.theme.bgBase : root.theme.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.canApply
                            cursorShape: parent.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.applyDisplayChanges()
                        }
                    }
                }
            }
        }
    }
}
