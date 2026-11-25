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
                    text: "Resolution"
                    font.family: root.font
                    font.pixelSize: Style.px(13)
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            /* Resolution Dropdown Pill */
            Rectangle {
                id: resDropdownBtn
                Layout.preferredWidth: 380
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 7
                color: resPopup.visible
                    ? root.theme.bgSelected
                    : (resPillHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                border.color: resPopup.visible
                    ? root.theme.accentPrimary
                    : (resPillHover.hovered
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5)
                        : root.theme.bgBorder)
                border.width: resPopup.visible ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: resPillHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: {
                            if (!root.selectedMonitor) return "";
                            const parts = root.currentResString.split("x");
                            if (parts.length === 2) {
                                const ar = root.getAspectRatio(parseInt(parts[0]), parseInt(parts[1]));
                                return parts[0] + " × " + parts[1] + (ar ? (" (" + ar + ")") : "");
                            }
                            return root.currentResString;
                        }
                        font.family: root.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "󰅀"
                        font.family: root.font
                        font.pixelSize: Style.px(13)
                        color: resPopup.visible ? root.theme.accentPrimary : root.theme.textSecondary
                        rotation: resPopup.visible ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (resPopup.visible) resPopup.close();
                        else {
                            root.mirrorDropdownOpen = false;
                            resPopup.open();
                        }
                    }
                }

                Popup {
                    id: resPopup
                    y: resDropdownBtn.height + 4
                    width: resDropdownBtn.width
                    padding: 4
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                    transformOrigin: Item.Top
                    onVisibleChanged: root.resolutionDropdownOpen = visible

                    Connections {
                        target: root
                        function onResolutionDropdownOpenChanged() {
                            if (!root.resolutionDropdownOpen && resPopup.visible) resPopup.close();
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

                    contentItem: Flickable {
                        implicitWidth: resPopup.width - 8
                        implicitHeight: Math.min(240, resListCol.implicitHeight)
                        contentHeight: resListCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: resListCol
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: root.availableResolutions
                                delegate: Rectangle {
                                    id: resOptItem
                                    required property var modelData
                                    readonly property bool isSelected: root.currentResString === modelData.res
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 6
                                    color: isSelected
                                        ? root.theme.bgSelected
                                        : (resOptHover.hovered ? root.theme.bgHover : "transparent")
                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    HoverHandler { id: resOptHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 6

                                        Text {
                                            text: resOptItem.modelData.label
                                            font.family: root.font
                                            font.pixelSize: Style.px(12)
                                            font.bold: resOptItem.isSelected
                                            color: resOptItem.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                        }

                                        Rectangle {
                                            visible: resOptItem.modelData.aspect !== ""
                                            Layout.preferredHeight: 17
                                            Layout.preferredWidth: aspectLabel.implicitWidth + 8
                                            Layout.alignment: Qt.AlignVCenter
                                            radius: 4
                                            color: Qt.rgba(1, 1, 1, 0.06)

                                            Text {
                                                id: aspectLabel
                                                anchors.centerIn: parent
                                                text: resOptItem.modelData.aspect
                                                font.family: root.font
                                                font.pixelSize: Style.px(9)
                                                color: root.theme.textSecondary
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectResolution(resOptItem.modelData);
                                            resPopup.close();
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
