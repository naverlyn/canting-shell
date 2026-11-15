import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var theme
    required property string font
    required property string prefixMode
    required property var smartResults
    required property int selectedIndex

    readonly property alias count: smartResultsList.count

    signal itemSelected(int index)
    signal itemActivated(var item)

    function scrollToIndex(idx, mode) {
        if (smartResultsList.count > 0 && idx >= 0 && idx < smartResultsList.count) {
            smartResultsList.positionViewAtIndex(idx, mode !== undefined ? mode : ListView.Contain);
        }
    }

    ListView {
        id: smartResultsList
        anchors.fill: parent
        model: root.smartResults
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex
        highlightMoveDuration: 150
        highlightMoveVelocity: -1

        highlight: Rectangle {
            radius: 8
            color: root.theme.bgSelected
            visible: smartResultsList.count > 0 && root.selectedIndex >= 0
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 3
                height: 24
                radius: 2
                color: root.theme.accentPrimary
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        delegate: Rectangle {
            id: smartDelegate
            required property var modelData
            required property int index

            width: smartResultsList.width
            height: 46
            radius: 8
            color: smartHover.containsMouse && root.selectedIndex !== index ? root.theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Item {
                id: smartIconBox
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 22
                    source: smartDelegate.modelData.iconName
                        ? Quickshell.iconPath(smartDelegate.modelData.iconName, true)
                        : ""
                    visible: Boolean(smartDelegate.modelData.iconName)
                }

                Text {
                    anchors.centerIn: parent
                    visible: !smartDelegate.modelData.iconName
                    text: smartDelegate.modelData.glyph || ""
                    font.family: root.font
                    font.pixelSize: 16
                    color: root.theme.accentPrimary
                }
            }

            Rectangle {
                id: wsBadge
                visible: smartDelegate.modelData.kind === "window" && smartDelegate.modelData.wsId > 0
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: wsBadgeLbl.implicitWidth + 12
                implicitHeight: 20
                radius: 6
                color: root.theme.bgSurface
                border.width: 1
                border.color: root.theme.bgBorder

                Text {
                    id: wsBadgeLbl
                    anchors.centerIn: parent
                    text: "WS " + (smartDelegate.modelData.wsId || "")
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.theme.textSecondary
                }
            }

            Item {
                anchors.left: smartIconBox.right
                anchors.leftMargin: 12
                anchors.right: wsBadge.visible ? wsBadge.left : parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: smartDelegate.modelData.title || ""
                    color: root.selectedIndex === smartDelegate.index ? root.theme.textPrimary : root.theme.textSecondary
                    font.family: root.font
                    font.pixelSize: smartDelegate.modelData.kind === "calc" ? 15 : 13
                    font.bold: root.selectedIndex === smartDelegate.index || smartDelegate.modelData.kind === "calc"
                    elide: Text.ElideRight
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: smartDelegate.modelData.subtitle || ""
                    color: root.theme.textMuted
                    font.family: root.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: smartHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.itemSelected(smartDelegate.index)
                onClicked: root.itemActivated(smartDelegate.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.prefixMode === "window" ? "No matching windows" : "No matches found"
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: root.font
            visible: smartResultsList.count === 0
        }
    }
}
