import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Item {
    required property var root
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
