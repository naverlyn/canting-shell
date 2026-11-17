import QtQuick
import "../../../bar"
import "../Common"

SettingSliderRow {
    required property var root
<<<<<<< HEAD
    id: pillOpacityItem
    Layout.fillWidth: true
    visible: !root.generalTab.curHidePill
    height: visible ? 52 : 0
    implicitHeight: visible ? 52 : 0
    readonly property real activePillOpacity: root.generalTab.curPillOpacity
=======

    title: "Pill Background Opacity"
    desc: "Transparency of widget cards"
    value: root.generalTab.curPillOpacity
    minVal: 0.0
    maxVal: 1.0
    step: 0.05
    isFloat: true
    unit: "%"
>>>>>>> d760579 (refactor(bar-settings): reuse SettingSliderRow for opacity rows)
    opacity: root.generalTab.curHidePill ? 0.45 : 1.0
    enabled: !root.generalTab.curHidePill
    Behavior on opacity { NumberAnimation { duration: 150 } }
    onValueModified: (val) => BarConfig.updateBarProp("pillOpacity", val)
}
