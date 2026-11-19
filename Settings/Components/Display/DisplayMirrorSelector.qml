import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.editState.length > 1
    Layout.fillWidth: true
    spacing: 0
    opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
    enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

    Item {
        Layout.fillWidth: true
        height: 44

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Mirror Display"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: mirDropdownBtn
                Layout.preferredWidth: 380
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 7
                color: mirPopup.visible
                    ? root.theme.bgSelected
                    : (mirPillHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                border.color: mirPopup.visible
                    ? root.theme.accentPrimary
                    : (mirPillHover.hovered
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5)
                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                border.width: mirPopup.visible ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: mirPillHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: (root.selectedMonitor && root.selectedMonitor.mirrorOf)
                            ? ("Mirroring " + root.selectedMonitor.mirrorOf)
                            : "None (Extend Desktop)"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "󰅀"
                        font.family: root.font
                        font.pixelSize: 13
                        color: mirPopup.visible ? root.theme.accentPrimary : root.theme.textSecondary
                        rotation: mirPopup.visible ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mirPopup.visible) mirPopup.close();
                        else {
                            root.resolutionDropdownOpen = false;
                            mirPopup.open();
                        }
                    }
                }

                Popup {
                    id: mirPopup
                    y: mirDropdownBtn.height + 4
                    width: mirDropdownBtn.width
                    padding: 4
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                    transformOrigin: Item.Top
                    onVisibleChanged: root.mirrorDropdownOpen = visible

                    Connections {
                        target: root
                        function onMirrorDropdownOpenChanged() {
                            if (!root.mirrorDropdownOpen && mirPopup.visible) mirPopup.close();
                        }
                    }

                    enter: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    exit: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InCubic }
                            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 110; easing.type: Easing.InCubic }
                        }
                    }

                    background: Rectangle {
                        radius: 8
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1
                    }

                    contentItem: ColumnLayout {
                        spacing: 2

                        Repeater {
                            model: root.mirrorOptions
                            delegate: Rectangle {
                                id: mirOptItem
                                required property var modelData
                                readonly property bool isSelected: (root.selectedMonitor ? (root.selectedMonitor.mirrorOf || "") : "") === modelData.value
                                Layout.fillWidth: true
                                height: 30
                                radius: 6
                                color: isSelected
                                    ? root.theme.bgSelected
                                    : (mirOptHover.hovered ? root.theme.bgHover : "transparent")
                                Behavior on color { ColorAnimation { duration: 110 } }

                                HoverHandler { id: mirOptHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: mirOptItem.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: mirOptItem.isSelected
                                        color: mirOptItem.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectMirror(mirOptItem.modelData.value);
                                        mirPopup.close();
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
