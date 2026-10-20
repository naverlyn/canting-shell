import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Cava Visualizer Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Enable Cava Visualizer"
        desc: "Allow audio spectrum streaming when Cava is placed on a bar"
        checked: BarConfig.showCava !== false
        onToggled: (val) => {
            BarConfig.showCava = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Cava visualizer enabled" : "Cava visualizer disabled");
        }
    }



    RowDivider {}

    SettingToggleRow {
        title: "Auto-Hide When Silent"
        desc: "Hide or minimize the spectrum pill when no audio is currently playing"
        checked: BarConfig.cavaAutoHide
        onToggled: (val) => {
            BarConfig.cavaAutoHide = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Auto-hide enabled" : "Auto-hide disabled");
        }
    }

    RowDivider {}

    // Visual Style Selector: Smooth Bars / Glyphs / Line Waves
    Item {
        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Visualizer Display Style"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose between smooth rounded bars, centered waves, or terminal glyphs"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: cavaStyleSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property string activeVal: BarConfig.cavaStyle || "bars"
                readonly property int activeIdx: activeVal === "line" ? 1 : (activeVal === "glyphs" ? 2 : 0)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: cavaStyleSegmentTrack.cellWidth
                    x: 3 + cavaStyleSegmentTrack.activeIdx * (cavaStyleSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Bars", value: "bars" },
                            { label: "Line", value: "line" },
                            { label: "Glyphs", value: "glyphs" }
                        ]
                        delegate: Rectangle {
                            id: cavaStyleBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: cavaStyleSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && cavaStyleHov.hovered ? root.theme.bgHover : "transparent"
                            scale: cavaStyleMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: cavaStyleHov }

                            Text {
                                anchors.centerIn: parent
                                text: cavaStyleBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: cavaStyleBtn.isSel
                                color: cavaStyleBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: cavaStyleBtn.isSel || cavaStyleHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: cavaStyleMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.cavaStyle = cavaStyleBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Cava style set to: " + cavaStyleBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    // Cava Visualizer Mode Selector: Compact (Current) / Medium / Wide
    Item {
        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Cava Visualizer Mode"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose visualizer size: Compact (current), Medium, or Wide"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: cavaModeSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property string activeVal: BarConfig.cavaMode || "compact"
                readonly property int activeIdx: activeVal === "medium" ? 1 : (activeVal === "wide" ? 2 : 0)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: cavaModeSegmentTrack.cellWidth
                    x: 3 + cavaModeSegmentTrack.activeIdx * (cavaModeSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Compact", value: "compact" },
                            { label: "Medium",  value: "medium" },
                            { label: "Wide",    value: "wide" }
                        ]
                        delegate: Rectangle {
                            id: cavaModeBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: cavaModeSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && cavaModeHov.hovered ? root.theme.bgHover : "transparent"
                            scale: cavaModeMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: cavaModeHov }

                            Text {
                                anchors.centerIn: parent
                                text: cavaModeBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: cavaModeBtn.isSel
                                color: cavaModeBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: cavaModeBtn.isSel || cavaModeHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: cavaModeMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.setCavaMode(cavaModeBtn.modelData.value);
                                    root.showToast("Cava mode set to: " + cavaModeBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    // Refresh Framerate Selector: 20, 30, 60 FPS
    Item {
        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Visualizer Framerate"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Update rate in frames per second (higher is smoother, lower uses less CPU)"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: cavaFpsSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.cavaFramerate || 30)
                readonly property int activeIdx: activeVal === 20 ? 0 : (activeVal === 60 ? 2 : 1)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: cavaFpsSegmentTrack.cellWidth
                    x: 3 + cavaFpsSegmentTrack.activeIdx * (cavaFpsSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "20 FPS", value: 20 },
                            { label: "30 FPS", value: 30 },
                            { label: "60 FPS", value: 60 }
                        ]
                        delegate: Rectangle {
                            id: cavaFpsBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: cavaFpsSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && cavaFpsHov.hovered ? root.theme.bgHover : "transparent"
                            scale: cavaFpsMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: cavaFpsHov }

                            Text {
                                anchors.centerIn: parent
                                text: cavaFpsBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: cavaFpsBtn.isSel
                                color: cavaFpsBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: cavaFpsBtn.isSel || cavaFpsHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: cavaFpsMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.cavaFramerate = cavaFpsBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Cava framerate set to: " + cavaFpsBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
