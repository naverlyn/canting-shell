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
import "./Common"
import "./DefaultApps"

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

    function showStatus(msg) {
        Style.notify(msg, false);
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
                font.pixelSize: Style.px(20)
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            DefaultAppsWebGroup { root: root }

            DefaultAppsMediaGroup { root: root }
        }
    }

}
