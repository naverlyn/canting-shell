import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

RowLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 12

    // Primary UI Font Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        height: 88
        radius: 12
        color: root.targetRole === "ui"
            ? Style.withAlpha(root.theme.accentPrimary, 0.12)
            : root.theme.bgSurface
        border.color: root.targetRole === "ui"
            ? root.theme.accentPrimary
            : root.theme.bgBorder
        border.width: root.targetRole === "ui" ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: 10
                color: Style.withAlpha(root.theme.accentPrimary, 0.16)
                border.color: Style.withAlpha(root.theme.accentPrimary, 0.4)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Aa"
                    font.family: root.theme.fontFamily
                    font.pixelSize: Style.px(18)
                    font.bold: true
                    color: root.theme.accentPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "PRIMARY UI FONT"
                        font.family: Style.font
                        font.pixelSize: Style.px(9)
                        font.bold: true
                        font.letterSpacing: 0.8
                        color: root.theme.accentPrimary
                    }

                    Rectangle {
                        visible: root.targetRole === "ui" || root.targetRole === "both"
                        height: 15
                        radius: 4
                        implicitWidth: uiTargetLbl.implicitWidth + 8
                        color: root.theme.accentPrimary

                        Text {
                            id: uiTargetLbl
                            anchors.centerIn: parent
                            text: "BROWSING"
                            font.family: Style.font
                            font.pixelSize: 8
                            font.bold: true
                            color: root.theme.bgBase
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    text: root.theme.fontFamily
                    font.family: root.theme.fontFamily
                    font.pixelSize: Style.px(14)
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "Bar • Settings • Control Center • Notifications • OSD"
                    font.family: Style.font
                    font.pixelSize: Style.px(10)
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.targetRole = "ui"
        }
    }

    // Monospace & Lock Screen Font Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        height: 88
        radius: 12
        color: root.targetRole === "mono"
            ? Style.withAlpha(root.theme.accentCyan, 0.12)
            : root.theme.bgSurface
        border.color: root.targetRole === "mono"
            ? root.theme.accentCyan
            : root.theme.bgBorder
        border.width: root.targetRole === "mono" ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: 10
                color: Style.withAlpha(root.theme.accentCyan, 0.16)
                border.color: Style.withAlpha(root.theme.accentCyan, 0.4)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "01"
                    font.family: root.theme.monoFont
                    font.pixelSize: Style.px(16)
                    font.bold: true
                    color: root.theme.accentCyan
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "MONOSPACE & LOCK SCREEN"
                        font.family: Style.font
                        font.pixelSize: Style.px(9)
                        font.bold: true
                        font.letterSpacing: 0.8
                        color: root.theme.accentCyan
                    }

                    Rectangle {
                        visible: root.targetRole === "mono" || root.targetRole === "both"
                        height: 15
                        radius: 4
                        implicitWidth: monoTargetLbl.implicitWidth + 8
                        color: root.theme.accentCyan

                        Text {
                            id: monoTargetLbl
                            anchors.centerIn: parent
                            text: "BROWSING"
                            font.family: Style.font
                            font.pixelSize: 8
                            font.bold: true
                            color: root.theme.bgBase
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    text: root.theme.monoFont
                    font.family: root.theme.monoFont
                    font.pixelSize: Style.px(14)
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "Lock Screen • Weather Metrics • Code Blocks"
                    font.family: Style.font
                    font.pixelSize: Style.px(10)
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.targetRole = "mono"
        }
    }
}
