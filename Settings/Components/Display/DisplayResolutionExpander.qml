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
        height: 52

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
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Native pixel dimensions and aspect ratio"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            /* Resolution Dropdown Pill */
            Rectangle {
                width: 220
                height: 32
                radius: 6
                color: root.resolutionDropdownOpen
                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                    : (resPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.04)))
                border.color: root.resolutionDropdownOpen
                    ? root.theme.accentPrimary
                    : (resPillHover.hovered
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                border.width: root.resolutionDropdownOpen ? 1.5 : 1
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: resPillHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: {
                            if (!root.selectedMonitor) return "";
                            const parts = root.currentResString.split("x");
                            if (parts.length === 2) {
                                const ar = root.getAspectRatio(parseInt(parts[0]), parseInt(parts[1]));
                                return parts[0] + " × " + parts[1] + (ar ? ("  (" + ar + ")") : "");
                            }
                            return root.currentResString;
                        }
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.resolutionDropdownOpen ? "Close" : "Change"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.resolutionDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.mirrorDropdownOpen = false;
                        root.resolutionDropdownOpen = !root.resolutionDropdownOpen;
                    }
                }
            }
        }
    }

    /* Expandable Resolution Options Sub-Container */
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.bottomMargin: root.resolutionDropdownOpen ? 8 : 0
        Layout.preferredHeight: root.resolutionDropdownOpen ? Math.min(220, resListCol.implicitHeight + 8) : 0
        opacity: root.resolutionDropdownOpen ? 1.0 : 0.0
        clip: true
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.18)
        border.color: root.resolutionDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
        border.width: 1

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

        Flickable {
            anchors.fill: parent
            anchors.margins: 4
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
                        required property var modelData
                        Layout.fillWidth: true
                        height: 34
                        radius: 6
                        readonly property bool isSelected: root.currentResString === modelData.res

                        color: isSelected
                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                            : (resOptHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : "transparent")
                        border.color: isSelected
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                            : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: resOptHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: modelData.label
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: isSelected
                                color: isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            Rectangle {
                                visible: modelData.aspect !== ""
                                height: 18
                                implicitWidth: aspectLabel.implicitWidth + 10
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    id: aspectLabel
                                    anchors.centerIn: parent
                                    text: modelData.aspect
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                visible: isSelected
                                text: "Active"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectResolution(modelData);
                                root.resolutionDropdownOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
