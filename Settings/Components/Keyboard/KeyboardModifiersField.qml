import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 10

    Text {
        text: "Modifiers:"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
        Layout.preferredWidth: 70
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        implicitWidth: 280
        height: 32
        radius: 7
        color: root.theme.bgBase
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            Repeater {
                model: [
                    { label: "Super", id: "super" },
                    { label: "Ctrl",  id: "ctrl" },
                    { label: "Alt",   id: "alt" },
                    { label: "Shift", id: "shift" }
                ]

                delegate: Rectangle {
                    id: addModBtn
                    required property var modelData
                    readonly property bool isActive: {
                        if (modelData.id === "super") return root.addSuper;
                        if (modelData.id === "ctrl")  return root.addCtrl;
                        if (modelData.id === "alt")   return root.addAlt;
                        if (modelData.id === "shift") return root.addShift;
                        return false;
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: isActive ? root.theme.bgSelected : (addModHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                    border.color: isActive ? root.theme.accentPrimary : "transparent"
                    border.width: isActive ? 1 : 0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: addModHover }

                    Text {
                        anchors.centerIn: parent
                        text: addModBtn.modelData.label
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: addModBtn.isActive
                        color: addModBtn.isActive ? root.theme.accentPrimary : root.theme.textPrimary
                        opacity: addModBtn.isActive || addModHover.hovered ? 1.0 : 0.75
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (addModBtn.modelData.id === "super") root.addSuper = !root.addSuper;
                            else if (addModBtn.modelData.id === "ctrl")  root.addCtrl = !root.addCtrl;
                            else if (addModBtn.modelData.id === "alt")   root.addAlt = !root.addAlt;
                            else if (addModBtn.modelData.id === "shift") root.addShift = !root.addShift;
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillWidth: true }
}
