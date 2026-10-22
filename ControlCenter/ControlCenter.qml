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
        const scr = (win && win.screen) ? win.screen : (screen ? screen : null);
        targetWinWidth = (scr && scr.width > 0) ? scr.width : 1920;
        targetWinHeight = (scr && scr.height > 0) ? scr.height : 1080;
        try {
            const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
            if (pt && pt.x !== undefined && !isNaN(pt.x) && pt.x >= 0) anchorCenterX = pt.x;
            if (pt && pt.y !== undefined && !isNaN(pt.y) && pt.y >= 0) anchorCenterY = pt.y;
        } catch (e) {}
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
            void anchorTarget.x;
            void anchorTarget.width;
            try {
                const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
                if (pt && pt.x !== undefined && !isNaN(pt.x) && pt.x >= 0) return pt.x;
            } catch (e) {}
        }
        return anchorCenterX > 0 ? anchorCenterX : (targetWinWidth - 170);
    }

    readonly property real computedAnchorCenterY: {
        if (anchorTarget && anchorTarget.QsWindow && anchorTarget.QsWindow.window) {
            void anchorTarget.y;
            void anchorTarget.height;
            try {
                const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
                if (pt && pt.y !== undefined && !isNaN(pt.y) && pt.y >= 0) return pt.y;
            } catch (e) {}
        }
        return anchorCenterY > 0 ? anchorCenterY : 100;
    }

    readonly property real vertTopLimit: Math.max(10, controlCenter.edgeBarClearance("top") + (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0) + 6)
    readonly property real vertBottomLimit: Math.max(10, controlCenter.edgeBarClearance("bottom") + (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0) + 6)
    readonly property real horizLeftLimit: Math.max(10, controlCenter.edgeBarClearance("left") + (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0) + 6)
    readonly property real horizRightLimit: Math.max(10, controlCenter.edgeBarClearance("right") + (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0) + 6)

    readonly property real clampedVertY: {
        const scrH = (controlCenter.screen && controlCenter.screen.height > 0)
            ? controlCenter.screen.height
            : (controlCenter.targetWinHeight > 0 ? controlCenter.targetWinHeight : 1080);
        const rectH = ccMainRect ? ccMainRect.height : 500;
        const desiredY = Math.round(controlCenter.computedAnchorCenterY - (rectH / 2));
        const maxY = Math.max(controlCenter.vertTopLimit, scrH - controlCenter.vertBottomLimit - rectH);
        return Math.max(controlCenter.vertTopLimit, Math.min(maxY, desiredY));
    }

    readonly property bool fluidEnabled: (BarConfig.fluidCards !== false) && !barFloating && Boolean(BarConfig.innerCorners)
    readonly property int ownHorizClearance: (barFloating ? 6 : 0) + barThickness + (fluidEnabled ? 0 : 6)
    readonly property int ownVertClearance: (barFloating ? 6 : 0) + barThickness + (fluidEnabled ? 0 : 6)

    screen: (anchorTarget && anchorTarget.QsWindow.window) ? anchorTarget.QsWindow.window.screen : null
    anchors {
        top: controlCenter.isVertBar ? true : (controlCenter.barPosition !== "bottom")
        bottom: controlCenter.isVertBar ? true : (controlCenter.barPosition === "bottom")
        left: controlCenter.isVertBar ? (controlCenter.barPosition === "left") : false
        right: controlCenter.isVertBar ? (controlCenter.barPosition === "right") : true
    }
    margins {
        top: {
            if (controlCenter.isVertBar) return 0;
            if (controlCenter.barPosition === "top") return controlCenter.ownHorizClearance;
            return 10;
        }
        bottom: {
            if (controlCenter.isVertBar) return 0;
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
            return Math.max(controlCenter.horizRightLimit, Math.min(scrW - panelWidth - controlCenter.horizLeftLimit, desiredRight));
        }
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property int activePanelCols: {
        if (ControlCenterConfig.panelLayout !== "horizontal") return 1;
        const maxP = Math.max(1, Math.min(3, ControlCenterConfig.panelCount));
        if (ControlCenterConfig.isLiveEdit) return maxP;
        let nonEmpty = 0;
        for (let p = 0; p < maxP; p++) {
            if (ControlCenterConfig.getPanelIds(p).length > 0) nonEmpty++;
        }
        return Math.max(1, nonEmpty);
    }

    visible: false
    implicitWidth: {
        if (ControlCenterConfig.panelLayout === "horizontal") {
            const cols = controlCenter.activePanelCols;
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

    readonly property int maxCcHeight: {
        const scrH = (screen ? screen.height : 1080);
        if (controlCenter.isVertBar) {
            return Math.max(300, scrH - controlCenter.vertTopLimit - controlCenter.vertBottomLimit - 16);
        }
        return Math.max(300, scrH - margins.top - margins.bottom - 24);
    }
    readonly property int maxContentAreaHeight: Math.max(160, maxCcHeight - 24
        - (header.visible ? (header.implicitHeight + 12) : 0)
        - (switcher.visible ? (switcher.implicitHeight + 12) : 0))

    property var quickSettingsRef: null
    property var brightnessSliderRef: null

    // Card Drag & Drop State for Live Edit Mode (supports cross-panel drag & drop)
    property bool isDraggingCard: false
    property string draggedCardId: ""
    property int dragCardSourceIndex: -1
    property int dragCardHoverIndex: -1
    property int dragCardTargetPanel: -1
    property int dragCardTargetItemIdx: -1
    property real dragCardMouseX: 0
    property real dragCardMouseY: 0

    function startCardDrag(cid, srcIdx, mouseX, mouseY) {
        draggedCardId = cid;
        dragCardSourceIndex = srcIdx;
        dragCardHoverIndex = srcIdx;
        dragCardTargetPanel = ControlCenterConfig.getCardPanelIndex(cid);
        dragCardTargetItemIdx = -1;
        dragCardMouseX = mouseX;
        dragCardMouseY = mouseY;
        isDraggingCard = true;
    }

    function updateCardDrag(mouseX, mouseY) {
        dragCardMouseX = mouseX;
        dragCardMouseY = mouseY;
        if (!isDraggingCard) return;
        for (let p = 0; p < panelsRepeater.count; p++) {
            const panelCol = panelsRepeater.itemAt(p);
            if (!panelCol || !panelCol.visible) continue;
            const pPt = panelCol.mapFromItem(ccMainRect, mouseX, mouseY);
            if (pPt.x >= -6 && pPt.x <= panelCol.width + 6 && pPt.y >= -10 && pPt.y <= panelCol.height + 40) {
                dragCardTargetPanel = p;
                const rep = panelCol.cardsRep;
                if (rep) {
                    for (let i = 0; i < rep.count; i++) {
                        const item = rep.itemAt(i);
                        if (!item || !item.visible) continue;
                        const iPt = item.mapFromItem(ccMainRect, mouseX, mouseY);
                        if (iPt.y >= -6 && iPt.y <= item.height + 6) {
                            dragCardHoverIndex = item.enabledIdx;
                            dragCardTargetItemIdx = i;
                            return;
                        }
                    }
                    dragCardTargetItemIdx = rep.count;
                }
                return;
            }
        }
    }

    function finishCardDrag() {
        if (!isDraggingCard) return;
        const cid = draggedCardId;
        const targetPanel = dragCardTargetPanel;
        const targetItemIdx = dragCardTargetItemIdx;
        isDraggingCard = false;
        draggedCardId = "";
        dragCardHoverIndex = -1;
        dragCardSourceIndex = -1;
        dragCardTargetPanel = -1;
        dragCardTargetItemIdx = -1;
        if (cid !== "" && targetPanel >= 0) {
            ControlCenterConfig.moveCardToPanelAt(cid, targetPanel, targetItemIdx);
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
            top: controlCenter.isVertBar
                ? undefined
                : (controlCenter.barPosition === "bottom" ? undefined : parent.top)
            bottom: controlCenter.barPosition === "bottom" ? parent.bottom : undefined
            left: parent.left
            right: parent.right
        }
        y: controlCenter.isVertBar ? controlCenter.clampedVertY : 0
        Behavior on y {
            enabled: controlCenter.visible
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        height: Math.min(controlCenter.maxCcHeight, contentColumn.height + 24)
        radius: controlCenter.fluidEnabled ? 16 : 12
        color: controlCenter.fluidEnabled
            ? Qt.rgba(controlCenter.theme.bgBase.r, controlCenter.theme.bgBase.g, controlCenter.theme.bgBase.b, (BarConfig.barOpacity !== undefined ? BarConfig.barOpacity : 0.85))
            : controlCenter.theme.bgSurface
        border.color: controlCenter.theme.bgBorder
        border.width: 1
        clip: false

        // Square off connection edge and remove border line touching the bar
        Rectangle {
            visible: controlCenter.fluidEnabled && (controlCenter.barPosition === "top")
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 16
            color: parent.color
        }

        Rectangle {
            visible: controlCenter.fluidEnabled && (controlCenter.barPosition === "bottom")
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 16
            color: parent.color
        }

        Rectangle {
            visible: controlCenter.fluidEnabled && (controlCenter.barPosition === "left")
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 16
            color: parent.color
        }

        Rectangle {
            visible: controlCenter.fluidEnabled && (controlCenter.barPosition === "right")
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 16
            color: parent.color
        }

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
                    LiveEditBanner {
                        id: editBanner
                        hostCenter: controlCenter
                    }

                    // Multi-Panel Building-Block Columns
                    GridLayout {
                        id: cardsGridLayout
                        width: parent.width
                        columns: controlCenter.activePanelCols
                        columnSpacing: 12
                        rowSpacing: 12
                        uniformCellWidths: true

                        Repeater {
                            id: panelsRepeater
                            model: ControlCenterConfig.panelLayout === "horizontal"
                                ? ControlCenterConfig.panelCount
                                : 3

                            delegate: Column {
                                id: panelCol
                                required property int index
                                readonly property int panelIndex: index
                                readonly property var panelIds: {
                                    var _rev = ControlCenterConfig.cardsRevision;
                                    return ControlCenterConfig.getPanelIds(panelIndex);
                                }
                                readonly property bool hasVisibleModules: {
                                    var _rev = ControlCenterConfig.cardsRevision;
                                    if (ControlCenterConfig.isLiveEdit) return true;
                                    return panelIds.length > 0;
                                }
                                readonly property real cellWidth: ControlCenterConfig.panelLayout === "horizontal"
                                    ? Math.max(200, Math.floor((cardsGridLayout.width - (cardsGridLayout.columns - 1) * cardsGridLayout.columnSpacing) / cardsGridLayout.columns))
                                    : cardsGridLayout.width

                                property alias cardsRep: panelCardsRepeater

                                visible: hasVisibleModules
                                width: cellWidth
                                Layout.fillWidth: true
                                Layout.preferredWidth: cellWidth
                                Layout.minimumWidth: cellWidth
                                Layout.maximumWidth: cellWidth
                                Layout.preferredHeight: implicitHeight
                                Layout.alignment: Qt.AlignTop
                                spacing: 10

                                // Panel Header Badge in Live Edit Mode
                                Rectangle {
                                    visible: ControlCenterConfig.isLiveEdit
                                    width: panelCol.cellWidth
                                    height: 24
                                    radius: 6
                                    color: Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.1)
                                    border.color: Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.35)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Text {
                                            text: "󰕮 Panel " + (panelCol.panelIndex + 1)
                                            font.family: controlCenter.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: controlCenter.theme.accentPrimary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: panelCol.panelIds.length + (panelCol.panelIds.length === 1 ? " module" : " modules")
                                            font.family: controlCenter.font
                                            font.pixelSize: 10
                                            color: controlCenter.theme.textSecondary
                                        }
                                    }
                                }

                                // Modules inside this Panel
                                Repeater {
                                    id: panelCardsRepeater
                                    model: panelCol.panelIds

                                    delegate: Column {
                                        id: cardWrapper
                                        required property string modelData
                                        required property int index

                                        readonly property string cardId: modelData
                                        readonly property int panelIndex: panelCol.panelIndex
                                        readonly property int itemIndex: index
                                        readonly property int panelLength: panelCol.panelIds.length
                                        readonly property int enabledIdx: ControlCenterConfig.getEnabledCardIndex(cardId)
                                        readonly property bool isCardEnabled: true
                                        readonly property bool isBeingDragged: controlCenter.isDraggingCard && controlCenter.draggedCardId === cardId
                                        readonly property bool isDropTarget: controlCenter.isDraggingCard
                                            && controlCenter.dragTargetPanel === panelCol.panelIndex
                                            && controlCenter.dragTargetIndex === index
                                            && controlCenter.draggedCardId !== cardId

                                        readonly property real cellWidth: panelCol.cellWidth

                                        width: cellWidth
                                        spacing: 4

                                        scale: isBeingDragged ? 0.96 : (isDropTarget ? 1.02 : 1.0)
                                        opacity: isBeingDragged ? 0.35 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                        visible: {
                                            if (cardId === "quickSettings") {
                                                return ControlCenterConfig.isLiveEdit || ControlCenterConfig.enabledTiles.length > 0;
                                            }
                                            if (cardId === "quickSettings2") {
                                                return ControlCenterConfig.isLiveEdit || ControlCenterConfig.secondaryTiles.length > 0;
                                            }
                                            if (cardId === "media") {
                                                if (ControlCenterConfig.isLiveEdit) return true;
                                                return cardLoader.item ? cardLoader.item.hasMedia : false;
                                            }
                                            return true;
                                        }

                                        // Card Edit Toolbar (shown only during Live Edit Mode)
                                        ControlCenterCardEditBar {
                                            id: cardEditBar
                                            hostCenter: controlCenter
                                            hostMainRect: ccMainRect
                                            hostWrapper: cardWrapper
                                        }

                                        // Card Component Loader
                                        Loader {
                                            id: cardLoader
                                            width: cardWrapper.cellWidth
                                            sourceComponent: {
                                                switch (cardWrapper.cardId) {
                                                case "connectivity": return connectivityComp;
                                                case "quickSettings": return quickSettingsComp;
                                                case "quickSettings2": return quickSettings2Comp;
                                                case "brightness": return brightnessComp;
                                                case "audio": return audioComp;
                                                case "media": return mediaComp;
                                                case "systemInfo": return systemInfoComp;
                                                case "cava": return cavaComp;
                                                case "weather": return weatherComp;
                                                case "quickApps": return quickAppsComp;
                                                default: return null;
                                                }
                                            }
                                        }
                                    }
                                }

                                // Interactive Empty Panel Drop & Quick-Assign Zone in Live Edit Mode
                                Rectangle {
                                    visible: ControlCenterConfig.isLiveEdit && panelCol.panelIds.length === 0
                                    width: panelCol.cellWidth
                                    height: Math.max(110, emptyPanelContentCol.implicitHeight + 24)
                                    radius: 10
                                    color: (controlCenter.isDraggingCard && controlCenter.dragTargetPanel === panelCol.panelIndex)
                                        ? Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.14)
                                        : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.03)
                                    border.color: (controlCenter.isDraggingCard && controlCenter.dragTargetPanel === panelCol.panelIndex)
                                        ? controlCenter.theme.accentPrimary
                                        : controlCenter.theme.bgBorder
                                    border.width: 1

                                    Column {
                                        id: emptyPanelContentCol
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 12
                                        }
                                        spacing: 8

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "Empty Panel " + (panelCol.panelIndex + 1)
                                            font.family: controlCenter.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: controlCenter.theme.textSecondary
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "Drag a module here, or click to assign:"
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: controlCenter.font
                                            font.pixelSize: 10
                                            color: controlCenter.theme.textTertiary
                                        }

                                        Flow {
                                            width: parent.width
                                            spacing: 5

                                            // Unassigned Modules
                                            Repeater {
                                                model: ControlCenterConfig.unassignedCards
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    height: 24
                                                    implicitWidth: empModRow.implicitWidth + 14
                                                    radius: 12
                                                    color: empModMouse.containsMouse
                                                        ? Qt.rgba(controlCenter.theme.accentPrimary.r, controlCenter.theme.accentPrimary.g, controlCenter.theme.accentPrimary.b, 0.2)
                                                        : Qt.rgba(controlCenter.theme.textPrimary.r, controlCenter.theme.textPrimary.g, controlCenter.theme.textPrimary.b, 0.06)
                                                    border.color: controlCenter.theme.accentPrimary
                                                    border.width: 1

                                                    Row {
                                                        id: empModRow
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Text {
                                                            text: "+ " + (modelData.icon || "󰒓")
                                                            font.family: controlCenter.font
                                                            font.pixelSize: 10
                                                            color: controlCenter.theme.accentPrimary
                                                        }

                                                        Text {
                                                            text: modelData.label || ""
                                                            font.family: controlCenter.font
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: controlCenter.theme.textPrimary
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: empModMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ControlCenterConfig.moveCardToPanelAt(modelData.id, panelCol.panelIndex, 0)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Available Pool Tray in Live Edit Mode
                    LiveEditPoolTray {
                        id: poolTray
                        hostCenter: controlCenter
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
        CardDragGhost {
            id: cardDragGhost
            hostCenter: controlCenter
            hostMainRect: ccMainRect
        }
    }

    // Card Component Templates
    Component {
        id: connectivityComp
        QuickSettingsGrid {
            id: connGrid
            mode: "connectivity"
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
            Component.onCompleted: controlCenter.quickSettingsRef = connGrid
        }
    }

    Component {
        id: quickSettingsComp
        QuickSettingsGrid {
            id: qsGrid
            mode: "tiles"
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
            Component.onCompleted: {
                if (!controlCenter.quickSettingsRef) controlCenter.quickSettingsRef = qsGrid;
            }
        }
    }

    Component {
        id: quickSettings2Comp
        QuickSettingsGrid {
            id: qs2Grid
            mode: "tiles2"
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
            Component.onCompleted: {
                if (!controlCenter.quickSettingsRef) controlCenter.quickSettingsRef = qs2Grid;
            }
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

    Component {
        id: cavaComp
        CavaCard {
            theme: controlCenter.theme
            font: controlCenter.font
        }
    }

    Component {
        id: weatherComp
        WeatherCard {
            theme: controlCenter.theme
            font: controlCenter.font
        }
    }

    Component {
        id: quickAppsComp
        QuickAppsCard {
            theme: controlCenter.theme
            font: controlCenter.font
            onCloseParentRequested: controlCenter.visible = false
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