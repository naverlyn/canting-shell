/*
 * DefaultAppsSettings.qml
 *
 * Grouped preferences for managing system default applications (Browser, Terminal, Editor, Video, Audio).
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwExpanderRow, AdwComboRow).
 *
 * Features:
 *   - Grouped Web & Productivity and Media preferences with clean dividers
 *   - Reusable inline expandable application selectors with smooth cubic animations
 *   - Inset sub-container styling for option lists matching GNOME nested rows
 *   - Clean text-only options with active bold text, accent highlight, and checkmark
 *   - Mutual exclusion across expanders (opening one closes others)
 *   - Automatic startup discovery of current system defaults via xdg-settings / xdg-mime
 *   - Non-intrusive feedback toast on preference changes
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    property var theme
    property string font: "Lato Nerd Font"

    /* Current active defaults tracked live */
    property string currentBrowser: "brave-browser.desktop"
    property string currentTerminal: "kitty.desktop"
    property string currentEditor: "codium.desktop"
    property string currentVideo: "mpv.desktop"
    property string currentAudio: "mpv.desktop"

    /* Dropdown expansion states */
    property bool browserDropdownOpen: false
    property bool terminalDropdownOpen: false
    property bool editorDropdownOpen: false
    property bool videoDropdownOpen: false
    property bool audioDropdownOpen: false

    /* Mutual exclusion: close other expanders when one opens */
    function closeOtherDropdowns(active) {
        if (active !== "browser") root.browserDropdownOpen = false;
        if (active !== "terminal") root.terminalDropdownOpen = false;
        if (active !== "editor") root.editorDropdownOpen = false;
        if (active !== "video") root.videoDropdownOpen = false;
        if (active !== "audio") root.audioDropdownOpen = false;
    }

    function closeAllDropdowns() {
        root.browserDropdownOpen = false;
        root.terminalDropdownOpen = false;
        root.editorDropdownOpen = false;
        root.videoDropdownOpen = false;
        root.audioDropdownOpen = false;
    }

    onVisibleChanged: {
        if (!visible) closeAllDropdowns();
    }

    /* Feedback toast notification state */
    property string statusMessage: ""
    property bool statusVisible: false

    Timer {
        id: statusTimer
        interval: 2600
        repeat: false
        onTriggered: root.statusVisible = false
    }

    function showStatus(msg) {
        root.statusMessage = msg;
        root.statusVisible = true;
        statusTimer.restart();
    }

    /* Helper to get display name from options list */
    function getDisplayName(options, desktopFile) {
        if (!desktopFile) return "Select application...";
        const found = options.find(o => o.desktop.toLowerCase() === desktopFile.toLowerCase());
        return found ? found.name : desktopFile;
    }

    /* Available options discovered / configured for the system */
    readonly property var browserOptions: [
        { name: "Brave Browser", desktop: "brave-browser.desktop" },
        { name: "Firefox", desktop: "firefox.desktop" },
        { name: "Chromium", desktop: "chromium.desktop" },
        { name: "Google Chrome", desktop: "google-chrome.desktop" }
    ]

    readonly property var terminalOptions: [
        { name: "Kitty", desktop: "kitty.desktop" },
        { name: "Alacritty", desktop: "Alacritty.desktop" },
        { name: "Foot", desktop: "foot.desktop" },
        { name: "Ghostty", desktop: "ghostty.desktop" }
    ]

    readonly property var editorOptions: [
        { name: "VSCodium", desktop: "codium.desktop" },
        { name: "VS Code", desktop: "code.desktop" },
        { name: "Neovim", desktop: "nvim.desktop" },
        { name: "Text Editor", desktop: "org.gnome.TextEditor.desktop" }
    ]

    readonly property var videoOptions: [
        { name: "MPV Media Player", desktop: "mpv.desktop" },
        { name: "VLC Media Player", desktop: "vlc.desktop" }
    ]

    readonly property var audioOptions: [
        { name: "MPV Media Player", desktop: "mpv.desktop" },
        { name: "VLC Media Player", desktop: "vlc.desktop" },
        { name: "Audacious", desktop: "audacious.desktop" }
    ]

    /* Process runner for applying changes via standard FreeDesktop tools */
    Process {
        id: applyProc
        running: false
    }

    function setBrowser(desktopFile, optionData) {
        root.currentBrowser = desktopFile;
        applyProc.command = ["xdg-settings", "set", "default-web-browser", desktopFile];
        applyProc.running = true;
        root.showStatus("Web browser set to " + (optionData ? optionData.name : desktopFile));
    }

    function setTerminal(desktopFile, optionData) {
        root.currentTerminal = desktopFile;
        root.showStatus("Terminal set to " + (optionData ? optionData.name : desktopFile));
    }

    function setEditor(desktopFile, optionData) {
        root.currentEditor = desktopFile;
        applyProc.command = ["xdg-mime", "default", desktopFile, "text/plain"];
        applyProc.running = true;
        root.showStatus("Text editor set to " + (optionData ? optionData.name : desktopFile));
    }

    function setVideo(desktopFile, optionData) {
        root.currentVideo = desktopFile;
        applyProc.command = ["xdg-mime", "default", desktopFile, "video/mp4", "video/x-matroska", "video/webm"];
        applyProc.running = true;
        root.showStatus("Video player set to " + (optionData ? optionData.name : desktopFile));
    }

    function setAudio(desktopFile, optionData) {
        root.currentAudio = desktopFile;
        applyProc.command = ["xdg-mime", "default", desktopFile, "audio/mpeg", "audio/x-wav", "audio/flac"];
        applyProc.running = true;
        root.showStatus("Audio player set to " + (optionData ? optionData.name : desktopFile));
    }

    /* Startup discovery queries */
    Process {
        id: queryBrowserProc
        command: ["xdg-settings", "get", "default-web-browser"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val) root.currentBrowser = val;
            }
        }
    }

    Process {
        id: queryEditorProc
        command: ["xdg-mime", "query", "default", "text/plain"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val) root.currentEditor = val;
            }
        }
    }

    Process {
        id: queryVideoProc
        command: ["xdg-mime", "query", "default", "video/mp4"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val) root.currentVideo = val;
            }
        }
    }

    Process {
        id: queryAudioProc
        command: ["xdg-mime", "query", "default", "audio/mpeg"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val) root.currentAudio = val;
            }
        }
    }

    /* Reusable application expander row */
    component SettingExpanderRow: ColumnLayout {
        id: expanderRow
        property string title: ""
        property string currentValue: ""
        property var options: []
        property bool isOpen: false
        signal toggleRequested()
        signal optionSelected(string desktopFile, var optionData)

        Layout.fillWidth: true
        spacing: 0

        // Row header
        Item {
            Layout.fillWidth: true
            height: 50

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: expanderRow.title
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Dropdown selector pill
                Rectangle {
                    width: 240
                    height: 32
                    radius: 6
                    color: expanderRow.isOpen 
                        ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                        : (pillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04)))
                    border.color: expanderRow.isOpen 
                        ? root.theme.accentPrimary 
                        : (pillHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)))
                    border.width: expanderRow.isOpen ? 1.5 : 1
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: pillHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: root.getDisplayName(expanderRow.options, expanderRow.currentValue)
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "󰅀"
                            font.family: root.font
                            font.pixelSize: 12
                            color: expanderRow.isOpen ? root.theme.accentPrimary : root.theme.textSecondary
                            rotation: expanderRow.isOpen ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: expanderRow.toggleRequested()
                    }
                }
            }
        }

        // Expandable options sub-list
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: expanderRow.isOpen ? 8 : 0
            Layout.preferredHeight: expanderRow.isOpen ? (optListCol.implicitHeight + 8) : 0
            opacity: expanderRow.isOpen ? 1.0 : 0.0
            clip: true
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.18)
            border.color: expanderRow.isOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
            border.width: 1

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
            Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

            ColumnLayout {
                id: optListCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 4
                }
                spacing: 2

                Repeater {
                    model: expanderRow.options
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 6
                        readonly property bool isSelected: expanderRow.currentValue.toLowerCase() === modelData.desktop.toLowerCase()
                        color: isSelected 
                            ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                            : (itemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                        border.color: isSelected 
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3) 
                            : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }

                        HoverHandler { id: itemHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: modelData.name
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: isSelected
                                color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: isSelected
                                text: "󰄬"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: expanderRow.optionSelected(modelData.desktop, modelData)
                        }
                    }
                }
            }
        }
    }

    /* Main scrollable view */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Default Applications"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* Web & Productivity */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Web & Productivity"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: webCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: webCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Web Browser
                        SettingExpanderRow {
                            title: "Web Browser"
                            currentValue: root.currentBrowser
                            options: root.browserOptions
                            isOpen: root.browserDropdownOpen
                            onToggleRequested: {
                                if (!root.browserDropdownOpen) root.closeOtherDropdowns("browser");
                                root.browserDropdownOpen = !root.browserDropdownOpen;
                            }
                            onOptionSelected: (desktopFile, optionData) => {
                                root.setBrowser(desktopFile, optionData);
                                root.browserDropdownOpen = false;
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Terminal
                        SettingExpanderRow {
                            title: "Terminal"
                            currentValue: root.currentTerminal
                            options: root.terminalOptions
                            isOpen: root.terminalDropdownOpen
                            onToggleRequested: {
                                if (!root.terminalDropdownOpen) root.closeOtherDropdowns("terminal");
                                root.terminalDropdownOpen = !root.terminalDropdownOpen;
                            }
                            onOptionSelected: (desktopFile, optionData) => {
                                root.setTerminal(desktopFile, optionData);
                                root.terminalDropdownOpen = false;
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Text Editor
                        SettingExpanderRow {
                            title: "Text Editor"
                            currentValue: root.currentEditor
                            options: root.editorOptions
                            isOpen: root.editorDropdownOpen
                            onToggleRequested: {
                                if (!root.editorDropdownOpen) root.closeOtherDropdowns("editor");
                                root.editorDropdownOpen = !root.editorDropdownOpen;
                            }
                            onOptionSelected: (desktopFile, optionData) => {
                                root.setEditor(desktopFile, optionData);
                                root.editorDropdownOpen = false;
                            }
                        }
                    }
                }
            }

            /* Media */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Media"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: mediaCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: mediaCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Video Player
                        SettingExpanderRow {
                            title: "Video Player"
                            currentValue: root.currentVideo
                            options: root.videoOptions
                            isOpen: root.videoDropdownOpen
                            onToggleRequested: {
                                if (!root.videoDropdownOpen) root.closeOtherDropdowns("video");
                                root.videoDropdownOpen = !root.videoDropdownOpen;
                            }
                            onOptionSelected: (desktopFile, optionData) => {
                                root.setVideo(desktopFile, optionData);
                                root.videoDropdownOpen = false;
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Audio Player
                        SettingExpanderRow {
                            title: "Audio Player"
                            currentValue: root.currentAudio
                            options: root.audioOptions
                            isOpen: root.audioDropdownOpen
                            onToggleRequested: {
                                if (!root.audioDropdownOpen) root.closeOtherDropdowns("audio");
                                root.audioDropdownOpen = !root.audioDropdownOpen;
                            }
                            onOptionSelected: (desktopFile, optionData) => {
                                root.setAudio(desktopFile, optionData);
                                root.audioDropdownOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }

    /* Feedback toast notification */
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        implicitWidth: toastText.implicitWidth + 24
        height: 34
        radius: 17
        color: root.theme.bgSelected ?? "#283457"
        border.color: root.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1
        opacity: root.statusVisible ? 1.0 : 0.0
        scale: root.statusVisible ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            id: toastText
            anchors.centerIn: parent
            text: root.statusMessage
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary ?? "#c0caf5"
        }
    }
}
