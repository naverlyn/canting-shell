import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 14
    visible: root.currentSubTab === 2

    // Search Bar
    Rectangle {
        Layout.fillWidth: true
        height: 36
        radius: 7
        color: root.theme.bgBase
        border.color: envSearchInput.activeFocus
            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
            : root.theme.bgBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "󰍉"
                font.family: root.font
                font.pixelSize: Style.px(13)
                color: envSearchInput.activeFocus
                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                    : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
            }

            TextInput {
                id: envSearchInput
                Layout.fillWidth: true
                font.family: root.font
                font.pixelSize: Style.px(12)
                color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                clip: true
                selectByMouse: true
                text: root.envSearchQuery
                onTextChanged: root.envSearchQuery = text

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !parent.text && !parent.activeFocus
                    text: "Filter environment variables..."
                    font.family: root.font
                    font.pixelSize: Style.px(12)
                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: clearEnvSearchHover.hovered ? root.theme.bgHover : "transparent"
                visible: envSearchInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: root.font
                    font.pixelSize: Style.px(11)
                    color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                }

                HoverHandler { id: clearEnvSearchHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: envSearchInput.text = ""
                }
            }
        }
    }

    // Environment Variables Table Card Box
    Rectangle {
        Layout.fillWidth: true
        height: 440
        radius: 8
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true

        ListView {
            id: envListView
            anchors.fill: parent
            anchors.margins: 8
            model: root.filteredEnvs
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: root.theme.bgBorder
                }
            }

            delegate: Rectangle {
                id: envRow
                required property var modelData

                width: envListView.width - 8
                height: 42
                radius: 6
                color: envHover.hovered ? root.theme.bgSurface : "transparent"
                border.color: root.theme.bgBorder
                border.width: 1

                HoverHandler { id: envHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        Layout.preferredWidth: 260
                        text: envRow.modelData.key
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: (root.theme && root.theme.accentCyan) ? root.theme.accentCyan : "#7dcfff"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "="
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Style.px(12)
                        color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: envRow.modelData.value
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: Style.px(12)
                        color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
