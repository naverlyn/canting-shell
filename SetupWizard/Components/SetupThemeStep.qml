import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Settings/Components"

ColumnLayout {
    id: root

    required property var theme
    required property string font
    property string subView: "main" // "main" | "themes" | "wallpapers"
    property string themeSearchQuery: ""

    readonly property var filteredThemes: {
        const list = root.theme && root.theme.themes ? root.theme.themes : [];
        const q = root.themeSearchQuery.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            if (!t) continue;
            if (q === "" || String(t.name || "").toLowerCase().indexOf(q) !== -1) {
                out.push({ index: i, themeObj: t });
            }
        }
        return out;
    }

    spacing: 12

    // Main Step 2 view
    ColumnLayout {
        visible: root.subView === "main"
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Starter Palette"
                font.family: root.font
                font.pixelSize: 14
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            Rectangle {
                radius: 8
                color: modeMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: modeMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                implicitWidth: modeTxt.implicitWidth + 20
                implicitHeight: 32
                scale: modeMouse.pressed ? 0.96 : (modeMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.theme.toggleDarkLight()
                }

                Text {
                    id: modeTxt
                    anchors.centerIn: parent
                    text: root.theme.isDark ? "󰖔  Dark Mode" : "󰖨  Light Mode"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: Math.min(8, root.theme.themes ? root.theme.themes.length : 0)
                delegate: SetupThemeCard {
                    required property int index
                    Layout.fillWidth: true
                    height: 64
                    theme: root.theme
                    font: root.font
                    themeObj: root.theme.themes[index]
                    isSelected: root.theme.currentIndex === index
                    onClicked: root.theme.setTheme(index)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: browseThemesMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: browseThemesMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                scale: browseThemesMouse.pressed ? 0.98 : (browseThemesMouse.containsMouse ? 1.01 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: browseThemesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.subView = "themes"
                }

                Text {
                    anchors.centerIn: parent
                    text: "Browse 200+ Themes"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: pickWallMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: pickWallMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                scale: pickWallMouse.pressed ? 0.98 : (pickWallMouse.containsMouse ? 1.01 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: pickWallMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.subView = "wallpapers"
                }

                Text {
                    anchors.centerIn: parent
                    text: "Open Wallpaper Picker"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Inline All Themes browser
    ColumnLayout {
        visible: root.subView === "themes"
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                radius: 8
                color: backThemeMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: backThemeMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                implicitWidth: backThemeLbl.implicitWidth + 20
                implicitHeight: 32
                scale: backThemeMouse.pressed ? 0.96 : (backThemeMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: backThemeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.subView = "main"
                }

                Text {
                    id: backThemeLbl
                    anchors.centerIn: parent
                    text: "Back"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: root.theme.bgSurface
                border.color: themeSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: themeSearchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    selectByMouse: true
                    text: root.themeSearchQuery
                    onTextChanged: root.themeSearchQuery = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search themes..."
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textMuted
                        visible: !themeSearchInput.text
                    }
                }
            }

            Rectangle {
                radius: 8
                color: modeMouse2.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: modeMouse2.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                implicitWidth: modeTxt2.implicitWidth + 20
                implicitHeight: 32
                scale: modeMouse2.pressed ? 0.96 : (modeMouse2.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: modeMouse2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.theme.toggleDarkLight()
                }

                Text {
                    id: modeTxt2
                    anchors.centerIn: parent
                    text: root.theme.isDark ? "󰖔  Dark" : "󰖨  Light"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.floor(width / 4)
            cellHeight: 74
            model: root.filteredThemes

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Item {
                required property var modelData
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                SetupThemeCard {
                    anchors.fill: parent
                    anchors.margins: 4
                    theme: root.theme
                    font: root.font
                    themeObj: modelData.themeObj
                    isSelected: root.theme.currentIndex === modelData.index
                    onClicked: root.theme.setTheme(modelData.index)
                }
            }
        }
    }

    // Inline WallpaperSettings view
    ColumnLayout {
        visible: root.subView === "wallpapers"
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                radius: 8
                color: backWallMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: backWallMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                implicitWidth: backWallLbl.implicitWidth + 20
                implicitHeight: 28
                scale: backWallMouse.pressed ? 0.96 : (backWallMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: backWallMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.subView = "main"
                }

                Text {
                    id: backWallLbl
                    anchors.centerIn: parent
                    text: "Back"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }
        }

        Loader {
            active: root.subView === "wallpapers"
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: Component {
                WallpaperSettings {
                    theme: root.theme
                }
            }
        }
    }
}
