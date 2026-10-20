import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: toggleRow
    property string title: ""
    property string desc: ""
    property bool checked: false
    property bool rowEnabled: true
    property bool announce: false      // emit Style.toast on click
    property bool invertThumb: false   // thumb uses base colour while checked
    signal toggled(bool val)

    Layout.fillWidth: true
    height: 52
    opacity: rowEnabled ? 1.0 : 0.45

    Behavior on opacity { NumberAnimation { duration: 140 } }

    MouseArea {
        id: toggleRowMouse
        anchors.fill: parent
        z: 10
        enabled: toggleRow.rowEnabled
        cursorShape: toggleRow.rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            toggleRow.toggled(!toggleRow.checked);
            if (toggleRow.announce)
                Style.toast(toggleRow.title + ": " + (!toggleRow.checked ? "Enabled" : "Disabled"));
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            Text {
                text: toggleRow.title
                font.family: Style.font
                font.pixelSize: 13
                font.bold: true
                color: Style.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: toggleRow.desc !== ""
                text: toggleRow.desc
                font.family: Style.font
                font.pixelSize: 11
                color: Style.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            width: 44
            height: 24
            radius: 12
            scale: toggleRowMouse.pressed ? 0.94 : 1.0
            color: toggleRow.checked ? Style.theme.accentPrimary : Style.theme.bgSelected
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on scale { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: toggleRow.checked ? parent.width - width - 3 : 3
                color: toggleRow.checked ? "#ffffff" : (Style.theme.textPrimary ?? "#c0caf5")

                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }
    }
}
