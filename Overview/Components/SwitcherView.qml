import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    required property string font
    required property var toplevels
    required property int selectedIndex

    signal windowClicked(var toplevel)
    signal windowClosed(var toplevel)
    signal selectionChanged(int index)

    readonly property int columns: Math.min(4, Math.max(1, root.toplevels.length))

    implicitWidth: root.toplevels.length > 0
        ? (columns * 250 + (columns - 1) * 14)
        : 360
    implicitHeight: root.toplevels.length > 0
        ? Math.min(440, grid.implicitHeight)
        : 120

    Text {
        anchors.centerIn: parent
        visible: root.toplevels.length === 0
        text: "No open windows"
        font.family: root.font
        font.pixelSize: 14
        color: root.theme.textMuted
    }

    Flickable {
        anchors.fill: parent
        visible: root.toplevels.length > 0
        contentHeight: grid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: grid
            width: parent.width
            columns: root.columns
            rowSpacing: 14
            columnSpacing: 14

            Repeater {
                model: root.toplevels

                delegate: WindowPreviewCard {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    theme: root.theme
                    font: root.font
                    toplevel: modelData
                    isSelected: root.selectedIndex === index

                    onHovered: root.selectionChanged(index)
                    onClicked: root.windowClicked(modelData)
                    onCloseClicked: root.windowClosed(modelData)
                }
            }
        }
    }
}
