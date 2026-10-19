import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    property int selectedIndex: 0
    property bool confirmWipe: false

    IpcHandler {
        target: "clipboard"

        function toggle() {
            clipboardPanel.visible = !clipboardPanel.visible;
            if (clipboardPanel.visible) {
                ClipboardService.searchText = "";
                ClipboardService.activeCategory = "all";
                ClipboardService.refresh();
                root.selectedIndex = 0;
                root.confirmWipe = false;
                searchInput.forceActiveFocus();
            }
        }

        function open() {
            clipboardPanel.visible = true;
            ClipboardService.searchText = "";
            ClipboardService.activeCategory = "all";
            ClipboardService.refresh();
            root.selectedIndex = 0;
            root.confirmWipe = false;
            searchInput.forceActiveFocus();
        }

        function close() {
            clipboardPanel.visible = false;
        }
    }

    PanelWindow {
        id: clipboardPanel
        visible: false
        focusable: true
        color: "transparent"

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

        // Dark overlay backdrop
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            onClicked: clipboardPanel.visible = false

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay ?? Qt.rgba(0, 0, 0, 0.65)
            }
        }

        // Main modal dialog container
        Rectangle {
            id: mainCard
            anchors.centerIn: parent
            width: Math.min(840, parent.width - 40)
            height: Math.min(640, parent.height - 40)
            radius: 16
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

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
                            onClicked: clipboardPanel.visible = false
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
                                    clipboardPanel.visible = false;
                                }
                            }
                            Keys.onEnterPressed: {
                                if (ClipboardService.filteredItems.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < ClipboardService.filteredItems.length) {
                                    const it = ClipboardService.filteredItems[root.selectedIndex];
                                    ClipboardService.copyItem(it.id, it.preview);
                                    clipboardPanel.visible = false;
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
                                    clipboardPanel.visible = false;
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
                        model: ClipboardService.filteredItems
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

                        delegate: Rectangle {
                            id: itemCard
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: root.selectedIndex === itemCard.index
                            readonly property string category: modelData.category || "text"
                            readonly property bool isImage: modelData.isBinary || category === "image"
                            readonly property bool isColor: category === "color"
                            readonly property bool isHovered: cardMouse.containsMouse || copyBtnMouse.containsMouse || delBtnMouse.containsMouse

                            width: clipListView.width - (clipScrollBar.visible ? 10 : 0)
                            height: isImage ? 76 : (isColor ? 54 : (previewTextItem.lineCount > 1 ? 64 : 52))
                            radius: 8

                            color: isSelected
                                ? (root.theme.bgSelected ?? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18))
                                : (itemCard.isHovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : root.theme.bgSurface)
                            border.color: isSelected ? root.theme.accentPrimary : (itemCard.isHovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.45) : root.theme.bgBorder)
                            border.width: isSelected ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Left Visual: Image Thumbnail / Color Circle (only when present)
                                Item {
                                    visible: itemCard.isImage || itemCard.isColor
                                    width: itemCard.isImage ? 64 : 28
                                    height: itemCard.isImage ? 56 : 28
                                    Layout.alignment: Qt.AlignVCenter

                                    // Image Thumbnail
                                    Rectangle {
                                        visible: itemCard.isImage
                                        anchors.fill: parent
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.25)
                                        border.color: root.theme.bgBorder
                                        border.width: 1
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: itemCard.modelData.thumbPath ? ("file://" + itemCard.modelData.thumbPath) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            smooth: true
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "IMAGE"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.theme.textMuted
                                            visible: !itemCard.modelData.thumbPath
                                        }
                                    }

                                    // Color Circle Swatch
                                    Rectangle {
                                        visible: itemCard.isColor
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: itemCard.modelData.preview.trim()
                                        border.color: "#ffffff"
                                        border.width: 1.5
                                    }
                                }

                                // Center Content Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Layout.alignment: Qt.AlignVCenter

                                    // Top row: Category tag & Image Meta
                                    RowLayout {
                                        spacing: 6
                                        visible: itemCard.isImage || itemCard.category === "link" || itemCard.category === "code" || itemCard.isColor

                                        Text {
                                            text: {
                                                if (itemCard.isImage) return itemCard.modelData.imgMeta || "IMAGE";
                                                if (itemCard.isColor) return "COLOR SWATCH";
                                                if (itemCard.category === "link") return "LINK / URL";
                                                if (itemCard.category === "code") return "CODE SNIPPET";
                                                return "";
                                            }
                                            font.family: root.font
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: {
                                                if (itemCard.category === "link") return root.theme.accentCyan;
                                                if (itemCard.category === "code") return root.theme.accentPrimary;
                                                return root.theme.textMuted;
                                            }
                                        }
                                    }

                                    // Preview Text
                                    Text {
                                        id: previewTextItem
                                        Layout.fillWidth: true
                                        text: itemCard.isImage ? (itemCard.modelData.imgMeta || "Image from clipboard") : itemCard.modelData.preview
                                        font.family: (itemCard.category === "code" || itemCard.isColor) ? "monospace" : root.font
                                        font.pixelSize: itemCard.category === "code" ? 11 : 12
                                        font.bold: itemCard.isSelected
                                        color: itemCard.category === "link"
                                            ? root.theme.accentCyan
                                            : (itemCard.isSelected ? root.theme.textPrimary : root.theme.textSecondary)
                                        elide: Text.ElideRight
                                        maximumLineCount: itemCard.isImage ? 1 : 2
                                        wrapMode: Text.WrapAnywhere
                                    }
                                }

                                // Right Action Buttons (visible on hover or when selected)
                                RowLayout {
                                    spacing: 6
                                    opacity: (itemCard.isHovered || itemCard.isSelected) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                    Layout.alignment: Qt.AlignVCenter

                                    // Copy Button
                                    Rectangle {
                                        implicitWidth: copyBtnLabel.implicitWidth + 16
                                        height: 26
                                        radius: 5
                                        color: copyBtnMouse.containsMouse ? root.theme.accentPrimary : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.22)
                                        border.color: root.theme.accentPrimary
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                        Text {
                                            id: copyBtnLabel
                                            anchors.centerIn: parent
                                            text: "Copy"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: copyBtnMouse.containsMouse ? root.theme.bgBase : root.theme.accentPrimary
                                        }

                                        MouseArea {
                                            id: copyBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ClipboardService.copyItem(itemCard.modelData.id, itemCard.modelData.preview);
                                                clipboardPanel.visible = false;
                                            }
                                        }
                                    }

                                    // Delete Button
                                    Rectangle {
                                        implicitWidth: delBtnLabel.implicitWidth + 14
                                        height: 26
                                        radius: 5
                                        color: delBtnMouse.containsMouse ? (root.theme.accentRed ?? "#e05252") : Qt.rgba(1, 1, 1, 0.08)
                                        border.color: delBtnMouse.containsMouse ? root.theme.accentRed : root.theme.bgBorder
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                        Text {
                                            id: delBtnLabel
                                            anchors.centerIn: parent
                                            text: "Delete"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: delBtnMouse.containsMouse ? "#ffffff" : root.theme.textMuted
                                        }

                                        MouseArea {
                                            id: delBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ClipboardService.deleteItem(itemCard.modelData.id);
                                            }
                                        }
                                    }
                                }
                            }

                            // Click card to copy & close
                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                anchors.rightMargin: 130
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = itemCard.index;
                                    ClipboardService.copyItem(itemCard.modelData.id, itemCard.modelData.preview);
                                    clipboardPanel.visible = false;
                                }
                            }
                        }
                    }
                }

                // Footer Status Bar & Shortcut Legend
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: {
                            if (ClipboardService.filteredItems.length === 0) return "No items";
                            return `Item ${root.selectedIndex + 1} of ${ClipboardService.filteredItems.length}`;
                        }
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    // Shortcut Legend Pills
                    RowLayout {
                        spacing: 8

                        // Enter Copy
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                height: 18
                                implicitWidth: k1.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: root.theme.bgBorder
                                border.width: 1
                                Text { id: k1; anchors.centerIn: parent; text: "↵ Enter"; font.family: root.font; font.pixelSize: 9; color: root.theme.textSecondary; }
                            }
                            Text { text: "Copy"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted; }
                        }

                        // Del Delete
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                height: 18
                                implicitWidth: k2.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: root.theme.bgBorder
                                border.width: 1
                                Text { id: k2; anchors.centerIn: parent; text: "Del"; font.family: root.font; font.pixelSize: 9; color: root.theme.textSecondary; }
                            }
                            Text { text: "Delete"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted; }
                        }

                        // Esc Close
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                height: 18
                                implicitWidth: k3.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: root.theme.bgBorder
                                border.width: 1
                                Text { id: k3; anchors.centerIn: parent; text: "Esc"; font.family: root.font; font.pixelSize: 9; color: root.theme.textSecondary; }
                            }
                            Text { text: "Close"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted; }
                        }

                        // Up Down Navigate
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                height: 18
                                implicitWidth: k4.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: root.theme.bgBorder
                                border.width: 1
                                Text { id: k4; anchors.centerIn: parent; text: "↑ ↓"; font.family: root.font; font.pixelSize: 9; color: root.theme.textSecondary; }
                            }
                            Text { text: "Navigate"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted; }
                        }
                    }
                }
            }
        }
    }
}
