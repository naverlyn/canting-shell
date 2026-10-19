import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../bar"
import ".."

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    property int currentSubTab: 0
    property string selectedColorTargetType: "block"
    property string selectedColorWidgetId: "launcher"
    property int selectedColorPanelIndex: 0
    property string themeSearchQuery: ""

    property bool isDraggingBlock: false
    property string draggedWidgetId: ""
    property int dragSourcePanelIndex: -1
    property int dragSourceItemIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0
    property int dragHoverPanelIndex: -1
    property int dragHoverItemIndex: -1

    /* Feedback Toast Notification State */
    property string toastMessage: ""
    property bool toastVisible: false
    property bool toastIsWarning: false

    Timer {
        id: toastTimer
        interval: 2800
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg, isWarn) {
        root.toastMessage = msg;
        root.toastIsWarning = Boolean(isWarn);
        root.toastVisible = true;
        toastTimer.restart();
    }

    Connections {
        target: BarConfig
        function onConfigWarning(msg) {
            root.showToast(msg, true);
        }
        function onPanelsUpdated() {
            const p = BarConfig.panels;
            panelColumnsRepeater.model = null;
            panelColumnsRepeater.model = p;
        }
    }

    readonly property var themeRoles: [
        { key: "",              label: "Auto (Default)" },
        { key: "accentPrimary", label: "Primary" },
        { key: "accentCyan",    label: "Cyan" },
        { key: "accentGreen",   label: "Green" },
        { key: "accentOrange",  label: "Orange" },
        { key: "accentRed",     label: "Red" },
        { key: "textPrimary",   label: "Text" },
        { key: "textSecondary", label: "Subtext" },
        { key: "textMuted",     label: "Muted" }
    ]

    readonly property var themeAccentKeys: [
        { key: "accentPrimary", label: "Primary" },
        { key: "accentCyan",    label: "Cyan" },
        { key: "accentGreen",   label: "Green" },
        { key: "accentOrange",  label: "Orange" },
        { key: "accentRed",     label: "Red" },
        { key: "textPrimary",   label: "Text" }
    ]

    readonly property var filteredThemesList: {
        const all = (root.theme && root.theme.themes) ? root.theme.themes : [];
        const q = root.themeSearchQuery.toLowerCase().trim();
        let res = [];
        for (let i = 0; i < all.length; i++) {
            const t = all[i];
            if (!t || !t.name) continue;
            if (q === ""
                || String(t.name).toLowerCase().indexOf(q) !== -1
                || (t.family && String(t.family).toLowerCase().indexOf(q) !== -1)) {
                res.push(t);
            }
        }
        return res;
    }

    function cleanBarName(raw, fallback) {
        return String(raw || fallback || "Primary Bar").replace(/\s*\((Top|Bottom|Left|Right)\)$/i, "");
    }

    function currentBarId() {
        return (BarConfig.currentBar && BarConfig.currentBar.id) ? String(BarConfig.currentBar.id) : "bar_1";
    }

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function _trackColorDeps() {
        if (root.theme) {
            void root.theme.currentName;
            void root.theme.customAccent;
            void root.theme.previewAccent;
            void root.theme.wallpaperMode;
            void root.theme.accentPrimary;
            void root.theme.accentCyan;
            void root.theme.accentGreen;
            void root.theme.accentOrange;
            void root.theme.accentRed;
            void root.theme.textPrimary;
            void root.theme.textSecondary;
            void root.theme.textMuted;
            void root.theme.bgBase;
            void root.theme.themes;
        }
        void BarConfig.selectedBarIndex;
        void BarConfig.removedWidgets;
    }

    function getBlockColorSpec(widgetId) {
        _trackColorDeps();
        if (!widgetId) return "";
        const prefix = "@color:" + currentBarId() + ":" + widgetId + "=";
        const rem = BarConfig.removedWidgets || [];
        for (let i = 0; i < rem.length; i++) {
            const s = String(rem[i]);
            if (s.indexOf(prefix) === 0) return s.substring(prefix.length).trim();
        }
        return "";
    }

    function setBlockColorSpec(widgetId, spec) {
        if (!widgetId) return;
        const prefix = "@color:" + currentBarId() + ":" + widgetId + "=";
        let rem = (BarConfig.removedWidgets || []).filter(item => String(item).indexOf(prefix) !== 0);
        const clean = spec ? String(spec).trim() : "";
        if (clean !== "") rem.push(prefix + clean);
        BarConfig.removedWidgets = rem;
        BarConfig.saveConfig();
    }

    function setPanelBlocksColorSpec(panelIndex, spec) {
        const pList = BarConfig.panels || [];
        if (panelIndex < 0 || panelIndex >= pList.length) return;
        const widgets = pList[panelIndex] || [];
        const bId = currentBarId();
        let rem = (BarConfig.removedWidgets || []).slice();
        const clean = spec ? String(spec).trim() : "";
        for (let i = 0; i < widgets.length; i++) {
            const prefix = "@color:" + bId + ":" + widgets[i] + "=";
            rem = rem.filter(item => String(item).indexOf(prefix) !== 0);
            if (clean !== "") rem.push(prefix + clean);
        }
        BarConfig.removedWidgets = rem;
        BarConfig.saveConfig();
    }

    function getPanelColorSpec(panelIndex) {
        _trackColorDeps();
        const pList = BarConfig.panels || [];
        if (panelIndex < 0 || panelIndex >= pList.length) return "";
        const widgets = pList[panelIndex] || [];
        if (widgets.length === 0) return "";
        const firstSpec = getBlockColorSpec(widgets[0]);
        for (let i = 1; i < widgets.length; i++) {
            if (getBlockColorSpec(widgets[i]) !== firstSpec) return "";
        }
        return firstSpec;
    }

    function clearAllBlockColorsForCurrentBar() {
        const prefix = "@color:" + currentBarId() + ":";
        BarConfig.removedWidgets = (BarConfig.removedWidgets || []).filter(item => String(item).indexOf(prefix) !== 0);
        BarConfig.saveConfig();
    }

    function getActiveTargetSpec() {
        if (root.selectedColorTargetType === "bar") {
            return BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "");
        }
        return root.selectedColorTargetType === "panel"
            ? root.getPanelColorSpec(root.selectedColorPanelIndex)
            : root.getBlockColorSpec(root.selectedColorWidgetId);
    }

    function applyColorToActiveTarget(spec) {
        if (root.selectedColorTargetType === "bar") {
            BarConfig.updateBarProp("barColor", spec);
        } else if (root.selectedColorTargetType === "panel") {
            root.setPanelBlocksColorSpec(root.selectedColorPanelIndex, spec);
        } else {
            root.setBlockColorSpec(root.selectedColorWidgetId, spec);
        }
    }

    function resolveThemeSpec(spec, fallbackColor) {
        _trackColorDeps();
        const fb = fallbackColor !== undefined ? fallbackColor : root.theme.accentPrimary;
        if (!spec || String(spec).trim() === "") return fb;
        const s = String(spec).trim();
        try {
            if (s.indexOf("theme:") === 0) {
                const parts = s.split(":");
                if (parts.length >= 3) {
                    const tName = parts.slice(1, parts.length - 1).join(":");
                    const roleKey = parts[parts.length - 1];
                    const tList = (root.theme && root.theme.themes) ? root.theme.themes : [];
                    for (let i = 0; i < tList.length; i++) {
                        if (tList[i] && tList[i].name === tName && tList[i][roleKey]) {
                            return Qt.color(String(tList[i][roleKey]));
                        }
                    }
                }
            }
            if (root.theme && root.theme[s] !== undefined && typeof root.theme[s] !== "function") {
                return root.theme[s];
            }
            if (root.theme && root.theme.current && root.theme.current[s]) {
                return Qt.color(String(root.theme.current[s]));
            }
            if (s.charAt(0) === "#") return Qt.color(s);
        } catch (e) {}
        return fb;
    }

    function getSpecLabel(spec) {
        if (!spec || String(spec).trim() === "") return "Auto";
        const s = String(spec).trim();
        if (s.indexOf("theme:") === 0) {
            const parts = s.split(":");
            if (parts.length >= 3) {
                const tName = parts.slice(1, parts.length - 1).join(":");
                const roleKey = parts[parts.length - 1];
                return tName + " · " + roleKey.replace("accent", "").replace("text", "");
            }
        }
        for (let i = 0; i < root.themeRoles.length; i++) {
            if (root.themeRoles[i].key === s) return root.themeRoles[i].label;
        }
        return s;
    }

    function getWidgetPanelBadge(widgetId) {
        const pList = BarConfig.panels || [];
        for (let p = 0; p < pList.length; p++) {
            if ((pList[p] || []).indexOf(widgetId) !== -1) return "P" + (p + 1);
        }
        return "Unused";
    }

    function startBlockDrag(widgetId, srcPanelIdx, srcItemIdx, rootX, rootY) {
        root.draggedWidgetId = widgetId;
        root.dragSourcePanelIndex = srcPanelIdx;
        root.dragSourceItemIndex = srcItemIdx;
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        root.dragHoverPanelIndex = srcPanelIdx;
        root.dragHoverItemIndex = srcItemIdx;
        root.isDraggingBlock = true;
        updateBlockDragHover(rootX, rootY);
    }

    function updateBlockDragHover(rootX, rootY) {
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        if (!root.isDraggingBlock) return;

        for (let p = 0; p < panelColumnsRepeater.count; p++) {
            const panelCard = panelColumnsRepeater.itemAt(p);
            if (!panelCard) continue;
            const pt = panelCard.mapFromItem(root, rootX, rootY);
            if (pt.x >= -8 && pt.x <= panelCard.width + 8 && pt.y >= -8 && pt.y <= panelCard.height + 8) {
                root.dragHoverPanelIndex = p;
                const blocksRep = panelCard.blocksRepeater;
                if (!blocksRep || blocksRep.count === 0) {
                    root.dragHoverItemIndex = 0;
                    return;
                }
                let foundIdx = blocksRep.count;
                for (let i = 0; i < blocksRep.count; i++) {
                    const cItem = blocksRep.itemAt(i);
                    if (!cItem) continue;
                    const cPt = cItem.mapFromItem(root, rootX, rootY);
                    if (cPt.y <= cItem.height * 0.5) {
                        foundIdx = i;
                        break;
                    }
                }
                root.dragHoverItemIndex = foundIdx;
                return;
            }
        }

        if (availPoolCard && root.dragSourcePanelIndex >= 0) {
            const poolPt = availPoolCard.mapFromItem(root, rootX, rootY);
            if (poolPt.x >= -8 && poolPt.x <= availPoolCard.width + 8 && poolPt.y >= -8 && poolPt.y <= availPoolCard.height + 8) {
                root.dragHoverPanelIndex = -2;
                root.dragHoverItemIndex = -1;
                return;
            }
        }

        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;
    }

    function finishBlockDrag() {
        if (!root.isDraggingBlock) return;
        const wId = root.draggedWidgetId;
        const targetP = root.dragHoverPanelIndex;
        const targetI = root.dragHoverItemIndex;
        const srcP = root.dragSourcePanelIndex;

        root.isDraggingBlock = false;
        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;

        if (!wId) return;
        if (targetP === -2) {
            BarConfig.moveWidgetToPanelAt(wId, -1, -1);
        } else if (targetP >= 0) {
            if (srcP !== targetP && !BarConfig.canAddWidgetToPanel(wId, targetP)) {
                root.showToast("Already maxed out, please move somewhere else", true);
                return;
            }
            if (!BarConfig.moveWidgetToPanelAt(wId, targetP, targetI)) {
                root.showToast("Already maxed out, please move somewhere else", true);
            }
        }
    }

    component RowDivider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        height: 1
        color: root.withAlpha(root.theme.bgBorder, 0.5)
    }

    component SectionCard: ColumnLayout {
        id: secCard
        property string title: ""
        property string subtitle: ""
        property color titleColor: root.theme.textSecondary
        property color subtitleColor: root.theme.textMuted
        property bool subtitleBold: false
        property int contentMargins: 12
        property int contentSpacing: 12
        default property alias content: secInnerCol.data

        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: secCard.title
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: secCard.titleColor
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: secCard.subtitle !== ""
                text: secCard.subtitle
                font.family: root.font
                font.pixelSize: 11
                font.bold: secCard.subtitleBold
                color: secCard.subtitleColor
                elide: Text.ElideRight
                Layout.maximumWidth: Math.max(180, secCard.width * 0.62)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: secInnerCol.implicitHeight + secCard.contentMargins * 2
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1
            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: secInnerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: secCard.contentMargins
                }
                spacing: secCard.contentSpacing
            }
        }
    }

    component ActionButton: Rectangle {
        id: actBtn
        property string iconText: ""
        property string label: ""
        property bool danger: false
        property bool btnEnabled: true
        property int btnHeight: 32
        signal clicked()

        readonly property color activeCol: danger ? root.theme.accentRed : root.theme.accentPrimary

        implicitWidth: actRow.implicitWidth + 24
        implicitHeight: btnHeight
        width: implicitWidth
        height: implicitHeight
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignVCenter
        radius: 8
        opacity: btnEnabled ? 1.0 : 0.4
        color: !btnEnabled
            ? root.theme.bgBase
            : (danger
                ? (actMouse.pressed
                    ? root.withAlpha(root.theme.accentRed, 0.28)
                    : (actHover.hovered ? root.withAlpha(root.theme.accentRed, 0.20) : root.withAlpha(root.theme.accentRed, 0.10)))
                : (actMouse.pressed
                    ? root.theme.bgSelected
                    : (actHover.hovered ? root.withAlpha(root.theme.accentPrimary, 0.14) : root.theme.bgBase)))
        border.color: danger
            ? "transparent"
            : (actHover.hovered && btnEnabled ? root.withAlpha(root.theme.accentPrimary, 0.5) : root.theme.bgBorder)
        border.width: danger ? 0 : 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        HoverHandler { id: actHover }

        Row {
            id: actRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: actBtn.iconText !== ""
                width: 14
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
                text: actBtn.iconText
                font.family: root.font
                font.pixelSize: 12
                color: actBtn.danger
                    ? root.theme.accentRed
                    : (actHover.hovered && actBtn.btnEnabled ? actBtn.activeCol : root.theme.textSecondary)
            }

            Text {
                id: actTxt
                anchors.verticalCenter: parent.verticalCenter
                text: actBtn.label
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: actBtn.danger
                    ? root.theme.accentRed
                    : (actHover.hovered && actBtn.btnEnabled ? actBtn.activeCol : root.theme.textPrimary)
            }
        }

        MouseArea {
            id: actMouse
            anchors.fill: parent
            enabled: actBtn.btnEnabled
            cursorShape: actBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: actBtn.clicked()
        }
    }

    component MiniIconButton: Rectangle {
        id: miniBtn
        property string iconText: ""
        property bool dangerHover: false
        property bool btnEnabled: true
        signal clicked()

        readonly property color hoverCol: dangerHover ? root.theme.accentRed : root.theme.accentPrimary

        implicitWidth: 24
        implicitHeight: 24
        width: 24
        height: 24
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        Layout.alignment: Qt.AlignVCenter
        radius: 6
        color: !btnEnabled
            ? "transparent"
            : (btnMouse.pressed
                ? root.withAlpha(hoverCol, 0.26)
                : (btnHover.hovered ? root.withAlpha(hoverCol, 0.16) : "transparent"))
        border.width: 0
        opacity: btnEnabled ? 1.0 : 0.3

        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: btnHover; enabled: miniBtn.btnEnabled }

        Text {
            anchors.centerIn: parent
            text: miniBtn.iconText
            font.family: root.font
            font.pixelSize: 12
            color: miniBtn.btnEnabled
                ? (btnHover.hovered ? miniBtn.hoverCol : root.theme.textMuted)
                : root.theme.textMuted

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: miniBtn.btnEnabled
            cursorShape: miniBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: miniBtn.clicked()
        }
    }

    component BlockDragArea: MouseArea {
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

    component BlockCard: Rectangle {
        id: blockCard
        property string widgetId: ""
        property int panelIdx: 0
        property int itemIndex: 0
        property int panelTotalItems: 1

        readonly property var meta: BarConfig.getWidgetMeta(widgetId)
        readonly property bool isVisible: BarConfig.isWidgetVisible(widgetId, root.currentBarId())
        readonly property string colorSpec: root.getBlockColorSpec(widgetId)
        readonly property color activeColor: root.resolveThemeSpec(colorSpec, root.theme.accentPrimary)
        readonly property bool isBeingDragged: root.isDraggingBlock && root.draggedWidgetId === blockCard.widgetId
        readonly property bool isPanelMaxedForDrag: blockCard.panelIdx !== root.dragSourcePanelIndex && !BarConfig.canAddWidgetToPanel(root.draggedWidgetId, blockCard.panelIdx)
        readonly property bool isTargetPanel: root.isDraggingBlock && root.dragHoverPanelIndex === blockCard.panelIdx && root.draggedWidgetId !== blockCard.widgetId && !isPanelMaxedForDrag
        readonly property bool isBeforeThis: isTargetPanel && root.dragHoverItemIndex === blockCard.itemIndex
        readonly property bool isAfterThis: isTargetPanel && (
            (root.dragHoverItemIndex === blockCard.itemIndex + 1) ||
            (blockCard.itemIndex === blockCard.panelTotalItems - 1 && root.dragHoverItemIndex >= blockCard.panelTotalItems)
        )
        readonly property bool isDropTarget: isBeforeThis || isAfterThis

        Layout.fillWidth: true
        height: 38
        radius: 8
        scale: isBeingDragged ? 0.96 : 1.0
        color: isDropTarget
            ? root.theme.bgSelected
            : (cardHover.hovered ? root.theme.bgHover : root.theme.bgBase)
        border.color: isDropTarget || isBeingDragged
            ? root.theme.accentPrimary
            : (isVisible ? (cardHover.hovered ? activeColor : root.theme.bgBorder) : root.withAlpha(root.theme.bgBorder, 0.5))
        border.width: isDropTarget ? 1.5 : 1
        opacity: isBeingDragged ? 0.35 : (isVisible ? 1.0 : 0.55)

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        HoverHandler { id: cardHover }

        Rectangle {
            visible: blockCard.isDropTarget
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            y: blockCard.isAfterThis ? parent.height - 3 : 1
            height: 2
            radius: 1
            color: root.theme.accentPrimary
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: "󰍜"
                font.family: root.font
                font.pixelSize: 11
                color: cardHover.hovered ? root.theme.textSecondary : root.theme.textMuted
                opacity: cardHover.hovered ? 0.85 : 0.35
                Layout.preferredWidth: 12
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: blockCard.meta.icon
                font.family: root.font
                font.pixelSize: 13
                color: blockCard.isVisible ? blockCard.activeColor : root.theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: blockCard.meta.name
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: blockCard.isVisible ? root.theme.textPrimary : root.theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                id: cardBtnRow
                z: 2
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                MiniIconButton {
                    visible: cardHover.hovered && blockCard.itemIndex > 0
                    iconText: "󰅃"
                    onClicked: BarConfig.moveWidgetUp(blockCard.widgetId)
                }

                MiniIconButton {
                    visible: cardHover.hovered && blockCard.itemIndex < blockCard.panelTotalItems - 1
                    iconText: "󰅀"
                    onClicked: BarConfig.moveWidgetDown(blockCard.widgetId)
                }

                MiniIconButton {
                    visible: cardHover.hovered && blockCard.panelIdx > 0
                    iconText: "󰅁"
                    onClicked: {
                        if (!BarConfig.moveWidgetSectionLeft(blockCard.widgetId)) {
                            root.showToast("Already maxed out, please move somewhere else", true);
                        }
                    }
                }

                MiniIconButton {
                    visible: cardHover.hovered && blockCard.panelIdx < BarConfig.panels.length - 1
                    iconText: "󰅂"
                    onClicked: {
                        if (!BarConfig.moveWidgetSectionRight(blockCard.widgetId)) {
                            root.showToast("Already maxed out, please move somewhere else", true);
                        }
                    }
                }

                MiniIconButton {
                    visible: cardHover.hovered
                    iconText: "󰏘"
                    onClicked: {
                        root.selectedColorTargetType = "block";
                        root.selectedColorWidgetId = blockCard.widgetId;
                        root.currentSubTab = 1;
                        subTabContentAnim.restart();
                    }
                }

                MiniIconButton {
                    iconText: blockCard.isVisible ? "󰈈" : "󰈉"
                    onClicked: BarConfig.setWidgetVisible(blockCard.widgetId, !blockCard.isVisible, root.currentBarId())
                }

                MiniIconButton {
                    iconText: "󰅖"
                    dangerHover: true
                    onClicked: BarConfig.removeWidgetFromBar(blockCard.widgetId)
                }
            }
        }

        BlockDragArea {
            anchors.fill: parent
            anchors.rightMargin: cardBtnRow.width + 10
            widgetId: blockCard.widgetId
            panelIdx: blockCard.panelIdx
            itemIdx: blockCard.itemIndex
            onClickedWithoutDrag: {
                root.selectedColorTargetType = "block";
                root.selectedColorWidgetId = blockCard.widgetId;
            }
        }
    }

    component SettingToggleRow: Item {
        id: toggleRow
        property string title: ""
        property string desc: ""
        property bool checked: false
        property bool rowEnabled: true
        signal toggled(bool val)

        Layout.fillWidth: true
        height: 52
        opacity: rowEnabled ? 1.0 : 0.45

        Behavior on opacity { NumberAnimation { duration: 140 } }

        MouseArea {
            anchors.fill: parent
            z: 10
            enabled: toggleRow.rowEnabled
            cursorShape: toggleRow.rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: toggleRow.toggled(!toggleRow.checked)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: toggleRow.title
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    visible: toggleRow.desc !== ""
                    text: toggleRow.desc
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: toggleRow.checked ? root.theme.accentPrimary : root.theme.bgSelected
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Behavior on color { ColorAnimation { duration: 160 } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleRow.checked ? parent.width - width - 3 : 3
                    color: toggleRow.checked ? root.theme.bgBase : root.theme.textPrimary

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        interactive: !root.isDraggingBlock
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 10
            spacing: 18

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Bar Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure modular building blocks, panel count, block colors, and bar appearance"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset to Default"
                    onClicked: BarConfig.resetDefaults()
                }
            }

            Connections {
                target: BarConfig
                function onSelectedBarIndexChanged() {
                    subTabContentAnim.restart();
                }
            }

            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.3
                    to: 1.0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 6
                    to: 0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
            }

            SectionCard {
                title: "Desktop Bars (" + BarConfig.bars.length + ")"
                subtitle: "Select a bar to customize its panels, block colors, and dock position"
                contentMargins: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Flow {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: BarConfig.bars
                            delegate: Rectangle {
                                id: barTabBtn
                                required property var modelData
                                required property int index
                                readonly property bool isCurrent: BarConfig.selectedBarIndex === index
                                readonly property string barPos: modelData.position || "top"
                                readonly property string posLabel: barPos.charAt(0).toUpperCase() + barPos.slice(1)
                                readonly property string cleanName: root.cleanBarName(modelData.name, index === 0 ? "Primary Bar" : ("Bar " + (index + 1)))

                                implicitWidth: barTabContent.implicitWidth + 16
                                implicitHeight: 34
                                width: implicitWidth
                                height: implicitHeight
                                color: "transparent"
                                border.width: 0
                                opacity: modelData.enabled !== false ? 1.0 : 0.6

                                HoverHandler { id: barTabHover }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 2
                                    radius: 1
                                    width: barTabBtn.isCurrent ? parent.width - 8 : (barTabHover.hovered ? parent.width * 0.5 : 0)
                                    opacity: barTabBtn.isCurrent ? 1.0 : (barTabHover.hovered ? 0.5 : 0.0)
                                    color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                }

                                Row {
                                    id: barTabContent
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Rectangle {
                                        width: 16
                                        height: 12
                                        radius: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "transparent"
                                        border.width: 1.5
                                        border.color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                        Rectangle {
                                            readonly property string p: barTabBtn.barPos
                                            x: p === "right" ? parent.width - width - 2 : 2
                                            y: p === "bottom" ? parent.height - height - 2 : 2
                                            width: (p === "left" || p === "right") ? 2.5 : parent.width - 4
                                            height: (p === "top" || p === "bottom") ? 2.5 : parent.height - 4
                                            radius: 1
                                            color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barTabBtn.cleanName
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: barTabBtn.isCurrent
                                        color: barTabBtn.isCurrent
                                            ? root.theme.accentPrimary
                                            : (barTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    }

                                    Rectangle {
                                        width: posBadgeTxt.implicitWidth + 10
                                        height: 18
                                        radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: barTabBtn.isCurrent ? root.withAlpha(root.theme.accentPrimary, 0.16) : root.theme.bgBase

                                        Text {
                                            id: posBadgeTxt
                                            anchors.centerIn: parent
                                            text: barTabBtn.posLabel + (barTabBtn.modelData.enabled === false ? " · Off" : "")
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textMuted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: barTabMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (BarConfig.selectedBarIndex !== barTabBtn.index) {
                                            BarConfig.selectedBarIndex = barTabBtn.index;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ActionButton {
                        visible: BarConfig.bars.length > 1
                        iconText: "󰅖"
                        label: "Remove Bar"
                        danger: true
                        btnHeight: 32
                        onClicked: BarConfig.removeBarAt(BarConfig.selectedBarIndex)
                    }

                    ActionButton {
                        iconText: "󰐕"
                        label: "Add Bar"
                        btnEnabled: BarConfig.bars.length < 4
                        btnHeight: 32
                        onClicked: BarConfig.addBar()
                    }
                }
            }

            Rectangle {
                id: subTabTrack
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, icon: "󰕮", label: "Layout & Panels" },
                            { idx: 1, icon: "󰏘", label: "Block Colors" },
                            { idx: 2, icon: "󰒓", label: "General & Options" }
                        ]
                        delegate: Rectangle {
                            id: subTabItem
                            required property var modelData
                            readonly property bool isCurrent: root.currentSubTab === modelData.idx

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            border.width: 0

                            HoverHandler { id: subTabHover }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                radius: 1
                                width: subTabItem.isCurrent
                                    ? subTabRow.implicitWidth + 16
                                    : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                                opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                                color: subTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }

                            Row {
                                id: subTabRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    width: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: subTabItem.modelData.icon
                                    font.family: root.font
                                    font.pixelSize: 13
                                    color: subTabItem.isCurrent
                                        ? root.theme.accentPrimary
                                        : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? root.theme.accentPrimary
                                        : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentSubTab !== subTabItem.modelData.idx) {
                                        root.currentSubTab = subTabItem.modelData.idx;
                                        subTabContentAnim.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 20
                transform: Translate { id: subTabContentTranslate; y: 0 }

                SectionCard {
                    visible: root.currentSubTab === 0
                    title: "Bar Layout & Building Blocks: " + root.cleanBarName(BarConfig.currentBar ? BarConfig.currentBar.name : "")
                    subtitle: "Drag blocks to reorder or move between panels · Click block to color · ✕ to remove"

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 9
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "Bar Panels:"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            RowLayout {
                                spacing: 8

                                Repeater {
                                    model: [2, 3, 4, 5]
                                    delegate: Rectangle {
                                        id: pCountBtn
                                        required property int modelData
                                        readonly property bool isCurrent: BarConfig.panels.length === modelData
                                        implicitWidth: pCountTxt.implicitWidth + 16
                                        implicitHeight: 30
                                        width: implicitWidth
                                        height: implicitHeight
                                        color: "transparent"
                                        border.width: 0

                                        HoverHandler { id: pCountHover }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            height: 2
                                            radius: 1
                                            width: pCountBtn.isCurrent ? parent.width - 6 : (pCountHover.hovered ? parent.width * 0.5 : 0)
                                            opacity: pCountBtn.isCurrent ? 1.0 : (pCountHover.hovered ? 0.5 : 0.0)
                                            color: pCountBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on opacity { NumberAnimation { duration: 140 } }
                                            Behavior on color { ColorAnimation { duration: 140 } }
                                        }

                                        Text {
                                            id: pCountTxt
                                            anchors.centerIn: parent
                                            text: pCountBtn.modelData + " Panels"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: pCountBtn.isCurrent
                                            color: pCountBtn.isCurrent
                                                ? root.theme.accentPrimary
                                                : (pCountHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BarConfig.setPanelCount(pCountBtn.modelData)
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            ActionButton {
                                iconText: "󰐕"
                                label: "Add Blank Panel"
                                btnEnabled: BarConfig.panels.length < 6
                                btnHeight: 28
                                onClicked: BarConfig.addBlankPanel()
                            }
                        }
                    }

                    GridLayout {
                        id: blockBuilderLayout
                        columns: BarConfig.panels.length > 3 ? 2 : Math.max(1, BarConfig.panels.length)
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.fillWidth: true

                        Repeater {
                            id: panelColumnsRepeater
                            model: BarConfig.panels
                            delegate: Rectangle {
                                id: panelColumnCard
                                required property var modelData
                                required property int index
                                property alias blocksRepeater: panelBlocksRepeater
                                readonly property var currentPanelItems: (BarConfig.panels && BarConfig.panels[panelColumnCard.index]) ? BarConfig.panels[panelColumnCard.index] : (panelColumnCard.modelData || [])
                                readonly property bool isMaxedOut: panelColumnCard.currentPanelItems.length >= (BarConfig.maxPanelWidgets || 10)
                                readonly property bool isIncomingBlocked: isMaxedOut && root.isDraggingBlock && root.dragSourcePanelIndex !== panelColumnCard.index
                                readonly property bool isPanelDropTarget: root.isDraggingBlock && root.dragHoverPanelIndex === panelColumnCard.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                implicitHeight: Math.max(320, panelColContent.implicitHeight + 20)
                                radius: 10
                                color: isPanelDropTarget
                                    ? (isIncomingBlocked ? root.withAlpha(root.theme.accentRed, 0.08) : root.withAlpha(root.theme.accentPrimary, 0.08))
                                    : root.theme.bgBase
                                border.color: isPanelDropTarget
                                    ? (isIncomingBlocked ? root.theme.accentRed : root.theme.accentPrimary)
                                    : (isMaxedOut ? root.withAlpha(root.theme.accentRed, 0.35) : root.theme.bgBorder)
                                border.width: isPanelDropTarget ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                ColumnLayout {
                                    id: panelColContent
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10
                                    }
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 7
                                        color: root.theme.bgSelected

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 4
                                            spacing: 6

                                            Text {
                                                text: BarConfig.getPanelTitle(panelColumnCard.index)
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: panelColumnCard.isMaxedOut ? root.theme.accentRed : root.theme.accentPrimary
                                            }

                                            Rectangle {
                                                implicitWidth: pCountBadgeTxt.implicitWidth + 10
                                                implicitHeight: 18
                                                radius: 9
                                                color: panelColumnCard.isMaxedOut
                                                    ? root.withAlpha(root.theme.accentRed, 0.18)
                                                    : root.withAlpha(root.theme.textMuted, 0.12)
                                                border.color: panelColumnCard.isMaxedOut ? root.theme.accentRed : "transparent"
                                                border.width: 1

                                                Text {
                                                    id: pCountBadgeTxt
                                                    anchors.centerIn: parent
                                                    text: panelColumnCard.isMaxedOut
                                                        ? "MAX (10/10)"
                                                        : ("(" + panelColumnCard.currentPanelItems.length + "/10)")
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: panelColumnCard.isMaxedOut
                                                    color: panelColumnCard.isMaxedOut ? root.theme.accentRed : root.theme.textMuted
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            MiniIconButton {
                                                visible: !panelColumnCard.isMaxedOut && BarConfig.unassignedWidgets.length > 0
                                                iconText: "󰐕"
                                                onClicked: {
                                                    if (BarConfig.unassignedWidgets.length > 0) {
                                                        const wid = BarConfig.unassignedWidgets[0].id;
                                                        if (BarConfig.addWidgetToPanel(wid, panelColumnCard.index)) {
                                                            root.showToast("Added " + BarConfig.getWidgetMeta(wid).name + " to " + BarConfig.getPanelTitle(panelColumnCard.index));
                                                        }
                                                    }
                                                }
                                            }

                                            MiniIconButton {
                                                visible: BarConfig.panels.length > 1
                                                iconText: "󰅖"
                                                dangerHover: true
                                                onClicked: BarConfig.removePanelAt(panelColumnCard.index)
                                            }
                                        }
                                    }

                                    Repeater {
                                        id: panelBlocksRepeater
                                        model: panelColumnCard.currentPanelItems
                                        delegate: BlockCard {
                                            required property string modelData
                                            required property int index
                                            widgetId: modelData
                                            panelIdx: panelColumnCard.index
                                            itemIndex: index
                                            panelTotalItems: panelColumnCard.currentPanelItems.length
                                        }
                                    }

                                    Rectangle {
                                        visible: panelColumnCard.currentPanelItems.length === 0
                                        Layout.fillWidth: true
                                        implicitHeight: 70
                                        radius: 8
                                        color: panelColumnCard.isPanelDropTarget
                                            ? root.withAlpha(root.theme.accentPrimary, 0.14)
                                            : (blankHover.hovered && BarConfig.unassignedWidgets.length > 0
                                                ? root.withAlpha(root.theme.bgSelected, 0.7)
                                                : "transparent")
                                        border.color: panelColumnCard.isPanelDropTarget
                                            ? root.theme.accentPrimary
                                            : (blankHover.hovered && BarConfig.unassignedWidgets.length > 0 ? root.theme.accentPrimary : root.theme.bgBorder)
                                        border.width: panelColumnCard.isPanelDropTarget ? 1.5 : 1

                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        HoverHandler { id: blankHover }

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: panelColumnCard.isPanelDropTarget
                                                    ? "Drop here to place in " + BarConfig.getPanelTitle(panelColumnCard.index)
                                                    : ("Blank Panel (" + BarConfig.getPanelTitle(panelColumnCard.index) + ")")
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: panelColumnCard.isPanelDropTarget ? root.theme.accentPrimary : root.theme.textMuted
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                visible: !panelColumnCard.isPanelDropTarget
                                                text: BarConfig.unassignedWidgets.length > 0
                                                    ? "Drag block here, or click to add"
                                                    : "Drag any building block here"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: blankHover.hovered && BarConfig.unassignedWidgets.length > 0 ? root.theme.accentPrimary : root.theme.textMuted
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !root.isDraggingBlock && BarConfig.unassignedWidgets.length > 0
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (BarConfig.unassignedWidgets.length > 0) {
                                                    const wid = BarConfig.unassignedWidgets[0].id;
                                                    if (BarConfig.addWidgetToPanel(wid, panelColumnCard.index)) {
                                                        root.showToast("Added " + BarConfig.getWidgetMeta(wid).name + " to " + BarConfig.getPanelTitle(panelColumnCard.index));
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        visible: panelColumnCard.currentPanelItems.length > 0 && root.isDraggingBlock && root.dragHoverPanelIndex === panelColumnCard.index && (root.dragHoverItemIndex >= panelColumnCard.currentPanelItems.length || panelColumnCard.isIncomingBlocked)
                                        Layout.fillWidth: true
                                        implicitHeight: 36

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            radius: 7
                                            color: panelColumnCard.isIncomingBlocked
                                                ? root.withAlpha(root.theme.accentRed, 0.14)
                                                : root.withAlpha(root.theme.accentPrimary, 0.12)
                                            border.color: panelColumnCard.isIncomingBlocked ? root.theme.accentRed : root.theme.accentPrimary
                                            border.width: 1.5

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    text: panelColumnCard.isIncomingBlocked ? "󰀪" : "󰐕"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: panelColumnCard.isIncomingBlocked ? root.theme.accentRed : root.theme.accentPrimary
                                                }

                                                Text {
                                                    text: panelColumnCard.isIncomingBlocked
                                                        ? "Already maxed out, please move somewhere else"
                                                        : ("Append to " + BarConfig.getPanelTitle(panelColumnCard.index))
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: panelColumnCard.isIncomingBlocked ? root.theme.accentRed : root.theme.accentPrimary
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: availPoolCard
                        readonly property bool isPoolDropTarget: root.isDraggingBlock && root.dragHoverPanelIndex === -2 && root.dragSourcePanelIndex >= 0
                        Layout.fillWidth: true
                        implicitHeight: availPoolCol.implicitHeight + 20
                        radius: 10
                        color: isPoolDropTarget
                            ? root.withAlpha(root.theme.accentRed, 0.12)
                            : root.theme.bgBase
                        border.color: isPoolDropTarget
                            ? root.theme.accentRed
                            : root.theme.bgBorder
                        border.width: isPoolDropTarget ? 1.5 : 1

                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            id: availPoolCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Available Building Blocks"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: availPoolCard.isPoolDropTarget ? root.theme.accentRed : root.theme.accentPrimary
                                }

                                Text {
                                    text: "(" + BarConfig.unassignedWidgets.length + " available)"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: availPoolCard.isPoolDropTarget
                                        ? "Release here to remove from bar"
                                        : (BarConfig.unassignedWidgets.length > 0
                                            ? "Drag block into any panel above"
                                            : "All building blocks are placed on panels (drag here or click ✕ to remove)")
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: availPoolCard.isPoolDropTarget
                                    color: availPoolCard.isPoolDropTarget ? root.theme.accentRed : root.theme.textMuted
                                }
                            }

                            Flow {
                                visible: BarConfig.unassignedWidgets.length > 0
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: BarConfig.unassignedWidgets
                                    delegate: Rectangle {
                                        id: poolCard
                                        required property var modelData
                                        readonly property color blockAccent: root.resolveThemeSpec(root.getBlockColorSpec(poolCard.modelData.id), root.theme.accentPrimary)
                                        readonly property bool isBeingDragged: root.isDraggingBlock && root.draggedWidgetId === poolCard.modelData.id

                                        implicitWidth: poolRow.implicitWidth + 22
                                        implicitHeight: 34
                                        width: implicitWidth
                                        height: implicitHeight
                                        radius: 8
                                        scale: isBeingDragged ? 0.94 : (poolHover.hovered ? 1.02 : 1.0)
                                        opacity: isBeingDragged ? 0.35 : 1.0
                                        color: poolHover.hovered ? root.theme.bgHover : root.theme.bgSurface
                                        border.color: poolHover.hovered ? poolCard.blockAccent : root.theme.bgBorder
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        HoverHandler { id: poolHover }

                                        Row {
                                            id: poolRow
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Text {
                                                width: 16
                                                anchors.verticalCenter: parent.verticalCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                text: poolCard.modelData.icon
                                                font.family: root.font
                                                font.pixelSize: 13
                                                color: poolCard.blockAccent
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: poolCard.modelData.name
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textPrimary
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰐕"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: poolHover.hovered ? poolCard.blockAccent : root.theme.textMuted
                                                opacity: poolHover.hovered ? 1.0 : 0.6
                                            }
                                        }

                                        BlockDragArea {
                                            anchors.fill: parent
                                            widgetId: poolCard.modelData.id
                                            panelIdx: -1
                                            itemIdx: -1
                                            onClickedWithoutDrag: {
                                                const wid = poolCard.modelData.id;
                                                const wname = poolCard.modelData.name || wid;
                                                if (BarConfig.addWidgetToPanel(wid, 0)) {
                                                    const targetPanel = BarConfig.getWidgetPanelIndex(wid);
                                                    const targetTitle = targetPanel >= 0 ? BarConfig.getPanelTitle(targetPanel) : "Panel";
                                                    root.showToast("Added " + wname + " to " + targetTitle);
                                                } else {
                                                    root.showToast("Already maxed out, please move somewhere else", true);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: root.currentSubTab === 1
                    Layout.fillWidth: true
                    spacing: 16

                    SectionCard {
                        title: "1. Select Building Block or Panel to Color"
                        subtitle: "Pick any block or panel below, then choose a color"

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 9
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: "Targets:"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }

                                Rectangle {
                                    id: barTargetBtn
                                    readonly property bool isTarget: root.selectedColorTargetType === "bar"
                                    readonly property string barSpec: BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "")
                                    readonly property color barCol: root.resolveThemeSpec(barSpec, root.theme.bgBase)

                                    implicitWidth: barTargetRow.implicitWidth + 20
                                    implicitHeight: 28
                                    width: implicitWidth
                                    height: implicitHeight
                                    radius: 6
                                    color: isTarget
                                        ? root.theme.bgSelected
                                        : (barTargetHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                                    border.color: isTarget ? root.theme.accentPrimary : (barTargetHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder)
                                    border.width: isTarget ? 1.5 : 1

                                    HoverHandler { id: barTargetHover }

                                    RowLayout {
                                        id: barTargetRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Rectangle {
                                            width: 10
                                            height: 10
                                            radius: 2
                                            color: barTargetBtn.barCol
                                            border.color: root.theme.bgBorder
                                            border.width: 1
                                        }

                                        Text {
                                            text: "Bar Background"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: barTargetBtn.isTarget
                                            color: barTargetBtn.isTarget ? root.theme.accentPrimary : root.theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedColorTargetType = "bar";
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    height: 18
                                    color: root.theme.bgBorder
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "Panels:"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }

                                Repeater {
                                    model: BarConfig.panels
                                    delegate: Rectangle {
                                        id: panelTargetBtn
                                        required property var modelData
                                        required property int index
                                        readonly property bool isTarget: root.selectedColorTargetType === "panel" && root.selectedColorPanelIndex === index
                                        readonly property string pSpec: root.getPanelColorSpec(index)
                                        readonly property color pCol: root.resolveThemeSpec(pSpec, root.theme.accentPrimary)

                                        implicitWidth: panelTargetTxt.implicitWidth + 18
                                        implicitHeight: 28
                                        width: implicitWidth
                                        height: implicitHeight
                                        radius: 6
                                        color: isTarget
                                            ? root.theme.bgSelected
                                            : (pTargetHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                                        border.color: isTarget ? pCol : (pTargetHover.hovered ? root.withAlpha(pCol, 0.45) : root.theme.bgBorder)
                                        border.width: isTarget ? 1.5 : 1

                                        HoverHandler { id: pTargetHover }

                                        Text {
                                            id: panelTargetTxt
                                            anchors.centerIn: parent
                                            text: BarConfig.getPanelTitle(panelTargetBtn.index)
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: panelTargetBtn.isTarget
                                            color: panelTargetBtn.isTarget ? panelTargetBtn.pCol : root.theme.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedColorTargetType = "panel";
                                                root.selectedColorPanelIndex = panelTargetBtn.index;
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                ActionButton {
                                    iconText: "󰦛"
                                    label: "Reset Block Colors"
                                    danger: true
                                    btnHeight: 28
                                    onClicked: root.clearAllBlockColorsForCurrentBar()
                                }
                            }
                        }

                        GridLayout {
                            columns: 3
                            columnSpacing: 10
                            rowSpacing: 10
                            Layout.fillWidth: true

                            Repeater {
                                model: BarConfig.widgetDefinitions
                                delegate: Rectangle {
                                    id: colorBlockCard
                                    required property var modelData
                                    readonly property bool isSelectedTarget: root.selectedColorTargetType === "block" && root.selectedColorWidgetId === modelData.id
                                    readonly property string spec: root.getBlockColorSpec(modelData.id)
                                    readonly property bool hasCustom: spec !== ""
                                    readonly property color resolvedCol: root.resolveThemeSpec(spec, root.theme.accentPrimary)
                                    readonly property string panelBadge: root.getWidgetPanelBadge(modelData.id)

                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    height: 44
                                    radius: 8
                                    color: isSelectedTarget
                                        ? root.theme.bgSelected
                                        : (cbHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                                    border.color: isSelectedTarget
                                        ? resolvedCol
                                        : (hasCustom ? root.withAlpha(resolvedCol, 0.5) : root.theme.bgBorder)
                                    border.width: isSelectedTarget ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Behavior on border.color { ColorAnimation { duration: 130 } }

                                    HoverHandler { id: cbHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: colorBlockCard.modelData.icon
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: colorBlockCard.resolvedCol
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.preferredWidth: 18
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            spacing: 1
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                text: colorBlockCard.modelData.name
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: colorBlockCard.panelBadge + " · " + root.getSpecLabel(colorBlockCard.spec)
                                                font.family: root.font
                                                font.pixelSize: 9
                                                color: colorBlockCard.hasCustom ? colorBlockCard.resolvedCol : root.theme.textMuted
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: cbMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedColorTargetType = "block";
                                            root.selectedColorWidgetId = colorBlockCard.modelData.id;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        readonly property string targetTitle: {
                            if (root.selectedColorTargetType === "bar") return "Bar Background";
                            if (root.selectedColorTargetType === "panel") return "Entire " + BarConfig.getPanelTitle(root.selectedColorPanelIndex);
                            return BarConfig.getWidgetMeta(root.selectedColorWidgetId).name;
                        }
                        title: "2. Assign Color for: " + targetTitle
                        titleColor: root.theme.accentPrimary
                        subtitle: "Current: " + root.getSpecLabel(root.getActiveTargetSpec())
                        subtitleColor: root.resolveThemeSpec(root.getActiveTargetSpec(), root.theme.textSecondary)
                        subtitleBold: true
                        contentSpacing: 14

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Active Theme Semantic Roles (" + ((root.theme && root.theme.currentName) ? root.theme.currentName : "Current Theme") + ")"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.themeRoles
                                    delegate: Rectangle {
                                        id: semanticRoleBtn
                                        required property var modelData
                                        readonly property string activeSpec: root.getActiveTargetSpec()
                                        readonly property bool isChosen: activeSpec === modelData.key
                                        readonly property color roleCol: modelData.key === ""
                                            ? root.theme.accentPrimary
                                            : root.resolveThemeSpec(modelData.key, root.theme.accentPrimary)

                                        implicitWidth: semanticRoleTxt.implicitWidth + 20
                                        implicitHeight: 32
                                        width: implicitWidth
                                        height: implicitHeight
                                        radius: 8
                                        color: isChosen
                                            ? root.theme.bgSelected
                                            : (sRoleHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                                        border.color: isChosen || sRoleHover.hovered ? roleCol : root.theme.bgBorder
                                        border.width: isChosen ? 1.5 : 1

                                        HoverHandler { id: sRoleHover }

                                        Text {
                                            id: semanticRoleTxt
                                            anchors.centerIn: parent
                                            text: semanticRoleBtn.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: semanticRoleBtn.modelData.key === ""
                                                ? (semanticRoleBtn.isChosen ? root.theme.textPrimary : root.theme.textSecondary)
                                                : semanticRoleBtn.roleCol
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyColorToActiveTarget(semanticRoleBtn.modelData.key)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.theme.bgBorder
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "All Palettes (" + root.filteredThemesList.length + " themes)"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 280
                                    height: 30
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: themeSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                    border.width: 1

                                    TextInput {
                                        id: themeSearchInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textPrimary
                                        selectByMouse: true
                                        onTextChanged: root.themeSearchQuery = text

                                        Text {
                                            visible: parent.text === ""
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Search (e.g. Night, Mocha, Taiga)..."
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textMuted
                                        }
                                    }
                                }
                            }

                            Flickable {
                                Layout.fillWidth: true
                                height: 280
                                contentHeight: themesGrid.implicitHeight + 8
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle {
                                        implicitWidth: 4
                                        radius: 2
                                        color: root.theme.bgBorder
                                    }
                                }

                                GridLayout {
                                    id: themesGrid
                                    width: parent.width - 10
                                    columns: 2
                                    columnSpacing: 10
                                    rowSpacing: 8

                                    Repeater {
                                        model: root.filteredThemesList
                                        delegate: Rectangle {
                                            id: themePaletteCard
                                            required property var modelData
                                            Layout.fillWidth: true
                                            height: 40
                                            radius: 8
                                            color: themeCardHover.hovered ? root.theme.bgHover : root.theme.bgBase
                                            border.color: root.theme.bgBorder
                                            border.width: 1

                                            HoverHandler { id: themeCardHover }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8

                                                ColumnLayout {
                                                    spacing: 1
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter

                                                    Text {
                                                        text: themePaletteCard.modelData.name
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Text {
                                                        text: themePaletteCard.modelData.family || "Theme"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        color: root.theme.textMuted
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }

                                                RowLayout {
                                                    spacing: 6
                                                    Layout.alignment: Qt.AlignVCenter

                                                    Repeater {
                                                        model: root.themeAccentKeys
                                                        delegate: Rectangle {
                                                            id: swatchRect
                                                            required property var modelData
                                                            readonly property string fullSpec: "theme:" + themePaletteCard.modelData.name + ":" + modelData.key
                                                            readonly property bool isChosen: root.getActiveTargetSpec() === fullSpec
                                                            readonly property color swatchCol: themePaletteCard.modelData[modelData.key]
                                                                ? Qt.color(String(themePaletteCard.modelData[modelData.key]))
                                                                : root.theme.accentPrimary

                                                            width: 18
                                                            height: 14
                                                            radius: 4
                                                            scale: swatchHover.hovered ? 1.15 : (isChosen ? 1.08 : 1.0)
                                                            color: swatchCol
                                                            border.color: isChosen ? root.theme.textPrimary : (swatchHover.hovered ? root.theme.textSecondary : root.theme.bgBorder)
                                                            border.width: isChosen ? 2 : 1

                                                            HoverHandler { id: swatchHover }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.applyColorToActiveTarget(swatchRect.fullSpec)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: generalTabCol
                    visible: root.currentSubTab === 2
                    Layout.fillWidth: true
                    spacing: 20

                    readonly property string curPos: BarConfig.currentBar ? BarConfig.currentBar.position : BarConfig.position
                    readonly property bool curIsVert: (curPos === "left" || curPos === "right")
                    readonly property int curHeight: BarConfig.currentBar ? Number(BarConfig.currentBar.barHeight) : BarConfig.barHeight
                    readonly property bool curFloating: BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating
                    readonly property real curOpacity: BarConfig.currentBar ? Number(BarConfig.currentBar.barOpacity) : BarConfig.barOpacity
                    readonly property int curPillRadius: BarConfig.currentBar ? (BarConfig.currentBar.pillRadius !== undefined ? Number(BarConfig.currentBar.pillRadius) : 10) : BarConfig.pillRadius
                    readonly property real curPillOpacity: BarConfig.currentBar ? (BarConfig.currentBar.pillOpacity !== undefined ? Number(BarConfig.currentBar.pillOpacity) : 1.0) : BarConfig.pillOpacity
                    readonly property bool curHidePill: BarConfig.currentBar ? Boolean(BarConfig.currentBar.hidePill) : BarConfig.hidePill
                    readonly property string curActiveStyle: BarConfig.currentBar ? (BarConfig.currentBar.activeStyle || BarConfig.activeStyle || "pill") : (BarConfig.activeStyle || "pill")
                    readonly property string curBarColor: BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "")
                    readonly property bool curAllMonitors: BarConfig.currentBar ? Boolean(BarConfig.currentBar.allMonitors) : BarConfig.allMonitors
                    readonly property bool curEnabled: BarConfig.currentBar ? (BarConfig.currentBar.enabled !== false) : BarConfig.barVisible

                    SectionCard {
                        id: generalSection
                        title: "General Appearance: " + root.cleanBarName(BarConfig.currentBar ? BarConfig.currentBar.name : "")
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Desktop Bar"
                            desc: "Display this status bar on the desktop"
                            checked: generalTabCol.curEnabled
                            onToggled: (val) => BarConfig.updateBarProp("enabled", val)
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Position"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Dock to Top, Bottom, Left, or Right edge of the display"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: posSegmentTrack
                                    implicitWidth: 280
                                    implicitHeight: 32
                                    width: 280
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    readonly property string activePos: BarConfig.currentBar ? BarConfig.currentBar.position : BarConfig.position
                                    readonly property int activePosIndex: activePos === "bottom" ? 1 : (activePos === "left" ? 2 : (activePos === "right" ? 3 : 0))
                                    readonly property real cellWidth: (width - 6 - 12) / 4

                                    Rectangle {
                                        y: 3
                                        height: parent.height - 6
                                        width: posSegmentTrack.cellWidth
                                        x: 3 + posSegmentTrack.activePosIndex * (posSegmentTrack.cellWidth + 4)
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Top", value: "top" },
                                                { label: "Bottom", value: "bottom" },
                                                { label: "Left", value: "left" },
                                                { label: "Right", value: "right" }
                                            ]

                                            delegate: Rectangle {
                                                id: posSegBtn
                                                required property var modelData
                                                readonly property bool isSel: posSegmentTrack.activePos === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && posSegHover.hovered ? root.theme.bgHover : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: posSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: posSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: posSegBtn.isSel
                                                    color: posSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: BarConfig.updateBarProp("position", posSegBtn.modelData.value)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            id: barHeightItem
                            Layout.fillWidth: true
                            implicitHeight: customHeightCol.implicitHeight + 20
                            height: implicitHeight
                            clip: true

                            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            readonly property int activeH: BarConfig.currentBar ? Number(BarConfig.currentBar.barHeight) : BarConfig.barHeight
                            readonly property bool isPreset: [28, 32, 36, 40, 46].indexOf(activeH) !== -1
                            property bool customActive: !isPreset

                            ColumnLayout {
                                id: customHeightCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: generalTabCol.curIsVert ? "Bar Thickness (Width)" : "Bar Height"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        Text {
                                            text: generalTabCol.curIsVert ? "Horizontal width in pixels for left/right vertical bar" : "Vertical thickness in pixels"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        id: heightSegmentTrack
                                        implicitWidth: 360
                                        implicitHeight: 32
                                        width: 360
                                        height: 32
                                        radius: 7
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        readonly property int activeIdx: {
                                            if (barHeightItem.customActive) return 5;
                                            const presets = [28, 32, 36, 40, 46];
                                            const idx = presets.indexOf(barHeightItem.activeH);
                                            return idx !== -1 ? idx : 5;
                                        }
                                        readonly property real cellWidth: (width - 6 - 20) / 6

                                        Rectangle {
                                            y: 3
                                            height: parent.height - 6
                                            width: heightSegmentTrack.cellWidth
                                            x: 3 + heightSegmentTrack.activeIdx * (heightSegmentTrack.cellWidth + 4)
                                            radius: 5
                                            color: root.theme.bgSelected
                                            border.color: root.theme.accentPrimary
                                            border.width: 1

                                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 3
                                            spacing: 4

                                            Repeater {
                                                model: [
                                                    { label: "28px", value: 28 },
                                                    { label: "32px", value: 32 },
                                                    { label: "36px", value: 36 },
                                                    { label: "40px", value: 40 },
                                                    { label: "46px", value: 46 },
                                                    { label: "Custom", value: "custom" }
                                                ]

                                                delegate: Rectangle {
                                                    id: hSegBtn
                                                    required property var modelData
                                                    required property int index
                                                    readonly property bool isSel: heightSegmentTrack.activeIdx === hSegBtn.index

                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 5
                                                    color: !isSel && hSegHover.hovered ? root.theme.bgHover : "transparent"
                                                    Behavior on color { ColorAnimation { duration: 140 } }

                                                    HoverHandler { id: hSegHover }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: (hSegBtn.modelData.value === "custom")
                                                            ? (barHeightItem.customActive ? (barHeightItem.activeH + "px") : "Custom...")
                                                            : hSegBtn.modelData.label
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: hSegBtn.isSel
                                                        color: hSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                        opacity: hSegBtn.isSel || hSegHover.hovered ? 1.0 : 0.75
                                                        Behavior on color { ColorAnimation { duration: 140 } }
                                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (hSegBtn.modelData.value === "custom") {
                                                                barHeightItem.customActive = !barHeightItem.customActive;
                                                            } else {
                                                                barHeightItem.customActive = false;
                                                                BarConfig.updateBarProp("barHeight", hSegBtn.modelData.value);
                                                                root.showToast("Bar height set to: " + hSegBtn.modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    id: customSeekbarRow
                                    visible: barHeightItem.customActive
                                    opacity: barHeightItem.customActive ? 1.0 : 0.0
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 12

                                    Behavior on opacity { NumberAnimation { duration: 160 } }

                                    Text {
                                        text: "Custom Height:"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textSecondary
                                        Layout.preferredWidth: 160
                                        Layout.minimumWidth: 160
                                        Layout.maximumWidth: 160
                                    }

                                    Rectangle {
                                        id: heightSeekTrack
                                        Layout.fillWidth: true
                                        height: 6
                                        radius: 3
                                        color: root.theme.bgSelected
                                        Layout.alignment: Qt.AlignVCenter

                                        readonly property real minH: 20.0
                                        readonly property real maxH: 100.0
                                        readonly property real frac: Math.max(0.0, Math.min(1.0, (barHeightItem.activeH - minH) / (maxH - minH)))
                                        readonly property bool isDragging: heightMouse.pressed

                                        Rectangle {
                                            height: parent.height
                                            radius: parent.radius
                                            width: Math.max(0, Math.min(parent.width, parent.width * heightSeekTrack.frac))
                                            color: root.theme.accentPrimary

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: heightSeekTrack.isDragging ? 0 : 140
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        // Outer halo ring on hover/press
                                        Rectangle {
                                            anchors.centerIn: heightKnob
                                            width: heightKnob.width + (heightMouse.pressed ? 8 : (heightMouse.containsMouse ? 6 : 0))
                                            height: width
                                            radius: width / 2
                                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, heightMouse.pressed ? 0.35 : (heightMouse.containsMouse ? 0.2 : 0))
                                            z: 1

                                            Behavior on width { NumberAnimation { duration: 120 } }
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }

                                        // Tactile white knob
                                        Rectangle {
                                            id: heightKnob
                                            width: heightMouse.containsMouse || heightMouse.pressed ? 17 : 15
                                            height: width
                                            radius: width / 2
                                            color: "#ffffff"
                                            border.color: root.theme.accentPrimary
                                            border.width: 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(heightSeekTrack.width - width, (heightSeekTrack.width * heightSeekTrack.frac) - (width / 2)))
                                            z: 2

                                            Behavior on width { NumberAnimation { duration: 120 } }
                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: heightSeekTrack.isDragging ? 0 : 140
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: heightMouse
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            function updateFromPos(mouse) {
                                                if (heightSeekTrack.width <= 0) return;
                                                const trackX = mapToItem(heightSeekTrack, mouse.x, 0).x;
                                                const f = Math.max(0.0, Math.min(1.0, trackX / heightSeekTrack.width));
                                                const val = Math.round(heightSeekTrack.minH + f * (heightSeekTrack.maxH - heightSeekTrack.minH));
                                                BarConfig.updateBarProp("barHeight", val);
                                            }
                                            onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                            onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                                            onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                        }
                                    }

                                    Text {
                                        text: barHeightItem.activeH + "px"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                        Layout.preferredWidth: 44
                                        horizontalAlignment: Text.AlignRight
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Floating Bar"
                            desc: "Add screen margins and rounded outer corners"
                            checked: BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating
                            onToggled: (val) => BarConfig.updateBarProp("floating", val)
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Inner Rounded Corners"
                            desc: "Display concave rounded corners connecting docked bar edges to screen borders"
                            checked: BarConfig.currentBar ? (BarConfig.currentBar.innerCorners !== undefined ? Boolean(BarConfig.currentBar.innerCorners) : Boolean(BarConfig.innerCorners)) : Boolean(BarConfig.innerCorners)
                            rowEnabled: !(BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating)
                            onToggled: (val) => {
                                BarConfig.innerCorners = val;
                                BarConfig.updateBarProp("innerCorners", val);
                            }
                        }

                        RowDivider {}

                        Item {
                            id: barOpacityItem
                            Layout.fillWidth: true
                            height: 52
                            readonly property real activeOpacity: BarConfig.currentBar ? Number(BarConfig.currentBar.barOpacity) : BarConfig.barOpacity

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 160
                                    Layout.minimumWidth: 160
                                    Layout.maximumWidth: 160
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Opacity"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "Background transparency"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    id: opacityTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real val: barOpacityItem.activeOpacity
                                    readonly property bool isDragging: opMouse.pressed

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * opacityTrack.val))
                                        color: root.theme.accentPrimary

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: opacityTrack.isDragging ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    // Outer halo ring on hover/press
                                    Rectangle {
                                        anchors.centerIn: opKnob
                                        width: opKnob.width + (opMouse.pressed ? 8 : (opMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, opMouse.pressed ? 0.35 : (opMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: opKnob
                                        width: opMouse.containsMouse || opMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(opacityTrack.width - width, (opacityTrack.width * opacityTrack.val) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            NumberAnimation {
                                                duration: opacityTrack.isDragging ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: opMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        preventStealing: true
                                        cursorShape: Qt.PointingHandCursor
                                        function updateFromPos(mouse) {
                                            if (opacityTrack.width <= 0) return;
                                            const trackX = mapToItem(opacityTrack, mouse.x, 0).x;
                                            const frac = Math.max(0.1, Math.min(1.0, trackX / opacityTrack.width));
                                            BarConfig.updateBarProp("barOpacity", Math.round(frac * 100) / 100);
                                        }
                                        onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                        onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                                        onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                    }
                                }

                                Text {
                                    text: Math.round(opacityTrack.val * 100) + "%"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            id: barColorSettingRow
                            Layout.fillWidth: true
                            height: 52

                            readonly property string barSpec: generalTabCol.curBarColor
                            readonly property color resolvedColor: root.resolveThemeSpec(barSpec, root.theme.bgBase)
                            readonly property bool isCustom: barSpec !== ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Background Color"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Custom color for desktop bar and matching inner corners"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 5
                                        color: barColorSettingRow.resolvedColor
                                        border.color: root.theme.bgBorder
                                        border.width: 1
                                    }

                                    Text {
                                        text: barColorSettingRow.isCustom ? root.getSpecLabel(barColorSettingRow.barSpec) : "Auto (Default)"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: barColorSettingRow.isCustom ? root.theme.accentPrimary : root.theme.textSecondary
                                    }

                                    ActionButton {
                                        iconText: "󰏘"
                                        label: "Customize Color..."
                                        btnHeight: 28
                                        onClicked: {
                                            root.selectedColorTargetType = "bar";
                                            root.currentSubTab = 1;
                                            subTabContentAnim.restart();
                                        }
                                    }

                                    ActionButton {
                                        visible: barColorSettingRow.isCustom
                                        iconText: "󰦛"
                                        label: "Reset"
                                        danger: true
                                        btnHeight: 28
                                        onClicked: BarConfig.updateBarProp("barColor", "")
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Hide Pill Backgrounds"
                            desc: "Remove individual widget card backgrounds for a clean, borderless appearance"
                            checked: generalTabCol.curHidePill
                            onToggled: (val) => BarConfig.updateBarProp("hidePill", val)
                        }

                        RowDivider {}

                        Item {
                            id: activeStyleItem
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Active Indicator Style"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Highlight style for active workspaces and menus"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: activeStyleSegmentTrack
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    width: 260
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    readonly property string activeStyleVal: generalTabCol.curActiveStyle
                                    readonly property int activeIdx: activeStyleVal === "underline" ? 1 : (activeStyleVal === "both" ? 2 : 0)
                                    readonly property real cellWidth: (width - 6 - 8) / 3

                                    Rectangle {
                                        y: 3
                                        height: parent.height - 6
                                        width: activeStyleSegmentTrack.cellWidth
                                        x: 3 + activeStyleSegmentTrack.activeIdx * (activeStyleSegmentTrack.cellWidth + 4)
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Pill", value: "pill" },
                                                { label: "Line", value: "underline" },
                                                { label: "Both", value: "both" }
                                            ]

                                            delegate: Rectangle {
                                                id: styleSegBtn
                                                required property var modelData
                                                readonly property bool isSel: activeStyleSegmentTrack.activeStyleVal === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && styleSegHover.hovered ? root.theme.bgHover : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: styleSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: styleSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: styleSegBtn.isSel
                                                    color: styleSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: styleSegBtn.isSel || styleSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: BarConfig.updateBarProp("activeStyle", styleSegBtn.modelData.value)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            id: pillRadiusItem
                            Layout.fillWidth: true
                            height: 64
                            readonly property int activeRadius: generalTabCol.curPillRadius
                            opacity: generalTabCol.curHidePill ? 0.45 : 1.0
                            enabled: !generalTabCol.curHidePill
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 160
                                    Layout.minimumWidth: 160
                                    Layout.maximumWidth: 160
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Pill Corner Radius"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "Widget pill rounded corners"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Rectangle {
                                            id: pillRadiusTrack
                                            Layout.fillWidth: true
                                            height: 6
                                            radius: 3
                                            color: root.theme.bgSelected
                                            Layout.alignment: Qt.AlignVCenter

                                            readonly property real maxRadius: 14.0
                                            readonly property real frac: Math.max(0.0, Math.min(1.0, pillRadiusItem.activeRadius / maxRadius))
                                            readonly property bool isDragging: pillRadMouse.pressed

                                            Rectangle {
                                                height: parent.height
                                                radius: parent.radius
                                                width: Math.max(0, Math.min(parent.width, parent.width * pillRadiusTrack.frac))
                                                color: root.theme.accentPrimary

                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: pillRadiusTrack.isDragging ? 0 : 140
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }

                                            // Outer halo ring on hover/press
                                            Rectangle {
                                                anchors.centerIn: pillRadKnob
                                                width: pillRadKnob.width + (pillRadMouse.pressed ? 8 : (pillRadMouse.containsMouse ? 6 : 0))
                                                height: width
                                                radius: width / 2
                                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, pillRadMouse.pressed ? 0.35 : (pillRadMouse.containsMouse ? 0.2 : 0))
                                                z: 1

                                                Behavior on width { NumberAnimation { duration: 120 } }
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                            }

                                            // Tactile white knob
                                            Rectangle {
                                                id: pillRadKnob
                                                width: pillRadMouse.containsMouse || pillRadMouse.pressed ? 17 : 15
                                                height: width
                                                radius: width / 2
                                                color: "#ffffff"
                                                border.color: root.theme.accentPrimary
                                                border.width: 3
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: Math.max(0, Math.min(pillRadiusTrack.width - width, (pillRadiusTrack.width * pillRadiusTrack.frac) - (width / 2)))
                                                z: 2

                                                Behavior on width { NumberAnimation { duration: 120 } }
                                                Behavior on x {
                                                    NumberAnimation {
                                                        duration: pillRadiusTrack.isDragging ? 0 : 140
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: pillRadMouse
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                hoverEnabled: true
                                                preventStealing: true
                                                cursorShape: Qt.PointingHandCursor
                                                function updateFromPos(mouse) {
                                                    if (pillRadiusTrack.width <= 0) return;
                                                    const trackX = mapToItem(pillRadiusTrack, mouse.x, 0).x;
                                                    const frac = Math.max(0.0, Math.min(1.0, trackX / pillRadiusTrack.width));
                                                    const val = Math.round(frac * pillRadiusTrack.maxRadius);
                                                    BarConfig.updateBarProp("pillRadius", val);
                                                }
                                                onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                                onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                                                onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                            }
                                        }

                                        Text {
                                            text: pillRadiusItem.activeRadius + "px"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 40
                                            horizontalAlignment: Text.AlignRight
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    RowLayout {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { label: "Sharp", r: 0 },
                                                { label: "Subtle", r: 4 },
                                                { label: "Default", r: 10 },
                                                { label: "Capsule", r: 14 }
                                            ]
                                            delegate: Rectangle {
                                                id: rPresetBtn
                                                required property var modelData
                                                readonly property bool isSel: pillRadiusItem.activeRadius === modelData.r
                                                implicitWidth: 62
                                                implicitHeight: 22
                                                radius: 4
                                                color: isSel ? root.theme.bgSelected : (rPresetHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                                                border.color: isSel ? root.theme.accentPrimary : root.theme.bgBorder
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: rPresetHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rPresetBtn.modelData.label + " (" + rPresetBtn.modelData.r + ")"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: rPresetBtn.isSel
                                                    color: rPresetBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: BarConfig.updateBarProp("pillRadius", rPresetBtn.modelData.r)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            id: pillOpacityItem
                            Layout.fillWidth: true
                            height: 52
                            readonly property real activePillOpacity: generalTabCol.curPillOpacity
                            opacity: generalTabCol.curHidePill ? 0.45 : 1.0
                            enabled: !generalTabCol.curHidePill
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 160
                                    Layout.minimumWidth: 160
                                    Layout.maximumWidth: 160
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Pill Background Opacity"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "Transparency of widget cards"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    id: pillOpacityTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real val: pillOpacityItem.activePillOpacity
                                    readonly property bool isDragging: pillOpMouse.pressed

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * pillOpacityTrack.val))
                                        color: root.theme.accentPrimary

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: pillOpacityTrack.isDragging ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    // Outer halo ring on hover/press
                                    Rectangle {
                                        anchors.centerIn: pillOpKnob
                                        width: pillOpKnob.width + (pillOpMouse.pressed ? 8 : (pillOpMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, pillOpMouse.pressed ? 0.35 : (pillOpMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: pillOpKnob
                                        width: pillOpMouse.containsMouse || pillOpMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(pillOpacityTrack.width - width, (pillOpacityTrack.width * pillOpacityTrack.val) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            NumberAnimation {
                                                duration: pillOpacityTrack.isDragging ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: pillOpMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        preventStealing: true
                                        cursorShape: Qt.PointingHandCursor
                                        function updateFromPos(mouse) {
                                            if (pillOpacityTrack.width <= 0) return;
                                            const trackX = mapToItem(pillOpacityTrack, mouse.x, 0).x;
                                            const frac = Math.max(0.0, Math.min(1.0, trackX / pillOpacityTrack.width));
                                            BarConfig.updateBarProp("pillOpacity", Math.round(frac * 100) / 100);
                                        }
                                        onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                        onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                                        onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                                    }
                                }

                                Text {
                                    text: Math.round(pillOpacityTrack.val * 100) + "%"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Show on All Displays"
                            desc: "Display status bar across all connected monitors"
                            checked: BarConfig.currentBar ? Boolean(BarConfig.currentBar.allMonitors) : BarConfig.allMonitors
                            onToggled: (val) => BarConfig.updateBarProp("allMonitors", val)
                        }
                    }

                    SectionCard {
                        title: "Network Speed Options"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Download Speed (󰇚)"
                            desc: "Display live incoming network bandwidth rate on the Network pill"
                            checked: BarConfig.showNetDown
                            onToggled: (val) => {
                                if (!val && !BarConfig.showNetUp) BarConfig.showNetUp = true;
                                BarConfig.showNetDown = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Download speed visible" : "Download speed hidden");
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Show Upload Speed (󰕒)"
                            desc: "Display live outgoing network bandwidth rate on the Network pill"
                            checked: BarConfig.showNetUp
                            onToggled: (val) => {
                                if (!val && !BarConfig.showNetDown) BarConfig.showNetDown = true;
                                BarConfig.showNetUp = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Upload speed visible" : "Upload speed hidden");
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Compact Speed Format"
                            desc: "Use concise unit labels (e.g. 1.2M / 45K instead of 1.2 MB/s / 45 KB/s)"
                            checked: BarConfig.netCompact
                            onToggled: (val) => {
                                BarConfig.netCompact = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Compact speed format enabled" : "Standard speed format enabled");
                            }
                        }
                    }

                    SectionCard {
                        title: "Clock Options"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Seconds in Clock"
                            desc: "Display precision seconds format (hh:mm:ss)"
                            checked: BarConfig.showSeconds
                            onToggled: (val) => {
                                BarConfig.showSeconds = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Clock seconds visible" : "Clock seconds hidden");
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Show Date in Clock"
                            desc: "Display weekday and calendar date alongside the time"
                            checked: BarConfig.showDate
                            onToggled: (val) => {
                                BarConfig.showDate = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Clock date visible" : "Clock date hidden");
                            }
                        }
                    }

                    SectionCard {
                        title: "Workspaces Options"
                        contentMargins: 8
                        contentSpacing: 0

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Workspace Numbering Style"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Display numeric digits, Roman numerals, or minimal dots"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "1, 2, 3", value: "index" },
                                                { label: "I, II, III", value: "roman" },
                                                { label: "• • •", value: "dot" }
                                            ]
                                            delegate: Rectangle {
                                                 id: wsStyleBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.workspaceStyle || "index") === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (wsHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: wsHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wsStyleBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: wsStyleBtn.isSel
                                                    color: wsStyleBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.workspaceStyle = wsStyleBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Workspace style set to: " + wsStyleBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Mouse Wheel Workspace Switching"
                            desc: "Scroll over workspace pills to navigate between active workspaces"
                            checked: BarConfig.workspaceScrollSwitch !== false
                            onToggled: (val) => {
                                BarConfig.workspaceScrollSwitch = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Mouse wheel workspace switching enabled" : "Mouse wheel workspace switching disabled");
                            }
                        }
                    }

                    SectionCard {
                        title: "Global Menu (AppMenu) Options"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Menu Glyph (󰍜)"
                            desc: "Display application menu indicator icon before File, Edit, Help menus"
                            checked: BarConfig.showGlobalMenuIcon
                            onToggled: (val) => {
                                BarConfig.showGlobalMenuIcon = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Global menu glyph enabled" : "Global menu glyph hidden");
                            }
                        }
                    }

                    SectionCard {
                        title: "Weather Options"
                        contentMargins: 8
                        contentSpacing: 0

                        Item {
                            Layout.fillWidth: true
                            height: 60

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Weather Location (City / Region)"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Specify city name (e.g. Bekasi, Jakarta, Tokyo) or leave blank for auto-IP"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                    Rectangle {
                                        width: 220
                                        height: 32
                                        radius: 7
                                        color: root.theme.bgBase
                                        border.color: weatherLocationInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                                        border.width: 1

                                        TextInput {
                                            id: weatherLocationInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textPrimary
                                            selectByMouse: true
                                            text: BarConfig.weatherLocation

                                            function applyChange() {
                                                const trimmed = text.trim();
                                                BarConfig.weatherLocation = trimmed;
                                                BarConfig.saveConfig();
                                                SystemInfo.refreshWeather();
                                                root.showToast("Weather location set to: " + (trimmed || "Auto-detect"));
                                            }

                                            onAccepted: applyChange()

                                            Text {
                                                visible: parent.text === "" && !parent.activeFocus
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Auto-detect (by IP)..."
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                        }
                                    }

                                    ActionButton {
                                        label: "Apply"
                                        btnHeight: 32
                                        onClicked: weatherLocationInput.applyChange()
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Temperature Unit"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Choose metric (°C) or imperial (°F) units for readouts and popup"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 220
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Metric (°C)", value: "m" },
                                                { label: "Imperial (°F)", value: "u" }
                                            ]
                                            delegate: Rectangle {
                                                id: wUnitBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.weatherUnit || "m") === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (wUnitHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: wUnitHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wUnitBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: wUnitBtn.isSel
                                                    color: wUnitBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.weatherUnit = wUnitBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        SystemInfo.refreshWeather();
                                                        root.showToast("Weather unit set to: " + wUnitBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Popup Forecast Detail"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Choose between concise today-only summary or full 3-day multi-period forecast"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 240
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Compact (1-Day)", value: "compact" },
                                                { label: "Detailed (3-Day)", value: "full" }
                                            ]
                                            delegate: Rectangle {
                                                id: wModeBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.weatherMode || "compact") === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (wModeHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: wModeHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wModeBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: wModeBtn.isSel
                                                    color: wModeBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.weatherMode = wModeBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Forecast format set to: " + wModeBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Auto-Refresh Interval"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Background poll frequency for weather updates"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 240
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "15 min", value: 15 },
                                                { label: "30 min", value: 30 },
                                                { label: "1 hour", value: 60 }
                                            ]
                                            delegate: Rectangle {
                                                id: wIntBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.weatherIntervalMinutes || 15) === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (wIntHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: wIntHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wIntBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: wIntBtn.isSel
                                                    color: wIntBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.weatherIntervalMinutes = wIntBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Weather poll interval set to: " + wIntBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        title: "Battery Pill Options"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Battery Percentage"
                            desc: "Display numerical charge percentage text alongside the battery status icon"
                            checked: BarConfig.batteryShowPercentage !== false
                            onToggled: (val) => {
                                BarConfig.batteryShowPercentage = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Battery percentage visible" : "Battery percentage hidden");
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Low Battery Alert Level"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Percentage at which battery icon turns red to warn about low charge"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "15%", value: 15 },
                                                { label: "20%", value: 20 },
                                                { label: "25%", value: 25 },
                                                { label: "30%", value: 30 }
                                            ]
                                            delegate: Rectangle {
                                                id: batThreshBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.batteryLowThreshold || 20) === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (batThreshHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: batThreshHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: batThreshBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: batThreshBtn.isSel
                                                    color: batThreshBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.batteryLowThreshold = batThreshBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Battery warning threshold set to: " + batThreshBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        title: "Cava Visualizer Options"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Enable Cava Visualizer"
                            desc: "Allow audio spectrum streaming when Cava is placed on a bar"
                            checked: BarConfig.showCava !== false
                            onToggled: (val) => {
                                BarConfig.showCava = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Cava visualizer enabled" : "Cava visualizer disabled");
                            }
                        }



                        RowDivider {}

                        SettingToggleRow {
                            title: "Auto-Hide When Silent"
                            desc: "Hide or minimize the spectrum pill when no audio is currently playing"
                            checked: BarConfig.cavaAutoHide
                            onToggled: (val) => {
                                BarConfig.cavaAutoHide = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Auto-hide enabled" : "Auto-hide disabled");
                            }
                        }

                        RowDivider {}

                        // Visual Style Selector: Smooth Bars / Glyphs / Line Waves
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Visualizer Display Style"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Choose between smooth rounded bars, centered waves, or terminal glyphs"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Bars", value: "bars" },
                                                { label: "Line", value: "line" },
                                                { label: "Glyphs", value: "glyphs" }
                                            ]
                                            delegate: Rectangle {
                                                id: cavaStyleBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.cavaStyle || "bars") === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (cavaStyleHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: cavaStyleHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cavaStyleBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: cavaStyleBtn.isSel
                                                    color: cavaStyleBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.cavaStyle = cavaStyleBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Cava style set to: " + cavaStyleBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        // Cava Visualizer Mode Selector: Compact (Current) / Medium / Wide
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Cava Visualizer Mode"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Choose visualizer size: Compact (current), Medium, or Wide"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "Compact", value: "compact" },
                                                { label: "Medium",  value: "medium" },
                                                { label: "Wide",    value: "wide" }
                                            ]
                                            delegate: Rectangle {
                                                id: cavaModeBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.cavaMode || "compact") === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (cavaModeHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: cavaModeHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cavaModeBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: cavaModeBtn.isSel
                                                    color: cavaModeBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.setCavaMode(cavaModeBtn.modelData.value);
                                                        root.showToast("Cava mode set to: " + cavaModeBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        // Refresh Framerate Selector: 20, 30, 60 FPS
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Visualizer Framerate"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Update rate in frames per second (higher is smoother, lower uses less CPU)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "20 FPS", value: 20 },
                                                { label: "30 FPS", value: 30 },
                                                { label: "60 FPS", value: 60 }
                                            ]
                                            delegate: Rectangle {
                                                id: cavaFpsBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.cavaFramerate || 30) === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (cavaFpsHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: cavaFpsHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cavaFpsBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: cavaFpsBtn.isSel
                                                    color: cavaFpsBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.cavaFramerate = cavaFpsBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Cava framerate set to: " + cavaFpsBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        title: "Hardware Monitor Options (CPU / RAM / Temp / Disk)"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Show Sensor Glyphs"
                            desc: "Display icons (CPU, RAM, Temp, Disk) before numerical utilization figures"
                            checked: BarConfig.hwShowIcons !== false
                            onToggled: (val) => {
                                BarConfig.hwShowIcons = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "Sensor glyphs visible" : "Sensor glyphs hidden");
                            }
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "High Load Warning Alerts"
                            desc: "Highlight hardware pills in red when processor, memory, or thermal levels reach critical levels"
                            checked: BarConfig.hwAlertEnabled !== false
                            onToggled: (val) => {
                                BarConfig.hwAlertEnabled = val;
                                BarConfig.saveConfig();
                                root.showToast(val ? "High load alerts enabled" : "High load alerts disabled");
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Critical Alert Threshold"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Percentage (%) or temperature (°C) that triggers warning highlights"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "75%", value: 75 },
                                                { label: "80%", value: 80 },
                                                { label: "85%", value: 85 },
                                                { label: "90%", value: 90 }
                                            ]
                                            delegate: Rectangle {
                                                id: hwThreshBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.hwAlertThreshold || 85) === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (hwThreshHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: hwThreshHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: hwThreshBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: hwThreshBtn.isSel
                                                    color: hwThreshBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.hwAlertThreshold = hwThreshBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Hardware alert threshold set to: " + hwThreshBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Hardware Polling Frequency"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Update interval for CPU, memory, network, and thermal sensors"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 260
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: [
                                                { label: "1s (Fast)", value: 1 },
                                                { label: "2s (Norm)", value: 2 },
                                                { label: "5s (Eco)", value: 5 }
                                            ]
                                            delegate: Rectangle {
                                                id: pollRateBtn
                                                required property var modelData
                                                readonly property bool isSel: (BarConfig.hwPollInterval || 2) === modelData.value

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSel ? root.theme.bgSelected : (pollRateHov.hovered ? root.theme.bgHover : "transparent")
                                                border.color: isSel ? root.theme.accentPrimary : "transparent"
                                                border.width: isSel ? 1 : 0

                                                HoverHandler { id: pollRateHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: pollRateBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: pollRateBtn.isSel
                                                    color: pollRateBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        BarConfig.hwPollInterval = pollRateBtn.modelData.value;
                                                        BarConfig.saveConfig();
                                                        root.showToast("Hardware polling interval set to: " + pollRateBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: dragGhostCard
        readonly property bool activeDrag: root.isDraggingBlock && root.draggedWidgetId !== ""
        readonly property bool isRemoving: root.dragHoverPanelIndex === -2 && root.dragSourcePanelIndex >= 0
        readonly property bool isTargetMaxed: root.isDraggingBlock
            && root.dragHoverPanelIndex >= 0
            && root.dragHoverPanelIndex !== root.dragSourcePanelIndex
            && !BarConfig.canAddWidgetToPanel(root.draggedWidgetId, root.dragHoverPanelIndex)
        readonly property var dragMeta: BarConfig.getWidgetMeta(root.draggedWidgetId)
        readonly property color dragColor: root.resolveThemeSpec(root.getBlockColorSpec(root.draggedWidgetId), root.theme.accentPrimary)

        visible: opacity > 0.01
        z: 9999
        implicitWidth: ghostRow.implicitWidth + 24
        width: implicitWidth
        height: 36
        radius: 8
        x: Math.max(4, Math.min(root.width - width - 4, root.dragMouseX - (width / 2)))
        y: Math.max(4, Math.min(root.height - height - 4, root.dragMouseY - (height / 2)))
        scale: activeDrag ? 1.04 : 0.92
        opacity: activeDrag ? 0.96 : 0.0
        color: (isRemoving || isTargetMaxed) ? root.withAlpha(root.theme.accentRed, 0.18) : root.theme.bgSelected
        border.color: (isRemoving || isTargetMaxed) ? root.theme.accentRed : dragColor
        border.width: 1.5

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Row {
            id: ghostRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dragGhostCard.isRemoving ? "󰅖" : (dragGhostCard.isTargetMaxed ? "󰀪" : dragGhostCard.dragMeta.icon)
                font.family: root.font
                font.pixelSize: 13
                color: (dragGhostCard.isRemoving || dragGhostCard.isTargetMaxed) ? root.theme.accentRed : dragGhostCard.dragColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dragGhostCard.isTargetMaxed
                    ? (dragGhostCard.dragMeta.name + " (Maxed out)")
                    : (dragGhostCard.isRemoving ? ("Remove " + dragGhostCard.dragMeta.name) : dragGhostCard.dragMeta.name)
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: (dragGhostCard.isRemoving || dragGhostCard.isTargetMaxed) ? root.theme.accentRed : root.theme.textPrimary
            }
        }
    }

    // Feedback Toast (bottom floating notification)
    Rectangle {
        id: statusToast
        z: 10000
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        implicitWidth: toastRow.implicitWidth + 32
        height: 38
        radius: 19
        color: root.toastIsWarning ? root.withAlpha(root.theme.accentRed, 0.25) : (root.theme.bgSelected ?? "#283457")
        border.color: root.toastIsWarning ? root.theme.accentRed : (root.theme.accentPrimary ?? "#7aa2f7")
        border.width: 1.5
        opacity: root.toastVisible ? 1.0 : 0.0
        scale: root.toastVisible ? 1.0 : 0.92
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: 0

            Text {
                id: toastText
                text: root.toastMessage
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
            }
        }
    }
}
