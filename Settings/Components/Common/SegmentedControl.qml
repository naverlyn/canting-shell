import QtQuick
import QtQuick.Layouts

Rectangle {
    id: segCtrl
    property var options: [] // [{ id, label }]
    property string currentId: ""
    property int trackWidth: 340
    signal optionSelected(string optionId, string optionLabel)

    readonly property int activeIdx: {
        for (let i = 0; i < options.length; i++) {
            if (options[i].id === currentId) return i;
        }
        return -1;
    }
    readonly property real cellWidth: options.length > 0 ? (width - 6 - (options.length - 1) * 3) / options.length : 0

    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    implicitWidth: trackWidth
    height: 32
    radius: 7
    color: Style.theme.bgBase
    border.color: Style.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    // Sliding Selection Pill
    Rectangle {
        visible: segCtrl.activeIdx >= 0
        y: 3
        height: parent.height - 6
        width: segCtrl.cellWidth
        x: 3 + Math.max(0, segCtrl.activeIdx) * (segCtrl.cellWidth + 3)
        radius: 5
        color: Style.theme.bgSelected
        border.color: Style.theme.accentPrimary
        border.width: 1

        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: segCtrl.options
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool isSel: segCtrl.activeIdx === index

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 5
                color: !isSel && segHover.hovered ? (Style.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }

                HoverHandler { id: segHover }

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: Style.font
                    font.pixelSize: 11
                    font.bold: isSel
                    color: isSel ? Style.theme.accentPrimary : Style.theme.textPrimary
                    opacity: isSel || segHover.hovered ? 1.0 : 0.75
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: segCtrl.optionSelected(modelData.id, modelData.label)
                }
            }
        }
    }
}
