import QtQuick
import QtQuick.Layouts

Rectangle {
    id: subTabTrack
    property int currentIndex: 0
    property var tabs: []
    signal tabSelected(int index)

    Layout.fillWidth: true
    height: 40
    radius: 10
    color: Style.theme.bgSurface
    border.color: Style.theme.bgBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Repeater {
            model: subTabTrack.tabs
            delegate: Rectangle {
                id: subTabItem
                required property var modelData
                required property int index
                readonly property int tabIdx: modelData.idx !== undefined ? modelData.idx : index
                readonly property bool isCurrent: subTabTrack.currentIndex === tabIdx

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.width: 0
                scale: subTabMouse.pressed ? 0.96 : (subTabHover.hovered ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                HoverHandler { id: subTabHover }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2
                    radius: 1
                    width: subTabItem.isCurrent
                        ? subTabRow.implicitWidth + 16
                        : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                    opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                    color: subTabItem.isCurrent ? Style.theme.accentPrimary : Style.theme.textSecondary

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Row {
                    id: subTabRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        visible: Boolean(subTabItem.modelData.icon)
                        width: 16
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: subTabItem.modelData.icon || ""
                        font.family: Style.font
                        font.pixelSize: Style.px(13)
                        color: subTabItem.isCurrent
                            ? Style.theme.accentPrimary
                            : (subTabHover.hovered ? Style.theme.textPrimary : Style.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: subTabItem.modelData.label || ""
                        font.family: Style.font
                        font.pixelSize: Style.px(12)
                        font.bold: subTabItem.isCurrent
                        font.letterSpacing: Style.letterSpacing
                        font.hintingPreference: Style.fontHintingEnum
                        antialiasing: Style.fontAntialiasing
                        renderType: Style.fontRenderTypeEnum
                        color: subTabItem.isCurrent
                            ? Style.theme.accentPrimary
                            : (subTabHover.hovered ? Style.theme.textPrimary : Style.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    id: subTabMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (subTabTrack.currentIndex !== subTabItem.tabIdx) {
                            subTabTrack.tabSelected(subTabItem.tabIdx);
                        }
                    }
                }
            }
        }
    }
}
