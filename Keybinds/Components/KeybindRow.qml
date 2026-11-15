import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property string font
    required property var bindItem

    width: ListView.view ? ListView.view.width : 680
    height: 48
    radius: 10
    color: rowHover.hovered ? root.theme.bgHover : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    HoverHandler { id: rowHover }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Description & dispatcher
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.bindItem.title || ""
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: (root.bindItem.dispatcherLabel || "") !== ""
                text: root.bindItem.dispatcherLabel || ""
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
                elide: Text.ElideRight
            }
        }

        // Keycap combo
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 5

            Repeater {
                model: root.bindItem.mods || []
                delegate: Row {
                    spacing: 5
                    required property string modelData

                    KeycapBadge {
                        theme: root.theme
                        font: root.font
                        label: modelData
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "+"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            KeycapBadge {
                theme: root.theme
                font: root.font
                label: root.bindItem.keyLabel || ""
                isPrimary: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
