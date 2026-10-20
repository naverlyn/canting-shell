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
                    text: "Mirror Display"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Clone content from another active monitor"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 220
                height: 32
                radius: 6
                color: root.mirrorDropdownOpen
                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                    : (mirPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.04)))
                border.color: root.mirrorDropdownOpen
                    ? root.theme.accentPrimary
                    : (mirPillHover.hovered
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                border.width: root.mirrorDropdownOpen ? 1.5 : 1
                Layout.alignment: Qt.AlignVCenter

                HoverHandler { id: mirPillHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: (root.selectedMonitor && root.selectedMonitor.mirrorOf)
                            ? ("Mirroring " + root.selectedMonitor.mirrorOf)
                            : "None (Extend Desktop)"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.mirrorDropdownOpen ? "Close" : "Change"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.mirrorDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resolutionDropdownOpen = false;
                        root.mirrorDropdownOpen = !root.mirrorDropdownOpen;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.bottomMargin: root.mirrorDropdownOpen ? 8 : 0
        Layout.preferredHeight: root.mirrorDropdownOpen ? (mirrorOptCol.implicitHeight + 8) : 0
        opacity: root.mirrorDropdownOpen ? 1.0 : 0.0
        clip: true
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.18)
        border.color: root.mirrorDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
        border.width: 1

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

        ColumnLayout {
            id: mirrorOptCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 4
            }
            spacing: 2

            Repeater {
                model: root.mirrorOptions
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 34
                    radius: 6
                    readonly property bool isSelected: (root.selectedMonitor ? (root.selectedMonitor.mirrorOf || "") : "") === modelData.value

                    color: isSelected
                        ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                        : (mirOptHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : "transparent")
                    border.color: isSelected
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                        : "transparent"
                    border.width: 1

                    HoverHandler { id: mirOptHover }

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
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

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
                            root.selectMirror(modelData.value);
                            root.mirrorDropdownOpen = false;
                        }
                    }
                }
            }
        }
    }
}
