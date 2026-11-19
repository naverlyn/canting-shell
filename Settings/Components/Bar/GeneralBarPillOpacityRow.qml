import QtQuick
import "../../../bar"
import "../Common"

SettingSliderRow {
    required property var root

    title: "Pill Background Opacity"
    value: root.generalTab.curPillOpacity
    minVal: 0.0
    maxVal: 1.0
    step: 0.05
    isFloat: true
    unit: "%"
    visible: !root.generalTab.curHidePill
    opacity: root.generalTab.curHidePill ? 0.45 : 1.0
    enabled: !root.generalTab.curHidePill
    Behavior on opacity { NumberAnimation { duration: 150 } }
    onValueModified: (val) => BarConfig.updateBarProp("pillOpacity", val)
}
