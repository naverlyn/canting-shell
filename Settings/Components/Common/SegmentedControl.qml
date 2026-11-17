import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: segCtrl
    property var options: [] // [{ id, label }]
    property string currentId: ""
    property int trackWidth: 220
    signal optionSelected(string optionId, string optionLabel)

    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    implicitWidth: 220
    implicitHeight: 32
    width: 220
    height: 32

    AppDropdown {
        anchors.fill: parent
        theme: Style.theme
        font: Style.font
        menuWidth: 220
        currentValue: segCtrl.currentId
        options: (segCtrl.options || []).map(o => ({
            desktop: String(o.id),
            name: String(o.label),
            desc: ""
        }))
        onSelected: (val, opt) => segCtrl.optionSelected(val, opt ? opt.name : val)
    }
}
