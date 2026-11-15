import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var theme
    required property string font
    required property var binds
    required property bool loading

    signal overlayClosed()
    signal refreshRequested()

    property string searchQuery: ""
    property string activeCategory: "All"
    readonly property var categories: ["All", "Apps", "Windows", "Workspaces", "Media", "System"]

    function switchCategory(cat) {
        if (root.activeCategory === cat) return;
        root.activeCategory = cat;
        bindsList.positionViewAtBeginning();
        switchAnim.restart();
    }

    readonly property var filteredBinds: {
        const q = root.searchQuery.trim().toLowerCase();
        const cat = root.activeCategory;
        const list = root.binds || [];
        return list.filter(item => {
            if (cat !== "All" && item.category !== cat) return false;
            if (q === "") return true;
            return item.searchBlob.indexOf(q) !== -1;
        });
    }

    visible: true
    focusable: true
    color: "transparent"

    Component.onCompleted: searchInput.forceActiveFocus()

    onVisibleChanged: {
        if (!visible) root.overlayClosed();
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-keybinds"
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
        onClicked: root.visible = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(780, root.width - 80)
        height: Math.min(580, root.height - 80)
        radius: 16
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true

        // Absorb clicks inside the card
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 10
                    
                    Text {
                        text: "Keybindings"
                        font.family: root.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Rectangle {
                        implicitWidth: countText.implicitWidth + 14
                        height: 22
                        radius: 11
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.filteredBinds.length + " binds"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Refresh button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 8
                        color: refreshHover.hovered ? root.theme.bgHover : "transparent"

                        HoverHandler { id: refreshHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshRequested()
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: root.font
                            font.pixelSize: 16
                            color: refreshHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        }
                    }

                    // Close button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 8
                        color: closeHover.hovered ? root.theme.bgHover : "transparent"

                        HoverHandler { id: closeHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.visible = false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.font
                            font.pixelSize: 16
                            color: closeHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        }
                    }
                }
            }

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                height: 42
                radius: 10
                color: root.theme.bgSurface
                border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "󰍉"
                        font.family: root.font
                        font.pixelSize: 16
                        color: root.theme.accentPrimary
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            color: root.theme.textPrimary
                            font.family: root.font
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true

                            onTextChanged: root.searchQuery = searchInput.text

                            Keys.onEscapePressed: {
                                if (searchInput.text !== "") {
                                    searchInput.text = "";
                                } else {
                                    root.visible = false;
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    const idx = root.categories.indexOf(root.activeCategory);
                                    root.switchCategory(root.categories[(idx + 1) % root.categories.length]);
                                } else if (event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    bindsList.contentY = Math.min(
                                        Math.max(0, bindsList.contentHeight - bindsList.height),
                                        bindsList.contentY + 96
                                    );
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    bindsList.contentY = Math.max(0, bindsList.contentY - 96);
                                }
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search by action, key (e.g. Return, Print), or modifier (SUPER, CTRL)..."
                            color: root.theme.textMuted
                            font.family: root.font
                            font.pixelSize: 13
                            visible: searchInput.text === ""
                        }
                    }

                    Text {
                        visible: searchInput.text !== ""
                        text: "󰅖"
                        font.family: root.font
                        font.pixelSize: 14
                        color: clearHover.hovered ? root.theme.textPrimary : root.theme.textMuted

                        HoverHandler { id: clearHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Category pills
            Row {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 6

                Repeater {
                    model: root.categories
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool isActive: root.activeCategory === modelData

                        implicitWidth: catLabel.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: isActive
                            ? root.theme.accentPrimary
                            : (catHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                        border.color: isActive ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: catHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.switchCategory(modelData)
                        }

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: isActive
                            color: isActive ? root.theme.bgBase : root.theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.theme.bgBorder
            }

            // Binds list
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Item {
                    id: listAnimContainer
                    width: parent.width
                    height: parent.height

                    ParallelAnimation {
                        id: switchAnim
                        NumberAnimation {
                            target: listAnimContainer
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: listAnimContainer
                            property: "y"
                            from: 10
                            to: 0
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    ListView {
                        id: bindsList
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.filteredBinds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: KeybindRow {
                            required property var modelData
                            theme: root.theme
                            font: root.font
                            bindItem: modelData
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.loading && root.filteredBinds.length === 0
                    text: "Loading Hyprland keybindings..."
                    font.family: root.font
                    font.pixelSize: 13
                    color: root.theme.textMuted
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.loading && root.filteredBinds.length === 0
                    text: "No matching keybindings found"
                    font.family: root.font
                    font.pixelSize: 13
                    color: root.theme.textMuted
                }
            }

            // Footer hints
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: root.theme.bgSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Row {
                        spacing: 4
                        Text { text: "Tab"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "category"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Text { text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "scroll"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Text { text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "qs ipc call keybinds toggle"
                        color: root.theme.textMuted
                        font.pixelSize: 10
                        font.family: root.font
                    }
                }
            }
        }
    }
}
