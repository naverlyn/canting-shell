import QtQuick
import "../../../bar"
import "../Common"

SettingSliderRow {
    required property var root

    title: "Bar Opacity"
    desc: {
        const cur = BarConfig.currentBar;
        if (!cur) return "Background transparency";
        const bName = cur.name || "Bar";
        const bPos = (cur.position || "top").toUpperCase();
        return "Transparency · " + bName + " (" + bPos + ")";
    }
    value: BarConfig.currentBar ? Number(BarConfig.currentBar.barOpacity) : BarConfig.barOpacity
    minVal: 0.1
    maxVal: 1.0
    step: 0.05
    isFloat: true
    unit: "%"
    onValueModified: (val) => BarConfig.updateBarProp("barOpacity", val)
}
