import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 14
    visible: root.currentSubTab === 0

    // Search & Filter Bar
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Search Input Box
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 7
            color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
            border.color: appSearchInput.activeFocus
                ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: root.font
                    font.pixelSize: 13
                    color: appSearchInput.activeFocus
                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                        : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                }

                TextInput {
                    id: appSearchInput
                    Layout.fillWidth: true
                    font.family: root.font
                    font.pixelSize: 12
                    color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                    clip: true
                    selectByMouse: true
                    text: root.appSearchQuery
                    onTextChanged: root.appSearchQuery = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !parent.text && !parent.activeFocus
                        text: "Filter startup applications..."
                        font.family: root.font
                        font.pixelSize: 12
                        color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                    }
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: clearAppSearchHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                    visible: appSearchInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: root.font
                        font.pixelSize: 11
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }

                    HoverHandler { id: clearAppSearchHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appSearchInput.text = ""
                    }
                }
            }
        }

        // Filter Segmented Track
        Rectangle {
            id: appFilterSeg
            implicitWidth: 260
            height: 36
            radius: 7
            color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            readonly property var modes: ["all", "enabled", "disabled"]
            readonly property int activeIdx: Math.max(0, modes.indexOf(root.appFilterMode))
            readonly property real cellWidth: (width - 6 - 2 * 3) / 3

            Rectangle {
                y: 3
                height: parent.height - 6
                width: appFilterSeg.cellWidth
                x: 3 + appFilterSeg.activeIdx * (appFilterSeg.cellWidth + 3)
                radius: 5
                color: (root.theme && root.theme.bgSelected) ? root.theme.bgSelected : Qt.rgba(1, 1, 1, 0.15)
                border.color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                border.width: 1
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { id: "all",      label: "All (" + root.appsList.length + ")" },
                        { id: "enabled",  label: "Active (" + root.enabledAppsCount + ")" },
                        { id: "disabled", label: "Off (" + (root.appsList.length - root.enabledAppsCount) + ")" }
                    ]
                    delegate: Rectangle {
                        id: fBtn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: appFilterSeg.activeIdx === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && fHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                        HoverHandler { id: fHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appFilterMode = fBtn.modelData.id
                        }

                        Text {
                            anchors.centerIn: parent
                            text: fBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: fBtn.isSel
                            color: fBtn.isSel
                                ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                : ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                            opacity: fBtn.isSel || fHover.hovered ? 1.0 : 0.75
                        }
                    }
                }
            }
        }

        // Add Application Button
        ActionButton {
            label: "Add Application"
            iconText: "󰐕"
            btnHeight: 36
            onClicked: {
                root.addAppQuery = "";
                root.addAppModalOpen = true;
            }
        }
    }

    // Applications List View Box
    Rectangle {
        Layout.fillWidth: true
        height: 440
        radius: 8
        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        clip: true

        ListView {
            id: appsListView
            anchors.fill: parent
            anchors.margins: 8
            model: root.filteredApps
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                }
            }

            // Empty State
            Item {
                anchors.centerIn: parent
                visible: appsListView.count === 0
                width: 280
                height: 120

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰵆"
                        font.family: root.font
                        font.pixelSize: 32
                        color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.appSearchQuery ? "No matching startup applications" : "No startup applications configured"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }
                }
            }

            delegate: Rectangle {
                id: appItemRow
                required property var modelData

                width: appsListView.width - 8
                height: 58
                radius: 6
                color: appItemHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.05)) : "transparent"
                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                HoverHandler { id: appItemHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Icon Box
                    Rectangle {
                        id: appIconBox
                        width: 36
                        height: 36
                        radius: 7
                        color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)
                        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property string resolvedIcon: {
                            const raw = (appItemRow.modelData && appItemRow.modelData.icon) ? appItemRow.modelData.icon : "";
                            if (raw) {
                                const p = Quickshell.iconPath(raw, true);
                                if (p) return p;
                            }
                            return Quickshell.iconPath("application-x-executable", true);
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: appIconBox.resolvedIcon
                            visible: appIconBox.resolvedIcon !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰵆"
                            font.family: root.font
                            font.pixelSize: 18
                            color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                            visible: appIconBox.resolvedIcon === ""
                        }
                    }

                    // Application Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            spacing: 8
                            Text {
                                text: appItemRow.modelData.name || "Unknown Application"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: appItemRow.modelData.enabled
                                    ? ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                    : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                            }

                            // Scope badge
                            Rectangle {
                                implicitWidth: scopeText.implicitWidth + 10
                                implicitHeight: 18
                                radius: 4
                                color: appItemRow.modelData.scope === "user"
                                    ? Qt.rgba(0.4, 0.7, 1.0, 0.15)
                                    : Qt.rgba(0.5, 0.5, 0.5, 0.15)

                                Text {
                                    id: scopeText
                                    anchors.centerIn: parent
                                    text: appItemRow.modelData.scope === "user" ? "User" : "System"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: appItemRow.modelData.scope === "user"
                                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                        : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0")
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: appItemRow.modelData.comment || appItemRow.modelData.exec || ""
                            font.family: root.font
                            font.pixelSize: 11
                            color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                            elide: Text.ElideRight
                        }
                    }

                    // Actions
                    RowLayout {
                        spacing: 12
                        Layout.alignment: Qt.AlignVCenter

                        // Delete user app button
                        Rectangle {
                            visible: appItemRow.modelData.scope === "user"
                            width: 28
                            height: 28
                            radius: 6
                            color: delAppHover.hovered ? Qt.rgba(1, 0.3, 0.3, 0.2) : "transparent"
                            border.color: delAppHover.hovered ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e") : "transparent"
                            border.width: 1

                            HoverHandler { id: delAppHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteApp(appItemRow.modelData.id, appItemRow.modelData.name)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰆴"
                                font.family: root.font
                                font.pixelSize: 14
                                color: delAppHover.hovered
                                    ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e")
                                    : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                            }
                        }

                        // Switch Toggle
                        SwitchToggle {
                            checked: appItemRow.modelData.enabled
                            onToggled: function(newState) {
                                root.toggleApp(appItemRow.modelData.id, newState);
                            }
                        }
                    }
                }
            }
        }
    }
}
