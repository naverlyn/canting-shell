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
        text: "Action:"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
        Layout.preferredWidth: 70
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        id: addActionSegmentTrack
        implicitWidth: 620
        Layout.preferredWidth: 620
        height: 32
        radius: 7
        color: root.theme.bgBase
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        readonly property var options: root.addDispatcherOptions
        readonly property int activeIdx: {
            for (let i = 0; i < options.length; i++) {
                if (options[i].val === root.addDispatcher) return i;
            }
            return 0;
        }
        readonly property real cellWidth: (width - 6 - ((options.length - 1) * 4)) / Math.max(1, options.length)

        /* Sliding Pill */
        Rectangle {
            y: 3
            height: parent.height - 6
            width: addActionSegmentTrack.cellWidth
            x: 3 + addActionSegmentTrack.activeIdx * (addActionSegmentTrack.cellWidth + 4)
            radius: 5
            color: root.theme.bgSelected
            border.color: root.theme.accentPrimary
            border.width: 1

            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            Repeater {
                model: addActionSegmentTrack.options

                delegate: Rectangle {
                    id: aSegBtn
                    required property var modelData
                    required property int index
                    readonly property bool isSel: addActionSegmentTrack.activeIdx === index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: !isSel && aSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: aSegHover }

                    Text {
                        anchors.centerIn: parent
                        text: aSegBtn.modelData.name
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: aSegBtn.isSel
                        color: aSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                        opacity: aSegBtn.isSel || aSegHover.hovered ? 1.0 : 0.75
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addDispatcher = aSegBtn.modelData.val
                    }
                }
            }
        }
    }

    Item { Layout.fillWidth: true }
}
