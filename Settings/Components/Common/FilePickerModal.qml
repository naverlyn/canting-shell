import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: modal
    required property var root

    property string title: "Select File"
    property var extensions: [".png"]
    property bool showThumbnails: true
    property string fileGlyph: "󰈔"
    property string emptyText: "No matching files found here"
    property string hintText: "Click a folder to open, or select a file"
    property string searchPlaceholder: "Filter folders or files..."
    property var quickPlaces: []

    signal fileSelected(string path)

    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-file-picker"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property string homeDir: Quickshell.env("HOME") || "/home"
    property string currentDir: homeDir
    property string searchQuery: ""
    property string selectedPath: ""
    property var entries: []
    property real openProgress: 0.0

    readonly property var effectivePlaces: modal.quickPlaces && modal.quickPlaces.length > 0
        ? modal.quickPlaces
        : [
            { label: "Home", path: modal.homeDir },
            { label: "Pictures", path: modal.homeDir + "/Pictures" },
            { label: "Downloads", path: modal.homeDir + "/Downloads" },
            { label: "Quickshell", path: modal.homeDir + "/.config/quickshell" }
        ]

    function openPicker(startDir) {
        modal.selectedPath = "";
        modal.searchQuery = "";
        modal.openProgress = 0.0;
        if (startDir && startDir !== "") modal.currentDir = startDir;
        modal.visible = true;
        openAnim.restart();
        loadDir(modal.currentDir);
    }

    NumberAnimation {
        id: openAnim
        target: modal
        property: "openProgress"
        from: 0.0
        to: 1.0
        duration: 180
        easing.type: Easing.OutCubic
    }

    function loadDir(dirPath) {
        modal.currentDir = dirPath;
        const extJson = JSON.stringify(modal.extensions || []);
        listProc.command = [
            "python3", "-c",
            "import os, json, sys\n" +
            "d, exts = sys.argv[1], [e.lower() for e in json.loads(sys.argv[2])]\n" +
            "dirs, files = [], []\n" +
            "try:\n" +
            "    for name in sorted(os.listdir(d), key=lambda s: s.lower()):\n" +
            "        if name.startswith('.'): continue\n" +
            "        full = os.path.join(d, name)\n" +
            "        if os.path.isdir(full): dirs.append({'name': name, 'path': full, 'isDir': True})\n" +
            "        elif not exts or any(name.lower().endswith(e) for e in exts): files.append({'name': name, 'path': full, 'isDir': False})\n" +
            "except Exception:\n" +
            "    pass\n" +
            "print(json.dumps(dirs + files))",
            dirPath,
            extJson
        ];
        listProc.running = true;
    }

    function goUp() {
        const idx = modal.currentDir.lastIndexOf("/");
        if (idx <= 0) {
            if (modal.currentDir !== "/") loadDir("/");
        } else {
            loadDir(modal.currentDir.slice(0, idx));
        }
    }

    function filteredEntries() {
        const q = modal.searchQuery.trim().toLowerCase();
        if (!q) return modal.entries;
        return modal.entries.filter(e => e.name.toLowerCase().indexOf(q) !== -1);
    }

    Process {
        id: listProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    modal.entries = JSON.parse(text || "[]");
                } catch (e) {
                    modal.entries = [];
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: modal.visible
        onActivated: modal.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55 * modal.openProgress)

        MouseArea {
            anchors.fill: parent
            onClicked: modal.visible = false
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(700, parent.width - 48)
        height: Math.min(540, parent.height - 48)
        radius: 14
        color: modal.root.theme.bgBase
        border.color: modal.root.theme.bgBorder
        border.width: 1
        opacity: modal.openProgress
        scale: 0.96 + 0.04 * modal.openProgress

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: modal.title
                    font.family: modal.root.font
                    font.pixelSize: Style.px(15)
                    font.bold: true
                    color: modal.root.theme.textPrimary
                    Layout.fillWidth: true
                }

                ActionButton {
                    iconText: "󰁞"
                    label: "Up"
                    btnHeight: 28
                    btnEnabled: modal.currentDir !== "/"
                    onClicked: modal.goUp()
                }

                ActionButton {
                    label: "Close"
                    btnHeight: 28
                    onClicked: modal.visible = false
                }
            }

            // Quick Places + Current Path
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: modal.effectivePlaces
                    delegate: Rectangle {
                        id: placeBtn
                        required property var modelData
                        readonly property bool active: modal.currentDir === modelData.path
                        Layout.preferredWidth: placeTxt.implicitWidth + 16
                        Layout.preferredHeight: 26
                        radius: 6
                        color: active ? modal.root.theme.bgSelected : (placeHover.hovered ? modal.root.theme.bgHover : modal.root.theme.bgSurface)
                        border.color: active ? modal.root.theme.accentPrimary : modal.root.theme.bgBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        HoverHandler { id: placeHover }
                        Text {
                            id: placeTxt
                            anchors.centerIn: parent
                            text: placeBtn.modelData.label
                            font.family: modal.root.font
                            font.pixelSize: Style.px(11)
                            font.bold: placeBtn.active
                            color: placeBtn.active ? modal.root.theme.accentPrimary : modal.root.theme.textSecondary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modal.loadDir(placeBtn.modelData.path)
                        }
                    }
                }

                Text {
                    text: modal.currentDir
                    font.family: modal.root.font
                    font.pixelSize: Style.px(11)
                    color: modal.root.theme.textMuted
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Search box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: modal.root.theme.bgSurface
                border.color: searchInput.activeFocus ? modal.root.theme.accentPrimary : modal.root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: modal.root.font
                    font.pixelSize: Style.px(12)
                    color: modal.root.theme.textPrimary
                    selectByMouse: true
                    text: modal.searchQuery
                    onTextChanged: modal.searchQuery = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: modal.searchPlaceholder
                        font.family: modal.root.font
                        font.pixelSize: Style.px(12)
                        color: modal.root.theme.textMuted
                        visible: searchInput.text === ""
                    }
                }
            }

            // Grid of folders and matching files
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: modal.root.theme.bgSurface
                border.color: modal.root.theme.bgBorder
                border.width: 1
                clip: true

                GridView {
                    id: entryGrid
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    cellWidth: Math.floor((width - 4) / 4)
                    cellHeight: 96
                    model: modal.filteredEntries()

                    delegate: Rectangle {
                        id: entryTile
                        required property var modelData
                        readonly property bool isSelected: !modelData.isDir && modal.selectedPath === modelData.path
                        width: entryGrid.cellWidth - 8
                        height: entryGrid.cellHeight - 8
                        radius: 8
                        color: isSelected
                            ? modal.root.theme.bgSelected
                            : (tileHover.hovered ? modal.root.theme.bgHover : modal.root.theme.bgBase)
                        border.color: isSelected
                            ? modal.root.theme.accentPrimary
                            : (tileHover.hovered ? Qt.alpha(modal.root.theme.accentPrimary, 0.45) : modal.root.theme.bgBorder)
                        border.width: isSelected ? 1.5 : 1
                        scale: tileHover.hovered ? 1.02 : 1.0

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: tileHover }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    anchors.centerIn: parent
                                    visible: entryTile.modelData.isDir || !modal.showThumbnails
                                    text: entryTile.modelData.isDir ? "󰉋" : modal.fileGlyph
                                    font.family: modal.root.font
                                    font.pixelSize: Style.px(28)
                                    color: (entryTile.modelData.isDir || entryTile.isSelected) ? modal.root.theme.accentPrimary : modal.root.theme.textSecondary
                                }

                                Image {
                                    anchors.centerIn: parent
                                    visible: !entryTile.modelData.isDir && modal.showThumbnails
                                    width: 44
                                    height: 44
                                    source: (!entryTile.modelData.isDir && modal.showThumbnails) ? ("file://" + entryTile.modelData.path) : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    asynchronous: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entryTile.modelData.name
                                font.family: modal.root.font
                                font.pixelSize: Style.px(10)
                                font.bold: entryTile.isSelected
                                color: entryTile.isSelected ? modal.root.theme.accentPrimary : modal.root.theme.textPrimary
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (entryTile.modelData.isDir) {
                                    modal.searchQuery = "";
                                    searchInput.text = "";
                                    modal.loadDir(entryTile.modelData.path);
                                } else {
                                    modal.selectedPath = entryTile.modelData.path;
                                }
                            }
                            onDoubleClicked: {
                                if (!entryTile.modelData.isDir) {
                                    modal.fileSelected(entryTile.modelData.path);
                                    modal.visible = false;
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: entryGrid.count === 0
                    text: modal.emptyText
                    font.family: modal.root.font
                    font.pixelSize: Style.px(12)
                    color: modal.root.theme.textMuted
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: modal.selectedPath !== "" ? modal.selectedPath : modal.hintText
                    font.family: modal.root.font
                    font.pixelSize: Style.px(11)
                    color: modal.root.theme.textSecondary
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                ActionButton {
                    label: "Cancel"
                    btnHeight: 32
                    onClicked: modal.visible = false
                }

                ActionButton {
                    label: "Use Selected"
                    btnHeight: 32
                    btnEnabled: modal.selectedPath !== ""
                    onClicked: {
                        modal.fileSelected(modal.selectedPath);
                        modal.visible = false;
                    }
                }
            }
        }
    }
}
