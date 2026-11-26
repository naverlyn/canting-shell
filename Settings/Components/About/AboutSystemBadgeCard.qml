import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Rectangle {
    id: badgeCard
    required property var theme
    required property string font
    required property string hostname
    required property string hostModel

    property bool editing: false
    signal hostnameSubmitted(string newHostname)

    function startEdit() {
        nameInput.text = badgeCard.hostname || "";
        badgeCard.editing = true;
        Qt.callLater(() => {
            nameInput.forceActiveFocus();
            nameInput.selectAll();
        });
    }

    function commitEdit() {
        const cleaned = nameInput.text.trim();
        badgeCard.editing = false;
        if (cleaned !== "" && cleaned !== badgeCard.hostname) {
            badgeCard.hostnameSubmitted(cleaned);
        }
    }

    function cancelEdit() {
        badgeCard.editing = false;
    }

    Layout.fillWidth: true
    height: 84
    radius: 12
    clip: true
    color: theme.bgSurface
    border.color: badgeCard.editing
        ? Style.withAlpha(theme.accentPrimary, 0.5)
        : theme.bgBorder
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    // View mode
    RowLayout {
        id: viewRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        visible: opacity > 0.01
        opacity: badgeCard.editing ? 0.0 : 1.0
        scale: badgeCard.editing ? 0.98 : 1.0
        transform: Translate {
            y: badgeCard.editing ? -6 : 0
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            spacing: 10
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: badgeCard.hostname !== "" ? badgeCard.hostname : "localhost"
                font.family: badgeCard.font
                font.pixelSize: Style.px(18)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: badgeCard.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: badgeCard.hostModel
                font.family: badgeCard.font
                font.pixelSize: Style.px(12)
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: badgeCard.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        ActionButton {
            iconText: "󰏫"
            label: "Rename"
            onClicked: badgeCard.startEdit()
        }
    }

    // Edit mode
    RowLayout {
        id: editRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10
        visible: opacity > 0.01
        opacity: badgeCard.editing ? 1.0 : 0.0
        scale: badgeCard.editing ? 1.0 : 0.98
        transform: Translate {
            y: badgeCard.editing ? 0 : 6
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        TextField {
            id: nameInput
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            placeholderText: "Enter device name..."
            placeholderTextColor: badgeCard.theme.textMuted
            color: badgeCard.theme.textPrimary
            font.family: badgeCard.font
            font.pixelSize: Style.px(14)
            font.bold: true
            leftPadding: 12
            rightPadding: 12
            selectByMouse: true

            background: Rectangle {
                radius: 8
                color: badgeCard.theme.bgBase
                border.color: nameInput.activeFocus
                    ? badgeCard.theme.accentPrimary
                    : badgeCard.theme.bgBorder
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 140 } }
            }

            Keys.onReturnPressed: badgeCard.commitEdit()
            Keys.onEnterPressed: badgeCard.commitEdit()
            Keys.onEscapePressed: badgeCard.cancelEdit()
        }

        ActionButton {
            iconText: "󰄬"
            label: "Save"
            onClicked: badgeCard.commitEdit()
        }

        ActionButton {
            label: "Cancel"
            onClicked: badgeCard.cancelEdit()
        }
    }
}
