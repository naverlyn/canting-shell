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
    height: 40

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
        }

        Item { Layout.fillWidth: true }

        AppDropdown {
            id: barStyleDropdown
            theme: root.theme
            font: root.font
            Layout.preferredWidth: 380
            implicitWidth: 380
            menuWidth: 380
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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
