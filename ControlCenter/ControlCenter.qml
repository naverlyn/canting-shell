import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./Components"
import "../bar"

PanelWindow {
    id: controlCenter

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property var anchorTarget
    property string barPosition: BarConfig.position
    property int barThickness: BarConfig.barHeight
    property bool barFloating: BarConfig.floating
    property int barWindowWidth: 0
    property int barWindowHeight: 0

    property bool viewNotifications: false

    property real anchorCenterX: 0
    property real anchorCenterY: 0
    property real targetWinWidth: 1920
    property real targetWinHeight: 1080

    function updateAnchorMetrics() {
        if (!anchorTarget || !anchorTarget.QsWindow || !anchorTarget.QsWindow.window) return;
        const win = anchorTarget.QsWindow.window;
        targetWinWidth = win.width > 0 ? win.width : (screen ? screen.width : 1920);
        targetWinHeight = win.height > 0 ? win.height : (screen ? screen.height : 1080);
        const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
        anchorCenterX = pt.x;
        anchorCenterY = pt.y;
    }

    function edgeBarClearance(edgePos) {
        const list = BarConfig.bars || [];
        let maxClearance = 0;
        for (let i = 0; i < list.length; i++) {
            const b = list[i];
            if (!b || b.enabled === false || b.position !== edgePos) continue;
            const h = b.barHeight !== undefined ? b.barHeight : 38;
            const fl = b.floating !== undefined ? b.floating : false;
            const isV = (edgePos === "left" || edgePos === "right");
            const c = isV ? (h + 16 + (fl ? 12 : 0)) : (h + (fl ? 12 : 6));
            if (c > maxClearance) maxClearance = c;
        }
        return maxClearance;
    }

    readonly property bool isVertBar: barPosition === "left" || barPosition === "right"

    readonly property real computedAnchorCenterX: {
        if (anchorTarget && anchorTarget.QsWindow && anchorTarget.QsWindow.window) {
            try {
                const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
                if (pt && pt.x > 0) return pt.x;
            } catch (e) {}
        }
        return anchorCenterX > 0 ? anchorCenterX : (targetWinWidth - 170);
    }

    readonly property real computedAnchorCenterY: {
        if (anchorTarget && anchorTarget.QsWindow && anchorTarget.QsWindow.window) {
            try {
                const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
                if (pt && pt.y > 0) return pt.y;
            } catch (e) {}
        }
        return anchorCenterY > 0 ? anchorCenterY : 100;
    }

    readonly property int ownHorizClearance: (barFloating ? 6 : 0) + barThickness + 6
    readonly property int ownVertClearance: (barFloating ? 6 : 0) + barThickness + 6

    screen: (anchorTarget && anchorTarget.QsWindow.window) ? anchorTarget.QsWindow.window.screen : null
    anchors {
        top: controlCenter.barPosition !== "bottom"
        bottom: controlCenter.barPosition === "bottom"
        left: controlCenter.isVertBar ? (controlCenter.barPosition === "left") : false
        right: controlCenter.isVertBar ? (controlCenter.barPosition === "right") : true
    }
    margins {
        top: {
            if (controlCenter.barPosition === "top") return controlCenter.ownHorizClearance;
            return 10;
        }
        bottom: {
            if (controlCenter.barPosition === "bottom") return controlCenter.ownHorizClearance;
            return 10;
        }
        left: (controlCenter.isVertBar && controlCenter.barPosition === "left") ? controlCenter.ownVertClearance : 10
        right: {
            if (controlCenter.isVertBar) {
                return controlCenter.barPosition === "right" ? controlCenter.ownVertClearance : 10;
            }
            const scrW = (controlCenter.screen && controlCenter.screen.width > 0)
                ? controlCenter.screen.width
                : (controlCenter.targetWinWidth > 0 ? controlCenter.targetWinWidth : 1920);
            const panelWidth = controlCenter.implicitWidth;
            const desiredRight = Math.round(scrW - (controlCenter.computedAnchorCenterX + (panelWidth / 2)));
            return Math.max(10, Math.min(scrW - panelWidth - 10, desiredRight));
        }
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay

    visible: false
    implicitWidth: {
        if (ControlCenterConfig.panelLayout === "horizontal") {
            const cols = Math.max(1, Math.min(ControlCenterConfig.enabledCards.length, 3));
            const total = (ControlCenterConfig.panelWidth * cols) + (12 * (cols - 1)) + 24;
            const scrW = screen ? screen.width : 1920;
            return Math.min(scrW - 40, total);
        }
        return ControlCenterConfig.panelWidth;
    }
    implicitHeight: (screen ? screen.height : 1080) - margins.top - margins.bottom
    mask: Region { item: ccMainRect }
    color: "transparent"

    HyprlandFocusGrab {
        windows: controlCenter.anchorTarget
            ? [controlCenter, controlCenter.anchorTarget.QsWindow.window]
            : [controlCenter]
        active: controlCenter.visible
        onCleared: controlCenter.visible = false
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: controlCenter.visible
        onActivated: controlCenter.visible = false
    }

    signal refreshRequested()

    readonly property int maxCcHeight: Math.max(300, (screen ? screen.height : 1080) - margins.top - margins.bottom - 24)
    readonly property int maxContentAreaHeight: Math.max(160, maxCcHeight - 24
        - (header.visible ? (header.implicitHeight + 12) : 0)
        - (switcher.visible ? (switcher.implicitHeight + 12) : 0))

    property var quickSettingsRef: null
    property var brightnessSliderRef: null

    // Card Drag & Drop State for Live Edit Mode
    property bool isDraggingCard: false
    property string draggedCardId: ""
    property int dragCardSourceIndex: -1
    property int dragCardHoverIndex: -1
    property real dragCardMouseX: 0
    property real dragCardMouseY: 0

    function startCardDrag(cid, srcIdx, mouseX, mouseY) {
        draggedCardId = cid;
        dragCardSourceIndex = srcIdx;
        dragCardHoverIndex = srcIdx;
        dragCardMouseX = mouseX;
        dragCardMouseY = mouseY;
        isDraggingCard = true;
    }

    function updateCardDrag(mouseX, mouseY) {
        dragCardMouseX = mouseX;
        dragCardMouseY = mouseY;
        if (!isDraggingCard) return;
        for (let i = 0; i < cardsRepeater.count; i++) {
            const item = cardsRepeater.itemAt(i);
            if (!item || !item.visible) continue;
            const pt = item.mapFromItem(ccMainRect, mouseX, mouseY);
            if (pt.x >= 0 && pt.x <= item.width && pt.y >= 0 && pt.y <= item.height) {
                if (item.enabledIdx >= 0) {
                    dragCardHoverIndex = item.enabledIdx;
                    return;
                }
            }
        }
    }

    function finishCardDrag() {
        if (!isDraggingCard) return;
        const srcIdx = dragCardSourceIndex;
        const targetIdx = dragCardHoverIndex;
        isDraggingCard = false;
        draggedCardId = "";
        dragCardHoverIndex = -1;
        dragCardSourceIndex = -1;
        if (srcIdx >= 0 && targetIdx >= 0 && srcIdx !== targetIdx) {
            ControlCenterConfig.moveEnabledCard(srcIdx, targetIdx);
        }
    }

    onVisibleChanged: {
        if (visible) {
            updateAnchorMetrics();
            if (ccFlickable) ccFlickable.contentY = 0;
            if (brightnessSliderRef) brightnessSliderRef.refresh();
            if (quickSettingsRef) quickSettingsRef.refresh();
            controlCenter.refreshRequested();
            ccMainRect.forceActiveFocus();
        }
    }

    Component.onCompleted: updateAnchorMetrics()

    Rectangle {
        id: ccMainRect
        anchors {
            top: controlCenter.barPosition === "bottom" ? undefined : parent.top
            bottom: controlCenter.barPosition === "bottom" ? parent.bottom : undefined
            left: parent.left
            right: parent.right
        }
        height: Math.min(controlCenter.maxCcHeight, contentColumn.height + 24)
        radius: 12
        color: controlCenter.theme.bgSurface
        border.color: controlCenter.theme.bgBorder
        border.width: 1
        clip: false

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        focus: true
        Keys.onEscapePressed: controlCenter.visible = false

        opacity: controlCenter.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 12

            // Top Header: Profile, Battery, Settings, Power
            ControlCenterHeader {
                id: header
                width: parent.width
                visible: ControlCenterConfig.showHeader
                theme: controlCenter.theme
                font: controlCenter.font
                onCloseRequested: controlCenter.visible = false
            }

            // Tab Switcher: Control Center / Notifications
            ViewSwitcher {
                id: switcher
                width: parent.width
                visible: ControlCenterConfig.showViewSwitcher
                theme: controlCenter.theme
                font: controlCenter.font
                viewNotifications: controlCenter.viewNotifications
                onViewNotificationsChanged: controlCenter.viewNotifications = viewNotifications
            }

            // Main Content Container
            Item {
                id: mainContentContainer
                width: parent.width
                implicitHeight: controlCenter.viewNotifications
                    ? notificationsView.implicitHeight
                    : Math.min(controlCenter.maxContentAreaHeight, controlCenterView.implicitHeight)
                height: implicitHeight
                clip: true
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                // 1. Control Center View (Scrollable Flickable with WheelHandler & ScrollBar)
                Flickable {
                    id: ccFlickable
                    anchors.fill: parent
                    contentHeight: controlCenterView.implicitHeight
                    contentWidth: width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: !controlCenter.isDraggingCard && (contentHeight > height)
                    opacity: controlCenter.viewNotifications ? 0 : 1
                    x: controlCenter.viewNotifications ? -30 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    WheelHandler {
                        target: ccFlickable
                        enabled: !controlCenter.isDraggingCard
                        onWheel: (event) => {
                            const step = 80;
                            const delta = event.angleDelta.y > 0 ? -step : step;
                            ccFlickable.contentY = Math.max(0, Math.min(ccFlickable.contentHeight - ccFlickable.height, ccFlickable.contentY + delta));
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: ccScrollBar
                        visible: ccFlickable.contentHeight > ccFlickable.height
                        width: 5
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 2.5
                            color: controlCenter.theme.accentPrimary
                            opacity: ccScrollBar.active ? 0.8 : (ccScrollBar.hovered ? 0.6 : 0.3)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Column {
                        id: controlCenterView
                        width: ccFlickable.contentHeight > ccFlickable.height ? (parent.width - 8) : parent.width
                        spacing: 12
                        bottomPadding: 6

                    // Top Banner for Live Edit Mode
                    Rectangle {
                        id: editBanner
                        visible: ControlCenterConfig.isLiveEdit
                        width: parent.width
                        height: 36
                        radius: 8
                        color: Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.15)
                        border.color: controlCenter.theme.accentPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: "󰏫"
                                font.family: controlCenter.font
                                font.pixelSize: 13
                                color: controlCenter.theme.accentPrimary
                            }

                            Text {
                                text: "Edit Mode"
                                font.family: controlCenter.font
                                font.pixelSize: 12
                                font.bold: true
                                color: controlCenter.theme.textPrimary
                                Layout.fillWidth: true
                            }

                            // Reset to default button
                            Rectangle {
                                width: 50
                                height: 24
                                radius: 4
                                color: resetMouse.containsMouse ? Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.14) : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.06)
                                border.color: controlCenter.theme.bgBorder
                                border.width: 1
                                scale: resetMouse.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    font.family: controlCenter.font
                                    font.pixelSize: 11
                                    color: controlCenter.theme.textSecondary
                                }

                                MouseArea {
                                    id: resetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true
                                    onClicked: ControlCenterConfig.resetDefaults()
                                }
                            }

                            // Done button
                            Rectangle {
                                width: 50
                                height: 24
                                radius: 4
                                color: doneMouse.containsMouse ? Qt.lighter(controlCenter.theme.accentPrimary, 1.12) : controlCenter.theme.accentPrimary
                                scale: doneMouse.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Done"
                                    font.family: controlCenter.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: controlCenter.theme.bgBase
                                }

                                MouseArea {
                                    id: doneMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true
                                    onClicked: ControlCenterConfig.isLiveEdit = false
                                }
                            }
                        }
                    }

                    // Dynamically ordered Cards
                    GridLayout {
                        id: cardsGridLayout
                        width: parent.width
                        columns: ControlCenterConfig.panelLayout === "horizontal"
                            ? Math.max(1, Math.min(ControlCenterConfig.enabledCards.length, 3))
                            : 1
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            id: cardsRepeater
                            model: ControlCenterConfig.cardOrder

                            delegate: Column {
                                id: cardWrapper
                                required property string modelData
                                required property int index

                                readonly property string cardId: modelData
                                readonly property int enabledIdx: ControlCenterConfig.getEnabledCardIndex(cardId)
                                readonly property bool isCardEnabled: ControlCenterConfig.isCardVisible(cardId)
                                readonly property bool isBeingDragged: controlCenter.isDraggingCard && controlCenter.draggedCardId === cardId
                                readonly property bool isDropTarget: controlCenter.isDraggingCard && controlCenter.dragCardHoverIndex === enabledIdx && controlCenter.draggedCardId !== cardId

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                width: parent.width
                                spacing: 4

                            scale: isBeingDragged ? 0.96 : (isDropTarget ? 1.02 : 1.0)
                            opacity: isBeingDragged ? 0.35 : 1.0
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                            visible: {
                                if (cardId === "quickSettings") {
                                    return ControlCenterConfig.isLiveEdit || (isCardEnabled && ControlCenterConfig.enabledTiles.length > 0);
                                }
                                if (cardId === "media") {
                                    if (!isCardEnabled) return false;
                                    if (ControlCenterConfig.mediaAutoHide && !ControlCenterConfig.isLiveEdit) {
                                        return cardLoader.item ? cardLoader.item.hasMedia : false;
                                    }
                                    return true;
                                }
                                return isCardEnabled;
                            }

                            // Card Edit Toolbar (shown only during Live Edit Mode)
                            Rectangle {
                                id: cardEditBar
                                visible: ControlCenterConfig.isLiveEdit && cardWrapper.isCardEnabled
                                width: parent.width
                                height: 30
                                radius: 6
                                color: cardWrapper.isDropTarget
                                    ? Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.22)
                                    : (cardDragMouseArea.containsMouse
                                        ? Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.12)
                                        : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.08))
                                border.color: cardWrapper.isDropTarget ? controlCenter.theme.accentPrimary : controlCenter.theme.bgBorder
                                border.width: cardWrapper.isDropTarget ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    // Drag handle grip icon
                                    Text {
                                        text: "󰇘"
                                        font.family: controlCenter.font
                                        font.pixelSize: 14
                                        color: cardWrapper.isDropTarget ? controlCenter.theme.accentPrimary : controlCenter.theme.textMuted
                                    }

                                    Text {
                                        text: ControlCenterConfig.getCardDef(cardWrapper.cardId).icon
                                        font.family: controlCenter.font
                                        font.pixelSize: 12
                                        color: controlCenter.theme.accentPrimary
                                    }

                                    Text {
                                        text: ControlCenterConfig.getCardDef(cardWrapper.cardId).label
                                        font.family: controlCenter.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: controlCenter.theme.textPrimary
                                    }

                                    Text {
                                        text: cardWrapper.isDropTarget ? "Drop here" : (cardDragMouseArea.containsMouse ? "· Drag to reorder" : "")
                                        font.family: controlCenter.font
                                        font.pixelSize: 10
                                        color: cardWrapper.isDropTarget ? controlCenter.theme.accentPrimary : controlCenter.theme.textMuted
                                        Layout.fillWidth: true
                                    }

                                    // Remove Card Button
                                    Rectangle {
                                        implicitWidth: removeText.implicitWidth + 14
                                        height: 22
                                        radius: 4
                                        z: 10
                                        color: cRemoveMouse.containsMouse
                                            ? (controlCenter.theme.accentRed ?? "#e05252")
                                            : Qt.rgba(1, 1, 1, 0.08)
                                        border.color: cRemoveMouse.containsMouse ? (controlCenter.theme.accentRed ?? "#e05252") : controlCenter.theme.bgBorder
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: removeText
                                            anchors.centerIn: parent
                                            text: "Remove"
                                            font.family: controlCenter.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: cRemoveMouse.containsMouse ? "#ffffff" : controlCenter.theme.textSecondary
                                        }

                                        MouseArea {
                                            id: cRemoveMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            preventStealing: true
                                            onClicked: ControlCenterConfig.setCardVisible(cardWrapper.cardId, false)
                                        }
                                    }
                                }

                                // Drag MouseArea covering toolbar except right Remove button
                                MouseArea {
                                    id: cardDragMouseArea
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                        left: parent.left
                                        right: parent.right
                                        rightMargin: 72
                                    }
                                    hoverEnabled: true
                                    cursorShape: controlCenter.isDraggingCard ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    preventStealing: true

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
                                        const pt = cardDragMouseArea.mapToItem(ccMainRect, mouse.x, mouse.y);
                                        if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 5) {
                                            dragStarted = true;
                                            controlCenter.startCardDrag(cardWrapper.cardId, cardWrapper.enabledIdx, pt.x, pt.y);
                                        } else if (dragStarted) {
                                            controlCenter.updateCardDrag(pt.x, pt.y);
                                        }
                                    }

                                    onReleased: (mouse) => {
                                        if (dragStarted) {
                                            const pt = cardDragMouseArea.mapToItem(ccMainRect, mouse.x, mouse.y);
                                            controlCenter.updateCardDrag(pt.x, pt.y);
                                            controlCenter.finishCardDrag();
                                            dragStarted = false;
                                        }
                                    }

                                    onCanceled: {
                                        if (dragStarted) {
                                            controlCenter.finishCardDrag();
                                            dragStarted = false;
                                        }
                                    }
                                }
                            }

                            // Card Component Loader
                            Loader {
                                id: cardLoader
                                width: parent.width
                                sourceComponent: {
                                    switch (cardWrapper.cardId) {
                                    case "quickSettings": return quickSettingsComp;
                                    case "brightness": return brightnessComp;
                                    case "audio": return audioComp;
                                    case "media": return mediaComp;
                                    case "systemInfo": return systemInfoComp;
                                    default: return null;
                                    }
                                }
                            }
                        }
                    }
                }

                    Connections {
                        target: ControlCenterConfig
                        function onCardsUpdated() {
                            const order = ControlCenterConfig.cardOrder;
                            cardsRepeater.model = null;
                            cardsRepeater.model = order;
                        }
                    }

                    // Available Pool Tray in Live Edit Mode
                    Rectangle {
                        id: poolTray
                        visible: ControlCenterConfig.isLiveEdit && (ControlCenterConfig.unassignedCards.length > 0 || ControlCenterConfig.unassignedTiles.length > 0)
                        width: parent.width
                        implicitHeight: poolCol.implicitHeight + 20
                        radius: 10
                        color: Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.05)
                        border.color: controlCenter.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: poolCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 10

                            // Available Sections (Unassigned Cards)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: ControlCenterConfig.unassignedCards.length > 0

                                Text {
                                    text: "Available Sections"
                                    font.family: controlCenter.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: controlCenter.theme.textSecondary
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: ControlCenterConfig.unassignedCards

                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 28
                                            implicitWidth: cChipRow.implicitWidth + 16
                                            radius: 14
                                            color: cChipMouse.containsMouse
                                                ? Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.14)
                                                : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.06)
                                            border.color: controlCenter.theme.accentPrimary
                                            border.width: 1
                                            scale: cChipMouse.pressed ? 0.96 : 1.0
                                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                            RowLayout {
                                                id: cChipRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    text: "+ " + (modelData.icon || "󰒓")
                                                    font.family: controlCenter.font
                                                    font.pixelSize: 12
                                                    color: controlCenter.theme.accentPrimary
                                                }

                                                Text {
                                                    text: modelData.label || ""
                                                    font.family: controlCenter.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: controlCenter.theme.textPrimary
                                                }
                                            }

                                            MouseArea {
                                                id: cChipMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                preventStealing: true
                                                onClicked: ControlCenterConfig.setCardVisible(modelData.id, true)
                                            }
                                        }
                                    }
                                }
                            }

                            // Available Quick Settings Tiles (Unassigned Tiles)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: ControlCenterConfig.unassignedTiles.length > 0

                                Text {
                                    text: "Available Quick Settings Tiles"
                                    font.family: controlCenter.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: controlCenter.theme.textSecondary
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: ControlCenterConfig.unassignedTiles

                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 28
                                            implicitWidth: tChipRow.implicitWidth + 16
                                            radius: 14
                                            color: tChipMouse.containsMouse
                                                ? Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.14)
                                                : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.06)
                                            border.color: controlCenter.theme.bgBorder
                                            border.width: 1
                                            scale: tChipMouse.pressed ? 0.96 : 1.0
                                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                            RowLayout {
                                                id: tChipRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    text: "+ " + (modelData.icon || "󰒓")
                                                    font.family: controlCenter.font
                                                    font.pixelSize: 12
                                                    color: controlCenter.theme.accentPrimary
                                                }

                                                Text {
                                                    text: modelData.label || ""
                                                    font.family: controlCenter.font
                                                    font.pixelSize: 11
                                                    color: controlCenter.theme.textPrimary
                                                }
                                            }

                                            MouseArea {
                                                id: tChipMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                preventStealing: true
                                                onClicked: ControlCenterConfig.addTile(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

                // 2. Notifications View
                NotificationsView {
                    id: notificationsView
                    width: parent.width
                    opacity: controlCenter.viewNotifications ? 1 : 0
                    x: controlCenter.viewNotifications ? 0 : 30
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    theme: controlCenter.theme
                    font: controlCenter.font
                }
            }
        }

        // Floating card drag ghost
        Rectangle {
            id: cardDragGhost
            readonly property bool active: controlCenter.isDraggingCard && controlCenter.draggedCardId !== ""
            visible: opacity > 0.01
            z: 9999
            width: 200
            height: 36
            radius: 8
            color: controlCenter.theme.bgSurface
            border.color: controlCenter.theme.accentPrimary
            border.width: 1.5
            scale: active ? 1.05 : 0.85
            opacity: active ? 0.95 : 0.0
            x: Math.max(10, Math.min(ccMainRect.width - width - 10, controlCenter.dragCardMouseX - (width / 2)))
            y: Math.max(10, Math.min(ccMainRect.height - height - 10, controlCenter.dragCardMouseY - (height / 2)))

            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    font.family: controlCenter.font
                    font.pixelSize: 14
                    color: controlCenter.theme.accentPrimary
                    text: ControlCenterConfig.getCardDef(controlCenter.draggedCardId).icon
                }

                Text {
                    font.family: controlCenter.font
                    font.pixelSize: 12
                    font.bold: true
                    color: controlCenter.theme.textPrimary
                    text: ControlCenterConfig.getCardDef(controlCenter.draggedCardId).label
                }

                Text {
                    font.family: controlCenter.font
                    font.pixelSize: 10
                    color: controlCenter.theme.accentPrimary
                    text: "󰁝 Move"
                }
            }
        }
    }

    // Card Component Templates
    Component {
        id: quickSettingsComp
        QuickSettingsGrid {
            id: qsGrid
            theme: controlCenter.theme
            font: controlCenter.font
            onCloseParentRequested: controlCenter.visible = false
            onOpenWifiRequested: {
                controlCenter.visible = false;
                if (!wifiModalLoader.active) {
                    wifiModalLoader.active = true;
                } else if (wifiModalLoader.item) {
                    wifiModalLoader.item.visible = true;
                }
            }
            Component.onCompleted: controlCenter.quickSettingsRef = qsGrid
        }
    }

    Component {
        id: brightnessComp
        BrightnessSlider {
            id: bSlider
            theme: controlCenter.theme
            font: controlCenter.font
            Component.onCompleted: controlCenter.brightnessSliderRef = bSlider
        }
    }

    Component {
        id: audioComp
        AudioSection {
            theme: controlCenter.theme
            font: controlCenter.font
        }
    }

    Component {
        id: mediaComp
        MediaControl {
            theme: controlCenter.theme
            font: controlCenter.font
        }
    }

    Component {
        id: systemInfoComp
        SystemInfoCard {
            theme: controlCenter.theme
            font: controlCenter.font
        }
    }

    // Modal Wi-Fi Selector Dialog (lazy loaded)
    Loader {
        id: wifiModalLoader
        active: false
        sourceComponent: Component {
            WifiSelectorModal {
                theme: controlCenter.theme
                font: controlCenter.font
                wifiEnabled: controlCenter.quickSettingsRef ? controlCenter.quickSettingsRef.wifiEnabled : true
                onSetWifiRequested: (enabled) => { if (controlCenter.quickSettingsRef) controlCenter.quickSettingsRef.setWifi(enabled); }
                onToggleWifiRequested: { if (controlCenter.quickSettingsRef) controlCenter.quickSettingsRef.toggleWifi(); }
                onNetworkConnected: (ssid) => {
                    if (controlCenter.quickSettingsRef) controlCenter.quickSettingsRef.refresh();
                }
                onNetworkDisconnected: (ssid) => {
                    if (controlCenter.quickSettingsRef) controlCenter.quickSettingsRef.refresh();
                }
                Component.onCompleted: {
                    visible = true;
                }
            }
        }
    }
}