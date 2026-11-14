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
    SectionCard {
        title: "Application Ranking & Sorting"
        subtitle: "Determines how applications are ordered before entering a search term"
        contentMargins: 10
        contentSpacing: 8

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
                        ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08))
                        : (sortHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : root.theme.bgBase)
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
                            font.pixelSize: 13
                            font.bold: true
                            color: sortCard.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                            horizontalAlignment: Text.AlignLeft
                        }

                        Text {
                            width: parent.width
                            text: sortCard.modelData.desc
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textMuted
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }
            }
        }
    }

    // Search Match Scope Section
    SectionCard {
        title: "Search Matching Scope"
        subtitle: "Control which metadata fields are evaluated during fuzzy search"
        contentMargins: 8
        contentSpacing: 0

        SettingToggleRow {
            title: "Match Generic App Names"
            desc: "Allow searches like 'Browser', 'Terminal', 'Text Editor', or 'File Manager'"
            checked: AppLauncherConfig.matchGenericName
            onToggled: (val) => AppLauncherConfig.setMatchGenericName(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Match Keywords"
            desc: "Match developer tags and search keywords embedded in .desktop entries"
            checked: AppLauncherConfig.matchKeywords
            onToggled: (val) => AppLauncherConfig.setMatchKeywords(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Match Categories"
            desc: "Allow filtering by categories such as 'Development', 'Graphics', or 'AudioVideo'"
            checked: AppLauncherConfig.matchCategories
            onToggled: (val) => AppLauncherConfig.setMatchCategories(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Clear Search Query on Close"
            desc: "Reset search bar and return to default state when the launcher is closed"
            checked: AppLauncherConfig.clearSearchOnClose
            onToggled: (val) => AppLauncherConfig.setClearSearchOnClose(val)
        }
    }

    // Actions & Cache Section
    SectionCard {
        title: "Actions & Cache Management"
        subtitle: "Manage launch history and restore default launcher configurations"
        contentMargins: 8
        contentSpacing: 0

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
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "Wipe all recorded application launch counts and timestamps in ~/.cache/qs_app_usage.json"
                    font.family: root.font
                    font.pixelSize: 11
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
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "Revert dimensions, sorting, search scopes, and exclusions to default values"
                    font.family: root.font
                    font.pixelSize: 11
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
