/*
 * DefaultAppsSettings.qml
 *
 * Manages default applications (Browser, Terminal, Editor, Video, Audio)
 * using standard FreeDesktop specifications (xdg-settings and xdg-mime).
 *
 * Useful troubleshooting commands:
 *   xdg-settings get default-web-browser
 *   xdg-mime query default text/plain
 *   xdg-mime query default video/mp4
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
    property string font

    /* Current active defaults */
    property string currentBrowser: "brave-browser.desktop"
    property string currentTerminal: "kitty.desktop"
    property string currentEditor: "codium.desktop"
    property string currentVideo: "mpv.desktop"

    /* Dropdown open states */
    property bool browserDropdownOpen: false
    property bool terminalDropdownOpen: false
    property bool editorDropdownOpen: false
    property bool videoDropdownOpen: false

    /* Available options discovered on the system */
    readonly property var browserOptions: [
        { name: "Brave Browser", desktop: "brave-browser.desktop" },
        { name: "Firefox", desktop: "firefox.desktop" },
        { name: "Chromium", desktop: "chromium.desktop" }
    ]

    readonly property var terminalOptions: [
        { name: "Kitty", desktop: "kitty.desktop" },
        { name: "Alacritty", desktop: "alacritty.desktop" },
        { name: "Foot", desktop: "foot.desktop" }
    ]

    readonly property var editorOptions: [
        { name: "VSCodium", desktop: "codium.desktop" },
        { name: "Neovim", desktop: "nvim.desktop" },
        { name: "Text Editor", desktop: "org.gnome.TextEditor.desktop" }
    ]

    readonly property var videoOptions: [
        { name: "MPV Media Player", desktop: "mpv.desktop" },
        { name: "VLC Media Player", desktop: "vlc.desktop" }
    ]

    /* Process runner for applying changes */
    Process {
        id: applyProc
        running: false
    }

    function setBrowser(desktopFile) {
        root.currentBrowser = desktopFile;
        applyProc.command = ["xdg-settings", "set", "default-web-browser", desktopFile];
        applyProc.running = true;
    }

    function setEditor(desktopFile) {
        root.currentEditor = desktopFile;
        applyProc.command = ["xdg-mime", "default", desktopFile, "text/plain"];
        applyProc.running = true;
    }

    function setVideo(desktopFile) {
        root.currentVideo = desktopFile;
        applyProc.command = ["xdg-mime", "default", desktopFile, "video/mp4", "video/x-matroska"];
        applyProc.running = true;
    }

    /* Query initial defaults on startup */
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

    /* Main Scrollable View */
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

            /* Web & Productivity Group */
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

                        /* Web Browser Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Web Browser"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 220
                                    height: 32
                                    radius: 6
                                    color: browserHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.browserDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: browserHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            readonly property var found: root.browserOptions.find(o => o.desktop === root.currentBrowser)
                                            text: found ? found.name : root.currentBrowser
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
                                            color: root.theme.textSecondary
                                            rotation: root.browserDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.browserDropdownOpen = !root.browserDropdownOpen
                                    }
                                }
                            }
                        }

                        /* Expandable Browser Options */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.browserDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.browserOptions
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.currentBrowser === modelData.desktop
                                    color: isSelected ? root.theme.bgSelected : (bHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: bHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.name
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.setBrowser(modelData.desktop);
                                            root.browserDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Terminal Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Terminal"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 220
                                    height: 32
                                    radius: 6
                                    color: termHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.terminalDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    HoverHandler { id: termHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            readonly property var found: root.terminalOptions.find(o => o.desktop === root.currentTerminal)
                                            text: found ? found.name : root.currentTerminal
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
                                            color: root.theme.textSecondary
                                            rotation: root.terminalDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.terminalDropdownOpen = !root.terminalDropdownOpen
                                    }
                                }
                            }
                        }

                        /* Expandable Terminal Options */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.terminalDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.terminalOptions
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.currentTerminal === modelData.desktop
                                    color: isSelected ? root.theme.bgSelected : (tHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: tHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.name
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.currentTerminal = modelData.desktop;
                                            root.terminalDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Text Editor Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Text Editor"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 220
                                    height: 32
                                    radius: 6
                                    color: edHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.editorDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    HoverHandler { id: edHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            readonly property var found: root.editorOptions.find(o => o.desktop === root.currentEditor)
                                            text: found ? found.name : root.currentEditor
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
                                            color: root.theme.textSecondary
                                            rotation: root.editorDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.editorDropdownOpen = !root.editorDropdownOpen
                                    }
                                }
                            }
                        }

                        /* Expandable Editor Options */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.editorDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.editorOptions
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.currentEditor === modelData.desktop
                                    color: isSelected ? root.theme.bgSelected : (eHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: eHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.name
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.setEditor(modelData.desktop);
                                            root.editorDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Media Group */
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

                        /* Video Player Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Video Player"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 220
                                    height: 32
                                    radius: 6
                                    color: vidHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.04))
                                    border.color: root.videoDropdownOpen ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    HoverHandler { id: vidHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            readonly property var found: root.videoOptions.find(o => o.desktop === root.currentVideo)
                                            text: found ? found.name : root.currentVideo
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
                                            color: root.theme.textSecondary
                                            rotation: root.videoDropdownOpen ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.videoDropdownOpen = !root.videoDropdownOpen
                                    }
                                }
                            }
                        }

                        /* Expandable Video Options */
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 8
                            visible: root.videoDropdownOpen
                            spacing: 4

                            Repeater {
                                model: root.videoOptions
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 6
                                    readonly property bool isSelected: root.currentVideo === modelData.desktop
                                    color: isSelected ? root.theme.bgSelected : (vHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")

                                    HoverHandler { id: vHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.name
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: isSelected
                                            color: isSelected ? root.theme.textPrimary : root.theme.textSecondary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: isSelected
                                            text: "󰄬"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.setVideo(modelData.desktop);
                                            root.videoDropdownOpen = false;
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
