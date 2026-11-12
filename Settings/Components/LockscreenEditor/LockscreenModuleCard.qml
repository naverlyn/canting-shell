import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../Common"
import "../../../Lockscreen"

Rectangle {
    id: cardRoot

    property var moduleData: ({})
    property int moduleIndex: 0
    property var theme: DefaultTheme {}
    property string font: (cardRoot.theme && cardRoot.theme.fontFamily) ? cardRoot.theme.fontFamily : "Lato Nerd Font"
    property bool isExpanded: false

    signal moduleSaved(int index, var payload)
    signal moduleDeleted(int index)
    signal expandedToggled(bool expanded)

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 24
    radius: 10
    clip: true
    color: cardHover.hovered ? cardRoot.theme.bgHover : cardRoot.theme.bgSurface
    border.color: isExpanded
        ? cardRoot.theme.accentPrimary
        : (cardHover.hovered ? Qt.rgba(cardRoot.theme.accentPrimary.r, cardRoot.theme.accentPrimary.g, cardRoot.theme.accentPrimary.b, 0.4) : cardRoot.theme.bgBorder)
    border.width: isExpanded ? 1.5 : 1

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    HoverHandler { id: cardHover }

    readonly property string modType: (moduleData && moduleData.type) ? moduleData.type : "customText"
    readonly property var modDef: LockscreenConfig.getDefForType(modType)

    // Local editing state
    property bool editEnabled: moduleData && moduleData.enabled !== undefined ? moduleData.enabled : true
    property string editName: moduleData && moduleData.name ? moduleData.name : modDef.name
    property string editHalign: moduleData && moduleData.halign ? moduleData.halign : "center"
    property string editValign: moduleData && moduleData.valign ? moduleData.valign : "center"
    property int editPosX: moduleData && moduleData.position_x !== undefined ? moduleData.position_x : 0
    property int editPosY: moduleData && moduleData.position_y !== undefined ? moduleData.position_y : 0
    property string editColor: moduleData && moduleData.color ? moduleData.color : "$accent"
    property int editFontSize: moduleData && moduleData.fontSize ? moduleData.fontSize : (modType === "clock" ? 90 : 13)
    property string editClockFormat: moduleData && moduleData.clockFormat ? moduleData.clockFormat : "24h"
    property bool editShowDate: moduleData && moduleData.showDate !== undefined ? moduleData.showDate : true
    property bool editShowCard: (moduleData && moduleData.showCard !== undefined)
        ? Boolean(moduleData.showCard)
        : (modType !== "clock" && modType !== "auth" && modType !== "customText")
    property string editDisplayMode: moduleData && moduleData.displayMode ? moduleData.displayMode : (modType === "media" ? "compact" : (modType === "notifications" ? "full" : "detailed"))
    property int editMaxVisible: moduleData && moduleData.maxVisible !== undefined ? Number(moduleData.maxVisible) : 3
    property bool editShowContent: moduleData && moduleData.showContent !== undefined ? Boolean(moduleData.showContent) : true
    property bool editHideWhenEmpty: moduleData && moduleData.hideWhenEmpty !== undefined ? Boolean(moduleData.hideWhenEmpty) : false
    property string editCmd: moduleData && moduleData.cmd ? moduleData.cmd : ""
    property string editText: moduleData && moduleData.text ? moduleData.text : ""
    property int editInterval: moduleData && moduleData.interval ? Number(moduleData.interval) : 5000

    onModuleDataChanged: {
        if (!moduleData) return;
        const nextEnabled = moduleData.enabled !== undefined ? Boolean(moduleData.enabled) : true;
        const nextName = moduleData.name ? String(moduleData.name) : modDef.name;
        const nextHalign = moduleData.halign ? String(moduleData.halign) : "center";
        const nextValign = moduleData.valign ? String(moduleData.valign) : "center";
        const nextPosX = moduleData.position_x !== undefined ? Number(moduleData.position_x) : 0;
        const nextPosY = moduleData.position_y !== undefined ? Number(moduleData.position_y) : 0;
        const nextColor = moduleData.color ? String(moduleData.color) : "$accent";
        const nextFontSize = moduleData.fontSize ? Number(moduleData.fontSize) : (modType === "clock" ? 90 : 13);
        const nextClockFormat = moduleData.clockFormat ? String(moduleData.clockFormat) : "24h";
        const nextShowDate = moduleData.showDate !== undefined ? Boolean(moduleData.showDate) : true;
        const nextShowCard = moduleData.showCard !== undefined
            ? Boolean(moduleData.showCard)
            : (modType !== "clock" && modType !== "auth" && modType !== "customText");
        const nextDisplayMode = moduleData.displayMode
            ? String(moduleData.displayMode)
            : (modType === "media" ? "compact" : (modType === "notifications" ? "full" : "detailed"));
        const nextMaxVisible = moduleData.maxVisible !== undefined ? Number(moduleData.maxVisible) : 3;
        const nextShowContent = moduleData.showContent !== undefined ? Boolean(moduleData.showContent) : true;
        const nextHideWhenEmpty = moduleData.hideWhenEmpty !== undefined ? Boolean(moduleData.hideWhenEmpty) : false;
        const nextCmd = moduleData.cmd ? String(moduleData.cmd) : "";
        const nextText = moduleData.text ? String(moduleData.text) : "";
        const nextInterval = moduleData.interval ? Number(moduleData.interval) : 5000;

        if (editEnabled !== nextEnabled) editEnabled = nextEnabled;
        if (editName !== nextName) editName = nextName;
        if (editHalign !== nextHalign) editHalign = nextHalign;
        if (editValign !== nextValign) editValign = nextValign;
        if (editPosX !== nextPosX) editPosX = nextPosX;
        if (editPosY !== nextPosY) editPosY = nextPosY;
        if (editColor !== nextColor) editColor = nextColor;
        if (editFontSize !== nextFontSize) editFontSize = nextFontSize;
        if (editClockFormat !== nextClockFormat) editClockFormat = nextClockFormat;
        if (editShowDate !== nextShowDate) editShowDate = nextShowDate;
        if (editShowCard !== nextShowCard) editShowCard = nextShowCard;
        if (editDisplayMode !== nextDisplayMode) editDisplayMode = nextDisplayMode;
        if (editMaxVisible !== nextMaxVisible) editMaxVisible = nextMaxVisible;
        if (editShowContent !== nextShowContent) editShowContent = nextShowContent;
        if (editHideWhenEmpty !== nextHideWhenEmpty) editHideWhenEmpty = nextHideWhenEmpty;
        if (editCmd !== nextCmd) editCmd = nextCmd;
        if (editText !== nextText) editText = nextText;
        if (editInterval !== nextInterval) editInterval = nextInterval;
    }

    function saveChanges() {
        let payload = {
            enabled: cardRoot.editEnabled,
            name: cardRoot.editName,
            halign: cardRoot.editHalign,
            valign: cardRoot.editValign,
            position_x: cardRoot.editPosX,
            position_y: cardRoot.editPosY,
            color: cardRoot.editColor,
            fontSize: cardRoot.editFontSize,
            clockFormat: cardRoot.editClockFormat,
            showDate: cardRoot.editShowDate,
            showCard: cardRoot.editShowCard,
            displayMode: cardRoot.editDisplayMode,
            maxVisible: cardRoot.editMaxVisible,
            showContent: cardRoot.editShowContent,
            hideWhenEmpty: cardRoot.editHideWhenEmpty,
            cmd: cardRoot.editCmd,
            text: cardRoot.editText,
            interval: cardRoot.editInterval
        };
        cardRoot.moduleSaved(cardRoot.moduleIndex, payload);
    }

    ColumnLayout {
        id: mainLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 12

        // Header Row: Text-only (Name & Description) on Left, Edit Button Only on Right
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Title & Description (No glyphs, no type tags)
            ColumnLayout {
                spacing: 3
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: cardRoot.editName
                    font.family: cardRoot.font
                    font.pixelSize: 13
                    font.bold: true
                    color: cardRoot.editEnabled ? cardRoot.theme.textPrimary : cardRoot.theme.textMuted
                }

                Text {
                    text: cardRoot.modDef.desc || (cardRoot.editHalign + ", " + cardRoot.editValign + " (" + cardRoot.editPosX + ", " + cardRoot.editPosY + ")")
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    color: cardRoot.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillWidth: true }

            // Expand / Collapse Edit Button Only
            Rectangle {
                implicitWidth: 64
                Layout.preferredWidth: 64
                height: 30
                radius: 6
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                color: cardRoot.isExpanded
                    ? cardRoot.theme.bgSelected
                    : (editBtnHover.hovered ? cardRoot.theme.bgHover : cardRoot.theme.bgBase)
                border.color: cardRoot.isExpanded || editBtnHover.hovered
                    ? cardRoot.theme.accentPrimary
                    : cardRoot.theme.bgBorder
                border.width: 1
                scale: editBtnMouse.pressed ? 0.95 : 1.0

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                HoverHandler { id: editBtnHover }

                Text {
                    id: editBtnText
                    anchors.centerIn: parent
                    text: cardRoot.isExpanded ? "Close" : "Edit"
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: cardRoot.isExpanded ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: editBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        cardRoot.expandedToggled(!cardRoot.isExpanded);
                    }
                }
            }
        }

        // Expanded Configuration Body
        ColumnLayout {
            visible: cardRoot.isExpanded
            Layout.fillWidth: true
            spacing: 12
            Layout.topMargin: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: cardRoot.theme.bgBorder
            }

            // Horizontal Alignment
            PreferenceRow {
                title: "Horizontal Alignment"
                subtitle: "Anchor module to screen left, center, or right"

                Rectangle {
                    id: hAlignSegmentTrack
                    width: 240
                    height: 32
                    radius: 7
                    color: cardRoot.theme.bgBase
                    border.color: cardRoot.theme.bgBorder
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var modes: [
                        { label: "Left", value: "left" },
                        { label: "Center", value: "center" },
                        { label: "Right", value: "right" }
                    ]

                    readonly property int activeIdx: cardRoot.editHalign === "center" ? 1 : (cardRoot.editHalign === "right" ? 2 : 0)
                    readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: hAlignSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: hAlignSegmentTrack.cellWidth
                        x: 3 + Math.max(0, hAlignSegmentTrack.activeIdx) * (hAlignSegmentTrack.cellWidth + 3)
                        radius: 5
                        color: cardRoot.theme.bgSelected
                        border.color: cardRoot.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: hAlignSegmentTrack.modes
                            delegate: Rectangle {
                                id: hSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: hAlignSegmentTrack.activeIdx === index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && hSegHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: hSegHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: hSegBtn.modelData.label
                                    font.family: cardRoot.font
                                    font.pixelSize: 11
                                    font.bold: hSegBtn.isSel
                                    color: hSegBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                    opacity: hSegBtn.isSel || hSegHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: hSegMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cardRoot.editHalign = hSegBtn.modelData.value;
                                        cardRoot.saveChanges();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Vertical Alignment
            PreferenceRow {
                title: "Vertical Alignment"
                subtitle: "Anchor module to screen top, center, or bottom"

                Rectangle {
                    id: vAlignSegmentTrack
                    width: 240
                    height: 32
                    radius: 7
                    color: cardRoot.theme.bgBase
                    border.color: cardRoot.theme.bgBorder
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var modes: [
                        { label: "Top", value: "top" },
                        { label: "Center", value: "center" },
                        { label: "Bottom", value: "bottom" }
                    ]

                    readonly property int activeIdx: cardRoot.editValign === "center" ? 1 : (cardRoot.editValign === "bottom" ? 2 : 0)
                    readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: vAlignSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: vAlignSegmentTrack.cellWidth
                        x: 3 + Math.max(0, vAlignSegmentTrack.activeIdx) * (vAlignSegmentTrack.cellWidth + 3)
                        radius: 5
                        color: cardRoot.theme.bgSelected
                        border.color: cardRoot.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: vAlignSegmentTrack.modes
                            delegate: Rectangle {
                                id: vSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: vAlignSegmentTrack.activeIdx === index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && vSegHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: vSegHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: vSegBtn.modelData.label
                                    font.family: cardRoot.font
                                    font.pixelSize: 11
                                    font.bold: vSegBtn.isSel
                                    color: vSegBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                    opacity: vSegBtn.isSel || vSegHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: vSegMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cardRoot.editValign = vSegBtn.modelData.value;
                                        cardRoot.saveChanges();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Offset X Slider
            PreferenceSlider {
                title: "Horizontal Offset (X)"
                subtitle: "Pixel offset from anchor edge or screen center"
                minVal: -600
                maxVal: 600
                unit: "px"
                currentVal: cardRoot.editPosX
                onValueChanged: (val) => {
                    cardRoot.editPosX = val;
                    cardRoot.saveChanges();
                }
            }

            // Offset Y Slider
            PreferenceSlider {
                title: "Vertical Offset (Y)"
                subtitle: "Pixel offset from anchor edge or screen center"
                minVal: -400
                maxVal: 400
                unit: "px"
                currentVal: cardRoot.editPosY
                onValueChanged: (val) => {
                    cardRoot.editPosY = val;
                    cardRoot.saveChanges();
                }
            }

            // Card Background Toggle (available for all visual modules)
            PreferenceRow {
                visible: cardRoot.modType !== "auth"
                title: "Show Card Background"
                subtitle: "Wrap module in a frosted surface card with border"
                SwitchToggle {
                    checked: cardRoot.editShowCard
                    onToggled: (st) => {
                        cardRoot.editShowCard = st;
                        cardRoot.saveChanges();
                    }
                }
            }

            // Weather specific options
            ColumnLayout {
                visible: cardRoot.modType === "weather"
                Layout.fillWidth: true
                spacing: 8

                PreferenceRow {
                    title: "Weather Layout Style"
                    subtitle: "Choose between single-line compact badge or detailed multi-line view"

                    Rectangle {
                        id: weatherLayoutSegmentTrack
                        width: 200
                        height: 32
                        radius: 7
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        readonly property var modes: [
                            { label: "Compact", value: "compact" },
                            { label: "Detailed", value: "detailed" }
                        ]

                        readonly property int activeIdx: cardRoot.editDisplayMode === "compact" ? 0 : 1
                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        Rectangle {
                            visible: weatherLayoutSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: weatherLayoutSegmentTrack.cellWidth
                            x: 3 + Math.max(0, weatherLayoutSegmentTrack.activeIdx) * (weatherLayoutSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: cardRoot.theme.bgSelected
                            border.color: cardRoot.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: weatherLayoutSegmentTrack.modes
                                delegate: Rectangle {
                                    id: wSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: weatherLayoutSegmentTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && wSegHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: wSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: wSegBtn.modelData.label
                                        font.family: cardRoot.font
                                        font.pixelSize: 11
                                        font.bold: wSegBtn.isSel
                                        color: wSegBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                        opacity: wSegBtn.isSel || wSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cardRoot.editDisplayMode = wSegBtn.modelData.value;
                                            cardRoot.saveChanges();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Clock specific options
            ColumnLayout {
                visible: cardRoot.modType === "clock"
                Layout.fillWidth: true
                spacing: 8

                // Time Format (12-Hour / 24-Hour)
                PreferenceRow {
                    title: "Time Format"
                    subtitle: "12-Hour AM/PM or 24-Hour standard format"

                    Rectangle {
                        id: timeFormatSegmentTrack
                        width: 200
                        height: 32
                        radius: 7
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        readonly property var modes: [
                            { label: "12-Hour", value: "12h" },
                            { label: "24-Hour", value: "24h" }
                        ]

                        readonly property int activeIdx: cardRoot.editClockFormat === "24h" ? 1 : 0
                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        /* Sliding Selection Pill (Matching SettingSliderRow / Image 4) */
                        Rectangle {
                            visible: timeFormatSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: timeFormatSegmentTrack.cellWidth
                            x: 3 + Math.max(0, timeFormatSegmentTrack.activeIdx) * (timeFormatSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: cardRoot.theme.bgSelected
                            border.color: cardRoot.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: timeFormatSegmentTrack.modes
                                delegate: Rectangle {
                                    id: tfBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: timeFormatSegmentTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && tfHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: tfHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: tfBtn.modelData.label
                                        font.family: cardRoot.font
                                        font.pixelSize: 11
                                        font.bold: tfBtn.isSel
                                        color: tfBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                        opacity: tfBtn.isSel || tfHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: tfMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cardRoot.editClockFormat = tfBtn.modelData.value;
                                            cardRoot.saveChanges();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PreferenceSlider {
                    title: "Clock Font Size"
                    subtitle: "Pixel size of the main digital clock text"
                    minVal: 40
                    maxVal: 140
                    unit: "px"
                    currentVal: cardRoot.editFontSize
                    onValueChanged: (val) => {
                        cardRoot.editFontSize = val;
                        cardRoot.saveChanges();
                    }
                }

                PreferenceRow {
                    title: "Show Date"
                    subtitle: "Display full date under the clock"
                    SwitchToggle {
                        checked: cardRoot.editShowDate
                        onToggled: (st) => {
                            cardRoot.editShowDate = st;
                            cardRoot.saveChanges();
                        }
                    }
                }
            }

            // Media Player specific options
            ColumnLayout {
                visible: cardRoot.modType === "media"
                Layout.fillWidth: true
                spacing: 8

                PreferenceRow {
                    title: "Player Layout Style"
                    subtitle: "Choose between compact horizontal pill or full detailed card"

                    Rectangle {
                        id: mediaLayoutSegmentTrack
                        width: 200
                        height: 32
                        radius: 7
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        readonly property var modes: [
                            { label: "Compact", value: "compact" },
                            { label: "Full", value: "full" }
                        ]

                        readonly property int activeIdx: cardRoot.editDisplayMode === "full" ? 1 : 0
                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        /* Sliding Selection Pill (Matching SettingSliderRow / Image 4) */
                        Rectangle {
                            visible: mediaLayoutSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: mediaLayoutSegmentTrack.cellWidth
                            x: 3 + Math.max(0, mediaLayoutSegmentTrack.activeIdx) * (mediaLayoutSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: cardRoot.theme.bgSelected
                            border.color: cardRoot.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: mediaLayoutSegmentTrack.modes
                                delegate: Rectangle {
                                    id: mSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: mediaLayoutSegmentTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && mSegHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: mSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: mSegBtn.modelData.label
                                        font.family: cardRoot.font
                                        font.pixelSize: 11
                                        font.bold: mSegBtn.isSel
                                        color: mSegBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                        opacity: mSegBtn.isSel || mSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: mSegMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cardRoot.editDisplayMode = mSegBtn.modelData.value;
                                            cardRoot.saveChanges();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Notifications specific options
            ColumnLayout {
                visible: cardRoot.modType === "notifications" || cardRoot.modType === "notification"
                Layout.fillWidth: true
                spacing: 8

                PreferenceRow {
                    title: "Notification Layout Style"
                    subtitle: "Choose between compact single-line pill or stacked notification list"

                    Rectangle {
                        id: notifLayoutSegmentTrack
                        width: 200
                        height: 32
                        radius: 7
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        readonly property var modes: [
                            { label: "Compact", value: "compact" },
                            { label: "Stack", value: "full" }
                        ]

                        readonly property int activeIdx: cardRoot.editDisplayMode === "compact" ? 0 : 1
                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        Rectangle {
                            visible: notifLayoutSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: notifLayoutSegmentTrack.cellWidth
                            x: 3 + Math.max(0, notifLayoutSegmentTrack.activeIdx) * (notifLayoutSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: cardRoot.theme.bgSelected
                            border.color: cardRoot.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: notifLayoutSegmentTrack.modes
                                delegate: Rectangle {
                                    id: nSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: notifLayoutSegmentTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && nSegHover.hovered ? cardRoot.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: nSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: nSegBtn.modelData.label
                                        font.family: cardRoot.font
                                        font.pixelSize: 11
                                        font.bold: nSegBtn.isSel
                                        color: nSegBtn.isSel ? cardRoot.theme.accentPrimary : cardRoot.theme.textPrimary
                                        opacity: nSegBtn.isSel || nSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cardRoot.editDisplayMode = nSegBtn.modelData.value;
                                            cardRoot.saveChanges();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PreferenceSlider {
                    visible: cardRoot.editDisplayMode !== "compact"
                    title: "Max Visible Notifications"
                    subtitle: "Maximum number of notification cards shown in the stack"
                    minVal: 1
                    maxVal: 6
                    unit: ""
                    currentVal: cardRoot.editMaxVisible
                    onValueChanged: (val) => {
                        cardRoot.editMaxVisible = val;
                        cardRoot.saveChanges();
                    }
                }

                PreferenceRow {
                    title: "Show Message Content"
                    subtitle: "Display notification title and body text (disable to redact content while locked)"
                    SwitchToggle {
                        checked: cardRoot.editShowContent
                        onToggled: (st) => {
                            cardRoot.editShowContent = st;
                            cardRoot.saveChanges();
                        }
                    }
                }

                PreferenceRow {
                    title: "Hide When Empty"
                    subtitle: "Hide notification card on lock screen when there are no active notifications"
                    SwitchToggle {
                        checked: cardRoot.editHideWhenEmpty
                        onToggled: (st) => {
                            cardRoot.editHideWhenEmpty = st;
                            cardRoot.saveChanges();
                        }
                    }
                }
            }

            // Custom Text / Script options
            ColumnLayout {
                visible: cardRoot.modType === "customText"
                Layout.fillWidth: true
                spacing: 8

                PreferenceRow {
                    title: "Custom Text Label"
                    subtitle: "Static text rendered if shell command is empty"
                    Rectangle {
                        width: 240
                        height: 30
                        radius: 6
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        TextInput {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: cardRoot.editText
                            font.family: cardRoot.font
                            font.pixelSize: 11
                            color: cardRoot.theme.textPrimary
                            onEditingFinished: {
                                cardRoot.editText = text;
                                cardRoot.saveChanges();
                            }
                        }
                    }
                }

                PreferenceRow {
                    title: "Shell Command"
                    subtitle: "Script executed periodically (e.g. date +%A, uptime -p, echo 'Hello')"
                    Rectangle {
                        width: 240
                        height: 30
                        radius: 6
                        color: cardRoot.theme.bgBase
                        border.color: cardRoot.theme.bgBorder
                        border.width: 1

                        TextInput {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: cardRoot.editCmd
                            font.family: cardRoot.font
                            font.pixelSize: 11
                            color: cardRoot.theme.textPrimary
                            onEditingFinished: {
                                cardRoot.editCmd = text;
                                cardRoot.saveChanges();
                            }
                        }
                    }
                }

                PreferenceSlider {
                    title: "Update Interval"
                    subtitle: "How often to execute the shell command"
                    minVal: 1
                    maxVal: 60
                    unit: "s"
                    currentVal: Math.round(cardRoot.editInterval / 1000)
                    onValueChanged: (val) => {
                        cardRoot.editInterval = val * 1000;
                        cardRoot.saveChanges();
                    }
                }

                PreferenceSlider {
                    title: "Font Size"
                    subtitle: "Pixel size of custom text readout"
                    minVal: 9
                    maxVal: 48
                    unit: "px"
                    currentVal: cardRoot.editFontSize
                    onValueChanged: (val) => {
                        cardRoot.editFontSize = val;
                        cardRoot.saveChanges();
                    }
                }
            }

            // Bottom Actions: Delete
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: delTxt.implicitWidth + 24
                    height: 30
                    radius: 6
                    color: delHover.hovered ? Qt.rgba(cardRoot.theme.accentRed.r, cardRoot.theme.accentRed.g, cardRoot.theme.accentRed.b, 0.18) : cardRoot.theme.bgBase
                    border.color: delHover.hovered ? cardRoot.theme.accentRed : cardRoot.theme.bgBorder
                    border.width: 1
                    scale: delMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: delHover }

                    Text {
                        id: delTxt
                        anchors.centerIn: parent
                        text: "Delete Module"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: delHover.hovered ? cardRoot.theme.accentRed : cardRoot.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.moduleDeleted(cardRoot.moduleIndex)
                    }
                }
            }
        }
    }
}

