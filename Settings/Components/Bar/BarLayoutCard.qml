import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    property alias panelRepeater: panelColumnsRepeater
    property alias poolCard: availPoolCard
    visible: root.currentSubTab === 0
    title: {
        const cur = BarConfig.currentBar;
        const tgt = cur ? (cur.displayTarget || (cur.allMonitors ? "all" : "primary")) : "primary";
        if (tgt === "all") {
            const isSec = root.hasMultipleMonitors && BarConfig.activeEditingDisplay === "secondary";
            const mName = root.getMonitorNameForTarget(isSec ? "secondary" : "primary");
            return "Bar Layout & Building Blocks: " + (isSec ? "Secondary Bar" : "Primary Bar") + " (" + mName + (root.isSingleMonitor ? " · Single Monitor" : "") + ")";
        }
        const mName = root.getMonitorNameForTarget(tgt);
        return "Bar Layout & Building Blocks: " + root.cleanBarName(cur ? cur.name : "") + " (" + mName + (root.isSingleMonitor ? " · Single Monitor" : "") + ")";
    }
    subtitle: "Drag blocks to reorder or move between panels · Click block to color · ✕ to remove"

    Rectangle {
        visible: BarConfig.activeEditingDisplay !== "secondary" || (BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode) === "custom"
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
                        scale: pCountMouse.pressed ? 0.94 : (pCountHover.hovered ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

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
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: pCountMouse
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
        visible: BarConfig.activeEditingDisplay !== "secondary" || (BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode) === "custom"
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
                            root: self.root
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

    // Blank Bar Mode Graphic Preview Card
    Rectangle {
        visible: BarConfig.activeEditingDisplay === "secondary" && (BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode) === "blank"
        Layout.fillWidth: true
        implicitHeight: 200
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: "󰌨"
                font.family: root.font
                font.pixelSize: 36
                color: root.theme.accentPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Clean Blank Bar Active on Secondary Display"
                font.family: root.font
                font.pixelSize: 14
                font.bold: true
                color: root.theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "An empty status bar frame matching your bar's height, opacity, and corners is displayed on your secondary monitor.\nThis maintains window docking margins and desktop balance with zero widget overhead."
                font.family: root.font
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                color: root.theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }

            ActionButton {
                Layout.alignment: Qt.AlignHCenter
                iconText: "󰒓"
                label: "Switch to Custom Layout"
                btnHeight: 30
                onClicked: BarConfig.updateBarProp("secondaryMode", "custom")
            }
        }
    }

    // Mirror Primary Graphic Preview Card
    Rectangle {
        visible: BarConfig.activeEditingDisplay === "secondary" && (BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode) === "mirror"
        Layout.fillWidth: true
        implicitHeight: 200
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: "󰍹"
                font.family: root.font
                font.pixelSize: 36
                color: root.theme.accentPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Mirroring Primary Display Layout"
                font.family: root.font
                font.pixelSize: 14
                font.bold: true
                color: root.theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Your secondary monitor duplicates the exact panel layout and widgets configured on the Primary Display bar in real time."
                font.family: root.font
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                color: root.theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }

            ActionButton {
                Layout.alignment: Qt.AlignHCenter
                iconText: "󰒓"
                label: "Customize Secondary Layout Independently"
                btnHeight: 30
                onClicked: BarConfig.updateBarProp("secondaryMode", "custom")
            }
        }
    }

    Rectangle {
        id: availPoolCard
        visible: BarConfig.activeEditingDisplay !== "secondary" || (BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode) === "custom"
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
                            root: self.root
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
