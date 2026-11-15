import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    required property string font
    required property var workspaces
    required property var toplevels
    required property string searchQuery

    signal searchQueryChangedByUser(string query)
    signal windowClicked(var toplevel)
    signal windowClosed(var toplevel)
    signal windowMoved(var toplevel, int wsId)
    signal workspaceClicked(int wsId)

    property var draggedToplevel: null
    property real dragSceneX: 0
    property real dragSceneY: 0
    property int hoveredWsId: -1

    readonly property int nextNewWsId: {
        let maxId = 0;
        for (let i = 0; i < root.workspaces.length; i++) {
            if (root.workspaces[i] && root.workspaces[i].id > maxId) {
                maxId = root.workspaces[i].id;
            }
        }
        return maxId + 1;
    }

    readonly property int firstGapWsId: {
        const used = {};
        for (let i = 0; i < root.workspaces.length; i++) {
            if (root.workspaces[i] && root.workspaces[i].id > 0) {
                used[root.workspaces[i].id] = true;
            }
        }
        for (let id = 1; id < root.nextNewWsId; id++) {
            if (!used[id]) return id;
        }
        return -1;
    }

    function windowsForWorkspace(wsId) {
        const q = root.searchQuery.trim().toLowerCase();
        return root.toplevels.filter(t => {
            if (!t || !t.workspace || t.workspace.id !== wsId) return false;
            if (q === "") return true;
            const title = (t.title || "").toLowerCase();
            const cls = ((t.lastIpcObject && (t.lastIpcObject.class || t.lastIpcObject.initialClass)) || "").toLowerCase();
            return title.indexOf(q) !== -1 || cls.indexOf(q) !== -1;
        });
    }

    function focusSearch() {
        searchInput.forceActiveFocus();
    }

    function updateHoveredWorkspace(sceneX, sceneY) {
        root.dragSceneX = sceneX;
        root.dragSceneY = sceneY;

        if (sceneX < 0 || sceneY < 0) {
            root.hoveredWsId = -1;
            return;
        }

        // Check existing workspace cards
        for (let i = 0; i < wsRepeater.count; i++) {
            const item = wsRepeater.itemAt(i);
            if (!item) continue;
            const local = item.mapFromItem(null, sceneX, sceneY);
            if (local.x >= 0 && local.y >= 0 && local.x <= item.width && local.y <= item.height) {
                root.hoveredWsId = item.wsId;
                return;
            }
        }

        // Check first empty gap workspace card (if any)
        if (gapWsCard.visible) {
            const localGap = gapWsCard.mapFromItem(null, sceneX, sceneY);
            if (localGap.x >= 0 && localGap.y >= 0 && localGap.x <= gapWsCard.width && localGap.y <= gapWsCard.height) {
                root.hoveredWsId = root.firstGapWsId;
                return;
            }
        }

        // Check "+ New Workspace" drop card
        if (newWsCard.visible) {
            const localNew = newWsCard.mapFromItem(null, sceneX, sceneY);
            if (localNew.x >= 0 && localNew.y >= 0 && localNew.x <= newWsCard.width && localNew.y <= newWsCard.height) {
                root.hoveredWsId = root.nextNewWsId;
                return;
            }
        }

        root.hoveredWsId = -1;
    }

    function finishDrag(sceneX, sceneY) {
        updateHoveredWorkspace(sceneX, sceneY);
        const top = root.draggedToplevel;
        const targetWs = root.hoveredWsId;
        const sourceWs = (top && top.workspace) ? top.workspace.id : -1;

        root.draggedToplevel = null;
        root.hoveredWsId = -1;

        if (top && targetWs > 0 && targetWs !== sourceWs) {
            root.windowMoved(top, targetWs);
        }
    }

    implicitWidth: 960
    implicitHeight: Math.min(620, col.implicitHeight)

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 14

        // Filter Input Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: root.theme.bgSurface
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: root.font
                    font.pixelSize: 14
                    color: root.theme.textMuted
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: root.theme.textPrimary
                    font.family: root.font
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: root.searchQueryChangedByUser(text)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Filter windows by title or app... (drag cards to move between workspaces)"
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.textMuted
                        visible: searchInput.text.length === 0
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(540, wsGrid.implicitHeight)
            contentHeight: wsGrid.implicitHeight
            clip: true
            interactive: root.draggedToplevel === null
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: wsGrid
                width: parent.width
                columns: 2
                rowSpacing: 14
                columnSpacing: 14

                Repeater {
                    id: wsRepeater
                    model: root.workspaces

                    delegate: Rectangle {
                        id: wsCard
                        required property var modelData
                        readonly property int wsId: modelData.id
                        readonly property var wsWindows: root.windowsForWorkspace(wsId)
                        readonly property bool isActiveWs: Boolean(modelData.active)
                        readonly property bool isDropTarget: root.draggedToplevel !== null
                            && root.hoveredWsId === wsId
                            && (!root.draggedToplevel.workspace || root.draggedToplevel.workspace.id !== wsId)

                        Layout.fillWidth: true
                        implicitHeight: Math.max(196, wsCol.implicitHeight + 24)
                        radius: 14
                        color: isDropTarget
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
                            : root.theme.bgSurface
                        border.width: (isActiveWs || isDropTarget) ? 2 : 1
                        border.color: (isActiveWs || isDropTarget) ? root.theme.accentPrimary : root.theme.bgBorder
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.workspaceClicked(wsCard.wsId)
                        }

                        ColumnLayout {
                            id: wsCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 12
                            }
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Workspace " + (wsCard.modelData.name || wsCard.wsId)
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: (wsCard.isActiveWs || wsCard.isDropTarget) ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: wsCard.isDropTarget
                                        ? "Drop to move here"
                                        : (wsCard.wsWindows.length + (wsCard.wsWindows.length === 1 ? " window" : " windows"))
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: wsCard.isDropTarget
                                    color: wsCard.isDropTarget ? root.theme.accentPrimary : root.theme.textMuted
                                }
                            }

                            Text {
                                visible: wsCard.wsWindows.length === 0
                                Layout.fillWidth: true
                                Layout.topMargin: 36
                                horizontalAlignment: Text.AlignHCenter
                                text: root.searchQuery.trim() !== "" ? "No matching windows" : "Empty workspace — click to switch"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textMuted
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                visible: wsCard.wsWindows.length > 0
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 10

                                Repeater {
                                    model: wsCard.wsWindows

                                    delegate: WindowPreviewCard {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        compact: true
                                        dragEnabled: true
                                        isDragging: root.draggedToplevel === modelData
                                        theme: root.theme
                                        font: root.font
                                        toplevel: modelData
                                        isSelected: false
                                        onClicked: root.windowClicked(modelData)
                                        onCloseClicked: root.windowClosed(modelData)
                                        onDragStarted: (top, sx, sy) => {
                                            root.draggedToplevel = top;
                                            root.updateHoveredWorkspace(sx, sy);
                                        }
                                        onDragMoved: (sx, sy) => root.updateHoveredWorkspace(sx, sy)
                                        onDragEnded: (sx, sy) => root.finishDrag(sx, sy)
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty gap workspace drop target (e.g. WS 2 when WS 1 and WS 3 exist)
                Rectangle {
                    id: gapWsCard
                    visible: root.draggedToplevel !== null && root.firstGapWsId > 0
                    readonly property bool isDropTarget: root.hoveredWsId === root.firstGapWsId

                    Layout.fillWidth: true
                    implicitHeight: 196
                    radius: 14
                    color: isDropTarget
                        ? Qt.rgba(root.theme.accentCyan.r, root.theme.accentCyan.g, root.theme.accentCyan.b, 0.16)
                        : Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.55)
                    border.width: isDropTarget ? 2 : 1
                    border.color: isDropTarget ? root.theme.accentCyan : root.theme.bgBorder
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰆏"
                            font.family: root.font
                            font.pixelSize: 26
                            color: gapWsCard.isDropTarget ? root.theme.accentCyan : root.theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Move to Workspace " + root.firstGapWsId
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: gapWsCard.isDropTarget
                            color: gapWsCard.isDropTarget ? root.theme.accentCyan : root.theme.textSecondary
                        }
                    }
                }

                // "+ New Workspace" drop target (shown while dragging)
                Rectangle {
                    id: newWsCard
                    visible: root.draggedToplevel !== null
                    readonly property bool isDropTarget: root.hoveredWsId === root.nextNewWsId

                    Layout.fillWidth: true
                    implicitHeight: 196
                    radius: 14
                    color: isDropTarget
                        ? Qt.rgba(root.theme.accentGreen.r, root.theme.accentGreen.g, root.theme.accentGreen.b, 0.16)
                        : Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.55)
                    border.width: isDropTarget ? 2 : 1
                    border.color: isDropTarget ? root.theme.accentGreen : root.theme.bgBorder
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰐕"
                            font.family: root.font
                            font.pixelSize: 26
                            color: newWsCard.isDropTarget ? root.theme.accentGreen : root.theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Move to Workspace " + root.nextNewWsId
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: newWsCard.isDropTarget
                            color: newWsCard.isDropTarget ? root.theme.accentGreen : root.theme.textSecondary
                        }
                    }
                }
            }
        }
    }

    // Floating Drag Ghost
    Rectangle {
        id: dragGhost
        visible: root.draggedToplevel !== null
        readonly property point localPos: root.draggedToplevel !== null
            ? root.mapFromItem(null, root.dragSceneX, root.dragSceneY)
            : Qt.point(0, 0)
        readonly property string ghostClass: (root.draggedToplevel && root.draggedToplevel.lastIpcObject && (root.draggedToplevel.lastIpcObject.class || root.draggedToplevel.lastIpcObject.initialClass)) || ""
        readonly property var ghostEntry: ghostClass !== "" ? DesktopEntries.heuristicLookup(ghostClass) : null
        readonly property string ghostIcon: (ghostEntry && ghostEntry.icon) ? Quickshell.iconPath(ghostEntry.icon, true) : ""

        x: localPos.x - width / 2
        y: localPos.y - height / 2
        width: 210
        height: 44
        radius: 10
        z: 100
        color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.94)
        border.width: 2
        border.color: root.theme.accentPrimary

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            IconImage {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                source: dragGhost.ghostIcon
                visible: dragGhost.ghostIcon !== ""
            }

            Text {
                Layout.fillWidth: true
                text: (root.draggedToplevel && root.draggedToplevel.title) ? root.draggedToplevel.title : "Moving window..."
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
            }
        }
    }
}
