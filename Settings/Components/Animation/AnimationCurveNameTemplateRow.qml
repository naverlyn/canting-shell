import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Name:"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
    }

    Rectangle {
        width: 120
        height: 26
        radius: 6
        color: root.theme.bgBase
        border.color: curveNameIn.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1

        TextInput {
            id: curveNameIn
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            font.family: root.font
            font.pixelSize: 10
            color: root.theme.textPrimary
            text: root.newCurveName
            onTextChanged: {
                if (text.trim() !== "" && text !== root.newCurveName) {
                    root.updateSelectedBezierName(text.trim());
                }
            }
        }
    }

    Text {
        text: "Templates:"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
    }

    Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: root.curveTemplates

            Rectangle {
                id: cTplPill
                property var tplData: modelData
                height: 24
                implicitWidth: cTplText.implicitWidth + 14
                radius: 6
                color: root.newCurvePreset === tplData.name
                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                    : (cTplHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgBase)
                border.color: root.newCurvePreset === tplData.name
                    ? root.theme.accentPrimary
                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: cTplHover }

                Text {
                    id: cTplText
                    anchors.centerIn: parent
                    text: cTplPill.tplData.name
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: root.newCurvePreset === cTplPill.tplData.name
                    color: root.newCurvePreset === cTplPill.tplData.name ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectCurveTemplate(cTplPill.tplData.name, cTplPill.tplData.points)
                }
            }
        }
    }
}
