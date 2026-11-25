import QtQuick
import QtQuick.Layouts
import Quickshell

// Reusable 2-column Active / Available drag-and-drop & click-to-assign list editor.
Item {
    id: editor

    required property var rootRef
    property var activeItems: []
    property var availableItems: []
    property string idKey: "id"
    property string labelKey: "name"
    property string iconKey: "icon"
    property string fallbackIcon: "󰄲"
    property int minActiveCount: 1
    property string activeTitle: "Active Items"
    property string availableTitle: "Available Items"
    property string emptyAvailableText: "All items active"
    property int minPanelHeight: 190
    property int cardHeight: 38
    property color panelSurfaceColor: rootRef.theme.bgBase

    signal addRequested(string itemId)
    signal removeRequested(string itemId)
    signal reorderRequested(string itemId, int targetIndex)

    implicitHeight: grid.implicitHeight
    Layout.fillWidth: true

    property string dragId: ""
    property string dragLabel: ""
    property bool dragFromAvail: false
    property bool dragOverAvail: false
    property int dragHoverIndex: -1
    property real dragX: 0
    property real dragY: 0

    function _itemId(obj) {
        return obj && obj[editor.idKey] !== undefined ? String(obj[editor.idKey]) : "";
    }
    function _itemLabel(obj) {
        if (!obj) return "";
        if (obj[editor.labelKey] !== undefined) return String(obj[editor.labelKey]);
        return obj.name || obj.label || "";
    }
    function _itemIcon(obj) {
        return (obj && obj[editor.iconKey]) ? String(obj[editor.iconKey]) : editor.fallbackIcon;
    }

    function updateDrag(localX, localY) {
        editor.dragX = localX;
        editor.dragY = localY;
        const ap = activePanel.mapFromItem(editor, localX, localY);
        if (ap.x >= -8 && ap.x <= activePanel.width + 8 && ap.y >= -8 && ap.y <= activePanel.height + 8) {
            editor.dragOverAvail = false;
            const listPt = activeListCol.mapFromItem(editor, localX, localY);
            const cnt = activeRepeater.count;
            let found = cnt;
            for (let i = 0; i < cnt; i++) {
                const it = activeRepeater.itemAt(i);
                if (!it) continue;
                if (listPt.y <= it.y + it.height * 0.5) {
                    found = i;
                    break;
                }
            }
            editor.dragHoverIndex = found;
            return;
        }
        const avp = availPanel.mapFromItem(editor, localX, localY);
        if (!editor.dragFromAvail && avp.x >= -8 && avp.x <= availPanel.width + 8 && avp.y >= -8 && avp.y <= availPanel.height + 8) {
            editor.dragOverAvail = true;
            editor.dragHoverIndex = -1;
            return;
        }
        editor.dragOverAvail = false;
        editor.dragHoverIndex = -1;
    }

    function finishDrag() {
        const id = editor.dragId;
        if (!id) return;
        if (editor.dragOverAvail && !editor.dragFromAvail) {
            editor.removeRequested(id);
        } else if (editor.dragHoverIndex >= 0) {
            if (editor.dragFromAvail) {
                editor.addRequested(id);
                editor.reorderRequested(id, editor.dragHoverIndex);
            } else {
                const curIds = (editor.activeItems || []).map(it => editor._itemId(it));
                const fromIdx = curIds.indexOf(id);
                let target = editor.dragHoverIndex;
                if (fromIdx !== -1 && fromIdx < target) {
                    target = Math.max(0, target - 1);
                }
                editor.reorderRequested(id, target);
            }
        }
        editor.dragId = "";
        editor.dragLabel = "";
        editor.dragFromAvail = false;
        editor.dragOverAvail = false;
        editor.dragHoverIndex = -1;
    }

    // Floating drag ghost
    Rectangle {
        id: dragGhost
        readonly property bool active: editor.dragId !== ""
        readonly property bool isRemoving: active && editor.dragOverAvail && !editor.dragFromAvail

        visible: opacity > 0.01
        z: 9999
        implicitWidth: ghostTxt.implicitWidth + 28
        width: implicitWidth
        height: 36
        radius: 8
        x: Math.max(4, Math.min(editor.width - width - 4, editor.dragX - (width / 2)))
        y: Math.max(4, Math.min(editor.height - height - 4, editor.dragY - (height / 2)))
        scale: active ? 1.04 : 0.92
        opacity: active ? 0.96 : 0.0
        color: isRemoving ? editor.rootRef.withAlpha(editor.rootRef.theme.accentRed, 0.18) : editor.rootRef.theme.bgSelected
        border.color: isRemoving ? editor.rootRef.theme.accentRed : editor.rootRef.theme.accentPrimary
        border.width: 1.5

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Text {
            id: ghostTxt
            anchors.centerIn: parent
            text: dragGhost.isRemoving ? ("Remove " + editor.dragLabel) : editor.dragLabel
            font.family: editor.rootRef.font
            font.pixelSize: 11
            font.bold: true
            color: dragGhost.isRemoving ? editor.rootRef.theme.accentRed : editor.rootRef.theme.textPrimary
        }
    }

    GridLayout {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        // Left Panel: Active Items
        Rectangle {
            id: activePanel
            readonly property bool isPanelTarget: editor.dragId !== "" && !editor.dragOverAvail && editor.dragHoverIndex >= 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.max(editor.minPanelHeight, activeCol.implicitHeight + 20)
            radius: 10
            color: isPanelTarget ? editor.rootRef.withAlpha(editor.rootRef.theme.accentPrimary, 0.06) : editor.panelSurfaceColor
            border.color: isPanelTarget ? editor.rootRef.theme.accentPrimary : editor.rootRef.theme.bgBorder
            border.width: isPanelTarget ? 1.5 : 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            ColumnLayout {
                id: activeCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 7
                    color: editor.rootRef.theme.bgSelected

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: editor.activeTitle
                            font.family: editor.rootRef.font
                            font.pixelSize: 11
                            font.bold: true
                            color: editor.rootRef.theme.accentPrimary
                        }

                        Rectangle {
                            implicitWidth: actBadgeTxt.implicitWidth + 10
                            implicitHeight: 18
                            radius: 9
                            color: editor.rootRef.withAlpha(editor.rootRef.theme.textMuted, 0.12)

                            Text {
                                id: actBadgeTxt
                                anchors.centerIn: parent
                                text: "(" + (editor.activeItems || []).length + ")"
                                font.family: editor.rootRef.font
                                font.pixelSize: 10
                                color: editor.rootRef.theme.textMuted
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                Column {
                    id: activeListCol
                    Layout.fillWidth: true
                    spacing: 6
                    move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                    add: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }

                    Repeater {
                        id: activeRepeater
                        model: ScriptModel {
                            values: editor.activeItems || []
                            objectProp: editor.idKey
                        }
                        delegate: Rectangle {
                            id: activeCard
                            required property var modelData
                            required property int index
                            readonly property string itemId: editor._itemId(modelData)
                            readonly property string itemLabel: editor._itemLabel(modelData)
                            readonly property string itemIcon: editor._itemIcon(modelData)
                            readonly property bool isDragged: editor.dragId === itemId
                            readonly property bool isBeforeThis: editor.dragId !== "" && !isDragged && editor.dragHoverIndex === index
                            readonly property bool isAfterThis: editor.dragId !== "" && !isDragged && (
                                (editor.dragHoverIndex === index + 1) ||
                                (index === activeRepeater.count - 1 && editor.dragHoverIndex >= activeRepeater.count)
                            )
                            readonly property bool isDropTarget: isBeforeThis || isAfterThis

                            width: activeListCol.width
                            height: editor.cardHeight
                            radius: 8
                            scale: isDragged ? 0.96 : 1.0
                            opacity: isDragged ? 0.35 : 1.0
                            color: isDropTarget
                                ? editor.rootRef.theme.bgSelected
                                : (actCardHover.hovered ? editor.rootRef.theme.bgHover : editor.rootRef.theme.bgBase)
                            border.color: (isDropTarget || isDragged)
                                ? editor.rootRef.theme.accentPrimary
                                : (actCardHover.hovered ? editor.rootRef.theme.accentPrimary : editor.rootRef.theme.bgBorder)
                            border.width: isDropTarget ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            HoverHandler { id: actCardHover }

                            Rectangle {
                                visible: activeCard.isDropTarget
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                y: activeCard.isAfterThis ? parent.height - 3 : 1
                                height: 2
                                radius: 1
                                color: editor.rootRef.theme.accentPrimary
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: "󰍜"
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 11
                                    color: actCardHover.hovered ? editor.rootRef.theme.textSecondary : editor.rootRef.theme.textMuted
                                    opacity: actCardHover.hovered ? 0.85 : 0.35
                                    Layout.preferredWidth: 12
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: activeCard.itemIcon
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 13
                                    color: editor.rootRef.theme.accentPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.preferredWidth: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: activeCard.itemLabel
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: editor.rootRef.theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                RowLayout {
                                    id: actBtnRow
                                    z: 2
                                    spacing: 3
                                    Layout.alignment: Qt.AlignVCenter

                                    MiniIconButton {
                                        visible: actCardHover.hovered && activeCard.index > 0
                                        iconText: "󰅃"
                                        onClicked: editor.reorderRequested(activeCard.itemId, activeCard.index - 1)
                                    }

                                    MiniIconButton {
                                        visible: actCardHover.hovered && activeCard.index < activeRepeater.count - 1
                                        iconText: "󰅀"
                                        onClicked: editor.reorderRequested(activeCard.itemId, activeCard.index + 1)
                                    }

                                    MiniIconButton {
                                        visible: (editor.activeItems || []).length > editor.minActiveCount
                                        iconText: "󰅖"
                                        dangerHover: true
                                        onClicked: editor.removeRequested(activeCard.itemId)
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: actBtnRow.width + 10
                                preventStealing: true
                                cursorShape: editor.dragId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                property real pressX: 0
                                property real pressY: 0
                                property bool dragging: false

                                onPressed: (mouse) => {
                                    pressX = mouse.x;
                                    pressY = mouse.y;
                                    dragging = false;
                                }
                                onPositionChanged: (mouse) => {
                                    if (!pressed) return;
                                    const pt = mapToItem(editor, mouse.x, mouse.y);
                                    if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                        dragging = true;
                                        editor.dragId = activeCard.itemId;
                                        editor.dragLabel = activeCard.itemLabel;
                                        editor.dragFromAvail = false;
                                    }
                                    if (dragging) {
                                        editor.updateDrag(pt.x, pt.y);
                                    }
                                }
                                onReleased: (mouse) => {
                                    if (dragging) {
                                        const pt = mapToItem(editor, mouse.x, mouse.y);
                                        editor.updateDrag(pt.x, pt.y);
                                        editor.finishDrag();
                                    }
                                    dragging = false;
                                }
                                onCanceled: {
                                    if (dragging) editor.finishDrag();
                                    dragging = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right Panel: Available Items
        Rectangle {
            id: availPanel
            readonly property bool isPoolTarget: editor.dragId !== "" && editor.dragOverAvail && !editor.dragFromAvail
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.max(editor.minPanelHeight, availCol.implicitHeight + 20)
            radius: 10
            color: isPoolTarget ? editor.rootRef.withAlpha(editor.rootRef.theme.accentRed, 0.12) : editor.panelSurfaceColor
            border.color: isPoolTarget ? editor.rootRef.theme.accentRed : editor.rootRef.theme.bgBorder
            border.width: isPoolTarget ? 1.5 : 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            ColumnLayout {
                id: availCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 7
                    color: editor.rootRef.theme.bgSelected

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: editor.availableTitle
                            font.family: editor.rootRef.font
                            font.pixelSize: 11
                            font.bold: true
                            color: editor.rootRef.theme.textSecondary
                        }

                        Rectangle {
                            implicitWidth: avBadgeTxt.implicitWidth + 10
                            implicitHeight: 18
                            radius: 9
                            color: editor.rootRef.withAlpha(editor.rootRef.theme.textMuted, 0.12)

                            Text {
                                id: avBadgeTxt
                                anchors.centerIn: parent
                                text: "(" + (editor.availableItems || []).length + ")"
                                font.family: editor.rootRef.font
                                font.pixelSize: 10
                                color: editor.rootRef.theme.textMuted
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: editor.availableItems || []
                        delegate: Rectangle {
                            id: availCard
                            required property var modelData
                            readonly property string itemId: editor._itemId(modelData)
                            readonly property string itemLabel: editor._itemLabel(modelData)
                            readonly property string itemIcon: editor._itemIcon(modelData)

                            Layout.fillWidth: true
                            height: editor.cardHeight
                            radius: 8
                            color: avHover.hovered ? editor.rootRef.theme.bgHover : editor.rootRef.theme.bgBase
                            border.color: avHover.hovered ? editor.rootRef.theme.accentPrimary : editor.rootRef.theme.bgBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: avHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: availCard.itemIcon
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 13
                                    color: avHover.hovered ? editor.rootRef.theme.accentPrimary : editor.rootRef.theme.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.preferredWidth: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: availCard.itemLabel
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: avHover.hovered ? editor.rootRef.theme.textPrimary : editor.rootRef.theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    visible: avHover.hovered
                                    text: "󰐕"
                                    font.family: editor.rootRef.font
                                    font.pixelSize: 12
                                    color: editor.rootRef.theme.accentPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                cursorShape: editor.dragId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                property real pressX: 0
                                property real pressY: 0
                                property bool dragging: false

                                onPressed: (mouse) => {
                                    pressX = mouse.x;
                                    pressY = mouse.y;
                                    dragging = false;
                                }
                                onPositionChanged: (mouse) => {
                                    if (!pressed) return;
                                    const pt = mapToItem(editor, mouse.x, mouse.y);
                                    if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                        dragging = true;
                                        editor.dragId = availCard.itemId;
                                        editor.dragLabel = availCard.itemLabel;
                                        editor.dragFromAvail = true;
                                    }
                                    if (dragging) {
                                        editor.updateDrag(pt.x, pt.y);
                                    }
                                }
                                onReleased: (mouse) => {
                                    if (dragging) {
                                        const pt = mapToItem(editor, mouse.x, mouse.y);
                                        editor.updateDrag(pt.x, pt.y);
                                        editor.finishDrag();
                                    } else {
                                        editor.addRequested(availCard.itemId);
                                    }
                                    dragging = false;
                                }
                                onCanceled: {
                                    if (dragging) editor.finishDrag();
                                    dragging = false;
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (editor.availableItems || []).length === 0
                        Layout.fillWidth: true
                        implicitHeight: 68
                        radius: 8
                        color: "transparent"
                        border.color: editor.rootRef.theme.bgBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: editor.emptyAvailableText
                            font.family: editor.rootRef.font
                            font.pixelSize: 11
                            color: editor.rootRef.theme.textMuted
                        }
                    }
                }
            }
        }
    }
}
