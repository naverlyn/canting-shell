import QtQuick
import QtQuick.Layouts
import "../Common"

ColumnLayout {
    id: generalTabContent

    required property var root
    Layout.fillWidth: true
    spacing: 20

    GeneralBarCard {
        root: generalTabContent.root
    }

    AnimatedSection {
        expanded: generalTabContent.root.generalTab.curDynamicIsland
        DynamicIslandOptionsCard {
            root: generalTabContent.root
        }
    }

    GlobalFrameCard {
        root: generalTabContent.root
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Layout.topMargin: 4
        spacing: 12

        Text {
            text: "Widget Settings"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 260
            height: 32
            radius: 7
            color: generalTabContent.root.theme.bgSurface
            border.color: optionSearchInput.activeFocus ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.bgBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "󰍉"
                    font.family: generalTabContent.root.font
                    font.pixelSize: 13
                    color: optionSearchInput.activeFocus ? generalTabContent.root.theme.accentPrimary : generalTabContent.root.theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                TextInput {
                    id: optionSearchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: generalTabContent.root.font
                    font.pixelSize: 12
                    color: generalTabContent.root.theme.textPrimary
                    selectByMouse: true
                    clip: true
                    text: generalTabContent.root.optionSearchQuery
                    onTextChanged: generalTabContent.root.optionSearchQuery = text

                    Text {
                        visible: parent.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search widget settings..."
                        font.family: generalTabContent.root.font
                        font.pixelSize: 11
                        color: generalTabContent.root.theme.textMuted
                    }
                }

                Rectangle {
                    visible: optionSearchInput.text !== ""
                    width: 18
                    height: 18
                    radius: 9
                    color: clearOptionSearchHover.hovered ? generalTabContent.root.theme.bgHover : "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    HoverHandler { id: clearOptionSearchHover }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: generalTabContent.root.font
                        font.pixelSize: 10
                        color: clearOptionSearchHover.hovered ? generalTabContent.root.theme.textPrimary : generalTabContent.root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            optionSearchInput.text = "";
                            generalTabContent.root.optionSearchQuery = "";
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        readonly property var r: generalTabContent.root
        readonly property bool hasAnyMatch:
            r.matchesOptionFilter("app grid launcher icon")
            || r.matchesOptionFilter("network speed down up compact")
            || r.matchesOptionFilter("clock time date seconds year calendar")
            || r.matchesOptionFilter("workspaces index scroll hyprland")
            || r.matchesOptionFilter("task switcher window scope label width")
            || r.matchesOptionFilter("global menu appmenu")
            || r.matchesOptionFilter("weather location unit forecast")
            || r.matchesOptionFilter("battery percentage low threshold")
            || r.matchesOptionFilter("cava audio visualizer bars stereo")
            || r.matchesOptionFilter("media player mpris album art seekbar popup")
            || r.matchesOptionFilter("hardware cpu gpu memory disk temp alert")
            || r.matchesOptionFilter("wifi bluetooth connectivity labels")
            || r.matchesOptionFilter("brightness night light step")
            || r.matchesOptionFilter("custom script command interval png image")

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("app grid launcher icon")
            AppGridOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("network speed down up compact")
            NetworkSpeedOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("clock time date seconds year calendar")
            ClockOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("workspaces index scroll hyprland")
            WorkspacesOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("task switcher window scope label width")
            TaskSwitcherOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("global menu appmenu")
            GlobalMenuOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("weather location unit forecast")
            WeatherOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("battery percentage low threshold")
            BatteryOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("cava audio visualizer bars stereo")
            CavaOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("media player mpris album art seekbar popup")
            MediaOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("hardware cpu gpu memory disk temp alert")
            HardwareMonitorOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("wifi bluetooth connectivity labels")
            WifiBluetoothOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("brightness night light step")
            BrightnessOptionsCard { root: generalTabContent.root }
            Item { Layout.fillWidth: true; height: 20 }
        }

        AnimatedSection {
            expanded: generalTabContent.root.matchesOptionFilter("custom script command interval png image")
            CustomScriptOptionsCard { root: generalTabContent.root }
        }

        AnimatedSection {
            expanded: !parent.hasAnyMatch && generalTabContent.root.optionSearchQuery.trim() !== ""
            Item {
                Layout.fillWidth: true
                height: 64
                Text {
                    anchors.centerIn: parent
                    text: "No widget settings matching \"" + generalTabContent.root.optionSearchQuery.trim() + "\""
                    font.family: generalTabContent.root.font
                    font.pixelSize: 12
                    color: generalTabContent.root.theme.textMuted
                }
            }
        }
    }
}
