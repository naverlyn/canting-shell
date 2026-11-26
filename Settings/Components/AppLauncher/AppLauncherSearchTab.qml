import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import Quickshell.Io
import Quickshell.Widgets
import "../../../AppLauncher"
import "../.."
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 1

    // Sorting Algorithm Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Application Ranking & Sorting"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol1.implicitHeight + 10 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: AppLauncherConfig.sortOptions
                        delegate: Rectangle {
                            id: sortCard
                            required property var modelData
                            readonly property bool isSelected: AppLauncherConfig.sortMode === modelData.id

                            Layout.fillWidth: true
                            height: 52
                            radius: 8
                            color: isSelected
                                ? root.theme.bgSelected
                                : (sortHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                            border.color: isSelected ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: isSelected ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            HoverHandler { id: sortHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    AppLauncherConfig.setSortMode(sortCard.modelData.id);
                                    root.showToast("Sorting set to " + sortCard.modelData.label);
                                }
                            }

                            // Radio indicator circle anchored left
                            Rectangle {
                                id: radioCircle
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: sortCard.isSelected ? root.theme.accentPrimary : root.theme.textMuted
                                border.width: 1.5

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: root.theme.accentPrimary
                                    visible: sortCard.isSelected
                                }
                            }

                            // Content Column explicitly anchored to radio circle
                            Column {
                                anchors.left: radioCircle.right
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: sortCard.modelData.label
                                    font.family: root.font
                                    font.pixelSize: Style.px(13)
                                    font.bold: true
                                    color: sortCard.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                    horizontalAlignment: Text.AlignLeft
                                }

                                Text {
                                    width: parent.width
                                    text: sortCard.modelData.desc
                                    font.family: root.font
                                    font.pixelSize: Style.px(11)
                                    color: root.theme.textMuted
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Search Match Scope Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Search Matching Scope"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol2.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol2
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingToggleRow {
                    title: "Match Generic App Names"
                    checked: AppLauncherConfig.matchGenericName
                    onToggled: (val) => AppLauncherConfig.setMatchGenericName(val)
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Match Keywords"
                    checked: AppLauncherConfig.matchKeywords
                    onToggled: (val) => AppLauncherConfig.setMatchKeywords(val)
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Match Categories"
                    checked: AppLauncherConfig.matchCategories
                    onToggled: (val) => AppLauncherConfig.setMatchCategories(val)
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Clear Search Query on Close"
                    checked: AppLauncherConfig.clearSearchOnClose
                    onToggled: (val) => AppLauncherConfig.setClearSearchOnClose(val)
                }
            }
        }
    }

    // Actions & Cache Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Actions & Cache Management"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol3.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol3
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    height: 52

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: clearHistBtn.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: "Clear App Launch History"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Wipe all recorded application launch counts and timestamps in ~/.cache/qs_app_usage.json"
                            font.family: root.font
                            font.pixelSize: Style.px(11)
                            color: root.theme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        id: clearHistBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Clear History"
                        danger: true
                        btnHeight: 30
                        onClicked: AppLauncherConfig.clearAppUsage()
                    }
                }

                RowDivider {}

                Item {
                    Layout.fillWidth: true
                    height: 52

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: resetDefaultsBtn.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: "Reset All Launcher Settings"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Revert dimensions, sorting, search scopes, and exclusions to default values"
                            font.family: root.font
                            font.pixelSize: Style.px(11)
                            color: root.theme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        id: resetDefaultsBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Reset Defaults"
                        btnHeight: 30
                        onClicked: {
                            AppLauncherConfig.resetDefaults();
                            root.showToast("App Launcher reset to default settings");
                        }
                    }
                }
            }
        }
    }
}
