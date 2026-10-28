import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

RowLayout {
    required property var hostCard
    Layout.fillWidth: true
    spacing: 10

    // Block Name
    Text {
        text: hostCard.editName
        font.family: hostCard.font
        font.pixelSize: 13
        font.bold: true
        color: hostCard.editEnabled ? (hostCard.theme.textPrimary ?? "#ffffff") : (hostCard.theme.textMuted ?? "#666666")
        Layout.alignment: Qt.AlignVCenter
    }

    // Color Indicator Swatch
    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: hostCard.resolveColor(hostCard.editColor)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter
    }

    // Mode Badge Pill
    Rectangle {
        height: 20
        implicitWidth: badgeText.implicitWidth + 12
        radius: 4
        color: hostCard.editIsCmd ? Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.14) : Qt.rgba(1, 1, 1, 0.06)
        border.color: hostCard.editIsCmd ? Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.3) : Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: hostCard.editIsCmd ? ("cmd (" + (hostCard.editCmdInterval >= 1000 ? ((hostCard.editCmdInterval / 1000) + "s") : (hostCard.editCmdInterval + "ms")) + ")") : "text"
            font.family: hostCard.font
            font.pixelSize: 10
            font.bold: true
            color: hostCard.editIsCmd ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textSecondary ?? "#9aa5ce")
        }
    }

    // Font & Size Badge Pill
    Rectangle {
        height: 20
        implicitWidth: fontBadgeText.implicitWidth + 12
        radius: 4
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: fontBadgeText
            anchors.centerIn: parent
            text: (hostCard.editFontFamily || "$font") + " • " + hostCard.editFontSize + "pt"
            font.family: hostCard.font
            font.pixelSize: 10
            color: hostCard.theme.textSecondary ?? "#9aa5ce"
        }
    }

    // Custom block indicator
    Rectangle {
        visible: hostCard.blockData && hostCard.blockData.is_custom
        height: 20
        implicitWidth: customBadgeText.implicitWidth + 12
        radius: 4
        color: Qt.rgba(0.9, 0.7, 0.2, 0.15)
        border.color: Qt.rgba(0.9, 0.7, 0.2, 0.35)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: customBadgeText
            anchors.centerIn: parent
            text: "custom"
            font.family: hostCard.font
            font.pixelSize: 10
            font.bold: true
            color: "#e0af68"
        }
    }

    Item { Layout.fillWidth: true }

    // Master Toggle Switch
    Rectangle {
        id: blockSwitchTrack
        width: 44
        height: 24
        radius: 12
        color: hostCard.editEnabled ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
        Layout.alignment: Qt.AlignVCenter

        Behavior on color { ColorAnimation { duration: 140 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: hostCard.editEnabled ? parent.width - width - 3 : 3
            color: hostCard.editEnabled ? "#ffffff" : (hostCard.theme.textPrimary ?? "#c0caf5")

            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                hostCard.editEnabled = !hostCard.editEnabled;
                let payload = {
                    enabled: hostCard.editEnabled,
                    name: hostCard.editName,
                    raw_text: (hostCard.blockData && hostCard.blockData.raw_text) ? hostCard.blockData.raw_text : hostCard.editRawText
                };
                hostCard.blockSaved(hostCard.blockIndex, payload);
            }
        }
    }

    // Edit / Done Button (Modern secondary action button)
    Rectangle {
        id: editBtn
        implicitWidth: editBtnText.implicitWidth + 20
        height: 28
        radius: 7
        color: editHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
        border.color: (hostCard.isExpanded || editHover.hovered) ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1
        scale: editMouse.pressed ? 0.96 : 1.0
        Layout.alignment: Qt.AlignVCenter

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        HoverHandler { id: editHover }

        Text {
            id: editBtnText
            anchors.centerIn: parent
            text: hostCard.isExpanded ? "Close" : "Edit"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: (hostCard.isExpanded || editHover.hovered) ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textPrimary ?? "#ffffff")
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: editMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hostCard.isExpanded = !hostCard.isExpanded
        }
    }
}
