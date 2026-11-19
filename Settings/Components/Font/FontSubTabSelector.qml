import QtQuick
import QtQuick.Layouts
import "../Common"

Rectangle {
    required property var root
    signal tabSwitched()

    id: fontSubTabTrack
    Layout.fillWidth: true
    height: 40
    radius: 10
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Repeater {
            model: [
                { idx: 0, icon: "󰛖", label: "Preview & Pairings" },
                { idx: 1, icon: "󰍉", label: "Font Browser" },
                { idx: 2, icon: "󰒓", label: "Scale & Rendering" }
            ]
            delegate: Rectangle {
                id: fontSubTabItem
                required property var modelData
                readonly property bool isCurrent: root.currentSubTab === modelData.idx

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.width: 0
                scale: fontSubTabMouse.pressed ? 0.96 : (fontSubTabHover.hovered ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                HoverHandler { id: fontSubTabHover }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2
                    radius: 1
                    width: fontSubTabItem.isCurrent
                        ? fontSubTabRow.implicitWidth + 16
                        : (fontSubTabHover.hovered ? (fontSubTabRow.implicitWidth + 16) * 0.5 : 0)
                    opacity: fontSubTabItem.isCurrent ? 1.0 : (fontSubTabHover.hovered ? 0.5 : 0.0)
                    color: fontSubTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Row {
                    id: fontSubTabRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: fontSubTabItem.modelData.icon
                        font.family: Style.font
                        font.pixelSize: 13
                        color: fontSubTabItem.isCurrent
                            ? root.theme.accentPrimary
                            : (fontSubTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: fontSubTabItem.modelData.label
                        font.family: Style.font
                        font.pixelSize: 12
                        font.bold: fontSubTabItem.isCurrent
                        color: fontSubTabItem.isCurrent
                            ? root.theme.textPrimary
                            : (fontSubTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    id: fontSubTabMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentSubTab !== fontSubTabItem.modelData.idx) {
                            root.currentSubTab = fontSubTabItem.modelData.idx;
                            fontSubTabTrack.tabSwitched();
                        }
                    }
                }
            }
        }
    }
}
