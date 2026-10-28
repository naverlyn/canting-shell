import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.currentSubTab === 0
    Layout.fillWidth: true
    spacing: 16

    /* Interactive Live Preview Canvas */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Live Window Layout Preview"
        subtitle: "Simulated layout with active gaps, borders, and rounding"

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

    /* Window Gaps Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Spacing & Gaps"
        subtitle: "Inner gaps between windows & outer margins to monitor edges"

        SettingSliderRow {
            announce: true
            title: "Inner Window Gaps"
            desc: "Distance in pixels between adjacent tiled windows"
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
            desc: "Distance in pixels between windows and monitor borders"
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

    /* Window Borders & Resizing Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Borders & Sizing"
        subtitle: "Border thickness and edge interaction"

        SettingSliderRow {
            announce: true
            title: "Border Thickness"
            desc: "Width of window outline border"
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
            desc: "Enable clicking and dragging directly on window borders to resize"
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
            desc: "Master switch to allow tearing for ultra-low latency gaming"
            checked: root.generalAllowTearing
            onToggled: (val) => {
                root.generalAllowTearing = val;
                root.setHyprVar("general", "allow_tearing", val);
            }
        }
    }

    /* Window Border Colors Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Border Colors"
        subtitle: "Active gradient colors, angle, inactive border, and theme sync"

        SettingToggleRow {
            announce: true
            title: "Sync Borders With Theme"
            desc: "Automatically update active and inactive window borders when switching Quickshell themes"
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
            Layout.fillWidth: true
            height: 44

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: "Active Gradient Preview"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 22
                    radius: 6
                    border.color: root.theme.bgBorder
                    border.width: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.borderThemeSync ? root.theme.accentPrimary : (root.activeBorderCol1 || "#7aa2f7") }
                        GradientStop { position: 1.0; color: root.borderThemeSync ? root.theme.accentCyan : (root.activeBorderCol2 || "#7dcfff") }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (root.borderThemeSync ? String(root.theme.accentPrimary) : root.activeBorderCol1) +
                              "  →  " +
                              (root.borderThemeSync ? String(root.theme.accentCyan) : root.activeBorderCol2) +
                              "  (" + root.activeBorderAngle + "°)"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: "#ffffff"
                        style: Text.Outline
                        styleColor: "#80000000"
                    }
                }

                Rectangle {
                    width: 110
                    height: 22
                    radius: 6
                    color: root.borderThemeSync ? root.theme.bgBorder : (root.inactiveBorderCol || "#32364a")
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Inactive"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: !root.borderThemeSync }

        /* Active Primary Color Row */
        ColumnLayout {
            visible: !root.borderThemeSync
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: "Active Border Primary Color"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Start color of the focused window border gradient"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: root.activeBorderCol1 || "#7aa2f7"
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                }

                Rectangle {
                    width: 105
                    height: 30
                    radius: 6
                    color: root.theme.bgBase
                    border.color: col1Input.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: col1Input.activeFocus ? 2 : 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    TextInput {
                        id: col1Input
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.activeBorderCol1
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onEditingFinished: {
                            let v = text.trim();
                            if (!v.startsWith("#") && v.length === 6) v = "#" + v;
                            if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                                root.activeBorderCol1 = v.toLowerCase();
                                root.applyBorderColors();
                            }
                        }
                    }
                }
            }

            /* Segmented Color Swatch Track with Sliding Selection Pill */
            Rectangle {
                id: sw1Track
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property int count: root.borderColorSwatches.length
                readonly property int activeIdx: {
                    let cur = String(root.activeBorderCol1).toLowerCase();
                    for (let i = 0; i < root.borderColorSwatches.length; i++) {
                        if (String(root.borderColorSwatches[i].color).toLowerCase() === cur) return i;
                    }
                    return -1;
                }
                readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

                Rectangle {
                    visible: sw1Track.activeIdx >= 0
                    y: 3
                    height: parent.height - 6
                    width: sw1Track.cellWidth
                    x: 3 + Math.max(0, sw1Track.activeIdx) * (sw1Track.cellWidth + 3)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: root.borderColorSwatches
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isSel: sw1Track.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && sw1Hover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            scale: sw1Mouse.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            HoverHandler { id: sw1Hover }

                            RowLayout {
                                id: sw1Row
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: modelData.color
                                    border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                                }
                                Text {
                                    text: modelData.name
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: isSel
                                    color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: isSel || sw1Hover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: sw1Mouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeBorderCol1 = String(modelData.color).toLowerCase();
                                    root.applyBorderColors();
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: !root.borderThemeSync }

        /* Active Secondary Color Row */
        ColumnLayout {
            visible: !root.borderThemeSync
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: "Active Border Secondary Color"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "End color of the focused window border gradient (set same as primary for solid border)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: root.activeBorderCol2 || "#7dcfff"
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                }

                Rectangle {
                    width: 105
                    height: 30
                    radius: 6
                    color: root.theme.bgBase
                    border.color: col2Input.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: col2Input.activeFocus ? 2 : 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    TextInput {
                        id: col2Input
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.activeBorderCol2
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onEditingFinished: {
                            let v = text.trim();
                            if (!v.startsWith("#") && v.length === 6) v = "#" + v;
                            if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                                root.activeBorderCol2 = v.toLowerCase();
                                root.applyBorderColors();
                            }
                        }
                    }
                }
            }

            /* Segmented Color Swatch Track with Sliding Selection Pill */
            Rectangle {
                id: sw2Track
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property int count: root.borderColorSwatches.length
                readonly property int activeIdx: {
                    let cur = String(root.activeBorderCol2).toLowerCase();
                    for (let i = 0; i < root.borderColorSwatches.length; i++) {
                        if (String(root.borderColorSwatches[i].color).toLowerCase() === cur) return i;
                    }
                    return -1;
                }
                readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

                Rectangle {
                    visible: sw2Track.activeIdx >= 0
                    y: 3
                    height: parent.height - 6
                    width: sw2Track.cellWidth
                    x: 3 + Math.max(0, sw2Track.activeIdx) * (sw2Track.cellWidth + 3)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: root.borderColorSwatches
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isSel: sw2Track.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && sw2Hover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            scale: sw2Mouse.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            HoverHandler { id: sw2Hover }

                            RowLayout {
                                id: sw2Row
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: modelData.color
                                    border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                                }
                                Text {
                                    text: modelData.name
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: isSel
                                    color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: isSel || sw2Hover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: sw2Mouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeBorderCol2 = String(modelData.color).toLowerCase();
                                    root.applyBorderColors();
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: !root.borderThemeSync }

        SettingSliderRow {
            visible: !root.borderThemeSync
            announce: true
            title: "Gradient Angle"
            desc: "Rotation angle for the active window border gradient"
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
                root.activeBorderAngle = v;
                root.applyBorderColors();
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0; visible: !root.borderThemeSync }

        /* Inactive Border Color Row */
        ColumnLayout {
            visible: !root.borderThemeSync
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: "Inactive Window Border Color"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Outline color for unfocused background windows"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: root.inactiveBorderCol || "#32364a"
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                }

                Rectangle {
                    width: 105
                    height: 30
                    radius: 6
                    color: root.theme.bgBase
                    border.color: colInactInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: colInactInput.activeFocus ? 2 : 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    TextInput {
                        id: colInactInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.inactiveBorderCol
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onEditingFinished: {
                            let v = text.trim();
                            if (!v.startsWith("#") && v.length === 6) v = "#" + v;
                            if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                                root.inactiveBorderCol = v.toLowerCase();
                                root.applyBorderColors();
                            }
                        }
                    }
                }
            }

            /* Segmented Color Swatch Track with Sliding Selection Pill */
            Rectangle {
                id: swInactTrack
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property int count: root.inactiveColorSwatches.length
                readonly property int activeIdx: {
                    let cur = String(root.inactiveBorderCol).toLowerCase();
                    for (let i = 0; i < root.inactiveColorSwatches.length; i++) {
                        if (String(root.inactiveColorSwatches[i].color).toLowerCase() === cur) return i;
                    }
                    return -1;
                }
                readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

                Rectangle {
                    visible: swInactTrack.activeIdx >= 0
                    y: 3
                    height: parent.height - 6
                    width: swInactTrack.cellWidth
                    x: 3 + Math.max(0, swInactTrack.activeIdx) * (swInactTrack.cellWidth + 3)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: root.inactiveColorSwatches
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isSel: swInactTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && swInactHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            scale: swInactMouse.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            HoverHandler { id: swInactHover }

                            RowLayout {
                                id: swInactRow
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: modelData.color
                                    border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                                }
                                Text {
                                    text: modelData.name
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: isSel
                                    color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: isSel || swInactHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: swInactMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.inactiveBorderCol = String(modelData.color).toLowerCase();
                                    root.applyBorderColors();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Layout & Snapping Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Tiling Engine & Snapping"
        subtitle: "Compositor layout algorithm and floating window snapping"

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

                Rectangle {
                    id: layoutSegmentTrack
                    implicitWidth: 340
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var layouts: ["dwindle", "master", "scrolling", "monocle"]
                    readonly property int activeIdx: layouts.indexOf(root.generalLayout)
                    readonly property real cellWidth: (width - 6 - 9) / 4

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: layoutSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: layoutSegmentTrack.cellWidth
                        x: 3 + Math.max(0, layoutSegmentTrack.activeIdx) * (layoutSegmentTrack.cellWidth + 3)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: [
                                { id: "dwindle", label: "Dwindle" },
                                { id: "master", label: "Master" },
                                { id: "scrolling", label: "Scrolling" },
                                { id: "monocle", label: "Monocle" }
                            ]

                            delegate: Rectangle {
                                id: lSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: layoutSegmentTrack.activeIdx === lSegBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && lHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: lHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: lSegBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: lSegBtn.isSel
                                    color: lSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: lSegBtn.isSel || lHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.generalLayout = lSegBtn.modelData.id;
                                        root.setHyprVar("general", "layout", lSegBtn.modelData.id);
                                        root.showToast("Layout engine set to " + lSegBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Floating Window Snapping"
            desc: "Snap floating windows to adjacent window edges and monitor borders"
            checked: root.generalSnapEnabled
            onToggled: (val) => {
                root.generalSnapEnabled = val;
                root.setHyprVar("general.snap", "enabled", val);
            }
        }
    }
}
