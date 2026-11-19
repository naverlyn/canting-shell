import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

SectionCard {
    required property var root
    title: "Factory Defaults"
    subtitle: "Reset components to clean defaults (saves a safety backup first)"
    contentMargins: 4
    contentSpacing: 0

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
