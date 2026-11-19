import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: frameSection
    readonly property var barState: {
        void BarConfig.panelsRevision;
        const list = BarConfig.bars || [];
        let anyDocked = false;
        for (let i = 0; i < list.length; i++) {
            const b = list[i];
            if (!b || b.enabled === false) continue;
            if (!Boolean(b.floating) && !Boolean(b.dashed)) {
                anyDocked = true;
                break;
            }
            const bTgt = b.displayTarget || (b.allMonitors ? "all" : "primary");
            if (bTgt === "all") {
                const secFlt = (b.secondaryFloating !== undefined ? Boolean(b.secondaryFloating) : Boolean(b.floating))
                    || (b.secondaryDashed !== undefined ? Boolean(b.secondaryDashed) : Boolean(b.dashed));
                if (!secFlt) {
                    anyDocked = true;
                    break;
                }
            }
        }
        return { hasAnyDocked: anyDocked };
    }
    readonly property bool cornerOrShadowDisabled: !barState.hasAnyDocked && !Boolean(BarConfig.screenBorder)
    readonly property string noEdgeReason: "Requires at least one docked bar or Framed Screen Border"
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Screen Frame & Corners (Global)"
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
        implicitHeight: innerCol.implicitHeight + 8 * 2
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
                margins: 8
            }
            spacing: 0
            SettingToggleRow {
                title: "Inner Corners"
                desc: frameSection.cornerOrShadowDisabled ? frameSection.noEdgeReason : ""
                checked: Boolean(BarConfig.innerCorners) && !frameSection.cornerOrShadowDisabled
                rowEnabled: !frameSection.cornerOrShadowDisabled
                onToggled: (val) => BarConfig.setInnerCorners(val)
            }

            RowDivider {}

            SettingToggleRow {
                title: "Framed Screen Border"
                checked: Boolean(BarConfig.screenBorder)
                onToggled: (val) => BarConfig.setScreenBorder(val)
            }

            AnimatedSection {
                expanded: Boolean(BarConfig.screenBorder)

                RowDivider {}

                SettingSliderRow {
                    title: "Screen Border Thickness"
                    value: BarConfig.screenBorderThickness
                    minVal: 1
                    maxVal: 32
                    step: 1
                    unit: "px"
                    presets: [
                        { label: "2px", val: 2 },
                        { label: "4px", val: 4 },
                        { label: "8px", val: 8 },
                        { label: "16px", val: 16 }
                    ]
                    onValueModified: (val) => BarConfig.setScreenBorderThickness(val)
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Screen Border Inner Corners"
                    checked: Boolean(BarConfig.screenBorderCorners)
                    onToggled: (val) => BarConfig.setScreenBorderCorners(val)
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Inner Shadow"
                desc: frameSection.cornerOrShadowDisabled ? frameSection.noEdgeReason : ""
                checked: Boolean(BarConfig.screenBorderShadow) && !frameSection.cornerOrShadowDisabled
                rowEnabled: !frameSection.cornerOrShadowDisabled
                onToggled: (val) => BarConfig.setScreenBorderShadow(val)
            }

            AnimatedSection {
                expanded: Boolean(BarConfig.screenBorderShadow) && !frameSection.cornerOrShadowDisabled

                RowDivider {}

                SettingSliderRow {
                    title: "Inner Shadow Size"
                    value: BarConfig.screenBorderShadowSize
                    minVal: 2
                    maxVal: 64
                    step: 1
                    unit: "px"
                    presets: [
                        { label: "4px", val: 4 },
                        { label: "8px", val: 8 },
                        { label: "12px", val: 12 },
                        { label: "16px", val: 16 },
                        { label: "24px", val: 24 }
                    ]
                    onValueModified: (val) => BarConfig.setScreenBorderShadowSize(val)
                }
            }

            RowDivider {}

            SettingSliderRow {
                title: "Frame & Corners Opacity"
                value: Math.round((BarConfig.screenFrameOpacity !== undefined ? BarConfig.screenFrameOpacity : 1.0) * 100)
                minVal: 10
                maxVal: 100
                step: 5
                unit: "%"
                presets: [
                    { label: "50%", val: 50 },
                    { label: "75%", val: 75 },
                    { label: "85%", val: 85 },
                    { label: "100%", val: 100 }
                ]
                onValueModified: (val) => BarConfig.setScreenFrameOpacity(Math.round(val) / 100)
            }
        }
    }
}
