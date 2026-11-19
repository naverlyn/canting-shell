import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Applications (AppGrid) Button Options"
    contentMargins: 8
    contentSpacing: 0

    readonly property var iconPresets: [
        { icon: "󰀻", label: "Grid" },
        { icon: "󰕮", label: "Bento" },
        { icon: "󰣇", label: "Arch" },
        { icon: "", label: "Hyprland" },
        { icon: "", label: "NixOS" },
        { icon: "", label: "Linux" },
        { icon: "󱓞", label: "Rocket" },
        { icon: "󰍜", label: "Menu" },
        { icon: "󰘳", label: "Super" }
    ]

    function detectMode() {
        const cur = BarConfig.appGridIcon || "󰀻";
        if (BarConfig.isAppGridImage(cur)) return "png";
        for (let i = 0; i < iconPresets.length; i++) {
            if (iconPresets[i].icon === cur) return "preset";
        }
        return "glyph";
    }

    function currentPresetObj() {
        const cur = BarConfig.appGridIcon || "󰀻";
        for (let i = 0; i < iconPresets.length; i++) {
            if (iconPresets[i].icon === cur) return iconPresets[i];
        }
        return null;
    }

    property string iconMode: detectMode()
    property real rowAnimProgress: 1.0

    function switchMode(newMode) {
        if (self.iconMode === newMode) return;
        self.rowAnimProgress = 0.0;
        self.iconMode = newMode;
        rowRevealAnim.restart();
    }

    NumberAnimation {
        id: rowRevealAnim
        target: self
        property: "rowAnimProgress"
        from: 0.0
        to: 1.0
        duration: 180
        easing.type: Easing.OutCubic
    }

    Connections {
        target: BarConfig
        function onAppGridIconChanged() {
            self.iconMode = self.detectMode();
        }
    }

    // 1. Mode Switcher Row
    Item {
        Layout.fillWidth: true
        height: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Icon Source"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
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
                currentValue: self.iconMode
                options: [
                    { desktop: "preset", name: "Icon Preset",  desc: "" },
                    { desktop: "glyph",  name: "Custom Glyph", desc: "" },
                    { desktop: "png",    name: "PNG Image",    desc: "" }
                ]
                onSelected: function(val) {
                    self.switchMode(val);
                }
            }
        }
    }

    RowDivider {}

    // 2A. Preset Dropdown Row
    Item {
        id: presetRow
        visible: self.iconMode === "preset"
        Layout.fillWidth: true
        height: 40
        opacity: self.rowAnimProgress
        transform: Translate { y: (1.0 - self.rowAnimProgress) * 6 }

        readonly property var activePreset: self.currentPresetObj()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Icon Preset"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                // Dropdown Button
                Rectangle {
                    id: presetDropdownBtn
                    Layout.preferredWidth: 210
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    radius: 7
                    color: presetPopup.visible
                        ? root.theme.bgSelected
                        : (dropdownHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                    border.color: presetPopup.visible
                        ? root.theme.accentPrimary
                        : (dropdownHover.hovered ? root.withAlpha(root.theme.accentPrimary, 0.5) : root.theme.bgBorder)
                    border.width: presetPopup.visible ? 1.5 : 1

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: dropdownHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: presetRow.activePreset ? presetRow.activePreset.icon : "󰀻"
                            font.family: root.font
                            font.pixelSize: 14
                            color: presetRow.activePreset ? root.theme.accentPrimary : root.theme.textMuted
                        }

                        Text {
                            text: presetRow.activePreset ? presetRow.activePreset.label : "Choose preset..."
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: presetRow.activePreset !== null
                            color: presetRow.activePreset ? root.theme.textPrimary : root.theme.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅀"
                            font.family: root.font
                            font.pixelSize: 13
                            color: presetPopup.visible ? root.theme.accentPrimary : root.theme.textSecondary
                            rotation: presetPopup.visible ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (presetPopup.visible) presetPopup.close();
                            else presetPopup.open();
                        }
                    }

                    Popup {
                        id: presetPopup
                        y: presetDropdownBtn.height + 4
                        width: presetDropdownBtn.width
                        padding: 4
                        modal: false
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                        transformOrigin: Item.Top

                        enter: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                            }
                        }

                        exit: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InCubic }
                                NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 110; easing.type: Easing.InCubic }
                            }
                        }

                        background: Rectangle {
                            radius: 8
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1
                        }

                        contentItem: ColumnLayout {
                            spacing: 2

                            Repeater {
                                model: self.iconPresets
                                delegate: Rectangle {
                                    id: presetItem
                                    required property var modelData
                                    readonly property bool isSelected: (BarConfig.appGridIcon || "󰀻") === modelData.icon
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 6
                                    color: isSelected
                                        ? root.theme.bgSelected
                                        : (itemHover.hovered ? root.theme.bgHover : "transparent")
                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    HoverHandler { id: itemHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: presetItem.modelData.icon
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: presetItem.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                        }

                                        Text {
                                            text: presetItem.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: presetItem.isSelected
                                            color: presetItem.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: presetItem.isSelected
                                            text: "✓"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            BarConfig.appGridIcon = presetItem.modelData.icon;
                                            appGridIconInput.text = presetItem.modelData.icon;
                                            BarConfig.saveConfig();
                                            presetPopup.close();
                                            root.showToast("AppGrid icon set to " + presetItem.modelData.icon + " (" + presetItem.modelData.label + ")");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset"
                    btnHeight: 32
                    btnEnabled: (BarConfig.appGridIcon || "󰀻") !== "󰀻"
                    onClicked: {
                        BarConfig.appGridIcon = "󰀻";
                        appGridIconInput.text = "󰀻";
                        BarConfig.saveConfig();
                        root.showToast("AppGrid icon reset to default (󰀻)");
                    }
                }
            }
        }
    }

    // 2B. Custom Glyph or Label Row
    Item {
        visible: self.iconMode === "glyph"
        Layout.fillWidth: true
        height: 40
        opacity: self.rowAnimProgress
        transform: Translate { y: (1.0 - self.rowAnimProgress) * 6 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Custom Glyph or Label"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Rectangle {
                    readonly property string glyphVal: appGridIconInput.text.trim() !== ""
                        ? appGridIconInput.text.trim()
                        : (!BarConfig.isAppGridImage(BarConfig.appGridIcon) ? (BarConfig.appGridIcon || "󰀻") : "󰀻")
                    implicitWidth: Math.max(32, previewGlyphTxt.implicitWidth + 16)
                    height: 32
                    radius: 7
                    color: root.withAlpha(root.theme.accentPrimary, 0.12)
                    border.color: root.withAlpha(root.theme.accentPrimary, 0.4)
                    border.width: 1

                    Text {
                        id: previewGlyphTxt
                        anchors.centerIn: parent
                        text: parent.glyphVal
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    radius: 7
                    color: root.theme.bgBase
                    border.color: appGridIconInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1
                    clip: true

                    TextInput {
                        id: appGridIconInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.textPrimary
                        selectByMouse: true
                        text: BarConfig.isAppGridImage(BarConfig.appGridIcon) ? "" : (BarConfig.appGridIcon || "󰀻")

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "Glyph / text"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textMuted
                            visible: appGridIconInput.text === "" && !appGridIconInput.activeFocus
                        }

                        Connections {
                            target: BarConfig
                            function onAppGridIconChanged() {
                                if (!appGridIconInput.activeFocus) {
                                    appGridIconInput.text = BarConfig.isAppGridImage(BarConfig.appGridIcon)
                                        ? ""
                                        : (BarConfig.appGridIcon || "󰀻");
                                }
                            }
                        }

                        function applyIcon() {
                            const val = BarConfig.normalizeAppGridIcon(text);
                            text = BarConfig.isAppGridImage(val) ? "" : val;
                            BarConfig.appGridIcon = val;
                            BarConfig.saveConfig();
                            if (BarConfig.isAppGridImage(val)) {
                                root.showToast("AppGrid icon set to PNG: " + val.split("/").pop());
                            } else {
                                root.showToast("AppGrid icon updated to: " + val);
                            }
                        }

                        onAccepted: applyIcon()
                    }
                }

                ActionButton {
                    label: "Apply"
                    btnHeight: 32
                    btnEnabled: appGridIconInput.text.trim() !== ""
                    onClicked: appGridIconInput.applyIcon()
                }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset"
                    btnHeight: 32
                    btnEnabled: (BarConfig.appGridIcon || "󰀻") !== "󰀻"
                    onClicked: {
                        BarConfig.appGridIcon = "󰀻";
                        appGridIconInput.text = "󰀻";
                        BarConfig.saveConfig();
                        root.showToast("AppGrid icon reset to default (󰀻)");
                    }
                }
            }
        }
    }

    // 2C. Custom PNG Image Row
    Item {
        id: pngRow
        visible: self.iconMode === "png"
        Layout.fillWidth: true
        height: 40
        opacity: self.rowAnimProgress
        transform: Translate { y: (1.0 - self.rowAnimProgress) * 6 }

        readonly property bool isImageActive: BarConfig.isAppGridImage(BarConfig.appGridIcon)
        readonly property string fileName: isImageActive ? String(BarConfig.appGridIcon).split("/").pop() : ""

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Custom PNG Image"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                // Active PNG Badge (Thumbnail + Filename)
                Rectangle {
                    visible: pngRow.isImageActive
                    implicitWidth: Math.min(220, pngBadgeRow.implicitWidth + 16)
                    height: 32
                    radius: 7
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1
                    clip: true

                    RowLayout {
                        id: pngBadgeRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 7

                        Image {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Layout.maximumWidth: 18
                            Layout.maximumHeight: 18
                            source: pngRow.isImageActive
                                ? BarConfig.appGridImageSource(BarConfig.appGridIcon)
                                : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }

                        Text {
                            text: pngRow.fileName
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }

                ActionButton {
                    iconText: "󰈟"
                    label: pngRow.isImageActive ? "Change PNG..." : "Choose PNG..."
                    btnHeight: 32
                    onClicked: pngPickerModal.openPicker()
                }

                ActionButton {
                    visible: pngRow.isImageActive
                    label: "Clear"
                    btnHeight: 32
                    onClicked: {
                        BarConfig.appGridIcon = "󰀻";
                        appGridIconInput.text = "󰀻";
                        BarConfig.saveConfig();
                        root.showToast("Custom PNG cleared; reverted to default glyph (󰀻)");
                    }
                }
            }
        }
    }

    FilePickerModal {
        id: pngPickerModal
        root: self.root
        title: "Select AppGrid Icon (.png)"
        extensions: [".png"]
        showThumbnails: true
        emptyText: "No folders or .png files found here"
        hintText: "Click a folder to open, or select a .png file"
        searchPlaceholder: "Filter folders or .png files..."
        onFileSelected: function(path) {
            BarConfig.appGridIcon = path;
            appGridIconInput.text = "";
            BarConfig.saveConfig();
            root.showToast("AppGrid icon set to PNG: " + path.split("/").pop());
        }
    }
}
