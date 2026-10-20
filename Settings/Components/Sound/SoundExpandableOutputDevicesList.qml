import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: sinkExpandBox
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.bottomMargin: root.outputDropdownOpen ? 8 : 0
    Layout.preferredHeight: root.outputDropdownOpen ? (sinkListCol.implicitHeight + 8) : 0
    opacity: root.outputDropdownOpen ? 1.0 : 0.0
    clip: true
    radius: 8
    color: Qt.rgba(0, 0, 0, 0.18)
    border.color: root.outputDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
    border.width: 1

    Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

    Column {
        id: sinkListCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 4
        }
        spacing: 2

        Repeater {
            model: root.audioSinks
            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 38
                radius: root.btnRadius
                readonly property bool isSelected: Boolean(modelData && root.defaultSink && root.defaultSink.id === modelData.id)
                color: isSelected 
                    ? (root.theme.bgSelected ?? Qt.rgba(1,1,1,0.12)) 
                    : (itemHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                border.color: isSelected 
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3) 
                    : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }

                HoverHandler { id: itemHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: modelData ? (modelData.description || modelData.name || "Output Device") : "Output Device"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: isSelected
                        color: isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    /* Text Badge: Current */
                    Rectangle {
                        visible: isSelected
                        implicitWidth: currentSinkLabel.implicitWidth + 14
                        height: 22
                        radius: 4
                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                        border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                        border.width: 1

                        Text {
                            id: currentSinkLabel
                            anchors.centerIn: parent
                            text: "Current"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData) Pipewire.preferredDefaultAudioSink = modelData;
                        root.outputDropdownOpen = false;
                    }
                }
            }
        }
    }
}
