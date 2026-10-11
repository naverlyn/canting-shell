import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../ThemeSwitcher"
import "./Components"

Scope {
    id: root
    property var theme: Theme
    property string font: "Hack Nerd Font"
    
    // UI state: 0: WiFi, 1: Bluetooth, 2: Sound, 3: Notifications, 4: Power, 5: Mouse, 6: Keyboard, 7: Applications, 8: Display, 9: Appearance, 10: Bar Settings, 11: About
    property int currentTab: 0
    property var tabs: ["Wi-Fi", "Bluetooth", "Sound", "Notifications", "Power", "Mouse", "Keyboard", "Applications", "Display", "Appearance", "Bar Settings", "About"]
    property var tabIcons: ["󰖩", "󰂯", "󰕾", "󰂚", "󰐥", "󰍽", "󰌌", "󰵆", "󰍹", "󰏘", "󰮲", ""]

    property var sections: [
        {
            category: "System",
            items: [
                { id: "wifi", name: "Wi-Fi", icon: "󰖩", pageIndex: 0 },
                { id: "bluetooth", name: "Bluetooth", icon: "󰂯", pageIndex: 1 },
                { id: "sound", name: "Sound", icon: "󰕾", pageIndex: 2 },
                { id: "power", name: "Power", icon: "󰐥", pageIndex: 4 }
            ]
        },
        {
            category: "Hardware",
            items: [
                { id: "display", name: "Display", icon: "󰍹", pageIndex: 8 },
                { id: "mouse", name: "Mouse & Touchpad", icon: "󰍽", pageIndex: 5 },
                { id: "keyboard", name: "Keyboard", icon: "󰌌", pageIndex: 6 },
                { id: "apps", name: "Applications", icon: "󰵆", pageIndex: 7 }
            ]
        },
        {
            category: "Quickshell",
            items: [
                { id: "bar", name: "Bar Settings", icon: "󰮲", pageIndex: 10 },
                { id: "appearance", name: "Appearance", icon: "󰏘", pageIndex: 9 },
                { id: "notifications", name: "Notifications", icon: "󰂚", pageIndex: 3 }
            ]
        },
        {
            category: "About",
            items: [
                { id: "about", name: "About", icon: "", pageIndex: 11 }
            ]
        }
    ]

    onCurrentTabChanged: {
        if (root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() {
            settingsWindow.visible = !settingsWindow.visible;
        }
        function open(tabName) {
            if (tabName !== undefined && tabName !== "") {
                let target = String(tabName).toLowerCase().trim();
                for (let s = 0; s < root.sections.length; s++) {
                    for (let i = 0; i < root.sections[s].items.length; i++) {
                        let item = root.sections[s].items[i];
                        if (item.name.toLowerCase().includes(target) || (item.id && item.id.toLowerCase() === target)) {
                            root.currentTab = item.pageIndex;
                            settingsWindow.visible = true;
                            return;
                        }
                    }
                }
            }
            settingsWindow.visible = true;
        }
    }

    PanelWindow {
        id: settingsWindow
        visible: false
        focusable: true
        color: "transparent"

        onVisibleChanged: {
            if (!visible && root.theme) {
                root.theme.previewIndex = -1;
                root.theme.previewAccent = "";
            }
            if (visible) {
                winCard.forceActiveFocus();
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: settingsWindow.visible
            onActivated: settingsWindow.visible = false
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-settings"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Keys.onEscapePressed: (event) => {
            settingsWindow.visible = false;
            event.accepted = true;
        }

        // Overlay backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: settingsWindow.visible = false

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay ?? "#80000000"
            }
        }

        // Floating Draggable & Resizable Window Card
        Rectangle {
            id: winCard
            width: 880
            height: 620
            x: Math.max(10, (settingsWindow.width - width) / 2)
            y: Math.max(10, (settingsWindow.height - height) / 2)
            radius: 14
            color: root.theme.bgBase
            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
            border.width: 1

            focus: true
            Keys.onEscapePressed: (event) => {
                settingsWindow.visible = false;
                event.accepted = true;
            }

            readonly property int minWidth: 720
            readonly property int minHeight: 480

            // Absorb clicks on background
            MouseArea { anchors.fill: parent }

            // Drag Header Area
            MouseArea {
                id: dragHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                cursorShape: Qt.OpenHandCursor
                property point dragStart

                onPressed: (mouse) => {
                    dragStart = Qt.point(mouse.x, mouse.y);
                    cursorShape = Qt.ClosedHandCursor;
                }
                onReleased: cursorShape = Qt.OpenHandCursor
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - dragStart.x;
                        let dy = mouse.y - dragStart.y;
                        winCard.x = Math.max(0, Math.min(settingsWindow.width - winCard.width, winCard.x + dx));
                        winCard.y = Math.max(0, Math.min(settingsWindow.height - winCard.height, winCard.y + dy));
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar
                Rectangle {
                    Layout.fillHeight: true
                    width: 204
                    color: root.theme.bgSurface
                    radius: 12
                    
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 12
                        color: parent.color
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Sidebar Header with Drag Handle indicator
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.bottomMargin: 4

                            Text {
                                text: "Settings"
                                font.family: root.font
                                font.pixelSize: 18
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: "󰓅"
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.textMuted
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Scrollable categorized sections
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: sectionsCol.implicitHeight
                            contentWidth: width
                            flickableDirection: Flickable.VerticalFlick
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    implicitWidth: 4
                                    radius: 2
                                    color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.2)
                                }
                            }

                            ColumnLayout {
                                id: sectionsCol
                                width: parent.width
                                spacing: 4

                                Repeater {
                                    model: root.sections
                                    delegate: ColumnLayout {
                                        id: secCol
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spacing: 2

                                        // Section Category Header
                                        Item {
                                            Layout.fillWidth: true
                                            height: secCol.index === 0 ? 22 : 28

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 4
                                                text: secCol.modelData.category
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.capitalization: Font.AllUppercase
                                                color: root.theme.textMuted ?? Qt.rgba(1,1,1,0.4)
                                            }
                                        }

                                        // Section Items
                                        Repeater {
                                            model: secCol.modelData.items
                                            delegate: Rectangle {
                                                id: itemRect
                                                required property var modelData
                                                required property int index

                                                Layout.fillWidth: true
                                                height: 34
                                                radius: 7
                                                color: root.currentTab === itemRect.modelData.pageIndex
                                                    ? root.theme.bgSelected
                                                    : (tabMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent")

                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    Item {
                                                        width: 18
                                                        height: 18
                                                        Layout.alignment: Qt.AlignVCenter

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: itemRect.modelData.icon
                                                            font.family: root.font
                                                            font.pixelSize: 14
                                                            color: root.currentTab === itemRect.modelData.pageIndex
                                                                ? root.theme.accentPrimary
                                                                : root.theme.textSecondary
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                            Behavior on color { ColorAnimation { duration: 150 } }
                                                        }
                                                    }

                                                    Text {
                                                        text: itemRect.modelData.name
                                                        font.family: root.font
                                                        font.pixelSize: 13
                                                        font.bold: root.currentTab === itemRect.modelData.pageIndex
                                                        color: root.currentTab === itemRect.modelData.pageIndex
                                                            ? root.theme.textPrimary
                                                            : root.theme.textSecondary
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                        elide: Text.ElideRight
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                    }
                                                }

                                                MouseArea {
                                                    id: tabMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.currentTab = itemRect.modelData.pageIndex
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Main Content Area with Close Button & Smooth Tab Animations
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Close Button in Top Right
                    Rectangle {
                        z: 99
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 12
                        width: 26
                        height: 26
                        radius: 13
                        color: closeMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.1)) : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.font
                            font.pixelSize: 12
                            color: closeMouse.containsMouse ? root.theme.accentRed ?? "#f7768e" : root.theme.textMuted

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.visible = false
                        }
                    }

                    // 0: Wi-Fi
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 0 ? 1 : 0
                        scale: root.currentTab === 0 ? 1 : 0.98
                        y: root.currentTab === 0 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        WifiSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 1: Bluetooth
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 1 ? 1 : 0
                        scale: root.currentTab === 1 ? 1 : 0.98
                        y: root.currentTab === 1 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        BluetoothSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 2: Sound
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 2 ? 1 : 0
                        scale: root.currentTab === 2 ? 1 : 0.98
                        y: root.currentTab === 2 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        SoundSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 3: Notifications
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 3 ? 1 : 0
                        scale: root.currentTab === 3 ? 1 : 0.98
                        y: root.currentTab === 3 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        NotificationSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 4: Power
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 4 ? 1 : 0
                        scale: root.currentTab === 4 ? 1 : 0.98
                        y: root.currentTab === 4 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        PowerSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 5: Mouse & Touchpad
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 5 ? 1 : 0
                        scale: root.currentTab === 5 ? 1 : 0.98
                        y: root.currentTab === 5 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        MouseSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 6: Keyboard
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 6 ? 1 : 0
                        scale: root.currentTab === 6 ? 1 : 0.98
                        y: root.currentTab === 6 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        KeyboardSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 7: Default Applications
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 7 ? 1 : 0
                        scale: root.currentTab === 7 ? 1 : 0.98
                        y: root.currentTab === 7 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        DefaultAppsSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 8: Display
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 8 ? 1 : 0
                        scale: root.currentTab === 8 ? 1 : 0.98
                        y: root.currentTab === 8 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        DisplaySettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 9: Appearance
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 9 ? 1 : 0
                        scale: root.currentTab === 9 ? 1 : 0.98
                        y: root.currentTab === 9 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        AppearanceSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 10: Bar Settings
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 10 ? 1 : 0
                        scale: root.currentTab === 10 ? 1 : 0.98
                        y: root.currentTab === 10 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        BarSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }

                    // 11: About
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 36
                        visible: opacity > 0
                        opacity: root.currentTab === 11 ? 1 : 0
                        scale: root.currentTab === 11 ? 1 : 0.98
                        y: root.currentTab === 11 ? 0 : 8

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        AboutSettings { anchors.fill: parent; theme: root.theme; font: root.font }
                    }
                }
            }

            // --- 8-Direction Window Resize Handles ---

            // Right Edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: -4
                width: 8
                cursorShape: Qt.SizeHorCursor
                property real startX
                property real startW
                onPressed: (mouse) => { startX = mouse.x; startW = winCard.width; }
                onPositionChanged: (mouse) => {
                    if (pressed) winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startX));
                }
            }

            // Bottom Edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -4
                height: 8
                cursorShape: Qt.SizeVerCursor
                property real startY
                property real startH
                onPressed: (mouse) => { startY = mouse.y; startH = winCard.height; }
                onPositionChanged: (mouse) => {
                    if (pressed) winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startY));
                }
            }

            // Left Edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: -4
                width: 8
                cursorShape: Qt.SizeHorCursor
                property real startMouseX
                property real startWinX
                property real startW
                onPressed: (mouse) => {
                    startMouseX = mouse.x;
                    startWinX = winCard.x;
                    startW = winCard.width;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouseX;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        winCard.x = startWinX + (startW - nw);
                        winCard.width = nw;
                    }
                }
            }

            // Top Edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -4
                height: 8
                cursorShape: Qt.SizeVerCursor
                property real startMouseY
                property real startWinY
                property real startH
                onPressed: (mouse) => {
                    startMouseY = mouse.y;
                    startWinY = winCard.y;
                    startH = winCard.height;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dy = mouse.y - startMouseY;
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.y = startWinY + (startH - nh);
                        winCard.height = nh;
                    }
                }
            }

            // Bottom-Right Corner
            MouseArea {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeFDiagCursor
                property point startMouse
                property real startW
                property real startH
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startMouse.x));
                        winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startMouse.y));
                    }
                }
            }

            // Top-Right Corner
            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeBDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startY
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startY = winCard.y;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startMouse.x));
                        let dy = mouse.y - startMouse.y;
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.y = startY + (startH - nh);
                        winCard.height = nh;
                    }
                }
            }

            // Bottom-Left Corner
            MouseArea {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeBDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startX
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startX = winCard.x;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouse.x;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        winCard.x = startX + (startW - nw);
                        winCard.width = nw;
                        winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startMouse.y));
                    }
                }
            }

            // Top-Left Corner
            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeFDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startX
                property real startY
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startX = winCard.x;
                    startY = winCard.y;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouse.x;
                        let dy = mouse.y - startMouse.y;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.x = startX + (startW - nw);
                        winCard.y = startY + (startH - nh);
                        winCard.width = nw;
                        winCard.height = nh;
                    }
                }
            }
        }
    }
}
