import QtQuick
import "../../../bar"
import "../Common"

SettingSliderRow {
    required property var root

    title: "Bar Opacity"
    value: BarConfig.currentBar ? Number(BarConfig.currentBar.barOpacity) : BarConfig.barOpacity
    minVal: 0.1
    maxVal: 1.0
    step: 0.05
    isFloat: true
    unit: "%"
    onValueModified: (val) => BarConfig.updateBarProp("barOpacity", val)
}
