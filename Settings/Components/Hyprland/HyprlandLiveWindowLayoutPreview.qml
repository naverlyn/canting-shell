import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    id: layoutPreviewRoot
    required property var root
    visible: root.currentSubTab === 0
    Layout.fillWidth: true
    spacing: 16

    /* Interactive Live Preview Canvas */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Live Window Layout Preview"
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
            implicitHeight: innerCol1.implicitHeight + 12 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 12
                Rectangle {
                    Layout.fillWidth: true
                    height: 140
                    radius: 8
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1
                    clip: true

                    // Monitor outer bezel simulation
                    Item {
                        id: previewMonitorArea
                        anchors.fill: parent

                        property real animGapsOut: Math.max(4, root.generalGapsOut * 1.2)
                        property real animGapsIn: Math.max(2, root.generalGapsIn * 1.2)
                        property real animRounding: Math.min(18, root.decorRounding)
                        property real animBorderSize: Math.max(1, root.generalBorderSize)
                        property real animInactiveOpacity: root.decorInactiveOpacity
                        property color activeBorderCol: root.borderThemeSync ? root.theme.accentPrimary : (root.activeBorderCol1 || root.theme.accentPrimary)
                        property color inactiveBorderCol: root.borderThemeSync ? root.theme.bgBorder : (root.inactiveBorderCol || root.theme.bgBorder)

                        Behavior on animGapsOut { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on animGapsIn { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on animRounding { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on animBorderSize { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on animInactiveOpacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on activeBorderCol { ColorAnimation { duration: 180 } }
                        Behavior on inactiveBorderCol { ColorAnimation { duration: 180 } }

                        anchors.margins: animGapsOut

                        // 1. Dwindle or Master layout
                        RowLayout {
                            opacity: (root.generalLayout === "dwindle" || root.generalLayout === "master") ? 1.0 : 0.0
                            visible: opacity > 0
                            anchors.fill: parent
                            spacing: previewMonitorArea.animGapsIn

                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            // Primary / Master Window
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: previewMonitorArea.animRounding
                                color: root.theme.bgSelected
                                border.color: previewMonitorArea.activeBorderCol
                                border.width: previewMonitorArea.animBorderSize

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: root.generalLayout === "master" ? "󰕰 Master Window" : "󰕮 Primary Window"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: previewMonitorArea.activeBorderCol
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: root.generalLayout.toUpperCase() + " | Active"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textSecondary
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            // Secondary Stack
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: previewMonitorArea.animGapsIn

                                // Window 2
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSurface
                                    border.color: previewMonitorArea.inactiveBorderCol
                                    border.width: previewMonitorArea.animBorderSize
                                    opacity: previewMonitorArea.animInactiveOpacity

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Window 2"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }

                                // Window 3
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSurface
                                    border.color: previewMonitorArea.inactiveBorderCol
                                    border.width: previewMonitorArea.animBorderSize
                                    opacity: previewMonitorArea.animInactiveOpacity

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Window 3"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }
                            }
                        }

                        // 2. Scrolling strip layout
                        RowLayout {
                            opacity: root.generalLayout === "scrolling" ? 1.0 : 0.0
                            visible: opacity > 0
                            anchors.fill: parent
                            spacing: previewMonitorArea.animGapsIn

                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: previewMonitorArea.animRounding
                                color: root.theme.bgSurface
                                border.color: previewMonitorArea.inactiveBorderCol
                                border.width: previewMonitorArea.animBorderSize
                                opacity: previewMonitorArea.animInactiveOpacity

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Column 1"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: previewMonitorArea.animRounding
                                color: root.theme.bgSelected
                                border.color: previewMonitorArea.activeBorderCol
                                border.width: previewMonitorArea.animBorderSize

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "󰍍 Active Column"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: previewMonitorArea.activeBorderCol
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: "SCROLLING STRIP"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textSecondary
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: previewMonitorArea.animRounding
                                color: root.theme.bgSurface
                                border.color: previewMonitorArea.inactiveBorderCol
                                border.width: previewMonitorArea.animBorderSize
                                opacity: previewMonitorArea.animInactiveOpacity

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Column 3"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                }
                            }
                        }

                        // 3. Monocle fullscreen / stacked layout
                        Rectangle {
                            opacity: root.generalLayout === "monocle" ? 1.0 : 0.0
                            visible: opacity > 0
                            anchors.fill: parent
                            radius: previewMonitorArea.animRounding
                            color: root.theme.bgSelected
                            border.color: previewMonitorArea.activeBorderCol
                            border.width: previewMonitorArea.animBorderSize

                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "󰍹 Focused Window (1 of 3)"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: previewMonitorArea.activeBorderCol
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "MONOCLE | Fullscreen Focused Window Stack"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    color: root.theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Window Gaps Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Spacing & Gaps"
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
            implicitHeight: innerCol2.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol2
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingSliderRow {
                    announce: true
                    title: "Inner Window Gaps"
                    value: root.generalGapsIn
                    minVal: 0
                    maxVal: 24
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "2px", val: 2 },
                        { label: "5px", val: 5 },
                        { label: "10px", val: 10 }
                    ]
                    onValueModified: (v) => {
                        root.generalGapsIn = v;
                        root.setHyprVar("general", "gaps_in", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingSliderRow {
                    announce: true
                    title: "Outer Screen Gaps"
                    value: root.generalGapsOut
                    minVal: 0
                    maxVal: 40
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "4px", val: 4 },
                        { label: "10px", val: 10 },
                        { label: "20px", val: 20 }
                    ]
                    onValueModified: (v) => {
                        root.generalGapsOut = v;
                        root.setHyprVar("general", "gaps_out", v);
                    }
                }
            }
        }
    }

    /* Window Borders & Resizing Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Borders & Sizing"
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
            implicitHeight: innerCol3.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol3
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingSliderRow {
                    announce: true
                    title: "Border Thickness"
                    value: root.generalBorderSize
                    minVal: 0
                    maxVal: 6
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "1px", val: 1 },
                        { label: "2px", val: 2 },
                        { label: "3px", val: 3 }
                    ]
                    onValueModified: (v) => {
                        root.generalBorderSize = v;
                        root.setHyprVar("general", "border_size", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingToggleRow {
                    announce: true
                    title: "Resize On Border"
                    checked: root.generalResizeOnBorder
                    onToggled: (val) => {
                        root.generalResizeOnBorder = val;
                        root.setHyprVar("general", "resize_on_border", val);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingToggleRow {
                    announce: true
                    title: "Allow Screen Tearing"
                    checked: root.generalAllowTearing
                    onToggled: (val) => {
                        root.generalAllowTearing = val;
                        root.setHyprVar("general", "allow_tearing", val);
                    }
                }
            }
        }
    }

    /* Window Border Colors Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Border Colors"
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
            implicitHeight: innerCol4.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol4
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingToggleRow {
                    announce: true
                    title: "Sync Borders With Theme"
                    desc: "Automatically match active and inactive borders to the current theme"
                    checked: root.borderThemeSync
                    onToggled: (val) => {
                        root.borderThemeSync = val;
                        if (val) {
                            root.activeBorderCol1 = String(root.theme.accentPrimary);
                            root.activeBorderCol2 = String(root.theme.accentCyan);
                            root.activeBorderAngle = 45;
                            root.inactiveBorderCol = String(root.theme.bgBorder);
                        }
                        root.applyBorderColors();
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                /* Live Gradient & Inactive Preview Strip */
                Item {
                    id: borderPreviewStrip
                    Layout.fillWidth: true
                    implicitHeight: 54

                    readonly property string activeCol1Hex: (root.borderThemeSync ? String(root.theme.accentPrimary) : (root.activeBorderCol1 || String(root.theme.accentPrimary))).toLowerCase()
                    readonly property string activeCol2Hex: (root.borderThemeSync ? String(root.theme.accentCyan) : (root.activeBorderCol2 || String(root.theme.accentCyan))).toLowerCase()
                    readonly property string inactiveColHex: (root.borderThemeSync ? String(root.theme.bgBorder) : (root.inactiveBorderCol || String(root.theme.bgBorder))).toLowerCase()
                    readonly property bool isSolidActive: activeCol1Hex === activeCol2Hex

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: "Border Preview"
                            font.family: Style.font
                            font.pixelSize: Style.px(12)
                            font.bold: Style.boldHeadings
                            font.letterSpacing: Style.letterSpacing
                            font.hintingPreference: Style.fontHintingEnum
                            antialiasing: Style.fontAntialiasing
                            renderType: Style.fontRenderTypeEnum
                            color: Style.theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        /* Active Gradient Bar */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignVCenter
                            radius: 8
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            border.width: 1

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: borderPreviewStrip.activeCol1Hex
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                GradientStop {
                                    position: 1.0
                                    color: borderPreviewStrip.activeCol2Hex
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(gradientBadgeText.implicitWidth + 18, parent.width - 12)
                                height: 20
                                radius: 5
                                color: Qt.rgba(0, 0, 0, 0.48)
                                border.color: Qt.rgba(1, 1, 1, 0.14)
                                border.width: 1

                                Text {
                                    id: gradientBadgeText
                                    anchors.centerIn: parent
                                    width: Math.min(implicitWidth, parent.width - 10)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: borderPreviewStrip.isSolidActive
                                          ? (borderPreviewStrip.activeCol1Hex + "  ·  Solid")
                                          : (borderPreviewStrip.activeCol1Hex + " → " + borderPreviewStrip.activeCol2Hex + "  ·  " + root.activeBorderAngle + "°")
                                    font.family: Style.monoFont
                                    font.pixelSize: Style.px(10)
                                    font.bold: true
                                    font.hintingPreference: Style.fontHintingEnum
                                    renderType: Style.fontRenderTypeEnum
                                    color: "#ffffff"
                                }
                            }
                        }

                        /* Inactive Border Preview Chip */
                        Rectangle {
                            Layout.preferredWidth: Math.max(132, inactiveChipRow.implicitWidth + 20)
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignVCenter
                            radius: 8
                            color: Style.theme.bgBase
                            border.color: borderPreviewStrip.inactiveColHex
                            border.width: 2

                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            RowLayout {
                                id: inactiveChipRow
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    Layout.preferredWidth: 10
                                    Layout.preferredHeight: 10
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 5
                                    color: borderPreviewStrip.inactiveColHex
                                    border.color: Qt.rgba(1, 1, 1, 0.25)
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                Text {
                                    text: "Inactive"
                                    font.family: Style.font
                                    font.pixelSize: Style.px(11)
                                    font.bold: Style.boldHeadings
                                    font.letterSpacing: Style.letterSpacing
                                    font.hintingPreference: Style.fontHintingEnum
                                    antialiasing: Style.fontAntialiasing
                                    renderType: Style.fontRenderTypeEnum
                                    color: Style.theme.textPrimary
                                }

                                Text {
                                    text: borderPreviewStrip.inactiveColHex
                                    font.family: Style.monoFont
                                    font.pixelSize: Style.px(10)
                                    font.hintingPreference: Style.fontHintingEnum
                                    renderType: Style.fontRenderTypeEnum
                                    color: Style.theme.textSecondary
                                }
                            }
                        }
                    }
                }

                AnimatedSection {
                    expanded: !root.borderThemeSync

                    RowDivider { sideMargin: 0; alpha: 1.0 }

                    /* Active Primary Color Row */
                    HyprlandBorderColorPickerRow {
                        root: layoutPreviewRoot.root
                        title: "Active Border Primary Color"
                        subtitle: "Start color of the focused window border gradient"
                        colorValue: root.activeBorderCol1
                        fallbackColor: String(root.theme.accentPrimary)
                        onColorSelected: hex => {
                            root.activeBorderCol1 = hex;
                            root.applyBorderColors();
                        }
                    }

                    RowDivider { sideMargin: 0; alpha: 1.0 }

                    /* Active Secondary Color Row */
                    HyprlandBorderColorPickerRow {
                        root: layoutPreviewRoot.root
                        title: "Active Border Secondary Color"
                        subtitle: "End color of the focused window border gradient (match primary for solid)"
                        colorValue: root.activeBorderCol2
                        fallbackColor: String(root.theme.accentCyan)
                        onColorSelected: hex => {
                            root.activeBorderCol2 = hex;
                            root.applyBorderColors();
                        }
                    }

                    RowDivider { sideMargin: 0; alpha: 1.0 }

                    /* Gradient Angle Row */
                    SettingSliderRow {
                        announce: true
                        title: "Gradient Angle"
                        desc: "Direction of the active window border color gradient"
                        value: root.activeBorderAngle
                        minVal: 0
                        maxVal: 360
                        unit: "°"
                        presets: [
                            { label: "0°", val: 0 },
                            { label: "45°", val: 45 },
                            { label: "90°", val: 90 },
                            { label: "135°", val: 135 }
                        ]
                        onValueModified: (v) => {
                            root.activeBorderAngle = Math.round(v);
                            root.applyBorderColors();
                        }
                    }

                    RowDivider { sideMargin: 0; alpha: 1.0 }

                    /* Inactive Border Color Row */
                    HyprlandBorderColorPickerRow {
                        root: layoutPreviewRoot.root
                        title: "Inactive Window Border Color"
                        subtitle: "Outline color for unfocused background windows"
                        colorValue: root.inactiveBorderCol
                        fallbackColor: String(root.theme.bgBorder)
                        swatches: root.inactiveColorSwatches
                        onColorSelected: hex => {
                            root.inactiveBorderCol = hex;
                            root.applyBorderColors();
                        }
                    }
                }
            }
        }
    }

    /* Layout & Snapping Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Tiling Engine & Snapping"
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
            implicitHeight: innerCol5.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol5
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    height: 54

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
                                text: "Layout Engine"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "Select default tiling layout algorithm"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AppDropdown {
                            theme: root.theme
                            font: root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            options: [
                                { desktop: "dwindle",   name: "Dwindle",   desc: "" },
                                { desktop: "master",    name: "Master",    desc: "" },
                                { desktop: "scrolling", name: "Scrolling", desc: "" },
                                { desktop: "monocle",   name: "Monocle",   desc: "" }
                            ]
                            currentValue: root.generalLayout
                            onSelected: (val, opt) => {
                                root.generalLayout = val;
                                root.setHyprVar("general", "layout", val);
                                root.showToast("Layout engine set to " + (opt ? opt.name : val));
                            }
                        }
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingToggleRow {
                    announce: true
                    title: "Floating Window Snapping"
                    checked: root.generalSnapEnabled
                    onToggled: (val) => {
                        root.generalSnapEnabled = val;
                        root.setHyprVar("general.snap", "enabled", val);
                    }
                }
            }
        }
    }
}
