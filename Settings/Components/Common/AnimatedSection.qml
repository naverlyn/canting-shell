import QtQuick
import QtQuick.Layouts

Item {
    property bool expanded: true
    default property alias content: innerCol.data

    Layout.fillWidth: true
    clip: true
    implicitHeight: expanded ? innerCol.implicitHeight : 0
    opacity: expanded ? 1 : 0
    visible: implicitHeight > 0.5

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: innerCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0
    }
}
