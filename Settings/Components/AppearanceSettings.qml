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

    property string searchText: ""
    property string selectedFamily: "All"
    property string hoveredAccentName: ""

    readonly property var families: ["All", "GenAI", "Tokyo Night", "Catppuccin", "MonkeyType"]

    function isColorMatch(c1, c2) {
        if (!c1 || !c2) return false;
        var s1 = String(c1).toLowerCase();
        var s2 = String(c2).toLowerCase();
        return s1.substring(0, 7) === s2.substring(0, 7);
    }

    function getThemeAccent(name, defaultColor) {
        if (!root.theme || !root.theme.current) return defaultColor;
        var t = root.theme.current;
        return t[name] ? String(t[name]) : defaultColor;
    }

    readonly property var accentSwatches: [
        { name: "Primary", color: getThemeAccent("accentPrimary", "#7aa2f7") },
        { name: "Cyan",    color: getThemeAccent("accentCyan", "#7dcfff") },
        { name: "Green",   color: getThemeAccent("accentGreen", "#9ece6a") },
        { name: "Orange",  color: getThemeAccent("accentOrange", "#ff9e64") },
        { name: "Red",     color: getThemeAccent("accentRed", "#f7768e") }
    ]

    function hasActiveCustomAccent() {
        if (!root.theme || !root.theme.customAccent) return false;
        for (var i = 0; i < root.accentSwatches.length; i++) {
            if (isColorMatch(root.theme.customAccent, root.accentSwatches[i].color))
                return true;
        }
        return false;
    }

    readonly property var filteredThemes: {
        if (!root.theme || !root.theme.themes) return [];
        var query = searchText.toLowerCase().trim();
        var fam = selectedFamily;
        var res = [];
        for (var i = 0; i < root.theme.themes.length; i++) {
            var t = root.theme.themes[i];
            if (!t) continue;
            if (fam !== "All" && t.family !== fam) continue;
            if (query !== "") {
                var nameMatch = t.name && t.name.toLowerCase().indexOf(query) !== -1;
                var famMatch = t.family && t.family.toLowerCase().indexOf(query) !== -1;
                if (!nameMatch && !famMatch) continue;
            }
            res.push({ data: t, originalIndex: i });
        }
        return res;
    }

    onVisibleChanged: {
        if (!visible && root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    Component.onDestruction: {
        if (root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: 14
        spacing: 10

        // Page title
        Text {
            text: "Appearance"
            font.family: root.font
            font.pixelSize: 18
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        // 1. Current Theme Preview & System Color Scheme Card
        Rectangle {
            Layout.fillWidth: true
            height: 90
            radius: 12
            color: root.theme.bgSelected

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰏘"
                        font.family: root.font
                        font.pixelSize: 24
                        color: root.theme.accentPrimary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "System Color Scheme"
                            font.family: root.font
                            font.pixelSize: 14
                            font.bold: true
                            color: root.theme.textPrimary
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Active theme badge
                        Rectangle {
                            height: 18
                            radius: 9
                            implicitWidth: badgeText.implicitWidth + 12
                            color: root.theme.bgSurface
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.accentPrimary
                                text: root.theme.wallpaperMode
                                      ? "Wallpaper Palette"
                                      : ((root.theme.currentFamily || "") + " - " + (root.theme.currentName || ""))
                            }
                        }
                    }

                    Text {
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        text: root.hoveredAccentName !== ""
                              ? ("Hovering: " + root.hoveredAccentName + " accent")
                              : (root.hasActiveCustomAccent()
                                 ? "Custom accent active. Click Primary to reset."
                                 : "Hover swatches or themes to live-preview colors, click to apply")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Theme Accent Swatches with stable hover container
                    Item {
                        height: 24
                        Layout.fillWidth: true

                        HoverHandler {
                            id: swatchesHover
                            onHoveredChanged: {
                                if (!hovered) {
                                    root.theme.previewAccent = "";
                                    root.hoveredAccentName = "";
                                }
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Repeater {
                                model: root.accentSwatches

                                Item {
                                    required property var modelData
                                    required property int index

                                    width: 22
                                    height: 22

                                    readonly property bool isActive: {
                                        if (root.theme.previewAccent !== "")
                                            return root.isColorMatch(root.theme.previewAccent, modelData.color);
                                        if (root.hasActiveCustomAccent())
                                            return root.isColorMatch(root.theme.customAccent, modelData.color);
                                        return modelData.name === "Primary";
                                    }

                                    // Outer focus/active ring
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: "transparent"
                                        border.color: isActive
                                                      ? root.theme.textPrimary
                                                      : (swatchMouse.containsMouse ? root.theme.accentPrimary : Qt.rgba(1,1,1,0.1))
                                        border.width: isActive ? 2 : 1
                                        Behavior on border.color { ColorAnimation { duration: 100 } }
                                    }

                                    // Color circle
                                    Rectangle {
                                        id: innerCircle
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: modelData.color
                                        scale: swatchMouse.containsMouse ? 1.2 : 1.0

                                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                                        // Active center indicator dot
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 4
                                            height: 4
                                            radius: 2
                                            visible: isActive
                                            color: root.theme.isLightColor(modelData.color) ? "#000000" : "#ffffff"
                                        }
                                    }

                                    MouseArea {
                                        id: swatchMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: {
                                            root.hoveredAccentName = modelData.name;
                                            root.theme.previewAccent = modelData.color;
                                        }
                                        onClicked: {
                                            if (modelData.name === "Primary") {
                                                root.theme.setAccent("");
                                            } else {
                                                root.theme.setAccent(modelData.color);
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

        // 2. Embedded Theme & Color Scheme Selector
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰔎"
                    font.family: root.font
                    font.pixelSize: 16
                    color: root.theme.accentPrimary
                }

                Text {
                    text: "Theme Selector"
                    font.family: root.font
                    font.pixelSize: 14
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "(" + root.filteredThemes.length + " themes)"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                }

                Item { Layout.fillWidth: true }

                // Open Full Theme Switcher Modal button
                Rectangle {
                    height: 26
                    implicitWidth: modalBtnRow.implicitWidth + 14
                    radius: 6
                    color: modalBtnMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: modalBtnRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰔎"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.accentPrimary
                        }
                        Text {
                            text: "Full View"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: modalBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themeProc.running = true
                    }
                }
            }

            // Controls row: Category pills on left, search pill on right
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Family category pills
                Row {
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: root.families

                        Rectangle {
                            required property var modelData
                            height: 24
                            implicitWidth: pillText.implicitWidth + 14
                            radius: 12
                            color: root.selectedFamily === modelData ? root.theme.bgSelected : root.theme.bgSurface
                            border.color: root.selectedFamily === modelData ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                id: pillText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: root.selectedFamily === modelData
                                color: root.selectedFamily === modelData ? root.theme.accentPrimary : root.theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedFamily = modelData
                            }
                        }
                    }

                    // Wallpaper palette mode pill
                    Rectangle {
                        visible: root.theme.wallpaperFeatureEnabled
                        height: 24
                        implicitWidth: wpPillText.implicitWidth + 14
                        radius: 12
                        color: root.theme.wallpaperMode ? root.theme.bgSelected : root.theme.bgSurface
                        border.color: root.theme.wallpaperMode ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            id: wpPillText
                            anchors.centerIn: parent
                            text: "Wallpaper"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: root.theme.wallpaperMode
                            color: root.theme.wallpaperMode ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.theme.previewIndex = -1;
                                root.theme.setWallpaperMode();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search input
                Rectangle {
                    width: 180
                    height: 26
                    radius: 13
                    color: root.theme.bgSurface
                    border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4

                        Text {
                            text: "󰍉"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: root.theme.textPrimary
                            font.family: root.font
                            font.pixelSize: 10
                            clip: true
                            selectByMouse: true

                            onTextChanged: root.searchText = text

                            Text {
                                text: "Search..."
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text === ""
                            }
                        }

                        Text {
                            text: "󰅖"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textMuted
                            visible: searchInput.text !== ""

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    root.searchText = "";
                                }
                            }
                        }
                    }
                }
            }

            // Scrollable Theme List with smooth container-level hover exit
            Rectangle {
                id: listContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 180
                radius: 10
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                border.width: 1
                clip: true

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                HoverHandler {
                    id: listHover
                    onHoveredChanged: {
                        if (!hovered) {
                            previewResetTimer.restart();
                        }
                    }
                }

                Timer {
                    id: previewResetTimer
                    interval: 150
                    repeat: false
                    onTriggered: {
                        if (!listHover.hovered) {
                            root.theme.previewIndex = -1;
                        }
                    }
                }

                ListView {
                    id: themeList
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2
                    model: root.filteredThemes

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.2)
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        width: ListView.view.width - 6
                        height: 40
                        radius: 8

                        readonly property bool isSelected: !root.theme.wallpaperMode && root.theme.currentIndex === modelData.originalIndex
                        readonly property bool isPreviewing: root.theme.previewIndex === modelData.originalIndex

                        color: isPreviewing
                               ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08))
                               : (isSelected
                                  ? root.theme.bgSelected
                                  : (hoverArea.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 80 } }

                        // Indicator bar on left edge
                        Rectangle {
                            width: 3
                            height: 20
                            radius: 2
                            color: root.theme.accentPrimary
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isSelected || isPreviewing
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8

                            // Theme name
                            Text {
                                text: delegateRoot.modelData.data.name
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: isSelected || isPreviewing
                                color: (isSelected || isPreviewing) ? root.theme.textPrimary : root.theme.textSecondary
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                Layout.maximumWidth: 220
                            }

                            // Family tag
                            Rectangle {
                                height: 16
                                radius: 4
                                implicitWidth: famTag.implicitWidth + 8
                                color: root.theme.bgBase
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    id: famTag
                                    anchors.centerIn: parent
                                    text: delegateRoot.modelData.data.family
                                    font.family: root.font
                                    font.pixelSize: 9
                                    color: root.theme.textMuted
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Color swatches preview
                            Row {
                                spacing: 5
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: [
                                        delegateRoot.modelData.data.bgBase,
                                        delegateRoot.modelData.data.accentPrimary,
                                        delegateRoot.modelData.data.accentGreen,
                                        delegateRoot.modelData.data.accentOrange,
                                        delegateRoot.modelData.data.accentRed
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: modelData
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                                        border.width: 1
                                    }
                                }
                            }

                            // Fixed-width checkmark slot so swatches always align
                            Item {
                                width: 22
                                height: 22
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.accentGreen
                                    visible: isSelected
                                }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                previewResetTimer.stop();
                                root.theme.previewIndex = delegateRoot.modelData.originalIndex;
                            }
                            onClicked: {
                                previewResetTimer.stop();
                                root.theme.previewIndex = -1;
                                root.theme.setTheme(delegateRoot.modelData.originalIndex);
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No themes found matching \"" + root.searchText + "\""
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textMuted
                        visible: themeList.count === 0
                    }
                }
            }
        }

        // 3. Desktop Wallpaper Switcher Card
        Rectangle {
            Layout.fillWidth: true
            height: 58
            radius: 10
            color: wpMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : root.theme.bgSurface
            border.color: wpMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: wpMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wpProc.running = true
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Desktop Wallpaper"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Pick background images or set dynamic wallpapers"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                // Explicit spacer pushes the Browse button to the far right
                Item {
                    Layout.fillWidth: true
                }

                // Browse button on the far right
                Rectangle {
                    width: 84
                    height: 28
                    radius: 6
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    color: wpBtnMouse.containsMouse ? root.theme.bgSelected : root.theme.bgBase
                    border.color: wpBtnMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.12))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Browse"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: wpBtnMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
                    }

                    MouseArea {
                        id: wpBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wpProc.running = true
                    }
                }
            }
        }
    }

    Process {
        id: themeProc
        command: ["qs", "ipc", "call", "theme", "toggle"]
        running: false
    }

    Process {
        id: wpProc
        command: ["qs", "ipc", "call", "wallpaper", "toggle"]
        running: false
    }
}
