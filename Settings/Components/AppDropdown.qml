/*
 * AppDropdown.qml
 *
 * Modern, clean application selector dropdown component (text-only).
 * Features:
 *   - Clean text-focused typography with responsive elision
 *   - Sleek trigger button with glowing hover & active states
 *   - Floating popover menu with entrance animations and backdrop shadow
 *   - Two-line option delegates (app name + desktop file / description)
 *   - Active selection checkmark with glowing accent highlight
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../utils/ColorUtils.js" as ColorUtils
import "./Common"

Item {
    id: root

    property var theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
    property string currentValue: ""
    property var options: []
    property string placeholder: "Select application..."
    property int menuWidth: 260

    signal opened()
    signal closed()
    signal selected(string desktopFile, var optionData)

    implicitWidth: 220
    implicitHeight: 32

    function closeMenu() {
        dropdownPopup.close();
    }

    function openMenu() {
        dropdownPopup.open();
    }

    readonly property bool isOpen: dropdownPopup.opened

    function colorWithAlpha(c, alpha) {
        return ColorUtils.withAlpha(c, alpha);
    }

    readonly property var currentOption: {
        if (!options || options.length === 0) return null;
        for (let i = 0; i < options.length; i++) {
            if (options[i].desktop === currentValue) return options[i];
        }
        return null;
    }

    // Dropdown Trigger Pill Button
    Rectangle {
        id: triggerBtn
        anchors.fill: parent
        radius: 7
        color: {
            if (root.isOpen) return root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12);
            if (btnHover.hovered) return root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08);
            return root.theme.bgBase;
        }
        border.color: {
            if (root.isOpen) return root.theme.accentPrimary;
            if (btnHover.hovered) return root.colorWithAlpha(root.theme.accentPrimary, 0.45);
            return root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1);
        }
        border.width: root.isOpen ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler { id: btnHover }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // App Name Text
            Text {
                text: root.currentOption ? root.currentOption.name : (root.currentValue || root.placeholder)
                font.family: root.font
                font.pixelSize: Style.px(12)
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Rotating Chevron
            Text {
                text: "󰅀"
                font.family: root.font
                font.pixelSize: Style.px(13)
                color: root.isOpen ? root.theme.accentPrimary : root.theme.textSecondary
                rotation: root.isOpen ? 180 : 0
                Layout.alignment: Qt.AlignVCenter

                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (dropdownPopup.opened) {
                    dropdownPopup.close();
                } else {
                    dropdownPopup.open();
                }
            }
        }
    }

    // Floating Popover Menu
    Popup {
        id: dropdownPopup
        parent: triggerBtn
        x: triggerBtn.width - width
        y: triggerBtn.height + 4
        width: root.menuWidth
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        onOpened: root.opened()
        onClosed: root.closed()

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "y"; from: triggerBtn.height; to: triggerBtn.height + 4; duration: 150; easing.type: Easing.OutCubic }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InQuad }
        }

        background: Rectangle {
            radius: 8
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1
        }

        contentItem: ListView {
            id: optionsList
            implicitHeight: Math.min(contentHeight, 240)
            model: root.options
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            spacing: 2

            delegate: Rectangle {
                id: itemDelegate
                width: optionsList.width
                readonly property string itemDesc: modelData.desc !== undefined ? modelData.desc : (modelData.desktop || "")
                height: itemDesc !== "" ? 40 : 30
                radius: 6

                readonly property bool isSelected: root.currentValue === modelData.desktop

                color: {
                    if (isSelected) return root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.14);
                    if (itemHover.hovered) return root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06);
                    return "transparent";
                }

                Behavior on color { ColorAnimation { duration: 110 } }

                HoverHandler { id: itemHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // App Text (Title + Description)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: modelData.name || modelData.desktop
                            font.family: root.font
                            font.pixelSize: Style.px(12)
                            font.bold: itemDelegate.isSelected
                            color: itemDelegate.isSelected 
                                ? root.theme.accentPrimary 
                                : root.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: itemDelegate.itemDesc
                            font.family: root.font
                            font.pixelSize: Style.px(10)
                            color: root.theme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected(modelData.desktop, modelData);
                        dropdownPopup.close();
                    }
                }
            }
        }
    }
}
