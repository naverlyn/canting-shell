import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

MouseArea {
    required property var root
    id: dragArea
    property string widgetId: ""
    property int panelIdx: -1
    property int itemIdx: -1
    signal clickedWithoutDrag()

    preventStealing: true
    cursorShape: root.isDraggingBlock ? Qt.ClosedHandCursor : Qt.OpenHandCursor

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
        const pt = dragArea.mapToItem(root, mouse.x, mouse.y);
        if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
            dragStarted = true;
            root.startBlockDrag(dragArea.widgetId, dragArea.panelIdx, dragArea.itemIdx, pt.x, pt.y);
        } else if (dragStarted) {
            root.updateBlockDragHover(pt.x, pt.y);
        }
    }

    onReleased: (mouse) => {
        if (dragStarted) {
            const pt = dragArea.mapToItem(root, mouse.x, mouse.y);
            root.updateBlockDragHover(pt.x, pt.y);
            root.finishBlockDrag();
            dragStarted = false;
        } else {
            dragArea.clickedWithoutDrag();
        }
    }

    onCanceled: {
        if (dragStarted) {
            root.finishBlockDrag();
            dragStarted = false;
        }
    }
}
