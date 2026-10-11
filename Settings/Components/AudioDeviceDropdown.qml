/*
 * AudioDeviceDropdown.qml
 *
 * Modern, clean audio device selector dropdown component (text-only).
 * Features:
 *   - Clean text-focused typography with device profiles
 *   - Sleek trigger button with glowing hover & active states
 *   - Floating popover menu with entrance animations and backdrop shadow
 *   - Two-line option delegates (device name + hardware interface / format)
 *   - Active selection checkmark with glowing accent highlight
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property var theme
    property string font: "Hack Nerd Font"
    property var devices: []
    property var currentDevice: null
    property bool isInput: false
    property string placeholder: isInput ? "No input device" : "No output device"
    property int menuWidth: 300

    signal opened()
    signal closed()
    signal selected(var deviceNode)

    implicitWidth: 250
    implicitHeight: 38

    function closeMenu() {
        dropdownPopup.close();
    }

    function openMenu() {
        dropdownPopup.open();
    }

    readonly property bool isOpen: dropdownPopup.opened

    function colorWithAlpha(c, alpha) {
        if (!c) return Qt.rgba(1, 1, 1, alpha);
        try {
            let col = Qt.color(c);
            return Qt.rgba(col.r, col.g, col.b, alpha);
        } catch (e) {
            return Qt.rgba(1, 1, 1, alpha);
        }
    }

    function getDeviceTitle(node) {
        if (!node) return root.placeholder;
        return node.description || node.name || (root.isInput ? "Microphone" : "Audio Output");
    }

    function getDeviceSubtext(node) {
        if (!node) return "";
        const name = (node.name || "").toLowerCase();
        if (name.includes("analog-stereo")) return "Analog Stereo";
        if (name.includes("analog-surround")) return "Analog Surround";
        if (name.includes("hdmi")) return "Digital HDMI Output";
        if (name.includes("bluez")) return "Bluetooth Audio";
        if (name.includes("usb")) return "USB Audio Device";
        return node.name || "";
    }

    // Trigger Pill Button
    Rectangle {
        id: triggerBtn
        anchors.fill: parent
        radius: 8
        color: {
            if (root.isOpen) return root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12);
            if (btnHover.hovered) return root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08);
            return root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.04);
        }
        border.color: {
            if (root.isOpen) return root.theme.accentPrimary ?? "#7aa2f7";
            if (btnHover.hovered) return root.colorWithAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.45);
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

            // Device Name Text
            Text {
                text: root.getDeviceTitle(root.currentDevice)
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary ?? "#c0caf5"
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Rotating Chevron
            Text {
                text: "󰅀"
                font.family: root.font
                font.pixelSize: 13
                color: root.isOpen ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textSecondary ?? "#a9b1d6")
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
        y: triggerBtn.height + 6
        width: root.menuWidth
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        onOpened: root.opened()
        onClosed: root.closed()

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "y"; from: triggerBtn.height; to: triggerBtn.height + 6; duration: 150; easing.type: Easing.OutCubic }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InQuad }
        }

        background: Rectangle {
            radius: 12
            color: root.theme.bgSurface ?? "#24283b"
            border.color: root.theme.accentPrimary 
                ? root.colorWithAlpha(root.theme.accentPrimary, 0.3) 
                : Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            // Outer subtle glow layer
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 13
                color: "transparent"
                border.color: root.colorWithAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.12)
                border.width: 1
                z: -1
            }
        }

        contentItem: ColumnLayout {
            spacing: 4

            // Empty state placeholder
            Text {
                text: root.isInput ? "No microphone inputs found" : "No audio outputs found"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted ?? "#565f89"
                visible: !root.devices || root.devices.length === 0
                Layout.margins: 12
                Layout.alignment: Qt.AlignHCenter
            }

            ListView {
                id: deviceListView
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight + 2, 280)
                model: root.devices ?? []
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                spacing: 3
                visible: root.devices && root.devices.length > 0

                delegate: Rectangle {
                    id: itemDelegate
                    width: deviceListView.width
                    height: 42
                    radius: 8

                    readonly property bool isSelected: root.currentDevice && root.currentDevice.id === modelData.id

                    color: {
                        if (isSelected) return root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.14);
                        if (itemHover.hovered) return root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06);
                        return "transparent";
                    }

                    border.color: isSelected 
                        ? root.colorWithAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.35)
                        : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on border.color { ColorAnimation { duration: 130 } }

                    HoverHandler { id: itemHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        // Device Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: root.getDeviceTitle(modelData)
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: itemDelegate.isSelected
                                color: itemDelegate.isSelected 
                                    ? (root.theme.accentPrimary ?? "#7aa2f7") 
                                    : (root.theme.textPrimary ?? "#c0caf5")
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.getDeviceSubtext(modelData)
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textMuted ?? "#565f89"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text !== ""
                            }
                        }

                        // Selected Checkmark Pill
                        Text {
                            text: "󰄬"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.accentPrimary ?? "#7aa2f7"
                            visible: itemDelegate.isSelected
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selected(modelData);
                            dropdownPopup.close();
                        }
                    }
                }
            }
        }
    }
}
