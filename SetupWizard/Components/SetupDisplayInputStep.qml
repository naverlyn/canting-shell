import QtQuick
import QtQuick.Layouts
import "../../Settings/Components"

ColumnLayout {
    id: root

    required property var theme
    required property string font
    required property bool isActive

    property int activeTab: 0 // 0: Display, 1: Mouse & Touchpad

    spacing: 10

    // Segmented tab bar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: ["Display", "Mouse & Touchpad"]
            delegate: Rectangle {
                required property string modelData
                required property int index
                readonly property bool isSel: root.activeTab === index

                radius: 8
                color: isSel
                    ? root.theme.accentPrimary
                    : (tabMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                border.color: isSel
                    ? root.theme.accentPrimary
                    : (tabMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder)
                border.width: 1
                implicitWidth: tabLbl.implicitWidth + 24
                implicitHeight: 30
                scale: tabMouse.pressed ? 0.96 : (tabMouse.containsMouse ? 1.02 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeTab = index
                }

                Text {
                    id: tabLbl
                    anchors.centerIn: parent
                    text: modelData
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: isSel
                    color: isSel ? root.theme.bgBase : root.theme.textPrimary
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    Loader {
        visible: root.activeTab === 0
        active: root.isActive && root.activeTab === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: Component {
            DisplaySettings {
                theme: root.theme
                font: root.font
            }
        }
    }

    Loader {
        visible: root.activeTab === 1
        active: root.isActive && root.activeTab === 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: Component {
            MouseSettings {
                theme: root.theme
                font: root.font
            }
        }
    }
}
