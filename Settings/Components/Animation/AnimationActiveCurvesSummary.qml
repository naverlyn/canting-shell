import QtQuick
import QtQuick.Layouts
import "../Common"

SectionCard {
    required property var root
    title: "Active Bezier Curves & Compositor Rules"
    subtitle: root.activeBeziers.length + " curves · " + root.activeRules.length + " rules"
    contentMargins: 12
    contentSpacing: 10

    // Configured Bezier Curves
    Text {
        text: "Configured Bezier Curves"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: root.activeBeziers

            Rectangle {
                id: chipRect
                required property var modelData
                height: 28
                width: chipRow.implicitWidth + 20
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: chipRect.modelData.name
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }

                    Text {
                        text: "(" + chipRect.modelData.curve + ")"
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                    }
                }
            }
        }
    }

    RowDivider { sideMargin: 0 }

    // Active Animation Rules (2-column compact grid)
    Text {
        text: "Active Animation Rules"
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textSecondary
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 6

        Repeater {
            model: root.activeRules

            Rectangle {
                id: ruleRect
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                height: 34
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: ruleRect.modelData.enabled
                            ? (root.theme.accentGreen ?? "#9ece6a")
                            : (root.theme.accentRed ?? "#f7768e")
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: ruleRect.modelData.target
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: ruleRect.modelData.speed + " · " + ruleRect.modelData.curve
                            + (ruleRect.modelData.style ? (" · " + ruleRect.modelData.style) : "")
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.maximumWidth: 200
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
