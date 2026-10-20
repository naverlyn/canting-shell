import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

RowLayout {
    required property var hostCard
    visible: !hostCard.isExpanded
    Layout.fillWidth: true
    spacing: 8

    // Text / Command Monospace Box
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 100
        height: 30
        radius: 6
        color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
        border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        TextInput {
            id: summaryInput
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            verticalAlignment: TextInput.AlignVCenter
            text: (hostCard.blockData && hostCard.blockData.raw_text) ? hostCard.blockData.raw_text : hostCard.editRawText
            font.family: hostCard.font
            font.pixelSize: 11
            color: hostCard.editEnabled ? (hostCard.theme.textSecondary ?? "#9aa5ce") : (hostCard.theme.textMuted ?? "#666666")
            selectByMouse: true
            onEditingFinished: {
                if (hostCard.editIsCmd) {
                    let m = text.match(/^cmd\[update:\d+\]\s*(.*)$/);
                    if (m) {
                        hostCard.editCmdBody = m[1];
                    } else {
                        hostCard.editCmdBody = text;
                    }
                } else {
                    hostCard.editRawText = text;
                }
                let payload = {
                    enabled: hostCard.editEnabled,
                    name: hostCard.editName,
                    raw_text: text
                };
                hostCard.blockSaved(hostCard.blockIndex, payload);
            }
        }
    }

    // Compact "Run / Test" Button for Shell Commands (Modern secondary action button)
    Rectangle {
        id: runSummaryBtn
        visible: hostCard.editIsCmd
        implicitWidth: runSummaryText.implicitWidth + 20
        height: 30
        radius: 7
        color: runSummaryHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
        border.color: runSummaryHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1
        scale: runSummaryMouse.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        HoverHandler { id: runSummaryHover }

        Text {
            id: runSummaryText
            anchors.centerIn: parent
            text: hostCard.isEvaluating ? "Running..." : "Run Test"
            font.family: hostCard.font
            font.pixelSize: 10
            font.bold: true
            color: runSummaryHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textPrimary ?? "#ffffff")
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: runSummaryMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !hostCard.isEvaluating
            onClicked: hostCard.runTest()
        }
    }
}
