import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../Common"
import "../../../Lockscreen"
import "../../../ThemeSwitcher"

Rectangle {
    id: cardRoot

    property var moduleData: ({})
    property int moduleIndex: 0
    property var theme: Theme
    property string font: (cardRoot.theme && cardRoot.theme.fontFamily) ? cardRoot.theme.fontFamily : "Lato Nerd Font"
    property bool isExpanded: false

    signal moduleSaved(int index, var payload)
    signal moduleDeleted(int index)
    signal expandedToggled(bool expanded)

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 16
    radius: 12
    clip: true
    color: (!isExpanded && cardHover.hovered) ? cardRoot.theme.bgHover : cardRoot.theme.bgSurface
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
    property bool editShowSeconds: moduleData && moduleData.showSeconds !== undefined ? Boolean(moduleData.showSeconds) : false
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
        const nextShowSeconds = moduleData.showSeconds !== undefined ? Boolean(moduleData.showSeconds) : false;
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
        if (editShowSeconds !== nextShowSeconds) editShowSeconds = nextShowSeconds;
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
            showSeconds: cardRoot.editShowSeconds,
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
            margins: 8
        }
        spacing: 0

        // Header Row: Name on Left, Edit/Close Button on Right
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.preferredHeight: 40
            spacing: 12

            Text {
                text: cardRoot.editName
                font.family: cardRoot.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: cardRoot.editEnabled ? cardRoot.theme.textPrimary : cardRoot.theme.textMuted
                Layout.alignment: Qt.AlignVCenter
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
                    font.pixelSize: Style.px(11)
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
            spacing: 0

            RowDivider {}

            // Horizontal Alignment
            PreferenceRow {
                title: "Horizontal Alignment"

                Rectangle {
                    id: hAlignSegmentTrack
                    width: 280
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
                                    font.pixelSize: Style.px(11)
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

            RowDivider {}

            // Vertical Alignment
            PreferenceRow {
                title: "Vertical Alignment"

                Rectangle {
                    id: vAlignSegmentTrack
                    width: 280
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
                                    font.pixelSize: Style.px(11)
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

            RowDivider {}

            // Offset X Slider
            SettingSliderRow {
                title: "Horizontal Offset (X)"
                minVal: -600
                maxVal: 600
                unit: "px"
                value: cardRoot.editPosX
                onValueModified: (val) => {
                    cardRoot.editPosX = val;
                    cardRoot.saveChanges();
                }
            }

            RowDivider {}

            // Offset Y Slider
            SettingSliderRow {
                title: "Vertical Offset (Y)"
                minVal: -400
                maxVal: 400
                unit: "px"
                value: cardRoot.editPosY
                onValueModified: (val) => {
                    cardRoot.editPosY = val;
                    cardRoot.saveChanges();
                }
            }

            RowDivider { visible: cardRoot.modType !== "auth" }

            // Card Background Toggle (available for all visual modules)
            SettingToggleRow {
                visible: cardRoot.modType !== "auth"
                title: "Show Card Background"
                checked: cardRoot.editShowCard
                onToggled: (st) => {
                    cardRoot.editShowCard = st;
                    cardRoot.saveChanges();
                }
            }

            RowDivider {}

            LockscreenModuleTypeOptions {
                hostCard: cardRoot
            }

            RowDivider {}

            // Bottom Actions: Delete
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 8
                Layout.bottomMargin: 4
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
                        font.pixelSize: Style.px(11)
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

