import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Rectangle {
    required property var stageRoot
    visible: stageRoot.selectedIndex === -2
    Layout.fillWidth: true
    height: 36
    radius: 8
    color: stageRoot.theme.bgBase
    border.color: stageRoot.theme.bgBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            text: "Password Box Color:"
            font.family: stageRoot.font
            font.pixelSize: 11
            font.bold: true
            color: stageRoot.theme.textSecondary
        }

        Repeater {
            model: [
                { name: "Accent", outer: "$accent", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentPrimary },
                { name: "Blue / Cyan", outer: "$blue", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentCyan },
                { name: "Green", outer: "$green", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentGreen },
                { name: "Orange", outer: "$peach", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentOrange },
                { name: "Red", outer: "$red", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentRed },
                { name: "Bright Text", outer: "$text", inner: "$surface0", font: "$text", hex: stageRoot.theme.textPrimary },
                { name: "Minimal Dark", outer: "$surface2", inner: "$base", font: "$text", hex: stageRoot.theme.bgSelected }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool isSel: stageRoot.inputOuterColor === modelData.outer && stageRoot.inputInnerColor === modelData.inner
                implicitWidth: pColRow.implicitWidth + 12
                height: 24
                radius: 5
                color: isSel ? stageRoot.theme.bgSelected : (pColHover.hovered ? stageRoot.theme.bgHover : "transparent")
                border.color: isSel ? stageRoot.theme.accentPrimary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                HoverHandler { id: pColHover }

                RowLayout {
                    id: pColRow
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle {
                        width: 9; height: 9; radius: 4.5
                        color: modelData.hex
                        border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                    }
                    Text {
                        text: modelData.name
                        font.family: stageRoot.font
                        font.pixelSize: 10
                        font.bold: isSel
                        color: isSel ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: stageRoot.inputColorModified(modelData.outer, modelData.inner, modelData.font)
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
