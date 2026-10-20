import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

RowLayout {
    required property var hostCard
    Layout.fillWidth: true
    spacing: 10

    // Delete Button (Modern danger action button)
    Rectangle {
        id: delBtn
        visible: hostCard.blockData && hostCard.blockData.is_custom
        implicitWidth: delText.implicitWidth + 24
        height: 32
        radius: 8
        color: delHover.hovered ? Qt.rgba(0.97, 0.46, 0.56, 0.18) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
        border.color: delHover.hovered ? (hostCard.theme.accentRed ?? "#f7768e") : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1
        scale: delMouse.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        HoverHandler { id: delHover }

        Text {
            id: delText
            anchors.centerIn: parent
            text: "Delete Block"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: delHover.hovered ? (hostCard.theme.accentRed ?? "#f7768e") : (hostCard.theme.textPrimary ?? "#ffffff")
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: delMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hostCard.blockDeleted(hostCard.blockIndex)
        }
    }

    Item { Layout.fillWidth: true }

    // Cancel / Close Button (Modern secondary action button)
    Rectangle {
        id: cancelBtn
        implicitWidth: cancelText.implicitWidth + 22
        height: 32
        radius: 8
        color: cancelHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
        border.color: cancelHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1
        scale: cancelMouse.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        HoverHandler { id: cancelHover }

        Text {
            id: cancelText
            anchors.centerIn: parent
            text: "Cancel"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: cancelHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textPrimary ?? "#ffffff")
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: cancelMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hostCard.isExpanded = false
        }
    }

    // Save & Apply Button (Modern primary action button)
    Rectangle {
        id: saveBtn
        implicitWidth: saveText.implicitWidth + 26
        height: 32
        radius: 8
        color: saveHover.hovered ? Qt.darker(hostCard.theme.accentPrimary ?? "#7aa2f7", 1.1) : (hostCard.theme.accentPrimary ?? "#7aa2f7")
        scale: saveMouse.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        HoverHandler { id: saveHover }

        Text {
            id: saveText
            anchors.centerIn: parent
            text: "Apply Changes"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: "#ffffff"
        }

        MouseArea {
            id: saveMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hostCard.saveChanges()
        }
    }
}
