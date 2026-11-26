import QtQuick
import QtQuick.Layouts
import "../Common"

ColumnLayout {
    id: webGroup
    required property var root

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Web & Productivity"
        font.family: webGroup.root.font
        font.pixelSize: Style.px(13)
        font.bold: true
        color: webGroup.root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: webCol.implicitHeight + 16
        radius: 12
        color: webGroup.root.theme.bgSurface
        border.color: webGroup.root.theme.bgBorder
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

            DefaultAppSelectorRow {
                theme: webGroup.root.theme
                font: webGroup.root.font
                title: "Web Browser"
                currentValue: webGroup.root.currentBrowser
                options: webGroup.root.browserOptions
                isOpen: webGroup.root.browserDropdownOpen
                onToggleRequested: {
                    if (!webGroup.root.browserDropdownOpen) webGroup.root.closeOtherDropdowns("browser");
                    webGroup.root.browserDropdownOpen = !webGroup.root.browserDropdownOpen;
                }
                onOptionSelected: (desktopFile, optionData) => {
                    webGroup.root.setBrowser(desktopFile, optionData);
                    webGroup.root.browserDropdownOpen = false;
                }
            }

            RowDivider {}

            DefaultAppSelectorRow {
                theme: webGroup.root.theme
                font: webGroup.root.font
                title: "Terminal"
                currentValue: webGroup.root.currentTerminal
                options: webGroup.root.terminalOptions
                isOpen: webGroup.root.terminalDropdownOpen
                onToggleRequested: {
                    if (!webGroup.root.terminalDropdownOpen) webGroup.root.closeOtherDropdowns("terminal");
                    webGroup.root.terminalDropdownOpen = !webGroup.root.terminalDropdownOpen;
                }
                onOptionSelected: (desktopFile, optionData) => {
                    webGroup.root.setTerminal(desktopFile, optionData);
                    webGroup.root.terminalDropdownOpen = false;
                }
            }

            RowDivider {}

            DefaultAppSelectorRow {
                theme: webGroup.root.theme
                font: webGroup.root.font
                title: "Text Editor"
                currentValue: webGroup.root.currentEditor
                options: webGroup.root.editorOptions
                isOpen: webGroup.root.editorDropdownOpen
                onToggleRequested: {
                    if (!webGroup.root.editorDropdownOpen) webGroup.root.closeOtherDropdowns("editor");
                    webGroup.root.editorDropdownOpen = !webGroup.root.editorDropdownOpen;
                }
                onOptionSelected: (desktopFile, optionData) => {
                    webGroup.root.setEditor(desktopFile, optionData);
                    webGroup.root.editorDropdownOpen = false;
                }
            }
        }
    }
}
