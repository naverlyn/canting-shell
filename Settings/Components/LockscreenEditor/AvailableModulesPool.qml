import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Lockscreen"

Rectangle {
    id: poolRoot
    required property var hostRoot

    readonly property bool isPoolDropTarget: hostRoot.isDraggingBlock && hostRoot.isOverPool
    readonly property var allDefs: LockscreenConfig.availableModuleDefs || []
    readonly property var activeModules: hostRoot.textBlocks || []

    function isModulePlaced(mType) {
        if (!activeModules) return false;
        for (let i = 0; i < activeModules.length; i++) {
            if (activeModules[i] && activeModules[i].type === mType) return true;
        }
        return false;
    }

    function getPlacedIndex(mType) {
        if (!activeModules) return -1;
        for (let i = 0; i < activeModules.length; i++) {
            if (activeModules[i] && activeModules[i].type === mType) return i;
        }
        return -1;
    }

    Layout.fillWidth: true
    implicitHeight: poolCol.implicitHeight + 24
    radius: 10
    color: isPoolDropTarget
        ? Qt.rgba(hostRoot.theme.accentRed.r, hostRoot.theme.accentRed.g, hostRoot.theme.accentRed.b, 0.12)
        : hostRoot.theme.bgBase
    border.color: isPoolDropTarget
        ? hostRoot.theme.accentRed
        : hostRoot.theme.bgBorder
    border.width: isPoolDropTarget ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    ColumnLayout {
        id: poolCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 12

        // Header matching Picture 2
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Available Building Blocks"
                font.family: hostRoot.font
                font.pixelSize: 11
                font.bold: true
                color: poolRoot.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary
            }

            Text {
                text: "(" + poolRoot.allDefs.length + " available)"
                font.family: hostRoot.font
                font.pixelSize: 11
                color: hostRoot.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: poolRoot.isPoolDropTarget
                    ? "Release here to remove from Lock Screen"
                    : "Drag block into live preview above or click to add"
                font.family: hostRoot.font
                font.pixelSize: 10
                font.bold: poolRoot.isPoolDropTarget
                color: poolRoot.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.textMuted
                elide: Text.ElideRight
            }
        }

        // Flow of chips matching Picture 2
        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: poolRoot.allDefs
                delegate: Rectangle {
                    id: chipCard
                    required property var modelData

                    readonly property string mType: modelData.type
                    readonly property string mName: modelData.name
                    readonly property string mIcon: modelData.icon || "󰆍"
                    readonly property bool isPlaced: poolRoot.isModulePlaced(mType)
                    readonly property bool isBeingDragged: hostRoot.isDraggingBlock && hostRoot.draggedModType === mType

                    implicitWidth: chipRow.implicitWidth + 22
                    implicitHeight: 34
                    width: implicitWidth
                    height: implicitHeight
                    radius: 8

                    scale: isBeingDragged ? 0.94 : (chipHover.hovered ? 1.02 : 1.0)
                    opacity: isBeingDragged ? 0.35 : 1.0

                    color: chipHover.hovered
                        ? hostRoot.theme.bgHover
                        : hostRoot.theme.bgSurface
                    border.color: chipHover.hovered
                        ? hostRoot.theme.accentPrimary
                        : hostRoot.theme.bgBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    HoverHandler { id: chipHover }

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: chipCard.mIcon
                            font.family: hostRoot.font
                            font.pixelSize: 13
                            color: hostRoot.theme.accentPrimary
                        }

                        Text {
                            text: chipCard.mName
                            font.family: hostRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: hostRoot.theme.textPrimary
                        }

                        // Plus Icon (+) strictly matching Picture 2
                        Text {
                            text: "󰐕"
                            font.family: hostRoot.font
                            font.pixelSize: 10
                            color: chipHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                            opacity: chipHover.hovered ? 1.0 : 0.6
                        }
                    }

                    MouseArea {
                        id: chipDragArea
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: hostRoot.isDraggingBlock ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                        property real pressX: 0
                        property real pressY: 0
                        property bool dragStarted: false

                        onPressed: (mouse) => {
                            pressX = mouse.x;
                            pressY = mouse.y;
                            dragStarted = false;
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return;
                            const pt = chipDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                dragStarted = true;
                                hostRoot.startModuleDrag(
                                    chipCard.mType,
                                    chipCard.mName,
                                    chipCard.mIcon,
                                    pt.x,
                                    pt.y
                                );
                            } else if (dragStarted) {
                                hostRoot.updateModuleDrag(pt.x, pt.y);
                            }
                        }

                        onReleased: (mouse) => {
                            if (dragStarted) {
                                const pt = chipDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                                hostRoot.updateModuleDrag(pt.x, pt.y);
                                hostRoot.finishModuleDrag();
                                dragStarted = false;
                            } else {
                                hostRoot.addModule(chipCard.mType);
                            }
                        }

                        onCanceled: {
                            if (dragStarted) {
                                hostRoot.finishModuleDrag();
                                dragStarted = false;
                            }
                        }
                    }
                }
            }
        }
    }
}

