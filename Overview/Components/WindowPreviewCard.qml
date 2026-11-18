import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property string font
    required property var toplevel
    required property bool isSelected
    property bool compact: false
    property bool showWsBadge: true
    property bool dragEnabled: false
    property bool isDragging: false

    signal clicked()
    signal closeClicked()
    signal hovered()
    signal dragStarted(var toplevel, real globalX, real globalY)
    signal dragMoved(real globalX, real globalY)
    signal dragEnded(real globalX, real globalY)

    readonly property string appClass: (toplevel && toplevel.lastIpcObject && (toplevel.lastIpcObject.class || toplevel.lastIpcObject.initialClass)) || ""
    readonly property string windowTitle: (toplevel && toplevel.title) ? toplevel.title : (appClass !== "" ? appClass : "Window")
    readonly property int wsId: (toplevel && toplevel.workspace) ? toplevel.workspace.id : -1
    readonly property bool isFocused: Boolean(toplevel && toplevel.activated)
    readonly property var desktopEntry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string iconSource: (desktopEntry && desktopEntry.icon) ? Quickshell.iconPath(desktopEntry.icon, true) : ""
    readonly property var ipcSize: (toplevel && toplevel.lastIpcObject && Array.isArray(toplevel.lastIpcObject.size))
        ? toplevel.lastIpcObject.size
        : null
    readonly property real windowAspect: (ipcSize && ipcSize.length >= 2 && ipcSize[0] > 0 && ipcSize[1] > 0)
        ? Math.max(0.55, Math.min(2.2, ipcSize[0] / ipcSize[1]))
        : (16 / 10)
    readonly property int previewTargetHeight: compact ? 112 : 142
    readonly property int aspectCardWidth: Math.max(compact ? 128 : 160, Math.round(previewTargetHeight * windowAspect) + 16)

    implicitWidth: compact ? aspectCardWidth : 250
    implicitHeight: compact ? 156 : 186
    radius: 14
    color: root.isSelected
        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
        : (cardMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
    border.width: root.isSelected ? 2 : 1
    border.color: root.isSelected
        ? root.theme.accentPrimary
        : (root.isFocused ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5) : root.theme.bgBorder)

    opacity: root.isDragging ? 0.32 : 1.0
    scale: cardMouse.pressed && !root.isDragging ? 0.97 : 1.0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool dragging: false
        property real pressX: 0
        property real pressY: 0

        onEntered: root.hovered()
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton && root.dragEnabled) {
                pressX = mouse.x;
                pressY = mouse.y;
                dragging = false;
            }
        }
        onPositionChanged: (mouse) => {
            if (!pressed || !root.dragEnabled || !(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging) {
                const dx = mouse.x - pressX;
                const dy = mouse.y - pressY;
                if (dx * dx + dy * dy > 64) {
                    dragging = true;
                    const pt = cardMouse.mapToItem(null, mouse.x, mouse.y);
                    root.dragStarted(root.toplevel, pt.x, pt.y);
                }
            }
            if (dragging) {
                const pt = cardMouse.mapToItem(null, mouse.x, mouse.y);
                root.dragMoved(pt.x, pt.y);
            }
        }
        onReleased: (mouse) => {
            if (dragging) {
                dragging = false;
                const pt = cardMouse.mapToItem(null, mouse.x, mouse.y);
                root.dragEnded(pt.x, pt.y);
            }
        }
        onCanceled: {
            if (dragging) {
                dragging = false;
                root.dragEnded(-1, -1);
            }
        }
        onClicked: (mouse) => {
            if (dragging) return;
            if (mouse.button === Qt.MiddleButton) {
                root.closeClicked();
            } else {
                root.clicked();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Live Window Thumbnail Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 9
            color: root.theme.bgBase
            border.width: 1
            border.color: root.theme.bgBorder
            clip: true

            ScreencopyView {
                id: preview
                anchors.fill: parent
                captureSource: (root.visible && root.toplevel && root.toplevel.wayland) ? root.toplevel.wayland : null
                live: false
                paintCursor: false
                constraintSize: Qt.size(Math.max(1, width), Math.max(1, height))
                visible: hasContent

                property bool retried: false
                function requestSnap() {
                    if (!root.visible || !captureSource) return;
                    preview.captureFrame();
                    if (!preview.hasContent && !preview.retried) {
                        preview.retried = true;
                        screencopyRetryTimer.restart();
                    }
                }
                Component.onCompleted: Qt.callLater(() => preview.requestSnap())
                onCaptureSourceChanged: {
                    retried = false;
                    Qt.callLater(() => preview.requestSnap());
                }
            }

            Timer {
                id: screencopyRetryTimer
                interval: 250
                repeat: false
                onTriggered: {
                    if (root.visible && preview.captureSource && !preview.hasContent) {
                        preview.captureFrame();
                    }
                }
            }

            // Fallback when no screencopy frame is available yet
            Item {
                anchors.fill: parent
                visible: !preview.hasContent

                IconImage {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    source: root.iconSource
                    visible: root.iconSource !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource === ""
                    text: "󰖯"
                    font.family: root.font
                    font.pixelSize: 28
                    color: root.theme.textMuted
                }
            }

            // Workspace badge (top-left)
            Rectangle {
                visible: root.showWsBadge && root.wsId > 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 6
                implicitWidth: wsLbl.implicitWidth + 12
                implicitHeight: 20
                radius: 6
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.85)
                border.width: 1
                border.color: root.theme.bgBorder

                Text {
                    id: wsLbl
                    anchors.centerIn: parent
                    text: "WS " + root.wsId
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.isFocused ? root.theme.accentPrimary : root.theme.textSecondary
                }
            }

            // Close window button (top-right on hover/select)
            Rectangle {
                visible: cardMouse.containsMouse || closeMouse.containsMouse || root.isSelected
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: 22
                height: 22
                radius: 11
                color: closeMouse.containsMouse
                    ? root.theme.accentRed
                    : Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.85)
                border.width: 1
                border.color: closeMouse.containsMouse ? root.theme.accentRed : root.theme.bgBorder
                z: 2

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: root.font
                    font.pixelSize: 10
                    color: closeMouse.containsMouse ? root.theme.bgBase : root.theme.textSecondary
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeClicked()
                }
            }
        }

        // Bottom Title & Icon Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconImage {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: root.iconSource
                visible: root.iconSource !== ""
            }

            Text {
                Layout.fillWidth: true
                text: root.windowTitle
                font.family: root.font
                font.pixelSize: 12
                font.bold: root.isSelected || root.isFocused
                color: root.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
