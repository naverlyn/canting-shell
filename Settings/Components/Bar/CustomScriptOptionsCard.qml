import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    readonly property bool isImageActive: BarConfig.isAppGridImage(BarConfig.customScriptIcon)
    readonly property string imageFileName: isImageActive ? String(BarConfig.customScriptIcon).split("/").pop() : ""
    function detectMode() {
        return BarConfig.isAppGridImage(BarConfig.customScriptIcon) ? "png" : "glyph";
    }
    property string iconMode: detectMode()
    property real rowAnimProgress: 1.0
    function switchMode(newMode) {
        if (self.iconMode === newMode) return;
        self.rowAnimProgress = 0.0;
        self.iconMode = newMode;
        rowRevealAnim.restart();
    }
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Custom Script Module Options"
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
                function onCustomScriptIconChanged() {
                    self.iconMode = self.detectMode();
                }
            }

            // 1. Command to Execute
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Script / Shell Command"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Rectangle {
                            width: 304
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: csCmdInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1
                            clip: true

                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            TextInput {
                                id: csCmdInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: Style.px(11)
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: BarConfig.customScriptCommand

                                function applyChange() {
                                    BarConfig.customScriptCommand = text.trim();
                                    BarConfig.customScriptRevision++;
                                    BarConfig.saveConfig();
                                    root.showToast("Custom script command updated");
                                }

                                onAccepted: applyChange()

                                Text {
                                    visible: parent.text === "" && !parent.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "e.g. uptime -p"
                                    font.family: root.font
                                    font.pixelSize: Style.px(10)
                                    color: root.theme.textMuted
                                }
                            }
                        }

                        ActionButton {
                            label: "Apply"
                            btnHeight: 32
                            minWidth: 68
                            onClicked: csCmdInput.applyChange()
                        }
                    }
                }
            }

            RowDivider {}

            // 2. Left-Click Command
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Left-Click Command"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Rectangle {
                            width: 304
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: csClickInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1
                            clip: true

                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            TextInput {
                                id: csClickInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: Style.px(11)
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: BarConfig.customScriptOnClick

                                function applyClick() {
                                    BarConfig.customScriptOnClick = text.trim();
                                    BarConfig.customScriptRevision++;
                                    BarConfig.saveConfig();
                                    root.showToast("Custom script click command updated");
                                }

                                onAccepted: applyClick()

                                Text {
                                    visible: parent.text === "" && !parent.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "On-click cmd (optional)..."
                                    font.family: root.font
                                    font.pixelSize: Style.px(10)
                                    color: root.theme.textMuted
                                }
                            }
                        }

                        ActionButton {
                            label: "Apply"
                            btnHeight: 32
                            minWidth: 68
                            onClicked: csClickInput.applyClick()
                        }
                    }
                }
            }

            RowDivider {}

            // 3. Icon Source Mode Switcher
            Item {
                Layout.fillWidth: true
                height: 44

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
                            font.pixelSize: Style.px(13)
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
                            { desktop: "glyph", name: "Custom Glyph", desc: "" },
                            { desktop: "png",   name: "PNG Image",    desc: "" }
                        ]
                        onSelected: function(val) {
                            self.switchMode(val);
                        }
                    }
                }
            }

            RowDivider {}

            // 3A. Custom Glyph / Label Row
            Item {
                id: csGlyphRow
                visible: self.iconMode === "glyph"
                Layout.fillWidth: true
                height: 44
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
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Rectangle {
                            readonly property string glyphVal: csIconInput.text.trim() !== ""
                                ? csIconInput.text.trim()
                                : (!self.isImageActive ? (BarConfig.customScriptIcon || "󰆍") : "󰆍")
                            implicitWidth: Math.max(32, csPreviewGlyphTxt.implicitWidth + 16)
                            height: 32
                            radius: 7
                            color: root.withAlpha(root.theme.accentPrimary, 0.12)
                            border.color: root.withAlpha(root.theme.accentPrimary, 0.4)
                            border.width: 1

                            Text {
                                id: csPreviewGlyphTxt
                                anchors.centerIn: parent
                                text: parent.glyphVal
                                font.family: root.font
                                font.pixelSize: Style.px(14)
                                color: root.theme.accentPrimary
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignVCenter
                            radius: 7
                            color: root.theme.bgBase
                            border.color: csIconInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1
                            clip: true

                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            TextInput {
                                id: csIconInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: Style.px(13)
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: self.isImageActive ? "" : (BarConfig.customScriptIcon || "󰆍")

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Glyph / text"
                                    font.family: root.font
                                    font.pixelSize: Style.px(11)
                                    color: root.theme.textMuted
                                    visible: csIconInput.text === "" && !csIconInput.activeFocus
                                }

                                Connections {
                                    target: BarConfig
                                    function onCustomScriptIconChanged() {
                                        if (!csIconInput.activeFocus) {
                                            csIconInput.text = self.isImageActive
                                                ? ""
                                                : (BarConfig.customScriptIcon || "󰆍");
                                        }
                                    }
                                }

                                function applyIcon() {
                                    const val = text.trim() || "󰆍";
                                    text = BarConfig.isAppGridImage(val) ? "" : val;
                                    BarConfig.customScriptIcon = val;
                                    BarConfig.customScriptRevision++;
                                    BarConfig.saveConfig();
                                    root.showToast("Custom script icon updated to: " + val);
                                }

                                onAccepted: applyIcon()
                            }
                        }

                        ActionButton {
                            label: "Apply"
                            btnHeight: 32
                            btnEnabled: csIconInput.text.trim() !== ""
                            onClicked: csIconInput.applyIcon()
                        }

                        ActionButton {
                            iconText: "󰦛"
                            label: "Reset"
                            btnHeight: 32
                            btnEnabled: (BarConfig.customScriptIcon || "󰆍") !== "󰆍"
                            onClicked: {
                                BarConfig.customScriptIcon = "󰆍";
                                csIconInput.text = "󰆍";
                                BarConfig.customScriptRevision++;
                                BarConfig.saveConfig();
                                root.showToast("Custom script icon reset to default (󰆍)");
                            }
                        }
                    }
                }
            }

            // 3B. Custom PNG Image Row
            Item {
                id: csPngRow
                visible: self.iconMode === "png"
                Layout.fillWidth: true
                height: 44
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
                            text: "Custom PNG Image"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Rectangle {
                            visible: self.isImageActive
                            implicitWidth: Math.min(220, csPngBadgeRow.implicitWidth + 16)
                            height: 32
                            radius: 7
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1
                            clip: true

                            RowLayout {
                                id: csPngBadgeRow
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    Layout.maximumWidth: 18
                                    Layout.maximumHeight: 18
                                    source: self.isImageActive
                                        ? BarConfig.appGridImageSource(BarConfig.customScriptIcon)
                                        : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    text: self.imageFileName
                                    font.family: root.font
                                    font.pixelSize: Style.px(11)
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        ActionButton {
                            iconText: "󰈟"
                            label: self.isImageActive ? "Change PNG..." : "Choose PNG..."
                            btnHeight: 32
                            onClicked: csPngPickerModal.openPicker()
                        }

                        ActionButton {
                            visible: self.isImageActive
                            label: "Clear"
                            btnHeight: 32
                            onClicked: {
                                BarConfig.customScriptIcon = "󰆍";
                                csIconInput.text = "󰆍";
                                BarConfig.customScriptRevision++;
                                BarConfig.saveConfig();
                                root.showToast("Custom PNG cleared; reverted to default glyph (󰆍)");
                            }
                        }
                    }
                }
            }

            RowDivider {}

            // 3. Poll Interval
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Execution Poll Interval"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: csIntTrack
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        implicitHeight: 32
                        height: 32
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1

                        readonly property int activeVal: Number(BarConfig.customScriptInterval || 10)
                        readonly property int activeIdx: activeVal <= 5 ? 0 : (activeVal <= 10 ? 1 : (activeVal <= 30 ? 2 : 3))
                        readonly property real cellWidth: (width - 6 - 12) / 4

                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: csIntTrack.cellWidth
                            x: 3 + csIntTrack.activeIdx * (csIntTrack.cellWidth + 4)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 4

                            Repeater {
                                model: [
                                    { label: "5s", value: 5 },
                                    { label: "10s", value: 10 },
                                    { label: "30s", value: 30 },
                                    { label: "60s", value: 60 }
                                ]
                                delegate: Rectangle {
                                    id: csIntBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: csIntTrack.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && csIntHov.hovered ? root.theme.bgHover : "transparent"
                                    HoverHandler { id: csIntHov }

                                    Text {
                                        anchors.centerIn: parent
                                        text: csIntBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: Style.px(11)
                                        font.bold: csIntBtn.isSel
                                        color: csIntBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            BarConfig.customScriptInterval = csIntBtn.modelData.value;
                                            BarConfig.customScriptRevision++;
                                            BarConfig.saveConfig();
                                            root.showToast("Custom script poll interval set to: " + csIntBtn.modelData.label);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Show Hover Popup Card"
                checked: Boolean(BarConfig.customScriptShowPopup)
                onToggled: (val) => {
                    BarConfig.customScriptShowPopup = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Custom script popup card enabled" : "Custom script popup card disabled");
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Auto-Hide When Output is Empty"
                checked: Boolean(BarConfig.customScriptHideWhenEmpty)
                onToggled: (val) => {
                    BarConfig.customScriptHideWhenEmpty = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Custom script will hide when empty" : "Custom script always visible");
                }
            }

            FilePickerModal {
                id: csPngPickerModal
                root: self.root
                title: "Select Custom Script Icon (.png)"
                extensions: [".png"]
                showThumbnails: true
                emptyText: "No folders or .png files found here"
                hintText: "Click a folder to open, or select a .png file"
                searchPlaceholder: "Filter folders or .png files..."
                onFileSelected: function(path) {
                    BarConfig.customScriptIcon = path;
                    csIconInput.text = "";
                    BarConfig.customScriptRevision++;
                    BarConfig.saveConfig();
                    root.showToast("Custom script icon set to PNG: " + path.split("/").pop());
                }
            }
        }
    }
}
