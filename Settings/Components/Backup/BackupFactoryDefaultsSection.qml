import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Factory Defaults"
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
        implicitHeight: innerCol.implicitHeight + 4 * 2
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 4
            }
            spacing: 0
            Repeater {
                model: root.resetDefs

                delegate: ColumnLayout {
                    required property var modelData
                    required property int index
                    readonly property bool isConfirming: root.confirmResetModule === modelData.id

                    Layout.fillWidth: true
                    spacing: 0

                    RowDivider { visible: index > 0 }

                    PreferenceRow {
                        title: modelData.title

                        ActionButton {
                            visible: !isConfirming
                            iconText: "󰑓"
                            label: modelData.btnLabel
                            minWidth: 104
                            danger: true
                            onClicked: root.confirmResetModule = modelData.id
                        }

                        RowLayout {
                            visible: isConfirming
                            spacing: 6

                            ActionButton {
                                label: "Cancel"
                                btnHeight: 28
                                onClicked: root.confirmResetModule = ""
                            }

                            ActionButton {
                                iconText: "󰑓"
                                label: "Confirm Reset"
                                danger: true
                                btnHeight: 28
                                onClicked: root.resetFactoryDefaults(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
