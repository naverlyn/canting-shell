/*
 * ClipboardSettings.qml
 *
 * Comprehensive Clipboard History & Daemon Configuration for Quickshell Settings.
 * Supports:
 *   - Layout & Dimensions (Popup window width & height, live interactive preview)
 *   - History Capacity & Behavior (Max items, close on copy, search clearing, auto-paste)
 *   - Content Detection (Thumbnails, Hex color swatches, URLs, Code syntax recognition)
 *   - Daemon & Service Management (cliphist store watcher status, 1-click start/stop, cache wipe)
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../Clipboard"
import "Common"

Item {
    id: root

    property var theme
    property string font: Style.font

    /* Sub-tabs: 0: Layout & Sizing, 1: History & Behavior, 2: Daemon & Services */
    property int currentSubTab: 0

    /* Daemon status & stats */
    property bool daemonRunning: false
    property int totalStoredItems: 0
    property string dbSizeFormatted: "0 B"
    property int thumbsCount: 0
    property bool statusLoading: false

    /* Feedback toast state */
    property string toastMessage: ""
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: 2500
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg) {
        root.toastMessage = msg;
        root.toastVisible = true;
        toastTimer.restart();
    }

    readonly property string serviceScript: ClipboardConfig.serviceScript

    /* Process runner for status query */
    Process {
        id: statusProc
        command: ["python3", root.serviceScript, "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.statusLoading = false;
                try {
                    const data = JSON.parse(text);
                    if (data.success) {
                        root.daemonRunning = Boolean(data.daemonRunning);
                        root.totalStoredItems = Number(data.totalItems) || 0;
                        root.dbSizeFormatted = data.dbSizeFormatted || "0 B";
                        root.thumbsCount = Number(data.thumbsCount) || 0;
                    }
                } catch(e) {
                    console.error("Failed to parse clip_service status:", e);
                }
            }
        }
    }

    /* Process runner for daemon actions */
    Process {
        id: daemonActionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.queryStatus();
            }
        }
    }

    function queryStatus() {
        if (!statusProc.running) {
            root.statusLoading = true;
            statusProc.running = true;
        }
    }

    function startDaemon() {
        daemonActionProc.command = ["python3", root.serviceScript, "start_daemon"];
        daemonActionProc.running = true;
        root.showToast("Starting clipboard watcher daemon...");
    }

    function stopDaemon() {
        daemonActionProc.command = ["python3", root.serviceScript, "stop_daemon"];
        daemonActionProc.running = true;
        root.showToast("Stopping clipboard watcher daemon...");
    }

    function wipeHistory() {
        ClipboardService.wipeAll();
        root.showToast("All clipboard history wiped");
        root.queryStatus();
    }

    function testCopy() {
        const testStr = "Quickshell Clipboard Test @" + new Date().toLocaleTimeString();
        testCopyProc.command = ["wl-copy", testStr];
        testCopyProc.running = true;
        root.showToast("Copied test snippet to clipboard");
        ClipboardService.refresh();
        root.queryStatus();
    }

    Process {
        id: testCopyProc
        running: false
    }

    Component.onCompleted: {
        root.queryStatus();
    }

    Connections {
        target: ClipboardConfig
        function onHistoryWiped() {
            root.queryStatus();
        }
    }

    /* ---- Main Scrollable Content ---- */
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: flickable.width - (vertScroll.visible ? 12 : 0)
            spacing: 20

            // Header Section
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "Clipboard Manager"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Configure clipboard history capacity, content detection, window dimensions, and daemon status"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }

            /* Sub-Tab Switch Transition Animation (Matching HyprlandSettings) */
            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 8
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            /* Sub-Tab Navigation Bar (Underline indicator matching HyprlandSettings & BarSettings) */
            Rectangle {
                id: subTabTrack
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.04)
                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, icon: "󰍉", label: "Layout & Sizing" },
                            { idx: 1, icon: "󰋚", label: "History & Behavior" },
                            { idx: 2, icon: "󰒲", label: "Daemon & Services" }
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
                                color: subTabItem.isCurrent
                                    ? (root.theme.accentPrimary)
                                    : (root.theme.textSecondary)

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
                                        ? (root.theme.accentPrimary)
                                        : (subTabHover.hovered
                                            ? (root.theme.textPrimary)
                                            : (root.theme.textSecondary))
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? (root.theme.accentPrimary)
                                        : (subTabHover.hovered
                                            ? (root.theme.textPrimary)
                                            : (root.theme.textSecondary))
                                    Behavior on color { ColorAnimation { duration: 150 } }
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

            /* Sub-Tab Dynamic Animated Container */
            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 16
                transform: Translate { id: subTabContentTranslate; y: 0 }

            // =====================================================================
            // SUB-TAB 0: LAYOUT & SIZING
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: root.currentSubTab === 0

                // Live Proportions Preview Canvas
                Rectangle {
                    Layout.fillWidth: true
                    height: 200
                    radius: 8
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    // Dimensions info pill top right
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        implicitWidth: dimLabel.implicitWidth + 12
                        height: 22
                        radius: 5
                        color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)
                        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        z: 10

                        Text {
                            id: dimLabel
                            anchors.centerIn: parent
                            text: ClipboardConfig.windowWidth + " × " + ClipboardConfig.windowHeight + " px"
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: 11
                            color: root.theme.accentPrimary
                        }
                    }

                    // Scaled Mockup Container
                    Rectangle {
                        id: mockWin
                        anchors.centerIn: parent
                        readonly property real scaleFactor: 0.22
                        width: Math.round(ClipboardConfig.windowWidth * scaleFactor)
                        height: Math.round(ClipboardConfig.windowHeight * scaleFactor)
                        radius: 8
                        color: root.theme.bgSurface
                        border.color: root.theme.accentPrimary
                        border.width: 1.5

                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // Mock Search Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 16
                                radius: 4
                                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    spacing: 4

                                    Text {
                                        text: "󰍉"
                                        font.family: root.font
                                        font.pixelSize: 8
                                        color: root.theme.textMuted
                                    }

                                    Text {
                                        text: "search clipboard..."
                                        font.family: root.font
                                        font.pixelSize: 8
                                        color: root.theme.textMuted
                                    }
                                }
                            }

                            // Mock Category Filter Chips
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: 4
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 10
                                        radius: 3
                                        color: index === 0
                                            ? (root.theme.accentPrimary)
                                            : ((root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(1, 1, 1, 0.08))
                                        opacity: index === 0 ? 0.9 : 0.5
                                    }
                                }
                            }

                            // Mock Item Rows
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4

                                Repeater {
                                    model: Math.min(4, Math.floor((mockWin.height - 50) / 18))
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 14
                                        radius: 3
                                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                                        border.color: index === 0
                                            ? (root.theme.accentPrimary)
                                            : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.05))
                                        border.width: index === 0 ? 1 : 0.5

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 4

                                            Rectangle {
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: index === 0 ? root.theme.accentPrimary : (index === 1 ? root.theme.accentGreen : root.theme.accentOrange)
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 4
                                                radius: 2
                                                color: root.theme.textSecondary
                                                opacity: 0.6
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Window Dimensions Section
                SectionCard {
                    title: "Clipboard Window Dimensions (Center Popup)"
                    subtitle: "Adjust the popup box size when opened via Super+V or global menu"
                    contentMargins: 8
                    contentSpacing: 0

                    SettingSliderRow {
                        title: "Popup Width"
                        desc: "Width of the center clipboard history popup window"
                        value: ClipboardConfig.windowWidth
                        minVal: 640
                        maxVal: 960
                        step: 20
                        unit: "px"
                        presets: [
                            { label: "680px", val: 680 },
                            { label: "840px (Default)", val: 840 },
                            { label: "960px", val: 960 }
                        ]
                        onValueModified: (val) => ClipboardConfig.setWindowWidth(val)
                    }

                    RowDivider {}

                    SettingSliderRow {
                        title: "Popup Height"
                        desc: "Vertical height of the clipboard history window"
                        value: ClipboardConfig.windowHeight
                        minVal: 480
                        maxVal: 760
                        step: 20
                        unit: "px"
                        presets: [
                            { label: "520px", val: 520 },
                            { label: "640px (Default)", val: 640 },
                            { label: "740px", val: 740 }
                        ]
                        onValueModified: (val) => ClipboardConfig.setWindowHeight(val)
                    }

                    RowDivider {}

                    // Default Category Segmented Row
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
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "Default Opening Category"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: "Initial filter tab active when clipboard window opens"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                }
                            }

                            Rectangle {
                                id: catSegmentTrack
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                implicitWidth: 320
                                height: 32
                                radius: 7
                                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                readonly property var catIds: ["all", "text", "image", "link", "code", "color"]
                                readonly property int activeIdx: Math.max(0, catIds.indexOf(ClipboardConfig.defaultCategory))
                                readonly property real cellWidth: (width - 6 - 5 * 3) / 6

                                Rectangle {
                                    y: 3
                                    height: parent.height - 6
                                    width: catSegmentTrack.cellWidth
                                    x: 3 + catSegmentTrack.activeIdx * (catSegmentTrack.cellWidth + 3)
                                    radius: 5
                                    color: (root.theme && root.theme.bgSelected) ? root.theme.bgSelected : Qt.rgba(1, 1, 1, 0.15)
                                    border.color: root.theme.accentPrimary
                                    border.width: 1
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: [
                                            { id: "all",   label: "All" },
                                            { id: "text",  label: "Text" },
                                            { id: "image", label: "Images" },
                                            { id: "link",  label: "Links" },
                                            { id: "code",  label: "Code" },
                                            { id: "color", label: "Colors" }
                                        ]
                                        delegate: Rectangle {
                                            id: catBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: catSegmentTrack.activeIdx === index

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && catHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                                            HoverHandler { id: catHover }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ClipboardConfig.setDefaultCategory(catBtn.modelData.id)
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: catBtn.modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: catBtn.isSel
                                                color: catBtn.isSel
                                                    ? (root.theme.accentPrimary)
                                                    : (root.theme.textPrimary)
                                                opacity: catBtn.isSel || catHover.hovered ? 1.0 : 0.75
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // SUB-TAB 1: HISTORY & BEHAVIOR
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: root.currentSubTab === 1

                // History Capacity Card
                SectionCard {
                    title: "History Capacity & Retention"
                    subtitle: "Control how many clipboard items are stored in memory and displayed"
                    contentMargins: 8
                    contentSpacing: 0

                    SettingSliderRow {
                        title: "Max History Items"
                        desc: "Maximum number of past clips loaded into the Quickshell clipboard UI"
                        value: ClipboardConfig.maxItems
                        minVal: 25
                        maxVal: 500
                        step: 25
                        unit: " items"
                        presets: [
                            { label: "50", val: 50 },
                            { label: "100 (Default)", val: 100 },
                            { label: "250", val: 250 },
                            { label: "500", val: 500 }
                        ]
                        onValueModified: (val) => ClipboardConfig.setMaxItems(val)
                    }
                }

                // Window & Selection Behavior Card
                SectionCard {
                    title: "Window & Copying Behavior"
                    subtitle: "Preferences for modal dismissal and search state retention"
                    contentMargins: 8
                    contentSpacing: 0

                    SettingToggleRow {
                        title: "Close Popup on Copy"
                        desc: "Automatically close the clipboard window when an item is copied"
                        checked: ClipboardConfig.closeOnCopy
                        onToggled: (val) => ClipboardConfig.setCloseOnCopy(val)
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Clear Search Query on Close"
                        desc: "Reset the search bar and filter text whenever the clipboard modal is dismissed"
                        checked: ClipboardConfig.clearSearchOnClose
                        onToggled: (val) => ClipboardConfig.setClearSearchOnClose(val)
                    }
                }

                // Content Recognition & Badges Card
                SectionCard {
                    title: "Content Detection & Visual Thumbnails"
                    subtitle: "Automatic categorization for media, code, web links, and hex color values"
                    contentMargins: 8
                    contentSpacing: 0

                    SettingToggleRow {
                        title: "Generate Image Preview Thumbnails"
                        desc: "Decode clipboard binary PNG/JPEG images into instant visual preview thumbnails"
                        checked: ClipboardConfig.generateThumbnails
                        onToggled: (val) => ClipboardConfig.setGenerateThumbnails(val)
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Detect Hex Color Codes"
                        desc: "Recognize color strings (e.g. #7aa2f7) and display live color swatch badges"
                        checked: ClipboardConfig.detectColors
                        onToggled: (val) => ClipboardConfig.setDetectColors(val)
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Detect Web Links & URLs"
                        desc: "Identify http/https URLs and show globe link indicators with open actions"
                        checked: ClipboardConfig.detectLinks
                        onToggled: (val) => ClipboardConfig.setDetectLinks(val)
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Detect Code Snippets"
                        desc: "Inspect snippet contents for syntax keywords (functions, imports, classes)"
                        checked: ClipboardConfig.detectCode
                        onToggled: (val) => ClipboardConfig.setDetectCode(val)
                    }
                }

                // Cache & Danger Actions Card
                SectionCard {
                    title: "Actions & Cache Management"
                    subtitle: "Wipe recorded clipboard items or restore default preferences"
                    contentMargins: 8
                    contentSpacing: 0

                    Item {
                        Layout.fillWidth: true
                        height: 52

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: wipeBtn.left
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: "Wipe Clipboard History"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.accentRed
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "Permanently delete all stored clips in ~/.cache/cliphist/db and thumbnail cache"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        ActionButton {
                            id: wipeBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            label: "Wipe History"
                            danger: true
                            btnHeight: 30
                            onClicked: root.wipeHistory()
                        }
                    }

                    RowDivider {}

                    Item {
                        Layout.fillWidth: true
                        height: 52

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: resetDefaultsBtn.left
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: "Reset All Clipboard Settings"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "Revert dimensions, category filters, and detection toggles to default values"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        ActionButton {
                            id: resetDefaultsBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            label: "Reset Defaults"
                            btnHeight: 30
                            onClicked: {
                                ClipboardConfig.resetDefaults();
                                root.showToast("Clipboard preferences reset to defaults");
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // SUB-TAB 2: DAEMON & SERVICES
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: root.currentSubTab === 2

                // Daemon Status Card
                SectionCard {
                    title: "Clipboard Watcher Daemon (cliphist store)"
                    subtitle: "Real-time background listener capturing selection updates via wl-paste"
                    contentMargins: 8
                    contentSpacing: 0

                    Item {
                        Layout.fillWidth: true
                        height: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: root.daemonRunning ? "Watcher Daemon is Active" : "Watcher Daemon is Stopped"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Rectangle {
                                        implicitWidth: dStatusTxt.implicitWidth + 8
                                        implicitHeight: 18
                                        radius: 4
                                        color: root.daemonRunning
                                            ? Qt.rgba(0.2, 0.8, 0.4, 0.15)
                                            : Qt.rgba(0.9, 0.3, 0.3, 0.15)

                                        Text {
                                            id: dStatusTxt
                                            anchors.centerIn: parent
                                            text: root.daemonRunning ? "RUNNING" : "INACTIVE"
                                            font.family: "JetBrains Mono, monospace"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: root.daemonRunning
                                                ? (root.theme.accentGreen)
                                                : (root.theme.accentRed)
                                        }
                                    }
                                }

                                Text {
                                    text: "wl-paste --watch cliphist store tracks clipboard changes in real time"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Action Buttons (Right-aligned matching stats row)
                            RowLayout {
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                ActionButton {
                                    label: root.daemonRunning ? "Stop Daemon" : "Start Daemon"
                                    iconText: root.daemonRunning ? "󰓛" : "󰐊"
                                    danger: root.daemonRunning
                                    btnHeight: 30
                                    onClicked: {
                                        if (root.daemonRunning) {
                                            root.stopDaemon();
                                        } else {
                                            root.startDaemon();
                                        }
                                    }
                                }

                                ActionButton {
                                    label: "Refresh"
                                    iconText: "󰑐"
                                    btnHeight: 30
                                    onClicked: root.queryStatus()
                                }
                            }
                        }
                    }

                    RowDivider {}

                    // Database Stats Row
                    Item {
                        Layout.fillWidth: true
                        height: 52

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 20

                            // Stat 1: Total Stored Items
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰅌"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: root.theme.accentPrimary
                                }
                                Text {
                                    text: "Total Clips:"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                }
                                Text {
                                    text: String(root.totalStoredItems)
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }
                            }

                            // Stat 2: DB File Size
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰋊"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: root.theme.accentCyan
                                }
                                Text {
                                    text: "Database Size:"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                }
                                Text {
                                    text: root.dbSizeFormatted
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }
                            }

                            // Stat 3: Cached Thumbnails
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰋩"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: root.theme.accentGreen
                                }
                                Text {
                                    text: "Cached Thumbs:"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                }
                                Text {
                                    text: String(root.thumbsCount)
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Test Copy button
                            ActionButton {
                                label: "Test Copy Snippet"
                                iconText: "󰅍"
                                btnHeight: 30
                                onClicked: root.testCopy()
                            }
                        }
                    }
                }

                // System & Shortcut Integration Card
                SectionCard {
                    title: "System & Shortcut Integration"
                    subtitle: "Default global bindings and command line interaction points"
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
                                Layout.fillWidth: true
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "Global Keybind (Hyprland)"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: "Toggles the Quickshell clipboard window overlay"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                implicitWidth: keyTxt.implicitWidth + 16
                                height: 26
                                radius: 6
                                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                Text {
                                    id: keyTxt
                                    anchors.centerIn: parent
                                    text: "SUPER + V"
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.accentPrimary
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
                                Layout.fillWidth: true
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "CLI Toggle Command"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: "Programmatic IPC call to toggle the clipboard UI"
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
                                    implicitWidth: cliTxt.implicitWidth + 16
                                    height: 26
                                    radius: 6
                                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
                                    border.width: 1

                                    Text {
                                        id: cliTxt
                                        anchors.centerIn: parent
                                        text: "qs ipc call clipboard toggle"
                                        font.family: "JetBrains Mono, monospace"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.accentCyan
                                    }
                                }

                                ActionButton {
                                    label: "Copy"
                                    iconText: "󰅍"
                                    btnHeight: 26
                                    onClicked: {
                                        testCopyProc.command = ["wl-copy", "qs ipc call clipboard toggle"];
                                        testCopyProc.running = true;
                                        root.showToast("Copied CLI command to clipboard");
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

    // =========================================================================
    // FLOATING TOAST
    // =========================================================================
    Rectangle {
        id: toastPill
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: toastText.implicitWidth + 32
        height: 36
        radius: 18
        color: root.theme.bgSurface
        border.color: root.theme.accentPrimary
        border.width: 1
        opacity: root.toastVisible ? 1.0 : 0.0
        scale: root.toastVisible ? 1.0 : 0.95
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
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

