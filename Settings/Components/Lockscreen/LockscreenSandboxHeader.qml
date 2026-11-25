import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

RowLayout {
    required property var stageRoot
    Layout.fillWidth: true
    spacing: 10

    ColumnLayout {
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            spacing: 8
            Text {
                text: "Interactive Lock Screen Stage"
                font.family: stageRoot.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: stageRoot.theme.textPrimary
            }

            // Live Unsaved Pill
            Rectangle {
                visible: stageRoot.hasUnsavedMoves
                height: 18
                implicitWidth: unBadgeText.implicitWidth + 10
                radius: 4
                color: Qt.rgba(stageRoot.theme.accentOrange.r, stageRoot.theme.accentOrange.g, stageRoot.theme.accentOrange.b, 0.18)
                border.color: Qt.rgba(stageRoot.theme.accentOrange.r, stageRoot.theme.accentOrange.g, stageRoot.theme.accentOrange.b, 0.4)
                border.width: 1

                Text {
                    id: unBadgeText
                    anchors.centerIn: parent
                    text: "Unsaved Moves"
                    font.family: stageRoot.font
                    font.pixelSize: Style.px(9)
                    font.bold: true
                    color: stageRoot.theme.accentOrange
                }
            }
        }

        Text {
            text: stageRoot.previewMode
                ? "Live Preview Mode active: rendering real clock, date, and lock screen typography"
                : "Drag any label or password box across the screen (snaps to center & sibling edges)"
            font.family: stageRoot.font
            font.pixelSize: Style.px(11)
            color: stageRoot.theme.textSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    Item { Layout.fillWidth: true }

    // Action & Mode Buttons
    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.fillWidth: false
        Layout.preferredWidth: implicitWidth
        Layout.minimumWidth: implicitWidth

        // Preview Animation Button
        Rectangle {
            implicitWidth: previewAnimLabel.implicitWidth + 20
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: previewStageHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase
            border.color: previewStageHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.bgBorder
            border.width: 1
            scale: previewStageMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: previewStageHover }

            Text {
                id: previewAnimLabel
                anchors.centerIn: parent
                text: "Preview Anim"
                font.family: stageRoot.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: previewStageHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: previewStageMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: stageRoot.playAnimationPreview(LockscreenConfig.animation_style)
            }
        }

        // Snap Toggle Button
        Rectangle {
            implicitWidth: snapLabel.implicitWidth + 20
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: stageRoot.snapEnabled
                ? stageRoot.theme.bgSelected
                : (snapToggleHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase)
            border.color: stageRoot.snapEnabled || snapToggleHover.hovered
                ? stageRoot.theme.accentPrimary
                : stageRoot.theme.bgBorder
            border.width: 1
            scale: snapToggleMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: snapToggleHover }

            Text {
                id: snapLabel
                anchors.centerIn: parent
                text: "Snap"
                font.family: stageRoot.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: stageRoot.snapEnabled ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: snapToggleMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: stageRoot.snapEnabled = !stageRoot.snapEnabled
            }
        }

        // Snap Selected to Center X: 0
        Rectangle {
            visible: (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) || stageRoot.selectedIndex === -2
            implicitWidth: snapText.implicitWidth + 20
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: snapHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase
            border.color: snapHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.bgBorder
            border.width: 1
            scale: snapMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: snapHover }

            Text {
                id: snapText
                anchors.centerIn: parent
                text: "Center X: 0"
                font.family: stageRoot.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: stageRoot.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: snapMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (stageRoot.selectedIndex === -2) {
                        stageRoot.liveInputX = 0;
                        stageRoot.inputHalign = "center";
                        stageRoot.hasUnsavedMoves = true;
                        stageRoot.inputMoved(0, stageRoot.liveInputY, "center", stageRoot.inputValign);
                        stageRoot.refreshTrigger++;
                    } else if (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) {
                        let b = stageRoot.liveBlocks[stageRoot.selectedIndex];
                        b.halign = "center";
                        b.position_x = 0;
                        stageRoot.hasUnsavedMoves = true;
                        stageRoot.blockMoved(stageRoot.selectedIndex, 0, b.position_y, "center", b.valign);
                        stageRoot.liveBlocks = stageRoot.liveBlocks.slice();
                        stageRoot.refreshTrigger++;
                    }
                }
            }
        }

        // Remove Selected Module Button
        Rectangle {
            visible: stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length
            implicitWidth: delSelRow.implicitWidth + 18
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: delSelHover.hovered ? Qt.rgba(stageRoot.theme.accentRed.r, stageRoot.theme.accentRed.g, stageRoot.theme.accentRed.b, 0.22) : Qt.rgba(stageRoot.theme.accentRed.r, stageRoot.theme.accentRed.g, stageRoot.theme.accentRed.b, 0.12)
            border.color: stageRoot.theme.accentRed
            border.width: 1
            scale: delSelMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: delSelHover }

            RowLayout {
                id: delSelRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "✕"
                    font.family: stageRoot.font
                    font.pixelSize: Style.px(9)
                    font.bold: true
                    color: stageRoot.theme.accentRed
                }

                Text {
                    text: "Remove"
                    font.family: stageRoot.font
                    font.pixelSize: Style.px(11)
                    font.bold: true
                    color: stageRoot.theme.accentRed
                }
            }

            MouseArea {
                id: delSelMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: stageRoot.removeModule(stageRoot.selectedIndex)
            }
        }

        // Reset Positions Button
        Rectangle {
            visible: stageRoot.hasUnsavedMoves
            implicitWidth: resetText.implicitWidth + 20
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: resetHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase
            border.color: resetHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.bgBorder
            border.width: 1
            scale: resetMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: resetHover }

            Text {
                id: resetText
                anchors.centerIn: parent
                text: "Reset"
                font.family: stageRoot.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: stageRoot.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    stageRoot.hasUnsavedMoves = false;
                    stageRoot.syncBlocks();
                    stageRoot.resetRequested();
                    stageRoot.refreshTrigger++;
                }
            }
        }

        // Apply Layout / Save Positions Button
        Rectangle {
            implicitWidth: applyText.implicitWidth + 24
            Layout.preferredWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            height: 30
            radius: 6
            color: stageRoot.hasUnsavedMoves
                ? (applyHover.hovered ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.25) : stageRoot.theme.bgSelected)
                : (applyHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase)
            border.color: stageRoot.hasUnsavedMoves || applyHover.hovered
                ? stageRoot.theme.accentPrimary
                : stageRoot.theme.bgBorder
            border.width: 1
            scale: applyMouse.pressed ? 0.95 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: applyHover }

            Text {
                id: applyText
                anchors.centerIn: parent
                text: stageRoot.hasUnsavedMoves ? "Apply Layout" : "Save Positions"
                font.family: stageRoot.font
                font.pixelSize: Style.px(11)
                font.bold: true
                color: stageRoot.hasUnsavedMoves ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    stageRoot.hasUnsavedMoves = false;
                    stageRoot.applyRequested(stageRoot.liveBlocks);
                }
            }
        }
    }
}
