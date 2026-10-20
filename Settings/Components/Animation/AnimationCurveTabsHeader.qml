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
        text: "Béziers:"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textPrimary
    }

    // Curve Selectors
    Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: root.studioBeziers

            Rectangle {
                id: bTabPill
                property var bezierTabItem: modelData
                property int tabIdx: index
                height: 26
                implicitWidth: bTabText.implicitWidth + 16
                radius: 6
                color: root.selectedBezierIndex === tabIdx
                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                    : (bTabHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : root.theme.bgBase)
                border.color: root.selectedBezierIndex === tabIdx
                    ? root.theme.accentPrimary
                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: bTabHover }

                Text {
                    id: bTabText
                    anchors.centerIn: parent
                    text: bTabPill.bezierTabItem.name
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: root.selectedBezierIndex === bTabPill.tabIdx
                    color: root.selectedBezierIndex === bTabPill.tabIdx ? root.theme.accentPrimary : root.theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectBezier(bTabPill.tabIdx)
                }
            }
        }
    }

    // Right Action Buttons (+ Add Curve, - Remove)
    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

        // Add Curve Button
        Rectangle {
            height: 26
            implicitWidth: addCurveText.implicitWidth + 18
            radius: 6
            color: addCurveHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
            border.color: addCurveHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: addCurveHover }

            Text {
                id: addCurveText
                anchors.centerIn: parent
                text: "+ Add Curve"
                font.family: root.font
                font.pixelSize: 10
                font.bold: true
                color: root.theme.accentPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.addStudioBezier()
            }
        }

        // Remove Curve Button
        Rectangle {
            visible: root.studioBeziers.length > 1
            height: 26
            implicitWidth: remCurveText.implicitWidth + 16
            radius: 6
            color: remCurveHover.hovered ? Qt.rgba(0.97, 0.46, 0.56, 0.18) : root.theme.bgBase
            border.color: remCurveHover.hovered ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: remCurveHover }

            Text {
                id: remCurveText
                anchors.centerIn: parent
                text: "- Remove"
                font.family: root.font
                font.pixelSize: 10
                font.bold: true
                color: remCurveHover.hovered ? (root.theme.accentRed ?? "#f7768e") : root.theme.textMuted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeSelectedBezier()
            }
        }
    }
}
