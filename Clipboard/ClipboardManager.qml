import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

Scope {
    id: root

    property var theme: DefaultTheme {}
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    property int selectedIndex: 0
    property bool confirmWipe: false
    property bool panelVisible: false

    IpcHandler {
        target: "clipboard"

        function toggle() {
            if (root.panelVisible && clipLoader.item) {
                clipLoader.item.requestClose();
                return;
            }
            root.panelVisible = !root.panelVisible;
            if (root.panelVisible) {
                if (ClipboardConfig.clearSearchOnClose) {
                    ClipboardService.searchText = "";
                }
                ClipboardService.activeCategory = ClipboardConfig.defaultCategory || "all";
                ClipboardService.refresh();
                root.selectedIndex = 0;
                root.confirmWipe = false;
            }
        }

        function open() {
            root.panelVisible = true;
            if (ClipboardConfig.clearSearchOnClose) {
                ClipboardService.searchText = "";
            }
            ClipboardService.activeCategory = ClipboardConfig.defaultCategory || "all";
            ClipboardService.refresh();
            root.selectedIndex = 0;
            root.confirmWipe = false;
        }

        function close() {
            if (clipLoader.item) {
                clipLoader.item.requestClose();
            } else {
                root.panelVisible = false;
            }
        }
    }

    Loader {
        id: clipLoader
        active: root.panelVisible
        sourceComponent: Component {
    PanelWindow {
        id: clipboardPanel
        visible: true
        focusable: true
        color: "transparent"

        property bool closing: false

        function requestClose() {
            if (clipboardPanel.closing) return;
            clipboardPanel.closing = true;
            openAnim.stop();
            closeAnim.start();
        }

        Component.onCompleted: {
            openAnim.start();
            Qt.callLater(() => searchInput.forceActiveFocus());
        }

        Component.onDestruction: {
            ClipboardService.releaseMemory();
        }

        onVisibleChanged: {
            if (!visible) {
                ClipboardService.releaseMemory();
                root.panelVisible = false;
                Qt.callLater(() => gc());
            }
        }

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: mainCard; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: mainCard; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation { target: mainCard; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: mainCard; property: "scale"; to: 0.97; duration: 110; easing.type: Easing.InCubic }
            onFinished: clipboardPanel.visible = false
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-clipboard"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Undimmed transparent backdrop
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            onClicked: clipboardPanel.requestClose()
        }

        // Main modal dialog container
        Rectangle {
            id: mainCard
            anchors.centerIn: parent
            width: Math.min(ClipboardConfig.windowWidth, parent.width - 40)
            height: Math.min(ClipboardConfig.windowHeight, parent.height - 40)
            radius: 16
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true
            opacity: 0.0
            scale: 0.96

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                onClicked: (event) => event.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Title
                    RowLayout {
                        spacing: 8

                        Text {
                            text: "Clipboard History"
                            color: root.theme.accentPrimary
                            font.pixelSize: 15
                            font.family: root.font
                            font.bold: true
                        }

                        // Badge
                        Rectangle {
                            height: 20
                            implicitWidth: countBadgeText.implicitWidth + 12
                            radius: 10
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                            border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                            border.width: 1

                            Text {
                                id: countBadgeText
                                anchors.centerIn: parent
                                text: ClipboardService.filteredItems.length + (ClipboardService.filteredItems.length === ClipboardService.totalCount ? " items" : ` / ${ClipboardService.totalCount}`)
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Toast Feedback pill (if any)
                    Rectangle {
                        visible: ClipboardService.toastMessage !== ""
                        height: 24
                        implicitWidth: toastLabel.implicitWidth + 16
                        radius: 12
                        color: Qt.rgba(root.theme.accentGreen.r, root.theme.accentGreen.g, root.theme.accentGreen.b, 0.18)
                        border.color: root.theme.accentGreen
                        border.width: 1

                        Text {
                            id: toastLabel
                            anchors.centerIn: parent
                            text: ClipboardService.toastMessage
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: root.theme.accentGreen
                        }
                    }

                    // Refresh Button
                    Rectangle {
                        implicitWidth: refreshBtnText.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: refreshMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                        border.color: root.theme.bgBorder
                        border.width: 1
                        scale: refreshMouse.containsMouse ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Text {
                            id: refreshBtnText
                            anchors.centerIn: parent
                            text: "Refresh"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.refresh()
                        }
                    }

                    // Clear All / Wipe Button
                    Rectangle {
                        implicitWidth: wipeBtnText.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: root.confirmWipe
                            ? (root.theme.accentRed ?? "#e05252")
                            : (wipeMouse.containsMouse ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.06)))
                        border.color: (root.confirmWipe || wipeMouse.containsMouse) ? root.theme.accentRed : root.theme.bgBorder
                        border.width: 1
                        scale: wipeMouse.containsMouse ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Text {
                            id: wipeBtnText
                            anchors.centerIn: parent
                            text: root.confirmWipe ? "Confirm Wipe?" : "Clear All"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.confirmWipe ? "#ffffff" : (wipeMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted)
                        }

                        MouseArea {
                            id: wipeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.confirmWipe) {
                                    ClipboardService.wipeAll();
                                    root.confirmWipe = false;
                                } else {
                                    root.confirmWipe = true;
                                }
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        implicitWidth: closeBtnText.implicitWidth + 20
                        height: 28
                        radius: 6
                        color: closeMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                        border.color: root.theme.bgBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Text {
                            id: closeBtnText
                            anchors.centerIn: parent
                            text: "Close"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: closeMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardPanel.requestClose()
                        }
                    }
                }

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 8

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: root.theme.textPrimary
                            font.pixelSize: 12
                            font.family: root.font
                            clip: true
                            selectByMouse: true
                            text: ClipboardService.searchText
                            onTextChanged: {
                                ClipboardService.searchText = text;
                                root.selectedIndex = 0;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search copied text, URLs, images..."
                                color: root.theme.textMuted
                                font.pixelSize: 12
                                font.family: root.font
                                visible: !parent.text && !parent.activeFocus
                            }

                            Keys.onDownPressed: {
                                if (root.selectedIndex < ClipboardService.filteredItems.length - 1) {
                                    root.selectedIndex++;
                                    clipListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                }
                            }
                            Keys.onUpPressed: {
                                if (root.selectedIndex > 0) {
                                    root.selectedIndex--;
                                    clipListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                }
                            }
                            Keys.onReturnPressed: {
                                if (ClipboardService.filteredItems.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < ClipboardService.filteredItems.length) {
                                    const it = ClipboardService.filteredItems[root.selectedIndex];
                                    ClipboardService.copyItem(it.id, it.preview);
                                    if (ClipboardConfig.closeOnCopy) clipboardPanel.requestClose();
                                }
                            }
                            Keys.onEnterPressed: {
                                if (ClipboardService.filteredItems.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < ClipboardService.filteredItems.length) {
                                    const it = ClipboardService.filteredItems[root.selectedIndex];
                                    ClipboardService.copyItem(it.id, it.preview);
                                    if (ClipboardConfig.closeOnCopy) clipboardPanel.requestClose();
                                }
                            }
                            Keys.onDeletePressed: {
                                if (ClipboardService.filteredItems.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < ClipboardService.filteredItems.length) {
                                    const it = ClipboardService.filteredItems[root.selectedIndex];
                                    ClipboardService.deleteItem(it.id);
                                }
                            }
                            Keys.onEscapePressed: {
                                if (text !== "") {
                                    text = "";
                                } else {
                                    clipboardPanel.requestClose();
                                }
                            }
                        }

                        // Clear search text button
                        Rectangle {
                            visible: searchInput.text !== ""
                            implicitWidth: clearSearchText.implicitWidth + 12
                            height: 20
                            radius: 4
                            color: clearSearchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            Text {
                                id: clearSearchText
                                anchors.centerIn: parent
                                text: "Clear"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textMuted
                            }

                            MouseArea {
                                id: clearSearchMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Filter Category Chips Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "all",   label: "All",    count: ClipboardService.totalCount },
                            { id: "text",  label: "Text",   count: ClipboardService.textCount },
                            { id: "image", label: "Images", count: ClipboardService.imageCount },
                            { id: "link",  label: "Links",  count: ClipboardService.linkCount },
                            { id: "code",  label: "Code",   count: ClipboardService.codeCount },
                            { id: "color", label: "Colors", count: ClipboardService.colorCount }
                        ]

                        delegate: Rectangle {
                            id: catChip
                            required property var modelData
                            readonly property bool isActive: ClipboardService.activeCategory === modelData.id

                            height: 26
                            implicitWidth: chipRow.implicitWidth + 18
                            radius: 13
                            color: isActive
                                ? root.theme.accentPrimary
                                : (chipMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05))
                            border.color: isActive ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: catChip.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: catChip.isActive
                                    color: catChip.isActive ? root.theme.bgBase : root.theme.textPrimary
                                }

                                Text {
                                    text: String(catChip.modelData.count)
                                    font.family: root.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    opacity: 0.8
                                    color: catChip.isActive ? root.theme.bgBase : root.theme.textMuted
                                }
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ClipboardService.activeCategory = catChip.modelData.id;
                                    root.selectedIndex = 0;
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Main Content Area (Items List)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.15)
                    border.color: root.theme.bgBorder
                    border.width: 1
                    clip: true

                    // Empty state indicator
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: ClipboardService.filteredItems.length === 0

                        Text {
                            text: ClipboardService.loading
                                ? "Reading clipboard history..."
                                : (ClipboardService.searchText !== "" ? "No items matching \"" + ClipboardService.searchText + "\"" : "Clipboard history is empty")
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: ClipboardService.loading ? "Please wait" : "Copied text and images will appear here"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textMuted
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Items List View
                    ListView {
                        id: clipListView
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        clip: true
                        cacheBuffer: 0
                        model: clipboardPanel.visible ? ClipboardService.filteredItems : []
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            id: clipScrollBar
                            width: 5
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 5
                                radius: 2.5
                                color: root.theme.accentPrimary
                                opacity: clipScrollBar.active ? 0.8 : (clipScrollBar.hovered ? 0.6 : 0.3)
                            }
                        }

                        remove: Transition {
                            NumberAnimation { property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
                        }
                        displaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 150; easing.type: Easing.OutCubic }
                        }

                        delegate: ClipboardItemCard {
                            width: clipListView.width - (clipScrollBar.visible ? 10 : 0)
                            theme: root.theme
                            font: root.font
                            isSelected: root.selectedIndex === index
                            panelVisible: clipboardPanel.visible

                            onCardClicked: (idx, item) => {
                                root.selectedIndex = idx;
                                ClipboardService.copyItem(item.id, item.preview);
                                if (ClipboardConfig.closeOnCopy) clipboardPanel.requestClose();
                            }
                            onCopyClicked: item => {
                                ClipboardService.copyItem(item.id, item.preview);
                                if (ClipboardConfig.closeOnCopy) clipboardPanel.requestClose();
                            }
                            onDeleteClicked: item => {
                                ClipboardService.deleteItem(item.id);
                            }
                        }
                    }
                }

                // Footer Status Bar & Shortcut Legend
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: -18
                    Layout.rightMargin: -18
                    Layout.bottomMargin: -18
                    height: 32
                    color: root.theme.bgSurface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 16

                        Row {
                            spacing: 4
                            Text { text: "↵ Enter"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "copy"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            spacing: 4
                            Text { text: "Del"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "delete"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            spacing: 4
                            Text { text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            spacing: 4
                            Text { text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: {
                                if (ClipboardService.filteredItems.length === 0) return "No items";
                                return `Item ${root.selectedIndex + 1} of ${ClipboardService.filteredItems.length}`;
                            }
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textMuted
                        }
                    }
                }
            }
        }
    }
        }
    }
}
