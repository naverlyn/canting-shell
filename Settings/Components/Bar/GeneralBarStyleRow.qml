import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: styleRow

    Layout.fillWidth: true
    height: 58

    readonly property bool isEditingSecondary: root.generalTab.isEditingSecondary
    readonly property string currentStyle: {
        if (root.generalTab.curDashed) return "dashed";
        if (root.generalTab.curFloating) return "floating";
        return "docked";
    }

    function applyBarStyle(styleKey) {
        const floatProp = isEditingSecondary ? "secondaryFloating" : "floating";
        const dashProp = isEditingSecondary ? "secondaryDashed" : "dashed";

        if (styleKey === "dashed") {
            BarConfig.updateBarProp(floatProp, false);
            BarConfig.updateBarProp(dashProp, true);
            return;
        }

        BarConfig.updateBarProp(dashProp, false);
        BarConfig.updateBarProp(floatProp, styleKey === "floating");
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            Text {
                text: {
                    const cur = BarConfig.currentBar;
                    const tgt = cur ? (cur.displayTarget || (cur.allMonitors ? "all" : "primary")) : "primary";
                    if (tgt === "all" && root.hasMultipleMonitors) {
                        return BarConfig.activeEditingDisplay === "secondary" ? "Bar Style (Secondary)" : "Bar Style (Primary)";
                    }
                    return "Bar Style";
                }
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Choose between docked, floating, or dashed bar appearance"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        AppDropdown {
            id: barStyleDropdown
            theme: root.theme
            font: root.font
            implicitWidth: 200
            menuWidth: 200
            currentValue: styleRow.currentStyle
            options: [
                {
                    desktop: "docked",
                    name: "Docked",
                    desc: ""
                },
                {
                    desktop: "floating",
                    name: "Floating",
                    desc: ""
                },
                {
                    desktop: "dashed",
                    name: "Dashed",
                    desc: ""
                }
            ]
            onSelected: (val) => styleRow.applyBarStyle(val)
        }
    }
}
