import QtQuick
import QtQuick.Layouts
import "../../Settings/Components"

ColumnLayout {
    id: root

    required property var theme
    required property string font
    required property bool isActive

    spacing: 8

    Loader {
        active: root.isActive
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: Component {
            DefaultAppsSettings {
                theme: root.theme
                font: root.font
            }
        }
    }
}
