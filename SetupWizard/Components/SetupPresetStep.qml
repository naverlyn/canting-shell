import QtQuick
import QtQuick.Layouts
import "../../Settings/Components"

ColumnLayout {
    id: root

    required property var theme
    required property string font
    required property string selectedPreset
    property bool customizingBar: false

    signal presetChosen(string name)

    readonly property var presetOptions: [
        {
            id: "laptop",
            icon: "󰌢",
            title: "Laptop",
            desc: "Compact bar with battery, brightness, Wi-Fi, balanced toasts & 2-panel Control Center."
        },
        {
            id: "pc",
            icon: "󰍹",
            title: "PC / Desktop",
            desc: "Full bar with CPU, RAM, network speed, weather, 3-panel Control Center & full lockscreen."
        },
        {
            id: "gaming",
            icon: "󰊴",
            title: "Gaming",
            desc: "1s CPU/GPU/temp polling, idle inhibitor, compact bottom-right toasts & minimal lockscreen."
        },
        {
            id: "minimal",
            icon: "󰕮",
            title: "Minimal",
            desc: "Floating translucent bar, compact toasts, 1-panel vertical Control Center & clean lockscreen."
        }
    ]

    spacing: 12

    GridLayout {
        visible: !root.customizingBar
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        rowSpacing: 12
        columnSpacing: 12

        Repeater {
            model: root.presetOptions
            delegate: Rectangle {
                required property var modelData
                readonly property bool isSel: root.selectedPreset === modelData.id

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: isSel
                    ? root.theme.bgHover
                    : (presetMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                border.color: isSel
                    ? root.theme.accentPrimary
                    : (presetMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder)
                border.width: isSel ? 2 : 1
                z: presetMouse.containsMouse ? 2 : (isSel ? 1 : 0)
                scale: presetMouse.pressed ? 0.97 : (presetMouse.containsMouse ? 1.02 : 1.0)
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: presetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.presetChosen(modelData.id)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.family: root.font
                            font.pixelSize: 22
                            color: isSel ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        Text {
                            text: modelData.title
                            font.family: root.font
                            font.pixelSize: 15
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            radius: 6
                            color: root.theme.accentPrimary
                            implicitWidth: activeLbl.implicitWidth + 12
                            implicitHeight: 20
                            opacity: isSel ? 1.0 : 0.0
                            scale: isSel ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                            Text {
                                id: activeLbl
                                anchors.centerIn: parent
                                text: "Active"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.bgBase
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData.desc
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Rectangle {
        visible: !root.customizingBar
        Layout.fillWidth: true
        height: 44
        radius: 10
        color: customMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
        border.color: customMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
        border.width: 1
        scale: customMouse.pressed ? 0.98 : (customMouse.containsMouse ? 1.01 : 1.0)
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        MouseArea {
            id: customMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.presetChosen("custom");
                root.customizingBar = true;
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰒓"
                font.family: root.font
                font.pixelSize: 16
                color: root.theme.accentPrimary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Customize myself"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }
        }
    }

    // Inline BarSettings view
    ColumnLayout {
        visible: root.customizingBar
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                radius: 8
                color: backPresetMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: backPresetMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
                border.width: 1
                implicitWidth: backPresetLbl.implicitWidth + 20
                implicitHeight: 28
                scale: backPresetMouse.pressed ? 0.96 : (backPresetMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: backPresetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.customizingBar = false
                }

                Text {
                    id: backPresetLbl
                    anchors.centerIn: parent
                    text: "Back to Presets"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }
        }

        Loader {
            active: root.customizingBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: Component {
                BarSettings {
                    theme: root.theme
                    font: root.font
                }
            }
        }
    }
}
